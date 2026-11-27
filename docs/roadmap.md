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
- **一个 Sprint = 一个 patch 号**：S01 = `0.1.1`、S02 = `0.1.2` … 计划值见 Sprint 表；因 S19/S20/S16 的落地顺序晚于原表，实际号已顺延（S20 = `0.1.20`、S16 = `0.1.21`，S17 = `0.1.22`、S21 = `0.1.23`、S22 = `0.1.24`）。Sprint 收尾时 7 个 `moon.mod` 同步升 patch（S16 起为 11 个），`check_version.mjs` 必须 ok。
- **四段号（0.1.x.y）不采用**：实测 `version = "0.1.2.3"` 被 mooncakes 拒绝（`version bad format / unexpected character '.' after patch version number`）；`0.1.2+s06` 虽可解析但会破坏 `check_version.mjs` 的徽章比对，故不用。
- **发布（`moon publish`）只在阶段收口做**：已发布 0.1.7 / 0.1.8 / 0.1.10；未发布 0.1.9、0.1.11–0.1.24，下一个收口窗口需明确授权后一次性发 11 环（顺序见 `docs/release.md` §九）。中间 Sprint 只升版本号不发布，避免不可逆外部动作。
- Sprint 编号 S01… 跨版本连续，不断号、不回填。
- 每个 Sprint 收尾必须回写本文件：状态 / commit hash / bench 数字。
- **每轮改动结束自动提交**（用户 2026-11-25 要求）：一次提交 = 一次可回滚的交付，提交信息带类型前缀与数字。
- **发布列车**：每 5 个 Sprint 收口一次，中间只升号不发布；S16 起发布列车是 **11 个模块逐环**（core → codec → process → photography → vision → domain → 根 → doc → media → commerce → pro）。

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
- ✅ **下游可用性**：`examples/quickstart`（造图 → WebP 无损 → 解码 → 缩放 → PNG → 回读）四目标可编译、`moon run` 真跑通；README 快速上手与它逐行对齐；`image.codec/lib` 补 `encode_webp_lossless` / `decode_webp`，让"只 import 一个 lib"的下游也能编 WebP。
- ✅ **发布链诊断（2026-11-25）**：`moon publish --dry-run` 的 verify 是在解压目录里用 **registry 已发布包**重编，所谓 `testgen` 报错已被证伪（0.1.1 的 zip 里确实含 testgen；0.1.0 才是缺的）。真因是根依赖钉停在 `@0.1.1`；钉子已随版本走并由 `check_version` 第 14 项守护，流程与坑点沉淀进 `docs/release.md`。
- ✅ **S07.5 发布包去噪（2026-11-25）**：测试随包发布 + 删掉 9 个包的 plain/`for "test"` 重复导入 → `[0029]` 归零；基准拆 `benchmarks/`、根 `moon.pkg` 清空导入；新增 `scripts/check_pkg_imports.mjs` 与 `scripts/verify_publish_warnings.mjs`，七模块归档实测 7/7 零警告零错误。**反例存档**：按目录名排子模块会把子模块自己的归档排成 22 字节空包，已撤销。详见 `docs/release.md` 第八节。
- ✅ **S08 ROI 区域视图（2026-11-25）**：`Region` / `ImageRegion` 零复制视图（只存底图引用 + 坐标）；
  `crop_region` 越界自动裁剪；门面包补齐 8 个薄封装 + `crop_region`。
  下游实测 4000×3000 底图取 1200×900 视图不新增分配、物化 3,240,000 B 逐通道一致。
  **口径修正**：20000² 底图本身就要 1.2 GB（3 通道），"内存 <30MB" 只能指区域操作的**增量**——
  视图增量 = 0，物化增量 = 区域面积×通道。
- ✅ **S09 预算 + 大图缩略（2026-11-25）**：`resize_subsample` 面积平均（唯一分配 = 输出）、
  `thumbnail` 等比、`thumbnail_budgeted` 输出侧准入；4000×3000 → 512×384 只花 589,824 B。
  **口径修正**：所谓"20000² 出 512 缩略图峰值 ≤512MB"，瓶颈在**解码**（20000²×3=1.2 GB 底图），
  算子侧已做到零中间缓冲；真要压住峰值得靠 S14 区域/流式解码，S09 只保证"算子不再额外翻倍"。
