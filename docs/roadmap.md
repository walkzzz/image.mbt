# image.mbt 远期路线图（Sprint 级）

> 目标只有两条：**下游开发者能装上、跑通、看得懂错误；我自己在日常项目里真的会用。**
> 制定：2026-11-25 | 版本轨道：包 SemVer（0.2.0 / 0.3.0 / 0.4.0 / 1.0） | Sprint 编号：S01 起连续
> 历史（v0.1 起的功能迭代流水、mermaid 甘特图）：[roadmap-history.md](roadmap-history.md)

## 0. 战略一句话

先证明"能用"，再证明"好用"，最后才谈"更多"。

现状是 90 个算子、6664 个测试、70 个包、83.4% 覆盖率 —— 但没有一份可复算的速度数字，没有一个给非 MoonBit 用户的出口，没有能放进服务的错误码与资源限额。0.2.0 只补这三件事，一个新算法都不加。

## 1. 判据（每个 Sprint 的交付必须同时满足）

| # | 判据 | 可核查形式 |
|---|---|---|
| 1 | **装得上** | 新项目 `moon add walkzzz/image.mbt` 后 5 分钟内出图；registry 版本 = README 徽章 = 演示可用 |
| 2 | **跑得动** | 1MP 级编解码在 release 下 ≤100ms 量级；20000² 图不 OOM |
| 3 | **错得清楚** | 失败返回稳定错误码 + 建议动作，不是 panic、不是空返回 |
| 4 | **我自己在用** | 每个 Sprint 至少 1 条真实使用记录（dogfood），无记录视为未完成 |

产能假设：单人，**1 Sprint = 5 人日**。Sprint 超载时**砍交付物，不改日期**；一个 Sprint 只允许一个主目标。

## 2. 版本与编号规则

- 唯一版本轨道是**包 SemVer**。功能版本 v5.x 停止累加，只作历史。
- Sprint 编号 S01… 跨版本连续，不断号、不回填。
- 每个 Sprint 收尾必须回写本文件：状态 / commit hash / bench 数字。
- **每轮改动结束自动提交**（用户 2026-11-25 要求）：一次提交 = 一次可回滚的交付，提交信息带类型前缀与数字。
- 发布列车：**0.2.0 = S01–S06**，**0.3.0 = S07–S11**，**0.4.0 = S12–S16**，**1.0 = S17–S20**。

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
| WebP | 编码产物合法性未验证 |

## 4. 阶段地图

| 版本 | 主题 | Sprint | 成败判定 |
|---|---|---|---|
| 0.2.0 | **能用** | S01–S06 | 陌生人照 README 30 分钟出图；坏图不崩；有 1 个出口；我自己已在用 |
| 0.3.0 | **工程可用** | S07–S11 | 能放进服务/批处理；20000² 出缩略图 ≤512MB；CI 有性能门禁 |
| 0.4.0 | 专业纵深 | S12–S16 | 16bit/动画/区域解码补齐；场景包收敛为 4 个 |
| 1.0 | 可承诺 | S17–S20 | 覆盖率 90%；版本与文档零漂移；外部可复算基准 |

---

## 5. 0.2.0 Sprint 卡

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

### S02 JPEG 提速 + WebP 合法性核查（1–2 周）

**目标**：S01 已测出 JPEG 是唯一真瓶颈（编 1.96 MP/s / 解 2.12 MP/s，12MP 编 6.4s）。把它提到可用区间，同时查清 WebP 那 3.16ms 是不是假象。

**交付**
1. **前置核查（P0）**：`encode_webp_lossy_pure` 产物用外部解码器（浏览器 / libwebp）打开；再用位流结构检查 RIFF/frame header。若产物非法 → 转为 correctness issue，WebP 从能力清单摘除，不进性能优化。
2. **JPEG 编码**：AAN 整数 DCT、量化表与 Huffman 表预计算、去除每 8×8 块分配、位写缓冲区合并。
3. **JPEG 解码**：IDCT 加速、Huffman 查表化、YCbCr→RGB 整数化、去逐像素分配。

**验收**
- `jpeg_encode_1024` ≥ 8 MP/s（12MP ≤1.5s），`jpeg_decode_1024` ≥ 8 MP/s；
- 1024²/128² roundtrip 与 S01 位流逐字节可比对（Q=75/90 两档），像素差 ≤1；
- 产物被浏览器与系统看图器正常打开；
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

### S06 dogfood 收口 + 0.2.0 发布（1 周）

**交付**
1. 自家 CAD/GIS 或批处理脚本接一次，记录 ≥5 条 friction → issue；
2. 按 `core → codec → process → photography → vision → domain → 根` 顺序发 7 个包；
3. README / 徽章 / 演示站同步。

**验收**：全新项目 `moon add` 后 30 分钟跑出 PNG/JPEG 往返；根 `moon publish --dry-run` 通过；dogfood 记录入库。

**风险**：发布链 7 环不可逆 → 先分步 dry-run（注意 `scripts/publish.sh --dry-run` 全链会在 codec 处失败，属 dry-run 语义所限，不是脚本 bug）。

---

## 6. 0.3.0 / 0.4.0 / 1.0（一行一 Sprint）

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
| S20 | 1.0 冻结 + 迁移指南 + 弃用策略 | 从 0.1.x 迁移只需 3 处改动 |

## 7. 每个 Sprint 必过的门禁

```
moon check --deny-warn --target all      # 零警告
moon test --target native                # 4 目标全绿（native / wasm-gc / js / wasm）
moon fmt                                 # 无 diff
node scripts/check_version.mjs           # ok: true
moon bench --release --target native     # 相对上一 Sprint 退化 ≤8%（S01 后生效）
docs/performance.md 与 bench 输出一致    # 脚本核对
dogfood 记录 ≥1 条                       # 本 Sprint 真实用过
```

## 8. 不做清单（不排期，需重新决策才立项）

- **统一像素抽象重构**（三套算法 × 3 深度重写，≈90 人日，用户零感知）；
- **8 个场景包同时拆分**（与地基改造同期 = 同时改地基和上层）；
- **三/四个出口并行**（MCP 先行，其余按需）；
- 渐进式 JPEG、AVIF 编码、DICOM、GeoTIFF；
- SIMD / 多线程 / C FFI（与仓库红线冲突；要做先改红线再立项，不在本路线图内）；
- 人脸识别（只做 redact）、医学诊断结论、印刷 ICC 嵌入。

## 9. 改路线的触发条件

- （已消耗，2026-11-25）S01 实测：JPEG 1.96 MP/s → 确认是瓶颈，S02 开工；PNG 21/13 MP/s → PNG 优化项删除；
- WebP 产物经外部解码器判定为非法 → WebP 从能力清单摘除，S02 释放出的时间并给 S03；
- dogfood 记录出现"某算子必须整图复制" → S07 提前；
- 下游 issue 集中在某个格式 → 该格式 Sprint 前移，后续顺延；
- 连续两个 Sprint 未过门禁 → 停新增功能，先还技术债。
