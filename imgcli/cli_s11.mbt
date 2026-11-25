///|
/// # S11：CLI 扩到 8 个子命令
///
/// 新增能力：
/// - `convert`：任意可写格式互转，`--best` 走 S10 的"逐候选实编取最小"；
/// - `filter`：box / gaussian / sharpen / median / bilateral / nlm 六种算子；
/// - `bench`：解码、编码、缩放各跑 N 轮，给每轮均值（微秒）；
/// - 写盘类子命令统一支持 `--dry-run`；
/// - 路径写 `-` 即 stdin / stdout（此时 JSON 结果改走 stderr）。

///|
/// 读源：`-` 走 stdin，其余走文件。
pub fn src_bytes(path : String) -> Bytes raise @types.ImageError {
  if is_stdin_path(path) {
    match read_stdin_bytes() {
      Some(b) => b
      None =>
        raise @types.ImageError::Decode(
          @types.ErrorCode::UnsupportedFormat,
          "当前目标不支持从 stdin 读图，请以 native 目标构建",
        )
    }
  } else {
    read_bytes(path)
  }
}

///|
/// 源字节对应的"原样另存"格式：可写就沿用，否则退回 PNG。
pub fn writable_format_of(data : Bytes) -> @types.ImageFormat {
  let f = @lib.detect_format(data)
  if is_writable_format(f) {
    f
  } else {
    @types.ImageFormat::Png
  }
}

///|
/// 编码为字节；把 `LoadError` 统一折成 `ImageError`。
pub fn encode_image(
  img : @types.Image,
  format : @types.ImageFormat,
  quality : Int32,
) -> Bytes raise @types.ImageError {
  @lib.save_image_with_quality(img, format, quality) catch {
    e => raise @types.image_error_from_load(e)
  }
}

///|
/// 写出：`-` 走 stdout，`--dry-run` 只算不写。返回是否写到了 stdout。
pub fn emit_bytes(
  dst : String,
  data : Bytes,
  dry : Bool,
) -> Bool raise @types.ImageError {
  if dry {
    return false
  }
  if is_stdout_path(dst) {
    if !write_stdout_bytes(data) {
      raise @types.ImageError::Process(
        @types.ErrorCode::UnsupportedFormat,
        "当前目标不支持写 stdout，请以 native 目标构建",
      )
    }
    return true
  }
  write_bytes(dst, data)
  false
}

///|
/// 校验命令行里的 quality，越界直接报错（不静默夹取）。
pub fn quality_of(flags : Flags) -> Int32 raise @types.ImageError {
  let q = flags.int("quality", 90)
  if q < 1 || q > 100 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "quality 必须在 1-100（收到 \{q}）",
    )
  }
  q
}

///|
/// 解析 `--formats png,jpeg,webp` 这种逗号列表。
pub fn parse_format_list(text : String) -> Array[String] {
  let out : Array[String] = []
  for name in text.split(",") {
    let t = name.trim()
    if t.length() > 0 {
      out.push(t.to_owned())
    }
  }
  out
}

///|
/// `convert`（`decode` / `encode` 作为同义别名保留）。
fn cmd_convert(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let input = src_bytes(src)
  let img = @lib.decode_with_limits(input, limits_of(flags))
  let quality = quality_of(flags)
  let dry = flags.has("dry-run")
  let best = flags.has("best")
  let explicit_format = match flags.values.get("format") {
    Some(f) => f != "auto"
    None => false
  }
  if best && explicit_format {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "--best 与 --format 不能同时给：--best 自己选最小体积的格式",
    )
  }
  if !best && flags.has("max-bytes") {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "--max-bytes 需要配合 --best 使用（它约束的是选格式后的体积上限）",
    )
  }
  let enc : @lib.EncodedImage = if best {
    let max_bytes = flags.int("max-bytes", 0).to_int64()
    if max_bytes > 0 {
      @lib.encode_best_limited(img, quality, max_bytes)
    } else {
      @lib.encode_best(img, quality)
    }
  } else {
    let fmt = out_format(flags, dst, @types.ImageFormat::Png)
    { format: fmt, bytes: encode_image(img, fmt, quality), }
  }
  let to_stdout = emit_bytes(dst, enc.bytes, dry)
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "format": jstr(format_name(enc.format)),
    "format_source": jstr(if best { "best" } else { "explicit" }),
    "width": jnum(img.width),
    "height": jnum(img.height),
    "channels": jnum(img.channels),
    "bytes": jnum(enc.bytes.length().to_int()),
    "dry_run": jbool(dry),
    "wrote": jbool(!dry),
    "to_stdout": jbool(to_stdout),
  })
}

