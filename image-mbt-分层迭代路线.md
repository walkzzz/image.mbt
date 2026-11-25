# image.mbt 分层迭代路线（场景适配版）

> 目标：让这个库从"算法很全的纯 MoonBit 图像库"，变成"**每个真实场景都有现成入口**"的工具底座。
> 方法：按 **L0 内核 → L1 编解码 → L2 算子 → L3 场景包 → L4 出口 → L5 生态** 六层扩张，每层只解决自己那一层的问题，下层不做场景判断，上层不重复造算法。

---

## 一、分层模型（总览）

| 层 | 职责 | 当前状态 | 扩展原则 | 判定"这一层做完了" |
|---|---|---|---|---|
| **L0 内核** | 数据类型、内存、错误、元数据、取消 | Image/Image16/ImageF 三套；`LoadError` 单一错误类型；ImageF 峰值约 12GB；无 ROI/零拷贝 | 只做"表示与约束"，不做任何算法 | 三深度统一抽象、错误码可透传、内存按预算分配 |
| **L1 编解码** | 18 格式读写、容器、元数据、格式选优 | 解码很全；编码偏窄；流式是"全解再分发"；无区域解码 | 只做"字节 ↔ 像素"，不做业务规则 | 每格式 roundtrip 过、大图可分块、恶意文件不 OOM |
| **L2 算子** | 90+ 算法：几何/滤波/边缘/特征/分割/频域/绘制/度量 | 广度高；8/16/float 三套重复；多为整图 in-place 不便 | 只做"像素 → 像素"，输出确定、可组合 | 三深度同测试、ROI 版本与整图一致、有性能预算 |
| **L3 场景包** | 把算子组合成"一次调用解决一件事"的 Recipe | 只有一个 `domain` 大包，医学/遥感/水印/取证混装 | **一场景一包**，只做组合与业务规则，不复制算法 | 每个包有 Recipe API + golden set + 失败模式文档 |
| **L4 出口** | CLI / WASM 组件 / HTTP 服务 / MCP / Playground | 几乎没有；演示页写好但 404 | 只做"调用方式"，不做算法 | 不会 MoonBit 的人也能用；Agent 能调 |
| **L5 生态** | 技能注册、artifact 协议、基准集、兼容层 | 无 | 只做"对外契约" | 别的项目能依赖、能复算、能对比 |

关键约束：**分层不是分叉**。L0–L2 只有一份实现、四目标同源；L3 只允许"组合 + 参数 + 业务规则"；L4 只允许"协议适配 + 参数编排"。任何在 L3 里复制一遍 resize 的做法都应被 review 拒绝。

---

## 二、场景适配的三个粒度（判断一个场景"真的适配了吗"）

一个场景要算真正可用，必须在三层都有东西，缺一层就是"能算不能用"：

1. **Primitive（算子级）**：算法本身正确、有精度与性能指标。例：`warp_perspective`、`grab_cut`、`cclahe`。
2. **Recipe（配方级）**：把 5–10 个算子串成"一次调用"，输入输出是业务语义。例：`make_id_photo(bytes, {size:"1寸", bg:"蓝"})`。
3. **Product（产品级）**：CLI 一条命令、HTTP 一个 URL、MCP 一个工具、页面一个按钮。

> 现有仓库 90% 的场景只做到了 1，少数做到 1.5，2 和 3 基本空白——这就是"能力很强但用不上"的根因。

---

## 三、六层各自要补什么（含 API 名与验收）

### L0 内核加固（0.2.0 必做）

