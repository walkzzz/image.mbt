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
test "encode_jpeg_progressive: EOBRUN merging beats baseline on gradient" {
  let img = jpe_grad_image(128, 128)
  let baseline = @codec.encode_jpeg_with_quality(img, 80)
  let progressive = @codec.encode_jpeg_progressive(img, 80)
  // AC 首扫带 EOBRUN 合并 + 按频次优化的 AC 霍夫曼表，体积应稳定小于 baseline；
  // 若哪天回退成逐块 EOB 或退回标准表，这条会立刻变红（渐变实测 2.3 KB vs 3.1 KB）。
  assert_true(progressive.length() < baseline.length())
}

///|
fn jpe_flat_image(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for _ in 0..<(width * height) {
    data.push(b'\x40')
    data.push(b'\x80')
    data.push(b'\xC0')
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
test "encode_jpeg_progressive: big flat image uses long EOBRUN and roundtrips" {
  // 512×512 纯色 → 每分量 64×64 = 4096 个全零 AC 块，必然触发 EOBRUN 上限（1023）多次 flush；
  // 这条锁住"上限 flush 后位流仍合法"（早期版本在此处把符号写成 nbits 而非 nbits << 4）。
  let img = jpe_flat_image(512, 512)
  let bytes = @codec.encode_jpeg_progressive(img, 90)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 512)
  assert_eq(restored.height, 512)
  let mean = jpe_mean_abs_diff(img.data, restored.data)
  assert_true(mean <= 2)
  // 纯色几乎没有 AC 数据，四条扫描合计只该占几百字节
  assert_true(bytes.length() < 4096)
}

///|
test "encode_jpeg_progressive: DHT tables are self-consistent (kraft + counts)" {
  // 黑盒校验：扫出 DHT 段，逐张表核对「码长总和 == 值个数」以及 Kraft 和 ≤ 1。
  // 这两条一旦破，解码端必报霍夫曼错误——自建频次表最容易在这里出问题。
  let img = jpe_flat_image(512, 512)
  let bytes = @codec.encode_jpeg_progressive(img, 90)
  let n = bytes.length()
  let mut i = 0
  let mut tables = 0
  while i < n - 1 {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == 0xC4 {
      let seg_len = bytes[i + 2].to_int() * 256 + bytes[i + 3].to_int()
      let end = i + 2 + seg_len
      let mut p = i + 4
      while p < end {
        // p: Tc/Th 字节；p+1..p+16: 16 个码长计数
        let mut total = 0
        let mut kraft = 0
        for l in 1..<=16 {
          let c = bytes[p + l].to_int()
          total += c
          kraft += c * (1 << (16 - l))
        }
        assert_true(kraft <= 65536)
        assert_true(p + 17 + total <= end)
        p += 17 + total
        tables += 1
      }
      i = end
    } else {
      i += 1
    }
  }
  assert_eq(tables, 4)
}
