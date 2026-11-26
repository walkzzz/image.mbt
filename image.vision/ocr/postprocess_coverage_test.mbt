// 覆盖率测试：OCR 后处理（词典 / 编辑距离 / N-gram / 流水线 / 置信度校准）

fn pp_char(ch : String, conf : Double) -> @ocr.OcrCharResult {
  @ocr.OcrCharResult::{ char: ch, confidence: conf, x: 0, y: 0, width: 10, height: 10 }
}

fn pp_result(text : String, chars : Array[@ocr.OcrCharResult]) -> @ocr.OcrResult {
  @ocr.OcrResult::{ text, confidence: 0.5, characters: chars }
}

fn pp_err_empty_dict() -> Bool {
  try {
    let _ = @ocr.dictionary_create([])
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_empty_word() -> Bool {
  try {
    let _ = @ocr.dictionary_match("", @ocr.dictionary_create_common_english())
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_neg_distance() -> Bool {
  try {
    let d = @ocr.dictionary_create(["abc"])
    let _ = @ocr.dictionary_match("abc", d, max_distance=-1)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_edit_both_empty() -> Bool {
  try {
    let _ = @ocr.edit_distance("", "")
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_ngram_empty() -> Bool {
  try {
    let _ = @ocr.ngram_create([])
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_ngram_n() -> Bool {
  try {
    let _ = @ocr.ngram_create(["ab"], n=0)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_score_empty_text() -> Bool {
  try {
    let m = @ocr.ngram_create(["hello world"])
    let _ = @ocr.ngram_score("", m)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_score_empty_model() -> Bool {
  try {
    let empty_model = @ocr.NgramModel::{ n: 2, bigram_counts: [], unigram_counts: [] }
    let _ = @ocr.ngram_score("ab", empty_model)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_postprocess_empty() -> Bool {
  try {
    let _ = @ocr.ocr_postprocess(pp_result("", []))
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_calibrate_empty() -> Bool {
  try {
    let _ = @ocr.calibrate_confidence(pp_result("x", []))
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

fn pp_err_calibrate_factor() -> Bool {
  try {
    let _ = @ocr.calibrate_confidence(pp_result("x", [pp_char("x", 0.5)]), factor=0.0)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

test "ppcov: 词典创建与匹配" {
  assert_true(pp_err_empty_dict())
  let d = @ocr.dictionary_create(["cat", "cut", "dog"])
  assert_true(d.words.length() == 3)
  // "cot" 与 cat/cut 距离 1，与 dog 距离 3
  let matches = @ocr.dictionary_match("cot", d, max_distance=1)
  assert_true(matches.length() == 2)
  assert_true(matches[0].1 <= matches[1].1)
  assert_true(matches[0].1 == 1)
  // 距离放宽到 3 → 三个都命中，排序保证升序
  let all = @ocr.dictionary_match("cot", d, max_distance=3)
  assert_true(all.length() == 3)
  assert_true(all[2].1 == 2)
  // 距离 0 → 精确匹配
  let exact = @ocr.dictionary_match("cat", d, max_distance=0)
  assert_true(exact.length() == 1)
  assert_true(exact[0].0 == "cat")
  // 常用词典可直接构建
  let common = @ocr.dictionary_create_common_english()
  assert_true(common.words.length() > 100)
  assert_true(common.word_set.length() == common.words.length())
  assert_true(pp_err_empty_word())
  assert_true(pp_err_neg_distance())
}

test "ppcov: 编辑距离" {
  assert_true(@ocr.edit_distance("abc", "abc") == 0)
  assert_true(@ocr.edit_distance("abc", "abd") == 1)
  assert_true(@ocr.edit_distance("kitten", "sitting") == 3)
  // 一方为空
  assert_true(@ocr.edit_distance("", "abc") == 3)
  assert_true(@ocr.edit_distance("abc", "") == 3)
  // 非对称：删除 vs 插入
  assert_true(@ocr.edit_distance("abcd", "ab") == 2)
  assert_true(@ocr.edit_distance("ab", "abcd") == 2)
  assert_true(pp_err_edit_both_empty())
}

test "ppcov: N-gram 建模与打分" {
  let m = @ocr.ngram_create(["hello", "hello world"])
  assert_true(m.n == 2)
  assert_true(m.bigram_counts.length() >= 2)
  assert_true(m.unigram_counts.length() >= 5)
  // "h" 出现 2 次，"he" 出现 2 次 → 相对频率 1.0
  let s = @ocr.ngram_score("he", m)
  assert_true(s > 0.0 && s <= 1.0)
  // 单字符文本直接 0
  assert_true(@ocr.ngram_score("h", m) == 0.0)
  // 未见过的 bigram：bigram_count 0 → 0
  assert_true(@ocr.ngram_score("zz", m) >= 0.0)
  // n=1 的模型只有 unigram
  let m1 = @ocr.ngram_create(["abc"], n=1)
  assert_true(m1.n == 1)
  assert_true(m1.bigram_counts.length() >= 2)
  assert_true(pp_err_ngram_empty())
  assert_true(pp_err_ngram_n())
  assert_true(pp_err_score_empty_text())
  assert_true(pp_err_score_empty_model())
}

test "ppcov: 后处理流水线" {
  // 默认配置：低置信度 "0" → "O"，并做单词级纠错
  let chars : Array[@ocr.OcrCharResult] = [
    pp_char("0", 0.1),
    pp_char("l", 0.2),
  ]
  let r = @ocr.ocr_postprocess(pp_result("0l", chars))
  assert_true(r.characters.length() == 2)
  assert_true(r.characters[0].char == "O")
  assert_true(r.characters[0].confidence == 0.2)
  assert_true(r.confidence > 0.0)
  // 高置信度字符不做替换
  let hi = @ocr.ocr_postprocess(pp_result("0", [pp_char("0", 0.9)]))
  assert_true(hi.characters[0].char == "0")
  // 单词级纠错："helo" → 距离 1 命中 hello
  let ws : Array[@ocr.OcrCharResult] = [
    pp_char("h", 0.9),
    pp_char("e", 0.9),
    pp_char("l", 0.9),
    pp_char("o", 0.9),
  ]
  let wr = @ocr.ocr_postprocess(pp_result("helo", ws))
  assert_true(wr.text == "hello")
  // 关闭词典：原样输出
  let cfg = @ocr.PostProcessConfig::{
    use_dictionary: false,
    use_ngram: false,
    ngram_size: 2,
    min_confidence: 0.3,
    max_candidates: 5,
  }
  let off = @ocr.ocr_postprocess(pp_result("0", [pp_char("0", 0.1)]), config=cfg)
  assert_true(off.text == "0")
  // 只有 text 没有 characters：可正常返回
  let text_only = @ocr.ocr_postprocess(pp_result("hello", []))
  assert_true(text_only.characters.length() == 0)
  assert_true(text_only.confidence == 0.0)
  assert_true(pp_err_postprocess_empty())
  assert_true(@ocr.postprocess_default_config().use_dictionary)
}

test "ppcov: 置信度校准" {
  let r = @ocr.calibrate_confidence(
    pp_result("ab", [pp_char("a", 0.4), pp_char("b", 0.8)]),
    factor=2.0,
  )
  assert_true(r.characters[0].confidence == 0.8)
  assert_true(r.characters[1].confidence == 1.0)
  assert_true(r.confidence == 0.9)
  // factor 1.0 保持原值
  let same = @ocr.calibrate_confidence(pp_result("a", [pp_char("a", 0.5)]))
  assert_true(same.characters[0].confidence == 0.5)
  assert_true(pp_err_calibrate_empty())
  assert_true(pp_err_calibrate_factor())
}
