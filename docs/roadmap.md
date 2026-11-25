# image.mbt 远期路线图（Sprint 级）

> 目标只有两条：**下游开发者能装上、跑通、看得懂错误；我自己在日常项目里真的会用。**
> 制定：2026-11-25 | 版本轨道：0.1.x（一个 Sprint 一个 patch） | Sprint 编号：S01 起连续
> 历史（v0.1 起的功能迭代流水、mermaid 甘特图）：[roadmap-history.md](roadmap-history.md)

## 0. 战略一句话

先证明"能用"，再证明"好用"，最后才谈"更多"。

现状是 90 个算子、6664 个测试、70 个包、83.4% 覆盖率 —— 但没有一份可复算的速度数字，没有一个给非 MoonBit 用户的出口，没有能放进服务的错误码与资源限额。0.1.1–0.1.7 只补这三件事，一个新算法都不加。

## 1. 判据（每个 Sprint 的交付必须同时满足）

| # | 判据 | 可核查形式 |
|---|---|---|
| 1 | **装得上** | 新项目 `moon add walkzzz/image.mbt` 后 5 分钟内出图；registry 版本 = README 徽章 = 演示可用 |
| 2 | **跑得动** | 1MP 级编解码在 release 下 ≤100ms 量级；20000² 图不 OOM |
| 3 | **错得清楚** | 失败返回稳定错误码 + 建议动作，不是 panic、不是空返回 |
| 4 | **我自己在用** | 每个 Sprint 至少 1 条真实使用记录（dogfood），无记录视为未完成 |

产能假设：单人，**1 Sprint = 5 人日**。Sprint 超载时**砍交付物，不改日期**；一个 Sprint 只允许一个主目标。

**补充诊断（吸收自[分层迭代路线](../image-mbt-分层迭代路线.md)第二节）**：一个场景要真可用，必须在三层都有东西 ——
**Primitive**（算子正确 + 有精度/性能指标）→ **Recipe**（5–10 个算子串成一次调用，输入输出是业务语义）→ **Product**（CLI 一条命令 / HTTP 一个 URL / MCP 一个工具 / 页面一个按钮）。
本仓库现状：90% 场景只做到 Primitive，所以"能力很强但用不上"。这就是 S05（出口）与 S06（Recipe）必须排在 0.1.6 之前的理由。

## 2. 版本与编号规则

- 唯一版本轨道是 **0.1.x**：三段 SemVer，`major.minor` 钉死在 `0.1`，只递增 patch。功能版本 v5.x 停止累加，只作历史。
- **一个 Sprint = 一个 patch 号**：S01 = `0.1.1`、S02 = `0.1.2` … S21 = `0.1.21`。Sprint 收尾时 7 个 `moon.mod` 同步升 patch，`check_version.mjs` 必须 ok。
- **四段号（0.1.x.y）不采用**：实测 `version = "0.1.2.3"` 被 mooncakes 拒绝（`version bad format / unexpected character '.' after patch version number`）；`0.1.2+s06` 虽可解析但会破坏 `check_version.mjs` 的徽章比对，故不用。
- **发布（`moon publish`）只在阶段收口做**：S07 → 0.1.6、S12 → 0.1.11、S17 → 0.1.16、S21 → 0.1.20。中间 Sprint 只升版本号不发布，避免 20 次不可逆外部动作。
- Sprint 编号 S01… 跨版本连续，不断号、不回填。
- 每个 Sprint 收尾必须回写本文件：状态 / commit hash / bench 数字。
- **每轮改动结束自动提交**（用户 2026-11-25 要求）：一次提交 = 一次可回滚的交付，提交信息带类型前缀与数字。
- **发布列车**：每 5 个 Sprint 收口一次（0.1.7 / 0.1.12 / 0.1.17 / 0.1.21），中间只升号不发布。

## 3. 基线（2026-11-25 实测，x86 / Windows / native release）

完整表见 [performance.md](performance.md)。关键数字：

| 格式 | 编码 | 解码 | 判定 |
|---|---|---|---|
| PNG 1MP | 21.6 MP/s | 13.2 MP/s | **够用，不优化** |
| PNG 16.8MP | 21.4 MP/s | 13.1 MP/s | 够用 |
| **JPEG 1MP** | **1.96 MP/s** | **2.12 MP/s** | **唯一真瓶颈**：12MP 编 6.4s / 解 6.0s；1000 张批处理编 1.8 小时 |
| WebP 1MP | 331 MP/s（可疑） | — | 速度不合理 + 自述"仅外部工具可解"→ **先验产物合法性** |
| BMP / QOI 1MP | 126 / 107 MP/s | — | 合理 |
| GIF 0.26MP | 0.44 MP/s | — | 12MP ≈ 27s，暂不优化（格式本身低频） |
| resize 1024→512 | 5.23 ms | — | 够用 |

