// 覆盖率测试：超分辨率增强（插值 / 锐化 / 去噪 / 指标 / 报告）

///|
fn sr_img(w : Int32, h : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn sr_flat(w : Int32, h : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(v)
  }
  sr_img(w, h, d)
}

///|
fn sr_grad(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(((x * 10 + y * 20) % 256).to_byte())
    }
  }
  sr_img(w, h, d)
}

///|
fn sr_cfg(
  algo : @superres.SuperResolutionAlgorithm,
  scale : Double,
) -> @superres.InterpolationConfig {
  @superres.InterpolationConfig::{
    algorithm: algo,
    scale_factor: scale,
    use_edge_preservation: true,
    sharpening_strength: 0.0,
    denoise_strength: 0.0,
  }
}

///|
fn sr_enh(
  brightness : Double,
  contrast : Double,
  gamma : Double,
  denoise : Double,
  sharpness : Double,
) -> @superres.EnhancementConfig {
  @superres.EnhancementConfig::{
    brightness,
    contrast,
    saturation: 1.0,
    sharpness,
    denoise,
    gamma,
    use_clahe: false,
    clahe_clip_limit: 2.0,
    clahe_tile_size: 8,
  }
}

///|
test "srcov: 默认配置" {
  let ic = @superres.create_default_interpolation_config()
  assert_true(ic.algorithm == @superres.SuperResolutionAlgorithm::Bicubic)
  assert_true(ic.scale_factor == 2.0)
  assert_true(ic.use_edge_preservation)
  assert_true(ic.sharpening_strength == 0.3)
  assert_true(ic.denoise_strength == 0.1)
  let ec = @superres.create_default_enhancement_config()
  assert_true(ec.brightness == 0.0)
  assert_true(ec.contrast == 1.0)
  assert_true(ec.gamma == 1.0)
  assert_true(!ec.use_clahe)
  assert_true(ec.clahe_tile_size == 8)
}

///|
test "srcov: 最近邻插值" {
  let img = sr_img(2, 2, [b'\x0A', b'\x14', b'\x1E', b'\x28'])
  let up = @superres.nearest_neighbor_interpolate(img, 2.0)
  assert_true(up.width == 4)
  assert_true(up.height == 4)
  assert_true(up.channels == 1)
  assert_true(up.data[0].to_int() == 10)
  assert_true(up.data[1].to_int() == 10)
  assert_true(up.data[2].to_int() == 20)
  assert_true(up.data[4].to_int() == 10)
  assert_true(up.data[6].to_int() == 20)
  assert_true(up.data[8].to_int() == 30)
  assert_true(up.data[10].to_int() == 40)
  // scale 1 → 原样
  let same = @superres.nearest_neighbor_interpolate(img, 1.0)
  assert_true(same.width == 2)
  assert_true(same.data[3].to_int() == 40)
  // scale 0.5 → 1x1（取左上）
  let down = @superres.nearest_neighbor_interpolate(img, 0.5)
  assert_true(down.width == 1)
  assert_true(down.height == 1)
  assert_true(down.data[0].to_int() == 10)
  // 平坦图：放大后仍平坦
  let flat = sr_flat(2, 2, b'\x64')
  let fu = @superres.nearest_neighbor_interpolate(flat, 3.0)
  assert_true(fu.width == 6)
  assert_true(fu.data[0].to_int() == 100)
  assert_true(fu.data[35].to_int() == 100)
}

///|
test "srcov: 双线性插值" {
  let img = sr_img(2, 2, [b'\x0A', b'\x14', b'\x1E', b'\x28'])
  let up = @superres.bilinear_interpolate(img, 2.0)
  assert_true(up.width == 4)
  // (0,0) 取原像素
  assert_true(up.data[0].to_int() == 10)
  // x=1 采样 0.5 → (10+20)/2 = 15
  assert_true(up.data[1].to_int() == 15)
  // (3,3) 采样 (1.5,1.5) → 钳到 (1,1) → 40
  assert_true(up.data[15].to_int() == 40)
  // 平坦图保持值
  let flat = sr_flat(2, 2, b'\x80')
  let fu = @superres.bilinear_interpolate(flat, 2.0)
  assert_true(fu.data[5].to_int() == 128)
}

///|
test "srcov: 双三次插值（简化）" {
  let img = sr_img(2, 2, [b'\x0A', b'\x14', b'\x1E', b'\x28'])
  let up = @superres.bicubic_interpolate(img, 2.0)
  assert_true(up.width == 4)
  assert_true(up.height == 4)
  assert_true(up.data.length() == 16)
  // x=1 处采样 0.5，仍插出 15
  assert_true(up.data[1].to_int() == 15)
  // 平坦图
  let flat = sr_flat(3, 3, b'\x40')
  let fu = @superres.bicubic_interpolate(flat, 2.0)
  assert_true(fu.width == 6)
  assert_true(fu.data[0].to_int() == 64)
  assert_true(fu.data[35].to_int() == 64)
}

