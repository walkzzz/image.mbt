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
test "decode_webp_pure: self-encoded 16x16 VP8 roundtrip" {
  let img = wvd_make_rgb(16, 16, 0)
  let bytes = @codec.encode_webp_lossy_full(img, quality=75)
  try {
    let back = @codec.decode_webp_pure(bytes)
    assert_eq(back.width, 16)
    assert_eq(back.height, 16)
    assert_eq(back.channels, 3)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("self-encoded decode failed: \{msg}")
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "decode_webp_pure: self-encoded 8x8 VP8 roundtrip" {
  let img = wvd_make_rgb(8, 8, 5)
  let bytes = @codec.encode_webp_lossy_full(img, quality=50)
  try {
    let back = @codec.decode_webp_pure(bytes)
    assert_eq(back.width, 8)
    assert_eq(back.height, 8)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("self-encoded 8x8 decode failed: \{msg}")
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "decode_webp_pure: 32x32 quality 100 roundtrip" {
  let img = wvd_make_rgb(32, 32, 11)
  let bytes = @codec.encode_webp_lossy_full(img, quality=100)
  try {
    let back = @codec.decode_webp_pure(bytes)
    assert_eq(back.width, 32)
    assert_eq(back.height, 32)
    assert_eq(back.channels, 3)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("32x32 decode failed: \{msg}")
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "decode_webp_pure: RGBA 16x16 roundtrip" {
  let img = wvd_make_rgba(16, 16, 3)
  let bytes = @codec.encode_webp_lossy_full(img, quality=75)
  try {
    let back = @codec.decode_webp_pure(bytes)
    assert_eq(back.width, 16)
    assert_eq(back.height, 16)
    assert_true(back.channels >= 3)
  } catch {
    @types.LoadError::DecodeFailed(msg) => {
      println("rgba decode failed: \{msg}")
      assert_true(false)
    }
    _ => assert_true(false)
  }
}

///|
test "decode_webp_pure: 奇数尺寸返回明确错误而非崩溃" {
  let small = wvd_make_rgb(1, 1, 7)
  let odd = wvd_make_rgb(3, 3, 2)
  let rejected1 = try {
    let _ = @codec.decode_webp_pure(@codec.encode_webp_lossy_full(small))
    false
  } catch {
    @types.LoadError::DecodeFailed(_) => true
    _ => false
  }
  assert_true(rejected1)
  let rejected3 = try {
    let _ = @codec.decode_webp_pure(
      @codec.encode_webp_lossy_full(odd, quality=25),
    )
    false
  } catch {
    @types.LoadError::DecodeFailed(_) => true
    _ => false
  }
  assert_true(rejected3)
}
