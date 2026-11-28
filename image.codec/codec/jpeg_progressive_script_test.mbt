// progressive 扫描脚本（`encode_jpeg_progressive_420_scripted`）测试
// 覆盖：libjpeg 10 段脚本的 SOS 参数逐条核对、与固定 8 段解码结果逐字节一致、非 16 倍数尺寸

///|
fn jps_grad(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      data.push(((x * 5 + y * 3) % 256).to_byte())
      data.push(((y * 4 + 40) % 256).to_byte())
      data.push(((x * 2 + 120) % 256).to_byte())
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
fn jps_scan_params(bytes : Bytes) -> Array[(Int32, Int32, Int32, Int32, Int32)] {
  let res : Array[(Int32, Int32, Int32, Int32, Int32)] = []
  let n = bytes.length()
  let mut i = 0
  while i < n - 1 {
    if bytes[i].to_int() == 0xFF && bytes[i + 1].to_int() == 0xDA {
      let seg_len = bytes[i + 2].to_int() * 256 + bytes[i + 3].to_int()
      let ns = bytes[i + 4].to_int()
      let p = i + 5 + ns * 2
      let ss = bytes[p].to_int()
      let se = bytes[p + 1].to_int()
      let ahal = bytes[p + 2].to_int()
      res.push((ns, ss, se, ahal >> 4, ahal & 0x0F))
      i = i + 2 + seg_len
    } else {
      i += 1
    }
  }
  res
}

///|
test "progressive script: libjpeg 10-scan script emits expected SOS parameters" {
  let img = jps_grad(48, 32)
  let bytes = @codec.encode_jpeg_progressive_420_scripted(
    img,
    75,
    @codec.jpeg_progressive_script_libjpeg(),
  )
  let scans = jps_scan_params(bytes)
  assert_eq(scans.length(), 10)
  // (ns, Ss, Se, Ah, Al)
  let expect : Array[(Int32, Int32, Int32, Int32, Int32)] = [
    (3, 0, 0, 0, 1),
    (1, 1, 5, 0, 2),
    (1, 1, 63, 0, 1),
    (1, 1, 63, 0, 1),
    (1, 6, 63, 0, 2),
    (3, 0, 0, 1, 0),
    (1, 1, 63, 2, 1),
    (1, 1, 63, 1, 0),
    (1, 1, 63, 1, 0),
    (1, 1, 63, 1, 0),
  ]
  for idx in 0..<10 {
    assert_eq(scans[idx].0, expect[idx].0)
    assert_eq(scans[idx].1, expect[idx].1)
    assert_eq(scans[idx].2, expect[idx].2)
    assert_eq(scans[idx].3, expect[idx].3)
    assert_eq(scans[idx].4, expect[idx].4)
  }
}

///|
test "progressive script: 10-scan output decodes to the same pixels as 8-scan" {
  // 两种脚本量化系数完全相同，差异只在扫描组织 → 解码像素必须逐字节一致
  let img = jps_grad(64, 48)
  let s8 = @codec.encode_jpeg_progressive_420_scripted(
    img,
    80,
    @codec.jpeg_progressive_script_eight(),
  )
  let s10 = @codec.encode_jpeg_progressive_420_scripted(
    img,
    80,
    @codec.jpeg_progressive_script_libjpeg(),
  )
  let d8 = @codec.decode_jpeg_pure(s8)
  let d10 = @codec.decode_jpeg_pure(s10)
  assert_eq(d10.width, 64)
  assert_eq(d10.height, 48)
  assert_eq(d10.data.length(), d8.data.length())
  let mut diffs = 0
  for i in 0..<d8.data.length() {
    if d8.data[i].to_int() != d10.data[i].to_int() {
      diffs += 1
    }
  }
  assert_eq(diffs, 0)
}

///|
test "progressive script: 10-scan overhead stays small versus 8-scan" {
  // 10 段把色度拆成两条扫描并多两级细化，熵编码本身更省，
  // 但每扫描要各带一张 DHT、EOBRUN 也各扫描重置一次；
  // 小图上段头开销占比重，故用相对上界而不是「不大于」来做回归护栏。
  let img = jps_grad(96, 72)
  let s8 = @codec.encode_jpeg_progressive_420_scripted(
    img,
    70,
    @codec.jpeg_progressive_script_eight(),
  )
  let s10 = @codec.encode_jpeg_progressive_420_scripted(
    img,
    70,
    @codec.jpeg_progressive_script_libjpeg(),
  )
  assert_true(s10.length() <= s8.length() * 115 / 100)
}

///|
test "progressive script: non-multiple-of-16 dimensions roundtrip" {
  let img = jps_grad(137, 93)
  let bytes = @codec.encode_jpeg_progressive_420_scripted(
    img,
    85,
    @codec.jpeg_progressive_script_libjpeg(),
  )
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 137)
  assert_eq(restored.height, 93)
  assert_eq(restored.channels, 3)
}

///|
test "progressive script: DC-only script produces a decodable low-frequency preview" {
  let img = jps_grad(40, 24)
  let script : Array[@codec.JpegProgScan] = [
    @codec.JpegProgScan::{ comps: [0, 1, 2], ss: 0, se: 0, ah: 0, al: 0, },
  ]
  let bytes = @codec.encode_jpeg_progressive_420_scripted(img, 90, script)
  let restored = @codec.decode_jpeg_pure(bytes)
  assert_eq(restored.width, 40)
  assert_eq(restored.height, 24)
}
