# 已知边界与缺口（真话台账）

> 维护者人工维护的诚实台账。README 只描述能力；本文件描述边界与未完成项。
> 当前口径（2026-11-27）：版本 0.1.27 · 7,423 测试 × 4 目标 · 82 包 · 覆盖率 90.07% · prove 8 goals。

## 功能边界

| 编号 | 描述 | 影响面 | 状态 / 规避 |
|------|------|--------|-------------|
| GAP-1 | ~~JPEG progressive 解码未实现~~ **已闭环（2026-11-27）**：SOF2 多扫描累积（DC 首扫/DC 细化/AC 首扫/AC 细化、跨扫描 DHT 重定义快照、交错与非交错块网格、EOB run）全通；4 份 Pillow 样本（48×32/32×24/96×72/160×120）逐块系数与同图案 baseline 解码一致，灰度像素差 ≤1 LSB，彩色输出与 baseline 解码逐字节相同 | 格式矩阵 | 剩余边界：4 分量（CMYK）与 arithmetic coding 不支持；progressive 下的 DRI 无样本验证 |
| GAP-2 | AVIF / HEIF / JPEG-XL 仅基础解码，无编码 | 格式矩阵 | 编码面明确不做（JPEG-XL 全特性不做） |
| GAP-3 | 流式解码为「全量解码后逐行分发」，非增量 | lib 流式 API | 真增量解码规划于后续大版本 |
| GAP-4 | PSD 无编码；TIFF Huffman 块不支持；形态学固定 3×3 核 | codec / process | 已在 README 与 docs/notes 标注 |
| GAP-5 | `ImageF` 受 `MAX_TOTAL_PIXELS = 5e8` 约束（峰值内存约 12 GB） | core/types | 解码器入口 `check_dims` 守卫 |
| GAP-6 | ~~`detect_format` 仅识别 9 种 magic~~ **已闭环（2026-11-26）**：TIFF/ICO/CUR/ICNS/APNG 早有分支，TGA 补入末位头部字段判定（`is_tga_format` 覆盖 1/2/3/9/10/11 类型与 8/15/16/24/32 bpp） | codec/lib | S20 基准集暴露后修复，`g11_tga24` 已可 `imgtool convert` 直通 |
| GAP-7 | 未实现 GPU / CUDA、音视频流编解码（H.264/音频） | 范围外 | 明确不做 |

## 工程质量边界

