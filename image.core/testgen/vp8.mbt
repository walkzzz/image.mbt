///|
/// 构造最小 VP8 **inter（非关键帧）**：3 字节小端 tag（bit0=1、show_frame=1、
/// first_part_size 写入 bit5-23），随后为全零首分区。inter 帧头不携带分辨率，
/// 解码器应使用参考帧尺寸（见 decode_vp8_inter_frame）。
pub fn build_vp8_inter_frame(first_part_size~ : Int32 = 32) -> Bytes {
  let size = if first_part_size < 0 { 0 } else { first_part_size }
  let tag = (1 << 0) | (0 << 1) | (1 << 4) | ((size & 0x7FFFF) << 5)
  let out : Array[Byte] = []
  out.push((tag & 0xFF).to_byte())
  out.push(((tag >> 8) & 0xFF).to_byte())
  out.push(((tag >> 16) & 0xFF).to_byte())
  for _ in 0..<size {
    out.push(b'\x00')
  }
  Bytes::from_array(out)
}

///|
/// 构造最小 VP8 **key frame**：小端 tag + start code（9D 01 2A）+ 小端分辨率
/// + 全零首分区。可用于 decode_vp8_frame（零 token 会解码为平坦图像）。
pub fn build_vp8_key_frame(
  width : Int32,
  height : Int32,
  first_part_size~ : Int32 = 32,
) -> Bytes {
  let w = if width < 0 { 0 } else { width }
  let h = if height < 0 { 0 } else { height }
  let size = if first_part_size < 0 { 0 } else { first_part_size }
  let tag = (0 << 0) | (0 << 1) | (1 << 4) | ((size & 0x7FFFF) << 5)
  let out : Array[Byte] = []
  out.push((tag & 0xFF).to_byte())
  out.push(((tag >> 8) & 0xFF).to_byte())
  out.push(((tag >> 16) & 0xFF).to_byte())
  out.push(b'\x9D')
  out.push(b'\x01')
  out.push(b'\x2A')
  out.push((w & 0xFF).to_byte())
  out.push(((w >> 8) & 0x3F).to_byte())
  out.push((h & 0xFF).to_byte())
  out.push(((h >> 8) & 0x3F).to_byte())
  for _ in 0..<size {
    out.push(b'\x00')
  }
  Bytes::from_array(out)
}

///|
/// 构造走帧内预测分支的最小 VP8 关键帧：首分区前两字节为 0xFF，使
/// Vp8BoolDecoder 的首个 read_bool(180) 判为 1（is_intra），其后以 0 填充。
pub fn build_vp8_intra_frame(
  width : Int32,
  height : Int32,
  ones~ : Int32 = 2,
) -> Bytes {
  let w = if width < 0 { 0 } else { width }
  let h = if height < 0 { 0 } else { height }
  let n = if ones < 2 { 2 } else { ones }
  let stream : Array[Byte] = []
  for _ in 0..<n {
    stream.push(b'\xFF')
  }
  for _ in 0..<30 {
    stream.push(b'\x00')
  }
  let size = stream.length()
  let out : Array[Byte] = []
  let tag = (0 << 0) | (0 << 1) | (1 << 4) | ((size & 0x7FFFF) << 5)
  out.push((tag & 0xFF).to_byte())
  out.push(((tag >> 8) & 0xFF).to_byte())
  out.push(((tag >> 16) & 0xFF).to_byte())
  out.push(b'\x9D')
  out.push(b'\x01')
  out.push(b'\x2A')
  out.push((w & 0xFF).to_byte())
  out.push(((w >> 8) & 0x3F).to_byte())
  out.push((h & 0xFF).to_byte())
  out.push(((h >> 8) & 0x3F).to_byte())
  for b in stream {
    out.push(b)
  }
  Bytes::from_array(out)
}
