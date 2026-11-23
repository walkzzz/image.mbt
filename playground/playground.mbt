///|
/// 浏览器演示导出层（JavaScript 后端）。
/// 只使用 f64 / Int32 / String 参数，PNG 以十六进制字符串跨边界，避免复杂 ABI。

let hex_chars : Array[Char] = [
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
]

///|
fn hex_value(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else if c >= 'A' && c <= 'F' {
    c.to_int() - 'A'.to_int() + 10
  } else {
    0
  }
}

///|
fn bytes_to_hex(data : Bytes) -> String {
  let out = StringBuilder()
  for i in 0..<data.length() {
    let value = data[i].to_int()
    out.write_char(hex_chars[(value >> 4) & 0xF])
    out.write_char(hex_chars[value & 0xF])
  }
  out.to_string()
}

///|
fn hex_to_bytes(hex : String) -> Bytes {
  let chars = hex.to_array()
  let count = chars.length() / 2
  let data : Array[Byte] = Array::make(count, b'\x00')
  for i in 0..<count {
    let hi = hex_value(chars[i * 2])
    let lo = hex_value(chars[i * 2 + 1])
    data[i] = ((hi << 4) | lo).to_byte()
  }
  Bytes::from_array(data)
}

///|
#export_name("img_version")
pub fn img_version() -> String {
  "0.1.1"
}

///|
/// 文本 → QR PNG（hex）。
#export_name("img_qr_png_hex")
pub fn img_qr_png_hex(
  text : String,
  module_px : Int32,
  quiet_zone : Int32,
) -> String {
  let image = @testgen.render_qr(
    @encoding/utf8.encode(text),
    module_px=module_px,
    quiet_zone=quiet_zone,
  )
  bytes_to_hex(@lib.encode_png(image))
}

///|
/// 文本 → QR → 亮度 / 方框模糊 → PNG（hex）。
#export_name("img_qr_filter_png_hex")
pub fn img_qr_filter_png_hex(
  text : String,
  brightness : Int32,
  blur_radius : Int32,
) -> String {
  try {
    let image = @testgen.render_qr(@encoding/utf8.encode(text), module_px=6, quiet_zone=2)
    let bright = @color.adjust_brightness(image, brightness)
    let filtered = @filter.box_blur(bright, blur_radius)
    bytes_to_hex(@lib.encode_png(filtered))
  } catch {
    _ => ""
  }
}

///|
/// PNG（hex）→ 摘要：尺寸、通道、格式、字节数。
#export_name("img_png_summary")
pub fn img_png_summary(png_hex : String) -> String {
  if png_hex.length() == 0 {
    return ""
  }
  try {
    @lib.get_image_summary(hex_to_bytes(png_hex))
  } catch {
    _ => ""
  }
}