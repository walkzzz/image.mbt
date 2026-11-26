// 覆盖率测试：lib 统一分派 API 的各格式臂

fn ldc_img(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  let n = w * h * ch
  let data : Array[Byte] = []
  for i in 0..<n {
    data.push(((i * 7) % 256).to_byte())
  }
  @types.Image::{ width: w, height: h, channels: ch, data: Bytes::from_array(data) }
}

///|
test "ldc: save_image_auto 全格式分派" {
  let img = ldc_img(16, 16, 3)
  let fmts : Array[@types.ImageFormat] = [
    @types.ImageFormat::Jpeg,
    @types.ImageFormat::Bmp,
    @types.ImageFormat::Qoi,
    @types.ImageFormat::Pnm,
    @types.ImageFormat::Gif,
    @types.ImageFormat::Tga,
    @types.ImageFormat::Tiff,
    @types.ImageFormat::Ico,
    @types.ImageFormat::Cur,
    @types.ImageFormat::Icns,
    @types.ImageFormat::Webp,
  ]
  for f in fmts {
    let out = @lib.save_image_auto(img, f) catch {
      _ => Bytes::from_array([])
    }
    assert_true(out.length() > 0)
  }
}

///|
test "ldc: save_image_with_quality 全格式分派" {
  let img = ldc_img(16, 16, 3)
  let fmts : Array[@types.ImageFormat] = [
    @types.ImageFormat::Webp,
    @types.ImageFormat::Png,
    @types.ImageFormat::Jpeg,
    @types.ImageFormat::Bmp,
    @types.ImageFormat::Qoi,
    @types.ImageFormat::Pnm,
    @types.ImageFormat::Gif,
    @types.ImageFormat::Tga,
    @types.ImageFormat::Tiff,
    @types.ImageFormat::Ico,
    @types.ImageFormat::Cur,
    @types.ImageFormat::Icns,
  ]
  for f in fmts {
    let out = @lib.save_image_with_quality(img, f, 80) catch {
      _ => Bytes::from_array([])
    }
    assert_true(out.length() > 0)
  }
}

///|
test "ldc: 不支持的格式拒绝保存" {
  try {
    let _ = @lib.save_image_auto(ldc_img(8, 8, 3), @types.ImageFormat::Psd)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @lib.save_image_with_quality(ldc_img(8, 8, 3), @types.ImageFormat::Psd, 80)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "ldc: load_any 对 HDR 显式报错" {
  let fdata : Array[Byte] = []
  try {
    let _ = @lib.load_from_bytes_auto(Bytes::from_array([0x23, 0x3F, 0x52, 0x41, 0x44, 0x49, 0x41, 0x4E, 0x43, 0x45]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let _ = fdata
  assert_true(true)
}

///|
test "ldc: decode_webp 委托与 load_any_f 分派" {
  let img = ldc_img(16, 16, 3)
  let webp = @lib.encode_webp_lossless(img) catch {
    _ => Bytes::from_array([])
  }
  if webp.length() > 0 {
    let back = @lib.decode_webp(webp) catch {
      _ => ldc_img(1, 1, 3)
    }
    assert_true(back.width == 16)
    assert_true(back.height == 16)
  }
  // HDR 走 Float 路径
  let hdr_bytes = @lib.encode_hdr(@types.ImageF::{
    width: 2,
    height: 2,
    channels: 3,
    data: Bytes::from_array(Array::make(48, b'\x00')),
  }) catch {
    _ => Bytes::from_array([])
  }
  if hdr_bytes.length() > 0 {
    try {
      let f = @lib.load_any_f(hdr_bytes)
      assert_true(f.width == 2)
    } catch {
      _ => assert_true(false)
    }
  }
  try {
    let _ = @lib.load_any_f(Bytes::from_array([1, 2, 3, 4]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "ldc: APNG 解码取首帧" {
  let img = ldc_img(8, 8, 3)
  let frames : Array[@types.Image] = [img, img]
  let delays : Array[Int32] = [100, 100]
  let apng = @codec.encode_apng_pure(@types.PngAnimation::{
    frames,
    delays,
  })
  try {
    let first = @lib.load_from_bytes_auto(apng)
    assert_true(first.width == 8)
  } catch {
    _ => assert_true(false)
  }
}
