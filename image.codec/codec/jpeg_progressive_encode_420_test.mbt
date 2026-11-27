// progressive JPEG · 4:2:0（`encode_jpeg_progressive_420`）测试
// 覆盖：SOF2 采样因子、8 条扫描参数、与 4:4:4 的体积对比、非 16 倍数尺寸往返、边界尺寸

///|
fn jpr420_marker_count(bytes : Bytes, marker : Int32) -> Int32 {
  let n = bytes.length()
  let mut count = 0
  for i in 0..<(n - 1) {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == marker {
      count += 1
    }
  }
  count
}

///|
fn jpr420_grad(width : Int32, height : Int32) -> @types.Image {
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
fn jpr420_mean_abs_diff(a : Bytes, b : Bytes) -> Int32 {
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
test "encode_jpeg_progressive_420: SOF2 carries Y 2x2 and 1x1 chroma sampling" {
  let img = jpr420_grad(32, 32)
  let bytes = @codec.encode_jpeg_progressive_420(img, 80)
  assert_eq(jpr420_marker_count(bytes, 0xC2), 1)
  assert_eq(jpr420_marker_count(bytes, 0xC0), 0)
  // SOF2 分量表：每分量 3 字节（id, 采样, 量化表号）
  let n = bytes.length()
  let mut i = 0
  let mut found = false
  while i < n - 1 {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == 0xC2 {
      let p = i + 4
      assert_eq(bytes[p + 5].to_int(), 3)
      let c1 = p + 6
      assert_eq(bytes[c1].to_int(), 1)
      assert_eq(bytes[c1 + 1].to_int(), 0x22)
      assert_eq(bytes[c1 + 2].to_int(), 0)
      assert_eq(bytes[c1 + 3].to_int(), 2)
      assert_eq(bytes[c1 + 4].to_int(), 0x11)
      assert_eq(bytes[c1 + 5].to_int(), 1)
      assert_eq(bytes[c1 + 6].to_int(), 3)
      assert_eq(bytes[c1 + 7].to_int(), 0x11)
      assert_eq(bytes[c1 + 8].to_int(), 1)
      found = true
      break
    }
    i += 1
  }
  assert_true(found)
}

///|
test "encode_jpeg_progressive_420: eight scans with expected parameters" {
  let img = jpr420_grad(48, 32)
  let bytes = @codec.encode_jpeg_progressive_420(img, 75)
  assert_eq(jpr420_marker_count(bytes, 0xDA), 8)
  let expect : Array[(Int32, Int32, Int32, Int32)] = [
    (0, 0, 0, 1),
    (1, 63, 0, 1),
    (1, 63, 0, 1),
    (1, 63, 0, 1),
    (0, 0, 1, 0),
    (1, 63, 1, 0),
    (1, 63, 1, 0),
    (1, 63, 1, 0),
  ]
  let n = bytes.length()
  let mut i = 0
  let mut idx = 0
  while i < n - 1 {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == 0xDA {
      let seg_len = bytes[i + 2].to_int() * 256 + bytes[i + 3].to_int()
      let ns = bytes[i + 4].to_int()
      let p = i + 5 + ns * 2
      assert_eq(bytes[p].to_int(), expect[idx].0)
      assert_eq(bytes[p + 1].to_int(), expect[idx].1)
      assert_eq(bytes[p + 2].to_int(), (expect[idx].2 << 4) | expect[idx].3)
      idx += 1
      i = i + 2 + seg_len
    } else {
      i += 1
    }
  }
  assert_eq(idx, 8)
}

///|
test "encode_jpeg_progressive_420: smaller than 4:4:4 and roundtrips" {
  // 色度平面块数 1/4：渐变图的色度几乎全是低频，体积应明显小于同质量 4:4:4
  let img = jpr420_grad(96, 96)
  let b420 = @codec.encode_jpeg_progressive_420(img, 80)
  let b444 = @codec.encode_jpeg_progressive(img, 80)
  assert_true(b420.length() < b444.length())
  let restored = @codec.decode_jpeg_pure(b420)
  assert_eq(restored.width, 96)
  assert_eq(restored.height, 96)
  assert_eq(restored.channels, 3)
  // 4:2:0 有损于色度细节，渐变图仍应贴近原图
  let mean = jpr420_mean_abs_diff(img.data, restored.data)
  assert_true(mean <= 6)
}

///|
test "encode_jpeg_progressive_420: non-multiple-of-16 dimensions roundtrip" {
  // 137×93：Y 平面有 padding 列/行，单分量 AC 扫描不能写 padding 块
  let img = jpr420_grad(137, 93)
  let bytes = @codec.encode_jpeg_progressive_420(img, 85)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 137)
  assert_eq(restored.height, 93)
  let mean = jpr420_mean_abs_diff(img.data, restored.data)
  assert_true(mean <= 6)
}

///|
test "encode_jpeg_progressive_420: tiny and odd sizes do not fail" {
  for (w, h) in [(1, 1), (2, 3), (9, 17), (17, 9)] {
    let img = jpr420_grad(w, h)
    let bytes = @codec.encode_jpeg_progressive_420(img, 90)
    let restored = @codec.decode_jpeg_pure(bytes)
    assert_eq(restored.width, w)
    assert_eq(restored.height, h)
  }
}
