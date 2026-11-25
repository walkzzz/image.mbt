///|
/// # 错误模型 Error model
///
/// 面向"放进服务"的统一错误面：稳定的错误码 + 结构化分类 + 建议动作。
/// 既有 `LoadError` 保持不变（避免动 70 个包），通过 `image_error_from_load` 投影到新模型。
///
/// Stable, structured error surface for service use: stable codes + category + hint.
/// `LoadError` stays untouched; `image_error_from_load` projects it into this model.

///|
/// 稳定错误码（字符串形式是小写蛇形，可直接出现在 JSON 的 `code` 字段）。
/// Stable error codes; the string form is lower_snake_case and safe for a JSON `code` field.
#derive(Eq, @debug.Debug)
pub(all) enum ErrorCode {
  UnsupportedFormat
  InvalidHeader
  InvalidDimensions
  InvalidArgument
  Truncated
  DecodeFailed
  EncodeFailed
  ProcessFailed
  LimitBytes
  LimitPixels
  LimitTime
  Cancelled
}

///|
/// 错误码 → 稳定字符串（小写蛇形，跨版本不变）。Error code to stable lower_snake_case string.
pub fn ErrorCode::to_string(self : ErrorCode) -> String {
  match self {
    UnsupportedFormat => "unsupported_format"
    InvalidHeader => "invalid_header"
    InvalidDimensions => "invalid_dimensions"
    InvalidArgument => "invalid_argument"
    Truncated => "truncated"
    DecodeFailed => "decode_failed"
    EncodeFailed => "encode_failed"
    ProcessFailed => "process_failed"
    LimitBytes => "limit_bytes"
    LimitPixels => "limit_pixels"
    LimitTime => "limit_time"
    Cancelled => "cancelled"
  }
}

///|
/// 是否属于资源限额类错误（调用方可据此决定"换大预算重试"还是"直接拒绝"）。
/// Whether the code is a budget/limit failure (caller may raise the budget and retry).
pub fn ErrorCode::is_budget(self : ErrorCode) -> Bool {
  match self {
    LimitBytes | LimitPixels | LimitTime => true
    _ => false
  }
}

///|
/// 统一图像错误 Unified image error
///
/// 变体 Variants:
/// - `Decode(ErrorCode, String)` - 解码阶段 Decode phase
/// - `Encode(ErrorCode, String)` - 编码阶段 Encode phase
/// - `Process(ErrorCode, String)` - 像素处理阶段 Process phase
/// - `Budget(ErrorCode, String)` - 预算/限额拒绝 Budget rejection
/// - `Cancelled(String)` - 调用方取消 Caller cancelled
pub(all) suberror ImageError {
  Decode(ErrorCode, String)
  Encode(ErrorCode, String)
  Process(ErrorCode, String)
  Budget(ErrorCode, String)
  Cancelled(String)
}

///|
/// 稳定错误码字符串，形如 `decode/truncated`、`budget/limit_pixels`、`cancelled`。
/// Stable code string such as `decode/truncated`, `budget/limit_pixels`, `cancelled`.
pub fn ImageError::code(self : ImageError) -> String {
  match self {
    Decode(c, _) => "decode/" + c.to_string()
    Encode(c, _) => "encode/" + c.to_string()
    Process(c, _) => "process/" + c.to_string()
    Budget(c, _) => "budget/" + c.to_string()
    Cancelled(_) => "cancelled"
  }
}

///|
/// 错误消息（面向人，含具体数值）。Human-readable message (may include concrete numbers).
pub fn ImageError::message(self : ImageError) -> String {
  match self {
    Decode(_, m) | Encode(_, m) | Process(_, m) | Budget(_, m) | Cancelled(m) => m
  }
}

///|
/// 建议动作：给下游/agent 的处置建议（稳定文本，便于直接回给调用方）。
/// Suggested action for callers/agents; stable text suitable to return as-is.
pub fn image_error_hint(code : String) -> String {
  let base = if code.contains("limit_pixels") {
    "图像像素数超出预算：提高 max_pixels 或先降采样/分区解码；不要放宽到无上限。"
  } else if code.contains("limit_bytes") {
    "输入字节或内存分配超出预算：提高 max_bytes 或改为流式/分块处理；拒绝超限输入。"
  } else if code.contains("limit_time") {
    "处理耗时超出预算：缩小任务（降采样、裁剪 ROI）或提高 max_ms；必要时异步化。"
  } else if code.contains("unsupported_format") {
    "格式无对应编解码器：先用 detect_format 确认格式，或转成 PNG/JPEG/QOI 再处理。"
  } else if code.contains("truncated") {
    "输入被截断：丢弃该输入（不要重试同一份坏数据），并记录来源。"
  } else if code.contains("invalid_header") || code.contains("invalid_dimensions") {
    "文件头/尺寸非法：当作坏图拒绝，不要按头部声明去预分配内存。"
  } else if code.contains("invalid_argument") {
    "调用参数非法：检查尺寸/通道/质量/策略取值范围。"
  } else if code.contains("cancelled") {
    "调用方主动取消：按取消语义返回，不要当作错误重试。"
  } else if code.contains("encode") {
    "编码失败：检查输入通道数与尺寸；必要时改格式（无损用 PNG/WebP-VP8L）。"
  } else {
    "解码/处理失败：按坏图处理，记录 code 与 message 便于定位。"
  }
  base
}

