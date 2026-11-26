// 覆盖率测试：16f 滤波（box / gaussian / median / sharpen 的 Image16 与 ImageF 变体）

///|
fn f16_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32) -> Int32,
) -> @types.Image16 {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        let v = f(x, y)
        d.push((v % 256).to_byte())
        d.push((v / 256).to_byte())
      }
    }
  }
  @types.Image16::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn f16_px(v : Float) -> Array[Byte] {
  if v == 1.0F {
    [b'\x00', b'\x00', b'\x80', b'\x3f']
  } else if v == 0.5F {
    [b'\x00', b'\x00', b'\x00', b'\x3f']
  } else {
    [b'\xcd', b'\xcc', b'\x4c', b'\x3e']
  }
}

///|
fn ff_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32) -> Float,
) -> @types.ImageF {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        for b in f16_px(f(x, y)) {
          d.push(b)
        }
      }
    }
  }
  @types.ImageF::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn f16_gray(w : Int32, h : Int32) -> @types.Image16 {
  f16_img(w, h, 1, fn(x, y) { if (x + y) % 2 == 0 { 60000 } else { 1000 } })
}

///|
fn f16_rgba(w : Int32, h : Int32) -> @types.Image16 {
  f16_img(w, h, 4, fn(x, y) { if (x + y) % 2 == 0 { 40000 } else { 5000 } })
}

///|
fn f16_short() -> @types.Image16 {
  @types.Image16::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
}

///|
fn ff_gray(w : Int32, h : Int32) -> @types.ImageF {
  ff_img(w, h, 1, fn(x, y) { if (x + y) % 2 == 0 { 1.0F } else { 0.2F } })
}

///|
fn ff_rgba(w : Int32, h : Int32) -> @types.ImageF {
  ff_img(w, h, 4, fn(x, y) { if (x + y) % 2 == 0 { 0.75F } else { 0.2F } })
}

///|
fn ff_short() -> @types.ImageF {
  @types.ImageF::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
}

///|
test "f16cov: box_blur 16/f" {
  let g = f16_gray(6, 6)
  let o1 = @filter.box_blur_16(g, 1)
  assert_true(o1.channels == 1)
  assert_true(o1.data.length() == 6 * 6 * 2)
  // radius 0 → 原样
  let same = @filter.box_blur_16(g, 0)
  assert_true(same.data[0].to_int() == g.data[0].to_int())
  // RGBA
  let o2 = @filter.box_blur_16(f16_rgba(5, 5), 2)
  assert_true(o2.channels == 4)
  assert_true(o2.data.length() == 5 * 5 * 8)
  // 错误
  try {
    let _ = @filter.box_blur_16(f16_img(0, 4, 1, fn(_x, _y) { 1 }), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_16(f16_img(4, 4, 5, fn(_x, _y) { 1 }), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_16(f16_short(), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_16(g, -1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float
  let fg = ff_gray(6, 6)
  let fo1 = @filter.box_blur_f(fg, 1)
  assert_true(fo1.data.length() == 6 * 6 * 4)
  let fsame = @filter.box_blur_f(fg, 0)
  assert_true(fsame.data[0].to_int() == fg.data[0].to_int())
  let fo2 = @filter.box_blur_f(ff_rgba(5, 5), 2)
  assert_true(fo2.channels == 4)
  try {
    let _ = @filter.box_blur_f(ff_img(0, 4, 1, fn(_x, _y) { 0.5F }), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_f(ff_img(4, 4, 5, fn(_x, _y) { 0.5F }), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_f(ff_short(), 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.box_blur_f(fg, -1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "f16cov: gaussian_blur 16/f" {
  let g = f16_gray(6, 6)
  let o1 = @filter.gaussian_blur_16(g, 1, 1.0F)
  assert_true(o1.data.length() == 6 * 6 * 2)
  let o2 = @filter.gaussian_blur_16(f16_rgba(5, 5), 2, 1.5F)
  assert_true(o2.channels == 4)
  // 错误
  try {
    let _ = @filter.gaussian_blur_16(
      f16_img(0, 4, 1, fn(_x, _y) { 1 }),
      1,
      1.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_16(
      f16_img(4, 4, 5, fn(_x, _y) { 1 }),
      1,
      1.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_16(f16_short(), 1, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_16(g, -1, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_16(g, 1, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float
  let fg = ff_gray(6, 6)
  let fo1 = @filter.gaussian_blur_f(fg, 1, 1.0F)
  assert_true(fo1.data.length() == 6 * 6 * 4)
  let fo2 = @filter.gaussian_blur_f(ff_rgba(5, 5), 2, 1.5F)
  assert_true(fo2.channels == 4)
  try {
    let _ = @filter.gaussian_blur_f(
      ff_img(0, 4, 1, fn(_x, _y) { 0.5F }),
      1,
      1.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_f(
      ff_img(4, 4, 5, fn(_x, _y) { 0.5F }),
      1,
      1.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_f(ff_short(), 1, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.gaussian_blur_f(fg, 1, -1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "f16cov: median_blur 与 sharpen 16/f" {
  let g = f16_gray(6, 6)
  let m1 = @filter.median_blur_16(g, 3)
  assert_true(m1.data.length() == 6 * 6 * 2)
  let m2 = @filter.median_blur_16(f16_rgba(5, 5), 3)
  assert_true(m2.channels == 4)
  try {
    let _ = @filter.median_blur_16(f16_img(0, 4, 1, fn(_x, _y) { 1 }), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.median_blur_16(f16_img(4, 4, 5, fn(_x, _y) { 1 }), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.median_blur_16(f16_short(), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sharpen
  let s1 = @filter.sharpen_16(g, 1.0F)
  assert_true(s1.data.length() == 6 * 6 * 2)
  let s2 = @filter.sharpen_16(f16_rgba(5, 5), 2.0F)
  assert_true(s2.channels == 4)
  try {
    let _ = @filter.sharpen_16(f16_img(0, 4, 1, fn(_x, _y) { 1 }), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.sharpen_16(f16_img(4, 4, 5, fn(_x, _y) { 1 }), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.sharpen_16(f16_short(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float 版本
  let fg = ff_gray(6, 6)
  let fm1 = @filter.median_blur_f(fg, 3)
  assert_true(fm1.data.length() == 6 * 6 * 4)
  let fm2 = @filter.median_blur_f(ff_rgba(5, 5), 3)
  assert_true(fm2.channels == 4)
  let fs1 = @filter.sharpen_f(fg, 1.0F)
  assert_true(fs1.data.length() == 6 * 6 * 4)
  let fs2 = @filter.sharpen_f(ff_rgba(5, 5), 2.0F)
  assert_true(fs2.channels == 4)
  try {
    let _ = @filter.median_blur_f(ff_img(0, 4, 1, fn(_x, _y) { 0.5F }), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.median_blur_f(ff_img(4, 4, 5, fn(_x, _y) { 0.5F }), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.median_blur_f(ff_short(), 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.sharpen_f(ff_img(0, 4, 1, fn(_x, _y) { 0.5F }), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.sharpen_f(ff_img(4, 4, 5, fn(_x, _y) { 0.5F }), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @filter.sharpen_f(ff_short(), 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
