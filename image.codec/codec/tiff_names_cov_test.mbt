// 覆盖率测试：TIFF 头部标签映射与缺失标签的默认值

fn tne_push_u16(out : Array[Byte], v : Int32) -> Unit {
  out.push((v & 0xFF).to_byte())
  out.push(((v >> 8) & 0xFF).to_byte())
}

fn tne_push_u32(out : Array[Byte], v : Int32) -> Unit {
  out.push((v & 0xFF).to_byte())
  out.push(((v >> 8) & 0xFF).to_byte())
  out.push(((v >> 16) & 0xFF).to_byte())
  out.push(((v >> 24) & 0xFF).to_byte())
}

///|
/// 构造最小 little-endian TIFF：IFD 位于偏移 8，每个条目为 SHORT(3) × count(1)
fn tne_tiff(pairs : Array[(Int32, Int32)]) -> Bytes {
  let out : Array[Byte] = [0x49, 0x49, 0x2A, 0x00]
  tne_push_u32(out, 8)
  tne_push_u16(out, pairs.length())
  for p in pairs {
    let (tag, value) = p
    tne_push_u16(out, tag)
    tne_push_u16(out, 3)
    tne_push_u32(out, 1)
    tne_push_u16(out, value)
    tne_push_u16(out, 0)
  }
  tne_push_u32(out, 0)
  Bytes::from_array(out)
}

fn tne_base() -> Array[(Int32, Int32)] {
  [(256, 4), (257, 3), (258, 8), (277, 3)]
}

///|
test "tne: 压缩方式名称全表" {
  let codes : Array[(Int32, String)] = [
    (1, "none"),
    (2, "CCITT"),
    (5, "LZW"),
    (6, "JPEG"),
    (7, "JPEG lossy"),
    (8, "Deflate"),
    (32773, "PackBits"),
    (32946, "Deflate (old)"),
    (99, "unknown"),
  ]
  for i in 0..<codes.length() {
    let (code, name) = codes[i]
    let data = tne_tiff([(256, 4), (257, 3), (259, code)])
    try {
      let info = @codec.tiff_info_extended(data)
      assert_true(info.compression_name.contains(name))
    } catch {
      _ => assert_true(false)
    }
  }
}

///|
test "tne: 光度解释名称全表" {
  let codes : Array[(Int32, String)] = [
    (0, "WhiteIsZero"),
    (1, "BlackIsZero"),
    (2, "RGB"),
    (3, "Palette"),
    (4, "TransparencyMask"),
    (5, "CMYK"),
    (6, "YCbCr"),
    (8, "CIELab"),
    (9, "unknown"),
  ]
  for i in 0..<codes.length() {
    let (code, name) = codes[i]
    let data = tne_tiff([(256, 4), (257, 3), (262, code)])
    try {
      let info = @codec.tiff_info_extended(data)
      assert_true(info.photometric_name.contains(name))
    } catch {
      _ => assert_true(false)
    }
  }
}

///|
test "tne: 缺省标签回落默认值" {
  let data = tne_tiff(tne_base())
  try {
    let info = @codec.tiff_info_extended(data)
    assert_true(info.compression == 1)
    assert_true(info.photometric == 1)
    assert_true(info.orientation == 1)
    assert_true(info.resolution_unit == 2)
    assert_true(info.width == 4)
    assert_true(info.height == 3)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "tne: 缺失宽度/高度报错" {
  try {
    let _ = @codec.tiff_info_extended(tne_tiff([(257, 3)]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.tiff_info_extended(tne_tiff([(256, 4)]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "tne: IFD 偏移越界与非法尺寸报错" {
  let out : Array[Byte] = [0x49, 0x49, 0x2A, 0x00]
  tne_push_u32(out, 4096)
  let bad = Bytes::from_array(out)
  try {
    let _ = @codec.tiff_info_extended(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.tiff_info_extended(tne_tiff([(256, 0), (257, 3)]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "tne: 非 TIFF 数据抛不支持的格式" {
  try {
    let _ = @codec.tiff_info_extended(Bytes::from_array([1, 2, 3]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

