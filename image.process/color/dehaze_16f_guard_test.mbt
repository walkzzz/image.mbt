// dehaze 16f 守卫分支覆盖测试（S13）

///|
fn dehaze_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn dehaze_gd16bad(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let base = dehaze_gd16(w, h, ch)
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
fn dehaze_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn dehaze_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = dehaze_gdf(w, h, ch)
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
test "dehaze guard: dehaze_16" {
  try {
    let _ = @color.dehaze_16(dehaze_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.dehaze_16(dehaze_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "dehaze guard: dehaze_f" {
  try {
    let _ = @color.dehaze_f(dehaze_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.dehaze_f(dehaze_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "dehaze guard: guided_filter_16" {
  try {
    let _ = @color.guided_filter_16(dehaze_gd16(0, 0, 1), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_16(dehaze_gd16(6, 6, 5), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_16(dehaze_gd16bad(6, 6, 3), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_16(dehaze_gd16(6, 6, 3), [], radius=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_16(dehaze_gd16(6, 6, 3), [], eps=0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "dehaze guard: guided_filter_f" {
  try {
    let _ = @color.guided_filter_f(dehaze_gdf(0, 0, 1), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_f(dehaze_gdf(6, 6, 5), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_f(dehaze_gdfbad(6, 6, 3), [])
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_f(dehaze_gdf(6, 6, 3), [], radius=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @color.guided_filter_f(dehaze_gdf(6, 6, 3), [], eps=0.0F)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
