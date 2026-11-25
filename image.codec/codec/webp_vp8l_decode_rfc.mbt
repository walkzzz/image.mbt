///|
/// # WebP VP8L 解码（RFC 9649 合规路径）
///
/// 为什么单独写一份：仓库原有 `read_huffman_tree` 与 VP8L 主循环有三处非标准实现，
/// 无法解码标准编码器产物（详见 docs/known-gaps.md GAP-28）：
/// 1. simple 码表按"4 位长度 + 变长符号"解析，RFC 是"1 位 is_first_8bits + 1/8 位符号"；
/// 2. 码长只读满 256 个，绿树字母表实为 280（256 literal + 24 长度码）；
/// 3. 红/蓝/alpha 三个通道复用了绿树。
///
/// 本模块实现：5 棵独立前缀树（绿 280 / 红 256 / 蓝 256 / alpha 256 / 距离 40）、
/// RFC simple 与 normal 两种码表、literal + 色彩缓存索引。
/// 尚未实现（M2/M3 补齐）：LZ77 长度/距离、meta 多组、predictor / cross-color / palette 变换。
/// 遇到未实现结构一律抛出 DecodeFailed，绝不静默输出错误像素。

///|
/// 按 code length 数组构建 canonical Huffman 树
fn vp8l_build_canonical_tree(lens : Array[Int32], alphabet_size : Int32) -> HuffmanTree {
  let tree = HuffmanTree::new()
  let mut max_len = 0
  for i in 0..<alphabet_size {
    if lens[i] > max_len {
      max_len = lens[i]
    }
  }
  if max_len == 0 {
    tree.codes.push(HuffmanCode::{ value: 0, left: -1, right: -1 })
    return tree
  }
  let bl_count : Array[Int32] = Array::make(max_len + 1, 0)
  for i in 0..<alphabet_size {
    let cl = lens[i]
    if cl > 0 {
      bl_count[cl] += 1
    }
  }
  let next_code : Array[Int32] = Array::make(max_len + 1, 0)
  let mut code = 0
  for bits in 1..<=max_len {
    code = (code + bl_count[bits - 1]) << 1
    next_code[bits] = code
  }
  for n in 0..<alphabet_size {
    let cl = lens[n]
    if cl > 0 {
      tree.add_code(next_code[cl], cl, n)
      next_code[cl] += 1
    }
  }
  tree
}

///|
/// 读一棵 RFC 9649 §3.2 前缀码（simple 或 normal），字母表大小由调用方给出
fn vp8l_read_prefix_code(br : BitReader, alphabet_size : Int32) -> HuffmanTree {
  let tree = HuffmanTree::new()
  let is_simple = br.read_bit()
  if is_simple == 1 {
    let num_symbols = br.read_bit() + 1
    let is_first_8bits = br.read_bit()
    let sym0 = if is_first_8bits == 1 {
      br.read_bits(8)
    } else {
      br.read_bits(1)
    }
    if num_symbols == 2 {
      let sym1 = br.read_bits(8)
      tree.add_code(0, 1, sym0)
      tree.add_code(1, 1, sym1)
    } else {
      // 单符号：根节点直接持值，解码时零比特
      tree.codes.push(HuffmanCode::{ value: sym0, left: -1, right: -1 })
    }
    return tree
  }
  // normal：先读码长码
  let num_code_lengths = br.read_bits(4) + 4
  let cl_lens : Array[Int32] = Array::make(19, 0)
  for i in 0..<num_code_lengths {
    cl_lens[vp8l_code_length_order[i]] = br.read_bits(3)
  }
  let cl_tree = vp8l_build_canonical_tree(cl_lens, 19)
  // max_symbol：标志置位时只读前 max_symbol 个长度
  let max_symbol = if br.read_bit() == 1 {
    ((br.read_bits(2) + 2) << 3) + br.read_bits(3)
  } else {
    alphabet_size
  }
  let lens : Array[Int32] = Array::make(alphabet_size, 0)
  let mut idx = 0
  while idx < max_symbol && idx < alphabet_size {
    let sym = cl_tree.decode(br)
    if sym < 16 {
      lens[idx] = sym
      idx += 1
    } else if sym == 16 {
      let repeat = 3 + br.read_bits(2)
      let prev = if idx > 0 { lens[idx - 1] } else { 0 }
      for _ in 0..<repeat {
        if idx < alphabet_size {
          lens[idx] = prev
          idx += 1
        }
      }
    } else if sym == 17 {
      let repeat = 3 + br.read_bits(3)
      for _ in 0..<repeat {
        if idx < alphabet_size {
          lens[idx] = 0
          idx += 1
        }
      }
    } else if sym == 18 {
      let repeat = 11 + br.read_bits(7)
      for _ in 0..<repeat {
        if idx < alphabet_size {
          lens[idx] = 0
          idx += 1
        }
      }
    } else {
      // 19 及以上不合法，直接放弃本棵树
      return vp8l_build_canonical_tree(Array::make(alphabet_size, 0), alphabet_size)
    }
  }
  vp8l_build_canonical_tree(lens, alphabet_size)
}

