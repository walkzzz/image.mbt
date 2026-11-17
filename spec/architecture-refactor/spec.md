# Feature Specification: walkzzz/image.mbt 项目架构全面重构

**Created**: 2026-11-12  
**Status**: Draft  
**Input**: 全面熟悉本项目然后全面优化项目架构。参考 moon2dart 项目架构进行 modules/ 多模块工作空间重构。

## Overview

walkzzz/image.mbt 是一个拥有 1338 公开函数 + 491 类型的纯 MoonBit 图像处理库，但当前架构存在严重的结构性问题：src/ 单体巨石与 modules/ 多模块工作空间并存且代码完全重复、33 个 `_advanced` 存根包未集成、功能重叠包散落各处、pure/ 迁移不完整、cv_advanced 巨型包未拆分、文档严重过时。本次重构的目标是完成从 src/ 单体到 modules/ 多模块工作空间的迁移，消除所有重复代码和存根包，全面重划功能域合并重叠包，打散 cv_advanced 到现有包，完成 pure/ 迁移，重构 reexport 模式，清理项目并更新文档，使项目达到可维护、可扩展、文档准确的工程标准。

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 库用户通过 @image 访问完整 API（Priority: P1）

库用户安装 `walkzzz/image.mbt` 包后，通过 `@image.xxx` 访问所有公开 API，行为与重构前完全一致。重构不应破坏任何现有的公开 API。

**Why this priority**: API 兼容性是库项目的生命线，必须首先保证。

**Independent Test**: `moon test --target native` 和 `moon test --target wasm-gc` 全部通过，pkg.generated.mbti 中公开 API 表面不变。

**Acceptance Scenarios**:

1. **Given** 重构后的项目, **When** 用户通过 `@image.gaussian_blur(...)` 调用函数, **Then** 行为与重构前完全一致
2. **Given** 重构后的项目, **When** 运行 `moon test --target all`, **Then** 四目标测试全部通过
3. **Given** 重构后的项目, **When** 查看 pkg.generated.mbti, **Then** 公开 API 表面（类型+函数签名）与重构前一致

---

### User Story 2 - 开发者在 modules/ 中维护代码，src/ 不再存在（Priority: P1）

开发者只需在 `modules/` 下维护代码，src/ 目录被完全移除。每个子模块有清晰的职责边界和依赖层级。

**Why this priority**: 消除代码重复是本次重构的核心目标，直接影响开发效率和代码质量。

**Independent Test**: src/ 目录不存在；modules/ 下每个子模块可独立 `moon check` 和 `moon test`。

**Acceptance Scenarios**:

1. **Given** 项目根目录, **When** 检查文件结构, **Then** src/ 目录不存在，所有源码在 modules/ 下
2. **Given** modules/image-process/, **When** 运行 `moon check -C modules/image-process`, **Then** 编译通过
3. **Given** 任意子模块, **When** 检查 moon.mod 依赖, **Then** 仅依赖下层模块，无循环依赖

---

### User Story 3 - 功能域全面重划，重叠包已合并（Priority: P2）

对项目中的所有包进行功能域审查，全面合并重叠包并按功能域重新组织。cv_advanced 的 72 个文件打散合并到对应功能域的现有包中。

**Why this priority**: 包重叠和巨型包造成用户困惑和代码冗余，重划后大幅提升项目可理解性和可维护性。

**Independent Test**: 原重叠包目录不存在；cv_advanced 包不存在；合并后的包包含所有功能；相关测试全部通过。

**Acceptance Scenarios**:

1. **Given** 合并后的 filter/ 包, **When** 检查功能, **Then** 包含原 filter + denoise + cv_advanced 中滤波相关功能
2. **Given** 合并后的 feature/ 包, **When** 检查功能, **Then** 包含原 feature + cv_advanced 中特征检测相关功能
3. **Given** 重构后的项目, **When** 列出 image-process 下的包, **Then** 不存在 cv_advanced、denoise、segmentation 等已合并包
4. **Given** 每个 image-process 子包, **When** 统计文件数, **Then** 单包文件数不超过 30