**结论修正（相对旧报告）**：旧 `performance_report.md`（ARM aarch64、128²、编译器 0.1.20260819）的 PNG 933 KP/s、JPEG 65.9 KP/s 均不成立 —— PNG 实际快 20 倍，JPEG 实际快 30 倍。**但 JPEG 仍是唯一需要动手的格式**，PNG 优化项直接从计划里删掉。

现状短板（全部可核查）：

| 项 | 事实 |
|---|---|
| registry 最新版 | 0.1.0（本地 0.1.1 未发布） |
| README 徽章 | 0.1.1，早于 registry |
| 在线演示 | 旧地址 HTTP 404，README 已改为"迁移中" |
| 错误类型 | 分散多处，无稳定错误码 |
| 资源限额 | 无 max_pixels / max_bytes / 超时 |
| 非 MoonBit 出口 | 无（CLI / MCP / npm 均未成型） |
| 大图 | 算子整图复制，无内存预算 |
| 覆盖率 | 83.4%（32862/39395） |
| WebP | 编码产物**非法**（ffmpeg 报 `Invalid partitions`），已从"可编码格式"摘除（GAP-27） |

## 4. 阶段地图

| 版本 | 主题 | Sprint | 成败判定 |
|---|---|---|---|
| **0.1.1–0.1.7** | **能用** | S01–S07 | 陌生人照 README 30 分钟出图；坏图不崩；有 1 个出口；我自己已在用 |
| **0.1.8–0.1.12** | **工程可用** | S08–S12 | 能放进服务/批处理；20000² 出缩略图 ≤512MB；CI 有性能门禁 |
| **0.1.13–0.1.17** | 专业纵深 | S13–S17 | 16bit/动画/区域解码补齐；场景包收敛为 4 个 |
| **0.1.18–0.1.21** | 可承诺 | S18–S21 | 覆盖率 90%；版本与文档零漂移；外部可复算基准 |

---

## 5. 0.1.1–0.1.7 Sprint 卡（能用阶段）

### S01 度量与发布一致性（1 周）

**目标**：让"多快、哪一版、点开有没有用"三件事都可核查。

**交付**
1. `bench_real.mbt` 补 6 项：`jpeg_encode_1024`、`jpeg_decode_1024`、`webp_encode_1024`、`gif_encode_1024`、`bmp_encode_1024`、`qoi_decode_1024`。
2. `docs/performance.md`：x86 release 实测表 + 每项复现命令 + 环境指纹（已建，随补测追加）。
3. 旧报告归档 `docs/performance-2026-08-arm.md`，头部注明口径失效原因。
4. README：性能命令改为 `moon bench`；演示链接改为"迁移中"；徽章待发布后同步。

**验收**
- `moon bench --release --target native` 输出 ≥12 项且全绿；
- `docs/performance.md` 每一行都能对应到一个 bench 名；
- README 不再出现 ARM / 128² 旧数字。

**风险**：Windows 计时抖动 → 每项 ≥10 轮取中位数并记录 σ；4096² 只跑 1 轮时注明。

**状态**：**已完成（2026-11-25，commit `8fbee28e`）** —— `bench_real.mbt` 现 12 项全绿（PNG 6 + JPEG/WebP/BMP/QOI/GIF 6），`docs/performance.md` 已建，旧报告已归档，README 三处已改。剩余待办只有"发布 0.1.1 后同步徽章"，归入 S07。

---

### S02 WebP VP8L 编码器（2–3 周，M1–M4）

**目标**：给 WebP 一条**合法且可用**的编码路径，取代现有两个非法 VP8 实现。选 VP8L（lossless）而不修 VP8 lossy，理由与阶段计划见 [webp-encoder.md](webp-encoder.md)。

**为什么不是修 VP8**：两个现有编码器（`encode_webp_lossy_pure` / `_full`）都把"头部+模式+系数"写进同一个 bool 流，产物里不存在 first partition 与 token partition 的边界，`first_part_size` 被写成整条流长度 —— 结构性地无解，只能重写。VP8 真正可用需 4–6 周，VP8L 做到"比 PNG 更小"只需 2–3 周。

