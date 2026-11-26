// 白盒覆盖率测试：中文 / 手写 OCR 内部流程（分割、裁剪、特征、模板匹配）

///|
fn chw_bin(
  w : Int32,
  h : Int32,
  x0 : Int32,
  y0 : Int32,
  bw : Int32,
  bh : Int32,
) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let inside = x >= x0 && x < x0 + bw && y >= y0 && y < y0 + bh
      d.push(if inside { b'\xff' } else { b'\x00' })
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn chw_chicfg() -> ChineseOcrConfig {
  ChineseOcrConfig::{
    min_char_width: 10,
    max_char_width: 100,
    target_size: 48,
    distance_metric: "euclidean",
    char_set: "common",
  }
}

///|
fn chw_hwcfg() -> HandwritingOcrConfig {
  HandwritingOcrConfig::{
    min_char_width: 8,
    max_char_width: 80,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 48,
    distance_metric: "euclidean",
    flexibility: 0.7,
    use_slant_correction: true,
  }
}

///|
test "chicov-wb: 中文分割 / 裁剪 / 特征" {
  let img = chw_bin(64, 64, 16, 16, 32, 32)
  let regions = segment_chinese_chars(img, chw_chicfg())
  assert_true(regions.length() == 1)
  assert_true(regions[0].0 == 16)
  assert_true(regions[0].1 == 16)
  assert_true(regions[0].2 == 32)
  assert_true(regions[0].3 == 32)
  // 过小区域（宽高 < min_char_width）被过滤
  let small = chw_bin(64, 64, 16, 16, 4, 4)
  let rs = segment_chinese_chars(small, chw_chicfg())
  assert_true(rs.length() == 0)
  // 空白图无区域
  let blank = chw_bin(32, 32, 0, 0, 0, 0)
  let rb = segment_chinese_chars(blank, chw_chicfg())
  assert_true(rb.length() == 0)
  // 裁剪：正常区域 → 目标尺寸平方
  let crop = extract_chinese_char_region(img, 16, 16, 32, 32, 32)
  assert_true(crop.width == 32 && crop.height == 32)
  assert_true(crop.data.length() == 1024)
  // 裁剪：超出右边界 → 截断后仍有效
  let crop2 = extract_chinese_char_region(img, 60, 60, 20, 20, 16)
  assert_true(crop2.data.length() == 256)
  // 裁剪：完全越界 → 全零图
  let crop3 = extract_chinese_char_region(img, 70, 70, 20, 20, 8)
  assert_true(crop3.data.length() == 64)
  // 特征：16x16 网格
  let f = extract_chinese_char_features(crop, 16)
  assert_true(f.length() == 256)
  let mut sum = 0.0
  for v in f {
    sum += v
  }
  assert_true(sum > 0.0 && sum <= 256.0)
  // 网格大于图像 → cell 为 0 → 密度 0
  let f2 = extract_chinese_char_features(crop3, 16)
  assert_true(f2.length() == 256)
  assert_true(f2[0] == 0.0)
}

///|
test "chicov-wb: 中文模板匹配各度量" {
  let f : Array[Double] = []
  for i in 0..<256 {
    f.push(if i % 3 == 0 { 1.0 } else { 0.0 })
  }
  let tpls : Array[(String, Array[Double])] = [("甲", f)]
  // 完全一致 → 距离 0 → 置信度 1.0
  let r = match_chinese_template(f, tpls, "euclidean")
  assert_true(r.0 == "甲")
  assert_true(r.1 == 1.0)
  // 曼哈顿
  let rm = match_chinese_template(f, tpls, "manhattan")
  assert_true(rm.0 == "甲")
  assert_true(rm.1 == 1.0)
  // 余弦
  let rc = match_chinese_template(f, tpls, "cosine")
  assert_true(rc.0 == "甲")
  // 未知度量 → 欧氏
  let ru = match_chinese_template(f, tpls, "whatever")
  assert_true(ru.0 == "甲")
  // 距离非零 → 置信度 ∈ (0,1)
  let other : Array[Double] = []
  for i in 0..<256 {
    other.push(if i % 2 == 0 { 1.0 } else { 0.0 })
  }
  let tpls2 : Array[(String, Array[Double])] = [("乙", other)]
  let r2 = match_chinese_template(f, tpls2, "euclidean")
  assert_true(r2.0 == "乙")
  assert_true(r2.1 > 0.0 && r2.1 < 1.0)
  // 空模板 → 占位标签
  let empty : Array[(String, Array[Double])] = []
  let r3 = match_chinese_template(f, empty, "euclidean")
  assert_true(r3.0 == "?")
  assert_true(r3.1 > 0.0 && r3.1 < 0.1)
}

