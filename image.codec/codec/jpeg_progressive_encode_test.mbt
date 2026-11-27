// 渐进式 JPEG（SOF2）编码测试
// 覆盖：帧头/扫描结构、与自解码的往返、边界尺寸、灰度输入、像素上限、与 baseline 的体积对比

///|
fn jpe_marker_count(bytes : Bytes, marker : Int32) -> Int32 {
  let n = bytes.length()
  let mut count = 0
  let mut i = 0
  while i < n - 1 {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == marker {
      count += 1
    }
    i += 1
  }
  count
}

///|
fn jpe_grad_image(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      data.push((x * 4 % 256).to_byte())
      data.push((y * 4 % 256).to_byte())
      data.push(b'\x80')
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
fn jpe_mean_abs_diff(a : Bytes, b : Bytes) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  let mut sum = 0
  for i in 0..<n {
    let d = a[i].to_int() - b[i].to_int()
    sum += if d < 0 { -d } else { d }
  }
  if n == 0 {
    0
  } else {
    sum / n
  }
}

///|
test "encode_jpeg_progressive: SOF2 frame header, no SOF0" {
  let img = jpe_grad_image(16, 16)
  let bytes = @codec.encode_jpeg_progressive(img, 85)
  assert_eq(jpe_marker_count(bytes, 0xC2), 1)
  assert_eq(jpe_marker_count(bytes, 0xC0), 0)
  // SOI / EOI 仍在两端
  assert_eq(bytes[0].to_int(), 0xFF)
  assert_eq(bytes[1].to_int(), 0xD8)
  let n = bytes.length()
  assert_eq(bytes[n - 2].to_int(), 0xFF)
  assert_eq(bytes[n - 1].to_int(), 0xD9)
}

///|
test "encode_jpeg_progressive: four scans (1 DC + 3 AC)" {
  let img = jpe_grad_image(32, 32)
  let bytes = @codec.encode_jpeg_progressive(img, 80)
  assert_eq(jpe_marker_count(bytes, 0xDA), 4)
}

///|
test "encode_jpeg_progressive: 64x64 roundtrip within tolerance" {
  let img = jpe_grad_image(64, 64)
  let bytes = @codec.encode_jpeg_progressive(img, 90)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 64)
  assert_eq(restored.height, 64)
  assert_eq(restored.channels, 3)
  let mean = jpe_mean_abs_diff(img.data, restored.data)
  assert_true(mean <= 4)
}

///|
test "encode_jpeg_progressive: 1x1 roundtrip" {
  let img = jpe_grad_image(1, 1)
  let bytes = @codec.encode_jpeg_progressive(img, 90)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 1)
  assert_eq(restored.height, 1)
}

///|
test "encode_jpeg_progressive: non-multiple-of-8 dimensions roundtrip" {
  let img = jpe_grad_image(17, 13)
  let bytes = @codec.encode_jpeg_progressive(img, 85)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 17)
  assert_eq(restored.height, 13)
  let mean = jpe_mean_abs_diff(img.data, restored.data)
  assert_true(mean <= 6)
}

///|
test "encode_jpeg_progressive: grayscale input roundtrip" {
  let data : Array[Byte] = []
  for _ in 0..<24 {
    for x in 0..<24 {
      data.push((x * 10 % 256).to_byte())
    }
  }
  let img : @types.Image = @types.Image::{
    width: 24,
    height: 24,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let bytes = @codec.encode_jpeg_progressive(img, 85)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 24)
  assert_eq(restored.height, 24)
  assert_eq(restored.channels, 3)
}

///|
test "encode_jpeg_progressive: above pixel budget raises" {
  // 只声明尺寸、不提供像素：上限检查发生在触碰 data 之前
  let img : @types.Image = @types.Image::{
    width: 2000,
    height: 2000,
    channels: 3,
    data: Bytes::from_array([]),
  }
  let raised = try {
    let _ = @codec.encode_jpeg_progressive(img, 80)
    false
  } catch {
    _ => true
  }
  assert_true(raised)
}

///|
test "encode_jpeg_progressive: size stays within 1.5x baseline on gradient" {
  let img = jpe_grad_image(128, 128)
  let baseline = @codec.encode_jpeg_with_quality(img, 80)
  let progressive = @codec.encode_jpeg_progressive(img, 80)
  // 最简 4 扫描形态没有 EOBRUN 合并与 successive approximation，体积通常略大于 baseline；
  // 这条只防"编码器失控"（例如逐块写 ZRL 或重复扫描），不作为压缩率承诺。
  assert_true(progressive.length() <= baseline.length() * 3 / 2)
}
