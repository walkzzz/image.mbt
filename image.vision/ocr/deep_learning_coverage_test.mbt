// 覆盖率测试：OCR 深度学习集成（层 / 归一化 / 卷积 / 池化 / 全连接 / 推理 / 特征）

fn dlc_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let v = f(x, y)
      for _ in 0..<c {
        d.push(v.to_byte())
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn dlc_grad(w : Int32, h : Int32) -> @types.Image {
  dlc_img(w, h, 1, fn(x, y) { x + y })
}

test "dlcov: 默认 CNN 配置与层构造" {
  let cfg = @ocr.create_default_char_cnn_config(10)
  assert_true(cfg.model_name == "char_cnn_v1")
  assert_true(cfg.input_width == 32)
  assert_true(cfg.num_classes == 10)
  assert_true(cfg.conv_layers.length() == 3)
  assert_true(cfg.dense_layers.length() == 2)
  assert_true(cfg.conv_layers[0].out_channels == 32)
  assert_true(cfg.dense_layers[0].out_features == 256)
  assert_true(cfg.batch_size == 32)
  // Conv2D：形状不变
  let l1 = @ocr.create_neural_layer(
    @ocr.DLLayerType::Conv2D,
    "conv1",
    [1, 8, 8],
  )
  assert_true(l1.output_shape.length() == 3)
  assert_true(l1.output_shape[1] == 8)
  assert_true(l1.config == "{}")
  assert_true(l1.weights.length() == 0)
  // MaxPool2D / AvgPool2D：减半
  let l2 = @ocr.create_neural_layer(
    @ocr.DLLayerType::MaxPool2D,
    "pool",
    [2, 8, 6],
  )
  assert_true(l2.output_shape[1] == 4)
  assert_true(l2.output_shape[2] == 3)
  let l3 = @ocr.create_neural_layer(
    @ocr.DLLayerType::AvgPool2D,
    "apool",
    [2, 8, 6],
  )
  assert_true(l3.output_shape[1] == 4)
  // Flatten：乘积
  let l4 = @ocr.create_neural_layer(
    @ocr.DLLayerType::Flatten,
    "flat",
    [2, 4, 4],
  )
  assert_true(l4.output_shape[0] == 32)
  // Dense：单元素
  let l5 = @ocr.create_neural_layer(
    @ocr.DLLayerType::Dense,
    "fc",
    [32, 1, 1],
  )
  assert_true(l5.output_shape[0] == 32)
  // ReLU 等：原样
  let l6 = @ocr.create_neural_layer(
    @ocr.DLLayerType::ReLU,
    "relu",
    [3, 3],
  )
  assert_true(l6.output_shape.length() == 2)
  assert_true(l6.input_shape[0] == 3)
}

test "dlcov: 归一化与缩放" {
  // 归一化
  let n = @ocr.normalize_image([10.0, 20.0], 10.0, 5.0)
  assert_true(n.length() == 2)
  assert_true(n[0] == 0.0)
  assert_true(n[1] == 2.0)
  try {
    let empty : Array[Double] = []
    let _ = @ocr.normalize_image(empty, 0.0, 1.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.normalize_image([1.0], 0.0, 0.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 缩放到 2x2：取 (0,0)/(2,0)/(0,2)/(2,2) → 0/2/2/4
  let img = dlc_grad(4, 4)
  let r = @ocr.resize_image_for_cnn(img, 2, 2)
  assert_true(r.length() == 4)
  assert_true(r[0] == 0.0)
  assert_true(r[1] == 2.0 / 255.0)
  assert_true(r[3] == 4.0 / 255.0)
  // 放大到 8x8：索引不越界并填 0
  let up = @ocr.resize_image_for_cnn(img, 8, 8)
  assert_true(up.length() == 64)
  // 校验
  try {
    let _ = @ocr.resize_image_for_cnn(dlc_img(0, 4, 1, fn(x, y) { x + 0 * y }), 2, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.resize_image_for_cnn(dlc_img(2, 2, 5, fn(x, y) { x }), 2, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let bad = @types.Image::{
      width: 2,
      height: 2,
      channels: 1,
      data: Bytes::from_array([b'\x01']),
    }
    let _ = @ocr.resize_image_for_cnn(bad, 2, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.resize_image_for_cnn(img, 0, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "dlcov: 激活函数与 softmax" {
  assert_true(@ocr.relu(-1.0) == 0.0)
  assert_true(@ocr.relu(2.5) == 2.5)
  let s0 = @ocr.sigmoid(0.0)
  assert_true(s0 > 0.49 && s0 < 0.51)
  // 泰勒近似的 exp 在大输入下误差明显，只在小范围断言单调性
  assert_true(@ocr.sigmoid(1.0) > s0)
  assert_true(@ocr.sigmoid(-1.0) < s0)
  // softmax 归一化
  let sm = @ocr.softmax([0.0, 0.0])
  assert_true(sm.length() == 2)
  assert_true(sm[0] > 0.49 && sm[0] < 0.51)
  let sm2 = @ocr.softmax([1.0, 2.0, 3.0])
  assert_true(sm2[2] > sm2[1])
  assert_true(sm2[1] > sm2[0])
  let mut total = 0.0
  for v in sm2 {
    total += v
  }
  assert_true(total > 0.99 && total < 1.01)
}

test "dlcov: 卷积与池化" {
  // 3x3 输入、全 1 核、无填充、步长 1 → 单输出 = 45
  let input : Array[Double] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  let kernel : Array[Double] = []
  for _ in 0..<9 {
    kernel.push(1.0)
  }
  let c = @ocr.conv2d(input, 3, 3, 1, kernel, 1, 3, 1, 0)
  assert_true(c.length() == 1)
  assert_true(c[0] == 45.0)
  // 负核 → ReLU 归零
  let neg : Array[Double] = []
  for _ in 0..<9 {
    neg.push(-1.0)
  }
  let cneg = @ocr.conv2d(input, 3, 3, 1, neg, 1, 3, 1, 0)
  assert_true(cneg[0] == 0.0)
  // 填充 1 输出保持 3x3
  let cp = @ocr.conv2d(input, 3, 3, 1, kernel, 1, 3, 1, 1)
  assert_true(cp.length() == 9)
  // 校验
  let empty : Array[Double] = []
  try {
    let _ = @ocr.conv2d(empty, 3, 3, 1, kernel, 1, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 1, empty, 1, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 0, 3, 1, kernel, 1, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 0, kernel, 1, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 1, kernel, 0, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 1, kernel, 1, 0, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 1, kernel, 1, 3, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 1, kernel, 1, 3, 1, -1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.conv2d(input, 3, 3, 2, kernel, 1, 3, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 最大池化 4x4 → 2x2
  let pool_in : Array[Double] = []
  for i in 1..<17 {
    pool_in.push(i.to_double())
  }
  let p = @ocr.max_pool2d(pool_in, 4, 4, 1, 2)
  assert_true(p.length() == 4)
  assert_true(p[0] == 6.0)
  assert_true(p[1] == 8.0)
  assert_true(p[2] == 14.0)
  assert_true(p[3] == 16.0)
  // 校验
  try {
    let _ = @ocr.max_pool2d(empty, 4, 4, 1, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.max_pool2d(pool_in, 0, 4, 1, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.max_pool2d(pool_in, 4, 4, 0, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.max_pool2d(pool_in, 4, 4, 1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.max_pool2d(pool_in, 5, 4, 1, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "dlcov: 全连接与推理" {
  // identity 权重：out = [1, 2]
  let d = @ocr.dense_forward(
    [1.0, 2.0], [1.0, 0.0, 0.0, 1.0], [0.0, 0.0], 2, 2, "none",
  )
  assert_true(d.length() == 2)
  assert_true(d[0] == 1.0)
  assert_true(d[1] == 2.0)
  // relu 分支
  let dr = @ocr.dense_forward(
    [-1.0, 2.0], [1.0, 0.0, 0.0, 1.0], [0.0, 0.0], 2, 2, "relu",
  )
  assert_true(dr[0] == 0.0)
  // sigmoid / tanh 分支
  let ds = @ocr.dense_forward(
    [1.0, 2.0], [1.0, 0.0, 0.0, 1.0], [0.0, 0.0], 2, 2, "sigmoid",
  )
  assert_true(ds[0] > 0.5)
  let dt = @ocr.dense_forward(
    [1.0, 2.0], [1.0, 0.0, 0.0, 1.0], [0.0, 0.0], 2, 2, "tanh",
  )
  assert_true(dt[0] > 0.5 && dt[1] > 0.9)
  // 推理：类别分数带 c*0.001 偏置 → 最高类为最后一个
  let cfg = @ocr.create_default_char_cnn_config(3)
  let ir = @ocr.cnn_infer([10.0, 20.0, 30.0, 40.0], cfg, ["a", "b", "c"])
  assert_true(ir.predicted_class == 2)
  assert_true(ir.predicted_label == "c")
  assert_true(ir.confidence > 0.33)
  assert_true(ir.top_k_predictions.length() == 3)
  // 标签不足 → unknown
  let ir2 = @ocr.cnn_infer([1.0, 2.0], cfg, ["only"])
  assert_true(ir2.predicted_label == "unknown")
}

test "dlcov: 训练样本 / 损失 / 报告 / 模型" {
  let img = dlc_grad(8, 8)
  let sample = @ocr.create_training_sample(img, 3, "3")
  assert_true(sample.label == 3)
  assert_true(sample.label_text == "3")
  assert_true(sample.width == 32)
  assert_true(sample.image_data.length() == 1024)
  try {
    let _ = @ocr.create_training_sample(dlc_img(0, 4, 1, fn(x, y) { x }), 1, "1")
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.create_training_sample(img, -1, "-")
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 交叉熵：目标概率高 → 损失小
  let low = @ocr.cross_entropy_loss([0.9, 0.1], 0)
  let high = @ocr.cross_entropy_loss([0.1, 0.9], 0)
  assert_true(low < high)
  // 目标越界 → 用 eps
  let oob = @ocr.cross_entropy_loss([0.5, 0.5], 5)
  assert_true(oob > 0.0)
  // 训练历史 + 报告（空历史）
  let cfg = @ocr.create_default_char_cnn_config(5)
  let empty : Array[@ocr.DLTrainingHistory] = []
  let report0 = @ocr.generate_training_report(empty, cfg)
  assert_true(report0.contains("CNN 模型训练报告"))
  assert_true(report0.contains("char_cnn_v1"))
  assert_true(!report0.contains("最终结果"))
  // 非空历史 → 含最终结果
  let h1 = @ocr.create_training_history(1, 0.8, 0.7, 0.9, 0.65, 0.001, 12.0)
  let h2 = @ocr.create_training_history(2, 0.4, 0.85, 0.5, 0.8, 0.001, 10.0)
  let hist : Array[@ocr.DLTrainingHistory] = [h1, h2]
  let report1 = @ocr.generate_training_report(hist, cfg)
  assert_true(report1.contains("最终结果"))
  assert_true(report1.contains("85"))
  // 保存 / 加载
  assert_true(@ocr.save_model(cfg, [1.0, 2.0], "m.json"))
  assert_true(@ocr.load_model("m.json") == None)
}

test "dlcov: 特征提取与余弦相似度" {
  let ex = @ocr.create_feature_extractor("char_cnn_v1", 20)
  assert_true(ex.feature_dim == 20)
  assert_true(ex.layer_name == "conv3")
  let img = dlc_grad(4, 4)
  let f = @ocr.extract_features(ex, img)
  assert_true(f.length() == 20)
  // 前两个是均值/标准差
  assert_true(f[0] >= 0.0 && f[0] <= 1.0)
  assert_true(f[1] >= 0.0)
  // 8x8 图：投影各 8 行 8 列 → 2+8+8 = 18，仍补齐到 20
  let img8 = dlc_grad(8, 8)
  let ex2 = @ocr.create_feature_extractor("m", 18)
  let f8 = @ocr.extract_features(ex2, img8)
  assert_true(f8.length() == 18)
  // 余弦相似度
  assert_true(@ocr.cosine_similarity([1.0, 2.0], [1.0, 2.0]) > 0.99)
  assert_true(@ocr.cosine_similarity([0.0, 0.0], [1.0, 1.0]) == 0.0)
  assert_true(@ocr.cosine_similarity([1.0], [1.0, 2.0]) > 0.99)
  assert_true(@ocr.cosine_similarity([1.0, 0.0], [0.0, 1.0]) == 0.0)
}
