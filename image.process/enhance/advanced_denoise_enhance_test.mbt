///|
fn ade_make_gray(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h) {
    data.push((i * 13 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "advanced_denoise: 均值/中值/高斯/双边滤波" {
  let img = ade_make_gray(8, 8)
  try {
    let mean = @enhance.mean_filter_denoise(img, 3)
    assert_eq(mean.width, 8)
    assert_eq(mean.height, 8)
    let median = @enhance.median_filter_denoise(img, 3)
    assert_eq(median.channels, 1)
    let gauss = @enhance.gaussian_filter_denoise(img, 3, 1.5)
    assert_eq(gauss.width, 8)
    let bilateral = @enhance.bilateral_filter_denoise(img, 3, 10.0, 10.0)
    assert_eq(bilateral.height, 8)
    assert_true(@enhance.calculate_noise_level(img) >= 0.0)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "advanced_enhance: 直方图/伽马/USM/统计" {
  let img = ade_make_gray(8, 8)
  try {
    assert_eq(@enhance.histogram_equalization_enhance(img).width, 8)
    assert_eq(@enhance.gamma_correction_enhance(img, 1.0).height, 8)
    assert_eq(@enhance.unsharp_mask_enhance(img, 1.0, 1).channels, 1)
    assert_true(@enhance.calculate_brightness(img) >= 0.0)
    assert_true(@enhance.calculate_contrast(img) >= 0.0)
    assert_true(@enhance.calculate_sharpness(img) >= 0.0)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "advanced_denoise: denoise_image 默认配置与报告" {
  let img = ade_make_gray(8, 8)
  let config = @enhance.create_default_denoise_config()
  try {
    let result = @enhance.denoise_image(img, config)
    assert_eq(result.image.width, 8)
    let text = @enhance.denoise_report_to_string(result)
    assert_true(text.length() > 0)
    assert_true(
      @enhance.denoise_algorithm_to_string(config.algorithm).length() > 0,
    )
  } catch {
    _ => assert_true(false)
  }
}
