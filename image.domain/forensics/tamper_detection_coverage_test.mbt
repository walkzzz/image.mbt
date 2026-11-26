// 覆盖率测试：图像取证/篡改检测（ELA / 噪声残差 / DCT / 克隆 / 光照 / 元数据 / ghost / CFA / 综合）

///|
fn td_gray(w : Int32, h : Int32, fill : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for _ in 0..<(w * h) {
    data.push(fill.to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
fn td_pattern(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      data.push(((x * 13 + y * 29) % 256).to_byte())
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
test "td: ELA 分析与质量参数边界" {
  let img = td_pattern(16, 16)
  let r = @forensics.analyze_ela(img, 90)
  assert_true(r.ela_distribution.length() == 16)
  assert_true(r.ela_mean >= 0.0)
  assert_true(r.ela_max >= 0.0)
  assert_true(r.ela_std >= 0.0)
  assert_true(r.tampered_region_ratio >= 0.0)
  // quality 0 → quant 取默认 8
  let r0 = @forensics.analyze_ela(img, 0)
  assert_true(r0.ela_mean >= 0.0)
  // 质量过高 → quant 为 0 → 明确报错
  try {
    let _ = @forensics.analyze_ela(img, 300)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "td: 噪声残差分析" {
  // 平坦图：残差全 0
  let flat = @forensics.analyze_noise_residual(td_gray(8, 8, 128))
  assert_true(flat.residual_mean == 0.0)
  assert_true(flat.residual_std == 0.0)
  assert_true(flat.residual_energy == 0.0)
  assert_true(flat.sensor_pattern.length() == 8)
  assert_true(flat.pattern_consistency >= 0.0)
  // 高 4 行（<8）：sensor_pattern 只有 4 行
  let small = @forensics.analyze_noise_residual(td_gray(6, 4, 200))
  assert_true(small.sensor_pattern.length() == 4)
  // 单行：无相邻行 → consistency 为 0
  let one_row = @forensics.analyze_noise_residual(td_gray(6, 1, 100))
  assert_true(one_row.pattern_consistency == 0.0)
  // 噪声图：残差非零
  let noisy = @forensics.analyze_noise_residual(td_pattern(16, 16))
  assert_true(noisy.residual_energy > 0.0)
}

///|
test "td: DCT 系数分析" {
  let r = @forensics.analyze_dct_coefficients(td_pattern(32, 32))
  assert_true(r.double_jpeg_indicator >= 0.0)
  assert_true(r.double_jpeg_indicator <= 1.0)
  assert_true(r.blockiness_artifact >= 0.0)
  // 小图（不足一个 8x8 块）也需要正常返回
  let tiny = @forensics.analyze_dct_coefficients(td_pattern(4, 4))
  assert_true(tiny.blockiness_artifact >= 0.0)
}

///|
test "td: 克隆检测" {
  // 复制粘贴同一 8x8 块
  let data : Array[Byte] = []
  let w = 40
  let h = 20
  for y in 0..<h {
    for x in 0..<w {
      let in_src = x >= 2 && x < 10 && y >= 2 && y < 10
      let in_dst = x >= 28 && x < 36 && y >= 2 && y < 10
      data.push(if in_src || in_dst { b'\xF0' } else { b'\x10' })
    }
  }
  let img = @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let r = @forensics.detect_clone_regions(img, 4, 0.9)
  assert_true(r.has_clone)
  assert_true(r.clone_region_count >= 1)
  assert_true(r.clone_similarity > 0.0)
  // 高阈值 → 无克隆
  let strict = @forensics.detect_clone_regions(img, 4, 1.5)
  assert_true(!strict.has_clone)
  // block_size 非法
  try {
    let _ = @forensics.detect_clone_regions(img, 1, 0.9)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @forensics.detect_clone_regions(img, 17, 0.9)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "td: 光照一致性" {
  // 平坦图：无梯度、无高光无阴影
  let flat = @forensics.analyze_illumination_consistency(td_gray(16, 16, 128))
  assert_true(flat.illumination_direction == 0.0)
  assert_true(flat.highlight_distribution == 0.0)
  assert_true(flat.shadow_consistency == 0.0)
  assert_true(!flat.has_inconsistent_lighting)
  // 左暗右亮：既有高光也有阴影
  let data : Array[Byte] = []
  for _ in 0..<16 {
    for x in 0..<16 {
      data.push(if x < 8 { b'\x00' } else { b'\xFF' })
    }
  }
  let img = @types.Image::{
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let r = @forensics.analyze_illumination_consistency(img)
  assert_true(r.highlight_distribution > 0.0)
  assert_true(r.shadow_consistency == 0.0)
  assert_true(r.has_inconsistent_lighting)
  // 2x2 图：循环体不执行（边界为 1..(w-1)）
  let tiny = @forensics.analyze_illumination_consistency(td_gray(2, 2, 100))
  assert_true(tiny.illumination_direction == 0.0)
}

///|
test "td: 元数据取证" {
  // 唯一值 < 10 → Paint/Editor，且方形、低分辨率
  let few = @forensics.analyze_metadata_forensics(td_gray(8, 8, 128))
  assert_true(few.software_signature == "Paint/Editor")
  assert_true(few.creation_time == "Early/Low-res")
  assert_true(few.device_info == "Square/Social")
  assert_true(few.metadata_consistency == 0.3)
  assert_true(few.has_inconsistency)
  assert_true(few.has_metadata)
  // 唯一值 10~100 → JPEG/Compressed
  let data_mid : Array[Byte] = []
  for y in 0..<16 {
    for x in 0..<16 {
      data_mid.push(((x * 2 + y) % 20 * 6).to_byte())
    }
  }
  let mid_img = @types.Image::{
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(data_mid),
  }
  let mid = @forensics.analyze_metadata_forensics(mid_img)
  assert_true(mid.software_signature == "JPEG/Compressed")
  assert_true(mid.creation_time == "Early/Low-res")
  // 唯一值 > 100 且尺寸 > 64 → consistency 0.8，宽图为 Panorama
  let data : Array[Byte] = []
  for y in 0..<70 {
    for x in 0..<200 {
      data.push(((x + y) % 256).to_byte())
    }
  }
  let wide = @types.Image::{
    width: 200,
    height: 70,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let big = @forensics.analyze_metadata_forensics(wide)
  assert_true(big.software_signature == "Camera/Raw")
  assert_true(big.creation_time == "Standard")
  assert_true(big.device_info == "Panorama")
  assert_true(big.metadata_consistency == 0.8)
  assert_true(!big.has_inconsistency)
  // 竖图 → Portrait/Mobile
  let data2 : Array[Byte] = []
  for y in 0..<200 {
    for x in 0..<70 {
      data2.push(((x * 3 + y) % 256).to_byte())
    }
  }
  let tall = @types.Image::{
    width: 70,
    height: 200,
    channels: 1,
    data: Bytes::from_array(data2),
  }
  let r3 = @forensics.analyze_metadata_forensics(tall)
  assert_true(r3.device_info == "Portrait/Mobile")
  assert_true(r3.creation_time == "Standard")
}

///|
test "td: JPEG ghost 与 CFA" {
  let ghost = @forensics.analyze_jpeg_ghost(td_pattern(16, 16))
  assert_true(ghost.ghost_quality_levels.length() == 5)
  assert_true(ghost.ghost_region_count >= 0)
  let cfa = @forensics.analyze_cfa_pattern(td_pattern(16, 16))
  assert_true(cfa.bayer_pattern_score >= 0.0)
  assert_true(cfa.cfa_artifact_level >= 0.0)
  assert_true(cfa.cfa_pattern.length() > 0)
  // 平坦图：adj_diff 恒为 0 → bayer_score 保持 0 → Bayer/RGGB 且一致
  let flat = @forensics.analyze_cfa_pattern(td_gray(8, 8, 128))
  assert_true(flat.bayer_pattern_score == 0.0)
  assert_true(flat.is_cfa_consistent)
  assert_true(flat.cfa_pattern == "Bayer/RGGB")
  // 棋盘：对角相同、相邻差异大 → bayer_score 低 → 仍判 Bayer 一致
  let data : Array[Byte] = []
  for y in 0..<8 {
    for x in 0..<8 {
      data.push(if (x + y) % 2 == 0 { b'\x00' } else { b'\xFF' })
    }
  }
  let checker = @types.Image::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let r2 = @forensics.analyze_cfa_pattern(checker)
  assert_true(r2.bayer_pattern_score == 0.0)
}

///|
test "td: 综合检测" {
  let img = td_pattern(32, 32)
  let r = @forensics.detect_tamper_comprehensive(img, 90)
  assert_true(r.tamper_probability >= 0.0)
  assert_true(r.tamper_probability <= 1.0)
  assert_true(!r.is_tampered || r.tamper_probability > 0.0)
  // 平坦低质量图走低分分支
  let flat = @forensics.detect_tamper_comprehensive(td_gray(32, 32, 128), 50)
  assert_true(flat.tamper_probability >= 0.0)
}
