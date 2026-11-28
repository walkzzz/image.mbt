# CHANGELOG

> 本文件为变更**摘要**（面向评审与使用者的第一入口）。完整功能迭代历史（v0.1 → v237.0.0，3300+ 行）见 [docs/changelog.md](docs/changelog.md)。

**版本双轨说明**：功能迭代版本（v0.1 → v237.0.0）与 mooncakes 包版本（0.x.y）并行演进；包版本随发布递增，workspace 十一个模块（6 原子子模块 + S16 的 `image.doc/media/commerce/pro` 场景包）版本与依赖钉随主包同步，S17 的两条绑定通道（`npm/package.json`、`bindings/dart/pubspec.yaml`）同号，全部由 `check_version.mjs` 22 项守门。

## [0.1.33] - 2026-11-28

### Added

- **progressive JPEG 逐扫描预览**：新增 `image.codec/codec/jpeg_progressive_preview.mbt`。`decode_jpeg_progressive_previews(data, every_scans)` 每解完 `every_scans` 条扫描就成型一帧，返回 `Array[JpegProgPreview]`（`scan_index` 为 1 起的扫描序号 + 当期 `Image`），末帧恒等于终态解码结果。第 1 条扫描（DC 首扫）即可给出整幅低频轮廓，后续扫描逐位补细节——这是渐进编码唯一真正的用户价值（渐进加载 / 大图先看轮廓）。
- **`jpeg_progressive_scan_count(data)`**：不解码、只取扫描条数（8 段脚本为 8，libjpeg 10 段脚本为 10），便于调用方预分配帧预算。
- **`image.media` 场景包同步重导出**：`type JpegProgPreview`、`decode_jpeg_progressive_previews`、`jpeg_progressive_scan_count`。

### Changed

- `jpeg_decode_progressive` 改用共享的 `jpeg_progressive_ctx`（头部校验 + 网格分配）与 `jpeg_progressive_render`（成型），行为不变——全量 native 7,449 测试与 0.1.32 逐字节一致（末帧断言 `frames[last] == decode_jpeg_pure(bytes)` 逐字节比对）。

### Verified

- 新增 6 条测试：帧数与 `scan_index` 递增、末帧与全量解码逐字节相等、`every_scans=4` 只出 4/8 两帧、纯 DC 首帧细节量显著小于末帧（行内相邻差和 `< 1/4`）、`every_scans<1` 归一、baseline JPEG 拒绝、扫描数查询（8 段 / 10 段）；native 全量 7,449 / 7,449。

## [0.1.32] - 2026-11-28

### Added

- **色度上采样对齐 libjpeg 三角滤波（F-01 最后一项）**：新增 `image.codec/codec/jpeg_upsample.mbt`，按 `jdsample.c` 逐位复刻 `h2v2_fancy_upsample`（权重 9/16、3/16、3/16、1/16）与 `h2v1_fancy_upsample`（3/4、1/4）；边界行列复制钳制。此前 4:2:0 用最近邻（一个色度值铺满 2×2），放大处有方块边缘。
- **baseline / progressive 共用收尾**：新增 `jpeg_planes_to_rgb(header, planes, plane_w, max_h, max_v)`。baseline 走了和 progressive 一样的路——每个分量先铺一张整幅平面（行跨距按 8 对齐），解码结束后统一上采样 + YCbCr→RGB；逐 MCU 的 `jpeg_write_mcu_pixels` 删除（它的近邻取样跨不出块边界，做不了三角滤波）。

### Fixed

- 非上采样分量（如 4:4:4 的 Y）返回时必须携带**真实行跨距**而不是有效宽：137×93 这类宽度非 8 倍数的图，块对齐让 stride=144、有效宽=137，取错会把整幅错位（实测 mean 差 29.89、max 254）。修后回到 5.19。

### Verified

- **解码器与 libjpeg 逐像素对齐**：`g07_jpeg_photo_1280x720`（4:2:0 彩色）对比 Pillow 解码 **mean 0.48 / max 1**（改前 mean 7.66 / max 103）；`g08` 灰度 **0.00 / 0**；`g25` progressive 640×400 **0.49 / max 3**；`g26` progressive+restart 480×320 **0.52 / max 2**。残差只来自 IDCT 取整。
- 自编码自解码三向一致（Q85 4:2:0）：64×48 我们解 3.62 / Pillow 解 3.51；96×96 5.30 / 5.21；137×93 5.19 / 5.09（mean 差，对源图）。
- 新增 6 条白盒测试（`h2v1`/`h2v2` 逐点数值与公式核对、4×4 全表、平面恒定、斜坡行内单调、比例分派与 stride 回传），全量 native **7,443/7,443**。
- 顺带修：progressive 输出改走共享收尾后，`jpeg_progressive_output` 里重复的最近邻取样代码删除（约 60 行）。

## [0.1.31] - 2026-11-28

### Added

- **progressive 扫描脚本可配置 + spectral selection 分段（F-01 收尾）**：新增 `image.codec/codec/jpeg_progressive_script.mbt`。`JpegProgScan { comps, ss, se, ah, al }` 描述一条扫描；`encode_jpeg_progressive_420_scripted(img, quality, script)` 按脚本逐条发射，每条 AC 扫描走"两遍"（先计频自建优化表、再写位流），并以紧邻 SOS 的独立 DHT 段携带自己的表。
- 两个内置脚本：`jpeg_progressive_script_libjpeg()` = **10 段**，对齐 libjpeg `jpeg_simple_progression()`——DC 首扫 `Al=1` → Y 的 `Ss=1..5 Al=2` → Cr 全带 `Al=1` → Cb 全带 `Al=1` → Y 的 `Ss=6..63 Al=2` → DC 细化 → Y `Ah=2 Al=1` → Cr/Cb/Y 逐级细化（亮度最低位最后发）；`jpeg_progressive_script_eight()` = 等价 0.1.30 的 8 段，供对照与回归。
- 语义按 libjpeg `encode_mcu_AC_first` / `encode_mcu_AC_refine` 实现：首扫按 `|c|>>Al` 判零计 run；细化扫 `absv==1` 为新非零（发修正位）、`absv>1` 为旧非零（补发 `absv & 1` 位），EOB 取最后一个 `absv==1` 位置，ZRL 折叠条件 `r>15 && k<=eob`，块尾 `r>0 || BR>0` 计入 EOBRUN。
- CLI：`imgtool convert --jpeg-progressive-10scan`（必须配合 `--jpeg-progressive`，隐含 4:2:0）；`help_text` 与 `docs/cli.md` 同步。

### Fixed

- 新引擎最初只写 AC 表、漏写 DC 标准 DHT，导致自解码在 DC 首扫即报 `JPEG Huffman 解码失败`；改为 SOF2 之后一次性写入 DC 表 0/1 两张后，10 段、纯 DC 脚本、非 16 倍数尺寸全部回环通过。

### Verified

- 10 段与 8 段**解码像素逐字节一致**（64×48，两者量化系数相同，仅扫描组织不同）。
- 10 段实测**不更省**（多扫描各自的 DHT 段与 EOBRUN 重置）：1280×720 Q55 **52,860 B**（8 段 51,837，+2.0%）、Q80 113,762（113,637，+0.1%）；128×128 Q80 1,670（1,540，+8.4%）、Q90 2,063（1,952，+5.7%）。**结论：默认仍走 8 段**，10 段作为可配置脚本（对齐 libjpeg 的渐进层次与互操作）保留。
- 新增 5 条测试（10 段 SOS 参数 `(Ns,Ss,Se,Ah,Al)` 逐条核对、10 段 vs 8 段像素一致、10 段段头开销相对上界、137×93 非 16 倍数往返、纯 DC 脚本）+ 1 条 CLI 测试；全量 native **7,437/7,437**。
- 边界：解码侧 4:2:0 上采样仍是最近邻；`--jpeg-progressive-10scan` 目前只作用于 4:2:0（脚本引擎按 16×16 MCU 组织）。

## [0.1.30] - 2026-11-27

### Added

- **progressive 的 4:2:0 色度下采样（F-01 第四步）**：新增 `encode_jpeg_progressive_420(img, quality)`（`image.codec/codec/jpeg_progressive_encode_420.mbt`，门面 `walkzzz/image.codec/lib` 同步导出）。SOF2 分量表 Y `h=2 v=2`、Cb/Cr `h=1 v=1`，MCU 16×16、每 MCU 6 块；色度先做 2×2 盒式平均降到半分辨再 8×8 DCT 量化。扫描脚本与 4:4:4 版完全相同（8 条：DC 首扫 Al=1 → 3×AC 首扫 Al=1 → DC 细化 → 3×AC 细化），单分量 AC 扫描按各分量有效块网格推进、padding 块只出现在交错 DC 扫描，与解码器 `bw/bh` 口径逐条对齐。
- CLI：`imgtool convert --jpeg-progressive-420`（必须配合 `--jpeg-progressive`，单独给会报错）；`help_text` 与 `docs/cli.md` 同步。

### Verified

- 1280×720 照片 Q55：baseline 79,638 B → 4:4:4 **75,268 B（−5.5%）**、4:2:0 **51,837 B（−34.9%）**（比 4:4:4 再降 31.1%）。
- 128×128 渐变 Q80：baseline 3,120 B → 4:4:4 2,440 B、4:2:0 **1,540 B（−50.6%）**；Q90 为 1,952 / 2,952 B。
- 质量：4:2:0 Q55 PSNR **29.54 dB**（源图）；与 Pillow(libjpeg) 自己写的 4:2:0 progressive 解码逐像素 **mean 差 0.68、max 32**（差异来自上采样滤波：我们最近邻、libjpeg 三角）。
- 自解码回环：320×180 / 1280×720 / 512×512 纯色、137×93 与 17×9 非 16 倍数尺寸全部 `"ok":true`。
- 新增 6 条测试（SOF2 采样因子逐字节、8 条扫描参数、4:2:0 体积 < 4:4:4 且往返、137×93、奇偶小尺寸、CLI 正路与互斥），全量 native **7,432/7,432**；`moon check --deny-warn --target all` 0 警告。
- 边界：解码侧 4:2:0 上采样仍是最近邻（未做 libjpeg 三角滤波）；spectral selection 分段与扫描脚本可配置仍未做，见 `docs/roadmap.md` F-01。
## [0.1.29] - 2026-11-27

### Added

- **progressive successive approximation（F-01 第三步，`Ah>0`）**：`encode_jpeg_progressive` 从 4 条扫描扩到 **8 条**——DC 首扫（`Al=1`，交错 3 分量）→ 3 条 AC 首扫（`Ah=0 Al=1`，单分量）→ DC 细化（`Ah=1 Al=0`，交错）→ 3 条 AC 细化（`Ah=1 Al=0`）。新增 `codec/jpeg_progressive_refine.mbt`：`jpeg_prog_shift`（AC 按绝对值右移、向零取整，同 libjpeg）、`jpeg_progressive_ac_refine_scan`（对齐 libjpeg `encode_mcu_AC_refine` 的修正位发射），以及 `jpeg_prog_emit_sym`/`emit_bit`/`emit_value`（靠 `freq.length() > 0` 切换"计频"/"写位"，保证统计与位流严格同构）。
- **细化用的两张优化 AC 表**：`0x12`（亮度）/`0x13`（色度），按 AC 细化符号频次自建，DHT 由 4 张增到 6 张。

### Fixed

