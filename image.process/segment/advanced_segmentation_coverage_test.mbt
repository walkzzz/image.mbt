// 覆盖率测试：高级分割的校验分支与配置变体

///|
fn asc_gray(w : Int32, h : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      data.push(f(x, y).to_byte())
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
fn asc_bad_dims() -> @types.Image {
  @types.Image::{
    width: 0,
    height: 4,
    channels: 1,
    data: Bytes::from_array([]),
  }
}

///|
fn asc_bad_channels() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 5,
    data: Bytes::from_array([]),
  }
}

///|
fn asc_bad_data() -> @types.Image {
  let d : Array[Byte] = [b'\x00', b'\x10']
  @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn asc_err_threshold(img : @types.Image) -> Bool {
  try {
    let _ = @segment.threshold_segmentation(img, 1.0)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
fn asc_err_otsu(img : @types.Image) -> Bool {
  try {
    let _ = @segment.otsu_threshold_value(img)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
fn asc_err_kmeans(img : @types.Image) -> Bool {
  try {
    let _ = @segment.kmeans_segmentation(
      img,
      @segment.create_default_kmeans_config(),
    )
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
fn asc_err_superpixel(img : @types.Image) -> Bool {
  try {
    let _ = @segment.superpixel_segmentation(img, 4)
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
fn asc_err_watershed(img : @types.Image) -> Bool {
  try {
    let _ = @segment.watershed_segmentation(
      img,
      @segment.create_default_watershed_config(),
    )
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
fn asc_err_grabcut(img : @types.Image) -> Bool {
  try {
    let _ = @segment.grabcut_segmentation(
      img,
      0,
      0,
      2,
      2,
      @segment.create_default_grabcut_config(),
    )
    false
  } catch {
    @types.DecodeFailed(_) => true
    _ => false
  }
}

///|
test "ascov: 阈值分割校验与全前景/全背景" {
  let img = asc_gray(4, 4, fn(x, _y) { if x < 2 { 10 } else { 200 } })
  let r = @segment.threshold_segmentation(img, 100.0)
  assert_true(r.labels.length() == 16)
  assert_true(r.num_classes == 2)
  assert_true(r.label_info.length() == 2)
  assert_true(r.label_info[0].pixel_count == 8)
  assert_true(r.label_info[1].pixel_count == 8)
  // 阈值低于全部像素 → 全前景
  let all_fg = @segment.threshold_segmentation(img, -1.0)
  assert_true(all_fg.label_info[1].pixel_count == 16)
  assert_true(all_fg.label_info[0].pixel_count == 0)
  // 阈值高于全部像素 → 全背景
  let all_bg = @segment.threshold_segmentation(img, 300.0)
  assert_true(all_bg.label_info[0].pixel_count == 16)
  // 三类校验错误
  assert_true(asc_err_threshold(asc_bad_dims()))
  assert_true(asc_err_threshold(asc_bad_channels()))
  assert_true(asc_err_threshold(asc_bad_data()))
}

///|
test "ascov: Otsu 校验与双峰图" {
  let img = asc_gray(8, 8, fn(x, _y) { if x < 4 { 0 } else { 255 } })
  let t = @segment.otsu_threshold_value(img)
  assert_true(t >= 0.0 && t <= 255.0)
  assert_true(asc_err_otsu(asc_bad_dims()))
  assert_true(asc_err_otsu(asc_bad_channels()))
  assert_true(asc_err_otsu(asc_bad_data()))
}

///|
test "ascov: K-Means 配置变体" {
  let img = asc_gray(8, 8, fn(x, y) { (x * 30 + y * 10) % 256 })
  let cfg = @segment.create_default_kmeans_config()
  let r = @segment.kmeans_segmentation(img, cfg)
  assert_true(r.label_info.length() == r.num_classes)
  assert_true(r.labels.length() == 64)
  // 单簇
  let cfg1 = @segment.KMeansConfig::{
    num_clusters: 1,
    max_iterations: 1,
    tolerance: 1.0,
    use_color_space: false,
    random_seed: 7,
  }
  let r2 = @segment.kmeans_segmentation(img, cfg1)
  assert_true(r2.num_classes >= 1)
  // 多簇且走色彩空间
  let cfg3 = @segment.KMeansConfig::{
    num_clusters: 8,
    max_iterations: 3,
    tolerance: 0.5,
    use_color_space: true,
    random_seed: 0,
  }
  let r3 = @segment.kmeans_segmentation(img, cfg3)
  assert_true(r3.labels.length() == 64)
  assert_true(asc_err_kmeans(asc_bad_dims()))
  assert_true(asc_err_kmeans(asc_bad_channels()))
  assert_true(asc_err_kmeans(asc_bad_data()))
}

///|
test "ascov: 超像素变体" {
  let img = asc_gray(8, 8, fn(x, y) { (x + y) * 8 })
  let r = @segment.superpixel_segmentation(img, 4)
  assert_true(r.labels.length() == 64)
  assert_true(r.num_superpixels >= 1)
  assert_true(r.superpixels.length() == r.num_superpixels)
  // 超像素数少于网格数
  let r1 = @segment.superpixel_segmentation(img, 1)
  assert_true(r1.labels.length() == 64)
  // 超像素数等于像素数（步长为 1 的极端）
  let r2 = @segment.superpixel_segmentation(img, 64)
  assert_true(r2.labels.length() == 64)
  assert_true(r2.num_superpixels >= 1)
  assert_true(asc_err_superpixel(asc_bad_dims()))
  assert_true(asc_err_superpixel(asc_bad_channels()))
  assert_true(asc_err_superpixel(asc_bad_data()))
}

///|
test "ascov: 超像素参数边界（0 抛错 / 超量截断 / 无 -1 空洞）" {
  let img = asc_gray(8, 8, fn(x, y) { (x + y) * 8 })
  // num_superpixels = 0 必须抛结构化错误，而不是除零
  let mut raised = false
  try {
    let _ = @segment.superpixel_segmentation(img, 0)
  } catch {
    _ => raised = true
  }
  assert_true(raised)
  // 超量（> 像素数）截断到像素数：旧实现 step 取整成 0 → 除零 panic / 死循环
  let r = @segment.superpixel_segmentation(img, 100)
  assert_eq(r.labels.length(), 64)
  let mut neg = 0
  for v in r.labels {
    if v < 0 {
      neg += 1
    }
  }
  assert_eq(neg, 0)
}

///|
test "ascov: 分水岭配置变体" {
  let img = asc_gray(10, 10, fn(x, y) {
    if (x - 5) * (x - 5) + (y - 5) * (y - 5) < 9 {
      200
    } else {
      20
    }
  })
  let base = @segment.create_default_watershed_config()
  let r = @segment.watershed_segmentation(img, base)
  assert_true(r.labels.length() == 100)
  assert_true(r.num_classes >= 1)
  // 8 连通 + 关闭标记 + 强制区域上限
  let cfg8 = @segment.WatershedConfigAdv::{
    min_region_size: 2,
    max_regions: 3,
    use_markers: false,
    connectivity: 8,
  }
  let r8 = @segment.watershed_segmentation(img, cfg8)
  assert_true(r8.labels.length() == 100)
  assert_true(r8.num_classes <= 3)
  // 4 连通 + 开启标记 + 大区域
  let cfg4 = @segment.WatershedConfigAdv::{
    min_region_size: 40,
    max_regions: 20,
    use_markers: true,
    connectivity: 4,
  }
  let r4 = @segment.watershed_segmentation(img, cfg4)
  assert_true(r4.labels.length() == 100)
  assert_true(asc_err_watershed(asc_bad_dims()))
  assert_true(asc_err_watershed(asc_bad_channels()))
  assert_true(asc_err_watershed(asc_bad_data()))
}

///|
test "ascov: GrabCut 矩形变体" {
  let img = asc_gray(10, 10, fn(x, y) {
    if x >= 3 && x < 7 && y >= 3 && y < 7 {
      220
    } else {
      30
    }
  })
  let cfg = @segment.create_default_grabcut_config()
  let r = @segment.grabcut_segmentation(img, 3, 3, 4, 4, cfg)
  assert_true(r.labels.length() == 100)
  assert_true(r.num_classes == 2)
  // 矩形覆盖整图
  let full = @segment.grabcut_segmentation(img, 0, 0, 10, 10, cfg)
  assert_true(
    full.label_info[0].pixel_count + full.label_info[1].pixel_count == 100,
  )
  // 零面积矩形
  let empty = @segment.grabcut_segmentation(img, 5, 5, 0, 0, cfg)
  assert_true(
    empty.label_info[0].pixel_count + empty.label_info[1].pixel_count == 100,
  )
  // 越界矩形（裁剪后仍需正常返回）
  let over = @segment.grabcut_segmentation(img, 8, 8, 10, 10, cfg)
  assert_true(over.labels.length() == 100)
  assert_true(asc_err_grabcut(asc_bad_dims()))
  assert_true(asc_err_grabcut(asc_bad_channels()))
  assert_true(asc_err_grabcut(asc_bad_data()))
}

///|
test "ascov: 指标计算边界" {
  // 完全一致
  let same : Array[Int32] = [1, 1, 0, 0]
  let m = @segment.calculate_segmentation_metrics(same, same, 2)
  assert_true(m.pixel_accuracy == 1.0)
  assert_true(m.true_positives == 2)
  assert_true(m.false_positives == 0)
  assert_true(m.false_negatives == 0)
  assert_true(m.dice_coefficient == 1.0)
  // 完全相反：tp=0, fp=2, fn=2 → iou 0
  let pred_a : Array[Int32] = [1, 1, 0, 0]
  let gt_a : Array[Int32] = [0, 0, 1, 1]
  let m2 = @segment.calculate_segmentation_metrics(pred_a, gt_a, 2)
  assert_true(m2.pixel_accuracy == 0.0)
  assert_true(m2.mean_iou == 0.0)
  assert_true(m2.dice_coefficient == 0.0)
  assert_true(m2.false_positives == 2)
  assert_true(m2.false_negatives == 2)
  // 空输入：全部 0
  let e0 : Array[Int32] = []
  let m3 = @segment.calculate_segmentation_metrics(e0, e0, 2)
  assert_true(m3.pixel_accuracy == 0.0)
  assert_true(m3.mean_iou == 0.0)
  // 全背景一致：分母为 0 → iou 0
  let zeros : Array[Int32] = [0, 0]
  let m4 = @segment.calculate_segmentation_metrics(zeros, zeros, 2)
  assert_true(m4.pixel_accuracy == 1.0)
  assert_true(m4.mean_iou == 0.0)
}

///|
test "ascov: 可视化与报告" {
  let img = asc_gray(4, 4, fn(x, _y) { if x < 2 { 0 } else { 255 } })
  let r = @segment.threshold_segmentation(img, 100.0)
  let vis = @segment.segmentation_to_image(r)
  assert_true(vis.width == 4)
  assert_true(vis.height == 4)
  assert_true(vis.channels == 1)
  assert_true(vis.data.length() == 16)
  let m = @segment.calculate_segmentation_metrics(r.labels, r.labels, 2)
  let report = @segment.segmentation_report_to_string(r, m)
  assert_true(report.contains("图像分割报告"))
  assert_true(report.contains("类别统计"))
  assert_true(report.contains("background"))
  assert_true(report.contains("foreground"))
  assert_true(report.contains("4x4"))
}