| 要补的 | 具体交付 | 验收 |
|---|---|---|
| 零拷贝视图 | `ImageView{data, stride, fmt, rect}` + `ImageMut`，所有算子可接收视图 | 大图 ROI 处理内存不随整图增长 |
| 统一像素抽象 | `Plane`/`PixelFmt`（8/16/float × 1/3/4 通道），算子走 trait，替代三套重复（roadmap v5.1） | 同一算子三深度共用一套测试 |
| 内存预算 | `alloc_budget(max_bytes)`、`MemoryGuard`，ImageF 12GB 峰值改为按 tile 分配 | 20000×20000 图在 512MB 内完成缩略图 |
| 统一错误模型 | `ImageError{Decode,Encode,Process,Budget,Cancelled}` + 稳定错误码字符串 | CLI/MCP/HTTP 都能原样透传错误码 |
| 取消与进度 | `CancellationToken` + `Progress`（行/块粒度） | 长任务可在 100ms 内中止且不留半成品 |
| 元数据强类型 | `Metadata{exif, icc, xmp, iptc, gps}` + `strip(policy)` | 剥离策略可断言（逐字段检查） |

### L1 编解码扩展（0.2.0–0.4.0）

按"场景需要"排序，不是按"格式齐全"排序：

1. **区域解码与 tile**：`decode_region(bytes, rect)`、`tiles(bytes, tw, th)`，先做 PNG/BMP/QOI（这三个最容易真增量）。
2. **渐进式 JPEG 解码**：首扫出 1/8 预览，用于网页/移动端"先糊后清"。
3. **动画容器闭环**：GIF/APNG/动画 WebP 的解码 + 帧编辑 + APNG 编码（表情包、动图压缩场景必需）。
4. **编码补齐（按需）**：PNG 调色板量化、JPEG 4:2:0 与渐进编码、WebP alpha、ICO 多尺寸、TIFF LZW 编码、EXIF 内嵌缩略图。
5. **格式选优**：`best_format(image, {target_bytes, quality_floor})` —— 电商/CDN 场景的核心 API，同质量下自动选体积最小格式。
6. **解码限额**：`decode_limits{max_pixels, max_bytes, max_ms}`，防解压炸弹；截断文件容错。
7. **元数据往返**：EXIF 写回、Orientation 自动应用、ICC 嵌入/转换。

验收：18 格式 golden 文件 roundtrip 像素差 ≤1；渐进 JPEG 首扫 <300ms；100MB 恶意 PNG 在预算内被拒且不 OOM。

### L2 算子扩展（0.3.0–0.4.0）

- **通用能力**：ROI/in-place 全覆盖（Top 30 算子先做）、`map_rows` 流式滤波、8/16/float 泛化、确定性声明。
- **性能**：native 分支的 SIMD/多线程（若 MoonBit 支持），PNG unfilter、JPEG DCT、resize 专项；bench CI 阈值退化 >8% 即 fail。
- **场景专属算子**（补现有 90 个没覆盖的"脏活"）：
  - 文档类：去阴影（光照估计）、去摩尔纹（频域 notch + 引导滤波）、去白边/自动裁边、纸张角点检测、文字行检测、表格线检测、印章检测；
  - 电商类：商品主体显著性、边缘精修 matting（grab_cut 后处理）、白底合成、圆角/描边/投影；
  - 消费类：智能裁剪（saliency + 人脸 + 熵）、老照片划痕检测 + 修复、去色偏、人像保守磨皮；
  - 内容类：水印（文字/图片/平铺/鲁棒）、ELA 篡改打分、拼图/联系表；
  - 度量类：`sharpness`/`blockiness` 用于编码选优，`ΔE2000` 用于色彩预检。

验收：每算子三深度同测试；resize 12MP <80ms；ROI 版与整图版像素一致；新增算子必须带 golden 用例。

### L3 场景包（这是"更多场景"的主战场）

**架构改造建议**：把现在的一个 `image.domain` 拆成**八个可独立安装的场景包**。用户为了裁一张图不该装 70 多个包。