**交付（按里程碑，每个单独可验证）**
1. **M1 最小合法**：literal-only + 5 棵前缀码（走 normal code length code 路径），16²/64²/1024² 三档产物被 ffmpeg 打开。
2. **M2 LZ77**：长度/距离前缀码 + 120 个近邻距离映射，体积进入 PNG 量级。
3. **M3 变换**：subtract-green + predictor（14 模式 / block 级）+ 色彩缓存，体积比 PNG 小 15–30%。
4. **M4 收口**：自家 VP8L 解码器逐字节回环 + ffmpeg 双验证；bench 进 `docs/performance.md`；对外命名 `encode_webp_lossless`；旧 `_pure` / `_full` 标 `#deprecated` 并从能力表移除。

**验收**
- 三档尺寸产物 ffmpeg 全部可解，且解码像素与源图**逐字节一致**（lossless）；
- 1024² 编码 ≥3 MP/s；
- 同图体积 ≤ PNG；
- 6664 测试全绿，`moon check --deny-warn --target all` 零警告。

**风险**：码长码与位序最易错 → 已用 Node 原型 + ffmpeg 逐阶段验证（阶段 A 已通过，见 webp-encoder.md 日志）；**每个里程碑必须 ffmpeg 判定后才算完成**，不接受"看起来对"。

**状态**：M1 已完成（2026-11-25）—— `encode_webp_vp8l_literal` 落地，内环 5 项 + ffmpeg 逐字节复核 + 全包 558 项无回归；新增 RFC 合规解码路径 `decode_webp_vp8l_rfc`（顺带修掉"单符号码表仍消耗 1 位"的错位 bug，记 GAP-28）。M2 已完成（2026-11-25）—— `encode_webp_vp8l_lz77`（哈希链贪心匹配 + 频次驱动长度受限 Huffman + normal 码表零游程），内环回环与 ffmpeg 外环均 0 字节差异；体积基线：纯色 64² 36 B（libwebp 44 B）、棋盘 256² 154 B（66 B）、噪声 256² 196702 B（37258 B）。结论：LZ77 只吃重复结构，熵编码竞争力由 M3 变换决定，M3 已提为体积主战场。

下一步 M3：subtract-green 逆变换对齐 + predictor 14 模式（block 级）+ palette（libwebp 默认产物）+ 色彩缓存出码。M3 两侧已落地（2026-11-25）—— 解码侧（commit `c76f0079`）四类逆变换 + meta 多组 + palette + predictor，真实 libwebp 文件逐字节通过；编码侧重构出 `vp8l_write_image_stream` + `vp8l_forward_predictor` + `vp8l_try_palette`，对外单入口 `encode_webp_lossless`（候选实际编码一遍比长度取胜者）。过程中修掉三个 simple 码表坑（详见 [webp-encoder.md §4.5](webp-encoder.md)），修完后 ffmpeg 解码产物与 libwebp 逐字节 0 差异；体积：纯色 64² 38 B（44 B）、梯度 64² 66 B（70 B）、棋盘 256² 112 B（66 B）、噪声 64² 12422 B（12404 B）。

**状态：M1–M4 全部完成（2026-11-25，版本 0.1.2）** —— M4 收口内容：`bench_real.mbt` 的 WebP 项换成 `encode_webp_lossless`（1024² 梯度 244.83 ms / 4.28 MP/s，达标 ≥3 MP/s）；`docs/performance.md` 增行并改写"331 MP/s 可疑"结论；`encode_webp_lossy_pure` / `_full` 标 `#deprecated`，内部调用点加 `#warnings("-deprecated")`，`moon check --deny-warn` 零警告；README 中英能力表只留 VP8L 无损编码一行；GAP-27 恢复 WebP 编码宣称。

---

### S03 JPEG 提速（1–2 周）

**目标**：S01 已测出 JPEG 是唯一真瓶颈（编 1.96 MP/s / 解 2.12 MP/s，12MP 编 6.4s），把它提到可用区间。因 WebP 插队，本 Sprint 顺延一位。

**状态：已完成（2026-11-25，版本 0.1.3）**

交付与结果：

