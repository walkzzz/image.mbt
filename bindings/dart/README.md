# image_mbt —— Dart 绑定（S17）

`walkzzz/image.mbt` 的 Dart 侧入口。**不实现任何编解码**，只把字节搬进本仓的
`imgtool` 进程，实现仍是同一份 MoonBit 代码。

```dart
import 'package:image_mbt/image_mbt.dart';

final ImageMbt img = ImageMbt(); // IMGTOOL 环境变量 > PATH 里的 imgtool

final ImageInfo info = await img.info(pngBytes);              // decode
final Uint8List out = await img.resize(pngBytes, 320, 200,    // resize
    mode: 'cover', format: 'png');
final Uint8List webp = await img.convert(out, format: 'webp', quality: 80); // encode
```

## 通道选型（为什么不是 wasm / FFI）

| 候选 | 结论 | 依据 |
| --- | --- | --- |
| `dart:ffi` + MoonBit native 库 | 不可行 | MoonBit 官方：native 不产出静态/动态库；探针只拿到 `x.lib` 与运行时符号，用户函数未导出 |
| Dart 内跑 wasm（`package:wasm`） | 不可行 | 该包已废弃（`0.1.0+1`），且要靠 Rust + MSVC `link.exe` 现编 Wasmer |
| Dart 内跑 wasm（Dart VM 内置） | 不存在 | Dart VM 无 WebAssembly 运行时；`dart:js` 仅 Web 平台 |
| **进程调用 `imgtool`** | **采用** | 零编解码重复实现、跨平台、无原生编译依赖 |

JS 侧继续走 wasm：`npm/` 包用 `--target wasm`（线性内存 + `abi_*` 导出），
Node 里直接 `node npm/test.mjs`。两条通道共用同一份 MoonBit 实现，区别只在宿主。

## 自测

```powershell
moon build --release cmd/imgtool
$env:IMGTOOL = "$PWD\_build\native\release\build\walkzzz\image.mbt\cmd\imgtool\imgtool.exe"
cd bindings\dart
dart run tool/selftest.dart
```

或一步到位：`node scripts/check_dart_binding.mjs`（自动构建 + 注入 `IMGTOOL` + 跑自测）。

自测覆盖（6 项）：decode 尺寸/格式、decode→resize→encode（PPM 4×3 → PNG 2×2）、
PNG→WebP 魔数与尺寸、PNG→JPEG（`quality=80`）SOI、空输入抛带 `code` 的异常、
非法宽高在 Dart 侧即被拒绝（不打到进程）。
