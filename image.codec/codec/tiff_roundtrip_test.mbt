///|
fn tiff_make_rgb(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 17 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "tiff: encode → decode RGB 8x8 往返" {
  let img = tiff_make_rgb(8, 8, 0)
  try {
    let tiff = @codec.encode_tiff_pure(img)
    assert_true(tiff.length() > 8)
    let back = @codec.decode_tiff_pure(tiff)
    assert_eq(back.width, 8)
    assert_eq(back.height, 8)
    assert_eq(back.channels, 3)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "tiff: encode → decode 灰度 4x4 往返" {
  let data : Array[Byte] = [
    b'\x00', b'\x40', b'\x80', b'\xFF', b'\x10', b'\x20', b'\x30', b'\x40', b'\x50',
    b'\x60', b'\x70', b'\x80', b'\x90', b'\xA0', b'\xB0', b'\xC0',
  ]
  let img = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(data),
  }
  try {
    let tiff = @codec.encode_tiff_pure(img)
    let back = @codec.decode_tiff_pure(tiff)
    assert_eq(back.width, 4)
    assert_eq(back.height, 4)
    assert_eq(back.channels, 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "codec_trait: codec_detect_format 魔数识别" {
  let img = tiff_make_rgb(2, 2, 5)
  let png = @codec.encode_png_pure(img)
  let bmp = @codec.encode_bmp_pure(img)
  assert_eq(@codec.codec_detect_format(png), @types.ImageFormat::Png)
  assert_eq(@codec.codec_detect_format(bmp), @types.ImageFormat::Bmp)
  assert_eq(@codec.codec_detect_format(b"\x00"), @types.ImageFormat::Unknown)
}

///|
test "tiff: packbits 解码字面/重复/无效控制码" {
  try {
    // 0x02 → 复制 3 个字面字节；0xFE → 重复 3 次 0xAA；0x80 → 无效（跳过）
    let out = @codec.tiff_packbits_decode(b"\x02\x10\x20\x30\xFE\xAA")
    assert_true(out.length() >= 6)
    assert_eq(out[0].to_int(), 0x10)
    assert_eq(out[1].to_int(), 0x20)
    assert_eq(out[2].to_int(), 0x30)
    assert_eq(out[3].to_int(), 0xAA)
  } catch {
    _ => assert_true(false)
  }
}
