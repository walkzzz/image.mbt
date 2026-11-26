// 覆盖率测试：英文 OCR 符号模板与距离度量

///|
test "eng: 标点/符号模板均非空" {
  let symbols : Array[String] = [
    "+", "=", "-", ".", ",", ":", ";", "!", "?", "/", "\\", "~",
  ]
  for s in symbols {
    let f = generate_char_template_simple(s)
    let mut sum = 0.0
    for v in f {
      sum += v
    }
    assert_true(sum > 0.0)
  }
}

///|
test "eng: 曼哈顿/余弦距离短数组一侧截断" {
  let a : Array[Double] = [1.0, 2.0, 3.0]
  let b : Array[Double] = [1.0]
  assert_true(manhattan_distance_eng(a, b) == 0.0)
  assert_true(manhattan_distance_eng(b, a) == 0.0)
  assert_true(cosine_distance_eng(a, b) == 0.0)
  assert_true(cosine_distance_eng(b, a) == 0.0)
}

///|
test "eng: 余弦距离零向量回退为 1" {
  let z : Array[Double] = [0.0, 0.0, 0.0]
  let o : Array[Double] = [1.0, 0.0, 0.0]
  assert_true(cosine_distance_eng(z, o) == 1.0)
}

///|
test "eng: 单像素字符图仍可返回结果且置信度归一" {
  let data : Array[Byte] = Array::make(16 * 16, b'\xff')
  data[8 * 16 + 8] = b'\x00'
  let img : @types.Image = {
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(data),
  }
  try {
    let r = recognize_english(img)
    assert_true(r.confidence >= 0.0)
    assert_true(r.confidence <= 1.0)
    assert_true(r.confidence == r.confidence)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "eng: 非法配置与非法输入照常抛错" {
  let data : Array[Byte] = Array::make(4 * 4, b'\x00')
  let rgb : @types.Image = {
    width: 4,
    height: 4,
    channels: 3,
    data: Bytes::from_array(Array::make(48, b'\x00')),
  }
  try {
    let _ = recognize_english(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let gray : @types.Image = {
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(data),
  }
  try {
    let _ = recognize_english(gray, config=EnglishOcrConfig::{
      min_char_width: 0,
      max_char_width: 10,
      target_size: 8,
      case_sensitive: false,
      distance_metric: "euclidean",
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
