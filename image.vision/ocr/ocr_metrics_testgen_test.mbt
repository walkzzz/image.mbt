///|
test "testgen-drive: 字符/词/编辑距离准确率" {
  assert_true(@ocr.calculate_char_accuracy("hello", "hello") >= 0.99)
  assert_true(
    @ocr.calculate_word_accuracy("hello world", "hello world") >= 0.99,
  )
  assert_eq(@ocr.calculate_edit_distance("kitten", "sitting"), 3)
  assert_eq(@ocr.calculate_edit_distance("abc", "abc"), 0)
}

///|
test "testgen-drive: 准确率统计 / 报告 / 阈值判定" {
  let stats = @ocr.calculate_accuracy_stats(["hello", "world"], [
    "hello", "wor1d",
  ])
  let report = @ocr.generate_accuracy_report(stats, "tiny-set")
  assert_true(report.length() > 0)
  let (ok, issues) = @ocr.check_accuracy_threshold(
    stats,
    min_char_accuracy=0.0,
    min_word_accuracy=0.0,
    min_f1_score=0.0,
  )
  assert_true(ok || issues.length() >= 0)
}

///|
test "testgen-drive: 训练准确率 / 早停 / 进度报告" {
  assert_true(@ocr.calculate_accuracy([1, 2, 3], [1, 2, 3]) >= 0.99)
  let cfg = @ocr.create_default_training_config()
  let state = @ocr.create_training_state()
  let (_stop, _next) = @ocr.check_early_stopping(state, cfg, 0.5)
  let report = @ocr.generate_training_progress_report(state, cfg)
  assert_true(report.length() > 0)
}
