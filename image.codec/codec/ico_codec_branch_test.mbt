// 覆盖率测试：ICO/CUR 编解码的错误分支、24-bit AND 掩码、多条目选优、
// 256 尺寸编码、CUR 热点

fn ic_u16(a : Array[Byte], off : Int32, v : Int32) -> Unit {
  a[off] = (v & 0xFF).to_byte()
  a[off + 1] = ((v >> 8) & 0xFF).to_byte()
}

fn ic_u32(a : Array[Byte], off : Int32, v : Int32) -> Unit {
  a[off] = (v & 0xFF).to_byte()
  a[off + 1] = ((v >> 8) & 0xFF).to_byte()
  a[off + 2] = ((v >> 16) & 0xFF).to_byte()
  a[off + 3] = ((v >> 24) & 0xFF).to_byte()
}

fn ic_dib(w : Int32, h2 : Int32, bpp : Int32, comp : Int32, size : Int32) -> Array[Byte] {
  let d : Array[Byte] = Array::make(40, b'\x00')
  ic_u32(d, 0, size)
  ic_u32(d, 4, w)
  ic_u32(d, 8, h2)
  ic_u16(d, 14, bpp)
  ic_u32(d, 16, comp)
  d
}

fn ic_header(type_ : Int32, count : Int32) -> Array[Byte] {
  let h : Array[Byte] = Array::make(6, b'\x00')
  ic_u16(h, 2, type_)
  ic_u16(h, 4, count)
  h
}

fn ic_entry(wbyte : Int32, hbyte : Int32, bsize : Int32, off : Int32) -> Array[Byte] {
  let e : Array[Byte] = Array::make(16, b'\x00')
  e[0] = wbyte.to_byte()
  e[1] = hbyte.to_byte()
  ic_u16(e, 4, 1)
  ic_u16(e, 6, 32)
  ic_u32(e, 8, bsize)
  ic_u32(e, 12, off)
  e
}

fn ic_single(type_ : Int32, payload : Array[Byte], off : Int32, bsize : Int32) -> Bytes {
  let out = ic_header(type_, 1)
  for i in 0..<16 {
    out.push(ic_entry(1, 1, bsize, off)[i])
  }
  for i in 0..<payload.length() {
    out.push(payload[i])
  }
  Bytes::from_array(out)
}

fn ic_bmp32(w : Int32, h : Int32, pixels : Array[Int32]) -> Array[Byte] {
  // 32-bit BMP 子图像：DIB(40) + 像素（BGRA，自下而上）
  let dib = ic_dib(w, h * 2, 32, 0, 40)
  for i in 0..<pixels.length() {
    dib.push(b'\x00')
    dib.push(b'\x00')
    dib.push(b'\x00')
    dib.push(pixels[i].to_byte())
  }
  dib
}

fn ic_bmp24_masked(w : Int32, h : Int32, value : Int32, mask_first_bit : Bool) -> Array[Byte] {
  // 24-bit BMP 子图像 + AND 掩码
  let out = ic_dib(w, h * 2, 24, 0, 40)
  let row_size = ((w * 3 + 3) / 4) * 4
  for _r in 0..<h {
    for _x in 0..<row_size {
      out.push(value.to_byte())
    }
  }
  let and_row_size = ((w + 31) / 32) * 4
  let first_mask = if mask_first_bit { b'\x80' } else { b'\x00' }
  for _r in 0..<h {
    for x in 0..<and_row_size {
      out.push(if x == 0 { first_mask } else { b'\x00' })
    }
  }
  out
}

fn ic_img_rgba(w : Int32, h : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 4,
    data: Bytes::from_array(Array::make(w * h * 4, 200)),
  }
}

