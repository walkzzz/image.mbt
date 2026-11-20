///|
test "wbtest: png_channels 标准颜色类型" {
  assert_eq(png_channels(0), Some(1))
  assert_eq(png_channels(2), Some(3))
  assert_eq(png_channels(3), Some(1))
  assert_eq(png_channels(4), Some(2))
  assert_eq(png_channels(6), Some(4))
  assert_eq(png_channels(1), None)
  assert_eq(png_channels(5), None)
  assert_eq(png_channels(7), None)
}

///|
test "wbtest: paeth_predict 三分支" {
  // p = a + b - c；pa/pb/pc 最近者胜
  assert_eq(paeth_predict(100, 50, 10), 100)
  assert_eq(paeth_predict(10, 200, 10), 200)
  assert_eq(paeth_predict(10, 20, 15), 15)
  assert_eq(paeth_predict(0, 0, 0), 0)
}
