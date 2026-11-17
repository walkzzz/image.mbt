# Feature Specification: 文档注释增强 (Doc Comment Enhancement)

**Created**: 2026-11-13
**Status**: Draft
**Input**: 用户要求增强文档注释，利用 MoonBit `///` 文档注释、`///|` 分隔符、````mbt check` 文档测试、`.mbt.md` 文学化文件等特性，系统性提升项目文档质量。

## Overview

walkzzz/image.mbt 项目已有较好的文档注释基础（1754/1754 pub 项有 `///` 前置注释，11768 个 `///|` 分隔符），但在 R3（三级文档注释中英文）合规性、文档测试覆盖、包级文档完整性、跨语言一致性等方面仍有显著提升空间。本特性旨在利用 MoonBit 文档注释系统的全部能力（doc test、文学化文件、Markdown 格式），将项目文档质量从"有注释"提升到"高质量可验证文档"。

## User Scenarios & Testing

### User Story 1 — 库用户查看 API 文档 (Priority: P1)

作为 walkzzz/image.mbt 的使用者，当我通过 `moon doc` 或 IDE 悬停查看某个函数/类型时，我期望看到：中英双语文档描述、参数说明、返回值说明、以及可直接运行的代码示例。

**Why this priority**: API 文档是库用户最直接的接触点，直接决定用户能否正确使用库。当前 83% 的文档注释是中英双语的，但 17% 仅中文，0 个文档测试。

**Independent Test**: 可通过 `moon doc` 生成文档后检查覆盖率和质量来独立验证。

**Acceptance Scenarios**:

1. **Given** 任意 pub fn/struct/enum，**When** 查看其文档注释，**Then** 能看到中英双语描述（中文在前、英文跟随后同行或下一行）
2. **Given** 核心编解码/图像加载函数，**When** 查看其文档，**Then** 包含 ````mbt check` 文档测试示例
3. **Given** 任意 pub fn 带 raise 子句，**When** 查看其文档，**Then** 文档描述了可能抛出的错误类型和场景

---

### User Story 2 — 包级文档导航 (Priority: P2)

作为库用户，当我浏览某个子包（如 `walkzzz/image.process/filter`）时，我期望看到清晰的包级文档，说明该包的用途、核心类型、典型用法和依赖关系。

**Why this priority**: 当前 54/348 个源文件缺少包级文档（15.5%），用户无法快速理解包的功能边界。

**Independent Test**: 可通过检查每个包的入口文件是否有完整的包级 `///` 注释块来验证。

**Acceptance Scenarios**:

1. **Given** 任意子包目录，**When** 查看其主源文件开头，**Then** 有 `///` 包级文档描述包用途（中英双语）
2. **Given** 任意子包，**When** 查看其包级文档，**Then** 列出了核心 pub 类型和函数清单
3. **Given** 任意子包，**When** 查看 `moon doc` 输出，**Then** 包描述完整且可导航

---

### User Story 3 — 文档测试保证示例正确性 (Priority: P2)

作为库维护者，我期望文档中的代码示例能被 `moon test` 自动验证，防止示例与实际 API 不同步。

**Why this priority**: 当前 0 个 ````mbt check` 文档测试，所有示例（仅 root `image.mbt` 有 2 个 `moonbit nocheck` 块）均不可验证。文档与代码不同步的风险高。

**Independent Test**: 运行 `moon test` 后文档测试全部通过。

**Acceptance Scenarios**:

1. **Given** 核心编解码函数（decode_bmp/decode_png/encode_jpeg 等），**When** 查看其文档注释，**Then** 包含 ````mbt check` 代码示例
2. **Given** 项目运行 `moon test`，**When** 文档测试执行，**Then** 所有文档测试通过
3. **Given** 文档测试失败（API 变更导致），**When** 运行 `moon check`，**Then** 报告具体失败的文档测试位置

---

### User Story 4 — 纯函数 noraise 标注文档 (Priority: P3)

作为库用户，我期望能从文档中快速识别哪些函数是纯函数（不抛错、可安全组合），哪些可能抛错。

**Why this priority**: 当前 720 个 pub fn 无 raise 子句（隐式 noraise），但仅 6 处显式使用 noraise。函数的错误行为在文档中不可见。

**Independent Test**: 通过 `moon doc` 输出检查函数签名中的 raise/noraise 标注。

**Acceptance Scenarios**:

1. **Given** 不抛错的纯函数（如 clamp_pixel_value），**When** 查看其文档，**Then** 签名包含 `noraise` 标注
2. **Given** 可能抛错的函数（如 decode_bmp），**When** 查看其文档，**Then** 签名明确标注 `raise XxxError` 并文档描述错误场景

---

### User Story 5 — 文学化 .mbt.md 包教程 (Priority: P3)

作为库新用户，我期望每个一级子包有一个 `.mbt.md` 文学化教程文件，包含可运行的示例和概念解释。

