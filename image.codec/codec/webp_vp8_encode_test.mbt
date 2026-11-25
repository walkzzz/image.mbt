///|
fn wve_make_rgb(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 7 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
#warnings("-deprecated")
test "encode_webp_lossy_full: 16x16 RGB 生成 RIFF/WEBP/VP8" {
  let img = wve_make_rgb(16, 16, 0)
  try {
    let out = @codec.encode_webp_lossy_full(img, quality=75)
    assert_true(out.length() > 100)
    assert_eq(out[0], b'\x52')
    assert_eq(out[1], b'\x49')
    assert_eq(out[2], b'\x46')
    assert_eq(out[3], b'\x46')
    assert_eq(out[8], b'\x57')
    assert_eq(out[9], b'\x45')
    assert_eq(out[10], b'\x42')
    assert_eq(out[11], b'\x50')
    assert_eq(out[12], b'\x56')
    assert_eq(out[13], b'\x50')
    assert_eq(out[14], b'\x38')
  } catch {
    _ => assert_true(false)
  }
}

///|
#warnings("-deprecated")
test "encode_webp_lossy_full: 8x8 quality 50" {
  let img = wve_make_rgb(8, 8, 3)
  try {
    let out = @codec.encode_webp_lossy_full(img, quality=50)
    assert_true(out.length() > 50)
  } catch {
    _ => assert_true(false)
  }
}

///|
#warnings("-deprecated")
test "encode_webp_lossy_full: 1x1 RGB 最小图" {
  let img = wve_make_rgb(1, 1, 9)
  try {
    let out = @codec.encode_webp_lossy_full(img)
    assert_true(out.length() > 20)
  } catch {
    _ => assert_true(false)
  }
}

///|
#warnings("-deprecated")
test "encode_webp_lossy_full: 奇数尺寸 3x3 不越界" {
  let img = wve_make_rgb(3, 3, 5)
  try {
    let out = @codec.encode_webp_lossy_full(img, quality=75)
    assert_true(out.length() > 20)
    assert_eq(out[0], b'\x52')
    assert_eq(out[8], b'\x57')
  } catch {
    _ => assert_true(false)
  }
}

///|
#warnings("-deprecated")
test "encode_webp_lossy_full: 1 通道被拒" {
  let img = @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x10', b'\x20', b'\x30', b'\x40']),
  }
  let rejected = try {
    let _ = @codec.encode_webp_lossy_full(img)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
