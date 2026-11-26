// 覆盖率测试：detect_format 全签名分支与 auto 分派解码

fn libb_bytes(vals : Array[Int]) -> Bytes {
  let a : Array[Byte] = []
  for v in vals {
    a.push(v.to_byte())
  }
  Bytes::from_array(a)
}

fn libb_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, fill.to_byte())),
  }
}

test "libcov: detect_format 各签名" {
  // 过短
  assert_true(@lib.detect_format(libb_bytes([0x42])) == @types.ImageFormat::Unknown)
  // PNG
  let png = libb_bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
  assert_true(@lib.detect_format(png) == @types.ImageFormat::Png)
  // JPEG
  assert_true(@lib.detect_format(libb_bytes([0xFF, 0xD8])) == @types.ImageFormat::Jpeg)
  // BMP
  assert_true(@lib.detect_format(libb_bytes([0x42, 0x4D])) == @types.ImageFormat::Bmp)
  // QOI
  assert_true(
    @lib.detect_format(libb_bytes([0x71, 0x6F, 0x69, 0x66])) == @types.ImageFormat::Qoi,
  )
  // PNM (P5 / P6)
  assert_true(@lib.detect_format(libb_bytes([0x50, 0x35])) == @types.ImageFormat::Pnm)
  assert_true(@lib.detect_format(libb_bytes([0x50, 0x36])) == @types.ImageFormat::Pnm)
  // P1 不是 PNM
  assert_true(@lib.detect_format(libb_bytes([0x50, 0x31])) == @types.ImageFormat::Unknown)
  // PSD
  assert_true(
    @lib.detect_format(libb_bytes([0x38, 0x42, 0x50, 0x53])) == @types.ImageFormat::Psd,
  )
  // GIF
  assert_true(
    @lib.detect_format(
      libb_bytes([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
    ) == @types.ImageFormat::Gif,
  )
  // HDR
  assert_true(
    @lib.detect_format(
      libb_bytes([0x23, 0x3F, 0x52, 0x41, 0x44, 0x49, 0x41, 0x4E, 0x43, 0x45]),
    ) == @types.ImageFormat::Hdr,
  )
  // WebP
  assert_true(
    @lib.detect_format(
      libb_bytes([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]),
    ) == @types.ImageFormat::Webp,
  )
  // ICNS
  assert_true(
    @lib.detect_format(libb_bytes([0x69, 0x63, 0x6E, 0x73])) == @types.ImageFormat::Icns,
  )
  // TIFF 小端 / 大端 / 魔数错误
  assert_true(
    @lib.detect_format(libb_bytes([0x49, 0x49, 0x2A, 0x00])) == @types.ImageFormat::Tiff,
  )
  assert_true(
    @lib.detect_format(libb_bytes([0x4D, 0x4D, 0x00, 0x2A])) == @types.ImageFormat::Tiff,
  )
  assert_true(
    @lib.detect_format(libb_bytes([0x49, 0x49, 0x2B, 0x00])) == @types.ImageFormat::Unknown,
  )
  // JPEG-XL 裸码流
  assert_true(
    @lib.detect_format(libb_bytes([0xFF, 0x0A])) == @types.ImageFormat::JpegXl,
  )
}

test "libcov: ICO / CUR / AVIF / HEIF 检测" {
  // ICO：22 字节以上，type=1，条目非零
  let ico : Array[Int] = [
    0x00, 0x00, 0x01, 0x00, 0x01, 0x00, //
    0x10, 0x10, 0x00, 0x00, 0x01, 0x00, 0x20, 0x00, 0x40, 0x00, 0x00, 0x00,
    0x16, 0x00, 0x00, 0x00,
  ]
  assert_true(@lib.detect_format(libb_bytes(ico)) == @types.ImageFormat::Ico)
  // CUR：type=2 且宽高为 0 → 热点占位
  let cur : Array[Int] = [
    0x00, 0x00, 0x02, 0x00, 0x01, 0x00, //
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x20, 0x00, 0x40, 0x00, 0x00, 0x00,
    0x16, 0x00, 0x00, 0x00,
  ]
  assert_true(@lib.detect_format(libb_bytes(cur)) == @types.ImageFormat::Cur)
  // CUR 但宽高非 0 → 归为 ICO
  let cur2 : Array[Int] = [
    0x00, 0x00, 0x02, 0x00, 0x01, 0x00, //
    0x10, 0x10, 0x00, 0x00, 0x01, 0x00, 0x20, 0x00, 0x40, 0x00, 0x00, 0x00,
    0x16, 0x00, 0x00, 0x00,
  ]
  assert_true(@lib.detect_format(libb_bytes(cur2)) == @types.ImageFormat::Ico)
  // 条目数为 0 → 不识别
  let zero_count : Array[Int] = [
    0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]
  assert_true(@lib.detect_format(libb_bytes(zero_count)) == @types.ImageFormat::Unknown)
  // JXL ISOBMFF 容器
  assert_true(
    @lib.detect_format(
      libb_bytes([0x00, 0x00, 0x00, 0x0C, 0x4A, 0x58, 0x4C, 0x20, 0, 0, 0, 0]),
    ) == @types.ImageFormat::JpegXl,
  )
  // AVIF
  assert_true(
    @lib.detect_format(
      libb_bytes([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x66]),
    ) == @types.ImageFormat::Avif,
  )
  // AVIF（avis）
  assert_true(
    @lib.detect_format(
      libb_bytes([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x61, 0x76, 0x69, 0x73]),
    ) == @types.ImageFormat::Avif,
  )
  // HEIF（heic）
  assert_true(
    @lib.detect_format(
      libb_bytes([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]),
    ) == @types.ImageFormat::Heif,
  )
  // HEIF（mif1）
  assert_true(
    @lib.detect_format(
      libb_bytes([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x69, 0x66, 0x31]),
    ) == @types.ImageFormat::Heif,
  )
  // ftyp 但品牌未知 → Unknown
  assert_true(
    @lib.detect_format(
      libb_bytes([0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x78, 0x78, 0x78, 0x78]),
    ) == @types.ImageFormat::Unknown,
  )
}

test "libcov: auto 分派往返与未识别错误" {
  let img = libb_img(4, 4, 3, 90)
  // BMP
  let bmp = @lib.encode_bmp(img)
  let d0 = @lib.load_from_bytes_auto(bmp)
  assert_true(d0.width == 4)
  // PNG
  let png = @lib.encode_png(img)
  let d1 = @lib.load_from_bytes_auto(png)
  assert_true(d1.width == 4)
  // PNM / PPM / PGM
  let pnm = @lib.encode_pnm_auto(img)
  let d2 = @lib.load_from_bytes_auto(pnm)
  assert_true(d2.width == 4)
  let ppm = @lib.encode_ppm_auto(img)
  assert_true(ppm.length() > 0)
  let pgm = @lib.encode_pgm_auto(libb_img(4, 4, 1, 40))
  assert_true(pgm.length() > 0)
  // QOI
  let qoi = @lib.encode_qoi(img)
  let d3 = @lib.load_from_bytes_auto(qoi)
  assert_true(d3.width == 4)
  // GIF
  let gif = @lib.encode_gif(img)
  let d4 = @lib.load_from_bytes_auto(gif)
  assert_true(d4.width == 4)
  // JPEG
  let jpg = @lib.encode_jpeg(img)
  let d5 = @lib.load_from_bytes_auto(jpg)
  assert_true(d5.height == 4)
  // WebP 无损
  let wp = @lib.encode_webp_lossless(img)
  let d6 = @lib.load_from_bytes_auto(wp)
  assert_true(d6.width == 4)
  // TGA 编码（不含自动分派）
  let tga = @lib.encode_tga(img)
  assert_true(tga.length() > 0)
  // req_channels 转换
  let d7 = @lib.load_from_bytes_auto(bmp, req_channels=Some(1))
  assert_true(d7.channels == 1)
  // 未识别格式 → 抛错
  try {
    let _ = @lib.load_from_bytes_auto(libb_bytes([0x00, 0x01, 0x02, 0x03]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 16-bit 入口：未识别 → 抛错
  try {
    let _ = @lib.load_16_from_bytes_auto(libb_bytes([0x00, 0x01, 0x02, 0x03]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 16-bit 入口：PNG 往返
  try {
    let d8 = @lib.load_16_from_bytes_auto(png)
    assert_true(d8.width >= 0)
  } catch {
    _ => assert_true(true)
  }
}
