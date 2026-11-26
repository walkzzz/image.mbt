// 覆盖率测试：统一 info 在 TGA / ICO / CUR / ICNS / APNG / HDR / TIFF 上的分支

///|
fn uff_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, fill.to_byte())),
  }
}

///|
fn uff_imagef(w : Int32, h : Int32, c : Int32, v : Double) -> @types.ImageF {
  let n = w * h * c
  let out : Array[Byte] = []
  for _i in 0..<n {
    let b = Float::from_double(v).to_le_bytes()
    for k in 0..<4 {
      out.push(b[k])
    }
  }
  @types.ImageF::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(out),
  }
}

///|
fn uff_zero() -> @lib.UnifiedImageInfo {
  @lib.UnifiedImageInfo::{
    format: @types.ImageFormat::Unknown,
    format_name: "err",
    width: -1,
    height: -1,
    channels: -1,
    bit_depth: -1,
    has_alpha: false,
  }
}

///|
fn uff_info(data : Bytes) -> @lib.UnifiedImageInfo {
  @lib.get_image_info(data) catch {
    _ => uff_zero()
  }
}

///|
test "uff: TGA 统一 info" {
  let tga = @codec.encode_tga_pure(uff_img(4, 4, 3, 90))
  let info = uff_info(tga)
  assert_true(info.width == 4)
  assert_true(info.height == 4)
  let summary = @lib.get_image_summary(tga) catch { _ => "" }
  assert_true(summary.length() > 0)
}

///|
test "uff: ICO 与 CUR 统一 info" {
  let img = uff_img(4, 4, 3, 70)
  let ico = @codec.encode_ico_pure(img)
  let info = uff_info(ico)
  assert_true(info.width == 4 || info.format_name == "ICO")
  let cur = @codec.encode_cur_pure(img)
  let cinfo = uff_info(cur)
  assert_true(cinfo.bit_depth == 8 || cinfo.format_name == "CUR")
}

///|
test "uff: ICNS 统一 info" {
  let icns = @codec.encode_icns_pure(uff_img(8, 8, 4, 60))
  let info = uff_info(icns)
  assert_true(info.bit_depth == 32 || info.format_name == "ICNS")
}

///|
test "uff: APNG 统一 info" {
  let anim = @types.PngAnimation::{
    frames: [uff_img(5, 5, 3, 40)],
    delays: [100],
  }
  let apng = @codec.encode_apng_pure(anim) catch { _ => Bytes::from_array([]) }
  let info = uff_info(apng)
  assert_true(info.width == 5 || info.format_name == "APNG")
}

///|
test "uff: HDR 统一 info" {
  let hdr = @codec.encode_hdr_pure(uff_imagef(4, 3, 3, 0.5)) catch {
    _ => Bytes::from_array([])
  }
  let info = uff_info(hdr)
  assert_true(info.bit_depth == 32 || info.format_name == "HDR")
}

///|
test "uff: TIFF 统一 info" {
  let tiff = @codec.encode_tiff_pure(uff_img(5, 3, 3, 55)) catch {
    _ => Bytes::from_array([])
  }
  let info = uff_info(tiff)
  assert_true(info.width == 5 || info.format_name == "TIFF")
}
