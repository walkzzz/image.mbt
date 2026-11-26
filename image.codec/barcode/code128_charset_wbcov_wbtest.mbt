// 白盒覆盖率：Code128 字符集切换与码字映射

fn c1c_runs(widths : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut is_bar = true
  for w in widths {
    let cnt = if w < 0 { 0 } else { w }
    for _i in 0..<cnt {
      out.push(if is_bar { 1 } else { 0 })
    }
    is_bar = !is_bar
  }
  out
}

fn c1c_px(codes : Array[Int32], pad : Int32) -> Array[Int32] {
  let px : Array[Int32] = []
  for c in codes {
    let sym = c1c_runs(code128_patterns[c])
    for v in sym {
      px.push(v)
    }
  }
  for _i in 0..<pad {
    px.push(0)
  }
  px
}

fn c1c_image(px : Array[Int32], h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for v in px {
    data.push(if v == 1 { b'\x00' } else { b'\xff' })
  }
  @types.Image::{ width: px.length(), height: h, channels: 1, data: Bytes::from_array(data) }
}

///|
test "c1c: 起始符 103 进入 CodeA 并解出低码位字符" {
  let img = c1c_image(c1c_px([103, 1, 1, 106], 14), 1)
  match decode_code128(img) {
    Some(r) => assert_true(r.data == "!")
    None => assert_true(false)
  }
}

///|
test "c1c: 起始符 104 + 切到 CodeA + 高位控制字符" {
  let img = c1c_image(c1c_px([104, 101, 70, 36, 106], 14), 1)
  match decode_code128(img) {
    Some(r) => assert_true(r.data.length() == 1)
    None => assert_true(false)
  }
}

///|
test "c1c: 起始符 105 进入 CodeC 解出两位数字" {
  let img = c1c_image(c1c_px([105, 12, 14, 106], 14), 1)
  match decode_code128(img) {
    Some(r) => assert_true(r.data == "12")
    None => assert_true(false)
  }
}

///|
test "c1c: 码字 96 在 CodeB 下映射为问号" {
  let img = c1c_image(c1c_px([104, 96, 97, 106], 14), 1)
  match decode_code128(img) {
    Some(r) => assert_true(r.data == "?")
    None => assert_true(false)
  }
}

///|
test "c1c: 99 切 CodeC 再 100 切回 CodeB" {
  let img = c1c_image(c1c_px([104, 99, 12, 100, 65, 66, 106], 14), 1)
  match decode_code128(img) {
    Some(r) => assert_true(r.data == "12a")
    None => assert_true(false)
  }
}

///|
test "c1c: 码字不足两条返回 None" {
  let img = c1c_image(c1c_px([104, 106], 14), 1)
  match decode_code128(img) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  // 起始符后全是空白，码字匹配失败直接 break
  let blank = c1c_image(c1c_px([104], 44), 1)
  match decode_code128(blank) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "c1c: 条空模式越界返回 false" {
  let line : Array[Int32] = [1, 0, 1]
  assert_true(!match_bar_pattern(line, 1, [2, 1, 1, 4, 1, 2]))
  assert_true(match_bar_pattern(line, 0, [1, 1, 1]))
}

///|
test "c1c: Code39 只吃终止符时返回 None" {
  let px = c1c_px(code39_start_pattern, 24)
  let img = c1c_image(px, 1)
  match decode_code39(img) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}
