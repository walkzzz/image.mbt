# walkzzz/image.doc

**文档场景入口（S16）**：扫描件、票据、证件、表单类任务需要的 OCR、条码、元数据与字段图像能力，一次 import 全拿到。

```bash
moon add walkzzz/image.doc
```

```moonbit
import "walkzzz/image.doc"
// 之后直接写 @doc.<符号>；符号清单见本包 pkg.generated.mbti
```

## 再导出了什么

| 原子包 | 提供 |
| --- | --- |
| `walkzzz/image.vision/ocr` | OCR 主流程、版面理解、手写与多语种识别、置信度校准 |
| `walkzzz/image.codec/barcode` | 一维码（Code128/Code39/EAN…）与二维码（QR）编码解码 |
| `walkzzz/image.codec/meta` | EXIF / 文档元数据读写 |
| `walkzzz/image.vision/fieldimg` | 字段图像处理（表格线、印章、签字区裁切） |

## 约定

- 本包**只有 `pub using` 再导出，没有实现**；`moon.pkg` 与 `doc_scene.mbt` 由
  `scripts/gen_scenes.mjs` 生成，请勿手改。
- 归属真值在仓库的 `docs/scenes.json`；改归属改那里再重跑生成器。
- `#deprecated` 符号不会出现在入口里（生成器跳过），新代码不会踩到历史包袱。
- 需要深层原子包的其它符号时，仍可单独 `moon add walkzzz/image.vision` 后
  `import "walkzzz/image.vision/ocr"`——两条路径指向同一份实现。

## 文档

- 场景总览：https://github.com/walkzzz/image.mbt/blob/main/docs/scenes.md
- API 索引：https://github.com/walkzzz/image.mbt/blob/main/docs/api_index.md
- 完整签名以本包 `pkg.generated.mbti` 为准。