| 包 | 覆盖场景 | 核心 Recipe API | 验收基线 |
|---|---|---|---|
| `image.doc` | 发票/票据、证件、合同、扫描件、白板、长截图 | `scan_clean`、`deskew`、`detect_page`、`layout_parse`→JSON、`table_to_csv`、`field_extract(schema)`、`seal_detect`、`pdf_pages`、`to_pdf` | 100 张发票/证件 golden：字段准确率 ≥85%，单页 <2s |
| `image.media` | 社交/内容平台合规、封面、去重、溯源 | `sanitize`（去 GPS/EXIF）、`redact(faces/plates/text)`、`watermark_batch`、`phash_index`、`tamper_score`、`cover_specs` | 200 张集：脱敏字段 0 残留，人脸召回 ≥95% |
| `image.commerce` | 电商主图、白底图、详情页、模特图 | `white_bg`、`product_cutout`、`main_image_specs`（1:1/3:4/16:9）、`rounded`、`color_check` | 主体边缘 IoU ≥0.9，白底 ΔE ≤2 |
| `image.photo` | 手机照片增强、全景、HDR、超分、老照片、贴纸 | `auto_enhance`、`hdr_merge`、`panorama`、`super_res`、`old_photo_restore`、`sticker` | PSNR/SSIM + 20 张人工抽样 |
| `image.medical` | DICOM 查看、窗宽窗位、测量、标注 | `dicom_read/write`、`window_level`、`measure`（长/面积/角度）、`annotate` | 样例集 roundtrip，测量误差 <1px |
| `image.geo` | 遥感、地图瓦片、变化检测 | `geotiff_tags`、`ndvi`、`tile_pyramid`、`mosaic`、`change_detect` | 坐标/tags 不丢，瓦片对齐 |
| `image.print` | 印刷前预检、设计稿导出 | `cmyk_convert`、`icc_convert`、`bleed_check`、`dpi_check` | ΔE2000 ≤3 |
| `image.industry` | 工业质检、测量、模板匹配 | `template_match`、`defect_detect`、`caliper_measure`、`calib` | 缺陷召回/误报双指标 |

每个包的统一结构：`recipe API` + `golden 数据集（50–200 张，随包发布）` + `失败模式文档（什么情况下会不准）` + `性能预算（每场景 P95 耗时）`。

### L4 出口（决定"有没有人真的用"）

| 出口 | 形态 | 首个版本 | 关键要求 |
|---|---|---|---|
| Playground | 静态站（`docs/` 已存在，只需部署） | 0.2.0 | 200 状态、移动端可用、四面板（格式转换/缩略图/滤镜/OCR+QR） |
| CLI | `moonimg`（native + WASI） | 0.2.0 | 8 个子命令、JSON pipeline、`--dry-run`、`--mem-budget`、失败隔离、机器可读报告 |
| WASM 组件 | `image-wasm` npm 包 | 0.3.0 | `optimizeForWeb`、Worker、可取消、能力探测与 AVIF/WebP 回退、<1.2MB gzip |
| HTTP 服务 | `image-server`（`/i/{op}?w=&h=&f=&q=&fit=`） | 0.3.0 | 签名、缓存头、P95 <150ms（1MP resize）、限流与解码限额 |
| MCP | `image-mcp`（10+ 工具） | 0.2.0 | JSON Schema、稳定错误码、幂等、20 条脚本化用例 ≥95% |
| 绑定 | Dart（经 moon2dart）、JS、Python（经 wasm） | 0.4.0 | 与 L2 算子一一对应，不另起实现 |

### L5 生态与协议

- **agentskills 联动**：`image-skill`（SKILL.md）声明"什么场景调哪个工具、参数边界、验收断言"，让 agentskills 运行时第一次拥有确定性图像工具。
- **gbz185 artifact 协议**：图像作为 Agent 间 artifact 时，附 `phash + watermark_id + sanitized 标记 + 来源`，形成"可信图像传递"的演示场景。
- **公开基准集**：`image.mbt-bench`（golden + 恶意样本 + 性能基线），让别人能复算你的 6,664 测试和 83.4% 覆盖率。
- **能力真值表**：格式矩阵/函数数/覆盖率/测试数全部脚本从 `.mbti` + codec 枚举生成，README 用占位符注入（治本方案见上一份报告第二节）。

