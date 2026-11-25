# WebP 编码器：从非法 VP8 到合法 VP8L

> 本文记录 WebP 编码能力的现状诊断、路线选择、规范要点、逐阶段验证日志与后续里程碑。
> 结论先行：**现有两个编码器不可修，只能重写；重写的目标是 VP8L（lossless），不是 VP8（lossy）。**

## 1. 现状诊断（2026-11-25 实测）

仓库里有两个 WebP 编码器：

| 函数 | 文件 | 规模 | 产物 | ffmpeg 判定 |
|---|---|---|---|---|
| `encode_webp_lossy_pure` | `image.codec/codec/webp_encode.mbt` | 占位实现 | 64² = 46 B，1024² = 4126 B | `Invalid partitions` |
| `encode_webp_lossy_full` | `image.codec/codec/webp_vp8_encode.mbt` | 27.5 KB，含 FDCT/WFHT/量化/四种帧内预测/概率自适应/环路滤波 | 64² = 1198 B，128² = 2654 B | `Invalid partitions` |

`docs/performance.md` 里 `webp_encode_1024 = 3.16 ms → 331 MP/s` 是**假数字**，它测的是一个不能解码的产物。已在 performance.md 与 README 标注。

**根因（结构性，非补丁级）**：VP8 keyframe 规定 first partition 与 token partitions 是**分开的段**，头部要写各 partition 的尺寸表；两个实现的共同写法是

```moonbit
vp8_build_frame_header(w, h, token_data.length())  // 把整条 bool 流长度当 first partition 尺寸
```

结果是 `first_part_size << 5` 写进了 frame tag，但流里根本没有按该尺寸切段 —— 解码器按尺寸切分后立刻越界，报 `Invalid partitions`。要修就得重写 partition 布局、宏块模式层、概率更新语义，等于重做 VP8 编码器（4–6 周）。

## 2. 路线选择

| 方案 | 工时 | 产物 | 体积 | 结论 |
|---|---|---|---|---|
| 修 VP8 lossy | 4–6 周 | 真·有损 WebP | 最优 | **不做**：成本高，且无损需求先用 VP8L 就能覆盖 |
| VP8L 最小合法 | 3–5 人日 | 合法 `.webp`（literal-only） | ≈ PNG 或更差 | 作为 M1 |
| VP8L 好用版 | 再 1.5–2 周 | 合法 + LZ77 + 变换 | 比 PNG 小 15–30% | **本次目标（M2–M3）** |

决定：走 VP8L。它复用了仓库已有 `webp_decode.mbt` 的 VP8L 解码路径，可以做"自己编、自己解"的逐字节回环验证，风险闭环最短。

## 3. 规范要点（RFC 9649 §3，编码侧必须逐条对上）

1. **位序 LSB-first**：`BitWriter` 逐位从低位写；与仓库 `BitReader::read_bits` 一致（`bit = bit_buf & 1`）。
2. **头部**：`0x2F` 魔数 + 14 位宽 + 14 位高 + `alpha_is_used` 1 位 + `version` 3 位（必须 0）。
3. **transforms 循环**：1 位"是否还有变换" + 2 位类型（0 预测 / 1 颜色变换 / 2 subtract-green / 3 颜色索引），**顺序写，解码反序应用**。
4. **color cache**：1 位标志 + 可选 4 位 `cache_bits`（1–11）。
5. **meta prefix 码**：1 位标志（本实现写 0）。
6. **5 棵前缀码**：绿（字母表 256 + 24 长度码 + cache 大小）、红、蓝、alpha、距离（含 120 项 distance mapping）。
7. **simple code**（1 位 1 = simple）：`num_symbols` 1 位（0→1 个符号，1→2 个）+ `is_first_8bits` 1 位 + `symbol0`（1 或 8 位）+ 可选 `symbol1` 8 位。**若整棵树只有一个符号，解码器不做位读取，直接输出该符号** —— 这是最省事的最小路径。
8. **normal code**（1 位 0 = normal）：
   - `num_code_lengths = 4 + ReadBits(4)`（4–19）
   - 码长按 `kCodeLengthCodeOrder = [17,18,0,1,2,3,4,5,16,6,7,8,9,10,11,12,13,14,15]` 顺序读取，每个 3 位
   - 1 位 `max_symbol` 标志 → 若置位，读 `(ReadBits(2)+2) << 3` 与 `ReadBits(3)` 得到 `max_symbol`
   - 码长码语义：`16` 重复前值 3–6 次（2 位 +3）、`17` 写零 3–10 次（3 位 +3）、`18` 写零 11–138 次（7 位 +11）
   - 码长表**必须 Kraft 完整**（Σ 2^-len = 1），且**未写到的尾部符号长度为 0**
