# 迁移指南（0.1.x → 0.1.23）

> 结论先行：从 `walkzzz/image`（0.6.x 及以前）或 0.1.x 早期版本迁到现在，**只需要改 3 个地方**：
> ①模块名与安装命令 ②import 的包路径 ③7 条弃用 API 换成 `_enhanced` / lossless。
> API 签名、错误模型、CLI 的 JSON、npm 导出面都不用动。

## 改动 1：模块名与安装命令（6 → 11 个模块）

| 旧 | 新（0.1.23） |
| --- | --- |
| `walkzzz/image` | `walkzzz/image.mbt` |
| `walkzzz/core` | `walkzzz/image.core` |
| `walkzzz/codec` | `walkzzz/image.codec` |
| `walkzzz/process` | `walkzzz/image.process` |
| `walkzzz/photography` | `walkzzz/image.photography` |
| `walkzzz/vision` | `walkzzz/image.vision` |
| `walkzzz/domain` | `walkzzz/image.domain` |
| —（无） | `walkzzz/image.doc` / `.media` / `.commerce` / `.pro`（S16 场景入口，可选） |

```bash
# 旧
moon add walkzzz/image
# 新（最小可用：一个 add + 门面包 @all）
moon add walkzzz/image.mbt
```

旧名包在 mooncakes 上仍可装但已 deprecated、不再更新（2026-11-17 起 13 个旧版本全部标记），
`--reason` 指向新模块名，可用 `moon deprecate --undo <模块名>` 撤销。

## 改动 2：import 的包路径

规则只两条：`walkzzz/image` → `walkzzz/image.mbt`；`walkzzz/<子模块>` → `walkzzz/image.<子模块>`。
包内的别名也统一简化了口径：

| 旧写法 | 新写法 |
| --- | --- |
| `@image.types` | `@types` |
| `@image.lib` / `@image.load` | `@lib` |
| `@image.codec` | `@codec` |
| `@image.process` | `@pipeline` / `@transform` / `@filter` 等具体子包 |
| `@image.vision` | `@ocr` / `@feature` / `@barcode` 等具体子包 |

深层包仍受 MoonBit 的「import 权限不跟随依赖传递」约束：要用 `walkzzz/image.codec/lib` 这种深层包，
得自己 `moon add walkzzz/image.codec`。只想快速起步就用门面包：

```moonbit
import "walkzzz/image.mbt/all"
// @all.load_from_bytes_auto / @all.save_image_auto / @all.resize_to_cover / @all.crop ...
```

也可以改用场景入口（S16），一次拿到某个场景的全套 API：

```moonbit
import "walkzzz/image.doc"     // OCR / 条码 / 文档元数据 / 表单
import "walkzzz/image.media"   // 编解码 / 元数据 / 变换 / 加密 / 流水线
```

## 改动 3：7 条弃用 API 的替换

| 旧 | 新 | 备注 |
| --- | --- | --- |
| `encode_webp_lossy_pure` | `encode_webp_lossless` | 旧产物不符合 VP8 规范（GAP-27） |
| `encode_webp_lossy_full` | `encode_webp_lossless` | 同上 |
| `verify_image_source` | `verify_image_source_enhanced` | 旧版校验项不足，结论不可用于取证 |
| `understand_document` | `understand_document_enhanced` | 旧版不返回结构化字段 |
| `recognize_handwriting` | `recognize_handwriting_enhanced` | 旧版预处理有缺陷 |
| `recognize_multilingual` | `recognize_multilingual_enhanced` | 旧版无语言回退链 |
| `calibrate_confidence` | `calibrate_confidence_enhanced` | 旧版单一阈值 |

7 条全部处于「保留窗口」内（`0.1.x` 不移除，最早 `0.2.0` 批次）。窗口规则、当前清单与门禁见
[docs/deprecation.md](deprecation.md)。临时只想消告警可以在局部写 `#warnings("-deprecated")`。

## 不用改的部分（有证据，不是口头保证）

| 面 | 结论 | 证据 |
| --- | --- | --- |
| 公开函数签名 | 0.1.0 起零变化 | 0.1.0 CHANGELOG：`moon info` 重新生成 `.mbti` 后「公共 API 符号零变化」 |
| 错误模型 | 未变 | 仍是 `ImageError` + `{code,message,hint}`，见 `docs/error-model.md` |
| CLI | 未变 | 8 子命令 + 单行 JSON，`--dry-run` / `-` 管道照旧，见 `docs/cli.md` |
| npm 导出面 | 未变 | `info / convert / convertMeta / resize / resizeMeta / formats` 六个 |
| 场景入口 | 新增，可选 | 不迁也能用；迁了少写 import |

## 迁移前后对照（15 行）

```moonbit
// 迁移前（walkzzz/image 0.6.x）
import "walkzzz/image/codec"
import "walkzzz/image/process/resize"
import "@image.types"
let png = @image.codec.encode_png(img)
let small = @image.resize.resize_to_cover(png, 320, 200)
let webp = @image.codec.encode_webp_lossy_pure(img)   // ← 弃用

// 迁移后（walkzzz/image.mbt 0.1.23）
import "walkzzz/image.mbt/all"                        // 一个门面包够用；深层包另需 moon add
let png = @all.encode_png(img)
let small = @all.resize_to_cover(png, 320, 200)
let webp = @all.encode_webp_lossless(img)             // ← 替换目标
```

## 自检清单

```powershell
moon check                       # 迁移后应零错误
moon check --deny-warn           # 若仍有 deprecated 告警 → 上表第 3 组还没换完
moon test                        # 自己的测试应仍全绿
```

版本对应：`0.1.0`（重命名）→ `0.1.23`（S21 收口）之间没有任何二次破坏性变更，所有中间版本
只加能力、不改既有签名。
