///|
type Out = Map[String, @json.Json]

///|
/// # imgtool — 可被脚本 / MCP / agent 调用的图像命令行
///
/// 设计原则：
/// 1. 参数走 argv，结果走 stdout 的**单行 JSON**，错误也走 JSON；
/// 2. 所有解码走 `decode_with_limits`，因此 `--mem-budget` 在分配前生效；
/// 3. 失败统一输出 `{ok:false, code, message, hint}` 并以退出码 1 结束。

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
    @types.ImageFormat::Tiff => "tiff"
    @types.ImageFormat::Ico => "ico"
    @types.ImageFormat::Cur => "cur"
    @types.ImageFormat::Icns => "icns"
    @types.ImageFormat::Apng => "apng"
    @types.ImageFormat::Avif => "avif"
    @types.ImageFormat::Heif => "heif"
    @types.ImageFormat::JpegXl => "jpeg-xl"
    _ => "unknown"
  }
}

///|
fn parse_format(s : String) -> @types.ImageFormat raise @types.ImageError {
  match s {
    "png" => @types.ImageFormat::Png
    "jpeg" | "jpg" => @types.ImageFormat::Jpeg
    "bmp" => @types.ImageFormat::Bmp
    "webp" => @types.ImageFormat::Webp
    "qoi" => @types.ImageFormat::Qoi
    "pnm" | "ppm" => @types.ImageFormat::Pnm
    "tga" => @types.ImageFormat::Tga
    "gif" => @types.ImageFormat::Gif
    _ =>
      raise @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "不支持的输出格式: \{s}（可用 png/jpeg/bmp/webp/qoi/pnm/tga/gif）",
      )
  }
}

///|
/// 是否为 CLI 能写出的格式（读得进但写不出的容器如 TIFF/ICO 不参与输出推断）。
fn is_writable_format(f : @types.ImageFormat) -> Bool {
  match f {
    @types.ImageFormat::Png
    | @types.ImageFormat::Jpeg
    | @types.ImageFormat::Bmp
    | @types.ImageFormat::Webp
    | @types.ImageFormat::Qoi
    | @types.ImageFormat::Pnm
    | @types.ImageFormat::Tga
    | @types.ImageFormat::Gif => true
    _ => false
  }
}

///|
/// 按输出文件扩展名推断格式（大小写不敏感）。写不出或不认识的扩展名返回 None。
///
/// 这条是 S07 dogfood 的第一号 friction：`decode a.png b.jpg` 早先恒写 PNG，
/// 下游拿到 `.jpg` 里装着 PNG 字节，再被别的工具按扩展名当 JPEG 读就会报错。
fn format_from_ext(path : String) -> @types.ImageFormat? {
  let lower = path.to_lower()
  let table : Array[(String, @types.ImageFormat)] = [
    (".png", @types.ImageFormat::Png),
    (".jpg", @types.ImageFormat::Jpeg),
    (".jpeg", @types.ImageFormat::Jpeg),
    (".jpe", @types.ImageFormat::Jpeg),
    (".webp", @types.ImageFormat::Webp),
    (".bmp", @types.ImageFormat::Bmp),
    (".qoi", @types.ImageFormat::Qoi),
    (".pnm", @types.ImageFormat::Pnm),
    (".ppm", @types.ImageFormat::Pnm),
    (".pgm", @types.ImageFormat::Pnm),
    (".tga", @types.ImageFormat::Tga),
    (".gif", @types.ImageFormat::Gif),
  ]
  let mut i = 0
  while i < table.length() {
    let (ext, fmt) = table[i]
    if lower.has_suffix(ext) {
      return Some(fmt)
    }
    i += 1
  }
  None
}

///|
/// 决定输出格式，优先级：`--format`（显式，`auto` 视为未指定）> 输出扩展名 > `fallback`。
fn out_format(
  flags : Flags,
  dst : String,
  fallback : @types.ImageFormat,
) -> @types.ImageFormat raise @types.ImageError {
  match flags.values.get("format") {
    Some(f) =>
      if f != "auto" {
        return parse_format(f)
      }
    None => ()
  }
  match format_from_ext(dst) {
    Some(f) => f
    None => fallback
  }
}

///|
/// 读源文件并给出「原样另存时该用的格式」：源格式可写就沿用，否则退回 PNG。
fn src_out_format(src : String) -> @types.ImageFormat raise @types.ImageError {
  let f = @lib.detect_format(read_bytes(src))
  if is_writable_format(f) {
    f
  } else {
    @types.ImageFormat::Png
  }
}

///|
/// 极简 flag 解析：位置参数收集 + `--key value` 表。
struct Flags {
  positional : Array[String]
  values : Map[String, String]
}

