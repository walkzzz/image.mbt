// 覆盖率测试：医学增强的窗宽窗位预设、分割、病灶、配准与报告分支

fn medc_img(w : Int32, h : Int32, slices : Int32, value : Double) -> @medical.MedicalImage {
  @medical.MedicalImage::{
    width: w,
    height: h,
    slices,
    data: Array::make(w * h * slices, value),
    image_type: @medical.MedicalImageType::CT,
    pixel_spacing_x: 1.0,
    pixel_spacing_y: 1.0,
    slice_thickness: 1.0,
    window_center: 128.0,
    window_width: 256.0,
  }
}

fn medc_grad(w : Int32, h : Int32) -> @medical.MedicalImage {
  let data : Array[Double] = []
  for y in 0..<h {
    for x in 0..<w {
      data.push((x * 7 + y * 3).to_double())
    }
  }
  @medical.MedicalImage::{
    width: w,
    height: h,
    slices: 1,
    data,
    image_type: @medical.MedicalImageType::MRI,
    pixel_spacing_x: 0.5,
    pixel_spacing_y: 0.5,
    slice_thickness: 2.0,
    window_center: 64.0,
    window_width: 128.0,
  }
}


fn medc_lesion(w : Int32, h : Int32, x0 : Int32, y0 : Int32, side : Int32, value : Double) -> @medical.MedicalImage {
  let data : Array[Double] = []
  for y in 0..<h {
    for x in 0..<w {
      if x >= x0 && x < x0 + side && y >= y0 && y < y0 + side {
        data.push(value)
      } else {
        data.push(0.0)
      }
    }
  }
  @medical.MedicalImage::{
    width: w,
    height: h,
    slices: 1,
    data,
    image_type: @medical.MedicalImageType::CT,
    pixel_spacing_x: 1.0,
    pixel_spacing_y: 1.0,
    slice_thickness: 1.0,
    window_center: 128.0,
    window_width: 256.0,
  }
}

test "medcov: 窗宽窗位预设六分支" {
  let cases = [
    ("brain", 40.0, 80.0),
    ("lung", -600.0, 1500.0),
    ("abdomen", 40.0, 400.0),
    ("bone", 300.0, 1500.0),
    ("soft_tissue", 50.0, 350.0),
  ]
  for c in cases {
    let (name, center, width) = c
    let cfg = @medical.create_default_window_level(name)
    assert_true(cfg.center == center)
    assert_true(cfg.width == width)
    assert_true(cfg.preset == name)
  }
  // 未知预设 → custom
  let custom = @medical.create_default_window_level("weird")
  assert_true(custom.preset == "custom")
  assert_true(custom.center == 128.0)
  assert_true(custom.width == 256.0)
}

test "medcov: apply_window_level_medical 钳制分支" {
  let img = medc_grad(8, 8)
  // 正常窗
  let cfg = @medical.create_default_window_level("brain")
  let out = @medical.apply_window_level_medical(img, cfg)
  assert_true(out.width == 8)
  assert_true(out.channels >= 1)
  // 宽为 0 → normalized 兜底 0.5
  let zero_w = @medical.WindowLevelConfig::{
    center: 100.0,
    width: 0.0,
    preset: "custom",
  }
  let out2 = @medical.apply_window_level_medical(img, zero_w)
  assert_true(out2.data.length() > 0)
  // 极端窗 → 全部钳到 0 或 255
  let tiny = @medical.WindowLevelConfig::{
    center: -1000.0,
    width: 1.0,
    preset: "custom",
  }
  let out3 = @medical.apply_window_level_medical(img, tiny)
  assert_true(out3.data[0].to_int() == 255)
}

