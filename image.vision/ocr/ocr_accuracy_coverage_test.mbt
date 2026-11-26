// 纯逻辑测试（全目标可用）
// 目标：ocr_accuracy 的数据集 / 特征增广 / Hu 矩 / 集成投票 / 组合特征入口

///|
fn oac_gray(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h) {
    data.push((i * 37 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "ocr_accuracy: 数据集创建 / 追加 / 统计" {
  let ds0 = @ocr.dataset_create()
  assert_eq(ds0.num_samples, 0)
  let ds1 = @ocr.dataset_add_sample(ds0, [1.0, 0.0], "a")
  assert_eq(ds1.num_samples, 1)
  assert_eq(ds1.num_classes, 1)
  let ds2 = @ocr.dataset_add_sample(ds1, [0.0, 1.0], "b")
  let ds3 = @ocr.dataset_add_sample(ds2, [1.0, 0.5], "a")
  assert_eq(ds3.num_samples, 3)
  assert_eq(ds3.num_classes, 2)
  let (n, c, counts) = @ocr.dataset_stats(ds3)
  assert_eq(n, 3)
  assert_eq(c, 2)
  let mut a_count = 0
  let mut b_count = 0
  for (label, k) in counts {
    if label == "a" {
      a_count = k
    } else if label == "b" {
      b_count = k
    }
  }
  assert_eq(a_count, 2)
  assert_eq(b_count, 1)
}

///|
test "ocr_accuracy: 特征增广把值夹在 [0,1]" {
  let feats : Array[Double] = [0.0, 0.5, 1.0, 0.999]
  let aug = @ocr.augment_features(feats, noise_level=0.5)
  assert_eq(aug.length(), 4)
  for v in aug {
    assert_true(v >= 0.0)
    assert_true(v <= 1.0)
  }
  // 默认噪声级别下也保持边界
  let aug2 = @ocr.augment_features(feats)
  assert_eq(aug2.length(), 4)
  for v in aug2 {
    assert_true(v >= 0.0)
    assert_true(v <= 1.0)
  }
}

///|
test "ocr_accuracy: Hu 矩 7 个特征（含全黑图）" {
  let img = oac_gray(8, 5)
  let h = @ocr.hu_moments_features(img)
  assert_eq(h.length(), 7)
  let black = @types.Image::{
    width: 3,
    height: 3,
    channels: 1,
    data: Bytes::from_array(Array::make(9, b'\x00')),
  }
  let hb = @ocr.hu_moments_features(black)
  assert_eq(hb.length(), 7)
  assert_eq(hb[0], 0.0)
}

///|
test "ocr_accuracy: Hu 矩输入校验" {
  let mut hits = 0
  let white2 = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(Array::make(16, b'\xFF')),
  }
  // 尺寸为 0
  try {
    let _ = @ocr.hu_moments_features(@types.Image::{
      width: 0,
      height: 4,
      channels: 1,
      data: Bytes::from_array([]),
    })
  } catch {
    _ => hits += 1
  }
  // 多通道
  try {
    let _ = @ocr.hu_moments_features(@types.Image::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array(Array::make(12, b'\x10')),
    })
  } catch {
    _ => hits += 1
  }
  // 数据长度不匹配
  try {
    let _ = @ocr.hu_moments_features(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array(Array::make(7, b'\x10')),
    })
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 3)
  // 正常路径不抛
  let h = @ocr.hu_moments_features(white2)
  assert_eq(h.length(), 7)
}

///|
test "ocr_accuracy: 集成预测（KNN + 模板 + SVM-like）" {
  let knn = @ocr.knn_create(k=3)
  let knn2 = @ocr.knn_add_sample(knn, [0.0, 0.0], "x")
  let knn3 = @ocr.knn_add_sample(knn2, [1.0, 1.0], "y")
  let templates : Array[(String, Array[Double])] = [
    ("x", [0.1, 0.0]),
    ("y", [1.0, 0.9]),
  ]
  let r = @ocr.ensemble_predict([0.0, 0.05], knn3, templates)
  assert_eq(r.label, "x")
  assert_true(r.confidence > 0.0)
  // majority 投票路径
  let cfg = @ocr.ensemble_default_config()
  let maj = @ocr.EnsembleConfig::{
    use_knn: cfg.use_knn,
    use_template: cfg.use_template,
    use_svm_like: cfg.use_svm_like,
    knn_k: cfg.knn_k,
    voting_method: "majority",
  }
  let r2 = @ocr.ensemble_predict([0.0, 0.05], knn3, templates, config=maj)
  assert_eq(r2.label, "x")
  // confidence 投票路径
  let conf = @ocr.EnsembleConfig::{
    use_knn: true,
    use_template: true,
    use_svm_like: false,
    knn_k: 1,
    voting_method: "confidence",
  }
  let r3 = @ocr.ensemble_predict([1.0, 1.0], knn3, templates, config=conf)
  assert_eq(r3.label, "y")
}

///|
test "ocr_accuracy: 集成预测空特征报错" {
  let knn = @ocr.knn_create(k=1)
  let mut hits = 0
  let empty : Array[Double] = []
  try {
    let _ = @ocr.ensemble_predict(empty, knn, [])
  } catch {
    @types.LoadError::DecodeFailed(_) => hits += 1
    _ => hits += 1
  }
  assert_eq(hits, 1)
}

///|
test "ocr_accuracy: 组合特征入口" {
  let img = oac_gray(16, 16)
  let f = @ocr.extract_combined_ocr_features(img)
  assert_true(f.length() > 0)
  let mut hits = 0
  try {
    let _ = @ocr.extract_combined_ocr_features(@types.Image::{
      width: 0,
      height: 2,
      channels: 1,
      data: Bytes::from_array([]),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.extract_combined_ocr_features(@types.Image::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array(Array::make(12, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  try {
    let _ = @ocr.extract_combined_ocr_features(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array(Array::make(3, b'\x00')),
    })
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 3)
}
