// 覆盖率测试（补充分支）：16f 自适应阈值 —— 错误分支与 RGBA alpha 保留

fn at16_data(w : Int32, h : Int32, c : Int32, alpha : (Int32) -> Int32) -> Bytes {
  let d : Array[Byte] = []
  for _i in 0..<(w * h) {
    for k in 0..<c {
      let v = if c == 1 { 100 } else if k == 3 { alpha(_i) } else { 40 + k * 30 }
      d.push((v % 256).to_byte())
      d.push((v / 256).to_byte())
    }
  }
  Bytes::from_array(d)
}

fn at16_img(w : Int32, h : Int32, c : Int32) -> @types.Image16 {
  @types.Image16::{
    width: w,
    height: h,
    channels: c,
    data: at16_data(w, h, c, fn(idx) { 200 + (idx % 20) }),
  }
}

fn atf_px(v : Float) -> Array[Byte] {
  if v == 1.0F {
    [b'\x00', b'\x00', b'\x80', b'\x3f']
  } else if v == 0.5F {
    [b'\x00', b'\x00', b'\x00', b'\x3f']
  } else if v == 0.75F {
    [b'\x00', b'\x00', b'\x40', b'\x3f']
  } else {
    [b'\xcd', b'\xcc', b'\x4c', b'\x3e']
  }
}

fn atf_data(w : Int32, h : Int32, c : Int32) -> Bytes {
  let d : Array[Byte] = []
  for _i in 0..<(w * h) {
    for k in 0..<c {
      let v = if c == 1 { 0.5F } else if k == 3 { 0.75F } else { 0.2F }
      for b in atf_px(v) {
        d.push(b)
      }
    }
  }
  Bytes::from_array(d)
}

fn atf_img(w : Int32, h : Int32, c : Int32) -> @types.ImageF {
  @types.ImageF::{
    width: w,
    height: h,
    channels: c,
    data: atf_data(w, h, c),
  }
}

test "at16cov: mean_16 RGBA alpha 与错误分支" {
  let rgba = at16_img(6, 6, 4)
  let o = @color.adaptive_threshold_mean_16(rgba, 3, 5)
  assert_true(o.channels == 4)
  assert_true(o.data.length() == 6 * 6 * 8)
  // alpha 字节保留（第 i 像素 offset i*8+6/+7）
  assert_true(o.data[6].to_int() == 200)
  assert_true(o.data[7].to_int() == 0)
  assert_true(o.data[6 + 8].to_int() == 201)
  // 二值性：通道 0 只允许 0 或 65535
  let mut ok = true
  for i in 0..<(6 * 6) {
    let b0 = o.data[i * 8].to_int()
    let b1 = o.data[i * 8 + 1].to_int()
    if !((b0 == 0 && b1 == 0) || (b0 == 255 && b1 == 255)) {
      ok = false
    }
  }
  assert_true(ok)
  // 错误：宽为 0
  try {
    let _ = @color.adaptive_threshold_mean_16(at16_img(0, 4, 1), 3, 5)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：block_size 偶数 / 过小
  try {
    let _ = @color.adaptive_threshold_mean_16(at16_img(6, 6, 1), 4, 5)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adaptive_threshold_mean_16(at16_img(6, 6, 1), 1, 5)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：通道数非法（数据长度按 channels 计算不匹配 → 先命中长度校验）
  try {
    let _ = @color.adaptive_threshold_mean_16(at16_img(4, 4, 5), 3, 5)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：数据长度不匹配
  try {
    let _ = @color.adaptive_threshold_mean_16(
      @types.Image16::{
        width: 4,
        height: 4,
        channels: 1,
        data: Bytes::from_array([b'\x00', b'\x01']),
      },
      3,
      5,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "at16cov: mean_f RGBA alpha 与错误分支" {
  let rgba = atf_img(6, 6, 4)
  let o = @color.adaptive_threshold_mean_f(rgba, 3, 0.1F)
  assert_true(o.channels == 4)
  // alpha 保留为 0.75
  let alpha_bits = o.data[12].to_int()
  let alpha_bits2 = o.data[13].to_int()
  assert_true(alpha_bits == 0)
  assert_true(alpha_bits2 == 0)
  assert_true(o.data[14].to_int() == 64)
  assert_true(o.data[15].to_int() == 63)
  // 错误：block_size
  try {
    let _ = @color.adaptive_threshold_mean_f(atf_img(6, 6, 1), 2, 0.1F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adaptive_threshold_mean_f(atf_img(6, 6, 1), 1, 0.1F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：通道数
  try {
    let _ = @color.adaptive_threshold_mean_f(atf_img(4, 4, 2), 3, 0.1F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "at16cov: gaussian_16 RGBA alpha 与错误分支" {
  let rgba = at16_img(5, 5, 4)
  let o = @color.adaptive_threshold_gaussian_16(rgba, 3, 4)
  assert_true(o.channels == 4)
  assert_true(o.data[6].to_int() == 200)
  assert_true(o.data[7].to_int() == 0)
  // block 5
  let o5 = @color.adaptive_threshold_gaussian_16(at16_img(9, 9, 1), 5, 6)
  assert_true(o5.data.length() == 81 * 2)
  // 错误：尺寸
  try {
    let _ = @color.adaptive_threshold_gaussian_16(at16_img(0, 4, 1), 3, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adaptive_threshold_gaussian_16(at16_img(4, 0, 1), 3, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：数据长度（channels 5 时长度不符）
  try {
    let _ = @color.adaptive_threshold_gaussian_16(at16_img(4, 4, 5), 3, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：通道数（数据长度先通过，再命中通道校验）
  try {
    let _ = @color.adaptive_threshold_gaussian_16(at16_img(4, 4, 2), 3, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 错误：block_size 偶数
  try {
    let _ = @color.adaptive_threshold_gaussian_16(at16_img(6, 6, 1), 4, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "at16cov: gaussian_f RGBA alpha 与错误分支" {
  let rgba = atf_img(5, 5, 4)
  let o = @color.adaptive_threshold_gaussian_f(rgba, 3, 0.05F)
  assert_true(o.channels == 4)
  assert_true(o.data[14].to_int() == 64)
  assert_true(o.data[15].to_int() == 63)
  // block 5
  let o5 = @color.adaptive_threshold_gaussian_f(atf_img(9, 9, 1), 5, 0.05F)
  assert_true(o5.data.length() == 81 * 4)
  // 错误
  try {
    let _ = @color.adaptive_threshold_gaussian_f(atf_img(6, 6, 1), 2, 0.05F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adaptive_threshold_gaussian_f(atf_img(4, 4, 2), 3, 0.05F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adaptive_threshold_gaussian_f(atf_img(4, 4, 5), 3, 0.05F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
