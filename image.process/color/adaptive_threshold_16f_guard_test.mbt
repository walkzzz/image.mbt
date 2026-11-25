// adaptive_threshold 16f 守卫分支覆盖测试（S13）

///|
fn adaptivethreshold_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let data : Array[Byte] = Array::make(w * h * ch * 2, b'\x00')
  for i in 0..<data.length() {
    data[i] = (i * 13 % 251).to_byte()
  }
  @types.Image16::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn adaptivethreshold_gd16bad(
  w : Int32,
  h : Int32,
  ch : Int32,
) -> @types.Image16 {
  let base = adaptivethreshold_gd16(w, h, ch)
  let arr = base.data.to_array()
  arr.push(b'\x00')
  @types.Image16::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(arr),
  }
}

///|
test "adaptive_threshold guard: adaptive_threshold_mean_16" {
  try {
    let _ = @color.adaptive_threshold_mean_16(
      adaptivethreshold_gd16(0, 0, 1),
      0,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.adaptive_threshold_mean_16(
      adaptivethreshold_gd16bad(6, 6, 3),
      0,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "adaptive_threshold guard: adaptive_threshold_gaussian_16" {
  try {
    let _ = @color.adaptive_threshold_gaussian_16(
      adaptivethreshold_gd16(0, 0, 1),
      0,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.adaptive_threshold_gaussian_16(
      adaptivethreshold_gd16bad(6, 6, 3),
      0,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "adaptive_threshold guard: threshold_otsu_16" {
  try {
    let _ = @color.threshold_otsu_16(adaptivethreshold_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.threshold_otsu_16(adaptivethreshold_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
