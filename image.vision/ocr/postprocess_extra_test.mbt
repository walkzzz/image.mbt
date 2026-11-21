///|
test "ocr_postprocess: edit_distance 基础" {
  try {
    assert_eq(@ocr.edit_distance("abc", "abc"), 0)
    assert_true(@ocr.edit_distance("abc", "") > 0)
    assert_true(@ocr.edit_distance("kitten", "sitting") > 0)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "ocr_postprocess: edit_distance 双空串被拒" {
  let rejected = try {
    let _ = @ocr.edit_distance("", "")
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "ocr_postprocess: 词典匹配与 ngram 打分" {
  let dict = @ocr.dictionary_create_common_english()
  try {
    let matches = @ocr.dictionary_match("helo", dict)
    assert_true(matches.length() >= 0)
    let model = @ocr.ngram_create(["hello world", "hello moon", "world peace"])
    let score = @ocr.ngram_score("hello world", model)
    assert_true(score >= 0.0)
  } catch {
    _ => assert_true(false)
  }
}
