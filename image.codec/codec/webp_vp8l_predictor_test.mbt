///|
/// predictor / color transform 路径的真实文件验证。

///|
test "VP8L 解码：libwebp 64² 梯度（predictor 变换）" {
  let hex = "524946463e000000574542505650384c310000002f3fc00f00b98ce87f0c840409ff8f1bad31e0fd9f00a9bf0c0ad23660f6fc1b9f800d02495bbcedaf404cc0f1f67cbe0300"
  let bytes = vp8l_hex_bytes(hex)
  let img = try @codec.decode_webp_vp8l_rfc(bytes) catch {
    e => {
      fail("解码失败：\{e}")
      @types.Image::{ width: 0, height: 0, channels: 4, data: Bytes::from_array([]) }
    }
  }
  assert_eq(img.width, 64)
  assert_eq(img.height, 64)
  let mut bad = 0
  for y in 0..<64 {
    for x in 0..<64 {
      let i = (y * 64 + x) * 4
      let want_r = (x * 4) % 256
      let want_g = (y * 4) % 256
      let want_b = ((x + y) * 2) % 256
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