- **修正位缓冲必须两个**：libjpeg 用 `BE`（跨块累积，随 EOBRUN 一起发出）与 `BR`（本块新增，跟随 ZRL 或 `(r<<4)|1` 符号之后发出）两个缓冲；上一版合并成一个数组，ZRL 分支把修正位提前/错位写出，320×180 与 128×128 Q90 自解码报 `JPEG 数据意外结束`。拆成双缓冲后全部样本通过。

### Verified

- 1280×720 照片 Q55：baseline 79,638 B → progressive **75,268 B（−5.49%）**；128×128 渐变 Q80：3,120 → 2,440 B（−21.79%）；512×512 纯色 < 8 KB。
- 与 baseline 解码**逐像素相同**（两级补齐后量化系数与单遍完全一致，max |Δ|=0）；Pillow 识别 `progressive=1`。
- 自解码回环：320×180 / 1280×720 / 512×512 纯色、渐变 Q90/70/40 全部 `"ok":true`。
- 测试：codec 696 条（新增 2 条：8 条扫描的 `(Ss,Se,Ah,Al)` 逐条核对、与 baseline 逐像素一致；硬边内容细化往返），全量 native **7,427/7,427**；`moon check --deny-warn --target all` 0 警告。
- **体积权衡**：比 0.1.28 的 4 扫描版大（−5.49% 对 −8.08%），代价是多 4 条扫描头 + 每条非零系数多 1 位修正位，换来真正的两级渐进显示（先粗后细）；仍小于 baseline。
## [0.1.28] - 2026-11-27

### Added

- **progressive 编码的体积收口（F-01 第二步）**：`encode_jpeg_progressive` 的 AC 首扫加 **EOBRUN 合并**——连续整块全零的块累计成一个 `(rrrr=nbits, ssss=0)` 符号 + nbits 位计数，上限 1023 块（`PROGRESSIVE_MAX_EOBRUN`），块尾残余零仍按单块 EOB 立即收尾（避免解码端把合并量错记到下一块）。
- **按频次自建 AC 霍夫曼表**：新增 `jpeg_progressive_ac_freq`（与写码分支逐一对齐地统计 257 项符号频次）与 `jpeg_gen_optimal_table`（移植 libjpeg `jpeg_gen_optimal_table`：哨兵、双最小合并、K.2 超 16 位折半重分配）。标准 K.3/K.5 AC 表既没有 0x10–0x90 的 EOBn 符号，Kraft 余量也只剩约一个 16 位槽位，只能自建；DHT 段随之改为「DC 标准表 + 两张优化 AC 表」。

### Fixed

- **EOBRUN 查表下标写错**：`jpeg_emit_eobrun` 曾用 `enc.codes[nbits]`（符号值 nbits，落在普通 AC 符号区）取码字，`lengths=0` 导致一个位都没写、位流缺数据；改为 `nbits << 4`。这是本轮"自身解码报 `JPEG 数据意外结束` 而 Pillow 能解"的根因。
- **块尾 EOB 不应进入合并累计**：把块尾残余零也计入 EOBRUN 时，emit 落在下一个非全零块里，解码端会按「块首 eobrun>0 即整块跳过」把这一个块吃掉，整条扫描从此错位。现在只有整块全零参与合并，块尾独立写 EOB。

### Verified

- 1280×720 照片 Q55：baseline 79,638 B → progressive **73,206 B（−8.08%）**；与 baseline 解码**逐像素相同**（max |Δ|=0、mean 0.000）。
- 128×128 渐变 Q80：3,120 → 2,368 B（−24%）；512×512 纯色 < 4 KB，四张 DHT 表 Kraft ≤ 1。
- 自身解码回环通过（512×512/1280×720/320×180 缩放照片/256·512 纯色），Pillow 识别 `progressive=1`、4 条 SOS。
- 新增 3 条测试（EOBRUN 大值纯色往返、体积 < baseline、DHT 表自洽黑盒校验），全量 native **7,425/7,425** 全绿。
- 边界见 `docs/known-gaps.md` GAP-56（已闭环，剩余 `Ah>0` 细化 / spectral 分段 / 4:2:0 转入 roadmap F-01 后续），`docs/roadmap.md` F-01 标 `✅`。

## [0.1.27] - 2026-11-27

### Added

- **progressive JPEG 编码（F-01 第一步）**：新增 `image.codec/codec/jpeg_progressive_encode.mbt` 的 `encode_jpeg_progressive(img, quality)`，门面 `walkzzz/image.codec/lib` 同步导出。输出最简合法 progressive 位流：DQT(2) + SOF2 + DHT(4) + 4 条 SOS——扫描 1 为 DC 首扫（交错 Y/Cb/Cr，Ss=0 Se=0），扫描 2–4 为各分量单分量 AC 首扫（Ss=1 Se=63）。4:4:4 采样，无 successive 细化、无 EOBRUN 合并（逐块写 EOB/ZRL）。先整幅量化系数缓存（之字形序，便于 AC 扫描顺 k 直读），像素上限 200 万，超限抛 `EncodeFailed`。
- CLI：`imgtool convert --jpeg-progressive`（与 `--best` 互斥；仅 JPEG 输出可用）。`help_text` 与 `docs/cli.md` 同步。

### Verified

- 1280×720 照片 Q55：progressive 58,115 B vs baseline 58,084 B（+31 B，4 条扫描头与逐块 EOB 的开销）。
- Pillow 识别 `progressive=1`、3 层扫描；自身解码与 Pillow 逐像素 max |Δ|=1 / mean 0.48。
- 新增 `jpeg_progressive_encode_test.mbt` 8 条（SOF2 且无 SOF0、SOS 计数、64×64 / 17×13 非 8 倍数 / 灰度 / 1×1 往返、超限抛错、体积 ≤ baseline×1.5）；全量 native **7,423/7,423** 全绿；覆盖率复测 38,562/42,814 = 90.07%。
- 边界见 `docs/known-gaps.md` GAP-56（不做 EOBRUN / Ah>0 / 4:2:0），`docs/roadmap.md` F-01 标 `⚠️` 第一步已落地。

## [0.1.26] - 2026-11-27

### Added

- **JPEG progressive（SOF2）解码（GAP-1，闭环）**：新增 `image.codec/codec/jpeg_progressive.mbt`，把原来只走 baseline 单扫描的解码路径扩成「多扫描系数累积」。解析层 `JpegHeader` 增 `progressive : Bool` 与 `scans : Array[JpegScanSpec]`；`JpegScanSpec` 承载 ns / 分量索引 / 该扫描时刻的 DC、AC 表快照 / `ss`、`se`、`ah`、`al` / 熵区间，并新增 `jpeg_skip_entropy_to_marker`（跳过 0xFF00 与 RSTn，取下一个真 marker）；`0xC2` 与 `0xE0` 同布局解析，SOS 在 progressive 时压入扫描并顺序继续，不再 `break`。扫描类型覆盖 DC 首扫、DC 细化、AC 首扫、AC 细化四类，含跨块 EOB run。
- 公开面不变：`decode_jpeg` / `decode_jpeg_pure` 按 `header.progressive` 自动分流，调用方无需改代码。

### Fixed

- **跨扫描 Huffman 表被「最后一次定义」覆盖**：编码器在每条扫描前重定义同号表（该样本 13 个 DHT 段、同一 ac0 反复改写），只保留最终版本会让早期扫描用错表——位消耗形状正确但解出的 RD 值全错。改为 SOS 解析时按分量快照 `huff_dc[td]` / `huff_ac[ta]` 存入 `JpegScanSpec.dc_tabs` / `ac_tabs`，解码统一走扫描内表。
- **分量块网格不能由 MCU 网格乘采样因子**：原 `bw = mcus_x * h_i` 让 32×24 的 Y 得 4×4=16 块（实际 3 块行）。改为 `ceil(w·h_i/(8·max_h))`、`ceil(h·v_i/(8·max_v))`；系数缓冲仍按 MCU 网格容量 `stride_x = mcus_x·h_i` 分配，因为交错扫描把越界的 padding 整块也编入码流，交错分支不裁剪、非交错分支才按分量块光栅序推进。
- **AC 细化把「先读码」写成「先修正」**：libjpeg 的 `decode_mcu_AC_refine` 每块先解一个 Huffman 码，已非零系数的修正位只在「跳过零位」途中读取；旧实现一进块就对 `k=ss` 处的非零系数读修正位，整条扫描位流从第一块起偏移一位，表现为「部分块系数错位 7~13、EOB run 计数 +1」。改为严格按 libjpeg 结构：码 → run 推进 → 途中修正 → 写新系数。
- **细化扫描 ZRL 少跳一个零位**：libjpeg 的 ZRL 由内层跳 15 个零加外层 `for` 自增合计 16，旧实现内层跳完 15 个零后不前进，累计只跳 15 位，后续新系数普遍前移 1 位（实测 4 块出现 49↔56、7↔14 的成对错位）。改为内层结束后统一 `k += 1`。
- **EOB run 块首与细化位累加**：块首 `eobrun > 0` 时整块只做修正、不读任何 run/size；修正位累加要求 `(v & p1) == 0`（同 libjpeg 口径，避免同一位面重复加）。

### Verified

- **逐块系数与同图案 baseline 解码对照**（Pillow quality=75 同图案双份样本，量化表完全相同，故两条路径的系数应逐字节一致）：
  - 48×32 灰度（548 B / 520 B，6 条扫描）：24/24 块 64 系数全等
  - 96×72 灰度（907 B / 828 B）：全等
  - 32×24 彩色（887 B / 809 B，10 条扫描）：Y 12 块 + Cb 4 块 + Cr 4 块共 20/20 全等（baseline 侧另有 4 个 padding 块不进输出）
  - 160×120 彩色（2030 B / 1800 B）：全等
- **像素级对照**：灰度 max |Δ| = 1（48×32 mean 0.008、96×72 mean 0.019），与 baseline 自身对 Pillow 的精度同级；彩色 progressive 输出与 baseline 解码**逐字节相同**（max 0），两者与 Pillow 的差异来自 4:2:0 色度最近邻上采样，属 baseline 既有行为、非 progressive 缺陷。
- 新增 `jpeg_progressive_test.mbt` 3 条：6 扫描 48×32 灰度样本的尺寸/通道、8 个采样点像素（±1 LSB）、截断熵数据抛 `DecodeFailed` 而非 panic。
- `moon test --target native image.codec/codec` 684/684 全绿；全量 native **7,415/7,415** 全绿（含本次新增 3 条）；覆盖率复测 38,352/42,611 = 90.00%（门槛 90%，`check_coverage.mjs` ok）。

## [0.1.25] - 2026-11-27

### Added

- **QR 生成器扩到多版本（GAP-48，闭环）**：`render_qr` 此前固定 21×21 矩阵、单块 RS，超过 17 字节（UTF-8）只能报错。生成侧重写为参数化：版本表按 ISO/IEC 18004 表 9 的 L 级单块行取 v1–v5（数据/纠错码字 19/7、34/10、55/15、80/20、108/26，字节上限 17/32/53/78/106），`qr_fits` 按载荷长度选最小版本；矩阵构造参数化到 size/finder/timing/dark/alignment（v2 起右下 `(size-7, size-7)` 5×5 环），格式信息两副本按 `size` 定位。公开面新增 `qr_modules` / `qr_matrix_size` / `qr_version_for` / `qr_max_bytes` / `qr_fits`，`qr_v1_max_bytes` 与 `qr_fits_v1` 保留历史语义。playground 的 `img_qr_png_hex` / `img_qr_filter_png_hex` / `img_qr_max_bytes` 切到新守卫，页面提示改为「自动选最小版本（1–5-L）：上限 106 字节」。

