///|
test "testgen: render_digits 尺寸与墨迹" {
  let img = @testgen.render_digits([8], scale=4, margin=4)
  assert_true(img.width > 0)
  assert_eq(img.channels, 1)
  let mut ink = 0
  for b in img.data {
    if b.to_int() == 0 {
      ink += 1
    }
  }
  assert_true(ink > 0)
}

///|
test "testgen: render_code39 黑白条纹" {
  let img = @testgen.render_code39([10, 11, 12])
  assert_true(img.width > 20)
  assert_eq(img.channels, 1)
  let y = img.height / 2
  let mut has_black = false
  let mut has_white = false
  for x in 0..<img.width {
    let v = img.data[y * img.width + x].to_int()
    if v == 0 {
      has_black = true
    }
    if v == 255 {
      has_white = true
    }
  }
  assert_true(has_black && has_white)
}

///|
test "testgen: QR finder / timing / dark module" {
  let m = @testgen.qr_modules(b"hi")
  assert_eq(m.length(), 441)
  assert_eq(m[0], 1)
  assert_eq(m[6], 1)
  assert_eq(m[1 * 21 + 1], 0)
  assert_eq(m[3 * 21 + 3], 1)
  assert_eq(m[14], 1)
  assert_eq(m[14 * 21], 1)
  assert_eq(m[6 * 21 + 8], 1)
  assert_eq(m[6 * 21 + 9], 0)
  assert_eq(m[13 * 21 + 8], 1)
}

///|
test "testgen: VP8 inter/key frame 头字段" {
  let inter = @testgen.build_vp8_inter_frame(first_part_size=16)
  assert_eq(inter.length(), 19)
  assert_eq(inter[0].to_int() & 1, 1)
  assert_eq((inter[0].to_int() >> 4) & 1, 1)
  let key = @testgen.build_vp8_key_frame(16, 16, first_part_size=8)
  assert_eq(key[0].to_int() & 1, 0)
  assert_eq(key[3].to_int(), 0x9D)
  assert_eq(key[4].to_int(), 0x01)
  assert_eq(key[5].to_int(), 0x2A)
  assert_eq(key[6].to_int(), 16)
  assert_eq(key[7].to_int(), 0)
}
