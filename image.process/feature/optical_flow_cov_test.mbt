// 覆盖率测试：光流的参数校验分支

///|
fn ofc_img(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  let n = w * h * ch
  let data : Array[Byte] = Array::make(n, b'\x80')
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn ofc_bad(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array([1, 2]),
  }
}

///|
fn ofc_zero() -> @types.Image {
  @types.Image::{
    width: 0,
    height: 0,
    channels: 1,
    data: Bytes::from_array([]),
  }
}

///|
test "ofc: lucas_kanade 校验链" {
  let ok = ofc_img(8, 8, 1)
  let pts : Array[(Int32, Int32)] = [(4, 4)]
  try {
    let _ = @feature.lucas_kanade(ofc_zero(), ok, pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ok, ofc_zero(), pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ofc_bad(8, 8, 5), ok, pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ok, ofc_bad(8, 8, 5), pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ofc_bad(8, 8, 1), ok, pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ok, ofc_bad(8, 8, 1), pts)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let empty : Array[(Int32, Int32)] = []
  try {
    let _ = @feature.lucas_kanade(ok, ok, empty)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ok, ok, pts, window_size=2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade(ok, ok, pts, max_iter=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "ofc: horn_schunck 校验链" {
  let ok = ofc_img(8, 8, 1)
  try {
    let _ = @feature.horn_schunck(ofc_zero(), ok)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ofc_zero())
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ofc_bad(8, 8, 5), ok)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ofc_bad(8, 8, 5))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ofc_bad(8, 8, 1), ok)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ofc_bad(8, 8, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ofc_img(4, 8, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ok, alpha=-1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck(ok, ok, iterations=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