### Fixed

- **QR 解码器把整行/整列 8 当格式信息（GAP-54）**：`is_function_module` 原写 `row == 8 || col == 8` 一律返回 true，而格式信息实际只占行 8 的左段 8 位、列 8 的上段 7 位与第二副本（行 8 右段 / 列 8 下段）；中间的 9..size-9 属数据区。v1 文本短（≤15 字符）时错位落在填充段未暴露，v2 的 30 字节用例直接解出乱码。改为「行 8 仅 col ≤ 8 或 col ≥ size-8、列 8 仅 row ≤ 8 或 row ≥ size-7」，并补 `qr_alignment_centers` 的 5×5 判定（v2–v10 中心表），否则对齐图案会被当数据位。
- **QR 区域定位改用「左上角 finder + 版本边长 × 模块尺寸」（GAP-55）**：旧逻辑取三 finder 的外接框当 ROI；v2 起数据区图案会被检测器误报为第三个 finder（实测应位于 x=88 的右上图案被检出在 x=62、s=30），外接框宽度少 6 模块，采样列中心整体压缩，格式位读成 mask 3。改为取 `x+y` 最小者为原点、`origin.size / 7` 取整为模块尺寸、ROI 边长 = `qr_size × module_size`；v2 采样矩阵与生成矩阵逐模块比对 0 差异。

### Verified

- `image.core/testgen` 新增 4 条（版本边界 17/18/32/33/53/54/78/79/106、v2 alignment 5×5、dark module 随版本右移、timing 隔一取黑）；`image.codec/barcode` 新增 v1–v5 往返（10/30/50/70/100 字节），同步改写 `qr_wbtest` 的 `is_function_module` 断言（行/列 8 中间段改为 false，补 v2 alignment 用例）
- native 7,412 / 7,412 全绿
- **第三方解码器交叉验证**：v1–v5 矩阵按 8 px/模块 + 4 模块静区渲染为 PNG，交 jsQR 1.4.0 解码，5/5 文本与 `version` 全部一致（10/30/50/70/100 字节）；自解码与第三方实现在版本判定上互证

## [0.1.24] - 2026-11-27

### Fixed

- **TGA 描述符位错（GAP-42）**：规范是 bit5(0x20)=top-down、bit4(0x10)=right-to-left；旧编码器写 `0x30`（两位置位、自相矛盾），旧解码器把 `& 0x10` 当 top-down。后果是双向错：本库产出的 TGA 在标准阅读器里水平镜像，标准 top-down 文件被当成 bottom-up 上下翻转。编码器改按通道数定位深（1/2/3 → 24-bit、4 → 32-bit BGRA，描述符 `0x20` / `0x28`）并写出 alpha（此前 4 通道只写 3 字节/像素）；解码器改按 bit5 判 top-down、bit4 置位时逐行镜像；`tga_decode_test.mbt` 里 3 处把 `0x10` 注释成「top-down」的构造同步纠正。
- **TIFF 编码越界崩溃（GAP-43）**：`encode_tiff_pure` 只校验 channels，之后按 `width*height*channels` 直接索引像素；数据短于声明尺寸时越界 trap（native `0xC0000409`，用户数据即可触发）。改为先校验宽高 > 0 与 `data.length() == width*height*channels`，不符抛 `EncodeFailed`。
- **超像素分割除零 / 死循环（GAP-44）**：`num_superpixels = 0` 除零；`num > total` 时 `step` 取整为 0 → `w / step` panic 且 `cx += 0` 死循环；另一条死代码同样除零。改为 `num <= 0` 抛 `DecodeFailed`、超量夹到像素总数、`step` 下限 1、删死代码；并按网格兜底 `labels` 的 -1 空洞。
- **Code128 Stop 符不符规范（GAP-45）**：码表 108 行里 105–107 位置混装（`[105]` 实为 Start A、`[106]` 为 Start B、`[107]` 才是 Start C），真实 Stop（码字 106）是 7 段 13 模块 `[2,3,3,1,1,1,2]`，6 段表装不下，旧实现用伪模式 `[2,1,1,2,2,3]` 冒充再补 2 个模块——生成物在标准扫码器不可读，自解码因同源反而「通过」。表截为 0–105（106 行），新增 `code128_stop_pattern`；解码器先匹配 7 段 Stop 再匹配码字；生成器直接渲染真 Stop。
- **GLCM 熵是占位公式（GAP-46）**：原 `entropy -= p * p * 0.1` 结果恒 ≤ 0，与「熵」语义相反。改为真香农熵 `-Σ p·log2(p)`（`@math.log2`，`style_transfer` 包 `moon.pkg` 增 `moonbitlang/core/math`）。
- **S16/S17 遗留：6 个包脱离版本列车（GAP-49）**：`image.doc/media/commerce/pro` 停在 `0.1.20`、依赖钉同停；`npm/package.json` 与 `bindings/dart/pubspec.yaml` 停在 `0.1.23`。`check_version.mjs` / `bump_version.mjs` 的模块名单都只有 7 项，注释却写「共 11 个」，四个 patch 的漂移无人拦。两脚本扩到 11 个 `moon.mod` + 37 处钉 + npm + Dart，门禁由 16 项升至 22 项；六个文件一次性对齐 `0.1.24`。
- **两条绑定通道的元信息面不对称（GAP-52）**：JS `info().channels` 恒为 `0`（`abi_info` 只读头部，wasm 侧写死 0），会被当成单通道灰度图——改为 `null` 并加断言；Dart 的 `resize`/`convert` 吞掉 CLI 回执的宽高与格式，新增 `ImageMeta` + `convertMeta` / `resizeMeta`（复用同一次进程的 JSON）；CLI `resize` 回执补 `channels`；`docs/bindings.md` 的 JS 示例从位置参数改回 options 写法。自测 JS 15 → 16、Dart 8 → 10。
- **Dart 绑定两条错误路径被自己吃掉（GAP-50）**：`_call` 的 `stderr.trim().split('\n').first` 在 stderr 为空时抛 `StateError`，把真实错误码换成无意义异常；`_ext` 表多列 7 个只读格式，导致 `convert(format: 'tiff')` 先 spawn 一次进程再失败。改为 `_ext` 只留 CLI `is_writable` 的 8 个、空 stderr 走「退出码 N」文案；自测 6 → 8 项。

- **VP8 解码拒绝奇数宽高（GAP-17，闭环）**：色度平面按 `w / 2 × (h / 2)` 向下取整分配，奇数宽高必然越界，旧实现因此加偶数守卫直接抛 `DecodeFailed`——比编码器（UV 已 ceil）窄一档，自编码 1x1 / 3x3 能出不能进。解码器关键帧（`decode_vp8_frame`）与 inter（`decode_vp8_inter_frame`）两条路径的 UV 平面全部改 `ceil(w/2) × ceil(h/2)`：平面分配、YUV→RGB 采样、帧内 UV 预测写回、inter UV 预测、参考帧 `uv_size` 与 `refs.update` 拷贝、环路滤波 UV 边界共 13 处尺寸/索引，两处偶数守卫删除；`vp8_frame_wbtest` 的奇数用例由「15×16 期望 `DecodeFailed`」改为 15×13 断言解出（宽 15 / 高 13 / 3 通道 / `15*13*3` 字节）。

### Added

- **S20 基准集扩容（golden 20 → 24、malformed 6 → 8）**：补的是 8-bit 之外没有实物的解码路径——`g21` PNM 灰度 P5（与 `g06` 的 P6 分属两种解析）、`g22` TGA 32-bit BGRA + 描述符 `0x28`（GAP-42 修后的分支）、`g23` WebP lossy **奇数 33×33**（VP8 解码 UV ceil 的端到端样本，反向验证 GAP-17）、`g24` QOI 四通道（此前只覆盖 RGB）；畸形侧此前只有 PNG/BMP/JPEG，`m7` WebP RIFF 声明 `0x7FFFFFF0` 与 `m8` TIFF IFD 偏移越界补上两个容器的越界回归。总量 1,209,836 B → **1,453,371 B**（上限 1,638,400 B，余量 11.3%）；`check_benchmarks.mjs` 条数契约 20/6 → 24/8，`manifest.json` 重封签；实测 `--update` 与默认校验均 `ok:true, failed:0`；`samples_wbtest` 追加 g23 固化为 756 B 且头为 `RIFF`/`VP8 ` 的断言，native 由 7,406 → **7,407 全绿**。重生成同时暴露 `g11` 滞后：TGA 描述符仍是 GAP-42 修复前的 `0x30`（应为 `0x20`，全文件 1 字节差）——封签只校验「磁盘 ↔ manifest」，不校验「磁盘 ↔ 当前生成器」（记 GAP-53），已重生成并重封签。
- **9 条回归测试**：`image.codec/codec/s22_probe_test.mbt` 转为正式回归（TGA 4 通道逐字节往返、24-bit 描述符 `0x20`、0x20 不翻转、0x00 翻转、0x30 水平镜像、TIFF 短数据抛错）；超像素 8×8 + `num = 0 / 100` 双路径；Code128 码表形状（每条 6 段 11 模块、Stop 7 段 13 模块）与渲染总模块数 `11×n+13`。native 由 7,395 → **7,404 全绿**。

### Changed

- 覆盖率真值随代码行数更新：**38,178/42,396 = 90.05%**（门槛仍 90，分母不排除任何文件）；`docs/coverage.json`、`AGENTS.md`、`docs/known-gaps.md`、`docs/release.md` 与首页经 `sync_pages` 同步。
- 台账新增 GAP-42…46（五类缺陷闭环）与 GAP-47（CUR 3×2 往返复测通过，不再挂缺陷）；GAP-23 补注「当时的 Stop 是伪模式，见 GAP-45」。

### Notes

- 本版全部为缺陷修复 + 回归，无新增公开 API、无签名变更；`moon publish` 仍未执行。
- 明确不做（沿用既有口径）：VP8 lossy 编码结构性问题（改走 VP8L，见 `docs/webp-encoder.md`）、`moon prove` 形式化扩展、`imgtool sanitize` 复用 `quality_of` 等 S23 候选。

## [0.1.23] - 2026-11-27

- **二维码格式信息位序（S23）**：`qr_format_bits` 的 BCH(15,5) 长除法漏检 bit10，L/mask0 得 `0x7412`（应 `0x77C4`）；副本 1 按 LSB-first 铺位置、副本 2 两段各自反向。三处叠加使 jsQR / zxing 一致拒扫（ChecksumException）。编码器改 MSB-first + 标准副本 2 布局 + 正确长除法；解码器 `read_qr_format_info` 同步改为 `1 << (14 - i)`，自解码往返恢复。
- **二维码容量与静区（S23）**：v1-L 上限 17 字节，旧实现超长静默截断、空串仍出图。`qr_fits_v1` 守卫 + `img_qr_max_bytes` 导出，页面按「请输入文本」/「超出 N 字节」分别报错并清空旧图；静区由 2 夹到 4（ISO 18004）。

### Added