///|
test "srcov: 锐化" {
  // 中心 200，周围 100
  let img = sr_img(3, 3, [
    b'\x64', b'\x64', b'\x64', b'\x64', b'\xC8', b'\x64', b'\x64', b'\x64', b'\x64',
  ])
  let s = @superres.sharpen_image(img, 0.5)
  // 中心：200 + 0.5*(200-100) = 250
  assert_true(s.data[4].to_int() == 250)
  // 角点：邻居平均 (100+100+200)/3 = 133.33 → 100 + 0.5*(-33.33) = 83.33 → 83
  assert_true(s.data[0].to_int() == 83)
  // strength 0 → 原值
  let s0 = @superres.sharpen_image(img, 0.0)
  assert_true(s0.data[4].to_int() == 200)
  // 平坦图不变
  let flat = sr_flat(3, 3, b'\x32')
  let sf = @superres.sharpen_image(flat, 2.0)
  assert_true(sf.data[4].to_int() == 50)
}

///|
test "srcov: 去噪" {
  let img = sr_img(3, 3, [
    b'\x64', b'\x64', b'\x64', b'\x64', b'\xC8', b'\x64', b'\x64', b'\x64', b'\x64',
  ])
  // strength <= 0.5 → 核 1 → 原样
  let d0 = @superres.denoise_image(img, 0.3)
  assert_true(d0.data[4].to_int() == 200)
  // strength 0.9 → 3x3 均值 100，混合 200*0.1 + 100*0.9 = 110
  let d9 = @superres.denoise_image(img, 0.9)
  assert_true(d9.data[4].to_int() == 120)
  // 角点：邻域 4 像素 (100,100,100,200) 均值 125 → 100*0.1+125*0.9 = 122.5 → 122
  assert_true(d9.data[0].to_int() == 122)
  // 平坦图不变
  let flat = sr_flat(3, 3, b'\x64')
  let df = @superres.denoise_image(flat, 1.0)
  assert_true(df.data[0].to_int() == 100)
}

///|
test "srcov: 超分辨率主流程" {
  let img = sr_grad(3, 3)
  let r_nn = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::NearestNeighbor, 2.0),
  )
  assert_true(r_nn.output_width == 6)
  assert_true(r_nn.output_height == 6)
  assert_true(r_nn.original_width == 3)
  assert_true(r_nn.scale_factor == 2.0)
  assert_true(
    r_nn.algorithm == @superres.SuperResolutionAlgorithm::NearestNeighbor,
  )
  assert_true(r_nn.psnr == 0.0)
  // Bilinear 分支
  let r_bl = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Bilinear, 2.0),
  )
  assert_true(r_bl.output_width == 6)
  assert_true(r_bl.algorithm == @superres.SuperResolutionAlgorithm::Bilinear)
  // Lanczos 走回退（双三次）
  let r_lz = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Lanczos, 2.0),
  )
  assert_true(r_lz.output_width == 6)
  assert_true(r_lz.algorithm == @superres.SuperResolutionAlgorithm::Lanczos)
  // 去噪 + 锐化同时开启
  let with_all = @superres.InterpolationConfig::{
    algorithm: @superres.SuperResolutionAlgorithm::Bicubic,
    scale_factor: 2.0,
    use_edge_preservation: true,
    sharpening_strength: 0.5,
    denoise_strength: 0.9,
  }
  let r_all = @superres.super_resolve(img, with_all)
  assert_true(r_all.output_width == 6)
  // 平坦图放大后仍平坦
  let flat = sr_flat(2, 2, b'\x80')
  let r_flat = @superres.super_resolve(
    flat,
    sr_cfg(@superres.SuperResolutionAlgorithm::Bicubic, 2.0),
  )
  assert_true(
    r_flat.image.data[3].to_int() == 128 || r_flat.image.data[3].to_int() >= 120,
  )
}

///|
test "srcov: PSNR / SSIM / 质量指标" {
  let a = sr_flat(4, 4, b'\x00')
  let b = sr_flat(4, 4, b'\x64')
  // 相同 → PSNR 100
  assert_true(@superres.calculate_psnr_sr(a, a) == 100.0)
  // 差 100 → mse 10000 → 10*(65025/10000)*0.1 = 6.5025
  assert_true(
    @superres.calculate_psnr_sr(a, b) > 6.4 &&
    @superres.calculate_psnr_sr(a, b) < 6.6,
  )
  // 相同 → SSIM 1
  let s_same = @superres.calculate_ssim_sr(a, a)
  assert_true(s_same > 0.99)
  let s_diff = @superres.calculate_ssim_sr(a, b)
  assert_true(s_diff < 0.1)
  // 指标（相同 → 满分）
  let m_same = @superres.calculate_image_quality_metrics(a, a)
  assert_true(m_same.mse == 0.0)
  assert_true(m_same.mae == 0.0)
  assert_true(m_same.psnr == 100.0)
  assert_true(m_same.noise_level == 0.0)
  assert_true(m_same.overall_quality == 5.0)
  // 平坦图相关性 0
  assert_true(m_same.correlation == 0.0)
  // 不同 → 低分
  let m_diff = @superres.calculate_image_quality_metrics(a, b)
  assert_true(m_diff.mse > 0.0)
  assert_true(m_diff.mae > 0.0)
  assert_true(m_diff.overall_quality == 2.0)
  assert_true(m_diff.correlation == 0.0)
  // 有梯度 → 清晰度 > 0 + 相关性 > 0
  let g1 = sr_grad(4, 4)
  let m_grad = @superres.calculate_image_quality_metrics(g1, g1)
  assert_true(m_grad.sharpness > 0.0)
  assert_true(m_grad.correlation > 0.0)
}

