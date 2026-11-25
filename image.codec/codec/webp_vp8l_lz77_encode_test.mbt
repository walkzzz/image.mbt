///|
/// M2 编码器验证：贪心 LZ77 + Huffman 码表，内环用 RFC 解码路径逐字节回环。

///|
fn vp8l_lz77_test_image(width : Int32, height : Int32) -> @types.Image {
  let w = width.to_int()
  let h = height.to_int()
  let src : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      src.push((x * 255 / (if w > 1 { w - 1 } else { 1 })).to_byte())
      src.push((y * 255 / (if h > 1 { h - 1 } else { 1 })).to_byte())
      src.push(((x + y) * 3 % 256).to_byte())
      src.push(255)
    }
  }
  @types.Image::{
    width,
    height,
    channels: 4,
    data: Bytes::from_array(src),
  }
}

///|
test "vp8l LZ77 编码: 64x64 回环逐字节一致" {
  let img = vp8l_lz77_test_image(64, 64)
  let encoded = try @codec.encode_webp_vp8l_lz77(img) catch {
    e => {
      fail("LZ77 编码失败：\{e}")
      Bytes::from_array([])
    }
  }
  assert_true(encoded.length() > 16)
  let decoded = try @codec.decode_webp_vp8l_rfc(encoded) catch {
    e => {
      fail("回环解码失败：\{e}")
      @types.Image::{
        width: 0,
        height: 0,
        channels: 4,
        data: Bytes::from_array([]),
      }
    }
  }
  assert_eq(decoded.width, 64)
  assert_eq(decoded.height, 64)
  assert_eq(decoded.channels, 4)
  let mut diff = 0
  for i in 0..<(64 * 64 * 4) {
    if decoded.data[i] != img.data[i] {
      diff = diff + 1
    }
  }
  assert_eq(diff, 0)
}

///|
test "vp8l LZ77 编码: 体积小于 literal-only" {
  let img = vp8l_lz77_test_image(64, 64)
  let lz = try @codec.encode_webp_vp8l_lz77(img) catch {
    _ => Bytes::from_array([])
  }
  let lit = try @codec.encode_webp_vp8l_literal(img) catch {
    _ => Bytes::from_array([])
  }
  println("LZ77=\{lz.length()} 字节, literal=\{lit.length()} 字节")
  assert_true(lz.length() < lit.length())
}

///|
test "vp8l LZ77 编码: dump 64x64 hex（外部 ffmpeg 校验）" {
  let img = vp8l_lz77_test_image(64, 64)
  let encoded = try @codec.encode_webp_vp8l_lz77(img) catch {
    _ => Bytes::from_array([])
  }
  println("LZ77_HEX=" + vp8l_to_hex(encoded))
}
