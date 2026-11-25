# Dogfood 记录（S07，2026-11-25）

> 目的：不用"demo 能跑"，而用**我自己每天要做的事**去压这个库——批量转码、缩略图、脱敏、体积调查。
> 脚本 `scripts/dogfood.mjs`（只读输入，只写 `_build/proto/dogfood/`），跑法：
>
> ```bash
> node scripts/dogfood.mjs            # 打印 dogfood@1 JSON 报告
> node scripts/dogfood.mjs > _build/proto/dogfood_report.json
> ```

## 1. 流水线：8 个真实输入 × 6 步

| 输入 | 来源 | 说明 |
|---|---|---|
| `shot_640.png` | ffmpeg `testsrc2` | 典型截图尺寸，压缩友好 |
| `photo_1920.jpg` | ffmpeg `testsrc2` + `-q:v 3` | 有损照片，含 EXIF 需剥 |
| `photo_1920.webp` | ffmpeg `-c:v libwebp -lossless 1` | **VP8L 无损**，本轮 bug 触发样本 |
| `flat_1080.bmp` | ffmpeg | 未压缩容器，读入路径最长 |
| `gray_800.png` | ffmpeg `format=gray` | 单通道 |
| `alpha_800.png` | ffmpeg `format=rgba` | 带 alpha |
| `big_4096.png` | ffmpeg `4096x4096` | 16 MP，测内存与耗时 |
| `band_1080.png` | ffmpeg `gradients` | 渐变，考 predictor |

每张输入依次跑 `info → decode→jpeg q85 → resize cover 320x180 → sanitize standard → analyze → info`，共 **48 个操作**。

**结果（2026-11-25 终态）**：`ops 48 / failed 0 / totalMs ≈ 16–20 s`（含每步进程启动）。

> 首轮跑的时候 `photo_1920.webp` 的 4 个下游操作**全失败**——那就是本轮 VP8L bug 的最初来源，详见 `docs/known-gaps.md` GAP-28。

## 2. 摩擦探针（8 条，全部 ok）

| # | 探针 | 修前 | 修后 |
|---|---|---|---|
| P1 | `-h` / `help` / `version` | 只回一句 JSON「未知子命令」 | `help`/`-h`/`--help` 打印人类可读用法（退出码 0），`version`/`-v`/`--version` 打印 `imgtool 0.1.7`；空参数仍回 JSON 错误供 agent 判定 |
| P2 | `decode in.png out.jpg`（不给 `--format`） | 写 PNG 字节到 `.jpg`（扩展名骗人） | 按**输出扩展名**推断格式 |
| P3 | `crop ... out.jpg` | 恒写 PNG，下游要 JPEG 得再跑一次 `decode` | `crop` 支持 `--format`，并同样按扩展名推断 |
| P4 | `sanitize in.jpg out.png` | 写出 JPEG 字节到 `.png` | 扩展名优先，`out.png` 真是 PNG |
| P5 | 输入不存在 / 输出目录不存在 | 已可执行 | 保持不变（`decode/invalid_argument` + 明确 message） |
| P6 | 4096²(16 MP) → 320×180 | ≈ 0.6–0.8 s（含进程启动） | 不变 |
| P7 | WebP 无损编码体积 | 20,144 B / 640×360 / ≈ 80 ms | 不变 |
| P8 | MCP 出口跑同一条 sanitize | 一致 | 一致（`IMGTOOL_BIN` 指向同一二进制） |

**格式决策规则（修后统一）**：`--format` 显式给出 → 用它（`auto` 视为未给）；否则看**输出扩展名**；再否则按子命令默认（`decode/encode` → PNG，`resize/crop` → 沿用源格式，`sanitize` → `strict` 强制 PNG、其余沿用 JPEG/WebP 源）。这条规则写进了 `imgtool help` 与 `docs/mcp.md`。

## 3. 这轮改到的代码

- `imgcli/imgtool.mbt`：`format_from_ext` / `out_format` / `src_out_format` / `help_text` / `version_text`，并把 `decode`、`encode`、`resize`、`crop`、`sanitize` 全部改走 `out_format`。
- `mcp/server.mjs`：`crop` 工具补 `format`+`quality` 参数，各工具 `format` 描述改为"省略时按输出扩展名推断"。
- `scripts/dogfood.mjs`：P1 探针改成校验 help/version 的真实输出；P2–P4 由"检测摩擦"升级为"守门"（一旦扩展名再被忽略就会翻红）。

## 4. 仍未解决（写在这里，不藏）

1. **VP8 有损 WebP 仍不支持**：`photo_1920.webp` 是 libwebp 的无损产物，已能解；但手机/相机导出的有损 WebP（VP8）仍会报 `decode/unsupported_format`。这是 S08+ 的独立议题，不在"好用版"范围。
2. **`max_ms` 没有强制中断**（GAP-31）：解码是纯同步循环，给一个超时也只是事后判定。
3. **发布链未执行**：`moon publish` 是不可逆外部动作，等用户授权；`docs/roadmap.md` S07 卡里写了分步顺序。
