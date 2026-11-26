// 覆盖率测试：颜色空间与通道转换（色彩转换全家桶）

fn cc_img(w : Int32, h : Int32, c : Int32, fill : Array[Int32]) -> @types.Image {
  let d : Array[Byte] = []
  let n = w * h * c
  for i in 0..<n {
    let v = if i < fill.length() { fill[i] } else { 0 }
    d.push(v.to_byte())
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn cc_bad() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
}

test "cccov: 通道转换（灰度 / RGB / RGBA）" {
  // 灰度：单通道原样
  let g = cc_img(2, 1, 1, [100, 200])
  let o1 = @color.to_grayscale(g)
  assert_true(o1.channels == 1)
  assert_true(o1.data[0].to_int() == 100)
  // RGB → 灰度（BT.601）
  let rgb = cc_img(1, 1, 3, [255, 0, 0])
  let o2 = @color.to_grayscale(rgb)
  assert_true(o2.channels == 1)
  assert_true(o2.data[0].to_int() == 76)
  // RGBA → 灰度（忽略 alpha）
  let rgba = cc_img(1, 1, 4, [0, 255, 0, 10])
  let o3 = @color.to_grayscale(rgba)
  assert_true(o3.data[0].to_int() == 149)
  // to_rgb：4 通道 → 3
  let o4 = @color.to_rgb(rgba)
  assert_true(o4.channels == 3)
  assert_true(o4.data[0].to_int() == 0)
  assert_true(o4.data[1].to_int() == 255)
  // to_rgb：3 通道原样
  let o5 = @color.to_rgb(rgb)
  assert_true(o5.channels == 3)
  // to_rgb：单通道原样
  let o6 = @color.to_rgb(g)
  assert_true(o6.channels == 1)
  // to_rgba：3 → 4，alpha 255
  let o7 = @color.to_rgba(rgb)
  assert_true(o7.channels == 4)
  assert_true(o7.data[0].to_int() == 255)
  assert_true(o7.data[1].to_int() == 0)
  assert_true(o7.data[3].to_int() == 255)
  // to_rgba：4 通道
  let o8 = @color.to_rgba(rgba)
  assert_true(o8.channels == 4)
  // 错误分支
  try {
    let _ = @color.to_grayscale(
      @types.Image::{
        width: 0,
        height: 2,
        channels: 1,
        data: Bytes::from_array([]),
      },
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.to_grayscale(
      @types.Image::{
        width: 1,
        height: 1,
        channels: 5,
        data: Bytes::from_array(Array::make(5, b'\x00')),
      },
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.to_grayscale(cc_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.to_rgb(cc_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.to_rgba(cc_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cccov: alpha 预乘与还原" {
  let rgba = cc_img(2, 1, 4, [200, 100, 50, 128, 10, 20, 30, 255])
  let p = @color.premultiply_alpha(rgba)
  assert_true(p.channels == 4)
  // alpha 保留
  assert_true(p.data[3].to_int() == 128)
  // 预乘：200*128/255 ≈ 100
  assert_true(p.data[0].to_int() >= 95 && p.data[0].to_int() <= 105)
  // 还原
  let u = @color.unpremultiply_alpha(p)
  assert_true(u.channels == 4)
  assert_true(u.data[3].to_int() == 128)
  assert_true(u.data[0].to_int() >= 195 && u.data[0].to_int() <= 205)
  // alpha=255 的像素还原后应等于原值
  let u2 = @color.unpremultiply_alpha(p)
  assert_true(u2.data[7].to_int() == 255)
  // 全透明像素还原不崩溃
  let zero = cc_img(1, 1, 4, [50, 50, 50, 0])
  let pz = @color.premultiply_alpha(zero)
  assert_true(pz.data[0].to_int() == 0)
  let uz = @color.unpremultiply_alpha(pz)
  assert_true(uz.data.length() == 4)
  // 错误分支
  try {
    let _ = @color.premultiply_alpha(cc_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.unpremultiply_alpha(cc_bad())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cccov: YCbCr / XYZ / Lab / CMYK 数学转换" {
  // YCbCr 往返
  let (y1, cb1, cr1) = @color.rgb_to_ycbcr(255, 0, 0)
  assert_true(y1 > 70 && y1 < 80)
  let (r1, g1, b1) = @color.ycbcr_to_rgb(y1, cb1, cr1)
  assert_true(r1 > 240)
  assert_true(g1 < 15)
  assert_true(b1 < 15)
  let (y2, _cb2, _cr2) = @color.rgb_to_ycbcr(0, 0, 0)
  assert_true(y2 == 0)
  let (y3, _cb3, _cr3) = @color.rgb_to_ycbcr(255, 255, 255)
  assert_true(y3 >= 250)
  // 灰色 → cb/cr 接近 128
  let (_y4, cb4, cr4) = @color.rgb_to_ycbcr(128, 128, 128)
  assert_true(cb4 >= 127 && cb4 <= 129)
  assert_true(cr4 >= 127 && cr4 <= 129)
  // 钳制
  let (r2, g2, b2) = @color.ycbcr_to_rgb(255, 0, 255)
  assert_true(r2 <= 255)
  assert_true(g2 >= 0)
  assert_true(b2 >= 0)
  // 错误
  try {
    let _ = @color.rgb_to_ycbcr(256, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.ycbcr_to_rgb(0, 300, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // XYZ
  let (x1, y1x, z1) = @color.rgb_to_xyz(255, 255, 255)
  assert_true(x1 > 0.94F && x1 < 0.96F)
  assert_true(y1x > 0.99F && y1x < 1.01F)
  assert_true(z1 > 1.08F && z1 < 1.10F)
  let (x0, _y0, _z0) = @color.rgb_to_xyz(0, 0, 0)
  assert_true(x0 == 0.0F)
  // 低值线性分支
  let (xs, _ys, _zs) = @color.rgb_to_xyz(5, 5, 5)
  assert_true(xs >= 0.0F && xs < 0.01F)
  let (rr, gg, bb) = @color.xyz_to_rgb(x1, y1x, 1.0F)
  assert_true(rr > 250 && gg > 250 && bb > 230)
  try {
    let _ = @color.rgb_to_xyz(300, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.xyz_to_rgb(1.5F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // Lab
  let (lw, aw, bw) = @color.rgb_to_lab(255, 255, 255)
  assert_true(lw > 99.0F && lw < 101.0F)
  assert_true(aw.abs() < 1.0F)
  assert_true(bw.abs() < 1.0F)
  let (lb, ab, bb2) = @color.rgb_to_lab(0, 0, 0)
  assert_true(lb.abs() < 1.0F)
  assert_true(ab.abs() < 1.0F)
  assert_true(bb2.abs() < 1.0F)
  // 暗色触发 f 的低值分支
  let (ld, _ad, _bd) = @color.rgb_to_lab(2, 2, 2)
  assert_true(ld >= 0.0F && ld < 10.0F)
  let (lr, lg2, lb2) = @color.lab_to_rgb(80.0F, 0.0F, 0.0F)
  assert_true(lr > 180 && lg2 > 180 && lb2 > 180)
  let (dr, _dg, _db) = @color.lab_to_rgb(0.0F, 0.0F, 0.0F)
  assert_true(dr < 20)
  try {
    let _ = @color.rgb_to_lab(-1, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.lab_to_rgb(120.0F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // CMYK
  let (c1, m1, yy1, k1) = @color.rgb_to_cmyk(255, 255, 255)
  assert_true(c1 == 0 && m1 == 0 && yy1 == 0 && k1 == 0)
  let (c2, m2, yy2, k2) = @color.rgb_to_cmyk(0, 0, 0)
  assert_true(c2 == 0 && m2 == 0 && yy2 == 0 && k2 == 255)
  let (c3, _m3, _y3, k3) = @color.rgb_to_cmyk(255, 0, 0)
  assert_true(c3 == 0)
  assert_true(k3 == 0)
  let (r3, g3, b3) = @color.cmyk_to_rgb(0, 0, 0, 0)
  assert_true(r3 == 255 && g3 == 255 && b3 == 255)
  let (r4, g4, b4) = @color.cmyk_to_rgb(0, 0, 0, 255)
  assert_true(r4 == 0 && g4 == 0 && b4 == 0)
  try {
    let _ = @color.rgb_to_cmyk(300, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.cmyk_to_rgb(0, 0, 0, 300)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
