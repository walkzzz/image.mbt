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
| B | `vp8l_proto.mjs` | literal-only；三棵"扁平 8 位"normal 码表，只写 256 个长度 | 868 B | **失败**：`Overdetermined VLC tree` |
| C | `vp8l_m1.mjs` | literal-only；绿树按 **280** 个符号写码长，码长码 `{8,18}`（12 项，Kraft 完整），尾部 24 个长度码用符号 18 写零游程 | 16²=908 B / 64²=12.4 KB / 1024²=3.1 MB | **通过**：三档 ffmpeg 全部可解，`verify_pixels.mjs` 逐字节比对**全等** |
| D | `gen_lz77_fixture.mjs` | 1 个 literal + 一次 length=255 / distance=1 反向引用；绿树是双符号 normal 码表，码长码 `{1,17,18}` | 38 B | **通过**：ffmpeg 解出 16×16 纯色全等；MoonBit `decode_webp_vp8l_rfc` 同一份字节也解出全等 |

阶段 A 的价值：一次性证明了 RIFF/VP8L 容器头、LSB-first 位序、G→R→B→A 像素顺序、simple 码表编码这四条链路全部正确 —— 后面出错只可能在 normal 码表。

阶段 B 的失败被定位为字母表长度写错：绿树字母表是 **280**（256 literal + 24 长度码），只写 256 个长度会让解码器读不满，把后续比特当成码长用，判定树"超额"。阶段 C 补齐 280 项后一次通过，与推断吻合。

阶段 C 中途发现一个易错点（已写进日志备查）：**simple 码表的单符号 ≤1 时只占 1 位，>1 必须置 `is_first_8bits=1` 并用 8 位**。第一版把 alpha 的 255 写成了 1 位，产物仍能解码、尺寸也识别正确，但 alpha 全变成 1 —— 这类"值被静默截断"的 bug 只有逐字节像素比对能抓到，所以 M1 之后每个里程碑都必须跑 `verify_pixels.mjs`，不能只看 ffmpeg 退出码。

阶段 C 的体积是 **3.0 字节/像素**，比 PNG 差 —— 这是 literal-only 的必然结果，LZ77 与变换（M2/M3）才是体积来源。

阶段 D 暴露三个"记忆型错误"，都以 RFC 原文为准修正（这类细节网上二手资料错误率很高，必须回原文）：

| 位置 | 错误写法 | RFC 9649 正确写法 |
|---|---|---|
| 长度前缀 15 的取值 | 以为写符号就够 | 还需 6 个 extra bits：`192 + extra + 1`，长度 255 需 extra=62 |
| `max_symbol` | `((ReadBits(2)+2)<<3) + ReadBits(3)` | `length_nbits = 2 + 2*ReadBits(3); max_symbol = 2 + ReadBits(length_nbits)` |
| 码长码 16 的首次重复值 | 0 | **8**（尚未输出非零长度时） |

另有一个关键发现：**libwebp 编出的真实无损文件默认带 `COLOR_INDEXING`（palette）变换**。ffmpeg 把 16×16 纯色图存成 38 B，结构是 `transform 3` + 1 色 palette。所以"能解码真实 WebP"必须先实现 palette / predictor 逆变换（M3），现有 `decode_webp_vp8l_rfc` 只支持 subtract-green，遇到其它变换会显式报错而不是输出错像素。

### 4.1 MoonBit 落地（M1）

`image.codec/codec/webp_vp8l_encode.mbt` → `encode_webp_vp8l_literal(img)`：literal-only + 5 棵前缀码（绿 280 / 红 256 / 蓝 256 / alpha / 距离 40），alpha 全不透明时用单符号码表省掉每像素 8 位。

验证链：

| 环节 | 结果 |
|---|---|
| 内环：编码 → `decode_webp_vp8l_rfc` 解码 → 逐字节比对 | 5 项测试通过（16² RGBA / 8² RGB 补 alpha / 1×1 / 尺寸超限 / hex dump） |
| 外环：MoonBit 产物 → ffmpeg 解码 → 与源图 RGBA 比对 | 16² 全等（1024 字节无差异） |
| 回归：`image.codec/codec` 全包测试 | 558 项全绿 |

同时暴露并修复了两个解码侧问题（记入 `docs/known-gaps.md` GAP-28）：

1. **单符号码表仍消耗 1 位**：旧 `HuffmanTree::decode` 一律"先读 1 位再走左子树"，而 RFC 规定单符号码表零比特。现象是 alpha/距离这类单符号树每像素多吃 1 位，导致整条流逐步错位 —— 1024 字节里错 1002 字节。修法：单符号树根节点直接持值，`decode` 先判根值。
2. **旧 VP8L 解码路径整体非 RFC 合规**：simple 码表位布局、码长硬编码 256、三通道复用绿树。因此不能拿 `decode_webp_pure` 当验证器，M1 的验证改用新增的 `decode_webp_vp8l_rfc`；切换默认路径与重写受影响的旧测试排到 S03（JPEG 之后）。

### 4.2 MoonBit 落地（M2：LZ77 + 频次驱动 Huffman）

`image.codec/codec/webp_vp8l_lz77_encode.mbt` → `encode_webp_vp8l_lz77(img)`：

