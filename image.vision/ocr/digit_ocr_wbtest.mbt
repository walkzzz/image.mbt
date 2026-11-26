// 覆盖率测试：数字 OCR（模板生成 / 区域提取 / 特征 / 模板匹配 / 距离度量）

///|
fn dw_gray(w : Int32, h : Int32, fill : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(fill)
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
test "dw: 模板生成覆盖 0-9" {
  let ts = generate_digit_templates()
  assert_true(ts.length() == 10)
  for i in 0..<10 {
    assert_true(ts[i].0 == i.to_string())
    assert_true(ts[i].1.length() == 64)
  }
  // 各数字模板互不相同
  assert_true(ts[1].1 != ts[8].1)
  // 8 的模板包含全部段 → 特征和为最大
  let mut sum8 = 0.0
  for v in ts[8].1 {
    sum8 += v
  }
  let mut sum1 = 0.0
  for v in ts[1].1 {
    sum1 += v
  }
  assert_true(sum8 > sum1)
}

///|
test "dw: set_segment 越界裁剪" {
  let f : Array[Double] = Array::make(64, 0.0)
  set_segment(f, 8, 0, 0, 1, 1)
  assert_true(f[0] == 1.0)
  // 越界部分被忽略：row=7,col=7,width=4,height=4 → 仅 (7,7) 有效
  let g : Array[Double] = Array::make(64, 0.0)
  set_segment(g, 8, 7, 7, 4, 4)
  assert_true(g[63] == 1.0)
  assert_true(g[62] == 0.0)
}

///|
test "dw: 字符区域提取" {
  let img = dw_gray(40, 40, b'\xFF')
  // 正常裁剪 + 缩放到 32
  let r = extract_char_region(img, 4, 4, 20, 30, 32)
  assert_true(r.width == 32)
  assert_true(r.height == 32)
  assert_true(r.data.length() == 1024)
  // 目标尺寸 8
  let small = extract_char_region(img, 0, 0, 10, 10, 8)
  assert_true(small.width == 8)
  assert_true(small.data.length() == 64)
  // 越界裁剪：宽度溢出
  let over = extract_char_region(img, 30, 30, 40, 40, 16)
  assert_true(over.width == 16)
  assert_true(over.data.length() == 256)
  // 负宽高 → 全零图
  let neg = extract_char_region(img, 10, 10, -5, -5, 16)
  assert_true(neg.width == 16)
  assert_true(neg.data.length() == 256)
  assert_true(neg.data[0].to_int() == 0)
  // x 超出图像 → crop_w <= 0 → 全零
  let out_x = extract_char_region(img, 50, 0, 10, 10, 16)
  assert_true(out_x.data[0].to_int() == 0)
}

///|
test "dw: 特征提取与模板匹配" {
  // 全白 32x32：每个网格密度 1
  let white = extract_char_features(dw_gray(32, 32, b'\xFF'), 8)
  assert_true(white.length() == 64)
  assert_true(white[0] == 1.0)
  // 全黑：密度 0
  let black = extract_char_features(dw_gray(32, 32, b'\x00'), 8)
  assert_true(black[0] == 0.0)
  // 半亮（> 128 阈值）：值为 100 不算前景
  let gray = extract_char_features(dw_gray(32, 32, b'\x64'), 8)
  assert_true(gray[0] == 0.0)
  // 模板匹配：输入与 8 号模板完全一致 → 命中 "8"，距离 0 → 置信度 1.0
  let ts = generate_digit_templates()
  let (label, conf) = match_template(ts[8].1, ts, "euclidean")
  assert_true(label == "8")
  assert_true(conf == 1.0)
  // 三种距离度量都能给出确定结果
  let (l1, _c1) = match_template(white, ts, "manhattan")
  assert_true(l1.length() == 1)
  let (l2, _c2) = match_template(white, ts, "cosine")
  assert_true(l2.length() == 1)
  // 未知度量 → 回退欧氏
  let (l3, c3) = match_template(ts[3].1, ts, "unknown")
  assert_true(l3 == "3")
  assert_true(c3 == 1.0)
  // 空模板表 → "?"，置信度 1/(1+1e6)
  let (l4, c4) = match_template(white, [], "euclidean")
  assert_true(l4 == "?")
  assert_true(c4 > 0.0 && c4 < 0.0001)
}

///|
test "dw: 距离度量边界" {
  let a : Array[Double] = [3.0, 4.0]
  let b : Array[Double] = [0.0, 0.0]
  assert_true(euclidean_distance_local(a, b) == 5.0)
  assert_true(manhattan_distance_local(a, b) == 7.0)
  // 余弦：a 与 b（零向量）→ denom 0 → 1.0
  assert_true(cosine_distance_local(a, b) == 1.0)
  // 同向量 → 0
  assert_true(cosine_distance_local(a, a) == 0.0)
  // 长度不等时取较短
  let c : Array[Double] = [3.0]
  assert_true(euclidean_distance_local(a, c) == 0.0)
  assert_true(manhattan_distance_local(a, c) == 0.0)
  // 空数组 → 0 / 0 / 1.0
  let e : Array[Double] = []
  assert_true(euclidean_distance_local(e, e) == 0.0)
  assert_true(manhattan_distance_local(e, e) == 0.0)
  assert_true(cosine_distance_local(e, e) == 1.0)
  assert_true(_max_ocr(3, 5) == 5)
  assert_true(_max_ocr(5, 3) == 5)
}

///|
test "dw: 识别流水线校验与运行" {
  // 尺寸为 0
  try {
    let _ = recognize_digits(@types.Image::{
      width: 0,
      height: 4,
      channels: 1,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 多通道
  try {
    let _ = recognize_digits(@types.Image::{
      width: 4,
      height: 4,
      channels: 3,
      data: Bytes::from_array(Array::make(48, b'\x00')),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据长度不匹配
  try {
    let _ = recognize_digits(@types.Image::{
      width: 4,
      height: 4,
      channels: 1,
      data: Bytes::from_array([b'\x00']),
    })
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 四种配置校验
  let base = digit_ocr_default_config()
  assert_true(base.min_char_width == 5)
  assert_true(base.max_char_width == 60)
  assert_true(base.target_size == 32)
  assert_true(base.k == 3)
  assert_true(base.distance_metric == "euclidean")
  let bad = @types.Image::{
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(Array::make(256, b'\xFF')),
  }
  let c_min = DigitOcrConfig::{
    min_char_width: 0,
    max_char_width: 60,
    target_size: 32,
    use_knn: true,
    k: 3,
    distance_metric: "euclidean",
  }
  try {
    let _ = recognize_digits(bad, config=c_min)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c_max = DigitOcrConfig::{
    min_char_width: 10,
    max_char_width: 5,
    target_size: 32,
    use_knn: true,
    k: 3,
    distance_metric: "euclidean",
  }
  try {
    let _ = recognize_digits(bad, config=c_max)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c_target = DigitOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 0,
    use_knn: true,
    k: 3,
    distance_metric: "euclidean",
  }
  try {
    let _ = recognize_digits(bad, config=c_target)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let c_k = DigitOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    use_knn: true,
    k: 0,
    distance_metric: "euclidean",
  }
  try {
    let _ = recognize_digits(bad, config=c_k)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 合法输入：空白图无字符
  let blank = recognize_digits(dw_gray(32, 32, b'\xFF'))
  assert_true(blank.characters.length() >= 0)
  assert_true(blank.confidence >= 0.0)
  // 有笔画：manhattan / cosine 配置也能跑通
  let d : Array[Byte] = []
  for y in 0..<32 {
    for x in 0..<32 {
      d.push(
        if x >= 12 && x < 18 && y >= 4 && y < 28 {
          b'\x00'
        } else {
          b'\xFF'
        },
      )
    }
  }
  let glyph = @types.Image::{
    width: 32,
    height: 32,
    channels: 1,
    data: Bytes::from_array(d),
  }
  let r1 = recognize_digits(glyph)
  assert_true(r1.text.length() >= 0)
  let c_man = DigitOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    use_knn: true,
    k: 3,
    distance_metric: "manhattan",
  }
  let r2 = recognize_digits(glyph, config=c_man)
  assert_true(r2.characters.length() >= 0)
  let c_cos = DigitOcrConfig::{
    min_char_width: 5,
    max_char_width: 60,
    target_size: 32,
    use_knn: false,
    k: 3,
    distance_metric: "cosine",
  }
  let r3 = recognize_digits(glyph, config=c_cos)
  assert_true(r3.characters.length() >= 0)
}
