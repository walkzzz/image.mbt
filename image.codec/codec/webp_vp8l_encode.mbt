///|
/// # WebP VP8L 无损编码器（M1：literal-only）
///
/// 规范：RFC 9649 §3（WebP Lossless Bitstream）
/// 里程碑：M1 = 合法容器 + 5 棵前缀码 + literal 像素，产物可被标准解码器逐字节还原。
/// 尚未实现（见 docs/webp-encoder.md）：LZ77（M2）、subtract-green/predictor/色彩缓存（M3）。
///
/// 设计取舍：
/// - 位序 LSB-first，与 `webp_decode.mbt` 的 `BitReader` 一致；
/// - Huffman 码按 canonical 规则计算后**按位反转**写入（解码器 MSB-first 累积），
///   因此 8 位符号码等于 `vp8l_reverse8(value)`；
/// - 绿树字母表 280（256 literal + 24 长度码），必须写满，否则解码器会越界读下一棵树；
/// - simple 码表里单符号 >1 时必须置 `is_first_8bits=1` 用 8 位写，否则值被截成 1 位。

///|
/// VP8L 位写入器（LSB-first）
priv struct Vp8lBits {
  bytes : Array[Byte]
  mut cur : Int32
  mut nbits : Int32
}

///|
fn Vp8lBits::new() -> Vp8lBits {
  { bytes: [], cur: 0, nbits: 0, }
}

///|
/// 写入 `n` 位（低位先出）
fn Vp8lBits::write(self : Vp8lBits, value : Int32, n : Int32) -> Unit {
  for i in 0..<n {
    let bit = (value >> i) & 1
    self.cur = self.cur | (bit << self.nbits)
    self.nbits = self.nbits + 1
    if self.nbits == 8 {
      self.bytes.push(self.cur.to_byte())
      self.cur = 0
      self.nbits = 0
    }
  }
}

///|
/// 收尾：补齐最后一个字节并返回
fn Vp8lBits::finish(self : Vp8lBits) -> Bytes {
  if self.nbits > 0 {
    self.bytes.push(self.cur.to_byte())
    self.cur = 0
    self.nbits = 0
  }
  Bytes::from_array(self.bytes)
}

///|
/// 8 位反转（canonical 码按 MSB-first 由解码器累积，写入前需反转）
fn vp8l_reverse8(v : Int32) -> Int32 {
  let mut r = 0
  for i in 0..<8 {
    r = r | (((v >> i) & 1) << (7 - i))
  }
  r
}

///|
/// 码长码的写入顺序（RFC 9649 §3.2.1）
let vp8l_code_length_order : Array[Int32] = [
  17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
]

///|
/// 写一棵"前 256 个符号长 8、其余长 0"的 normal 码表。
///
/// 码长码只用 `{8, 18}` 两个符号：`8` 表示长度 8，`18` 表示 11–138 个长度为 0 的符号。
/// 两符号各 1 位，Kraft 和 = 1，解码器可直接建表。
/// `alphabet_size` 为绿树时传 280，红/蓝树传 256。
fn vp8l_write_flat8_normal_code(w : Vp8lBits, alphabet_size : Int32) -> Unit {
  w.write(0, 1)
  // num_code_lengths = 4 + ReadBits(4)；写 8 得到 12，覆盖 order[0..11]（含 16 与 8）
  w.write(8, 4)
  for i in 0..<12 {
    let sym = vp8l_code_length_order[i]
    w.write(if sym == 8 || sym == 18 { 1 } else { 0 }, 3)
  }
  // max_symbol 标志 0 = 读满整个字母表
  w.write(0, 1)
  // 256 个符号长度 8：码长码符号 8 的码是 0，写 256 个 0 位
  for _ in 0..<256 {
    w.write(0, 1)
  }
  // 余下符号长度 0：符号 18 的码是 1，附加 7 位写 "个数 - 11"
  let mut zeros = alphabet_size - 256
  while zeros > 0 {
    let take = if zeros > 138 { 138 } else { zeros }
    w.write(1, 1)
    w.write(take - 11, 7)
    zeros = zeros - take
  }
}

