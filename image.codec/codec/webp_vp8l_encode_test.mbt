///|
/// M1 验证：literal-only VP8L 产物必须能被本库解码器逐字节还原。
/// 外部解码器（ffmpeg）验证由 scripts/proto/*.mjs 承担，这里只锁内环。

///|
fn vp8l_test_image(
  width : Int32,
  height : Int32,
  channels : Int32,
) -> @types.Image {
  let src : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      src.push(
        (x * 255 / (if width > 1 { width.to_int() - 1 } else { 1 })).to_byte(),
      )
      src.push(
        (y * 255 / (if height > 1 { height.to_int() - 1 } else { 1 })).to_byte(),
      )
      src.push(((x + y) * 3 % 256).to_byte())
      if channels.to_int() == 4 {
        src.push((200 + x % 56).to_byte())
      }
    }
  }
  @types.Image::{ width, height, channels, data: Bytes::from_array(src), }
}

///|
test "vp8l M1: 16x16 RGBA 编解码逐字节一致" {
  let img = vp8l_test_image(16, 16, 4)
  let encoded = @codec.encode_webp_vp8l_literal(img) catch {
    e => {
      fail("编码失败：\{e}")
      Bytes::from_array([])
    }
  }
  assert_true(encoded.length() > 8)
  // RIFF/WEBP 头
  assert_eq(encoded[0].to_int(), 0x52)
  assert_eq(encoded[8].to_int(), 0x57)
  assert_eq(encoded[12].to_int(), 0x56) // 'V'
  assert_eq(encoded[13].to_int(), 0x50) // 'P'
  let decoded = @codec.decode_webp_vp8l_rfc(encoded) catch {
    e => {
      fail("解码失败：\{e}")
      vp8l_test_image(1, 1, 4)
    }
  }
  assert_eq(decoded.width, 16)
  assert_eq(decoded.height, 16)
  assert_eq(decoded.channels, 4)
  assert_eq(decoded.data.length(), 16 * 16 * 4)
  let mut diff = 0
  for i in 0..<(16 * 16 * 4) {
    if decoded.data[i] != img.data[i] {
      diff = diff + 1
    }
  }
  assert_eq(diff, 0)
}

///|
test "vp8l M1: 3 通道输入补 alpha=255" {
  let img = vp8l_test_image(8, 8, 3)
  let encoded = @codec.encode_webp_vp8l_literal(img) catch {
    _ => Bytes::from_array([])
  }
  let decoded = @codec.decode_webp_vp8l_rfc(encoded) catch {
    e => {
      fail("解码失败：\{e}")
      vp8l_test_image(1, 1, 4)
    }
  }
  assert_eq(decoded.channels, 4)
  assert_eq(decoded.data.length(), 8 * 8 * 4)
  let mut bad_alpha = 0
  let mut bad_rgb = 0
  for i in 0..<(8 * 8) {
    if decoded.data[i * 4 + 3].to_int() != 255 {
      bad_alpha = bad_alpha + 1
    }
    for c in 0..<3 {
      if decoded.data[i * 4 + c] != img.data[i * 3 + c] {
        bad_rgb = bad_rgb + 1
      }
    }
  }
  assert_eq(bad_alpha, 0)
  assert_eq(bad_rgb, 0)
}

///|
test "vp8l M1: 1x1 边界" {
  let img = vp8l_test_image(1, 1, 4)
  let encoded = @codec.encode_webp_vp8l_literal(img) catch {
    _ => Bytes::from_array([])
  }
  let decoded = @codec.decode_webp_vp8l_rfc(encoded) catch {
    _ => vp8l_test_image(2, 2, 4)
  }
  assert_eq(decoded.width, 1)
  assert_eq(decoded.height, 1)
  assert_eq(decoded.data[0], img.data[0])
  assert_eq(decoded.data[1], img.data[1])
  assert_eq(decoded.data[2], img.data[2])
}

///|
/// 字节串转 hex，供外部脚本落盘给 ffmpeg 校验
fn vp8l_to_hex(bytes : Bytes) -> String {
  let chars : Array[String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
  ]
  let mut s = ""
  for i in 0..<bytes.length() {
    let v = bytes[i].to_int()
    s = s + chars[v / 16] + chars[v % 16]
  }
  s
}

///|
test "vp8l M1: dump 16x16 产物 hex（外部 ffmpeg 校验用）" {
  let img = vp8l_test_image(16, 16, 4)
  let encoded = @codec.encode_webp_vp8l_literal(img) catch {
    _ => Bytes::from_array([])
  }
  println("VP8L_HEX=" + vp8l_to_hex(encoded))
}

///|
test "vp8l M1: 尺寸超限报错" {
  let img : @types.Image = {
    width: 20000,
    height: 1,
    channels: 4,
    data: Bytes::from_array([]),
  }
  let mut raised = false
  try @codec.encode_webp_vp8l_literal(img) catch {
    @types.LoadError::DecodeFailed(_) => raised = true
    _ => ()
  } noraise {
    _ => ()
  }
  assert_true(raised)
}
