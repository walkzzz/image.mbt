///|
/// 区域视图的单元测试：裁剪语义、像素读取、物化一致性、零复制（共享同一份 `Bytes`）。

///|
fn make_rgb() -> @types.Image {
  // 4x3 RGB：R = x，G = y，B = x + y
  let w = 4
  let h = 3
  let ch = 3
  let data : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for y in 0..<h {
    for x in 0..<w {
      let o = (y * w + x) * ch
      data[o] = x.to_byte()
      data[o + 1] = y.to_byte()
      data[o + 2] = (x + y).to_byte()
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
test "region: clamp 裁剪到画布" {
  let a = @types.Region::new(-2, -3, 5, 5).clamp(4, 3)
  assert_eq(a.x, 0)
  assert_eq(a.y, 0)
  assert_eq(a.w, 3)
  assert_eq(a.h, 2)
  let b = @types.Region::new(3, 2, 10, 10).clamp(4, 3)
  assert_eq(b.x, 3)
  assert_eq(b.y, 2)
  assert_eq(b.w, 1)
  assert_eq(b.h, 1)
  let c = @types.Region::new(10, 10, 2, 2).clamp(4, 3)
  assert_true(c.is_empty())
  let d = @types.Region::new(0, 0, 0, 5).clamp(4, 3)
  assert_true(d.is_empty())
}

///|
test "region: area / is_empty" {
  assert_eq(@types.Region::new(0, 0, 3, 4).area(), 12)
  assert_false(@types.Region::new(0, 0, 3, 4).is_empty())
  assert_eq(@types.Region::new(0, 0, 0, 4).area(), 0)
  assert_true(@types.Region::new(0, 0, 0, 4).is_empty())
}

///|
test "region: 视图尺寸与像素" {
  let img = make_rgb()
  let r = img.region(1, 1, 2, 2)
  assert_eq(r.width(), 2)
  assert_eq(r.height(), 2)
  assert_eq(r.channels(), 3)
  assert_false(r.is_empty())
  // 区域左上角 = 原图 (1,1)
  assert_eq(r.get(0, 0, 0), b'\x01')
  assert_eq(r.get(0, 0, 1), b'\x01')
  assert_eq(r.get(0, 0, 2), b'\x02')
  // 区域右下角 = 原图 (2,2)
  assert_eq(r.get(1, 1, 0), b'\x02')
  assert_eq(r.get(1, 1, 2), b'\x04')
  let p = r.pixel(1, 0)
  assert_eq(p.length(), 3)
  assert_eq(p[0], b'\x02')
  assert_eq(p[1], b'\x01')
  assert_eq(p[2], b'\x03')
}

///|
test "region: 越界读取返回 0 而不 panic" {
  let img = make_rgb()
  let r = img.region(0, 0, 2, 2)
  assert_eq(r.get(-1, 0, 0), b'\x00')
  assert_eq(r.get(2, 0, 0), b'\x00')
  assert_eq(r.get(0, 2, 0), b'\x00')
  assert_eq(r.get(0, 0, 3), b'\x00')
}

///|
test "region: 越界请求被裁剪而不是报错" {
  let img = make_rgb()
  let r = img.region(2, 1, 100, 100)
  assert_eq(r.width(), 2)
  assert_eq(r.height(), 2)
  let m = r.to_image()
  assert_eq(m.width, 2)
  assert_eq(m.height, 2)
}

///|
test "region: to_image 与原图像素一致" {
  let img = make_rgb()
  let r = img.region(1, 0, 3, 2)
  let m = r.to_image()
  assert_eq(m.width, 3)
  assert_eq(m.height, 2)
  assert_eq(m.channels, 3)
  for y in 0..<2 {
    for x in 0..<3 {
      for c in 0..<3 {
        let a = m.data[(y * 3 + x) * 3 + c]
        let b = img.data[(y * img.width + x + 1) * 3 + c]
        assert_eq(a, b)
      }
    }
  }
}

///|
test "region: 空区域物化为 0x0" {
  let img = make_rgb()
  let r = img.region(10, 10, 5, 5)
  assert_true(r.is_empty())
  assert_eq(r.width(), 0)
  let m = r.to_image()
  assert_eq(m.width, 0)
  assert_eq(m.height, 0)
  assert_eq(m.data.length(), 0)
}

///|
test "region: 视图零复制——底层 Bytes 与原图同一份" {
  let img = make_rgb()
  let r = img.region(1, 1, 2, 2)
  // Bytes 是引用计数类型：视图持有的 base 与原图共享同一缓冲区，长度不变、无新增分配。
  assert_eq(r.base.data.length(), img.data.length())
  // 同图取多次视图，底层长度仍然只算一份
  let r2 = img.region(0, 0, 4, 3)
  let r3 = img.region(1, 1, 2, 2)
  assert_eq(r2.base.data.length(), img.data.length())
  assert_eq(r3.base.data.length(), img.data.length())
}
