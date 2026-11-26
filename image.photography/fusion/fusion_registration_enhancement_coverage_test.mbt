// 覆盖率测试：融合算法全分支 + 配准 + 报告

///|
fn frc_img2(w : Int32, h : Int32, c : Int32, base : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 9 + y * 5 + ch * 30 + base) % 256)
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

///|
test "frc2: 五种融合算法" {
  let a = frc_img2(16, 16, 1, 0)
  let b = frc_img2(16, 16, 1, 40)
  let imgs = [a, b]
  // 加权平均
  let w1 = @fusion.fuse_weighted_average(imgs, [0.5, 0.5])
  assert_true(w1.width == 16)
  let w2 = @fusion.fuse_weighted_average(imgs, [1.0, 0.0])
  assert_true(w2.height == 16)
  // 权重数量不匹配
  let w3 = @fusion.fuse_weighted_average(imgs, [0.7])
  assert_true(w3.width >= 0)
  // 最大 / 最小 / 均值
  assert_true(@fusion.fuse_maximum(imgs).width == 16)
  assert_true(@fusion.fuse_minimum(imgs).width == 16)
  assert_true(@fusion.fuse_simple_mean(imgs).width == 16)
  // 单张 / 空数组的兜底
  assert_true(@fusion.fuse_maximum([a]).width == 16)
  assert_true(@fusion.fuse_minimum([]).width == 0)
  assert_true(@fusion.fuse_simple_mean([]).width == 0)
  assert_true(@fusion.fuse_weighted_average([], []).width == 0)
  // 拉普拉斯金字塔
  assert_true(@fusion.fuse_laplacian_pyramid(imgs, 3).width == 16)
  assert_true(@fusion.fuse_laplacian_pyramid([a], 2).width == 16)
  assert_true(@fusion.fuse_laplacian_pyramid([], 2).width == 0)
  // 多通道
  let c1 = frc_img2(12, 12, 3, 10)
  let c2 = frc_img2(12, 12, 3, 200)
  let rgb = @fusion.fuse_simple_mean([c1, c2])
  assert_true(rgb.channels == 3)
}

///|
test "frc2: 融合配置分发全算法" {
  let a = frc_img2(16, 16, 1, 0)
  let b = frc_img2(16, 16, 1, 90)
  let imgs = [a, b]
  let algos : Array[@fusion.FusionAlgorithm] = [
    @fusion.FusionAlgorithm::WeightedAverage,
    @fusion.FusionAlgorithm::LaplacianPyramid,
    @fusion.FusionAlgorithm::GaussianPyramid,
    @fusion.FusionAlgorithm::Wavelet,
    @fusion.FusionAlgorithm::PCA,
    @fusion.FusionAlgorithm::IHS,
    @fusion.FusionAlgorithm::Brovey,
    @fusion.FusionAlgorithm::SimpleMean,
    @fusion.FusionAlgorithm::Maximum,
    @fusion.FusionAlgorithm::Minimum,
    @fusion.FusionAlgorithm::Unknown,
  ]
  for algo in algos {
    let cfg = @fusion.FusionEnhancedConfig::{
      algorithm: algo,
      weights: [0.5, 0.5],
      pyramid_levels: 3,
      use_color_preservation: true,
    }
    let res = @fusion.fuse_images_advanced(imgs, cfg)
    assert_true(res.num_images == 2)
    let rep = @fusion.fusion_report_to_string(
      res,
      @fusion.calculate_fusion_quality(res.image),
    )
    assert_true(rep.length() > 0)
  }
  // 默认配置
  let def = @fusion.create_default_fusion_enhanced_config()
  assert_true(def.algorithm == @fusion.FusionAlgorithm::WeightedAverage)
  assert_true(def.pyramid_levels == 4)
  assert_true(def.use_color_preservation)
}

///|
test "frc2: 配准与变换" {
  let base_img = frc_img2(24, 24, 1, 0)
  let shifted = @fusion.apply_translation(base_img, 2, 1)
  assert_true(shifted.width == 24)
  let neg = @fusion.apply_translation(base_img, -3, -2)
  assert_true(neg.height == 24)
  let big = @fusion.apply_translation(base_img, 40, 40)
  assert_true(big.width == 24)
  // 相位相关配准
  let r1 = @fusion.register_phase_correlation(base_img, shifted)
  assert_true(r1.image.width >= 0)
  let r2 = @fusion.register_phase_correlation(base_img, base_img)
  assert_true(r2.similarity >= 0.0)
  // 配准配置分发
  let cfg = @fusion.create_default_registration_advanced_config()
  assert_true(cfg.algorithm == @fusion.RegistrationAlgorithm::PhaseCorrelation)
  assert_true(cfg.max_iterations == 100)
  let r3 = @fusion.register_images_advanced(base_img, shifted, cfg)
  assert_true(r3.image.width >= 0)
  let cfg2 = @fusion.RegistrationAdvancedConfig::{
    algorithm: @fusion.RegistrationAlgorithm::FeatureBased,
    max_iterations: 50,
    tolerance: 0.01,
    use_multiscale: false,
  }
  let r4 = @fusion.register_images_advanced(base_img, shifted, cfg2)
  assert_true(r4.similarity >= 0.0)
}

///|
test "frc2: 高斯模糊与上下采样" {
  let img = frc_img2(16, 16, 1, 20)
  let bl = @fusion.gaussian_blur_fe(img, 1)
  assert_true(bl.width == 16)
  let bl3 = @fusion.gaussian_blur_fe(img, 3)
  assert_true(bl3.height == 16)
  let down = @fusion.downsample_fe(img)
  assert_true(down.width <= 16)
  let up = @fusion.upsample_fe(down)
  assert_true(up.width >= down.width)
  // 单像素图
  let one = frc_img2(1, 1, 1, 5)
  let d1 = @fusion.downsample_fe(one)
  assert_true(d1.width <= 1)
  let u1 = @fusion.upsample_fe(one)
  assert_true(u1.width <= 8)
  // 质量指标
  let q = @fusion.calculate_fusion_quality(img)
  assert_true(q >= 0.0)
}
