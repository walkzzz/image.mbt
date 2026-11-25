///|
/// # VP8L 通用解码：图像流 + 四种逆变换
///
/// 按 RFC 9649 §3.5 / §3.6 / §3.7 实现：
/// - 图像流：literal / LZ77 / 色彩缓存 / meta 多组前缀码
/// - 逆变换：predictor（14 模式）、color transform、subtract-green、color indexing（含像素打包）
///
/// `decode_webp_vp8l_rfc` 是唯一对外入口，本文件是其实现。

// ==================== 图像流解码 ====================

///|
priv struct Vp8lGroup {
  green : HuffmanTree
  red : HuffmanTree
  blue : HuffmanTree
  alpha : HuffmanTree
  dist : HuffmanTree
}

///|
fn vp8l_div_round_up(num : Int32, den : Int32) -> Int32 {
  (num + den - 1) / den
}

///|
/// 读色彩缓存信息：返回 (code_bits, size)，未启用时都返回 0
fn vp8l_read_cache_info(
  br : BitReader,
) -> (Int32, Int32) raise @types.LoadError {
  if br.read_bit() == 1 {
    let bits = br.read_bits(4)
    if bits < 1 || bits > 11 {
      raise @types.LoadError::DecodeFailed(
        "VP8L：色彩缓存位宽非法（" + bits.to_string() + "）",
      )
    }
    (bits, 1 << bits)
  } else {
    (0, 0)
  }
}

///|
fn vp8l_read_group(
  br : BitReader,
  cache_size : Int32,
) -> Vp8lGroup raise @types.LoadError {
  let green = vp8l_read_prefix_code(br, 256 + 24 + cache_size)
  let red = vp8l_read_prefix_code(br, 256)
  let blue = vp8l_read_prefix_code(br, 256)
  let alpha = vp8l_read_prefix_code(br, 256)
  let dist = vp8l_read_prefix_code(br, 40)
  Vp8lGroup::{ green, red, blue, alpha, dist, }
}

///|
/// 通用图像流解码，返回 `width * height` 个 ARGB 像素。
///
/// `allow_meta = false` 时用于子分辨率图像（变换数据 / 熵图），这类图像没有 meta 多组前缀码。
fn vp8l_decode_stream(
  br : BitReader,
  width : Int32,
  height : Int32,
  allow_meta : Bool,
) -> Array[Int32] raise @types.LoadError {
  let (cache_bits, cache_size) = vp8l_read_cache_info(br)
  let groups : Array[Vp8lGroup] = []
  let meta : Array[Int32] = []
  let mut prefix_bits = 0
  let mut prefix_w = 0
  if allow_meta && br.read_bit() == 1 {
    prefix_bits = br.read_bits(3) + 2
    prefix_w = vp8l_div_round_up(width, 1 << prefix_bits)
    let prefix_h = vp8l_div_round_up(height, 1 << prefix_bits)
    let entropy = vp8l_decode_stream(br, prefix_w, prefix_h, false)
    let mut max_meta = 0
    for k in 0..<entropy.length() {
      let code = (entropy[k] >> 8) & 0xFFFF
      if code > max_meta {
        max_meta = code
      }
    }
    for k in 0..<entropy.length() {
      meta.push(entropy[k])
    }
    for _ in 0..<(max_meta + 1) {
      groups.push(vp8l_read_group(br, cache_size))
    }
  } else {
    groups.push(vp8l_read_group(br, cache_size))
  }
  let n = width * height
  let pixels : Array[Int32] = Array::make(n, 0)
  let cache : Array[Int32] = Array::make(cache_size, 0)
  let mut i = 0
  while i < n {
    let x = i % width
    let y = i / width
    let gi = if prefix_bits > 0 {
      (y >> prefix_bits) * prefix_w + (x >> prefix_bits)
    } else {
      0
    }
    let g = if groups.length() == 0 {
      raise @types.LoadError::DecodeFailed("VP8L：前缀码组缺失")
    } else if meta.length() > 0 {
      let mc = (meta[gi] >> 8) & 0xFFFF
      if mc >= groups.length() {
        raise @types.LoadError::DecodeFailed("VP8L：meta 前缀码越界")
      }
      groups[mc]
    } else {
      groups[0]
    }
    let sym = g.green.decode(br)
    if sym < 256 {
      let r = g.red.decode(br)
      let b = g.blue.decode(br)
      let a = g.alpha.decode(br)
      let argb = (a << 24) | (r << 16) | (sym << 8) | b
      pixels[i] = argb
      if cache_size > 0 {
        cache[vp8l_cache_hash(argb, cache_bits)] = argb
      }
      i += 1
    } else if sym < 280 {
      let length = vp8l_prefix_value(br, sym - 256)
      let dcode = vp8l_prefix_value(br, g.dist.decode(br))
      let d = vp8l_map_distance(dcode, width)
      if d <= 0 || i - d < 0 {
        raise @types.LoadError::DecodeFailed(
          "VP8L：反向引用距离越界 (i=\{i} d=\{d} dcode=\{dcode} sym=\{sym} len=\{length} w=\{width} h=\{height} cache=\{cache_bits} groups=\{groups.length()})",
        )
      }
      let mut k = 0
      while k < length && i < n {
        let argb = pixels[i - d]
        pixels[i] = argb
        if cache_size > 0 {
          cache[vp8l_cache_hash(argb, cache_bits)] = argb
        }
        i += 1
        k += 1
      }
    } else {
      if cache_size == 0 {
        raise @types.LoadError::DecodeFailed(
          "VP8L：出现色彩缓存索引但未启用缓存",
        )
      }
      let idx = sym - 280
      if idx < 0 || idx >= cache_size {
        raise @types.LoadError::DecodeFailed("VP8L：色彩缓存索引越界")
      }
      pixels[i] = cache[idx]
      i += 1
    }
  }
  pixels
}

