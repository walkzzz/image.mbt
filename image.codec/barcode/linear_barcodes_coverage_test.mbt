// 覆盖率测试：线性条码（Code128 / Code39 / 通用识别）—— 合成图形驱动

///|
/// 把「条/空宽度序列」展开成像素序列（第 0 个元素视为黑条宽度）
fn lb_runs_px(widths : Array[Int32]) -> Array[Int32] {
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

fn lb_cat(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for v in a {
    out.push(v)
  }
  for v in b {
    out.push(v)
  }
  out
}

fn lb_zeros(px : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for v in px {
    out.push(v)
  }
  for _i in 0..<n {
    out.push(0)
  }
  out
}

///|
/// 由像素序列生成条形码图像（1 = 黑条）
fn lb_from_px(px : Array[Int32], h : Int32) -> @types.Image {
  let w = px.length()
  let data : Array[Byte] = Array::make(w * h, b'\xFF')
  for y in 0..<h {
    for x in 0..<w {
      if px[x] == 1 {
        data[y * w + x] = b'\x00'
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

fn lb_blank(w : Int32, h : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, b'\xFF')),
  }
}

test "lbcov: Code128 合成图形解码" {
  // Start B(104) + 数据 33('A') + 校验 69 + Stop(106) + 终止条 + 空白区
  let px = lb_cat(
    lb_runs_px([2, 1, 1, 2, 1, 4]),
    lb_cat(
      lb_runs_px([1, 1, 1, 3, 2, 3]),
      lb_cat(
        lb_runs_px([1, 1, 2, 2, 1, 4]),
        lb_cat(lb_runs_px([2, 1, 1, 2, 2, 3]), [1, 1]),
      ),
    ),
  )
  let img = lb_from_px(lb_zeros(px, 20), 4)
  match @barcode.decode_code128(img) {
    Some(v) => {
      assert_true(v.data == "A")
      assert_true(v.barcode_type == @barcode.BarcodeType::Code128)
      assert_true(v.confidence == 0.9)
      assert_true(v.x >= 0)
      assert_true(v.width > 0)
    }
    None => assert_true(false)
  }
  // 空白图 → None
  match @barcode.decode_code128(lb_blank(64, 4)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  // 校验位错误 → confidence 0.5（仍返回结果）
  let px2 = lb_cat(
    lb_runs_px([2, 1, 1, 2, 1, 4]),
    lb_cat(
      lb_runs_px([1, 1, 1, 3, 2, 3]),
      lb_cat(
        lb_runs_px([1, 1, 1, 3, 2, 3]),
        lb_cat(lb_runs_px([2, 1, 1, 2, 2, 3]), [1, 1]),
      ),
    ),
  )
  match @barcode.decode_code128(lb_from_px(lb_zeros(px2, 20), 4)) {
    Some(v) => assert_true(v.confidence == 0.5)
    None => assert_true(false)
  }
}

test "lbcov: Code39 合成图形解码" {
  // * + '1' + *
  let px = lb_cat(
    lb_runs_px([1, 2, 1, 1, 2, 1, 2, 1, 1]),
    lb_cat(
      lb_runs_px([2, 1, 1, 2, 1, 1, 1, 1, 2]),
      lb_cat(lb_runs_px([1, 2, 1, 1, 2, 1, 2, 1, 1]), [0]),
    ),
  )
  let img = lb_from_px(lb_zeros(px, 20), 4)
  match @barcode.decode_code39(img) {
    Some(v) => {
      assert_true(v.data == "1")
      assert_true(v.confidence == 0.8)
    }
    None => assert_true(false)
  }
  // 空白图 → None
  match @barcode.decode_code39(lb_blank(64, 4)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

test "lbcov: 通用一维码识别与 UPC-A" {
  let px = lb_cat(
    lb_runs_px([1, 2, 1, 1, 2, 1, 2, 1, 1]),
    lb_cat(
      lb_runs_px([2, 1, 1, 2, 1, 1, 1, 1, 2]),
      lb_cat(lb_runs_px([1, 2, 1, 1, 2, 1, 2, 1, 1]), [0]),
    ),
  )
  let img = lb_from_px(lb_zeros(px, 30), 4)
  let rs = @barcode.decode_linear_barcode(img)
  assert_true(rs.length() >= 1)
  // 空白图 → 0 个结果
  let rs0 = @barcode.decode_linear_barcode(lb_blank(120, 4))
  assert_true(rs0.length() == 0)
  // UPC-A：空白 → None
  match @barcode.decode_upca(lb_blank(120, 4)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  let _upca = @barcode.decode_upca(img)
  // 错误分支
  try {
    let _ = @barcode.decode_linear_barcode(
      @types.Image::{
        width: 0,
        height: 4,
        channels: 1,
        data: Bytes::from_array([]),
      },
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @barcode.decode_linear_barcode(
      @types.Image::{
        width: 2,
        height: 2,
        channels: 1,
        data: Bytes::from_array([b'\x00']),
      },
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