1. 哈希链贪心匹配（4096 槽、链深 16、最短 3、最长 4096）；
2. 两遍：先统计 literal / 长度前缀 / 距离码频次，再建 5 棵长度受限（≤15 位）Huffman 树；
3. 码表按 RFC simple / normal 两路写出（normal 用码长码 16/17/18 压缩零游程）。

同一套编码器在**编码侧**踩到与解码侧对称的坑：单符号树每像素符号位必须写 **0 位**，而我们初版按 `lens[s]=1` 写了 1 位。结果是流结构合法、ffmpeg 不报错，但像素整片错位（16384 字节错 12097）。修法：`vp8l_is_single` 判定后跳过该树的符号位（距离树同样跳过，距离值由前缀码唯一决定）。这条规则在 RFC 9649 §3.4 里写的是"码表仅一个符号时不再读比特"，编码侧必须对称处理 —— 内环测试与 ffmpeg 外环都能抓到，缺一不可。

验证链：

| 环节 | 结果 |
|---|---|
| 内环：64² 梯度图 → `encode_webp_vp8l_lz77` → `decode_webp_vp8l_rfc` → 逐字节比对 | 差异 0 字节 |
| 外环：MoonBit 产物 → ffmpeg 解码 → 与源图 RGBA 比对 | 差异 0 字节（64²，16384 字节全对） |
| 体积下限：同图 LZ77 vs literal-only | 12428 → 9800 字节（−21%） |

### 4.3 体积基线（vs libwebp lossless，2026-11-25）

| 内容 | 尺寸 | 本库 LZ77 | libwebp `-lossless` | 差距 |
|---|---|---|---|---|
| 纯色 | 64² | 36 字节 | 44 字节 | 更小（头部开销少） |
| 纯色 | 256² | 56 字节 | 44 字节 | +27% |
| 棋盘 8px 块 | 256² | 154 字节 | 66 字节 | +133% |
| 噪声 | 256² | 196702 字节 | 37258 字节 | +428% |

结论：M2 只解决"重复结构"，未解决"熵"。噪声图 5.9 bits/byte 已是 literal 的熵下限附近，libwebp 靠 palette / predictor 变换把残差压到 1.1 bits/byte。因此 **M3 的变换不是优化项，而是体积竞争力的主体**；纯色 / 棋盘这类可被长距离匹配吃掉的内容，本库已与 libwebp 同档。

### 4.4 MoonBit 落地（M3 解码侧：四类逆变换）

`image.codec/codec/webp_vp8l_transforms.mbt` 重写了解码主路径：

1. 通用图像流解码 `vp8l_decode_stream`：literal / LZ77 / 色彩缓存 / meta 多组前缀码，`allow_meta=false` 用于变换数据、熵图等子分辨率图像；
2. 变换表按读入顺序记录，按**逆序**应用；palette 会先缩小宽度（影响后续变换尺寸），逆变换时再复原；
3. 四类逆变换：predictor（14 模式 + 16² 块 + 边界规则）、cross-color（3.5 定点 delta）、subtract-green、color indexing（调色板 delta 解码 + 1/2/4/8 像素打包）。

同时删掉了旧的非 RFC 解码器（`decode_webp_nonrfc`、`read_huffman_tree`、`apply_predictor_inverse`）与其 10 项伪流测试：这些只解得开自造的非标准流，留着会误导下游。`decode_webp_pure` 现在直接走 RFC 路径。

**编码侧两处修正**（都由真实文件解析暴露）：

- 距离码直方图按"码值"统计而非"前缀符号"统计，导致距离码表与写入不匹配 → 改成 `vp8l_encode_length(dcode).0`；
- 单符号树只该省略**符号码**，`extra bits` 仍必须写出。此前整块跳过，距离码实际值为 0（64 像素的匹配被读成 19），流合法但像素全错。

验证：

| 环节 | 结果 |
|---|---|
| libwebp 纯色 256²（palette + 8 像素打包） | 65536 像素全等 |
| libwebp 棋盘 256²（palette） | 65536 像素全等 |
| libwebp 64² 梯度（predictor + subtract-green） | 4096 像素全等（70 字节文件） |
| 自编码 RGBA 16²（256 色，5 棵多符号树） | 内环 0 差异；ffmpeg 外环 0 差异 |
| 自编码尺寸阶梯 2²/4²/8²/16²/32² | 全部 0 差异 |
| `image.codec/codec` 全包 | 556 项全绿 |

## 5. 里程碑（对应 roadmap S02）

| 里程碑 | 内容 | 验收 |
|---|---|---|
| M1 | literal-only + 正常码表路径；16²/64²/1024² 三档 | 三档 ffmpeg 均可解，像素逐字节一致 |
| M2 | LZ77：长度/距离前缀码 + 距离映射 | 正确性：内环 + ffmpeg 外环均逐字节一致（达标）；体积：可匹配内容（纯色/棋盘）与 libwebp 同档，噪声图仍差 4.3 倍（体积目标押到 M3） |
| M3 | 变换：subtract-green + predictor（14 模式 / block 级）+ 色彩缓存 | 解码侧完成：三类变换 + palette 全支持，真实 libwebp 文件逐字节一致；编码侧（选择与写变换表）未开始 |
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
