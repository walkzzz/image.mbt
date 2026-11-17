# 陷阱目录（pitfall-catalog）

> 准入标准（借鉴 flutter-ohos-expert-agent）：**只收"复现过并修好"的条目**，来源标【实测】并附编译器错误码 / 复现命令；报告不许写「预计可行」「理论上支持」。
> 编号分段：`M*` = MoonBit 语法演进（跨项目通用）· `I*` = image 项目特有。同号不复用。

---

## M 系列 · MoonBit 语法演进（moon 0.1.20261104 实测）

### M1 `try?` 语法已移除

- **现象**：`match try? f() { ... }` 编译失败。
- **判别**：编译器直接提示 `try? has been removed. Replace 'try? expr' with 'try Ok(expr) catch { e => Err(e) }'`。
- **修法**：`let r : Result[T, E] = try { Ok(f()) } catch { e => Err(e) }`。
- **来源**：【实测】moon check 编译错误。
- **可自动化**：✅。

### M2 `inspect!` 宏已移除，且 `inspect` 的 Show 版本已弃用

- **现象**：`inspect!(expr, content=)` 解析错 `unexpected f!(..)`；`inspect` 对 `Result` 类型触发 `[0020] deprecated: Use Debug instead of Show for debugging purposes`（note 指向 `moonbitlang/core/builtin/show.mbt:357`）。
- **根因**：moonbitlang/core 将 `Result` 的 `Show` 弃用——调试场景转向 `Debug`（`debug_inspect`）。
- **判别**：inspect 快照断言在 CI `--deny-warn` 下变红。
- **修法**：断言改 `to_string()` / 插值；或实现 `Debug` 后用 `debug_inspect`。
- **来源**：【实测】astrolabe 侧对照实验（3002 + 4018 双实锤，本包未用 inspect 但语法演进出口同源）。
- **可自动化**：✅。

### M3 命名参数传值语法是 `label=`，不是 `label~=`

- **现象**：`[3016] The syntax 'label~=..' is invalid, the correct syntax is 'label=..'`。
- **修法**：`label="value"`。
- **来源**：【实测】moon check 编译错误。
- **可自动化**：✅。

### M4 `not(expr)` 已弃用

- **现象**：`[0020] deprecated: Use !expr instead`。
- **修法**：`!expr`。
- **来源**：【实测】moon check 警告（--deny-warn 下为错误）。
- **可自动化**：✅。

### M5 `StringBuilder::new()` 已弃用

- **现象**：`[0020] deprecated: Use 'StringBuilder()' instead`。
- **修法**：`let buf : StringBuilder = StringBuilder()`。
- **来源**：【实测】moon check 警告。
- **可自动化**：✅。

### M6 MoonBit trait 不支持类型参数

- **现象**：`pub trait Name[A] { ... }` 编译错 `[3002] unexpected '['`；impl 处 `Name[T] for Type[T]` 同样拒绝。
- **根因**：MoonBit trait 无类型参数化能力——"实现类型与结果类型分离"的抽象不可表达。
- **修法**：函数式扩展点（裸函数作参数）或 Self 绑定；见 walkzzz/astrolabe `core/parser_like.mbt` 设计说明（同作者实测记录）。
- **来源**：【实测】astrolabe v0.5.0 ParserLike 类型类方案被编译器推翻。
- **可自动化**：❌ 设计约束。

### M7 `Char` 的 Show 输出无引号

- **现象**：inspect 快照 `content="Ok('a')"` 失败，实际 `Ok(a)`。
- **修法**：快照断言以实测为准（`moon test --update` 自动对齐）。
- **来源**：【实测】astrolabe 侧快照 diff。
- **可自动化**：✅。

### M8 `impl Show` 的隐式方法提升已弃用（implicit promotion）

- **现象**：`[0079] implicit_impl_as_method: The methods output from 'impl Show for X' are implicit promoted... deprecated`。
- **修法**：显式 `pub extend X with Show::{output, to_string}`。
- **来源**：【实测】core/types LoadError 实现 Show 时触发（0079）。
- **可自动化**：✅。

### M9 `Result` 的 Show 已弃用——failable API 推荐 `T raise E`

- **现象**：`[0078] result_error_return: Prefer 'T raise E' for failable APIs`；inspect（Show 版）同源弃用。
- **修法**：API 签名改 `-> T raise E`；测试断言改 `to_string()` / 插值。
- **来源**：【实测】CI --deny-warn 门禁（0078）。
- **可自动化**：✅。

### M10 `many` 零消耗死循环防护：mut 引用比较必须用运行前快照

- **现象**：`many(p)` 中 `p` 零消耗成功（如 `pure`/零宽 `option`）→ 尾递归同位置无限循环挂起；防护比较 `st.offset == state.offset` 因 `State` 为 mut 引用（run 原地推进）恒为 true，反而误伤全部正常匹配。
- **修法**：`p.run` 前取 `let before = state.offset` 快照，运行后比较 `st.offset == before`。
- **来源**：【实测】astrolabe 侧同类实现（walkzzz/astrolabe v0.5.2，M 系列同源）。
- **可自动化**：✅ 正反向测试。

---

## I 系列 · image 项目特有

### I1 `#derive(Debug, Eq)` 要求所有字段类型也实现 Debug/Eq