---

## 四、30 个场景 → 包 → 层 的映射（优先级）

| # | 场景 | 归属包 | 依赖层 | 现状缺口 | 优先级 |
|---|---|---|---|---|---|
| 1 | 证件照换底/排版 | commerce/photo | L2 抠图 + L4 CLI | 无模板、无排版 | P1 |
| 2 | 发票识别归档 | doc | L2 预处理 + L1 PDF | 无版面 JSON、无字段抽取 | P0 |
| 3 | 合同/证照扫描增强 | doc | L2 去阴影 | 无去阴影/去摩尔纹 | P0 |
| 4 | 白板/笔记拍照净化 | doc | L2 去阴影 + 二值化 | 未组合 | P1 |
| 5 | 电商白底主图 | commerce | L2 matting | 抠图边缘不精 | P0 |
| 6 | 商品/模特换背景 | commerce | L2 抠图 + 合成 | 无合成 API | P1 |
| 7 | 发布前隐私脱敏 | media | L1 元数据 + L2 打码 | 无 `sanitize` 成品 | P0 |
| 8 | 图片去重/版权比对 | media | L2 phash（已有） | 无反查索引与阈值策略 | P1 |
| 9 | 手机照片一键增强 | photo | L2 | 无 auto_enhance 配方 | P1 |
| 10 | 全景拼接 | photo | L2（已有拼接） | 无产品化 | P2 |
| 11 | 表情包/贴纸 | photo | L2 抠图 + 描边 | 无透明导出链 | P1 |
| 12 | 课件/PPT 配图批量 | doc/CLI | L4 CLI | 无批处理 | P0 |
| 13 | 医学影像查看 | medical | L1 DICOM + L2 | 无 DICOM 容器 | P2 |
| 14 | 遥感变化检测 | geo | L1 GeoTIFF + L2 | 无 tags/多光谱管线 | P2 |
| 15 | 工业缺陷检测 | industry | L2 + L3 | 无模板匹配/差分基准 | P2 |
| 16 | 印刷色彩预检 | print | L1 ICC + L2 ΔE | 无 ICC/CMYK | P2 |
| 17 | 视频封面抽取 | media | L1 mp4（已有）+ L2 | 无"关键帧→多规格"链 | P1 |
| 18 | 动图压缩/编辑 | media | L1 动画容器 | 无 APNG 编码、无帧编辑 | P1 |
| 19 | 网站图片服务 | L4 服务 | L1 选优 + L2 | 无 HTTP 层 | P0 |
| 20 | Agent 图像工具 | agent | L4 MCP | 无 MCP | P0 |
| 21 | 地图瓦片生产 | geo | L1 tile + L2 | 无金字塔 | P2 |
| 22 | 合同签章定位 | doc | L2 印章检测 | 未做 | P2 |
| 23 | 车牌/人脸脱敏 | media | L2 检测 + 打码 | 检测有、打码无成品 | P1 |
| 24 | 老照片修复 | photo | L2 划痕/色偏/修复 | 算子有、配方无 | P2 |
| 25 | 标注预分割 | industry/photo | L2 分割（已有） | 无"预标注导出" | P2 |
| 26 | 长截图拼接/切分 | doc | L2 拼接 | 未做长图逻辑 | P1 |
| 27 | 二维码/条码批量 | commerce/doc | L1 barcode（已有） | 无 batch 与容错 | P1 |
| 28 | 训练数据增强 | industry | L2 + 确定性 | 无增强流水线 | P3 |
| 29 | 视觉回归测试 | L5 | L2 SSIM（已有） | 无 golden diff 工具 | P1 |
| 30 | 水印溯源 | media | L2 鲁棒水印 | 有嵌入、无提取/抗攻击基准 | P2 |

---