///|
pub fn parse_flags(args : Array[String]) -> Flags {
  let pos : Array[String] = []
  let vals : Map[String, String] = Map([])
  let mut i = 0
  while i < args.length() {
    let a = args[i]
    if a.has_prefix("--") {
      let key = match a.strip_prefix("--") {
        Some(rest) => rest.to_owned()
        None => a
      }
      if i + 1 < args.length() && !args[i + 1].has_prefix("--") {
        vals[key] = args[i + 1]
        i += 2
      } else {
        vals[key] = "true"
        i += 1
      }
    } else {
      pos.push(a)
      i += 1
    }
  }
  { positional: pos, values: vals }
}

///|
fn Flags::int(self : Flags, key : String, default : Int32) -> Int32 {
  match self.values.get(key) {
    Some(v) =>
      try {
        @string.parse_int(v)
      } catch {
        _ => default
      }
    None => default
  }
}

///|
fn Flags::has(self : Flags, key : String) -> Bool {
  self.values.contains(key)
}

///|
fn Flags::str(self : Flags, key : String, default : String) -> String {
  match self.values.get(key) {
    Some(v) => v
    None => default
  }
}

///|
pub fn limits_of(flags : Flags) -> @types.DecodeLimits {
  let base = @types.DecodeLimits::default_limits()
  let budget = flags.int("mem-budget", 0)
  let mut l = base
  if budget > 0 {
    let b = budget.to_int64()
    l = { max_pixels: b / 8L, max_bytes: b, max_ms: base.max_ms }
  }
  if flags.has("max-pixels") {
    l = { max_pixels: flags.int("max-pixels", 0).to_int64(), max_bytes: l.max_bytes, max_ms: l.max_ms }
  }
  l
}

///|
fn read_image(path : String, limits : @types.DecodeLimits) -> @types.Image raise @types.ImageError {
  @lib.decode_with_limits(read_bytes(path), limits)
}

///|
fn save_image(
  img : @types.Image,
  path : String,
  format : @types.ImageFormat,
  quality : Int32,
) -> Int raise @types.ImageError {
  let bytes = try {
    @lib.save_image_with_quality(img, format, quality)
  } catch {
    e => raise @types.image_error_from_load(e)
  }
  write_bytes(path, bytes)
  bytes.length()
}

///|
fn result(pairs : Out) -> Out {
  pairs["ok"] = jbool(true)
  pairs
}

///|
/// `info` — 只读头部，不整图解码，超大图也能秒回。
fn cmd_info(flags : Flags) -> Out raise @types.ImageError {
  let path = flags.positional[0]
  let bytes = read_bytes(path)
  let (w, h) = @lib.check_decode_budget(bytes, limits_of(flags))
  result({
    "path": jstr(path),
    "format": jstr(format_name(@lib.detect_format(bytes))),
    "width": jnum(w.to_int()),
    "height": jnum(h.to_int()),
    "bytes": jnum(bytes.length().to_int()),
  })
}

///|
/// `decode` — 解码后重写，输出格式取自 `--format` 或**输出扩展名**（都没有则 PNG）。
fn cmd_decode(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let img = read_image(src, limits_of(flags))
  let fmt = out_format(flags, dst, @types.ImageFormat::Png)
  let size = save_image(img, dst, fmt, flags.int("quality", 90))
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "format": jstr(format_name(fmt)),
    "width": jnum(img.width),
    "height": jnum(img.height),
    "channels": jnum(img.channels),
    "bytes": jnum(size.to_int()),
  })
}

///|
/// `encode` — 与 `decode` 同路径；语义上强调输出去哪，便于 agent 选词。
fn cmd_encode(flags : Flags) -> Out raise @types.ImageError {
  cmd_decode(flags)
}

///|
/// `resize` — `--width/--height` + `--mode cover|contain`。
fn cmd_resize(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let w = flags.int("width", 0)
  let h = flags.int("height", 0)
  if w <= 0 || h <= 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "resize 需要正整数 --width 与 --height（当前 \{w}x\{h}）",
    )
  }
  let img = read_image(src, limits_of(flags))
  let mode = flags.str("mode", "cover")
  let out = try {
    if mode == "contain" {
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
  let fmt = out_format(flags, dst, src_out_format(src))
  let size = save_image(out, dst, fmt, flags.int("quality", 90))
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "width": jnum(out.width),
    "height": jnum(out.height),
    "mode": jstr(mode),
    "format": jstr(format_name(fmt)),
    "bytes": jnum(size.to_int()),
  })
}