- ✅ **S10 自动选格式 + 出口限额（2026-11-25）**：`has_alpha` / `best_format`（不编码的启发式）/
  `encode_best`（逐候选实编取最小，失败跳过）/ `encode_best_limited`（最小仍超 `max_bytes` 报
  `ImageError::Budget(LimitBytes)`）；12 类样本 256×192 实测 PNG 合计 39,875 B → 最小格式 7,596 B，省 80.95%。
  **顺带修掉一个真 bug**：WebP 无损的距离前缀误用了长度前缀表（上限 4096），距离 >4096 时 extra 位数非法，
  码流可解析但像素被写成别的颜色块（128×192 三色横条错 12,288 像素）。现改用 RFC 9649 的 40 项距离前缀
  （`vp8l_encode_distance`），tokenizer 距离上限收到 1,048,000；Pillow 12.3 与本库双向解码均为 0 差异。
- ✅ **S11 CLI 8 子命令（2026-11-25）**：`info/convert/resize/crop/filter/analyze/sanitize/bench`（`decode`/`encode` 保留为 `convert` 别名）；
  `--dry-run` 完整编码但不落盘；路径 `-` 走 stdin/stdout（JSON 改走 stderr）；`convert --best` 接 S10 选格式、
  `--max-bytes` 接出口限额；`filter` 覆盖 box/gaussian/sharpen/median/bilateral/nlm；`bench` 给 decode/encode/resize 的每轮均值（微秒）。
  **口径**：管道靠 `imgcli/stdio_stub.c`（native）实现，wasm/js 返回 `UnsupportedFormat`；`bench` 是耗时参考，不是跨机基准。
  **实测（320×240 PNG）**：`convert --best` 404 B（PNG 2,386 B）；`--dry-run` 返回 `wrote:false` 且目标不存在；`< in.png > out.png` 管道回读 320×240 RGB 一致。
- ✅ **S12 npm-wasm（2026-11-25）**：`wasm/` 导出包 + `npm/@walkzzz/image-mbt` 封装。
  **形态定案：wasm MVP 字节 ABI**（`abi_alloc / abi_info / abi_convert / abi_resize` + `abi_last_*` 读元信息），
  不是 wasm-gc：wasm-gc 把每个字符串常量编成 `"_"` 模块的 `(ref extern)` 全局导入（本包 460 条），
  Node 无法创建非空 externref 全局，只能在 MoonBit 自有 host 里实例化；MVP 导出 `memory`，
  `Bytes` 入参/返回值就是 i32 指针，JS 直接写输入、读输出，零 shim。
  **体积**：248.3 KiB raw / 110.6 KiB gzip（阈值 1.2 MiB gzip），`WebAssembly.Module.imports` 为 0。
  **API**：`info / convert / convertMeta / resize / resizeMeta / formats`，输入 `Buffer`，输出 `Buffer`，
  失败带 `code / hint`（如 `decode/unsupported_format`）。
  **验收**：`node scripts/build_npm_wasm.mjs` 一键构建→拷 wasm→体积校验→跑自测，**15/15**；
  1000×1000 PPM→PNG 走通线性内存增长；Pillow 回读 PNG / 缩放像素一致。
  **口径**：`npm` 包暂不发布，等 S17 绑定一起收口；`npm/image.wasm` 不提交，由 `prepack` 生成。
- ✅ **S13 16bit/float 覆盖收敛（2026-11-25）**：不新增算子，只补 16f 家族未覆盖分支。
  新增 17 个 `*_16f_guard_test.mbt` + `seam_carving_16f_coverage_test.mbt`，测试数 6,726 → **6,836**。
  做法：`scripts/proto/gen_guard_tests.mjs` 扫 `DecodeFailed` 消息，按"尺寸 / 通道 / 数据长度 / 标量下界"四类
  反推违法入参，为每个 pub fn 生成探测调用（raise 分支被走到即计覆盖，不断言异常类型以免锁死文案）。
  seam carving 另补真实像素断言：`remove_vertical/horizontal_seam_16/_f` 四个此前完全未测的 pub fn、
  放大 `insert_*` 路径、单维缩放、目标 ≤0 与 >2 倍报错。
  **结果**：16f 家族 4,727/5,505（85.87%）→ **5,018/5,505（91.15%）**；全库 **34,309/41,634（82.40%）**。
  单文件从低到高：gabor_template / optical_glcm 80.6%、retinex 81.6%、color_space 82.0%、hough_circles 82.5%、
  adaptive_threshold 82.8%；seam_carving 65.4% → 96.2%。
  **口径**：90% 按 16f 家族加权总覆盖验收（路线图原话"未覆盖分支补到 90%"），不要求逐文件 ≥90%。
