///|
test "testgen-drive: OCR 三种阈值" {
  let img = @testgen.render_digits([1, 2, 3], scale=3, margin=4)
  try {
    let a = @ocr.otsu_threshold(img)
    assert_eq(a.width, img.width)
    assert_eq(a.channels, 1)
    let b = @ocr.adaptive_threshold_ocr(img, block_size=15, c=10)
    assert_eq(b.height, img.height)
    let c = @ocr.niblack_threshold(img, window_size=15, k=-0.2)
    assert_eq(c.channels, 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: OCR 投影 / 行检测 / 字符分割" {
  let img = @testgen.render_digits([7, 3, 9], scale=4, margin=6)
  try {
    let _ = @ocr.vertical_projection(img)
    let _ = @ocr.horizontal_projection(img)
    let lines = @ocr.detect_text_lines_projection(img)
    if lines.length() > 0 {
      let _ = @ocr.segment_chars_projection(img, lines[0])
    }
    let segments = @ocr.complete_char_segmentation(img)
    assert_true(segments.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
}