// ==================== 逆变换 ====================

///|
/// 色彩缓存哈希：RFC 9649 §3.6.2.3 的 (0x1e35a7bd * color) >> (32 - bits)，
/// 按无符号 32 位语义实现（Int32 的算术右移需要补上符号位贡献）。
fn vp8l_cache_hash(argb : Int32, bits : Int32) -> Int32 {
  // libwebp：((argb * 0x1e35a7bd) & 0xffffffff) >> (32 - bits)，即 32 位**无符号**乘法的结果取高 bits 位。
  // Int32 乘法天然按 2^32 回绕，但 `>>` 是算术右移，负数会符号扩展；
  // 用掩码取低 bits 位即可得到与逻辑右移一致的结果（之前用 "+ (1 << bits)" 修补是错的）。
  let prod = argb * 0x1E35A7BD
  (prod >> (32 - bits)) & ((1 << bits) - 1)
}

///|
fn vp8l_c1(argb : Int32, shift : Int32) -> Int32 {
  (argb >> shift) & 0xFF
}

///|
fn vp8l_avg2(a : Int32, b : Int32) -> Int32 {
  ((vp8l_c1(a, 24) + vp8l_c1(b, 24)) >> 1 << 24) |
  ((vp8l_c1(a, 16) + vp8l_c1(b, 16)) >> 1 << 16) |
  ((vp8l_c1(a, 8) + vp8l_c1(b, 8)) >> 1 << 8) |
  ((vp8l_c1(a, 0) + vp8l_c1(b, 0)) >> 1)
}

///|
fn vp8l_clamp8(v : Int32) -> Int32 {
  if v < 0 {
    0
  } else if v > 255 {
    255
  } else {
    v
  }
}

///|
fn vp8l_clamp_add_full(a : Int32, b : Int32, c : Int32) -> Int32 {
  (vp8l_clamp8(vp8l_c1(a, 24) + vp8l_c1(b, 24) - vp8l_c1(c, 24)) << 24) |
  (vp8l_clamp8(vp8l_c1(a, 16) + vp8l_c1(b, 16) - vp8l_c1(c, 16)) << 16) |
  (vp8l_clamp8(vp8l_c1(a, 8) + vp8l_c1(b, 8) - vp8l_c1(c, 8)) << 8) |
  vp8l_clamp8(vp8l_c1(a, 0) + vp8l_c1(b, 0) - vp8l_c1(c, 0))
}

