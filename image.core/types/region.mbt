///|
/// # 区域视图 Region / ImageRegion
///
/// 一张大图上的矩形兴趣区（ROI）。`ImageRegion` 只持有 `Image` 的引用与坐标，
/// **不复制像素**：`base.data` 的底层缓冲区被共享（`Bytes` 为引用计数类型）。
/// 需要独立像素时才调用 `ImageRegion::to_image()` 物化一次。
///
/// 用途：超大图的局部读、局部算子、局部编码，避免为了一块区域再复制整幅图。

///|
/// 矩形区域（左上角 + 宽高，单位像素）。坐标可为负或越界，
/// 由 `Region::clamp` / `Image::region` 负责裁到图像边界内。
#derive(Eq, @debug.Debug)
pub(all) struct Region {
  x : Int32
  y : Int32
  w : Int32
  h : Int32
}

///|
/// 构造区域。不做边界检查（越界由使用方或 `clamp` 处理）。
pub fn Region::new(x : Int32, y : Int32, w : Int32, h : Int32) -> Region {
  { x, y, w, h, }
}

///|
/// 区域像素数（宽 * 高）。非正尺寸时返回 0。
pub fn Region::area(self : Region) -> Int32 {
  if self.w <= 0 || self.h <= 0 {
    0
  } else {
    self.w * self.h
  }
}

///|
/// 区域是否为空（宽或高非正）。
pub fn Region::is_empty(self : Region) -> Bool {
  self.w <= 0 || self.h <= 0
}

///|
/// 把区域裁到 `width * height` 的画布内，返回可能缩小甚至为空的区域。
/// 负宽/负高视为空；部分越界时保留交集。
pub fn Region::clamp(self : Region, width : Int32, height : Int32) -> Region {
  if self.w <= 0 || self.h <= 0 || width <= 0 || height <= 0 {
    return { x: 0, y: 0, w: 0, h: 0, }
  }
  let x0 = if self.x < 0 { 0 } else { self.x }
  let y0 = if self.y < 0 { 0 } else { self.y }
  let x1 = if self.x + self.w > width { width } else { self.x + self.w }
  let y1 = if self.y + self.h > height { height } else { self.y + self.h }
  if x1 <= x0 || y1 <= y0 {
    { x: 0, y: 0, w: 0, h: 0, }
  } else {
    { x: x0, y: y0, w: x1 - x0, h: y1 - y0, }
  }
}

///|
/// 图像上的区域视图。持有 `base` 的共享引用，不复制像素。
#derive(Eq, @debug.Debug)
pub(all) struct ImageRegion {
  base : Image
  region : Region
}

///|
/// 取图像的一块区域视图（越界部分自动裁掉，不报错）。
/// 区域为空时 `width()` / `height()` 为 0，`to_image()` 得到 0×0 图。
pub fn Image::region(
  self : Image,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> ImageRegion {
  let r = Region::new(x, y, w, h).clamp(self.width, self.height)
  { base: self, region: r, }
}

///|
/// 用现成的 `Region` 取区域视图（同样自动裁剪）。
pub fn Image::region_with(self : Image, region : Region) -> ImageRegion {
  { base: self, region: region.clamp(self.width, self.height), }
}

///|
/// 区域视图的宽（可能因裁剪小于请求值）。
pub fn ImageRegion::width(self : ImageRegion) -> Int32 {
  self.region.w
}

///|
/// 区域视图的高（可能因裁剪小于请求值）。
pub fn ImageRegion::height(self : ImageRegion) -> Int32 {
  self.region.h
}

///|
/// 区域视图的通道数（与原图一致）。
pub fn ImageRegion::channels(self : ImageRegion) -> Int32 {
  self.base.channels
}

///|
/// 区域视图对应的 `Region`（已裁剪到图像内）。
pub fn ImageRegion::region_of(self : ImageRegion) -> Region {
  self.region
}

///|
/// 区域视图是否为空。
pub fn ImageRegion::is_empty(self : ImageRegion) -> Bool {
  self.region.is_empty()
}

///|
/// 读区域内的单通道字节；坐标相对区域左上角。越界返回 0（不 panic），便于算子边界处理。
pub fn ImageRegion::get(
  self : ImageRegion,
  x : Int32,
  y : Int32,
  channel : Int32,
) -> Byte {
  if x < 0 ||
    y < 0 ||
    x >= self.region.w ||
    y >= self.region.h ||
    channel < 0 ||
    channel >= self.base.channels {
    return b'\x00'
  }
  let idx = ((self.region.y + y) * self.base.width + self.region.x + x) *
    self.base.channels +
    channel
  self.base.data[idx]
}

///|
/// 读区域内一个像素的全部通道，返回长度 `channels` 的数组。
pub fn ImageRegion::pixel(
  self : ImageRegion,
  x : Int32,
  y : Int32,
) -> Array[Byte] {
  let ch = self.base.channels
  let out : Array[Byte] = Array::make(ch, b'\x00')
  for c in 0..<ch {
    out[c] = self.get(x, y, c)
  }
  out
}

///|
/// 把区域视图物化为独立 `Image`（这一步才真正分配像素）。
/// 与 `crop` 的差别：越界不报错，按裁剪后的有效区域输出。
pub fn ImageRegion::to_image(self : ImageRegion) -> Image {
  let ch = self.base.channels
  let w = self.region.w
  let h = self.region.h
  if w <= 0 || h <= 0 {
    return Image::{
      width: 0,
      height: 0,
      channels: ch,
      data: Bytes::make(0, b'\x00'),
    }
  }
  let out : Array[Byte] = Array::make(w * h * ch, b'\x00')
  for row in 0..<h {
    let src_off = ((self.region.y + row) * self.base.width + self.region.x) * ch
    let dst_off = row * w * ch
    for i in 0..<(w * ch) {
      out[dst_off + i] = self.base.data[src_off + i]
    }
  }
  Image::{ width: w, height: h, channels: ch, data: Bytes::from_array(out), }
}
