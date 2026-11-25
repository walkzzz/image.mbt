# image.mbt 远期路线图（Sprint 级）

> 目标只有两条：**下游开发者能装上、跑通、看得懂错误；我自己在日常项目里真的会用。**
> 制定：2026-11-25 | 版本轨道：0.1.x（一个 Sprint 一个 patch） | Sprint 编号：S01 起连续
> 历史（v0.1 起的功能迭代流水、mermaid 甘特图）：[roadmap-history.md](roadmap-history.md)

## 0. 战略一句话

先证明"能用"，再证明"好用"，最后才谈"更多"。

现状是 90 个算子、6664 个测试、70 个包、83.4% 覆盖率 —— 但没有一份可复算的速度数字，没有一个给非 MoonBit 用户的出口，没有能放进服务的错误码与资源限额。0.1.1–0.1.6 只补这三件事，一个新算法都不加。

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
本仓库现状：90% 场景只做到 Primitive，所以"能力很强但用不上"。这就是 S04（出口）与 S05（Recipe）必须排在 0.1.6 之前的理由。

## 2. 版本与编号规则

- 唯一版本轨道是 **0.1.x**：三段 SemVer，`major.minor` 钉死在 `0.1`，只递增 patch。功能版本 v5.x 停止累加，只作历史。
- **一个 Sprint = 一个 patch 号**：S01 = `0.1.1`、S02 = `0.1.2` … S20 = `0.1.20`。Sprint 收尾时 7 个 `moon.mod` 同步升 patch，`check_version.mjs` 必须 ok。
- **四段号（0.1.x.y）不采用**：实测 `version = "0.1.2.3"` 被 mooncakes 拒绝（`version bad format / unexpected character '.' after patch version number`）；`0.1.2+s06` 虽可解析但会破坏 `check_version.mjs` 的徽章比对，故不用。
- **发布（`moon publish`）只在阶段收口做**：S06 → 0.1.6、S11 → 0.1.11、S16 → 0.1.16、S20 → 0.1.20。中间 Sprint 只升版本号不发布，避免 20 次不可逆外部动作。
- Sprint 编号 S01… 跨版本连续，不断号、不回填。
- 每个 Sprint 收尾必须回写本文件：状态 / commit hash / bench 数字。
- **每轮改动结束自动提交**（用户 2026-11-25 要求）：一次提交 = 一次可回滚的交付，提交信息带类型前缀与数字。
- **发布列车**：每 5 个 Sprint 收口一次（0.1.6 / 0.1.11 / 0.1.16 / 0.1.20），中间只升号不发布。

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
| **0.1.1–0.1.6** | **能用** | S01–S06 | 陌生人照 README 30 分钟出图；坏图不崩；有 1 个出口；我自己已在用 |
| **0.1.7–0.1.11** | **工程可用** | S07–S11 | 能放进服务/批处理；20000² 出缩略图 ≤512MB；CI 有性能门禁 |
| **0.1.12–0.1.16** | 专业纵深 | S12–S16 | 16bit/动画/区域解码补齐；场景包收敛为 4 个 |
| **0.1.17–0.1.20** | 可承诺 | S17–S20 | 覆盖率 90%；版本与文档零漂移；外部可复算基准 |

---

## 5. 0.1.1–0.1.6 Sprint 卡（能用阶段）

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

**状态**：**已完成（2026-11-25，commit `8fbee28e`）** —— `bench_real.mbt` 现 12 项全绿（PNG 6 + JPEG/WebP/BMP/QOI/GIF 6），`docs/performance.md` 已建，旧报告已归档，README 三处已改。剩余待办只有"发布 0.1.1 后同步徽章"，归入 S06。

---

### S02 JPEG 提速（1–2 周）

**目标**：S01 已测出 JPEG 是唯一真瓶颈（编 1.96 MP/s / 解 2.12 MP/s，12MP 编 6.4s），把它提到可用区间。

**前置核查已完成（2026-11-25）**：WebP 的 3.16 ms 是假象 —— 产物非法。ffmpeg 对 64² 与 1024² 均报 `Invalid partitions`；根因是只写了 frame tag + start code + 宽高，缺 first partition 的分段/滤波/量化/概率更新与 token partition 尺寸表，`first_part_size` 被写成整个 token 流长度。已转 correctness issue（`docs/known-gaps.md` GAP-27），README / notes / 源码注释的能力宣称已修正。