///|
fn vp8l_clamp_add_half(a : Int32, b : Int32) -> Int32 {
  (vp8l_clamp8(vp8l_c1(a, 24) + (vp8l_c1(a, 24) - vp8l_c1(b, 24)) / 2) << 24) |
  (vp8l_clamp8(vp8l_c1(a, 16) + (vp8l_c1(a, 16) - vp8l_c1(b, 16)) / 2) << 16) |
  (vp8l_clamp8(vp8l_c1(a, 8) + (vp8l_c1(a, 8) - vp8l_c1(b, 8)) / 2) << 8) |
  vp8l_clamp8(vp8l_c1(a, 0) + (vp8l_c1(a, 0) - vp8l_c1(b, 0)) / 2)
}

///|
fn vp8l_abs32(v : Int32) -> Int32 {
  if v < 0 {
    -v
  } else {
    v
  }
}

///|

///|
/// Predictor 11 的 Select（RFC §3.5.1 / libwebp `Select(top, left, top_left)`）：
/// |top-top_left| <= |left-top_left| 时取 top，否则取 left。
/// 早期实现把比较方向写反，导致任何用到模式 11 的块像素全错。
/// RFC 9649 §3.5.1 的 Select(L, T, TL)：先算估计值 p = L + T - TL（逐通道、不裁剪），
/// 再看 L 与 T 谁离 p 更近（曼哈顿距离 4 通道求和），返回更近的那个。
/// 之前写成"比较 |L-TL| 与 |T-TL|"是错的，会让所有用到模式 11 的块整体偏色。
fn vp8l_select(l : Int32, t : Int32, tl : Int32) -> Int32 {
  let la = vp8l_c1(l, 24)
  let lr = vp8l_c1(l, 16)
  let lg = vp8l_c1(l, 8)
  let lb = vp8l_c1(l, 0)
  let ta = vp8l_c1(t, 24)
  let tr = vp8l_c1(t, 16)
  let tg = vp8l_c1(t, 8)
  let tb = vp8l_c1(t, 0)
  let tla = vp8l_c1(tl, 24)
  let tlr = vp8l_c1(tl, 16)
  let tlg = vp8l_c1(tl, 8)
  let tlb = vp8l_c1(tl, 0)
  let pa = la + ta - tla
  let pr = lr + tr - tlr
  let pg = lg + tg - tlg
  let pb = lb + tb - tlb
  let dist_l = vp8l_abs32(pa - la) +
    vp8l_abs32(pr - lr) +
    vp8l_abs32(pg - lg) +
    vp8l_abs32(pb - lb)
  let dist_t = vp8l_abs32(pa - ta) +
    vp8l_abs32(pr - tr) +
    vp8l_abs32(pg - tg) +
    vp8l_abs32(pb - tb)
  if dist_l < dist_t {
    l
  } else {
    t
  }
}

///|
/// predictor 逆变换：按 16² 块模式重建（RFC §3.5.1）
fn vp8l_inverse_predictor(
  pixels : Array[Int32],
  width : Int32,
  height : Int32,
  modes : Array[Int32],
  block_bits : Int32,
  mode_width : Int32,
) -> Unit {
  for y in 0..<height {
    for x in 0..<width {
      let i = y * width + x
      let residual = pixels[i]
      let left = if x > 0 { pixels[i - 1] } else { 0 }
      let top = if y > 0 { pixels[i - width] } else { 0 }
      let topleft = if x > 0 && y > 0 { pixels[i - width - 1] } else { 0 }
      let topright = if y > 0 {
        if x + 1 < width {
          pixels[i - width + 1]
        } else {
          pixels[i - x] // 同行的最左像素
        }
      } else {
        0
      }
      let mut pred = 0xFF000000
      if y == 0 && x > 0 {
        pred = left
      } else if x == 0 && y > 0 {
        pred = top
      } else if y > 0 && x > 0 {
        let mi = (y >> block_bits) * mode_width + (x >> block_bits)
        let mode = if mi < modes.length() { (modes[mi] >> 8) & 0xFF } else { 0 }
        pred = match mode {
          0 => 0xFF000000
          1 => left
          2 => top
          3 => topright
          4 => topleft
          5 => vp8l_avg2(vp8l_avg2(left, topright), top)
          6 => vp8l_avg2(left, topleft)
          7 => vp8l_avg2(left, top)
          8 => vp8l_avg2(topleft, top)
          9 => vp8l_avg2(top, topright)
          10 => vp8l_avg2(vp8l_avg2(left, topleft), vp8l_avg2(top, topright))
          11 => vp8l_select(left, top, topleft)
          12 => vp8l_clamp_add_full(left, top, topleft)
          _ => vp8l_clamp_add_half(vp8l_avg2(left, top), topleft)
        }
      }
      let a = (vp8l_c1(residual, 24) + vp8l_c1(pred, 24)) & 0xFF
      let r = (vp8l_c1(residual, 16) + vp8l_c1(pred, 16)) & 0xFF
      let g = (vp8l_c1(residual, 8) + vp8l_c1(pred, 8)) & 0xFF
      let b = (vp8l_c1(residual, 0) + vp8l_c1(pred, 0)) & 0xFF
      pixels[i] = (a << 24) | (r << 16) | (g << 8) | b
    }
  }
}

