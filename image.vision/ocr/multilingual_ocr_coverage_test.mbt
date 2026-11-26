// 纯逻辑测试（全目标可用）
// 目标：multilingual_ocr_enhanced 的配置 / 字间空格 / 标点归一 / 语言模型后处理 / 输入校验

///|
fn moe_gray(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, fill)),
  }
}

///|
test "multilingual_ocr: 默认配置" {
  let cfg = @ocr.multilingual_ocr_enhanced_default_config()
  assert_true(cfg.enable_chinese)
  assert_true(cfg.enable_english)
  assert_true(cfg.enable_digits)
  assert_true(cfg.enable_punctuation)
  assert_true(!cfg.enable_japanese)
  assert_true(!cfg.enable_korean)
  assert_eq(cfg.target_size, 48)
  assert_eq(cfg.distance_metric, "euclidean")
  assert_true(cfg.auto_language_detection)
  assert_true(cfg.smart_spacing)
  assert_true(cfg.punctuation_normalization)
  assert_true(cfg.use_language_model)
}

///|
test "multilingual_ocr: 字间空格只在 CJK 与拉丁之间插入" {
  let langs : Array[String] = ["chinese", "english", "digit", "chinese"]
  let out = @ocr.smart_spacing_process("AB12", langs)
  assert_eq(out, "A B1 2")
  // 纯 CJK 不加空格
  let cjk : Array[String] = ["chinese", "chinese"]
  assert_eq(@ocr.smart_spacing_process("汉字", cjk), "汉字")
  // 纯拉丁不加空格
  let latin : Array[String] = ["english", "english"]
  assert_eq(@ocr.smart_spacing_process("ab", latin), "ab")
  // 长度不一致 / 空串直接返回原文
  let one : Array[String] = ["chinese"]
  assert_eq(@ocr.smart_spacing_process("abc", one), "abc")
  let none : Array[String] = []
  assert_eq(@ocr.smart_spacing_process("", none), "")
}

///|
fn moe_langs(n : Int32, lang : String) -> Array[String] {
  let out : Array[String] = []
  for _ in 0..<n {
    out.push(lang)
  }
  out
}

///|
test "multilingual_ocr: 标点按语境归一" {
  let zh_pairs : Array[(String, String)] = [
    ("ab,c.", "ab，c。"),
    ("ab!c?", "ab！c？"),
    ("ab;c:", "ab；c："),
    ("(ab)", "（ab）"),
  ]
  for (raw, want) in zh_pairs {
    assert_eq(
      @ocr.normalize_punctuation(raw, moe_langs(raw.length(), "chinese")),
      want,
    )
  }
  let en_pairs : Array[(String, String)] = [
    ("ab，c。", "ab,c."),
    ("ab！c？", "ab!c?"),
    ("ab；c：", "ab;c:"),
    ("（ab）", "(ab)"),
  ]
  for (raw, want) in en_pairs {
    assert_eq(
      @ocr.normalize_punctuation(raw, moe_langs(raw.length(), "english")),
      want,
    )
  }
  // 长度不一致直接返回原文
  assert_eq(@ocr.normalize_punctuation("abc", moe_langs(1, "chinese")), "abc")
}

///|
test "multilingual_ocr: 语言模型后处理只压低低置信度" {
  let conf : Array[Double] = [0.2, 0.3, 0.9]
  let langs : Array[String] = ["chinese", "chinese", "chinese"]
  let (text, out) = @ocr.language_model_postprocess("abc", langs, conf)
  assert_eq(text, "abc")
  assert_true(out[0] < 0.2)
  assert_eq(out[1], 0.3)
  assert_eq(out[2], 0.9)
}

///|
test "multilingual_ocr: 语言检测入口（正常 + 三类校验）" {
  let img = moe_gray(16, 16, b'\x20')
  let r = @ocr.detect_language_enhanced(img)
  assert_true(r.language.length() > 0)
  let mut hits = 0
  try {
    let _ = @ocr.detect_language_enhanced(@types.Image::{
      width: 0,
      height: 2,
      channels: 1,
      data: Bytes::from_array([]),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.detect_language_enhanced(@types.Image::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array(Array::make(12, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.detect_language_enhanced(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array(Array::make(3, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 3)
}

///|
test "multilingual_ocr: 智能分割入口（三类校验 + 空白图）" {
  let cfg = @ocr.multilingual_ocr_enhanced_default_config()
  let blank = moe_gray(12, 12, b'\x00')
  let segs = @ocr.smart_segment_chars(blank, cfg)
  assert_true(segs.length() >= 0)
  let mut hits = 0
  try {
    let _ = @ocr.smart_segment_chars(
      @types.Image::{
        width: 0,
        height: 2,
        channels: 1,
        data: Bytes::from_array([]),
      },
      cfg,
    )
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.smart_segment_chars(
      @types.Image::{
        width: 2,
        height: 2,
        channels: 3,
        data: Bytes::from_array(Array::make(12, b'\x00')),
      },
      cfg,
    )
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.smart_segment_chars(
      @types.Image::{
        width: 4,
        height: 4,
        channels: 1,
        data: Bytes::from_array(Array::make(3, b'\x00')),
      },
      cfg,
    )
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 3)
}

///|
test "multilingual_ocr: 完整流水线入口（三类校验）" {
  let mut hits = 0
  try {
    let _ = @ocr.recognize_multilingual_enhanced(@types.Image::{
      width: 0,
      height: 2,
      channels: 1,
      data: Bytes::from_array([]),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.recognize_multilingual_enhanced(@types.Image::{
      width: 2,
      height: 2,
      channels: 5,
      data: Bytes::from_array(Array::make(20, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.recognize_multilingual_enhanced(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array(Array::make(3, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 3)
}
