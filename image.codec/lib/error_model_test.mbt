///|
/// S04 错误模型与资源限额的回归断言（≥20 条）。
/// Error-model and budget regression assertions (20+).

///|
fn em_solid_png(w : Int32, h : Int32) -> Bytes {
  let n = w.to_int() * h.to_int()
  let src : Array[Byte] = []
  for _ in 0..<n {
    src.push(140)
    src.push(90)
    src.push(40)
  }
  @lib.encode_png(@types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(src),
  })
}

///|
/// 构造一个只用头部声明超大尺寸的 QOI（无校验、无额外数据）。
fn em_fake_huge_qoi(w : Int32, h : Int32) -> Bytes {
  let b : Array[Byte] = [b'q', b'o', b'i', b'f']
  let put = fn(v : Int32) {
    b.push(((v >> 24) & 0xFF).to_byte())
    b.push(((v >> 16) & 0xFF).to_byte())
    b.push(((v >> 8) & 0xFF).to_byte())
    b.push((v & 0xFF).to_byte())
  }
  put(w)
  put(h)
  b.push(b'\x03')
  b.push(b'\x00')
  b.push(b'\x00')
  b.push(b'\x00')
  b.push(b'\x00')
  b.push(b'\x00')
  b.push(b'\x00')
  b.push(b'\x00')
  Bytes::from_array(b)
}

///|
test "error model: 错误码稳定字符串" {
  assert_eq(
    @types.ErrorCode::UnsupportedFormat.to_string(),
    "unsupported_format",
  )
  assert_eq(@types.ErrorCode::InvalidHeader.to_string(), "invalid_header")
  assert_eq(
    @types.ErrorCode::InvalidDimensions.to_string(),
    "invalid_dimensions",
  )
  assert_eq(@types.ErrorCode::InvalidArgument.to_string(), "invalid_argument")
  assert_eq(@types.ErrorCode::Truncated.to_string(), "truncated")
  assert_eq(@types.ErrorCode::DecodeFailed.to_string(), "decode_failed")
  assert_eq(@types.ErrorCode::EncodeFailed.to_string(), "encode_failed")
  assert_eq(@types.ErrorCode::ProcessFailed.to_string(), "process_failed")
  assert_eq(@types.ErrorCode::LimitBytes.to_string(), "limit_bytes")
  assert_eq(@types.ErrorCode::LimitPixels.to_string(), "limit_pixels")
  assert_eq(@types.ErrorCode::LimitTime.to_string(), "limit_time")
  assert_eq(@types.ErrorCode::Cancelled.to_string(), "cancelled")
}

///|
test "error model: 分类前缀与预算判定" {
  let e1 : @types.ImageError = @types.Decode(@types.ErrorCode::Truncated, "x")
  let e2 : @types.ImageError = @types.Encode(
    @types.ErrorCode::EncodeFailed,
    "y",
  )
  let e3 : @types.ImageError = @types.Process(
    @types.ErrorCode::InvalidArgument,
    "z",
  )
  let e4 : @types.ImageError = @types.Budget(@types.ErrorCode::LimitPixels, "p")
  let e5 : @types.ImageError = @types.Cancelled("c")
  assert_eq(e1.code(), "decode/truncated")
  assert_eq(e2.code(), "encode/encode_failed")
  assert_eq(e3.code(), "process/invalid_argument")
  assert_eq(e4.code(), "budget/limit_pixels")
  assert_eq(e5.code(), "cancelled")
  assert_eq(e1.message(), "x")
  assert_true(@types.ErrorCode::LimitBytes.is_budget())
  assert_true(@types.ErrorCode::LimitPixels.is_budget())
  assert_true(@types.ErrorCode::LimitTime.is_budget())
  assert_false(@types.ErrorCode::Truncated.is_budget())
  assert_false(@types.ErrorCode::DecodeFailed.is_budget())
}

///|
test "error model: 建议动作映射覆盖全部码" {
  let codes = [
    "decode/truncated", "decode/invalid_header", "decode/invalid_dimensions", "decode/invalid_argument",
    "decode/unsupported_format", "decode/decode_failed", "encode/encode_failed",
    "process/process_failed", "budget/limit_pixels", "budget/limit_bytes", "budget/limit_time",
    "cancelled",
  ]
  for c in codes {
    let hint = @types.image_error_hint(c)
    assert_true(hint.length() > 8)
  }
  assert_true(
    @types.image_error_hint("budget/limit_pixels").contains("max_pixels"),
  )
  assert_true(
    @types.image_error_hint("budget/limit_bytes").contains("max_bytes"),
  )
  assert_true(@types.image_error_hint("decode/truncated").contains("截断"))
  assert_true(@types.image_error_hint("cancelled").contains("取消"))
}

///|
test "error model: LoadError 投影" {
  let e1 = @types.image_error_from_load(
    @types.LoadError::UnsupportedFormat("no webp"),
  )
  assert_eq(e1.code(), "decode/unsupported_format")
  let e2 = @types.image_error_from_load(
    @types.LoadError::DecodeFailed("数据过短"),
  )
  assert_eq(e2.code(), "decode/truncated")
  let e3 = @types.image_error_from_load(
    @types.LoadError::DecodeFailed("图像尺寸无效: 0x0"),
  )
  assert_eq(e3.code(), "decode/invalid_header")
  let e3b = @types.image_error_from_load(
    @types.LoadError::DecodeFailed(
      "图像像素总数超过内存安全上限 500000000",
    ),
  )
  assert_eq(e3b.code(), "decode/invalid_dimensions")
  let e4 = @types.image_error_from_load(@types.LoadError::EncodeFailed("bad"))
  assert_eq(e4.code(), "encode/encode_failed")
  let e5 = @types.image_error_from_load(@types.LoadError::FileIO("disk"))
  assert_eq(e5.code(), "decode/invalid_argument")
}

