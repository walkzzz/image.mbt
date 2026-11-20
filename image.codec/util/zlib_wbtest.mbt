///|
test "wbtest: crc32_table 256 项且首项为 0" {
  let table = crc32_table()
  assert_eq(table.length(), 256)
  assert_eq(table[0].to_int(), 0)
  assert_true(table[1].to_int() != 0)
  assert_true(table[255].to_int() != 0)
}

///|
test "wbtest: length_base_extra RFC1951 边界" {
  assert_eq(length_base_extra(0), (3, 0))
  assert_eq(length_base_extra(8), (11, 1))
  assert_eq(length_base_extra(28), (258, 0))
  assert_eq(length_base_extra(-1), (0, 0))
  assert_eq(length_base_extra(29), (0, 0))
}

///|
test "wbtest: distance_base_extra RFC1951 边界" {
  assert_eq(distance_base_extra(0), (1, 0))
  assert_eq(distance_base_extra(4), (5, 1))
  assert_eq(distance_base_extra(29), (24577, 13))
  assert_eq(distance_base_extra(30), (0, 0))
  assert_eq(distance_base_extra(-1), (0, 0))
}
