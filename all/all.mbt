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
/// 变换（缩放 / 裁切 / 旋转 / 翻转）
pub using @transform {
  resize_to_cover,
  resize_to_contain,
  crop,
  rotate,
  rotate_90,
  rotate_180,
  rotate_270,
  flip_horizontal,
  flip_vertical,
}
