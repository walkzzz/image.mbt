///|
fn wvd_make_rgb(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 9 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
fn wvd_make_rgba(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 4) {
    data.push(((i * 7 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 4,
    data: Bytes::from_array(data),
  }
}

///|
test "decode_webp_pure: 16x16 RGB VP8L 回环" {
  let img = wvd_make_rgb(16, 16, 0)
  let bytes = try @codec.encode_webp_vp8l_lz77(img) catch {
    _ => Bytes::from_array([])
  }
  let back = @codec.decode_webp_pure(bytes)
  assert_eq(back.width, 16)
  assert_eq(back.height, 16)
  assert_eq(back.channels, 4)
  let mut bad = 0
  for i in 0..<(16 * 16) {
    for c in 0..<3 {
      if back.data[i * 4 + c] != img.data[i * 3 + c] {
        bad = bad + 1
      }
    }
    if back.data[i * 4 + 3].to_int() != 255 {
      bad = bad + 1
    }
  }
  assert_eq(bad, 0)
}

///|
test "decode_webp_pure: 16x16 RGBA VP8L 回环" {
  let img = wvd_make_rgba(16, 16, 3)
  let bytes = try @codec.encode_webp_vp8l_lz77(img) catch {
    _ => Bytes::from_array([])
  }
  let back = @codec.decode_webp_pure(bytes)
  assert_eq(back.channels, 4)
  for c in 0..<8 {
    println(back.data[c].to_int().to_string())
  }
  let mut bad = 0
  for i in 0..<256 {
    for c in 0..<4 {
      if back.data[i * 4 + c] != img.data[i * 4 + c] {
        bad = bad + 1
      }
    }
  }
  assert_eq(bad, 0)
}

///|
test "decode_webp_pure: 非法 VP8 lossy 产物在解码侧被拒绝" {
  let img = wvd_make_rgb(16, 16, 1)
  let bytes = @codec.encode_webp_lossy_full(img, quality=75)
  let rejected = try {
    let _ = @codec.decode_webp_pure(bytes)
    false
  } catch {
    @types.LoadError::DecodeFailed(_) => true
    _ => false
  }
  assert_true(rejected)
}