///|
/// cross-color 逆变换（RFC §3.5.2）
fn vp8l_color_delta(t : Int32, c : Int32) -> Int32 {
  let tt = if t >= 128 { t - 256 } else { t }
  let cc = if c >= 128 { c - 256 } else { c }
  (tt * cc) >> 5
}

///|
fn vp8l_inverse_color_transform(
  pixels : Array[Int32],
  width : Int32,
  height : Int32,
  cte : Array[Int32],
  block_bits : Int32,
  mode_width : Int32,
) -> Unit {
  for y in 0..<height {
    for x in 0..<width {
      let i = y * width + x
      let mi = (y >> block_bits) * mode_width + (x >> block_bits)
      if mi >= cte.length() {
        continue
      }
      let e = cte[mi]
      let green_to_red = vp8l_c1(e, 0)
      let green_to_blue = vp8l_c1(e, 8)
      let red_to_blue = vp8l_c1(e, 16)
      let argb = pixels[i]
      let g = vp8l_c1(argb, 8)
      let r = (vp8l_c1(argb, 16) + vp8l_color_delta(green_to_red, g)) & 0xFF
      let b = (
          vp8l_c1(argb, 0) +
          vp8l_color_delta(green_to_blue, g) +
          vp8l_color_delta(red_to_blue, r)
        ) &
        0xFF
      pixels[i] = (vp8l_c1(argb, 24) << 24) |
        (r << 16) |
        (vp8l_c1(argb, 8) << 8) |
        b
    }
  }
}

///|
/// color indexing 逆变换：解像素打包 + 调色板查表（RFC §3.5.4）
///
/// 返回展开后的像素数组，通过 `out_width` 输出新宽度。
fn vp8l_inverse_color_indexing(
  pixels : Array[Int32],
  width : Int32,
  height : Int32,
  palette : Array[Int32],
  width_bits : Int32,
  orig_width : Int32,
) -> (Array[Int32], Int32) {
  // 未打包：逐像素查表
  if width_bits == 0 {
    let out : Array[Int32] = Array::make(pixels.length(), 0)
    for i in 0..<pixels.length() {
      let idx = vp8l_c1(pixels[i], 8)
      out[i] = if idx < palette.length() { palette[idx] } else { 0 }
    }
    return (out, width)
  }
  let bundle = 1 << width_bits // 每个打包像素承载的索引个数：2 / 4 / 8
  let bits_per = 8 >> width_bits // 每个索引占的位宽：4 / 2 / 1
  let mask = (1 << bits_per) - 1
  // 关键：还原宽度是**原图宽**，不是 width * bundle——最后一组可能只用了前几个槽
  // （4 像素图 + width_bits=3 时 subsample 宽 1，展开应是 4 而不是 8）。
  let out_width = orig_width
  let out : Array[Int32] = Array::make(out_width * height, 0)
  for y in 0..<height {
    for x in 0..<out_width {
      let sx = x / bundle
      let j = x % bundle
      let packed = vp8l_c1(pixels[y * width + sx], 8)
      let idx = (packed >> (j * bits_per)) & mask
      out[y * out_width + x] = if idx < palette.length() {
        palette[idx]
      } else {
        0
      }
    }
  }
  (out, out_width)
}

