# 安全策略（SECURITY）

## 支持版本

| 版本 | 支持 |
|------|------|
| 0.1.x | 是 |

## 报告漏洞

请**不要**通过公开 Issue 报告安全漏洞。使用 GitHub Security Advisory（仓库 Security 页 → Report a vulnerability）或私下联系维护者 walkzzz。请在报告中包含：受影响版本、最小复现输入（图片字节）、期望/实际行为、影响评估。我们会在 7 天内确认，并在修复发布后致谢（如你同意）。

## 安全边界与已知加固

- 所有解码器入口调用 `check_dims` 校验宽高与通道数；非法维度返回 `LoadError`。
- 乘法路径使用 `safe_mul` / `safe_mul3` 防整数溢出；像素运算使用 `clamp` 钳制。
- `MAX_IMAGE_DIMENSION = 65535`、`MAX_TOTAL_PIXELS = 5e8` 双重守卫。
- `image.core/safe_math` 附 SMT 可机检证明（8 goals：溢出安全 / 钳制 / 索引 / 旋转恒等）。
- 库不进行任何网络 IO、不执行外部代码、不写文件；文件读写由调用方负责。

## 不在范围内

- 恶意构造的图片导致的资源耗尽（超大但合法的图片）——请调用方先做尺寸/字节数限制。
- 下游用法错误（未调用 `check_dims` 的自定义解码循环）。
- GPU / 硬件相关路径（本项目不提供）。