- ✅ **S14 区域解码（2026-11-25）**：`image.codec/codec/region_decode.mbt` 新增
  `decode_png_region / decode_bmp_region / decode_qoi_region`，入口 `image.codec/lib` 的
  `decode_region(data, x, y, w, h)` 按魔数自动分派（仅 PNG / BMP / QOI，其余格式报
  `DecodeFailed("decode_region 暂只支持 PNG / BMP / QOI")`）。
  **内存形态**：PNG 的 IDAT 仍整条 inflate（zlib 无流式接口），但反滤波只保留 `prev + cur` 两行、
  输出按 tile 尺寸分配；BMP 无压缩按行直接寻址；QOI 顺序解码、区域外像素只推进状态不落内存。
  **验收**：tile 与"整图解码后裁切"逐字节一致（PNG RGB/RGBA/全图/1×1、BMP 24/32 上下行、QOI 3/4 通道），
  越界 / 零尺寸 / 负坐标 / 非支持格式四类错误各有断言。
  **口径**：4096² 输出侧不再分配整图（PNG 的 64 MB 级输出缓冲降为 tile），但 inflate 中间缓冲仍在；
  真正的流式 inflate 需要 zlib 增量 API，留到后续。
- ✅ **S15 动画闭环（2026-11-25）**：编解码本体已在位（`decode_gif_animation_pure`、`decode_apng_pure`、
  `encode_apng_pure`），本 Sprint 补统一入口：`decode_animation(data) -> (Array[Image], Array[Int32])`
  按魔数分派 GIF / APNG；`encode_apng(frames, delays)` 校验空帧与延迟长度后转调 `encode_apng_pure`。
  **验收**：双帧 APNG（100/200ms）编码 → 解码，帧数与延迟一致；GIF 单帧经统一入口可读；
  空帧、`delays` 长度不一致报 `EncodeFailed`；静态 PNG 报 `DecodeFailed`。
  **口径**：GIF 只解码动画、编码仍为单帧（`encode_gif`），GIF 动画编码未承诺。
