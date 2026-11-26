// 白盒覆盖率：英文字符模板生成与像素填充

///|
test "eot: 像素块填充" {
  let size = 8
  let f : Array[Double] = Array::make(size * size, 0.0)
  set_char_pixels(f, size, 1, 1, 2, 2)
  assert_true(f[1 * size + 1] == 1.0)
  assert_true(f[2 * size + 2] == 1.0)
  assert_true(f[0] == 0.0)
  // 越界填充不 panic
  set_char_pixels(f, size, 7, 7, 4, 4)
  assert_true(f[7 * size + 7] == 1.0)
}

///|
test "eot: 常见字符模板非空" {
  let t0 = generate_char_template_simple("0")
  assert_true(t0.length() == 64)
  let mut sum = 0.0
  for v in t0 {
    sum += v
  }
  assert_true(sum > 0.0)
  let ta = generate_char_template_simple("A")
  let mut sum_a = 0.0
  for v in ta {
    sum_a += v
  }
  assert_true(sum_a > 0.0)
  let tl = generate_char_template_simple("l")
  let mut sum_l = 0.0
  for v in tl {
    sum_l += v
  }
  assert_true(sum_l > 0.0)
  // 未知字符走「中心点」默认模板
  let tx = generate_char_template_simple("Ω")
  let mut sum_x = 0.0
  for v in tx {
    sum_x += v
  }
  assert_true(sum_x > 0.0)
}
