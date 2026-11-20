/// ============================================================================
/// ISO BMFF (MP4) box 结构解析 — 纯 MoonBit 零依赖实现。
/// ============================================================================

///|
/// 4 字节 ASCII fourcc → String（非 Unicode scalar 字节以 U+FFFD 占位，保证不匹配任何已知 box 类型）。
fn fourcc(data : Bytes, offset : Int32) -> String {
  String::from_array([
    data[offset].to_int().to_char().unwrap_or('\u{FFFD}'),
    data[offset + 1].to_int().to_char().unwrap_or('\u{FFFD}'),
    data[offset + 2].to_int().to_char().unwrap_or('\u{FFFD}'),
    data[offset + 3].to_int().to_char().unwrap_or('\u{FFFD}'),
  ])
}

///|
/// u32 大端读取（ISO BMFF 长度/计数字段）。
fn read_u32(data : Bytes, offset : Int32) -> Int32 {
  (data[offset].to_int() << 24) |
  (data[offset + 1].to_int() << 16) |
  (data[offset + 2].to_int() << 8) |
  data[offset + 3].to_int()
}

///|
/// u64 大端读取（largesize / co64 偏移）。
fn read_u64(data : Bytes, offset : Int32) -> Int64 {
  ((data[offset].to_int() & 0xFF).to_int64() << 56) |
  ((data[offset + 1].to_int() & 0xFF).to_int64() << 48) |
  ((data[offset + 2].to_int() & 0xFF).to_int64() << 40) |
  ((data[offset + 3].to_int() & 0xFF).to_int64() << 32) |
  ((data[offset + 4].to_int() & 0xFF).to_int64() << 24) |
  ((data[offset + 5].to_int() & 0xFF).to_int64() << 16) |
  ((data[offset + 6].to_int() & 0xFF).to_int64() << 8) |
  (data[offset + 7].to_int() & 0xFF).to_int64()
}

///|
/// 解析出的 MP4 box。
pub(all) struct Mp4Box {
  box_type : String
  start : Int32
  payload_start : Int32
  size : Int32
}

///|
/// 在 [start, end) 范围内**单层遍历** box 序列，对每个 box 调用 f。
fn walk_boxes_one_level(
  data : Bytes,
  start : Int32,
  end : Int32,
  f : (Mp4Box) -> Unit,
) -> Unit {
  let mut off = start
  while off + 8 <= end {
    let size = read_u32(data, off)
    let ty = fourcc(data, off + 4)
    let header = if size == 1 { 16 } else { 8 }
    if size < header {
      return // 非法 size，停止遍历
    }
    let total = if size == 1 {
      let large = read_u64(data, off + 8)
      if large.to_int() < header || off + large.to_int() > end {
        return // 截断
      }
      large.to_int()
    } else if size == 0 {
      end - off // size==0：box 延伸到容器末尾
    } else {
      size
    }
    if off + total > end {
      return // 截断
    }
    f({ box_type: ty, start: off, payload_start: off + header, size: total, })
    if size == 0 {
      return
    }
    off = off + total
  }
}

///|
/// 在 [start, end) 单层查找指定类型的第一个 box。
fn find_box(data : Bytes, start : Int32, end : Int32, ty : String) -> Mp4Box? {
  let mut result : Mp4Box? = None
  walk_boxes_one_level(data, start, end, fn(b) {
    if b.box_type == ty {
      match result {
        None => result = Some(b)
        Some(_) => ()
      }
    }
  })
  result
}

///|
/// 在 [start, end) 单层收集指定类型的全部 box（如多 trak）。
fn collect_boxes(
  data : Bytes,
  start : Int32,
  end : Int32,
  ty : String,
) -> Array[Mp4Box] {
  let arr : Array[Mp4Box] = []
  walk_boxes_one_level(data, start, end, fn(b) {
    if b.box_type == ty {
      arr.push(b)
    }
  })
  arr
}

///|
/// 绝对偏移 u32 读取。
fn payload_u32_at(data : Bytes, base : Int32, rel : Int32) -> Int32 {
  read_u32(data, base + rel)
}

///|
/// 绝对偏移 u64 读取。
fn payload_u64_at(data : Bytes, base : Int32, rel : Int32) -> Int64 {
  read_u64(data, base + rel)
}
