///|
/// # 自动选格式（best_format）
///
/// 两种用法，别混淆：
/// - `best_format(img)`：**不编码**的启发式猜测，毫秒级，适合给日志/前端提示；
/// - `encode_best(img, quality)`：真的把候选格式各编一遍，挑最小的返回——这是"体积真值"，
///   代价是 N 次编码。出口想省体积就用它，想省 CPU 就先用 `best_format` 猜。

///|
/// 一次候选编码的结果。
#derive(@debug.Debug)
pub(all) struct EncodedImage {
  format : @types.ImageFormat
  bytes : Bytes
}

///|
/// 图像是否带"真的透明"（4 通道且存在 alpha < 255 的像素）。
/// 3 通道一律视为不透明；1 通道视为不透明。
pub fn has_alpha(img : @types.Image) -> Bool {
  if img.channels != 4 {
    return false
  }
  let n = img.width * img.height
  for i in 0..<n {
    if img.data[i * 4 + 3] != b'\xff' {
      return true
    }
  }
  false
}

///|
/// 廉价启发式：不编码，只按"有无透明"给一个偏好格式。
/// 不透明图默认给 `Jpeg`（照片类通常最省）；带透明给 `Webp`（无损且有 alpha）。
/// 想要真实最小体积请用 `encode_best`。
pub fn best_format(img : @types.Image) -> @types.ImageFormat {
  if has_alpha(img) {
    @types.ImageFormat::Webp
  } else {
    @types.ImageFormat::Jpeg
  }
}

///|
/// 候选格式集合：带透明走 WebP / PNG / QOI（无损且支持 alpha），
/// 不透明走 JPEG / WebP / QOI / PNG。
fn candidates(img : @types.Image) -> Array[@types.ImageFormat] {
  if has_alpha(img) {
    [
      @types.ImageFormat::Webp,
      @types.ImageFormat::Png,
      @types.ImageFormat::Qoi,
    ]
  } else {
    [
      @types.ImageFormat::Jpeg,
      @types.ImageFormat::Webp,
      @types.ImageFormat::Qoi,
      @types.ImageFormat::Png,
    ]
  }
}

///|
/// 把候选格式各编一遍，返回体积最小的那个（同体积时按候选顺序取前者）。
/// 单个候选编码失败会被跳过；全部失败才报 `ProcessFailed`。
/// `quality` 传给 `save_image_with_quality`（当前仅 JPEG 生效，无损格式忽略）。
pub fn encode_best(
  img : @types.Image,
  quality : Int32,
) -> EncodedImage raise @types.ImageError {
  let cands = candidates(img)
  let mut best : (Int32, Bytes, @types.ImageFormat)? = None
  for fmt in cands {
    let encoded = try {
      Some(save_image_with_quality(img, fmt, quality))
    } catch {
      _ => None
    }
    match encoded {
      Some(bytes) => {
        let size = bytes.length()
        match best {
          None => best = Some((size, bytes, fmt))
          Some((best_size, _, _)) => if size < best_size {
            best = Some((size, bytes, fmt))
          }
        }
      }
      None => ()
    }
  }
  match best {
    Some((_, bytes, fmt)) => { format: fmt, bytes }
    None =>
      raise @types.ImageError::Process(
        @types.ErrorCode::ProcessFailed,
        "encode_best: 所有候选格式都编码失败",
      )
  }
}

///|
/// 带体积上限的 `encode_best`：最小结果仍超过 `max_bytes` 就报
/// `Budget(LimitBytes)`（不返回超限数据，避免调用方写出超限文件）。
pub fn encode_best_limited(
  img : @types.Image,
  quality : Int32,
  max_bytes : Int64,
) -> EncodedImage raise @types.ImageError {
  let best = encode_best(img, quality)
  let size = best.bytes.length().to_int64()
  if max_bytes > 0L && size > max_bytes {
    raise @types.ImageError::Budget(
      @types.ErrorCode::LimitBytes,
      "encode_best: 最小体积 \{size} 字节仍超过上限 \{max_bytes}",
    )
  }
  best
}
