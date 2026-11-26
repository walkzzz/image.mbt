///|
/// # codec_trait 分支覆盖测试 Branch coverage for Codec trait / format detection
///
/// 目标：把 `format_name` / `can_encode` / `can_decode` / `is_lossless` 的全枚举分支，
/// 以及 `codec_detect_format` 的每条魔数分支，各至少走一次。

///|
fn ctb_bytes(arr : Array[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
fn ctb_rgb(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push((i * 7 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "codec_trait: format_name 全枚举" {
  let cases : Array[(@types.ImageFormat, String)] = [
    (@types.ImageFormat::Png, "PNG"),
    (@types.ImageFormat::Jpeg, "JPEG"),
    (@types.ImageFormat::Bmp, "BMP"),
    (@types.ImageFormat::Gif, "GIF"),
    (@types.ImageFormat::Tga, "TGA"),
    (@types.ImageFormat::Psd, "PSD"),
    (@types.ImageFormat::Hdr, "HDR"),
    (@types.ImageFormat::Pnm, "PNM"),
    (@types.ImageFormat::Qoi, "QOI"),
    (@types.ImageFormat::Webp, "WebP"),
    (@types.ImageFormat::Tiff, "TIFF"),
    (@types.ImageFormat::Ico, "ICO"),
    (@types.ImageFormat::Cur, "CUR"),
    (@types.ImageFormat::Icns, "ICNS"),
    (@types.ImageFormat::Apng, "APNG"),
    (@types.ImageFormat::Avif, "AVIF"),
    (@types.ImageFormat::Heif, "HEIF"),
    (@types.ImageFormat::JpegXl, "JPEG-XL"),
    (@types.ImageFormat::Unknown, "Unknown"),
  ]
  for (f, name) in cases {
    assert_eq(@codec.Codec::format_name(f), name)
  }
}

///|
test "codec_trait: can_encode / can_decode / is_lossless 全枚举" {
  let encodable : Array[@types.ImageFormat] = [
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
  for f in encodable {
    assert_true(@codec.Codec::can_encode(f))
  }
  let encode_only_no : Array[@types.ImageFormat] = [
    @types.ImageFormat::Psd,
    @types.ImageFormat::Avif,
    @types.ImageFormat::Heif,
    @types.ImageFormat::JpegXl,
    @types.ImageFormat::Unknown,
  ]
  for f in encode_only_no {
    assert_true(!@codec.Codec::can_encode(f))
  }
  let lossy : Array[@types.ImageFormat] = [
    @types.ImageFormat::Jpeg,
    @types.ImageFormat::Webp,
    @types.ImageFormat::Avif,
    @types.ImageFormat::Heif,
    @types.ImageFormat::JpegXl,
  ]
  for f in lossy {
    assert_true(!@codec.Codec::is_lossless(f))
  }
  let lossless : Array[@types.ImageFormat] = [
    @types.ImageFormat::Png,
    @types.ImageFormat::Bmp,
    @types.ImageFormat::Gif,
    @types.ImageFormat::Tga,
    @types.ImageFormat::Hdr,
    @types.ImageFormat::Pnm,
    @types.ImageFormat::Qoi,
    @types.ImageFormat::Tiff,
    @types.ImageFormat::Ico,
    @types.ImageFormat::Cur,
    @types.ImageFormat::Icns,
    @types.ImageFormat::Apng,
    @types.ImageFormat::Psd,
    @types.ImageFormat::Unknown,
  ]
  for f in lossless {
    assert_true(@codec.Codec::is_lossless(f))
  }
  assert_true(@codec.Codec::can_decode(@types.ImageFormat::Png))
  assert_true(@codec.Codec::can_decode(@types.ImageFormat::JpegXl))
  assert_true(!@codec.Codec::can_decode(@types.ImageFormat::Unknown))
}

///|
test "codec_trait: codec_detect_format 全魔数分支" {
  let cases : Array[(Bytes, @types.ImageFormat)] = [
    (ctb_bytes([b'\x89', b'\x50']), @types.ImageFormat::Png),
    (ctb_bytes([b'\xFF', b'\xD8']), @types.ImageFormat::Jpeg),
    (ctb_bytes([b'\x47', b'\x49']), @types.ImageFormat::Gif),
    (ctb_bytes([b'\x42', b'\x4D']), @types.ImageFormat::Bmp),
    (ctb_bytes([b'\x71', b'\x6F']), @types.ImageFormat::Qoi),
    (
      ctb_bytes([
        b'\x52', b'\x49', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x57',
        b'\x45', b'\x42', b'\x50',
      ]),
      @types.ImageFormat::Webp,
    ),
    (ctb_bytes([b'\x49', b'\x49']), @types.ImageFormat::Tiff),
    (ctb_bytes([b'\x4D', b'\x4D']), @types.ImageFormat::Tiff),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x01', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x00',
        b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
        b'\x00', b'\x00', b'\x00', b'\x00',
      ]),
      @types.ImageFormat::Ico,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x02', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x00',
        b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
        b'\x00', b'\x00', b'\x00', b'\x00',
      ]),
      @types.ImageFormat::Cur,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
        b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x18', b'\x00',
      ]),
      @types.ImageFormat::Tga,
    ),
    (ctb_bytes([b'\x23', b'\x3F']), @types.ImageFormat::Hdr),
    (ctb_bytes([b'\x50', b'\x31']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x50', b'\x32']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x50', b'\x33']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x50', b'\x34']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x50', b'\x35']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x50', b'\x36']), @types.ImageFormat::Pnm),
    (ctb_bytes([b'\x38', b'\x42']), @types.ImageFormat::Psd),
    (ctb_bytes([b'\x69', b'\x63']), @types.ImageFormat::Icns),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x61',
        b'\x76', b'\x69', b'\x66',
      ]),
      @types.ImageFormat::Avif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x6D',
        b'\x69', b'\x66', b'\x31',
      ]),
      @types.ImageFormat::Avif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x61',
        b'\x76', b'\x69', b'\x73',
      ]),
      @types.ImageFormat::Avif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x68',
        b'\x65', b'\x69', b'\x63',
      ]),
      @types.ImageFormat::Heif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x68',
        b'\x65', b'\x69', b'\x78',
      ]),
      @types.ImageFormat::Heif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x68',
        b'\x65', b'\x69', b'\x66',
      ]),
      @types.ImageFormat::Heif,
    ),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x0C', b'\x4A', b'\x58', b'\x4C', b'\x20',
      ]),
      @types.ImageFormat::JpegXl,
    ),
    (ctb_bytes([b'\xFF', b'\x0A']), @types.ImageFormat::JpegXl),
    (ctb_bytes([b'\x99', b'\x99']), @types.ImageFormat::Unknown),
    (ctb_bytes([b'\x89']), @types.ImageFormat::Unknown),
    (
      ctb_bytes([
        b'\x00', b'\x00', b'\x00', b'\x18', b'\x66', b'\x74', b'\x79', b'\x70', b'\x00',
        b'\x00', b'\x00', b'\x00',
      ]),
      @types.ImageFormat::Unknown,
    ),
  ]
  for (data, expected) in cases {
    assert_eq(@codec.codec_detect_format(data), expected)
  }
}

