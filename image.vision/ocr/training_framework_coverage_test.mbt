// 覆盖率测试：OCR 训练框架（数据加载 / 学习率调度 / 增强 / 早停 / 报告 / 划分 / 混淆矩阵）

fn tfc_sample(label : Int32) -> @ocr.DLTrainingSample {
  @ocr.DLTrainingSample::{
    image_data: [0.1, 0.2, 0.3, 0.4],
    label,
    label_text: label.to_string(),
    width: 2,
    height: 2,
  }
}

fn tfc_samples(n : Int32) -> Array[@ocr.DLTrainingSample] {
  let out : Array[@ocr.DLTrainingSample] = []
  for i in 0..<n {
    out.push(tfc_sample(i))
  }
  out
}

fn tfc_metrics(
  epoch : Int32,
  val_acc : Double,
  time : Double,
) -> @ocr.TrainingMetrics {
  @ocr.TrainingMetrics::{
    epoch,
    train_loss: 0.5,
    train_accuracy: 0.8,
    val_loss: 0.4,
    val_accuracy: val_acc,
    learning_rate: 0.001,
    time_ms: time,
    is_best: false,
  }
}

fn tfc_lr_cfg(
  kind : @ocr.LRSchedulerType,
  initial : Double,
  min_lr : Double,
) -> @ocr.LRSchedulerConfig {
  @ocr.LRSchedulerConfig::{
    scheduler_type: kind,
    initial_lr: initial,
    min_lr,
    decay_rate: 0.1,
    decay_steps: 10,
    warmup_steps: 5,
    patience: 5,
    factor: 0.5,
  }
}

test "tfcov: 默认训练配置" {
  let cfg = @ocr.create_default_training_config()
  assert_true(cfg.epochs == 50)
  assert_true(cfg.batch_size == 32)
  assert_true(cfg.optimizer.optimizer_type == @ocr.OptimizerType::Adam)
  assert_true(cfg.optimizer.learning_rate == 0.001)
  assert_true(cfg.lr_scheduler.scheduler_type == @ocr.LRSchedulerType::CosineAnnealing)
  assert_true(cfg.augmentation.enabled)
  assert_true(cfg.augmentation.augmentation_types.length() == 4)
  assert_true(cfg.early_stopping_patience == 10)
  assert_true(cfg.validation_split == 0.2)
  assert_true(cfg.random_seed == 42)
}

