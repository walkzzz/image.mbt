# 公开基准集（S20）

> 目录：`benchmarks/golden/`（26 张）+ `benchmarks/malformed/`（8 个）+ `benchmarks/manifest.json`（封签）。
> 版本口径：0.1.20 起生效。样本全部由本仓代码合成，见 [`benchmarks/COPYRIGHT.md`](../benchmarks/COPYRIGHT.md)。

## 1. 为什么要有这一套

库有能力表（S19 的真值表）还不够——**「能不能读」需要可复现的证据**。这套基准集解决三件事：

1. **格式覆盖有实物**：13 种可编码格式各至少一张样本，第三方拿到仓库即可复跑，不依赖任何外部下载；
2. **畸形输入有回归**：8 类结构性无效字节，任何一次解码器改动都必须保持「返回 JSON 错误、不 panic、不超时」；
3. **样本可分发**：零第三方素材、体积 1.4 MB 量级、sha256 封签，可随包发布而不引入版权风险。

## 2. 样本清单（golden，26 张）

| 编号 | 文件 | 格式 | 尺寸 | 覆盖点 |
|---|---|---|---|---|
| g01 | `g01_png_gray_grad_512x512.png` | PNG | 512×512 | 8-bit 单通道，好压 |
| g02 | `g02_png_rgb_grad_640x400.png` | PNG | 640×400 | 三通道双轴渐变 |
| g03 | `g03_png_rgba_alpha_512x512.png` | PNG | 512×512 | RGBA + alpha 斜坡 |
| g04 | `g04_png_color_bars_800x450.png` | PNG | 800×450 | 8 色锐边 + 亮度阶梯 |
| g05 | `g05_png_noise_256x256.png` | PNG | 256×256 | 确定性噪声，最坏压缩率 |
| g06 | `g06_ppm_rgb_256x256.ppm` | PNM | 256×256 | ASCII 头 + 二进制体（P6） |
| g07 | `g07_jpeg_photo_1280x720.jpg` | JPEG | 1280×720 | 照片近似（径向亮场 + 区块纹理） |
| g08 | `g08_jpeg_gray_800x600.jpg` | JPEG | 800×600 | 灰度 JPEG |
| g09 | `g09_bmp24_256x256.bmp` | BMP | 256×256 | 24-bit 真彩 |
| g10 | `g10_bmp32_alpha_192x144.bmp` | BMP | 192×144 | 32-bit 带 alpha |
| g11 | `g11_tga24_256x256.tga` | TGA | 256×256 | 24-bit 真彩头 |
| g12 | `g12_gif_static_256x256.gif` | GIF | 256×256 | 静态 GIF + 调色板量化 |
| g13 | `g13_gif_anim4_128x128.gif` | GIF | 128×128 | 4 帧动画（帧间差异明确） |
| g14 | `g14_apng_anim4_160x120.png` | APNG | 160×120 | 4 帧 APNG |
| g15 | `g15_webp_lossless_1024x576.webp` | WebP | 1024×576 | VP8L 无损（大图压缩比） |
| g16 | `g16_tiff8_256x192.tiff` | TIFF | 256×192 | 8-bit 三通道无压缩 |
| g17 | `g17_ico_multi_48x48.ico` | ICO | 48×48 | 多尺寸（48/32/16） |
| g18 | `g18_icns256_256x256.icns` | ICNS | 256×256 | macOS 图标容器 |
| g19 | `g19_hdr_float_192x108.hdr` | HDR | 192×108 | IEEE 754 浮点 + 超白高光斑 |
| g20 | `g20_qoi_160x120.qoi` | QOI | 160×120 | Quite OK Image（RGB 三通道） |
| g21 | `g21_pgm_gray_192x144.pgm` | PNM | 192×144 | 灰度 P5（与 g06 的 P6 分属两种解析路径） |
| g22 | `g22_tga32_alpha_160x120.tga` | TGA | 160×120 | 32-bit BGRA + 描述符 `0x28`（GAP-42 修复分支） |
| g23 | `g23_webp_lossy_odd_33x33.webp` | WebP | 33×33 | VP8 lossy **奇数宽高**（GAP-17 端到端样本） |
| g24 | `g24_qoi_rgba_192x144.qoi` | QOI | 192×144 | QOI 四通道（覆盖 RGBA 差分操作） |
| g25 | `g25_jpeg_progressive_640x400.jpg` | JPEG | 640×400 | **progressive（SOF2）10 条扫描**，首条交错 DC（Al=1）+ AC 首扫/细化全链路 |
| g26 | `g26_jpeg_progressive_restart_480x320.jpg` | JPEG | 480×320 | **progressive + DRI**（restart interval 8 块，212 个 RST 标记），验证 `jpeg_skip_to_restart` 在多扫描下仍清空 DC 预测与 EOBRUN |

