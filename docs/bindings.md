# 语言绑定（S17）

两条通道、同一份实现。绑定的职责只有「把字节搬进 MoonBit 侧」，**任何编解码、
缩放、色彩转换都不在绑定里重写**。

| 通道 | 宿主 | 载体 | 入口 | 自测 |
| --- | --- | --- | --- | --- |
| JS / Node | Node ≥18 | wasm（`--target wasm`，线性内存 + `abi_*` 导出） | `npm/index.mjs` | `node npm/test.mjs`（16 项） |
| Dart | Dart SDK ≥3.6 | `imgtool` 进程（单行 JSON 协议） | `bindings/dart/lib/image_mbt.dart` | `dart run tool/selftest.dart`（10 项） |

## 1. JS 通道（`npm/`）

包名 `@walkzzz/image-mbt`，`files` 只带 `index.mjs` / `image.wasm` / `README.md`，
`prepack` 调 `scripts/build_npm_wasm.mjs --no-test` 现场重编 wasm，保证二进制与源码同版。

```js
import { info, resize, convertMeta } from '@walkzzz/image-mbt';
const head = info(ppmBytes);                              // {format,width,height,channels:null,bytes}
const out = convertMeta(ppmBytes, { format: 'png' });     // {data,format,width,height,channels}
const small = resize(ppmBytes, { width: 64, height: 64 }); // mode 默认 cover
```

`info` 是 header-only：不整图解码，`channels` 恒为 `null`（早期版本透出 `0`，会被当成单通道灰度图）。
真实通道数只有 `convertMeta` / `resizeMeta` 给——那条路径已经解过码。

导出面：`info` / `convert` / `convertMeta` / `resize` / `resizeMeta` / `formats`。

`info` 返回 `{format,width,height,channels:null,bytes}`；`convertMeta` / `resizeMeta` 返回 `{data,format,width,height,channels}`。

**ABI 时序约束**：`abi_alloc` 分配的输入缓冲在 MoonBit 侧不留引用，`index.mjs` 的 `run()` 因此必须保持「写内存 → 立即调用 → 立即取回」的同步块；`info` / `convert` / `resize` 都是这么写的。改成异步或一次 staging 多次调用会踩 GC 复用（见 [known-gaps](known-gaps.md) GAP-51）。
wasm 用 `--target wasm`（MVP，非 wasm-gc）：线性内存可导出，`Bytes` 就是 i32 指针，
Node 侧无需 `externref` 全局；ABI 见 `wasm/abi.mbt` 文件头注释。

## 2. Dart 通道（`bindings/dart/`）

```dart
final ImageMbt img = ImageMbt();                  // IMGTOOL 环境变量 > PATH
final ImageInfo i = await img.info(bytes);        // header-only：format / width / height / bytes
final ImageMeta m = await img.resizeMeta(bytes, 320, 200, format: 'png');   // + channels
final Uint8List png = m.data;
final Uint8List webp = await img.convert(png, format: 'webp', quality: 80); // encode
```

`ImageMeta` 与 `ImageInfo` 的分工：前者是编码后的真实回执（`format` / `width` / `height` / `channels` / `bytes` + `data`），
后者是 header-only（不解码，故不带 `channels`）。`convertMeta` / `resizeMeta` 复用同一次进程的 JSON，不多起进程。

`ImageMbt` 每次调用写一个临时目录（`in.bin` + `out.<ext>`），跑一次 `imgtool`，
读回输出字节后删目录；错误沿 CLI 的 `{ok,code,message,hint}` 抛 `ImageMbtException`。
宽高非法、格式不支持在 Dart 侧就地拦，不打进程。

### 为什么 Dart 不走 wasm / FFI

| 候选 | 结论 | 依据 |
| --- | --- | --- |
| `dart:ffi` + MoonBit native 静态/动态库 | 不可行 | MoonBit 官方：native 不产出静态/动态库；探针模块只得到 `.lib` 与运行时符号，用户函数未导出 |
| Dart 内跑 wasm（`package:wasm`） | 不可行 | 该包已废弃（`0.1.0+1`），且要用 Rust + MSVC `link.exe` 现编 Wasmer |
| Dart 内跑 wasm（Dart VM 内置） | 不存在 | Dart VM 无 WebAssembly 运行时；`dart:js` 只在 Web 平台上 |
| **进程调用 `imgtool`** | **采用** | 零编解码重复、跨平台、无原生编译链依赖；CI 里只要 Dart SDK |

代价说清楚：每次调用一次进程启动（Windows 上约 10–20ms），批量场景应一次进程多图
（把多张图拼进一个临时目录，逐次调用 CLI 仍是一次一进程，属已知上限）。

## 3. 自测与门禁

```powershell
node scripts/check_dart_binding.mjs          # 构建 release imgtool + 跑 Dart 自测
node npm/test.mjs                            # JS 通道 16 项
```

`check_dart_binding.mjs` 支持 `--no-build`（复用已构建的 imgtool），`IMGTOOL` 可覆盖路径；
`dart` 不在 PATH 时以退出码 2 跳过，不误报失败。

Dart 自测 10 项：PPM 4×3 识别、`decode → resize → encode`（PPM → PNG 2×2）、
PNG → WebP（RIFF/WEBP 魔数 + 尺寸）、PNG → JPEG（`quality=80`，SOI）、
空输入抛带 `code` 的异常、非法宽高本地拒绝、只读格式（tiff/hdr/avif…）本地拒绝（与 CLI `is_writable` 的 8 个一致，不 spawn 进程）、`imgtool` 缺失抛 `process/spawn_failed`（stderr 为空时不再被 `StateError` 掩盖）、
`convertMeta` 回执的格式/宽高/通道/体积与输出字节自洽、`resizeMeta` 回执的实际宽高可被再读回。

## 4. 与发布的关系

`npm` 版本随库版本走（当前 `0.1.24`，`bindings/dart/pubspec.yaml` 同号；两者均由 `check_version.mjs` 第 20、21 项守门），但**尚未发布到 npm**：绑定跟库一起在 S21 收口时发。
Dart 包 `publish_to: none`，只作为仓内绑定示例与自测载体，不发 pub.dev。