| 项 | 改造前 | 改造后 | 门禁 |
|---|---|---|---|
| `jpeg_encode_1024` | 534.56 ms（1.96 MP/s） | **82.90 ms（12.6 MP/s）** | ≥8 MP/s ✅ |
| `jpeg_decode_1024` | 495.22 ms（2.12 MP/s） | **116.36 ms（9.0 MP/s）** | ≥8 MP/s ✅ |
| `jpeg 64² 梯度回环误差` | 13 | **7** | ≤16 ✅ |
| ffmpeg / PIL 打开产物 | 可解 | 可解（PIL 与 ffmpeg 互差 mean 0.04） | ✅ |
| 测试 | 6,664 | **6,675 × 4 目标全绿** | ✅ |
| `moon check --deny-warn --target all` | — | 零警告 | ✅ |

1. **编码侧**：可分离浮点 DCT → **整数 AAN FDCT**（等价 libjpeg `jfdctint`，输出 ×8 由 `1/(q*8)` 量化倒数吸收）；定点 RGB→YCbCr（`(19595R+38470G+7471B+32768)>>16` 一组）；量化倒数 + zigzag 预计算；块/移位/系数/量化结果在图级只分配一次。
2. **解码侧**：可分离 IDCT（行→列，余弦表全图只建一次，替代每块 64 次 `cosf` + 4096 次乘）；块/空间/浮点暂存复用（不再每块 `Array::make(64)`）；YCbCr→RGB 改整数定点（`91881` / `22554+46802` / `116130` 加权）。
3. **顺带修掉一个失真 bug**：`jpeg_parse_header` 里 `Array::make(4, Array::make(64, 0))` 让 4 张量化表共享同一个数组实体，第二张（色度）表覆盖了第一张（亮度）表 → 解码整体失真（4:4:4 自回环 mean 5.7）。改成逐槽新建后与 PIL/ffmpeg 的差降到 max 3 / mean 0.50，并补了纯色回环回归测试。
4. **新增质量参数接口**：`encode_jpeg_with_quality(img, quality)`（libjpeg 缩放公式，50 = 标准表），`@lib.save_image_with_quality` 的 JPEG 分支现在真的生效（此前 `quality` 被 `let _ = quality` 丢弃）。

**遗留（不属于本 Sprint 门禁）**：编码只出 4:4:4（无 4:2:0 子采样），同质量下体积比 libjpeg 大 20–40%；Huffman 仍是逐位读（未做 8 位查表），解码还有一次提速空间。

---

### S04 错误模型与资源限额（1 周）

**目标**：能放进服务 —— 坏图不 panic、不 OOM。

**状态：已完成（2026-11-25，版本 0.1.4）**

交付与结果：

| 项 | 内容 | 验收 |
|---|---|---|
| `ImageError` | `Decode/Encode/Process/Budget/Cancelled` + `code()` 稳定码（`decode/truncated`、`budget/limit_pixels`…） | 12 个码字符串断言 ✅ |
| `DecodeLimits` | `max_pixels/max_bytes/max_ms`，`default/strict/with_max_pixels` 预设 | 101 字节超 100 上限被拒 ✅ |
| `AllocBudget` | `check_image(w,h,ch,what)` 准入，默认 512 MiB | 20000²×4 被拒 ✅ |
| `error_hint(code)` | 12 类码全部有建议动作，含具体参数名 | 12 条断言 + 关键词检查 ✅ |
| `decode_with_limits` | 字节上限 → 头部像素上限 → 解码；`LoadError` 投影成 `ImageError` | 正常 PNG 可解；截断 JPEG 归类；QOI 炸弹拒绝 ✅ |
| 文档 | `docs/error-model.md`（码表 + 预算 + 用法 + 攻击面验证） | 双语 README 文档表已挂链 ✅ |

**关键设计**：不改 `LoadError` 签名（避 70 包大面积改动），新增一层结构化错误 + 投影函数；预算检查**在分配内存之前**完成——同步纯 MoonBit 实现无法强杀死循环，因此 `max_ms` 只作准入与事后判定，真正防 OOM 的是字节/像素双上限。

**遗留**：`max_ms` 无强制中断（需可让出/可取消的解码循环）；处理算子尚未逐个接 `AllocBudget`；`{code,message,hint}` 的对外透传在 S05 出口落地。

---

### S05 一个出口（1 周）

**目标**：非 MoonBit 用户（包括 agent）能调。

**状态：已完成（2026-11-25，版本 0.1.5）**

**交付**：MCP server，6 个工具起步：`decode / encode / resize / crop / analyze / sanitize`；JSON Schema + 结构化错误；一条 stdio 启动命令。

