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
| `png_encode_1024` | 1.048 MP | 95.25 ms ± 1.08 ms | 10 × 2 | **11.0 MP/s** | libspng ≈ 40–60 MP/s |
| `png_decode_1024` | 1.048 MP | 132.34 ms ± 2.34 ms | 10 × 1 | **7.9 MP/s** | libspng ≈ 60–100 MP/s |
| `png_bytes_1024` | — | 36.97 ns | 10 × 100000 | — | — |
| `resize_cover_1024_to_512` | 1024²→512² | 5.23 ms ± 61 µs | 10 × 20 | — | — |
| `png_encode_4096` | 16.78 MP | 1.49 s ± 49 ms | 10 × 1 | **11.3 MP/s** | — |
| `png_decode_4096` | 16.78 MP | 2.09 s ± 89 ms | 10 × 1 | **8.0 MP/s** | — |
| `jpeg_encode_1024` | 1.048 MP | 82.90 ms ± 2.31 ms | 10 × 2 | **12.6 MP/s** | libjpeg-turbo ≈ 50–100 MP/s |
| `jpeg_decode_1024` | 1.048 MP | 116.36 ms ± 9.48 ms | 10 × 1 | **9.0 MP/s** | libjpeg-turbo ≈ 100+ MP/s |
| `webp_encode_1024` | 1.048 MP | 244.83 ms ± 2.48 ms | 10 × 1 | **4.28 MP/s** | libwebp `-lossless -m 4` ≈ 1–3 MP/s |
| `webp_decode_1024` | 1.048 MP | 15.68 ms ± 0.33 ms | 10 × 7 | **66.8 MP/s** | libwebp 解码 ≈ 100+ MP/s |
| `bmp_encode_1024` | 1.048 MP | 8.32 ms ± 255 µs | 10 × 13 | 126 MP/s | 内存带宽级，合理 |
| `qoi_encode_1024` | 1.048 MP | 9.76 ms ± 256 µs | 10 × 11 | 107 MP/s | 合理 |
| `gif_encode_512` | 0.262 MP | 590.53 ms ± 17 ms | 10 × 1 | **0.44 MP/s** | giflib 量级 |

复现：`moon bench --release --target native`（源文件 `bench_real.mbt`）

## 三条结论

1. **PNG 慢了一倍，但产物小了 22 倍（S06，2026-11-25）。** 旧实现走 stored deflate + filter 0，几乎不压缩：640×360 一张图输出 **691,678 B**（比原图还大 26 倍）；换成 fixed-Huffman + LZ77 与逐行 filter 择优后降到 **30,243 B**，PIL 逐像素 maxdiff 0。代价是编码 48.46 → **95.25 ms（11.0 MP/s）**、解码 79.14 → **132.34 ms（7.9 MP/s）**——旧解码数字是"解自家 stored 流"，几乎是 memcpy，不代表真实 PNG；现在这个数字才是含有 Huffman 解码的真实开销量级。1 MP 编 95 ms / 解 132 ms，在纯 MoonBit 里仍属可用，换来的是文件体积从"不可用"变成"接近 ffmpeg"：

   | 样本 | 本库 | ffmpeg（同源） | 倍率 |
   | --- | --- | --- | --- |
   | 640×360 RGB testsrc2 | 30,243 B | 26,482 B | 1.14× |
   | 1024² RGB testsrc2 | 129,762 B | 111,803 B | 1.16× |
   | 320×240 RGBA | 11,172 B | — | — |
   | 320×240 灰度 | 4,577 B | — | — |

   四种通道组合（RGB / RGBA / 灰度 / 带 alpha）经 PIL 逐像素比对 maxdiff 均为 0，chunk CRC 全部合法、ffmpeg 可解。后续若要继续压时间，方向是动态 Huffman 与更深的匹配链，不是回退 stored。

2. **JPEG 已从唯一瓶颈变成可用区间（S03，2026-11-25）。** 编码 534.56 → **82.90 ms（12.6 MP/s）**、解码 495.22 → **116.36 ms（9.0 MP/s）**，两项都过 8 MP/s 门禁；12MP 照片估算编码 ≈ 1 s、解码 ≈ 1.3 s。提速手段：
   - 编码：整数 AAN FDCT（等价 libjpeg `jfdctint`，输出 ×8 由量化倒数 `1/(q*8)` 吸收）、定点 RGB→YCbCr、量化倒数预计算、图级复用暂存；
   - 解码：可分离 IDCT + 余弦表全图只建一次、块/空间/浮点暂存复用（不再每块分配）、YCbCr→RGB 整数化、量化表按 table id 独立分配（修掉 `Array::make(4, Array::make(64,0))` 共享实体导致亮度表被色度表覆盖的失真 bug）。
   - 外部校验：产物经 ffmpeg / PIL 解码与源码比对，解码器与 PIL 差 max 3 / mean 0.50。

3. **WebP 编码原先的 331 MP/s 是产物非法导致的假数字**（旧 VP8 实现只写 container，ffmpeg 报 `Invalid partitions`）。S02 换成 VP8L 编码器 `encode_webp_lossless`（palette / predictor / subtract-green 三候选各编码一遍比长度）后，同一 1024² 梯度实测 **244.83 ms / 4.28 MP/s**，产物经 ffmpeg 与 libwebp 解码逐字节比对通过。

4. **WebP 解码是全库最快的路径（2026-11-25 补测）。** 修完 7 处 VP8L 缺陷后，自家编码器产物往返解码 **15.68 ms / 66.8 MP/s**，比 PNG（7.9）与 JPEG（9.0）快 7 倍以上——VP8L 是逐像素整数 predict + LZ77 拷贝 + 色彩缓存查表，没有 Huffman/IDCT 那种逐符号分支。放量到标准产物也一致：`scripts/proto/webp_battery.py` 的 **321 例**（PIL method 0/4/6 × 9 类内容 × 12 尺寸 + ffmpeg `-lossless 1` 三种 lavfi 源）与 Pillow 解码结果逐像素全等。结论：**WebP 无损可以做下游默认存档格式**（编码慢 4×，但解码快、体积小），PNG 留在"必须人人能开"的交换场景。

## 口径说明

- 全部 **release + native**；wasm/js 目标未测。
- 两次运行间 `png_encode_1024` 出现 62.02 → 48.46 → 95.25 ms 波动（首轮伴随编译、S06 换压缩器），故门禁取**连续 3 次中位数**，单轮数字不入决策。
- S06 之前的 PNG 数字（48.46 / 79.14 ms）对应 stored-deflate 产物，已失效；对比历史结论时以本节为准。
- 4096² 与 JPEG/GIF 项单次 >0.5s，只跑 1 轮，σ 仅作量级参考。
- 测试图为 `make_gradient(w,h)` 的 RGB 渐变图，熵远低于真实照片：JPEG 在真实照片上会更慢（熵编码更长），基线偏乐观。
- GIF 用 512² 以控制单次耗时，吞吐按 0.262 MP 折算。
