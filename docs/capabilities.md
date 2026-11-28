# 能力矩阵（自动生成）

> 本文件由 `node scripts/gen_capabilities.mjs` 生成，**请勿手工编辑**。
> 数据源（全部机器可读）：
> 1. `image.core/types/pkg.generated.mbti` 的 `enum ImageFormat` 变体清单；
> 2. `image.codec/codec/codec_trait.mbt` 的 `Codec for ImageFormat` 四个 impl 体的实际分支；
> 3. 各包 `pkg.generated.mbti` 的公开 API 计数；
> 4. `docs/format_notes.json` 的逐格式备注（只含人类可读说明，缺一条即生成失败）。
>
> 校验：`node scripts/gen_capabilities.mjs --check`（`check_docs` 的 B10 门禁会调用）。

## 格式能力（面向使用者）

> 口径：解码/编码来自 `Codec::can_decode` / `Codec::can_encode`，与 README 表格同源同渲染。

| 格式 | 解码 | 编码 | 备注 |
|:----:|:----:|:----:|------|
| **PNG** | ✅ | ✅ | 8/16-bit，Adam7 隔行扫描 |
| **JPEG** | ✅ | ✅ | baseline，可调质量 |
| **BMP** | ✅ | ✅ | 1/4/8/16/24/32-bit |
| **GIF** | ✅ | ✅ | 动画 GIF 解码/编码 |
| **TGA** | ✅ | ✅ | 含 RLE |
| **PSD** | ✅ | — | Photoshop 文档 **(独家)** |
| **HDR** | ✅ | ✅ | IEEE 754 浮点 **(独家)** |
| **PNM** | ✅ | ✅ | PPM / PGM |
| **QOI** | ✅ | ✅ | Quite OK Image |
| **WebP** | ✅ | ✅ | VP8L 无损编解码：palette / predictor / subtract-green / LZ77；lossy 路径已弃用 |
| **TIFF** | ✅ | ✅ | 无压缩 / LZW / PackBits |
| **ICO** | ✅ | ✅ | 单尺寸 / 多尺寸 |
| **CUR** | ✅ | ✅ | Windows 光标 |
| **ICNS** | ✅ | ✅ | macOS 图标 |
| **APNG** | ✅ | ✅ | 动画 PNG |
| **AVIF** | ✅ | — | AV1 关键帧解码 |
| **HEIF** | ✅ | — | AV1 / HEIC 解码 |
| **JPEG-XL** | ✅ | — | 基础解码 |

## Codec trait 全量口径（含无损位）

> `is_lossless` 是**枚举级**声明：WebP 的 VP8 lossy 编码路径已弃用、当前只承诺 VP8L 无损，
> 但枚举位仍返回 `false`（历史口径），使用时请以「备注」列与实际编解码路径为准。
> `Unknown` 不是真实格式，仅为探测失败占位。

| 变体 | format_name | can_decode | can_encode | is_lossless |
|---|---|:----:|:----:|:----:|
| `Png` | `PNG` | ✅ | ✅ | ✅ |
| `Jpeg` | `JPEG` | ✅ | ✅ | — |
| `Bmp` | `BMP` | ✅ | ✅ | ✅ |
| `Gif` | `GIF` | ✅ | ✅ | ✅ |
| `Tga` | `TGA` | ✅ | ✅ | ✅ |
| `Psd` | `PSD` | ✅ | — | ✅ |
| `Hdr` | `HDR` | ✅ | ✅ | ✅ |
| `Pnm` | `PNM` | ✅ | ✅ | ✅ |
| `Qoi` | `QOI` | ✅ | ✅ | ✅ |
| `Webp` | `WebP` | ✅ | ✅ | — |
| `Tiff` | `TIFF` | ✅ | ✅ | ✅ |
| `Ico` | `ICO` | ✅ | ✅ | ✅ |
| `Cur` | `CUR` | ✅ | ✅ | ✅ |
| `Icns` | `ICNS` | ✅ | ✅ | ✅ |
| `Apng` | `APNG` | ✅ | ✅ | ✅ |
| `Avif` | `AVIF` | ✅ | — | — |
| `Heif` | `HEIF` | ✅ | — | — |
| `JpegXl` | `JPEG-XL` | ✅ | — | — |
| `Unknown` | `Unknown` | — | — | ✅ |

## 模块矩阵（公开 API 面）

| 模块 | 包数 | pub fn | 公开类型/trait |
|---|---:|---:|---:|
| `(root)` | 16 | 2038 | 6 |
| `image.core` | 4 | 152 | 15 |
| `image.codec` | 7 | 249 | 39 |
| `image.process` | 11 | 519 | 71 |
| `image.photography` | 12 | 408 | 84 |
| `image.vision` | 13 | 1507 | 282 |
| `image.domain` | 17 | 992 | 222 |
| `cmd` | 2 | 0 | 0 |
| **合计** | **82** | **5865** | **719** |

统计口径：包 = 含 `pkg.generated.mbti` 的目录（排除 `examples` / `playground` / `scripts`）；
`pub fn` 只计顶层函数；公开类型 = `pub`/`pub(all)` 的 `struct|enum|type` + `pub trait`。