///|
/// `crop` — `--x/--y/--width/--height`，越界直接拒绝（不静默裁剪）。
fn cmd_crop(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let img = read_image(src, limits_of(flags))
  let x = flags.int("x", 0)
  let y = flags.int("y", 0)
  let w = flags.int("width", 0)
  let h = flags.int("height", 0)
  let out = try {
    @transform.crop(img, x, y, w, h)
  } catch {
    e => raise @types.image_error_from_load(e)
  }
  let fmt = out_format(flags, dst, src_out_format(src))
  let size = save_image(out, dst, fmt, flags.int("quality", 90))
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "x": jnum(x),
    "y": jnum(y),
    "width": jnum(out.width),
    "height": jnum(out.height),
    "format": jstr(format_name(fmt)),
    "bytes": jnum(size.to_int()),
  })
}

///|
/// `analyze` — 尺寸/通道/均值/极值/标准差，供 agent 判断过曝、全黑、低对比。
fn cmd_analyze(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let bytes_in = read_bytes(src)
  let img = @lib.decode_with_limits(bytes_in, limits_of(flags))
  let ch = img.channels
  let n = img.width * img.height
  let sums : Array[Double] = Array::make(4, 0.0)
  let mins : Array[Int32] = [255, 255, 255, 255]
  let maxs : Array[Int32] = [0, 0, 0, 0]
  let sq : Array[Double] = Array::make(4, 0.0)
  for i in 0..<n {
    for c in 0..<ch {
      let v = img.data[i * ch + c].to_int()
      sums[c] += v.to_double()
      if v < mins[c] {
        mins[c] = v
      }
      if v > maxs[c] {
        maxs[c] = v
      }
      sq[c] += v.to_double() * v.to_double()
    }
  }
  let mean_json : Array[@json.Json] = []
  let std_json : Array[@json.Json] = []
  let min_json : Array[@json.Json] = []
  let max_json : Array[@json.Json] = []
  for c in 0..<ch {
    let m = sums[c] / n.to_double()
    mean_json.push(@json.Json::number(m))
    let variance = sq[c] / n.to_double() - m * m
    std_json.push(@json.Json::number(if variance > 0.0 { variance.sqrt() } else { 0.0 }))
    min_json.push(jnum(mins[c]))
    max_json.push(jnum(maxs[c]))
  }
  result({
    "path": jstr(src),
    "format": jstr(format_name(@lib.detect_format(bytes_in))),
    "width": jnum(img.width),
    "height": jnum(img.height),
    "channels": jnum(ch),
    "mean": @json.Json::array(mean_json),
    "std": @json.Json::array(std_json),
    "min": @json.Json::array(min_json),
    "max": @json.Json::array(max_json),
  })
}

///|
/// `sanitize` — 三档脱敏（metadata / standard / strict）：
/// 重编码剥元数据 + 已知区域块均值打码 + strict 全图 box blur。
fn cmd_sanitize(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let img = read_image(src, limits_of(flags))
  let policy = flags.str("policy", "metadata")
  // 格式优先级：`--format` > 输出扩展名 > policy 默认（strict 强制 png，其余沿用源格式能写的那支）。
  // 早先只有 `--format` 与「源格式」两条路，`sanitize a.jpg out.png` 会写出 JPEG 字节，
  // 下游按扩展名当 PNG 读就炸——这是 S07 dogfood 的第四号 friction。
  let base = if policy == "strict" {
    @types.ImageFormat::Png
  } else {
    match @lib.detect_format(read_bytes(src)) {
      @types.ImageFormat::Jpeg => @types.ImageFormat::Jpeg
      @types.ImageFormat::Webp => @types.ImageFormat::Webp
      _ => @types.ImageFormat::Png
    }
  }
  let fmt = out_format(flags, dst, base)
  let raw_regions = match flags.values.get("regions") {
    Some(v) => v
    None =>
      match flags.values.get("region") {
        Some(v) => v
        None => ""
      }
  }
  let regions = parse_regions(raw_regions)
  let block = flags.int("block", 12)
  let blur = flags.int("blur", 8)
  let quality = flags.int("quality", 90)
  let res = sanitize_image(img, policy, regions, block, blur, fmt, quality)
  write_bytes(dst, res.bytes)
  let hits = metadata_hits(res.bytes)
  let mut hit_text = ""
  for h in hits {
    if hit_text.length() > 0 {
      hit_text = hit_text + ";"
    }
    hit_text = hit_text + h
  }
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "policy": jstr(policy),
    "format": jstr(format_name(res.format)),
    "bytes": jnum(res.bytes.length().to_int()),
    "regions_redacted": jnum(res.redacted),
    "blurred": jbool(res.blurred),
    "metadata_free": jbool(hits.length() == 0),
    "metadata_hits": jstr(hit_text),
  })
}

