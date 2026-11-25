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
  // max_symbol：标志置位时读 length_nbits = 2 + 2*ReadBits(3)，再读 max_symbol = 2 + ReadBits(length_nbits)
  let max_symbol = if br.read_bit() == 1 {
    let length_nbits = 2 + 2 * br.read_bits(3)
    2 + br.read_bits(length_nbits)
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
      // RFC 9649 §3.7.2.1.2：码 16 在尚未输出非零值前重复的是 8，而不是 0
      let prev = if idx > 0 { lens[idx - 1] } else { 8 }
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
/// 距离映射表 X 偏移（RFC 9649 §3.6.2.2.1，120 项，由 scripts/proto/gen_distance_table.mjs 从 RFC 原文生成）
let vp8l_distance_dx : Array[Int32] = [
  0, 1, 1, -1, 0, 2, 1, -1, 2, -2, 2, -2,
  0, 3, 1, -1, 3, -3, 2, -2, 3, -3, 0, 4,
  1, -1, 4, -4, 3, -3, 2, -2, 4, -4, 0, 3,
  -3, 4, -4, 5, 1, -1, 5, -5, 2, -2, 5, -5,
  4, -4, 3, -3, 5, -5, 0, 6, 1, -1, 6, -6,
  2, -2, 6, -6, 4, -4, 5, -5, 3, -3, 6, -6,
  0, 7, 1, -1, 5, -5, 7, -7, 4, -4, 6, -6,
  2, -2, 7, -7, 3, -3, 7, -7, 5, -5, 6, -6,
  8, 4, -4, 7, -7, 8, 8, 6, -6, 8, 5, -5,
  7, -7, 8, 6, -6, 7, -7, 8, 7, -7, 8, 8,
]

///|
/// 距离映射表 Y 偏移
let vp8l_distance_dy : Array[Int32] = [
  1, 0, 1, 1, 2, 0, 2, 2, 1, 1, 2, 2,
  3, 0, 3, 3, 1, 1, 3, 3, 2, 2, 4, 0,
  4, 4, 1, 1, 3, 3, 4, 4, 2, 2, 5, 4,
  4, 3, 3, 0, 5, 5, 1, 1, 5, 5, 2, 2,
  4, 4, 5, 5, 3, 3, 6, 0, 6, 6, 1, 1,
  6, 6, 2, 2, 5, 5, 4, 4, 6, 6, 3, 3,
  7, 0, 7, 7, 5, 5, 1, 1, 6, 6, 4, 4,
  7, 7, 2, 2, 7, 7, 3, 3, 6, 6, 5, 5,
  0, 7, 7, 4, 4, 1, 2, 6, 6, 3, 7, 7,
  5, 5, 4, 7, 7, 6, 6, 5, 7, 7, 6, 7,
]

///|
/// LZ77 前缀码取值（RFC 9649 §3.6.2.2）
fn vp8l_prefix_value(br : BitReader, prefix : Int32) -> Int32 {
  if prefix < 4 {
    return prefix + 1
  }
  let extra_bits = (prefix - 2) >> 1
  let offset = (2 + (prefix & 1)) << extra_bits
  offset + br.read_bits(extra_bits) + 1
}

///|
/// 把距离码转成扫描行序距离（<120 走邻域映射，≥120 直接减 120）
fn vp8l_map_distance(code : Int32, width : Int32) -> Int32 {
  if code > 120 {
    return code - 120
  }
  let idx = code - 1
  if idx < 0 || idx >= 120 {
    return 1
  }
  let d = vp8l_distance_dx[idx] + vp8l_distance_dy[idx] * width
  if d < 1 { 1 } else { d }
}
