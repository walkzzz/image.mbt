# 发布与分发

> 本页只讲**怎么把 `walkzzz/image.*` 发到 mooncakes 让下游 `moon add` 能用**，以及 `moon publish --dry-run` 到底在校验什么。
> 当前状态：**已发布 0.1.32**（2026-11-28，十一个模块齐发，`publish.ps1` 逐环 `moon update` 后全部 200 OK，registry 复核 11 包均 0.1.32；CI run 46119714490 全绿）。dry-run 结构性阻塞（依赖钉）已闭环，下游验收见文末。

## 一、十一个模块与发布顺序

工作区是 1 根 + 6 原子子模块 + 4 场景入口模块（S16 起），依赖是单向的（子模块不反向依赖根；场景入口只依赖原子模块）：

```
image.core        ← 谁都不依赖（types / testgen / error 基元）
image.codec       ← core
image.process     ← core, codec
image.photography ← core, codec, process
image.vision      ← core, codec, process
image.domain      ← core, codec, process, vision
image.mbt（根）   ← 上面全部 + moonbitlang/x
image.doc         ← core, codec, vision
image.media       ← core, codec, process, domain
image.commerce    ← core, codec, process, domain, photography
image.pro         ← core, codec, process, photography, vision, domain
```

**必须按上表从上往下逐个发**，同一版本号（0.1.x）。前 7 环（原子 + 根）是原有发布链，后 4 环（场景入口）只依赖原子模块、彼此无依赖，可任意顺序。任一环落后一版，下游编译就会撞 API 缺失——`check_version.mjs` 现在一次校验 **11 个 `moon.mod`**。

## 二、`moon publish --dry-run` 实际在校验什么（2026-11-25 实测）

它不只是打 zip，会：

1. 跑 `moon check`（本仓库 176–177 个 task）；
2. 把生成的 `_build/publish/walkzzz-image.mbt-<ver>.zip` 解到 `_build/publish/verify/mooncake_publish_checkXXXX/`；
3. **在那个空目录里重新 `moon check`** —— 此时依赖**不是工作区路径，而是 registry 缓存里已发布的包**。

第 3 步是关键：**它验的是"下游装到的组合"能不能编**。所以本地全绿 ≠ dry-run 能过。

### 曾经踩到的坑（已修）

根 `moon.mod` 的依赖钉长期停在 `@0.1.1`，但工作区已经到 0.1.7。dry-run 于是拉 `image.core@0.1.1` 来编 0.1.7 的代码，一次报 **56 个 error**：

| 报错 | 真实原因 |
|------|----------|
| `Value encode_webp_lossless not found in package codec/lib` | `image.codec` 0.1.7 才加的函数，0.1.1 没有 |
| `The type @types.ImageError is undefined` | `imgcli` 用的错误模型是 S04 之后才有的 |
| `The type/trait @types.DecodeLimits is not found` | 同上，`DecodeLimits` / `decode_with_limits` 都是后加的 |
| `there is no record definition with the fields: max_pixels...` | 拿旧版结构体字面量编新版 |

修法：依赖钉跟着版本走。现在由工具链守护，不靠人记：

- `node scripts/bump_version.mjs --to 0.1.8` 会同时改 7 个 `moon.mod` 的 `version` **和**每个 `moon.mod` 里 `"walkzzz/image.*@x.y.z"` 的钉；
- `node scripts/check_version.mjs` 第 12 项（`moon.mod dep pins`，11 个 `moon.mod` 的 37 处钉）一旦发现钉与版本不一致就红，并打印 `image.codec/moon.mod: walkzzz/image.core@0.1.1 != 0.1.7` 这种定位信息。

### 现在的残余阻塞与正确节奏

只剩顺序问题：registry 里没有 0.1.7 的子模块，dry-run 自然拿不到。

**关键：每发完一层要 `moon update` 一次，再发上一层。** 因为 verify 解析依赖读的是 registry 索引 + 本地缓存，发完 `image.core@0.1.7` 之后不刷新，上层 `image.codec` 的 verify 还是看不到它，会继续报"找不到 `walkzzz/image.core@0.1.7`"。

