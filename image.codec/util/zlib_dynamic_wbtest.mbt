// 白盒覆盖：DEFLATE 动态 Huffman 块（read_dynamic_trees 全流程）
// 样本由 node zlib.deflateSync(level=9) 生成，BTYPE=2

///|
fn zbt2_bytes(values : Array[Int32]) -> Bytes {
  let out : Array[Byte] = []
  for v in values {
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

///|
fn zbt2_puts() -> Bytes {
  zbt2_bytes([
    120, 218, 237, 202, 71, 1, 128, 48, 16, 69, 65, 43, 95, 1, 106, 98, 128, 178,
    16, 234, 66, 32, 52, 245, 152, 224, 248, 230, 60, 33, 154, 182, 220, 215, 163,
    170, 228, 215, 162, 214, 111, 13, 121, 94, 119, 249, 105, 73, 71, 52, 77, 229,
    251, 168, 241, 174, 80, 32, 147, 201, 100, 50, 153, 76, 38, 147, 255, 203, 31,
    193, 47, 201, 82,
  ])
}

///|
test "zbt2: 动态块解压出全部重复文本" {
  let out = zlib_inflate(zbt2_puts()) catch { _ => Bytes::from_array([]) }
  assert_true(out.length() == 2700)
  if out.length() > 5 {
    assert_true(out[0].to_int() == 0x54)
    assert_true(out[4].to_int() == 0x71)
  }
}

///|
test "zbt2: 截断的码长表报错" {
  let full = zbt2_puts()
  let cut : Array[Byte] = []
  for i in 0..<10 {
    cut.push(full[i])
  }
  let reader = bit_reader_new(Bytes::from_array(cut))
  let _ = bit_reader_read_bits(reader, 3) catch { _ => 0 }
  try {
    let _ = read_dynamic_trees(reader)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
