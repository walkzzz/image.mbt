// tonemap 16f 守卫分支覆盖测试（S13）

///|
fn tonemap_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn tonemap_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = tonemap_gdf(w, h, ch)
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
test "tonemap guard: gamma_tonemap_f" {
  try {
    let _ = @color.gamma_tonemap_f(tonemap_gdf(0, 0, 1), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_f(tonemap_gdf(6, 6, 5), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_f(tonemap_gdfbad(6, 6, 3), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_f(tonemap_gdf(6, 6, 3), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "tonemap guard: reinhard_tonemap_f" {
  try {
    let _ = @color.reinhard_tonemap_f(tonemap_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_f(tonemap_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_f(tonemap_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_f(tonemap_gdf(6, 6, 3), key=0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "tonemap guard: gamma_tonemap_16" {
  try {
    let _ = @color.gamma_tonemap_16(tonemap_gdf(0, 0, 1), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_16(tonemap_gdf(6, 6, 5), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_16(tonemap_gdfbad(6, 6, 3), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.gamma_tonemap_16(tonemap_gdf(6, 6, 3), 0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "tonemap guard: reinhard_tonemap_16" {
  try {
    let _ = @color.reinhard_tonemap_16(tonemap_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_16(tonemap_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_16(tonemap_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.reinhard_tonemap_16(tonemap_gdf(6, 6, 3), key=0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