- **`docs/migration.md`（S21）**：迁到 0.1.23 只需 3 处改动——①模块名与安装命令（6 → 11 个模块）②import 的包路径与别名 ③7 条弃用 API 换成 `_enhanced` / lossless。附 15 行迁移前后对照与「不用改的部分」（公开签名 / 错误模型 / CLI JSON / npm 导出面）。
- **`docs/deprecation.md`（S21）**：标注规则（必须有替换目标 + doc 说明 + 跨包 `skip_current_package`）、保留窗口（标注后至少 2 个 patch，`0.1.x` 内不移除）、当前 7 条清单（符号 / 包 / 替换目标 / 理由 / 起始版本）。
- **`scripts/check_deprecations.mjs` + B12 门禁**：代码里的 `#deprecated` ⇄ 弃用表双向比对（符号、所属包、从文案抽出的替换目标），漏登记、已移除未删行、替换目标不一致都会红灯。`check_docs` 由 11 项增到 **12 项**。
- **`docs/release.md` §九**：S21 收口核对清单——11 环发布顺序、13 条门禁逐条命令、发布后 30 分钟上手验收。
- **`docs/ci-cd.md`（S21 收口）**：CI/CD 与 Pages 的唯一说明书——8 个作业、B1–B13 门禁逐条对照、覆盖率单一真值、Pages 发布机制与本地等价命令、4 条已知限制。
- **`.github/workflows/pages.yml`**：Pages 构建 + 部署（artifact 方式，产物=`docs/`）。首次运行借 `configure-pages@v5` 的 `enablement: true` 自动开启 Pages。
- **`scripts/sync_pages.mjs` + `docs/coverage.json`**：首页数字不再手写。覆盖率先固化为 `coverage@1`（38,102 / 42,301 = 90.07%，threshold 90）；`sync_pages` 从 `moon.mod` + README 徽章 + 该 JSON 拉数，按 12 个具名槽位改写 `docs/index.html`，`--check` 进 CI；`bump_version` 末尾自动调用。
- **`scripts/check_links.mjs` + B13 门禁**：55 个 md / 126 条相对链接可达、`docs/*.md` 都在 README 表里、10 个子模块都有 README。`check_docs` 增到 **13 项**。
- **`scripts/check_release_ready.mjs`（S21 收口一条命令）**：串跑 15 项门禁（版本 / B1–B13 / 三个 `--check` 生成器 / 导入 / 弃用 / 链接 / 首页数字 / npm 15 / Dart 6 / fmt / check / test 7395 / pages 49），`--skip-slow` 只跑快的 12 项，`--json` 机读；任一条失败即退出码 1 并打印尾部输出。
- **B14 门禁 + 一处真实污染修复**：`image.vision/fieldimg/field_bind_test.mbt` 里有 5 个字面 `\x00`（控制字符直接写进源码），git 因此把该文件判成二进制——`git diff` / `blame` / 行级审查全部失灵，也是远程 `Format check` 反复红的一个盲区。已改成转义写法（`b'\x00'`），fieldimg 包 105 测试复跑全绿；并新增 `check_docs` **B14**：扫描 1,231 个 `.mbt/.md/.mjs/.yml/.json` 等文本文件，出现 NUL/控制字符即红。`check_docs` 由 13 项增到 **14 项**。
- **CI 真实转绿（2026-11-27）**：连续 4 次远程跑定位并修掉 3 个只在 Linux runner 暴露的问题——① 各作业缺 `moon update`（registry index 缺失，10 个作业同时红）② `imgtool` 产物在 Linux 也叫 `imgtool.exe`，脚本按 `process.platform` 猜名导致基准门禁与 Dart 自测红（抽出 `scripts/imgtool_path.mjs`）③ `npm/image.wasm` 是构建产物不入库，bindings 作业补 `build_npm_wasm.mjs --no-test`。最终 run `45869479035` 10/10 success。
- **GitHub Pages 上线**：`gh api -X POST .../pages -f build_type=workflow` 首次建站（`configure-pages` 的 `enablement` 用 GITHUB_TOKEN 建不了），`https://walkzzz.github.io/image.mbt/` 实测 200、playground.js 267,318 B；README 双语各加 CI / Pages 徽章。

- **2 条 QR 回归**：两份格式信息副本逐位等于 `111011111000100`；17 字节可编码 / 18 字节拒绝。native 7,404 → **7,406 全绿**。

### Changed

- README / README.en 文档表新增 `migration` 与 `deprecation` 两行；roadmap S21 标 ✅ 并写入验收证据。
- 绑定版本跟随库版本：`npm/package.json` 与 `bindings/dart/pubspec.yaml` 同步到 0.1.23（仍未对外发布）。
- **CI 门禁补全 + Pages 门禁**：`quality` 作业新增 `check_version` / `check_pkg_imports` / `sync_pages --check` / `check_pages`；`coverage` 门槛随实测从 80.5 提到 **90**；顶层最小权限 `contents: read` + 分支并发取消。
- **版本治理扩面**：`check_version` 由 14 处增到 **16 处**（新增 `playground/playground.mbt` 的 `img_version` 与 `docs/index.html` 品牌版本）；`bump_version` 同步改写这两处并尾调 `sync_pages`。

- 覆盖率随 `qr_format_bits` 重写更新为 **38,127/42,342 = 90.08%**；展示页经 `sync_pages` 同步为 0.1.24 / 7,406 / 90.08% / 82 包，并补齐汉堡导航 + `aria-live` + `og:image`/canonical + 触摸目标 ≥24px。
### Notes

- 本版是 0.1.x 收口版：只做文档与门禁收口，不改任何运行时行为，`moon test --target native` 仍 7,395 全绿。
- `moon publish` 未执行；11 环发布与 npm 发布需明确授权后另起一轮。

## [0.1.22] - 2026-11-27

### Added

- **语言绑定（S17）**：两条通道、同一份实现。
  - JS：`npm/` 走 `--target wasm`（线性内存 + `abi_*` 导出），`node npm/test.mjs` 15/15；包版本随库对齐到 0.1.22。
  - Dart：新增 `bindings/dart/`（`image_mbt.dart` + `tool/selftest.dart`），以 `imgtool` 进程为 ABI，自测 6/6，覆盖 `decode → resize → encode`。
- `scripts/check_dart_binding.mjs`：自动构建 release imgtool 后跑 Dart 自测（`--no-build` 可复用产物，`dart` 缺失时以退出码 2 跳过）。
- `docs/bindings.md`：通道选型表（FFI / `package:wasm` / 进程三条候选的实测结论）、Dart API、自测与发布口径；README 双语同步新增小节与文档行。

### Notes

- Dart 不载 wasm 的原因：MoonBit native 不产出静态/动态库；`package:wasm`（0.1.0+1）已废弃且需 Rust + MSVC `link.exe` 现编 Wasmer；Dart VM 无内置 WebAssembly 运行时。
- 绑定不重写任何编解码：Dart 侧只搬字节并解析 CLI 的单行 JSON。

## [0.1.21] - 2026-11-26

### Changed

- **场景包收敛为 4 个入口（S16）**：新增 4 个场景模块 `image.doc` / `image.media` /
  `image.commerce` / `image.pro`，每个模块一个入口包，用 `pub using` 同签名再导出原子包 API。
  `photo` 场景由既有 `image.photography` 承担（不新增 `image.photo`），其余原子包并入 `image.pro`。
  **模块数 7 → 11（不是 15）**，发布链随之 11 环。
- `docs/scenes.json` 是归属真值（场景 → 包列表 + 模块依赖）；`scripts/gen_scenes.mjs` 从
  `pkg.generated.mbti` 生成入口包（`moon.pkg` 的 import 列表 + `<scene>_scene.mbt` 的
  `pub using @pkg {…}`），支持 `--check` 防漂移。生成器**跳过 `#deprecated` 符号**
  （否则 `--deny-warn` 直接失败），跨包同名符号按 JSON 顺序先到先得并写入冲突清单，不静默丢失。
- 再导出规模：doc 504 符号 / media 313 / commerce 257 / pro 1,462；库体公开面
  **78 包 3,890 fn → 82 包 5,847 fn**（`docs/api_index.md` 含 playground 为 83 包 5,851 fn）。
- `scripts/check_version.mjs` 的模块清单 7 → 11（含 4 个场景模块），版本统一 `0.1.21`。
- `docs/scenes.md`：四个场景入口的适用面、包归属、冲突与弃用符号口径、发布链 11 环顺序。

### Notes

- 场景模块只是**入口**，不复制实现、不改测试归属；下游既可以 `moon add walkzzz/image.doc`
  一次拿全场景 API，也可以继续只依赖某个原子模块（细粒度不变）。
## [0.1.20] - 2026-11-26

### Added

- **公开基准集（S20）**：`benchmarks/gen/`（MoonBit 包）用自有代码合成 **20 张 golden**
  （13 种可编码格式）+ **6 个畸形样本**（数据流损坏 / chunk 长度越界 / 声明尺寸炸弹 /
  APNG 帧数声明 / BMP 非法枚举 / JPEG 元数据段截断）；零第三方素材，总体积 1.2 MB。
- `scripts/check_benchmarks.mjs`：六条契约校验（条数 / 命名与真实尺寸 / 体积上限 / sha256 封签 /
  magic 嗅探与 `imgtool` 报告一致 / 行为：golden 必须 `ok:true`，malformed 必须 `exit≠0 + ok:false`、
  5 秒内、无 `PanicError`）；`--update` 用于重新封签 `benchmarks/manifest.json`。
- `benchmarks/COPYRIGHT.md`：版权自查清单（逐项排除照片 / 字体 / 图标 / EXIF 个人信息）+ 新增样本四条准入规则。
- `docs/benchmarks.md`：样本清单、命令与判定链。
- CI 新增基准集门禁步骤（`moon build --release cmd/imgtool` + `node scripts/check_benchmarks.mjs`）。

### Fixed

- **PNG 家族 chunk 长度整数回绕 → panic**（基准集 m2 实测 `0xC0000409`）：`png_decode` /
  `png_decode_16` / `apng_codec` / `apng_extended` / `region_decode` 改为溢出安全比较
  `chunk_len > len - pos`，畸形输入现在返回 `decode/decode_failed` JSON 错误。
- **`imgtool` 把 HDR/PSD 报成 `unknown`**：`format_name` 补 `Hdr` / `Psd` 分支，默认臂改为
  `@types.ImageFormat::..`，漏分支会在 `--deny-warn` 下直接编译失败。
- **TGA 无法自动分派**：`@lib.detect_format` 末位接入 `@codec.is_tga_format`（扩展覆盖
  1/2/3/9/10/11 图像类型与 8/15/16/24/32 bpp、宽高非零、调色板头一致性），`imgtool convert` 可直通 TGA。
- **基准集生成器可测化**：`benchmarks/gen` 拆为纯构建器 `samples.mbt`（返回 `(文件名, 字节)` 列表）
  与写盘 `main.mbt`，新增白盒 `samples_wbtest.mbt`（条数/命名/逐字节确定性/`add` 错误臂/畸形样本魔数）。
  生成器不再是 0 覆盖死重，全库覆盖率复测 **38,102/42,301 = 90.07%**（7,391 测试，四目标全绿）。
- **覆盖率口径修正**：README / `docs/known-gaps.md` / `docs/architecture.md` / `AGENTS.md` 的
  测试数与覆盖率统一为 **7,391 / 90.07%**，`docs/mutation.md` 记录 89.26% → 90.07% 的处置过程。
