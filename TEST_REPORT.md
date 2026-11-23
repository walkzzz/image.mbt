# 测试报告（TEST_REPORT）

> 实测日期：2026-11-20（moon 工具链 latest，native 本机 + WSL 证明通道）。
> 本文件只记录**可复现**的数字与命令；与 README/known-gaps 的口径由 `scripts/check_docs.mjs` 校验。

## 1. 单元/集成测试矩阵

| 目标 | 命令 | 结果 |
|------|------|------|
| native | `moon test --target native` | **6,664 / 6,664 通过**（2026-11-20 本机实测） |
| wasm-gc | `moon test --target wasm-gc` | 6,664 / 6,664（CI `test` job 实测） |
| js | `moon test --target js` | 6,664 / 6,664（CI `test` job 实测） |
| wasm | `moon test --target wasm` | 6,664 / 6,664（CI `test` job 实测） |
| mp4 白盒 | `moon test mp4 --target native` | 4 / 4（`mp4/mp4_wbtest.mbt`） |

- 测试文件 398 个（392 黑盒 `*_test.mbt` + 6 白盒 `*_wbtest.mbt`：mp4、png_decode、zlib、fft、webp_vp8_decode、ean13_gen）。
- 覆盖 18 格式编解码、三级像素深度、resize、色彩/滤波/边缘/特征/分割/频域、计算摄影、OCR/视频、领域应用。

## 2. 覆盖率

| 指标 | 数值 |
|------|------|
| 可执行行覆盖 | **32,847 / 39,395 = 83.4%**（`moon test --enable-coverage --target native` → `moon coverage report -f summary`） |
| 未覆盖行 | 未覆盖行数见 CI artifact `coverage.txt`（`moon coverage analyze`） |
| CI 门槛 | **≥ 80.5%**（`scripts/check_coverage.mjs`，防退化；目标逐版提升至 90%） |

> 历史口径 90.4%（4878/50812）为 2026-11-13 快照；当前实测 83.4%，以本报告为准。README badge 已同步纠正。

## 2.1 本轮修复的缺陷

| 缺陷 | 文件 | 修复 | 回归测试 |
|------|------|------|---------|
| WebP VP8 编码奇数宽高 UV 平面越界（1x1/3x3 `PanicError`） | `image.codec/codec/webp_vp8_encode.mbt` | UV 平面按 `ceil(w/2)×ceil(h/2)` 分配，索引步长一致 | `webp_vp8_encode_test.mbt`（1x1 / 3x3 / 1 通道拒绝） |
| WebP VP8 解码帧头解析错误（合法关键帧被判为非关键帧，编解码不互操作） | `image.codec/codec/webp_vp8_decode.mbt` | 按 RFC 6386 读 3 字节小端 tag（bit0=关键帧、bit5-23=first_part_size），分辨率按 2 字节小端解析 | `webp_vp8_decode_roundtrip_test.mbt`（16x16 / 8x8 / 32x32 / RGBA 自编码往返） |
| WebP VP8 解码奇数宽高崩溃（色度平面按 floor 分配） | `image.codec/codec/webp_vp8_decode.mbt` | 解码器对奇数宽高返回明确 `DecodeFailed`（正确 ceil 平面支持列入后续） | 同上（1x1 / 3x3 期望明确错误） |
| QR finder 垂直验证从中心行开始扫描（检测恒为 0） | `image.codec/barcode/barcode_decode.mbt` | 从图案顶部（中心行 − 3×模块）开始扫描 5 段 | `testgen_driven_test.mbt`（QR 往返 hello） |
| QR finder 重复计数、x/y 语义不一致 | `image.codec/barcode/barcode_decode.mbt` | 统一返回图案左上角坐标，并按 x/y 邻域去重 | 同上 |
| QR 版本估算公式偏移（V 恒偏大 1） | `image.codec/barcode/qr_decode.mbt` | 改为 `V = (中心距 − 10) / 4`（finder 中心距 14+4(V−1)） | 同上 |
| QR 格式信息位序反（MSB/LSB） | `image.codec/barcode/qr_decode.mbt` | 按 ISO 18004 以 positions[i] = 第 i 位（LSB first）读取 | 同上（解析出 L / mask 0） |
| VP8 inter 帧尺寸来源错误（从 header 取 0 → 恒拒绝） | `image.codec/codec/webp_vp8_decode.mbt` | inter 帧无分辨率，回退参考帧宽高（保留偶数对齐守卫） | `webp_vp8_decode_wbtest.mbt`（inter 帧解码 16x16） |
| UPC-A 包装层 `String` 索引比较恒 false（`data[0] == '0'`） | `image.codec/barcode/linear_barcodes.mbt` | 改用切片 `data[0:1].to_owned() == "0"` 与 `data[1:13].to_owned()` | `ean13_gen_wbtest.mbt`（UPC-A 往返 490000123457） |
| 扩展 EXIF 解析器 tag 非法（`0x88222` / `0x88242` 五位十六进制） | `image.codec/meta/exif_extended_read.mbt` | 修正为 `0xA402`（ExposureMode）/ `0xA403`（WhiteBalance） | `exif_roundtrip_test.mbt`（多标签 ISO/曝光/光圈/焦距/GPS 解析） |

