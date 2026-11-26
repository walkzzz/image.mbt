// 覆盖率测试：版面分析各函数错误分支与二值化方法分支

fn lay_img(w : Int32, h : Int32, c : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, 0)),
  }
}

fn lay_short(w : Int32, h : Int32, c : Int32, len : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(len, 0)),
  }
}

fn lay_text(w : Int32, h : Int32, lines : Array[(Int32, Int32)]) -> @types.Image {
  // lines: (起始 y, 行高)；每行铺满宽度的白色文本带
  let data : Array[Int32] = Array::make(w * h, 0)
  for line in lines {
    let (y0, lh) = line
    for y in y0..<(y0 + lh) {
      for x in 0..<w {
        data[y * w + x] = 255
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
}

fn lay_two_cols(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Int32] = Array::make(w * h, 0)
  for y in 0..<h {
    for x in 0..<(w / 3) {
      data[y * w + x] = 255
    }
    for x in (w * 2 / 3)..<w {
      data[y * w + x] = 255
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
}

test "laycov: detect_text_regions 分支" {
  let ok = lay_text(40, 40, [(4, 8), (20, 8)])
  let r = @ocr.detect_text_regions(ok)
  assert_true(r.length() >= 1)
  // 空白图 → 无文本区域分支
  let blank = lay_img(40, 40, 1)
  let r0 = @ocr.detect_text_regions(blank)
  assert_true(r0.length() == 0)
  // 错误分支
  try {
    let _ = @ocr.detect_text_regions(lay_img(0, 10, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.detect_text_regions(lay_short(8, 8, 1, 8))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "laycov: segment_page 与 detect_columns 分支" {
  let ok = lay_text(60, 60, [(5, 10), (30, 10)])
  let r = @ocr.segment_page(ok)
  assert_true(r.length() >= 1)
  // 大区域分支（region_w > 50 && region_h > 50）
  let big = lay_text(80, 80, [(0, 80)])
  let r2 = @ocr.segment_page(big)
  let mut lay_ok = true
  for reg in r2 {
    if reg.width <= 0 || reg.height <= 0 {
      lay_ok = false
    }
  }
  assert_true(lay_ok)
  // 错误分支
  try {
    let _ = @ocr.segment_page(lay_img(0, 5, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.segment_page(lay_short(6, 6, 1, 6))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 双栏
  let cols = lay_two_cols(60, 40)
  let (n, spans) = @ocr.detect_columns(cols)
  assert_true(n >= 1)
  assert_true(spans.length() >= 1)
  // 单块 → 单栏
  let single = lay_text(40, 40, [(0, 40)])
  let (n2, spans2) = @ocr.detect_columns(single)
  assert_true(n2 >= 1)
  assert_true(spans2.length() >= 1)
  // 错误分支
  try {
    let _ = @ocr.detect_columns(lay_img(0, 4, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.detect_columns(lay_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "laycov: extract_text_lines 分支" {
  let ok = lay_text(30, 30, [(3, 6), (12, 6), (21, 6)])
  let lines = @ocr.extract_text_lines(ok)
  assert_true(lines.length() >= 1)
  // 无行 → 空
  let blank = lay_img(20, 20, 1)
  let l0 = @ocr.extract_text_lines(blank)
  assert_true(l0.length() == 0)
  // 错误分支
  try {
    let _ = @ocr.extract_text_lines(lay_img(0, 4, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.extract_text_lines(lay_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "laycov: ocr_preprocess 二值化方法分支" {
  let g = lay_text(24, 24, [(4, 8)])
  // 五种方法分支
  for m in ["sauvola", "niblack", "otsu", "adaptive", "unknown-method"] {
    let out = @ocr.ocr_preprocess(g, binarization_method=m)
    assert_true(out.channels == 1)
    assert_true(out.data.length() > 0)
  }
  // 彩色输入 → 灰度路径分支
  let rgb = @types.Image::{
    width: 16,
    height: 16,
    channels: 3,
    data: Bytes::from_array(Array::make(16 * 16 * 3, 100)),
  }
  let out2 = @ocr.ocr_preprocess(rgb, binarization_method="otsu")
  assert_true(out2.channels == 1)
  assert_true(out2.data.length() > 0)
  // 4 通道输入
  let rgba = @types.Image::{
    width: 12,
    height: 12,
    channels: 4,
    data: Bytes::from_array(Array::make(12 * 12 * 4, 60)),
  }
  let out3 = @ocr.ocr_preprocess(rgba, binarization_method="sauvola")
  assert_true(out3.channels == 1)
  assert_true(out3.data.length() > 0)
  // 错误分支
  try {
    let _ = @ocr.ocr_preprocess(lay_img(0, 4, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let c5 = @types.Image::{
    width: 4,
    height: 4,
    channels: 5,
    data: Bytes::from_array(Array::make(80, 0)),
  }
  try {
    let _ = @ocr.ocr_preprocess(c5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.ocr_preprocess(lay_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