///|
/// 把 `--op` 归一成 6 个规范名；未知返回 None。
pub fn normalize_filter_op(s : String) -> String? {
  match s {
    "box" | "blur" => Some("box")
    "gaussian" | "gauss" => Some("gaussian")
    "sharpen" | "sharp" => Some("sharpen")
    "median" => Some("median")
    "bilateral" => Some("bilateral")
    "nlm" | "denoise" => Some("nlm")
    _ => None
  }
}

///|
fn apply_filter(
  img : @types.Image,
  op : String,
  radius : Int32,
  sigma : Float,
  amount : Float,
  ksize : Int32,
  sigma_color : Float,
  patch : Int32,
  search : Int32,
  h : Int32,
) -> @types.Image raise @types.ImageError {
  let sigma_eff = if sigma > 0.0F {
    sigma
  } else {
    let half = radius.to_double() / 2.0
    Float::from_double(if half < 0.5 { 0.5 } else { half })
  }
  try {
    match op {
      "box" => @filter.box_blur(img, radius)
      "gaussian" => @filter.gaussian_blur(img, radius, sigma_eff)
      "sharpen" => @filter.sharpen(img, amount)
      "median" => @filter.median_blur(img, ksize)
      "bilateral" =>
        @filter.bilateral_filter(img, radius, sigma_eff, sigma_color)
      _ => @filter.nlm_denoise(img, patch_size=patch, search_size=search, h~)
    }
  } catch {
    e => raise @types.image_error_from_load(e)
  }
}

///|
/// `filter` — 六种滤波/锐化/去噪算子，参数全部走 flag。
fn cmd_filter(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let dst = flags.positional[1]
  let raw_op = flags.str("op", "box")
  let op = match normalize_filter_op(raw_op) {
    Some(o) => o
    None =>
      raise @types.ImageError::Process(
        @types.ErrorCode::InvalidArgument,
        "未知 --op: \{raw_op}（可用 box/gaussian/sharpen/median/bilateral/nlm）",
      )
  }
  let input = src_bytes(src)
  let img = @lib.decode_with_limits(input, limits_of(flags))
  let radius = flags.int("radius", 3)
  if radius < 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "radius 不能为负（收到 \{radius}）",
    )
  }
  let sigma = flags.float("sigma", 0.0F)
  let amount = flags.float("amount", 1.0F)
  let ksize = flags.int("ksize", 3)
  if op == "median" && (ksize < 3 || ksize % 2 == 0) {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "median 的 --ksize 必须是 >=3 的奇数（收到 \{ksize}）",
    )
  }
  let sigma_color = flags.float("sigma-color", 30.0F)
  let patch = flags.int("patch", 3)
  let search = flags.int("search", 7)
  let h = flags.int("h", 10)
  let out = apply_filter(
    img, op, radius, sigma, amount, ksize, sigma_color, patch, search, h,
  )
  let fmt = out_format(flags, dst, writable_format_of(input))
  let quality = quality_of(flags)
  let data = encode_image(out, fmt, quality)
  let dry = flags.has("dry-run")
  let to_stdout = emit_bytes(dst, data, dry)
  result({
    "src": jstr(src),
    "dst": jstr(dst),
    "op": jstr(op),
    "radius": jnum(radius),
    "width": jnum(out.width),
    "height": jnum(out.height),
    "format": jstr(format_name(fmt)),
    "bytes": jnum(data.length().to_int()),
    "dry_run": jbool(dry),
    "wrote": jbool(!dry),
    "to_stdout": jbool(to_stdout),
  })
}

///|
/// 解码跑 `iters` 轮，返回每轮均值（微秒）。先热身一轮避开首次分配。
fn bench_decode(
  input : Bytes,
  limits : @types.DecodeLimits,
  iters : Int32,
) -> Double raise @types.ImageError {
  ignore(@lib.decode_with_limits(input, limits))
  let ts = @bench.monotonic_clock_start()
  for _ in 0..<iters {
    ignore(@lib.decode_with_limits(input, limits))
  }
  @bench.monotonic_clock_end(ts) / iters.to_double()
}