**交付**
1. **JPEG 编码**：AAN 整数 DCT、量化表与 Huffman 表预计算、去除每 8×8 块分配、位写缓冲区合并。
2. **JPEG 解码**：IDCT 加速、Huffman 查表化、YCbCr→RGB 整数化、去逐像素分配。
3. **WebP 编码路线评估（只评估不实现，≤0.5 人日）**：给出"实现合法 VP8L 编码器"的工时估算（复用现有 VP8L 解码器的 Huffman 结构），决定排到 S14 还是彻底不做。

**验收**
- `jpeg_encode_1024` ≥ 8 MP/s（12MP ≤1.5s），`jpeg_decode_1024` ≥ 8 MP/s；
- 1024²/128² roundtrip 与 S01 位流逐字节可比对（Q=75/90 两档），像素差 ≤1；
- 产物被 ffmpeg 与系统看图器正常打开（**本次教训：任何编码器交付必须过外部解码器**）；
- 6664 测试全绿，`moon check --deny-warn --target all` 零警告。

**风险**：动熵编码最易出边界 bug → 先固化 Q=75/Q=90 的 golden 位流（S01 数据），任何字节差异都要解释；Windows 计时抖动 → 取连续 3 次中位数。

---

### S03 错误模型与资源限额（1 周）

**目标**：能放进服务 —— 坏图不 panic、不 OOM。

**交付**
- `ImageError` 枚举：`Decode / Encode / Process / Budget / Cancelled` + 稳定 `code` 字符串；
- `DecodeLimits{ max_pixels, max_bytes, max_ms }`、`AllocBudget`；
- 错误码 → 建议动作映射表（文档 + `error_hint(code)`）。

**验收**
- ≥20 条错误码断言；
- 构造 100MB 恶意 PNG、截断 JPEG、超大尺寸头 → 全部拒绝，内存峰值低于预算；
- 错误码在出口（S04）原样透传。

**风险**：改错误签名会碰 70 个包 → 一次性适配提交，`moon check --deny-warn --target all` 必须零警告。

---

### S04 一个出口（1 周）

**目标**：非 MoonBit 用户（包括 agent）能调。

**交付**：MCP server，6 个工具起步：`decode / encode / resize / crop / analyze / sanitize`；JSON Schema + 结构化错误；一条 stdio 启动命令。

**验收**：20 条脚本化用例 ≥95% 通过；启动 ≤1s；失败返回 `{code, message, hint}`；`--mem-budget` 生效。

**风险**：工具一次上太多 → 先 6 个，schema 稳定后再加。**npm-wasm 出口推到 S11，不同时做两个出口。**

---

### S05 sanitize Recipe（1 周）

**目标**：第一个"一次调用解决一件事"，也是我自己最常用的功能。

**交付**：`sanitize(bytes, policy)` = 剥离 EXIF/GPS/ICC/缩略图 + 已知区域打码；`examples/sanitize`。

**验收**：200 张样本脱敏后元数据 0 残留；打码区域复核无残留；文档给出 policy 三档（严格/常规/仅元数据）。

**风险**：人脸检测召回不足 → 只承诺"redact 已知区域 + 可选保守全图模糊"，**不承诺检测到所有脸**。

---

### S06 dogfood 收口 + 发布 0.1.6（1 周）

**交付**
1. 自家 CAD/GIS 或批处理脚本接一次，记录 ≥5 条 friction → issue；
2. 按 `core → codec → process → photography → vision → domain → 根` 顺序发 7 个包；
3. README / 徽章 / 演示站同步。

**验收**：全新项目 `moon add` 后 30 分钟跑出 PNG/JPEG 往返；根 `moon publish --dry-run` 通过；dogfood 记录入库。

**风险**：发布链 7 环不可逆 → 先分步 dry-run（注意 `scripts/publish.sh --dry-run` 全链会在 codec 处失败，属 dry-run 语义所限，不是脚本 bug）。

---

## 6. 0.1.7–0.1.20（一行一 Sprint）