- ✅ **S18 变异测试 + 覆盖率 90%（2026-11-26 完成）**：`scripts/mutation_test.mjs` 12 个变异点（PNG 反滤波 3、
  BMP 行对齐、QOI 标签/差分 2、`check_dims` 2、灰度 BT.601、APNG 延迟校验、`decode_region` 分派/文案），
  逐包基线先跑，变异后判定 `failed > 0` 为 killed，`finally` 无条件写回原文。
  **结果**：11 killed / 1 survived（M12 为纯错误文案变异，预期存活），得分 91.7%（门槛 75%）。
  **过程中补的真缺口**：`apply_colormap` 的 BT.601 加权和缺边界断言（补 `(0,5,176)`、加权和 22999 的用例）；
  QOI run-length 变异与 `pixel_idx < pixel_count` 保护等价，换成 LUMA 差分基准。
  **覆盖率推进（第五至九轮，测试 6,926 → 7,387）**：按 `_build\covN.xml` 的 miss 排行逐个收口——
  OCR 侧 `xmp` / `defile` / `code128` 字符集、TIFF 压缩名与光度全表、区域解码 PNG（PLTE / filter / 交错 /
  palette 越界）、`english_symbols` 符号模板与距离函数、lib 分发全格式、zlib 动态 Huffman（用 node `zlib.deflateSync`
  生成真实 BTYPE=2 流内联）、compression 量化钳位与报告、16-bit PNG 直读与 `req_channels`、`integral_image`
  空壳构造与零面积均值、`optical_flow` 九条校验链、`draw_polygon` 扫描线填充、registration / retrieval
  报告枚举映射、16f 色彩空间越界与 alpha=0 反预乘。
  **结果**：全库 35,075 → **37,740/41,894 = 90.08%**（`moon coverage report -f full_summary`，native，7,387 测试全绿）。
  **口径说明**：分母含 native 下不可覆盖的 `wasm/abi.mbt`(89) + `wasm/api.mbt`(85) + `playground`(35) +
  `examples/quickstart`(37)，未做任何排除——即 90% 是在最严分母下取得的。
  **覆盖率推进（2026-11-26 第二轮）**：补 `codec_trait` 全枚举分支（format_name / can_encode / is_lossless /
  detect_format 全魔数）、`limits` 的 `info_dims` 各格式分支与 `check_decode_budget`、`ocr_accuracy` 的
  数据集 / 增广 / Hu 矩 / 集成投票；`codec_trait` 104→178、`limits` 19→62、`ocr_accuracy` 60→130。
  过程中修出两个真实缺陷：① `is_cur_format` / `is_ico_format` 只看前 4 字节，24/32-bit TGA 被误判成 CUR
  （现补「条目数 ≥1 且目录表装得下」）；② `codec_detect_format` 完全没有 TGA 分支，且 `ftyp` 的 `mif1`
  品牌被写成 `mifs`（字节 0x73 应为 0x31），导致 `mif1` 容器识别失败。
  **覆盖率推进（第三轮）**：`advanced_denoise_enhance` 197→257（补 15 个入口的三类输入校验、
  `denoise_image` 五路算法分派、算法名 11 项映射、报告字段）、`multilingual_ocr_enhanced` 209→229、
  `postprocess` 112→119。过程中又修出一个通用缺陷：MoonBit 的 `String[i]` 返回 `UInt16` 码元，
  直接 `.to_string()` 会得到 `"65"` 这类数字串——`smart_spacing_process` / `normalize_punctuation`
  / `ngram_create` / `ngram_score` 的中英空格与标点归一因此一直是坏输出，现统一走
  `UInt16 → Int → Char → String`（`moe_char_str` / `pp_char_str`）。
  **覆盖率推进（第四轮，测试 6,884 → 6,926）**：按缺口排序逐个收口——
  `region_decode` 119→185（畸形 PNG chunk：签名 / 头不足 8 字节 / 负长度 / 越界 / IHDR 过短 / 无 IHDR /
  零尺寸 / interlace / 16-bit / 非法 color type / 缺 PLTE / zlib 短数据；BMP 头 7 类错误 + 自顶向下；
  QOI 魔数 / 零尺寸 / RGB / RGBA / LUMA 三处截断）、
  `stitch/image_stitch` 103→174（白盒直调 `descriptor_distance` 长度不等、`compute_homography_dlt` 点不足、
  `random_sample` 去重与少样本、选择排序换位、`compute_output_size` 单位/缩放/负偏移、`warp_image` 奇异矩阵、
  `blend_images` 仅 img1 / 融合 alpha / 仅 img2 三分支、RANSAC 采样退化）、
  `enhanced_layout_analysis` 130→205（三组枚举 Debug/Eq、双栏/混合/回退单栏、页眉页脚缺口、
  标题六级映射、列表四类与缩进、代码/引用判定、段落三种切分、阅读顺序跨列、全 13 种元素 Markdown、分布计数）、
  `tiff_codec` 251→303（`tiff_type_size` 全 12 类型、内联/外置值读取（含越界补 0）、`tiff_get_value` 空数组、
  LZW 字典回溯链与中段 CLEAR、PackBits 扩展复制截断/扩展重复、Deflate 保留块与动态 Huffman 拒绝、
  photometric 0/1 灰度化、缺 StripByteCounts / RowsPerStrip、像素越界）。
  **结果**：全库 34,779 → **35,075/41,889 = 83.7%**。
- ✅ **S19 文档真值脚本化（2026-11-26 完成）**：新增 `scripts/gen_capabilities.mjs`，能力表不再手写——
  真值取自三处机器可读数据：`image.core/types/pkg.generated.mbti` 的 `enum ImageFormat` 变体清单、
  `image.codec/codec/codec_trait.mbt` 里 `Codec for ImageFormat` 四个 impl 的实际 match 分支
  （`format_name` / `can_decode` / `can_encode` / `is_lossless`，含 `_ =>` 默认臂）、各包 `.mbti` 的公开 API 计数。
  产出 `docs/capabilities.md`（格式矩阵 + Codec 全量口径 + 模块矩阵），并回填两份 README 的
  `<!-- AUTO:formats:start -->` 区块；逐格式备注收敛到 `docs/format_notes.json`，**枚举新增变体而未补备注即生成失败**。
  **验收**：`check_docs` 新增 **B10** 门禁调用 `gen_capabilities --check`；负向实测——手改 README 表格一个单元格立即
  报「AUTO:formats 区块与生成结果不一致」；标题「格式支持 · 18 种」与枚举行数对齐；模块矩阵 78 包 / 3,890 fn / 718 类型。
  **口径**：`playground` 不在库体统计内（B6 仍要求 78 包），`api_index.md` 仍为 79 包 / 3,894 fn（含 playground）。