// ==================== 对外入口 ====================

///|
/// RFC 合规的 VP8L 解码：图像流（literal / LZ77 / 色彩缓存 / meta 多组）
/// + 四类逆变换（predictor / cross-color / subtract-green / color indexing）。
///
/// 返回 channels = 4（本实现始终输出 RGBA）。
pub fn decode_webp_vp8l_rfc(
  data : Bytes,
) -> @types.Image raise @types.LoadError {
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
  let pre_widths : Array[Int32] = []
  let mut cur_w = width
  while br.read_bit() == 1 {
    let t = br.read_bits(2)
    let pre_w = cur_w
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
      pre_widths.push(pre_w)
    } else if t == 2 {
      kinds.push(2)
      block_bits.push(0)
      mode_widths.push(0)
      aux.push([])
      width_bits.push(0)
      pre_widths.push(pre_w)
    } else {
      let nc = br.read_bits(8) + 1
      let table = vp8l_decode_stream(br, nc, 1, false)
      for k in 1..<nc {
        let prev = table[k - 1]
        let cur0 = table[k]
        let a = ((vp8l_c1(cur0, 24) + vp8l_c1(prev, 24)) & 0xFF) << 24
        let r = ((vp8l_c1(cur0, 16) + vp8l_c1(prev, 16)) & 0xFF) << 16
        let g = ((vp8l_c1(cur0, 8) + vp8l_c1(prev, 8)) & 0xFF) << 8
        let b = (vp8l_c1(cur0, 0) + vp8l_c1(prev, 0)) & 0xFF
        table[k] = a | r | g | b
      }
      let wb = if nc <= 2 {
        3
      } else if nc <= 4 {
        2
      } else if nc <= 16 {
        1
      } else {
        0
      }
      kinds.push(3)
      block_bits.push(0)
      mode_widths.push(0)
      aux.push(table)
      width_bits.push(wb)
      pre_widths.push(pre_w)
      cur_w = vp8l_div_round_up(cur_w, 1 << wb)
    }
  }
  let mut pixels = vp8l_decode_stream(br, cur_w, height, true)
  let mut w = cur_w
  let mut k = kinds.length() - 1
  while k >= 0 {
    let kind = kinds[k]
    if kind == 0 {
      vp8l_inverse_predictor(
        pixels,
        w,
        height,
        aux[k],
        block_bits[k],
        mode_widths[k],
      )
    } else if kind == 1 {
      vp8l_inverse_color_transform(
        pixels,
        w,
        height,
        aux[k],
        block_bits[k],
        mode_widths[k],
      )
    } else if kind == 2 {
      for i in 0..<(w * height) {
        let argb = pixels[i]
        let g = vp8l_c1(argb, 8)
        let r = (vp8l_c1(argb, 16) + g) & 0xFF
        let b = (vp8l_c1(argb, 0) + g) & 0xFF
        pixels[i] = (vp8l_c1(argb, 24) << 24) | (r << 16) | (g << 8) | b
      }
    } else {
      let (out, nw) = vp8l_inverse_color_indexing(
        pixels,
        w,
        height,
        aux[k],
        width_bits[k],
        pre_widths[k],
      )
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
  let out : Array[Byte] = Array::make(digit * 4, b'\x00')
  for i in 0..<digit {
    let argb = pixels[i]
    out[i * 4] = vp8l_c1(argb, 16).to_byte()
    out[i * 4 + 1] = vp8l_c1(argb, 8).to_byte()
    out[i * 4 + 2] = vp8l_c1(argb, 0).to_byte()
    out[i * 4 + 3] = vp8l_c1(argb, 24).to_byte()
  }
  @types.Image::{ width, height, channels: 4, data: Bytes::from_array(out), }
}

///|
/// WebP 解码入口：统一走 RFC 合规的 VP8L 路径（palette / predictor / cross-color / subtract-green 全部支持）。
pub fn decode_webp_pure(data : Bytes) -> @types.Image raise @types.LoadError {
  decode_webp_vp8l_rfc(data)
}