| 项 | 内容 | 验收 |
|---|---|---|
| MoonBit CLI | `imgcli` 库包（可测）+ `cmd/imgtool` 入口；7 个子命令：`info/decode/encode/resize/crop/analyze/sanitize`；结果单行 JSON | 7 子命令手动往返全通过；5 条 whitebox 测试 ✅ |
| MCP 协议层 | `mcp/server.mjs`：`initialize / tools/list / tools/call / ping`，newline-delimited JSON-RPC，零第三方依赖 | 27/27 用例通过，冷启动 **73 ms** ✅ |
| 6 工具 schema | 每个工具 `inputSchema` 为 object + required 数组；省略 `output` 时直接内联 base64 图片 + mimeType | 04/07/08 用例断言 ✅ |
| 结构化错误 | imgtool 失败 → `{ok:false, code, message, hint}`；MCP 侧 `isError:true` 原样透传 | 18/19/20/22/24/25 用例 ✅ |
| `--mem-budget` | MCP `mem_budget` 或环境 `IMGTOOL_MEM_BUDGET` → CLI `--mem-budget` → `DecodeLimits`（像素按 8 字节/像素换算） | 1 KiB 预算下正常 PNG 被 `budget/limit_bytes` 拒绝 ✅ |
| 文档 | `docs/mcp.md`（协议、6 工具、错误契约、Claude/Cursor 配置片段、CLI 直用） | 双语 README 已挂链 ✅ |

**关键设计**：MCP 进程只做协议/参数校验/文件桥接，图像逻辑全部在 MoonBit 侧——CLI 与 MCP 共用一条代码路径，行为不会漂移；因此 `moon test` 与 `smoke.mjs` 覆盖的是同一份实现。`moonbitlang/x` 只为 CLI 的文件读写引入，库用户不受影响。

**验收结果**：20 条门槛 → 实交 **27 条脚本化用例全绿**（`node scripts/mcp/smoke.mjs`）；启动 73 ms（门槛 1 s）。

**风险**：工具一次上太多 → 先 6 个，schema 稳定后再加。**npm-wasm 出口推到 S12，不同时做两个出口。**


---

### S06 sanitize Recipe（1 周）

**目标**：第一个"一次调用解决一件事"，也是我自己最常用的功能。

**状态：已完成（2026-11-25，版本 0.1.6）**

**交付**：`sanitize_image(img, policy, regions, block, blur, format, quality)` = 剥离 EXIF/GPS/XMP/ICC/缩略图 + 已知区域块均值打码 + 可选整图模糊；CLI / MCP / 库三层共用 `imgcli/recipe.mbt`。

| 项 | 内容 | 验收 |
|---|---|---|
| 三档 policy | `metadata`（只剥壳、像素不变）/ `standard`（+区域打码）/ `strict`（+整图 box blur、强制 png） | 三档手动往返 + smoke 28/29/30 用例 ✅ |
| 区域语法 | `"x,y,w,h"`，多块分号分隔；越界裁剪、完全在图外报 `process/invalid_argument` | smoke 32 + 白盒 parse_region 正反例 ✅ |
| 元数据扫描 | 输出字节签名表 Exif/GPS/XMP/ICC_PROFILE/Photoshop 3.0/`<x:xmpmeta`/Thumbnail → `metadata_free` + `metadata_hits` | 200 张样本 residue 0 ✅ |
| 批量验收 | `scripts/mcp/sanitize_batch.mjs`：200 张注入元数据 JPEG，三档全跑 | `samples 200 / runs 200 / dirtyInputs 200 / residue 0 / failed 0` ✅ |
| MCP 同步 | `sanitize` schema 增 policy/regions/block/blur；冒烟 27 → **33** 条 | 33/33 ✅ |
| 文档 | `docs/sanitize.md`（policy 语义、区域语法、失败模式、已知限制） | 双语 README 挂链，B5 无死链 ✅ |

**顺带修掉的两个真 bug**（不修则 sanitize 等于往用户手里塞坏文件）：
1. `crc32` 用 Int32 算术右移 → PNG chunk CRC 全错，PIL / ffmpeg 拒开；加逻辑右移掩码修复。
2. PNG 编码器为 stored deflate + filter 0，640×360 输出 691,678 B（比源文件大 26 倍）；换成 fixed Huffman + LZ77 + 逐行 5 种 filter 择优后 30,243 B（**22.9×**），PIL 逐像素 maxdiff 0，RGB/RGBA/灰度均逐像素一致。代价：1MP 编码 48 → 95 ms，仍属可用，已回写 `docs/performance.md`。

