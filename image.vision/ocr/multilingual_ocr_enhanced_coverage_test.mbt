// 覆盖率测试：多语言 OCR 增强（语言检测 / 智能分割 / 空格与标点 / 后处理 / 流水线）

fn mle_img(w : Int32, h : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(f(x, y).to_byte())
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

fn mle_all_off() -> @ocr.MultilingualOcrEnhancedConfig {
  @ocr.MultilingualOcrEnhancedConfig::{
    enable_chinese: false,
    enable_english: false,
    enable_digits: false,
    enable_punctuation: false,
    enable_japanese: false,
    enable_korean: false,
    target_size: 32,
    distance_metric: "euclidean",
    auto_language_detection: false,
    smart_spacing: false,
    punctuation_normalization: false,
    use_language_model: false,
  }
}

test "mleov: 默认配置" {
  let cfg = @ocr.multilingual_ocr_enhanced_default_config()
  assert_true(cfg.enable_chinese)
  assert_true(cfg.enable_english)
  assert_true(cfg.enable_digits)
  assert_true(cfg.enable_punctuation)
  assert_true(!cfg.enable_japanese)
  assert_true(!cfg.enable_korean)
  assert_true(cfg.target_size == 48)
  assert_true(cfg.distance_metric == "euclidean")
  assert_true(cfg.auto_language_detection)
  assert_true(cfg.smart_spacing)
  assert_true(cfg.punctuation_normalization)
  assert_true(cfg.use_language_model)
}

test "mleov: 语言检测分支" {
  // 近方形、适中密度 → chinese 最高分
  let square = mle_img(16, 16, fn(x, y) {
    if x >= 3 && x < 13 && y >= 3 && y < 13 { 255 } else { 0 }
  })
  let r1 = @ocr.detect_language_enhanced(square)
  assert_true(r1.language == "chinese")
  assert_true(r1.probabilities.length() == 4)
  assert_true(r1.confidence > 0.6 && r1.confidence < 0.8)
  // 窄条、密度适中 → english / digit 领先
  let narrow = mle_img(8, 16, fn(x, y) {
    if x >= 2 && x < 5 { 255 } else { 0 }
  })
  let r2 = @ocr.detect_language_enhanced(narrow)
  assert_true(r2.language == "english" || r2.language == "digit")
  // 极低密度 → punctuation
  let sparse = mle_img(32, 8, fn(x, y) {
    if y == 3 && x < 4 { 255 } else { 0 }
  })
  let r3 = @ocr.detect_language_enhanced(sparse)
  assert_true(r3.language == "punctuation")
  // 全黑（密度 0）→ punctuation
  let empty = mle_img(16, 16, fn(_x, _y) { 0 })
  let r4 = @ocr.detect_language_enhanced(empty)
  assert_true(r4.language == "punctuation")
  // 校验
  try {
    let _ = @ocr.detect_language_enhanced(mle_img(0, 8, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(192, b'\x00')),
  }
  try {
    let _ = @ocr.detect_language_enhanced(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.detect_language_enhanced(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "mleov: 智能分割" {
  let img = mle_img(64, 64, fn(x, y) {
    if x >= 20 && x < 40 && y >= 20 && y < 40 { 255 } else { 0 }
  })
  let cfg = @ocr.multilingual_ocr_enhanced_default_config()
  let regions = @ocr.smart_segment_chars(img, cfg)
  assert_true(regions.length() == 1)
  assert_true(regions[0].0 == 20)
  assert_true(regions[0].2 == 20)
  assert_true(regions[0].4.length() > 0)
  // 关闭自动语言检测 → unknown
  let off = mle_all_off()
  let r2 = @ocr.smart_segment_chars(img, off)
  assert_true(r2.length() == 1)
  assert_true(r2[0].4 == "unknown")
  // 过小连通域被过滤
  let small = mle_img(16, 16, fn(x, y) {
    if x >= 2 && x < 4 && y >= 2 && y < 4 { 255 } else { 0 }
  })
  let r3 = @ocr.smart_segment_chars(small, cfg)
  assert_true(r3.length() == 0)
  // 校验
  try {
    let _ = @ocr.smart_segment_chars(mle_img(0, 8, fn(_x, _y) { 0 }), cfg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(192, b'\x00')),
  }
  try {
    let _ = @ocr.smart_segment_chars(bad_ch, cfg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.smart_segment_chars(bad_data, cfg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "mleov: 智能空格与标点规范化" {
  // 中英混排 → 插入空格
  let sp = @ocr.smart_spacing_process("a中b", ["english", "chinese", "digit"])
  assert_true(sp == "a 中 b")
  // 纯中文 → 不变
  let sp2 = @ocr.smart_spacing_process("中文", ["chinese", "chinese"])
  assert_true(sp2 == "中文")
  // 长度不匹配 → 原样
  let sp3 = @ocr.smart_spacing_process("中文", ["chinese"])
  assert_true(sp3 == "中文")
  // 空串
  let empty_langs : Array[String] = []
  assert_true(@ocr.smart_spacing_process("", empty_langs) == "")
  // 中文语境 → 中文标点
  let p1 = @ocr.normalize_punctuation(",", ["chinese"])
  assert_true(p1 == "，")
  let p2 = @ocr.normalize_punctuation("(", ["chinese"])
  assert_true(p2 == "（")
  // 英文语境 → 英文标点
  let p3 = @ocr.normalize_punctuation("。", ["english"])
  assert_true(p3 == ".")
  let p4 = @ocr.normalize_punctuation("）", ["digit"])
  assert_true(p4 == ")")
  // 非标点字符保留
  let p5 = @ocr.normalize_punctuation("a", ["chinese"])
  assert_true(p5 == "a")
  // 长度不匹配 → 原样
  let p6 = @ocr.normalize_punctuation(",", ["chinese", "english"])
  assert_true(p6 == ",")
  // 语言模型后处理：低置信度再降
  let confs : Array[Double] = [0.1, 0.5, 0.29]
  let (t, out) = @ocr.language_model_postprocess("abc", ["english", "english", "english"], confs)
  assert_true(t == "abc")
  assert_true(out[0] > 0.089 && out[0] < 0.091)
  assert_true(out[1] == 0.5)
  assert_true(out[2] > 0.26 && out[2] < 0.262)
}

test "mleov: 增强识别流水线" {
  // 单字符方块 → 至少走一次识别
  let img = mle_img(64, 64, fn(x, y) {
    if x >= 18 && x < 46 && y >= 18 && y < 46 { 255 } else { 0 }
  })
  let r = @ocr.recognize_multilingual_enhanced(img)
  assert_true(r.confidence >= 0.0 && r.confidence <= 1.0)
  assert_true(r.characters.length() <= 4)
  // 全部开关关闭：模板全空 → 输出占位字符
  let r2 = @ocr.recognize_multilingual_enhanced(img, config=mle_all_off())
  assert_true(r2.characters.length() <= 4)
  if r2.characters.length() > 0 {
    assert_true(r2.text.contains("?"))
  }
  // 仅中文模板
  let cn_only = @ocr.MultilingualOcrEnhancedConfig::{
    enable_chinese: true,
    enable_english: false,
    enable_digits: false,
    enable_punctuation: false,
    enable_japanese: false,
    enable_korean: false,
    target_size: 32,
    distance_metric: "manhattan",
    auto_language_detection: true,
    smart_spacing: true,
    punctuation_normalization: true,
    use_language_model: true,
  }
  let r3 = @ocr.recognize_multilingual_enhanced(img, config=cn_only)
  assert_true(r3.confidence >= 0.0)
  // 校验
  try {
    let _ = @ocr.recognize_multilingual_enhanced(mle_img(0, 8, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 8,
    height: 8,
    channels: 5,
    data: Bytes::from_array(Array::make(320, b'\x00')),
  }
  try {
    let _ = @ocr.recognize_multilingual_enhanced(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
