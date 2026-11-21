///|
/// 5×7 数字点阵（每字符 7 行，每行 5 位；1 = 墨迹）。
pub fn digit_glyph(d : Int32) -> Array[Int32] {
  match d {
    0 => [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110]
    1 => [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110]
    2 => [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111]
    3 => [0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110]
    4 => [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010]
    5 => [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110]
    6 => [0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110]
    7 => [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000]
    8 => [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110]
    9 => [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100]
    _ => [0, 0, 0, 0, 0, 0, 0]
  }
}

///|
/// 把数字序列渲染成灰度图（白底 255 / 黑字 0）。
/// scale：每像素放大倍数；margin：四周留白（模块数）。
pub fn render_digits(
  digits : Array[Int32],
  scale~ : Int32 = 4,
  margin~ : Int32 = 4,
) -> @types.Image {
  let s = if scale < 1 { 1 } else { scale }
  let m = if margin < 0 { 0 } else { margin }
  let n = digits.length()
  let glyph_w = 5
  let glyph_h = 7
  let spacing = 1
  let inner_w = if n == 0 { 1 } else { n * (glyph_w + spacing) - spacing }
  let w = (inner_w + 2 * m) * s
  let h = (glyph_h + 2 * m) * s
  let data : Array[Byte] = Array::make(w * h, b'\xFF')
  for gi in 0..<n {
    let glyph = digit_glyph(digits[gi])
    for row in 0..<glyph_h {
      for col in 0..<glyph_w {
        let on = ((glyph[row] >> (glyph_w - 1 - col)) & 1) == 1
        if on {
          for dy in 0..<s {
            for dx in 0..<s {
              let px = (m + gi * (glyph_w + spacing) + col) * s + dx
              let py = (m + row) * s + dy
              data[py * w + px] = b'\x00'
            }
          }
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
