// 把 decode_webp_vp8l_rfc 主入口迁到 webp_vp8l_transforms.mbt，并修正色彩缓存哈希
import fs from "node:fs";

const p1 = "image.codec/codec/webp_vp8l_transforms.mbt";
let t1 = fs.readFileSync(p1, "utf8");

const hashHelper = `///|
/// 色彩缓存哈希：RFC 9649 §3.6.2.3 的 (0x1e35a7bd * color) >> (32 - bits)，
/// 按无符号 32 位语义实现（Int32 的算术右移需要补上符号位贡献）。
fn vp8l_cache_hash(argb : Int32, bits : Int32) -> Int32 {
  let prod = argb * 0x1E35A7BD
  let raw = prod >> (32 - bits)
  if prod < 0 { raw + (1 << bits) } else { raw }
}

///|
fn vp8l_c1(argb : Int32, shift : Int32) -> Int32 {`;
t1 = t1.replace(`///|
fn vp8l_c1(argb : Int32, shift : Int32) -> Int32 {`, hashHelper);

t1 = t1.replace(
  `        cache[((argb * 0x1E35A7BD) & 0xFFFFFFFF) >> (32 - cache_bits)] = argb
      }
      i += 1
    } else if sym < 280 {`,
  `        cache[vp8l_cache_hash(argb, cache_bits)] = argb
      }
      i += 1
    } else if sym < 280 {`,
);
t1 = t1.replace(
  `          cache[((argb * 0x1E35A7BD) & 0xFFFFFFFF) >> (32 - cache_bits)] = argb
        }
        i += 1
        k += 1`,
  `          cache[vp8l_cache_hash(argb, cache_bits)] = argb
        }
        i += 1
        k += 1`,
);