| 编号 | 描述 | 现状 | 计划 |
|------|------|------|------|
| GAP-8 | ~~白盒测试仅 1 个~~ **已补强（2026-11-20）** | 392 黑盒 + 6 白盒（mp4 / png_decode / zlib / fft / webp_vp8_decode / ean13_gen） | 后续可为 resize / 滤波 / 分割核心算法继续补白盒 |
| GAP-9 | ~~覆盖率 82.3%~~ **已闭环（2026-11-27）** | **38,178/42,396 = 90.05%**（S18 专项后实测，S20/GAP-17 轮复测，分母不排除任何文件） | 真值在 `docs/coverage.json`（`coverage@1`），CI 与本地统一 `--min 90`；页面、README、known-gaps 三处由 B3/B6 + `sync_pages --check` 联动 |
| GAP-10 | Windows 本地 `moon prove` 触发工具链 `\\?\` mkdir bug | `Unix.EINVAL` | 统一走 WSL / CI `prove` job |
| GAP-11 | ~~无 OS 矩阵~~ **受上游限制（2026-11-20 实测）** | 官方安装脚本仅支持 Linux x86_64/aarch64 与 macOS arm64；Windows 二进制 URL 实测返回 403 | 暂不纳入 CI；如官方提供 Windows/macOS 包再补 job |
| GAP-12 | ~~API 参考过时~~ **已闭环（2026-11-20）** | `docs/api_reference.md` 仍为历史快照（1,339 fn / 50 包） | ✅ 新增 `docs/api_index.md`（`scripts/gen_api_index.mjs` 从 73 包 `.mbti` 自动生成：3,748 fn / 710 类型；CI `--check` 防漂移）；旧参考页已标注"历史快照，以 api_index 与 `.mbti` 为准" |
| GAP-13 | ~~示例集缺失~~ **已闭环（2026-11-20）** | `examples/` 7 个可运行示例 | ✅ `raw_to_png` / `resize_demo` / `threshold_otsu` / `format_detect` / `lossless_roundtrip` / `canny_edges` / `gaussian_blur`，内嵌合成数据、零外部依赖 |
| GAP-14 | ~~无 tag / Release~~ **已闭环（2026-11-20）** | tag `v0.1.1` + GitHub Release 已创建；`scripts/publish.sh` 按依赖序发布（上传由维护者执行） | ✅ 版本门禁 `scripts/check_version.mjs`（12 项一致）；mooncakes 0.1.1 上传仍待维护者执行 |
| GAP-17 | ~~VP8 解码要求偶数宽高（YUV420 色度平面对齐）~~ **已闭环（2026-11-27）** | 旧实现色度平面按 `w/2 × h/2` 向下取整，奇数尺寸必越界，故加偶数守卫抛 `DecodeFailed`——比编码器（UV 已 ceil）窄一档 | ✅ 关键帧与 inter 两条路径 UV 平面改 `ceil(w/2) × ceil(h/2)`（平面分配、YUV→RGB、帧内/inter UV 预测、参考帧 `uv_size` 与拷贝、环路滤波边界共 13 处），两处守卫删除；`vp8_frame_wbtest` 15×13 奇数用例断言解出 |
| GAP-29 | `imgtool` CLI / MCP 依赖 native 文件系统（`moonbitlang/x/fs`），`-` 管道另依赖 `imgcli/stdio_stub.c` | 库包四目标仍可编译，wasm/js 下同签名返回 `decode/unsupported_format` | 浏览器侧出口列 S12；`docs/mcp.md` 与 CLI `help` 已写明 |
| GAP-30 | MCP 层无路径沙箱，读哪由进程用户权限决定 | 接不可信输入存在越权读文件可能 | 用容器/受限账号运行，并同时给 `--mem-budget` |
| GAP-31 | `max_ms` 仍无强制中断（S04 遗留） | 纯同步解码循环无法中途 kill | 需要可让出/可取消的解码循环，未排期 |
| GAP-32 | 根 `moon.mod` 依赖钉停在 `@0.1.1`，与工作区 0.1.7 错配 → `moon publish --dry-run` 拿旧版子模块编新代码，报 56 个 API 缺失 | **钉子部分已闭环（2026-11-25）**：`bump_version.mjs` 同步改写 7 个 `moon.mod` 的 `walkzzz/image.*@x.y.z` 钉，`check_version.mjs` 新增第 14 项守门。残余只差发布顺序：registry 里没有 0.1.7 子模块 | ✅ 钉子现为 `@0.1.7`、门禁 14 项全绿；⏳ 待发六个子模块 0.1.7 后根包 dry-run 转绿（详见 `docs/release.md`） |
| GAP-33 | wasm-gc 产物无法在 Node 直接实例化 | `use-js-builtin-string` 下每个字符串常量都被编成 `"_"` 模块的 `(ref extern)` 全局导入（本包 460 条）；JS 只能创建可空 `externref`，`WebAssembly.Global` 类型不匹配 → `LinkError` | npm 改走 **wasm MVP 字节 ABI**（导出 `memory`，`Bytes` = i32 指针，0 import，110.6 KiB gzip）；wasm-gc 导出仅保留给 MoonBit 自有 host，S17 若需要再评估 |
| GAP-34 | ~~PNG 家族 chunk 长度整数回绕导致 panic~~ **已闭环（2026-11-26）** | 基准集 m2（chunk 声明 0x7FFFFFF0）实测打出 `0xC0000409`：`pos + chunk_len > len` 在 Int32 上回绕为负，越界检查被绕过 | ✅ `png_decode` / `png_decode_16` / `apng_codec` / `apng_extended` / `region_decode` 改为溢出安全比较 `chunk_len > len - pos`；m2 现返回 `decode/decode_failed` |
| GAP-35 | ~~同型整数回绕隐患未逐格式审计~~ **已闭环（2026-11-26）** | 10 处 `offset + size > len` 全部改为减法形式：AVIF（2）、HEIF（2）、ICNS（2）、JPEG-XL（1）、PSD（2）、BMP 像素地址（1） | ✅ 白盒回归 `codec/bounds_overflow_wbtest.mbt`：声明 `0x7FFFFFF0` 的 ICNS / PSD / AVIF / HEIF / JPEG-XL 均返回 `LoadError`；benchmarks 侧 m2 覆盖 PNG 家族同型 |
| GAP-36 | ~~CLI 把 HDR/PSD 报成 `unknown`~~ **已闭环（2026-11-26）** | `imgcli` 自带一份 `format_name`，缺 `Hdr`/`Psd` 分支，默认臂 `_ => "unknown"` 静默兜底 | ✅ 补齐两分支，默认臂改 `@types.ImageFormat::..`（`--deny-warn` 下未匹配新变体会直接编译失败） |
| GAP-18 | ~~QR 数据级往返未打通~~ **已闭环（2026-11-21）** | 修复 4 处解码器缺陷（垂直验证起点 / 重复计数与坐标语义 / 版本公式 / 格式信息位序） | ✅ testgen `render_qr` → `decode_qrcode_full` 往返 `hello` 成功 |
| GAP-19 | ~~VP8 inter 帧尺寸取 header（恒 0 → 恒拒绝）~~ **已闭环（2026-11-21）** | inter 帧头无分辨率，改为回退参考帧宽高（保留偶数对齐守卫） | ✅ inter 帧解码 16×16 通过；覆盖率 +88 行 |
| GAP-20 | ~~EAN-13 / UPC-A 无输入样本~~ **已闭环（2026-11-21）** | 解码器 `String` 索引（`data[0] == '0'`）恒为 false，UPC-A 包装层恒返回 None | ✅ 白盒生成器用同包编码表渲染条码；EAN-13 往返 `0490000123457`、UPC-A 往返 `490000123457` 均成功（改用 `[0:1].to_owned()` 比较） |
| GAP-21 | ~~扩展 EXIF 多标签无输入样本~~ **已闭环（2026-11-21）** | 解析器用非法 tag `0x88222/0x88242`（5 位十六进制），ExposureMode/WhiteBalance 永不解析 | ✅ 修正为 `0xA402/0xA403`；testgen `build_exif_jpeg` 构造含 ISO/曝光/光圈/焦距/模式/白平衡/闪光/GPS 的 JPEG APP1，解析 71→142/167 |
| GAP-22 | ~~字母/英文 OCR 无输入样本~~ **部分闭环（2026-11-21）** | testgen 新增 5×7 大写字母点阵 `render_letters`（0=A…25=Z） | ✅ 驱动 `recognize_english` / 阈值 / 字符分割链路；`english_ocr` 模板匹配主路径未提升（289/348 持平），需训练模板或更真实字形后再攻 |
| GAP-23 | ~~Code128 无输入样本~~ **已闭环（2026-11-21）** | 白盒生成器复用同包 `code128_patterns`（Start B + 校验位 + Stop） | ✅ 往返 `HELLO` / `123` 成功；`linear_barcodes.mbt` 77 → 106/150。**注**：当时「Stop」用的仍是伪模式，缺陷见 GAP-45（2026-11-27 修复） |
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
| GAP-37 | ~~GitHub Pages 未启用~~ **已启用（2026-11-27）** | 已部署 `https://walkzzz.github.io/image.mbt/`（200，playground.js 267,318 B） | `configure-pages` 的 `enablement` 用 GITHUB_TOKEN 建不了站，首次须手工 `gh api -X POST .../pages -f build_type=workflow`，已写进 `docs/ci-cd.md` |
| GAP-38 | **4 个场景模块此前无 README** | `image.doc/media/commerce/pro` 在 mooncakes 上无说明页（S16 只生成了入口包） | 已补 4 份手写 README（定位/再导出表/生成物约定/文档链接）；`check_links` 的 B13 会把“子模块缺 README”拦成红灯 |
| GAP-39 | **展示页口径曾长期漂移** | `docs/index.html` 停留在 0.1.1 / 6664 / 83.4% / 73 包 | 新增 `scripts/sync_pages.mjs`（真值 = moon.mod + README 徽章 + `docs/coverage.json`），`bump_version` 末尾自动调用，`sync_pages --check` 进 CI |
| GAP-40 | **CI 各作业缺 `moon update`** | 2026-11-27 首次推送后 10 个作业全红在 `Failed to resolve registry dependency moonbitlang/x` | 每个作业装完 CLI 后补 `moon update`；已在 ci.yml / pages.yml 落地并复跑验证 |
| GAP-41 | **`imgtool` 产物后缀跨平台不一致** | Linux runner 输出 `imgtool.exe`，脚本按 `process.platform` 猜 `imgtool` 会误报「未找到」，连带基准门禁与 Dart 自测整条红 | 抽出 `scripts/imgtool_path.mjs`（环境变量 → 固定路径 → `_build` 兜底扫描），benchmarks / dart / release-ready 三处已切换 |
| GAP-42 | ~~TGA 描述符位错（bit4/bit5 混用）+ 4 通道丢 alpha~~ **已闭环（2026-11-27）** | 编码器写 `0x30`（bit4=right-to-left 与 bit5=top-down 同时置位，自相矛盾），解码器把 `& 0x10` 当 top-down。后果：① 本库产出的 TGA 在标准阅读器里水平镜像 ② 标准 top-down 文件（0x20）被当成 bottom-up → 上下翻转 ③ 4 通道输入只写 3 字节/像素（bpp=24，alpha 丢失） | 编码器按通道数定 bpp（4 → 32-bit BGRA，其余 24-bit），24-bit 描述符 `0x20`、32-bit `0x28`；解码器改为 bit5 = top-down、bit4 = right-to-left 逐行镜像；旧测试里 3 处把 `0x10` 注释成「top-down」的构造同步纠正；新增 6 条 `s22_*` 回归（含 4 通道逐字节往返、0x20 不翻转、0x00 翻转、0x30 水平镜像） |
| GAP-43 | ~~`encode_tiff_pure` 缺像素长度守卫~~ **已闭环（2026-11-27）** | `tiff_codec.mbt` 只校验 channels ∈ {1,3,4}，随后按 `width*height*channels` 直接索引 `data[idx]`；数据短于声明尺寸时越界，native 下打出 `0xC0000409`（用户数据即可触发的崩溃） | channels 校验后新增宽高 > 0 与 `data.length() == width*height*channels` 断言，不符抛 `EncodeFailed`；回归测试构造 2×1 RGB 但只给 3 字节，断言抛错而非崩溃 |
| GAP-44 | ~~`superpixel_segmentation` 未校验 `num_superpixels`~~ **已闭环（2026-11-27）** | `step = sqrt(total/num).to_int()`：`num = 0` 除零；`num > total` → `step = 0` → `w / step` panic、`cx += 0` 死循环；另有 `let _ = w / step * (h / step)` 死代码同病。此外距离阈值剪枝会留下 `labels = -1` 空洞 | `num <= 0` 抛 `DecodeFailed`；超量夹到像素总数；`step` 下限 1；删死代码；按网格 `(y/step)*cols + x/step` 兜底 -1；回归测试用 8×8 图 + `num = 0 / 100` 双路径断言 |
| GAP-45 | ~~Code128 Stop 符不符规范（静默错输出）~~ **已闭环（2026-11-27）** | 码表 108 行里 105–107 位置混装：`code128_patterns[105]` 实为 Start A、`[106]` 为 Start B、`[107]` 才是 Start C；真实 Stop（码字 106）是 7 段 13 模块 `[2,3,3,1,1,1,2]`，6 段表装不下，旧实现用伪模式 `[2,1,1,2,2,3]` 冒充并再补 2 个模块 → 生成物在标准扫码器不可读（自解码因同源而「通过」） | 表截为 0–105 共 106 行（103/104/105 = Start A/B/C），新增 `code128_stop_pattern` / 106 常量；解码器改为**先**匹配 7 段 Stop 再匹配码字；生成器直接渲染真 Stop（去掉补丁模块）；新增码表形状断言（每条 6 段 11 模块、Stop 7 段 13 模块）与总模块数 `11×n+13` 断言 |
| GAP-46 | ~~GLCM `entropy` 是占位公式~~ **已闭环（2026-11-27）** | `style_transfer_enhancement.mbt` 里写成 `entropy -= p * p * 0.1`，结果恒 ≤ 0，与「熵」语义相反，且无法与任何文献值对照 | 改为真香农熵 `-Σ p·log2(p)`（`@math.log2`，`moon.pkg` 增 `moonbitlang/core/math`）；断言收紧为 `0 ≤ entropy ≤ 8`（8×8 GLCM 上界 6 bit，留余量） |
| GAP-47 | **CUR 3×2 往返已复测通过（2026-11-27）** | 历史台账曾把 CUR 编解码列为缺陷；本轮用 `encode_cur_pure` + `decode_cur_pure` 实测 3×2 / 4 通道逐字节一致 | 不再挂缺陷；未改动代码 |
| GAP-48 | **QR 生成只覆盖 version 1-L（≤17 字节）** | 生成器固定 21×21 矩阵、单块 RS；超出 17 字节即无法无损编码（修复前静默截断，后改 qr_fits_v1 守卫） | ✅ 生成器扩到 v1–v5-L（单块 RS 19/7、34/10、55/15、80/20、108/26），按载荷长度自动选最小版本，上限 **106 字节**；解码器补 alignment 5×5 功能模块判定，并修正「行/列 8 中间段（9..size-9）属数据区」——旧实现把整行/整列 8 当格式信息跳过，导致 >15 字符的消息位流错位。jsQR 1.4.0 交叉验证 5/5（v1–v5 文本与版本一致）；v6+ 与 M/Q/H 纠错级仍不做 |
| GAP-54 | **QR 解码器把整行/整列 8 当格式信息** | `is_function_module` 对 `row == 8 || col == 8` 一律返回 true；格式信息实际只占行 8 左段 8 位、列 8 上段 7 位与第二副本（行 8 右段 / 列 8 下段），中间 9..size-9 属数据区，被误跳后位流错位 | ✅ 收窄为「行 8 仅 col ≤ 8 或 col ≥ size-8；列 8 仅 row ≤ 8 或 row ≥ size-7」；v1 短文本（≤15 字符）错位落在填充段故未暴露，v2 起 30 字节用例直接失败，修复后 v1–v5 往返全绿 |
| GAP-55 | **QR 区域定位用三 finder 外接框** | v2 起数据区图案会被检测器误报为第三个 finder（v2 实测右上图案应在 x=88，被检出 x=62、s=30），外接框宽度少 6 模块，采样列中心整体压缩，格式位读成 mask 3 | ✅ 改为授 `x+y` 最小 finder 为原点、`origin.size/7` 取整为模块尺寸、ROI 边长 = `qr_size × module_size`；v2 采样矩阵与生成矩阵逐模块比对 0 差异，v1–v5 往返全绿 |

