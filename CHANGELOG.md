# CHANGELOG

> 本文件为变更**摘要**（面向评审与使用者的第一入口）。完整功能迭代历史（v0.1 → v237.0.0，3300+ 行）见 [docs/changelog.md](docs/changelog.md)。

**版本双轨说明**：功能迭代版本（v0.1 → v237.0.0）与 mooncakes 包版本（0.x.y）并行演进；包版本随发布递增，workspace 六子模块（image.core/image.codec/image.process/image.photography/image.vision/image.domain）版本随主包同步。

## [0.1.1] - 2026-11-20

### Added

- **可运行示例集**：`examples/` 7 个零外部依赖示例（raw_to_png / resize_demo / threshold_otsu / format_detect / lossless_roundtrip / canny_edges / gaussian_blur），均 `moon run` 实测通过，见 docs/examples.md。
- **变异测试闭环**：`scripts/mutation_test.mjs`（7 包 / 12 变异点，100% KILLED）+ CI `mutation` job + `mutation-report.json` artifact。
- **质量门禁脚本**：`scripts/check_docs.mjs`（9 断言 + 5 负向自测）、`scripts/check_coverage.mjs`（≥80.5%）、`scripts/check_version.mjs`（七模块版本一致）、`scripts/publish.sh`（依赖序发布，由维护者执行）。
- **治理文件**：TEST_REPORT.md、docs/known-gaps.md、CONTRIBUTING.md、SECURITY.md、CODE_OF_CONDUCT.md、PR 模板、CODEOWNERS。

### Changed

- **CI 重构**：单 job → 6 jobs（quality / test 四目标矩阵 / bench / coverage / mutation / prove，ubuntu-24.04）；`mbti` 漂移与 `moon fmt --check` 改为阻断；`scripts/` 取消 gitignore，门禁脚本随仓库发布。
- **测试**：6,580 → **6,621**（+41：门禁/边界补测、7 个零覆盖大文件补测、分割/视频/拼接/TIFF/Codec trait/EXIF/OCR 补测、5 个白盒测试文件、WebP 编解码互操作与奇数尺寸回归）。
- **弃用 API 迁移**：19 处 `Int64::from_int` / `Double::from_int` → `to_int64()` / `to_double()`，四目标 `check --deny-warn` 零警告。

### Fixed

- **WebP VP8 编码奇数尺寸崩溃**：`rgb_to_yuv420` 的 UV 平面按 `w/2*(h/2)` 分配、索引却按 `ceil(w/2)` 步长访问，1x1/3x3 触发 `PanicError`；改为 `ceil(w/2)×ceil(h/2)` 分配并统一步长，新增 1x1 / 3x3 / 1 通道拒绝回归测试。
- **WebP VP8 解码无法解自身编码**：`parse_vp8_frame_header` 把 3 字节帧 tag 当 MSB-first 3 位读取并判 `tag == 0`，合法关键帧被误判为非关键帧；按 RFC 6386 改为小端 tag（bit0=关键帧、bit5-23=first_part_size）+ 小端分辨率解析，自编码 16x16 / 8x8 / 32x32 / RGBA 往返全部通过。
- **WebP VP8 解码奇数尺寸崩溃**：色度平面按 `w/2*(h/2)` 分配导致 1x1/3x3 越界 panic；解码器现返回明确 `DecodeFailed`（正确 ceil 平面支持列入后续，见 GAP-17）。
- 文档口径：版本 0.5.0/0.1.0 冲突、测试数 6,574/6,486、包数 71、proof 5 goals、覆盖率 90.4% 全部按实测纠正（覆盖率 **82.2% = 32010/38950**）；删除死链 banner 与旧仓库链接；`docs/examples.md` 虚报 32 示例改为真实清单。
- 测试盲区：resize 零/负尺寸断言被 try/catch 吞掉、最近邻下采样与 Otsu 渐变图只断言尺寸。

### Verified

- `moon check --deny-warn --target all` 零警告；`moon test` **6,621/6,621**（native，2026-11-20）；CI 6 jobs（quality / test×4 / bench / coverage / mutation / prove）。
- 覆盖率 32,010/38,950 = **82.2%**（门槛 80.5%）；变异 **12/12 KILLED（7 包）**；`moon prove` **8 goals proved**（WSL Why3 1.6.0 + Z3 4.8.12）。

## [0.1.0] - 2026-11-17

### Breaking（包重命名重构 — 破坏性变更）

模块名统一重构：根模块 `walkzzz/image` → **`walkzzz/image.mbt`**，六子模块加 `image.*` 前缀，子模块目录同步改名（core/ → image.core/ 等）。**API 零变化，纯前缀迁移**；下游需更新安装命令与 import 路径：

| 旧模块名 | 新模块名 |
|---|---|
| walkzzz/image | walkzzz/image.mbt |
| walkzzz/core | walkzzz/image.core |
| walkzzz/codec | walkzzz/image.codec |
| walkzzz/process | walkzzz/image.process |
| walkzzz/photography | walkzzz/image.photography |
| walkzzz/vision | walkzzz/image.vision |
| walkzzz/domain | walkzzz/image.domain |

