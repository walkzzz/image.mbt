///|
/// # 分块 / 预算：大图直接出缩略图
///
/// 目标：**不为缩略图分配与底图同量级的内存**。
/// `resize_subsample` 直接按面积平均从底图读数，中间只用一个长度为 `channels` 的累加器；
/// 唯一分配是输出图（`out_w × out_h × channels`）。
/// 20000×20000 灰度图出 512×512 缩略图，额外内存约 786 KB，而不是再开一张 400 MB 的中间图。

///|
/// 面积平均重采样（下采样首选，上采样退化为最近邻）。
/// 每格把源图对应矩形内的像素求平均后写一个输出像素——**不建中间缓冲**。
/// 失败条件：输入/输出尺寸非正、数据长度与 `width*height*channels` 不符。
pub fn resize_subsample(
  img : @types.Image,
  out_w : Int32,
  out_h : Int32,
) -> @types.Image raise @types.LoadError {
  let ch = img.channels
  if out_w <= 0 || out_h <= 0 || img.width <= 0 || img.height <= 0 || ch <= 0 {
    raise @types.LoadError::DecodeFailed("resize_subsample: 尺寸无效")
  }
  if img.data.length() < img.width * img.height * ch {
    raise @types.LoadError::DecodeFailed(
      "resize_subsample: 像素数据长度不足",
    )
  }
  let out : Array[Byte] = Array::make(out_w * out_h * ch, b'\x00')
  let acc : Array[Double] = Array::make(ch, 0.0)
  for oy in 0..<out_h {
    let y0 = oy * img.height / out_h
    let y1_raw = (oy + 1) * img.height / out_h
    let y1 = if y1_raw <= y0 { y0 + 1 } else { y1_raw }
    for ox in 0..<out_w {
      let x0 = ox * img.width / out_w
      let x1_raw = (ox + 1) * img.width / out_w
      let x1 = if x1_raw <= x0 { x0 + 1 } else { x1_raw }
      for c in 0..<ch {
        acc[c] = 0.0
      }
      let mut count = 0
      for sy in y0..<y1 {
        let row_off = sy * img.width * ch
        for sx in x0..<x1 {
          let off = row_off + sx * ch
          for c in 0..<ch {
            acc[c] = acc[c] + img.data[off + c].to_double()
          }
        }
        count = count + (x1 - x0)
      }
      let d = if count <= 0 { 1 } else { count }
      let dst = (oy * out_w + ox) * ch
      for c in 0..<ch {
        let v = acc[c] / d.to_double()
        out[dst + c] = v.round().to_int().to_byte()
      }
    }
  }
  @types.Image::{
    width: out_w,
    height: out_h,
    channels: ch,
    data: Bytes::from_array(out),
  }
}

///|
/// 等比缩略图：长边压到 `max_side`，短边按比例（四舍五入，至少 1 像素）。
/// 原图两边都不超过 `max_side` 时原样返回（零分配）。
pub fn thumbnail(
  img : @types.Image,
  max_side : Int32,
) -> @types.Image raise @types.LoadError {
  if max_side <= 0 {
    raise @types.LoadError::DecodeFailed("thumbnail: max_side 必须为正")
  }
  let w = img.width
  let h = img.height
  if w <= max_side && h <= max_side {
    return img
  }
  let (ow, oh) = thumbnail_dims(w, h, max_side)
  resize_subsample(img, ow, oh)
}

///|
/// 等比缩略图的输出尺寸（不分配内存，供预算检查先算）。
pub fn thumbnail_dims(
  width : Int32,
  height : Int32,
  max_side : Int32,
) -> (Int32, Int32) {
  if width <= 0 || height <= 0 || max_side <= 0 {
    return (0, 0)
  }
  if width >= height {
    let oh_raw = (height * max_side + width / 2) / width
    let oh = if oh_raw < 1 { 1 } else { oh_raw }
    (max_side, oh)
  } else {
    let ow_raw = (width * max_side + height / 2) / height
    let ow = if ow_raw < 1 { 1 } else { ow_raw }
    (ow, max_side)
  }
}

///|
/// 带分配预算的缩略图：先按尺寸算输出字节，超出 `budget` 直接拒（不分配）。
/// 这是"大图出小图"的推荐入口：预算按**输出**计，底图内存由解码期 `DecodeLimits` 把关。
pub fn thumbnail_budgeted(
  img : @types.Image,
  max_side : Int32,
  budget : @types.AllocBudget,
) -> @types.Image raise @types.ImageError {
  if max_side <= 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "thumbnail: max_side 必须为正",
    )
  }
  let (ow, oh) = thumbnail_dims(img.width, img.height, max_side)
  if ow <= 0 || oh <= 0 {
    raise @types.ImageError::Process(
      @types.ErrorCode::InvalidArgument,
      "thumbnail: 图像尺寸无效",
    )
  }
  budget.check_image(
    ow.to_int64(),
    oh.to_int64(),
    img.channels.to_int64(),
    "thumbnail",
  )
  let out = resize_subsample(img, ow, oh) catch {
    @types.LoadError::DecodeFailed(msg) =>
      raise @types.ImageError::Process(@types.ErrorCode::InvalidArgument, msg)
    _ =>
      raise @types.ImageError::Process(
        @types.ErrorCode::ProcessFailed,
        "thumbnail: 重采样失败",
      )
  }
  out
}