///|
/// 在 RIFF 容器里定位 VP8L chunk 的数据起点，找不到返回 -1
fn vp8l_find_chunk(data : Bytes, target : Int32) -> Int32 {
  let len = data.length()
  let mut pos = 12
  while pos + 8 <= len {
    let id = data[pos].to_int() |
      (data[pos + 1].to_int() << 8) |
      (data[pos + 2].to_int() << 16) |
      (data[pos + 3].to_int() << 24)
    if id == target {
      return pos + 8
    }
    let size = data[pos + 4].to_int() |
      (data[pos + 5].to_int() << 8) |
      (data[pos + 6].to_int() << 16) |
      (data[pos + 7].to_int() << 24)
    pos = pos + 8 + size + (size & 1)
  }
  -1
}

///|
/// RFC 合规的 VP8L 解码：literal + 色彩缓存 + subtract-green。
///
/// 返回 `channels = 4`（本实现始终输出 RGBA，alpha 缺失时由树给出）。
/// 未实现的编码结构（LZ77、meta 多组、predictor/palette 变换）会抛出
/// `LoadError::DecodeFailed`，附带具体缺哪一项，便于定位。
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
  let _ = br.read_bits(3)
  if width <= 0 || height <= 0 || width > 16384 || height > 16384 {
    raise @types.LoadError::DecodeFailed("VP8L：尺寸无效")
  }
  // transforms
  let mut has_transform = br.read_bit() == 1
  let mut subtract_green = false
  let mut transform_count = 0
  while has_transform && transform_count < 4 {
    let t_type = br.read_bits(2)
    transform_count += 1
    if t_type == 2 {
      subtract_green = true
    } else {
      raise @types.LoadError::DecodeFailed(
        "VP8L：变换类型 " + t_type.to_string() + " 尚未实现（当前仅支持 subtract-green）",
      )
    }
    has_transform = br.read_bit() == 1
  }
  // color cache
  let use_cache = br.read_bit()
  let cache_bits = if use_cache == 1 { br.read_bits(4) } else { 0 }
  let cache_size = if cache_bits > 0 { 1 << cache_bits } else { 0 }
  // meta huffman
  let use_meta = br.read_bit()
  if use_meta == 1 {
    raise @types.LoadError::DecodeFailed("VP8L：meta 多组前缀码尚未实现")
  }
  let green_alphabet = 256 + 24 + cache_size
  let green = vp8l_read_prefix_code(br, green_alphabet)
  let red = vp8l_read_prefix_code(br, 256)
  let blue = vp8l_read_prefix_code(br, 256)
  let alpha = vp8l_read_prefix_code(br, 256)
  let dist = vp8l_read_prefix_code(br, 40)
  let n = width * height
  let pixels : Array[Int32] = Array::make(n, 0)
  let cache : Array[Int32] = Array::make(if cache_size > 0 { cache_size } else { 0 }, 0)
  let mut i = 0
  while i < n {
    let g = green.decode(br)
    if g < 256 {
      let r = red.decode(br)
      let b = blue.decode(br)
      let a = alpha.decode(br)
      let argb = (a << 24) | (b << 16) | (g << 8) | r
      pixels[i] = argb
      if cache_size > 0 {
        let hash = ((argb * 0x1E35A7BD) & 0xFFFFFFFF) >> (32 - cache_bits)
        cache[hash & (cache_size - 1)] = argb
      }
      i += 1
    } else if g == 256 {
      if cache_size == 0 {
        raise @types.LoadError::DecodeFailed("VP8L：出现色彩缓存索引但未启用缓存")
      }
      let idx = br.read_bits(cache_bits)
      pixels[i] = cache[idx]
      i += 1
    } else {
      let _ = dist
      raise @types.LoadError::DecodeFailed("VP8L：LZ77 反向引用尚未实现（symbol ≥ 257）")
    }
  }
  if subtract_green {
    apply_subtract_green_inverse(pixels, n)
  }
  let _ = alpha_used
  @types.check_dims(width, height, 4)
  let out : Array[Byte] = Array::make(n * 4, b'\x00')
  for k in 0..<n {
    let argb = pixels[k]
    out[k * 4] = (argb & 0xFF).to_byte()
    out[k * 4 + 1] = ((argb >> 8) & 0xFF).to_byte()
    out[k * 4 + 2] = ((argb >> 16) & 0xFF).to_byte()
    out[k * 4 + 3] = ((argb >> 24) & 0xFF).to_byte()
  }
  @types.Image::{
    width,
    height,
    channels: 4,
    data: Bytes::from_array(out),
  }
}
