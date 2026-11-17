# image 项目申报书（季度优秀社区项目评选方向）

## 基本信息

- **项目名称**：image — 纯 MoonBit 图像处理库（零 C 依赖 · 18 格式 · OCR 全链路）
- **参赛者**：蒋本雄（GitHub: walkzzz）
- **联系方式**：745244185@qq.com / 13689047817
- **GitHub 仓库链接**：https://github.com/toadium/image
- **参赛方向**：季度优秀社区项目评选方向（既有生态项目维护与升级，章程 5.2）
- **项目性质**：以 stb_image.h 为参考基础的 MoonBit 原生重实现（移植合规见第四节），并大幅超越原项目能力
- **开源许可证**：MIT

## 一、项目简介

image 是纯 MoonBit 实现的图像处理库：**零 C FFI 依赖、四目标（native / wasm-gc / js / wasm）共用同一代码库**。覆盖 **18 种格式**的解码与编码（含独家 PSD / HDR / TIFF / ICNS / AVIF / HEIF / JPEG-XL），提供 8 位 / 16 位 / HDR 浮点三级像素深度、**90+ 算法子包**（色彩/边缘/特征/频域/分割/变换）与 **OCR 全链路**（数字/英文/中文/表格/手写体/多语言混合，19 模块），合计 1338 个公开 API。

本期参赛内容为**既有项目的持续维护与升级**（章程 5.2）：完成 workspace 六模块架构重构并将七个模块全部发布至 mooncakes（子模块可独立安装），建立根 CHANGELOG 与 CI 零警告门禁，完成 README 双语徽章与元数据对齐（6574 测试 / 8 goals 实测），刷新竞品对比快照，并落地真实尺寸性能基准。以下贡献均为本届赛事周期内的新增有效成果。

## 二、项目价值与生态定位

**观察到的痛点**：MoonBit 生态在图像处理上长期处于空白——(1) 无原生图像库，需要图像能力的 MoonBit 项目只能调用 C 或跨语言；(2) wasm 场景（网页图片处理）缺少零依赖方案；(3) 现有语言生态的图像库（如 Go image）能力分散且移植成本高。

**生态缺口**：mooncakes.io 上 image 相关包共 6 个（mizchi / bikallem / gmlewis / Nanaloveyuki / shunge / 本库），但格式覆盖均不超过 7 种，且无一支持 16-bit / HDR 浮点 / OCR（详见 docs/comparison.md 2026-11-13 快照）。

**为什么非做不可**：图像是视觉类应用（GUI、游戏、OCR、CV 教学）的基础数据类型。一个零 C 依赖、四目标、格式覆盖完整的图像底座，能让 MoonBit 的 GUI 框架、游戏引擎、文档工具直接站在其上——这正是生态建设期最需要的基础设施。

## 三、与近邻竞品的差异化分析

申报前已核查 mooncakes.io（docs/comparison.md，2026-11-13 版本核对快照）：不存在格式覆盖与本库相当的项目。

### 3.1 六竞品格式覆盖对比（解码）

| 能力 | walkzzz/image.mbt | mizchi | bikallem | gmlewis | Nanaloveyuki | shunge |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 格式总数（解码） | **18** | 4 | 4 | 2 | 1 | 5 |
| PNG 16-bit / Adam7 | ✅ | ❌ | ✅ | ? | ❌ | ❌ |
| PSD / HDR / TIFF / ICNS / AVIF / HEIF / JPEG-XL | ✅ 独家 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 16-bit 像素深度 | ✅ | ❌ | ✅ | ? | ❌ | ❌ |
| HDR float 像素深度 | ✅ 独家 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 动画 GIF / APNG | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

### 3.2 独有工程能力

| 能力 | 说明 |
|---|---|
| OCR 全链路（19 模块） | 预处理→文本检测→字符分割→特征→分类器→数字/英文/中文 OCR→表格识别→后处理→文档理解→手写体→多语言混合 |
| 自演化工程体系 | self_evolve 闭环：可执行测试生成 → 退化自动修复 → 管道优化 → 拷问引擎 → 演化推荐（docs/roadmap.md Phase 5-9） |
| 安全加固 | check_dims 全解码器入口校验 + MAX_IMAGE_DIMENSION 守卫 + safe_mul 溢出保护，`moon prove` 8 goals |
| workspace 架构 | 六子模块独立发布（core/codec/process/photography/vision/domain），按需轻量依赖 |