///|
test "srcov: 图像增强" {
  let img = sr_flat(4, 4, b'\x64')
  // 亮度 +0.5 → 100 + 127.5 = 227
  let b = @superres.enhance_image(img, sr_enh(0.5, 1.0, 1.0, 0.0, 0.0))
  assert_true(b.data[0].to_int() == 227)
  // 亮度 -1 → 负 → 钳 0
  let b0 = @superres.enhance_image(img, sr_enh(-1.0, 1.0, 1.0, 0.0, 0.0))
  assert_true(b0.data[0].to_int() == 0)
  // 对比度 2 → (100-128)*2+128 = 72
  let c = @superres.enhance_image(img, sr_enh(0.0, 2.0, 1.0, 0.0, 0.0))
  assert_true(c.data[0].to_int() == 72)
  // gamma 2 → 255*(100/255)*0.5 = 50
  let g = @superres.enhance_image(img, sr_enh(0.0, 1.0, 2.0, 0.0, 0.0))
  assert_true(g.data[0].to_int() == 50)
  // gamma 0 跳过
  let g0 = @superres.enhance_image(img, sr_enh(0.0, 1.0, 0.0, 0.0, 0.0))
  assert_true(g0.data[0].to_int() == 100)
  // 默认配置 → 原图
  let d = @superres.enhance_image(
    img,
    @superres.create_default_enhancement_config(),
  )
  assert_true(d.data[0].to_int() == 100)
  // 去噪 + 锐化分支
  let noisy = sr_img(3, 3, [
    b'\x64', b'\x64', b'\x64', b'\x64', b'\xC8', b'\x64', b'\x64', b'\x64', b'\x64',
  ])
  let dn = @superres.enhance_image(noisy, sr_enh(0.0, 1.0, 1.0, 0.9, 0.0))
  assert_true(dn.data[4].to_int() == 120)
  let sh = @superres.enhance_image(noisy, sr_enh(0.0, 1.0, 1.0, 0.0, 0.5))
  assert_true(sh.data[4].to_int() == 250)
}

///|
test "srcov: 报告" {
  let img = sr_grad(2, 2)
  let res = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::NearestNeighbor, 2.0),
  )
  let m = @superres.calculate_image_quality_metrics(img, img)
  let report = @superres.super_resolution_report_to_string(res, m)
  assert_true(report.contains("超分辨率报告"))
  assert_true(report.contains("最近邻"))
  assert_true(report.contains("2x2"))
  assert_true(report.contains("4x4"))
  // 各算法名称分支
  let r_bl = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Bilinear, 2.0),
  )
  let t_bl = @superres.super_resolution_report_to_string(r_bl, m)
  assert_true(t_bl.contains("双线性"))
  let r_bc = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Bicubic, 2.0),
  )
  let t_bc = @superres.super_resolution_report_to_string(r_bc, m)
  assert_true(t_bc.contains("双三次"))
  let r_lz = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Lanczos, 2.0),
  )
  let t_lz = @superres.super_resolution_report_to_string(r_lz, m)
  assert_true(t_lz.contains("Lanczos"))
  let r_ed = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::EdgeDirected, 2.0),
  )
  let t_ed = @superres.super_resolution_report_to_string(r_ed, m)
  assert_true(t_ed.contains("边缘导向"))
  let r_eb = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::ExampleBased, 2.0),
  )
  let t_eb = @superres.super_resolution_report_to_string(r_eb, m)
  assert_true(t_eb.contains("基于示例"))
  let r_dl = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::DeepLearning, 2.0),
  )
  let t_dl = @superres.super_resolution_report_to_string(r_dl, m)
  assert_true(t_dl.contains("深度学习"))
  let r_uk = @superres.super_resolve(
    img,
    sr_cfg(@superres.SuperResolutionAlgorithm::Unknown, 2.0),
  )
  let t_uk = @superres.super_resolution_report_to_string(r_uk, m)
  assert_true(t_uk.contains("未知"))
}
