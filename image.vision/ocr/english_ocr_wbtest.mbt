///|
fn wb_letter_h() -> @types.Image {
  let w = 10
  let h = 10
  let data : Array[Byte] = Array::make(w * h, b'\xFF')
  for y in 2..<8 {
    data[y * w + 2] = b'\x00'
    data[y * w + 7] = b'\x00'
  }
  for x in 2..<8 {
    data[5 * w + x] = b'\x00'
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "wbtest: extract_char_features + match_template（多距离度量）" {
  let img = wb_letter_h()
  let feats = extract_char_features_english(img, 8)
  assert_eq(feats.length(), 64)
  let templates = generate_english_templates(case_sensitive=true)
  assert_true(templates.length() >= 10)
  let (label, dist) = match_template_english(feats, templates, "euclidean")
  assert_true(label.length() > 0)
  assert_true(dist >= 0.0)
  let _ = match_template_english(feats, templates, "manhattan")
  let _ = match_template_english(feats, templates, "cosine")
  let _ = match_template_english(feats, templates, "chebyshev")
  let _ = match_template_english(feats, templates, "unknown")
}

///|
test "wbtest: 小图特征提取边界" {
  let tiny = @types.Image::{
    width: 3,
    height: 3,
    channels: 1,
    data: Bytes::from_array([
      b'\x00', b'\xFF', b'\x00', b'\xFF', b'\x00', b'\xFF', b'\x00', b'\xFF', b'\x00',
    ]),
  }
  let feats = extract_char_features_english(tiny, 4)
  assert_eq(feats.length(), 16)
  let templates = generate_english_templates(case_sensitive=false)
  let (label, _) = match_template_english(feats, templates, "euclidean")
  assert_true(label.length() > 0)
}
