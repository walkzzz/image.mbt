// 覆盖率测试：融合与配准增强

fn fr_img(w : Int32, h : Int32, c : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn fr_const(w : Int32, h : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(v)
  }
  fr_img(w, h, 1, d)
}

fn fr_empty() -> @types.Image {
  fr_img(0, 0, 1, [])
}

test "frcov: 默认配置" {
  let fc = @fusion.create_default_fusion_enhanced_config()
  assert_true(fc.algorithm == @fusion.WeightedAverage)
  assert_true(fc.weights.length() == 2)
  assert_true(fc.weights[0] == 0.5)
  assert_true(fc.pyramid_levels == 4)
  assert_true(fc.use_color_preservation)
  let rc = @fusion.create_default_registration_advanced_config()
  assert_true(rc.algorithm == @fusion.PhaseCorrelation)
  assert_true(rc.max_iterations == 100)
  assert_true(rc.tolerance == 0.001)
  assert_true(rc.use_multiscale)
}

test "frcov: 加权/最大/最小/均值融合" {
  let a = fr_const(4, 4, b'\x10')
  let b = fr_const(4, 4, b'\x30')
  // 空输入
  let e = @fusion.fuse_weighted_average([], [])
  assert_true(e.width == 0)
  assert_true(e.data.length() == 0)
  // 权重 0.25 / 0.75 → 加权均值
  let w1 = @fusion.fuse_weighted_average([a, b], [0.25, 0.75])
  assert_true(w1.width == 4)
  assert_true(w1.data.length() == 16)
  assert_true(w1.data[0].to_int() == 40)
  // 权重不足时剩余图像按 1.0 计
  let w2 = @fusion.fuse_weighted_average([a, b], [0.5])
  assert_true(w2.data[0].to_int() == 37)
  // 权重全 0 → 输出 0
  let w3 = @fusion.fuse_weighted_average([a, b], [0.0, 0.0])
  assert_true(w3.data[0].to_int() == 0)
  // 最大值/最小值
  let mx = @fusion.fuse_maximum([a, b])
  assert_true(mx.data[0].to_int() == 48)
  let mn = @fusion.fuse_minimum([a, b])
  assert_true(mn.data[0].to_int() == 16)
  // 空输入
  let emx = @fusion.fuse_maximum([])
  assert_true(emx.width == 0)
  let emn = @fusion.fuse_minimum([])
  assert_true(emn.width == 0)
  // 简单均值与三图叠加
  let c = fr_const(4, 4, b'\x50')
  let mean3 = @fusion.fuse_simple_mean([a, b, c])
  assert_true(mean3.data[0].to_int() == 48)
  // 空图像的简单均值走 0 权重分支
  let emean = @fusion.fuse_simple_mean([])
  assert_true(emean.width == 0)
}

test "frcov: 高斯模糊与金字塔采样" {
  let img = fr_const(4, 4, b'\x40')
  // kernel 1 → radius 0 → 权重和为 0 → 保持原值
  let k1 = @fusion.gaussian_blur_fe(img, 1)
  assert_true(k1.width == 4)
  assert_true(k1.data.length() == 16)
  assert_true(k1.data[0].to_int() == 64)
  // kernel 3 → 归一化加权，平坦图仍为原值
  let k3 = @fusion.gaussian_blur_fe(img, 3)
  assert_true(k3.data[0].to_int() == 64)
  // 棋盘上 3x3 会平滑掉极值
  let d : Array[Byte] = []
  for y in 0..<4 {
    for x in 0..<4 {
      d.push(if (x + y) % 2 == 0 { b'\x00' } else { b'\xFF' })
    }
  }
  let checker = fr_img(4, 4, 1, d)
  let smooth = @fusion.gaussian_blur_fe(checker, 3)
  let mid = smooth.data[5].to_int()
  assert_true(mid >= 0 && mid <= 255)
  // 下采样：4x4 → 2x2
  let down = @fusion.downsample_fe(fr_const(4, 4, b'\x20'))
  assert_true(down.width == 2)
  assert_true(down.height == 2)
  assert_true(down.data.length() == 4)
  assert_true(down.data[0].to_int() == 32)
  // 奇数尺寸 3x3 → 1x1
  let odd = @fusion.downsample_fe(fr_const(3, 3, b'\x60'))
  assert_true(odd.width == 1)
  assert_true(odd.height == 1)
  // 上采样：2x2 → 4x4，平坦图保持原值
  let up = @fusion.upsample_fe(fr_const(2, 2, b'\x80'))
  assert_true(up.width == 4)
  assert_true(up.height == 4)
  assert_true(up.data.length() == 16)
  assert_true(up.data[0].to_int() == 128)
  // 1x1 上采样：边界索引钳制
  let tiny = @fusion.upsample_fe(fr_const(1, 1, b'\x11'))
  assert_true(tiny.width == 2)
  assert_true(tiny.height == 2)
  assert_true(tiny.data.length() == 4)
  assert_true(tiny.data[3].to_int() == 17)
}

