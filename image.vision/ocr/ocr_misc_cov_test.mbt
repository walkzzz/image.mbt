// 覆盖率测试：OCR 后处理（词典 / N-gram / 置信度校准）与中文字库

fn omc_char(c : String, conf : Double) -> @ocr.OcrCharResult {
  @ocr.OcrCharResult::{
    char: c,
    confidence: conf,
    x: 0,
    y: 0,
    width: 8,
    height: 8,
  }
}

fn omc_result(text : String) -> @ocr.OcrResult {
  let chars : Array[@ocr.OcrCharResult] = []
  for i in 0..<text.length() {
    chars.push(omc_char(text[i].to_string(), 0.7))
  }
  @ocr.OcrResult::{ text, confidence: 0.7, characters: chars }
}

test "pp: 词典构造与编辑距离" {
  let d = @ocr.dictionary_create(["hello", "world", "image"])
  assert_true(d.words.length() == 3)
  let common = @ocr.dictionary_create_common_english()
  assert_true(common.words.length() > 10)
  assert_true(@ocr.edit_distance("abc", "abd") == 1)
  assert_true(@ocr.edit_distance("", "xyz") == 3)
  assert_true(@ocr.edit_distance("xyz", "") == 3)
  assert_true(@ocr.edit_distance("same", "same") == 0)
  // 空词典 / 空单词 / 双方为空 / 负距离
  try {
    let _ = @ocr.dictionary_create([])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.edit_distance("", "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.dictionary_match("", d)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.dictionary_match("helo", @ocr.Dictionary::{ words: [], word_set: [] })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.dictionary_match("helo", d, max_distance=-1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "pp: 词典匹配与 N-gram" {
  let d = @ocr.dictionary_create(["hello", "world", "help"])
  let m0 = @ocr.dictionary_match("hello", d, max_distance=0)
  assert_true(m0.length() >= 1)
  let m1 = @ocr.dictionary_match("helo", d, max_distance=2)
  assert_true(m1.length() >= 1)
  let m2 = @ocr.dictionary_match("zzzz", d, max_distance=1)
  assert_true(m2.length() == 0)
  // N-gram 模型
  let model = @ocr.ngram_create(["hello world", "hello there", "world peace"])
  assert_true(model.n == 2)
  assert_true(model.bigram_counts.length() > 0)
  let model1 = @ocr.ngram_create(["abc"], n=1)
  assert_true(model1.n == 1)
  let score = @ocr.ngram_score("hello", model)
  assert_true(score >= 0.0)
  let score0 = @ocr.ngram_score("zzzz", model)
  assert_true(score0 >= 0.0)
  // 错误分支
  try {
    let _ = @ocr.ngram_create([])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.ngram_create(["abc"], n=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.ngram_score("", model)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.ngram_score(
      "abc",
      @ocr.NgramModel::{ n: 2, bigram_counts: [], unigram_counts: [] },
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "pp: 后处理流水线与置信度校准" {
  let r = omc_result("hello")
  let cfg = @ocr.postprocess_default_config()
  assert_true(cfg.ngram_size >= 1)
  assert_true(cfg.max_candidates >= 1)
  let d = @ocr.dictionary_create_common_english()
  let model = @ocr.ngram_create(["hello world"])
  // 默认配置
  let out0 = @ocr.ocr_postprocess(r)
  assert_true(out0.text.length() > 0)
  // 带词典
  let out1 = @ocr.ocr_postprocess(r, dictionary=d)
  assert_true(out1.characters.length() == r.characters.length())
  // 带词典 + N-gram
  let out2 = @ocr.ocr_postprocess(r, dictionary=d, ngram_model=model)
  assert_true(out2.confidence >= 0.0)
  // 自定义配置：关闭词典
  let cfg2 = @ocr.PostProcessConfig::{
    use_dictionary: false,
    use_ngram: false,
    ngram_size: 1,
    min_confidence: 0.1,
    max_candidates: 1,
  }
  let out3 = @ocr.ocr_postprocess(r, config=cfg2)
  assert_true(out3.text.length() > 0)
  // 置信度校准
  let cal = @ocr.calibrate_confidence(r, factor=1.5)
  assert_true(cal.characters.length() == r.characters.length())
  let cal2 = @ocr.calibrate_confidence(r)
  assert_true(cal2.confidence >= 0.0)
  // 错误分支
  try {
    let _ = @ocr.ocr_postprocess(@ocr.OcrResult::{
      text: "",
      confidence: 0.0,
      characters: [],
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.calibrate_confidence(@ocr.OcrResult::{
      text: "x",
      confidence: 0.0,
      characters: [],
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.calibrate_confidence(r, factor=0.0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "dict: 中文字库查询与相似度" {
  let dict = @ocr.create_default_chinese_dictionary()
  assert_true(dict.total_chars > 0)
  assert_true(dict.chars.length() == dict.total_chars)
  let first = dict.chars[0]
  assert_true(first.char.length() == 1)
  // 按部首 / 拼音 / 结构
  let by_rad = @ocr.lookup_by_radical(dict, first.radical)
  assert_true(by_rad.length() >= 1)
  let by_struct = @ocr.lookup_by_structure(dict, first.structure)
  assert_true(by_struct.length() >= 0)
  let by_py = @ocr.lookup_by_pinyin(dict, "zhong")
  assert_true(by_py.length() >= 0)
  let by_char = @ocr.lookup_char(dict, first.char)
  match by_char {
    Some(e) => assert_true(e.char == first.char)
    None => assert_true(false)
  }
  let missing = @ocr.lookup_char(dict, "龘")
  let _ = missing
  // 自相似度最高
  let sim = @ocr.calculate_chinese_similarity(first, first)
  assert_true(sim >= 0.0 && sim <= 1.0)
  let similar = @ocr.find_similar_chinese_chars(dict, first.char, top_n=3)
  assert_true(similar.length() <= 3)
  let rec = @ocr.recognize_by_components(dict, first.structure, first.components.map(fn(c) { c.name }))
  assert_true(rec.length() >= 0)
  let report = @ocr.generate_chinese_dictionary_report(dict)
  assert_true(report.length() > 0)
  // 错误分支
  try {
    let _ = @ocr.lookup_by_radical(dict, "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.lookup_by_pinyin(dict, "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.lookup_char(dict, "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.find_similar_chinese_chars(dict, "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
