// decode_region 自动识别测试（S14）

///|
fn rg_mk_img(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for i in 0..<data.length() {
    data[i] = ((i * 29) & 0xFF).to_byte()
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn rg_crop(
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
fn rg_same(a : @types.Image, b : @types.Image) -> Bool {
  if a.width != b.width || a.height != b.height || a.channels != b.channels {
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
test "decode_region auto-detects png" {
  let src = rg_mk_img(11, 8, 3)
  let png = @codec.encode_png_pure(src)
  let full = @lib.load_from_bytes_auto(png)
  assert_true(
    rg_same(@lib.decode_region(png, 2, 1, 5, 4), rg_crop(full, 2, 1, 5, 4)),
  )
}

///|
test "decode_region auto-detects bmp" {
  let src = rg_mk_img(11, 8, 3)
  let bmp = @codec.encode_bmp_pure(src)
  let full = @lib.load_from_bytes_auto(bmp)
  assert_true(
    rg_same(@lib.decode_region(bmp, 0, 4, 11, 4), rg_crop(full, 0, 4, 11, 4)),
  )
}

///|
test "decode_region auto-detects qoi" {
  let src = rg_mk_img(11, 8, 4)
  let qoi = @codec.encode_qoi_pure(src)
  let full = @lib.load_from_bytes_auto(qoi)
  assert_true(
    rg_same(@lib.decode_region(qoi, 3, 3, 4, 4), rg_crop(full, 3, 3, 4, 4)),
  )
}

///|
test "decode_region rejects unsupported format" {
  let arr : Array[Byte] = [b'\xFF', b'\xD8', b'\x00', b'\x00']
  let jpeg_like = Bytes::from_array(arr)
  let mut hit = false
  try {
    let _ = @lib.decode_region(jpeg_like, 0, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => hit = true
    _ => ()
  }
  assert_true(hit)
}
