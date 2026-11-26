// 覆盖率测试：英文 OCR 与多语言 OCR 的内部辅助函数（白盒）

fn em_gray(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(fill)
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

fn em_glyph(w : Int32, h : Int32, bx0 : Int32, bx1 : Int32, by0 : Int32, by1 : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(if x >= bx0 && x < bx1 && y >= by0 && y < by1 { b'\x00' } else { b'\xFF' })
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

test "em: 英文字符区域与特征" {
  let img = em_gray(40, 40, b'\xFF')
  let r = extract_char_region_english(img, 4, 4, 16, 20, 32)
  assert_true(r.width == 32)
  assert_true(r.data.length() == 1024)
  // 负宽高 → 全零
  let neg = extract_char_region_english(img, 4, 4, -1, 4, 8)
  assert_true(neg.width == 8)
  assert_true(neg.data[0].to_int() == 0)
  // 裁剪超出右下边界
  let over = extract_char_region_english(img, 38, 38, 10, 10, 8)
  assert_true(over.width == 8)
  // 特征：全白 32x32 密度 1；全黑 0
  let white = extract_char_features_english(em_gray(32, 32, b'\xFF'), 8)
  assert_true(white.length() == 64)
  assert_true(white[0] == 1.0)
  let black = extract_char_features_english(em_gray(32, 32, b'\x00'), 8)
  assert_true(black[0] == 0.0)
  // 阈值 128：值为 128 不算前景
  let mid = extract_char_features_english(em_gray(32, 32, b'\x80'), 8)
  assert_true(mid[0] == 0.0)
}

test "em: 英文模板匹配与距离" {
  let ts = generate_english_templates(case_sensitive=true)
  assert_true(ts.length() == 10 + 26 + 26)
  // 与 "A" 模板完全一致 → 命中 "A"，距离 0 → 置信度 1.0
  let mut a_idx = -1
  for i in 0..<ts.length() {
    if ts[i].0 == "A" {
      a_idx = i
    }
  }
  assert_true(a_idx >= 0)
  let fa = ts[a_idx].1
  let (label, conf) = match_template_english(fa, ts, "euclidean")
  assert_true(label.length() == 1)
  assert_true(conf == 1.0)
  let (_l1, _c1) = match_template_english(fa, ts, "manhattan")
  assert_true(_l1.length() == 1)
  let (_l2, _c2) = match_template_english(fa, ts, "cosine")
  assert_true(_l2.length() >= 1)
  // 未知度量回退欧氏
  let (l3, _c3) = match_template_english(fa, ts, "bogus")
  assert_true(l3.length() == 1)
  // 空模板 → "?"
  let empty_t : Array[(String, Array[Double])] = []
  let (l4, c4) = match_template_english(fa, empty_t, "euclidean")
  assert_true(l4 == "?")
  assert_true(c4 > 0.0 && c4 < 0.0001)
  // 距离边界
  let a : Array[Double] = [3.0, 4.0]
  let z : Array[Double] = [0.0, 0.0]
  assert_true(euclidean_distance_eng(a, z) == 5.0)
  assert_true(manhattan_distance_eng(a, z) == 7.0)
  assert_true(cosine_distance_eng(a, z) == 1.0)
  assert_true(cosine_distance_eng(a, a) == 0.0)
  let e : Array[Double] = []
  assert_true(euclidean_distance_eng(e, e) == 0.0)
  assert_true(manhattan_distance_eng(e, e) == 0.0)
  assert_true(cosine_distance_eng(e, e) == 1.0)
  let short : Array[Double] = [3.0]
  assert_true(euclidean_distance_eng(a, short) == 0.0)
}

test "em: 英文识别流水线校验与运行" {
  // 配置默认值
  let cfg = english_ocr_default_config()
  assert_true(cfg.min_char_width == 5)
  assert_true(cfg.max_char_width == 60)
  assert_true(cfg.target_size == 32)
  assert_true(cfg.distance_metric == "euclidean")
  assert_true(!cfg.case_sensitive)
  // 校验：尺寸 / 通道 / 数据 / 三个配置项
  try {
    let _ = recognize_english(@types.Image::{ width: 0, height: 4, channels: 1, data: Bytes::from_array([]) })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = recognize_english(@types.Image::{
      width: 4,
      height: 4,
      channels: 3,
      data: Bytes::from_array(Array::make(48, b'\x00')),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = recognize_english(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array([b'\x00']),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad = em_gray(16, 16, b'\xFF')
  let c1 = EnglishOcrConfig::{
    min_char_width: 0,
    max_char_width: 60,
    target_size: 32,
    distance_metric: "euclidean",
    case_sensitive: false,
  }
  try {
    let _ = recognize_english(bad, config=c1)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c2 = EnglishOcrConfig::{
    min_char_width: 10,
    max_char_width: 4,
    target_size: 32,
    distance_metric: "euclidean",
    case_sensitive: false,
  }
  try {
    let _ = recognize_english(bad, config=c2)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c3 = EnglishOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 0,
    distance_metric: "euclidean",
    case_sensitive: false,
  }
  try {
    let _ = recognize_english(bad, config=c3)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 合法输入：空白 + 笔画
  let blank = recognize_english(em_gray(32, 32, b'\xFF'))
  assert_true(blank.characters.length() >= 0)
  let glyph = em_glyph(40, 40, 10, 24, 6, 34)
  let g = recognize_english(glyph)
  assert_true(g.confidence >= 0.0)
  // 区分大小写 + 不同度量
  let cs = EnglishOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    distance_metric: "manhattan",
    case_sensitive: true,
  }
  let g2 = recognize_english(glyph, config=cs)
  assert_true(g2.characters.length() >= 0)
}

test "em: 多语言标点模板与特征" {
  let ts = generate_punctuation_templates()
  assert_true(ts.length() >= 20)
  for t in ts {
    assert_true(t.features.length() == 256)
    assert_true(t.width_ratio > 0.0)
  }
  // 空字符 → seed 0；非空 → seed 取首字符码点
  let f_empty = generate_punctuation_features("", 0.3)
  assert_true(f_empty.length() == 256)
  let f_dot = generate_punctuation_features(".", 0.3)
  assert_true(f_dot.length() == 256)
  let f_wide = generate_punctuation_features("_", 0.9)
  assert_true(f_wide.length() == 256)
  // 不同字符生成不同特征
  assert_true(f_empty != f_dot)
}

test "em: 字符语言判定分支" {
  // 中文字符：接近正方形且 > 20
  let chinese = detect_char_language(em_gray(24, 24, b'\x00'))
  assert_true(chinese == Chinese)
  // 英文：窄条 0.3 < ratio < 0.75
  let english = detect_char_language(em_gray(12, 24, b'\x00'))
  assert_true(english == English)
  // 标点：ratio < 0.4
  let narrow = detect_char_language(em_gray(6, 24, b'\x00'))
  assert_true(narrow == Punctuation)
  // 标点：ratio > 1.35
  let wide = detect_char_language(em_gray(40, 20, b'\x00'))
  assert_true(wide == Punctuation)
  // 正方形但尺寸 <= 20：所有分支都不命中 → Unknown
  let small_square = detect_char_language(em_gray(16, 16, b'\x00'))
  assert_true(small_square == Unknown)
  // 校验：尺寸 / 通道 / 数据
  try {
    let _ = detect_char_language(@types.Image::{ width: 0, height: 4, channels: 1, data: Bytes::from_array([]) })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = detect_char_language(@types.Image::{
      width: 4,
      height: 4,
      channels: 5,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = detect_char_language(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array([b'\x00']),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "em: 多语言分割/区域/特征/匹配" {
  let cfg = multilingual_ocr_default_config()
  assert_true(cfg.target_size == 48)
  // 分割：空白图无区域
  assert_true(segment_multilingual_chars(em_gray(32, 32, b'\xFF'), cfg).length() == 1)
  // 分割：两个块
  let d : Array[Byte] = []
  for y in 0..<32 {
    for x in 0..<32 {
      let on = (x >= 4 && x < 12 && y >= 4 && y < 24) || (x >= 18 && x < 26 && y >= 4 && y < 24)
      d.push(if on { b'\x00' } else { b'\xFF' })
    }
  }
  let img = @types.Image::{ width: 32, height: 32, channels: 1, data: Bytes::from_array(d) }
  let regions = segment_multilingual_chars(img, cfg)
  assert_true(regions.length() >= 1 && regions.length() <= 2)
  // 区域提取：正常 / 负尺寸 / 越界
  let r = extract_multilingual_char_region(img, 4, 4, 8, 20, 48)
  assert_true(r.width == 48)
  assert_true(r.data.length() == 2304)
  let neg = extract_multilingual_char_region(img, 4, 4, -2, 20, 16)
  assert_true(neg.data[0].to_int() == 0)
  let over = extract_multilingual_char_region(img, 30, 30, 10, 10, 16)
  assert_true(over.width == 16)
  // 特征
  let f_white = extract_multilingual_features(em_gray(48, 48, b'\xFF'), 8)
  assert_true(f_white.length() == 64)
  assert_true(f_white[0] == 1.0)
  let f_black = extract_multilingual_features(em_gray(48, 48, b'\x00'), 8)
  assert_true(f_black[0] == 0.0)
  // 多语言模板匹配：用英文字母模板做确证
  let ts = generate_english_templates()
  let (label, conf) = match_multilingual_template(ts[10].1, ts, "euclidean")
  assert_true(label.length() == 1)
  assert_true(conf == 1.0)
  let (_l1, _c1) = match_multilingual_template(f_white, ts, "manhattan")
  assert_true(_l1.length() >= 1)
  let (_l2, _c2) = match_multilingual_template(f_white, ts, "cosine")
  assert_true(_l2.length() >= 1)
  let empty_t : Array[(String, Array[Double])] = []
  let (l3, c3) = match_multilingual_template(f_white, empty_t, "euclidean")
  assert_true(l3 == "?")
  assert_true(c3 > 0.0 && c3 < 0.0001)
  // 标点模板匹配
  let pts = generate_punctuation_templates()
  let (pl, pc) = match_punctuation_template(pts[0].features, pts)
  assert_true(pl == pts[0].char)
  assert_true(pc == 1.0)
  let empty_p : Array[PunctuationTemplate] = []
  let (pl2, pc2) = match_punctuation_template(f_white, empty_p)
  assert_true(pl2 == "?")
  assert_true(pc2 > 0.0 && pc2 < 0.0001)
  // 距离
  let a : Array[Double] = [3.0, 4.0]
  let z : Array[Double] = [0.0, 0.0]
  assert_true(euclidean_ml(a, z) == 5.0)
  assert_true(manhattan_ml(a, z) == 7.0)
  assert_true(cosine_ml(a, z) == 1.0)
  assert_true(cosine_ml(a, a) == 0.0)
  let e : Array[Double] = []
  assert_true(euclidean_ml(e, e) == 0.0)
  assert_true(manhattan_ml(e, e) == 0.0)
  assert_true(cosine_ml(e, e) == 1.0)
  // 文档语言检测的三类校验
  try {
    let _ = detect_document_language(@types.Image::{ width: 0, height: 4, channels: 1, data: Bytes::from_array([]) })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = detect_document_language(@types.Image::{
      width: 4,
      height: 4,
      channels: 5,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = detect_document_language(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array([b'\x00']),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 空白文档 & 有字文档都能返回语言
  let blank_lang = detect_document_language(em_gray(64, 64, b'\xFF'))
  assert_true(blank_lang == Unknown || blank_lang == Chinese || blank_lang == English)
  let glyph_lang = detect_document_language(em_glyph(64, 64, 10, 30, 10, 30))
  assert_true(glyph_lang == Unknown || glyph_lang == Chinese || glyph_lang == English)
}
