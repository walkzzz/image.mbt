// 白盒覆盖率：表格线合并与灰度化

fn tbl_line(x1 : Int32, y1 : Int32, x2 : Int32, y2 : Int32, kind : TableLineType) -> TableLine {
  TableLine::{ x1, y1, x2, y2, line_type: kind, thickness: 1 }
}

fn tbl_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, fill.to_byte())),
  }
}

///|
test "tbl: 水平线合并空表与相邻合并" {
  let empty : Array[TableLine] = []
  assert_true(merge_horizontal_lines(empty, 2).length() == 0)
  let near : Array[TableLine] = [
    tbl_line(0, 10, 40, 10, TableLineType::Horizontal),
    tbl_line(0, 11, 40, 11, TableLineType::Horizontal),
    tbl_line(0, 20, 40, 20, TableLineType::Horizontal),
  ]
  let merged = merge_horizontal_lines(near, 2)
  assert_true(merged.length() == 2)
  assert_true(merged[0].thickness == 2)
  assert_true(merged[0].x1 == 0)
  assert_true(merged[0].x2 == 40)
  // x 不重叠 → 不合并
  let apart : Array[TableLine] = [
    tbl_line(0, 10, 10, 10, TableLineType::Horizontal),
    tbl_line(50, 10, 70, 10, TableLineType::Horizontal),
  ]
  assert_true(merge_horizontal_lines(apart, 4).length() == 2)
}

///|
test "tbl: 垂直线合并空表与相邻合并" {
  let empty : Array[TableLine] = []
  assert_true(merge_vertical_lines(empty, 2).length() == 0)
  let near : Array[TableLine] = [
    tbl_line(10, 0, 10, 30, TableLineType::Vertical),
    tbl_line(11, 0, 11, 30, TableLineType::Vertical),
    tbl_line(30, 0, 30, 30, TableLineType::Vertical),
  ]
  let merged = merge_vertical_lines(near, 2)
  assert_true(merged.length() == 2)
  assert_true(merged[0].thickness == 2)
  assert_true(merged[0].y1 == 0)
  assert_true(merged[0].y2 == 30)
  // y 不重叠 → 不合并
  let apart : Array[TableLine] = [
    tbl_line(10, 0, 10, 10, TableLineType::Vertical),
    tbl_line(10, 40, 10, 60, TableLineType::Vertical),
  ]
  assert_true(merge_vertical_lines(apart, 4).length() == 2)
}

///|
test "tbl: 灰度化单通道直通与彩色加权" {
  let gray = tbl_img(3, 2, 1, 200)
  let out = to_grayscale_table(gray)
  assert_true(out.channels == 1)
  assert_true(out.width == 3)
  // 纯白三通道 → 255
  let white = tbl_img(2, 2, 3, 255)
  let g = to_grayscale_table(white)
  assert_true(g.data[0].to_int() == 255)
  // 纯黑 → 0
  let black = tbl_img(2, 2, 3, 0)
  let gb = to_grayscale_table(black)
  assert_true(gb.data[0].to_int() == 0)
  // RGBA 的前三通道参与计算
  let rgba = tbl_img(2, 2, 4, 100)
  let ga = to_grayscale_table(rgba)
  assert_true(ga.data[0].to_int() == 100)
}
