# walkzzz/image.media

**媒体场景入口（S16）**：编解码、元数据、几何/色彩变换、加密与流水线，日常"读进来—改一改—写出去"所需的能力一次 import。

```bash
moon add walkzzz/image.media
```

```moonbit
import "walkzzz/image.media"
// 之后直接写 @media.<符号>；符号清单见本包 pkg.generated.mbti
```

## 再导出了什么

| 原子包 | 提供 |
| --- | --- |
| `walkzzz/image.codec/codec` | 18 种格式的纯编解码实现 |
| `walkzzz/image.codec/lib` | 统一加载/保存入口、格式探测、内存预算 |
| `walkzzz/image.codec/util` | 字节/压缩等编解码公共工具 |
| `walkzzz/image.codec/color` | 色彩空间转换与深度转换 |
| `walkzzz/image.process/transform` | 缩放、裁切、旋转、翻转、拼接 |
| `walkzzz/image.domain/encryption` | 图像加密与解密（含隐写/分块方案） |
| `walkzzz/image.domain/pipeline` | 处理流水线与批处理编排 |

## 约定

- 本包**只有 `pub using` 再导出，没有实现**；`moon.pkg` 与 `media_scene.mbt` 由
  `scripts/gen_scenes.mjs` 生成，请勿手改。
- 归属真值在仓库的 `docs/scenes.json`。
- `#deprecated` 符号不导出；WebP lossy 的两个旧入口因此不在入口面上，请用 `encode_webp_lossless`。

## 文档

- 场景总览：https://github.com/walkzzz/image.mbt/blob/main/docs/scenes.md
- 能力矩阵：https://github.com/walkzzz/image.mbt/blob/main/docs/capabilities.md
- 完整签名以本包 `pkg.generated.mbti` 为准。
