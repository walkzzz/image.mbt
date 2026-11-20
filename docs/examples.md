# 示例

> 本页列出**真实可运行**的示例（`examples/` 目录），输出为 2026-11-20 native 实测。
> 运行方式：`moon run examples/<name> --target native`（四目标通用，示例无目标限制）。

## 7 个可运行示例

| 示例 | 命令 | 覆盖 API | 实测输出（摘要） |
|------|------|----------|------------------|
| `raw_to_png` | `moon run examples/raw_to_png --target native` | `encode_png_pure` / `decode_png_pure` | `PNG bytes: 82` / `pixel-exact roundtrip: true` |
| `resize_demo` | `moon run examples/resize_demo --target native` | `resize_pure`（上采样/下采样） | `upscale: 8x8 first=0 last=96` / `downscale: 2x2` |
| `threshold_otsu` | `moon run examples/threshold_otsu --target native` | `threshold_otsu` | `black=50 white=50` |
| `format_detect` | `moon run examples/format_detect --target native` | `detect_format` | `png->Png` / `bmp->Bmp` / `qoi->Qoi` |
| `lossless_roundtrip` | `moon run examples/lossless_roundtrip --target native` | BMP / QOI 编解码 | `bmp: 102 bytes, pixel-exact=true` / `qoi: 54 bytes, pixel-exact=true` |
| `canny_edges` | `moon run examples/canny_edges --target native` | `canny_edge` | `canny edges: 52 / 256 pixels` |
| `gaussian_blur` | `moon run examples/gaussian_blur --target native` | `gaussian_blur` | `center before 255` → `after 22` |

每个示例仅内嵌几十字节合成像素，不依赖外部图片文件、网络或 C 库。

## 其他可运行入口

| 入口 | 命令 | 覆盖内容 |
|------|------|---------|
| 性能基准（根模块） | `moon bench --target native` | PNG 1024/4096 编解码、resize 基准 |
| MP4 白盒测试 | `moon test mp4 --target native` | ISO BMFF 关键帧定位（stss/stsz/stco/stts） |

## 安全 API

`check_dims`、`safe_mul`、`safe_mul3`、`MAX_IMAGE_DIMENSION` 已集成到所有解码器入口，无需手动调用；自定义代码也可直接调用 `check_dims(w, h, ch)` 校验维度。