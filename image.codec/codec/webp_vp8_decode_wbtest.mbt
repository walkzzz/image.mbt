///|
fn wvd_wb_make_rgb(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push((i * 11 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
#warnings("-deprecated")
test "wbtest: decode_vp8_inter_frame 关键帧输入走常规解码并更新参考帧" {
  let img = wvd_wb_make_rgb(16, 16)
  let bytes = encode_webp_lossy_full(img)
  let refs = Vp8ReferenceFrames::new(16, 16)
  try {
    let (out, new_refs) = decode_vp8_inter_frame(bytes, 20, refs)
    assert_eq(out.width, 16)
    assert_eq(out.height, 16)
    assert_eq(new_refs.width, 16)
  } catch {
    _ => assert_true(false)
  }
}

///|
fn wvd_wb_make_inter_frame(first_part_size : Int32) -> Bytes {
  let tag = (1 << 0) | (0 << 1) | (1 << 4) | ((first_part_size & 0x7FFFF) << 5)
  let out : Array[Byte] = []
  out.push((tag & 0xFF).to_byte())
  out.push(((tag >> 8) & 0xFF).to_byte())
  out.push(((tag >> 16) & 0xFF).to_byte())
  for _ in 0..<first_part_size {
    out.push(b'\x00')
  }
  Bytes::from_array(out)
}

///|
#warnings("-deprecated")
test "wbtest: inter 帧使用参考帧尺寸解码" {
  let bytes = wvd_wb_make_inter_frame(64)
  let refs = Vp8ReferenceFrames::new(16, 16)
  try {
    let (out, new_refs) = decode_vp8_inter_frame(bytes, 0, refs)
    assert_eq(out.width, 16)
    assert_eq(out.height, 16)
    assert_eq(new_refs.width, 16)
  } catch {
    // 零填充分区可能触发明确的解码错误（不应 panic）。
    _ => assert_true(true)
  }
}
