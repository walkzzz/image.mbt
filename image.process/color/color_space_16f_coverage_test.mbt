// 覆盖率测试：16-bit / float 色彩空间转换（HSL / HSV / XYZ / LAB）

test "cs16cov: HSL 16-bit 与 float" {
  // 纯红
  let (h1, s1, l1) = @color.rgb_to_hsl_16(65535, 0, 0)
  assert_true(h1 == 0.0F)
  assert_true(s1 == 1.0F)
  assert_true(l1 > 0.49F && l1 < 0.51F)
  // 反向
  let (r1, g1, b1) = @color.hsl_to_rgb_16(0.0F, 1.0F, 0.5F)
  assert_true(r1 == 65535)
  assert_true(g1 == 0)
  assert_true(b1 == 0)
  // 纯绿 / 纯蓝色相
  let (h2, _s2, _l2) = @color.rgb_to_hsl_16(0, 65535, 0)
  assert_true(h2 > 119.0F && h2 < 121.0F)
  let (h3, _s3, _l3) = @color.rgb_to_hsl_16(0, 0, 65535)
  assert_true(h3 > 239.0F && h3 < 241.0F)
  // 灰：s 0、h 0
  let (h4, s4, _l4) = @color.rgb_to_hsl_16(30000, 30000, 30000)
  assert_true(h4 == 0.0F)
  assert_true(s4 == 0.0F)
  // 负色相归一化（品红）
  let (h5, _s5, _l5) = @color.rgb_to_hsl_16(65535, 0, 65535)
  assert_true(h5 > 299.0F && h5 < 301.0F)
  // 环绕：h=360 → 0
  let (r2, _g2, _b2) = @color.hsl_to_rgb_16(360.0F, 1.0F, 0.5F)
  assert_true(r2 == 65535)
  // 负角
  let (r3, _g3, b3) = @color.hsl_to_rgb_16(-60.0F, 1.0F, 0.5F)
  assert_true(b3 == 65535)
  // 校验
  try {
    let _ = @color.rgb_to_hsl_16(70000, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsl_to_rgb_16(0.0F, 1.2F, 0.5F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float 版本
  let (fh, fs, fl) = @color.rgb_to_hsl_f(1.0F, 0.0F, 0.0F)
  assert_true(fh == 0.0F)
  assert_true(fs == 1.0F)
  assert_true(fl == 0.5F)
  let (fr, fg, fb) = @color.hsl_to_rgb_f(0.0F, 1.0F, 0.5F)
  assert_true(fr == 1.0F)
  assert_true(fg == 0.0F)
  assert_true(fb == 0.0F)
  let (fh2, _fs2, _fl2) = @color.rgb_to_hsl_f(0.0F, 1.0F, 0.0F)
  assert_true(fh2 > 119.0F && fh2 < 121.0F)
  let (fh3, ffs3, _fl3) = @color.rgb_to_hsl_f(0.5F, 0.5F, 0.5F)
  assert_true(fh3 == 0.0F)
  assert_true(ffs3 == 0.0F)
  let (fr2, _fg2, fb2) = @color.hsl_to_rgb_f(240.0F, 1.0F, 0.5F)
  assert_true(fb2 > 0.99F)
  assert_true(fr2 < 0.01F)
  try {
    let _ = @color.rgb_to_hsl_f(1.5F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsl_to_rgb_f(0.0F, 1.0F, -0.1F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cs16cov: HSV 16-bit 与 float" {
  let (h1, s1, v1) = @color.rgb_to_hsv_16(65535, 0, 0)
  assert_true(h1 == 0.0F)
  assert_true(s1 == 1.0F)
  assert_true(v1 == 1.0F)
  let (r1, g1, b1) = @color.hsv_to_rgb_16(0.0F, 1.0F, 1.0F)
  assert_true(r1 == 65535 && g1 == 0 && b1 == 0)
  let (r2, g2, _b2) = @color.hsv_to_rgb_16(120.0F, 1.0F, 1.0F)
  assert_true(r2 == 0 && g2 == 65535)
  // 黑：v 0
  let (_h2, s2, v2) = @color.rgb_to_hsv_16(0, 0, 0)
  assert_true(s2 == 0.0F)
  assert_true(v2 == 0.0F)
  // 灰
  let (h3, s3, _v3) = @color.rgb_to_hsv_16(20000, 20000, 20000)
  assert_true(h3 == 0.0F)
  assert_true(s3 == 0.0F)
  // 品红负色相归一化
  let (h4, _s4, _v4) = @color.rgb_to_hsv_16(65535, 0, 65535)
  assert_true(h4 > 299.0F && h4 < 301.0F)
  // 环绕
  let (r3, _g3, _b3) = @color.hsv_to_rgb_16(360.0F, 1.0F, 1.0F)
  assert_true(r3 == 65535)
  let (r4, g4, b4) = @color.hsv_to_rgb_16(-120.0F, 1.0F, 1.0F)
  assert_true(b4 == 65535)
  assert_true(r4 == 0 && g4 == 0)
  // 校验
  try {
    let _ = @color.rgb_to_hsv_16(-1, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsv_to_rgb_16(0.0F, 1.0F, 1.5F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float
  let (fh, fs, fv) = @color.rgb_to_hsv_f(1.0F, 0.0F, 0.0F)
  assert_true(fh == 0.0F)
  assert_true(fs == 1.0F)
  assert_true(fv == 1.0F)
  let (fr, fg, fb) = @color.hsv_to_rgb_f(0.0F, 1.0F, 1.0F)
  assert_true(fr == 1.0F && fg == 0.0F && fb == 0.0F)
  let (fh2, _fs2, fv2) = @color.rgb_to_hsv_f(0.0F, 0.0F, 0.0F)
  assert_true(fh2 == 0.0F)
  assert_true(fv2 == 0.0F)
  let (fh3, fs3, _fv3) = @color.rgb_to_hsv_f(0.4F, 0.4F, 0.4F)
  assert_true(fh3 == 0.0F)
  assert_true(fs3 == 0.0F)
  let (fr2, _fg2, _fb2) = @color.hsv_to_rgb_f(60.0F, 1.0F, 1.0F)
  assert_true(fr2 > 0.99F)
  try {
    let _ = @color.rgb_to_hsv_f(0.0F, 2.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.hsv_to_rgb_f(0.0F, -0.5F, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "cs16cov: XYZ 与 LAB" {
  // 白 → X≈0.9505, Y=1, Z≈1.089
  let (x1, y1, z1) = @color.rgb_to_xyz_16(65535, 65535, 65535)
  assert_true(x1 > 0.94F && x1 < 0.96F)
  assert_true(y1 > 0.99F && y1 < 1.01F)
  assert_true(z1 > 1.08F && z1 < 1.10F)
  // 黑 → 0
  let (x0, y0, z0) = @color.rgb_to_xyz_16(0, 0, 0)
  assert_true(x0 == 0.0F && y0 == 0.0F && z0 == 0.0F)
  // 低值走线性分支（1/65535 <= 0.04045）
  let (x2, _y2, _z2) = @color.rgb_to_xyz_16(1, 1, 1)
  assert_true(x2 >= 0.0F && x2 < 0.01F)
  // 往返
  let (r1, g1, b1) = @color.xyz_to_rgb_16(x1, y1, z1)
  assert_true(r1 > 65520)
  assert_true(g1 > 65520)
  assert_true(b1 > 65520)
  // 越界 clamp（负值）
  let (r2, _g2, _b2) = @color.xyz_to_rgb_16(0.0F, 0.0F, 1.0F)
  assert_true(r2 >= 0 && r2 <= 65535)
  // 校验
  try {
    let _ = @color.rgb_to_xyz_16(70000, 0, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.xyz_to_rgb_16(-1.0F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float XYZ
  let (fx, fy, fz) = @color.rgb_to_xyz_f(1.0F, 1.0F, 1.0F)
  assert_true(fx > 0.94F && fx < 0.96F)
  assert_true(fy > 0.99F && fy < 1.01F)
  let (fr, fg, fb) = @color.xyz_to_rgb_f(fx, fy, fz)
  assert_true(fr > 0.99F && fg > 0.99F && fb > 0.99F)
  let (fx0, _fy0, _fz0) = @color.rgb_to_xyz_f(0.001F, 0.001F, 0.001F)
  assert_true(fx0 >= 0.0F)
  try {
    let _ = @color.rgb_to_xyz_f(1.2F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.xyz_to_rgb_f(0.0F, -1.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // LAB 16：白 L≈100
  let (l1, a1, b1v) = @color.rgb_to_lab_16(65535, 65535, 65535)
  assert_true(l1 > 99.0F && l1 < 101.0F)
  assert_true(a1.abs() < 1.0F)
  assert_true(b1v.abs() < 1.0F)
  // LAB 16：黑 L≈0
  let (l0, a0, b0v) = @color.rgb_to_lab_16(0, 0, 0)
  assert_true(l0.abs() < 1.0F)
  assert_true(a0.abs() < 1.0F)
  assert_true(b0v.abs() < 1.0F)
  // 低亮度分支（t <= 0.008856）
  let (l2, _a2, _b2v) = @color.rgb_to_lab_16(100, 100, 100)
  assert_true(l2 >= 0.0F && l2 < 20.0F)
  // LAB → RGB 往返
  let (rr, gg, bb) = @color.lab_to_rgb_16(l1, 0.0F, 0.0F)
  assert_true(rr > 65520 && gg > 65520 && bb > 65520)
  let (rr2, gg2, bb2) = @color.lab_to_rgb_16(l0, 0.0F, 0.0F)
  assert_true(rr2 < 200 && gg2 < 200 && bb2 < 200)
  // 校验
  try {
    let _ = @color.rgb_to_lab_16(0, 0, 70000)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.lab_to_rgb_16(120.0F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float LAB
  let (fl1, fa1, fb1) = @color.rgb_to_lab_f(1.0F, 1.0F, 1.0F)
  assert_true(fl1 > 99.0F && fl1 < 101.0F)
  assert_true(fa1.abs() < 1.0F)
  assert_true(fb1.abs() < 1.0F)
  let (fl0, fa0, fb0) = @color.rgb_to_lab_f(0.0F, 0.0F, 0.0F)
  assert_true(fl0.abs() < 1.0F)
  assert_true(fa0.abs() < 1.0F)
  assert_true(fb0.abs() < 1.0F)
  let (frr, fgg, fbb) = @color.lab_to_rgb_f(100.0F, 0.0F, 0.0F)
  assert_true(frr > 0.99F && fgg > 0.99F && fbb > 0.99F)
  try {
    let _ = @color.rgb_to_lab_f(-0.1F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @color.lab_to_rgb_f(-1.0F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
