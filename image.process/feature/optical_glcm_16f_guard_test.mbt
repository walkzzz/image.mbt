// optical_glcm 16f 守卫分支覆盖测试（S13）

///|
fn opticalglcm_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn opticalglcm_gd16bad(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let base = opticalglcm_gd16(w, h, ch)
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
fn opticalglcm_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn opticalglcm_gdfbad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let base = opticalglcm_gdf(w, h, ch)
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
test "optical_glcm guard: lucas_kanade_16" {
  try {
    let _ = @feature.lucas_kanade_16(
      opticalglcm_gd16(0, 0, 1),
      opticalglcm_gd16(0, 0, 1),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_16(
      opticalglcm_gd16(6, 6, 5),
      opticalglcm_gd16(6, 6, 5),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_16(
      opticalglcm_gd16bad(6, 6, 3),
      opticalglcm_gd16bad(6, 6, 3),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_16(
      opticalglcm_gd16(6, 6, 3),
      opticalglcm_gd16(6, 6, 3),
      [],
      window_size=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_16(
      opticalglcm_gd16(6, 6, 3),
      opticalglcm_gd16(6, 6, 3),
      [],
      max_iter=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: lucas_kanade_f" {
  try {
    let _ = @feature.lucas_kanade_f(
      opticalglcm_gdf(0, 0, 1),
      opticalglcm_gdf(0, 0, 1),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_f(
      opticalglcm_gdf(6, 6, 5),
      opticalglcm_gdf(6, 6, 5),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_f(
      opticalglcm_gdfbad(6, 6, 3),
      opticalglcm_gdfbad(6, 6, 3),
      [],
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_f(
      opticalglcm_gdf(6, 6, 3),
      opticalglcm_gdf(6, 6, 3),
      [],
      window_size=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.lucas_kanade_f(
      opticalglcm_gdf(6, 6, 3),
      opticalglcm_gdf(6, 6, 3),
      [],
      max_iter=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: horn_schunck_16" {
  try {
    let _ = @feature.horn_schunck_16(
      opticalglcm_gd16(0, 0, 1),
      opticalglcm_gd16(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_16(
      opticalglcm_gd16(6, 6, 5),
      opticalglcm_gd16(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_16(
      opticalglcm_gd16bad(6, 6, 3),
      opticalglcm_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_16(
      opticalglcm_gd16(6, 6, 3),
      opticalglcm_gd16(6, 6, 3),
      alpha=0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_16(
      opticalglcm_gd16(6, 6, 3),
      opticalglcm_gd16(6, 6, 3),
      iterations=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: horn_schunck_f" {
  try {
    let _ = @feature.horn_schunck_f(
      opticalglcm_gdf(0, 0, 1),
      opticalglcm_gdf(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_f(
      opticalglcm_gdf(6, 6, 5),
      opticalglcm_gdf(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_f(
      opticalglcm_gdfbad(6, 6, 3),
      opticalglcm_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_f(
      opticalglcm_gdf(6, 6, 3),
      opticalglcm_gdf(6, 6, 3),
      alpha=0.0F,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.horn_schunck_f(
      opticalglcm_gdf(6, 6, 3),
      opticalglcm_gdf(6, 6, 3),
      iterations=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: compute_glcm_16" {
  try {
    let _ = @feature.compute_glcm_16(opticalglcm_gd16(0, 0, 1), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_16(opticalglcm_gd16(6, 6, 5), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_16(opticalglcm_gd16bad(6, 6, 3), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_16(opticalglcm_gd16(6, 6, 3), 0, 0, levels=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: compute_glcm_f" {
  try {
    let _ = @feature.compute_glcm_f(opticalglcm_gdf(0, 0, 1), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_f(opticalglcm_gdf(6, 6, 5), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_f(opticalglcm_gdfbad(6, 6, 3), 0, 0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.compute_glcm_f(opticalglcm_gdf(6, 6, 3), 0, 0, levels=0)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: glcm_features_multi_direction_16" {
  try {
    let _ = @feature.glcm_features_multi_direction_16(opticalglcm_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_16(opticalglcm_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_16(
      opticalglcm_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_16(
      opticalglcm_gd16(6, 6, 3),
      levels=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "optical_glcm guard: glcm_features_multi_direction_f" {
  try {
    let _ = @feature.glcm_features_multi_direction_f(opticalglcm_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_f(opticalglcm_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_f(
      opticalglcm_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.glcm_features_multi_direction_f(
      opticalglcm_gdf(6, 6, 3),
      levels=0,
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
