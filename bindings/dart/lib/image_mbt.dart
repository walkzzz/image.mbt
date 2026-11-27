// image_mbt.dart —— walkzzz/image.mbt 的 Dart 绑定（S17）
//
// 设计取舍（为什么走进程而不是 wasm / FFI）：
//   * Dart VM 没有可用的 WebAssembly 运行时：`package:wasm`（0.1.0+1）已废弃，
//     且需要本地用 Rust + MSVC `link.exe` 现编 Wasmer，不适合作为库依赖；
//   * MoonBit 官方明确「native 不支持产出静态/动态库」，`dart:ffi` 无库可载；
//   * 因此 Dart 侧把 `imgtool` 当作唯一 ABI：本文件**不实现任何编解码**，
//     只负责「字节 ↔ 临时文件 ↔ CLI JSON」的搬运，实现仍是同一份 MoonBit 代码。
//
// 用法：
//
//   final img = ImageMbt();            // 默认取环境变量 IMGTOOL，否则 PATH 里的 imgtool
//   final info = await img.info(pngBytes);
//   final resized = await img.resize(pngBytes, 320, 200, mode: 'cover', format: 'png');
//   final webp = await img.convert(resized, format: 'webp', quality: 80);

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// CLI 返回的非 ok 结果，或进程本身失败。
class ImageMbtException implements Exception {
  ImageMbtException(this.code, this.message, {this.hint = ''});

  /// 形如 `decode/decode_failed`、`process/invalid_argument`。
  final String code;
  final String message;
  final String hint;

  @override
  String toString() => 'ImageMbtException($code): $message'
      '${hint.isEmpty ? '' : '（$hint）'}';
}

/// `imgtool info` 的结果。
class ImageInfo {
  ImageInfo({
    required this.format,
    required this.width,
    required this.height,
    required this.bytes,
  });

  final String format;
  final int width;
  final int height;
  final int bytes;

  @override
  String toString() => 'ImageInfo($format ${width}x$height, $bytes B)';
}

/// 命令行绑定：每次调用一次 `imgtool` 进程，临时目录在返回前删掉。
class ImageMbt {
  ImageMbt({String? executablePath})
      : _exe = executablePath ??
            Platform.environment['IMGTOOL'] ??
            'imgtool';

  final String _exe;

  /// 可写格式之一（png / jpeg / bmp / gif / webp / qoi / ppm / tga …）。
  static const List<String> formats = <String>[
    'png',
    'jpeg',
    'bmp',
    'gif',
    'webp',
    'qoi',
    'ppm',
    'tga',
  ];

  /// 与 CLI 的 `is_writable` 一一对应（`imgcli/imgtool.mbt` 只对这 8 个格式返回 true）。
  /// 表里不列 tiff / hdr / avif / heif / ico / icns / psd：这些在本库只读，
  /// 写之前拦住而不是 spawn 一次进程再吃 `encode/unsupported_format`。
  static const Map<String, String> _ext = <String, String>{
    'png': 'png',
    'jpeg': 'jpg',
    'jpg': 'jpg',
    'bmp': 'bmp',
    'gif': 'gif',
    'webp': 'webp',
    'qoi': 'qoi',
    'ppm': 'ppm',
    'pnm': 'ppm',
    'tga': 'tga',
  };

  /// 只读探测：格式 / 尺寸 / 字节数。对应 `imgtool info`。
  Future<ImageInfo> info(Uint8List data) async {
    final _Call r = await _call(<String>['info', '@in'], data);
    final int w = (r.json['width'] as num?)?.toInt() ?? 0;
    final int h = (r.json['height'] as num?)?.toInt() ?? 0;
    return ImageInfo(
      format: (r.json['format'] as String?) ?? 'unknown',
      width: w,
      height: h,
      bytes: data.length,
    );
  }