## 四、参考项目说明（章程申报内容第 6/7 项）

- **参考项目**：[stb_image.h](https://github.com/nothings/stb)（Sean Barrett，MIT / Public Domain）——以其核心图像编解码能力为参考基础，用纯 MoonBit 重新实现 18 格式编解码与基础操作；
- **未复制任何 C 代码**；实现为 MoonBit 原生重写，并在文法、类型（8/16-bit/HDR 三级深度）、错误模型（suberror + raise/catch）、安全加固（维度守卫 + 溢出证明）上全面重新设计；
- **超越原项目的扩展**：OCR 全链路、CV 算法栈（Canny/ORB/SIFT/RANSAC/grabCut/光流）、频域分析（FFT/DCT/小波）、WebP lossy 编码、安全加固——均为 stb_image.h 不具备的能力（README「移植说明」节有完整对照表）；
- **许可证兼容**：stb 为 MIT / Public Domain，本库 MIT，合规无冲突。

## 五、本期新增贡献（赛期内有效维护成果）

| 贡献 | 内容 | 可验证性 |
|:---|:---|:---|
| workspace 六模块重构 | src/ 单体 → core/codec/process/photography/vision/domain 六模块，编译并行化、职责清晰 | moon.work + 各 moon.mod |
| **七模块全部发布 mooncakes** | core/codec/process/photography/vision/domain @0.1.0 + image @0.6.0，按依赖顺序发布，子模块可独立安装 | mooncakes.io 七个模块页 |
| 根 CHANGELOG.md | 摘要页 + 版本双轨说明（功能版本 v0.1-v237 / 包版本 0.x.y），指向完整历史 | 评审第一眼可见 |
| CI 零警告门禁 | 4 处 `moon check --deny-warn`（568 tasks 零警告实测固化） | .github/workflows/ci.yml |
| badge 数据实测对齐 | 测试 6,526 → **6,574**（native 实测全绿）、proof 5 → **8 goals**（moon prove 实测）、双语 badge 首次对齐 | README.md / README.en.md |
| comparison.md 刷新 | 快照 2026-08-06 → 2026-11-13：四家竞品版本升级实测（mizchi 0.5.0 / gmlewis 0.17.19 / shunge 0.2.2 / Nanaloveyuki 0.1.5） | docs/comparison.md |
| 真实尺寸性能基准 | 1024²/4096² PNG 编解码 + resize（moon bench 框架，与 astrolabe 同款机制）：4096² 解码 1.25 s / 编码 0.78 s，跨规模线性度良好 | docs/performance_report.md |
| 文档对齐 | docs/notes.md 重写（0.6.0/6574/workspace 口径）、AGENTS.md 元数据对齐（8 goals 函数名实测）、README 自演化叙事（中英） | docs/ + AGENTS.md |

## 六、核心功能范围

**已交付**：18 格式编解码；三级像素深度；resize（7 滤波器 × 4 边缘模式）；色彩/绘制/合成；90+ 算法子包（含 OCR 19 模块）；32 个示例；四目标测试 6574 × 4 全绿、coverage 90.4%。

**拟实现（下赛期）**：JPEG progressive 解码、TIFF LZW/PackBits 压缩（格式矩阵仅存的两处短板）；真实尺寸 JPEG 基准；coverage 90.4% → 95%；fuzz 扩展（草案阶段六，+240~295 测试）。

**明确不做**：不做 GPU/CUDA 加速（纯 MoonBit 定位）；不做视频编解码（与图像库定位区分）；不追求 JPEG-XL 全特性（仅基础解码，边界已在 README 标注）。

## 七、预期使用场景

1. **服务端图像处理管线**：缩略图生成、格式转换、水印、元数据读写（EXIF/IPTC/XMP）——纯 MoonBit 部署零依赖，wasm 场景可直接嵌入边缘/浏览器。
2. **OCR 文档数字化**：扫描件 → 二值化 → 版面分析 → 中英文识别 → 表格结构化输出——19 模块全链路内置，无需拼接多个外部服务。**量化验收标准**（docs/roadmap.md）：打印数字识别准确率 **95%+**、手写数字 **80%+**、文本行检测与字符分割 **90%+**；配套 Levenshtein 编辑距离 / Precision-Recall-F1 / 混淆矩阵评估框架、后处理纠错（O→0 / I→1 / 16 组形近字映射）与批处理引擎（v12.25.0）。
3. **游戏 / 设计工具资源管线**：PSD / HDR / ICNS / APNG 等独家格式支持，配合 resize / 色彩 / 合成完成资产生成。
4. **CV 算法教学与原型**：90+ 算法子包（Canny/SIFT/分水岭/FFT）+ 双语文档 + 32 示例，适合作为 MoonBit 视觉课程配套。

## 八、实现路径与技术理解

- **workspace 架构先行**：单体 5.6 万行重构为六模块 workspace（core 类型底座 → codec 编解码 → process 算法 → photography/vision/domain 上层），依赖单向、编译并行、子模块独立发布——架构决策在先，重构在赛期内完成并完成七模块发布验证。
- **安全即语义**：`check_dims` 进入全部解码器入口、`safe_mul` 溢出安全乘法、`MAX_IMAGE_DIMENSION` 守卫——安全约束不是事后补丁，而是类型与入口设计的一部分，并以 `moon prove` 8 goals 形式化背书。
- **四目标零条件编译**：native / wasm-gc / js / wasm 共用同一套源文件，无平台分支——多目标支持的代价被架构吸收而非扩散到代码。
- **自演化工程体系**：self_evolve 闭环（测试生成 → 退化修复 → 管道优化 → 拷问引擎 → 演化推荐）保证 6574 测试的持续增长有可复现的流水线支撑，而非人工堆砌。
- **MoonBit 惯用法**：`suberror LoadError` + raise/catch、`#derive(Eq, Debug)` 全覆盖、`#inline` 热路径、`pub extend` 特征实现、`#non_exhaustive` 前向兼容。

## 九、预期验收产物

- mooncakes.io 七模块在线：walkzzz/image@0.6.0 + 六个子模块@0.1.0（子模块独立安装）；本期重构为 walkzzz/image.mbt + image.* 子模块（0.1.0 重新计数发布）；
- 四目标测试 6574 × 4 全绿、`moon check --deny-warn` 零警告、coverage 90.4%（CI 报告）；
- 双语 README（badge 实测对齐）+ 13 份 docs 文档 + 根 CHANGELOG + 评估报告（docs/assessment.md）+ 本申报书；
- 本期全部新增贡献在 CHANGELOG、git 提交历史与 docs/roadmap.md 中可追踪。

## 十、后续迭代计划

| 版本 | 内容 | 大赛维度 |
|:---|:---|:---|
| v0.7.0 | JPEG progressive 解码 + TIFF LZW/PackBits（格式矩阵补齐） | 项目完成度 |
| v0.8.0 | 真实尺寸 JPEG 基准 + stb_image.h C 基线同机量化对比 | 工程质量 |
| v0.9.0 | coverage 90.4% → 95%（薄弱模块 fuzz 扩展） | 工程质量 |
| v1.0.0 | API 稳定化候选 + 子模块生态推广（OCR/codec 独立采用案例） | 生态贡献 |

## 使用 AI 工具的声明与人工把控

本项目按章程鼓励合理使用 AI 工具辅助开发（README 参赛声明节已披露，docs/skill.md 有详细范围）。以下关键决策由参赛者本人把控：**workspace 架构与模块边界设计**、**18 格式的支持优先级与边界取舍**（TIFF 仅无压缩等边界承诺）、**安全加固方案**（check_dims 入口设计 + proof 命题选择）、**竞品研究与格式矩阵核查**（comparison.md 快照）、**开源合规**（stb 移植声明与许可证兼容）。提交记录、docs/changelog.md 与 CI 门禁共同保证产出的连续可追踪性。

## 选型自检（对照章程审核原则）

| 章程审核原则 | 本项目对照 |
|:---|:---|
| 题目真实反映客观需求 | MoonBit 生态无图像底座是真实空白；wasm 零依赖图像处理是明确刚需 |
| 技术方案最优或最合适 | workspace 六模块 + 三级像素深度 + suberror 错误模型是 MoonBit 类型系统下的自然形态；六竞品格式矩阵证明无更优替代 |
| mooncakes.io 无同质项目 | 2026-11-13 快照核查：六竞品格式覆盖均 ≤7 种，无 16-bit/HDR/OCR 对标项目；差异已在第三节明确 |

---

*本申报书基于项目实测数据（moon 0.1.20261104：check 零警告、test 6574×4、moon prove 8 goals）与 mooncakes.io 发布页实时核查（7 模块在线 / 429+ 下载 / 1 依赖方 moonrockz/diagrams-raster）撰写，竞品数据见 docs/comparison.md 快照。*
