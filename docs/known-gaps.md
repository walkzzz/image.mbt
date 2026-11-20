# 已知边界与缺口（真话台账）

> 维护者人工维护的诚实台账。README 只描述能力；本文件描述边界与未完成项。
> 当前口径（2026-11-20）：版本 0.1.1 · 6,619 测试 × 4 目标 · 72 包 · 覆盖率 81.3% · prove 8 goals。

## 功能边界

| 编号 | 描述 | 影响面 | 状态 / 规避 |
|------|------|--------|-------------|
| GAP-1 | JPEG progressive 解码未实现 | 格式矩阵 | 仅支持 baseline；progressive 列入下一版本 |
| GAP-2 | AVIF / HEIF / JPEG-XL 仅基础解码，无编码 | 格式矩阵 | 编码面明确不做（JPEG-XL 全特性不做） |
| GAP-3 | 流式解码为「全量解码后逐行分发」，非增量 | lib 流式 API | 真增量解码规划于后续大版本 |
| GAP-4 | PSD 无编码；TIFF Huffman 块不支持；形态学固定 3×3 核 | codec / process | 已在 README 与 docs/notes 标注 |
| GAP-5 | `ImageF` 受 `MAX_TOTAL_PIXELS = 5e8` 约束（峰值内存约 12 GB） | core/types | 解码器入口 `check_dims` 守卫 |
| GAP-6 | `detect_format` 仅识别 9 种 magic；TIFF/ICO/CUR/ICNS/APNG/TGA 需调用对应解码函数 | codec/lib | 文档已说明 |
| GAP-7 | 未实现 GPU / CUDA、音视频流编解码（H.264/音频） | 范围外 | 明确不做 |

## 工程质量边界

| 编号 | 描述 | 现状 | 计划 |
|------|------|------|------|
| GAP-8 | ~~白盒测试仅 1 个~~ **已补强（2026-11-20）** | 379 黑盒 + 5 白盒（mp4 / png_decode / zlib / fft / webp_vp8_decode） | 后续可为 resize / 滤波 / 分割核心算法继续补白盒 |
| GAP-9 | 覆盖率 81.3%（31,668/38,950），低于历史宣称 90.4% | 已按实测纠正 README/notes/proposal | CI 门槛 80.5% 防退化；90% 需专项（webp 解码剩余约 380 行、OCR 约 1,400 行） |
| GAP-10 | Windows 本地 `moon prove` 触发工具链 `\\?\` mkdir bug | `Unix.EINVAL` | 统一走 WSL / CI `prove` job |
| GAP-11 | ~~无 OS 矩阵~~ **受上游限制（2026-11-20 实测）** | 官方安装脚本仅支持 Linux x86_64/aarch64 与 macOS arm64；Windows 二进制 URL 实测返回 403 | 暂不纳入 CI；如官方提供 Windows/macOS 包再补 job |
| GAP-12 | ~~API 参考过时~~ **已闭环（2026-11-20）** | `docs/api_reference.md` 仍为历史快照（1,339 fn / 50 包） | ✅ 新增 `docs/api_index.md`（`scripts/gen_api_index.mjs` 从 72 包 `.mbti` 自动生成：3,748 fn / 710 类型；CI `--check` 防漂移）；旧参考页已标注"历史快照，以 api_index 与 `.mbti` 为准" |
| GAP-13 | ~~示例集缺失~~ **已闭环（2026-11-20）** | `examples/` 7 个可运行示例 | ✅ `raw_to_png` / `resize_demo` / `threshold_otsu` / `format_detect` / `lossless_roundtrip` / `canny_edges` / `gaussian_blur`，内嵌合成数据、零外部依赖 |
| GAP-14 | ~~无 tag / Release~~ **已闭环（2026-11-20）** | tag `v0.1.1` + GitHub Release 已创建；`scripts/publish.sh` 按依赖序发布（上传由维护者执行） | ✅ 版本门禁 `scripts/check_version.mjs`（12 项一致）；mooncakes 0.1.1 上传仍待维护者执行 |
| GAP-17 | VP8 解码要求偶数宽高（YUV420 色度平面对齐）；奇数尺寸返回明确 `DecodeFailed` | 编码器已支持奇数（UV ceil）；解码器正确 ceil 平面支持列入后续 | 已消除 panic；文档注明限制 |

## 平台与工具链

| 编号 | 描述 | 规避 |
|------|------|------|
| GAP-15 | `moon coverage analyze` 在 Windows 本地有路径拼接问题 | 覆盖率基线在 CI（ubuntu）与 WSL 生成 |
| GAP-16 | `moon test` 中 `Int64::from_int` 等弃用警告不影响 `check --deny-warn` | 逐步迁移到 `to_int64()` 等新 API |

## 测试口径

- **6,619 为 native 实测**（2026-11-20）；四目标由 CI `test` job 矩阵实测。
- 差分/往返/边界测试分布在 364 个 `*_test.mbt`；`roundtrip_test.mbt` 覆盖全格式往返。
- 覆盖率、prove、变异、CI 门禁的完整矩阵见 [TEST_REPORT.md](../TEST_REPORT.md)。