///|
/// # WebP Lossless 解码器 WebP Lossless Decoder
///
/// 纯 MoonBit WebP lossless (VP8L) 解码器，支持 RGBA 解码，不支持 lossy (VP8)。 Pure MoonBit WebP lossless (VP8L) decoder, supports RGBA decoding, does not support lossy (VP8).
///
/// 核心函数 Core functions:
/// - `decode_webp_pure` - 解码 WebP 字节流为 Image Decode WebP byte stream to Image

// 纯 MoonBit WebP lossless 解码器 (VP8L)
// 规范: https://developers.google.com/speed/webp/docs/compression
// 支持 lossless RGBA 解码，不支持 lossy (VP8)

// ==================== BitReader ====================

///|
priv struct BitReader {
  data : Bytes
  mut pos : Int32
  mut bit_buf : Int32
  mut bit_count : Int32
}

///|
fn BitReader::new(data : Bytes, start : Int32) -> BitReader {
  BitReader::{ data, pos: start, bit_buf: 0, bit_count: 0, }
}

///|
fn BitReader::read_bits(self : BitReader, n : Int32) -> Int32 {
  let mut result = 0
  for i in 0..<n {
    if self.bit_count == 0 {
      if self.pos >= self.data.length() {
        self.bit_buf = 0
        self.bit_count = 8
      } else {
        self.bit_buf = self.data[self.pos].to_int()
        self.pos += 1
        self.bit_count = 8
      }
    }
    let bit = self.bit_buf & 1
    self.bit_buf = self.bit_buf >> 1
    self.bit_count -= 1
    result = result | (bit << i)
  }
  result
}

///|
fn BitReader::read_bit(self : BitReader) -> Int32 {
  self.read_bits(1)
}

// ==================== Huffman Decoding ====================

///|
priv struct HuffmanCode {
  mut value : Int32
  mut left : Int32
  mut right : Int32
}

///|
priv struct HuffmanTree {
  codes : Array[HuffmanCode]
}

///|
fn HuffmanTree::new() -> HuffmanTree {
  HuffmanTree::{ codes: [], }
}

///|
fn HuffmanTree::add_code(
  self : HuffmanTree,
  code : Int32,
  code_len : Int32,
  symbol : Int32,
) -> Unit {
  // Build a binary tree by walking the code bits MSB-first
  let mut node = 0
  if self.codes.length() == 0 {
    self.codes.push(HuffmanCode::{ value: -1, left: -1, right: -1, })
  }
  for i in 0..<code_len {
    let bit = (code >> (code_len - 1 - i)) & 1
    let child = if bit == 0 {
      self.codes[node].left
    } else {
      self.codes[node].right
    }
    if child == -1 {
      let new_idx = self.codes.length()
      self.codes.push(HuffmanCode::{ value: -1, left: -1, right: -1, })
      if bit == 0 {
        self.codes[node].left = new_idx
      } else {
        self.codes[node].right = new_idx
      }
      node = new_idx
    } else {
      node = child
    }
  }
  self.codes[node].value = symbol
}

///|
fn HuffmanTree::decode(self : HuffmanTree, br : BitReader) -> Int32 {
  let mut node = 0
  if self.codes.length() == 0 {
    return 0
  }
  // 单符号码表：不消耗任何比特（RFC 9649 §3.2.2；此前按"读 1 位走左子树"会让后续流错位）
  if self.codes[0].value != -1 {
    return self.codes[0].value
  }
  while true {
    let bit = br.read_bit()
    let child = if bit == 0 {
      self.codes[node].left
    } else {
      self.codes[node].right
    }
    if child == -1 {
      return self.codes[node].value
    }
    node = child
    if self.codes[node].value != -1 {
      return self.codes[node].value
    }
  }
  0
}

///|
