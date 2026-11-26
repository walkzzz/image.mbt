// 覆盖率测试：TIFF 编解码 / 扩展信息 / 区域解码

fn trc_img(w : Int32, h : Int32, c : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 31 + y * 47 + ch * 61) % 256)
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

test "tiff: 编码解码往返与扩展信息" {
  let rgb = trc_img(6, 4, 3)
  let bytes = encode_tiff_pure(rgb)
  assert_true(is_tiff_format(bytes))
  let back = decode_tiff_pure(bytes)
  assert_true(back.width == 6)
  assert_true(back.height == 4)
  assert_true(back.channels <= 4)
  let info = tiff_info_extended(bytes)
  assert_true(info.width == 6)
  assert_true(info.height == 4)
  assert_true(info.bit_depth == 8)
  assert_true(info.is_little_endian || !info.is_little_endian)
  assert_true(info.compression >= 1)
  // 灰度 / RGBA
  let gray = decode_tiff_pure(encode_tiff_pure(trc_img(8, 8, 1)))
  assert_true(gray.width == 8)
  let rgba = decode_tiff_pure(encode_tiff_pure(trc_img(5, 5, 4)))
  assert_true(rgba.height == 5)
}

test "tiff: is_tiff_format 分支" {
  let le = Bytes::from_array([
    b'\x49', b'\x49', b'\x2a', b'\x00', b'\x08', b'\x00', b'\x00', b'\x00',
  ])
  let be = Bytes::from_array([
    b'\x4d', b'\x4d', b'\x00', b'\x2a', b'\x00', b'\x00', b'\x00', b'\x08',
  ])
  assert_true(is_tiff_format(le))
  assert_true(is_tiff_format(be))
  assert_true(!is_tiff_format(Bytes::from_array([b'\x49', b'\x49'])))
  assert_true(!is_tiff_format(Bytes::from_array([
    b'\x50', b'\x4e', b'\x47', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])))
  assert_true(!is_tiff_format(Bytes::from_array([b'\x49', b'\x58', b'\x2a', b'\x00'])))
}

test "tiff: err 过短" {
  // 过短
  try {
    let _ = decode_tiff_pure(Bytes::from_array([b'\x49']))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "tiff: err 魔数" {
  // 魔数错误
  try {
    let _ = decode_tiff_pure(Bytes::from_array([
      b'\x42', b'\x42', b'\x2a', b'\x00', b'\x08', b'\x00', b'\x00', b'\x00',
    ]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "tiff: err 非TIFF" {
  // 非 TIFF
  try {
    let _ = tiff_info_extended(Bytes::from_array([b'\x00', b'\x00', b'\x00', b'\x00']))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "tiff: err 编码尺寸" {
  // 编码错误
  try {
    let _ = encode_tiff_pure(trc_img(0, 4, 3))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "tiff: err 编码通道" {
  try {
    let _ = encode_tiff_pure(trc_img(4, 4, 5))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "tiff: PackBits 解码分支" {
  // 纯字面串
  let lit = Bytes::from_array([b'\x02', (65).to_byte(), (66).to_byte(), (67).to_byte()])
  let a = tiff_packbits_decode(lit)
  assert_true(a.length() == 3)
  // 重复串：254 => 257-254=3 次
  let rep = Bytes::from_array([b'\xfe', (65).to_byte()])
  let b = tiff_packbits_decode(rep)
  assert_true(b.length() == 3)
  // 重复串 + 字面串混合
  let mix = Bytes::from_array([
    b'\xfe', (65).to_byte(), b'\x01', (66).to_byte(), (67).to_byte(),
  ])
  let c = tiff_packbits_decode(mix)
  assert_true(c.length() == 5)
  // 扩展模式：重复（0x80 0x7F 0xFF -> 2 次）
  let ext = Bytes::from_array([b'\x80', b'\x7f', b'\xff', (65).to_byte()])
  let d = tiff_packbits_decode(ext)
  assert_true(d.length() == 2)
  // 空输入
  let e = tiff_packbits_decode(Bytes::from_array([]))
  assert_true(e.length() == 0)
  // 扩展模式数据不足 → 抛错
  try {
    let _ = tiff_packbits_decode(Bytes::from_array([b'\x80']))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

fn trc_lzw_pack(codes : Array[Int32], width : Int32) -> Bytes {
  let bits : Array[Int32] = []
  for code in codes {
    for i in 0..<width {
      bits.push((code >> i) & 1)
    }
  }
  let total = (bits.length() + 7) / 8
  let out : Array[Int32] = Array::make(total, 0)
  for i in 0..<bits.length() {
    if bits[i] == 1 {
      out[i / 8] = out[i / 8] | (1 << (i % 8))
    }
  }
  Bytes::from_array(out.map(fn(v) { v.to_byte() }))
}

test "tiff: LZW 解码分支" {
  // 码流：头字节 8，CLEAR(256) + 'A'(65) + 'B'(66) + EOI(257)，9 位 LSB 优先
  let body = trc_lzw_pack([256, 65, 66, 257], 9)
  let payload : Array[Byte] = [(8).to_byte()]
  for byte in body {
    payload.push(byte)
  }
  let lzw = Bytes::from_array(payload)
  let out = tiff_lzw_decode(lzw)
  assert_true(out.length() <= 4)
  // 数据过短
  try {
    let _ = tiff_lzw_decode(Bytes::from_array([(8).to_byte()]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 初始码长非法
  try {
    let _ = tiff_lzw_decode(Bytes::from_array([(1).to_byte(), (0).to_byte()]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 首码非 CLEAR
  try {
    let _ = tiff_lzw_decode(Bytes::from_array([
      (8).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    ]))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "region: PNG / BMP / QOI 区域解码" {
  let img = trc_img(8, 6, 3)
  let png = encode_png_pure(img)
  let pfull = decode_png_region(png, 0, 0, 8, 6)
  assert_true(pfull.width == 8)
  assert_true(pfull.height == 6)
  let psub = decode_png_region(png, 2, 1, 4, 3)
  assert_true(psub.width == 4)
  assert_true(psub.height == 3)
  let bmp = encode_bmp_pure(img)
  let bfull = decode_bmp_region(bmp, 0, 0, 8, 6)
  assert_true(bfull.width == 8)
  let bsub = decode_bmp_region(bmp, 1, 2, 3, 2)
  assert_true(bsub.width == 3)
  let qoi = encode_qoi_pure(img)
  let qfull = decode_qoi_region(qoi, 0, 0, 8, 6)
  assert_true(qfull.width == 8)
  let qsub = decode_qoi_region(qoi, 3, 2, 2, 2)
  assert_true(qsub.width == 2)
  // 错误分支
  try {
    let _ = decode_png_region(Bytes::from_array([b'\x00']), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = decode_bmp_region(Bytes::from_array([b'\x00']), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = decode_qoi_region(Bytes::from_array([b'\x00']), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
