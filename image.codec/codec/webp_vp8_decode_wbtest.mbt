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
