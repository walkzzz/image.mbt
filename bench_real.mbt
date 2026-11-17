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
