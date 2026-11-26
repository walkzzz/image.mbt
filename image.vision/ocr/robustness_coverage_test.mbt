// 覆盖率测试：OCR 鲁棒性增强（自适应配置 / 倾斜检测 / 畸变检测 / 版面分析 / 报告）

///|
fn rb_img(w : Int32, h : Int32, c : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn rb_flat(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(fill)
  }
  rb_img(w, h, 1, d)
}

///|
fn rb_scan(score : Double) -> @ocr.ScanQuality {
  @ocr.ScanQuality::{
    brightness: 128.0,
    contrast: 40.0,
    sharpness: 10.0,
    noise_level: 0.1,
    skew_angle: 0.0,
    overall_score: score,
    issues: [],
  }
}

///|
fn rb_has_distortion(
  rs : Array[@ocr.DistortionDetectionResult],
  t : @ocr.DistortionType,
) -> Bool {
  for r in rs {
    if r.distortion_type == t {
      return true
    }
  }
  false
}

///|
test "rbcov: 自适应配置五档" {
  let c90 = @ocr.select_adaptive_config(rb_scan(95.0))
  assert_true(c90.quality_level == @ocr.Excellent)
  assert_true(c90.denoise_strength == 1)
  assert_true(c90.binarization_method == "otsu")
  assert_true(c90.recommended_dpi == 200)
  assert_true(!c90.deskew_enabled)
  let c75 = @ocr.select_adaptive_config(rb_scan(80.0))
  assert_true(c75.quality_level == @ocr.Good)
  assert_true(c75.recommended_dpi == 250)
  assert_true(c75.morph_close_enabled)
  assert_true(!c75.sharpen_enabled)
  let c60 = @ocr.select_adaptive_config(rb_scan(65.0))
  assert_true(c60.quality_level == @ocr.Fair)
  assert_true(c60.binarization_method == "adaptive")
  assert_true(c60.sharpen_enabled)
  assert_true(c60.morph_open_enabled)
  let c40 = @ocr.select_adaptive_config(rb_scan(45.0))
  assert_true(c40.quality_level == @ocr.Poor)
  assert_true(c40.binarization_method == "sauvola")
  assert_true(c40.contrast_enhance == 2.0)
  assert_true(c40.recommended_dpi == 400)
  let c0 = @ocr.select_adaptive_config(rb_scan(20.0))
  assert_true(c0.quality_level == @ocr.VeryPoor)
  assert_true(c0.denoise_strength == 5)
  assert_true(c0.recommended_dpi == 600)
  // 边界：90 / 40 恰好落在高档
  let b90 = @ocr.select_adaptive_config(rb_scan(90.0))
  assert_true(b90.quality_level == @ocr.Excellent)
  let b40 = @ocr.select_adaptive_config(rb_scan(40.0))
  assert_true(b40.quality_level == @ocr.Poor)
  // 越界校验
  try {
    let _ = @ocr.select_adaptive_config(rb_scan(-1.0))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.select_adaptive_config(rb_scan(101.0))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "rbcov: 倾斜检测" {
  // 校验：尺寸为 0
  let empty = rb_img(0, 4, 1, [])
  try {
    let _ = @ocr.detect_skew_angle_robust(empty)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 校验：非单通道
  let rgb = rb_img(4, 4, 3, Array::make(48, b'\x00'))
  try {
    let _ = @ocr.detect_skew_angle_robust(rgb)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 校验：数据长度不匹配
  let bad = rb_img(4, 4, 1, [b'\x00'])
  try {
    let _ = @ocr.detect_skew_angle_robust(bad)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 全白：无黑像素行 → 角度 0
  assert_true(@ocr.detect_skew_angle_robust(rb_flat(20, 20, b'\xFF')) == 0.0)
  // 水平粗线：只有一行，first_y == last_y → 0
  let hline_d : Array[Byte] = []
  for y in 0..<20 {
    for _ in 0..<20 {
      hline_d.push(if y == 10 { b'\x00' } else { b'\xFF' })
    }
  }
  assert_true(@ocr.detect_skew_angle_robust(rb_img(20, 20, 1, hline_d)) == 0.0)
  // 右下斜（每行 3 个黑像素）：正角度
  let diag_d : Array[Byte] = []
  for y in 0..<20 {
    for x in 0..<20 {
      let on = x >= y - 1 && x <= y + 1
      diag_d.push(if on { b'\x00' } else { b'\xFF' })
    }
  }
  let pos = @ocr.detect_skew_angle_robust(rb_img(20, 20, 1, diag_d))
  assert_true(pos > 0.0 && pos <= 90.0)
  // 左下斜：负角度
  let neg_d : Array[Byte] = []
  for y in 0..<20 {
    for x in 0..<20 {
      let on = x >= 19 - y - 1 && x <= 19 - y + 1
      neg_d.push(if on { b'\x00' } else { b'\xFF' })
    }
  }
  let neg = @ocr.detect_skew_angle_robust(rb_img(20, 20, 1, neg_d))
  assert_true(neg < 0.0 && neg >= -90.0)
}

///|
test "rbcov: 畸变检测" {
  // 校验
  try {
    let _ = @ocr.detect_distortions(rb_img(0, 4, 1, []))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.detect_distortions(rb_img(2, 2, 5, []))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.detect_distortions(rb_img(2, 2, 1, [b'\x00']))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 平坦图：拉普拉斯方差 0 → 模糊（severity 0.9）
  let flat = @ocr.detect_distortions(rb_flat(20, 20, b'\x80'))
  assert_true(rb_has_distortion(flat, @ocr.Blur))
  let mut blur_sev = 0.0
  for r in flat {
    if r.distortion_type == @ocr.Blur {
      blur_sev = r.severity
    }
  }
  assert_true(blur_sev == 0.9)
  for r in flat {
    assert_true(r.severity >= 0.0 && r.severity <= 1.0)
    assert_true(r.confidence >= 0.0 && r.confidence <= 1.0)
  }
  // 棋盘噪声：噪声 + 光照不均都可能出现，但噪声必然命中
  let noisy_d : Array[Byte] = []
  for y in 0..<40 {
    for x in 0..<40 {
      noisy_d.push(if (x + y) % 2 == 0 { b'\x00' } else { b'\xFF' })
    }
  }
  let noisy = @ocr.detect_distortions(rb_img(40, 40, 1, noisy_d))
  assert_true(rb_has_distortion(noisy, @ocr.Noise))
  // 左右明暗差 > 50：光照不均
  let light_d : Array[Byte] = []
  for _ in 0..<40 {
    for x in 0..<40 {
      light_d.push(if x < 20 { b'\x0A' } else { b'\xF0' })
    }
  }
  let light = @ocr.detect_distortions(rb_img(40, 40, 1, light_d))
  assert_true(rb_has_distortion(light, @ocr.UnevenLighting))
  // 小图（<= 20）跳过光照检测
  let small = @ocr.detect_distortions(rb_flat(10, 10, b'\x40'))
  assert_true(!rb_has_distortion(small, @ocr.UnevenLighting))
}

///|
test "rbcov: 复杂版面分析" {
  // 空块 → Unknown
  let empty = @ocr.analyze_complex_layout([], 200, 300)
  assert_true(empty.layout_type == @ocr.Unknown)
  assert_true(empty.num_columns == 1)
  assert_true(empty.confidence == 0.0)
  assert_true(empty.column_boundaries.length() == 0)
  assert_true(empty.reading_order_strategy == "default")
  // 全宽块 → 单栏
  let full_blocks : Array[@ocr.TextBlock] = []
  for i in 0..<3 {
    full_blocks.push(@ocr.TextBlock::{
      x: 10,
      y: i * 50,
      width: 190,
      height: 40,
      block_type: "text",
      text: "line",
      confidence: 0.9,
      reading_order: i,
    })
  }
  let single = @ocr.analyze_complex_layout(full_blocks, 200, 300)
  assert_true(single.layout_type == @ocr.SingleColumn)
  assert_true(single.num_columns == 1)
  assert_true(single.reading_order_strategy == "top_to_bottom")
  assert_true(single.column_boundaries.length() == 2)
  assert_true(single.column_boundaries[1] == 200)
  // 左右各半 → 双栏
  let two_blocks : Array[@ocr.TextBlock] = []
  for i in 0..<3 {
    two_blocks.push(@ocr.TextBlock::{
      x: 10,
      y: i * 40,
      width: 60,
      height: 30,
      block_type: "text",
      text: "l",
      confidence: 0.9,
      reading_order: i,
    })
    two_blocks.push(@ocr.TextBlock::{
      x: 130,
      y: i * 40,
      width: 60,
      height: 30,
      block_type: "text",
      text: "r",
      confidence: 0.9,
      reading_order: i + 3,
    })
  }
  let two = @ocr.analyze_complex_layout(two_blocks, 200, 300)
  assert_true(two.layout_type == @ocr.DoubleColumn)
  assert_true(two.num_columns == 2)
  assert_true(two.reading_order_strategy == "left_column_first")
  assert_true(two.column_boundaries.length() == 4)
  assert_true(two.column_boundaries[1] == 80)
  assert_true(two.column_boundaries[2] == 120)
  // 全宽 + 分栏混合 → MixedLayout，且存在浮动元素
  let mixed_blocks : Array[@ocr.TextBlock] = []
  for i in 0..<3 {
    mixed_blocks.push(@ocr.TextBlock::{
      x: 10,
      y: i * 40,
      width: 190,
      height: 30,
      block_type: "text",
      text: "full",
      confidence: 0.9,
      reading_order: i,
    })
  }
  for i in 0..<3 {
    mixed_blocks.push(@ocr.TextBlock::{
      x: 10,
      y: 150 + i * 40,
      width: 70,
      height: 30,
      block_type: "text",
      text: "l",
      confidence: 0.9,
      reading_order: 3 + i,
    })
    mixed_blocks.push(@ocr.TextBlock::{
      x: 120,
      y: 150 + i * 40,
      width: 70,
      height: 30,
      block_type: "text",
      text: "r",
      confidence: 0.9,
      reading_order: 6 + i,
    })
  }
  let mixed = @ocr.analyze_complex_layout(mixed_blocks, 200, 300)
  assert_true(mixed.layout_type == @ocr.MixedLayout)
  assert_true(mixed.num_columns == 1)
  assert_true(mixed.has_floating_elements)
  assert_true(mixed.reading_order_strategy == "adaptive")
  assert_true(mixed.column_boundaries.length() == 2)
}

///|
test "rbcov: 鲁棒性报告与文本" {
  // 高质量 + 单栏 + 无畸变 → 标准流程，建议为「质量良好」
  let good_layout = @ocr.analyze_complex_layout([], 200, 300)
  let r1 = @ocr.generate_robustness_report(rb_scan(95.0), [], good_layout)
  assert_true(r1.quality_score == 0.95)
  assert_true(r1.distortion_score == 1.0)
  assert_true(r1.noise_resistance_score == 1.0)
  assert_true(r1.overall_score > 0.8)
  assert_true(r1.processing_recommendation == "标准处理流程")
  assert_true(r1.recommendations.length() == 1)
  assert_true(r1.recommendations[0].contains("文档质量良好"))
  assert_true(r1.estimated_accuracy > 0.8)
  let txt = @ocr.robustness_report_to_string(r1)
  assert_true(txt.contains("OCR 鲁棒性评估报告"))
  assert_true(txt.contains("综合评分"))
  // 低质量 + 噪声 + 双栏 + 严重畸变 → 重度预处理
  let d_flat = @ocr.detect_distortions(rb_flat(20, 20, b'\x80'))
  let two = @ocr.analyze_complex_layout([], 200, 300)
  let low_layout = @ocr.ComplexLayoutAnalysis::{
    layout_type: @ocr.DoubleColumn,
    num_columns: 2,
    has_floating_elements: false,
    has_cross_page_elements: false,
    column_boundaries: [0, 80, 120, 200],
    reading_order_strategy: "left_column_first",
    confidence: 0.75,
  }
  ignore(two)
  let r2 = @ocr.generate_robustness_report(rb_scan(30.0), d_flat, low_layout)
  assert_true(r2.quality_score == 0.3)
  assert_true(r2.layout_complexity_score == 0.8)
  assert_true(r2.recommendations.length() >= 2)
  assert_true(r2.overall_score > 0.6 && r2.overall_score <= 0.8)
  assert_true(r2.processing_recommendation == "增强处理流程")
  let mut has_dpi = false
  let mut has_column = false
  for rec in r2.recommendations {
    if rec.contains("300 DPI") {
      has_dpi = true
    }
    if rec.contains("多栏") {
      has_column = true
    }
  }
  assert_true(has_dpi)
  assert_true(has_column)
  // 噪声严重度高 → 去噪建议
  let noisy_d : Array[Byte] = []
  for y in 0..<40 {
    for x in 0..<40 {
      noisy_d.push(if (x + y) % 2 == 0 { b'\x00' } else { b'\xFF' })
    }
  }
  let rs = @ocr.detect_distortions(rb_img(40, 40, 1, noisy_d))
  let r3 = @ocr.generate_robustness_report(rb_scan(95.0), rs, good_layout)
  assert_true(r3.noise_resistance_score < 1.0)
  let mut has_denoise = false
  for rec in r3.recommendations {
    if rec.contains("去噪") {
      has_denoise = true
    }
  }
  assert_true(has_denoise)
  assert_true(rb_scan(50.0).overall_score == 50.0)
}
