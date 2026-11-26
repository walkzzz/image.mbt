// 覆盖率白盒：增强多语言 OCR（语言检测 / 智能分割 / 空格与标点后处理 / 识别流水线）

fn moe_gray(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  let data : Array[Byte] = []
  for _ in 0..<(w * h) {
    data.push(fill)
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(data) }
}

fn moe_block(
  w : Int32,
  h : Int32,
  x0 : Int32,
  y0 : Int32,
  bw : Int32,
  bh : Int32,
) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let inside = x >= x0 && x < x0 + bw && y >= y0 && y < y0 + bh
      data.push(if inside { b'\xFF' } else { b'\x00' })
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(data) }
}

fn moe_catch_dims(img : @types.Image) -> Bool {
  try {
    let _ = detect_language_enhanced(img)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

test "moe: 默认配置与语言检测分支" {
  let cfg = multilingual_ocr_enhanced_default_config()
  assert_true(cfg.enable_chinese)
  assert_true(!cfg.enable_japanese)
  assert_eq(cfg.target_size, 48)
  assert_true(cfg.auto_language_detection)
  // 方形实心：中文最高分
  let square = moe_block(16, 16, 4, 4, 8, 8)
  let r = detect_language_enhanced(square)
  assert_true(r.probabilities.length() == 4)
  assert_eq(r.language, "chinese")
  assert_true(r.confidence > 0.0)
  // 窄条：英文
  let narrow = moe_block(6, 16, 1, 4, 4, 8)
  let r2 = detect_language_enhanced(narrow)
  assert_eq(r2.language, "english")
  // 扁宽：标点
  let flat = moe_block(32, 8, 2, 3, 28, 2)
  let r3 = detect_language_enhanced(flat)
  assert_eq(r3.language, "punctuation")
  // 纯黑：密度 0 → 标点分支
  let blank = moe_gray(12, 12, b'\x00')
  let r4 = detect_language_enhanced(blank)
  assert_eq(r4.language, "punctuation")
  // 校验错误分支
  assert_true(moe_catch_dims(moe_gray(0, 4, b'\x01')))
  let rgb : Array[Byte] = []
  for _ in 0..<16 {
    rgb.push(b'\x01')
  }
  let img3 = @types.Image::{ width: 2, height: 2, channels: 3, data: Bytes::from_array(rgb) }
  assert_true(moe_catch_dims(img3))
  let bad = @types.Image::{ width: 4, height: 4, channels: 1, data: Bytes::from_array([b'\x00']) }
  assert_true(moe_catch_dims(bad))
}

test "moe: 智能字符分割" {
  let cfg = multilingual_ocr_enhanced_default_config()
  // 两个合法字符块 + 一个小噪点
  let data : Array[Byte] = []
  let w = 40
  let h = 20
  for y in 0..<h {
    for x in 0..<w {
      let in_a = x >= 2 && x < 14 && y >= 2 && y < 18
      let in_b = x >= 20 && x < 28 && y >= 4 && y < 16
      let noise = x >= 34 && x < 36 && y >= 8 && y < 10
      data.push(if in_a || in_b || noise { b'\xFF' } else { b'\x00' })
    }
  }
  let img = @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(data) }
  let regions = smart_segment_chars(img, cfg)
  // 噪点被面积/尺寸过滤；两个字符块保留
  assert_true(regions.length() == 2)
  assert_true(regions[0].2 >= 5)
  assert_true(regions[0].4.length() > 0)
  // 关闭自动语言检测
  let cfg2 = MultilingualOcrEnhancedConfig::{
    enable_chinese: true,
    enable_english: true,
    enable_digits: true,
    enable_punctuation: true,
    enable_japanese: false,
    enable_korean: false,
    target_size: 48,
    distance_metric: "euclidean",
    auto_language_detection: false,
    smart_spacing: true,
    punctuation_normalization: true,
    use_language_model: true,
  }
  let r2 = smart_segment_chars(img, cfg2)
  assert_true(r2.length() == 2)
  assert_true(r2[0].4 == "unknown")
  // 空图：无区域
  let empty = moe_gray(10, 10, b'\x00')
  assert_true(smart_segment_chars(empty, cfg).length() == 0)
  // 校验错误
  try {
    let _ = smart_segment_chars(moe_gray(0, 4, b'\x01'), cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "moe: 字符区域提取边界" {
  let img = moe_block(20, 20, 0, 0, 20, 20)
  // 正常裁剪并缩放
  let c1 = extract_char_region_for_smart(img, 2, 2, 10, 10, 8)
  assert_eq(c1.width, 8)
  assert_eq(c1.height, 8)
  // 超出右/下边界 → 截断
  let c2 = extract_char_region_for_smart(img, 15, 15, 20, 20, 8)
  assert_eq(c2.width, 8)
  // 起点完全越界 → 返回空图
  let c3 = extract_char_region_for_smart(img, 20, 20, 10, 10, 4)
  assert_eq(c3.width, 4)
  assert_eq(c3.data[0].to_int(), 0)
}

test "moe: 空格与标点后处理" {
  let text = "中文AB"
  let langs : Array[String] = ["chinese", "chinese", "english", "english"]
  let spaced = smart_spacing_process(text, langs)
  assert_true(spaced == "中文 AB")
  // 长度不匹配 → 原样返回
  let raw = smart_spacing_process(text, ["chinese"])
  assert_true(raw == text)
  // 空串
  let none : Array[String] = []
  assert_true(smart_spacing_process("", none) == "")
  // 数字与中文之间也加空格
  let t2 = "数1"
  assert_true(smart_spacing_process(t2, ["chinese", "digit"]) == "数 1")
  // 日文/韩文同样视为 CJK
  let t3 = "あA"
  assert_true(smart_spacing_process(t3, ["japanese", "english"]) == "あ A")
  // 标点规范化：中文语境
  let punct_cn = normalize_punctuation(",.;:()!?", [
    "chinese", "chinese", "chinese", "chinese", "chinese", "chinese",
    "chinese", "chinese",
  ])
  assert_true(punct_cn == "，。；：（）！？")
  // 英文语境反向
  let punct_en = normalize_punctuation("，。；：（）！？", [
    "english", "english", "english", "english", "english", "english",
    "english", "english",
  ])
  assert_true(punct_en == ",.;:()!?")
  // 未命中的字符保留
  assert_true(normalize_punctuation("中", ["chinese"]) == "中")
  assert_true(normalize_punctuation("a", ["english"]) == "a")
  // 长度不匹配 / 空串
  assert_true(normalize_punctuation("abc", ["chinese"]) == "abc")
  assert_true(normalize_punctuation("", []) == "")
}

test "moe: 语言模型后处理" {
  let text = "abc"
  let langs : Array[String] = ["english", "english", "english"]
  let conf : Array[Double] = [0.2, 0.5, 0.9]
  let (t, c) = language_model_postprocess(text, langs, conf)
  assert_true(t == text)
  assert_true(c[0] > 0.0)
  assert_true(c[0] < 0.2)
  assert_true(c[1] == 0.5)
  // 空数组
  let (t2, c2) = language_model_postprocess("", [], [])
  assert_true(t2 == "")
  assert_true(c2.length() == 0)
}

test "moe: 识别流水线校验与空图" {
  // 零尺寸
  try {
    let _ = recognize_multilingual_enhanced(moe_gray(0, 0, b'\x00'))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道 > 4
  let bad_ch : Array[Byte] = []
  for _ in 0..<20 {
    bad_ch.push(b'\x00')
  }
  let img5 = @types.Image::{ width: 2, height: 2, channels: 5, data: Bytes::from_array(bad_ch) }
  try {
    let _ = recognize_multilingual_enhanced(img5)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据不足
  let img_bad = @types.Image::{ width: 4, height: 4, channels: 1, data: Bytes::from_array([b'\x00']) }
  try {
    let _ = recognize_multilingual_enhanced(img_bad)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 空图：无字符 → 空文本
  let blank = moe_gray(12, 12, b'\x00')
  let res = recognize_multilingual_enhanced(blank)
  assert_true(res.text.length() == 0)
  assert_true(res.characters.length() == 0)
  assert_true(res.confidence == 0.0)
}

test "moe: 识别流水线全模板关闭与默认模板" {
  // 全部模板关闭 → 命中 "?" 分支
  let cfg_off = MultilingualOcrEnhancedConfig::{
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
  let glyph = moe_block(24, 24, 4, 2, 14, 20)
  let res = recognize_multilingual_enhanced(glyph, config=cfg_off)
  assert_true(res.characters.length() >= 1)
  assert_true(res.text.contains("?"))
  // 默认配置：走中/英/数字模板匹配
  let res2 = recognize_multilingual_enhanced(moe_block(40, 40, 10, 6, 12, 24))
  assert_true(res2.characters.length() >= 1)
  assert_true(res2.confidence >= 0.0)
}
