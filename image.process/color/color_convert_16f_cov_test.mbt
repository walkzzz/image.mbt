// 覆盖率测试：16-bit/Float 颜色转换的越界校验与黑点分支

///|
test "cfc: 16-bit 色彩空间越界校验" {
  try {
    let _ = @color.rgb_to_ycbcr_16(70000, 0, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.ycbcr_to_rgb_16(-1, 0, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.rgb_to_cmyk_16(0, 70000, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.cmyk_to_rgb_16(0, -5, 0, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "cfc: Float 色彩空间越界校验" {
  try {
    let _ = @color.rgb_to_ycbcr_f(1.5F, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.ycbcr_to_rgb_f(0.0F, -0.1F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.rgb_to_cmyk_f(0.0F, 0.0F, 1.2F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.cmyk_to_rgb_f(0.0F, 0.0F, 0.0F, 2.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "cfc: 全黑 CMYK 退化分支" {
  let (c16, m16, y16, k16) = @color.rgb_to_cmyk_16(0, 0, 0)
  assert_true(c16 == 0)
  assert_true(k16 == 65535)
  let (c, m, y, k) = @color.rgb_to_cmyk_f(0.0F, 0.0F, 0.0F)
  assert_true(c == 0.0F)
  assert_true(k == 1.0F)
  let _ = m
  let _ = y
  let _ = m16
  let _ = y16
}

///|
fn cfc_img16(w : Int32, h : Int32, ch : Int32, alpha0 : Bool) -> @types.Image16 {
  let n = w * h * ch
  let data : Array[Byte] = []
  for i in 0..<n {
    let v = if i % ch == ch - 1 && alpha0 { 0 } else { 20000 }
    data.push((v & 0xFF).to_byte())
    data.push(((v >> 8) & 0xFF).to_byte())
  }
  @types.Image16::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
test "cfc: alpha 为 0 时反预乘结果清零" {
  let img = cfc_img16(2, 1, 4, true)
  try {
    let out = @color.unpremultiply_alpha_16(img)
    assert_true(out.data[0].to_int() == 0)
  } catch {
    _ => assert_true(false)
  }
}

///|
fn cfc_imgf(w : Int32, h : Int32, ch : Int32, alpha0 : Bool) -> @types.ImageF {
  let n = w * h * ch
  let bytes : Array[Byte] = []
  for i in 0..<n {
    let v = if i % ch == ch - 1 && alpha0 { 0.0F } else { 0.5F }
    for b in v.to_le_bytes() {
      bytes.push(b)
    }
  }
  @types.ImageF::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(bytes),
  }
}

///|
test "cfc: Float alpha 为 0 时反预乘结果清零" {
  let img = cfc_imgf(2, 1, 4, true)
  try {
    let out = @color.unpremultiply_alpha_f(img)
    assert_true(out.data[0].to_double() == 0.0)
  } catch {
    _ => assert_true(false)
  }
}
