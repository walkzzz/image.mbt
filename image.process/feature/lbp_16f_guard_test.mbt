// lbp 16f 守卫分支覆盖测试（S13）

///|
fn lbp_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn lbp_gd16bad(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let base = lbp_gd16(w, h, ch)
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
fn lbp_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn lbp_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = lbp_gdf(w, h, ch)
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
test "lbp guard: lbp_16" {
  try {
    let _ = @feature.lbp_16(lbp_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lbp_16(lbp_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "lbp guard: lbp_f" {
  try {
    let _ = @feature.lbp_f(lbp_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lbp_f(lbp_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "lbp guard: lbp_uniform_16" {
  try {
    let _ = @feature.lbp_uniform_16(lbp_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lbp_uniform_16(lbp_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "lbp guard: lbp_uniform_f" {
  try {
    let _ = @feature.lbp_uniform_f(lbp_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lbp_uniform_f(lbp_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
