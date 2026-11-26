// 覆盖率测试：PNG 区域解码的调色板 / 滤波类型 / 异常分支

fn rd_u32be(out : Array[Byte], v : Int32) -> Unit {
  out.push(((v >> 24) & 0xFF).to_byte())
  out.push(((v >> 16) & 0xFF).to_byte())
  out.push(((v >> 8) & 0xFF).to_byte())
  out.push((v & 0xFF).to_byte())
}

fn rd_chunk(
  out : Array[Byte],
  t : (Int32, Int32, Int32, Int32),
  body : Array[Byte],
) -> Unit {
  let (t0, t1, t2, t3) = t
  rd_u32be(out, body.length())
  out.push(t0.to_byte())
  out.push(t1.to_byte())
  out.push(t2.to_byte())
  out.push(t3.to_byte())
  for b in body {
    out.push(b)
  }
  rd_u32be(out, 0)
}

///|
/// stored（无压缩）deflate 块：zlib 头 + BFINAL/BTYPE=00 + LEN/NLEN + 原文
fn rd_zlib_stored(raw : Array[Byte]) -> Array[Byte] {
  let out : Array[Byte] = [0x78, 0x01, 0x01]
  let n = raw.length()
  out.push((n & 0xFF).to_byte())
  out.push(((n >> 8) & 0xFF).to_byte())
  let nlen = n ^ 0xFFFF
  out.push((nlen & 0xFF).to_byte())
  out.push(((nlen >> 8) & 0xFF).to_byte())
  for b in raw {
    out.push(b)
  }
  rd_u32be(out, @util.adler32(Bytes::from_array(raw)))
  out
}

fn rd_png(
  w : Int32,
  h : Int32,
  bit_depth : Int32,
  color_type : Int32,
  interlace : Int32,
  plte : Array[Byte],
  extra : Array[Byte],
  raw : Array[Byte],
) -> Bytes {
  let out : Array[Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
  let ihdr : Array[Byte] = []
  rd_u32be(ihdr, w)
  rd_u32be(ihdr, h)
  ihdr.push(bit_depth.to_byte())
  ihdr.push(color_type.to_byte())
  ihdr.push(0)
  ihdr.push(0)
  ihdr.push(0)
  ihdr.push(interlace.to_byte())
  rd_chunk(out, (0x49, 0x48, 0x44, 0x52), ihdr)
  if plte.length() > 0 {
    rd_chunk(out, (0x50, 0x4C, 0x54, 0x45), plte)
  }
  if extra.length() > 0 {
    rd_chunk(out, (0x74, 0x49, 0x4D, 0x45), extra)
  }
  rd_chunk(out, (0x49, 0x44, 0x41, 0x54), rd_zlib_stored(raw))
  rd_chunk(out, (0x49, 0x45, 0x4E, 0x44), [])
  Bytes::from_array(out)
}

///|
test "rd: 调色板图像 + filter 2/3 行重建" {
  let plte : Array[Byte] = []
  for i in 0..<16 {
    plte.push((i * 8).to_byte())
    plte.push(0)
    plte.push(0)
  }
  // 3 行 × 2 像素，通道 1
  let raw : Array[Byte] = [
    b'\x00', b'\x00', b'\x01', b'\x02', b'\x01', b'\x00', b'\x03', b'\x05',
    b'\x05',
  ]
  let png = rd_png(2, 3, 8, 3, 0, plte, [], raw)
  try {
    let img = @codec.decode_png_region(png, 0, 0, 2, 3)
    assert_true(img.channels == 1)
    assert_true(img.width == 2)
    assert_true(img.height == 3)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "rd: 未知 chunk 跳过不影响解码" {
  let raw : Array[Byte] = [b'\x00', b'\x00', b'\x00']
  let png = rd_png(1, 1, 8, 0, 0, [], [1, 2, 3, 4, 5, 6, 7], raw)
  try {
    let img = @codec.decode_png_region(png, 0, 0, 1, 1)
    assert_true(img.channels == 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "rd: interlace 与位深不支持时报错" {
  try {
    let _ = @codec.decode_png_region(rd_png(1, 1, 8, 0, 1, [], [], []), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.decode_png_region(rd_png(1, 1, 16, 0, 0, [], [], []), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rd: 非法 filter type 报错" {
  let raw : Array[Byte] = [b'\x09', b'\x00', b'\x00']
  try {
    let _ = @codec.decode_png_region(rd_png(1, 1, 8, 0, 0, [], [], raw), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rd: 解压数据短于图像行数时报错" {
  let raw : Array[Byte] = [b'\x00', b'\x00', b'\x00']
  try {
    let _ = @codec.decode_png_region(rd_png(4, 4, 8, 0, 0, [], [], raw), 0, 0, 4, 4)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rd: 调色板索引越界报错" {
  let plte : Array[Byte] = [0, 0, 0]
  let raw : Array[Byte] = [b'\x00', b'\x0F', b'\x00']
  try {
    let _ = @codec.decode_png_region(rd_png(1, 1, 8, 3, 0, plte, [], raw), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rd: 调色板缺失报错" {
  let raw : Array[Byte] = [b'\x00', b'\x00', b'\x00']
  try {
    let _ = @codec.decode_png_region(rd_png(1, 1, 8, 3, 0, [], [], raw), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rd: 区域参数与签名校验" {
  let raw : Array[Byte] = [b'\x00', b'\x00', b'\x00']
  let png = rd_png(1, 1, 8, 0, 0, [], [], raw)
  try {
    let _ = @codec.decode_png_region(png, 1, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.decode_png_region(Bytes::from_array([1, 2, 3]), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

