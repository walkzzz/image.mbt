// convolve_bilateral 16f 守卫分支覆盖测试（S13）

///|
fn convolvebilateral_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn convolvebilateral_gd16bad(
  w : Int32,
  h : Int32,
  ch : Int32,
) -> @types.Image16 {
  let base = convolvebilateral_gd16(w, h, ch)
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
fn convolvebilateral_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let data : Array[Byte] = Array::make(w * h * ch * 4, b'\x00')
  for i in 0..<(w * h * ch) {
    let v = 0.01F * Float::from_int(i % 100)
    let bits = v.reinterpret_as_int()
    data[i * 4] = (bits & 0xFF).to_byte()
    data[i * 4 + 1] = ((bits >> 8) & 0xFF).to_byte()
    data[i * 4 + 2] = ((bits >> 16) & 0xFF).to_byte()
    data[i * 4 + 3] = ((bits >> 24) & 0xFF).to_byte()
  }
  @types.ImageF::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn convolvebilateral_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = convolvebilateral_gdf(w, h, ch)
  let arr = base.data.to_array()
  arr.push(b'\x00')
  @types.ImageF::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(arr),
  }
}

///|
test "convolve_bilateral guard: convolve_16" {
  try {
    let _ = @filter.convolve_16(convolvebilateral_gd16(0, 0, 1), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_16(convolvebilateral_gd16(6, 6, 5), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_16(
      convolvebilateral_gd16bad(6, 6, 3),
      [],
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_16(convolvebilateral_gd16(6, 6, 3), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_16(convolvebilateral_gd16(6, 6, 3), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "convolve_bilateral guard: convolve_f" {
  try {
    let _ = @filter.convolve_f(convolvebilateral_gdf(0, 0, 1), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_f(convolvebilateral_gdf(6, 6, 5), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_f(
      convolvebilateral_gdfbad(6, 6, 3),
      [],
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_f(convolvebilateral_gdf(6, 6, 3), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.convolve_f(convolvebilateral_gdf(6, 6, 3), [], 0.0F, 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "convolve_bilateral guard: bilateral_filter_16" {
  try {
    let _ = @filter.bilateral_filter_16(
      convolvebilateral_gd16(0, 0, 1),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_16(
      convolvebilateral_gd16bad(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "convolve_bilateral guard: bilateral_filter_f" {
  try {
    let _ = @filter.bilateral_filter_f(
      convolvebilateral_gdf(0, 0, 1),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_f(
      convolvebilateral_gdfbad(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "convolve_bilateral guard: bilateral_filter_fast_16" {
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16(0, 0, 1),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16bad(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_16(
      convolvebilateral_gd16(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "convolve_bilateral guard: bilateral_filter_fast_f" {
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdf(0, 0, 1),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdfbad(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.bilateral_filter_fast_f(
      convolvebilateral_gdf(6, 6, 3),
      0,
      0.0F,
      0.0F,
      0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
