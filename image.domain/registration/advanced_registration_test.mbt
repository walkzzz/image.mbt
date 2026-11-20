///|
fn reg_make_gray(w : Int32, h : Int32, shift : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      data.push(((x * 9 + y * 7 + shift) % 256).to_byte())
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
test "registration: 相位相关/平移/相关性度量" {
  let a = reg_make_gray(8, 8, 0)
  let b = reg_make_gray(8, 8, 5)
  let p = @registration.phase_correlation_registration(a, b)
  assert_eq(p.registered_image.width, 8)
  let t = @registration.apply_translation(a, 1, 0)
  assert_eq(t.width, 8)
  assert_true(@registration.normalized_cross_correlation(a, a) > 0.0)
  assert_true(@registration.calculate_mutual_information(a, b) >= 0.0)
}

///|
test "registration: Harris 角点/匹配/仿射/高级配准" {
  let a = reg_make_gray(8, 8, 0)
  let b = reg_make_gray(8, 8, 5)
  let corners = @registration.detect_harris_corners(a, 1.0)
  let matches = @registration.match_feature_points(corners, corners, 10.0)
  let matrix = @registration.estimate_affine_transform(matches)
  let warped = @registration.apply_affine_transform(a, matrix)
  assert_eq(warped.width, 8)
  let cfg = @registration.create_default_registration_config_advanced()
  let fbr = @registration.feature_based_registration(a, b, cfg)
  assert_eq(fbr.registered_image.width, 8)
  let rr = @registration.register_images_advanced(a, b, cfg)
  let report = @registration.registration_report_to_string_advanced(rr)
  assert_true(report.length() > 0)
}
