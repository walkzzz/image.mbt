// 动画入口测试（S15）：帧数与延迟往返

///|
fn am_mk_img(w : Int32, h : Int32, ch : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for i in 0..<data.length() {
    data[i] = ((i * 13 + seed) & 0xFF).to_byte()
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
test "apng frames and delays roundtrip" {
  let f1 = am_mk_img(8, 6, 3, 0)
  let f2 = am_mk_img(8, 6, 3, 99)
  let frames : Array[@types.Image] = [f1, f2]
  let delays : Array[Int32] = [100, 200]
  let apng = @lib.encode_apng(frames, delays)
  let (got_frames, got_delays) = @lib.decode_animation(apng)
  assert_eq(got_frames.length(), 2)
  assert_eq(got_delays.length(), 2)
  assert_eq(got_delays[0], 100)
  assert_eq(got_delays[1], 200)
  assert_eq(got_frames[0].width, 8)
  assert_eq(got_frames[0].channels, 3)
}

///|
test "encode_apng rejects empty frames and delay mismatch" {
  let img = am_mk_img(4, 4, 3, 1)
  let mut hits = 0
  try {
    let _ = @lib.encode_apng([], [])
    assert_true(false)
  } catch {
    @types.LoadError::EncodeFailed(_) => hits = hits + 1
    _ => ()
  }
  try {
    let _ = @lib.encode_apng([img], [])
    assert_true(false)
  } catch {
    @types.LoadError::EncodeFailed(_) => hits = hits + 1
    _ => ()
  }
  assert_eq(hits, 2)
}

///|
test "gif single frame goes through decode_animation" {
  let img = am_mk_img(6, 5, 3, 7)
  let gif = @lib.encode_gif(img)
  let (frames, delays) = @lib.decode_animation(gif)
  assert_eq(frames.length(), 1)
  assert_eq(delays.length(), 1)
  assert_eq(frames[0].width, 6)
  assert_eq(frames[0].height, 5)
}

///|
test "decode_animation rejects static png" {
  let png = @codec.encode_png_pure(am_mk_img(4, 4, 3, 3))
  let mut hit = false
  try {
    let _ = @lib.decode_animation(png)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hit = true
    _ => ()
  }
  assert_true(hit)
}
