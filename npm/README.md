# @walkzzz/image-mbt

MoonBit 纯图像库的 Node 绑定，单文件 WebAssembly，零原生依赖、零 install 脚本。

支持解码 PNG / JPEG / WebP(VP8L) / GIF / BMP / QOI / PNM / TGA，编码 PNG / JPEG / WebP(VP8L) / GIF / BMP / QOI / PNM / TGA，另有 cover / contain 缩放。

## 安装

```bash
npm add @walkzzz/image-mbt
```

要求 Node >= 18（ESM）。包内自带 `image.wasm`，不需要 Rust/C++ 工具链。

## 三行调用

```js
import { readFileSync, writeFileSync } from 'node:fs';
import { convert } from '@walkzzz/image-mbt';

writeFileSync('out.jpg', convert(readFileSync('in.png'), { format: 'jpeg', quality: 85 }));
```

## API

| 方法 | 说明 | 返回 |
| --- | --- | --- |
| `info(input)` | 只读头部：格式 / 宽高 / 字节数，不解完整像素 | `{format, width, height, channels, bytes}` |
| `convert(input, {format, quality})` | 解码后重新编码，`format='best'` 逐候选实编取最小 | `Buffer` |
| `convertMeta(input, opts)` | 同 convert，另带输出元信息 | `{data, format, width, height, channels}` |
| `resize(input, {width, height, mode, format, quality})` | 缩放后编码，`mode` 为 `cover`（默认）或 `contain`（白底留边） | `Buffer` |
| `resizeMeta(input, opts)` | 同 resize，另带输出元信息 | 同上 |
| `formats` | 可用格式名列表 | `string[]` |

`input` 接受 `Buffer` / `Uint8Array` / `ArrayBuffer`。

输出格式名：`png` `jpeg`（别名 `jpg`）`webp` `gif` `bmp` `qoi` `pnm`（别名 `ppm`）`tga` `best`。

`quality` 默认 90，只在 JPEG / WebP 等有损编码里生效；PNG/QOI/BMP 等无损格式会忽略。

## 示例

```js
import { readFileSync } from 'node:fs';
import { info, resize } from '@walkzzz/image-mbt';

const png = readFileSync('photo.png');
console.log(info(png)); // { format:'png', width: 1920, height: 1080, ... }

const thumb = resize(png, { width: 640, height: 640, mode: 'cover', format: 'webp', quality: 80 });
```

`contain` 会在两侧用白色填充，适合生成固定尺寸的头像/封面；`cover` 先等比放大再居中裁切。

## 错误处理

失败时抛 `Error`，并带两个附加字段：

```js
try {
  info(Buffer.from('not an image'));
} catch (err) {
  err.code; // 'decode/unsupported_format'
  err.hint; // 中文修复建议
}
```

`code` 取值与 MoonBit 库一致：`decode/*`（输入/格式）、`encode/*`（输出）、`process/*`（参数/尺寸）、`budget/*`（体积/像素限制）。

## 体积与性能

- `image.wasm`：248 KiB raw / 111 KiB gzip（S12 实测，Node 22）
- 无 import，`new WebAssembly.Instance(module, {})` 直接实例化
- 单次调用同步执行；大图解码会按需增长线性内存，封装层每次调用后重新取 `memory.buffer` 视图

## 从源码构建

```bash
node scripts/build_npm_wasm.mjs          # 构建 + 拷贝 + 体积校验 + 跑自测
node scripts/build_npm_wasm.mjs --no-test
```

需要 MoonBit 工具链（`moon`）。构建产物在 `npm/image.wasm`，`npm publish` 时由 `prepack` 自动生成。

## 限制

- WebP 只支持 lossless（VP8L），不支持 VP8 lossy；
- 不做 EXIF 旋转、ICC 色彩管理、动画合成（GIF/APNG 只取首帧）；
- 解码有默认像素与体积上限，超限抛 `budget/*`。

完整能力与 CLI 见主仓库 <https://github.com/walkzzz/image.mbt>。