| Sprint | 交付 | 验收 |
|---|---|---|
| S07 | ROI / Region 视图：Top 30 算子不整图复制 | 20000² 剪 10% 区域，内存 <30MB |
| S08 | 内存预算 + 分块处理 | 20000² 出 512 缩略图，峰值 ≤512MB |
| S09 | `best_format` + 出口接入限额 | 12 张样本自动选格式，体积优于 PNG 默认 ≥30% |
| S10 | CLI 8 子命令：`info/convert/resize/crop/filter/analyze/sanitize/bench` | 支持 `--dry-run`、JSON 输出、stdin/stdout 管道 |
| S11 | npm-wasm（≤1.2MB gzip，codec+process 子集） | node 侧 3 行调用，示例可跑 |
| S12 | 16bit / float 覆盖收敛（不新增算子） | 未覆盖分支补到 90% |
| S13 | 区域解码（PNG/BMP/QOI） | 4096² 只解需要的 tile |
| S14 | 动画闭环（GIF/APNG 解码；APNG 编码） | 帧数与延迟可往返 |
| S15 | 场景包收敛为 4（`doc/media/commerce/photo`），其余并入 `image.pro` | 模块数 7→11（不是 15），发布链 11 环 |
| S16 | Dart / JS 绑定（经 wasm/导出，不另起实现） | Dart 侧跑通 decode→resize→encode |
| S17 | 覆盖率 90% + 变异测试 12 点 | 变异得分 ≥70% |
| S18 | 文档真值脚本化（能力表由 `.mbti` + 枚举生成） | 手写能力表全部替换，CI 校验 |
| S19 | 公开基准集（golden 20 张 + 6 类恶意样本） | 版权自查清单齐全，样本可分发 |
| S20 | 0.1.20 收口 + 迁移指南 + 弃用策略 | 从 0.1.x 早期版本迁移只需 3 处改动 |

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
- **golden 样本必须可分发**：带人脸/票据/证件的样本来路与授权要留档，做不到就不随包发布（S19 前置）。

## 9. 改路线的触发条件

- （已消耗，2026-11-25）S01 实测：JPEG 1.96 MP/s → 确认是瓶颈，S02 开工；PNG 21/13 MP/s → PNG 优化项删除；
- （已消耗，2026-11-25）WebP 产物经 ffmpeg 判定非法（`Invalid partitions`）→ 从可编码格式摘除，记 GAP-27，S02 只留 JPEG；
- dogfood 记录出现"某算子必须整图复制" → S07 提前；
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
| L0 零拷贝视图 `ImageView` / 内存预算 | 吸收 | S07 / S08（S03 先落限额接口） |
| L0 统一错误模型 + 稳定错误码 | 吸收 | S03 |
| L0 取消与进度 `CancellationToken` | 部分吸收 | 并入 S03 接口，不单独排期 |
| L0 统一像素抽象 `Plane`/`PixelFmt` | **砍** | 需重写 90 算子 × 3 深度 ≈90 人日；S12 只做覆盖收敛 |
| L1 区域解码 / tile | 吸收 | S13 |
| L1 解码限额、`best_format` | 吸收 | S03、S09 |
| L1 动画容器闭环 | 吸收 | S14 |
| L1 渐进式 JPEG | **砍** | 收益低于"JPEG 编码提速"，后者已实测为唯一瓶颈 |
| L2 SIMD / 多线程 / native 分支 | **砍** | 违反"纯 MoonBit、零 C 依赖、四目标同源"，且与本路线图第 8 节冲突 |
| L2 JPEG DCT 专项 | **升级为 P0** | S02（实测 1.96 MP/s） |
| L2 场景专属算子（去阴影/去摩尔纹/印章等） | 延后 | 由 dogfood 与下游 issue 触发，不进 0.1.x 前段 |
| L3 "一场景一包" 8 包 | **部分吸收**：收敛为 4 包 | S15（doc/media/commerce/photo，其余并入 `image.pro`） |
| L3 Recipe + golden + 失败模式文档 | 吸收 | 从 S05 起，每个 Recipe 交付都带这三件 |
| L4 Playground / CLI / WASM / HTTP / MCP / 绑定 | 吸收但**串行** | S04 MCP → S10 CLI → S11 npm → S16 绑定；HTTP 与 Playground 按需 |
| L4 10+ MCP 工具 | 收缩 | S04 先 6 个，schema 稳定后再加 |
| L5 公开基准集、能力真值表 | 吸收 | S18、S19 |
| L5 agentskills 联动 / gbz185 artifact 协议 | 记录为可选 | 0.1.17 之后按需，不进前段 |
| 30 场景优先级表（7 条 P0） | **收敛为 2 条** | #20 Agent 图像工具 → S04；#7 发布前脱敏 → S05；其余按触发条件排期 |
| 版本节奏 0.2.0/0.3.0/0.4.0/1.0 | **改号** | 统一为 0.1.x，见第 2 节 |
| 第八节"只推进 doc 一条线" | **否决** | 实测：PDF 容器无、版面解析/表格→CSV/字段抽取全无、去阴影无、印章检测无；OCR 有但为模板法无准确率证据。doc 是全路线里**最重**的一条，不是最轻的；入口瓶颈在速度与出口，不在场景数量 |

一句话：**吸收的是约束与判据，砍掉的是排期与拆分。** 三条硬理由：统一像素抽象 ≈90 人日；SIMD 违反仓库红线；8 包拆分与地基改造同期 = 同时改地基和上层。
