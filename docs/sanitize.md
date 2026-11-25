# 脱敏：`imgtool sanitize`

发图之前先把"不该带走的东西"剥干净：EXIF（含 GPS）、XMP、ICC、Photoshop 资源块、内嵌缩略图；已知人脸/证件区域做块均值打码；需要更强时整图模糊。CLI / MCP / MoonBit 库三层同一份实现（`imgcli/recipe.mbt`）。

## 三档 policy

| policy | 做什么 | 输出格式 | 像素 |
| --- | --- | --- | --- |
| `metadata`（默认） | 读入 → 全量重编码，只保留像素 | 沿用输入（jpeg/webp/png），未知格式落 png | 逐像素不变（有损格式按 quality 变） |
| `standard` | 元数据 + 对 `--regions` 列出的区域做块均值打码 | 同上 | 区域被压平成块均值 |
| `strict` | 元数据 + 打码 + 整图 box blur | 强制 png（无损，便于复核） | 全图不可逆降质 |

`metadata` 是"只剥壳"的安全档：图片外观不变，适合"只是不想泄露拍摄地点"的场合。`standard` 才是拦脸：你告诉它哪里是敏感区。`strict` 兜底——不知道敏感区在哪时整图废掉细节。

> 不承诺自动检测到所有人脸。库没有检测模型，`regions` 由调用方给出（来自你的人工标注、别的检测器、或产品里的框选）。这条是设计边界，不是待办。

## 区域语法

```
--regions "40,40,200,120"                 # 单块：x,y,w,h（像素）
--regions "40,40,200,120;300,200,80,80"   # 多块，分号分隔
```

- 越界自动裁剪到图内；**完全在图外**直接报错（`process/invalid_argument`），不静默吞掉。
- 打码方式：把区域切成 `--block`（默认 12）边长的方块，每块填该块的 RGB 均值。比纯色覆盖更好——保留明暗结构，看图不会误以为图坏了，但细节不可恢复。

## 用法

```bash
# 只剥元数据
imgtool sanitize in.jpg out.jpg

# 打掉一块证件/人脸区
imgtool sanitize in.jpg out.jpg --policy standard --regions "120,80,220,260" --block 10

# 不知道敏感区在哪，整图毁细节（输出 png）
imgtool sanitize in.jpg out.png --policy strict --blur 10
```

输出恒为单行 JSON：

```json
{"src":"in.jpg","dst":"out.jpg","policy":"standard","format":"jpeg","width":1280,"height":720,
 "regions_redacted":1,"blurred":false,"metadata_free":true,"metadata_hits":[],"bytes":51234,"ok":true}
```

- `metadata_free`：对输出字节做签名扫描（`Exif` / `GPS` / `XMP` / `ICC_PROFILE` / `Photoshop 3.0` / `<x:xmpmeta` / `Thumbnail`），`false` 时 `metadata_hits` 给出命中的签名。
- `regions_redacted`：实际打码块数（strict 无 regions 时等于整图打码次数 1）。
- 失败走统一错误契约：`{"ok":false,"code":...,"message":...,"hint":...}` + 退出码 1。

MCP 侧同名工具 `sanitize`，参数 `policy` / `regions` / `block` / `blur`；省略 `output` 时内联返回 base64 图（见 `docs/mcp.md`）。

## 在自己代码里调用

CLI 和 MCP 都是薄壳，库内直接写：

```moonbit
import "walkzzz/image.codec/lib"
import "walkzzz/image.core/types"
import "walkzzz/image.mbt/imgcli"

// 最小：只剥元数据，输出沿用输入格式
let img = @lib.load_from_bytes_auto(bytes)!
let r = @imgcli.sanitize_image(img, "metadata", [], 12, 8, @types.ImageFormat::Jpeg, 90)
// r.bytes 已是编码后的干净字节，直接落盘/上传，不必再编码一次
```

`SanitizeResult` 带 `image / bytes / format / redacted / blurred / quality`。想自己组合更强打码时，单独用 `redact_region(img, region, block)` 或 `@filter.gaussian_blur(img, radius, sigma)`；文件读写走 `@fs`（native）或由调用方负责，库本身不碰 IO。

## 验收（0.1.6）

`node scripts/mcp/sanitize_batch.mjs`：造 200 张带 EXIF+GPS+XMP+ICC+缩略图签名的 JPEG，三档 policy 轮流跑满 200 次。

```
samples 200 / runs 200 / dirtyInputs 200 / residue 0 / failed 0
```

每张都复核了两件事：输出字节里 7 个元数据签名命中数为 0；输出仍可解码且宽高与输入一致（strict 为 png）。脚本失败即退出码 1，可直接挂 CI。

MCP 冒烟（`node scripts/mcp/smoke.mjs`）另有 6 条脱敏相关用例：standard 打 1 块、strict 强制 png + 全图模糊、默认不动像素、PNG 真压缩、非法 region 被拒、非法 policy 被拒。33/33 通过。

## 失败模式

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `metadata_free:false` + hits 非空 | 输入格式本身带不可剥离的私有块，或输出容器选了不支持无损剥离的路径 | 换 `--format png` 再脱一次 |
| `process/invalid_argument` 区域报错 | region 完全在图外 / 语法不是 `x,y,w,h` | 核对坐标与图尺寸 |
| standard 档图看着"糊了但没糊透" | `--block` 偏小（默认 12） | 调大 `--block`（20~40 适合人脸） |
| strict 输出很大 | png 无损 | 需要小体积就 standard + 明确 regions |

## 已知限制

- 只处理本库支持容器内的元数据块：JPEG APPn、PNG 文本/时间块、WebP 附属块。外部工具塞的非标准私有块可能扫描不到——`metadata_free:false` 会如实报出来，不假装干净。
- 不做人脸检测、不做 OCR 文字打码。
- `strict` 的模糊是 box blur，不是高斯；要更好看的外观用库 API `@filter.gaussian_blur` 自行组合。