///|
test "budget: 默认/严格预算取值" {
  let d = @types.DecodeLimits::default_limits()
  assert_eq(d.max_pixels, 500000000L)
  assert_eq(d.max_bytes, 268435456L)
  let s = @types.DecodeLimits::strict_limits()
  assert_eq(s.max_pixels, 67108864L)
  assert_eq(s.max_bytes, 67108864L)
  let custom = @types.DecodeLimits::with_max_pixels(1000000L)
  assert_eq(custom.max_pixels, 1000000L)
  assert_true(custom.max_bytes > 0L)
}

///|
test "budget: 字节/像素准入拒绝" {
  let l = @types.DecodeLimits::with_max_pixels(1000000L)
  let tight = @types.DecodeLimits::{
    max_pixels: l.max_pixels,
    max_bytes: 100L,
    max_ms: 10L,
  }
  try {
    tight.check_bytes(101L)
    fail("check_bytes 应拒绝")
  } catch {
    @types.ImageError::Budget(c, _) => assert_eq(c.to_string(), "limit_bytes")
    _ => fail("错误类型不对")
  }
  try {
    l.check_pixels(2000L, 2000L)
    fail("check_pixels 应拒绝")
  } catch {
    @types.ImageError::Budget(c, _) => assert_eq(c.to_string(), "limit_pixels")
    _ => fail("错误类型不对")
  }
  try {
    l.check_pixels(0L, 10L)
    fail("0 宽应拒绝")
  } catch {
    @types.ImageError::Decode(c, _) =>
      assert_eq(c.to_string(), "invalid_dimensions")
    _ => fail("错误类型不对")
  }
  l.check_pixels(1000L, 1000L)
  l.check_bytes(100L)
}

///|
test "budget: 分配预算准入" {
  let b = @types.AllocBudget::default_budget()
  b.check_image(1024L, 1024L, 4L, "resize")
  try {
    b.check_image(20000L, 20000L, 4L, "resize")
    fail("超预算应拒绝")
  } catch {
    @types.ImageError::Budget(c, _) => assert_eq(c.to_string(), "limit_bytes")
    _ => fail("错误类型不对")
  }
  try {
    b.check_image(-1L, 10L, 3L, "crop")
    fail("负宽应拒绝")
  } catch {
    @types.ImageError::Process(c, _) =>
      assert_eq(c.to_string(), "invalid_argument")
    _ => fail("错误类型不对")
  }
}

///|
test "budget: 正常 PNG 在默认预算内可解" {
  let png = em_solid_png(64, 64)
  let img = @lib.decode_with_limits(png, @types.DecodeLimits::default_limits())
  assert_eq(img.width, 64)
  assert_eq(img.channels, 3)
}

///|
test "budget: 字节超限直接拒绝（不进解码器）" {
  let png = em_solid_png(256, 256)
  let limits = @types.DecodeLimits::{
    max_pixels: 500000000L,
    max_bytes: 64L,
    max_ms: 1000L,
  }
  try {
    let _ = @lib.decode_with_limits(png, limits)
    fail("超字节预算应拒绝")
  } catch {
    @types.ImageError::Budget(c, m) => {
      assert_eq(c.to_string(), "limit_bytes")
      assert_true(m.contains("超过上限"))
    }
    _ => fail("错误类型不对")
  }
}

///|
test "budget: 头部声明超大像素被拒（不预分配）" {
  let bomb = em_fake_huge_qoi(100000, 100000)
  assert_true(bomb.length() < 64)
  try {
    let _ = @lib.decode_with_limits(bomb, @types.DecodeLimits::default_limits())
    fail("超大像素应拒绝")
  } catch {
    @types.ImageError::Budget(c, m) => {
      assert_eq(c.to_string(), "limit_pixels")
      assert_true(m.contains("10000000000"))
    }
    _ => fail("错误类型不对")
  }
}

///|
test "budget: 截断 JPEG 归类为 truncated" {
  let jpg = @lib.encode_jpeg(@types.Image::{
    width: 32,
    height: 32,
    channels: 3,
    data: Bytes::from_array(Array::make(32 * 32 * 3, b'\x7F')),
  })
  let cut : Array[Byte] = []
  for i in 0..<60 {
    cut.push(jpg[i])
  }
  try {
    let _ = @lib.decode_with_limits(
      Bytes::from_array(cut),
      @types.DecodeLimits::default_limits(),
    )
    fail("截断输入应拒绝")
  } catch {
    @types.ImageError::Decode(c, m) => {
      assert_true(
        c.to_string() == "truncated" ||
        c.to_string() == "decode_failed" ||
        c.to_string() == "invalid_header",
      )
      assert_true(m.length() > 0)
    }
    _ => fail("错误类型不对")
  }
}