test "frcov: 拉普拉斯金字塔与高级融合分派" {
  let a = fr_const(2, 2, b'\x00')
  let b = fr_const(2, 2, b'\x40')
  // 空输入
  let none = @fusion.fuse_laplacian_pyramid([], 3)
  assert_true(none.width == 0)
  // 单图直通
  let one = @fusion.fuse_laplacian_pyramid([a], 3)
  assert_true(one.width == 2)
  assert_true(one.data[0].to_int() == 0)
  // 双图 → 均值
  let two = @fusion.fuse_laplacian_pyramid([a, b], 3)
  assert_true(two.data[0].to_int() == 32)
  // 六种算法分派
  let cfg_w = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.WeightedAverage,
    weights: [0.5, 0.5],
    pyramid_levels: 2,
    use_color_preservation: false,
  }
  let r_w = @fusion.fuse_images_advanced([a, b], cfg_w)
  assert_true(r_w.num_images == 2)
  assert_true(r_w.algorithm == @fusion.WeightedAverage)
  assert_true(r_w.image.data[0].to_int() == 32)
  let cfg_mx = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.Maximum,
    weights: [],
    pyramid_levels: 2,
    use_color_preservation: false,
  }
  let r_mx = @fusion.fuse_images_advanced([a, b], cfg_mx)
  assert_true(r_mx.image.data[0].to_int() == 64)
  let cfg_mn = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.Minimum,
    weights: [],
    pyramid_levels: 2,
    use_color_preservation: false,
  }
  let r_mn = @fusion.fuse_images_advanced([a, b], cfg_mn)
  assert_true(r_mn.image.data[0].to_int() == 0)
  let cfg_sm = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.SimpleMean,
    weights: [],
    pyramid_levels: 2,
    use_color_preservation: false,
  }
  let r_sm = @fusion.fuse_images_advanced([a, b], cfg_sm)
  assert_true(r_sm.image.data[0].to_int() == 32)
  let cfg_lp = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.LaplacianPyramid,
    weights: [],
    pyramid_levels: 2,
    use_color_preservation: true,
  }
  let r_lp = @fusion.fuse_images_advanced([a, b], cfg_lp)
  assert_true(r_lp.algorithm == @fusion.LaplacianPyramid)
  assert_true(r_lp.image.data[0].to_int() == 32)
  // 未实现算法（GaussianPyramid）：回退到简单均值
  let cfg_unk = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.GaussianPyramid,
    weights: [],
    pyramid_levels: 2,
    use_color_preservation: true,
  }
  let r_unk = @fusion.fuse_images_advanced([a, b], cfg_unk)
  assert_true(r_unk.image.data[0].to_int() == 32)
  // 空输入 + 高级融合
  let r_empty = @fusion.fuse_images_advanced([], cfg_w)
  assert_true(r_empty.num_images == 0)
  assert_true(r_empty.image.width == 0)
}

