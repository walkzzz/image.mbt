///|
test "crc32 与 zlib.crc32 一致（回归：Int32 算术右移曾让 CRC 全错）" {
  let data : Bytes = b"123456789"
  // zlib.@util.crc32(b"123456789") = 0xCBF43926
  inspect(@util.crc32(data), content="-873187034") // 0xCBF43926 的有符号表示
}

///|
test "zlib_compress 可被自家 inflate 还原" {
  let raw : Array[Byte] = []
  for i in 0..<1000 {
    raw.push((i % 7).to_byte())
  }
  let src = Bytes::from_array(raw)
  let packed = zlib_compress(src)
  // 高度重复的数据必须明显小于原数据
  inspect(packed.length() < src.length() / 2, content="true")
  let back = @util.zlib_inflate(packed)
  inspect(back.length() == src.length(), content="true")
  let mut same = true
  for i in 0..<src.length() {
    if back[i] != src[i] {
      same = false
    }
  }
  inspect(same, content="true")
}

///|
test "zlib_compress 对随机数据保持可还原" {
  let raw : Array[Byte] = []
  let mut seed = 12345
  for _ in 0..<500 {
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    raw.push((seed % 256).to_byte())
  }
  let src = Bytes::from_array(raw)
  let back = @util.zlib_inflate(zlib_compress(src))
  inspect(back.length() == src.length(), content="true")
  let mut same = true
  for i in 0..<src.length() {
    if back[i] != src[i] {
      same = false
    }
  }
  inspect(same, content="true")
}
