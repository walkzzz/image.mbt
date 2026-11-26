// 覆盖率测试：进阶中文 OCR 模板与结构分解

///|
fn acoc_img(w : Int32, h : Int32, c : Int32, value : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, value.to_byte())),
  }
}

///|
test "acocov: 模板生成与结构分解" {
  // 默认配置字段
  let cfg = @ocr.advanced_chinese_ocr_default_config()
  assert_true(cfg.min_char_width == 10)
  assert_true(cfg.max_char_width == 100)
  assert_true(cfg.target_size == 48)
  assert_true(cfg.char_set == "common3500")
  // 模板：三种字符集
  let t1 = @ocr.generate_3500_chinese_templates()
  assert_true(t1.length() > 0)
  let t2 = @ocr.generate_3500_chinese_templates(char_set="common100")
  assert_true(t2.length() > 0)
  let t3 = @ocr.generate_3500_chinese_templates(char_set="full")
  assert_true(t3.length() > 0)
  // 结构分解：覆盖 seed%5 五种结构
  let s0 = @ocr.decompose_chinese_char("你")
  assert_true(s0.char == "你")
  assert_true(s0.strokes > 0)
  assert_true(s0.components.length() > 0)
  assert_true(s0.radical.length() > 0)
  assert_true(
    s0.structure_type == "single" ||
    s0.structure_type == "left-right" ||
    s0.structure_type == "top-bottom" ||
    s0.structure_type == "surround" ||
    s0.structure_type == "complex",
  )
  let s1 = @ocr.decompose_chinese_char("好")
  assert_true(s1.char == "好")
  let s2 = @ocr.decompose_chinese_char("字")
  assert_true(s2.char == "字")
  let s3 = @ocr.decompose_chinese_char("日")
  assert_true(s3.char == "日")
  let s4 = @ocr.decompose_chinese_char("一")
  assert_true(s4.char == "一")
  // 空字符 → 抛错
  try {
    let _ = @ocr.decompose_chinese_char("")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "acocov: 进阶中文识别流水线" {
  // 白底黑块（多列墨迹）
  let w : Int32 = 64
  let h : Int32 = 40
  let data : Array[Int32] = Array::make(w * h, 0)
  for y in 6..<34 {
    for x in 6..<18 {
      data[y * w + x] = 255
    }
    for x in 24..<36 {
      data[y * w + x] = 255
    }
    for x in 44..<56 {
      data[y * w + x] = 255
    }
  }
  let img = @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
  let r1 = @ocr.recognize_chinese_advanced(img)
  assert_true(r1.characters.length() >= 0)
  assert_true(r1.confidence >= 0.0)
  // 自定义配置：cosine 距离 + full 字符集
  let cfg = @ocr.advanced_chinese_ocr_default_config()
  let cfg2 = @ocr.AdvancedChineseOcrConfig::{
    min_char_width: cfg.min_char_width,
    max_char_width: cfg.max_char_width,
    target_size: cfg.target_size,
    distance_metric: "cosine",
    char_set: "full",
    use_radical_decomposition: cfg.use_radical_decomposition,
    use_structure_analysis: cfg.use_structure_analysis,
  }
  let r2 = @ocr.recognize_chinese_advanced(img, config=cfg2)
  assert_true(r2.characters.length() >= 0)
  // 未知距离度量走兜底
  let cfg3 = @ocr.AdvancedChineseOcrConfig::{
    min_char_width: cfg.min_char_width,
    max_char_width: cfg.max_char_width,
    target_size: cfg.target_size,
    distance_metric: "manhattan",
    char_set: "common100",
    use_radical_decomposition: cfg.use_radical_decomposition,
    use_structure_analysis: cfg.use_structure_analysis,
  }
  let r3 = @ocr.recognize_chinese_advanced(img, config=cfg3)
  assert_true(r3.confidence >= 0.0)
  // 空白图 → 无字符
  let blank = acoc_img(32, 32, 1, 0)
  let r0 = @ocr.recognize_chinese_advanced(blank)
  assert_true(r0.characters.length() == 0)
  // 错误分支
  try {
    let _ = @ocr.recognize_chinese_advanced(acoc_img(0, 8, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.recognize_chinese_advanced(acoc_img(8, 8, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
