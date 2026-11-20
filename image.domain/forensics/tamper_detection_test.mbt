///|
fn td_make_gray(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h) {
    data.push((i * 17 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "forensics: ELA/噪声/DCT/光照/元数据/JPEG 幽灵/CFA" {
  let img = td_make_gray(16, 16)
  try {
    let _ = @forensics.analyze_ela(img, 75)
    let _ = @forensics.analyze_noise_residual(img)
    let _ = @forensics.analyze_dct_coefficients(img)
    let _ = @forensics.analyze_illumination_consistency(img)
    let _ = @forensics.analyze_metadata_forensics(img)
    let _ = @forensics.analyze_jpeg_ghost(img)
    let _ = @forensics.analyze_cfa_pattern(img)
    assert_true(true)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "forensics: 克隆检测与综合检测" {
  let img = td_make_gray(16, 16)
  try {
    let _ = @forensics.detect_clone_regions(img, 4, 0.9)
    let _ = @forensics.detect_tamper_comprehensive(img, 75)
    assert_true(true)
  } catch {
    _ => assert_true(false)
  }
}