///|
/// 把旧 `LoadError` 投影成 `ImageError`（按消息特征归类到稳定码）。
/// Project legacy `LoadError` into `ImageError`, classifying by message traits.
pub fn image_error_from_load(e : LoadError) -> ImageError {
  match e {
    FileIO(m) => Decode(InvalidArgument, m)
    UnsupportedFormat(m) => Decode(UnsupportedFormat, m)
    EncodeFailed(m) => Encode(EncodeFailed, m)
    DecodeFailed(m) =>
      if m.contains("截断") || m.contains("过短") || m.contains("truncated") {
        Decode(Truncated, m)
      } else if m.contains("超过") || m.contains("溢出") || m.contains("exceed") {
        Decode(InvalidDimensions, m)
      } else if m.contains("尺寸无效") || m.contains("标记") || m.contains("marker") ||
        m.contains("header") {
        Decode(InvalidHeader, m)
      } else if m.contains("不支持") || m.contains("unsupported") {
        Decode(UnsupportedFormat, m)
      } else {
        Decode(DecodeFailed, m)
      }
  }
}

///|
/// 解码/处理预算（默认保守）。Decode/process limits with conservative defaults.
///
/// - `max_pixels`：总像素上限（默认 5 亿，与 `MAX_TOTAL_PIXELS` 一致）
/// - `max_bytes`：输入字节上限（默认 256 MiB）
/// - `max_ms`：单次处理时间上限（默认 10 秒；纯 MoonBit 同步实现下为"准入检查 + 事后判定"，不能强杀）
pub(all) struct DecodeLimits {
  max_pixels : Int64
  max_bytes : Int64
  max_ms : Int64
}

///|
/// 默认预算。Default limits.
pub fn DecodeLimits::default_limits() -> DecodeLimits {
  { max_pixels: 500000000L, max_bytes: 268435456L, max_ms: 10000L }
}

///|
/// 严格预算（面向不可信输入的批处理/服务端）。Strict limits for untrusted input.
pub fn DecodeLimits::strict_limits() -> DecodeLimits {
  { max_pixels: 67108864L, max_bytes: 67108864L, max_ms: 3000L }
}

///|
/// 按格式上限构造预算（只覆盖像素数，字节/时间沿用默认）。
/// Build limits overriding only the pixel budget.
pub fn DecodeLimits::with_max_pixels(max_pixels : Int64) -> DecodeLimits {
  let d = DecodeLimits::default_limits()
  { ..d, max_pixels }
}

///|
/// 校验输入字节数是否超预算。Reject input whose byte length exceeds the budget.
pub fn DecodeLimits::check_bytes(
  self : DecodeLimits,
  bytes : Int64,
) -> Unit raise ImageError {
  if bytes > self.max_bytes {
    raise Budget(
      LimitBytes,
      "输入字节 \{bytes} 超过上限 \{self.max_bytes}",
    )
  }
}

///|
/// 校验像素数是否超预算。Reject pixel counts exceeding the budget.
pub fn DecodeLimits::check_pixels(
  self : DecodeLimits,
  width : Int64,
  height : Int64,
) -> Unit raise ImageError {
  if width <= 0L || height <= 0L {
    raise Decode(
      InvalidDimensions,
      "图像尺寸无效: width=\{width}, height=\{height}",
    )
  }
  let pixels = width * height
  if pixels > self.max_pixels {
    raise Budget(
      LimitPixels,
      "图像像素数 \{pixels} 超过上限 \{self.max_pixels}",
    )
  }
}

///|
/// 内存分配预算（供像素级算子使用）。Allocation budget for pixel operators.
pub(all) struct AllocBudget {
  max_bytes : Int64
}

///|
/// 默认分配预算（512 MiB）。Default allocation budget.
pub fn AllocBudget::default_budget() -> AllocBudget {
  { max_bytes: 536870912L }
}

///|
/// 需要 `width × height × channels` 字节时的准入检查。Admission check for an allocation.
pub fn AllocBudget::check_image(
  self : AllocBudget,
  width : Int64,
  height : Int64,
  channels : Int64,
  what : String,
) -> Unit raise ImageError {
  if width <= 0L || height <= 0L || channels <= 0L {
    raise Process(InvalidArgument, "\{what}: 尺寸/通道无效 (\{width}×\{height}×\{channels})")
  }
  let need = width * height * channels
  if need > self.max_bytes {
    raise Budget(
      LimitBytes,
      "\{what} 需要 \{need} 字节，超过分配预算 \{self.max_bytes}",
    )
  }
}