```
cd image.core       moon publish  →  cd ..  moon update
cd image.codec      moon publish  →  cd ..  moon update
cd image.process    moon publish  →  cd ..  moon update
cd image.photography moon publish →  cd ..  moon update
cd image.vision     moon publish  →  cd ..  moon update
cd image.domain     moon publish  →  cd ..  moon update
cd .          （根） moon publish
```

反例：一次把六个全发完再 `moon update`，中间四层的 verify 会连锁失败，且失败后**该版本号已占位**，要改只能升版本。

## 三、发布前门禁（全绿才发）

```bash
node scripts/check_version.mjs            # 22 项（11 个 moon.mod + 依赖钉 + npm + Dart 绑定 + 门面/CLI/playground/首页/徽章）
node scripts/check_docs.mjs               # 0 failed
node scripts/gen_api_index.mjs --check    # api_index 与源码一致
moon check --deny-warn --target all
moon test --target all                    # 四目标
node scripts/dogfood.mjs > _build/proto/dogfood_report.json   # CLI 48 操作 + 8 探针
node scripts/mcp/smoke.mjs                # 33 用例
```

## 四、打包内容（事实记录）

zip 里会带上非库代码：`bench_real.mbt`、`examples/quickstart/`、`imgcli/`、各包 `*_test.mbt`。它们不影响下游（不 import 就不会编），但会让 verify 阶段把这些也一起编——这正是本轮 56 个错里混着 `bench_real.mbt` / `examples/quickstart` 的原因。若要"发布包只含库"，需要研究 `moon.mod` 的排除机制，暂列为待评估，不阻塞发布。

## 五、没发布时下游怎么用

| 方式 | 命令 | 说明 |
|------|------|------|
| 路径依赖 | `moon add --path ../image.mbt` | 本地调试首选，改代码立刻生效 |
| git 依赖 | `moon add walkzzz/image.mbt@<git-url>` | 需要仓库公开且版本标签齐全 |
| 工作区共享 | 把自己的包放进本 workspace | 多模块联调最快 |

`examples/quickstart` 就是"下游视角"的最小验证：只 import `image.core/types` + `image.codec/lib` + `image.process/transform` 三个包，不碰根门面、不碰文件系统。

## 六、下游验收记录（2026-11-25，0.1.7 首发）

在一个**空的非工作区项目**里装公开包，验证"别人拿到的是能用的组合"：

```powershell
mkdir downstream\src
# moon.mod: name = "demo/downstream" / version = "0.1.0"（注意：不能写 edition 键，moon 会报 Unexpected key）
moon add walkzzz/image.mbt@0.1.7
moon add walkzzz/image.core@0.1.7
moon add walkzzz/image.codec@0.1.7
moon add walkzzz/image.process@0.1.7
moon run src --target native
```

实测输出（`src/moon.pkg` 只 import `types` / `codec/lib` / `transform` 三个包）：

```
webp    124 B  ch=4  diff=0
png     125 B  16x12 ch=4
downstream-ok=true
```

### 验收中发现的两条下游摩擦（已写进 README）

1. **只 `moon add` 根模块，不能直接 import 子模块包**。错误原文：
   `Import walkzzz/image.core/types@0.1.7 exists in global environment, but its containing module is not imported by demo/downstream@0.1.0`。
   处理：用哪个子模块就显式 add 哪个。这是 MoonBit 的模块边界，不是本库的缺陷，但新手必踩，README 已加粗提示。
2. **`moon.mod` 不接受 `edition = "2024"` 键**（`Unexpected key 'edition' found in moon.mod`）；且用 PowerShell `Set-Content -Encoding utf8` 写的 `moon.mod` 带 BOM，会报 `Lexing error at 0..3`。写 `moon.mod` 要用无 BOM 的 UTF-8。

## 七、门面包 `all/`：把"必须 add 子模块"这条摩擦消掉

