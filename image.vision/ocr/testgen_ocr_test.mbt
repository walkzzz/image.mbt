///|
test "testgen-drive: 数字渲染图进入 OCR 识别链路" {
  let img = @testgen.render_digits([1, 2, 3], scale=4, margin=4)
  try {
    let result = @ocr.recognize_digits(img)
    assert_true(result.characters.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: 更多数字与低倍渲染" {
  let img = @testgen.render_digits([0, 7, 8, 9], scale=3, margin=3)
  try {
    let _ = @ocr.recognize_digits(img)
    assert_true(true)
  } catch {
    _ => assert_true(false)
  }
}
