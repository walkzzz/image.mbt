// 覆盖率测试：ImageLike trait 在四种容器上的默认方法，以及 AnyImage 转换

fn tk_u8(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  let n = w * h * c
  let d : Array[Byte] = []
  for i in 0..<n {
    d.push((fill + i).to_byte())
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn tk_u16(w : Int32, h : Int32, vals : Array[Int32]) -> @types.Image16 {
  let d : Array[Byte] = []
  for v in vals {
    d.push((v & 0xff).to_byte())
    d.push(((v >> 8) & 0xff).to_byte())
  }
  @types.Image16::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

fn tk_f32(w : Int32, h : Int32, vals : Array[Float]) -> @types.ImageF {
  let d : Array[Byte] = []
  for v in vals {
    let b = v.to_le_bytes()
    for j in 0..<4 {
      d.push(b[j])
    }
  }
  @types.ImageF::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

test "tkcov: ImageLike 在 @types.Image 上" {
  let img = tk_u8(2, 3, 3, 10)
  assert_true(img.width() == 2)
  assert_true(img.height() == 3)
  assert_true(img.channels() == 3)
  assert_true(img.bytes_per_pixel() == 1)
  assert_true(img.pixel_count() == 18)
  assert_true(img.byte_count() == 18)
  assert_true(!img.is_grayscale())
  assert_true(img.is_rgb())
  assert_true(!img.is_rgba())
  // 灰度与 RGBA
  let g = tk_u8(2, 2, 1, 0)
  assert_true(g.is_grayscale())
  assert_true(!g.is_rgb())
  assert_true(g.pixel_count() == 4)
  let a = tk_u8(2, 2, 4, 0)
  assert_true(a.is_rgba())
  assert_true(a.pixel_count() == 16)
  assert_true(a.byte_count() == 16)
}

test "tkcov: ImageLike 在 @types.Image16 上" {
  let img = tk_u16(2, 2, [1000, 2000, 3000, 4000])
  assert_true(img.width() == 2)
  assert_true(img.height() == 2)
  assert_true(img.channels() == 1)
  assert_true(img.bytes_per_pixel() == 2)
  assert_true(img.pixel_count() == 4)
  assert_true(img.byte_count() == 8)
  assert_true(img.is_grayscale())
  assert_true(!img.is_rgb())
  assert_true(!img.is_rgba())
}

test "tkcov: ImageLike 在 @types.ImageF 与 AnyImage 上" {
  let img = tk_f32(2, 2, [0.0F, 0.5F, 1.0F, 2.0F])
  assert_true(img.width() == 2)
  assert_true(img.height() == 2)
  assert_true(img.bytes_per_pixel() == 4)
  assert_true(img.pixel_count() == 4)
  assert_true(img.byte_count() == 16)
  assert_true(img.is_grayscale())
  // AnyImage 三分支
  let u8 = @types.image_to_any(tk_u8(2, 1, 3, 1))
  assert_true(u8.width() == 2)
  assert_true(u8.height() == 1)
  assert_true(u8.channels() == 3)
  assert_true(u8.bytes_per_pixel() == 1)
  assert_true(u8.is_rgb())
  let u16 = @types.image16_to_any(tk_u16(2, 1, [1, 2]))
  assert_true(u16.width() == 2)
  assert_true(u16.channels() == 1)
  assert_true(u16.bytes_per_pixel() == 2)
  assert_true(u16.is_grayscale())
  let f32img = @types.imagef_to_any(tk_f32(2, 1, [0.1F, 0.2F]))
  assert_true(f32img.width() == 2)
  assert_true(f32img.height() == 1)
  assert_true(f32img.channels() == 1)
  assert_true(f32img.bytes_per_pixel() == 4)
  assert_true(f32img.pixel_count() == 2)
  assert_true(f32img.byte_count() == 8)
}

test "tkcov: AnyImage 降级到 8-bit" {
  // U8 原样返回
  let src = tk_u8(2, 1, 1, 5)
  let o0 = @types.any_image_to_u8(@types.image_to_any(src))
  assert_true(o0.data[0].to_int() == 5)
  // U16：低位截断 + 高位钳制
  let o1 = @types.any_image_to_u8(@types.image16_to_any(tk_u16(3, 1, [0x00FF, 0x01FF, 0xABCD])))
  assert_true(o1.data[0].to_int() == 255)
  assert_true(o1.data[1].to_int() == 255)
  assert_true(o1.data[2].to_int() == 255)
  // F32：四舍五入 + 负值钳 0 + 超 255 钳 255
  let o2 = @types.any_image_to_u8(
    @types.imagef_to_any(tk_f32(4, 1, [-0.5F, 0.0F, 0.5F, 1.5F])),
  )
  assert_true(o2.channels == 1)
  assert_true(o2.data[0].to_int() == 0)
  assert_true(o2.data[1].to_int() == 0)
  assert_true(o2.data[2].to_int() == 128)
  assert_true(o2.data[3].to_int() == 255)
}

test "tkcov: @types.hdr_from_u8 归一化" {
  let src = tk_u8(2, 1, 1, 0)
  let f = @types.hdr_from_u8(src)
  assert_true(f.width == 2)
  assert_true(f.height == 1)
  assert_true(f.channels == 1)
  assert_true(f.bytes_per_pixel() == 4)
  // 0 -> 0.0，255 -> 1.0
  let f255 = @types.hdr_from_u8(tk_u8(1, 1, 1, 255))
  let f0 = @types.hdr_from_u8(tk_u8(1, 1, 1, 0))
  let b255 = f255.data
  let b0 = f0.data
  let v255 = Float::reinterpret_from_int(
    (b255[3].to_int() << 24) |
    (b255[2].to_int() << 16) |
    (b255[1].to_int() << 8) |
    b255[0].to_int(),
  )
  let v0 = Float::reinterpret_from_int(
    (b0[3].to_int() << 24) |
    (b0[2].to_int() << 16) |
    (b0[1].to_int() << 8) |
    b0[0].to_int(),
  )
  assert_true(v255 == 1.0F)
  assert_true(v0 == 0.0F)
  // 中值近似 0.5
  let mid = @types.hdr_from_u8(tk_u8(1, 1, 1, 128))
  let bm = mid.data
  let vm = Float::reinterpret_from_int(
    (bm[3].to_int() << 24) |
    (bm[2].to_int() << 16) |
    (bm[1].to_int() << 8) |
    bm[0].to_int(),
  )
  assert_true(vm > 0.49F && vm < 0.51F)
}