- import 迁移规则：`walkzzz/image` → `walkzzz/image.mbt`；`walkzzz/<子模块>` → `walkzzz/image.<子模块>`
- 完整迁移示例见 README.md「从 walkzzz/image（0.6.x）迁移」章节
- 旧名包（walkzzz/image@0.6.0 及六子模块@0.1.0）在 mooncakes 上保留可装，不再更新；已于 2026-11-17 对旧模块全部 13 个版本（walkzzz/image 7 版 0.4.8~0.6.1 + 六子模块各 1 版）标记 deprecated，`--reason` 指引对应新模块名（`moon deprecate --undo <模块名>` 可恢复）
- 版本号重新计数：新名包首发 0.1.0

### Fixed
- mp4 包修复（上次提交遗留的不可编译半成品）：补齐缺失的大端字节读取原语 `read_u32`/`read_u64`；`parse_chunk_offsets` 的 stco 按规范读 32 位字段（原误用 64 位读取污染偏移值）；`compute_sample_offset` 修正 chunk 首样本 1-based 偏移并补数组下界保护；白盒测试合成数据修正（stbl 子 box 缺 header 包装、stsc 条目缺 sdi 字段且 first_chunk/samples_per_chunk 字段顺序颠倒）
- 元数据修正：7 个 moon.mod 的 `repository` 字段与六子模块 README、`docs/proposal.md` 中的 GitHub 仓库链接，由 `toadium/image` 统一更新为 `https://github.com/walkzzz/image.mbt`（`docs/examples.md` 指向 stb-image 上游参考仓库的链接不受影响）

### Verified
- `moon check --deny-warn --target all` 零警告；`moon test` 四目标 6580/6580 全绿
- `moon info` 重新生成 `.mbti`：仅 `package` 路径行变化，公共 API 符号零变化
- 目录树/徽章/文档/脚本同步更新（136 文件批量替换 + 人工治理）

## [0.6.1] - 2026-11-13

### Added
- `docs/pitfall-catalog.md` — 15 measured pitfalls（M 系列 MoonBit 语法演进 9 条 + I 系列项目特有 6 条：workspace 发布陷阱 / mooncakes 409 占用 / coverage 口径换算）
- `docs/proposal.md` — quarterly award proposal（章程 8 项内容 + 六竞品差异化 + stb 移植合规 + AI 把控声明 + OCR 量化验收引用）
- `scripts/check_docs.mjs` — doc-number consistency self-check（5 正向断言 + 7 负向自测全绿：双语 badge 漂移 / proof goals 漂移 / moon.mod 与 badge 版本分离，全部检出）

### Fixed
- `.github/workflows/ci.yml`：四行 `--targetnative` 等参数空格修正（原生笔误，CI 四个月未通过的主因）
- 六个子模块 moon.mod `repository` 统一 → toadium/image

### Changed
- `docs/notes.md` 重写（0.6.0 / 6574 / workspace 口径）；AGENTS.md 元数据对齐（8 goals 函数名实测）；README 自演化叙事（中英）+ 子模块安装说明 + comparison 刷新（2026-11-13 四家升级）+ mooncakes 徽章

## [0.6.0] - 2026-11-13

### Changed
- 版本号顺移：mooncakes 0.5.0 已发布且对应旧单模块结构，workspace 六模块重构后的首个发布版本 bump 至 0.6.0（避免 409 冲突）
- README badge 数据修正：测试数 6,526 → **6,574**（`moon test --target native` 实测全绿）、形式化 5 → **8 goals proved**（`moon prove` 实测，与 docs/changelog.md 内部记录对齐）
- CI 零警告门禁：4 处 `moon check` 增加 `--deny-warn`（固化 568 tasks 零警告状态，防回退）
- 新增 mooncakes 徽章与生态采用展示（moonrockz/diagrams-raster 为首个依赖方）

## [0.5.0] - 2026-10（mooncakes 已发布）

### Added（摘要，完整记录见 docs/changelog.md 的 "v0.5.1 Sprint A-H" 与 "Phase 18"）
- MoonBit 属性系统优化 Sprint A-H：`#derive` 补全（~100+ 类型）、`#inline` ×14、`#deprecated` ×5、`#non_exhaustive` ×149、255 个 @see 引用、~1460 行双语文档注释
- 形式化验证 5→8 goals proved（int_max / int_min / dims_valid_check 新增；clamp_int/clamp_coord 等谓词预留，SMT 超时与前端限制见 safe_math.mbtp 注释）
- R13 Warning 治理：27 处 `#warnings("-deprecated")`
- **Workspace 六模块重构**：src/ 单体 → core/codec/process/photography/vision/domain

### 统计（v0.5.1 实测）
- moon check: 0 error, 0 warning · moon test: 6574/6574 pass (native) · moon prove: 8 goals proved

## 更早版本

完整历史（v0.1 → v237.0.0 全部 Sprint/Phase 记录）见 [docs/changelog.md](docs/changelog.md)。
