/// ============================================================================
/// 真实尺寸基准 — 1024² / 4096² 的 PNG 编解码与缩放（B3 现代化，取代 128² 固定小图）
/// ============================================================================

///| 构造 RGB 渐变测试图（x/y/对角分量），尺寸参数化。

///|

///|
/// Build a RGB gradient test image with parameterized size.
fn make_gradient(w : Int32, h : Int32) -> @types.Image noraise {
  let buf : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      buf.push((x % 256).to_byte())
      buf.push((y % 256).to_byte())
      buf.push(((x + y) % 256).to_byte())
    }
  }
  { width: w, height: h, channels: 3, data: Bytes::from_array(buf), }
}

///| PNG 往返：编码 → 自动格式检测解码，返回 width+height（失败 -1）。

///|

///|
/// PNG roundtrip: encode → auto-detect decode, returning width+height (-1 on failure).
fn png_roundtrip(img : @types.Image) -> Int32 raise @types.LoadError {
  let bytes : Bytes = @lib.encode_png(img)
  let decoded = @lib.load_from_bytes_auto(bytes)
  decoded.width + decoded.height
}

///|
test (b : @bench.T) {
  let img_1024 = make_gradient(1024, 1024)
  let png_1024 : Bytes = @lib.encode_png(img_1024)
  b.bench(name="png_encode_1024", fn() {
    b.keep(@lib.encode_png(img_1024).length())
  })
  b.bench(name="png_decode_1024", fn() {
    b.keep(png_roundtrip(img_1024) catch { _ => -1 })
  })
  b.bench(name="png_bytes_1024", fn() { b.keep(png_1024.length()) })
}

///|
test (b : @bench.T) {
  let img_1024 = make_gradient(1024, 1024)
  b.bench(name="resize_cover_1024_to_512", fn() {
    b.keep(
      try {
        let r = @transform.resize_to_cover(img_1024, 512, 512)
        r.width + r.height
      } catch {
        _ => -1
      },
    )
  })
}

///|
test (b : @bench.T) {
  let img_4096 = make_gradient(4096, 4096)
  b.bench(name="png_encode_4096", fn() {
    b.keep(@lib.encode_png(img_4096).length())
  })
  b.bench(name="png_decode_4096", fn() {
    b.keep(png_roundtrip(img_4096) catch { _ => -1 })
  })
}

///| 各编码器的字节长度（失败 -1），供 bench 闭包内使用（闭包不可 raise）。

///|
fn jpeg_len(img : @types.Image) -> Int32 noraise {
  @lib.encode_jpeg(img).length() catch {
    _ => -1
  }
}

///|
fn gif_len(img : @types.Image) -> Int32 noraise {
  @lib.encode_gif(img).length() catch {
    _ => -1
  }
}

///|
fn qoi_len(img : @types.Image) -> Int32 noraise {
  @lib.encode_qoi(img).length() catch {
    _ => -1
  }
}

///|
fn webp_len(img : @types.Image) -> Int32 noraise {
  @codec.encode_webp_lossless(img).length() catch {
    _ => -1
  }
}

///| 自动识别解码后的 width+height（失败 -1）。

///|
fn auto_dims(bytes : Bytes) -> Int32 noraise {
  try {
    let d = @lib.load_from_bytes_auto(bytes)
    d.width + d.height
  } catch {
    _ => -1
  }
}

///| 非 PNG 格式编解码基准。GIF 用 512² 以控制单次耗时（旧 ARM 报告 23.4 KP/s 量级过慢）。

///|
/// Non-PNG codec benchmarks. GIF uses 512² to keep a single run bounded.
test (b : @bench.T) {
  let img_1024 = make_gradient(1024, 1024)
  let img_512 = make_gradient(512, 512)
  let jpeg_1024 : Bytes = @lib.encode_jpeg(img_1024) catch {
    _ => Bytes::make(0, b'\x00')
  }
  b.bench(name="jpeg_encode_1024", fn() { b.keep(jpeg_len(img_1024)) })
  b.bench(name="jpeg_decode_1024", fn() { b.keep(auto_dims(jpeg_1024)) })
  b.bench(name="webp_encode_1024", fn() { b.keep(webp_len(img_1024)) })
  // 解码基准用自家编码器产物（含调色板 / predictor / subtract-green 变换），
  // 覆盖下游真实路径：`moon add` 后 encode → 存盘 → decode。
  let webp_1024 : Bytes = @codec.encode_webp_lossless(img_1024) catch {
    _ => Bytes::make(0, b'\x00')
  }
  b.bench(name="webp_decode_1024", fn() { b.keep(auto_dims(webp_1024)) })
  b.bench(name="bmp_encode_1024", fn() {
    b.keep(@lib.encode_bmp(img_1024).length())
  })
  b.bench(name="qoi_encode_1024", fn() { b.keep(qoi_len(img_1024)) })
  b.bench(name="gif_encode_512", fn() { b.keep(gif_len(img_512)) })
}