  /// 格式互转：返回编码后的字节。对应 `imgtool convert`。
  Future<Uint8List> convert(
    Uint8List data, {
    required String format,
    int? quality,
  }) async {
    final String ext = _extOf(format);
    final _Call r = await _call(
      <String>[
        'convert',
        '@in',
        '@out',
        '--format',
        format,
        if (quality != null) ...<String>['--quality', '$quality'],
      ],
      data,
      outName: 'out.$ext',
    );
    return r.output!;
  }

  /// 缩放：`mode` 取 `cover` / `contain`。对应 `imgtool resize`。
  Future<Uint8List> resize(
    Uint8List data,
    int width,
    int height, {
    String mode = 'cover',
    String? format,
    int? quality,
  }) async {
    if (width <= 0 || height <= 0) {
      throw ImageMbtException(
        'process/invalid_argument',
        '宽高必须为正数：$width x $height',
      );
    }
    final String fmt = format ?? 'png';
    final String ext = _extOf(fmt);
    final _Call r = await _call(
      <String>[
        'resize',
        '@in',
        '@out',
        '--width',
        '$width',
        '--height',
        '$height',
        '--mode',
        mode,
        '--format',
        fmt,
        if (quality != null) ...<String>['--quality', '$quality'],
      ],
      data,
      outName: 'out.$ext',
    );
    return r.output!;
  }

  /// decode → resize → encode 一次走完（S17 验收口径）。
  Future<Uint8List> roundtrip(
    Uint8List data, {
    required int width,
    required int height,
    String mode = 'cover',
    String format = 'png',
    int? quality,
  }) =>
      resize(data, width, height, mode: mode, format: format, quality: quality);

  String _extOf(String format) {
    final String? ext = _ext[format.toLowerCase()];
    if (ext == null) {
      throw ImageMbtException(
        'process/invalid_argument',
        '不支持的输出格式：$format（可用：${formats.join(' / ')}）',
      );
    }
    return ext;
  }

  Future<_Call> _call(
    List<String> args,
    Uint8List data, {
    String? outName,
  }) async {
    final Directory dir = await Directory.systemTemp.createTemp('image_mbt_');
    try {
      final String inPath = '${dir.path}/in.bin';
      await File(inPath).writeAsBytes(data, flush: true);
      final String? outPath = outName == null ? null : '${dir.path}/$outName';
      final List<String> resolved = args
          .map((String a) => a == '@in'
              ? inPath
              : a == '@out'
                  ? outPath!
                  : a)
          .toList();
      final ProcessResult res = await Process.run(_exe, resolved);
      final String stdout = (res.stdout as String).trim();
      final Map<String, dynamic> json = stdout.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(stdout.split('\n').last) as Map<String, dynamic>;
      if (res.exitCode != 0 || json['ok'] != true) {
        // stderr 可能整段为空（进程直接失败、或只写 JSON 到 stdout），
        // 空的时候 `.split('\n').first` 会抛 StateError 并把真实 code 掩盖掉。
        final String stderrText = (res.stderr as String).trim();
        final String firstErrLine =
            stderrText.isEmpty ? '' : stderrText.split('\n').first;
        throw ImageMbtException(
          (json['code'] as String?) ?? 'process/failed',
          (json['message'] as String?) ??
              (firstErrLine.isNotEmpty
                  ? firstErrLine
                  : 'imgtool 退出码 ${res.exitCode}，无 stderr'),
          hint: (json['hint'] as String?) ?? '',
        );
      }
      Uint8List? output;
      if (outPath != null) {
        final File f = File(outPath);
        if (!f.existsSync()) {
          throw ImageMbtException(
            'io/missing_output',
            'CLI 报告成功但没写出文件：$outPath',
          );
        }
        output = Uint8List.fromList(f.readAsBytesSync());
      }
      return _Call(json, output);
    } catch (e) {
      if (e is ImageMbtException) rethrow;
      throw ImageMbtException('process/spawn_failed', '$e');
    } finally {
      try {
        await dir.delete(recursive: true);
      } catch (_) {
        // Windows 上偶发占用：删不掉就留给系统临时目录，不影响结果。
      }
    }
  }
}

class _Call {
  _Call(this.json, this.output);

  final Map<String, dynamic> json;
  final Uint8List? output;
}
