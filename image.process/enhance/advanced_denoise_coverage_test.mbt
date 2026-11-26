// 纯逻辑测试（全目标可用）
// 目标：advanced_denoise_enhance 各入口的三类输入校验分支、denoise_image 算法分派、算法名映射

///|
fn adv_gray(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, fill)),
  }
}

///|
fn adv_zero() -> @types.Image {
  @types.Image::{
    width: 0,
    height: 2,
    channels: 1,
    data: Bytes::from_array([]),
  }
}

///|
fn adv_bad_channels() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 5,
    data: Bytes::from_array(Array::make(20, b'\x10')),
  }
}

///|
fn adv_bad_len() -> @types.Image {
  @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(Array::make(5, b'\x10')),
  }
}

///|
fn adv_bad_images() -> Array[@types.Image] {
  [adv_zero(), adv_bad_channels(), adv_bad_len()]
}

///|
test "advanced_denoise: 滤波入口三类输入校验" {
  let mut hits = 0
  for img in adv_bad_images() {
    try {
      let _ = @enhance.mean_filter_denoise(img, 3)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.median_filter_denoise(img, 3)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.gaussian_filter_denoise(img, 3, 1.0)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.bilateral_filter_denoise(img, 3, 10.0, 10.0)
    } catch {
      _ => hits += 1
    }
  }
  assert_eq(hits, 12)
}

///|
test "advanced_denoise: 增强入口三类输入校验" {
  let mut hits = 0
  for img in adv_bad_images() {
    try {
      let _ = @enhance.histogram_equalization_enhance(img)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.gamma_correction_enhance(img, 1.2)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.unsharp_mask_enhance(img, 0.5, 2)
    } catch {
      _ => hits += 1
    }
  }
  assert_eq(hits, 9)
}

///|
test "advanced_denoise: 统计入口三类输入校验" {
  let mut hits = 0
  for img in adv_bad_images() {
    try {
      let _ = @enhance.calculate_noise_level(img)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.calculate_brightness(img)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.calculate_contrast(img)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.calculate_sharpness(img)
    } catch {
      _ => hits += 1
    }
  }
  assert_eq(hits, 12)
}

///|
test "advanced_denoise: denoise_image 各算法分派 + 均匀图 PSNR 分支" {
  let img = adv_gray(8, 8, b'\x80')
  let algs : Array[@enhance.DenoiseAlgorithm] = [
    @enhance.DenoiseAlgorithm::MeanFilter,
    @enhance.DenoiseAlgorithm::MedianFilter,
    @enhance.DenoiseAlgorithm::GaussianFilter,
    @enhance.DenoiseAlgorithm::BilateralFilter,
    @enhance.DenoiseAlgorithm::NonLocalMeans,
  ]
  for a in algs {
    let cfg = @enhance.create_default_denoise_config()
    let c = @enhance.DenoiseConfig::{
      algorithm: a,
      strength: cfg.strength,
      kernel_size: 3,
      sigma_color: 10.0,
      sigma_space: 10.0,
      search_window: cfg.search_window,
      patch_size: cfg.patch_size,
      iterations: cfg.iterations,
    }
    let r = @enhance.denoise_image(img, c)
    assert_eq(r.image.width, 8)
    assert_true(r.psnr >= 0.0)
  }
  // 1×1 图降噪后必然与原图一致 → mse = 0 → psnr 走 100.0 分支
  let one = adv_gray(1, 1, b'\x80')
  let cfg1 = @enhance.create_default_denoise_config()
  let r1 = @enhance.denoise_image(one, cfg1)
  assert_eq(r1.psnr, 100.0)
}

///|
test "advanced_denoise: denoise_image / enhance_image_advanced 输入校验" {
  let cfg = @enhance.create_default_denoise_config()
  let mut hits = 0
  for img in adv_bad_images() {
    try {
      let _ = @enhance.denoise_image(img, cfg)
    } catch {
      _ => hits += 1
    }
    try {
      let _ = @enhance.enhance_image_advanced(
        img,
        @enhance.EnhancementAlgorithm::HistogramEqualization,
      )
    } catch {
      _ => hits += 1
    }
  }
  assert_eq(hits, 6)
}

///|
test "advanced_denoise: 算法名映射全枚举" {
  let names : Array[(@enhance.DenoiseAlgorithm, String)] = [
    (@enhance.DenoiseAlgorithm::MeanFilter, "均值滤波"),
    (@enhance.DenoiseAlgorithm::MedianFilter, "中值滤波"),
    (@enhance.DenoiseAlgorithm::GaussianFilter, "高斯滤波"),
    (@enhance.DenoiseAlgorithm::BilateralFilter, "双边滤波"),
    (@enhance.DenoiseAlgorithm::NonLocalMeans, "非局部均值"),
    (@enhance.DenoiseAlgorithm::WienerFilter, "维纳滤波"),
    (@enhance.DenoiseAlgorithm::TotalVariation, "全变分"),
    (@enhance.DenoiseAlgorithm::WaveletDenoise, "小波降噪"),
    (@enhance.DenoiseAlgorithm::BM3D, "BM3D"),
    (@enhance.DenoiseAlgorithm::DeepLearningDenoise, "深度学习降噪"),
    (@enhance.DenoiseAlgorithm::Unknown, "未知"),
  ]
  for (a, n) in names {
    assert_eq(@enhance.denoise_algorithm_to_string(a), n)
  }
}

///|
test "advanced_denoise: 降噪报告包含关键字段" {
  let img = adv_gray(6, 6, b'\x40')
  let cfg = @enhance.create_default_denoise_config()
  let r = @enhance.denoise_image(img, cfg)
  let text = @enhance.denoise_report_to_string(r)
  assert_true(text.contains("图像降噪报告"))
  assert_true(text.contains("PSNR"))
  assert_true(text.contains("降噪强度"))
}