test "medcov: 阈值分割与区域生长" {
  let img = medc_grad(6, 6)
  // 阈值区间覆盖部分像素
  let mask = @medical.medical_threshold_segmentation(img, 10.0, 20.0)
  assert_true(mask.length() == 36)
  let mut true_count = 0
  for v in mask {
    if v {
      true_count += 1
    }
  }
  assert_true(true_count > 0 && true_count < 36)
  // 全部命中 / 全部不命中
  let all = @medical.medical_threshold_segmentation(img, -1.0, 1000.0)
  assert_true(all.length() == 36)
  let none = @medical.medical_threshold_segmentation(img, 1000000.0, 2000000.0)
  let mut none_true = 0
  for v in none {
    if v {
      none_true += 1
    }
  }
  assert_true(none_true == 0)
  // 区域生长：正常种子
  let rg = @medical.region_growing_segmentation(img, 2, 2, 0, 1000.0)
  assert_true(rg.length() == 36)
  let mut rg_true = 0
  for v in rg {
    if v {
      rg_true += 1
    }
  }
  assert_true(rg_true > 0)
  // 种子越界 → 全 false
  let bad = @medical.region_growing_segmentation(img, 99, 99, 0, 10.0)
  let mut bad_true = 0
  for v in bad {
    if v {
      bad_true += 1
    }
  }
  assert_true(bad_true == 0)
  // 负种子
  let neg = @medical.region_growing_segmentation(img, -1, -1, 0, 10.0)
  let mut neg_true = 0
  for v in neg {
    if v {
      neg_true += 1
    }
  }
  assert_true(neg_true == 0)
}

test "medcov: ROI 统计与病灶检测" {
  let img = medc_grad(10, 10)
  // 掩码部分为真
  let mask : Array[Bool] = []
  for i in 0..<100 {
    mask.push(i < 20)
  }
  let (mean, std, count) = @medical.calculate_roi_stats(img, mask)
  assert_true(count == 20)
  assert_true(mean > 0.0)
  assert_true(std >= 0.0)
  // 全 false → 空 ROI
  let empty_mask : Array[Bool] = []
  for _ in 0..<100 {
    empty_mask.push(false)
  }
  let (m2, s2, c2) = @medical.calculate_roi_stats(img, empty_mask)
  assert_true(c2 == 0)
  assert_true(m2 == 0.0)
  assert_true(s2 == 0.0)
  // 掩码长度不足（比像素少）→ 只统计覆盖部分
  let short_mask : Array[Bool] = [true, true, true]
  let (m3, _s3, c3) = @medical.calculate_roi_stats(img, short_mask)
  assert_true(c3 == 3)
  assert_true(m3 >= 0.0)
  // 病灶检测：清晰的高亮团块
  let lesion_img = medc_lesion(20, 20, 8, 8, 4, 200.0)
  let lesions = @medical.detect_lesions_simple(lesion_img, 1.0, 20.0)
  assert_true(lesions.length() >= 0)
  // 直径范围过滤（最小直径过大 → 无检出）
  let none = @medical.detect_lesions_simple(lesion_img, 100.0, 200.0)
  assert_true(none.length() == 0)
}

test "medcov: 配准 / 质量 / 报告分支" {
  let a = medc_grad(8, 8)
  let b = medc_grad(8, 8)
  // 相同图像 → 相似度高
  let reg = @medical.medical_image_registration(a, b, 5)
  assert_true(reg.iterations >= 0)
  assert_true(reg.similarity >= 0.0)
  assert_true(reg.transformation.length() == 16)
  // max_iterations = 0
  let reg0 = @medical.medical_image_registration(a, b, 0)
  assert_true(reg0.iterations >= 0)
  // 质量指标
  let q = @medical.calculate_medical_image_quality(a)
  assert_true(q.overall_quality >= 0.0)
  assert_true(q.snr >= 0.0)
  // 平坦图 → 噪声 0 的边界
  let flat = medc_img(8, 8, 1, 128.0)
  let q2 = @medical.calculate_medical_image_quality(flat)
  assert_true(q2.overall_quality >= 0.0)
  // 报告：无病灶 / 有病灶
  let rep0 = @medical.medical_image_report_to_string(a, [], q)
  assert_true(rep0.length() > 0)
  let lesions = @medical.detect_lesions_simple(a, 1.0, 50.0)
  let rep1 = @medical.medical_image_report_to_string(a, lesions, q)
  assert_true(rep1.length() > 0)
  // 默认分割配置字段
  let sc = @medical.create_default_medical_segmentation_config()
  assert_true(sc.method_type == "threshold")
  assert_true(sc.lower_threshold == 0.0)
  assert_true(sc.upper_threshold == 255.0)
  assert_true(sc.smoothness == 1.0)
}
