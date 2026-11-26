// 纯逻辑测试（全目标可用）
// 目标：region_decode 的全部错误分支（畸形 PNG chunk / BMP 头 / QOI 码流）与灰度/GA 通道映射

///|
fn rde_be32(v : Int32) -> Array[Byte] {
  [
    ((v >> 24) & 0xFF).to_byte(),
    ((v >> 16) & 0xFF).to_byte(),
    ((v >> 8) & 0xFF).to_byte(),
    (v & 0xFF).to_byte(),
  ]
}

///|
fn rde_cat(parts : Array[Array[Byte]]) -> Bytes {
  let out : Array[Byte] = []
  for p in parts {
    for b in p {
      out.push(b)
    }
  }
  Bytes::from_array(out)
}

///|
fn rde_png_sig() -> Array[Byte] {
  [b'\x89', b'\x50', b'\x4E', b'\x47', b'\x0D', b'\x0A', b'\x1A', b'\x0A']
}

///|
fn rde_chunk(tag : String, payload : Array[Byte]) -> Array[Byte] {
  let out : Array[Byte] = []
  for b in rde_be32(payload.length()) {
    out.push(b)
  }
  for i in 0..<4 {
    out.push(tag[i].to_int().to_byte())
  }
  for b in payload {
    out.push(b)
  }
  // CRC 不参与校验，填 0
  for _ in 0..<4 {
    out.push(b'\x00')
  }
  out
}

///|
fn rde_ihdr(
  w : Int32,
  h : Int32,
  depth : Int32,
  ctype : Int32,
  interlace : Int32,
) -> Array[Byte] {
  let p : Array[Byte] = []
  for b in rde_be32(w) {
    p.push(b)
  }
  for b in rde_be32(h) {
    p.push(b)
  }
  p.push(depth.to_byte())
  p.push(ctype.to_byte())
  for _ in 0..<3 {
    p.push(b'\x00')
  }
  p.push(interlace.to_byte())
  rde_chunk("IHDR", p)
}

///|
fn rde_png_1x1() -> Bytes {
  @codec.encode_png_pure(@types.Image::{
    width: 1,
    height: 1,
    channels: 3,
    data: Bytes::from_array([b'\x10', b'\x20', b'\x30']),
  })
}

///|
fn rde_patch(bytes : Bytes, offset : Int32, values : Array[Byte]) -> Bytes {
  let arr : Array[Byte] = []
  for b in bytes {
    arr.push(b)
  }
  for i in 0..<values.length() {
    arr[offset + i] = values[i]
  }
  Bytes::from_array(arr)
}

///|
fn rde_bmp_2x2() -> Bytes {
  let img = @types.Image::{
    width: 2,
    height: 2,
    channels: 3,
    data: Bytes::from_array([
      b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06', b'\x07', b'\x08', b'\x09',
      b'\x0A', b'\x0B', b'\x0C',
    ]),
  }
  @codec.encode_bmp_pure(img)
}

///|
fn rde_qoi_header(w : Int32, h : Int32, channels : Int32) -> Array[Byte] {
  let out : Array[Byte] = [b'\x71', b'\x6F', b'\x69', b'\x66']
  for b in rde_be32(w) {
    out.push(b)
  }
  for b in rde_be32(h) {
    out.push(b)
  }
  out.push(channels.to_byte())
  out.push(b'\x00')
  out
}

