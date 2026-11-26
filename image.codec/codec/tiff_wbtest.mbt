// 白盒：TIFF 私有解析函数 + LZW 回溯 + 结构补丁路径

///|
fn twb_ctx(data : Bytes, le~ : Bool = true) -> TiffContext {
  TiffContext::{ data, little_endian: le, }
}

///|
fn twb_entry(
  tag : Int32,
  type_id : Int32,
  count : Int32,
  v : Int32,
) -> TiffIfdEntry {
  TiffIfdEntry::{ tag, type_id, count, value_or_offset: v, }
}

///|
fn twb_bytes(arr : Array[Int32]) -> Bytes {
  let b : Array[Byte] = []
  for v in arr {
    b.push(v.to_byte())
  }
  Bytes::from_array(b)
}

///|
fn twb_patch(data : Bytes, offset : Int32, vals : Array[Int32]) -> Bytes {
  let arr : Array[Byte] = []
  for b in data {
    arr.push(b)
  }
  for i in 0..<vals.length() {
    arr[offset + i] = vals[i].to_byte()
  }
  Bytes::from_array(arr)
}

///|
test "twb: tiff_type_size 全类型表" {
  assert_eq(tiff_type_size(1), 1)
  assert_eq(tiff_type_size(2), 1)
  assert_eq(tiff_type_size(3), 2)
  assert_eq(tiff_type_size(4), 4)
  assert_eq(tiff_type_size(5), 8)
  assert_eq(tiff_type_size(6), 1)
  assert_eq(tiff_type_size(7), 1)
  assert_eq(tiff_type_size(8), 2)
  assert_eq(tiff_type_size(9), 4)
  assert_eq(tiff_type_size(10), 8)
  assert_eq(tiff_type_size(11), 4)
  assert_eq(tiff_type_size(12), 8)
  assert_eq(tiff_type_size(13), 0)
  assert_eq(tiff_type_size(0), 0)
}

///|
test "twb: tiff_read_values 内联四种类型" {
  // type 1（BYTE），v=0x030201 → 3 个值
  let ctx = twb_ctx(twb_bytes([]))
  let v1 = tiff_read_values(ctx, twb_entry(0, 1, 3, 0x030201))
  assert_eq(v1.length(), 3)
  assert_eq(v1[0], 1)
  assert_eq(v1[2], 3)
  // type 7（UNDEFINED）同 BYTE
  let v7 = tiff_read_values(ctx, twb_entry(0, 7, 2, 0x0000FF00))
  assert_eq(v7.length(), 2)
  assert_eq(v7[1], 0xFF)
  // type 3（SHORT），v=0x00070005 → 两个 16 位
  let v3 = tiff_read_values(ctx, twb_entry(0, 3, 2, 0x00070005))
  assert_eq(v3.length(), 2)
  assert_eq(v3[0], 5)
  assert_eq(v3[1], 7)
  // type 4（LONG）
  let v4 = tiff_read_values(ctx, twb_entry(0, 4, 1, 12345))
  assert_eq(v4.length(), 1)
  assert_eq(v4[0], 12345)
  // type 2（ASCII）走兜底：全 0
  let va = tiff_read_values(ctx, twb_entry(0, 2, 4, 0x41424344))
  assert_eq(va.length(), 4)
  assert_eq(va[0], 0)
}

///|
test "twb: tiff_read_values 外置偏移四种类型（含越界补 0）" {
  let raw = twb_bytes([10, 20, 30, 40, 0, 0, 0, 0])
  let ctx = twb_ctx(raw)
  // type 1，count 8（总字节 8 > 4 → 外置），base=4：索引 0..3 有效、4..7 越界补 0
  let e1 = tiff_read_values(ctx, twb_entry(0, 1, 8, 4))
  assert_eq(e1.length(), 8)
  assert_eq(e1[0], 0)
  assert_eq(e1[4], 0)
  assert_eq(e1[7], 0)
  // 越界更极端：base=6，count 8
  let e2 = tiff_read_values(ctx, twb_entry(0, 1, 8, 6))
  assert_eq(e2.length(), 8)
  assert_eq(e2[0], 0)
  assert_eq(e2[7], 0)
  // type 3 外置：count 2（4 字节 > 4？4 <= 4 走内联）→ 用 count 3
  let raw16 = twb_bytes([1, 0, 2, 0, 3, 0, 0, 0])
  let ctx16 = twb_ctx(raw16)
  let e3 = tiff_read_values(ctx16, twb_entry(0, 3, 3, 0))
  assert_eq(e3.length(), 3)
  assert_eq(e3[0], 1)
  assert_eq(e3[1], 2)
  assert_eq(e3[2], 3)
  // type 4 外置：count 2
  let raw32 = twb_bytes([1, 0, 0, 0, 2, 0, 0, 0])
  let ctx32 = twb_ctx(raw32)
  let e4 = tiff_read_values(ctx32, twb_entry(0, 4, 2, 0))
  assert_eq(e4.length(), 2)
  assert_eq(e4[0], 1)
  assert_eq(e4[1], 2)
  // type 5（RATIONAL 8 字节）走兜底：全 0
  let e5 = tiff_read_values(ctx32, twb_entry(0, 5, 2, 0))
  assert_eq(e5.length(), 2)
  assert_eq(e5[0], 0)
}

///|
test "twb: tiff_get_value 空数组返回 None" {
  let raw = twb_bytes([0, 0, 0, 0, 0, 0, 0, 0])
  let ctx = twb_ctx(raw)
  // count 0 的 RATIONAL：values 为空 → None
  let entries = [twb_entry(300, 5, 0, 0)]
  match tiff_get_value(entries, ctx, 300) {
    None => ()
    Some(_) => assert_true(false)
  }
  // 不存在的 tag
  match tiff_get_value(entries, ctx, 256) {
    None => ()
    Some(_) => assert_true(false)
  }
}

