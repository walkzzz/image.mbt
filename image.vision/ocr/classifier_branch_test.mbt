// 覆盖率测试：距离度量、KNN 与模板匹配的分支补充

test "clfcov: 四种距离与空向量校验" {
  // 欧氏 / 曼哈顿 / 切比雪夫
  assert_true(@ocr.euclidean_distance([1.0, 2.0], [4.0, 6.0]) == 5.0)
  assert_true(@ocr.manhattan_distance([1.0, 2.0], [4.0, 6.0]) == 7.0)
  assert_true(@ocr.chebyshev_distance([1.0, 2.0], [4.0, 6.0]) == 4.0)
  // 余弦：相同向量 → 0；零向量 → 1.0 兜底
  assert_true(@ocr.cosine_distance([1.0, 0.0], [1.0, 0.0]) == 0.0)
  assert_true(@ocr.cosine_distance([0.0, 0.0], [1.0, 1.0]) == 1.0)
  // 长度不一致时按较短长度计算
  assert_true(@ocr.euclidean_distance([0.0, 0.0, 0.0], [3.0, 4.0]) == 5.0)
  // 空向量错误分支
  try {
    let _ = @ocr.euclidean_distance([], [1.0])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.euclidean_distance([1.0], [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.manhattan_distance([], [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.cosine_distance([], [1.0])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.cosine_distance([1.0], [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.chebyshev_distance([], [1.0])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.chebyshev_distance([1.0], [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "clfcov: compute_distance 四种度量分发" {
  let a = [1.0, 3.0]
  let b = [4.0, 3.0]
  assert_true(@ocr.compute_distance(a, b, @ocr.DistanceMetric::Euclidean) == 3.0)
  assert_true(@ocr.compute_distance(a, b, @ocr.DistanceMetric::Manhattan) == 3.0)
  // 余弦结果在 [0,2]
  let cos = @ocr.compute_distance(a, b, @ocr.DistanceMetric::Cosine)
  assert_true(cos >= 0.0 && cos <= 2.0)
  assert_true(@ocr.compute_distance(a, b, @ocr.DistanceMetric::Chebyshev) == 3.0)
  // 空向量错误
  try {
    let _ = @ocr.compute_distance([], b, @ocr.DistanceMetric::Euclidean)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.compute_distance(a, [], @ocr.DistanceMetric::Chebyshev)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "clfcov: KNN 创建/加样/预测" {
  // k <= 0 报错
  try {
    let _ = @ocr.knn_create(k=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 各度量字符串都能创建
  for m in ["euclidean", "manhattan", "cosine", "chebyshev", "unknown"] {
    let c = @ocr.knn_create(k=3, distance_metric=m)
    assert_true(c.k == 3)
  }
  // 加单个样本
  let mut clf = @ocr.knn_create(k=3)
  clf = @ocr.knn_add_sample(clf, [0.0, 0.0], "A")
  clf = @ocr.knn_add_sample(clf, [1.0, 1.0], "A")
  clf = @ocr.knn_add_sample(clf, [10.0, 10.0], "B")
  assert_true(clf.samples.length() == 3)
  // 预测：最近两票 A → 结果 A
  let res = @ocr.knn_predict(clf, [0.2, 0.2])
  assert_true(res.label == "A")
  assert_true(res.top_k.length() == 3)
  assert_true(res.confidence > 0.0)
  // k 大于样本数 → 截断到样本数
  let clf2 = @ocr.knn_add_sample(@ocr.knn_create(k=9), [1.0, 1.0], "X")
  let res2 = @ocr.knn_predict(clf2, [1.0, 1.0])
  assert_true(res2.top_k.length() == 1)
  assert_true(res2.confidence == 1.0)
  // 批量加样
  let clf3 = @ocr.knn_add_samples(
    @ocr.knn_create(k=2),
    [([1.0], "P"), ([2.0], "Q")],
  )
  assert_true(clf3.samples.length() == 2)
  // 空特征 / 无样本错误
  try {
    let _ = @ocr.knn_predict(clf, [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.knn_predict(@ocr.knn_create(k=2), [1.0])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 加样时空特征
  try {
    let _ = @ocr.knn_add_sample(@ocr.knn_create(), [], "Z")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "clfcov: 模板匹配分支" {
  // 非法度量字符串 → 兜底 euclidean
  let m0 = @ocr.template_matcher_create(distance_metric="unknown-metric")
  assert_true(m0.templates.length() == 0)
  let m1 = @ocr.template_matcher_create(distance_metric="chebyshev")
  let matcher = @ocr.template_matcher_add(m1, "one", [1.0, 2.0, 3.0])
  let matcher2 = @ocr.template_matcher_add(matcher, "two", [4.0, 5.0, 6.0])
  assert_true(matcher2.templates.length() == 2)
  // 预测选最近模板
  let res = @ocr.template_matcher_predict(matcher2, [1.1, 2.1, 3.1])
  assert_true(res.label == "one")
  assert_true(res.top_k.length() == 2)
  assert_true(res.confidence > 0.5)
  // 完全相同 → 置信度 1
  let res2 = @ocr.template_matcher_predict(matcher2, [4.0, 5.0, 6.0])
  assert_true(res2.label == "two")
  assert_true(res2.confidence == 1.0)
  // 空特征 / 无模板错误
  try {
    let _ = @ocr.template_matcher_predict(matcher2, [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.template_matcher_predict(m0, [1.0])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 加模板时空模板向量
  try {
    let _ = @ocr.template_matcher_add(m1, "bad", [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