- **同型整数回绕收口（GAP-35）**：`avif_decode` / `avif_extended` / `heif_decode` / `heif_extended` /
  `icns_codec` / `icns_extended` / `jpegxl_extended` / `psd_decode` / `psd_extended` / `bmp_decode`
  共 10 处 `offset + size > len` 改为减法形式；新增白盒回归 `codec/bounds_overflow_wbtest.mbt`
  （声明长度 `0x7FFFFFF0` 的 ICNS / PSD / AVIF / HEIF / JPEG-XL 必须返回 `LoadError` 而非 panic）。

## [0.1.19] - 2026-11-26

### Added

- **能力表真值化（S19）**：`scripts/gen_capabilities.mjs` 从 `enum ImageFormat` 的 `.mbti` 变体清单 +
  `Codec for ImageFormat` 四个 impl 的实际分支（`format_name` / `can_decode` / `can_encode` / `is_lossless`）
  + 各包公开 API 计数，生成 `docs/capabilities.md`，并回填两份 README 的 `<!-- AUTO:formats:start -->` 区块。
- `docs/format_notes.json`：逐格式 zh/en 备注的唯一来源；枚举新增格式而未补备注时生成直接失败。
- `check_docs` 新增 **B10** 门禁：调用 `gen_capabilities --check`，README 与 `docs/capabilities.md`
  任一漂移即红灯（已做负向实测）。

### Changed

- README/README.en 的 18 行格式表从手写改为自动生成区块（解码/编码列来自 `Codec` trait，不再手抄）。
- 统计口径统一：库体 **78 包 / 3,890 pub fn / 718 公开类型**；`api_index.md` 保持 79 包 / 3,894（含 playground）。

## [0.1.18] - 2026-11-26

### Added

- **S18 覆盖率 90%（native 全量实测 37,740/41,894 = 90.08%）**：按 cobertura 行级缺口排行逐个收口，新增
  40+ 个针对性测试文件（OCR 字符集与符号模板、TIFF 压缩名/光度全表、区域解码 PNG、zlib 动态 Huffman、
  16-bit PNG 直读、积分图、光流、多边形填充、registration/retrieval 报告枚举、16f 色彩空间等）。
- `scripts/mutation_test.mjs` 12 点变异，11 killed / 1 survived（91.7%，M12 为纯文案变异预期存活），见 `docs/mutation.md`。

### Fixed

- `is_cur_format` / `is_ico_format` 只看前 4 字节，24/32-bit TGA 被误判为 CUR；现补「条目数 ≥1 且目录表装得下」。
- `codec_detect_format` 缺 TGA 分支；`ftyp` 的 `mif1` 品牌被写成 `mifs`（字节 0x73 应为 0x31），`mif1` 容器识别失败。
- 光标 / 标点归一化把 `String[i]` 的 `UInt16` 码元直接 `.to_string()`，产出 `"65"` 这类数字串；统一改走
  `UInt16 → Int → Char → String`（`smart_spacing_process` / `normalize_punctuation` / `ngram_create` / `ngram_score`）。
- `mp4/box.mbt` size==0 / size==1 分支早退不可达。

### Changed

- 覆盖率分母不做任何排除：90% 是在含 `wasm/abi.mbt`(89) + `wasm/api.mbt`(85) + `playground`(35) +
  `examples/quickstart`(37) 这些 native 不可覆盖文件的最严口径下取得。

## [0.1.17] - 2026-11-25

### Added

- **动画统一入口（S15）**：`image.codec/lib/animation.mbt`
  - `decode_animation(data) -> (Array[Image], Array[Int32])`：按魔数分派 GIF / APNG，返回帧与延迟（毫秒）。
  - `encode_apng(frames, delays)`：校验空帧 / 长度不一致后转调 `encode_apng_pure`。

### Verified

- 双帧 APNG（100ms / 200ms）编码 → 解码：帧数 2、延迟一致、尺寸与通道一致。
- GIF 单帧经 `decode_animation` 可读；静态 PNG 报 `DecodeFailed`；空帧与延迟长度不一致报 `EncodeFailed`。
- 测试数 6,847 → **6,851**；全库行覆盖 **34,477/41,868（82.3%）**；四目标全绿，`--deny-warn` 零警告。

## [0.1.16] - 2026-11-25

### Added

- **区域解码（S14）**：`decode_png_region / decode_bmp_region / decode_qoi_region`
  （`image.codec/codec/region_decode.mbt`），入口 `decode_region(data, x, y, w, h)`
  （`image.codec/lib/region.mbt`），按魔数自动分派 PNG / BMP / QOI。
  PNG 反滤波只保留上一行 + 当前行、输出按 tile 分配；BMP 无压缩按行直接寻址；
  QOI 顺序解码但区域外像素只推进状态不落内存。

### Verified

- 与"整图解码后裁切"逐字节一致：PNG RGB/RGBA/全图/1×1、BMP 24/32 上下行、QOI 3/4 通道。
- 错误路径：区域越界、零尺寸、负坐标、非支持格式（JPEG 魔数）各 1 项断言。
- 测试数 6,836 → **6,847**；全库行覆盖 **34,463/41,854（82.3%）**。
- 四目标 `moon test` 全绿；`moon check --deny-warn --target all` 零警告。

## [0.1.15] - 2026-11-25

### Added

- **16bit / float 覆盖收敛（S13）**：不新增算子，只补 16f 家族未覆盖分支。
  新增 18 组守卫/边界测试（`image.process/**/*_16f_guard_test.mbt` 17 个 +
  `seam_carving_16f_coverage_test.mbt`），测试数 6,726 → **6,836**。
- **`scripts/proto/gen_guard_tests.mjs`**：从源文件 `DecodeFailed` 消息反推守卫参数，
  自动为每个 pub fn 生成维度 / 通道 / 数据长度 / 标量下界四类探测调用，供后续 Sprint 复用。

### Verified

- 16f 家族行覆盖：4,727/5,505（85.87%）→ **5,018/5,505（91.15%）**。
- 全库行覆盖：**34,309/41,634（82.40%）**（`check_coverage.mjs` 门槛 80.5 通过）。
- 单文件：`seam_carving_16f` 65.4% → **96.2%**（补齐 `remove_vertical/horizontal_seam_16/_f` 四个未测 pub fn、
  放大 `insert_*` 路径、目标 ≤0 与 >2 倍错误分支）；`advanced_16f` 71.7% → 98.1%；`tonemap_16f` 72.1% → 88.2%。
- 四目标 `moon test` **6,836/6,836**；`moon check --deny-warn --target all` 零警告。

## [0.1.14] - 2026-11-25

### Added

- **npm 包 `@walkzzz/image-mbt`（S12）**：`npm/` 下 ESM 封装 + 随包 `image.wasm`，
  Node ≥18 直接 `import`，零原生依赖、零 install 脚本。
  API：`info / convert / convertMeta / resize / resizeMeta / formats`；输入 `Buffer/Uint8Array/ArrayBuffer`，
  输出 `Buffer`；错误抛 `Error` 并带 `code / hint`。
- **wasm MVP 字节 ABI**（`wasm/abi.mbt`）：`abi_alloc` 分配输入缓冲并导出 `memory`，
  `abi_info / abi_convert / abi_resize` 返回输出指针，`abi_last_len/ok/format/width/height/channels/error`
  读元信息与错误。`Bytes` 在 wasm32 上就是 i32 指针，Node 侧直接读写，**0 个 WebAssembly import**。
- **`scripts/build_npm_wasm.mjs`**：构建 → 拷 `npm/image.wasm` → gzip 体积校验（≤1.2 MiB）→
  校验导出/零 import → 同步 `package.json` 版本 → 跑 npm 自测，一条命令完成。
- **`npm/test.mjs`**：15 项自测（PPM→PNG/JPEG/WebP/QOI/BMP、`best` 选最小、元信息、
  cover/contain 缩放、错误码、空输入、1000×1000 触发内存增长）。

### Verified

- `image.wasm`：**248.3 KiB raw / 110.6 KiB gzip**，`WebAssembly.Module.imports` = 0；导出含 `memory` 与 12 个 ABI 函数。
- `node scripts/build_npm_wasm.mjs` → **15/15 passed**。
- Pillow 回读：PPM 4×3 → PNG 83 B、像素 `(0,7,14)` 一致；8×6 cover 缩放像素渐变正确。
- 反例：非图片输入抛 `decode/unsupported_format`，带中文 hint。

### Notes

- wasm-gc 导出路径不可用于 Node：字符串常量被编成 `"_"` 模块 460 条 `(ref extern)` 全局导入，
  JS 无法创建非空 externref 全局（`LinkError`）。npm 因此走 wasm MVP，详见 GAP-33。
- `npm` 暂不发布，`npm/image.wasm` 不提交，由 `prepack` 构建。

## [0.1.13] - 2026-11-25

### Added

- **CLI 扩到 8 个子命令**：`info / convert / resize / crop / filter / analyze / sanitize / bench`。
  `decode` / `encode` 保留为 `convert` 的同义别名，旧脚本不用改。
- **`convert --best`**：接 S10 的 `encode_best`（逐候选实编取最小）；`--max-bytes N` 接 `encode_best_limited`，
  超限报 `budget/limit_bytes`。`--best` 与显式 `--format` 互斥（避免"说要 PNG 又偷偷换格式"）。
- **`filter`**：box / gaussian / sharpen / median / bilateral / nlm 六种算子，
  参数 `--radius / --sigma / --amount / --ksize / --sigma-color / --patch / --search / --h`。
- **`bench`**：解码、逐格式编码、可选缩放的每轮均值（微秒），`--iters` 限 1-1000。
- **`--dry-run`**：convert / resize / crop / filter / sanitize 统一支持——完整解码、处理、编码，
  返回体积与格式但**不落盘**，便于脚本先算预算。
- **stdin / stdout 管道**：路径写 `-` 即 stdin 或 stdout（与 ImageMagick/ffmpeg 同约定），
  此时 JSON 结果自动改走 stderr。底层由 `imgcli/stdio_stub.c` + `pipe.mbt` 提供（native；
  Windows 下把 stdio 切到二进制模式，否则 0x1A 会被当成文本 EOF）。

### Verified

- 320×240 PNG（Pillow 生成、三色块）：`convert --best` 得 WebP **404 B**，同图 PNG 为 2,386 B；
  `--best --max-bytes 100` 正确报 `budget/limit_bytes`。
- 管道：`imgtool convert - - --format png < sample.png > pipe.png`，Pillow 回读 320×240 RGB 与原图一致，JSON 落在 stderr。
- `--dry-run`：`sanitize ... --dry-run` 返回 `regions_redacted=1, wrote=false`，目标文件未被创建。
- `filter` 六个算子各跑一遍均成功；`bench` 在 320×240 上给出 decode ≈2.3 ms、qoi 编码 ≈0.23 ms（本机参考值，不作跨机基准）。
- 四目标 `moon test --target all`：**6726/6726 通过**（wasm / wasm-gc / js / native 各 6726，failed 0）。

## [0.1.12] - 2026-11-25

### Added

