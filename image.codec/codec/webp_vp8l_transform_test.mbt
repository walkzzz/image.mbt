///|
/// 真实 WebP（libwebp/ffmpeg 产出，带 palette / predictor 变换）解码验证。

///|
fn vp8l_hex_bytes(hex : String) -> Bytes {
  let n = hex.length() / 2
  let out : Array[Byte] = Array::make(n, b'\x00')
  let mut k = 0
  let mut hi = 0
  for c in hex {
    let v = vp8l_nibble(c)
    if k % 2 == 0 {
      hi = v
    } else {
      out[k / 2] = (hi * 16 + v).to_byte()
    }
    k += 1
  }
  Bytes::from_array(out)
}

///|
fn vp8l_nibble(c : Char) -> Int32 {
  let code = c.to_int()
  if code >= 48 && code <= 57 {
    code - 48
  } else if code >= 65 && code <= 70 {
    code - 55
  } else {
    code - 87
  }
}

///|
test "VP8L 解码：libwebp 纯色 256²（palette + 像素打包）" {
  let hex = "5249464624000000574542505650384c180000002fffc03f000750bca214b9ff010045faff9f22fa9ffadf7f"
  let bytes = vp8l_hex_bytes(hex)
  println(bytes.length().to_string())
  println(bytes[0].to_int().to_string())
  println(bytes[12].to_int().to_string())
  println(bytes[13].to_int().to_string())
  println(bytes[14].to_int().to_string())
  println(bytes[15].to_int().to_string())
  println(hex.length().to_string())
  let img = @codec.decode_webp_vp8l_rfc(bytes) catch {
    e => {
      fail("解码失败：\{e}")
      @types.Image::{
        width: 0,
        height: 0,
        channels: 4,
        data: Bytes::from_array([]),
      }
    }
  }
  assert_eq(img.width, 256)
  assert_eq(img.height, 256)
  for i in 0..<8 {
    println(img.data[i].to_int().to_string())
  }
  let mut bad = 0
  for i in 0..<(256 * 256) {
    if img.data[i * 4] != (40).to_byte() ||
      img.data[i * 4 + 1] != (120).to_byte() ||
      img.data[i * 4 + 2] != (200).to_byte() ||
      img.data[i * 4 + 3] != (255).to_byte() {
      bad = bad + 1
    }
  }
  assert_eq(bad, 0)
}

///|
test "VP8L 解码：libwebp 棋盘 256²（palette）" {
  let hex = "524946463a000000574542505650384c2d0000002fffc03f000f701ec17bf8de486bfe83074202c2ffd3268822faaf206d03a63b0aaa02eb5fea7fffbdfb3fef0000"
  let bytes = vp8l_hex_bytes(hex)
  let img = @codec.decode_webp_vp8l_rfc(bytes) catch {
    e => {
      fail("解码失败：\{e}")
      @types.Image::{
        width: 0,
        height: 0,
        channels: 4,
        data: Bytes::from_array([]),
      }
    }
  }
  assert_eq(img.width, 256)
  let mut bad = 0
  for y in 0..<256 {
    for x in 0..<256 {
      let v = (x / 8 + y / 8) % 2
      let want_r = if v == 0 { 30 } else { 220 }
      let want_g = if v == 0 { 60 } else { 190 }
      let want_b = if v == 0 { 90 } else { 160 }
      let i = (y * 256 + x) * 4
      if img.data[i].to_int() != want_r ||
        img.data[i + 1].to_int() != want_g ||
        img.data[i + 2].to_int() != want_b ||
        img.data[i + 3].to_int() != 255 {
        bad = bad + 1
      }
    }
  }
  assert_eq(bad, 0)
}