**风险兑现**：人脸检测召回不足 → 按预案只承诺"redact 已知区域 + 可选整图模糊"，**不承诺检测到所有脸**，并在 `docs/sanitize.md` 写成设计边界而非待办。

---

### S07 dogfood 收口 + 发布 0.1.7（1 周）

**交付**
1. 自家 CAD/GIS 或批处理脚本接一次，记录 ≥5 条 friction → issue；
2. 按 `core → codec → process → photography → vision → domain → 根` 顺序发 7 个包；
3. README / 徽章 / 演示站同步。

**验收**：全新项目 `moon add` 后 30 分钟跑出 PNG/JPEG 往返；根 `moon publish --dry-run` 通过；dogfood 记录入库。

**风险**：发布链 7 环不可逆 → 先分步 dry-run（注意 `scripts/publish.sh --dry-run` 全链会在 codec 处失败，属 dry-run 语义所限，不是脚本 bug）。

**S07 进展（2026-11-25，版本 0.1.7，未发布）**
- ✅ **WebP 无损解码修通**：`scripts/dogfood.mjs` 跑真实输入时发现 `photo_1920.webp` 四个下游操作全失败，顺藤摸出 7 处 VP8L 缺陷（详见 `docs/known-gaps.md` GAP-28）。修完后自建回归 `scripts/proto/webp_battery.py` **321 例逐像素全等**（PIL method 0/4/6 × 9 类内容 × 12 尺寸 + ffmpeg `-lossless 1` 三种 lavfi 源），并加了 Kraft 完整性校验把静默全黑变成可定位错误。顺带补 `webp_decode_1024` bench：**15.68 ms / 66.8 MP/s**。
- ✅ **CLI friction 4 条全修**：`help`/`version` 人类可读输出；`decode/encode/resize/crop/sanitize` 统一走 `out_format`（`--format` > 输出扩展名 > 子命令默认），`out.jpg` 真是 JPEG、`crop` 支持 `--format`、`sanitize out.png` 真是 PNG。MCP 的 `crop` 同步补 `format`/`quality`，冒烟 33/33。
- ✅ **dogfood 收口**：`scripts/dogfood.mjs` 8 输入 × 6 步 = **48 操作全通过**、8 条摩擦探针 8/8 ok；记录写入 `docs/dogfood.md`；`scripts/bump_version.mjs` 固化了"一 Sprint 一 patch"的版本改动面（`check_version` 12 → 13 项）。
- ⬜ **发布链 7 环**（`core → codec → process → photography → vision → domain → 根`）仍待执行；`moon publish` 是不可逆外部动作，等用户授权后按上面的顺序分步 dry-run → 实发。
- ⬜ 下游"30 分钟上手"验收（全新项目 `moon add` 跑 PNG/JPEG 往返）需在发布后做，本机先用手写的最小示例替代。

**发布前诊断（2026-11-25 记）**：`moon publish --dry-run` 当前失败，报 `Cannot find import 'walkzzz/image.core/testgen' in walkzzz/image.mbt/playground@0.1.1`。根因是版本错配——根 `moon.mod` 仍 import `walkzzz/image.core@0.1.1` 等已发布版本，而 dry-run 的验证包会用这些缓存版本重解依赖；本地 `image.core` 里的 `testgen` 包若没随 0.1.1 发出去，playground 的 import 就悬空。收口顺序因此必须固定：先按 `core → codec → process → photography → vision → domain` 发 0.1.7（确认 `testgen` 在 `image.core` 发布集内），再把根 `moon.mod` 的 6 条依赖全部改到 `@0.1.7`，最后才跑根 dry-run。

---

## 6. 0.1.8–0.1.21（一行一 Sprint）

