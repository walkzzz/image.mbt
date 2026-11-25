# MCP 出口：`imgtool`

把库变成一个**agent 可直接调用**的图像服务。两层结构：

```
agent / MCP host
      │  stdio JSON-RPC
      ▼
mcp/server.mjs        协议 + 参数校验 + 内联 base64 桥接（无第三方依赖）
      │  argv / 单行 JSON
      ▼
imgtool（MoonBit）     imgtool 库包（imgcli）+ cmd/imgtool 入口，与 moon test 同一份实现
```

## 一条命令启动

```bash
# 1) 构建（native）
moon build --release cmd/imgtool

# 2) 检查二进制
./_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe info sample.png
# {"path":"sample.png","format":"png","width":640,"height":360,"bytes":26482,"ok":true}

# 3) 起 MCP server（stdio，自身不打印额外日志）
node mcp/server.mjs
```

冷启动实测 **73 ms**（`node scripts/mcp/smoke.mjs` 里断言 ≤1 s）。

Host 配置（Claude Code / Cursor / 任意 MCP stdio host）：

```json
{
  "mcpServers": {
    "imgtool": {
      "command": "node",
      "args": ["E:/AA_WP/forMoonHankson/image.mbt/mcp/server.mjs"],
      "env": { "IMGTOOL_BIN": "E:/AA_WP/forMoonHankson/image.mbt/_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe" }
    }
  }
}
```

`IMGTOOL_BIN` 可省略：server 会去 `_build/native/release/.../imgtool.exe` 找；找不到才报错。

## 6 个工具

| 工具 | 必填参数 | 可选 | 作用 |
|---|---|---|---|
| `analyze` | `input` | — | 头信息 + 像素统计（宽高、通道、逐通道 mean/std/min/max），不写文件 |
| `decode` | `input` | `format`(默认 png)、`quality`、`output` | 解码任意格式并归一化重写 |
| `encode` | `input`、`format` | `quality`、`output` | 显式指定输出格式 |
| `resize` | `input`、`width`、`height` | `mode`(cover/contain)、`format`、`quality`、`output` | 缩放；cover 铺满后居中裁切，contain 等比装入留白 |
| `crop` | `input`、`x`、`y`、`width`、`height` | `output` | 矩形裁剪，越界**直接报错** |
| `sanitize` | `input` | `policy`(metadata/standard/strict)、`regions`、`block`、`blur`、`format`、`quality`、`output` | 剥 EXIF/GPS/XMP/ICC/缩略图；standard 按 regions 打码；strict 整图模糊并强制 png。细则见 [sanitize.md](sanitize.md) |

省略 `output` 时，结果以 MCP image content 直接返回（base64 + mimeType），一次调用即可看到图；给了 `output` 则落盘并只回 JSON。

## 错误契约

任何失败都是同一个形状，不再有"空字符串/异常/退出码"三种语义混淆：

```json
{"ok":false,"code":"budget/limit_bytes","message":"图像字节数 26482 超过上限 1024","hint":"提高 max_bytes 或放宽 --mem-budget"}
```

- `code` 与 `docs/error-model.md` 的 12 个码一一对应（`decode/truncated`、`budget/limit_pixels`、`process/invalid_argument` …）；
- MCP 侧把这些字段放进 `content[0].text` 并置 `isError:true`，同时**保留原始 JSON**，agent 可直接按 `code` 分支处理；
- 缺参数由 MCP 层先拦（`process/invalid_argument` + 中文 message），不必等二进制启动。

## 资源限额

三条入口等价：

| 入口 | 写法 |
|---|---|
| MCP 调用参数 | `{"input":"a.png","mem_budget":1048576}` |
| 进程环境 | `IMGTOOL_MEM_BUDGET=1048576 node mcp/server.mjs` |
| 直接跑 CLI | `imgtool analyze a.png --mem-budget 1048576` |

语义：`max_bytes = mem_budget`，`max_pixels = mem_budget / 8`（按 4 通道 8 bit 的保守估算）。检查发生在**解码器分配内存之前**——声明 100000×100000 的 QOI 头会在读像素前被拒。

## CLI 直接用法（不经过 MCP）

```bash
imgtool info      in.png
imgtool analyze   in.png
imgtool decode    in.png out.jpg --format jpeg --quality 88
imgtool resize    in.png small.png --width 128 --height 72 --mode cover
imgtool crop      in.png cut.png --x 10 --y 10 --width 100 --height 60
imgtool sanitize  photo.jpg clean.jpg                          # 只剥元数据
imgtool sanitize  photo.jpg clean.jpg --policy standard --regions "120,80,220,260"
imgtool sanitize  photo.jpg clean.png --policy strict --blur 10
```

约定：结果恒为 **stdout 单行 JSON**；失败退出码 1。可用 `jq`、PowerShell `ConvertFrom-Json` 直接消费。

## 验证

```bash
node scripts/mcp/smoke.mjs
# Total: 33, passed: 33, failed: 0
```

33 条用例覆盖：initialize/capabilities、tools/list 结构与数量、7 个工具的正常路径（含内联图片与 mime）、越界裁剪、缺参、非法格式、非图像文件、截断 PNG、未知工具、`--mem-budget` 拒绝、qoi 回读、ping、脱敏三档（standard 打码块数 / strict 整图模糊 / 默认不动像素）、PNG 真压缩、非法 region 与非法 policy 被拒。

批量脱敏验收（200 张带 EXIF/GPS/XMP/ICC/缩略图的样本，三档 policy 全跑）：

```bash
node scripts/mcp/sanitize_batch.mjs
# {"ok":true,"samples":200,"runs":200,"dirtyInputs":200,"residue":0,"failed":0}
```

## 已知限制

- `imgtool` 依赖 native 文件系统：库包在 wasm/js 下编译通过但运行即返回 `decode/unsupported_format`（`imgcli/io.mbt` 的 `#cfg` 分叉）。浏览器侧出口是 S12 的事。
- MCP 层不做路径沙箱：能读到什么由启动进程的用户权限决定。要接不可信输入时，请用容器/受限账号运行，并同时给 `mem_budget`。
- 工具数刻意停在 6 个。schema 稳定后（S06 Recipe 落地再回头看）才扩容。
