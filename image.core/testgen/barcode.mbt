///|
/// Code39 字符表（与 image.codec/barcode/linear_barcodes.mbt 解码器保持一致）。
pub let code39_chars : Array[String] = [
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
  "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
  "W", "X", "Y", "Z", "-", ".", " ", "$", "/", "+", "%",
]

///|
/// Code39 条空模式：9 个元素（5 条 4 空），1 = 窄、2 = 宽。
pub let code39_patterns : Array[Array[Int32]] = [
  [1, 1, 1, 2, 2, 1, 2, 1, 1],
  [2, 1, 1, 2, 1, 1, 1, 1, 2],
  [1, 1, 2, 2, 1, 1, 1, 1, 2],
  [2, 1, 2, 2, 1, 1, 1, 1, 1],
  [1, 1, 1, 2, 2, 1, 1, 1, 2],
  [2, 1, 1, 2, 2, 1, 1, 1, 1],
  [1, 1, 2, 2, 2, 1, 1, 1, 1],
  [1, 1, 1, 2, 1, 1, 2, 1, 2],
  [2, 1, 1, 2, 1, 1, 2, 1, 1],
  [1, 1, 2, 2, 1, 1, 2, 1, 1],
  [2, 1, 1, 1, 1, 2, 1, 1, 2],
  [1, 1, 2, 1, 1, 2, 1, 1, 2],
  [2, 1, 2, 1, 1, 2, 1, 1, 1],
  [1, 1, 1, 1, 2, 2, 1, 1, 2],
  [2, 1, 1, 1, 2, 2, 1, 1, 1],
  [1, 1, 2, 1, 2, 2, 1, 1, 1],
  [1, 1, 1, 1, 1, 2, 2, 1, 2],
  [2, 1, 1, 1, 1, 2, 2, 1, 1],
  [1, 1, 2, 1, 1, 2, 2, 1, 1],
  [1, 1, 1, 1, 2, 2, 2, 1, 1],
  [2, 1, 1, 1, 1, 1, 1, 2, 2],
  [1, 1, 2, 1, 1, 1, 1, 2, 2],
  [2, 1, 2, 1, 1, 1, 1, 2, 1],
  [1, 1, 1, 1, 2, 1, 1, 2, 2],
  [2, 1, 1, 1, 2, 1, 1, 2, 1],
  [1, 1, 2, 1, 2, 1, 1, 2, 1],
  [1, 1, 1, 1, 1, 1, 2, 2, 2],
  [2, 1, 1, 1, 1, 1, 2, 2, 1],
  [1, 1, 2, 1, 1, 1, 2, 2, 1],
  [1, 1, 1, 1, 2, 1, 2, 2, 1],
  [2, 2, 1, 1, 1, 1, 1, 1, 2],
  [1, 2, 2, 1, 1, 1, 1, 1, 2],
  [2, 2, 2, 1, 1, 1, 1, 1, 1],
  [1, 2, 1, 1, 2, 1, 1, 1, 2],
  [2, 2, 1, 1, 2, 1, 1, 1, 1],
  [1, 2, 2, 1, 2, 1, 1, 1, 1],
  [1, 2, 1, 1, 1, 1, 2, 1, 2],
  [2, 2, 1, 1, 1, 1, 2, 1, 1],
  [1, 2, 2, 1, 1, 1, 2, 1, 1],
  [1, 2, 1, 2, 1, 2, 1, 1, 1],
  [1, 2, 1, 2, 1, 1, 1, 2, 1],
  [1, 2, 1, 1, 1, 2, 1, 2, 1],
  [1, 1, 1, 2, 1, 2, 1, 2, 1],
]

///|
/// Code39 起始/终止符 '*' 的模式。
pub let code39_start_pattern : Array[Int32] = [1, 2, 1, 1, 2, 1, 2, 1, 1]

///|
/// 按字符索引（0..42）渲染 Code39 条码为灰度图（白底 255 / 黑条 0）。
/// codes 中的非法索引会被跳过。module_px 为窄模块像素宽度。
pub fn render_code39(
  codes : Array[Int32],
  module_px~ : Int32 = 2,
  height~ : Int32 = 40,
) -> @types.Image {
  let mp = if module_px < 1 { 1 } else { module_px }
  let patterns : Array[Array[Int32]] = []
  patterns.push(code39_start_pattern)
  for c in codes {
    if c >= 0 && c < code39_patterns.length() {
      patterns.push(code39_patterns[c])
    }
  }
  patterns.push(code39_start_pattern)
  let mut bars_w = 0
  for p in patterns {
    for w in p {
      bars_w += w
    }
  }
  let total_modules = bars_w + patterns.length() - 1
  let w = (total_modules + 2) * mp
  let h = if height < 2 { 2 } else { height }
  let data : Array[Byte] = Array::make(w * h, b'\xFF')
  let mut x = mp
  for ci in 0..<patterns.length() {
    let p = patterns[ci]
    for ei in 0..<p.length() {
      let run = p[ei] * mp
      let is_bar = ei % 2 == 0
      if is_bar {
        for dy in 0..<h {
          for dx in 0..<run {
            data[dy * w + x + dx] = b'\x00'
          }
        }
      }
      x += run
    }
    if ci < patterns.length() - 1 {
      x += mp
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}