///|
fn twb_lzw_codes(codes : Array[Int32], bits : Int32) -> Bytes {
  let out : Array[Int32] = []
  let total = codes.length() * bits
  for _ in 0..<((total + 7) / 8) {
    out.push(0)
  }
  let mut pos = 0 // 首字节存放初始码长，位流从 data[1] 起
  for c in codes {
    for b in 0..<bits {
      if ((c >> b) & 1) == 1 {
        let idx = pos / 8
        let off = pos % 8
        out[idx] = out[idx] | (1 << off)
      }
      pos += 1
    }
  }
  let bytes : Array[Byte] = [8]
  for v in out {
    bytes.push(v.to_byte())
  }
  Bytes::from_array(bytes)
}

///|
test "twb: LZW 字典回溯与中段 CLEAR" {
  // CLEAR(256) → 'A'(65) → 258（回溯 dict[258]=65）→ 259（回溯链）→ EOI(257)
  let data = twb_lzw_codes([256, 65, 258, 259, 257], 9)
  let out = tiff_lzw_decode(data)
  assert_true(out.length() >= 3)
  assert_eq(out[0], b'\x41')
  // 中段 CLEAR 复位：A, CLEAR, B, EOI
  let data2 = twb_lzw_codes([256, 65, 256, 66, 257], 9)
  let out2 = tiff_lzw_decode(data2)
  assert_true(out2.length() >= 2)
  assert_eq(out2[0], b'\x41')
  assert_eq(out2[1], b'\x42')
}

///|
test "twb: PackBits 扩展模式截断与负控制码" {
  // 扩展复制：0x80 → 0x00 0x05（6 字节）但数据只有 2 字节 → 截断
  let d1 = twb_bytes([0x80, 0xFF, 0xFF, 7])
  let o1 = tiff_packbits_decode(d1)
  assert_eq(o1.length(), 1)
  assert_eq(o1[0], b'\x07')
  // 扩展重复：0x80 → 0xFF 0xF0 → extended = 0xFFF0-0x8000 = 32752 >= 0？否
  // 用 0xFF 0xFF → 65535-32768=32767 >=0，走复制；改为负：0x80 0x80 0x00 → 32768-32768=0
  let d2 = twb_bytes([0x80, 0x7F, 0xFF, 7])
  let o2 = tiff_packbits_decode(d2)
  assert_true(o2.length() >= 1)
  // 普通重复：0xFF（-1）→ 重复下一字节 2 次
  let d3 = twb_bytes([0xFF, 9])
  let o3 = tiff_packbits_decode(d3)
  assert_eq(o3.length(), 2)
  assert_eq(o3[0], b'\x09')
}

///|
test "twb: Deflate 保留块被拒" {
  // 字节 0x07：final=1, type=3（保留）
  try {
    let _ = tiff_deflate_decode(twb_bytes([0x07, 0, 0]))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
  // final=0, type=2（动态 Huffman）
  try {
    let _ = tiff_deflate_decode(twb_bytes([0x04, 0, 0]))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "twb: TIFF 结构补丁 - 灰化 / 缺 StripByteCounts / 像素越界" {
  let img = @types.Image::{
    width: 2,
    height: 2,
    channels: 3,
    data: Bytes::from_array([
      b'\x0A', b'\x14', b'\x1E', b'\x28', b'\x32', b'\x3C', b'\x46', b'\x50', b'\x5A',
      b'\x64', b'\x6E', b'\x78',
    ]),
  }
  let base = encode_tiff_pure(img)
  // photometric 值（索引 4 条目的 value 位于 66）改为 0 → 多通道灰度反相
  let gray = twb_patch(base, 66, [0, 0, 0, 0])
  let gimg = decode_tiff_pure(gray)
  assert_eq(gimg.channels, 3)
  assert_eq(gimg.width, 2)
  // 0A → 255-10 = 245
  assert_eq(gimg.data[0].to_int(), 245)
  // 把 279（StripByteCounts）tag 改成 999 → 走缺省字节数分支
  let no_counts = twb_patch(base, 106, [999, 0])
  let nimg = decode_tiff_pure(no_counts)
  assert_eq(nimg.width, 2)
  assert_eq(nimg.channels, 3)
  // 把 278（RowsPerStrip）tag 改成 999 → rows_per_strip 缺省为 height
  let no_rows = twb_patch(base, 94, [999, 0])
  let rimg = decode_tiff_pure(no_rows)
  assert_eq(rimg.height, 2)
  // 把 279 的字节数改成 4（像素 12 字节）→ 像素越界
  let short = twb_patch(base, 114, [4, 0, 0, 0])
  try {
    let _ = decode_tiff_pure(short)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "twb: TIFF RGBA 灰度化带 alpha" {
  let img = @types.Image::{
    width: 1,
    height: 1,
    channels: 4,
    data: Bytes::from_array([b'\x20', b'\x30', b'\x40', b'\x50']),
  }
  let base = encode_tiff_pure(img)
  // 1×1 RGBA：entry 4 的 value 在 66；改成 photometric=1
  let gray = twb_patch(base, 66, [1, 0, 0, 0])
  let out = decode_tiff_pure(gray)
  assert_eq(out.channels, 4)
  // photometric=1 → 正片灰度，三通道同值 0x20，alpha 保留
  assert_eq(out.data[0], b'\x20')
  assert_eq(out.data[1], b'\x20')
  assert_eq(out.data[3], b'\x50')
}
