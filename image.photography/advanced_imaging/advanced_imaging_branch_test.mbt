// 覆盖率测试（分支补充）：高级成像各模态的分支组合

fn ai_gray(w : Int32, h : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(f(x, y).to_byte())
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

test "aicov: 量子成像分支" {
  // 零模式 → 全零图
  let z = @advanced_imaging.quantum_ghost_imaging(
    0,
    4,
    4,
    @advanced_imaging.QuantumImagingAlgorithm::GhostImaging,
  )
  assert_true(z.channels == 1)
  assert_true(z.data.length() == 16)
  // 单像素算法分支
  let o1 = @advanced_imaging.quantum_ghost_imaging(
    2,
    4,
    4,
    @advanced_imaging.QuantumImagingAlgorithm::SinglePixel,
  )
  assert_true(o1.data.length() == 16)
  // 纠缠光子算法分支
  let o2 = @advanced_imaging.quantum_ghost_imaging(
    3,
    3,
    3,
    @advanced_imaging.QuantumImagingAlgorithm::EntangledPhoton,
  )
  assert_true(o2.width == 3)
  // 压缩感知算法分支
  let o3 = @advanced_imaging.quantum_ghost_imaging(
    1,
    2,
    2,
    @advanced_imaging.QuantumImagingAlgorithm::CompressiveSensing,
  )
  assert_true(o3.height == 2)
  // Unknown 算法
  let o4 = @advanced_imaging.quantum_ghost_imaging(
    2,
    2,
    2,
    @advanced_imaging.QuantumImagingAlgorithm::Unknown,
  )
  assert_true(o4.data.length() == 4)
}

test "aicov: 红外伪彩色四段分支" {
  // 覆盖 <0.25 / <0.5 / <0.75 / >=0.75 四段
  let img = @types.Image::{
    width: 4,
    height: 1,
    channels: 1,
    data: Bytes::from_array([b'\x00', b'\x40', b'\x80', b'\xff']),
  }
  let o = @advanced_imaging.infrared_pseudocolor(
    img,
    @advanced_imaging.InfraredImagingType::LWIR,
  )
  assert_true(o.channels == 3)
  assert_true(o.data.length() == 12)
  // 第一段：蓝通道 > 0，红通道 0
  assert_true(o.data[0].to_int() == 0)
  assert_true(o.data[5].to_int() > 0)
  // 第四段：红通道 255
  assert_true(o.data[9].to_int() == 255)
  // 其他红外类型
  let o2 = @advanced_imaging.infrared_pseudocolor(
    img,
    @advanced_imaging.InfraredImagingType::MWIR,
  )
  assert_true(o2.channels == 3)
  let o3 = @advanced_imaging.infrared_pseudocolor(
    img,
    @advanced_imaging.InfraredImagingType::Unknown,
  )
  assert_true(o3.data.length() == 12)
}

test "aicov: 高光谱立方体波长分支" {
  let base = ai_gray(4, 4, fn(x, y) { 100 + x * 10 + y })
  // 400→800 覆盖全部四个波长分支
  let cube = @advanced_imaging.generate_hyperspectral_cube(base, 4, 400.0, 800.0)
  assert_true(cube.num_bands == 4)
  assert_true(cube.image_cube.length() == 4)
  assert_true(cube.wavelengths.length() == 4)
  assert_true(cube.spatial_width == 4)
  assert_true(cube.spatial_height == 4)
  assert_true(cube.spectral_resolution > 0.0)
  // 第一波段（<500）响应 0.8 → 100 → 80
  assert_true(cube.image_cube[0].data[0].to_int() == 80)
  // 第二波段（<600）响应 1.0
  assert_true(cube.image_cube[1].data[0].to_int() == 100)
  // 单波段
  let cube1 = @advanced_imaging.generate_hyperspectral_cube(base, 1, 300.0, 400.0)
  assert_true(cube1.num_bands == 1)
  assert_true(cube1.image_cube.length() == 1)
}

test "aicov: 偏振与热成像" {
  let a = ai_gray(4, 4, fn(x, _y) { 100 + x })
  let b = ai_gray(4, 4, fn(_x, y) { 120 - y })
  let c = ai_gray(4, 4, fn(x, _y) { 200 - x * 5 })
  let d = ai_gray(4, 4, fn(_x, y) { 60 + y * 3 })
  let p = @advanced_imaging.analyze_polarization(a, b, c, d)
  assert_true(p.intensity.width == 4)
  assert_true(p.degree_of_polarization.data.length() == 16)
  assert_true(p.angle_of_polarization.data.length() == 16)
  assert_true(p.num_stokes == 4)
  assert_true(p.stokes_parameters.length() == 4)
  // 全同图 → 偏振度接近 0
  let same = @advanced_imaging.analyze_polarization(a, a, a, a)
  assert_true(same.degree_of_polarization.data.length() == 16)
  // 热成像：梯度温度
  let thermal = ai_gray(4, 4, fn(x, y) { (x + y) * 16 })
  let t = @advanced_imaging.thermal_to_temperature(thermal, 0.95, 20.0, 60.0)
  assert_true(t.temperature_map.data.length() == 16)
  assert_true(t.units == "Celsius")
  assert_true(t.emissivity == 0.95)
  assert_true(t.max_temperature >= t.min_temperature)
  // 低发射率 → 校正后温度更高（可能触发 >255 钳制）
  let t2 = @advanced_imaging.thermal_to_temperature(thermal, 0.1, 20.0, 60.0)
  assert_true(t2.average_temperature > t.average_temperature)
  assert_true(t2.temperature_map.data.length() == 16)
  // 平坦图 → 全部映射到 0
  let flat = ai_gray(2, 2, fn(_x, _y) { 128 })
  let t3 = @advanced_imaging.thermal_to_temperature(flat, 1.0, 20.0, 60.0)
  assert_true(t3.average_temperature > 20.0)
}

test "aicov: X 射线 / 超声 / MRI / PET 与报告" {
  // X 射线：平坦图（std_dev 兜底 1.0）
  let flat = ai_gray(4, 4, fn(_x, _y) { 50 })
  let x0 = @advanced_imaging.xray_enhance(flat, 80.0)
  assert_true(x0.projection.data.length() == 16)
  assert_true(x0.energy_kev == 80.0)
  assert_true(x0.dose > 0.0)
  // 梯度图（真实方差）
  let grad = ai_gray(4, 4, fn(x, _y) { x * 60 })
  let x1 = @advanced_imaging.xray_enhance(grad, 120.0)
  assert_true(x1.projection.data.length() == 16)
  // 超声
  let u = @advanced_imaging.ultrasound_synthesize(16, 16, 5.0, 10.0)
  assert_true(u.b_mode.width == 16)
  assert_true(u.b_mode.data.length() == 256)
  assert_true(u.doppler.data.length() == 256)
  assert_true(u.frequency_mhz == 5.0)
  assert_true(u.depth_cm == 10.0)
  // MRI：中心/灰质/白质/背景四段
  let m = @advanced_imaging.mri_synthesize(20, 20, 3.0)
  assert_true(m.t1_weighted.data.length() == 400)
  assert_true(m.t2_weighted.data.length() == 400)
  assert_true(m.flair.data.length() == 400)
  assert_true(m.field_strength_t == 3.0)
  // 中心像素为脑室（T2 亮）
  assert_true(m.t2_weighted.data[10 * 20 + 10].to_int() == 200)
  // 角落为背景
  assert_true(m.t1_weighted.data[0].to_int() == 10)
  // PET：中心摄取高
  let p = @advanced_imaging.pet_synthesize(32, 32, "FDG")
  assert_true(p.activity_map.data.length() == 1024)
  assert_true(p.radiotracer == "FDG")
  assert_true(p.reconstruction_algorithm == "OSEM")
  assert_true(p.activity_map.data[16 * 32 + 16].to_int() > 20)
  // 报告：不同模态
  let cfg = @advanced_imaging.create_default_advanced_imaging_config(
    @advanced_imaging.ImagingModality::MRI,
  )
  let img = ai_gray(4, 4, fn(_x, _y) { 10 })
  let r1 = @advanced_imaging.advanced_imaging_report_to_string(
    @advanced_imaging.ImagingModality::MRI,
    img,
    cfg,
  )
  assert_true(r1.has_prefix("## 高级成像报告"))
  let r2 = @advanced_imaging.advanced_imaging_report_to_string(
    @advanced_imaging.ImagingModality::CT,
    img,
    cfg,
  )
  assert_true(r2.contains("CT成像"))
  let r3 = @advanced_imaging.advanced_imaging_report_to_string(
    @advanced_imaging.ImagingModality::Terahertz,
    img,
    cfg,
  )
  assert_true(r3.contains("太赫兹成像"))
  let r4 = @advanced_imaging.advanced_imaging_report_to_string(
    @advanced_imaging.ImagingModality::Polarization,
    img,
    cfg,
  )
  assert_true(r4.contains("偏振成像"))
  // 默认配置字段
  assert_true(cfg.image_width == 512)
  assert_true(cfg.image_height == 512)
  assert_true(cfg.num_slices == 1)
  assert_true(cfg.use_noise_reduction)
  assert_true(cfg.use_enhancement)
  assert_true(cfg.calibration_factor == 1.0)
}
