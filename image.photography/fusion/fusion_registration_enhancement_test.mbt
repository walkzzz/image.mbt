///|
fn fuse_make_rgb(w : Int32, h : Int32, base : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 5 + base) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "fusion: 基础融合算子" {
  let a = fuse_make_rgb(8, 8, 0)
  let b = fuse_make_rgb(8, 8, 30)
  let f1 = @fusion.fuse_weighted_average([a, b], [0.5, 0.5])
  assert_eq(f1.width, 8)
  assert_eq(f1.channels, 3)
  let f2 = @fusion.fuse_maximum([a, b])
  assert_eq(f2.width, 8)
  let f3 = @fusion.fuse_minimum([a, b])
  assert_eq(f3.height, 8)
  let f4 = @fusion.fuse_simple_mean([a, b])
  assert_eq(f4.channels, 3)
}

///|
test "fusion: 金字塔与高级融合" {
  let a = fuse_make_rgb(8, 8, 10)
  let b = fuse_make_rgb(8, 8, 70)
  let blur = @fusion.gaussian_blur_fe(a, 3)
  assert_eq(blur.width, 8)
  let down = @fusion.downsample_fe(a)
  let up = @fusion.upsample_fe(down)
  assert_true(up.width > 0)
  let lap = @fusion.fuse_laplacian_pyramid([a, b], 2)
  assert_eq(lap.channels, 3)
  let cfg = @fusion.create_default_fusion_enhanced_config()
  let res = @fusion.fuse_images_advanced([a, b], cfg)
  let q = @fusion.calculate_fusion_quality(res.image)
  assert_true(q >= 0.0)
  let text = @fusion.fusion_report_to_string(res, q)
  assert_true(text.length() > 0)
}

///|
test "fusion: 相位相关配准与平移" {
  let a = fuse_make_rgb(8, 8, 0)
  let b = fuse_make_rgb(8, 8, 20)
  let r1 = @fusion.register_phase_correlation(a, b)
  assert_eq(r1.image.width, 8)
  let cfg = @fusion.create_default_registration_advanced_config()
  let r2 = @fusion.register_images_advanced(a, b, cfg)
  assert_eq(r2.image.width, 8)
  let shifted = @fusion.apply_translation(a, 1, 1)
  assert_eq(shifted.width, 8)
  assert_eq(shifted.channels, 3)
}
