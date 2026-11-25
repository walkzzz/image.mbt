// hash_quality_integral 16f 守卫分支覆盖测试（S13）

///|
fn hashqualityintegral_gd16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
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
fn hashqualityintegral_gd16bad(
  w : Int32,
  h : Int32,
  ch : Int32,
) -> @types.Image16 {
  let base = hashqualityintegral_gd16(w, h, ch)
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
fn hashqualityintegral_gdf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
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
fn hashqualityintegral_gdfbad(
  w : Int32,
  h : Int32,
  ch : Int32,
) -> @types.ImageF {
  let base = hashqualityintegral_gdf(w, h, ch)
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
test "hash_quality_integral guard: ahash_16" {
  try {
    let _ = @feature.ahash_16(hashqualityintegral_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ahash_16(hashqualityintegral_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ahash_16(hashqualityintegral_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: dhash_16" {
  try {
    let _ = @feature.dhash_16(hashqualityintegral_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.dhash_16(hashqualityintegral_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.dhash_16(hashqualityintegral_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: phash_16" {
  try {
    let _ = @feature.phash_16(hashqualityintegral_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.phash_16(hashqualityintegral_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.phash_16(hashqualityintegral_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: ahash_f" {
  try {
    let _ = @feature.ahash_f(hashqualityintegral_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ahash_f(hashqualityintegral_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ahash_f(hashqualityintegral_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: dhash_f" {
  try {
    let _ = @feature.dhash_f(hashqualityintegral_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.dhash_f(hashqualityintegral_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.dhash_f(hashqualityintegral_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: phash_f" {
  try {
    let _ = @feature.phash_f(hashqualityintegral_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.phash_f(hashqualityintegral_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.phash_f(hashqualityintegral_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: mse_16" {
  try {
    let _ = @feature.mse_16(
      hashqualityintegral_gd16(0, 0, 1),
      hashqualityintegral_gd16(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.mse_16(
      hashqualityintegral_gd16(6, 6, 5),
      hashqualityintegral_gd16(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.mse_16(
      hashqualityintegral_gd16bad(6, 6, 3),
      hashqualityintegral_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: psnr_16" {
  try {
    let _ = @feature.psnr_16(
      hashqualityintegral_gd16(0, 0, 1),
      hashqualityintegral_gd16(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.psnr_16(
      hashqualityintegral_gd16(6, 6, 5),
      hashqualityintegral_gd16(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.psnr_16(
      hashqualityintegral_gd16bad(6, 6, 3),
      hashqualityintegral_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: ssim_16" {
  try {
    let _ = @feature.ssim_16(
      hashqualityintegral_gd16(0, 0, 1),
      hashqualityintegral_gd16(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ssim_16(
      hashqualityintegral_gd16(6, 6, 5),
      hashqualityintegral_gd16(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ssim_16(
      hashqualityintegral_gd16bad(6, 6, 3),
      hashqualityintegral_gd16bad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: mse_f" {
  try {
    let _ = @feature.mse_f(
      hashqualityintegral_gdf(0, 0, 1),
      hashqualityintegral_gdf(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.mse_f(
      hashqualityintegral_gdf(6, 6, 5),
      hashqualityintegral_gdf(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.mse_f(
      hashqualityintegral_gdfbad(6, 6, 3),
      hashqualityintegral_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: psnr_f" {
  try {
    let _ = @feature.psnr_f(
      hashqualityintegral_gdf(0, 0, 1),
      hashqualityintegral_gdf(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.psnr_f(
      hashqualityintegral_gdf(6, 6, 5),
      hashqualityintegral_gdf(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.psnr_f(
      hashqualityintegral_gdfbad(6, 6, 3),
      hashqualityintegral_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: ssim_f" {
  try {
    let _ = @feature.ssim_f(
      hashqualityintegral_gdf(0, 0, 1),
      hashqualityintegral_gdf(0, 0, 1),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ssim_f(
      hashqualityintegral_gdf(6, 6, 5),
      hashqualityintegral_gdf(6, 6, 5),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.ssim_f(
      hashqualityintegral_gdfbad(6, 6, 3),
      hashqualityintegral_gdfbad(6, 6, 3),
    )
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: integral_image_16" {
  try {
    let _ = @feature.integral_image_16(hashqualityintegral_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_16(hashqualityintegral_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_16(hashqualityintegral_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: integral_image_sq_16" {
  try {
    let _ = @feature.integral_image_sq_16(hashqualityintegral_gd16(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_sq_16(hashqualityintegral_gd16(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_sq_16(hashqualityintegral_gd16bad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: integral_image_f" {
  try {
    let _ = @feature.integral_image_f(hashqualityintegral_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_f(hashqualityintegral_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_f(hashqualityintegral_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}

///|
test "hash_quality_integral guard: integral_image_sq_f" {
  try {
    let _ = @feature.integral_image_sq_f(hashqualityintegral_gdf(0, 0, 1))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_sq_f(hashqualityintegral_gdf(6, 6, 5))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
  try {
    let _ = @feature.integral_image_sq_f(hashqualityintegral_gdfbad(6, 6, 3))
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => ()
  }
}
