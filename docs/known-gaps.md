# 已知边界与缺口（真话台账）

> 维护者人工维护的诚实台账。README 只描述能力；本文件描述边界与未完成项。
> 当前口径（2026-11-25）：版本 0.1.11 · 6,701 测试 × 4 目标 · 77 包 · 覆盖率 83.4% · prove 8 goals。

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
| GAP-8 | ~~白盒测试仅 1 个~~ **已补强（2026-11-20）** | 392 黑盒 + 6 白盒（mp4 / png_decode / zlib / fft / webp_vp8_decode / ean13_gen） | 后续可为 resize / 滤波 / 分割核心算法继续补白盒 |
| GAP-9 | 覆盖率 83.4%（32,862/39,395），低于历史宣称 90.4% | 已按实测纠正 README/notes/proposal | CI 门槛 80.5% 防退化；90% 需专项（webp 解码剩余约 380 行、OCR 约 1,400 行） |
| GAP-10 | Windows 本地 `moon prove` 触发工具链 `\\?\` mkdir bug | `Unix.EINVAL` | 统一走 WSL / CI `prove` job |
| GAP-11 | ~~无 OS 矩阵~~ **受上游限制（2026-11-20 实测）** | 官方安装脚本仅支持 Linux x86_64/aarch64 与 macOS arm64；Windows 二进制 URL 实测返回 403 | 暂不纳入 CI；如官方提供 Windows/macOS 包再补 job |
| GAP-12 | ~~API 参考过时~~ **已闭环（2026-11-20）** | `docs/api_reference.md` 仍为历史快照（1,339 fn / 50 包） | ✅ 新增 `docs/api_index.md`（`scripts/gen_api_index.mjs` 从 73 包 `.mbti` 自动生成：3,748 fn / 710 类型；CI `--check` 防漂移）；旧参考页已标注"历史快照，以 api_index 与 `.mbti` 为准" |
| GAP-13 | ~~示例集缺失~~ **已闭环（2026-11-20）** | `examples/` 7 个可运行示例 | ✅ `raw_to_png` / `resize_demo` / `threshold_otsu` / `format_detect` / `lossless_roundtrip` / `canny_edges` / `gaussian_blur`，内嵌合成数据、零外部依赖 |
| GAP-14 | ~~无 tag / Release~~ **已闭环（2026-11-20）** | tag `v0.1.1` + GitHub Release 已创建；`scripts/publish.sh` 按依赖序发布（上传由维护者执行） | ✅ 版本门禁 `scripts/check_version.mjs`（12 项一致）；mooncakes 0.1.1 上传仍待维护者执行 |
| GAP-17 | VP8 解码要求偶数宽高（YUV420 色度平面对齐）；奇数尺寸返回明确 `DecodeFailed` | 编码器已支持奇数（UV ceil）；解码器正确 ceil 平面支持列入后续 | 已消除 panic；文档注明限制 |
| GAP-29 | `imgtool` CLI / MCP 依赖 native 文件系统（`moonbitlang/x/fs`） | 库包四目标仍可编译，wasm/js 下同签名返回 `decode/unsupported_format` | 浏览器侧出口列 S12；`docs/mcp.md` 已写明 |
| GAP-30 | MCP 层无路径沙箱，读哪由进程用户权限决定 | 接不可信输入存在越权读文件可能 | 用容器/受限账号运行，并同时给 `--mem-budget` |
| GAP-31 | `max_ms` 仍无强制中断（S04 遗留） | 纯同步解码循环无法中途 kill | 需要可让出/可取消的解码循环，未排期 |
| GAP-32 | 根 `moon.mod` 依赖钉停在 `@0.1.1`，与工作区 0.1.7 错配 → `moon publish --dry-run` 拿旧版子模块编新代码，报 56 个 API 缺失 | **钉子部分已闭环（2026-11-25）**：`bump_version.mjs` 同步改写 7 个 `moon.mod` 的 `walkzzz/image.*@x.y.z` 钉，`check_version.mjs` 新增第 14 项守门。残余只差发布顺序：registry 里没有 0.1.7 子模块 | ✅ 钉子现为 `@0.1.7`、门禁 14 项全绿；⏳ 待发六个子模块 0.1.7 后根包 dry-run 转绿（详见 `docs/release.md`） |
| GAP-18 | ~~QR 数据级往返未打通~~ **已闭环（2026-11-21）** | 修复 4 处解码器缺陷（垂直验证起点 / 重复计数与坐标语义 / 版本公式 / 格式信息位序） | ✅ testgen `render_qr` → `decode_qrcode_full` 往返 `hello` 成功 |
| GAP-19 | ~~VP8 inter 帧尺寸取 header（恒 0 → 恒拒绝）~~ **已闭环（2026-11-21）** | inter 帧头无分辨率，改为回退参考帧宽高（保留偶数对齐守卫） | ✅ inter 帧解码 16×16 通过；覆盖率 +88 行 |
| GAP-20 | ~~EAN-13 / UPC-A 无输入样本~~ **已闭环（2026-11-21）** | 解码器 `String` 索引（`data[0] == '0'`）恒为 false，UPC-A 包装层恒返回 None | ✅ 白盒生成器用同包编码表渲染条码；EAN-13 往返 `0490000123457`、UPC-A 往返 `490000123457` 均成功（改用 `[0:1].to_owned()` 比较） |
| GAP-21 | ~~扩展 EXIF 多标签无输入样本~~ **已闭环（2026-11-21）** | 解析器用非法 tag `0x88222/0x88242`（5 位十六进制），ExposureMode/WhiteBalance 永不解析 | ✅ 修正为 `0xA402/0xA403`；testgen `build_exif_jpeg` 构造含 ISO/曝光/光圈/焦距/模式/白平衡/闪光/GPS 的 JPEG APP1，解析 71→142/167 |
| GAP-22 | ~~字母/英文 OCR 无输入样本~~ **部分闭环（2026-11-21）** | testgen 新增 5×7 大写字母点阵 `render_letters`（0=A…25=Z） | ✅ 驱动 `recognize_english` / 阈值 / 字符分割链路；`english_ocr` 模板匹配主路径未提升（289/348 持平），需训练模板或更真实字形后再攻 |
| GAP-23 | ~~Code128 无输入样本~~ **已闭环（2026-11-21）** | 白盒生成器复用同包 `code128_patterns`（Start B + 校验位 + Stop） | ✅ 往返 `HELLO` / `123` 成功；`linear_barcodes.mbt` 77 → 106/150 |
| GAP-24 | OCR 评估/训练纯函数覆盖不足 | `calculate_char_accuracy` / `edit_distance` / `accuracy_stats` / `check_accuracy_threshold` / `calculate_accuracy` / `check_early_stopping` / 训练进度报告 | ✅ 已补测；这些函数多已被现有测试覆盖，覆盖率持平（真实缺口在模板匹配生成路径） |
| GAP-25 | VP8 解码非关键帧/精确残差分支缺输入（文件剩 220 行） | 解码器用非标准 16 位 bool 窗口，标准 libvpx 编码器不匹配 | 字节级构造驱动 intra 预测/残差/滤波分支（2/4/8/16 字节 1 位、32×32/64×64、4 种字节模式 0xAA/0x55/0xF0/0x0F），`webp_vp8_decode` 324 → **400/620**；再往上需按 16 位窗口逆向实现精确 bool 编码（非零 AC 系数/inter 预测），模式化探索已饱和（每变体 +2 行） |
| GAP-27 | **WebP lossy 编码产物非法（2026-11-25 实测）** | `encode_webp_lossy_pure` 只写 frame tag + start code + 宽高，再追加 bool 编码的 DC 值；缺 first partition 的分段/滤波/量化/概率更新、缺 token partition 尺寸表，`first_part_size` 被写成整个 token 流长度 | 证据：ffmpeg 对 64² 与 1024² 产物均报 `Invalid partitions` → `Decoding error: Invalid data found`，流尺寸解析为 unspecified。已修正 README / notes / 源码注释的能力宣称。同病的还有 `encode_webp_lossy_full`（64² 1198 B、128² 2654 B，ffmpeg 同样报 `Invalid partitions`），两者都把整条 bool 流当 first partition，属结构性错误、无法补丁修复。修复路径改为新写 **VP8L 编码器**（设计与日志见 `docs/webp-encoder.md`，排期见 roadmap S02）：M1（literal-only，normal 码表）已在 MoonBit 落地，产物经 ffmpeg 解码并与源图逐字节一致；M2（LZ77 + 频次驱动 Huffman）也已落地，64² 梯度图内环回环与 ffmpeg 外环均为 0 字节差异，纯色/棋盘类内容体积与 libwebp 同档，噪声类内容仍差 4.3 倍（等 M3 变换补齐）。**M4 收口完成（2026-11-25）**：README 已恢复 WebP 编码宣称（能力表只保留 `encode_webp_lossless` 一个入口），`encode_webp_lossy_pure` / `_full` 标 `#deprecated`；bench 里 WebP 项改用 lossless 入口（1024² = 244.83 ms / 4.28 MP/s）。 |
| GAP-28 | ~~VP8L 解码器非 RFC 合规~~ **已闭环（2026-11-25）** | 旧 `read_huffman_tree` 三处偏离 RFC 9649（simple 码表语义 / 绿树字母表 280 / 红蓝 alpha 复用绿树）；新路径 `decode_webp_vp8l_rfc` 迭代中又修掉 7 处：①单符号前缀码零比特，②simple 双符号按符号值排序，③调色板逆变换还原原宽度，④`max_symbol` 按「码的个数」递减且 code 16 重复上一个**非零**码长，⑤色彩缓存 hash 用 32 位无符号右移，⑥predictor 模式 11（Select）按 `p = L + T - TL` 重写，⑦**码长码（19 符号字母表）单叶子同样是零比特**（这条是最后 4 例噪声图全错的根因：码长码只含 16 号符号时每读一个码多耗 1 位，整条流错位） | ✅ `scripts/proto/webp_battery.py`：PIL(libwebp) method 0/4/6 × 9 类内容 × 12 种尺寸 + ffmpeg `-lossless 1` testsrc2/smptebars/mandelbrot 产物，**逐像素与 Pillow 解码结果全等**；另加 Kraft 完整性校验，把「静默全黑」变成可定位 `DecodeFailed` |
| GAP-26 | ~~覆盖率口径可优化~~ **已证伪（2026-11-21）** | 排除 examples/cmd/testgen 的"库覆盖率"为 83.07%，**低于**总口径 83.41%（testgen 自身 267/317 高覆盖拉高总比例） | ❌ 改口径不如实、不提分，不采用；白盒直调 VP8 私有算法（IDCT/WHT/4 种预测/滤波/参考平面）仅 +2 行（已被 intra 分支执行）。当前 **83.4%（32,862/39,395）** 为「生成器 + 白盒」路线可达上限 |

## 平台与工具链

| 编号 | 描述 | 规避 |
|------|------|------|
| GAP-15 | `moon coverage analyze` 在 Windows 本地有路径拼接问题 | 覆盖率基线在 CI（ubuntu）与 WSL 生成 |
| GAP-16 | `moon test` 中 `Int64::from_int` 等弃用警告不影响 `check --deny-warn` | 逐步迁移到 `to_int64()` 等新 API |

## 测试口径

- **6,701 为 native 实测**（2026-11-25）；四目标由 CI `test` job 矩阵实测。
- 差分/往返/边界测试分布在 364 个 `*_test.mbt`；`roundtrip_test.mbt` 覆盖全格式往返。
- 覆盖率、prove、变异、CI 门禁的完整矩阵见 [TEST_REPORT.md](../TEST_REPORT.md)。

