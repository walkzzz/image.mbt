// 覆盖率测试：Image ↔ ScalarField / VectorField 双向绑定

fn fb_img(w : Int32, h : Int32, c : Int32, seed : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 17 + y * 23 + ch * 41 + seed) % 256)
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d.map(fn(v) { v.to_byte() })) }
}

fn fb_img16(w : Int32, h : Int32, c : Int32) -> @types.Image16 {
  let d : Array[Int32] = []
  for i in 0..<(w * h * c) {
    let v = (i * 137) % 65536
    d.push(v & 0xFF)
    d.push((v >> 8) & 0xFF)
  }
  @types.Image16::{ width: w, height: h, channels: c, data: Bytes::from_array(d.map(fn(v) { v.to_byte() })) }
}

fn fb_imgf(w : Int32, h : Int32, c : Int32, vals : Array[Float]) -> @types.ImageF {
  let d : Array[Byte] = []
  for v in vals {
    let b = v.to_le_bytes()
    for i in 0..<4 {
      d.push(b[i])
    }
  }
  @types.ImageF::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

test "field: Image ↔ ScalarField" {
  let gray = fb_img(8, 6, 1, 5)
  let sf = @fieldimg.image_to_scalar_field(gray)
  assert_true(sf.width == 8)
  assert_true(sf.height == 6)
  let back = @fieldimg.scalar_field_to_image(sf)
  assert_true(back.channels == 1)
  assert_true(back.width == 8)
  let rgb = fb_img(4, 4, 3, 9)
  let sf3 = @fieldimg.image_to_scalar_field(rgb)
  assert_true(sf3.width == 4)
  let rgba = fb_img(4, 4, 4, 11)
  assert_true(@fieldimg.image_to_scalar_field(rgba).data.length() == 16)
  // 2 通道走 else 分支
  let two = fb_img(4, 4, 2, 3)
  let sf2 = @fieldimg.image_to_scalar_field(two)
  assert_true(sf2.data.length() == 16)
  // 错误分支
  try {
    let _ = @fieldimg.image_to_scalar_field(fb_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "field: ScalarField ↔ Image 钳位" {
  let clipped = @fieldimg.scalar_field_to_image(@fieldimg.ScalarField::{ width: 2, height: 1, data: [
    -0.5F, 1.5F,
  ] })
  assert_true(clipped.width == 2)
  assert_true(clipped.data[0].to_int() == 0)
  assert_true(clipped.data[1].to_int() == 255)
  let mid = @fieldimg.scalar_field_to_image(@fieldimg.ScalarField::{ width: 1, height: 1, data: [0.5F] })
  assert_true(mid.data[0].to_int() >= 127)
}

test "field: Image ↔ VectorField" {
  let rgb = fb_img(4, 3, 3, 7)
  let vf = @fieldimg.image_to_vector_field(rgb)
  assert_true(vf.width == 4)
  assert_true(vf.dim == 3)
  let back = @fieldimg.vector_field_to_image(vf)
  assert_true(back.channels == 3)
  assert_true(back.width == 4)
  let rgba = fb_img(3, 3, 4, 2)
  let vf4 = @fieldimg.image_to_vector_field(rgba)
  assert_true(vf4.dim == 4)
  assert_true(@fieldimg.vector_field_to_image(vf4).channels == 4)
  // 钳位
  let clip = @fieldimg.vector_field_to_image(@fieldimg.VectorField::{ width: 2, height: 1, dim: 2, data: [
    -1.0F, 2.0F, 1.5F, -0.5F,
  ] })
  assert_true(clip.data[0].to_int() == 0)
  assert_true(clip.data[1].to_int() == 255)
  // 错误分支
  try {
    let _ = @fieldimg.image_to_vector_field(fb_img(0, 4, 3, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @fieldimg.image_to_vector_field(@types.Image::{
      width: 4, height: 4, channels: 0,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "field: 16-bit 与 float 源" {
  let i16 = fb_img16(4, 3, 1)
  let sf = @fieldimg.image16_to_scalar_field(i16)
  assert_true(sf.width == 4)
  assert_true(sf.height == 3)
  let i16c = fb_img16(2, 2, 3)
  assert_true(@fieldimg.image16_to_scalar_field(i16c).data.length() == 4)
  try {
    let _ = @fieldimg.image16_to_scalar_field(@types.Image16::{
      width: 0, height: 2, channels: 1,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // ImageF：负值/超 1 值被钳位
  let imf = fb_imgf(2, 1, 1, [-0.25F, 1.25F])
  let sf_f = @fieldimg.imagef_to_scalar_field(imf)
  assert_true(sf_f.data[0] == 0.0F)
  assert_true(sf_f.data[1] == 1.0F)
  let imf_mid = fb_imgf(1, 1, 1, [0.5F])
  let sf_mid = @fieldimg.imagef_to_scalar_field(imf_mid)
  assert_true(sf_mid.data[0] > 0.4F)
  try {
    let _ = @fieldimg.imagef_to_scalar_field(@types.ImageF::{
      width: 0, height: 2, channels: 1,
      data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