| GAP-49 | **S16 的 4 个场景模块与 S17 的 2 条绑定通道脱离版本列车** | `image.doc/media/commerce/pro` 停在 `0.1.20`、依赖钉同停 `0.1.20`；`npm/package.json` 与 `bindings/dart/pubspec.yaml` 停在 `0.1.23`。`check_version.mjs` 的 `MODULES` 只有 7 项、`bump_version.mjs` 同名单，注释却写「共 11 个」——文档与实现不符，四个 patch 的漂移无人拦 | ✅ 两脚本扩到 11 个 `moon.mod` + 37 处钉 + npm + Dart（门禁 16 → 22 项）；六个文件版本与钉一次性对齐 `0.1.24`；4 个场景包 `moon test` 4/4 通过 |
| GAP-50 | **Dart 绑定的两条错误路径被自己吃掉（S17）** | ① `_call` 里 `(res.stderr as String).trim().split('\n').first` 在 stderr 整段为空时会抛 `StateError`，真实 `code` 被掩盖成无意义异常；② `_ext` 表列了 tiff/hdr/avif/heif/ico/icns/psd 七个只读格式，`convert(format: 'tiff')` 会先 spawn 一次进程再吃 `encode/unsupported_format` | ✅ `_ext` 收窄到 CLI `is_writable` 的 8 个（png/jpeg/bmp/gif/webp/qoi/ppm/tga），只读格式在 Dart 侧直接抛 `process/invalid_argument`；stderr 为空时改用「退出码 N，无 stderr」文案；自测 6 → 8 项（补「不可写格式本地拒绝」「imgtool 缺失抛 `process/spawn_failed`」） |
| GAP-51 | **wasm ABI 的输入指针没有保活（S17 边界）** | `abi_alloc` 用 `Bytes::make(n, 0)` 分配，返回 i32 指针让 JS 直接写；此时 MoonBit 侧已无引用，安全依赖「JS 写完立刻调用」这段同步时序——`abi_convert` / `abi_resize` 内部第一次分配发生在输入已复制之后，所以当前写法安全。若将来把调用改成异步、或一次 staging 多次调用，指针可能在 GC 后被复用 | 已如实记录，未加 pin 机制；真要做多步往返时需补一张保活表（把指针与输入长度登记到 wasm 侧全局，`abi_*` 结束时清空） |
| GAP-52 | **两条绑定通道的元信息面不对称（S17）** | ① JS `info().channels` 恒为 `0`：`abi_info` 只读头部、不解码，wasm 侧把 channels 写死 0，调用方会把 0 当「单通道灰度图」；② Dart 的 `resize` / `convert` 直接吞掉 CLI 回执里的 `width`/`height`/`format`，拿不到输出元信息；③ CLI `resize` 回执本身不回 `channels`（`convert` 有）；④ `docs/bindings.md` 的 JS 示例签名写成 `convertMeta(bytes, 'png')` / `resize(bytes, 64, 64, 'cover')`，与实现的 options 对象不符 | ✅ JS `info` 的 `channels` 改 `null`（显式未知）并加测试；CLI `resize` 回执补 `channels`；Dart 新增 `ImageMeta` + `convertMeta` / `resizeMeta`（复用同一次进程的 JSON，不多起进程），`convert` / `resize` 委托给它们；示例修正为 options 写法；Dart 自测 8 → 10 项、JS 自测 15 → 16 项 |
| GAP-53 | **基准集封签只对磁盘敏感，不对生成器敏感** | `check_benchmarks.mjs` 校验的是「磁盘文件 ↔ manifest」的 sha256 一致，不校验「磁盘文件 ↔ 当前生成器的产出」。后果实测：GAP-42 修好 TGA 描述符（`0x30` → `0x20`）后没有重生成 `g11`，样本仍是旧字节、manifest 照旧封签——六条契约全绿，但样本已不代表当前编码器输出；本轮扩容重生成时才暴露出这 1 字节差 | ✅ 已加机器拦：`check_benchmarks.mjs --regen` 把 `benchmarks/gen` 重跑产物写到 `_build/benchmarks_regen` 后逐文件比 sha256（外部脚本生成的样本按 manifest `generator` 字段跳过），本机增量 7.2 s / 32 verified / 2 skipped；口径同时写进 `docs/benchmarks.md` §4/§6。**未进 CI 主门禁**（+30 s 预算不划算），由发布前手动跑。另注一条实测陷阱：`imgtool_path.mjs` 默认取 `_build/native/release`，该目录里的二进制若早于当前源码（如 progressive 解码实现），会把能解的样本判成解码失败——校验前先 `moon build --release cmd/imgtool` |
| GAP-56 | **progressive 编码只到"能看"的最简形态** | `encode_jpeg_progressive` 产出 4 条扫描（DC 首扫 + 3 条 AC 首扫，`Ah=Al=0`，4:4:4），自解与 Pillow 对 1280×720 样本 max diff 1 / mean 0.48、位流 4 条 SOS 全合规；但**未做** successive approximation（`Ah>0` 细化扫描）、spectral selection 分段（`Se<63`）、EOBRUN 合并、4:2:0 子采样、扫描脚本可配置——因此体积与 baseline 持平（+31 B），只解决"渐进式加载"而非"更小"；另有 ≤ 200 万像素上限（全图量化系数缓存） | ⚠️ 未做（roadmap F-01 的后续，非缺陷）：下一步 EOBRUN 合并是唯一能把体积真正压到 baseline 以下的改动，做完再谈 `Ah>0` 细化 |

## 测试口径

- **7,423 为 native 实测**（2026-11-27，含 S22 新增 9 条、S23 新增 2 条 QR 回归、S20 扩容新增 1 条 g23 位流断言、GAP-1 收口新增 3 条 progressive 测试、GAP-56 的 progressive 编码新增 8 条）；四目标由 CI `test` job 矩阵实测。
- 差分/往返/边界测试分布在 364 个 `*_test.mbt`；`roundtrip_test.mbt` 覆盖全格式往返。
- 覆盖率、prove、变异、CI 门禁的完整矩阵见 [TEST_REPORT.md](../TEST_REPORT.md)。
- 本轮冻结时的未做项（progressive 编码、4 分量与 arithmetic、DRI 样本、色度上采样、基准集 progressive 样本等）已统一转入 [roadmap.md §11 冻结基线遗留](roadmap.md)，不在本表重复。

