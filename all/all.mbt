///|
/// # 门面包：`walkzzz/image.mbt/all`
///
/// 目的只有一个：**下游只 `moon add walkzzz/image.mbt` 一条，就能 `import "walkzzz/image.mbt/all"` 拿到常用的全部东西**。
///
/// MoonBit 的规则是"依赖会传递、import 不传递"——`moon add walkzzz/image.mbt` 会把六个子模块全部下载好，
/// 但下游包直接 `import "walkzzz/image.codec/lib"` 会报
/// `exists in global environment, but its containing module is not imported by <你的包>`。
/// 本包用 `pub using` 把这些名字从子模块**再导出**一次：下游 import 的是一个**直接依赖（根模块）**里的包，
/// 于是不需要额外 add 任何子模块。
///
/// 想要更多函数（filter / vision / photography / domain 的上百个 API），照旧显式 add 对应子模块——本包只覆盖"高频起步面"。
pub using @types {
  type Image,
  type Image16,
  type ImageF,
  type AnyImage,
  type LoadError,
  type ImageError,
  type ErrorCode,
  type ImageFormat,
  type DecodeLimits,
  type Region,
  type ImageRegion,
}

///|
/// 区域视图（ROI）：`pub using` 只能再导出类型，方法要在这里包一层薄函数，
/// 否则下游拿到类型却调不到 `Image::region` / `ImageRegion::to_image`。

///|
/// 取一块区域的零复制视图（越界自动裁剪）。失败不会发生，空区域返回空视图。
pub fn region(
  img : @types.Image,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.ImageRegion {
  img.region(x, y, w, h)
}

///|
/// 用现成 `Region` 取零复制视图。
pub fn region_with(img : @types.Image, r : @types.Region) -> @types.ImageRegion {
  img.region_with(r)
}

///|
/// 区域视图宽度（裁剪后的有效宽度）。
pub fn region_width(v : @types.ImageRegion) -> Int32 {
  v.width()
}

///|
/// 区域视图高度（裁剪后的有效高度）。
pub fn region_height(v : @types.ImageRegion) -> Int32 {
  v.height()
}

///|
/// 区域视图通道数。
pub fn region_channels(v : @types.ImageRegion) -> Int32 {
  v.channels()
}

///|
/// 读区域内单通道字节（坐标相对区域左上角，越界返回 0）。
pub fn region_get(v : @types.ImageRegion, x : Int32, y : Int32, c : Int32) -> Byte {
  v.get(x, y, c)
}

///|
/// 读区域内一个像素的全部通道。
pub fn region_pixel(v : @types.ImageRegion, x : Int32, y : Int32) -> Array[Byte] {
  v.pixel(x, y)
}

///|
/// 把区域视图物化为独立 `Image`（唯一一次分配）。
pub fn region_to_image(v : @types.ImageRegion) -> @types.Image {
  v.to_image()
}

///|
/// 编解码（格式自动识别、按格式输出、WebP 无损）
pub using @lib {
  load_from_bytes_auto,
  load_16_from_bytes_auto,
  load_any_f,
  save_image_auto,
  save_image_with_quality,
  detect_format,
  decode_with_limits,
  check_decode_budget,
  get_image_summary,
  encode_png,
  encode_jpeg,
  encode_bmp,
  encode_qoi,
  encode_tga,
  encode_gif,
  encode_webp_lossless,
  decode_webp,
}

///|
/// 变换（缩放 / 裁切 / 旋转 / 翻转 / 区域裁剪）
pub using @transform {
  resize_to_cover,
  resize_to_contain,
  crop,
  crop_region,
  rotate,
  rotate_90,
  rotate_180,
  rotate_270,
  flip_horizontal,
  flip_vertical,
}
