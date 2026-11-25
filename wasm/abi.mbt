///|
/// # wasm（MVP）字节 ABI 导出层（S12）
///
/// 为什么单独一层：wasm-gc 的字符串常量是 `(ref extern)` 全局导入，Node 侧无法提供
/// 非空 externref 全局，只能在 MoonBit 自己的 host 里实例化。wasm（MVP）没有这个问题：
/// 线性内存可导出，`Bytes` 参数/返回值就是内存里的 i32 指针，JS 直接读写。
///
/// 约定：
/// - 输入：先调 `abi_alloc(n)` 拿到指针，把原始字节写进导出内存的同地址；
/// - 输出：函数返回 `Bytes`（= 指针），长度用 `abi_last_len()` 取，数据从同一地址读；
/// - 元信息：`abi_last_ok/format/width/height/channels`；
/// - 错误：`abi_last_ok()==0`，`abi_last_error()` 返回 UTF-8 的 `code\nmessage\nhint`。
///
/// 本文件只在 `--target wasm` 下编译，不影响其它目标。
#cfg(target="wasm")
priv struct AbiState {
  mut ok : Int32
  mut format : Int32
  mut width : Int32
  mut height : Int32
  mut channels : Int32
  mut len : Int32
  mut error : String
}

///|
#cfg(target="wasm")
let state : AbiState = {
  ok: 0,
  format: 0,
  width: 0,
  height: 0,
  channels: 0,
  len: 0,
  error: "",
}

///|
#cfg(target="wasm")
fn empty_bytes() -> Bytes {
  Bytes::make(0, b'\x00')
}

///|
#cfg(target="wasm")
fn format_code(f : @types.ImageFormat) -> Int32 {
  match f {
    @types.ImageFormat::Png => 1
    @types.ImageFormat::Jpeg => 2
    @types.ImageFormat::Webp => 3
    @types.ImageFormat::Gif => 4
    @types.ImageFormat::Bmp => 5
    @types.ImageFormat::Qoi => 6
    @types.ImageFormat::Pnm => 7
    @types.ImageFormat::Tga => 8
    _ => 0
  }
}

///|
#cfg(target="wasm")
fn format_of_code(code : Int32) -> @types.ImageFormat raise @types.ImageError {
  match code {
    1 => @types.ImageFormat::Png
    2 => @types.ImageFormat::Jpeg
    3 => @types.ImageFormat::Webp
    4 => @types.ImageFormat::Gif
    5 => @types.ImageFormat::Bmp
    6 => @types.ImageFormat::Qoi
    7 => @types.ImageFormat::Pnm
    8 => @types.ImageFormat::Tga
    9 => @types.ImageFormat::Unknown // 占位，best 走单独分支
    _ =>
      raise @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "未知格式码: \{code}（可用 1=png 2=jpeg 3=webp 4=gif 5=bmp 6=qoi 7=pnm 8=tga 9=best）",
      )
  }
}

///|
#cfg(target="wasm")
fn set_ok(img : @types.Image, fmt : @types.ImageFormat, size : Int32) -> Unit {
  state.ok = 1
  state.format = format_code(fmt)
  state.width = img.width.to_int()
  state.height = img.height.to_int()
  state.channels = img.channels.to_int()
  state.len = size
  state.error = ""
}

///|
#cfg(target="wasm")
fn set_err(e : @types.ImageError) -> Bytes {
  state.ok = 0
  state.format = 0
  state.width = 0
  state.height = 0
  state.channels = 0
  state.len = 0
  let code = e.code()
  state.error = "\{code}\n\{e.message()}\n\{@types.image_error_hint(code)}"
  empty_bytes()
}

///|
#cfg(target="wasm")
fn encode_payload(
  img : @types.Image,
  code : Int32,
  quality : Int32,
) -> @lib.EncodedImage raise @types.ImageError {
  if code == 9 {
    @lib.encode_best(img, quality)
  } else {
    let fmt = format_of_code(code)
    let data = @lib.save_image_with_quality(img, fmt, quality) catch {
      e => raise @types.image_error_from_load(e)
    }
    { format: fmt, bytes: data, }
  }
}

///|
/// 分配 `n` 字节的输入缓冲，返回其指针（JS 直接往导出内存写）。
#cfg(target="wasm")
#export_name("abi_alloc")
pub fn abi_alloc(n : Int32) -> Bytes {
  if n <= 0 {
    return empty_bytes()
  }
  Bytes::make(n, b'\x00')
}

