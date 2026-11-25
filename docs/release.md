# 发布与分发

> 本页只讲**怎么把 `walkzzz/image.*` 发到 mooncakes 让下游 `moon add` 能用**，以及 `moon publish --dry-run` 到底在校验什么。
> 当前状态：**已发布 0.1.7**（2026-11-25，七个模块齐发，根包 `Server status: 200 OK`）。dry-run 结构性阻塞（依赖钉）已闭环，下游验收见文末。

## 一、七个模块与发布顺序

工作区是 1 根 + 6 子模块，依赖是单向的（子模块不反向依赖根）：

```
image.core        ← 谁都不依赖（types / testgen / error 基元）
image.codec       ← core
image.process     ← core, codec
image.photography ← core, codec, process
image.vision      ← core, codec, process
image.domain      ← core, codec, process, vision
image.mbt（根）   ← 上面全部 + moonbitlang/x
```

**必须按上表从上往下逐个发**，同一版本号（0.1.x）。根模块发出去的那一刻，下游拿到的是"同版本的六件套"，任何一环落后一版，下游编译就会撞 API 缺失。

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
- `node scripts/check_version.mjs` 第 14 项（`moon.mod dep pins`）一旦发现钉与版本不一致就红，并打印 `image.codec/moon.mod: walkzzz/image.core@0.1.1 != 0.1.7` 这种定位信息。

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
node scripts/check_version.mjs            # 14 项（含依赖钉）
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