- **`best_format(img)`**：不编码的启发式选格（有透明 → `Webp`，否则 `Jpeg`）；`has_alpha(img)` 只认 4 通道且存在 alpha<255。
- **`candidates(img)`**：带透明 `[Webp, Png, Qoi]`，不透明 `[Jpeg, Webp, Qoi, Png]`。
- **`encode_best(img, quality)`**：逐候选实编取最小（失败跳过，全失败报 `ProcessFailed`）。
- **`encode_best_limited(img, quality, max_bytes)`**：最小仍超限报 `ImageError::Budget(LimitBytes)`，`max_bytes<=0` 视为不限。
- `EncodedImage{format, bytes}` 类型；门面包 `all` 再导出上述 5 个入口。
- `webp_vp8l_far_distance_test.mbt`：3 个回归用例——三色横条 128×192（palette + 距离 6160）、
  300 色行重复 128×192（原样 LZ77 + 距离 12288）、纵向渐变 256×192（predictor）。

### Fixed

- **WebP 无损编码的远距离反向引用写坏像素（真 bug）**：距离前缀此前复用长度前缀表（上限 4096），
  距离 > 4096 时 `vp8l_encode_length` 退化成 `ebits = -1`（实测 `dextra=6279 debits=-1`），
  写出的 extra 位非法——码流仍可被解析，但解码结果是别的颜色块。现改用 RFC 9649 §3.6.2.2.1 的
  40 项距离前缀（`vp8l_encode_distance`），并把 tokenizer 的匹配距离上限收到 1,048,000
  （保证 `d + 120 ≤ 1,048,576`）。128×192 三色横条此前 Pillow 解码错 12,288 像素，修复后 0 差异。

### Verified

- 12 类样本（256×192，quality 85）：PNG 默认合计 39,875 B → 最小格式合计 7,596 B，省 **80.95%**；
  其中 10 个 WebP 样本本库与 Pillow 双向解码逐像素一致（JPEG 样本为有损，不参与无损校验）。
- Pillow 12.3 交叉验证（0 差异）：三色横条（palette）、300 色行重复（原样 LZ77）、纵向渐变（predictor）、
  64² 4 通道渐变（subtract-green）、256 色 RGBA 图标与 alpha 渐变（palette + alpha）。
- 四目标全量 `moon test --target all`：**6721/6721 通过**。

## [0.1.11] - 2026-11-25

### Added

- **`resize_subsample(img, out_w, out_h)`**：面积平均重采样，直接从底图读数，
  中间只有一个长度 = 通道数的累加器，**唯一分配是输出图**（上采样退化为最近邻）。
- **`thumbnail(img, max_side)` / `thumbnail_dims(w, h, max_side)`**：等比缩略图；两边都不超 `max_side` 时零分配原样返回。
- **`thumbnail_budgeted(img, max_side, budget)`**：先算输出字节再按 `AllocBudget` 准入，超预算直接拒（不分配）；
  拒绝走 `ImageError::Budget(LimitBytes)`，与解码期的 `DecodeLimits` 分工明确（解码管底图，算子在输出侧把关）。
- 门面包 `all` 再导出 `resize_subsample` / `thumbnail` / `thumbnail_budgeted` / `thumbnail_dims` / `AllocBudget` + `alloc_budget_default()`。
- `tile_test.mbt`：9 个用例（面积平均、同尺寸等价、上采样、等比尺寸、极小图、4000×3000→512、预算拒绝/放行、非法参数）。

### Verified

- 4000×3000×3（36,000,000 B）→ `thumbnail(img, 512)` 输出 512×384 = 589,824 B：
  只分配输出图，不建同量级中间缓冲；逐像素同值时输出与输入一致。

## [0.1.10] - 2026-11-25

### Added

- **ROI 区域视图 `Region` / `ImageRegion`（零复制）**：视图只存底图引用 + 坐标，不复制像素。
  `Region::new/clamp/area/is_empty`、`Image::region`、`Image::region_with`、
  `ImageRegion::width/height/channels/get/pixel/to_image`（越界读取返回 0，不 panic）。
- **`transform::crop_region(img, region)`**：按 `Region` 裁剪，越界自动裁掉、不报错（与 `crop` 的严格报错语义区分）。
- 门面包 `all` 再导出 Region 类型 + 8 个薄封装（`region` / `region_with` / `region_width` / `region_height` / `region_channels` / `region_get` / `region_pixel` / `region_to_image`）与 `crop_region`。
- `image.core/types/region_test.mbt`：9 个用例（裁剪、越界、逐通道一致、空区域、零复制）。

### Changed

- `pub using` 只能再导出**类型**，方法（`Image::region` 等）不会跟着走；门面包因此包一层同名薄函数，
  否则下游拿到类型却调不到方法（0.1.8 遗留的可用性缺口）。

### Verified

- 下游验收（workspace 双成员：只 import `walkzzz/image.mbt/all`）：
  底图 4000×3000×3 = 36,000,000 B → `region(img, 1200, 900, 1200, 900)` 视图 1200×900，
  `region_to_image` 得 3,240,000 B 且首像素与底图 `(1200,900)` 一致；
  `crop_region(img, Region::new(-50,-50,200,200))` 裁成 150×150（67,500 B），无异常。

## [0.1.9] - 2026-11-25

### Fixed

- **`moon publish` verify 的 `[0029] unused_package` 刷屏**：根因是 `.moonignore` 排掉了 `*_test.mbt` / `*_wbtest.mbt`，
  而各包 `moon.pkg` 的 `for "test"` 导入块仍在，测试依赖被当成未使用。改为**测试文件随包发布**（下游也能 `moon test`），警告归零。
- **根包 `moon.pkg` 导入全部清空**：根包只剩 `image.mbt`（门面文档 + 版本号），原有 import 全为 `bench_real.mbt` 服务。

### Changed

- 基准从根包拆出为 `benchmarks/` 包（`moon bench` 用法不变）；`benchmarks/` 不进发布包。
- **删掉 9 个包的重复导入**（plain 块与 `for "test"` 块各导一次 `walkzzz/image.core/types`）：plain 导入对测试同样可见，
  `for "test"` 里那条是冗余，归档一旦裁掉测试就变 `[0029]`。新增常驻门禁 `scripts/check_pkg_imports.mjs`（`--fix` 自动清）。
- 新增 `scripts/verify_publish_warnings.mjs`：七个模块逐个 `moon package` → 解压 → `moon check --deny-warn` → 统计警告；
  0.1.9 实测 **7/7 归档 0 warning 0 error**。
- 撤销「按目录名排除六个子模块源码」：子模块在 workspace 里 `moon package` 同样读根级 `.moonignore`，
  一条 `image.core/` 会把该模块自己的归档排成 22 字节空包，发布必然失败。根包 zip 因此仍带子模块源码副本（1013 个条目）。

## [0.1.8] - 2026-11-25

### Added

- **门面包 `walkzzz/image.mbt/all`**：`pub using` 再导出 9 个类型 + 17 个编解码函数 + 9 个变换函数。下游只 `moon add walkzzz/image.mbt` 一条，
  然后 `import "walkzzz/image.mbt/all"` 即可用，不再需要为高频 API 额外 add 子模块。
- **`.moonignore` 裁剪发布归档**：排掉 `scripts/ docs/ examples/ spec/ bench_real.mbt *_test.mbt *_wbtest.mbt` 与覆盖率/变异/工作区文件；
  `moon package --list` 1142 → 627 文件，zip 605 个；`playground/`（网页 demo 导出层）按要求保留。

### Changed

- README 安装段改为「一条 add + `@all`」；深层包（`image.codec/lib`、`image.process/filter` 等）仍需按需 add 子模块，并在文中写明**原因**（MoonBit 只有直接依赖的包可 import）。

## [0.1.7] - 2026-11-25

### Added

- **`imgtool help` / `version`（S07 dogfood 第一号摩擦）**：`help`、`-h`、`--help` 打印人类可读用法（命令、每个子命令的必选/可选参数、格式推断规则、`--mem-budget`），退出码 0；`version`、`-v`、`--version` 打印 `imgtool 0.1.7 (walkzzz/image.mbt)`。两者都不再是"未知子命令"的 JSON 错误，但**不带任何参数**调用仍回 `{ok:false, code:"process/invalid_argument", ...}`，供脚本/agent 判定。
- **`scripts/dogfood.mjs`**：8 个真实输入（ffmpeg 造的截图 / 有损照片 / 无损 WebP / 未压缩 BMP / 灰度 / 带 alpha / 4096² / 渐变）× 6 步流水线（info → decode → resize → sanitize → analyze → info）= 48 个操作，外加 8 条摩擦探针，输出 `dogfood@1` JSON。终态 `ops 48 / failed 0 / 探针 8/8 ok`，报告见 `docs/dogfood.md`。
- **`docs/dogfood.md`**：流水线表、8 条探针的修前/修后对照、格式决策规则，以及"仍未解决"三条（VP8 有损、`max_ms` 无强制中断、发布链待授权）。
- **`examples/quickstart`（5 分钟链路，四目标可编译）**：造图 → WebP 无损编码 → `load_from_bytes_auto` 解码 → `resize_to_cover` → PNG 出图 → 回读校验，全用子模块、不碰文件系统；README 的快速上手代码片段与它逐行一致，示例改坏 README 就直接编译失败。实测 `webp 156 B / png 158 B / verify ok=true`。
- **`image.codec/lib` 补 `encode_webp_lossless` / `decode_webp` 两个委托**：此前下游只 import `@lib` 时找不到 WebP 编码入口（实现在 `image.codec/codec`），得再记一个 import；现在 `@lib.save_image_auto(Webp)` 与 `@lib.encode_webp_lossless` 都在一处。
- **版本钉随版本走（发布链结构性修复）**：`scripts/bump_version.mjs` 现在会同时改写 7 个 `moon.mod` 里 `walkzzz/image.*@x.y.z` 的依赖钉；`scripts/check_version.mjs` 从 13 项扩到 **14 项**，钉子与版本不一致直接红并打印定位串。起因是 `moon publish --dry-run` 的 verify 用 registry 里的 `@0.1.1` 编 0.1.7 代码，一次 56 个 API 缺失。新增 `docs/release.md` 记录发布顺序、verify 语义与残余阻塞。
- **0.1.7 已发布到 mooncakes（七个模块齐发）**：`image.core / image.codec / image.process / image.photography / image.vision / image.domain / image.mbt` 全部 0.1.7，根包 verify `Check passed` + `Server status: 200 OK`。下游空项目 `moon add` 验收通过：`webp 124 B diff=0` / `png 125 B` / `downstream-ok=true`。安装摩擦（根模块 ≠ 子模块 import 权限；`moon.mod` 不收 `edition` 键、PowerShell 写文件带 BOM 会 lex 失败）已写进 README 与 `docs/release.md`。
- **`scripts/bump_version.mjs`**：一 Sprint 一 patch 的版本升级脚本，一次改 7 个 `moon.mod` + 门面 + CLI + 双语徽章 + `known-gaps` 口径行；`--to` 指定目标、`-n` 预演。
- `imgcli/imgtool_format_wbtest.mbt`：`format_from_ext`（含大写、`.tar.gz`、无扩展名）、`out_format` 优先级（`--format` > 扩展名 > fallback，`auto` 视为未给）、`help_text/version_text` 三条白盒测试。

### Changed