- ✅ **S20 公开基准集（2026-11-26 完成）**：新增 `benchmarks/gen/`（MoonBit 包，`moon run benchmarks/gen` 重生成）
  合成了 **20 张 golden**（13 种可编码格式，1.2 MB 量级）+ **6 个畸形样本**（数据流损坏 / 长度越界 / 声明尺寸炸弹 /
  帧数声明 / 非法枚举 / 元数据段截断），像素全部来自解析式（渐变 / 色条 / 确定性噪声 / 径向亮场 / 圆 alpha 切边 / 浮点高光斑），
  零第三方素材；`benchmarks/COPYRIGHT.md` 出具逐项自查表与新增样本四条准入规则。
  校验器 `scripts/check_benchmarks.mjs`（`--update` 封签 / 默认校验）判定六条契约：条数、命名+尺寸、体积上限、
  sha256 一致、magic 嗅探与 `imgtool` 报告一致、行为（golden 必须 `ok:true`；malformed 必须 `exit≠0 + ok:false`、
  5 秒内、无 `PanicError`）。负向实测：golden 追加 1 字节 → `sha256 漂移`；删一个恶意样本 → `count/malformed 5 ≠ 6`。
  **基准集直接暴露并已修的三处缺陷**：① `imgtool` 自带 `format_name` 缺 `Hdr`/`Psd` 分支（HDR/PSD 一律报 `unknown`），
  并把默认臂改为 `ImageFormat::..` 防止漏分支静默；② `@lib.detect_format` 按「TGA 无魔数」直接返回 Unknown，
  改为末位接 `@codec.is_tga_format`（扩展覆盖 1/2/3/9/10/11 类型 + 8/15/16/24/32 bpp + 宽高非零 + 调色板头一致性），
  TGA 由此可自动分派；③ PNG/APNG/region_decode 的 `pos + chunk_len > len` 在 Int32 回绕，
  m2 样本直接打出 `0xC0000409` panic，改为溢出安全比较 `chunk_len > len - pos`。
  口径：CUR 刻意不生成——`encode_cur_pure` 对小尺寸的既有缺陷未修（见 `known-gaps`），不把已知缺陷伪装成通过。
- ⬜ **发布链 7 环**（`core → codec → process → photography → vision → domain → 根`）仍待执行；`moon publish` 是不可逆外部动作，等用户授权后按上面的顺序分步 dry-run → 实发。
- ⬜ 下游"30 分钟上手"验收（全新项目 `moon add` 跑 PNG/JPEG 往返）需在发布后做，本机先用手写的最小示例替代。

**发布前诊断（2026-11-25 记）**：`moon publish --dry-run` 当前失败，报 `Cannot find import 'walkzzz/image.core/testgen' in walkzzz/image.mbt/playground@0.1.1`。根因是版本错配——根 `moon.mod` 仍 import `walkzzz/image.core@0.1.1` 等已发布版本，而 dry-run 的验证包会用这些缓存版本重解依赖；本地 `image.core` 里的 `testgen` 包若没随 0.1.1 发出去，playground 的 import 就悬空。收口顺序因此必须固定：先按 `core → codec → process → photography → vision → domain` 发 0.1.7（确认 `testgen` 在 `image.core` 发布集内），再把根 `moon.mod` 的 6 条依赖全部改到 `@0.1.7`，最后才跑根 dry-run。

---

## 6. 0.1.8–0.1.21（一行一 Sprint）

