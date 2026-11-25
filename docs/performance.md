# 性能基线（x86 / Windows / native release）

> 本文件是**唯一**性能口径。数字由 `moon bench --release --target native` 产生，每次优化后重跑覆盖。
> 初次测量：2026-11-25 | 历史口径（已失效）：[performance-2026-08-arm.md](performance-2026-08-arm.md)

## 环境指纹

| 项 | 值 |
|---|---|
| CPU | 11th Gen Intel Core i5-11400F @ 2.60GHz |
| 内存 | 31.8 GB |
| OS | Windows |
| moon | 0.1.20261117 (eb64713 2026-11-17) |
| moonc | v0.10.21+06da1ed44 (2026-11-16) |
| 编译模式 | `--release`，目标 `native` |

## 实测（2026-11-25）

| bench 项 | 像素量 | 耗时 (mean ± σ) | 轮次 | 吞吐 | 参考量级（成熟实现） |
|---|---|---|---|---|---|
| `png_encode_1024` | 1.048 MP | 48.46 ms ± 0.52 ms | 10 × 3 | **21.6 MP/s** | libspng ≈ 40–60 MP/s |
| `png_decode_1024` | 1.048 MP | 79.14 ms ± 1.51 ms | 10 × 2 | **13.2 MP/s** | libspng ≈ 60–100 MP/s |
| `png_bytes_1024` | — | 36.82 ns | 10 × 100000 | — | — |
| `resize_cover_1024_to_512` | 1024²→512² | 5.23 ms ± 61 µs | 10 × 20 | — | — |
| `png_encode_4096` | 16.78 MP | 784.29 ms ± 17 ms | 10 × 1 | **21.4 MP/s** | — |
| `png_decode_4096` | 16.78 MP | 1.28 s ± 28 ms | 10 × 1 | **13.1 MP/s** | — |
| `jpeg_encode_1024` | 1.048 MP | 534.56 ms ± 13 ms | 10 × 1 | **1.96 MP/s** | libjpeg-turbo ≈ 50–100 MP/s |
| `jpeg_decode_1024` | 1.048 MP | 495.22 ms ± 9 ms | 10 × 1 | **2.12 MP/s** | libjpeg-turbo ≈ 100+ MP/s |
| `webp_encode_1024` | 1.048 MP | 244.83 ms ± 2.48 ms | 10 × 1 | **4.28 MP/s** | libwebp `-lossless -m 4` ≈ 1–3 MP/s |
| `bmp_encode_1024` | 1.048 MP | 8.32 ms ± 255 µs | 10 × 13 | 126 MP/s | 内存带宽级，合理 |
| `qoi_encode_1024` | 1.048 MP | 9.76 ms ± 256 µs | 10 × 11 | 107 MP/s | 合理 |
| `gif_encode_512` | 0.262 MP | 590.53 ms ± 17 ms | 10 × 1 | **0.44 MP/s** | giflib 量级 |

复现：`moon bench --release --target native`（源文件 `bench_real.mbt`）

## 三条结论

1. **PNG 不用动。** 编 21 MP/s、解 13 MP/s，比 libspng 慢 3–5 倍但在纯 MoonBit 里属正常区间，1MP 编 48ms / 解 79ms 够用。原计划的"PNG 解码优化"从 S03 降级为**不做**。

2. **JPEG 是唯一真瓶颈。** 编码 1.96 MP/s、解码 2.12 MP/s，比 libjpeg-turbo 慢 **25–50 倍**：
   - 12MP 照片：编码 **6.4 秒**、解码 **6.0 秒**；
   - 1000 张 12MP 批处理：编码 **1.8 小时**。

   这是 S02 的唯一目标，靶子明确：编码 ≥8 MP/s、解码 ≥8 MP/s（12MP 落到 1.5s 级）。

3. **WebP 编码原先的 331 MP/s 是产物非法导致的假数字**（旧 VP8 实现只写 container，ffmpeg 报 `Invalid partitions`）。S02 换成 VP8L 编码器 `encode_webp_lossless`（palette / predictor / subtract-green 三候选各编码一遍比长度）后，同一 1024² 梯度实测 **244.83 ms / 4.28 MP/s**，产物经 ffmpeg 与 libwebp 解码逐字节比对通过。

## 口径说明

- 全部 **release + native**；wasm/js 目标未测。
- 两次运行间 `png_encode_1024` 出现 62.02 → 48.46 ms 波动（首轮伴随编译），故门禁取**连续 3 次中位数**，单轮数字不入决策。
- 4096² 与 JPEG/GIF 项单次 >0.5s，只跑 1 轮，σ 仅作量级参考。
- 测试图为 `make_gradient(w,h)` 的 RGB 渐变图，熵远低于真实照片：JPEG 在真实照片上会更慢（熵编码更长），基线偏乐观。
- GIF 用 512² 以控制单次耗时，吞吐按 0.262 MP 折算。
