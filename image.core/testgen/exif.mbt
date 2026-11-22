///|
/// 写 16 位小端整数。
fn exif_put_u16(out : Array[Byte], pos : Int32, v : Int32) -> Unit {
  out[pos] = (v & 0xFF).to_byte()
  out[pos + 1] = ((v >> 8) & 0xFF).to_byte()
}

///|
/// 写 32 位小端整数。
fn exif_put_u32(out : Array[Byte], pos : Int32, v : Int32) -> Unit {
  out[pos] = (v & 0xFF).to_byte()
  out[pos + 1] = ((v >> 8) & 0xFF).to_byte()
  out[pos + 2] = ((v >> 16) & 0xFF).to_byte()
  out[pos + 3] = ((v >> 24) & 0xFF).to_byte()
}

///|
/// TIFF IFD 条目（value 为完整编码数据）。
priv struct ExifEntry {
  tag : Int32
  typ : Int32
  count : Int32
  mut value : Array[Byte]
}

///|
fn exif_ascii(v : Array[Byte]) -> Array[Byte] {
  v
}

///|
fn exif_short(v : Int32) -> Array[Byte] {
  [(v & 0xFF).to_byte(), ((v >> 8) & 0xFF).to_byte()]
}

///|
fn exif_long(v : Int32) -> Array[Byte] {
  [
    (v & 0xFF).to_byte(),
    ((v >> 8) & 0xFF).to_byte(),
    ((v >> 16) & 0xFF).to_byte(),
    ((v >> 24) & 0xFF).to_byte(),
  ]
}

///|
fn exif_rational(num : Int32, den : Int32) -> Array[Byte] {
  let arr : Array[Byte] = []
  for b in exif_long(num) {
    arr.push(b)
  }
  for b in exif_long(den) {
    arr.push(b)
  }
  arr
}

///|
fn exif_rational3(
  n0 : Int32,
  d0 : Int32,
  n1 : Int32,
  d1 : Int32,
  n2 : Int32,
  d2 : Int32,
) -> Array[Byte] {
  let arr : Array[Byte] = []
  for b in exif_rational(n0, d0) {
    arr.push(b)
  }
  for b in exif_rational(n1, d1) {
    arr.push(b)
  }
  for b in exif_rational(n2, d2) {
    arr.push(b)
  }
  arr
}

///|
fn exif_ifd_size(entries : Array[ExifEntry]) -> Int32 {
  2 + entries.length() * 12 + 4
}

///|
fn exif_data_size(entries : Array[ExifEntry]) -> Int32 {
  let mut n = 0
  for e in entries {
    if e.value.length() > 4 {
      n += e.value.length()
    }
  }
  n
}

///|
/// 写出一个 IFD（含数据区），返回新的数据游标。
fn exif_write_ifd(
  out : Array[Byte],
  ifd_pos : Int32,
  entries : Array[ExifEntry],
  next_ifd : Int32,
  data_cursor : Ref[Int32],
) -> Unit {
  exif_put_u16(out, ifd_pos, entries.length())
  for i in 0..<entries.length() {
    let e = entries[i]
    let pos = ifd_pos + 2 + i * 12
    exif_put_u16(out, pos, e.tag)
    exif_put_u16(out, pos + 2, e.typ)
    exif_put_u32(out, pos + 4, e.count)
    if e.value.length() <= 4 {
      for k in 0..<4 {
        out[pos + 8 + k] = if k < e.value.length() {
          e.value[k]
        } else {
          (0).to_byte()
        }
      }
    } else {
      let off = data_cursor.val
      exif_put_u32(out, pos + 8, off)
      for k in 0..<e.value.length() {
        out[off + k] = e.value[k]
      }
      data_cursor.val = off + e.value.length()
    }
  }
  exif_put_u32(out, ifd_pos + 2 + entries.length() * 12, next_ifd)
}

