// 覆盖率测试：16-bit PNG 解码的调色板/滤波/位深/通道分支

fn p16_u32be(out : Array[Byte], v : Int32) -> Unit {
  out.push(((v >> 24) & 0xFF).to_byte())
  out.push(((v >> 16) & 0xFF).to_byte())
  out.push(((v >> 8) & 0xFF).to_byte())
  out.push((v & 0xFF).to_byte())
}

fn p16_chunk(
  out : Array[Byte],
  t : (Int32, Int32, Int32, Int32),
  body : Array[Byte],
) -> Unit {
  let (t0, t1, t2, t3) = t
  p16_u32be(out, body.length())
  out.push(t0.to_byte())
  out.push(t1.to_byte())
  out.push(t2.to_byte())
  out.push(t3.to_byte())
  for b in body {
    out.push(b)
  }
  p16_u32be(out, 0)
}

fn p16_zlib(raw : Array[Byte]) -> Array[Byte] {
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
  p16_u32be(out, @util.adler32(Bytes::from_array(raw)))
  out
}

fn p16_png(
  w : Int32,
  h : Int32,
  bit_depth : Int32,
  color_type : Int32,
  plte : Array[Byte],
  raw : Array[Byte],
) -> Bytes {
  let out : Array[Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
  let ihdr : Array[Byte] = []
  p16_u32be(ihdr, w)
  p16_u32be(ihdr, h)
  ihdr.push(bit_depth.to_byte())
  ihdr.push(color_type.to_byte())
  ihdr.push(0)
  ihdr.push(0)
  ihdr.push(0)
  ihdr.push(0)
  p16_chunk(out, (0x49, 0x48, 0x44, 0x52), ihdr)
  if plte.length() > 0 {
    p16_chunk(out, (0x50, 0x4C, 0x54, 0x45), plte)
  }
  p16_chunk(out, (0x49, 0x44, 0x41, 0x54), p16_zlib(raw))
  p16_chunk(out, (0x49, 0x45, 0x4E, 0x44), [])
  Bytes::from_array(out)
}

///|
test "p16: 16-bit 灰度原样上采样" {
  // 2×1 像素，16-bit BE：0x1234, 0x00FF
  let raw : Array[Byte] = [b'\x00', b'\x12', b'\x34', b'\x00', b'\xFF']
  let png = p16_png(2, 1, 16, 0, [], raw)
  try {
    let img = @codec.decode_png_16_pure(png)
    assert_true(img.width == 2)
    assert_true(img.height == 1)
    assert_true(img.channels == 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "p16: 调色板 chunk 解析 + filter 3" {
  let plte : Array[Byte] = [0, 0, 0, 128, 64, 32]
  let raw : Array[Byte] = [b'\x03', b'\x00', b'\x01']
  let png = p16_png(2, 1, 8, 3, plte, raw)
  try {
    let img = @codec.decode_png_16_pure(png)
    assert_true(img.channels == 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "p16: filter 4 与非法 filter" {
  // 2×2 灰度 8-bit，第二行用 filter 4
  let raw : Array[Byte] = [b'\x00', b'\x10', b'\x20', b'\x04', b'\x01', b'\x02']
  let png = p16_png(2, 2, 8, 0, [], raw)
  try {
    let img = @codec.decode_png_16_pure(png)
    assert_true(img.height == 2)
  } catch {
    _ => assert_true(false)
  }
  let bad : Array[Byte] = [b'\x09', b'\x10', b'\x20', b'\x00', b'\x01', b'\x02']
  try {
    let _ = @codec.decode_png_16_pure(p16_png(2, 2, 8, 0, [], bad))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "p16: 解压数据过短报错" {
  let raw : Array[Byte] = [b'\x00', b'\x10']
  try {
    let _ = @codec.decode_png_16_pure(p16_png(4, 4, 8, 0, [], raw))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "p16: 通道转换（GA/RGBA/指定输出通道）" {
  // GA 2×1
  let ga : Array[Byte] = [b'\x00', b'\x40', b'\x80', b'\x20', b'\x40']
  let png_ga = p16_png(2, 1, 8, 4, [], ga)
  try {
    let img = @codec.decode_png_16_pure(png_ga)
    assert_true(img.channels == 2)
  } catch {
    _ => assert_true(false)
  }
  // RGBA 1×1 输出 4 通道
  let rgba : Array[Byte] = [b'\x00', b'\x10', b'\x20', b'\x30', b'\x40']
  let png_rgba = p16_png(1, 1, 8, 6, [], rgba)
  try {
    let img = @codec.decode_png_16_pure(png_rgba, req_channels=Some(4))
    assert_true(img.channels == 4)
  } catch {
    _ => assert_true(false)
  }
  try {
    let img = @codec.decode_png_16_pure(png_rgba, req_channels=Some(1))
    assert_true(img.channels == 1)
  } catch {
    _ => assert_true(false)
  }
  try {
    let img = @codec.decode_png_16_pure(png_rgba, req_channels=Some(2))
    assert_true(img.channels == 2)
  } catch {
    _ => assert_true(false)
  }
}

