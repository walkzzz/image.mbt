// 白盒覆盖率：常用汉字字典构建

///|
test "cdt: 常用汉字字典基本形态" {
  let entries = get_dict_common_chinese_chars()
  assert_true(entries.length() > 10)
  assert_true(entries[0].char == "的")
  assert_true(entries[0].stroke_count == 8)
  assert_true(entries[0].pinyin.length() > 0)
  let mut all_single = true
  for e in entries {
    if e.char.length() != 1 {
      all_single = false
    }
  }
  assert_true(all_single)
}
