# imgtool 命令行（S11）

`imgtool` 是 `image.mbt` 的官方 CLI：native 二进制，参数走 argv，结果走**单行 JSON**。
它把库里的解码/缩放/裁剪/滤波/脱敏/选格式串成可被 shell、MCP、agent 直接调用的工具。

## 构建

```bash
moon build --release cmd/imgtool
# 产物：_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe
```

## 8 个子命令

| 子命令 | 作用 | 关键参数 |
|---|---|---|
| `info` | 读头部（不整图解码） | `<in>` |
| `convert` | 任意可写格式互转（`decode`/`encode` 为别名） | `--format` `--quality` `--best` `--max-bytes` |
| `resize` | 等比覆盖 / 包含缩放 | `--width` `--height` `--mode cover\|contain` |
| `crop` | 裁剪，越界直接拒绝 | `--x` `--y` `--width` `--height` |
| `filter` | 六种滤波/锐化/去噪 | `--op` `--radius` `--sigma` `--amount` `--ksize` `--sigma-color` `--patch` `--search` `--h` |
| `analyze` | 尺寸/通道/均值/极值/标准差 | `<in>` |
| `sanitize` | 三档脱敏（剥元数据/区域打码/整图模糊） | `--policy` `--regions` `--block` `--blur` |
| `bench` | decode / encode / resize 的每轮均值（微秒） | `--iters` `--formats` `--width` `--height` |

通用：`--format`（省略时按输出扩展名推断，再无则 PNG）、`--quality 1-100`、`--mem-budget`、`--max-pixels`。

## 输出约定

- 成功：`{"ok":true, ...}`；失败：`{"ok":false,"code":"...","message":"...","hint":"..."}`，退出码 1。
- 写盘类子命令统一带 `"dry_run"` / `"wrote"` / `"to_stdout"` 三个字段，脚本不必猜。
- `help` / `version` 走人类可读文本（不走 JSON）。

## 管道（`-`）

路径写 `-` 即 stdin / stdout，与 ImageMagick / ffmpeg 同约定：

```bash
imgtool convert - - --format png < in.png > out.png          # JSON 走 stderr
imgtool resize - out.webp --width 320 --height 180 < in.jpg
imgtool info - < in.png
```

- 二进制写 stdout 时，JSON 结果自动改走 stderr，管道里不会混入 JSON。
- 读取 stdin 是一次性全量进内存；超大流式输入不在 S11 范围。
- 该能力依赖 native（`imgcli/stdio_stub.c` + `imgcli/pipe.mbt`）；wasm/js 返回 `decode/unsupported_format`。

## `--dry-run`

`convert / resize / crop / filter / sanitize` 都支持：完整解码、处理、编码，**但不落盘**。
返回真实体积与格式，适合先算预算再决定要不要写：

```bash
imgtool convert photo.jpg out.webp --best --dry-run
# {...,"format":"webp","bytes":404,"dry_run":true,"wrote":false,"ok":true}
```

## `convert --best`

`--best` 调 S10 的 `encode_best`：对 PNG/JPEG/WebP/QOI 逐候选**实际编码**，取体积最小者。
`--max-bytes N` 接 `encode_best_limited`，最小仍超限时返回 `budget/limit_bytes`。

- `--best` 与显式 `--format` **互斥**（避免"声称 PNG 又偷偷换格式"）。
- `--max-bytes` 只能配 `--best`，否则报 `process/invalid_argument`。

实测（320×240 三色块 PNG，2,386 B）：`--best` 得 WebP **404 B**。

## `filter` 参数

| `--op` | 调用的算子 | 生效参数 |
|---|---|---|
| `box` / `blur` | `box_blur` | `--radius`（默认 3） |
| `gaussian` / `gauss` | `gaussian_blur` | `--radius`、`--sigma`（≤0 时取 radius/2） |
| `sharpen` / `sharp` | `sharpen` | `--amount`（默认 1.0） |
| `median` | `median_blur` | `--ksize`（默认 3，必须 ≥3 且为奇数） |
| `bilateral` | `bilateral_filter` | `--radius`、`--sigma`、`--sigma-color`（默认 30） |
| `nlm` / `denoise` | `nlm_denoise` | `--patch`（3）、`--search`（7）、`--h`（10） |

## `bench`

```json
{"path":"photo.png","format":"png","width":320,"height":240,"channels":3,"iters":5,
 "decode_us":2304.0,
 "encode":{"png":{"us":8579.1,"bytes":2386},"jpeg":{"us":7369.1,"bytes":7739},
           "webp":{"us":17908.3,"bytes":404},"qoi":{"us":233.4,"bytes":1888}},
 "resize":{"width":160,"height":120,"us":375.8},"ok":true}
```

- 单位微秒；每轮先热身一次再计时。
- `--iters` 限 1-1000；`--formats` 逗号列表，未知格式记 `{"error":...}`。
- 这是**同机耗时参考**，不是跨机基准；发布基准集在 S20。

## 验收（0.1.13）

- 四目标 `moon test --target all`：**6726/6726 通过**（wasm / wasm-gc / js / native）。
- `moon check --deny-warn --target all`：零警告。
- 实测：`--best` 404 B（PNG 2,386 B）；`-` 管道回读 320×240 RGB 一致；`--dry-run` 目标文件未创建。