> `g25`/`g26` 是本仓编码器暂不具备的能力（编码面只出 baseline，roadmap F-01），故由 `scripts/gen_progressive_samples.py` 生成，
> `manifest.json` 的 `generator` 字段登记为 `scripts/gen_progressive_samples.py`。其余 24 张仍由 `moon run benchmarks/gen` 产出。

**未覆盖的可编码格式**：CUR。原因见 `docs/known-gaps.md`（`encode_cur_pure` 对小尺寸输入的既有缺陷），此处**刻意不生成**，避免把已知缺陷伪装成「基准通过」。

## 3. 样本清单（malformed，8 个）

| 编号 | 文件 | 类别 | 构造方式 | 期望行为 |
|---|---|---|---|---|
| m1 | `m1_corrupt_idat.png` | 数据流损坏 | IDAT 数据头改为 `0xFF`（deflate 保留块类型） | 拒绝（`decode/decode_failed`） |
| m2 | `m2_chunk_len_overflow.png` | 长度越界 | chunk 声明长度 `0x7FFFFFF0`，无数据 | 拒绝（`PNG chunk 数据越界`） |
| m3 | `m3_huge_dims.png` | 声明尺寸炸弹 | IHDR 写 20000×20000，无像素数据 | 拒绝（`budget/limit_pixels`） |
| m4 | `m4_apng_frame_bomb.png` | 帧数声明 | acTL 声明 1,000,000 帧，0 帧实体 | 拒绝（`PNG chunk 数据越界`） |
| m5 | `m5_bmp_bad_enum.bmp` | 非法枚举 | bpp=37 + compression=99 | 拒绝（`decode/truncated`） |
| m6 | `m6_jpeg_app_bloat.jpg` | 元数据段截断 | APP1 声明 65535 B，实际 20 B | 拒绝（`decode/decode_failed`） |
| m7 | `m7_webp_riff_truncated.webp` | 容器声明越界 | RIFF 声明 `0x7FFFFFF0` B、VP8L chunk 声明 `0x7FFFFF` B，实体仅 4 B | 拒绝（`decode/decode_failed`） |
| m8 | `m8_tiff_ifd_oob.tiff` | 索引越界 | TIFF 首 IFD 偏移 `0x7FFFFFF0`，文件仅 16 B | 拒绝（`decode/decode_failed`） |

统一要求：**退出码非 0 + 单行 JSON `ok:false` + 5 秒内返回 + 输出中不得出现 `PanicError` / `moonbit_panic`**。

## 4. 命令

```powershell
# 重生成（仅维护者，native）：会重写 golden/ 与 malformed/
moon run benchmarks/gen

# 构建校验器依赖
moon build --release cmd/imgtool

# 重新封签（写 manifest.json）
node scripts/check_benchmarks.mjs --update

# 常规校验（CI / 发布前）：结构 + sha256 + 逐样本真实解码
node scripts/check_benchmarks.mjs

# 重生成比对（发布前，GAP-53）：重跑生成器并与磁盘逐字节比
node scripts/check_benchmarks.mjs --regen
```

`check_benchmarks.mjs` 的判定链（全部失败即红灯，输出单条 JSON）：

1. 条数契约：golden 26 / malformed 8；
2. 命名契约：`gNN_<内容>_<W>x<H>.<ext>` / `mN_<类别>.<ext>`，且 `W×H` 必须与真实解码尺寸一致；
3. 体积契约：单文件 ≤ 400 KiB、总量 ≤ 1600 KiB；
4. 字节契约：sha256 与 `manifest.json` 完全一致（漂移即红灯）；
5. 探测契约：magic bytes 独立嗅探结果与 `imgtool` 报出的 format 一致（唯一例外是 APNG：字节层为 `png`，语义层为 `apng`）；
6. 行为契约：golden 必须 `ok:true`；malformed 必须被拒绝且无 panic、不超时。
7. 生成器契约（`--regen`）：重跑 `benchmarks/gen` 到 `_build/benchmarks_regen` 后逐文件比 sha256；
   `generator` 标注为外部脚本的样本（当前 `g25`/`g26`）跳过并单独计数。本机增量实测 7.2 s（32 verified / 2 skipped）。

