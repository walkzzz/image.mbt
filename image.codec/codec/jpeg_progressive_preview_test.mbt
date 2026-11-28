// progressive JPEG 逐扫描预览（`decode_jpeg_progressive_previews`）测试
// 覆盖：帧数与扫描序号、末帧与全量解码逐字节一致、粗帧与细帧的细节差异、baseline 拒绝

///|
fn jpv_grad(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      data.push(((x * 7 + y * 11) % 256).to_byte())
      data.push(((y * 5 + 30) % 256).to_byte())
      data.push(((x * 3 + 90) % 256).to_byte())
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
/// 行内相邻像素差绝对值之和（衡量细节量，粗帧的 8x8 块内为 0）
fn jpv_detail(img : @types.Image) -> Int32 {
  let mut sum = 0
  for y in 0..<img.height {
    for x in 1..<img.width {
      let i = (y * img.width + x) * img.channels
      let j = (y * img.width + x - 1) * img.channels
      let d = img.data[i].to_int() - img.data[j].to_int()
      sum = sum + (if d < 0 { -d } else { d })
    }
  }
  sum
}

///|
test "preview: 每扫描一帧，序号递增且末帧等于全量解码" {
  let img = jpv_grad(64, 48)
  let bytes = @codec.encode_jpeg_progressive_420(img, 80)
  let frames = @codec.decode_jpeg_progressive_previews(bytes, 1)
  assert_eq(frames.length(), 8)
  assert_eq(frames[0].scan_index, 1)
  assert_eq(frames[7].scan_index, 8)
  for f in frames {
    assert_eq(f.image.width, 64)
    assert_eq(f.image.height, 48)
    assert_eq(f.image.channels, 3)
  }
  let full = @codec.decode_jpeg_pure(bytes)
  for i in 0..<full.data.length() {
    assert_eq(frames[7].image.data[i], full.data[i])
  }
}

///|
test "preview: every_scans=4 只出 4、8 两帧" {
  let img = jpv_grad(40, 40)
  let bytes = @codec.encode_jpeg_progressive_420(img, 75)
  let frames = @codec.decode_jpeg_progressive_previews(bytes, 4)
  assert_eq(frames.length(), 2)
  assert_eq(frames[0].scan_index, 4)
  assert_eq(frames[1].scan_index, 8)
}

///|
test "preview: 首帧（纯 DC）比末帧细节少" {
  let img = jpv_grad(96, 64)
  let bytes = @codec.encode_jpeg_progressive_420(img, 85)
  let frames = @codec.decode_jpeg_progressive_previews(bytes, 1)
  let first = jpv_detail(frames[0].image)
  let last = jpv_detail(frames[7].image)
  assert_true(last > first)
  // DC 首扫时块内 8x8 恒定，行内细节只来自块边界，量级远小于终态
  assert_true(first * 4 < last)
}

///|
test "preview: every_scans<1 归一为 1 帧/扫描" {
  let img = jpv_grad(32, 32)
  let bytes = @codec.encode_jpeg_progressive_420(img, 70)
  let frames = @codec.decode_jpeg_progressive_previews(bytes, 0)
  assert_eq(frames.length(), 8)
}

///|
test "preview: 扫描总数可查" {
  let img = jpv_grad(32, 32)
  let bytes = @codec.encode_jpeg_progressive_420(img, 70)
  assert_eq(@codec.jpeg_progressive_scan_count(bytes), 8)
  let ten = @codec.encode_jpeg_progressive_420_scripted(
    img,
    70,
    @codec.jpeg_progressive_script_libjpeg(),
  )
  assert_eq(@codec.jpeg_progressive_scan_count(ten), 10)
}

///|
test "preview: baseline JPEG 拒绝逐扫描预览" {
  let img = jpv_grad(32, 32)
  let bytes = @codec.encode_jpeg_with_quality(img, 80)
  try {
    let _ = @codec.decode_jpeg_progressive_previews(bytes, 1)
    fail("expected error")
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => fail("wrong error")
  }
}