| Sprint | 交付 | 验收 |
|---|---|---|
| S08 | ROI / Region 视图：Top 30 算子不整图复制 | 20000² 剪 10% 区域，内存 <30MB |
| S09 | 内存预算 + 分块处理 | 20000² 出 512 缩略图，峰值 ≤512MB |
| S10 | `best_format` + 出口接入限额 | 12 张样本自动选格式，体积优于 PNG 默认 ≥30% |
| S11 | CLI 8 子命令：`info/convert/resize/crop/filter/analyze/sanitize/bench` | 支持 `--dry-run`、JSON 输出、stdin/stdout 管道 |
| S12 | npm-wasm（≤1.2MB gzip，codec+process 子集） | node 侧 3 行调用，示例可跑 |
| S13 | 16bit / float 覆盖收敛（不新增算子） | 未覆盖分支补到 90% |
| S14 | 区域解码（PNG/BMP/QOI） | 4096² 只解需要的 tile |
| S15 | 动画闭环（GIF/APNG 解码；APNG 编码） | 帧数与延迟可往返 |
| S16 | 场景包收敛为 4（`doc/media/commerce/photo`），其余并入 `image.pro` | 模块数 7→11（不是 15），发布链 11 环 |
| S17 | Dart / JS 绑定（经 wasm/导出，不另起实现） | Dart 侧跑通 decode→resize→encode |
| S18 | 覆盖率 90% + 变异测试 12 点 | 变异得分 ≥70% |
| S19 | 文档真值脚本化（能力表由 `.mbti` + 枚举生成） | 手写能力表全部替换，CI 校验 |
| S20 | 公开基准集（golden 20 张 + 6 类恶意样本） | 版权自查清单齐全，样本可分发 |
| S21 | 0.1.21 收口 + 迁移指南 + 弃用策略 | 从 0.1.x 早期版本迁移只需 3 处改动 |

## 7. 每个 Sprint 必过的门禁

```
moon check --deny-warn --target all      # 零警告
moon test --target native                # 4 目标全绿（native / wasm-gc / js / wasm）
moon fmt                                 # 无 diff
node scripts/check_version.mjs           # ok: true
moon bench --release --target native     # 相对上一 Sprint 退化 ≤8%（S01 后生效）
docs/performance.md 与 bench 输出一致    # 脚本核对
dogfood 记录 ≥1 条                       # 本 Sprint 真实用过
外部解码器验证                           # 任何编码器改动，产物必须被 ffmpeg/浏览器打开
```

分层门禁（吸收自分层迭代路线第六节，按层卡"表面完成"）：

| 层 | 门禁 | 不通过的表现 |
|---|---|---|
| L0 内核 | 三深度类型不丢 + 预算内不 OOM + 错误码全覆盖 | 大图 OOM、错误只有一个字串 |
| L1 编解码 | 18 格式 golden roundtrip + 恶意样本拒收 | 编出来打不开、恶意图拖垮进程 |
| L2 算子 | 三深度同测试 + 性能预算 + ROI 与整图一致 | 16bit 与 8bit 差一个量级 |
| L3 Recipe | 每 Recipe 有 golden 通过率 + 失败模式文档 | 只有 happy path 示例 |
| L4 出口 | CLI/MCP 各一条 e2e 脚本 + 示例可用 | 演示 404、报错不可读 |
| L5 生态 | 文档数字由脚本生成（diff 为空）+ 基准可复算 | README 数字与代码不一致 |

## 8. 不做清单（不排期，需重新决策才立项）

- **统一像素抽象重构**（三套算法 × 3 深度重写，≈90 人日，用户零感知）；
- **8 个场景包同时拆分**（与地基改造同期 = 同时改地基和上层）；
- **三/四个出口并行**（MCP 先行，其余串行）；
- 渐进式 JPEG、DICOM、GeoTIFF；
- SIMD / 多线程 / C FFI（与仓库红线冲突；要做先改红线再立项，不在本路线图内）；
- **AVIF / JXL 编码**（编码器工程量超过现有全部算法之和，保持"解码支持、编码不做"）；
- **GPU / H.264**；
- 场景包复制算法（L3 只能 `import image.process`，禁止 fork 一份 resize 进场景包）。

合规红线（吸收自分层迭代路线第七节，任一条都不因需求压力放开）：

- **人脸只做"检测 + 脱敏"**：不做身份识别、不做属性推断（年龄/性别/种族），接口一律命名 `redact`，不出现 `recognize`；
- **医学只做"查看与测量"**：不做诊断结论、不输出"疑似病灶"，避免医疗器械监管口径；
- **印刷先做 sRGB 预检**：不承诺完整 ICC/CMYK 引擎，ΔE 达标后才谈专业色彩；
- **golden 样本必须可分发**：带人脸/票据/证件的样本来路与授权要留档，做不到就不随包发布（S20 前置）。

## 9. 改路线的触发条件

