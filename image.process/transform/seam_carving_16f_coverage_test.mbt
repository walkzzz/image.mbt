// seam_carving 16-bit/float 边界与放大分支测试（S13 覆盖收敛）

///|
fn sc_mk_img16(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {
  let data : Array[Byte] = Array::make(w * h * ch * 2, b'\x00')
  for y in 0..<h {
    for x in 0..<w {
      for c in 0..<ch {
        let val = y * 1000 + x * 100 + c * 7
        let offset = ((y * w + x) * ch + c) * 2
        data[offset] = (val & 0xFF).to_byte()
        data[offset + 1] = ((val >> 8) & 0xFF).to_byte()
      }
    }
  }
  @types.Image16::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn sc_mk_imgf(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {
  let data : Array[Byte] = Array::make(w * h * ch * 4, b'\x00')
  for y in 0..<h {
    for x in 0..<w {
      for c in 0..<ch {
        let val = Float::from_double(
          (y * 100 + x * 10 + c).to_double() / 1000.0,
        )
        let offset = ((y * w + x) * ch + c) * 4
        let bits = val.reinterpret_as_int()
        data[offset] = (bits & 0xFF).to_byte()
        data[offset + 1] = ((bits >> 8) & 0xFF).to_byte()
        data[offset + 2] = ((bits >> 16) & 0xFF).to_byte()
        data[offset + 3] = ((bits >> 24) & 0xFF).to_byte()
      }
    }
  }
  @types.ImageF::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn sc_px16(img : @types.Image16, x : Int32, y : Int32, c : Int32) -> Int32 {
  let o = ((y * img.width + x) * img.channels + c) * 2
  img.data[o].to_int() | (img.data[o + 1].to_int() << 8)
}

///|
fn sc_pxf(img : @types.ImageF, x : Int32, y : Int32, c : Int32) -> Int32 {
  let o = ((y * img.width + x) * img.channels + c) * 4
  img.data[o].to_int() |
  (img.data[o + 1].to_int() << 8) |
  (img.data[o + 2].to_int() << 16) |
  (img.data[o + 3].to_int() << 24)
}

///|
test "seam16 remove_vertical seam=0 shifts all pixels" {
  let img = sc_mk_img16(6, 4, 1)
  let seam : Array[Int32] = [0, 0, 0, 0]
  let out = @transform.remove_vertical_seam_16(img, seam)
  assert_eq(out.width, 5)
  assert_eq(out.height, 4)
  for y in 0..<4 {
    assert_eq(sc_px16(out, 0, y, 0), sc_px16(img, 1, y, 0))
    assert_eq(sc_px16(out, 4, y, 0), sc_px16(img, 5, y, 0))
  }
}

///|
test "seam16 remove_vertical seam=w-1 keeps left pixels" {
  let img = sc_mk_img16(6, 4, 2)
  let seam : Array[Int32] = [5, 5, 5, 5]
  let out = @transform.remove_vertical_seam_16(img, seam)
  assert_eq(out.width, 5)
  assert_eq(out.channels, 2)
  for y in 0..<4 {
    for c in 0..<2 {
      assert_eq(sc_px16(out, 0, y, c), sc_px16(img, 0, y, c))
      assert_eq(sc_px16(out, 4, y, c), sc_px16(img, 4, y, c))
    }
  }
}

///|
test "seamf remove_vertical both boundaries" {
  let img = sc_mk_imgf(6, 4, 2)
  let left = @transform.remove_vertical_seam_f(img, [0, 0, 0, 0])
  let right = @transform.remove_vertical_seam_f(img, [5, 5, 5, 5])
  assert_eq(left.width, 5)
  assert_eq(right.width, 5)
  assert_eq(sc_pxf(left, 0, 1, 0), sc_pxf(img, 1, 1, 0))
  assert_eq(sc_pxf(right, 0, 1, 0), sc_pxf(img, 0, 1, 0))
}

///|
test "seam16 remove_horizontal both boundaries" {
  let img = sc_mk_img16(4, 6, 1)
  let top = @transform.remove_horizontal_seam_16(img, [0, 0, 0, 0])
  let bottom = @transform.remove_horizontal_seam_16(img, [5, 5, 5, 5])
  assert_eq(top.height, 5)
  assert_eq(bottom.height, 5)
  assert_eq(sc_px16(top, 1, 0, 0), sc_px16(img, 1, 1, 0))
  assert_eq(sc_px16(bottom, 1, 0, 0), sc_px16(img, 1, 0, 0))
  assert_eq(sc_px16(bottom, 1, 4, 0), sc_px16(img, 1, 4, 0))
}

///|
test "seamf remove_horizontal both boundaries" {
  let img = sc_mk_imgf(4, 6, 1)
  let top = @transform.remove_horizontal_seam_f(img, [0, 0, 0, 0])
  let bottom = @transform.remove_horizontal_seam_f(img, [5, 5, 5, 5])
  assert_eq(top.height, 5)
  assert_eq(bottom.height, 5)
  assert_eq(sc_pxf(top, 2, 0, 0), sc_pxf(img, 2, 1, 0))
  assert_eq(sc_pxf(bottom, 2, 4, 0), sc_pxf(img, 2, 4, 0))
}

///|
test "seam16 resize upscale 6x6 -> 8x8 covers insert paths" {
  let img = sc_mk_img16(6, 6, 3)
  let out = @transform.seam_carve_resize_16(img, 8, 8)
  assert_eq(out.width, 8)
  assert_eq(out.height, 8)
  assert_eq(out.channels, 3)
}

///|
test "seamf resize upscale 6x6 -> 8x8 covers insert paths" {
  let img = sc_mk_imgf(6, 6, 3)
  let out = @transform.seam_carve_resize_f(img, 8, 8)
  assert_eq(out.width, 8)
  assert_eq(out.height, 8)
}

///|
test "seam16 resize width-only and height-only" {
  let img = sc_mk_img16(8, 6, 1)
  let narrow = @transform.seam_carve_resize_16(img, 5, 6)
  let short = @transform.seam_carve_resize_16(img, 8, 3)
  assert_eq(narrow.width, 5)
  assert_eq(narrow.height, 6)
  assert_eq(short.width, 8)
  assert_eq(short.height, 3)
}

///|
test "seamf resize width-only and height-only" {
  let img = sc_mk_imgf(8, 6, 1)
  let narrow = @transform.seam_carve_resize_f(img, 5, 6)
  let short = @transform.seam_carve_resize_f(img, 8, 3)
  assert_eq(narrow.width, 5)
  assert_eq(narrow.height, 6)
  assert_eq(short.width, 8)
  assert_eq(short.height, 3)
}

///|
test "seam16 resize rejects non-positive and >2x" {
  let img = sc_mk_img16(6, 6, 1)
  let mut hits = 0
  try {
    let _ = @transform.seam_carve_resize_16(img, 0, 6)
  } catch {
    _ => hits = hits + 1
  }
  try {
    let _ = @transform.seam_carve_resize_16(img, 6, -1)
  } catch {
    _ => hits = hits + 1
  }
  try {
    let _ = @transform.seam_carve_resize_16(img, 13, 6)
  } catch {
    _ => hits = hits + 1
  }
  assert_eq(hits, 3)
}

///|
test "seamf resize rejects non-positive and >2x" {
  let img = sc_mk_imgf(6, 6, 1)
  let mut hits = 0
  try {
    let _ = @transform.seam_carve_resize_f(img, -2, 6)
  } catch {
    _ => hits = hits + 1
  }
  try {
    let _ = @transform.seam_carve_resize_f(img, 6, 0)
  } catch {
    _ => hits = hits + 1
  }
  try {
    let _ = @transform.seam_carve_resize_f(img, 6, 13)
  } catch {
    _ => hits = hits + 1
  }
  assert_eq(hits, 3)
}
