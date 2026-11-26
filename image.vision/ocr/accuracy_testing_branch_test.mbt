// 覆盖率测试：OCR 准确率评估体系

fn acc_stats(
  char_acc : Double,
  word_acc : Double,
  f1 : Double,
) -> @ocr.AccuracyStats {
  @ocr.AccuracyStats::{
    total_chars: 10,
    correct_chars: (char_acc * 10.0).to_int(),
    char_accuracy: char_acc,
    total_words: 5,
    correct_words: (word_acc * 5.0).to_int(),
    word_accuracy: word_acc,
    total_lines: 2,
    correct_lines: 2,
    line_accuracy: 1.0,
    false_positives: 0,
    false_negatives: 0,
    precision: char_acc,
    recall: char_acc,
    f1_score: f1,
  }
}

test "accov: 字符/词准确率与编辑距离" {
  // 空 × 空 → 1.0；空 × 非空 → 0.0
  assert_true(@ocr.calculate_char_accuracy("", "") == 1.0)
  assert_true(@ocr.calculate_char_accuracy("", "abc") == 0.0)
  // 完全一致
  assert_true(@ocr.calculate_char_accuracy("你好", "你好") == 1.0)
  // 部分一致
  let half = @ocr.calculate_char_accuracy("abcd", "abxx")
  assert_true(half == 0.5)
  // 实际更长
  let longer = @ocr.calculate_char_accuracy("ab", "abcd")
  assert_true(longer >= 0.0)
  // 词准确率
  assert_true(@ocr.calculate_word_accuracy("hello world", "hello world") == 1.0)
  assert_true(@ocr.calculate_word_accuracy("", "") == 1.0)
  let w1 = @ocr.calculate_word_accuracy("hello world", "hello")
  assert_true(w1 >= 0.0)
  let w2 = @ocr.calculate_word_accuracy("a b c", "x y z")
  assert_true(w2 >= 0.0)
  assert_true(w2 <= 1.0)
  // 编辑距离
  assert_true(@ocr.calculate_edit_distance("", "") == 0)
  assert_true(@ocr.calculate_edit_distance("abc", "") == 3)
  assert_true(@ocr.calculate_edit_distance("", "abc") == 3)
  assert_true(@ocr.calculate_edit_distance("kitten", "sitting") == 3)
  assert_true(@ocr.calculate_edit_distance("same", "same") == 0)
}

test "accov: 统计与报告" {
  // 正常输入
  let stats = @ocr.calculate_accuracy_stats(
    ["hello world", "second line"],
    ["hello world", "second line"],
  )
  assert_true(stats.char_accuracy >= 0.0)
  assert_true(stats.word_accuracy >= 0.0)
  assert_true(stats.line_accuracy >= 0.0)
  assert_true(stats.total_chars > 0)
  // 部分错误 + 行数不等
  let stats2 = @ocr.calculate_accuracy_stats(
    ["abc", "def", "ghi"],
    ["abx", "de"],
  )
  assert_true(stats2.line_accuracy < 1.0)
  assert_true(stats2.false_positives >= 0)
  assert_true(stats2.false_negatives >= 0)
  // 空输入 → 抛错
  try {
    let _ = @ocr.calculate_accuracy_stats([], ["a"])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.calculate_accuracy_stats(["a"], [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 准确率报告
  let rep = @ocr.generate_accuracy_report(stats, "demo-set")
  assert_true(rep.length() > 0)
  // 性能报告：总时间为 0 走兜底分母
  let bench = @ocr.PerformanceBenchmark::{
    total_time_ms: 0.0,
    preprocess_time_ms: 0.0,
    layout_time_ms: 0.0,
    recognition_time_ms: 0.0,
    postprocess_time_ms: 0.0,
    pages_per_second: 0.0,
    chars_per_second: 0.0,
    memory_usage_mb: 10.0,
    cpu_usage_percent: 5.0,
  }
  let prep = @ocr.generate_performance_report(bench, "demo-set")
  assert_true(prep.length() > 0)
  let bench2 = @ocr.PerformanceBenchmark::{
    total_time_ms: 100.0,
    preprocess_time_ms: 10.0,
    layout_time_ms: 20.0,
    recognition_time_ms: 50.0,
    postprocess_time_ms: 20.0,
    pages_per_second: 10.0,
    chars_per_second: 500.0,
    memory_usage_mb: 10.0,
    cpu_usage_percent: 5.0,
  }
  let prep2 = @ocr.generate_performance_report(bench2, "demo-set")
  assert_true(prep2.length() > 0)
}

test "accov: 阈值校验" {
  let pass = @ocr.check_accuracy_threshold(acc_stats(0.99, 0.99, 0.99))
  let (ok1, issues1) = pass
  assert_true(ok1)
  assert_true(issues1.length() == 0)
  // 不达标
  let fail = @ocr.check_accuracy_threshold(
    acc_stats(0.5, 0.5, 0.5),
    min_char_accuracy=0.9,
  )
  let (ok2, issues2) = fail
  assert_true(!ok2)
  assert_true(issues2.length() > 0)
  // 阈值越界 → 抛错
  try {
    let _ = @ocr.check_accuracy_threshold(acc_stats(0.9, 0.9, 0.9), min_char_accuracy=1.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.check_accuracy_threshold(acc_stats(0.9, 0.9, 0.9), min_word_accuracy=(-0.5))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.check_accuracy_threshold(acc_stats(0.9, 0.9, 0.9), min_f1_score=2.0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
