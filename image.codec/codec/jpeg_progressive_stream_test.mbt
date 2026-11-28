// 渐进 JPEG 扫描游标（`JpegProgStream`）测试
// 覆盖：可停可续、与一次性预览逐字节一致、早停后 finish 等于完整解码、baseline 拒绝

///|
fn jpstr_grad(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      data.push(((x * 9 + y * 13) % 256).to_byte())
      data.push(((y * 7 + 40) % 256).to_byte())
      data.push(((x * 5 + 120) % 256).to_byte())
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
fn jps_same(a : @types.Image, b : @types.Image) -> Bool {
  if a.width != b.width || a.height != b.height || a.channels != b.channels {
    return false
  }
  if a.data.length() != b.data.length() {
    return false
  }
  for i in 0..<a.data.length() {
    if a.data[i] != b.data[i] {
      return false
    }
  }
  true
}

///|
test "stream: 逐步推进 8 条扫描，序号与剩余量同步" {
  let bytes = @codec.encode_jpeg_progressive_420(jpstr_grad(56, 40), 78)
  let s = @codec.jpeg_progressive_stream_open(bytes)
  assert_eq(@codec.jpeg_progressive_stream_remaining(s), 8)
  assert_eq(@codec.jpeg_progressive_stream_done(s), 0)
  let mut i = 0
  while true {
    match @codec.jpeg_progressive_stream_step(s) {
      Some(p) => {
        i = i + 1
        assert_eq(p.scan_index, i)
        assert_eq(p.image.width, 56)
        assert_eq(p.image.height, 40)
      }
      None => break
    }
  }
  assert_eq(i, 8)
  assert_eq(@codec.jpeg_progressive_stream_remaining(s), 0)
}

///|
test "stream: 每步帧与一次性预览逐字节一致" {
  let bytes = @codec.encode_jpeg_progressive_420(jpstr_grad(48, 32), 82)
  let frames = @codec.decode_jpeg_progressive_previews(bytes, 1)
  let s = @codec.jpeg_progressive_stream_open(bytes)
  let mut i = 0
  while i < frames.length() {
    match @codec.jpeg_progressive_stream_step(s) {
      Some(p) => {
        assert_eq(p.scan_index, frames[i].scan_index)
        assert_true(jps_same(p.image, frames[i].image))
      }
      None => fail("step 早于预期结束")
    }
    i = i + 1
  }
}

///|
test "stream: 只看前 2 帧后 finish 仍给出完整解码" {
  let bytes = @codec.encode_jpeg_progressive_420(jpstr_grad(64, 48), 80)
  let s = @codec.jpeg_progressive_stream_open(bytes)
  let first = @codec.jpeg_progressive_stream_step(s)
  assert_true(first is Some(_))
  let second = @codec.jpeg_progressive_stream_step(s)
  assert_true(second is Some(_))
  assert_eq(@codec.jpeg_progressive_stream_remaining(s), 6)
  // 前两帧的细节量必须小于终态（DC 与 AC 首扫还没完全补齐）
  let full = @codec.jpeg_progressive_stream_finish(s)
  assert_eq(@codec.jpeg_progressive_stream_remaining(s), 0)
  let full_ref = @codec.decode_jpeg_pure(bytes)
  assert_true(jps_same(full, full_ref))
}

///|
test "stream: 已解完后 step 返回 None 且 finish 不重复解码" {
  let bytes = @codec.encode_jpeg_progressive_420(jpstr_grad(32, 32), 75)
  let s = @codec.jpeg_progressive_stream_open(bytes)
  for _ in 0..<8 {
    let _ = @codec.jpeg_progressive_stream_step(s)
  }
  assert_eq(@codec.jpeg_progressive_stream_done(s), 8)
  assert_true(@codec.jpeg_progressive_stream_step(s) is None)
  let again = @codec.jpeg_progressive_stream_finish(s)
  let oracle = @codec.decode_jpeg_pure(bytes)
  assert_true(jps_same(again, oracle))
  assert_eq(@codec.jpeg_progressive_stream_done(s), 8)
}

///|
test "stream: baseline JPEG 拒绝打开" {
  let img = jpstr_grad(24, 24)
  let base = @codec.encode_jpeg_with_quality(img, 80)
  let r = Some(@codec.jpeg_progressive_stream_open(base)) catch { _ => None }
  assert_true(r is None)
}
