///|
/// 用同包 EAN-13 编码表渲染条码图（1 = 黑条）。
fn wb_render_ean13(digits : Array[Int32], module_px : Int32) -> @types.Image {
  let parity = ean13_parity_patterns[digits[0]]
  let modules : Array[Int32] = []
  // 起始保护条 101
  modules.push(1)
  modules.push(0)
  modules.push(1)
  // 左侧 6 位（L/G 由首位 parity 决定）
  for i in 0..<6 {
    let d = digits[1 + i]
    let code = if parity[i] == 0 { ean13_l_codes[d] } else { ean13_g_codes[d] }
    for v in code {
      modules.push(v)
    }
  }
  // 中央保护条 01010
  for v in [0, 1, 0, 1, 0] {
    modules.push(v)
  }
  // 右侧 6 位（R）
  for i in 0..<6 {
    let d = digits[7 + i]
    for v in ean13_r_codes[d] {
      modules.push(v)
    }
  }
  // 结束保护条 101
  modules.push(1)
  modules.push(0)
  modules.push(1)
  let mp = if module_px < 1 { 1 } else { module_px }
  let h = 40
  let w = modules.length() * mp
  let data : Array[Byte] = Array::make(w * h, b'\xFF')
  for i in 0..<modules.length() {
    if modules[i] == 1 {
      for dy in 0..<h {
        for dx in 0..<mp {
          data[dy * w + i * mp + dx] = b'\x00'
        }
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

///|
test "wbtest: EAN-13 生成 → 解码往返" {
  // 049000012345 + 校验位 7
  let digits : Array[Int32] = [0, 4, 9, 0, 0, 0, 0, 1, 2, 3, 4, 5, 7]
  let img = wb_render_ean13(digits, 1)
  try {
    match decode_ean13(img) {
      Some(r) => assert_eq(r.data, "0490000123457")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}

///|
test "wbtest: UPC-A（前导 0）生成 → 解码往返" {
  let digits : Array[Int32] = [0, 4, 9, 0, 0, 0, 0, 1, 2, 3, 4, 5, 7]
  let img = wb_render_ean13(digits, 1)
  try {
    match decode_upca(img) {
      Some(r) => assert_eq(r.data, "490000123457")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}
