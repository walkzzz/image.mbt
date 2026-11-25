///|
/// # 带预算的解码入口 Decode with budget
///
/// 统一出口的第一层防护：先看字节数、再看头部声明的像素数，最后才进解码器。
/// 超预算直接拒绝，**不按头部声明预分配内存**（这是"坏图不 OOM"的关键）。
///
/// First line of defense for a unified entry: byte budget, then header-declared
/// pixel budget, then decode. Over-budget input is rejected before allocation.

///|
/// 从 `ImageInfoExtended` 里取出宽高（未知/不支持返回 None）。
/// Extract width/height from extended info (None when unknown).
pub fn info_dims(info : @codec.ImageInfoExtended) -> (Int64, Int64) {
  match info {
    @codec.ImageInfoExtended::Png(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Apng(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Jpeg(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Bmp(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Gif(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Qoi(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Tga(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Pnm(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Webp(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Tiff(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Ico(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Cur(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Icns(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Hdr(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Psd(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Avif(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::Heif(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::JpegXl(i) => (i.width.to_int64(), i.height.to_int64())
    @codec.ImageInfoExtended::.. => (0L, 0L)
  }
}

///|
/// 带预算解码：字节上限 → 头部像素上限 → 解码，错误统一投影成 `ImageError`。
///
/// 参数 Parameters:
/// - `data` - 输入字节 Input bytes
/// - `limits` - 预算 Budget
///
/// 错误 Errors:
/// - `Budget(LimitBytes|LimitPixels, _)` - 超出预算 Over budget
/// - `Decode(_, _)` - 解码失败 Decode failure（`code` 稳定）
pub fn decode_with_limits(
  data : Bytes,
  limits : @types.DecodeLimits,
) -> @types.Image raise @types.ImageError {
  limits.check_bytes(data.length().to_int64())
  let info = try {
    @codec.get_image_info_extended(data)
  } catch {
    e => raise @types.image_error_from_load(e)
  }
  let (w, h) = info_dims(info)
  if w > 0L && h > 0L {
    limits.check_pixels(w, h)
  }
  try {
    load_from_bytes_auto(data)
  } catch {
    e => raise @types.image_error_from_load(e)
  }
}

///|
/// 只做准入检查（不真正解码），供"先验后解"的调用方使用。
/// Admission check only (no decoding); for callers that validate before decoding.
pub fn check_decode_budget(
  data : Bytes,
  limits : @types.DecodeLimits,
) -> (Int64, Int64) raise @types.ImageError {
  limits.check_bytes(data.length().to_int64())
  let info = try {
    @codec.get_image_info_extended(data)
  } catch {
    e => raise @types.image_error_from_load(e)
  }
  let (w, h) = info_dims(info)
  if w > 0L && h > 0L {
    limits.check_pixels(w, h)
  }
  (w, h)
}