test "tfcov: 数据加载器与取批" {
  let loader = @ocr.create_data_loader(tfc_samples(5), 2, true)
  assert_true(loader.batch_size == 2)
  assert_true(loader.current_index == 0)
  assert_true(loader.shuffle)
  // 第一批：2 条，索引推进到 2
  let (b1, l1) = @ocr.next_batch(loader)
  assert_true(b1.length() == 2)
  assert_true(l1.current_index == 2)
  assert_true(l1.epoch == 0)
  // 第二批
  let (b2, l2) = @ocr.next_batch(l1)
  assert_true(b2.length() == 2)
  assert_true(l2.current_index == 4)
  // 第三批：只剩 1 条，回绕到 0 且 epoch+1
  let (b3, l3) = @ocr.next_batch(l2)
  assert_true(b3.length() == 1)
  assert_true(l3.current_index == 0)
  assert_true(l3.epoch == 1)
  // 校验
  let empty : Array[@ocr.DLTrainingSample] = []
  try {
    let _ = @ocr.create_data_loader(empty, 2, false)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.create_data_loader(tfc_samples(3), 0, false)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // next_batch 校验
  let bad_loader = @ocr.DataLoader::{
    samples: empty,
    batch_size: 2,
    shuffle: false,
    current_index: 0,
    epoch: 0,
  }
  try {
    let _ = @ocr.next_batch(bad_loader)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let zero_batch = @ocr.DataLoader::{
    samples: tfc_samples(2),
    batch_size: 0,
    shuffle: false,
    current_index: 0,
    epoch: 0,
  }
  try {
    let _ = @ocr.next_batch(zero_batch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "tfcov: 学习率调度各分支" {
  // Constant
  let c = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.001, 0.00001),
    3,
    0.001,
    0.5,
  )
  assert_true(c == 0.001)
  // StepDecay：epoch 10 / decay_steps 10 → 0.001 * 0.1
  let s = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::StepDecay, 0.001, 0.00001),
    10,
    0.001,
    0.5,
  )
  assert_true(s > 0.00009 && s < 0.00011)
  // StepDecay 低于下界 → min_lr
  let s2 = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::StepDecay, 0.001, 0.0005),
    100,
    0.001,
    0.5,
  )
  assert_true(s2 == 0.0005)
  // ExponentialDecay epoch 2 → 0.001 * 0.01 = 1e-5 → 等于 min
  let e = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::ExponentialDecay, 0.001, 0.00001),
    2,
    0.001,
    0.5,
  )
  assert_true(e > 0.000009 && e < 0.000011)
  // CosineAnnealing epoch 0 → 回到初始
  let ca = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::CosineAnnealing, 0.001, 0.00001),
    0,
    0.001,
    0.5,
  )
  assert_true(ca > 0.00099)
  // WarmupCosine：预热段线性
  let w1 = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::WarmupCosine, 0.001, 0.00001),
    0,
    0.001,
    0.5,
  )
  assert_true(w1 > 0.00019 && w1 < 0.00021)
  // WarmupCosine：预热后余弦
  let w2 = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::WarmupCosine, 0.001, 0.00001),
    10,
    0.001,
    0.5,
  )
  assert_true(w2 > 0.0009 && w2 < 0.001)
  // ReduceOnPlateau → 当前学习率
  let r = @ocr.calculate_learning_rate(
    tfc_lr_cfg(@ocr.LRSchedulerType::ReduceOnPlateau, 0.001, 0.00001),
    3,
    0.005,
    0.5,
  )
  assert_true(r == 0.005)
  // 校验
  try {
    let _ = @ocr.calculate_learning_rate(
      tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.001, 0.00001),
      -1,
      0.001,
      0.5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.calculate_learning_rate(
      tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.001, 0.00001),
      1,
      0.0,
      0.5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.calculate_learning_rate(
      tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.001, 0.00001),
      1,
      0.001,
      -0.5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.calculate_learning_rate(
      tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.0, 0.00001),
      1,
      0.001,
      0.5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.calculate_learning_rate(
      tfc_lr_cfg(@ocr.LRSchedulerType::Constant, 0.001, -1.0),
      1,
      0.001,
      0.5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "tfcov: 数据增强" {
  let s = tfc_sample(1)
  // 旋转 / 平移 / 缩放为占位实现：原样返回
  let rot = @ocr.augment_random_rotation(s, 15.0)
  assert_true(rot.image_data == s.image_data)
  let sh = @ocr.augment_random_shift(s, 0.1)
  assert_true(sh.label == 1)
  let sc = @ocr.augment_random_scale(s, 0.1)
  assert_true(sc.width == 2)
  // 噪声：亮像素加噪后钳到 1，暗像素减噪后钳到 0
  let sample = @ocr.DLTrainingSample::{
    image_data: [0.8, 0.2, 0.0, 1.0],
    label: 2,
    label_text: "2",
    width: 2,
    height: 2,
  }
  let noisy = @ocr.augment_random_noise(sample, 0.5)
  assert_true(noisy.image_data.length() == 4)
  assert_true(noisy.image_data[0] == 1.0)
  assert_true(noisy.image_data[1] < 0.3)
  assert_true(noisy.image_data[2] == 0.0)
  assert_true(noisy.image_data[3] == 1.0)
  assert_true(noisy.label == 2)
  // 开关关闭 → 原样
  let off = @ocr.AugmentationConfig::{
    enabled: false,
    augmentation_types: [@ocr.AugmentationType::RandomNoise],
    rotation_range: 15.0,
    shift_range: 0.1,
    scale_range: 0.1,
    noise_level: 0.05,
    blur_sigma: 1.0,
    brightness_range: 0.2,
    contrast_range: 0.2,
    probability: 0.5,
  }
  let a1 = @ocr.apply_augmentation(s, off)
  assert_true(a1.image_data == s.image_data)
  // 开启且含噪声 → 变化
  let on = @ocr.AugmentationConfig::{
    enabled: true,
    augmentation_types: [@ocr.AugmentationType::RandomRotation, @ocr.AugmentationType::RandomNoise],
    rotation_range: 15.0,
    shift_range: 0.1,
    scale_range: 0.1,
    noise_level: 0.2,
    blur_sigma: 1.0,
    brightness_range: 0.2,
    contrast_range: 0.2,
    probability: 0.5,
  }
  let a2 = @ocr.apply_augmentation(s, on)
  assert_true(a2.image_data.length() == 4)
  assert_true(a2.image_data != s.image_data)
  // 开启但只含非噪声增强 → 原样
  let on2 = @ocr.AugmentationConfig::{
    enabled: true,
    augmentation_types: [@ocr.AugmentationType::RandomRotation],
    rotation_range: 15.0,
    shift_range: 0.1,
    scale_range: 0.1,
    noise_level: 0.2,
    blur_sigma: 1.0,
    brightness_range: 0.2,
    contrast_range: 0.2,
    probability: 0.5,
  }
  let a3 = @ocr.apply_augmentation(s, on2)
  assert_true(a3.image_data == s.image_data)
}

test "tfcov: 准确率 / 早停 / 状态记录" {
  // 准确率
  let acc = @ocr.calculate_accuracy([1, 2, 3], [1, 2, 4])
  assert_true(acc > 0.66 && acc < 0.67)
  let empty : Array[Int32] = []
  assert_true(@ocr.calculate_accuracy(empty, [1]) == 0.0)
  assert_true(@ocr.calculate_accuracy([1, 2], empty) == 0.0)
  // 长度不等取较短
  let acc2 = @ocr.calculate_accuracy([1, 9], [1, 9, 3])
  assert_true(acc2 == 1.0)
  // 早停：有提升 → 不停止且更新最佳
  let cfg = @ocr.create_default_training_config()
  let st0 = @ocr.create_training_state()
  assert_true(st0.current_epoch == 0)
  assert_true(st0.history.length() == 0)
  let (stop1, st1) = @ocr.check_early_stopping(st0, cfg, 0.8)
  assert_true(!stop1)
  assert_true(st1.best_val_accuracy == 0.8)
  assert_true(st1.best_epoch == 0)
  assert_true(st1.epochs_without_improvement == 0)
  // 无提升 → 累计 1 次，不停止
  let (stop2, st2) = @ocr.check_early_stopping(st1, cfg, 0.79)
  assert_true(!stop2)
  assert_true(st2.epochs_without_improvement == 1)
  assert_true(st2.best_val_accuracy == 0.8)
  // 连续 10 轮无提升 → 早停
  let mut cur = st2
  for _ in 0..<9 {
    let (s, next) = @ocr.check_early_stopping(cur, cfg, 0.5)
    ignore(s)
    cur = next
  }
  let (stop3, st3) = @ocr.check_early_stopping(cur, cfg, 0.5)
  assert_true(stop3)
  assert_true(st3.is_completed)
  assert_true(st3.stop_reason == "early_stopping")
  // 记录指标：首次最佳
  let m1 = tfc_metrics(1, 0.7, 100.0)
  let r1 = @ocr.record_training_metrics(st0, m1)
  assert_true(r1.history.length() == 1)
  assert_true(r1.best_val_accuracy == 0.7)
  assert_true(r1.best_epoch == 1)
  assert_true(r1.total_training_time_ms == 100.0)
  assert_true(r1.current_epoch == 1)
  // 记录指标：未超过 → 无改进计数 +1
  let m2 = tfc_metrics(2, 0.6, 50.0)
  let r2 = @ocr.record_training_metrics(r1, m2)
  assert_true(r2.history.length() == 2)
  assert_true(r2.best_val_accuracy == 0.7)
  assert_true(r2.epochs_without_improvement == 1)
  assert_true(r2.total_training_time_ms == 150.0)
  assert_true(r2.current_epoch == 2)
}

test "tfcov: 训练报告 / 数据划分 / 混淆矩阵" {
  let cfg = @ocr.create_default_training_config()
  let st = @ocr.create_training_state()
  let r0 = @ocr.generate_training_progress_report(st, cfg)
  assert_true(r0.contains("训练进度报告"))
  assert_true(r0.contains("进行中"))
  assert_true(!r0.contains("最近 5 轮"))
  // 7 条历史 → 只打印最后 5 条
  let mut st2 = st
  for i in 1..<8 {
    st2 = @ocr.record_training_metrics(
      st2,
      tfc_metrics(i, 0.5 + i.to_double() / 100.0, 10.0),
    )
  }
  let r1 = @ocr.generate_training_progress_report(st2, cfg)
  assert_true(r1.contains("最近 5 轮"))
  assert_true(r1.contains("| 7 |"))
  assert_true(!r1.contains("| 1 | 0.5"))
  // 已完成状态
  let done = @ocr.TrainingState::{
    current_epoch: 5,
    best_val_accuracy: 0.9,
    best_epoch: 4,
    epochs_without_improvement: 2,
    total_training_time_ms: 1500.0,
    history: [],
    is_completed: true,
    stop_reason: "early_stopping",
  }
  let r2 = @ocr.generate_training_progress_report(done, cfg)
  assert_true(r2.contains("已完成 (early_stopping)"))
  // 划分：10 条，0.2 → 8 / 2
  let (train, val) = @ocr.split_train_validation(tfc_samples(10), 0.2, true)
  assert_true(train.length() == 8)
  assert_true(val.length() == 2)
  assert_true(train[0].label == 0)
  assert_true(val[0].label == 8)
  // 0 比例 → 全部训练集
  let (t2, v2) = @ocr.split_train_validation(tfc_samples(4), 0.0, false)
  assert_true(t2.length() == 4)
  assert_true(v2.length() == 0)
  // 混淆矩阵：3 类
  let cm = @ocr.compute_confusion_matrix([1, 2, 0, 5], [1, 2, 2, 3], 3)
  assert_true(cm.length() == 3)
  assert_true(cm[0].length() == 3)
  assert_true(cm[1][1] == 1)
  assert_true(cm[2][2] == 1)
  assert_true(cm[2][0] == 1)
  // 越界标签被跳过
  assert_true(cm[0][0] == 0)
  // 每类准确率
  let pca = @ocr.compute_per_class_accuracy(cm)
  assert_true(pca.length() == 3)
  assert_true(pca[0] == 0.0)
  assert_true(pca[1] == 1.0)
  assert_true(pca[2] > 0.49 && pca[2] < 0.51)
}
