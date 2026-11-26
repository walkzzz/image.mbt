# walkzzz/image.commerce

**电商场景入口（S16）**：商品主图/详情页常见的裁切、调色、增强、水印、码图与画质评估，一次 import 全拿到。

```bash
moon add walkzzz/image.commerce
```

```moonbit
import "walkzzz/image.commerce"
// 之后直接写 @commerce.<符号>；符号清单见本包 pkg.generated.mbti
```

## 再导出了什么

| 原子包 | 提供 |
| --- | --- |
| `walkzzz/image.process/transform` | 缩略图裁切、缩放、旋转、拼接 |
| `walkzzz/image.process/color` | 白平衡、饱和度、曲线等调色 |
| `walkzzz/image.process/enhance` | 锐化、降噪、去雾等增强 |
| `walkzzz/image.codec/barcode` | 商品码/二维码与条码生成、识别 |
| `walkzzz/image.domain/watermark` | 可见/半透明水印叠加与检测 |
| `walkzzz/image.photography/quality` | 画质评估（清晰度/曝光/噪点打分） |

## 约定

- 本包**只有 `pub using` 再导出，没有实现**；`moon.pkg` 与 `commerce_scene.mbt` 由
  `scripts/gen_scenes.mjs` 生成，请勿手改。
- 归属真值在仓库的 `docs/scenes.json`。
- 批量化（几百张主图）建议走 `image.media` 的流水线编排，单图处理用本入口即可。

## 文档

- 场景总览：https://github.com/walkzzz/image.mbt/blob/main/docs/scenes.md
- 使用说明：https://github.com/walkzzz/image.mbt/blob/main/docs/notes.md
- 完整签名以本包 `pkg.generated.mbti` 为准。