## 五、版本节奏（每版必须同时有"层进展 + 场景落地 + 出口"）

| 版本 | 主题 | 层进展 | 场景落地 | 出口 | 出口验收 |
|---|---|---|---|---|---|
| **0.2.0**（4–6 周） | 能用 | L0 视图/预算/错误模型；L1 限额 + `best_format` + EXIF；L2 Top10 算子 ROI | doc MVP（发票/扫描）、media MVP（脱敏） | Playground 上线、CLI 6 命令、MCP 5 工具 | 1000 张批处理不中断；20 条 MCP 用例 ≥95%；演示 200 |
| **0.3.0**（6–8 周） | 场景成包 | L1 渐进 JPEG + 动画容器；L2 去阴影/摩尔纹/抠图精修 | commerce（白底/主图）、photo（增强/贴纸） | HTTP `image-server`、WASM npm 包 | 服务 P95 <150ms；3MB 手机照 → <200KB |
| **0.4.0**（8–10 周） | 大图与专业 | L1 真增量 + tile；L2 16-bit 泛化 + SIMD/线程；L3 medical/geo/print | DICOM 查看、GeoTIFF/NDVI、印刷预检 | Dart/JS 绑定 | 20000² 图 512MB 内出缩略图；ΔE ≤3 |
| **1.0**（12 周+） | 可承诺 | 性能预算全达标、覆盖率 90%、文档真值 | industry、agent 完整工具集 | 技能市场发布 + 基准集公开 | 所有门禁绿、外部可复算 |

**并行纪律**：每个版本只允许新增 1–2 个场景包；先做"需求密度最高"的 doc / media / commerce，medical/geo 属于长线专业纵深，不要和消费级场景抢档期。

---

## 六、分层门禁（CI 怎么卡住"表面完成"）

| 层 | 门禁 | 不通过的表现 |
|---|---|---|
| L0 | 三深度类型不丢 + 预算内不 OOM + 错误码全覆盖 | 大图 OOM、错误信息只有一句话 |
| L1 | 18 格式 golden roundtrip + 恶意样本拒收 | 某格式编码出来打不开、恶意图拖垮进程 |
| L2 | 三深度同测试 + 性能预算 + ROI 一致性 | 16-bit 结果与 8-bit 差一个量级 |
| L3 | 每包 golden 集通过率 + 失败模式文档齐全 | 只有 happy path 示例 |
| L4 | e2e 脚本（CLI/HTTP/MCP 各一条）+ 演示 200 | 演示 404、MCP 报错不可读 |
| L5 | 文档数字由脚本生成（diff 为空）+ 基准可复算 | README 数字与代码不一致 |

---

## 七、边界与合规红线

- **场景包不复制算法**：L3 只能 `import image.process`，禁止 fork 一份 resize 进 doc 包。
- **人脸只做"检测 + 脱敏"**：不做身份识别、不做属性推断（年龄/性别/种族），避免个人信息保护合规风险；接口命名用 `redact` 而不是 `recognize`。
- **医学只做"查看与测量"**：不做诊断结论、不输出"疑似病灶"这类判断，避免医疗器械监管口径。
- **印刷先做 sRGB 预检**：完整 ICC/CMYK 引擎成本高，第一版只保证"不会明显偏色"，ΔE 达标再宣称专业。
- **不追 AVIF/JXL 编码**：AV1 编码器工程量超过现有全部算法之和，保持"解码支持、编码不做"。
- **不做 GPU/H.264**：守住"纯 MoonBit、零 C 依赖、四目标同源"的立身之本。

---

## 八、如果只推进一条线

**先打通 `doc` 场景包**：发票/扫描件是需求密度最高、最能证明"库能解决实际问题"的场景，且它天然拉动 L0（大图预算）、L1（PDF/多页）、L2（去阴影/透视/版面）、L4（CLI + HTTP）四层一起往前走。做完一个包，其余包就是同一套模板复制。
