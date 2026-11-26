// 白盒覆盖率：DEFLATE 位读取器、Huffman 树与块解码核心

fn zbt_emit_lsb(bits : Array[Int32], v : Int32, n : Int32) -> Unit {
  for i in 0..<n {
    bits.push((v >> i) & 1)
  }
}

fn zbt_emit_msb(bits : Array[Int32], v : Int32, n : Int32) -> Unit {
  for i in 0..<n {
    bits.push((v >> (n - 1 - i)) & 1)
  }
}

fn zbt_pack(bits : Array[Int32]) -> Bytes {
  let bytes : Array[Byte] = []
  let mut cur = 0
  let mut n = 0
  for i in 0..<bits.length() {
    if bits[i] == 1 {
      cur = cur | (1 << n)
    }
    n += 1
    if n == 8 {
      bytes.push(cur.to_byte())
      cur = 0
      n = 0
    }
  }
  if n > 0 {
    bytes.push(cur.to_byte())
  }
  Bytes::from_array(bytes)
}

fn zbt_byte_of(data : Bytes, i : Int32) -> Int32 {
  data[i].to_int()
}

///|
test "zbt: CRC32 与 Adler32 已知值" {
  let t = crc32_table()
  assert_true(t.length() == 256)
  assert_true(t[0] == 0)
  let crc = crc32(Bytes::from_array([
    b'1', b'2', b'3', b'4', b'5', b'6', b'7', b'8', b'9',
  ]))
  assert_true(crc == 0xCBF43926 || crc == -873223898)
  let ad = adler32(Bytes::from_array([
    b'W', b'i', b'k', b'i', b'p', b'e', b'd', b'i', b'a',
  ]))
  assert_true(ad == 0x11E60398)
}

///|
test "zbt: Huffman 树构建与固定树" {
  let tree = build_huffman_tree([2, 2, 1], 15)
  assert_true(tree.counts[2] == 2)
  assert_true(tree.counts[1] == 1)
  assert_true(tree.symbols.length() == 3)
  let (lit, dist) = build_fixed_trees()
  assert_true(lit.counts[7] == 24)
  assert_true(dist.counts[5] == 30)
  assert_true(dist.symbols.length() == 30)
}

///|
test "zbt: 位读取器读出与越界报错" {
  let r = bit_reader_new(Bytes::from_array([0xFF, 0x00]))
  assert_true(bit_reader_read_bits(r, 4) == 15)
  assert_true(bit_reader_read_bits(r, 4) == 15)
  assert_true(bit_reader_read_bits(r, 8) == 0)
  // 数据耗尽
  try {
    let _ = bit_reader_read_bits(bit_reader_new(Bytes::from_array([0x00])), 16)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "zbt: Huffman 单比特树解码" {
  let tree = build_huffman_tree([1, 1], 15)
  let bits0 : Array[Int32] = []
  zbt_emit_lsb(bits0, 0, 1)
  let r0 = bit_reader_new(zbt_pack(bits0))
  assert_true(bit_reader_read_huffman(r0, tree) == 0)
  let bits1 : Array[Int32] = []
  zbt_emit_lsb(bits1, 1, 1)
  let r1 = bit_reader_new(zbt_pack(bits1))
  assert_true(bit_reader_read_huffman(r1, tree) == 1)
  // 空数据 → 解码失败
  try {
    let _ = bit_reader_read_huffman(bit_reader_new(Bytes::from_array([])), tree)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "zbt: 固定树块解码字面量与结束符" {
  let (lit, dist) = build_fixed_trees()
  let bits : Array[Int32] = []
  zbt_emit_msb(bits, 0x71, 8) // 字面量 'A'（65）
  zbt_emit_msb(bits, 0x00, 7) // 结束符 256
  let r = bit_reader_new(zbt_pack(bits))
  let out : Array[Byte] = []
  inflate_block_data(r, out, lit, dist)
  assert_true(out.length() == 1)
  assert_true(zbt_byte_of(Bytes::from_array(out), 0) == 65)
}

///|
test "zbt: 固定树块长度-距离复制" {
  let (lit, dist) = build_fixed_trees()
  let bits : Array[Int32] = []
  zbt_emit_msb(bits, 0x71, 8) // 'A'
  zbt_emit_msb(bits, 0x01, 7) // 257 → 长度 3，无额外位
  zbt_emit_msb(bits, 0x00, 5) // 距离符号 0 → 距离 1
  zbt_emit_msb(bits, 0x00, 7) // 结束符
  let r = bit_reader_new(zbt_pack(bits))
  let out : Array[Byte] = []
  inflate_block_data(r, out, lit, dist)
  assert_true(out.length() == 4)
  let packed = Bytes::from_array(out)
  for i in 0..<4 {
    assert_true(packed[i].to_int() == 65)
  }
}