///|
/// 编码跑 `iters` 轮，返回每轮均值（微秒）。
fn bench_encode(
  img : @types.Image,
  fmt : @types.ImageFormat,
  quality : Int32,
  iters : Int32,
) -> Double raise @types.ImageError {
  ignore(encode_image(img, fmt, quality))
  let ts = @bench.monotonic_clock_start()
  for _ in 0..<iters {
    ignore(encode_image(img, fmt, quality))
  }
  @bench.monotonic_clock_end(ts) / iters.to_double()
}

///|
fn resize_checked(
  img : @types.Image,
  w : Int32,
  h : Int32,
) -> @types.Image raise @types.ImageError {
  @transform.resize_to_cover(img, w, h) catch {
    e => raise @types.image_error_from_load(e)
  }
}

///|
/// `bench` — 解码 + 逐格式编码 +（可选）缩放的均值耗时，单位微秒。
fn cmd_bench(flags : Flags) -> Out raise @types.ImageError {
  let src = flags.positional[0]
  let input = src_bytes(src)
  let limits = limits_of(flags)
  let iters = flags.int("iters", 5)
  if iters < 1 || iters > 1000 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "iters 必须在 1-1000（收到 \{iters}）",
    )
  }
  let quality = quality_of(flags)
  let img = @lib.decode_with_limits(input, limits)
  let decode_us = bench_decode(input, limits, iters)
  let encode_json : Out = Map([])
  for name in parse_format_list(flags.str("formats", "png,jpeg,webp")) {
    let parsed : @types.ImageFormat? = Some(parse_format(name)) catch {
      _ => None
    }
    match parsed {
      Some(fmt) => {
        let mut encoded_len = -1
        let mut us = -1.0
        try {
          encoded_len = encode_image(img, fmt, quality).length()
          us = bench_encode(img, fmt, quality, iters)
        } catch {
          _ => ()
        }
        let entry : Out = if us < 0.0 {
          { "error": jstr("编码失败（该格式可能不支持写出）") }
        } else {
          { "us": @json.Json::number(us), "bytes": jnum(encoded_len) }
        }
        encode_json[format_name(fmt)] = @json.Json::object(entry)
      }
      None => ()
    }
  }
  let base : Out = {
    "path": jstr(src),
    "format": jstr(format_name(@lib.detect_format(input))),
    "width": jnum(img.width),
    "height": jnum(img.height),
    "channels": jnum(img.channels),
    "iters": jnum(iters),
    "decode_us": @json.Json::number(decode_us),
    "encode": @json.Json::object(encode_json),
  }
  let rw = flags.int("width", 0)
  let rh = flags.int("height", 0)
  if rw > 0 && rh > 0 {
    ignore(resize_checked(img, rw, rh))
    let ts = @bench.monotonic_clock_start()
    for _ in 0..<iters {
      ignore(resize_checked(img, rw, rh))
    }
    let us = @bench.monotonic_clock_end(ts) / iters.to_double()
    let entry : Out = {
      "width": jnum(rw),
      "height": jnum(rh),
      "us": @json.Json::number(us),
    }
    base["resize"] = @json.Json::object(entry)
  }
  result(base)
}

///|
/// 判断本次调用是否把二进制写到 stdout（决定 JSON 走 stdout 还是 stderr）。
///
/// 只有写盘类子命令、dst 为 `-`、且不是 `--dry-run` 时才成立。
pub fn json_to_stderr(args : Array[String]) -> Bool {
  if args.length() < 2 {
    return false
  }
  let sub = args[0]
  let write_sub = match sub {
    "convert"
    | "decode"
    | "encode"
    | "resize"
    | "crop"
    | "filter"
    | "sanitize" => true
    _ => false
  }
  if !write_sub {
    return false
  }
  let rest : Array[String] = []
  for i in 1..<args.length() {
    rest.push(args[i])
  }
  let flags = parse_flags(rest)
  if flags.has("dry-run") {
    return false
  }
  flags.positional.length() >= 2 && is_stdout_path(flags.positional[1])
}