- （已消耗，2026-11-25）S01 实测：JPEG 1.96 MP/s → 确认是瓶颈，S02 开工；PNG 21/13 MP/s → PNG 优化项删除；
- （已消耗，2026-11-25）WebP 产物经 ffmpeg 判定非法（`Invalid partitions`）→ 从可编码格式摘除，记 GAP-27，S02 只留 JPEG；
- dogfood 记录出现"某算子必须整图复制" → S08 提前；
- 下游 issue 集中在某个格式 → 该格式 Sprint 前移，后续顺延；
- 分层迭代路线的 P0 场景（#2 发票、#3 合同增强、#5 电商白底）出现真实下游需求 → 在 0.1.12 之后插入 Recipe Sprint，并同步评估 L1 PDF 容器成本；
- 连续两个 Sprint 未过门禁 → 停新增功能，先还技术债。

## 10. 与《分层迭代路线》的关系：吸收什么、砍什么

该文档的价值在**约束与判据**，不在排期。逐条落点如下。

| 该文档条目 | 结论 | 落点 |
|---|---|---|
| L0–L5 分层模型、职责边界、判定标准 | **吸收** | 第 3、7 节；作为架构约束，不新增 Sprint |
| Primitive / Recipe / Product 三层粒度 | **吸收** | 第 1 节诊断；解释"能力很强但用不上" |
| 分层门禁（每层卡表面完成） | **吸收** | 第 7 节门禁表 |
| 合规红线 5 条 | **吸收** | 第 8 节 |
| L0 零拷贝视图 `ImageView` / 内存预算 | 吸收 | S08 / S09（S04 先落限额接口） |
| L0 统一错误模型 + 稳定错误码 | 吸收 | S04 |
| L0 取消与进度 `CancellationToken` | 部分吸收 | 并入 S04 接口，不单独排期 |
| L0 统一像素抽象 `Plane`/`PixelFmt` | **砍** | 需重写 90 算子 × 3 深度 ≈90 人日；S13 只做覆盖收敛 |
| L1 区域解码 / tile | 吸收 | S14 |
| L1 解码限额、`best_format` | 吸收 | S04、S10 |
| L1 动画容器闭环 | 吸收 | S15 |
| L1 渐进式 JPEG | **砍** | 收益低于"JPEG 编码提速"，后者已实测为唯一瓶颈 |
| L2 SIMD / 多线程 / native 分支 | **砍** | 违反"纯 MoonBit、零 C 依赖、四目标同源"，且与本路线图第 8 节冲突 |
| L2 JPEG DCT 专项 | **升级为 P0** | S02（实测 1.96 MP/s） |
| L2 场景专属算子（去阴影/去摩尔纹/印章等） | 延后 | 由 dogfood 与下游 issue 触发，不进 0.1.x 前段 |
| L3 "一场景一包" 8 包 | **部分吸收**：收敛为 4 包 | S16（doc/media/commerce/photo，其余并入 `image.pro`） |
| L3 Recipe + golden + 失败模式文档 | 吸收 | 从 S06 起，每个 Recipe 交付都带这三件 |
| L4 Playground / CLI / WASM / HTTP / MCP / 绑定 | 吸收但**串行** | S05 MCP → S11 CLI → S12 npm → S17 绑定；HTTP 与 Playground 按需 |
| L4 10+ MCP 工具 | 收缩 | S05 先 6 个，schema 稳定后再加 |
| L5 公开基准集、能力真值表 | 吸收 | S19、S20 |
| L5 agentskills 联动 / gbz185 artifact 协议 | 记录为可选 | 0.1.17 之后按需，不进前段 |
| 30 场景优先级表（7 条 P0） | **收敛为 2 条** | #20 Agent 图像工具 → S05；#7 发布前脱敏 → S06；其余按触发条件排期 |
| 版本节奏 0.2.0/0.3.0/0.4.0/1.0 | **改号** | 统一为 0.1.x，见第 2 节 |
| 第八节"只推进 doc 一条线" | **否决** | 实测：PDF 容器无、版面解析/表格→CSV/字段抽取全无、去阴影无、印章检测无；OCR 有但为模板法无准确率证据。doc 是全路线里**最重**的一条，不是最轻的；入口瓶颈在速度与出口，不在场景数量 |

一句话：**吸收的是约束与判据，砍掉的是排期与拆分。** 三条硬理由：统一像素抽象 ≈90 人日；SIMD 违反仓库红线；8 包拆分与地基改造同期 = 同时改地基和上层。
