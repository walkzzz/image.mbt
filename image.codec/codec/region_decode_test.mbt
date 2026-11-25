// 区域解码测试（S14）：tile 输出必须与整图解码后裁切逐字节一致

///|
fn rd_mk_img(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for y in 0..<h {
    for x in 0..<w {
      for c in 0..<ch {
        data[(y * w + x) * ch + c] = ((x * 17 + y * 31 + c * 7) & 0xFF).to_byte()
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn rd_crop(
  img : @types.Image,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.Image {
  let ch = img.channels
  let out : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for ry in 0..<h {
    for rx in 0..<w {
      for c in 0..<ch {
        out[(ry * w + rx) * ch + c] = img.data[((y + ry) * img.width + (x + rx)) *
          ch +
          c]
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(out),
  }
}

///|
fn rd_same(a : @types.Image, b : @types.Image) -> Bool {
  if a.width != b.width || a.height != b.height || a.channels != b.channels {
    return false
  }
  if a.data.length() != b.data.length() {
    return false
  }
  for i in 0..<a.data.length() {
    if a.data[i] != b.data[i] {
      return false
    }
  }
  true
}

///|
test "png region == crop of full decode (RGB)" {
  let src = rd_mk_img(17, 13, 3)
  let png = @codec.encode_png_pure(src)
  let full = @codec.decode_png_pure(png)
  let tile = @codec.decode_png_region(png, 5, 4, 7, 6)
  assert_true(rd_same(tile, rd_crop(full, 5, 4, 7, 6)))
  assert_eq(tile.width, 7)
  assert_eq(tile.height, 6)
  assert_eq(tile.channels, 3)
}

///|
test "png region == crop of full decode (RGBA)" {
  let src = rd_mk_img(17, 13, 4)
  let png = @codec.encode_png_pure(src)
  let full = @codec.decode_png_pure(png)
  let tile = @codec.decode_png_region(png, 0, 9, 17, 4)
  assert_true(rd_same(tile, rd_crop(full, 0, 9, 17, 4)))
}

///|
test "png region full image and 1x1" {
  let src = rd_mk_img(9, 7, 3)
  let png = @codec.encode_png_pure(src)
  let full = @codec.decode_png_pure(png)
  assert_true(rd_same(@codec.decode_png_region(png, 0, 0, 9, 7), full))
  assert_true(
    rd_same(@codec.decode_png_region(png, 8, 6, 1, 1), rd_crop(full, 8, 6, 1, 1)),
  )
}

///|
test "png region rejects out of bounds and zero size" {
  let png = @codec.encode_png_pure(rd_mk_img(9, 7, 3))
  let mut hits = 0
  try {
    let _ = @codec.decode_png_region(png, 0, 0, 0, 7)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hits = hits + 1
    _ => ()
  }
  try {
    let _ = @codec.decode_png_region(png, 5, 0, 5, 7)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hits = hits + 1
    _ => ()
  }
  try {
    let _ = @codec.decode_png_region(png, 0, 5, 9, 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hits = hits + 1
    _ => ()
  }
  try {
    let _ = @codec.decode_png_region(png, -1, 0, 3, 3)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hits = hits + 1
    _ => ()
  }
  assert_eq(hits, 4)
}

///|
test "bmp region == crop of full decode (24-bit)" {
  let src = rd_mk_img(15, 11, 3)
  let bmp = @codec.encode_bmp_pure(src)
  let full = @codec.decode_bmp_pure(bmp)
  let tile = @codec.decode_bmp_region(bmp, 3, 2, 8, 6)
  assert_true(rd_same(tile, rd_crop(full, 3, 2, 8, 6)))
}

///|
test "bmp region == crop of full decode (32-bit bottom-up)" {
  let src = rd_mk_img(15, 11, 4)
  let bmp = @codec.encode_bmp_pure(src)
  let full = @codec.decode_bmp_pure(bmp)
  assert_true(
    rd_same(@codec.decode_bmp_region(bmp, 0, 0, 15, 3), rd_crop(full, 0, 0, 15, 3)),
  )
  assert_true(
    rd_same(@codec.decode_bmp_region(bmp, 4, 8, 6, 3), rd_crop(full, 4, 8, 6, 3)),
  )
}

///|
test "qoi region == crop of full decode" {
  let src = rd_mk_img(13, 9, 4)
  let qoi = @codec.encode_qoi_pure(src)
  let full = @codec.decode_qoi_pure(qoi)
  assert_true(
    rd_same(@codec.decode_qoi_region(qoi, 2, 3, 6, 5), rd_crop(full, 2, 3, 6, 5)),
  )
  let rgb_src = rd_mk_img(13, 9, 3)
  let qoi3 = @codec.encode_qoi_pure(rgb_src)
  let full3 = @codec.decode_qoi_pure(qoi3)
  assert_true(
    rd_same(@codec.decode_qoi_region(qoi3, 0, 7, 13, 2), rd_crop(full3, 0, 7, 13, 2)),
  )
}
