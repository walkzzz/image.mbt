///|
fn ct_make_rgb(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push((i * 19 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "codec_trait: encode/decode 分派（PNG/BMP/QOI/TIFF/GIF）" {
  let img = ct_make_rgb(2, 2)
  let any = @types.AnyImage::U8(img)
  let formats : Array[@types.ImageFormat] = [
    @types.ImageFormat::Png,
    @types.ImageFormat::Bmp,
    @types.ImageFormat::Qoi,
    @types.ImageFormat::Tiff,
    @types.ImageFormat::Gif,
  ]
  for f in formats {
    try {
      let bytes = @codec.Codec::encode(f, any)
      assert_true(bytes.length() > 4)
      let back = @codec.Codec::decode(f, bytes)
      assert_true(back is @types.AnyImage::U8(_))
    } catch {
      _ => assert_true(false)
    }
  }
}

///|
test "codec_trait: format_name / can_encode / can_decode / is_lossless" {
  let png = @types.ImageFormat::Png
  assert_eq(@codec.Codec::format_name(png), "PNG")
  assert_true(@codec.Codec::can_encode(png))
  assert_true(@codec.Codec::can_decode(png))
  assert_true(@codec.Codec::is_lossless(png))
  let psd = @types.ImageFormat::Psd
  assert_true(!@codec.Codec::can_encode(psd))
  assert_true(@codec.Codec::can_decode(psd))
  assert_true(!@codec.Codec::can_decode(@types.ImageFormat::Unknown))
}

///|
test "codec_trait: 全部可编码格式的 encode 分派" {
  let img = ct_make_rgb(2, 2)
  let any = @types.AnyImage::U8(img)
  let formats : Array[@types.ImageFormat] = [
    @types.ImageFormat::Png,
    @types.ImageFormat::Jpeg,
    @types.ImageFormat::Bmp,
    @types.ImageFormat::Gif,
    @types.ImageFormat::Tga,
    @types.ImageFormat::Hdr,
    @types.ImageFormat::Pnm,
    @types.ImageFormat::Qoi,
    @types.ImageFormat::Webp,
    @types.ImageFormat::Tiff,
    @types.ImageFormat::Ico,
    @types.ImageFormat::Cur,
    @types.ImageFormat::Icns,
    @types.ImageFormat::Apng,
  ]
  for f in formats {
    assert_true(@codec.Codec::can_encode(f))
    try {
      let bytes = @codec.Codec::encode(f, any)
      assert_true(bytes.length() > 4)
    } catch {
      _ => assert_true(false)
    }
  }
}