const mainFn = `
// ==================== 对外入口 ====================

///|
/// RFC 合规的 VP8L 解码：图像流（literal / LZ77 / 色彩缓存 / meta 多组）
/// + 四类逆变换（predictor / cross-color / subtract-green / color indexing）。
///
/// 返回 channels = 4（本实现始终输出 RGBA）。
pub fn decode_webp_vp8l_rfc(data : Bytes) -> @types.Image raise @types.LoadError {
  let len = data.length()
  if len < 16 {
    raise @types.LoadError::DecodeFailed("VP8L：数据过短")
  }
  if data[0].to_int() != 0x52 || data[8].to_int() != 0x57 {
    raise @types.LoadError::DecodeFailed("VP8L：RIFF/WEBP 容器无效")
  }
  let start = vp8l_find_chunk(data, 0x4C385056)
  if start < 0 {
    raise @types.LoadError::DecodeFailed("VP8L：未找到 VP8L chunk")
  }
  if data[start].to_int() != 0x2F {
    raise @types.LoadError::DecodeFailed("VP8L：签名不是 0x2F")
  }
  let br = BitReader::new(data, start + 1)
  let width = br.read_bits(14) + 1
  let height = br.read_bits(14) + 1
  let alpha_used = br.read_bit()
  let version = br.read_bits(3)
  if width <= 0 || height <= 0 || width > 16384 || height > 16384 {
    raise @types.LoadError::DecodeFailed("VP8L：尺寸无效")
  }
  if version != 0 {
    raise @types.LoadError::DecodeFailed("VP8L：version 必须为 0")
  }
  let kinds : Array[Int32] = []
  let block_bits : Array[Int32] = []
  let mode_widths : Array[Int32] = []
  let aux : Array[Array[Int32]] = []
  let width_bits : Array[Int32] = []
  let mut cur_w = width
  while br.read_bit() == 1 {
    let t = br.read_bits(2)
    if t == 0 || t == 1 {
      let sb = br.read_bits(3) + 2
      let mw = vp8l_div_round_up(cur_w, 1 << sb)
      let mh = vp8l_div_round_up(height, 1 << sb)
      let img = vp8l_decode_stream(br, mw, mh, false)
      kinds.push(t)
      block_bits.push(sb)
      mode_widths.push(mw)
      aux.push(img)
      width_bits.push(0)
    } else if t == 2 {
      kinds.push(2)
      block_bits.push(0)
      mode_widths.push(0)
      aux.push([])
      width_bits.push(0)
    } else {
      let nc = br.read_bits(8) + 1
      let table = vp8l_decode_stream(br, nc, 1, false)
      for k in 1..<nc {
        let prev = table[(k - 1) as Int]
        let cur0 = table[k as Int]
        let a = ((vp8l_c1(cur0, 24) + vp8l_c1(prev, 24)) & 0xFF) << 24
        let r = ((vp8l_c1(cur0, 16) + vp8l_c1(prev, 16)) & 0xFF) << 16
        let g = ((vp8l_c1(cur0, 8) + vp8l_c1(prev, 8)) & 0xFF) << 8
        let b = (vp8l_c1(cur0, 0) + vp8l_c1(prev, 0)) & 0xFF
        table[k as Int] = a | r | g | b
      }
      let wb = if nc <= 2 { 3 } else if nc <= 4 { 2 } else if nc <= 16 { 1 } else { 0 }
      kinds.push(3)
      block_bits.push(0)
      mode_widths.push(0)
      aux.push(table)
      width_bits.push(wb)
      cur_w = vp8l_div_round_up(cur_w, 1 << wb)
    }
  }
  let mut pixels = vp8l_decode_stream(br, cur_w, height, true)
  let mut w = cur_w
  let mut k = kinds.length() - 1
  while k >= 0 {
    let kind = kinds[k]
    if kind == 0 {
      vp8l_inverse_predictor(pixels, w, height, aux[k], block_bits[k], mode_widths[k])
    } else if kind == 1 {
      vp8l_inverse_color_transform(pixels, w, height, aux[k], block_bits[k], mode_widths[k])
    } else if kind == 2 {
      for i in 0..<(w * height) as Int {
        let argb = pixels[i]
        let g = vp8l_c1(argb, 8)
        let r = (vp8l_c1(argb, 16) + g) & 0xFF
        let b = (vp8l_c1(argb, 0) + g) & 0xFF
        pixels[i] = (vp8l_c1(argb, 24) << 24) | (r << 16) | (g << 8) | b
      }
    } else {
      let (out, nw) = vp8l_inverse_color_indexing(pixels, w, height, aux[k], width_bits[k])
      pixels = out
      w = nw
    }
    k -= 1
  }
  if w != width {
    raise @types.LoadError::DecodeFailed("VP8L：逆变换后宽度未复原")
  }
  let _ = alpha_used
  @types.check_dims(width, height, 4)
  let digit = width * height
  let out : Array[Byte] = Array::make((digit * 4) as Int, b'\\x00')
  for i in 0..<digit as Int {
    let argb = pixels[i]
    out[i * 4] = vp8l_c1(argb, 16).to_byte()
    out[i * 4 + 1] = vp8l_c1(argb, 8).to_byte()
    out[i * 4 + 2] = vp8l_c1(argb, 0).to_byte()
    out[i * 4 + 3] = vp8l_c1(argb, 24).to_byte()
  }
  @types.Image::{ width, height, channels: 4, data: Bytes::from_array(out) }
}
`;

t1 = t1.trimEnd() + "\n" + mainFn;
fs.writeFileSync(p1, t1, "utf8");

// 删除旧入口（从注释头到文件末尾）
const p2 = "image.codec/codec/webp_vp8l_decode_rfc.mbt";
let t2 = fs.readFileSync(p2, "utf8");
const marker = "///|\n/// RFC 合规的 VP8L 解码：";
const idx = t2.indexOf(marker);
if (idx < 0) throw new Error("old entry not found");
t2 = t2.slice(0, idx).trimEnd() + "\n";
fs.writeFileSync(p2, t2, "utf8");
console.log("migrated entry to transforms file");
