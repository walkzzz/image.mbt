///|
/// # sanitize Recipe
///
/// 一次调用解决"这张图能发给别人吗"：
/// 1. 元数据：解码后重编码，EXIF/GPS/XMP/ICC/内嵌缩略图都不会进入新容器；
/// 2. 已知区域打码（用户给坐标，不猜测人脸）：块均值替换，保留构图但不可读；
/// 3. 保守模糊：整图 box blur，用于"宁可不可用也别泄露"的场合。
///
/// 三档 policy：
/// - `metadata`：只做 1；
/// - `standard`：1 + 2（给了区域才打码，没给就退化成 metadata）；
/// - `strict`：1 + 2 + 3。

///|
pub struct Region {
  x : Int32
  y : Int32
  w : Int32
  h : Int32
}

///|
pub fn Region::to_string(self : Region) -> String {
  "\{self.x},\{self.y},\{self.w},\{self.h}"
}

///|
/// 解析 `"x,y,w,h"`；非法输入返回 None，由调用方决定报错还是忽略。
pub fn parse_region(s : String) -> Region? {
  let parts = s.split(",")
  let nums : Array[Int32] = []
  for p in parts {
    let t = p.trim()
    if t.length() == 0 {
      return None
    }
    let v = @string.parse_int(t) catch { _ => return None }
    nums.push(v)
  }
  if nums.length() != 4 {
    return None
  }
  Some({ x: nums[0], y: nums[1], w: nums[2], h: nums[3], })
}

///|
/// 解析 `"x,y,w,h;x,y,w,h"` 这种批量写法。
pub fn parse_regions(s : String) -> Array[Region] raise @types.ImageError {
  let out : Array[Region] = []
  for seg in s.split(";") {
    let t = seg.trim()
    if t.length() == 0 {
      continue
    }
    match parse_region(t.to_owned()) {
      Some(r) => out.push(r)
      None =>
        raise @types.ImageError::Process(
          @types.ErrorCode::InvalidArgument,
          "区域格式应为 x,y,w,h（收到: \{t}）",
        )
    }
  }
  out
}

///|
fn clamp_region(
  img : @types.Image,
  r : Region,
) -> Region raise @types.ImageError {
  if r.w <= 0 || r.h <= 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "打码区域宽高必须为正（收到 \{r.to_string()})",
    )
  }
  let x = if r.x < 0 { 0 } else { r.x }
  let y = if r.y < 0 { 0 } else { r.y }
  let x2 = if r.x + r.w > img.width { img.width } else { r.x + r.w }
  let y2 = if r.y + r.h > img.height { img.height } else { r.y + r.h }
  if x2 <= x || y2 <= y {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "打码区域完全在图外（图 \{img.width}x\{img.height}，区域 \{r.to_string()})",
    )
  }
  { x, y, w: x2 - x, h: y2 - y, }
}

///|
/// 块均值打码：每个 `block x block` 单元被其自身均值填平。
/// 效果是"能看出有个东西、看不出是什么"，比纯色覆盖更不容易误导读者。
pub fn redact_region(
  img : @types.Image,
  r : Region,
  block : Int32,
) -> @types.Image raise @types.ImageError {
  let br = if block < 1 { 1 } else { block }
  let reg = clamp_region(img, r)
  let ch = img.channels
  let src = img.data
  let dst : Array[Byte] = []
  for i in 0..<src.length() {
    dst.push(src[i])
  }
  let mut bx = reg.x
  while bx < reg.x + reg.w {
    let bw = if bx + br > reg.x + reg.w { reg.x + reg.w - bx } else { br }
    let mut by = reg.y
    while by < reg.y + reg.h {
      let bh = if by + br > reg.y + reg.h { reg.y + reg.h - by } else { br }
      let sums : Array[Int32] = Array::make(4, 0)
      for yy in 0..<bh {
        for xx in 0..<bw {
          let off = ((by + yy) * img.width + (bx + xx)) * ch
          for c in 0..<ch {
            sums[c] += src[off + c].to_int()
          }
        }
      }
      let count = bw * bh
      let means : Array[Byte] = []
      for c in 0..<ch {
        means.push((sums[c] / count).to_byte())
      }
      for yy in 0..<bh {
        for xx in 0..<bw {
          let off = ((by + yy) * img.width + (bx + xx)) * ch
          for c in 0..<ch {
            dst[off + c] = means[c]
          }
        }
      }
      by += br
    }
    bx += br
  }
  {
    width: img.width,
    height: img.height,
    channels: ch,
    data: Bytes::from_array(dst),
  }
}

///|
/// 全图打码（不给坐标时的保守选择）。
pub fn redact_all(
  img : @types.Image,
  block : Int32,
) -> @types.Image raise @types.ImageError {
  redact_region(img, { x: 0, y: 0, w: img.width, h: img.height, }, block)
}

///|
/// 全图 box blur：strict 档的"降级可用"手段。
pub fn blur_whole(
  img : @types.Image,
  radius : Int32,
) -> @types.Image raise @types.ImageError {
  let r = if radius < 1 { 1 } else { radius }
  @filter.box_blur(img, r) catch {
    e => raise @types.image_error_from_load(e)
  }
}

///|
/// 元数据签名：出现在输出容器里就说明没剥干净。
fn metadata_signatures() -> Array[String] {
  [
    "Exif", "GPS", "XMP", "ICC_PROFILE", "Photoshop 3.0", "<x:xmpmeta", "Thumbnail",
  ]
}

///|
/// 返回命中的签名（空数组 = 干净）。
pub fn metadata_hits(data : Bytes) -> Array[String] {
  let hits : Array[String] = []
  for sig in metadata_signatures() {
    if contains_ascii(data, sig) {
      hits.push(sig)
    }
  }
  hits
}

///|
/// 一步到位的 sanitize：策略 → 打码 → 模糊 → 编码，返回像素与编码结果。
pub struct SanitizeResult {
  image : @types.Image
  bytes : Bytes
  format : @types.ImageFormat
  redacted : Int32
  blurred : Bool
  quality : Int32
}

///|
pub fn sanitize_image(
  img : @types.Image,
  policy : String,
  regions : Array[Region],
  block : Int32,
  blur : Int32,
  format : @types.ImageFormat,
  quality : Int32,
) -> SanitizeResult raise @types.ImageError {
  let use_regions = policy == "standard" || policy == "strict"
  let use_blur = policy == "strict"
  if policy != "metadata" && policy != "standard" && policy != "strict" {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "policy 只能是 metadata / standard / strict（收到 \{policy}）",
    )
  }
  let mut work = img
  let mut redacted = 0
  if use_regions {
    if regions.length() == 0 {
      // strict 不给坐标 = 全图打码；standard 不给坐标 = 只剥元数据
      if use_blur {
        work = redact_all(work, block)
        redacted = 1
      }
    } else {
      for r in regions {
        work = redact_region(work, r, block)
        redacted += 1
      }
    }
  }
  if use_blur {
    work = blur_whole(work, blur)
  }
  let bytes = @lib.save_image_with_quality(work, format, quality) catch {
    e => raise @types.image_error_from_load(e)
  }
  { image: work, bytes, format, redacted, blurred: use_blur, quality, }
}
