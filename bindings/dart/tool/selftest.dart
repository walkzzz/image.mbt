// tool/selftest.dart —— Dart 绑定自测（无第三方依赖，退出码即结论）
//
// 验收口径（S17）：Dart 侧跑通 decode → resize → encode。
//
//   dart run tool/selftest.dart
//   IMGTOOL=E:\...\imgtool.exe dart run tool/selftest.dart
//
// 依赖一个已构建的 `imgtool`（`moon build --release cmd/imgtool`）；
// 脚本 `scripts/check_dart_binding.mjs` 会自动构建并注入 IMGTOOL。

import 'dart:io';
import 'dart:typed_data';

import 'package:image_mbt/image_mbt.dart';

int passed = 0;
int failed = 0;

void check(String name, void Function() body) {
  try {
    body();
    passed += 1;
    stdout.writeln('  ok  $name');
  } catch (e) {
    failed += 1;
    stdout.writeln('  FAIL $name: $e');
  }
}

Future<void> checkAsync(String name, Future<void> Function() body) async {
  try {
    await body();
    passed += 1;
    stdout.writeln('  ok  $name');
  } catch (e) {
    failed += 1;
    stdout.writeln('  FAIL $name: $e');
  }
}

/// P6 PPM：纯 Dart 生成，不依赖任何样本文件。
Uint8List ppm(int w, int h) {
  final Uint8List px = Uint8List(w * h * 3);
  for (int i = 0; i < px.length; i++) {
    px[i] = (i * 7 + 3) % 256;
  }
  final List<int> head = 'P6\n$w $h\n255\n'.codeUnits;
  return Uint8List.fromList(<int>[...head, ...px]);
}

List<int> head(Uint8List b, int n) => b.sublist(0, n);

bool assertEq(Object? a, Object? b, String what) {
  if (a != b) {
    throw StateError('$what: 期望 $b，实际 $a');
  }
  return true;
}

Future<void> main() async {
  final ImageMbt img = ImageMbt();
  stdout.writeln('imgtool: ${Platform.environment['IMGTOOL'] ?? '(PATH)'}');

  final Uint8List src = ppm(4, 3);

  // 1) decode：PPM 4x3
  await checkAsync('decode: PPM 4x3 识别为 pnm', () async {
    final ImageInfo info = await img.info(src);
    assertEq(info.format, 'pnm', 'format');
    assertEq(info.width, 4, 'width');
    assertEq(info.height, 3, 'height');
    assertEq(info.bytes, src.length, 'bytes');
  });

  // 2) decode → resize → encode：PPM 4x3 → PNG 2x2
  Uint8List resizedPng = Uint8List(0);
  await checkAsync('decode → resize → encode: PPM 4x3 → PNG 2x2', () async {
    resizedPng = await img.roundtrip(src, width: 2, height: 2, format: 'png');
    assertEq(head(resizedPng, 4).join(','), '137,80,78,71', 'PNG 魔数');
    final ImageInfo info = await img.info(resizedPng);
    assertEq(info.format, 'png', 'format');
    assertEq(info.width, 2, 'width');
    assertEq(info.height, 2, 'height');
  });

  // 3) 二次 encode：PNG 2x2 → WebP（lossless）
  await checkAsync('encode: PNG → WebP', () async {
    final Uint8List webp = await img.convert(resizedPng, format: 'webp');
    assertEq(head(webp, 4).join(','), '82,73,70,70', 'RIFF');
    assertEq(head(webp.sublist(8), 4).join(','), '87,69,66,80', 'WEBP');
    final ImageInfo info = await img.info(webp);
    assertEq(info.width, 2, 'width');
  });

  // 4) 带质量参数的 JPEG 通道
  await checkAsync('encode: PNG → JPEG quality=80', () async {
    final Uint8List jpg =
        await img.convert(resizedPng, format: 'jpeg', quality: 80);
    assertEq(head(jpg, 2).join(','), '255,216', 'JPEG SOI');
  });

  // 5) 错误通道：空字节必须抛带 code 的异常
  await checkAsync('错误输入抛带 code 的异常', () async {
    try {
      await img.info(Uint8List(0));
      throw StateError('空输入本应失败');
    } on ImageMbtException catch (e) {
      if (e.code.isEmpty) {
        throw StateError('异常缺 code');
      }
    }
  });

  // 6) 非法宽高在 Dart 侧就拦住，不打到进程
  await checkAsync('非法宽高本地拒绝', () async {
    try {
      await img.resize(src, 0, 10);
      throw StateError('0 宽本应失败');
    } on ImageMbtException catch (e) {
      assertEq(e.code, 'process/invalid_argument', 'code');
    }
  });

  // 7) 只读格式（tiff / hdr / avif …）在 Dart 侧拒绝，不 spawn 进程再吃 unsupported_format
  await checkAsync('不可写格式本地拒绝（与 CLI is_writable 的 8 个一致）', () async {
    try {
      await img.convert(src, format: 'tiff');
      throw StateError('tiff 本应失败');
    } on ImageMbtException catch (e) {
      assertEq(e.code, 'process/invalid_argument', 'code');
    }
  });

  // 8) 可执行文件缺失：必须是 ImageMbtException('process/spawn_failed')，
  //    不能被 stderr 为空的 StateError 掩盖
  await checkAsync('imgtool 缺失抛 process/spawn_failed', () async {
    final ImageMbt ghost =
        ImageMbt(executablePath: 'definitely-not-imgtool-xyz');
    try {
      await ghost.info(src);
      throw StateError('缺失可执行文件本应失败');
    } on ImageMbtException catch (e) {
      assertEq(e.code, 'process/spawn_failed', 'code');
    }
  });

  // 9) convertMeta：回执里的格式 / 宽高 / 通道 / 体积与输出字节自洽
  await checkAsync('convertMeta: 回执宽高与通道', () async {
    final ImageMeta m = await img.convertMeta(resizedPng, format: 'png');
    assertEq(m.format, 'png', 'format');
    assertEq(m.width, 2, 'width');
    assertEq(m.height, 2, 'height');
    assertEq(m.channels, 3, 'channels');
    assertEq(m.bytes, m.data.length, 'bytes');
  });

  // 10) resizeMeta：实际宽高来自 CLI 回执，且输出能被再读回
  await checkAsync('resizeMeta: 回执带实际宽高', () async {
    final ImageMeta m = await img.resizeMeta(src, 8, 6, mode: 'contain');
    assertEq(m.width, 8, 'width');
    assertEq(m.height, 6, 'height');
    assertEq(m.channels, 3, 'channels');
    final ImageInfo out = await img.info(m.data);
    assertEq(out.width, 8, 'decoded width');
    assertEq(out.height, 6, 'decoded height');
  });

  stdout.writeln('$passed/$passed+$failed passed');
  if (failed > 0) {
    exit(1);
  }
}
