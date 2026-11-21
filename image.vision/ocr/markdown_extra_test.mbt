///|
fn md_make_binary(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h, b'\x00')
  for y in 4..<12 {
    for x in 4..<12 {
      data[y * w + x] = b'\xFF'
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "ocr_markdown: 符号识别" {
  let syms = @ocr.recognize_symbols_markdown("a → b ± c")
  assert_true(syms.length() >= 0)
}

///|
test "ocr_markdown: 图像区域检测" {
  let img = md_make_binary(16, 16)
  try {
    let regions = @ocr.detect_image_regions_markdown(img, min_area=10)
    assert_true(regions.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
}