MoonBit 的规则是**两级声明**：`moon.mod` 声明模块依赖，`moon.pkg` 声明包依赖；只有**直接依赖模块**里的包才能被 import。
`moon add walkzzz/image.mbt` 会把六个子模块全部下载（`moon tree` 可见整棵树），但它们是传递依赖，下游直接 import `walkzzz/image.codec/lib` 就会被拒：

```
Import walkzzz/image.core/types@0.1.8 exists in global environment,
but its containing module is not imported by demo/two@0.1.0, thus cannot be imported by its package 'src'
```

**解法不是让下游多写几条 add，而是在根模块里放门面包。** `walkzzz/image.mbt/all` 用 `pub using` 把 types / 编解码 / 变换的高频 API 再导出一次
（`pub using` 带 `pub` 即为重新导出，见 `docs/moonbit-language-overview.md` 第 4745 行）。下游 import 的是**直接依赖（根模块）里的包**，于是单条 add 就够。

### 验证（workspace 双对照，2026-11-25）

用 `moon.work` 组一个 workspace（成员含本仓七个模块 + 两个 demo），本地解析、不走 registry：

| demo | `moon.mod` 只 import | `moon.pkg` import | 结果 |
|------|----------------------|-------------------|------|
| `demo` | `walkzzz/image.mbt@0.1.8` | `walkzzz/image.mbt/all` | ✅ 跑通：`webp=124B png=125B 16x12 fmt=png ok=true` |
| `demo2` | `walkzzz/image.mbt@0.1.8` | `walkzzz/image.core/types` | ❌ `exists in global environment, but its containing module is not imported` |

注意 demo2 里 `image.core` **也是 workspace 成员**（本地源码可见）却仍然被拒——证明这不是"版本没下到"，而是纯粹的直接依赖边界；demo 走 `all` 才通。

## 八、发布包瘦身（`.moonignore`）与 `[0029]` 根治

`moon.mod` 里的 `include`/`exclude` 已弃用，官方推荐 `.moonignore`（gitignore 语义，只作用于 `moon package` / `moon publish` 的归档，可用 `moon package --list` 预检）。
本仓 `.moonignore` 排掉了开发侧内容：

| 排除 | 原因 |
|------|------|
| `scripts/` | 诊断/门禁/回归脚本，消费者不需要 |
| `docs/`、`examples/`、`spec/`、`benchmarks/` | 文档源、示例、内部规约；基准包含 bench 依赖 |
| `coverage*.txt`、`coverage*.log`、`mutation-report.json` | 本仓覆盖率/变异产物 |
| `moon.work`、`AGENTS.md`、`TEST_REPORT.md`、`rules.md`、`image-mbt-*.md` | 工作区文件与内部规则/路线 |

### 8.1 `[0029] unused_package` 刷屏（2026-11-25，0.1.8 发布时）

第一版 `.moonignore` 连 `*_test.mbt` / `*_wbtest.mbt` 一起排了。结果各包 `moon.pkg` 里 `for "test"` 那段还在、测试文件不在了，
verify 阶段就把这些测试依赖当成**没用到的包**，根包一次刷 5 条、子模块各 1–6 条：

```
Warning: [0029]  Unused package 'moonbitlang/core/bench'
Warning: [0029]  Unused package 'walkzzz/image.core/testgen'
```

**四条修法（0.1.9 落地）**：

1. **测试文件留在包里**——测试既是"测试依赖的使用者"，也让下游能 `moon test` 复跑本库测试。
2. **根包不再 import 任何子包**。根包原本只有 `image.mbt`（文档 + 版本号），那几个 import 全是为了 `bench_real.mbt`；
   把基准拆成独立包 `benchmarks/`（`moon.pkg` 自己 import bench/types/lib/codec/transform），根 `moon.pkg` 清空导入。
