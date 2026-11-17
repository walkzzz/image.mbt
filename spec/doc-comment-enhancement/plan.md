# Implementation Plan: 文档注释增强 (Doc Comment Enhancement)

**Input**: Feature specification from `spec/doc-comment-enhancement/spec.md`

## Summary

walkzzz/image.mbt 项目已有 1754/1754 pub 项覆盖 `///` 文档注释和 11768 个 `///|` 分隔符，但在中英双语一致性、文档测试覆盖、包级文档完整性、参数/错误说明规范、文学化文件等方面需要系统性增强。本计划利用 MoonBit 文档注释系统全部能力，将文档质量从"有注释"提升到"高质量可验证文档"。

## Technical Context

**Language/Version**: MoonBit (latest stable, 四目标 native/wasm-gc/js/wasm)
**Primary Dependencies**: moonbitlang/core (标准库), moonbitlang/core/debug (#derive(@debug.Debug))
**State Management**: N/A (纯函数库)
**Storage**: N/A
**Testing**: moon test (四目标), moon check (文档测试自动运行), moon doc (文档生成)
**Target Platform**: 四目标 (native/wasm-gc/js/wasm)
**Project Type**: 纯 MoonBit 图像处理库
**Performance Goals**: 文档注释不影响运行时性能；文档测试通过 moon check/test 验证
**Constraints**: 纯 MoonBit 实现（零 C FFI）；四目标共用代码；文档测试为黑盒测试（只能用 pub API）
**Scale/Scope**: 2744 pub 项、348 源文件、71 包、6 子模块

## Project Structure

### Documentation (this feature)

```text
spec/doc-comment-enhancement/
├── spec.md              # 需求规范
├── plan.md              # 本文件
└── tasks.md             # 任务分解
```

### Source Code (repository root — 仅展示受影响区域)

```text
core/
├── types/               # 补全包级文档 + 参数/错误说明
├── safe_math/           # 添加 mbt check 文档测试 + 参数说明
└── cmd/                 # 可选包级文档

codec/
├── codec/               # 补全包级文档 + mbt check 文档测试
├── lib/                 # 补全包级文档 + mbt check 文档测试
├── color/               # 补全参数/错误说明
├── meta/                # 补全包级文档
├── util/                # 补全包级文档
├── barcode/             # 补全参数/错误说明
├── README.mbt.md        # 新建文学化教程
└── cmd/                 # 可选包级文档

process/
├── color/               # 补全包级文档 + 双语补全
├── edge/                # 补全包级文档 + 双语补全
├── feature/             # 补全包级文档 + 双语补全
├── filter/              # 补全包级文档（当前 0 文档内容）
├── frequency/           # 补全包级文档
├── segment/             # 补全包级文档
├── transform/           # 补全包级文档
├── enhance/             # 补全参数/错误说明
├── detection/           # 补全参数/错误说明
├── stereo3d/            # 补全参数/错误说明
├── README.mbt.md        # 新建文学化教程
└── cmd/                 # 可选包级文档

photography/
├── photo_enhance/       # 补全参数/错误说明
├── superres/            # 补全参数/错误说明
├── fusion/              # 补全参数/错误说明
├── stitch/              # 补全参数/错误说明
├── style_transfer/      # 补全参数/错误说明
├── inpainting/          # 补全参数/错误说明
├── computational_imaging/ # 补全参数/错误说明
├── neural_rendering/    # 补全参数/错误说明
├── advanced_imaging/    # 补全参数/错误说明
├── compression/         # 补全参数/错误说明
├── quality/             # 补全参数/错误说明
├── README.mbt.md        # 新建文学化教程
└── cmd/                 # 可选包级文档

vision/
├── ocr/                 # 补全双语注释
├── face_recognition/    # 补全双语注释
├── pose_estimation/     # 补全双语注释
├── slam/                # 补全双语注释
├── video/               # 补全双语注释
├── scene_understanding/ # 补全双语注释
├── spatiotemporal/      # 补全双语注释
├── vlm_multimodal/      # 补全双语注释
├── intelligent_vision/  # 补全双语注释
├── fieldimg/            # 补全双语注释
├── imgir/               # 补全双语注释
├── aoci/                # 补全包级文档（当前 5 文件无文档）
├── README.mbt.md        # 新建文学化教程
└── cmd/                 # 可选包级文档

domain/
├── encryption/          # 补全双语注释
├── remote_sensing/      # 补全双语注释
├── forensics/           # 补全双语注释
├── medical/             # 补全双语注释
├── watermark/           # 补全双语注释
├── registration/        # 补全双语注释
├── retrieval/           # 补全双语注释
├── pipeline/            # 补全双语注释
├── texture/             # 补全双语注释
├── mesh/                # 补全双语注释
├── point_cloud/         # 补全双语注释
├── agent_kit/           # 补全包级文档（当前 4 文件无文档）
├── self_evolve/         # 补全双语注释
├── production_utils/    # 补全双语注释
├── performance/         # 补全双语注释
├── util/                # 补全包级文档
├── README.mbt.md        # 新建文学化教程
└── cmd/                 # 可选包级文档

core/README.mbt.md       # 新建文学化教程
```

**Structure Decision**: 遵循现有项目架构（6 子模块扁平工作空间），不引入新目录结构。仅在每个子模块根目录新增 `README.mbt.md` 文学化教程文件。

## Complexity Tracking

无需记录 — 本特性为文档增强，不涉及架构违规。

## Research & Decisions

### RD-001: 中英双语格式规范

**Decision**: 采用同行双语格式 — `/// 中文描述 English description`

**Rationale**: 
- 项目已有 3737 行采用此格式（83% 的非分隔符文档行）
- 同行格式节省行数、阅读流畅
- 多行格式（中英分段）仅在描述超过 80 字符时使用

**Alternatives considered**:
- 多行分段格式（中段落 + 空行 + 英段落）：行数膨胀，不符合现有风格
- 仅英文：不符合 R3 中英文要求
- 仅中文：不符合国际化需求

### RD-002: 文档测试数据策略

**Decision**: 对纯函数使用内联构造数据；对编解码函数使用硬编码最小 hex 字节串

**Rationale**:
- `mbt check` 为黑盒测试，只能使用 pub API
- 纯函数（clamp/min/max/色彩转换）输入为基本类型，直接内联
- 编解码函数需要 Bytes 输入，使用硬编码最小合法图像字节串（如 BMP 14+40+4=58 字节最小 1×1 图像）
- 不使用 `@test.setup`（文档测试不支持外部 fixture）

**Alternatives considered**:
- 使用 `@test.setup` fixture：文档测试格式不支持
- 仅测试纯函数：编解码是核心 API，必须有文档测试
- 外部测试文件调用：与文档测试嵌入文档的目的冲突

### RD-003: 参数说明格式

**Decision**: 使用 Markdown 列表格式，嵌入 `///` 注释中

格式规范：
```
/// 函数描述 Function description
///
/// 参数 Parameters:
/// - `param_name` - 参数描述 Parameter description
///
/// 返回 Return:
/// - 返回值描述 Return description
///
/// 错误 Errors:
/// - `ErrorType::Variant` - 错误场景 Error scenario
```

**Rationale**:
- MoonBit `///` 支持 Markdown，列表格式在 `moon doc` 中渲染美观
- 与现有项目风格一致
- 中英双语信息嵌入各条目

**Alternatives considered**:
- `@param` JSDoc 风格：MoonBit 无内置 `@param` 支持，仅作为纯文本
- 无结构化格式：不利于 `moon doc` 渲染

### RD-004: 变体函数文档策略

**Decision**: `_16`/`_f` 变体函数使用引用式文档 — 简述差异 + 引用基础版本

格式规范：
```
/// 16-bit 版本的 func_name。16-bit version of func_name.
///
/// 与基础版本的区别：输入/输出为 Image16。Difference: input/output is Image16.
///
/// @see func_name - 基础版本 Base version
```

**Rationale**: 255 个变体函数完整复制文档会导致大量重复和维护负担

**Alternatives considered**:
- 完整复制基础版本文档：255×重复，维护噩梦
- 不添加文档：违反 R3

### RD-005: .mbt.md 文学化文件结构

**Decision**: 每个一级子模块创建 `README.mbt.md`，含 front matter 声明 import

结构：
1. 标题 + 模块简介（中英双语）
2. 核心类型概述（`mbt nocheck` 展示类型签名）
3. 快速入门示例（`mbt check` 可运行代码）
4. 进阶用法示例（`mbt check`）
5. API 索引（`mbt nocheck` 展示主要 pub 项）

**Rationale**: 文学化文件是 MoonBit 特色功能，同时作为文档和可测试代码

**Alternatives considered**:
- 不创建 `.mbt.md`：放弃 MoonBit 特色，文档不可验证
- 仅核心模块创建：6 个一级子模块都应有完整教程

### RD-006: 包级文档位置

**Decision**: 包级文档放在每个包的主入口源文件开头（通常是文件名最短的 .mbt 文件）

**Rationale**: `moon doc` 从包内所有 `///` 注释收集文档，主入口文件最直观

**Alternatives considered**:
- 独立 `doc.mbt`：增加文件数，不符合 MoonBit 惯例
- 放在 `moon.pkg` 旁：MoonBit 不支持 moon.pkg 文档

## Data Model

### DocComment 三级结构

| 级别 | 位置 | 内容要求 | 格式 |
|------|------|----------|------|
| 包级 | 源文件开头首个 `///` 块 | 包用途、核心类型、依赖关系 | `/// # 包名 PackageName` + 多行描述 |
| 类型级 | struct/enum 前的 `///` 块 | 类型用途、字段含义、约束 | `/// 类型描述 Type description` + 字段列表 |
| 方法级 | pub fn 前的 `///` 块 | 功能描述、参数、返回值、错误 | 结构化格式（RD-003） |

### DocTest 嵌入规范

| 适用对象 | 测试类型 | 数据来源 |
|----------|----------|----------|
| 纯函数（safe_math） | `mbt check` + assert_eq | 内联基本类型值 |
| 色彩转换函数 | `mbt check` + assert_eq | 内联构造 Image（1×1 最小图） |
| 编解码函数 | `mbt check` + try/catch | 硬编码最小合法字节串 |
| 加载/保存函数 | `mbt check` + try/catch | 硬编码最小合法字节串 |

### BilingualDoc 双语规范

- 模式 A（短描述）: `/// 中文描述 English description`
- 模式 B（长描述）: 中文段落 + 空行 + 英文段落，各以 `///` 开头
- 参数/返回/错误条目: 中文在前英文随后，同一 `///` 行

## Contracts & Interfaces

### 文档注释格式合约

所有 pub 项的文档注释必须遵循以下格式：

**函数文档**:
```
///|
/// 功能简述（中英双语）Brief description (bilingual)
///
/// 详细描述（可选）Detailed description (optional)
///
/// 参数 Parameters:
/// - `param1` - 参数说明 Parameter description
/// - `param2` - 参数说明 Parameter description
///
/// 返回 Return:
/// - 返回值说明 Return description
///
/// 错误 Errors (仅 raise 函数):
/// - `ErrorType::Variant` - 错误场景 Error scenario
///
/// 示例 Example:
/// ```mbt check
/// test "test_name" {
///   // 文档测试代码
/// }
/// ```
pub fn foo(param1 : Int32, param2 : String) -> Unit raise LoadError {
```

**类型文档**:
```
///|
/// 类型简述（中英双语）Type description (bilingual)
///
/// 字段 Fields:
/// - `field1` - 字段说明 Field description
#derive(Eq, @debug.Debug)
pub(all) struct TypeName {
  field1 : Int32
}
```

**包级文档**:
```
///|
/// # 包名 PackageName
///
/// 包用途描述（中英双语）Package purpose description
///
/// 核心类型 Core types:
/// - `TypeName` - 类型说明 Type description
///
/// 核心函数 Core functions:
/// - `function_name` - 函数说明 Function description
```

### 文档测试合约

- 所有 `mbt check` 块必须包含在 `test "name" { ... }` 中
- 测试名称格式: `"doc_函数名_场景"`
- 纯函数测试: 使用 `assert_eq` / `assert_true`
- 编解码测试: 使用 `try { ... } catch { ... }` 模式
- 每个 `mbt check` 块最多 15 行，保持简洁

### .mbt.md 文学化文件合约

- Front matter 必须声明 `moonbit.import`（列出核心依赖包）
- `mbt check` 块数量 ≥ 2（快速入门 + 进阶用法）
- `mbt nocheck` 块用于展示类型签名和 API 索引
- 中英双语叙述

### 变体函数文档合约

- `_16` 变体: 引用基础版本 + 说明"16-bit Image16 输入/输出"
- `_f` 变体: 引用基础版本 + 说明"浮点 ImageF 输入/输出"
- 使用 `@see` 标记引用基础版本
