///|
/// # PNG 编码 PNG Encode
///
/// PNG 图像格式编码
/// PNG 图像格式编码 PNG image format encoding
// 纯 MoonBit PNG 编码（全目标可用：native/wasm/js）
// 使用 filter type 0 (None) + zlib stored blocks（无压缩但有效）

///|
/// PNG 行过滤（RFC 2083 §9）：0 None / 1 Sub / 2 Up / 3 Average / 4 Paeth。
fn png_filter_row(
  raw : Array[Byte],
  prev : Array[Byte],
  bpp : Int32,
  ft : Int32,
) -> Array[Byte] {
  let n = raw.length()
  let out : Array[Byte] = Array::make(n, b'\x00')
  for i in 0..<n {
    let cur = raw[i].to_int()
    let left = if i >= bpp { raw[i - bpp].to_int() } else { 0 }
    let up = prev[i].to_int()
    let ul = if i >= bpp { prev[i - bpp].to_int() } else { 0 }
    let pred = match ft {
      1 => left
      2 => up
      3 => (left + up) / 2
      4 => {
        // Paeth predictor
        let p = left + up - ul
        let pa = if p > left { p - left } else { left - p }
        let pb = if p > up { p - up } else { up - p }
        let pc = if p > ul { p - ul } else { ul - p }
        if pa <= pb && pa <= pc {
          left
        } else if pb <= pc {
          up
        } else {
          ul
        }
      }
      _ => 0
    }
    out[i] = ((cur - pred) & 0xFF).to_byte()
  }
  out
}

///|
/// 过滤结果的启发式代价：按「有符号字节」取绝对值求和（PNG 规范推荐）。
fn png_filter_score(row : Array[Byte]) -> Int32 {
  let mut s = 0
  for i in 0..<row.length() {
    let v = row[i].to_int()
    s += if v < 128 { v } else { 256 - v }
  }
  s
}

///|
/// 写入 PNG chunk
fn write_chunk(out : Array[Byte], chunk_type : String, data : Bytes) -> Unit {
  let len = data.length()
  // length (big-endian)
  out.push(((len >> 24) & 0xFF).to_byte())
  out.push(((len >> 16) & 0xFF).to_byte())
  out.push(((len >> 8) & 0xFF).to_byte())
  out.push((len & 0xFF).to_byte())
  // type
  let type_bytes = @encoding/utf8.encode(chunk_type)
  for i in 0..<4 {
    out.push(type_bytes[i])
  }
  // data
  for i in 0..<len {
    out.push(data[i])
  }
  // CRC (over type + data)
  let crc_data : Array[Byte] = []
  for i in 0..<4 {
    crc_data.push(type_bytes[i])
  }
  for i in 0..<len {
    crc_data.push(data[i])
  }
  let crc = @util.crc32(Bytes::from_array(crc_data))
  out.push(((crc >> 24) & 0xFF).to_byte())
  out.push(((crc >> 16) & 0xFF).to_byte())
  out.push(((crc >> 8) & 0xFF).to_byte())
  out.push((crc & 0xFF).to_byte())
}

///|
/// PNG 编码（纯 MoonBit，全目标可用）。
/// 输入 Image（RGB），返回 PNG 格式字节流。
/// 使用 filter type 0 (None) + zlib stored blocks（无压缩）。
pub fn encode_png_pure(img : @types.Image) -> Bytes {
  let width = img.width
  let height = img.height
  let ch = img.channels
  // 确定输出通道数
  let out_ch = if ch == 4 {
    4
  } else if ch == 2 {
    2
  } else if ch == 1 {
    1
  } else {
    3
  }
  let color_type = if out_ch == 1 {
    0
  } else if out_ch == 2 {
    4
  } else if out_ch == 4 {
    6
  } else {
    2
  }
  let out : Array[Byte] = []
  // PNG signature
  out.push(b'\x89')
  out.push(b'\x50')
  out.push(b'\x4E')
  out.push(b'\x47')
  out.push(b'\x0D')
  out.push(b'\x0A')
  out.push(b'\x1A')
  out.push(b'\x0A')
  // IHDR chunk
  let ihdr : Array[Byte] = []
  // width (big-endian)
  ihdr.push(((width >> 24) & 0xFF).to_byte())
  ihdr.push(((width >> 16) & 0xFF).to_byte())
  ihdr.push(((width >> 8) & 0xFF).to_byte())
  ihdr.push((width & 0xFF).to_byte())
  // height (big-endian)
  ihdr.push(((height >> 24) & 0xFF).to_byte())
  ihdr.push(((height >> 16) & 0xFF).to_byte())
  ihdr.push(((height >> 8) & 0xFF).to_byte())
  ihdr.push((height & 0xFF).to_byte())
  ihdr.push(b'\x08') // bit depth = 8
  ihdr.push(color_type.to_byte())
  ihdr.push(b'\x00') // compression = 0
  ihdr.push(b'\x00') // filter = 0
  ihdr.push(b'\x00') // interlace = 0
  write_chunk(out, "IHDR", Bytes::from_array(ihdr))
  // 构建过滤后的图像数据：逐行在 5 种 filter 里选绝对值和最小的那个
  let bpp = out_ch
  let row_len = width * out_ch
  let filtered : Array[Byte] = []
  let prev_row : Array[Byte] = Array::make(row_len, b'\x00')
  for y in 0..<height {
    let raw : Array[Byte] = Array::make(row_len, b'\x00')
    for x in 0..<width {
      let src_off = (y * width + x) * ch
      if ch == out_ch {
        for c in 0..<ch {
          raw[x * out_ch + c] = img.data[src_off + c]
        }
      } else {
        for c in 0..<out_ch {
          raw[x * out_ch + c] = if c < ch {
            img.data[src_off + c]
          } else {
            b'\xFF'
          }
        }
      }
    }
    let mut best_type = 0
    let mut best_score = 0x7FFFFFFF
    let mut best_row : Array[Byte] = raw
    for ft in 0..<5 {
      let cand = png_filter_row(raw, prev_row, bpp, ft)
      let score = png_filter_score(cand)
      if score < best_score {
        best_score = score
        best_type = ft
        best_row = cand
      }
    }
    filtered.push(best_type.to_byte())
    for i in 0..<row_len {
      filtered.push(best_row[i])
    }
    for i in 0..<row_len {
      prev_row[i] = raw[i]
    }
  }
  // zlib deflate（fixed Huffman + LZ77，RFC 1950/1951 合法流）
  let compressed = zlib_compress(Bytes::from_array(filtered))
  // IDAT chunk
  write_chunk(out, "IDAT", compressed)
  // IEND chunk
  write_chunk(out, "IEND", Bytes::from_array([]))
  Bytes::from_array(out)
}
