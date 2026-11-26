// 覆盖测试：5×7 点阵字形与数字/字母渲染

///|
test "text: 全部数字字形" {
  for d in 0..<10 {
    let g = digit_glyph(d)
    assert_true(g.length() == 7)
  }
  let bad = digit_glyph(10)
  assert_true(bad.length() == 7)
  assert_true(bad[0] == 0)
  let neg = digit_glyph(-3)
  assert_true(neg.length() == 7)
}

///|
test "text: 全部字母字形" {
  for i in 0..<26 {
    let g = letter_glyph(i)
    assert_true(g.length() == 7)
  }
  let bad = letter_glyph(26)
  assert_true(bad.length() == 7)
  assert_true(bad[0] == 0)
}

///|
test "text: 数字渲染参数" {
  let img = render_digits([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  assert_true(img.channels == 1)
  // 10 个字形：inner_w = 10*6-1 = 59
  assert_true(img.width == (59 + 8) * 4)
  assert_true(img.height == (7 + 8) * 4)
  let ink = render_digits([8])
  let mut found = false
  for i in 0..<ink.data.length() {
    if ink.data[i].to_int() == 0 {
      found = true
    }
  }
  assert_true(found)
  // 空序列
  let empty = render_digits([])
  assert_true(empty.width == (1 + 8) * 4)
  // scale 钳制为 1，margin 钳制为 0
  let s1 = render_digits([1], scale=0, margin=-4)
  assert_true(s1.width == 5)
  assert_true(s1.height == 7)
  let s2 = render_digits([1], scale=1, margin=0)
  assert_true(s2.width == 5)
  // 非法字形走默认分支
  let s3 = render_digits([99])
  assert_true(s3.width == (5 + 8) * 4)
}

///|
test "text: 字母渲染参数" {
  let img = render_letters([0, 25])
  assert_true(img.width == (2 * 6 - 1 + 8) * 4)
  assert_true(img.height == (7 + 8) * 4)
  let ink = render_letters([0])
  let mut found = false
  for i in 0..<ink.data.length() {
    if ink.data[i].to_int() == 0 {
      found = true
    }
  }
  assert_true(found)
  let empty = render_letters([])
  assert_true(empty.height == (7 + 8) * 4)
  let s1 = render_letters([25], scale=-2, margin=-1)
  assert_true(s1.width == 5)
  let s2 = render_letters([99], scale=1, margin=0)
  assert_true(s2.width == 5)
}
