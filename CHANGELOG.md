# CHANGELOG

> 本文件为变更**摘要**（面向评审与使用者的第一入口）。完整功能迭代历史（v0.1 → v237.0.0，3300+ 行）见 [docs/changelog.md](docs/changelog.md)。

**版本双轨说明**：功能迭代版本（v0.1 → v237.0.0）与 mooncakes 包版本（0.x.y）并行演进；包版本随发布递增，workspace 六子模块（image.core/image.codec/image.process/image.photography/image.vision/image.domain）版本随主包同步。

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
