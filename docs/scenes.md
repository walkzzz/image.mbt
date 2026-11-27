# 场景入口（S16）

> 一句话：库仍是同一套实现，但对外提供 **4 个场景入口 + 6 个原子模块**，
> 下游按「我要做什么」选入口，不必记 82 个子包路径。
> 归属真值在 [`scenes.json`](scenes.json)，入口包由 `scripts/gen_scenes.mjs` 从 `.mbti` 生成。

## 1. 四个入口

| 场景 | 模块（`moon add`） | 入口包 | 收进来做什么 | 原子包数 | 再导出符号 |
|---|---|---|---|---|---|
| 文档 | `walkzzz/image.doc` | `image.doc` | 扫描件 / 票据 / 证件 / 表单：OCR（含中文、手写、多语种）、条码二维码、文档元数据、表格字段图 | 4 | 504 |
| 媒体 | `walkzzz/image.media` | `image.media` | 编解码与格式分派、元数据读写、几何变换、加密、批量流水线 | 7 | 313 |
| 电商 | `walkzzz/image.commerce` | `image.commerce` | 裁切调色增强、水印、码图、出图前的画质评估 | 6 | 257 |
| 专业 | `walkzzz/image.pro` | `image.pro` | 检测 / 边缘 / 特征 / 频域 / 分割 / 3D、全部视觉与摄影算子、领域包 | 40 | 1,462 |

**摄影场景**不新增模块：既有 `walkzzz/image.photography` 就是 photo 入口（HDR、夜景、景深、虚化、拼接、超分、风格迁移）。

## 2. 模块账（7 → 11）

| 类别 | 模块 |
|---|---|
| 原子（6） | `image.core` · `image.codec` · `image.process` · `image.photography` · `image.vision` · `image.domain` |
| 根 | `walkzzz/image.mbt`（`imgcli` / `mp4` / `all` / `wasm` / `playground` / `examples`） |
| 场景（4） | `image.doc` · `image.media` · `image.commerce` · `image.pro` |

合计 **11 个模块**（不是 roadmap 早期草稿里的 15）：没有为「一场景多包」再拆模块，
场景差异只在入口层体现，避免了 15 个模块带来的发布与依赖维护成本。

## 3. 发布链（11 环）

拓扑序（下依赖上，逐环 bump → publish）：

```text
1 image.core → 2 image.codec → 3 image.process → 4 image.photography
  → 5 image.vision → 6 image.domain → 7 walkzzz/image.mbt（根）
  → 8 image.doc → 9 image.media → 10 image.commerce → 11 image.pro
```

前 7 环是原有链；场景模块只依赖原子模块与根，彼此不互相依赖，故可并行发布（8–11 无所谓顺序）。
每个 `moon.mod` 的 `import` 钉都写 `@0.1.24`，`node scripts/check_version.mjs` 一次校验 11 个文件。

## 4. 生成规则与两个例外

`scripts/gen_scenes.mjs` 读 `scenes.json` + 各原子包的 `pkg.generated.mbti`，产出：

- `image.<scene>/moon.pkg`：`import` 列表（全限定路径 `walkzzz/image.vision/ocr`，别名取末段）；
- `image.<scene>/<scene>_scene.mbt`：每个原子包一段 `pub using @alias { …符号… }`。

两条规则决定「哪些符号不进来」：

1. **`#deprecated` 符号不导出**。导出了会在 `moon check --deny-warn` 下直接失败；
   历史 API 仍可在原子包内使用，弃用策略见 S21。
2. **跨包同名先到先得**。同一场景内两个包导出同名符号时，按 `scenes.json` 的包顺序保留先者，
   后者记入生成文件顶部的「冲突清单」注释——不静默丢失，也不硬改名（改名会破坏 API 稳定性）。
   当前冲突：doc 0 / media 1 / commerce 0 / pro 18。

`--check` 模式只比对不写盘，CI 用它在 `check_docs` 的 B11 门禁里拦漂移（改了 `scenes.json`
或原子包 API 却没重跑生成器，会直接红）。

## 5. 下游怎么用

```text
moon add walkzzz/image.doc          # 只做文档场景
moon add walkzzz/image.mbt          # 全库（含 imgcli/mp4）
moon add walkzzz/image.vision       # 只要视觉细粒度（入口之外的原子模块照常可用）
```

三个粒度并存：**场景入口**（一次拿全）→ **原子模块**（按子系统）→ **单包**
（`walkzzz/image.vision/ocr` 这类深路径仍可直接依赖）。收敛只发生在入口层，没有删包、没有合并实现。
