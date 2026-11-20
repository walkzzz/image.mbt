# 示例

> 本页只列**真实可运行**的入口，不虚构示例数量。

## 当前可运行入口

| 入口 | 命令 | 覆盖内容 |
|------|------|---------|
| 性能基准（根模块） | `moon bench --target native` | PNG 1024/4096 编解码、resize 基准 |
| MP4 白盒示例 | `moon test mp4 --target native` | ISO BMFF 关键帧定位（stss/stsz/stco/stts） |
| 各模块 README | 见 [architecture.md](architecture.md) 包表 | 各子包的 API 用法片段 |

## 独立示例集

可独立 `moon run` 的示例集（RAW→PNG、resize、EXIF 读取、二维码生成、MP4 关键帧等）正在补齐，落地后本节会给出真实路径与运行命令；在此之前不放任何未验证的示例列表。

## 安全 API

`check_dims`、`safe_mul`、`safe_mul3`、`MAX_IMAGE_DIMENSION` 已集成到所有解码器入口，无需手动调用；自定义代码也可直接调用 `check_dims(w, h, ch)` 校验维度。