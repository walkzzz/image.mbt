// 覆盖率测试：统一 info API 的多格式分支与摘要文本

///|
fn uic_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, fill.to_byte())),
  }
}

///|
test "uicov: 多格式统一 info" {
  let rgb = uic_img(6, 5, 3, 80)
  let gray = uic_img(6, 5, 1, 120)
  let rgba = uic_img(6, 5, 4, 60)
  // PNG
  let png = @lib.encode_png(rgb)
  let i1 = @lib.get_image_info(png)
  assert_true(i1.format == @types.ImageFormat::Png)
  assert_true(i1.format_name == "PNG")
  assert_true(i1.width == 6)
  assert_true(i1.height == 5)
  // BMP
  let bmp = @lib.encode_bmp(rgb)
  let i2 = @lib.get_image_info(bmp)
  assert_true(i2.format_name == "BMP")
  assert_true(i2.width == 6)
  // QOI
  let qoi = @lib.encode_qoi(rgb)
  let i3 = @lib.get_image_info(qoi)
  assert_true(i3.format_name == "QOI")
  // PNM
  let pnm = @lib.encode_pnm_auto(gray)
  let i4 = @lib.get_image_info(pnm)
  assert_true(i4.format_name == "PNM")
  assert_true(i4.channels >= 1)
  // GIF
  let gif = @lib.encode_gif(rgb)
  let i5 = @lib.get_image_info(gif)
  assert_true(i5.format_name == "GIF")
  // JPEG
  let jpg = @lib.encode_jpeg(rgb)
  let i6 = @lib.get_image_info(jpg)
  assert_true(i6.format_name == "JPEG")
  // WebP 无损
  let wp = @lib.encode_webp_lossless(rgb)
  let i7 = @lib.get_image_info(wp)
  assert_true(i7.format_name == "WebP")
  // RGBA 图 → has_alpha 可能为真
  let png_a = @lib.encode_png(rgba)
  let i8 = @lib.get_image_info(png_a)
  assert_true(i8.width == 6)
  assert_true(i8.bit_depth >= 1)
  // 摘要文本
  let s1 = @lib.get_image_summary(png)
  assert_true(s1.length() > 0)
  let s2 = @lib.get_image_summary(bmp)
  assert_true(s2.length() > 0)
  let s3 = @lib.get_image_summary(gif)
  assert_true(s3.length() > 0)
  // 未知格式 → 抛错
  let junk : Array[Byte] = [b'\x00', b'\x01', b'\x02', b'\x03']
  try {
    let _ = @lib.get_image_info(Bytes::from_array(junk))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @lib.get_image_summary(Bytes::from_array(junk))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 空数据 → 抛错
  try {
    let _ = @lib.get_image_info(Bytes::from_array([]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