///|
pub fn contains_ascii(data : Bytes, needle : String) -> Bool {
  let n = needle.length()
  let m = data.length()
  if n == 0 || m < n {
    return false
  }
  let mut i = 0
  while i <= m - n {
    let mut hit = true
    let mut j = 0
    while j < n {
      if data[i + j].to_int() != needle.at(j).to_int() {
        hit = false
        break
      }
      j += 1
    }
    if hit {
      return true
    }
    i += 1
  }
  false
}

///|
pub fn error_json(e : @types.ImageError) -> Out {
  let code = e.code()
  {
    "ok": jbool(false),
    "code": jstr(code),
    "message": jstr(e.message()),
    "hint": jstr(@types.image_error_hint(code)),
  }
}

///|
/// CLI 版本号（与 `moon.mod` 的 version 由 `scripts/check_version.mjs` 强制对齐）。
pub let version : String = "0.1.8"

///|
/// `imgtool help` / `--help` / `-h` 打印的人类可读用法（不输出 JSON）。
pub fn help_text() -> String {
  "imgtool \{version} — 图像命令行（结果走单行 JSON，错误也走 JSON 并以退出码 1 结束）\n\n" +
  "用法:\n" +
  "  imgtool info     <in>\n" +
  "  imgtool decode   <in> <out> [--format auto|png|jpeg|webp|bmp|qoi|pnm|tga|gif] [--quality 1-100]\n" +
  "  imgtool encode   <in> <out> [--format ...] [--quality 1-100]\n" +
  "  imgtool resize   <in> <out> --width N --height N [--mode cover|contain] [--format ...]\n" +
  "  imgtool crop     <in> <out> --x N --y N --width N --height N [--format ...]\n" +
  "  imgtool analyze  <in>\n" +
  "  imgtool sanitize <in> <out> [--policy metadata|standard|strict] [--regions \"x,y,w,h;...\"]\n" +
  "                             [--block N] [--blur N] [--format ...] [--quality 1-100]\n" +
  "  imgtool help | version\n\n" +
  "通用:\n" +
  "  --format 省略时按**输出扩展名**推断，再无则 PNG（resize/crop 退回源格式）\n" +
  "  --mem-budget BYTES  解码前设内存上限（含 max_pixels = BYTES/8）\n" +
  "  --max-pixels N      单独限制像素数\n"
}

///|
/// `imgtool version` / `--version` / `-v` 打印版本行（不输出 JSON）。
pub fn version_text() -> String {
  "imgtool \{version} (walkzzz/image.mbt)"
}

///|
fn usage() -> Out {
  {
    "ok": jbool(false),
    "code": jstr("process/invalid_argument"),
    "message": jstr("未知子命令。可用: info decode encode resize crop analyze sanitize help version"),
    "hint": jstr(
      "跑 `imgtool help` 看完整用法；每个子命令都输出单行 JSON；省略 --format 时按输出扩展名推断",
    ),
  }
}

///|
pub fn dispatch(args : Array[String]) -> Out raise @types.ImageError {
  if args.length() == 0 {
    return usage()
  }
  let sub = args[0]
  let rest : Array[String] = []
  for i in 1..<args.length() {
    rest.push(args[i])
  }
  let flags = parse_flags(rest)
  match sub {
    "info" => cmd_info(flags)
    "decode" => cmd_decode(flags)
    "encode" => cmd_encode(flags)
    "resize" => cmd_resize(flags)
    "crop" => cmd_crop(flags)
    "analyze" => cmd_analyze(flags)
    "sanitize" => cmd_sanitize(flags)
    _ => usage()
  }
}

///|
pub fn run() -> Unit {
  let argv = @env.args()
  let args : Array[String] = []
  let mut i = 1
  while i < argv.length() {
    args.push(argv[i])
    i += 1
  }
  // help / version 走人类可读输出（其余子命令一律单行 JSON，方便 agent 解析）。
  // 这两个是 S07 dogfood 的第一号 friction：早先连 `imgtool --help` 都只回一句 JSON 报错。
  let mut want_help = false
  let mut want_version = false
  for a in args {
    if a == "help" || a == "--help" || a == "-h" {
      want_help = true
    }
    if a == "version" || a == "--version" || a == "-v" {
      want_version = true
    }
  }
  if want_help {
    println(help_text())
    return
  }
  if want_version {
    println(version_text())
    return
  }
  let out = try {
    dispatch(args)
  } catch {
    e => error_json(e)
  }
  println(@json.Json::object(out).stringify())
  let ok = match out.get("ok") {
    Some(@json.Json::True) => true
    _ => false
  }
  if !ok {
    @env.exit(1)
  }
}
