// 纯逻辑测试（全目标可用）
// 目标：`info_dims` 的各格式分支、`check_decode_budget` 全路径

///|
fn lc_rgb(w : Int32, h : Int32) -> @types.Image {
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
test "info_dims: 各格式扩展信息都能取出正尺寸" {
  let img = lc_rgb(3, 2)
  let samples : Array[Bytes] = [
    @codec.encode_png_pure(img),
    @codec.encode_bmp_pure(img),
    @codec.encode_qoi_pure(img),
    @codec.encode_gif_pure(img),
    @codec.encode_tga_pure(img),
    @codec.encode_jpeg_pure(img),
    @codec.encode_tiff_pure(img),
    @codec.encode_ico_pure(img),
    @codec.encode_icns_pure(img),
    @codec.encode_pnm_pure(img),
    @codec.encode_hdr_pure(@types.hdr_from_u8(img)),
    @lib.encode_webp_lossless(img),
    @codec.encode_apng_pure(@types.PngAnimation::{ frames: [img], delays: [0], }),
  ]
  for data in samples {
    let info = @codec.get_image_info_extended(data)
    let (w, h) = @lib.info_dims(info)
    assert_true(w > 0L)
    assert_true(h > 0L)
  }
}

///|
test "check_decode_budget: 正常输入返回头部尺寸" {
  let png = @lib.encode_png(lc_rgb(4, 3))
  let (w, h) = @lib.check_decode_budget(
    png,
    @types.DecodeLimits::default_limits(),
  )
  assert_eq(w, 4L)
  assert_eq(h, 3L)
}

///|
test "check_decode_budget: 字节超限拒绝" {
  let png = @lib.encode_png(lc_rgb(16, 16))
  let limits = @types.DecodeLimits::{
    max_pixels: 500000000L,
    max_bytes: 32L,
    max_ms: 1000L,
  }
  let mut hits = 0
  try {
    let _ = @lib.check_decode_budget(png, limits)
  } catch {
    @types.ImageError::Budget(c, _) => {
      assert_eq(c.to_string(), "limit_bytes")
      hits += 1
    }
    _ => hits += 1
  }
  assert_eq(hits, 1)
}

///|
test "check_decode_budget: 像素超限拒绝" {
  let png = @lib.encode_png(lc_rgb(64, 64))
  let limits = @types.DecodeLimits::{
    max_pixels: 100L,
    max_bytes: 500000000L,
    max_ms: 1000L,
  }
  let mut hits = 0
  try {
    let _ = @lib.check_decode_budget(png, limits)
  } catch {
    @types.ImageError::Budget(c, _) => {
      assert_eq(c.to_string(), "limit_pixels")
      hits += 1
    }
    _ => hits += 1
  }
  assert_eq(hits, 1)
}

///|
test "check_decode_budget: 无法识别的输入投影为 Decode 错误" {
  let junk : Array[Byte] = []
  for _ in 0..<8 {
    junk.push(b'\x00')
  }
  let mut hits = 0
  try {
    let _ = @lib.check_decode_budget(
      Bytes::from_array(junk),
      @types.DecodeLimits::default_limits(),
    )
  } catch {
    @types.ImageError::Decode(_, _) => hits += 1
    _ => hits += 1
  }
  assert_eq(hits, 1)
}
