// 覆盖率测试：多边形填充与越界像素丢弃

fn dwc_img(w : Int32, h : Int32, ch : Int32) -> @types.Image {
  let n = w * h * ch
  let data : Array[Byte] = Array::make(n, b'\x00')
  @types.Image::{ width: w, height: h, channels: ch, data: Bytes::from_array(data) }
}

///|
test "dwc: 三角形填充覆盖内部像素" {
  let img = dwc_img(16, 16, 3)
  let pts : Array[(Int32, Int32)] = [(2, 2), (13, 2), (2, 13)]
  let color : Array[Byte] = [255, 0, 0]
  let out = @transform.draw_polygon(img, pts, color, fill=true)
  assert_true(out.width == 16)
  // 内部点 (4, 4) 应被填充
  let off = (4 * 16 + 4) * 3
  assert_true(out.data[off].to_int() == 255)
  // 外部点 (15, 15) 应保持原值
  let off2 = (15 * 16 + 15) * 3
  assert_true(out.data[off2].to_int() == 0)
}

///|
test "dwc: 少于两点的多边形直接返回副本" {
  let img = dwc_img(8, 8, 1)
  let pts : Array[(Int32, Int32)] = [(1, 1)]
  let out = @transform.draw_polygon(img, pts, [7])
  assert_true(out.width == 8)
  assert_true(out.data[0].to_int() == 0)
}

///|
test "dwc: 越界像素被丢弃" {
  let img = dwc_img(8, 8, 1)
  let out = @transform.draw_line(img, -5, -5, 20, 20, [9])
  assert_true(out.width == 8)
  // 落在线上的内部点应被写入
  assert_true(out.data[3 * 8 + 3].to_int() == 9)
}

///|
test "dwc: 细线加粗与多边形轮廓" {
  let img = dwc_img(12, 12, 3)
  let out = @transform.draw_line(img, 2, 2, 9, 2, [0, 255, 0], thickness=3)
  assert_true(out.width == 12)
  let out2 = @transform.draw_polygon(img, [(1, 1), (10, 1), (1, 10)], [0, 0, 255])
  assert_true(out2.width == 12)
}
