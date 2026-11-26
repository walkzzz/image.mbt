// 覆盖率测试：手写体 OCR（模板 / 倾斜校正 / 分割识别 / 校验）

///|
fn hwc_blank(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = Array::make(w * h, b'\x00')
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn hwc_square(size : Int32, blk : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<size {
    for x in 0..<size {
      let inside = x >= 20 && x < 20 + blk && y >= 20 && y < 20 + blk
      d.push(if inside { b'\xff' } else { b'\x40' })
    }
  }
  @types.Image::{
    width: size,
    height: size,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn hwc_cfg(metric : String) -> HandwritingOcrConfig {
  HandwritingOcrConfig::{
    min_char_width: 8,
    max_char_width: 80,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 48,
    distance_metric: metric,
    flexibility: 0.7,
    use_slant_correction: true,
  }
}

///|
test "hwcov: 默认配置与模板" {
  let cfg = handwriting_ocr_default_config()
  assert_true(cfg.min_char_width == 8)
  assert_true(cfg.max_char_width == 80)
  assert_true(cfg.min_char_height == 10)
  assert_true(cfg.max_char_height == 100)
  assert_true(cfg.target_size == 48)
  assert_true(cfg.distance_metric == "euclidean")
  assert_true(cfg.flexibility == 0.7)
  assert_true(cfg.use_slant_correction)
  // digits：10 字符 × 3 变体 = 30
  let td = generate_handwriting_templates()
  assert_true(td.length() == 30)
  assert_true(td[0].0 == "0_v0")
  assert_true(td[0].1.length() == 256)
  // digits+letters：36 × 3 = 108
  let tl = generate_handwriting_templates(char_set="digits+letters")
  assert_true(tl.length() == 108)
  // 变体之间模板不同
  assert_true(td[0].1 != td[1].1)
}

///|
test "hwcov: 倾斜校正" {
  // 平坦图：估计角度应为 0 → 原图返回
  let flat = hwc_blank(32, 32)
  let c1 = correct_slant(flat)
  assert_true(c1.width == 32)
  assert_true(c1.data.length() == 1024)
  // 带白块图：可能触发旋转分支，尺寸保持不变
  let sq = hwc_square(64, 24)
  let c2 = correct_slant(sq)
  assert_true(c2.width == 64 && c2.height == 64)
  assert_true(c2.channels == 1)
  // 校验
  try {
    let _ = correct_slant(hwc_blank(0, 4))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 3,
    data: Bytes::from_array(Array::make(48, b'\x00')),
  }
  try {
    let _ = correct_slant(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = correct_slant(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "hwcov: 手写识别主流程与度量分支" {
  let img = hwc_square(64, 32)
  let r = recognize_handwriting(img)
  assert_true(r.confidence >= 0.0 && r.confidence <= 1.0)
  // 预处理含二值化与倾斜校正，检测数量与阈值相关，这里只约束上限
  assert_true(r.characters.length() <= 2)
  // 曼哈顿
  let rm = recognize_handwriting(img, config=hwc_cfg("manhattan"))
  assert_true(rm.characters.length() <= 2)
  // 余弦
  let rc = recognize_handwriting(img, config=hwc_cfg("cosine"))
  assert_true(rc.characters.length() <= 2)
  // 未知度量 → 回退欧氏
  let ru = recognize_handwriting(img, config=hwc_cfg("other"))
  assert_true(ru.characters.length() <= 2)
  // 关闭倾斜校正
  let no_slant = HandwritingOcrConfig::{
    min_char_width: 8,
    max_char_width: 80,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 48,
    distance_metric: "euclidean",
    flexibility: 0.7,
    use_slant_correction: false,
  }
  let rn = recognize_handwriting(img, config=no_slant)
  assert_true(rn.characters.length() <= 2)
  // 空白图
  let rb = recognize_handwriting(hwc_blank(32, 32))
  assert_true(rb.characters.length() <= 2)
  assert_true(rb.confidence <= 1.0)
}

///|
test "hwcov: 手写识别校验" {
  try {
    let _ = recognize_handwriting(hwc_blank(0, 4))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 5,
    data: Bytes::from_array(Array::make(80, b'\x00')),
  }
  try {
    let _ = recognize_handwriting(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = recognize_handwriting(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let img4 = hwc_blank(16, 16)
  let c1 = HandwritingOcrConfig::{
    min_char_width: 0,
    max_char_width: 80,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 48,
    distance_metric: "euclidean",
    flexibility: 0.7,
    use_slant_correction: true,
  }
  try {
    let _ = recognize_handwriting(img4, config=c1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c2 = HandwritingOcrConfig::{
    min_char_width: 50,
    max_char_width: 10,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 48,
    distance_metric: "euclidean",
    flexibility: 0.7,
    use_slant_correction: true,
  }
  try {
    let _ = recognize_handwriting(img4, config=c2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c3 = HandwritingOcrConfig::{
    min_char_width: 8,
    max_char_width: 80,
    min_char_height: 10,
    max_char_height: 100,
    target_size: 0,
    distance_metric: "euclidean",
    flexibility: 0.7,
    use_slant_correction: true,
  }
  try {
    let _ = recognize_handwriting(img4, config=c3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
