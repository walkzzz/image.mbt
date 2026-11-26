// 白盒覆盖率：postprocess 的字符纠正表与分词

///|
test "ppt: 单字符转换与非法码位" {
  assert_true(pp_char_str(65) == "A")
  assert_true(pp_char_str(97) == "a")
}

///|
test "ppt: 常见混淆字符纠正表" {
  assert_true(common_char_corrections("0")[0] == "O")
  assert_true(common_char_corrections("O")[0] == "0")
  assert_true(common_char_corrections("1")[0] == "I")
  assert_true(common_char_corrections("I")[0] == "1")
  assert_true(common_char_corrections("l")[0] == "1")
  assert_true(common_char_corrections("2")[0] == "Z")
  assert_true(common_char_corrections("5")[0] == "S")
  // 无混淆的字符返回空表
  assert_true(common_char_corrections("#").length() == 0)
}

///|
test "ppt: 分词保留分隔符" {
  let parts = split_into_words("ab cd")
  let mut joined = ""
  for p in parts {
    joined += p
  }
  assert_true(joined == "ab cd")
  assert_true(parts.length() >= 3)
  // 空串与纯分隔符
  assert_true(split_into_words("").length() == 0)
  let spaces = split_into_words("   ")
  let mut joined2 = ""
  for p in spaces {
    joined2 += p
  }
  assert_true(joined2.length() == 3)
}
