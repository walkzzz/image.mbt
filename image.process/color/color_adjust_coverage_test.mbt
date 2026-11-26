// 覆盖率测试：颜色调整（亮度/对比度/Gamma/反色/HSV/HSL/饱和度/色相）

fn cadj_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
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

fn cadj_flat(w : Int32, h : Int32, c : Int32, v : Int32) -> @types.Image {
  cadj_img(w, h, c, fn(_x, _y) { v })
}

fn cadj_bad() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x01', b'\x02', b'\x03']),
  }
}

fn cadj_bad_ch() -> @types.Image {
  @types.Image::{
    width: 1,
    height: 1,
    channels: 5,
    data: Bytes::from_array(Array::make(5, b'\x00')),
  }
}

test "cadjcov: 亮度与对比度" {
  let g = cadj_flat(2, 1, 1, 100)
  let b1 = @color.adjust_brightness(g, 50)
  assert_true(b1.data[0].to_int() == 150)
  let b2 = @color.adjust_brightness(g, -200)
  assert_true(b2.data[0].to_int() == 0)
  // 4 通道：alpha 保留
  let rgba = cadj_flat(1, 1, 4, 100)
  let b3 = @color.adjust_brightness(rgba, 20)
  assert_true(b3.channels == 4)
  assert_true(b3.data[3].to_int() == 100)
  // 校验
  try {
    let _ = @color.adjust_brightness(cadj_flat(0, 1, 1, 0), 10)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_brightness(cadj_bad_ch(), 10)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_brightness(cadj_bad(), 10)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 对比度：factor 1.0 原图
  let c1 = @color.adjust_contrast(cadj_flat(2, 2, 1, 100), 1.0F)
  assert_true(c1.data[0].to_int() == 100)
  // factor 2.0：100 → 72
  let c2 = @color.adjust_contrast(cadj_flat(2, 2, 1, 100), 2.0F)
  assert_true(c2.data[0].to_int() == 72)
  // 200 → 饱和到 255
  let c3 = @color.adjust_contrast(cadj_flat(2, 2, 1, 200), 2.0F)
  assert_true(c3.data[0].to_int() == 255)
  // factor 0 → 全部 128
  let c4 = @color.adjust_contrast(cadj_flat(2, 2, 1, 100), 0.0F)
  assert_true(c4.data[0].to_int() == 128)
  // RGB / RGBA 分支
  let c5 = @color.adjust_contrast(cadj_flat(1, 1, 3, 100), 2.0F)
  assert_true(c5.channels == 3)
  let c6 = @color.adjust_contrast(cadj_flat(1, 1, 4, 100), 2.0F)
  assert_true(c6.data[3].to_int() == 100)
  // 校验
  try {
    let _ = @color.adjust_contrast(cadj_flat(0, 1, 1, 0), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_contrast(cadj_bad_ch(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_contrast(cadj_bad(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_contrast(cadj_flat(2, 2, 1, 10), -1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cadjcov: Gamma 与反色" {
  let g1 = @color.adjust_gamma(cadj_flat(2, 2, 1, 128), 1.0F)
  assert_true(g1.data[0].to_int() >= 127 && g1.data[0].to_int() <= 129)
  // gamma 2 → 变暗
  let g2 = @color.adjust_gamma(cadj_flat(2, 2, 1, 128), 2.0F)
  assert_true(g2.data[0].to_int() < 100)
  // gamma 0.5 → 变亮
  let g3 = @color.adjust_gamma(cadj_flat(2, 2, 1, 128), 0.5F)
  assert_true(g3.data[0].to_int() > 160)
  // 端点保持
  let g4 = @color.adjust_gamma(cadj_flat(2, 1, 1, 0), 2.0F)
  assert_true(g4.data[0].to_int() == 0)
  // RGBA 分支保留 alpha
  let g5 = @color.adjust_gamma(cadj_flat(1, 1, 4, 100), 2.0F)
  assert_true(g5.data[3].to_int() == 100)
  // 校验
  try {
    let _ = @color.adjust_gamma(cadj_flat(0, 1, 1, 0), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_gamma(cadj_bad_ch(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_gamma(cadj_bad(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_gamma(cadj_flat(2, 2, 1, 10), 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 反色
  let inv = @color.invert(cadj_flat(2, 1, 1, 10))
  assert_true(inv.data[0].to_int() == 245)
  let inv4 = @color.invert(cadj_flat(1, 1, 4, 10))
  assert_true(inv4.channels == 4)
  assert_true(inv4.data[3].to_int() == 10)
  try {
    let _ = @color.invert(cadj_flat(0, 1, 1, 0))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.invert(cadj_bad_ch())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.invert(cadj_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cadjcov: HSV 与 HSL 转换" {
  // 纯色色相
  let (h1, s1, v1) = @color.rgb_to_hsv(255, 0, 0)
  assert_true(h1 == 0.0F)
  assert_true(s1 == 1.0F)
  assert_true(v1 == 1.0F)
  let (h2, _s2, _v2) = @color.rgb_to_hsv(0, 255, 0)
  assert_true(h2 > 119.0F && h2 < 121.0F)
  let (h3, _s3, _v3) = @color.rgb_to_hsv(0, 0, 255)
  assert_true(h3 > 239.0F && h3 < 241.0F)
  // 负色相归一化：品红 → 300
  let (h4, _s4, _v4) = @color.rgb_to_hsv(255, 0, 255)
  assert_true(h4 > 299.0F && h4 < 301.0F)
  // 灰 → s 0, h 0
  let (h5, s5, _v5) = @color.rgb_to_hsv(128, 128, 128)
  assert_true(h5 == 0.0F)
  assert_true(s5 == 0.0F)
  // 黑 → v 0 → s 0
  let (_h6, s6, v6) = @color.rgb_to_hsv(0, 0, 0)
  assert_true(s6 == 0.0F)
  assert_true(v6 == 0.0F)
  // HSV → RGB
  let (r1, g1, b1) = @color.hsv_to_rgb(0.0F, 1.0F, 1.0F)
  assert_true(r1 == 255 && g1 == 0 && b1 == 0)
  let (r2, g2, b2) = @color.hsv_to_rgb(120.0F, 1.0F, 1.0F)
  assert_true(r2 == 0 && g2 == 255 && b2 == 0)
  // 360 环绕回 0
  let (r3, _g3, _b3) = @color.hsv_to_rgb(360.0F, 1.0F, 1.0F)
  assert_true(r3 == 255)
  // 负角度环绕
  let (r4, _g4, b4) = @color.hsv_to_rgb(-10.0F, 1.0F, 1.0F)
  assert_true(r4 > 240 && b4 > 0)
  // 灰度：s 0 → 三通道相等
  let (r5, g5, b5) = @color.hsv_to_rgb(0.0F, 0.0F, 0.5F)
  assert_true(r5 == g5 && g5 == b5)
  // HSL 转换
  let (h7, s7, l7) = @color.rgb_to_hsl(255, 0, 0)
  assert_true(h7 == 0.0F)
  assert_true(s7 == 1.0F)
  assert_true(l7 > 0.49F && l7 < 0.51F)
  let (h8, _s8, l8) = @color.rgb_to_hsl(0, 0, 255)
  assert_true(h8 > 239.0F && h8 < 241.0F)
  assert_true(l8 > 0.49F && l8 < 0.51F)
  let (h9, s9, _l9) = @color.rgb_to_hsl(128, 128, 128)
  assert_true(h9 == 0.0F)
  assert_true(s9 == 0.0F)
  // 负色相归一化（绿 > 蓝 且最大为绿以外）
  let (h10, _s10, _l10) = @color.rgb_to_hsl(255, 0, 255)
  assert_true(h10 > 299.0F && h10 < 301.0F)
  // HSL → RGB
  let (r6, g6, b6) = @color.hsl_to_rgb(0.0F, 1.0F, 0.5F)
  assert_true(r6 == 255 && g6 == 0 && b6 == 0)
  let (r7, g7, b7) = @color.hsl_to_rgb(120.0F, 1.0F, 0.5F)
  assert_true(r7 == 0 && g7 == 255 && b7 == 0)
  let (r8, _g8, b8) = @color.hsl_to_rgb(240.0F, 1.0F, 0.5F)
  assert_true(r8 == 0 && b8 == 255)
  // 环绕
  let (r9, _g9, _b9) = @color.hsl_to_rgb(360.0F, 1.0F, 0.5F)
  assert_true(r9 == 255)
  // 校验
  try {
    let _ = @color.rgb_to_hsv(256, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.rgb_to_hsv(0, -1, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsv_to_rgb(0.0F, 1.5F, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.rgb_to_hsl(0, 300, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsl_to_rgb(0.0F, 1.0F, -0.5F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cadjcov: 饱和度与色相调整" {
  // 单通道 → 原样返回
  let gray = cadj_flat(2, 2, 1, 100)
  let s1 = @color.adjust_saturation(gray, 2.0F)
  assert_true(s1.data[0].to_int() == 100)
  // factor 0 → 灰度化（BT.601）
  let rgb = @types.Image::{
    width: 1,
    height: 1,
    channels: 3,
    data: Bytes::from_array([b'\xff', b'\x00', b'\x00']),
  }
  let s2 = @color.adjust_saturation(rgb, 0.0F)
  let gy = s2.data[0].to_int()
  assert_true(gy == s2.data[1].to_int())
  assert_true(gy == s2.data[2].to_int())
  let expect = (255.0F * 0.299F + 0.5F).to_int()
  assert_true(gy == expect)
  // factor 1.0 → 原图
  let s3 = @color.adjust_saturation(rgb, 1.0F)
  assert_true(s3.data[0].to_int() == 255)
  assert_true(s3.data[1].to_int() <= 1)
  // RGBA 分支保留 alpha
  let rgba = @types.Image::{
    width: 1,
    height: 1,
    channels: 4,
    data: Bytes::from_array([b'\xff', b'\x00', b'\x00', b'\x80']),
  }
  let s4 = @color.adjust_saturation(rgba, 2.0F)
  assert_true(s4.data[3].to_int() == 128)
  // 校验
  try {
    let _ = @color.adjust_saturation(cadj_flat(0, 1, 3, 0), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_saturation(cadj_bad_ch(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_saturation(cadj_bad(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 色相：单通道原样
  let h1 = @color.adjust_hue(gray, 90.0F)
  assert_true(h1.data[0].to_int() == 100)
  // delta 0 → 近似原图
  let h2 = @color.adjust_hue(rgb, 0.0F)
  assert_true(h2.data[0].to_int() >= 250)
  // delta 120：红 → 绿
  let h3 = @color.adjust_hue(rgb, 120.0F)
  assert_true(h3.data[1].to_int() > 240)
  assert_true(h3.data[0].to_int() < 15)
  // 负偏移：红 + (-120) → 蓝
  let h4 = @color.adjust_hue(rgb, -120.0F)
  assert_true(h4.data[2].to_int() > 240)
  // 大偏移多次环绕
  let h5 = @color.adjust_hue(rgb, 720.0F)
  assert_true(h5.data[0].to_int() >= 250)
  // RGBA 保留 alpha
  let h6 = @color.adjust_hue(rgba, 120.0F)
  assert_true(h6.data[3].to_int() == 128)
  // 校验
  try {
    let _ = @color.adjust_hue(cadj_flat(0, 1, 3, 0), 90.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_hue(cadj_bad_ch(), 90.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.adjust_hue(cadj_bad(), 90.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
