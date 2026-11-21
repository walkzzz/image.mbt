///|
fn acc_make_binary(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h, b'\x00')
  for y in 2..<6 {
    for x in 2..<6 {
      data[y * w + x] = b'\xFF'
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "ocr_accuracy: 数据集创建 / 添加 / 统计" {
  let mut ds = @ocr.dataset_create()
  ds = @ocr.dataset_add_sample(ds, [0.1, 0.2], "A")
  ds = @ocr.dataset_add_sample(ds, [0.3, 0.4], "A")
  ds = @ocr.dataset_add_sample(ds, [0.5, 0.6], "B")
  let (n, c, counts) = @ocr.dataset_stats(ds)
  assert_eq(n, 3)
  assert_eq(c, 2)
  assert_eq(counts.length(), 2)
}

///|
test "ocr_accuracy: 特征增强与 Hu 矩" {
  let aug = @ocr.augment_features([1.0, 2.0, 3.0])
  assert_eq(aug.length(), 3)
  let img = acc_make_binary(8, 8)
  try {
    let hm = @ocr.hu_moments_features(img)
    assert_true(hm.length() > 0)
    let combined = @ocr.extract_combined_ocr_features(img)
    assert_true(combined.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
}
