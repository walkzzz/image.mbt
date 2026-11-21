///|
test "testgen-drive: VP8 关键帧零分区解码" {
  let bytes = @testgen.build_vp8_key_frame(16, 16, first_part_size=64)
  try {
    let img = @codec.decode_vp8_frame(bytes, 0)
    assert_eq(img.width, 16)
    assert_eq(img.height, 16)
    assert_eq(img.channels, 3)
  } catch {
    _ => assert_true(false)
  }
}