- **输出格式决策统一（S07 P2/P3/P4）**：新增 `out_format(flags, dst, fallback)`，优先级 `--format`（`auto` 视为未给）> 输出扩展名 > 子命令默认。`decode`/`encode` 默认 PNG，`resize`/`crop` 回退源格式，`sanitize` 回退"`strict` 强制 PNG、其余沿用 JPEG/WebP 源"。修前 `decode in.png out.jpg` 会写出 PNG 字节、`crop` 恒写 PNG、`sanitize in.jpg out.png` 会写出 JPEG 字节。
- **MCP 出口同步**：`crop` 工具补 `format`/`quality` 参数，`decode`/`resize`/`sanitize` 的 `format` 描述改为"省略时按输出扩展名推断"；冒烟仍 **33/33**。
- `scripts/check_docs.mjs` 的 B 系列与 `scripts/check_version.mjs`（12 → **13** 项，新增 CLI `--version` 与 `moon.mod` 对齐）。测试 6,698 → **6,701**；版本 0.1.6 → **0.1.7**。

## [0.1.6] - 2026-11-25

### Added

- **sanitize Recipe（S06）**：`imgcli/recipe.mbt` 提供 `sanitize_image(img, policy, regions, block, blur, format, quality)` 与 `Region / parse_region / parse_regions / clamp_region / redact_region / redact_all / blur_whole / metadata_hits / SanitizeResult`。三档 policy：`metadata`（只剥壳不动像素）、`standard`（剥壳 + 已知区域块均值打码）、`strict`（再加整图 box blur 并强制 png）。
- **CLI `sanitize` 重写**：`--policy metadata|standard|strict`、`--regions "x,y,w,h;x,y,w,h"`（越界裁剪、完全在图外报错）、`--block`、`--blur`；输出新增 `regions_redacted / blurred / metadata_free / metadata_hits`。
- **`docs/sanitize.md`**：三档 policy 语义、区域语法、打码方式、失败模式表、已知限制（不承诺人脸检测）。
- **`scripts/mcp/sanitize_batch.mjs`**：200 张注入 EXIF/GPS/XMP/ICC/缩略图签名的 JPEG，三档 policy 全跑 → `residue 0 / failed 0`，并复核输出可解码、尺寸不变。
- **MCP `sanitize` 工具扩展**：schema 增 `policy=standard`、`regions`、`block`、`blur`；冒烟新增 6 条用例（standard 打码块数、strict 整图模糊 + png、默认不动像素、PNG 真压缩、非法 region、非法 policy），共 **33/33**。
- `image.codec/codec/png_deflate_wbtest.mbt`：CRC 回归、重复数据压缩后可 inflate 还原、伪随机数据可还原 三条白盒测试。
- **`image.codec/codec/webp_vp8l_rfc_test.mbt`**：VP8L「码长码单叶子零比特」回归样本（4×4，92 B 手工拼装，已用 Pillow 校验内容），锁死本轮最后一处比特错位。
- **`scripts/proto/webp_battery.py`**：WebP 无损解码回归——PIL(libwebp) method 0/4/6 × 9 类内容（渐变 / 三种调色板 / alpha / 灰度 / 噪声 / 噪声+alpha / 截图风）× 12 种尺寸，加 ffmpeg `-lossless 1` 的 testsrc2 / smptebars / mandelbrot；**321 例逐像素全等**。基准取 Pillow 解码同一份 webp（源图与 webp 内容并不等价），避免把编码器行为误判成解码 bug。
- **`bench_real.mbt` 新增 `webp_decode_1024`**：自家编码器产物往返解码 **15.68 ms / 66.8 MP/s**，是 PNG（7.9）/ JPEG（9.0）的 7 倍以上，因为 VP8L 走整数 predict + LZ77 拷贝。

### Fixed

- **VP8L 无损解码 7 处缺陷全部修掉（标准编码器产物现可逐像素还原）**：① 单符号前缀码必须零比特；② simple 双符号按符号值排序（小符号分码 0）；③ 调色板逆变换按 bundle 还原原宽度（此前 4 色/16 色图尺寸错位）；④ `max_symbol` 数的是「码的个数」而不是「已填下标」，且 code 16 重复上一个**非零**码长（长零串会提前结束循环，导致后续树整体错位）；⑤ 色彩缓存 hash 用 32 位无符号右移；⑥ predictor 模式 11（Select）按 RFC 9649 `p = L + T - TL` 重写；⑦ **码长码单叶子（19 符号字母表只剩 16 号）同样零比特**——这是最后 4 例噪声图全错的根因。另加 Kraft 完整性校验，把「静默输出全黑」变成可定位的 `decode/decode_failed`。
- **PNG chunk CRC 全错**（致命）：`image.codec/util/zlib.mbt` 的 `crc32_table` 生成与 `crc32` 用 `>>` 算术右移，高位污染导致所有 chunk CRC 非法，产物 PIL / ffmpeg 拒开。改为逻辑右移掩码后 CRC 全绿、外部工具可读。
- **PNG 输出几乎不压缩**：编码器原是 stored deflate + filter 0，640×360 输出 **691,678 B**（比源文件大 26 倍）。新增 `png_deflate.mbt`（fixed Huffman + 32KB hash-chain LZ77 + `zlib_compress`）与逐行 5 种 filter 择优（含 Paeth），同一图降到 **30,243 B（22.9×）**，PIL 逐像素 maxdiff 0；RGB / RGBA / 灰度三种通道组合均逐像素一致，1024² 输出 129,762 B（ffmpeg 同源 111,803 B，1.16×）。

### Changed

- **性能口径更新**：`docs/performance.md` 的 PNG 数字换成新压缩器实测（`png_encode_1024` 95.25 ms / 11.0 MP/s、`png_decode_1024` 132.34 ms / 7.9 MP/s），并注明旧数字对应 stored 流、已失效。
- 测试总数 6,691 → **6,697**；包数不变 75；版本 0.1.5 → **0.1.6**。

## 展示页（2026-11-23）

### Added

- **GitHub Pages 库首页**（`docs/index.html`）：Hero、12 项能力、3 张浏览器内演示（QR 生成 / 亮度与模糊滤镜 / PNG 摘要）、快速开始、API 表、质量指标与文档入口；深浅主题与模块 README 跳转。
- **`playground/` 导出层**：4 个函数（版本、QR PNG、滤镜 PNG、PNG 摘要），PNG 以十六进制字符串跨 JS 边界，无需后端。
- **`scripts/check_pages.mjs`**：49 项门禁（构建产物、导出、QR/滤镜/摘要语义、页面结构、模块链接、口径数字）。

## [0.1.5] - 2026-11-25

### Added

- **CLI `imgtool`**：`imgcli` 库包（可 whitebox 测试）+ `cmd/imgtool` 入口，7 个子命令 `info / decode / encode / resize / crop / analyze / sanitize`；结果恒为 stdout 单行 JSON，失败退出码 1。
- **MCP server**（`mcp/server.mjs`）：stdio JSON-RPC 2.0（`initialize / tools/list / tools/call / ping`），6 个工具（`decode / encode / resize / crop / analyze / sanitize`）+ JSON Schema；省略 `output` 时直接以内联 base64 图片返回。零第三方依赖，冷启动 73 ms。
- **`--mem-budget` 全链路生效**：MCP `mem_budget` / `IMGTOOL_MEM_BUDGET` / CLI `--mem-budget` → `DecodeLimits`（`max_bytes = N`，`max_pixels = N/8`），仍在解码分配前拒绝。
- **`scripts/mcp/smoke.mjs`**：27 条端到端用例（正常 7 工具 + 9 类失败 + 协议面），当前 27/27。
- **`docs/mcp.md`**：启动、6 工具表、错误契约、限额三入口、CLI 直用、验证与已知限制。

### Changed

- 新增根模块依赖 `moonbitlang/x@0.5.9`，**仅供 CLI 文件读写**（`imgcli/io.mbt` 用 `#cfg(target="native")` 分叉，wasm/js 下保留同签名的拒绝实现，四目标编译门禁不受影响）。

## [0.1.4] - 2026-11-25

### Added

- **`ImageError` + stable codes**: `Decode / Encode / Process / Budget / Cancelled`, `code()` returns `decode/truncated`, `budget/limit_pixels` and similar; `ErrorCode::is_budget()`, `ImageError::message()`, `image_error_hint(code)`, and `image_error_from_load` to project legacy `LoadError` without touching its signature.
- **`DecodeLimits`** (`max_pixels / max_bytes / max_ms`, plus `default_limits` / `strict_limits` / `with_max_pixels`) and **`AllocBudget`** admission checks for pixel operators.
- **`@lib.decode_with_limits(bytes, limits)`** / **`check_decode_budget`**: byte budget → header-declared pixel budget → decode, so a decode bomb is rejected *before* allocation. Plus `docs/error-model.md` (code table, budgets, usage, verified attack surface).

### Note

- `max_ms` is admission + post-hoc only: a synchronous pure-MoonBit loop cannot be killed mid-flight, so OOM protection rests on the byte/pixel caps.

## [0.1.3] - 2026-11-25

### Added

- **`encode_jpeg_with_quality(img, quality)`**: libjpeg-style quant-table scaling (1–100, 50 = standard tables). `@lib.save_image_with_quality` now honors `quality` for JPEG instead of discarding it.
- **JPEG regression tests** (`jpeg_fdct_int_test.mbt`): integer-FDCT roundtrip, quality tiers on 1024², and a solid-color roundtrip that guards the quant-table aliasing bug.

### Changed

- **JPEG encoder ~6.4× faster**: separable float DCT → **integer AAN FDCT** (libjpeg `jfdctint` equivalent, ×8 output absorbed by `1/(q*8)` inverse quant), fixed-point RGB→YCbCr, precomputed inverse quant, image-level scratch reuse. `jpeg_encode_1024`: 534.56 ms → **82.90 ms (12.6 MP/s)**.
- **JPEG decoder ~4.2× faster**: separable IDCT with a single cosine table, reusable block/spatial/float scratch (no per-block allocation), integer YCbCr→RGB. `jpeg_decode_1024`: 495.22 ms → **116.36 ms (9.0 MP/s)**.

### Fixed

- **JPEG decoder color distortion**: `jpeg_parse_header` built `Array::make(4, Array::make(64, 0))`, so all four quantization-table slots shared one array — the second (chrominance) table overwrote the first (luminance). Roundtrip mean error dropped from 5.7 to 0.50 (max 3) against ffmpeg/PIL.

## [0.1.2] - 2026-11-25

### Added

- **WebP VP8L lossless encoder**: `encode_webp_lossless(img)` — palette / predictor / subtract-green / LZ77 candidates, each encoded once and the smallest payload wins. Output byte-verified against libwebp via ffmpeg (solid / checker / gradient / noise).
- **VP8L RFC decoder path**: `decode_webp_vp8l_rfc(bytes)` — four inverse transforms (predictor 14 modes, cross-color, subtract-green, color indexing), meta prefix groups, color cache.

### Changed

- `save_image` / `save_image_with_quality` now route WebP to the lossless encoder; `quality` is ignored for WebP.
- `encode_webp_lossy_pure` / `encode_webp_lossy_full` marked `#deprecated` (invalid VP8 partitions, see GAP-27).
- Bench: `webp_encode_1024` now measures the lossless encoder (244.83 ms / 4.28 MP/s, x86 release).
- Docs: `docs/performance.md` rewritten WebP row and stale "331 MP/s" conclusion; `docs/webp-encoder.md` M3 log + volume table; `docs/roadmap.md` S02 closed.

### Fixed

