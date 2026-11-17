# walkzzz/image.mbt 开发规则全集 / Development Rules

> **用途**：本文件是 walkzzz/image.mbt 项目所有开发规则的权威汇总，供 agent 与人类协作者复用。  
> **维护**：每次新增规则时回写本文件。  
> **优先级**：防跑偏规则 > 项目规则 > 个人偏好。

---

## 一、项目规则 / Project Rules

### R1 — 源码目录
源代码放在 6 个根目录子模块中：core/ codec/ process/ photography/ vision/ domain/

### R2 — 多手段测试
MoonBit 形式化证明 + AI/FAKE/MOCK/E2E 多手段测试，确保无 bug。每个 Sprint 交付前 `moon check` 0 error、`moon test` 全通过。

### R3 — 代码文档注释
代码三级文档注释中英文（包级、类型级、方法级）。

### R4 — README 规范
README 中英文，美化，默认中文；每个一级子包也要 README.md。

### R5 — 迭代路线
先制定 `docs/roadmap.md` 迭代路线，按 Sprint 推进。

### R6 — 提交查证
提交历史有迹可循——每个 Sprint 完成回写 `roadmap.md` 状态 + commit hash。

### R7 — 自动迭代触发
没有任务迭代时，自动触发新的路线迭代计划。

### R8 — 文档治理
每次迭代后进行开源项目文档治理：更新根 README、roadmap、CHANGELOG、子包 README。

### R9 — 经验沉淀
开发经验教训沉淀复用：更新 memory。

### R10 — 一级子包文档
一级子包（如 `process/filter`、`vision/ocr`）也要 README.md。

### R11 — 防跑偏规则（记/锁/回）
每一步做三件事：
1. **记**：把已确认的"规则/负责人/截止时间"写进固定区块；
2. **锁**：遇到与前序约定冲突的新要求，先停下，标注冲突来源，问"谁有权改"；
3. **回**：每完成一环，回写一句"已交付 x，下环依赖 Y"。
禁止在没确认的情况下，把群聊里的某句话当成最终决定。

### R12 — 根包门面
项目根包（`walkzzz/image.mbt`，根目录 `moon.pkg` + `image.mbt`）仅含 version + 文档，不做 reexport。用户直接 import 子模块包（如 `import "walkzzz/image.process/filter"`）。

### R13 — Warning 治理
每次迭代完成后都要进行 **warning 治理**：运行 `moon check` / `moon test`，对所有 warning 逐一处理（修复根因，禁止注释/ignore 压制），目标 0 warning。

### R14 — 占位 todo 检查
所有的占位 todo 项，每次迭代后都要检查是否具备条件完成。若依赖已满足且资源就绪，立即推进；否则标注阻塞原因。

### R15 — 规则输出复用
所有规则输出到 `rules.md`，供 agent 与人类协作者复用。每次新增规则回写。

### R16 — 迭代清理
每次迭代完成后，清理项目中无关文件和临时文件：
- 删除 `_build/` 下的临时构建产物（`moon clean` 可重建）
- 删除根目录及子包中的 `.tmp`、`.bak`、`*.log`、`uncovered.log` 等临时文件
- 删除调试用的临时测试文件
- 清理 git 未跟踪的无关文件（`git clean -nd` 检查，确认后 `git clean -fd` 删除）
- **注意**：清理前先用 `git status` 确认不会删除有价值的未提交工作

---

## 二、核心约束 / Core Constraints

> ⚠️ 以下约束不可违反：

- **禁止引入 C FFI 依赖** — 所有代码必须纯 MoonBit 实现，确保四目标可用
- **禁止目标条件编译** — 不使用 `target == "native"` 等条件分支，四目标共用代码
- **用户直接 import 子模块包** — 根模块仅含 version + 文档，不做 reexport

---

## 三、架构约束 / Architecture Constraints

### 模块层级依赖

```
core (Layer 0, 零依赖)
  ↑
codec (Layer 1, → core)
  ↑
process (Layer 2, → core + codec)
  ↑          ↑
photography  vision (Layer 3, → core + codec + process)
                ↑
            domain (Layer 4, → core + codec + process + vision)
```

- 下层模块不可依赖上层模块
- 同层模块之间不可互相依赖
- 跨模块引用使用完整路径：`"walkzzz/image.core/types"`, `"walkzzz/image.codec/lib"` 等

### moon.work 工作空间

```
members = [".", "core", "codec", "process", "photography", "vision", "domain"]
```

### 根包门面

- `image.mbt`：仅含 `pub let version : String = "0.5.0"` + 文档注释
- `moon.pkg`：空（不导入任何子包）
- 用户通过 `import "walkzzz/image.process/filter"` + `@filter.gaussian_blur()` 直接访问

---

## 四、MoonBit 关键语法约束

- `@math.atan2/cos/sin/pow/exp/log2/log10` 接受 `Double`，需 `.to_double()` 转入，`Float::from_double()` 转出
- `@math.lnf(Float)` 用于 Float 自然对数；`@math.log` **不存在**
- `@math.sqrt` **不存在**，用 `.sqrt()` 方法
- `not(expr)` 已弃用，用 `!expr`
- `1e10F` / `1e-10F` **无效**，用 `10000000000.0F` / `0.0000000001F`
- `(0..<n).rev()` **不支持**，用手动反向循环
- `is_empty()` 已弃用（Option），用 `x is None`
- `clamp` 用标签参数：`.clamp(min=0, max=255)`
- `pub(all) enum/struct` 才允许外部构造
- `Bytes` 不可变，用 `Array[Byte]` 构建后 `Bytes::from_array()`
- `ImageF.data` 是 `Bytes`（IEEE 754 LE），不是 `Array[Float]`
- Int × Float 类型不匹配：需 `Float::from_int(n) * float_val`

---

## 五、迭代流程（每 Sprint 执行步骤）

1. **查架构**：读 `docs/architecture.md` 对应章节，明确范围。
2. **实现**：写源码 + 白盒测试（`_wbtest.mbt`）。
3. **验证**：`moon check` 0 error + `moon test` 全通过。
4. **Warning 治理**（R13）：逐一处理 warning，目标 0 warning。
5. **文档治理**（R8）：更新 README / roadmap / CHANGELOG / 子包 README。
6. **经验沉淀**（R9）：更新 memory。
7. **占位检查**（R14）：检查占位 todo 是否可推进。
8. **迭代清理**（R16）：清理无关文件和临时文件。
9. **提交**（R6）：git commit + 回写 roadmap commit hash。
10. **回写**（R11 回）：回写"已交付 x，下环依赖 Y"。
