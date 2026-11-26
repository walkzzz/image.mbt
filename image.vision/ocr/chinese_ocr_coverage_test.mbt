// 覆盖率测试：中文 OCR（模板 / 分割 / 距离度量 / 校验）

///|
fn chc_blank(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = Array::make(w * h, b'\x00')
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn chc_square(size : Int32, blk : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<size {
    for x in 0..<size {
      let inside = x >= 16 && x < 16 + blk && y >= 16 && y < 16 + blk
      d.push(if inside { b'\xff' } else { b'\x00' })
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
test "chicov: 默认配置与模板生成" {
  let cfg = @ocr.chinese_ocr_default_config()
  assert_true(cfg.min_char_width == 10)
  assert_true(cfg.max_char_width == 100)
  assert_true(cfg.target_size == 48)
  assert_true(cfg.distance_metric == "euclidean")
  assert_true(cfg.char_set == "common")
  // 常用模板 100 个，每个 16x16
  let t = @ocr.generate_chinese_templates()
  assert_true(t.length() == 100)
  assert_true(t[0].1.length() == 256)
  assert_true(t[0].0 == "的")
  // full 字符集分支
  let tf = @ocr.generate_chinese_templates(char_set="full")
  assert_true(tf.length() == 100)
  // 模板稳定（同一汉字两次一致）
  let t2 = @ocr.generate_chinese_templates()
  assert_true(t2[1].1 == t[1].1)
}

///|
test "chicov: 识别主流程与距离度量分支" {
  let img = chc_square(64, 32)
  // 默认配置（欧氏度量 + common 字符集）
  let r = @ocr.recognize_chinese(img)
  assert_true(r.confidence >= 0.0 && r.confidence <= 1.0)
  // 预处理含 Sauvola 二值化，检测数量与阈值相关，这里只约束上限
  assert_true(r.characters.length() <= 2)
  // 曼哈顿距离分支
  let mut cfg_m = @ocr.chinese_ocr_default_config()
  cfg_m = @ocr.ChineseOcrConfig::{
    min_char_width: cfg_m.min_char_width,
    max_char_width: cfg_m.max_char_width,
    target_size: cfg_m.target_size,
    distance_metric: "manhattan",
    char_set: "full",
  }
  let rm = @ocr.recognize_chinese(img, config=cfg_m)
  assert_true(rm.characters.length() == r.characters.length())
  // 余弦距离分支
  let mut cfg_c = @ocr.chinese_ocr_default_config()
  cfg_c = @ocr.ChineseOcrConfig::{
    min_char_width: 8,
    max_char_width: 120,
    target_size: 32,
    distance_metric: "cosine",
    char_set: "common",
  }
  let rc = @ocr.recognize_chinese(img, config=cfg_c)
  assert_true(rc.characters.length() >= 1)
  // 未知度量 → 回退欧氏
  let cfg_u = @ocr.ChineseOcrConfig::{
    min_char_width: 8,
    max_char_width: 120,
    target_size: 32,
    distance_metric: "unknown",
    char_set: "common",
  }
  let ru = @ocr.recognize_chinese(img, config=cfg_u)
  assert_true(ru.characters.length() >= 1)
  // 空白图 → 无字符
  let rb = @ocr.recognize_chinese(chc_blank(32, 32))
  assert_true(rb.characters.length() == 0)
  assert_true(rb.confidence == 0.0)
}

///|
test "chicov: 输入与配置校验" {
  // 尺寸非法
  try {
    let _ = @ocr.recognize_chinese(chc_blank(0, 4))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道非法
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 3,
    data: Bytes::from_array(Array::make(48, b'\x00')),
  }
  try {
    let _ = @ocr.recognize_chinese(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据不匹配
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.recognize_chinese(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let img4 = chc_blank(16, 16)
  // min_char_width 非法
  let cfg1 = @ocr.ChineseOcrConfig::{
    min_char_width: 0,
    max_char_width: 100,
    target_size: 48,
    distance_metric: "euclidean",
    char_set: "common",
  }
  try {
    let _ = @ocr.recognize_chinese(img4, config=cfg1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // max < min
  let cfg2 = @ocr.ChineseOcrConfig::{
    min_char_width: 50,
    max_char_width: 10,
    target_size: 48,
    distance_metric: "euclidean",
    char_set: "common",
  }
  try {
    let _ = @ocr.recognize_chinese(img4, config=cfg2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // target_size 非法
  let cfg3 = @ocr.ChineseOcrConfig::{
    min_char_width: 8,
    max_char_width: 100,
    target_size: 0,
    distance_metric: "euclidean",
    char_set: "common",
  }
  try {
    let _ = @ocr.recognize_chinese(img4, config=cfg3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