///|
#cfg(target="wasm")
#export_name("abi_last_len")
pub fn abi_last_len() -> Int32 {
  state.len
}

///|
#cfg(target="wasm")
#export_name("abi_last_ok")
pub fn abi_last_ok() -> Int32 {
  state.ok
}

///|
#cfg(target="wasm")
#export_name("abi_last_format")
pub fn abi_last_format() -> Int32 {
  state.format
}

///|
#cfg(target="wasm")
#export_name("abi_last_width")
pub fn abi_last_width() -> Int32 {
  state.width
}

///|
#cfg(target="wasm")
#export_name("abi_last_height")
pub fn abi_last_height() -> Int32 {
  state.height
}

///|
#cfg(target="wasm")
#export_name("abi_last_channels")
pub fn abi_last_channels() -> Int32 {
  state.channels
}

///|
#cfg(target="wasm")
fn utf8_bytes(s : String) -> Bytes {
  let out : Array[Byte] = []
  for c in s {
    let cp = c.to_int()
    if cp < 0x80 {
      out.push(cp.to_byte())
    } else if cp < 0x800 {
      out.push((0xC0 | (cp >> 6)).to_byte())
      out.push((0x80 | (cp & 0x3F)).to_byte())
    } else if cp < 0x10000 {
      out.push((0xE0 | (cp >> 12)).to_byte())
      out.push((0x80 | ((cp >> 6) & 0x3F)).to_byte())
      out.push((0x80 | (cp & 0x3F)).to_byte())
    } else {
      out.push((0xF0 | (cp >> 18)).to_byte())
      out.push((0x80 | ((cp >> 12) & 0x3F)).to_byte())
      out.push((0x80 | ((cp >> 6) & 0x3F)).to_byte())
      out.push((0x80 | (cp & 0x3F)).to_byte())
    }
  }
  Bytes::from_array(out)
}

///|
#cfg(target="wasm")
#export_name("abi_last_error")
pub fn abi_last_error() -> Bytes {
  let b = utf8_bytes(state.error)
  state.len = b.length()
  b
}

///|
/// 格式/尺寸/体积探测。输入为 `abi_alloc` 分配并写入的原始字节。
#cfg(target="wasm")
#export_name("abi_info")
pub fn abi_info(input : Bytes) -> Bytes {
  try {
    let (w, h) = @lib.check_decode_budget(
      input,
      @types.DecodeLimits::default_limits(),
    )
    let fmt = @lib.detect_format(input)
    state.ok = 1
    state.format = format_code(fmt)
    state.width = w.to_int()
    state.height = h.to_int()
    state.channels = 0
    state.len = input.length()
    state.error = ""
    empty_bytes()
  } catch {
    e => set_err(e)
  }
}

///|
/// 解码 + 重新编码，`code` 见 `format_of_code`（9 = best）。
#cfg(target="wasm")
#export_name("abi_convert")
pub fn abi_convert(input : Bytes, code : Int32, quality : Int32) -> Bytes {
  try {
    let img = @lib.decode_with_limits(
      input,
      @types.DecodeLimits::default_limits(),
    )
    let enc = encode_payload(img, code, quality)
    set_ok(img, enc.format, enc.bytes.length())
    enc.bytes
  } catch {
    e => set_err(e)
  }
}

///|
/// 缩放 + 编码。`mode` 0=cover，1=contain（白底填充）。
#cfg(target="wasm")
#export_name("abi_resize")
pub fn abi_resize(
  input : Bytes,
  w : Int32,
  h : Int32,
  mode : Int32,
  code : Int32,
  quality : Int32,
) -> Bytes {
  if w <= 0 || h <= 0 {
    return set_err(
      @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "resize 需要正整数宽高（收到 \{w}x\{h}）",
      ),
    )
  }
  try {
    let img = @lib.decode_with_limits(
      input,
      @types.DecodeLimits::default_limits(),
    )
    let resized = try {
      if mode == 1 {
        let fill : Array[Byte] = []
        for _ in 0..<img.channels {
          fill.push(b'\xff')
        }
        @transform.resize_to_contain(img, w, h, fill)
      } else {
        @transform.resize_to_cover(img, w, h)
      }
    } catch {
      e => raise @types.image_error_from_load(e)
    }
    let enc = encode_payload(resized, code, quality)
    set_ok(resized, enc.format, enc.bytes.length())
    enc.bytes
  } catch {
    e => set_err(e)
  }
}
