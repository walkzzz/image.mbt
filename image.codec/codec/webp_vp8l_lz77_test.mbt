///|
/// LZ77 解码验证：样本由 `scripts/proto/gen_lz77_fixture.mjs` 生成，
/// 已被 ffmpeg 解码确认为 16×16 纯色 (R=0x20,G=0x10,B=0x30,A=0xFF)。
/// 结构：1 个 literal + 1 次 length=255 / distance=1 的反向引用；
/// 绿树是 normal 码表（符号 16 与 271），码长码 {1:1 位, 17:2 位, 18:2 位}。

///|
test "vp8l LZ77: literal + length 255 / distance 1 还原纯色" {
  let raw : Array[Int32] = [
    0x52, 0x49, 0x46, 0x46, 0x1E, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
    0x56, 0x50, 0x38, 0x4C, 0x12, 0x00, 0x00, 0x00, 0x2F, 0x0F, 0xC0, 0x03,
    0x10, 0x00, 0x12, 0xE2, 0x82, 0xFF, 0xA7, 0xD5, 0x82, 0x14, 0xA6, 0xFF,
    0xA9, 0x0F,
  ]
  let bytes : Array[Byte] = []
  for v in raw {
    bytes.push(v.to_byte())
  }
  let img = try @codec.decode_webp_vp8l_rfc(Bytes::from_array(bytes)) catch {
    e => {
      fail("LZ77 解码失败：\{e}")
      @types.Image::{
        width: 0,
        height: 0,
        channels: 4,
        data: Bytes::from_array([]),
      }
    }
  }
  assert_eq(img.width, 16)
  assert_eq(img.height, 16)
  assert_eq(img.channels, 4)
  assert_eq(img.data.length(), 16 * 16 * 4)
  let mut bad = 0
  for i in 0..<(16 * 16) {
    if img.data[i * 4].to_int() != 0x20 ||
      img.data[i * 4 + 1].to_int() != 0x10 ||
      img.data[i * 4 + 2].to_int() != 0x30 ||
      img.data[i * 4 + 3].to_int() != 0xFF {
      bad = bad + 1
    }
  }
  assert_eq(bad, 0)
}
