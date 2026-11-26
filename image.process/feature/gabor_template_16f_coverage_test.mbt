// 覆盖率测试：Gabor 滤波 16f 变体与模板匹配 16f 变体

///|
fn gt16_img(
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
fn gt16_gray(w : Int32, h : Int32) -> @types.Image16 {
  gt16_img(w, h, 1, fn(x, y) { (x * 6 + y * 3) * 100 })
}

///|
fn gt16_rgba(w : Int32, h : Int32) -> @types.Image16 {
  gt16_img(w, h, 4, fn(x, y) { if (x + y) % 2 == 0 { 50000 } else { 3000 } })
}

///|
fn gtf_px(v : Float) -> Array[Byte] {
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

///|
fn gtf_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32) -> Float,
) -> @types.ImageF {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        for b in gtf_px(f(x, y)) {
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
test "gtcov: Gabor 滤波 16-bit" {
  let g = gt16_gray(8, 8)
  let o1 = @feature.gabor_filter_16(g, 3, 1.0F, 0.0F)
  assert_true(o1.width == 8)
  assert_true(o1.height == 8)
  assert_true(o1.channels == 1)
  assert_true(o1.data.length() == 8 * 8 * 2)
  // 自定义 lambda/gamma/phi
  let o2 = @feature.gabor_filter_16(
    g,
    5,
    1.5F,
    0.785F,
    lambda=8.0F,
    gamma=0.8F,
    phi=1.57F,
  )
  assert_true(o2.data.length() == 8 * 8 * 2)
  // RGBA 分支
  let o3 = @feature.gabor_filter_16(gt16_rgba(6, 6), 3, 1.0F, 0.0F)
  assert_true(o3.channels == 4)
  // 滤波器组
  let b1 = @feature.gabor_filter_bank_16(g, 3, 1.0F)
  assert_true(b1.channels == 1)
  assert_true(b1.data.length() == 8 * 8 * 2)
  let b2 = @feature.gabor_filter_bank_16(
    gt16_rgba(6, 6),
    3,
    1.0F,
    num_orientations=2,
  )
  assert_true(b2.channels == 4)
  // 错误分支
  try {
    let _ = @feature.gabor_filter_16(
      gt16_img(0, 4, 1, fn(_x, _y) { 100 }),
      3,
      1.0F,
      0.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_16(
      gt16_img(4, 4, 5, fn(_x, _y) { 100 }),
      3,
      1.0F,
      0.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_16(
      @types.Image16::{
        width: 4,
        height: 4,
        channels: 1,
        data: Bytes::from_array([b'\x00']),
      },
      3,
      1.0F,
      0.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_16(g, 4, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_16(g, 3, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_bank_16(g, 0, 1.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_bank_16(
      gt16_img(4, 4, 5, fn(_x, _y) { 100 }),
      3,
      1.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "gtcov: Gabor 滤波 float" {
  let g = gtf_img(8, 8, 1, fn(x, y) {
    if (x + y) % 2 == 0 {
      1.0F
    } else {
      0.2F
    }
  })
  let o1 = @feature.gabor_filter_f(g, 3, 1.0F, 0.0F)
  assert_true(o1.width == 8)
  assert_true(o1.channels == 1)
  assert_true(o1.data.length() == 8 * 8 * 4)
  let o2 = @feature.gabor_filter_f(
    g,
    5,
    1.5F,
    0.5F,
    lambda=6.0F,
    gamma=0.7F,
    phi=0.5F,
  )
  assert_true(o2.data.length() == 8 * 8 * 4)
  let rgba = gtf_img(6, 6, 4, fn(x, y) {
    if (x + y) % 2 == 0 {
      0.75F
    } else {
      0.2F
    }
  })
  let o3 = @feature.gabor_filter_f(rgba, 3, 1.0F, 0.0F)
  assert_true(o3.channels == 4)
  let b1 = @feature.gabor_filter_bank_f(g, 3, 1.0F)
  assert_true(b1.data.length() == 8 * 8 * 4)
  let b2 = @feature.gabor_filter_bank_f(rgba, 3, 1.0F, num_orientations=2)
  assert_true(b2.channels == 4)
  // 错误分支
  try {
    let _ = @feature.gabor_filter_f(
      gtf_img(0, 4, 1, fn(_x, _y) { 0.5F }),
      3,
      1.0F,
      0.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_f(
      gtf_img(4, 4, 5, fn(_x, _y) { 0.5F }),
      3,
      1.0F,
      0.0F,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_f(g, 2, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_f(g, 3, -1.0F, 0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.gabor_filter_bank_f(g, 3, 1.0F, num_orientations=0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "gtcov: 模板匹配 16-bit 与 float" {
  // 8x8 图：左上 3x3 为亮块
  let img = gt16_img(8, 8, 1, fn(x, y) {
    if x < 3 && y < 3 {
      60000
    } else {
      2000
    }
  })
  let tpl = gt16_img(3, 3, 1, fn(_x, _y) { 60000 })
  // 默认方法
  let r1 = @feature.template_match_16(img, tpl)
  assert_true(r1.length() > 0)
  // 其他度量
  let r2 = @feature.template_match_16(
    img,
    tpl,
    match_method=@feature.TemplateMatchMethod::SqDiff,
  )
  assert_true(r2.length() > 0)
  let r3 = @feature.template_match_16(
    img,
    tpl,
    match_method=@feature.TemplateMatchMethod::CCorrNormed,
  )
  assert_true(r3.length() > 0)
  // 最优位置
  let best = @feature.template_match_best_16(
    img,
    tpl,
    match_method=@feature.TemplateMatchMethod::CCoeffNormed,
  )
  match best {
    Some(v) => {
      assert_true(v.x >= 0)
      assert_true(v.y >= 0)
      assert_true(v.x <= 5)
      assert_true(v.y <= 5)
    }
    None => assert_true(false)
  }
  // 错误分支
  try {
    let _ = @feature.template_match_16(gt16_img(0, 4, 1, fn(_x, _y) { 1 }), tpl)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.template_match_16(img, gt16_img(0, 3, 1, fn(_x, _y) { 1 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let bigger = gt16_img(10, 10, 1, fn(_x, _y) { 1 })
    let _ = @feature.template_match_16(img, bigger)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.template_match_best_16(
      @types.Image16::{
        width: 4,
        height: 4,
        channels: 1,
        data: Bytes::from_array([b'\x00']),
      },
      tpl,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // float
  let fimg = gtf_img(8, 8, 1, fn(x, y) {
    if x < 3 && y < 3 {
      1.0F
    } else {
      0.2F
    }
  })
  let ftpl = gtf_img(3, 3, 1, fn(_x, _y) { 1.0F })
  let fr1 = @feature.template_match_f(fimg, ftpl)
  assert_true(fr1.length() > 0)
  let fr2 = @feature.template_match_f(
    fimg,
    ftpl,
    match_method=@feature.TemplateMatchMethod::SqDiffNormed,
  )
  assert_true(fr2.length() > 0)
  match @feature.template_match_best_f(fimg, ftpl) {
    Some(v) => {
      assert_true(v.x >= 0)
      assert_true(v.y >= 0)
    }
    None => assert_true(false)
  }
  try {
    let _ = @feature.template_match_f(
      gtf_img(0, 4, 1, fn(_x, _y) { 0.5F }),
      ftpl,
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @feature.template_match_f(
      fimg,
      gtf_img(0, 3, 1, fn(_x, _y) { 0.5F }),
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
