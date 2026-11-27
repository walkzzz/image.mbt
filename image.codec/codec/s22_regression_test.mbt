// S22 缺陷回归测试：TGA descriptor / alpha / TIFF 数据长度守卫
// 纯逻辑断言，全目标可用，不依赖 @core

///|
fn s22_header(
  width : Int32,
  height : Int32,
  bpp : Int32,
  image_type : Int32,
  descriptor : Int32,
) -> Array[Byte] {
  let out : Array[Byte] = []
  out.push(b'\x00') // ID length
  out.push(b'\x00') // color map type
  out.push(image_type.to_byte())
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push((width & 0xFF).to_byte())
  out.push(((width >> 8) & 0xFF).to_byte())
  out.push((height & 0xFF).to_byte())
  out.push(((height >> 8) & 0xFF).to_byte())
  out.push(bpp.to_byte())
  out.push(descriptor.to_byte())
  out
}

///|
fn s22_push_bgr(a : Array[Byte], r : Int32, g : Int32, b : Int32) -> Unit {
  a.push(b.to_byte())
  a.push(g.to_byte())
  a.push(r.to_byte())
}

///|
test "s22: TGA 编码 4 通道不再丢 alpha（32-bit BGRA 往返）" {
  try {
    let img = @types.Image::{
      width: 3,
      height: 2,
      channels: 4,
      data: Bytes::from_array([
        255, 0, 0, 200, 0, 255, 0, 10, 0, 0, 255, 0, //
         10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, //
      ]),
    }
    let bytes = @codec.encode_tga_pure(img)
    // 位深 32，描述符 = 0x28（bit5 top-down + alpha 位深 8）
    assert_eq(bytes[16].to_int(), 32)
    assert_eq(bytes[17].to_int(), 0x28)
    assert_eq(bytes.length(), 18 + 3 * 2 * 4)
    let d = @codec.decode_tga_pure(bytes)
    assert_eq(d.channels, 4)
    assert_eq(d.data.length(), 24)
    for i in 0..<24 {
      assert_eq(d.data[i].to_int(), img.data[i].to_int())
    }
  } catch {
    _ => assert_true(false)
  }
}

///|
test "s22: TGA 编码器 24-bit 描述符 = 0x20（top-down，不再自相矛盾）" {
  try {
    let img = @types.Image::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array([
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, //
      ]),
    }
    let bytes = @codec.encode_tga_pure(img)
    assert_eq(bytes[16].to_int(), 24)
    assert_eq(bytes[17].to_int(), 0x20)
    // 与标准 top-down 文件一致：首像素即图像左上角
    assert_eq(bytes[18].to_int(), 3)
    assert_eq(bytes[19].to_int(), 2)
    assert_eq(bytes[20].to_int(), 1)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "s22: 规范 top-down TGA（0x20）解码不再上下翻转" {
  try {
    let out = s22_header(2, 2, 24, 2, 0x20)
    s22_push_bgr(out, 255, 0, 0) // 第 1 行：红、绿
    s22_push_bgr(out, 0, 255, 0)
    s22_push_bgr(out, 0, 0, 255) // 第 2 行：蓝、白
    s22_push_bgr(out, 255, 255, 255)
    let img = @codec.decode_tga_pure(Bytes::from_array(out))
    assert_eq(img.data[0].to_int(), 255)
    assert_eq(img.data[1].to_int(), 0)
    assert_eq(img.data[2].to_int(), 0)
    assert_eq(img.data[9].to_int(), 255)
    assert_eq(img.data[10].to_int(), 255)
    assert_eq(img.data[11].to_int(), 255)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "s22: 规范 bottom-up TGA（0x00）仍整体上下翻转" {
  try {
    let out = s22_header(2, 2, 24, 2, 0x00)
    s22_push_bgr(out, 255, 0, 0) // 文件首行为图像底行
    s22_push_bgr(out, 0, 255, 0)
    s22_push_bgr(out, 0, 0, 255)
    s22_push_bgr(out, 255, 255, 255)
    let img = @codec.decode_tga_pure(Bytes::from_array(out))
    // 图像第 1 行应是文件最后一行（蓝、白）
    assert_eq(img.data[0].to_int(), 0)
    assert_eq(img.data[1].to_int(), 0)
    assert_eq(img.data[2].to_int(), 255)
    assert_eq(img.data[3].to_int(), 255)
    assert_eq(img.data[4].to_int(), 255)
    assert_eq(img.data[5].to_int(), 255)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "s22: 描述符 bit4（right-to-left）触发水平镜像" {
  try {
    let out = s22_header(2, 2, 24, 2, 0x30)
    s22_push_bgr(out, 255, 0, 0) // 文件首行左侧：红
    s22_push_bgr(out, 0, 255, 0) // 右侧：绿
    s22_push_bgr(out, 0, 0, 255)
    s22_push_bgr(out, 255, 255, 255)
    let img = @codec.decode_tga_pure(Bytes::from_array(out))
    // top-down + 镜像：图像左上角应是文件首行最右的绿
    assert_eq(img.data[0].to_int(), 0)
    assert_eq(img.data[1].to_int(), 255)
    assert_eq(img.data[2].to_int(), 0)
    assert_eq(img.data[3].to_int(), 255)
    assert_eq(img.data[4].to_int(), 0)
    assert_eq(img.data[5].to_int(), 0)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "s22: TIFF 编码像素长度不足抛 EncodeFailed 而非崩溃" {
  let img = @types.Image::{
    width: 2,
    height: 1,
    channels: 3,
    data: Bytes::from_array([1, 2, 3]),
  }
  let mut raised = false
  try {
    let _ = @codec.encode_tiff_pure(img)
  } catch {
    _ => raised = true
  }
  assert_true(raised)
}
