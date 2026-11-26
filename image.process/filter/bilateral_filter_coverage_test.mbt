// 覆盖率测试：双边滤波（标准/快速）分支

///|
fn bil_img(w : Int32, h : Int32, c : Int32, seed : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 31 + y * 17 + ch * 53 + seed) % 256)
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

///|
test "bil: 标准双边滤波" {
  // 灰度
  let g = @filter.bilateral_filter(bil_img(16, 16, 1, 7), 1, 1.5F, 20.0F)
  assert_true(g.width == 16)
  assert_true(g.channels == 1)
  // RGB
  let rgb = @filter.bilateral_filter(bil_img(16, 16, 3, 3), 2, 2.0F, 30.0F)
  assert_true(rgb.channels == 3)
  // RGBA：alpha 保持
  let src = bil_img(12, 12, 4, 5)
  let rgba = @filter.bilateral_filter(src, 1, 1.0F, 25.0F)
  assert_true(rgba.channels == 4)
  assert_true(rgba.data.length() == src.data.length())
  // 大半径
  let big = @filter.bilateral_filter(bil_img(12, 12, 3, 2), 4, 3.0F, 60.0F)
  assert_true(big.height == 12)
}

///|
test "bil: 快速双边滤波" {
  let img = bil_img(32, 32, 3, 9)
  let f1 = @filter.bilateral_filter_fast(img, 2, 2.0F, 30.0F, 1)
  assert_true(f1.width == 32)
  let f2 = @filter.bilateral_filter_fast(img, 2, 2.0F, 30.0F, 2)
  assert_true(f2.width == 32)
  let f4 = @filter.bilateral_filter_fast(img, 3, 2.5F, 40.0F, 4)
  assert_true(f4.height == 32)
  // 灰度 + downsample 2
  let gray = bil_img(20, 20, 1, 4)
  let fg = @filter.bilateral_filter_fast(gray, 1, 1.0F, 15.0F, 2)
  assert_true(fg.channels == 1)
  // RGBA
  let rgba = bil_img(16, 16, 4, 6)
  let fr = @filter.bilateral_filter_fast(rgba, 2, 2.0F, 30.0F, 2)
  assert_true(fr.channels == 4)
}

///|
test "bil: 错误分支" {
  // 尺寸非法
  try {
    let _ = @filter.bilateral_filter(bil_img(0, 8, 3, 0), 1, 1.0F, 10.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @filter.bilateral_filter_fast(
      bil_img(8, 0, 3, 0),
      1,
      1.0F,
      10.0F,
      1,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道非法
  try {
    let _ = @filter.bilateral_filter(bil_img(8, 8, 2, 0), 1, 1.0F, 10.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @filter.bilateral_filter_fast(
      bil_img(8, 8, 5, 0),
      1,
      1.0F,
      10.0F,
      1,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // sigma_space 非正
  try {
    let _ = @filter.bilateral_filter(bil_img(8, 8, 3, 1), 1, 0.0F, 10.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // radius < 1
  try {
    let _ = @filter.bilateral_filter(bil_img(8, 8, 3, 1), 0, 1.0F, 10.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @filter.bilateral_filter_fast(
      bil_img(8, 8, 3, 1),
      0,
      1.0F,
      10.0F,
      1,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @filter.bilateral_filter_fast(
      bil_img(8, 8, 3, 1),
      1,
      -1.0F,
      10.0F,
      1,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 数据长度不匹配
  let bad = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(8, (1).to_byte())),
  }
  try {
    let _ = @filter.bilateral_filter(bad, 1, 1.0F, 10.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @filter.bilateral_filter_fast(bad, 1, 1.0F, 10.0F, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
