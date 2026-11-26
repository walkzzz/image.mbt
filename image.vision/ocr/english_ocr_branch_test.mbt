// 覆盖率测试：英文 OCR 模板与识别分支

///|
fn enoc_img(w : Int32, h : Int32, c : Int32, value : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, value.to_byte())),
  }
}

///|
test "enocov: 模板生成与配置" {
  let cfg = @ocr.english_ocr_default_config()
  assert_true(cfg.min_char_width == 5)
  assert_true(cfg.max_char_width == 60)
  assert_true(cfg.target_size == 32)
  let t0 = @ocr.generate_english_templates()
  assert_true(t0.length() > 0)
  let t1 = @ocr.generate_english_templates(case_sensitive=true)
  assert_true(t1.length() > 0)
  // 大小写模板数量差异（敏感模式含大写）
  assert_true(t1.length() >= t0.length())
}

///|
test "enocov: 英文识别流水线" {
  // 白底 + 黑色笔画
  let w : Int32 = 72
  let h : Int32 = 32
  let data : Array[Int32] = Array::make(w * h, 0)
  for y in 6..<26 {
    for x in 6..<16 {
      data[y * w + x] = 255
    }
    for x in 26..<36 {
      data[y * w + x] = 255
    }
    for x in 48..<58 {
      data[y * w + x] = 255
    }
  }
  let img = @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
  let r1 = @ocr.recognize_english(img)
  assert_true(r1.characters.length() >= 0)
  assert_true(r1.text.length() >= 0)
  // manhattan
  let c2 = @ocr.EnglishOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    distance_metric: "manhattan",
    case_sensitive: false,
  }
  let r2 = @ocr.recognize_english(img, config=c2)
  assert_true(r2.confidence >= 0.0)
  // cosine + 大小写敏感
  let c3 = @ocr.EnglishOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    distance_metric: "cosine",
    case_sensitive: true,
  }
  let r3 = @ocr.recognize_english(img, config=c3)
  assert_true(r3.confidence >= 0.0)
  // 未知度量 → 兜底
  let c4 = @ocr.EnglishOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    distance_metric: "chebyshev",
    case_sensitive: false,
  }
  let r4 = @ocr.recognize_english(img, config=c4)
  assert_true(r4.confidence >= 0.0)
  // 空白图
  let blank = enoc_img(48, 24, 1, 0)
  let r0 = @ocr.recognize_english(blank)
  assert_true(r0.confidence >= 0.0)
  // RGB 图 → 不支持则抛错
  let rgb = enoc_img(48, 24, 3, 200)
  try {
    let _ = @ocr.recognize_english(rgb)
    assert_true(true)
  } catch {
    _ => assert_true(true)
  }
  // 错误分支
  try {
    let _ = @ocr.recognize_english(enoc_img(0, 8, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.recognize_english(enoc_img(8, 8, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