- **simple code length code (2 symbols)**: first symbol must honour `is_first_8bits`; writing 8 bits unconditionally shifted the whole tree.
- **simple code only spans symbols [0..255]**: green tree mixes literals and length prefix codes — length symbols were silently truncated (279 → 23). Guard: all symbols < 256.
- **single leaf with symbol > 255 must use the normal code length code** (all other lengths zero, leaf length 1), per RFC 9649 §3.7.2.1.
- `vp8l_residual_cost`: hoisted the per-call array literal out of the 14-mode × pixel loop → predictor candidate 3.3x faster.

## [0.1.1] - 2026-11-20

### Added

- **可运行示例集**：`examples/` 7 个零外部依赖示例（raw_to_png / resize_demo / threshold_otsu / format_detect / lossless_roundtrip / canny_edges / gaussian_blur），均 `moon run` 实测通过，见 docs/examples.md。
- **测试输入生成器 `image.core/testgen`**：QR（版本 1-L / 字节模式 / 掩码 0，GF(256)+RS）、Code39 / Code128 / EAN-13 / UPC-A 条码、5×7 数字与 A–Z 字母点阵、VP8 key/inter 帧（RFC 6386 帧头 + 零填充分区）、多标签 EXIF 样本（小端 TIFF + JPEG APP1：ISO/曝光/光圈/焦距/模式/白平衡/闪光/GPS），均为纯 MoonBit。
- **变异测试闭环**：`scripts/mutation_test.mjs`（7 包 / 12 变异点，100% KILLED）+ CI `mutation` job + `mutation-report.json` artifact。
- **质量门禁脚本**：`scripts/check_docs.mjs`（9 断言 + 5 负向自测）、`scripts/check_coverage.mjs`（≥80.5%）、`scripts/check_version.mjs`（七模块版本一致）、`scripts/publish.sh`（依赖序发布，由维护者执行）。
- **治理文件**：TEST_REPORT.md、docs/known-gaps.md、CONTRIBUTING.md、SECURITY.md、CODE_OF_CONDUCT.md、PR 模板、CODEOWNERS。

### Changed

- **CI 重构**：单 job → 6 jobs（quality / test 四目标矩阵 / bench / coverage / mutation / prove，ubuntu-24.04）；`mbti` 漂移与 `moon fmt --check` 改为阻断；`scripts/` 取消 gitignore，门禁脚本随仓库发布。
- **测试**：6,580 → **6,664**（+84：门禁/边界补测、7 个零覆盖大文件补测、分割/视频/拼接/TIFF/Codec trait/EXIF/OCR 补测、8 个白盒测试文件、testgen 生成器驱动 QR/Code39/Code128/EAN-13/UPC-A/OCR/VP8/EXIF、A–Z 字母点阵驱动英文 OCR、OCR 评估/训练纯函数、英文 OCR 私有特征/模板匹配白盒直调、VP8 字节级 intra 帧与 4 种字节模式（324→402/620）+ IDCT/WHT/预测/滤波算法白盒、TIFF LZW/PackBits 解码、WebP 编解码互操作与奇数尺寸回归）。
- **弃用 API 迁移**：19 处 `Int64::from_int` / `Double::from_int` → `to_int64()` / `to_double()`，四目标 `check --deny-warn` 零警告。

### Fixed

- **WebP VP8 编码奇数尺寸崩溃**：`rgb_to_yuv420` 的 UV 平面按 `w/2*(h/2)` 分配、索引却按 `ceil(w/2)` 步长访问，1x1/3x3 触发 `PanicError`；改为 `ceil(w/2)×ceil(h/2)` 分配并统一步长，新增 1x1 / 3x3 / 1 通道拒绝回归测试。
- **WebP VP8 解码无法解自身编码**：`parse_vp8_frame_header` 把 3 字节帧 tag 当 MSB-first 3 位读取并判 `tag == 0`，合法关键帧被误判为非关键帧；按 RFC 6386 改为小端 tag（bit0=关键帧、bit5-23=first_part_size）+ 小端分辨率解析，自编码 16x16 / 8x8 / 32x32 / RGBA 往返全部通过。
- **WebP VP8 解码奇数尺寸崩溃**：色度平面按 `w/2*(h/2)` 分配导致 1x1/3x3 越界 panic；解码器现返回明确 `DecodeFailed`（正确 ceil 平面支持列入后续，见 GAP-17）。
- **QR 解码器无法定位/解析标准码**：修复 4 处缺陷——垂直验证从中心行而非图案顶部扫描（检测恒为 0）、finder 重复计数且 x/y 语义不一致、版本公式偏移（V 恒偏大 1）、格式信息位序反（MSB/LSB）。修复后 testgen 生成的版本 1-L/mask 0 码可完整往返（`hello`）。
- **VP8 inter 帧恒被拒绝**：inter 帧头不携带分辨率，原实现从 header 取 0 后判无效；改为回退参考帧宽高（保留偶数对齐守卫），16×16 inter 帧可解码。
- 文档口径：版本 0.5.0/0.1.0 冲突、测试数 6,574/6,486、包数 71、proof 5 goals、覆盖率 90.4% 全部按实测纠正（覆盖率 **83.4% = 32862/39395**）；删除死链 banner 与旧仓库链接；`docs/examples.md` 虚报 32 示例改为真实清单。
- 测试盲区：resize 零/负尺寸断言被 try/catch 吞掉、最近邻下采样与 Otsu 渐变图只断言尺寸。

### Verified

- `moon check --deny-warn --target all` 零警告；`moon test` **6,664/6,664**（native，2026-11-20）；CI 6 jobs（quality / test×4 / bench / coverage / mutation / prove）。
- 覆盖率 32,862/39,395 = **83.4%**（门槛 80.5%）；变异 **12/12 KILLED（7 包）**；`moon prove` **8 goals proved**（WSL Why3 1.6.0 + Z3 4.8.12）。

## [0.1.0] - 2026-11-17

### Breaking（包重命名重构 — 破坏性变更）

模块名统一重构：根模块 `walkzzz/image` → **`walkzzz/image.mbt`**，六子模块加 `image.*` 前缀，子模块目录同步改名（core/ → image.core/ 等）。**API 零变化，纯前缀迁移**；下游需更新安装命令与 import 路径：

| 旧模块名 | 新模块名 |
|---|---|
| walkzzz/image | walkzzz/image.mbt |
| walkzzz/core | walkzzz/image.core |
| walkzzz/codec | walkzzz/image.codec |
| walkzzz/process | walkzzz/image.process |
| walkzzz/photography | walkzzz/image.photography |
| walkzzz/vision | walkzzz/image.vision |
| walkzzz/domain | walkzzz/image.domain |

- import 迁移规则：`walkzzz/image` → `walkzzz/image.mbt`；`walkzzz/<子模块>` → `walkzzz/image.<子模块>`
- 完整迁移示例见 README.md「从 walkzzz/image（0.6.x）迁移」章节
- 旧名包（walkzzz/image@0.6.0 及六子模块@0.1.0）在 mooncakes 上保留可装，不再更新；已于 2026-11-17 对旧模块全部 13 个版本（walkzzz/image 7 版 0.4.8~0.6.1 + 六子模块各 1 版）标记 deprecated，`--reason` 指引对应新模块名（`moon deprecate --undo <模块名>` 可恢复）
- 版本号重新计数：新名包首发 0.1.0

### Fixed
- mp4 包修复（上次提交遗留的不可编译半成品）：补齐缺失的大端字节读取原语 `read_u32`/`read_u64`；`parse_chunk_offsets` 的 stco 按规范读 32 位字段（原误用 64 位读取污染偏移值）；`compute_sample_offset` 修正 chunk 首样本 1-based 偏移并补数组下界保护；白盒测试合成数据修正（stbl 子 box 缺 header 包装、stsc 条目缺 sdi 字段且 first_chunk/samples_per_chunk 字段顺序颠倒）
- 元数据修正：7 个 moon.mod 的 `repository` 字段与六子模块 README、`docs/proposal.md` 中的 GitHub 仓库链接，由 `toadium/image` 统一更新为 `https://github.com/walkzzz/image.mbt`（`docs/examples.md` 指向 stb-image 上游参考仓库的链接不受影响）

### Verified
- `moon check --deny-warn --target all` 零警告；`moon test` 四目标 6580/6580 全绿
- `moon info` 重新生成 `.mbti`：仅 `package` 路径行变化，公共 API 符号零变化
- 目录树/徽章/文档/脚本同步更新（136 文件批量替换 + 人工治理）

## [0.6.1] - 2026-11-13

### Added
- `docs/pitfall-catalog.md` — 15 measured pitfalls（M 系列 MoonBit 语法演进 9 条 + I 系列项目特有 6 条：workspace 发布陷阱 / mooncakes 409 占用 / coverage 口径换算）
- `docs/proposal.md` — quarterly award proposal（章程 8 项内容 + 六竞品差异化 + stb 移植合规 + AI 把控声明 + OCR 量化验收引用）
- `scripts/check_docs.mjs` — doc-number consistency self-check（5 正向断言 + 7 负向自测全绿：双语 badge 漂移 / proof goals 漂移 / moon.mod 与 badge 版本分离，全部检出）

### Fixed
- `.github/workflows/ci.yml`：四行 `--targetnative` 等参数空格修正（原生笔误，CI 四个月未通过的主因）
- 六个子模块 moon.mod `repository` 统一 → toadium/image

### Changed
- `docs/notes.md` 重写（0.6.0 / 6574 / workspace 口径）；AGENTS.md 元数据对齐（8 goals 函数名实测）；README 自演化叙事（中英）+ 子模块安装说明 + comparison 刷新（2026-11-13 四家升级）+ mooncakes 徽章

## [0.6.0] - 2026-11-13

### Changed
- 版本号顺移：mooncakes 0.5.0 已发布且对应旧单模块结构，workspace 六模块重构后的首个发布版本 bump 至 0.6.0（避免 409 冲突）
- README badge 数据修正：测试数 6,526 → **6,574**（`moon test --target native` 实测全绿）、形式化 5 → **8 goals proved**（`moon prove` 实测，与 docs/changelog.md 内部记录对齐）
- CI 零警告门禁：4 处 `moon check` 增加 `--deny-warn`（固化 568 tasks 零警告状态，防回退）
- 新增 mooncakes 徽章与生态采用展示（moonrockz/diagrams-raster 为首个依赖方）

## [0.5.0] - 2026-10（mooncakes 已发布）

### Added（摘要，完整记录见 docs/changelog.md 的 "v0.5.1 Sprint A-H" 与 "Phase 18"）
- MoonBit 属性系统优化 Sprint A-H：`#derive` 补全（~100+ 类型）、`#inline` ×14、`#deprecated` ×5、`#non_exhaustive` ×149、255 个 @see 引用、~1460 行双语文档注释
- 形式化验证 5→8 goals proved（int_max / int_min / dims_valid_check 新增；clamp_int/clamp_coord 等谓词预留，SMT 超时与前端限制见 safe_math.mbtp 注释）
- R13 Warning 治理：27 处 `#warnings("-deprecated")`
- **Workspace 六模块重构**：src/ 单体 → core/codec/process/photography/vision/domain

### 统计（v0.5.1 实测）
- moon check: 0 error, 0 warning · moon test: 6574/6574 pass (native) · moon prove: 8 goals proved

## 更早版本

完整历史（v0.1 → v237.0.0 全部 Sprint/Phase 记录）见 [docs/changelog.md](docs/changelog.md)。