///|
test "region_decode: PNG 头部错误分支" {
  let mut hits = 0
  // 签名错误
  try {
    let _ = @codec.decode_png_region(rde_cat([[b'\x00', b'\x01']]), 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // chunk 头不足 8 字节
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), [b'\x00', b'\x00', b'\x00', b'\x00']]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // chunk 长度为负（高位为 1）
  try {
    let _ = @codec.decode_png_region(
      rde_cat([
        rde_png_sig(),
        [b'\x80', b'\x00', b'\x00', b'\x00', b'\x49', b'\x48', b'\x44', b'\x52'],
      ]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // chunk 数据越界（声明 100 字节但只有 0 字节）
  try {
    let _ = @codec.decode_png_region(
      rde_cat([
        rde_png_sig(),
        [b'\x00', b'\x00', b'\x00', b'\x64', b'\x49', b'\x44', b'\x41', b'\x54'],
      ]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // IHDR 过短
  try {
    let bad_ihdr = rde_chunk("IHDR", [b'\x00', b'\x00'])
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), bad_ihdr]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // 无 IHDR
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // 尺寸为 0
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_ihdr(0, 1, 8, 2, 0), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // interlace 非 0
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_ihdr(2, 2, 8, 2, 1), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // bit depth 非 8
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_ihdr(2, 2, 16, 2, 0), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // 非法 color type
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_ihdr(2, 2, 8, 7, 0), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // palette 型缺 PLTE
  try {
    let _ = @codec.decode_png_region(
      rde_cat([rde_png_sig(), rde_ihdr(2, 2, 8, 3, 0), rde_chunk("IEND", [])]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // 解压数据过短：把 1×1 的 IHDR 宽改成 2，zlib 流仍只够 3 字节像素
  try {
    let patched = rde_patch(rde_png_1x1(), 16, [
      b'\x00', b'\x00', b'\x00', b'\x02',
    ])
    let _ = @codec.decode_png_region(patched, 0, 0, 2, 1)
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 12)
}

///|
test "region_decode: PNG 灰度 / GA 通道映射与整图裁切一致" {
  let gray = @codec.encode_png_pure(@types.Image::{
    width: 4,
    height: 3,
    channels: 1,
    data: Bytes::from_array([
      b'\x00', b'\x11', b'\x22', b'\x33', b'\x44', b'\x55', b'\x66', b'\x77', b'\x88',
      b'\x99', b'\xAA', b'\xBB',
    ]),
  })
  let full = @codec.decode_png_pure(gray)
  assert_eq(full.channels, 1)
  let tile = @codec.decode_png_region(gray, 2, 1, 2, 2)
  assert_eq(tile.channels, 1)
  assert_eq(tile.width, 2)
  assert_eq(tile.height, 2)
  // 与整图裁切逐字节比较（灰度）
  for r in 0..<2 {
    for c in 0..<2 {
      assert_eq(tile.data[r * 2 + c], full.data[(r + 1) * 4 + (c + 2)])
    }
  }
  let ga = @codec.encode_png_pure(@types.Image::{
    width: 3,
    height: 2,
    channels: 2,
    data: Bytes::from_array([
      b'\x10', b'\x80', b'\x20', b'\x90', b'\x30', b'\xA0', b'\x40', b'\xB0', b'\x50',
      b'\xC0', b'\x60', b'\xD0',
    ]),
  })
  let gaf = @codec.decode_png_pure(ga)
  assert_eq(gaf.channels, 2)
  let gat = @codec.decode_png_region(ga, 1, 0, 2, 2)
  assert_eq(gat.channels, 2)
  for r in 0..<2 {
    for c in 0..<2 {
      assert_eq(gat.data[(r * 2 + c) * 2], gaf.data[(r * 3 + c + 1) * 2])
      assert_eq(
        gat.data[(r * 2 + c) * 2 + 1],
        gaf.data[(r * 3 + c + 1) * 2 + 1],
      )
    }
  }
}

///|
test "region_decode: BMP 头部错误分支" {
  let mut hits = 0
  // 数据过短
  try {
    let _ = @codec.decode_bmp_region(rde_cat([[b'\x42', b'\x4D']]), 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // magic 不匹配
  try {
    let bad = rde_patch(rde_bmp_2x2(), 0, [b'\x58', b'\x59'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // DIB 头大小非 40
  try {
    let bad = rde_patch(rde_bmp_2x2(), 14, [b'\x0C', b'\x00', b'\x00', b'\x00'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // 位深非 24/32
  try {
    let bad = rde_patch(rde_bmp_2x2(), 28, [b'\x08', b'\x00'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // 压缩方式非 BI_RGB
  try {
    let bad = rde_patch(rde_bmp_2x2(), 30, [b'\x01', b'\x00', b'\x00', b'\x00'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // 宽度为 0
  try {
    let bad = rde_patch(rde_bmp_2x2(), 18, [b'\x00', b'\x00', b'\x00', b'\x00'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // 像素偏移超出数据长度
  try {
    let bad = rde_patch(rde_bmp_2x2(), 10, [b'\xFF', b'\xFF', b'\xFF', b'\x00'])
    let _ = @codec.decode_bmp_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 7)
}

///|
test "region_decode: BMP 自顶向下（负高度）" {
  let bmp = rde_bmp_2x2()
  // 高度改成 -2（0xFFFFFFFE），行序变为自顶向下
  let topdown = rde_patch(bmp, 22, [b'\xFE', b'\xFF', b'\xFF', b'\xFF'])
  let img = @codec.decode_bmp_region(topdown, 0, 0, 2, 2)
  assert_eq(img.width, 2)
  assert_eq(img.height, 2)
  assert_eq(img.channels, 3)
}

///|
test "region_decode: QOI 错误分支" {
  let mut hits = 0
  // 数据过短
  try {
    let _ = @codec.decode_qoi_region(rde_cat([[b'\x71', b'\x6F']]), 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // magic 不匹配
  try {
    let bad = rde_patch(
      rde_cat([rde_qoi_header(1, 1, 3), [b'\xFE', b'\x00', b'\x00', b'\x00']]),
      0,
      [b'\x70'],
    )
    let _ = @codec.decode_qoi_region(bad, 0, 0, 1, 1)
  } catch {
    _ => hits += 1
  }
  // 尺寸为 0
  try {
    let _ = @codec.decode_qoi_region(
      rde_cat([rde_qoi_header(0, 1, 3), [b'\xFE', b'\x00', b'\x00', b'\x00']]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // OP_RGB 截断
  try {
    let _ = @codec.decode_qoi_region(
      rde_cat([rde_qoi_header(2, 2, 3), [b'\xFE', b'\x01']]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // OP_RGBA 截断
  try {
    let _ = @codec.decode_qoi_region(
      rde_cat([rde_qoi_header(2, 2, 4), [b'\xFF', b'\x01', b'\x02']]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  // OP_LUMA 截断
  try {
    let _ = @codec.decode_qoi_region(
      rde_cat([rde_qoi_header(2, 2, 3), [b'\x80']]),
      0,
      0,
      1,
      1,
    )
  } catch {
    _ => hits += 1
  }
  assert_eq(hits, 6)
}
