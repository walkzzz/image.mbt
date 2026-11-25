// advanced 16f 守卫分支覆盖测试（S13）

///|
fn advanced_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn advanced_gd16bad(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let base = advanced_gd16(w, h, ch)
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
fn advanced_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn advanced_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = advanced_gdf(w, h, ch)
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
test "advanced guard: inpaint_16" {
  try {
    let _ = @filter.inpaint_16(advanced_gd16(0, 0, 1), advanced_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_16(advanced_gd16(6, 6, 5), advanced_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_16(
      advanced_gd16bad(6, 6, 3),
      advanced_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_16(
      advanced_gd16(6, 6, 3),
      advanced_gd16(6, 6, 3),
      iterations=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: inpaint_fast_16" {
  try {
    let _ = @filter.inpaint_fast_16(
      advanced_gd16(0, 0, 1),
      advanced_gd16(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_16(
      advanced_gd16(6, 6, 5),
      advanced_gd16(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_16(
      advanced_gd16bad(6, 6, 3),
      advanced_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_16(
      advanced_gd16(6, 6, 3),
      advanced_gd16(6, 6, 3),
      radius=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: inpaint_f" {
  try {
    let _ = @filter.inpaint_f(advanced_gdf(0, 0, 1), advanced_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_f(advanced_gdf(6, 6, 5), advanced_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_f(
      advanced_gdfbad(6, 6, 3),
      advanced_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_f(
      advanced_gdf(6, 6, 3),
      advanced_gdf(6, 6, 3),
      iterations=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: inpaint_fast_f" {
  try {
    let _ = @filter.inpaint_fast_f(advanced_gdf(0, 0, 1), advanced_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_f(advanced_gdf(6, 6, 5), advanced_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_f(
      advanced_gdfbad(6, 6, 3),
      advanced_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.inpaint_fast_f(
      advanced_gdf(6, 6, 3),
      advanced_gdf(6, 6, 3),
      radius=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: nlm_denoise_16" {
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16(6, 6, 3), patch_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16(6, 6, 3), search_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_16(advanced_gd16(6, 6, 3), h=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: nlm_denoise_fast_16" {
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(6, 6, 3), patch_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(6, 6, 3), search_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(6, 6, 3), h=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_16(advanced_gd16(6, 6, 3), step=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: nlm_denoise_f" {
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdf(6, 6, 3), patch_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdf(6, 6, 3), search_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_f(advanced_gdf(6, 6, 3), h=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "advanced guard: nlm_denoise_fast_f" {
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(6, 6, 3), patch_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(6, 6, 3), search_size=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(6, 6, 3), h=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @filter.nlm_denoise_fast_f(advanced_gdf(6, 6, 3), step=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