///|
test "codec_trait: decode 分派覆盖剩余格式" {
  let img = ctb_rgb(2, 2)
  let any = @types.AnyImage::U8(img)
  // HDR：U8 → F32 编码，解码回来仍是 F32
  let hdr_bytes = @codec.Codec::encode(@types.ImageFormat::Hdr, any)
  let hdr_back = @codec.Codec::decode(@types.ImageFormat::Hdr, hdr_bytes)
  assert_true(hdr_back is @types.AnyImage::F32(_))
  // ICO / CUR / ICNS / APNG
  let rest : Array[@types.ImageFormat] = [
    @types.ImageFormat::Ico,
    @types.ImageFormat::Cur,
    @types.ImageFormat::Icns,
    @types.ImageFormat::Apng,
  ]
  for f in rest {
    let bytes = @codec.Codec::encode(f, any)
    let back = @codec.Codec::decode(f, bytes)
    assert_true(back is @types.AnyImage::U8(_))
  }
}

///|
test "codec_trait: decode 失败分支" {
  let mut hits = 0
  // Unknown 格式
  try {
    let _ = @codec.Codec::decode(
      @types.ImageFormat::Unknown,
      ctb_bytes([b'\x00']),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => hits += 1
    _ => hits += 1
  }
  // PSD / AVIF / HEIF / JPEG-XL：给非法字节，只要求走进各自分支
  let thrown : Array[@types.ImageFormat] = [
    @types.ImageFormat::Psd,
    @types.ImageFormat::Avif,
    @types.ImageFormat::Heif,
    @types.ImageFormat::JpegXl,
  ]
  for f in thrown {
    try {
      let _ = @codec.Codec::decode(
        f,
        ctb_bytes([b'\x00', b'\x00', b'\x00', b'\x00']),
      )
    } catch {
      _ => hits += 1
    }
  }
  assert_eq(hits, 5)
}

///|
test "codec_trait: encode 失败分支" {
  let img = ctb_rgb(1, 1)
  let any = @types.AnyImage::U8(img)
  let mut hits = 0
  let not_encodable : Array[@types.ImageFormat] = [
    @types.ImageFormat::Psd,
    @types.ImageFormat::Avif,
    @types.ImageFormat::Heif,
    @types.ImageFormat::JpegXl,
    @types.ImageFormat::Unknown,
  ]
  for f in not_encodable {
    try {
      let _ = @codec.Codec::encode(f, any)
    } catch {
      @types.LoadError::EncodeFailed(_) => hits += 1
      _ => hits += 1
    }
  }
  assert_eq(hits, 5)
}