---

### User Story 4 - pure/ 迁移完成，命名空间统一（Priority: P2）

src/pure/codec → modules/image-codec/codec, src/pure/color → modules/image-codec/color, src/pure/util → modules/image-codec/util。pure/ 目录不存在。

**Why this priority**: pure/ 是不完整迁移的残留，消除后统一命名空间。

**Independent Test**: pure/ 目录不存在；codec/color/util 功能可通过 image-codec 模块访问。

**Acceptance Scenarios**:

1. **Given** 重构后的项目, **When** 检查文件结构, **Then** pure/ 目录不存在
2. **Given** modules/image-codec/codec/, **When** 调用编解码函数, **Then** 行为与原 pure/codec 一致
3. **Given** 根包 reexport, **When** 调用 `@image.load_from_bytes_auto`, **Then** 正常工作

---

### User Story 5 - 存根包已删除，项目仅包含实际功能的包（Priority: P2）

33 个 `_advanced` 存根包（每个仅 1 个源文件且未导入根包）被完全删除。

**Why this priority**: 存根包增加维护负担和认知复杂度，删除后项目更精简。

**Independent Test**: 项目中不存在任何 `_advanced` 存根包目录；根 moon.pkg 不导入任何已删除包。

**Acceptance Scenarios**:

1. **Given** 重构后的项目, **When** 列出所有包, **Then** 不存在 33 个已删除的 `_advanced` 包
2. **Given** modules/image-advanced/ 模块, **When** 检查内容, **Then** 该模块已被删除
3. **Given** 重构后的项目, **When** 运行 `moon test`, **Then** 测试数量合理减少（无存根测试）

---

### User Story 6 - reexport 模式重构，参考 moon2dart（Priority: P2）

参考 moon2dart 项目的 reexport 模式，重构根包的重导出方式。moon2dart 使用轻量级函数委托模式（~73 行），而非当前 image 的 20K 行 type/fn alias 巨文件。

**Why this priority**: 20K 行的 reexport.mbt 是维护噩梦，每次 API 变更都需要同步修改。参考 moon2dart 的轻量模式可大幅简化。

**Independent Test**: 根包重导出文件总量显著减少（目标 <5000 行）；API 表面不变；moon test 通过。

**Acceptance Scenarios**:

1. **Given** 重构后的根包, **When** 统计重导出相关代码行数, **Then** 总量比原 20K 行显著减少
2. **Given** 重构后的根包, **When** 通过 `@image.xxx` 调用函数, **Then** 行为与重构前一致
3. **Given** 新增一个子模块公开函数, **When** 需要重导出, **Then** 仅需在该子模块的 reexport 中添加，根包自动继承

---

### User Story 7 - 项目根目录干净，临时文件已清理（Priority: P3）

根目录下的 20+ 临时文件（batch*.txt, coverage*.txt, *.py 等）和无关文档已清理。ArcGIS_Pro_*.md 和 MoonBit参考.md 已移入 docs/ 或删除。

**Why this priority**: 项目清洁度直接影响专业形象和仓库体积。

**Independent Test**: 根目录仅包含项目必需文件（moon.mod, moon.work, README.md, LICENSE, AGENTS.md 等）。

**Acceptance Scenarios**:

1. **Given** 项目根目录, **When** 列出文件, **Then** 不存在 batch*.txt, coverage*.txt, *.py 等临时文件
2. **Given** 项目根目录, **When** 列出文件, **Then** ArcGIS_Pro_*.md 等参考文档已移入 docs/references/ 或删除

---

### User Story 8 - 文档全面更新，数据准确一致（Priority: P3）

README 徽章、roadmap 头部、AGENTS.md 项目结构、rules.md 内容全部更新为准确数据。

**Why this priority**: 文档是项目门面，过时文档造成严重误导。

**Independent Test**: README 徽章数据与 `moon test` 实际结果一致；AGENTS.md 结构与实际目录一致。

