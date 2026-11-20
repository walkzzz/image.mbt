///|
test "wbtest: log2_int 向下取整" {
  assert_eq(log2_int(1), 0)
  assert_eq(log2_int(2), 1)
  assert_eq(log2_int(3), 1)
  assert_eq(log2_int(8), 3)
  assert_eq(log2_int(9), 3)
  assert_eq(log2_int(1024), 10)
}

///|
test "wbtest: next_pow2 向上取整" {
  assert_eq(next_pow2(1), 1)
  assert_eq(next_pow2(2), 2)
  assert_eq(next_pow2(3), 4)
  assert_eq(next_pow2(8), 8)
  assert_eq(next_pow2(9), 16)
  assert_eq(next_pow2(1000), 1024)
}
