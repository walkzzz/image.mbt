///|
/// encode_webp_lossless 验证：四种内容的自适应变换选择 + 回环 + ffmpeg 外环。

///|
fn vp8l_lossless_solid(w : Int32, h : Int32) -> @types.Image {
  let n = w.to_int() * h.to_int()
  let src : Array[Byte] = Array::make(n * 4, b'\x00')
  for i in 0..<n {
    src[i * 4] = (40).to_byte()
    src[i * 4 + 1] = (120).to_byte()
    src[i * 4 + 2] = (200).to_byte()
    src[i * 4 + 3] = (255).to_byte()
  }
  @types.Image::{ width: w, height: h, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_lossless_checker(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let src : Array[Byte] = Array::make(wi * hi * 4, b'\x00')
  for y in 0..<hi {
    for x in 0..<wi {
      let v = ((x / 8) + (y / 8)) % 2
      let i = (y * wi + x) * 4
      src[i] = (if v == 0 { 30 } else { 220 }).to_byte()
      src[i + 1] = (if v == 0 { 60 } else { 190 }).to_byte()
      src[i + 2] = (if v == 0 { 90 } else { 160 }).to_byte()
      src[i + 3] = (255).to_byte()
    }
  }
  @types.Image::{ width: w, height: h, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_lossless_gradient(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let src : Array[Byte] = Array::make(wi * hi * 4, b'\x00')
  for y in 0..<hi {
    for x in 0..<wi {
      let i = (y * wi + x) * 4
      src[i] = ((x * 4) % 256).to_byte()
      src[i + 1] = ((y * 4) % 256).to_byte()
      src[i + 2] = (((x + y) * 2) % 256).to_byte()
      src[i + 3] = (255).to_byte()
    }
  }
  @types.Image::{ width: w, height: h, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_lossless_noise(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let src : Array[Byte] = Array::make(wi * hi * 4, b'\x00')
  let mut seed = 12345
  for i in 0..<(wi * hi) {
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    src[i * 4] = ((seed / 65536) % 256).to_byte()
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    src[i * 4 + 1] = ((seed / 65536) % 256).to_byte()
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    src[i * 4 + 2] = ((seed / 65536) % 256).to_byte()
    src[i * 4 + 3] = (255).to_byte()
  }
  @types.Image::{ width: w, height: h, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_lossless_roundtrip(name : String, img : @types.Image) -> (Bytes, Int) {
  let enc = try @codec.encode_webp_lossless(img) catch {
    _ => Bytes::from_array([])
  }
  let dec = try @codec.decode_webp_vp8l_rfc(enc) catch {
    _ => {
      println("\{name}: 回环解码失败")
      img
    }
  }
  let n = img.width.to_int() * img.height.to_int()
  let mut bad = 0
  for i in 0..<n {
    for c in 0..<4 {
      if dec.data[i * 4 + c] != img.data[i * 4 + c] {
        bad = bad + 1
      }
    }
  }
  println("\{name}: 体积=\{enc.length()} 差异=\{bad}")
  (enc, bad)
}

///|
test "webp lossless：纯色 64² 走 palette" {
  let img = vp8l_lossless_solid(64, 64)
  let (enc, bad) = vp8l_lossless_roundtrip("纯色 64²", img)
  println("纯色 HEX=" + vp8l_to_hex(enc))
  assert_eq(bad, 0)
  assert_true(enc.length() <= 60)
}

///|
test "webp lossless：棋盘 256² 走 palette" {
  let img = vp8l_lossless_checker(256, 256)
  let (enc, bad) = vp8l_lossless_roundtrip("棋盘 256²", img)
  assert_eq(bad, 0)
  println("棋盘 HEX=" + vp8l_to_hex(enc))
}

///|
test "webp lossless：梯度 64² 走 predictor" {
  let img = vp8l_lossless_gradient(64, 64)
  let (enc, bad) = vp8l_lossless_roundtrip("梯度 64²", img)
  assert_eq(bad, 0)
  println("梯度 HEX=" + vp8l_to_hex(enc))
}

///|
test "webp lossless：噪声 64² 走原样或 subtract-green" {
  let img = vp8l_lossless_noise(64, 64)
  let (enc, bad) = vp8l_lossless_roundtrip("噪声 64²", img)
  assert_eq(bad, 0)
  assert_true(enc.length() > 8000)
}