9. **像素解码顺序 G → R → B → A**，每像素 4 个子符号。
10. **LZ77**：长度前缀码 = 256 + 长度码值；距离前缀码 0–119 → 映射为 1–1048576 的距离（近邻 4 组 × 8 个偏移由 4 个距离码缓存派生）。

## 4. 逐阶段验证日志

原型放在 `scripts/proto/`（纯 Node 脚本，不依赖仓库），验证工具统一为

```powershell
ffmpeg -v error -i <file> -f null -    # 无输出即通过
```

| 阶段 | 脚本 | 内容 | 产物 | 结果 |
|---|---|---|---|---|
| A | `vp8l_stageA.mjs` | 16×16 棋盘格；5 棵树全走 simple（G 单符号 0、R/B 双符号 {0,255}、A 单符号 255、dist 单符号 0） | 96 B | **通过**：ffmpeg 解码正常，像素正确 |
| B | `vp8l_proto.mjs` | literal-only；三棵扁平 8 位 normal 码表（256 个符号全 8 位） | 868 B | **失败**：`Overdetermined VLC tree` |

阶段 A 的价值：一次性证明了 RIFF/VP8L 容器头、LSB-first 位序、G→R→B→A 像素顺序、simple 码表编码这四条链路全部正确 —— 后面出错只可能在 normal 码表。

阶段 B 的失败点被 ffmpeg 精确指向 normal code length code 段（16×16 尺寸已被正确识别，说明头解析没问题）。**Kraft 不完整是主因**：256 个符号各 8 位 → Σ 2^-8 × 256 = 1，看似完整，但绿树字母表是 **280**（256 literal + 24 长度码），只写 256 个 8 位长度时，其余 24 个长度为 0 —— 于是"8 位码实际承载 256 个符号"在两套字母表下不自洽，ffmpeg 的树构建判定为 overdetermined。

修正方向（M1 要做的事，按优先级）：

1. 绿树按 280 项填码长，长度码区（256–279）显式给 0 长或给可用长度；
2. 若走"显式零游程"，码长码必须包含 `17`/`18`，否则零长写不进去；
3. 码长码本身要 Kraft 完整（当前 `{8: 1 位, 16: 1 位}` 已只有 2 个符号，长度和为 2^-1 + 2^-1 = 1，但是否允许"只有 16 没有 17/18"要看实现，稳妥做法是给 `{1,2,17,18}` 之类可用集）；
4. 若仍失败，对照 ffmpeg `libavcodec/vp8l.c` 的 `read_huffman_code` 实现逐位比对。

## 5. 里程碑（对应 roadmap S02）

| 里程碑 | 内容 | 验收 |
|---|---|---|
| M1 | literal-only + 正常码表路径；16²/64²/1024² 三档 | 三档 ffmpeg 均可解，像素逐字节一致 |
| M2 | LZ77：长度/距离前缀码 + 距离映射 | 同图体积 ≤ literal-only 的 1/2，进入 PNG 量级 |
| M3 | 变换：subtract-green + predictor（14 模式 / block 级）+ 色彩缓存 | 同图体积比 PNG 小 15–30% |
| M4 | 落 MoonBit：`encode_webp_lossless`；bench 入 performance.md；`_pure`/`_full` 标 deprecated | 1024² 编码 ≥3 MP/s；6664 测试全绿；能力表只留一个 WebP 编码入口 |

## 6. 给下游的承诺（M4 之后）

- `encode_webp_lossless(img) -> Bytes`：无损、体积优于 PNG、单入口；
- 有损 WebP **不承诺**：`encode_webp_lossy_*` 标 `#deprecated`，文档明确"不支持，需要请用 JPEG"；
- 产物合法性由 `tools/verify_image.mjs`（S07 交付）在 CI 中用 ffmpeg 校验，防止再出现"看起来能编、其实不能解"。

## 7. 复现

```powershell
node scripts/proto/vp8l_stageA.mjs      # 生成 _build/proto/stageA.webp
ffmpeg -v error -i _build/proto/stageA.webp -f null -   # 无输出 = 通过
```