**Acceptance Scenarios**:

1. **Given** README.md, **When** 检查徽章, **Then** 测试数量、API 数量、覆盖率均与实际一致
2. **Given** AGENTS.md, **When** 检查项目结构, **Then** 准确反映 modules/ 多模块架构
3. **Given** rules.md, **When** 检查内容, **Then** 规则适用于 walkzzz/image.mbt 项目（不是 GeoVerse）

---

### Edge Cases

- 重构过程中某个子模块的测试失败如何处理？→ 回退该子模块的变更，单独修复后再继续
- 重叠包合并时，两个包的同名函数如何处理？→ 优先保留基包版本，被合并包的函数添加语义后缀
- modules/ 与 src/ 存在代码差异时如何处理？→ 以 src/ 为准（src/ 是实际被测试和使用的代码）
- 根包 reexport.mbt 引用路径变更导致编译失败？→ 逐步迁移，每步验证 `moon check`
- cv_advanced 打散合并时，72 个文件的功能归属如何确定？→ 按文件名前缀和函数语义分类到对应包
- self_evolve 迁入后补充关键路径白盒测试，最小覆盖核心调度逻辑

## Requirements *(mandatory)*

### Functional Requirements

**架构迁移（P1）**

- **FR-001**: 项目必须从 src/ 单体架构迁移到 modules/ 多模块工作空间架构，src/ 目录最终被完全移除
- **FR-002**: modules/ 下保持 6 个子模块（删除 image-advanced）：image-core, image-codec, image-process, image-photography, image-vision, image-domain
- **FR-003**: 每个子模块必须遵循严格的层级依赖：image-core(0层) → image-codec(1层) → image-process(2层) → image-photography/image-vision(3层) → image-domain(4层)
- **FR-004**: 根包 `walkzzz/image.mbt` 必须作为统一门面，用户通过 `@image.xxx` 访问全部公开 API
- **FR-005**: 重构后必须保持所有现有公开 API 的签名和行为不变（允许内部包路径变更）
- **FR-017**: 每个子模块必须有独立的 moon.mod（声明依赖）、moon.pkg（包配置）、cmd/main（独立测试入口）

**存根包删除（P2）**

- **FR-006**: 必须删除 33 个 `_advanced` 存根包及其对应的 image-advanced 子模块

**功能域重划与包合并（P2）**

- **FR-007**: 必须全面审查所有包的功能职责，按功能域重划，合并重叠包
- **FR-007a**: 明确重叠合并：denoise→filter, segmentation→segment, forensics_enhanced→forensics, fusion_enhanced→fusion, photo_enhance→enhance, style_transfer→stylize, image_generation→generative, registration_advanced→registration, remote_sensing_advanced→remote_sensing
- **FR-007b**: cv_advanced (72文件) 必须打散合并到现有功能域包中（按文件名前缀和函数语义分类到 filter/feature/edge/segment/transform/color 等对应包）
- **FR-007c**: 合并后的单包文件数不超过 30 个源文件（特殊大型包如 ocr/ 除外）
- **FR-018**: 重叠包合并后，被合并包中的所有公开函数必须在目标包中可访问（通过根包 reexport）

**pure/ 迁移（P2）**

- **FR-008**: 必须完成 pure/ 迁移：pure/codec→image-codec/codec, pure/color→image-codec/color, pure/util→image-codec/util，删除 pure/ 目录

**reexport 重构（P2）**

- **FR-019**: 参考 moon2dart 的轻量级重导出模式，重构根包 reexport：
  - 每个子模块拥有自己的 reexport 文件，汇聚该模块内所有子包的公开 API
  - 根包通过 `pub using` 引用各子模块的 reexport，而非 20K 行逐项 alias
  - 保留 `pub type`/`pub let`/`pub fn` 用于需要保留默认参数值的函数

**清理与文档（P3）**

