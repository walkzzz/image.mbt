///|
/// # TGA 编码 TGA Encode
///
/// TGA 图像格式编码
/// TGA 图像格式编码 TGA image format encoding
// 纯 MoonBit TGA 编码（全目标可用：native/wasm/js）
// 未压缩 true-color，top-down origin，BGR / BGRA

///|
/// TGA 编码（纯 MoonBit，全目标可用）。
///
/// 位深由通道数决定：1/2 通道 → 24-bit（灰度复制到 RGB），3 通道 → 24-bit，4 通道 → 32-bit BGRA。
/// 图像描述符按 TGA 规范写：bit5 = top-down origin；bit4（right-to-left）不置位；
/// 低 4 位 = alpha 位深（32-bit 时 8，24-bit 时 0）。
pub fn encode_tga_pure(img : @types.Image) -> Bytes {
  let width = img.width
  let height = img.height
  let channels = img.channels
  let data = img.data
  let bpp = if channels >= 4 { 32 } else { 24 }
  let out : Array[Byte] = []
  // TGA Header (18 bytes)
  out.push(b'\x00') // id length
  out.push(b'\x00') // color map type
  out.push(b'\x02') // image type = uncompressed true-color
  out.push(b'\x00') // color map spec (5)
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00')
  out.push(b'\x00') // x origin (2)
  out.push(b'\x00')
  out.push(b'\x00') // y origin (2)
  out.push(b'\x00')
  out.push((width & 0xFF).to_byte())
  out.push(((width >> 8) & 0xFF).to_byte())
  out.push((height & 0xFF).to_byte())
  out.push(((height >> 8) & 0xFF).to_byte())
  out.push(bpp.to_byte())
  // 描述符：bit5 = 1（top-down），低 4 位 = alpha 位深（32-bit 为 8）
  out.push(if bpp == 32 { b'\x28' } else { b'\x20' })
  // Pixel data (top-down, BGR(A))
  // 无 raise 签名：像素缓冲区短于声明尺寸时按可用像素数截断写入，不越界 panic
  let ch = if channels < 1 { 1 } else { channels }
  let px_total = width * height
  let avail_px = data.length() / ch
  let n_px = if avail_px < px_total { avail_px } else { px_total }
  let mut i = 0
  while i < n_px {
    let idx = i * ch
    let r = data[idx].to_int()
    let g = if ch >= 2 { data[idx + 1].to_int() } else { r }
    let b = if ch >= 3 { data[idx + 2].to_int() } else { r }
    out.push(b.to_byte())
    out.push(g.to_byte())
    out.push(r.to_byte())
    if bpp == 32 {
      out.push(data[idx + 3])
    }
    i += 1
  }
  Bytes::from_array(out)
}