| Sprint | 交付 | 验收 |
|---|---|---|
| S08 | ROI / Region 视图：Top 30 算子不整图复制 | 20000² 剪 10% 区域，内存 <30MB |
| S09 | 内存预算 + 分块处理 | 20000² 出 512 缩略图，峰值 ≤512MB |
| S10 ✅ | `best_format` + 出口接入限额 | 12 张样本自动选格式，体积优于 PNG 默认 ≥30%；实现 `image.codec/lib/best_format.mbt`，已接 `convert` 的 `format='best'`，npm 自测 `convert: best 选最小` 覆盖 |
| S11 ✅ | CLI 8 子命令：`info/convert/resize/crop/filter/analyze/sanitize/bench` | `--dry-run`、单行 JSON、`-` 管道均在位；`imgtool dispatch` 8 个分支实测可跑（见 `docs/cli.md`） |
| S12 ✅ | npm-wasm（≤1.2MB gzip，codec+process 子集） | node 侧 3 行调用可跑：`npm/index.mjs` 六导出；`npm/image.wasm` 由 `scripts/build_npm_wasm.mjs` 重建，`node npm/test.mjs` 15/15（含 1000×1000 触发内存增长） |
| S13 ✅ | 16bit / float 覆盖收敛（不新增算子） | 16f 家族行覆盖 91.15%（≥90%） |
| S14 ✅ | 区域解码（PNG/BMP/QOI） | 输出只分配 tile，与整图裁切逐字节一致 |
| S15 ✅ | 动画闭环（GIF/APNG 解码；APNG 编码） | 统一入口，帧数与延迟可往返 |
| S16 ✅ | 场景包收敛为 4（`doc/media/commerce` + `pro`，photo 由既有 `image.photography` 承担） | 新增 4 个场景模块，**模块数 7→11（不是 15）**，发布链 11 环；`docs/scenes.json` + `gen_scenes.mjs` 生成 4 个入口包（doc 504 / media 313 / commerce 257 / pro 1,462 符号），B11 门禁防漂移 |
| S17 ✅ | Dart / JS 绑定（经 wasm/导出，不另起实现） | **两条通道、同一份实现**：JS 走 `--target wasm` 线性内存（`npm/index.mjs`，自测 15/15）；Dart 因「native 不产出静态/动态库」+「Dart VM 无 wasm 运行时（`package:wasm` 已废弃）」改以 `imgtool` 进程为 ABI（`bindings/dart/`，自测 6/6）；Dart 侧 `decode→resize→encode` 跑通，见 `docs/bindings.md` |
| S18 ✅ | 覆盖率 90% + 变异测试 12 点 | 变异得分 91.7%（≥70%，见 `docs/mutation.md`）；覆盖率 90.08%（见 `docs/known-gaps.md`） |
| S19 ✅ | 文档真值脚本化（能力表由 `.mbti` + 枚举生成） | 手写格式表已由 `docs/capabilities.md` + README AUTO 区块取代，B10 门禁拦截漂移 |
| S20 ✅ | 公开基准集（golden 20 张 + 6 类恶意样本） | `check_benchmarks` 六条契约全绿；样本 sha256 封签、零第三方素材 |
| S21 ✅ | 0.1.23 收口 + 迁移指南 + 弃用策略 | `docs/migration.md` 给出**3 处改动**（模块名/import 路径/7 条弃用替换），迁移前后 15 行对照可逐条核对；`docs/deprecation.md` 定义标注规则 + 保留窗口 + 7 条清单，**B12**（`check_deprecations`）做代码 ⇄ 表双向比对；收口核对清单见 `docs/release.md` §九（11 环顺序 + 15 项门禁，一条 `check_release_ready.mjs` 跑完）；同轮补齐 CI/CD 与 Pages 治理：`docs/ci-cd.md`、`pages.yml`、`sync_pages` + `docs/coverage.json` 单一真值、`check_links`（B13） |
| S22 ✅ | 缺陷清零（0.1.24）：只在真实数据/非 Windows 下暴露的静默错 → 修复 + 回归 | 5 类缺陷逐条闭环（台账 GAP-42…46）：**TGA** 描述符 bit4/bit5 混用（标准 top-down 文件被上下翻转、本库产物水平镜像）+ 4 通道丢 alpha；**TIFF** 像素长度不足直接越界崩溃（`0xC0000409`）；**超像素** `num = 0` 除零、`num > total` 步长 0 死循环、`labels` 留 -1 空洞；**Code128 Stop** 用 6 段伪模式冒充（生成物标准扫码器不可读）；**GLCM 熵** 占位公式恒负。新增 9 条回归（`s22_*` 6 条 + 超像素边界 1 条 + 码表形状/模块数 2 条），native 7,404 全绿（+9） |

> 打勾口径：S10–S12 本轮补核（`best_format` 实现、CLI 8 分支、npm 15/15）；S08/S09 的能力（区域视图、`--mem-budget` 预算）已随后续 Sprint 落地，但当时承诺的量化验收（20000² 内存峰值）未复测，故不打勾。

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