## 2.2 测试输入生成器（`image.core/testgen`）

> 另在 `image.codec/barcode` 包内有白盒 EAN-13 渲染器（复用同包 L/G/R 与 parity 表，零复制）。

为覆盖 QR / 条码 / OCR / VP8 等“需要真实输入”的模块，新增纯 MoonBit 生成器包：

| 生成器 | 入口 | 产出 |
|--------|------|------|
| QR | `render_qr(payload, module_px~, quiet_zone~)` / `qr_modules` | 版本 1-L / 字节模式 / 掩码 0 的 21×21 码图（GF(256)+RS 自洽） |
| Code39 | `render_code39(codes, module_px~, height~)` | 与解码器同表的标准条码条纹图 |
| 数字文本 | `render_digits(digits, scale~, margin~)` | 5×7 点阵灰度图 |
| 字母文本 | `render_letters(letters, scale~, margin~)` / `letter_glyph` | 5×7 A–Z 点阵灰度图（驱动英文 OCR 链路） |
| EXIF | `build_exif_jpeg()` | 小端 TIFF + JPEG APP1（ISO/曝光/光圈/焦距/模式/白平衡/闪光/GPS） |
| VP8 | `build_vp8_key_frame(w, h, first_part_size~)` / `build_vp8_inter_frame(first_part_size~)` | RFC 6386 合法帧头 + 零填充分区 |

## 3. 形式化验证

| 项目 | 结果 |
|------|------|
| 包 | `image.core/safe_math`（`proof_enabled = true`） |
| 命令 | `cd image.core && moon prove`（WSL / Ubuntu，Why3 1.6.0 + Z3 4.8.12） |
| 结果 | **1 of 1 packages proved / 8 goals proved** |
| 已证目标 | `safe_mul_ok`、`clamp_pixel_ok`、`dims_valid_pred`、`int_max_ok`、`int_min_ok`、`valid_index`、`valid_2d_index`、`rotate90_identity` |
| 预留谓词 | 8 条（SMT 超时 / 前端限制，清单见 `safe_math.mbtp` 注释） |

> Windows 本地 `moon prove` 触发工具链 `\\?\` mkdir bug（`Unix.EINVAL`）；统一走 WSL 与 CI `prove` job。

## 4. 变异测试（12 点 / 7 包 / 100% KILLED）

命令：`node scripts/mutation_test.mjs --min-kill=80`（CI `mutation` job 同命令）

| ID | 包 | 变异 | 结果 |
|----|----|------|------|
| M01 | image.core/types | `check_dims` 漏检零宽 | KILLED |
| M02 | image.core/types | `check_dims` 边界 65535 误拒 | KILLED |
| M03 | image.core/types | `check_dims` 漏检零通道 | KILLED |
| M04 | image.codec/util | `resize` 漏检零宽输出 | KILLED |
| M05 | image.codec/util | `resize` 最近邻 x 取整偏移 | KILLED |
| M06 | image.process/segment | `threshold_otsu` 方差比较反转 | KILLED |
| M07 | image.process/segment | `otsu_threshold_value` 通道上限放宽 | KILLED |
| M08 | image.codec/codec | BMP 行 4 字节对齐缺失 | KILLED |
| M09 | image.codec/codec | PNG 位深校验反转 | KILLED |
| M10 | image.codec/barcode | Reed-Solomon 纠正计数偏移 | KILLED |
| M11 | image.vision/ocr | 数字 OCR KNN 邻居数默认值漂移 | KILLED |
| M12 | image.domain/watermark | 水印 PSNR 的 MSE 除法变乘法 | KILLED |

- 结果：**12 / 12 KILLED（击杀率 100%）**，报告写入 `mutation-report.json`。
- 过程中发现并修复 3 个测试盲区：resize 零/负尺寸测试的断言被 `try/catch` 吞掉、最近邻下采样只断言尺寸、Otsu 渐变图只断言尺寸。
- 变异点出现 0 次或多次时标记 SKIPPED 并计入总分母，防止"变异点写错也算通过"。

## 5. 性能基准

`moon bench --target native`：根模块 6 项（PNG 1024/4096 编解码、resize），CI `bench` job 回归运行。

## 6. CI 门禁（`.github/workflows/ci.yml`）

| job | 门禁 |
|-----|------|
| `quality` | `moon fmt --check` · 四目标 `check --deny-warn` · `moon info` + `git diff --exit-code -- '*.mbti'` · `check_docs.mjs`（9 断言 + 5 负向自测） |
| `test` | 四目标测试矩阵（native / wasm-gc / js / wasm） |
| `bench` | native 基准 |
| `coverage` | 覆盖率生成 + 80.5% 门槛 + artifact 上传 |
| `mutation` | `mutation_test.mjs --min-kill=80`（12 点 / 7 包） |
| `prove` | Why3 + Z3 + `moon prove` |

## 7. 复现步骤

```bash
moon check --deny-warn --target all
moon test --target all
moon fmt --check
node scripts/check_docs.mjs
moon test --enable-coverage --target native
moon coverage report -f summary
node scripts/check_coverage.mjs coverage-summary.txt --min 80.5
node scripts/mutation_test.mjs --min-kill=80
cd image.core && moon prove   # WSL / Ubuntu
```