3. **删掉重复导入**。有 9 个包在 plain 块和 `for "test"` 块里各导了一次同一个包
   （`barcode` / `production_utils` / `advanced_imaging` / `computational_imaging` / `neural_rendering` /
   `photo_enhance` / `intelligent_vision` / `scene_understanding` / `vlm_multimodal`，全是 `walkzzz/image.core/types`）。
   plain 导入对测试同样可见，所以测试块里那条纯属冗余；发布归档一旦裁掉测试，冗余就变成 `[0029]`。
   常驻门禁 `node scripts/check_pkg_imports.mjs`（`--fix` 可自动清）。
4. **子模块源码目录不排除**（见 8.2 的反例）。

### 8.2 反例：按目录名排除子模块会排空子模块自己

根模块 `source = "."`，根包 zip 会再带一份六个子模块的源码（约 570–1000 个文件）。
直觉修法是 `.moonignore` 加 `image.core/` … `image.domain/`。**实测这是致命的**：

```
$ cd image.core && moon package
Package to ...\walkzzz-image.core-0.1.9.zip
$ (Get-Item ...\walkzzz-image.core-0.1.9.zip).Length
22        # 22 字节 = 空 zip，发布必然失败
```

原因：子模块在 workspace 里执行 `moon package` 时**同样读根级 `.moonignore`**，路径按 workspace 根计算，
一条 `image.core/` 匹配掉该模块自己的全部文件。体积换不来正确性，所以这条排除已撤销并写进 `.moonignore` 注释。

### 8.3 归档零警告自检（`scripts/verify_publish_warnings.mjs`）

不再靠"发布时看运气"。脚本对七个模块逐个：
`moon package` → 解压到 `_build/proto/v2/` → 写一份本地 `moon.work`（其余六个模块当 workspace 成员，绕开未发布的依赖钉）
→ `moon check --deny-warn` → 统计 warning/error。

0.1.9 实测（2026-11-25）：

| 模块 | 归档文件数 | warning | error |
|------|-----------|---------|-------|
| `walkzzz/image.core` | 933 | 0 | 0 |
| `walkzzz/image.codec` | 1115 | 0 | 0 |
| `walkzzz/image.process` | 1169 | 0 | 0 |
| `walkzzz/image.photography` | 983 | 0 | 0 |
| `walkzzz/image.vision` | 1132 | 0 | 0 |
| `walkzzz/image.domain` | 1078 | 0 | 0 |
| `walkzzz/image.mbt`（根） | 1013 条目 | 0 | 0 |

根包 1013 个条目里约 974 个是子模块源码副本，其余是 `all/`、`imgcli/`、`cmd/`、`mp4/`、`playground/`、`mcp/`、
`image.mbt`、`moon.mod`、`moon.pkg`、`pkg.generated.mbti` 与 README/LICENSE 等；无 `_build` / `.mooncakes` 污染。

保留项不变：`playground/`（网页 demo 导出层）、`imgcli/`（CLI + 其测试）、`cmd/`、`mp4/`、`all/`、`mcp/`、README/LICENSE/CHANGELOG。

## 九、S21 收口核对清单（0.1.23）

只做核对，不发布。`moon publish` 需用户明确授权后另起一轮执行。

### 9.1 三份前置文档（S21 交付）

| 文档 | 作用 | 门禁 |
| --- | --- | --- |
| [docs/migration.md](migration.md) | 从 0.1.x 早期 / `walkzzz/image` 0.6.x 迁到 0.1.23 的 3 处改动 | 无（人工核对；示例代码逐条对照 `all/` 与 `image.codec/lib` 的真实符号） |
| [docs/deprecation.md](deprecation.md) | 弃用标注规则、保留窗口、7 条当前清单 | **B12**（`check_deprecations`） |
| [docs/bindings.md](bindings.md) | JS / Dart 两条绑定通道 | CI `bindings` job |

### 9.2 发布前 11 环顺序（同 §一）

