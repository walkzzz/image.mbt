# 基准样本版权自查清单

> 适用目录：`benchmarks/golden/`（24 张 golden）与 `benchmarks/malformed/`（8 个畸形样本）。
> 结论：**全部样本由本仓自有代码在运行时合成，不含任何第三方素材，可随 MIT 许可自由分发。**

## 一、来源声明

| 项目 | 事实 |
|---|---|
| 生成器 | `benchmarks/gen/`（MoonBit 包 `walkzzz/image.mbt/benchmarks/gen`），重生成命令 `moon run benchmarks/gen` |
| 像素来源 | 代码内的解析式（渐变 / 色条 / 确定性伪噪声 / 径向亮场 / 圆形 alpha 切边 / 浮点高光斑），无外部图片输入 |
| 编码来源 | 本仓 `walkzzz/image.codec`（PNG / JPEG / BMP / TGA / GIF / APNG / WebP / TIFF / ICO / ICNS / HDR / QOI / PNM 编码器） |
| 确定性 | 无随机源、无时钟、无环境依赖；同版本重生成字节一致（`manifest.json` 的 sha256 即证据） |
| 许可证 | 与仓库一致：[MIT](../LICENSE) |

## 二、逐项排除（自查表）

| 检查项 | 结果 | 依据 |
|---|---|---|
| 使用真实照片 | 否 | `photo_rgb` 为解析式合成（径向亮场 + 区块纹理），非采样自任何影像 |
| 使用字体 / 字形轮廓 | 否 | 未生成任何文字渲染样本；无 TTF/OTF 数据进入仓库 |
| 使用图标库 / 商标 / Logo | 否 | `logo_rgba` 为纯几何（圆 + 冷暖渐变），不含任何品牌图形 |
| 使用二维码 / 条码真实内容 | 否 | 样本集不含条码类生成物 |
| 携带 EXIF / GPS / 相机信息 | 否 | JPEG 为本仓编码器输出，不写 APP1；PNG 无 `tEXt`/`iTXt`；核对方式见下 |
| 携带个人信息 / 文件名泄露 | 否 | 文件名只含 `gNN`/`mN` + 内容标签 + 尺寸；生成器不读环境变量写元数据 |
| 第三方数据集片段 | 否 | 仓库内不存在 `.git-lfs` 指针、外部下载脚本或数据集引用 |
| 畸形样本含真实漏洞利用 | 否 | 全是「结构性无效」字节（截断 / 越界长度 / 超大声明尺寸 / 帧数声明 / 非法枚举 / 元数据段截断），不含 shellcode、RCE 载荷或真实 CVE PoC |

核对命令（应无 `Exif` / `tEXt` / `iTXt` / `zTXt` 命中）：

```powershell
Select-String -Path benchmarks\golden\*.jpg,benchmarks\golden\*.png -Pattern 'Exif|tEXt|iTXt|zTXt' -Encoding Byte -SimpleMatch
```

（二进制匹配不到即为通过；`--update` 生成的 `manifest.json` 记录了每张样本的 sha256，可用于跨机器比对。）

## 三、新增样本的四条准入规则

1. **自有代码合成**：只能由 `benchmarks/gen/` 生成，不得引入外部图片、字体、图标或数据集；
2. **确定性**：不得引入随机数、当前时间、本机路径等信息，重生成必须字节一致；
3. **体积受控**：单文件 ≤ 400 KiB、总体积 ≤ 1600 KiB（`scripts/check_benchmarks.mjs` 内 `LIMITS` 强制）；
4. **命名即契约**：golden 用 `gNN_<内容>_<W>x<H>.<ext>`，malformed 用 `mN_<类别>.<ext>`；新增后必须 `--update` 重新封签 manifest。

## 四、畸形样本的用途边界

`benchmarks/malformed/` 只用于验证「解码器对结构性无效输入必须返回 JSON 错误、不得 panic、不得超时」。
它们**不是**漏洞利用样本，不携带可执行内容，也不指向任何真实产品缺陷编号；对第三方工具的复现责任由使用者自担。