**Why this priority**: 当前 0 个 `.mbt.md` 文件。文学化文件是 MoonBit 的特色功能，能同时作为文档和可测试代码。

**Independent Test**: 运行 `moon test` 时 `.mbt.md` 中的 `mbt check` 块全部通过。

**Acceptance Scenarios**:

1. **Given** 6 个一级子模块（core/codec/process/photography/vision/domain），**When** 浏览其目录，**Then** 各有 `README.mbt.md` 文学化教程
2. **Given** 任一 `.mbt.md` 文件，**When** 运行 `moon test`，**Then** 其中 `mbt check` 代码块通过
3. **Given** `.mbt.md` 文件，**When** 在 IDE 中查看，**Then** Markdown 渲染正确且代码高亮

---

### Edge Cases

- 含 `@types.Image`（Bytes 字段）的 struct 无法在文档测试中构造（黑盒限制），如何提供示例？
- `#deprecated` 函数的文档注释应标注废弃信息和替代方案
- `_16`/`_f` 变体函数（255 个）的文档应引用基础版本并说明差异，避免重复
- `#non_exhaustive` enum 的文档应说明扩展性设计意图
- cmd/ 入口文件和 helpers.mbt 是否需要包级文档？

## Requirements

### Functional Requirements

- **FR-001**: 项目必须为所有 2744 个 pub 项（fn/let/struct/enum）提供中英双语文档注释，满足 R3（三级文档注释中英文）规则
- **FR-002**: 所有 54 个缺少包级文档的源文件必须补充包级 `///` 注释块
- **FR-003**: 所有 19 个完全无文档内容的源文件必须补充三级文档注释
- **FR-004**: 核心编解码函数（codec/codec 的 decode_*/encode_* 函数，约 27 个 pub fn）必须添加 ````mbt check` 文档测试
- **FR-005**: 核心图像加载/保存函数（codec/lib 的 load/save 系列，约 7 个 pub fn）必须添加 ````mbt check` 文档测试
- **FR-006**: core/safe_math 全部 17 个 pub fn 必须添加 ````mbt check` 文档测试（纯函数，最适合文档测试）
- **FR-007**: 所有 pub fn 的文档注释必须包含参数说明（使用 Markdown 列表格式 `@param name - 描述`）
- **FR-008**: 所有带 `raise` 子句的 pub fn 必须在文档中描述错误场景（`@raise ErrorType - 描述`）
- **FR-009**: 6 个一级子模块各创建 `README.mbt.md` 文学化教程文件
- **FR-010**: `_16`/`_f` 变体函数的文档注释必须引用基础版本（`@see base_function - 基础版本`）并说明差异
- **FR-011**: `#deprecated` 函数的文档注释必须包含 `@deprecated Use new_function instead` 标注
- **FR-012**: `#non_exhaustive` enum 的文档注释必须包含扩展性说明

### Key Entities

- **DocComment**: 文档注释单元 — 包级/类型级/方法级三级
- **DocTest**: ````mbt check` 文档测试块 — 嵌入文档的可验证代码示例
- **LiterateFile**: `.mbt.md` 文学化文件 — 包级教程，含可测试代码
- **BilingualDoc**: 中英双语文档注释 — 中文在前英文随后

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% 的 pub 项拥有中英双语文档注释（当前约 83% 双语，17% 仅中文）
- **SC-002**: 100% 的源文件拥有包级文档（当前 84.5%，需补充 54 个文件）
- **SC-003**: 至少 51 个核心 pub fn 拥有 ````mbt check` 文档测试（当前 0 个）
- **SC-004**: 所有文档测试通过 `moon test` 验证
- **SC-005**: 6 个一级子模块各有一个可运行的 `README.mbt.md` 文学化教程
- **SC-006**: `moon check` 0 error 0 warning，`moon test` 全目标通过

## Assumptions

- 文档注释中英文格式：中文描述在前，英文翻译在同一行跟随后方（`/// 中文描述 English description`），或多行格式（中文段落后空行接英文段落）
- ````mbt check` 文档测试为黑盒测试，只能使用 pub API
- `_16`/`_f` 变体函数的文档通过引用基础版本来避免重复，而非完整复制文档
- cmd/ 入口文件的包级文档为可选项（非 pub API 入口）
- helpers.mbt 内部辅助函数如非 pub 则无需文档
- 现有 `///|` 分隔符模式保持不变

## Open Questions

- [NEEDS CLARIFICATION: 文档测试的数据来源 — decode 函数需要合法的图像字节数据，文档测试中如何构造最小测试数据？用硬编码 hex 字节串还是用 `@test.setup` 提供测试 fixture？]
- [NEEDS CLARIFICATION: `.mbt.md` 文学化文件是否需要 front matter 声明 import？如果是，每个子模块的 import 清单如何确定？]