///|
test "hwcov-wb: 手写分割 / 裁剪 / 特征" {
  let img = chw_bin(64, 64, 20, 20, 30, 30)
  let cfg = chw_hwcfg()
  let regions = segment_handwriting_chars(img, cfg)
  assert_true(regions.length() == 1)
  assert_true(regions[0].0 == 20)
  assert_true(regions[0].2 == 30)
  // 过小 → 过滤
  let rs = segment_handwriting_chars(chw_bin(64, 64, 20, 20, 4, 4), cfg)
  assert_true(rs.length() == 0)
  // 窄条：宽高比超出范围 → 过滤
  let thin = segment_handwriting_chars(chw_bin(64, 64, 10, 10, 10, 60), cfg)
  assert_true(thin.length() == 0)
  // 裁剪
  let crop = extract_handwriting_char_region(img, 20, 20, 30, 30, 32)
  assert_true(crop.width == 32)
  assert_true(crop.data.length() == 1024)
  let crop2 = extract_handwriting_char_region(img, 70, 70, 20, 20, 8)
  assert_true(crop2.data.length() == 64)
  // 特征
  let f = extract_handwriting_char_features(crop, 16)
  assert_true(f.length() == 256)
  let f2 = extract_handwriting_char_features(crop2, 16)
  assert_true(f2.length() == 256)
  assert_true(f2[0] == 0.0)
}

///|
test "hwcov-wb: 手写模板匹配投票" {
  let f : Array[Double] = []
  for i in 0..<256 {
    f.push(if i % 4 == 0 { 1.0 } else { 0.0 })
  }
  // 三变体：0 的两票胜出
  let tpls : Array[(String, Array[Double])] = [
    ("0_v0", f),
    ("0_v1", f),
    ("1_v0", f),
  ]
  let r = match_handwriting_template(f, tpls, "euclidean")
  assert_true(r.0 == "0")
  assert_true(r.1 >= 1.5)
  // 曼哈顿 / 余弦 / 未知度量分支
  let rm = match_handwriting_template(f, tpls, "manhattan")
  assert_true(rm.0 == "0")
  let rc = match_handwriting_template(f, tpls, "cosine")
  assert_true(rc.0 == "0")
  let ru = match_handwriting_template(f, tpls, "other")
  assert_true(ru.0 == "0")
  // 空模板 → 占位标签 + 置信度 0
  let empty : Array[(String, Array[Double])] = []
  let r2 = match_handwriting_template(f, empty, "euclidean")
  assert_true(r2.0 == "?")
  assert_true(r2.1 == 0.0)
}

///|
test "hwcov-wb: 倾斜角度与旋转" {
  let flat = chw_bin(32, 32, 0, 0, 0, 0)
  let a1 = estimate_slant_angle(flat)
  assert_true(a1.abs() <= 15.0)
  let sq = chw_bin(48, 48, 16, 16, 16, 16)
  let a2 = estimate_slant_angle(sq)
  assert_true(a2.abs() <= 15.0)
  // 直接旋转（覆盖旋转分支与越界插值）
  let rot = rotate_document(sq, 30.0)
  assert_true(rot.width > 48)
  assert_true(rot.height > 48)
  assert_true(rot.data.length() == rot.width * rot.height)
  let rot2 = rotate_document(flat, -45.0)
  assert_true(rot2.width > 32)
  assert_true(rot2.data.length() == rot2.width * rot2.height)
}