1. `walkzzz/image.core` → codec → process → photography → vision → domain
2. 场景 4 环：`walkzzz/image.doc` / `.media` / `.commerce` / `.pro`（可任意顺序，依赖前 6 环）
3. 根模块 `walkzzz/image.mbt` 最后发（依赖上面 10 环）
4. 绑定：npm 包（`npm/`，`prepack` 现编 wasm）随根模块发；Dart 包 `publish_to: none` 不发

### 9.3 全绿门禁（一条命令，缺一不发）

```powershell
node scripts/check_release_ready.mjs              # 15 项全跑（含 moon check / test / pages 构建，约 10 分钟）
node scripts/check_release_ready.mjs --skip-slow  # 12 项快跑（约 10 秒），本地迭代用
```

脚本是本节清单的可执行版本（`scripts/check_release_ready.mjs`），逐条真跑、不看历史结论：

| 组 | 内容 |
| --- | --- |
| 版本 | `check_version`（22 处：11 个 `moon.mod` + 37 处依赖钉 + 门面 + CLI + playground + 首页 + 双 README 徽章 + `npm/package.json` + `bindings/dart/pubspec.yaml`） |
| 文档真值 | `check_docs`（**B1–B14**）、`gen_api_index` / `gen_capabilities` / `gen_scenes --check` |
| 契约 | `check_pkg_imports`、`check_deprecations`、`check_links`、`sync_pages --check`、`check_benchmarks` |
| 绑定 | `npm/test.mjs`（15 项）、`check_dart_binding.mjs --no-build`（6 项） |
| 编译与测试 | `moon fmt --check`、`moon check --deny-warn --target all`、`moon test --target native`（7,432） |
| 展示页 | `check_pages`（49 项，含 playground.js 现编） |

覆盖率门槛由 `docs/coverage.json` 定：当前 38,689/42,950 = **90.10%**，CI 与本地均按 `--min 90` 拦。

### 9.4 下游 30 分钟上手（发布后第一件事；未发布则跳过）

```bash
moon new demo/intro && cd intro
moon add walkzzz/image.mbt
# moon.mod: name = "demo/intro"，不要写 edition 键（会报 Unexpected key）
```

然后按 README「快速开始」跑 `import "walkzzz/image.mbt/all"` 的三行示例；验收点：零报错、零
`[0029]` 刷屏、PNG→JPEG 出图。0.1.7 那次实测记录见 §六。

## 十、发布脚本（`scripts/publish.ps1`）

一条命令按依赖序把 11 环发完，每发一环回根目录 `moon update`，失败即停：

```powershell
.\scripts\publish.ps1                        # 正式发布（启动先 moon update）
.\scripts\publish.ps1 -From image.codec         # 从中断的环续发
.\scripts\publish.ps1 -DryRun                   # 同一顺序只跑 --dry-run（不写 registry）
```

脚本内容就是 11 个目录名 + 一个循环，没有额外机制：`image.core → codec → process → photography → vision → domain → doc → media → commerce → pro → 根`。根包在正式发布前多跑一次 `moon publish --dry-run`（打包最贵，发错了撤不回）。

两条实测事实，决定它只能"先发后验"：

- **`moon publish --dry-run` 不是在本地验，而是在空目录按 registry 依赖重编**。新版本第一环还没上 registry 时，第二环必报 `registry dependency walkzzz/image.core: version 0.1.26 was not found in the registry`。所以完整链路只有真发一环、`moon update` 之后下一环才能验。
- **`moon publish` 不可撤销**：版本号一旦占用不能删，只能升 patch。中途停下的，已发环保留，用 `-From <环>` 从停止的那一环继续。
- **每发一环必须 `moon update`**（2026-11-27 实测）：不上传新索引时，下一环的空目录重编会报 `version 0.1.26 was not found in the registry`，即使上一环其实已发成功。脚本启动第一步与每环成功后各跑一次 update。
- **不要用退出码判成败**：本机实测 `moon publish` 在失败时也返回 0（十环全部停在旧版 registry 却全部"通过"）。脚本改为读输出文本：有 `Server status: 200 OK`（正式）/ `202 Accepted`（dry-run）且无 `Error:` 行即成功。
