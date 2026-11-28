// 渐进 JPEG 半扫描推进（`JpegProgPartial`）测试
// 覆盖：一次全量逐单位推进 = 整解、分三段喂入可续、前缀阶段能出帧、baseline 拒绝

///|
fn jppart_grad(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      data.push(((x * 3 + y * 5) % 256).to_byte())
      data.push((x * 7 % 256).to_byte())
      data.push((y * 11 % 256).to_byte())
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
fn jppart_same(a : @types.Image, b : @types.Image) -> Bool {
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
test "partial: 全量字节按单位预算推进与整解一致" {
  let src = jppart_grad(48, 32)
  let bytes = @codec.encode_jpeg_progressive_420(src, 72)
  let whole = @codec.decode_jpeg_pure(bytes)
  let p = @codec.jpeg_progressive_partial_open(bytes)
  @codec.jpeg_progressive_partial_feed(p, bytes.length())
  let mut finished = false
  let mut hops = 0
  while !finished && hops < 400 {
    let adv = @codec.jpeg_progressive_partial_advance(p, 7)
    finished = adv.finished
    hops = hops + 1
    assert_true(!adv.stuck)
  }
  assert_true(finished)
  assert_true(jppart_same(@codec.jpeg_progressive_partial_image(p), whole))
}

///|
test "partial: 字节分三段喂入, 中途 stuck 后可续" {
  let src = jppart_grad(40, 24)
  let bytes = @codec.encode_jpeg_progressive_420(src, 72)
  let whole = @codec.decode_jpeg_pure(bytes)
  let n = bytes.length()
  let p = @codec.jpeg_progressive_partial_open(bytes)
  @codec.jpeg_progressive_partial_feed(p, n / 3)
  let a1 = @codec.jpeg_progressive_partial_advance(p, 1000)
  assert_true(a1.stuck)
  @codec.jpeg_progressive_partial_feed(p, 2 * n / 3)
  let a2 = @codec.jpeg_progressive_partial_advance(p, 1000)
  assert_true(a2.unit_done >= a1.unit_done)
  @codec.jpeg_progressive_partial_feed(p, n)
  let mut finished = false
  let mut hops = 0
  while !finished && hops < 400 {
    let adv = @codec.jpeg_progressive_partial_advance(p, 1000)
    finished = adv.finished
    hops = hops + 1
  }
  assert_true(finished)
  assert_true(jppart_same(@codec.jpeg_progressive_partial_image(p), whole))
}

///|
test "partial: 四分之一字节就能出帧（渐进成形）" {
  let src = jppart_grad(40, 24)
  let bytes = @codec.encode_jpeg_progressive_420(src, 72)
  let n = bytes.length()
  let p = @codec.jpeg_progressive_partial_open(bytes)
  @codec.jpeg_progressive_partial_feed(p, n / 4)
  let a = @codec.jpeg_progressive_partial_advance(p, 1000)
  assert_true(a.unit_done > 0 || a.stuck)
  let img = @codec.jpeg_progressive_partial_image(p)
  assert_eq(img.width, 40)
  assert_eq(img.height, 24)
}

///|
test "partial: baseline 拒绝打开" {
  let src = jppart_grad(24, 16)
  let bytes = @codec.encode_jpeg_pure(src)
  let rejected = try {
    let _ = @codec.jpeg_progressive_partial_open(bytes)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