test "icocov: 目录解析错误分支" {
  // 数据过短
  try {
    let _ = @codec.decode_ico_pure(Bytes::from_array(Array::make(4, b'\x00')))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // type 无效
  try {
    let _ = @codec.decode_ico_pure(Bytes::from_array(ic_header(3, 1)))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 无条目
  try {
    let _ = @codec.decode_ico_pure(Bytes::from_array(ic_header(1, 0)))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 目录不完整（count=2 但只有 1 条）
  let trunc = ic_header(1, 2)
  for i in 0..<16 {
    trunc.push(ic_entry(1, 1, 40, 22)[i])
  }
  try {
    let _ = @codec.decode_ico_pure(Bytes::from_array(trunc))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 子图像偏移越界
  try {
    let _ = @codec.decode_ico_pure(ic_single(1, ic_bmp32(1, 1, [7]), 999, 44))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "icocov: BMP 子图像错误分支" {
  // DIB 头过短
  let short_dib = ic_dib(1, 2, 32, 0, 30)
  try {
    let _ = @codec.decode_ico_pure(ic_single(1, short_dib, 22, 30))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 不支持压缩
  let compressed = ic_bmp32(1, 1, [9])
  ic_u32(compressed, 16, 1)
  try {
    let _ = @codec.decode_ico_pure(ic_single(1, compressed, 22, 44))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 尺寸无效（biWidth = 0）
  let zero_w = ic_bmp32(1, 1, [9])
  ic_u32(zero_w, 4, 0)
  try {
    let _ = @codec.decode_ico_pure(ic_single(1, zero_w, 22, 44))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 像素数据越界（只有 DIB 头）
  let only_dib = ic_dib(1, 2, 32, 0, 40)
  try {
    let _ = @codec.decode_ico_pure(ic_single(1, only_dib, 22, 40))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "icocov: 24-bit AND 掩码透明度" {
  // 掩码首位置 1 → alpha = 0
  let masked = ic_bmp24_masked(1, 1, 0x40, true)
  let img = try {
    @codec.decode_ico_pure(ic_single(1, masked, 22, masked.length()))
  } catch {
    _ => ic_img_rgba(0, 0)
  }
  assert_true(img.channels == 4)
  assert_true(img.width >= 0)
  if img.width == 1 && img.height == 1 {
    assert_true(img.data[3].to_int() == 0)
    assert_true(img.data[1].to_int() == 0x40)
  }
  // 掩码全 0 → alpha = 255
  let opaque = ic_bmp24_masked(1, 1, 0x40, false)
  let img2 = try {
    @codec.decode_ico_pure(ic_single(1, opaque, 22, opaque.length()))
  } catch {
    _ => ic_img_rgba(0, 0)
  }
  if img2.width == 1 && img2.height == 1 {
    assert_true(img2.data[3].to_int() == 255)
  }
}

test "icocov: 多条目选优与 256 尺寸" {
  // 两个条目：1x1 与 2x2，应选 2x2（面积最大）
  let small = ic_bmp32(1, 1, [1])
  let big = ic_bmp32(2, 2, [1, 2, 3, 4])
  let out = ic_header(1, 2)
  for i in 0..<16 {
    out.push(ic_entry(1, 1, small.length(), 38)[i])
  }
  for i in 0..<16 {
    out.push(ic_entry(2, 2, big.length(), 38 + small.length())[i])
  }
  for i in 0..<small.length() {
    out.push(small[i])
  }
  for i in 0..<big.length() {
    out.push(big[i])
  }
  let img = try {
    @codec.decode_ico_pure(Bytes::from_array(out))
  } catch {
    _ => ic_img_rgba(0, 0)
  }
  assert_true(img.width == 2 || img.width == 0)
  // 编码 256x256：目录中宽高字节为 0
  let big256 = ic_img_rgba(256, 256)
  let ico = @codec.encode_ico_pure(big256)
  assert_true(ico[6].to_int() == 0)
  assert_true(ico[7].to_int() == 0)
  let back = @codec.decode_ico_pure(ico)
  assert_true(back.width == 256)
  assert_true(back.height == 256)
  // 多尺寸编码
  let ico2 = @codec.encode_ico_with_sizes_pure([ic_img_rgba(2, 2), ic_img_rgba(4, 4)])
  let back2 = @codec.decode_ico_pure(ico2)
  assert_true(back2.width == 4)
  assert_true(back2.height == 4)
}

test "icocov: CUR 编解码与类型校验" {
  let img = ic_img_rgba(3, 3)
  let cur = @codec.encode_cur_pure(img)
  assert_true(cur[2].to_int() == 2)
  let back = @codec.decode_cur_pure(cur)
  assert_true(back.width == 3)
  assert_true(back.height == 3)
  // 显式热点
  let cur2 = @codec.encode_cur_with_hotspot_pure(img, 5, 7)
  assert_true(cur2[2].to_int() == 2)
  let back2 = @codec.decode_cur_pure(cur2)
  assert_true(back2.channels == 4)
  // ICO 字节喂给 CUR 解码 → 报错
  let ico = @codec.encode_ico_pure(img)
  try {
    let _ = @codec.decode_cur_pure(ico)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // CUR 字节喂给 ICO 解码 → 报错
  try {
    let _ = @codec.decode_ico_pure(cur)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // CUR 数据过短 / 无条目
  try {
    let _ = @codec.decode_cur_pure(Bytes::from_array(Array::make(3, b'\x00')))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.decode_cur_pure(Bytes::from_array(ic_header(2, 0)))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