///|
/// 构造带多标签 EXIF 的 JPEG（小端 TIFF），覆盖 Make/Model/Orientation/
/// DateTime/PixelX/YDim/Exposure/FNumber/ISO/FocalLength/ExposureMode/
/// WhiteBalance/Flash 与 GPS 经纬度/海拔。
pub fn build_exif_jpeg() -> Bytes {
  // IFD0
  let ifd0 : Array[ExifEntry] = [
    ExifEntry::{
      tag: 0x010F,
      typ: 2,
      count: 8,
      value: exif_ascii([b'M', b'o', b'o', b'n', b'B', b'i', b't', b'\x00']),
    },
    ExifEntry::{
      tag: 0x0110,
      typ: 2,
      count: 7,
      value: exif_ascii([b'I', b'm', b'a', b'g', b'e', b'X', b'\x00']),
    },
    ExifEntry::{ tag: 0x0112, typ: 3, count: 1, value: exif_short(1), },
    ExifEntry::{
      tag: 0x0132,
      typ: 2,
      count: 20,
      value: exif_ascii([
        b'2', b'0', b'2', b'6', b':', b'1', b'1', b':', b'2', b'1', b' ', b'1', b'2',
        b':', b'0', b'0', b':', b'0', b'0', b'\x00',
      ]),
    },
    ExifEntry::{ tag: 0x8769, typ: 4, count: 1, value: exif_long(0), },
    ExifEntry::{ tag: 0x8825, typ: 4, count: 1, value: exif_long(0), },
    ExifEntry::{ tag: 0xA002, typ: 4, count: 1, value: exif_long(64), },
    ExifEntry::{ tag: 0xA003, typ: 4, count: 1, value: exif_long(48), },
  ]
  // ExifIFD
  let exif_ifd : Array[ExifEntry] = [
    ExifEntry::{ tag: 0x829A, typ: 5, count: 1, value: exif_rational(1, 500), },
    ExifEntry::{ tag: 0x829D, typ: 5, count: 1, value: exif_rational(28, 10), },
    ExifEntry::{ tag: 0x8827, typ: 3, count: 1, value: exif_short(100), },
    ExifEntry::{ tag: 0x920A, typ: 5, count: 1, value: exif_rational(50, 1), },
    ExifEntry::{ tag: 0xA402, typ: 3, count: 1, value: exif_short(1), },
    ExifEntry::{ tag: 0xA403, typ: 3, count: 1, value: exif_short(0), },
    ExifEntry::{ tag: 0x9209, typ: 3, count: 1, value: exif_short(16), },
  ]
  // GPS IFD
  let gps : Array[ExifEntry] = [
    ExifEntry::{
      tag: 0x0001,
      typ: 2,
      count: 2,
      value: exif_ascii([b'N', b'\x00']),
    },
    ExifEntry::{
      tag: 0x0002,
      typ: 5,
      count: 3,
      value: exif_rational3(39, 1, 54, 1, 0, 1),
    },
    ExifEntry::{
      tag: 0x0003,
      typ: 2,
      count: 2,
      value: exif_ascii([b'E', b'\x00']),
    },
    ExifEntry::{
      tag: 0x0004,
      typ: 5,
      count: 3,
      value: exif_rational3(116, 1, 24, 1, 0, 1),
    },
    ExifEntry::{ tag: 0x0006, typ: 5, count: 1, value: exif_rational(50, 1), },
  ]
  let ifd0_off = 8
  let ifd0_size = exif_ifd_size(ifd0)
  let exif_off = ifd0_off + ifd0_size
  let exif_size = exif_ifd_size(exif_ifd)
  let gps_off = exif_off + exif_size
  let gps_size = exif_ifd_size(gps)
  let data_off = gps_off + gps_size
  let total = data_off +
    exif_data_size(ifd0) +
    exif_data_size(exif_ifd) +
    exif_data_size(gps)
  let tiff : Array[Byte] = Array::make(total, (0).to_byte())
  // TIFF header（小端）
  tiff[0] = b'I'
  tiff[1] = b'I'
  exif_put_u16(tiff, 2, 0x2A)
  exif_put_u32(tiff, 4, ifd0_off)
  // 指针占位：ExifIFD 与 GPSIFD 的 value 写为真实偏移（在 IFD0 中第 5、6 条）
  ifd0[4].value = exif_long(exif_off)
  ifd0[5].value = exif_long(gps_off)
  let cursor : Ref[Int32] = { val: data_off, }
  exif_write_ifd(tiff, ifd0_off, ifd0, 0, cursor)
  exif_write_ifd(tiff, exif_off, exif_ifd, 0, cursor)
  exif_write_ifd(tiff, gps_off, gps, 0, cursor)
  // 包 JPEG：FFD8 + FFE1(APP1) + "Exif\0\0" + TIFF + FFD9
  let out : Array[Byte] = []
  out.push(b'\xFF')
  out.push(b'\xD8')
  out.push(b'\xFF')
  out.push(b'\xE1')
  let app1_len = 2 + 6 + tiff.length()
  out.push(((app1_len >> 8) & 0xFF).to_byte())
  out.push((app1_len & 0xFF).to_byte())
  for b in exif_ascii([b'E', b'x', b'i', b'f', b'\x00', b'\x00']) {
    out.push(b)
  }
  for b in tiff {
    out.push(b)
  }
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}