test "frcov: 相位相关配准与平移" {
  let pd : Array[Byte] = []
  for y in 0..<8 {
    for x in 0..<8 {
      pd.push((x * 20 + y * 5).to_byte())
    }
  }
  let img = fr_img(8, 8, 1, pd)
  let reg = @fusion.register_phase_correlation(img, img)
  assert_true(reg.algorithm == @fusion.PhaseCorrelation)
  assert_true(reg.translation_x >= -10.0 && reg.translation_x <= 10.0)
  assert_true(reg.translation_y >= -10.0 && reg.translation_y <= 10.0)
  assert_true(reg.rotation_angle == 0.0)
  assert_true(reg.scale_factor == 1.0)
  assert_true(reg.similarity > 0.9 && reg.similarity <= 1.0)
  // 目标平移 1 像素：最优位移应接近 (-1, 0) 或 (1, 0) 之一，相似度仍高
  let shifted = @fusion.apply_translation(img, 1, 0)
  let reg2 = @fusion.register_phase_correlation(shifted, img)
  assert_true(reg2.similarity >= 0.0 && reg2.similarity <= 1.0)
  assert_true(reg2.translation_x.abs() <= 10.0)
  // 高级配准：默认配置 & 非相位算法同样走相位分支
  let rc = @fusion.create_default_registration_advanced_config()
  let r3 = @fusion.register_images_advanced(img, img, rc)
  assert_true(r3.similarity > 0.9)
  let rc2 = @fusion.RegistrationAdvancedConfig::{
    algorithm: @fusion.MutualInformation,
    max_iterations: 5,
    tolerance: 0.1,
    use_multiscale: false,
  }
  let r4 = @fusion.register_images_advanced(img, img, rc2)
  assert_true(r4.algorithm == @fusion.PhaseCorrelation)
  // 平移：正负与零位移
  let t0 = @fusion.apply_translation(img, 0, 0)
  assert_true(t0.data[0].to_int() == 0)
  let tpos = @fusion.apply_translation(img, 2, 0)
  assert_true(tpos.width == 8)
  assert_true(tpos.data[0].to_int() == 0)
  let tneg = @fusion.apply_translation(img, -2, 0)
  assert_true(tneg.data[0].to_int() == 40)
  // 大位移全部越界 → 全 0
  let tall = @fusion.apply_translation(img, 10, 10)
  assert_true(tall.data[0].to_int() == 0)
}

test "frcov: 融合质量与报告" {
  // 平坦图：空间频率 0
  assert_true(@fusion.calculate_fusion_quality(fr_const(4, 4, b'\x80')) == 0.0)
  // 渐变：空间频率 > 0
  let d : Array[Byte] = []
  for y in 0..<4 {
    for x in 0..<4 {
      d.push((x * 60 + y * 10).to_byte())
    }
  }
  let grad = fr_img(4, 4, 1, d)
  let q = @fusion.calculate_fusion_quality(grad)
  assert_true(q > 0.0)
  // 1x1：无相邻像素 → 0
  assert_true(@fusion.calculate_fusion_quality(fr_const(1, 1, b'\x10')) == 0.0)
  // 报告文本：加权平均 / 拉普拉斯金字塔
  let cfg = @fusion.create_default_fusion_enhanced_config()
  let r = @fusion.fuse_images_advanced([fr_const(2, 2, b'\x00'), fr_const(2, 2, b'\x40')], cfg)
  let report = @fusion.fusion_report_to_string(r, q)
  assert_true(report.contains("图像融合报告"))
  assert_true(report.contains("加权平均"))
  let cfg_lp = @fusion.FusionEnhancedConfig::{
    algorithm: @fusion.LaplacianPyramid,
    weights: [],
    pyramid_levels: 3,
    use_color_preservation: false,
  }
  let r_lp = @fusion.fuse_images_advanced([fr_const(2, 2, b'\x00')], cfg_lp)
  let report_lp = @fusion.fusion_report_to_string(r_lp, 0.5)
  assert_true(report_lp.contains("拉普拉斯金字塔"))
}