///|
/// 写一棵单符号 simple 码表（0 位/符号）。
/// 符号 >1 时必须用 8 位写，否则会被截断成 1 位值。
fn vp8l_write_simple_single(w : Vp8lBits, symbol : Int32) -> Unit {
  w.write(1, 1)
  w.write(0, 1)
  if symbol > 1 {
    w.write(1, 1)
    w.write(symbol, 8)
  } else {
    w.write(0, 1)
    w.write(symbol, 1)
  }
}

///|
/// 把 VP8L 载荷包进 RIFF/WEBP 容器
fn vp8l_wrap_riff(payload : Bytes) -> Bytes {
  let out : Array[Byte] = []
  out.push(0x52)
  out.push(0x49)
  out.push(0x46)
  out.push(0x46)
  let pad = payload.length() % 2
  write_u32_le(out, 4 + 8 + payload.length() + pad)
  out.push(0x57)
  out.push(0x45)
  out.push(0x42)
  out.push(0x50)
  out.push(0x56)
  out.push(0x50)
  out.push(0x38)
  out.push(0x4C)
  write_u32_le(out, payload.length())
  for b in payload {
    out.push(b)
  }
  if pad != 0 {
    out.push(0)
  }
  Bytes::from_array(out)
}

///|
/// M1 编码器：literal-only 的合法 VP8L 产物。
///
/// 参数：`img` 支持 channels = 3（RGB）或 4（RGBA）；尺寸上限 16384。
/// 返回：完整的 RIFF/WEBP 字节流（单 VP8L chunk）。
///
/// 注意：本实现体积约 3 字节/像素（劣于 PNG），LZ77 与变换完成后才会优于 PNG。
/// 当前仅供内部验证与 M2/M3 基线，不作为对外 API 承诺。
///
/// ```moonbit nocheck
/// let bytes = @codec.encode_webp_vp8l_literal(img)
/// ```
pub fn encode_webp_vp8l_literal(
  img : @types.Image,
) -> Bytes raise @types.LoadError {
  let w = img.width.to_int()
  let h = img.height.to_int()
  if w <= 0 || h <= 0 {
    raise @types.LoadError::DecodeFailed("WebP 编码：图像尺寸无效")
  }
  if w > 16384 || h > 16384 {
    raise @types.LoadError::DecodeFailed(
      "WebP 编码：尺寸超出 VP8L 上限 16384",
    )
  }
  let ch = img.channels.to_int()
  if ch != 3 && ch != 4 {
    raise @types.LoadError::DecodeFailed("WebP 编码：仅支持 3/4 通道")
  }
  let bw = Vp8lBits::new()
  bw.write(0x2F, 8)
  bw.write(w - 1, 14)
  bw.write(h - 1, 14)
  bw.write(1, 1) // alpha_is_used
  bw.write(0, 3) // version
  bw.write(0, 1) // 无 transform
  bw.write(0, 1) // 无色彩缓存
  bw.write(0, 1) // 单 meta 前缀码组
  // alpha 是否全不透明：全不透明时用单符号码表，省掉每像素 8 位
  let mut all_solid_alpha = true
  if ch == 4 {
    for i in 0..<(w * h) {
      if img.data[i * 4 + 3].to_int() != 255 {
        all_solid_alpha = false
        break
      }
    }
  }
  vp8l_write_flat8_normal_code(bw, 280)
  vp8l_write_flat8_normal_code(bw, 256)
  vp8l_write_flat8_normal_code(bw, 256)
  if all_solid_alpha {
    vp8l_write_simple_single(bw, 255)
  } else {
    vp8l_write_flat8_normal_code(bw, 256)
  }
  vp8l_write_simple_single(bw, 0) // 距离码（literal-only 不使用）
  for i in 0..<(w * h) {
    let base = i * ch
    let r = img.data[base].to_int()
    let g = img.data[base + 1].to_int()
    let b = img.data[base + 2].to_int()
    bw.write(vp8l_reverse8(g), 8)
    bw.write(vp8l_reverse8(r), 8)
    bw.write(vp8l_reverse8(b), 8)
    if !all_solid_alpha {
      bw.write(vp8l_reverse8(img.data[base + 3].to_int()), 8)
    }
  }
  vp8l_wrap_riff(bw.finish())
}
