///|
/// # npm-wasm 导出层（S12）
///
/// 只做三件事：把 base64 当输入、把 JSON(base64) 当输出。
/// 这样 wasm-gc 侧只需要 JS String Builtin（`wasm:js-string`），
/// 不需要在 JS 里操作 MoonBit 的 GC 对象；Node 侧用 Buffer 做 base64 转换。
///
/// 导出的三个入口：
/// - `image_info(base64) -> JSON`：格式/尺寸/通道/体积；
/// - `image_convert(base64, format, quality) -> JSON{data}`：可写格式互转，`format=best` 选最小；
/// - `image_resize(base64, w, h, mode, format, quality) -> JSON{data}`：cover / contain 缩放。

///|
/// 本包自己的 JSON 对象别名（不复用 imgcli 的私有类型）。
type Out = Map[String, @json.Json]

///|
fn jstr(s : String) -> @json.Json {
  @json.Json::string(s)
}

///|
fn jnum(n : Int32) -> @json.Json {
  @json.Json::number(n.to_double())
}

///|
fn jbool(b : Bool) -> @json.Json {
  @json.Json::boolean(b)
}

///|
fn format_name(f : @types.ImageFormat) -> String {
  match f {
    @types.ImageFormat::Png => "png"
    @types.ImageFormat::Jpeg => "jpeg"
    @types.ImageFormat::Bmp => "bmp"
    @types.ImageFormat::Gif => "gif"
    @types.ImageFormat::Webp => "webp"
    @types.ImageFormat::Qoi => "qoi"
    @types.ImageFormat::Pnm => "pnm"
    @types.ImageFormat::Tga => "tga"
    _ => "unknown"
  }
}

///|
fn parse_format_arg(s : String) -> @types.ImageFormat raise @types.ImageError {
  match s.to_lower() {
    "png" => @types.ImageFormat::Png
    "jpeg" | "jpg" => @types.ImageFormat::Jpeg
    "bmp" => @types.ImageFormat::Bmp
    "gif" => @types.ImageFormat::Gif
    "webp" => @types.ImageFormat::Webp
    "qoi" => @types.ImageFormat::Qoi
    "pnm" | "ppm" => @types.ImageFormat::Pnm
    "tga" => @types.ImageFormat::Tga
    _ =>
      raise @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "不支持的输出格式: \{s}（可用 png/jpeg/webp/bmp/qoi/pnm/tga/gif/best）",
      )
  }
}

///|
fn b64_decode(text : String) -> Bytes raise @types.ImageError {
  @base64.decode(text) catch {
    _ =>
      raise @types.ImageError::Decode(
        @types.ErrorCode::InvalidArgument,
        "base64 解码失败：输入不是合法的 base64",
      )
  }
}

///|
fn load(b64 : String) -> (@types.Image, Bytes) raise @types.ImageError {
  let input = b64_decode(b64)
  let img = @lib.decode_with_limits(
    input,
    @types.DecodeLimits::default_limits(),
  )
  (img, input)
}

///|
fn err_json(e : @types.ImageError) -> String {
  let code = e.code()
  @json.Json::object({
    "ok": jbool(false),
    "code": jstr(code),
    "message": jstr(e.message()),
    "hint": jstr(@types.image_error_hint(code)),
  }).stringify()
}

///|
fn ok_meta(img : @types.Image, extra : Out) -> Out {
  extra["ok"] = jbool(true)
  extra["width"] = jnum(img.width.to_int())
  extra["height"] = jnum(img.height.to_int())
  extra["channels"] = jnum(img.channels.to_int())
  extra
}

///|
fn info_impl(b64 : String) -> String raise @types.ImageError {
  let input = b64_decode(b64)
  let (w, h) = @lib.check_decode_budget(
    input,
    @types.DecodeLimits::default_limits(),
  )
  @json.Json::object({
    "ok": jbool(true),
    "format": jstr(format_name(@lib.detect_format(input))),
    "width": jnum(w.to_int()),
    "height": jnum(h.to_int()),
    "bytes": jnum(input.length()),
  }).stringify()
}

///|
fn convert_impl(
  b64 : String,
  format : String,
  quality : Int32,
) -> String raise @types.ImageError {
  let (img, _) = load(b64)
  let enc : @lib.EncodedImage = if format.to_lower() == "best" {
    @lib.encode_best(img, quality)
  } else {
    let fmt = parse_format_arg(format)
    let data = @lib.save_image_with_quality(img, fmt, quality) catch {
      e => raise @types.image_error_from_load(e)
    }
    { format: fmt, bytes: data, }
  }
  let out = ok_meta(img, {
    "format": jstr(format_name(enc.format)),
    "bytes": jnum(enc.bytes.length()),
    "data": jstr(@base64.encode(enc.bytes)),
  })
  @json.Json::object(out).stringify()
}

///|
fn resize_impl(
  b64 : String,
  w : Int32,
  h : Int32,
  mode : String,
  format : String,
  quality : Int32,
) -> String raise @types.ImageError {
  if w <= 0 || h <= 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "resize 需要正整数宽高（收到 \{w}x\{h}）",
    )
  }
  let (img, _) = load(b64)
  let resized = try {
    if mode.to_lower() == "contain" {
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
  let enc : @lib.EncodedImage = if format.to_lower() == "best" {
    @lib.encode_best(resized, quality)
  } else {
    let fmt = parse_format_arg(format)
    let data = @lib.save_image_with_quality(resized, fmt, quality) catch {
      e => raise @types.image_error_from_load(e)
    }
    { format: fmt, bytes: data, }
  }
  let out = ok_meta(resized, {
    "format": jstr(format_name(enc.format)),
    "bytes": jnum(enc.bytes.length()),
    "data": jstr(@base64.encode(enc.bytes)),
  })
  @json.Json::object(out).stringify()
}

///|
#export_name("image_info")
pub fn image_info(b64 : String) -> String {
  info_impl(b64) catch {
    e => err_json(e)
  }
}

///|
#export_name("image_convert")
pub fn image_convert(b64 : String, format : String, quality : Int32) -> String {
  convert_impl(b64, format, quality) catch {
    e => err_json(e)
  }
}

///|
#export_name("image_resize")
pub fn image_resize(
  b64 : String,
  w : Int32,
  h : Int32,
  mode : String,
  format : String,
  quality : Int32,
) -> String {
  resize_impl(b64, w, h, mode, format, quality) catch {
    e => err_json(e)
  }
}
