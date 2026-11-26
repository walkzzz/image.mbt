// 覆盖率测试：多尺度 Retinex（SSR / MSR / MSRCR）

///|
fn rtx_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32) -> Int32,
) -> @types.Image {
  let d : Array[Byte] = []
  let n = w * h * c
  for i in 0..<n {
    d.push(f(i).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn rtx_gray(w : Int32, h : Int32) -> @types.Image {
  rtx_img(w, h, 1, fn(i) { 40 + i % 8 * 20 })
}

///|
fn rtx_rgb(w : Int32, h : Int32, c : Int32) -> @types.Image {
  rtx_img(w, h, c, fn(i) {
    if i % 3 == 0 {
      200
    } else if i % 3 == 1 {
      120
    } else {
      60
    }
  })
}

///|
fn rtx_bad_size() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x00', b'\x00', b'\x00']),
  }
}

///|
test "rtxcov: SSR 主流程与校验" {
  // 灰度
  let g = rtx_gray(8, 8)
  let o1 = @color.ssr(g, sigma=2.0F)
  assert_true(o1.width == 8)
  assert_true(o1.height == 8)
  assert_true(o1.channels == 1)
  assert_true(o1.data.length() == 64)
  // RGB
  let o2 = @color.ssr(rtx_rgb(4, 4, 3), sigma=2.0F)
  assert_true(o2.channels == 3)
  assert_true(o2.data.length() == 48)
  // RGBA：alpha 保留
  let rgba = rtx_img(4, 4, 4, fn(i) { if i % 4 == 3 { 200 } else { 100 } })
  let o3 = @color.ssr(rgba, sigma=1.5F, gain=2.0F, offset=10.0F)
  assert_true(o3.data[3].to_int() == 200)
  assert_true(o3.data[7].to_int() == 200)
  // 全零图（内部按 1 处理）
  let black = rtx_img(4, 4, 1, fn(_i) { 0 })
  let o4 = @color.ssr(black, sigma=2.0F)
  assert_true(o4.data.length() == 16)
  // 零尺寸：原样返回
  let empty = @types.Image::{
    width: 0,
    height: 0,
    channels: 5,
    data: Bytes::from_array([]),
  }
  let o5 = @color.ssr(empty)
  assert_true(o5.width == 0)
  assert_true(o5.channels == 5)
  // 通道数非法
  try {
    let _ = @color.ssr(@types.Image::{
      width: 2,
      height: 2,
      channels: 2,
      data: Bytes::from_array(Array::make(8, b'\x10')),
    })
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据长度不匹配
  try {
    let _ = @color.ssr(rtx_bad_size())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigma 非法
  try {
    let _ = @color.ssr(g, sigma=0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "rtxcov: MSR 主流程与校验" {
  let g = rtx_gray(8, 8)
  let o1 = @color.msr(g, sigmas=[2.0F, 3.0F])
  assert_true(o1.data.length() == 64)
  assert_true(o1.channels == 1)
  // RGB
  let o2 = @color.msr(rtx_rgb(4, 4, 3), sigmas=[1.5F, 2.0F], gain=0.8F)
  assert_true(o2.channels == 3)
  assert_true(o2.data.length() == 48)
  // RGBA：alpha 保留
  let rgba = rtx_img(3, 3, 4, fn(i) { if i % 4 == 3 { 90 } else { 150 } })
  let o3 = @color.msr(rgba, sigmas=[2.0F], offset=5.0F)
  assert_true(o3.data[3].to_int() == 90)
  // 零尺寸
  let empty = @types.Image::{
    width: 0,
    height: 1,
    channels: 3,
    data: Bytes::from_array([]),
  }
  let o4 = @color.msr(empty)
  assert_true(o4.width == 0)
  // 通道数非法
  try {
    let _ = @color.msr(@types.Image::{
      width: 2,
      height: 2,
      channels: 2,
      data: Bytes::from_array(Array::make(8, b'\x10')),
    })
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据长度不匹配
  try {
    let _ = @color.msr(rtx_bad_size())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 空 sigmas
  try {
    let _ = @color.msr(g, sigmas=[])
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 非法 sigma
  try {
    let _ = @color.msr(g, sigmas=[2.0F, 0.0F])
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "rtxcov: MSRCR 主流程与校验" {
  // RGB
  let o1 = @color.msrcr(rtx_rgb(4, 4, 3), sigmas=[2.0F])
  assert_true(o1.channels == 3)
  assert_true(o1.data.length() == 48)
  // 增益/偏移/alpha/beta 参数
  let o2 = @color.msrcr(
    rtx_rgb(4, 4, 3),
    sigmas=[1.5F, 2.5F],
    gain=1.2F,
    offset=3.0F,
    alpha=100.0F,
    beta=40.0F,
  )
  assert_true(o2.data.length() == 48)
  // RGBA：alpha 保留
  let rgba = rtx_img(3, 3, 4, fn(i) { if i % 4 == 3 { 77 } else { 130 } })
  let o3 = @color.msrcr(rgba, sigmas=[2.0F])
  assert_true(o3.data[3].to_int() == 77)
  // 零尺寸
  let empty = @types.Image::{
    width: 0,
    height: 0,
    channels: 3,
    data: Bytes::from_array([]),
  }
  let o4 = @color.msrcr(empty)
  assert_true(o4.width == 0)
  // 灰度不支持
  try {
    let _ = @color.msrcr(rtx_gray(4, 4))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 空 sigmas
  try {
    let _ = @color.msrcr(rtx_rgb(4, 4, 3), sigmas=[])
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