- **现象**：包装类型含 `Parser[T]`（函数类型，无 Debug/Eq 实现）字段时，`#derive(Debug, Eq)` 报 `[4018] Type X does not implement trait Debug: no 'impl' is defined`。
- **根因**：derive 是逐字段递归约束，函数类型天然无 Debug。
- **判别**：4018 + note "required by derive(Debug) for field ..."。
- **修法**：去掉 derive（包装类型无需相等比较）或为字段类型实现 Debug。
- **来源**：【实测】examples/ext `Traced[T]`（astrolabe 侧同类教训，image 的 CLI 包装类型同理）。
- **可自动化**：✅（编译器）。

### I2 `unused_package` 在 `--deny-warn` 下是错误

- **现象**：`[0029] Error Warning (unused_package): Unused package 'walkzzz/astrolabe/char'`——仅 `_wbtest.mbt` 使用的包被主 moon.pkg 的 import 判未使用。
- **根因**：moon.pkg 的 import 作用域检查不含白盒测试文件。
- **修法**：拆独立 import 块 `import { "..." } for "wbtest"`。
- **来源**：【实测】astrolabe examples/ext moon.pkg（同款 workspace 工程）。
- **可自动化**：✅（CI --deny-warn 即红）。

### I3 workspace 架构的发布陷阱：主模块依赖未发布的子模块 → registry 解析失败

- **现象**：`moon publish --dry-run` 在**解包验证**阶段报 `Failed to resolve registry dependency 'walkzzz/image.core' for module 'walkzzz/image.mbt': module was not found in the registry`（六连报）。
- **根因**：本地 moon.work 组合解析成功，但 publish 的干净环境验证从 registry 拉子模块——子模块从未发布。
- **判别**：dry-run 输出的 `Caused by: Failed to resolve registry dependency` 清单。
- **修法**：**按依赖顺序发布子模块**（core → codec → process → photography/vision → domain），每步之间 `moon update` 刷新本地 registry 索引（否则下一步仍找不到刚发布的依赖），最后发主模块。
- **来源**：【实测】0.6.0 发布（2026-11-13，7 步全部 200 OK）。
- **可自动化**：❌（发布编排，人工执行；可写脚本自动化依赖顺序——下赛期）。

### I4 mooncakes 版本占用 409：CHANGELOG 历史版本 ≠ 已发布版本

- **现象**：`Server status: 409 Conflict, detail: The version you are attempting to upload (0.2.0) is duplicated with an existing version`。
- **根因**：本地 CHANGELOG/历史 commit 记录过的版本号，mooncakes 上可能已发布或未发布——**两套记录不同步**（astrolabe 的 0.3.0/0.4.0 是本地条目但 mooncakes 未占用；image 的 0.5.0 是真占用）。
- **判别**：`moon publish --dry-run` 的 409；或抓取 `mooncakes.io/docs/<owner>/<pkg>/` 页面版本列表（唯一事实源）。
- **修法**：版本 bump 到页面列表中未占用的下一个号；CHANGELOG 未发布条目并入实际发布版本。
- **来源**：【实测】astrolabe 0.2.0 409（页面核查后终定 0.5.0）；image 0.5.0 409（bump 0.6.0）。
- **可自动化**：❌（可脚本化页面抓取——下赛期）。

### I5 coverage 口径：`moon coverage analyze` 的输出是"未覆盖行数"

- **现象**：badge 声称 90.4%，实测输出 `Total: 4878 uncovered line(s) in 311 file(s)`——数字对不上？
- **根因**：coverage 报告的是**未覆盖行**，百分比 = 1 - 4878/50812（可执行行总数）≈ 90.4%——口径换算后才与 badge 一致。
- **判别**：未覆盖行数反推百分比。
- **修法**：badge/文档注明口径（"90.4% = 1 - 4878/50812"），或 CI 中输出换算后的百分比。
- **来源**：【实测】moon coverage analyze 实测（2026-11-13）。
- **可自动化**：✅（脚本换算并断言与 badge 一致——check_docs.mjs 已覆盖）。

### I6 `Bytes` 构造与 `Byte` 类型转换

- **现象**：构造 `Image.data : Bytes` 时不确定 API（`Bytes::new` 不存在）。
- **修法**：`let buf : Array[Byte] = []; buf.push((x % 256).to_byte()); Bytes::from_array(buf)`——`Int32::to_byte()` 转换。
- **来源**：【实测】bench_real.mbt make_gradient。
- **可自动化**：❌（API 知识）。

### I7 主模块聚合器也可能有自己的包

- **现象**：workspace 主模块（walkzzz/image.mbt）根目录存在 `moon.pkg`（import 为空）——根包是合法包，可直接承载 bench/CLI 代码。
- **修法**：根 `moon.pkg` 加 import（如 bench 需要的子模块包）后即可在根包写代码。
- **来源**：【实测】bench_real.mbt（根包 bench 块）。
- **可自动化**：❌。

---

## 维护规则（照 flutter-ohos-expert 准入流程）

1. 新条目只收"复现过并修好"的，附编译器错误码或测试红绿证据，标【实测】。
2. 编号从各段最大号往后接（M* / I*），不跨段复用。
3. M 系列与 astrolabe/docs/pitfall-catalog.md 的 M 系列同源（两项目各自收录）；I 系列项目特有。