- **FR-009**: 必须清理项目根目录临时文件（batch*.txt, coverage*.txt, new_tests.txt, test_single.txt, func_params.txt, uncovered_funcs.txt, *.py 等）
- **FR-010**: 必须移动或删除根目录无关文档（ArcGIS_Pro_*.md, GeoVerse-ARCHITECTURE.md, MoonBit参考.md, 自查报告.md, docs-opt-report.md）
- **FR-020**: 删除 src/ 下版本锁定的临时测试文件（formal_v264_test.mbt, fuzz_v262_test.mbt, fuzz_v263_test.mbt, geoverse_integration_test.mbt）

**文档更新（P3）**

- **FR-011**: 必须更新 README.md 徽章数据使其与实际测试结果一致
- **FR-012**: 必须更新 AGENTS.md 项目结构使其准确反映 modules/ 多模块架构
- **FR-013**: 必须重写 rules.md 使其适用于 walkzzz/image.mbt 项目（当前内容为 GeoVerse 项目的规则）
- **FR-014**: 必须更新 docs/roadmap.md 头部数据（版本号、测试数量、覆盖率）

**质量保证**

- **FR-015**: 四目标测试必须全部通过（native, wasm-gc, js, wasm）
- **FR-016**: moon check 必须零 error、零 warning
- **FR-021**: self_evolve/ 迁入 image-domain 模块后，补充核心调度路径的白盒测试

### Key Entities

- **Module（子模块）**: 独立的 MoonBit 模块，拥有独立 moon.mod，通过 moon.work 组成工作空间。每个模块有明确的层级和依赖关系。
- **Package（包）**: 模块内的编译单元，拥有 moon.pkg。包之间通过 import 声明依赖。
- **Reexport（重导出）**: 每个子模块汇聚自身 API，根包通过 `pub using` 引用子模块 reexport，形成统一入口。
- **Layer（层级）**: 模块依赖的分层约束：0层(core)→1层(codec)→2层(process)→3层(photography/vision)→4层(domain)
- **Functional Domain（功能域）**: 按图像处理领域划分的功能集合，如滤波、特征检测、分割、编解码等。每个功能域对应一个或多个包。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 项目中不存在 src/ 目录，所有源码在 modules/ 下
- **SC-002**: 项目中不存在 33 个 `_advanced` 存根包和 image-advanced 子模块
- **SC-003**: 项目中不存在功能重叠包（denoise, segmentation, forensics_enhanced, fusion_enhanced, photo_enhance, style_transfer, cv_advanced 等）
- **SC-004**: 项目中不存在 pure/ 目录
- **SC-005**: 项目根目录不含任何临时文件（batch*.txt, coverage*.txt, *.py 等）
- **SC-006**: `moon check` 零 error 零 warning（四目标）
- **SC-007**: `moon test` 四目标全绿
- **SC-008**: 根包 pkg.generated.mbti 公开 API 表面与重构前一致
- **SC-009**: 每个子模块可独立 `moon check` 和 `moon test` 通过
- **SC-010**: README.md 徽章数据与 `moon test` 实际结果一致（误差 <5%）
- **SC-011**: 根包 reexport 相关代码总量 <5000 行（原 20K 行）
- **SC-012**: image-process 模块下单包文件数 ≤30 个源文件

## Assumptions

- 以 src/ 为代码真值源（src/ 是实际被测试和使用的代码），modules/ 是副本
- 重叠包合并时，基包（如 filter）的 API 优先保留，被合并包（如 denoise）的函数直接迁移
- 删除 `_advanced` 存根包不会影响任何实际用户（它们未在根包导入，无公开 API 被外部使用）
- moon.work 工作空间机制足以支持跨模块的测试和构建
- cv_advanced 打散时，按文件名语义前缀归类（如 blur*→filter, edge*→edge/feature, match*→feature, morph*→segment 等）
- 项目版本号在重构期间不变更（保持 0.5.0）
- reexport 重构采用 `pub using` + per-module reexport 模式，参考 moon2dart 的函数委托思想，但保留 type alias 以维持 API 兼容性

## Open Questions

（所有开放问题已在需求确认中解决）