## 5. 本轮由基准集直接暴露并已修的缺陷

| 现象 | 根因 | 修复 |
|---|---|---|
| `imgtool info` 对 HDR/PSD 报 `format:"unknown"` | CLI 内自带一份 `format_name`，缺 `Hdr` / `Psd` 分支 | 补齐分支，默认臂改为 `ImageFormat::..`（禁掉「漏分支静默 unknown」） |
| TGA 文件 `info` 报 `unknown`，`convert` 无法自动分派 | `@lib.detect_format` 按「TGA 无魔数」设计直接返回 Unknown | `@codec.is_tga_format` 扩展为覆盖 1/2/3/9/10/11 + 8/15/16/24/32 bpp + 宽高非零 + 调色板头一致性，并接进 `detect_format` 末位 |
| 畸形 chunk（m2）触发 **panic**（exit `0xC0000409`） | `pos + chunk_len > len` 在 Int32 上回绕为负数，越界检查被绕过 | PNG（8/16-bit）、APNG（两处）、region_decode 改为溢出安全比较 `chunk_len > len - pos` |

| 样本滞后于编码器修复（`g11` 的 TGA 描述符仍是 `0x30`） | 生成器改 `0x20` 后未重生成样本，manifest 只封「文件 ↔ 封签」，不封「文件 ↔ 当前生成器」 | 本轮重生成 `g11`（描述符 `0x30` → `0x20`，全文件仅此 1 字节差）并重封签；口径见 `known-gaps` GAP-53 |
| `imgtool convert` 对 progressive 样本报「JPEG 数据意外结束」/「Huffman 解码失败」，而同一提交的 debug 构建正常 | `scripts/imgtool_path.mjs` 默认取 `_build/native/release`，该目录里的 imgtool 是旧产物（早于 progressive 解码实现） | 重建 `moon build --release cmd/imgtool` 后两张样本均 `ok:true`（对 Pillow 参考解码 max diff 3 / 4、mean 0.51 / 0.57）；教训记入 `docs/known-gaps.md` GAP-53 备注 |

留档：其余 chunked 容器（AVIF / HEIF / ICNS / PSD / BMP / JPEG-XL）的同类比较式见 `docs/known-gaps.md` 的 GAP-35，待逐格式审计。

## 6. 扩容记录

| 日期 | 变更 | 理由 |
|---|---|---|
| 2026-11-26 | 建集：golden 20 / malformed 6 | S20 初版，13 种可编码格式各至少一张 |
| 2026-11-27 | golden +4（P5 灰度 / TGA 32-bit / WebP lossy 奇数 33×33 / QOI 四通道），malformed +2（WebP RIFF 声明越界 / TIFF IFD 越界） | 8-bit 之外的三条解码路径此前无实物；畸形侧只有 PNG/BMP/JPEG，WebP 与 TIFF 容器缺越界回归 |
| 2026-11-27 | golden +2（progressive `g25` / progressive+DRI `g26`） | 此前 24 张全为 baseline，`jpeg_progressive.mbt`（DC/AC 首扫 + 细化 + EOBRUN）没有任何实物回归；同时补 `check_benchmarks --regen` 生成器契约 |

同一轮重生成暴露出 `g11` 的滞后：TGA 描述符仍是 GAP-42 修复前的 `0x30`（应为 `0x20`），全文件仅此 1 字节差——这是「封签只对磁盘敏感」的直接后果（GAP-53）。

体积 1,209,836 B → 1,453,371 B → **1,471,532 B**（上限 1,638,400 B，余量 166,868 B ≈ 10.2%）。再扩容前应先调 `scripts/check_benchmarks.mjs` 的 `LIMITS.total_bytes`，或改用更小的图案（当前单文件最大 `g24` 138,258 B，接近上限的 1/3）。
