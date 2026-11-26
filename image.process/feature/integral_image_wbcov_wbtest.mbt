// 白盒覆盖：积分图像的参数校验分支

///|
fn iic_img(w : Int32, h : Int32, ch : Int32, v : Int32) -> @types.Image {
  let n = w * h * ch
  let data : Array[Byte] = Array::make(n, v.to_byte())
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn iic_zero(w : Int32, h : Int32) -> IntegralImage {
  IntegralImage::{
    width: w,
    height: h,
    data: Array::make((w + 1) * (h + 1), 0L),
  }
}

///|
fn iic_zero_sq(w : Int32, h : Int32) -> IntegralImageSq {
  IntegralImageSq::{
    width: w,
    height: h,
    data: Array::make((w + 1) * (h + 1), 0L),
  }
}

///|
test "iic: 非法通道与尺寸校验" {
  try {
    let _ = integral_image(iic_img(4, 4, 2, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_image_sq(iic_img(4, 4, 2, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let bad : @types.Image = {
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([1, 2]),
  }
  try {
    let _ = integral_image(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_image_sq(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "iic: 求和与均值的矩形校验" {
  let ii = iic_zero(4, 4)
  try {
    let _ = integral_sum(ii, -1, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_sum(ii, 0, 0, 0, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_sum(ii, 0, 0, 5, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_mean(ii, 0, -1, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_mean(ii, 0, 0, -1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_mean(ii, 0, 0, 5, 5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  assert_true(integral_mean(ii, 0, 0, 0, 0) == 0.0F)
}

///|
test "iic: 平方积分与方差校验" {
  let ii = iic_zero(4, 4)
  let sq = iic_zero_sq(4, 4)
  try {
    let _ = integral_variance(ii, iic_zero_sq(5, 4), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_variance(ii, sq, -1, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_variance(ii, sq, 0, 0, 0, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_variance(ii, sq, 0, 0, 5, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_sum_sq(sq, -1, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_sum_sq(sq, 0, 0, 0, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = integral_sum_sq(sq, 0, 0, 5, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let v = integral_variance(ii, sq, 0, 0, 1, 1) catch { _ => -1.0F }
  assert_true(v == 0.0F)
}
