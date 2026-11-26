// 覆盖率测试：直方图（统计 / 均衡化 / 归一化 / 比较 / 匹配）

fn hg_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _ in 0..<c {
        d.push(f(x, y).to_byte())
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn hg_flat(w : Int32, h : Int32, c : Int32, v : Int32) -> @types.Image {
  hg_img(w, h, c, fn(_x, _y) { v })
}

fn hg_ramp(w : Int32, h : Int32, c : Int32) -> @types.Image {
  hg_img(w, h, c, fn(x, y) { (x * 16 + y * 4) % 256 })
}

test "hgcov: 直方图统计" {
  // 单通道：两像素 10 / 20
  let img = hg_img(2, 1, 1, fn(x, _y) { if x == 0 { 10 } else { 20 } })
  let h = @feature.histogram(img)
  assert_true(h.length() == 256)
  assert_true(h[10] == 1)
  assert_true(h[20] == 1)
  let mut total = 0
  for v in h {
    total += v
  }
  assert_true(total == 2)
  // RGB：BT.601 加权（255,0,0）→ 76
  let red = @types.Image::{
    width: 1,
    height: 1,
    channels: 3,
    data: Bytes::from_array([b'\xff', b'\x00', b'\x00']),
  }
  let hr = @feature.histogram(red)
  assert_true(hr[76] == 1)
  // RGBA 也按 3 通道处理
  let rgba = hg_flat(1, 1, 4, 0)
  let h4 = @feature.histogram(rgba)
  assert_true(h4[0] == 1)
  // 校验
  try {
    let _ = @feature.histogram(hg_flat(0, 1, 1, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 1,
    height: 1,
    channels: 5,
    data: Bytes::from_array([b'\x00', b'\x00', b'\x00', b'\x00', b'\x00']),
  }
  try {
    let _ = @feature.histogram(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 2,
    height: 1,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @feature.histogram(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hgcov: 均衡化与归一化" {
  let bad_small = @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x01', b'\x02', b'\x03']),
  }
  // 渐变图均衡化后范围铺开
  let ramp = hg_ramp(16, 16, 1)
  let eq = @feature.histogram_equalize(ramp)
  assert_true(eq.width == 16 && eq.height == 16)
  assert_true(eq.channels == 1)
  assert_true(eq.data.length() == 256)
  // 平坦图：denom <= 0 → 原样返回
  let flat = hg_flat(8, 8, 1, 77)
  let eqf = @feature.histogram_equalize(flat)
  assert_true(eqf.data[0].to_int() == 77)
  // RGB 与 RGBA 分支
  let rgb = hg_ramp(8, 8, 3)
  let eqrgb = @feature.histogram_equalize(rgb)
  assert_true(eqrgb.channels == 3)
  assert_true(eqrgb.data.length() == 8 * 8 * 3)
  let rgba = hg_ramp(8, 8, 4)
  let eqrgba = @feature.histogram_equalize(rgba)
  assert_true(eqrgba.channels == 4)
  // 校验
  try {
    let _ = @feature.histogram_equalize(hg_flat(0, 1, 1, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_equalize(hg_flat(2, 2, 5, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_equalize(bad_small)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 归一化：把 10..20 拉伸到 0..255
  let stretch = hg_img(2, 1, 1, fn(x, _y) { if x == 0 { 10 } else { 20 } })
  let nm = @feature.histogram_normalize(stretch)
  assert_true(nm.data[0].to_int() == 0)
  assert_true(nm.data[1].to_int() == 255)
  // 平坦图：range 0 → 原样
  let nmf = @feature.histogram_normalize(flat)
  assert_true(nmf.data[0].to_int() == 77)
  // RGBA 归一化保留 alpha
  let rgba2 = hg_img(2, 1, 4, fn(x, _y) { if x == 0 { 10 } else { 20 } })
  let nm4 = @feature.histogram_normalize(rgba2)
  assert_true(nm4.channels == 4)
  // 校验
  try {
    let _ = @feature.histogram_normalize(hg_flat(0, 1, 1, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_normalize(bad_small)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_normalize(bad_small)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hgcov: 直方图比较" {
  let h1 : Array[Int32] = [1, 2, 3, 4]
  let h2 : Array[Int32] = [1, 2, 3, 4]
  let h3 : Array[Int32] = [4, 3, 2, 1]
  // 相同 → 相关系数为 1
  let cor = @feature.compare_hist(h1, h2, @feature.HistCompareMethod::Correlation)
  assert_true(cor.to_double() > 0.99)
  // 反向 → 相关系数 -1
  let cor2 = @feature.compare_hist(h1, h3, @feature.HistCompareMethod::Correlation)
  assert_true(cor2.to_double() < -0.99)
  // 常数直方图 → den == 0 → 0
  let const_h : Array[Int32] = [5, 5, 5]
  let cor3 = @feature.compare_hist(
    const_h, const_h, @feature.HistCompareMethod::Correlation,
  )
  assert_true(cor3.to_double() == 0.0)
  // 卡方：相同 → 0
  let chi = @feature.compare_hist(h1, h2, @feature.HistCompareMethod::ChiSquare)
  assert_true(chi.to_double() == 0.0)
  let chi2 = @feature.compare_hist(h1, h3, @feature.HistCompareMethod::ChiSquare)
  assert_true(chi2.to_double() > 0.0)
  // 卡方：两者都为 0 的 bin 跳过
  let zeros : Array[Int32] = [0, 0, 0]
  let chi3 = @feature.compare_hist(zeros, zeros, @feature.HistCompareMethod::ChiSquare)
  assert_true(chi3.to_double() == 0.0)
  // 巴氏距离：相同 → 1
  let bc = @feature.compare_hist(h1, h2, @feature.HistCompareMethod::Bhattacharyya)
  assert_true(bc.to_double() > 0.99)
  // 全零 → 0
  let nonempty : Array[Int32] = [1, 2, 3]
  let bc0 = @feature.compare_hist(zeros, nonempty, @feature.HistCompareMethod::Bhattacharyya)
  assert_true(bc0.to_double() == 0.0)
  // 校验
  let empty : Array[Int32] = []
  try {
    let _ = @feature.compare_hist(empty, h1, @feature.HistCompareMethod::Correlation)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.compare_hist(h1, empty, @feature.HistCompareMethod::Correlation)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.compare_hist(h1, const_h, @feature.HistCompareMethod::Correlation)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hgcov: 直方图匹配" {
  let bad_small = @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x01', b'\x02', b'\x03']),
  }
  // 输入图与参考图均为渐变
  let img = hg_ramp(8, 8, 1)
  let refimg = hg_img(8, 8, 1, fn(x, y) { (255 - ((x * 16 + y * 4) % 256)) })
  let m = @feature.histogram_matching(img, refimg)
  assert_true(m.width == 8 && m.height == 8)
  assert_true(m.channels == 1)
  assert_true(m.data.length() == 64)
  // RGB 匹配
  let img3 = hg_ramp(4, 4, 3)
  let ref3 = hg_ramp(4, 4, 3)
  let m3 = @feature.histogram_matching(img3, ref3)
  assert_true(m3.channels == 3)
  // 单通道参考 + RGBA 输入 → 后两通道用 hist_ref=全零
  let rgba = hg_ramp(4, 4, 4)
  let m4 = @feature.histogram_matching(rgba, refimg)
  assert_true(m4.channels == 4)
  // 校验：输入图
  try {
    let _ = @feature.histogram_matching(hg_flat(0, 1, 1, 0), refimg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_matching(bad_small, refimg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_matching(bad_small, refimg)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 校验：参考图
  try {
    let _ = @feature.histogram_matching(img, hg_flat(0, 1, 1, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_matching(img, bad_small)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.histogram_matching(img, bad_small)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
