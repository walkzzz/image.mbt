///|
/// 用同包 Code128 编码表渲染条码图（1 = 黑条）。codes 为 CodeB 值（ASCII − 32）。
fn wb_render_code128(codes : Array[Int32], module_px : Int32) -> @types.Image {
  let symbols : Array[Int32] = []
  symbols.push(104) // Start B
  for c in codes {
    symbols.push(c)
  }
  // 校验位 = (StartB + Σ code_i × i) % 103
  let mut sum = 104
  let mut idx = 1
  for c in codes {
    sum += c * idx
    idx += 1
  }
  symbols.push(sum % 103)
  symbols.push(106) // Stop
  let mp = if module_px < 1 { 1 } else { module_px }
  let modules : Array[Int32] = []
  for s in symbols {
    let pattern = code128_patterns[s]
    for ei in 0..<pattern.length() {
      let is_bar = ei % 2 == 0
      for _ in 0..<pattern[ei] {
        modules.push(if is_bar { 1 } else { 0 })
      }
    }
  }
  // Stop 后补终止条
  modules.push(1)
  modules.push(1)
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
test "wbtest: Code128 生成 → 解码往返 HELLO" {
  // CodeB 值：H=40, E=37, L=44, L=44, O=47
  let img = wb_render_code128([40, 37, 44, 44, 47], 1)
  try {
    match decode_code128(img) {
      Some(r) => assert_eq(r.data, "HELLO")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}

///|
test "wbtest: Code128 数字串往返" {
  // 数字：'1'=17, '2'=18, '3'=19
  let img = wb_render_code128([17, 18, 19], 1)
  try {
    match decode_code128(img) {
      Some(r) => assert_eq(r.data, "123")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}
