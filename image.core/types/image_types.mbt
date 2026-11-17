///|
/// # 核心图像类型 Core Image Types
///
/// 图像处理库的核心类型定义，提供 8-bit / 16-bit / float 三种像素精度的图像值对象、统一错误类型、格式枚举，以及安全算术函数的公开别名。 Core type definitions for the image processing library, providing 8-bit / 16-bit / float pixel precision image value objects, unified error type, format enum, and public aliases for safe arithmetic functions.

///
/// 核心类型 Core types:
/// - `Image` - 8-bit 无符号像素图像 8-bit unsigned pixel image
/// - `Image16` - 16-bit 无符号像素图像 16-bit unsigned pixel image
/// - `ImageF` - 32-bit IEEE float 像素图像 32-bit IEEE float pixel image
/// - `ImageInfo` - 图像几何信息（无像素数据）Image geometry info (no pixel data)
/// - `AnyImage` - 统一图像容器 Unified image container
/// - `GifAnimation` - GIF 动画解码结果 GIF animation decode result
/// - `PngAnimation` - APNG 动画解码结果 APNG animation decode result
/// - `LoadError` - 加载/解码/编码错误 Load/decode/encode error
/// - `ImageFormat` - 图像格式枚举 Image format enum
///
/// 核心函数 Core functions:
/// - `check_dims` - 校验图像维度安全 Validate image dimension safety
/// - `dims_valid_check` - 纯函数维度校验 Pure function dimension validation
/// - `safe_mul` / `safe_mul3` - 溢出安全乘法 Overflow-safe multiplication
/// - `clamp_pixel_value` / `clamp_byte` / `clamp_coord` - 钳制函数 Clamp functions
///
/// 依赖 Dependencies:
/// - `walkzzz/image.core/safe_math` - 安全算术与形式化证明 Safe arithmetic with formal proofs

///|
/// 解码结果值对象，承载图像几何元信息与像素数据（8-bit 无符号像素） Decoded image value object carrying geometry metadata and pixel data (8-bit unsigned pixels)
///
/// 像素数据存储在 `data` 字段中，按行优先排列，每像素 `channels` 个字节。典型通道数：1（灰度）、3（RGB）、4（RGBA）。 Pixel data is stored in the `data` field, row-major, with `channels` bytes per pixel. Typical channel counts: 1 (grayscale), 3 (RGB), 4 (RGBA).

///|
/// 字段 Fields:
/// - `width` - 图像宽度（像素）Image width in pixels
/// - `height` - 图像高度（像素）Image height in pixels
/// - `channels` - 通道数（1/3/4）Number of channels (1/3/4)
/// - `data` - 像素数据（长度 = width * height * channels）Pixel data (length = width * height * channels)
#derive(Eq, @debug.Debug)
pub(all) struct Image {
  width : Int32
  height : Int32
  channels : Int32
  data : Bytes
}

///|
pub extend Image with @debug.Debug::{to_repr}

///|
pub extend Image with Eq::{not_equal, equal}

///|
/// 16-bit 解码结果值对象，像素数据为 16-bit 无符号整数（little-endian，每像素 2 字节） 16-bit decoded image value object, pixel data as 16-bit unsigned integers (little-endian, 2 bytes per pixel)
///
/// 字段 Fields:
/// - `width` - 图像宽度（像素）Image width in pixels
/// - `height` - 图像高度（像素）Image height in pixels
/// - `channels` - 通道数（1/3/4）Number of channels (1/3/4)
/// - `data` - 像素数据（长度 = width * height * channels * 2）Pixel data (length = width * height * channels * 2)
#derive(Eq, @debug.Debug)
pub(all) struct Image16 {
  width : Int32
  height : Int32
  channels : Int32
  data : Bytes
}

///|
pub extend Image16 with @debug.Debug::{to_repr}

///|
pub extend Image16 with Eq::{not_equal, equal}

///|
/// HDR float 解码结果值对象，像素数据为 32-bit IEEE float（little-endian，每像素 4 字节） HDR float decoded image value object, pixel data as 32-bit IEEE float (little-endian, 4 bytes per pixel)
///
/// 字段 Fields:
/// - `width` - 图像宽度（像素）Image width in pixels
/// - `height` - 图像高度（像素）Image height in pixels
/// - `channels` - 通道数（1/3/4）Number of channels (1/3/4)
/// - `data` - 像素数据（长度 = width * height * channels * 4）Pixel data (length = width * height * channels * 4)
#derive(Eq, @debug.Debug)
pub(all) struct ImageF {
  width : Int32
  height : Int32
  channels : Int32
  data : Bytes
}

///|
pub extend ImageF with @debug.Debug::{to_repr}

///|
pub extend ImageF with Eq::{not_equal, equal}

///|
/// 图像信息查询结果，仅含几何元信息，不加载像素数据 Image info query result, geometry metadata only, no pixel data loaded
///
/// 字段 Fields:
/// - `width` - 图像宽度（像素）Image width in pixels
/// - `height` - 图像高度（像素）Image height in pixels
/// - `channels` - 通道数（1/3/4）Number of channels (1/3/4)
#derive(Eq, @debug.Debug)
pub(all) struct ImageInfo {
  width : Int32
  height : Int32
  channels : Int32
}

///|
pub extend ImageInfo with @debug.Debug::{to_repr}

///|
pub extend ImageInfo with Eq::{not_equal, equal}

///|
/// 动画 GIF 解码结果，包含多帧图像和每帧延迟（毫秒） Animated GIF decode result, containing multiple frames and per-frame delays (milliseconds)
///
/// 字段 Fields:
/// - `frames` - 帧图像数组 Array of frame images
/// - `delays` - 每帧延迟时间（毫秒）Per-frame delay in milliseconds
#derive(Eq, @debug.Debug)
pub(all) struct GifAnimation {
  frames : Array[Image]
  delays : Array[Int32]
}

///|
pub extend GifAnimation with @debug.Debug::{to_repr}

///|
pub extend GifAnimation with Eq::{not_equal, equal}

///|
/// 加载失败领域错误 Load error domain type
///
/// 变体 Variants:
/// - `FileIO(String)` - 文件 I/O 错误 File I/O error
/// - `UnsupportedFormat(String)` - 不支持的图像格式 Unsupported image format
/// - `DecodeFailed(String)` - 解码失败 Decode failure
/// - `EncodeFailed(String)` - 编码失败 Encode failure
pub(all) suberror LoadError {
  FileIO(String)
  UnsupportedFormat(String)
  DecodeFailed(String)
  EncodeFailed(String)
}

///|
/// `LoadError` 实现 `Show` — 分类前缀 + 消息，使 `"\{err}"` 插值与 `inspect` 开箱可用（下游调试体验）。
/// `LoadError` implements `Show` — category prefix + message, making interpolation and `inspect` work out of the box.
pub impl Show for LoadError with fn output(self, logger) {
  logger.write_string(
    match self {
      FileIO(msg) => "FileIO: \{msg}"
      UnsupportedFormat(msg) => "UnsupportedFormat: \{msg}"
      DecodeFailed(msg) => "DecodeFailed: \{msg}"
      EncodeFailed(msg) => "EncodeFailed: \{msg}"
    },
  )
}

///|
/// 补齐 `Show` 的 `to_string` 派生方法。Add the derived `to_string` from `Show`.
pub extend LoadError with Show::{output, to_string}

///|
/// 图像格式枚举 Image format enum
///
/// 标识支持的图像编解码格式。`#non_exhaustive` 表示未来可能添加新格式。
/// Identifies supported image codec formats. `#non_exhaustive` means new formats may be added in the future.
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum ImageFormat {
  Png
  Jpeg
  Bmp
  Gif
  Tga
  Psd
  Hdr
  Pnm
  Qoi
  Webp
  Tiff
  Ico
  Cur
  Icns
  Apng
  Avif
  Heif
  JpegXl
  Unknown
}

///|
pub extend ImageFormat with @debug.Debug::{to_repr}

///|
pub extend ImageFormat with Eq::{not_equal, equal}

///|
/// resize 滤波器类型 Resize filter type
///
/// 用于图像缩放时的插值算法选择。 Selects interpolation algorithm for image resizing.
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum ResizeFilter {
  Default
  Box
  Triangle
  CubicBSPline
  CatmullROM
  Mitchell
  PointSample
}

///|
pub extend ResizeFilter with @debug.Debug::{to_repr}

///|
pub extend ResizeFilter with Eq::{not_equal, equal}

///|
/// resize 边缘处理模式 Resize edge handling mode
///
/// 定义图像缩放时如何处理超出边界的像素坐标。 Defines how pixel coordinates beyond image boundaries are handled during resizing.
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum ResizeEdge {
  Clamp
  Reflect
  Wrap
  Zero
}

///|
pub extend ResizeEdge with @debug.Debug::{to_repr}

///|
pub extend ResizeEdge with Eq::{not_equal, equal}

///|
/// APNG 动画解码结果 APNG animation decode result
///
/// 字段 Fields:
/// - `frames` - 帧图像数组 Array of frame images
/// - `delays` - 每帧延迟时间（毫秒）Per-frame delay in milliseconds
#derive(Eq, @debug.Debug)
pub(all) struct PngAnimation {
  frames : Array[Image]
  delays : Array[Int32] // 毫秒
}

///|
pub extend PngAnimation with @debug.Debug::{to_repr}

///|
pub extend PngAnimation with Eq::{not_equal, equal}

///|
/// 图像维度上限（单边最大像素数） Maximum image dimension limit (max pixels per side)
///
/// 防止恶意图像声明超大尺寸导致 OOM 或整数溢出。 Prevents malicious images from declaring oversized dimensions causing OOM or integer overflow.
/// 65535 覆盖常见图像格式最大尺寸（PNG/TIFF 32-bit、JPEG 65500、BMP 32-bit）。 65535 covers max sizes of common formats (PNG/TIFF 32-bit, JPEG 65500, BMP 32-bit).
pub const MAX_IMAGE_DIMENSION : Int32 = 65535

///| 总像素数上限 — 维度守卫之上的内存安全闸门（发起人确认取值 5e8）。

///| 内存峰值：RGB 3 通道 ≈ 1.5 GB / ImageF HDR float 3 通道 ≈ 12 GB。

///| Total pixel budget — memory-safety gate on top of per-dimension guards

///|
/// (confirmed value 5e8; peak memory: RGB ≈ 1.5 GB, ImageF HDR ≈ 12 GB).
pub const MAX_TOTAL_PIXELS : Int32 = 500000000

///|
/// 校验图像维度是否在安全范围内。 Validate image dimensions are within safe bounds.
///
/// 检查 width/height 为正数且不超过 MAX_IMAGE_DIMENSION，且 width * height * channels 不超过 Int 最大值（防溢出）。 Checks width/height are positive and do not exceed MAX_IMAGE_DIMENSION, and width * height * channels does not overflow Int (prevents overflow).

///|
/// 参数 Parameters:
/// - `width` - 图像宽度 Image width
/// - `height` - 图像高度 Image height
/// - `channels` - 通道数 Number of channels
///
/// 错误 Errors:
/// - `LoadError::DecodeFailed` - 维度无效、超过上限或溢出 Invalid dimensions, exceeds limit, or overflow
///
/// 示例 Example:
/// ```mbt check
/// test "doc_check_dims_valid" {
///   @types.check_dims(1, 1, 3)
///   assert_true(true)
/// }
/// ```
///
/// ```mbt check
/// test "doc_check_dims_total_pixels_ok" {
///   @types.check_dims(25000, 20000, 3) // 5e8 边界内（总像素上限 5 亿）
///   assert_true(true)
/// }
/// ```
///
/// ```mbt check
/// test "doc_check_dims_total_pixels_exceeded" {
///   try {
///     @types.check_dims(25001, 20000, 3) // 500,020,000 > 5e8
///     assert_true(false)
///   } catch {
///     @types.LoadError::DecodeFailed(_) => assert_true(true)
///     _ => assert_true(false)
///   }
/// }
/// ```
pub fn check_dims(
  width : Int32,
  height : Int32,
  channels : Int32,
) -> Unit raise LoadError {
  if width <= 0 || height <= 0 || channels <= 0 {
    raise LoadError::DecodeFailed(
      "图像尺寸无效: width=\{width}, height=\{height}, channels=\{channels}",
    )
  }
  if width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION {
    raise LoadError::DecodeFailed(
      "图像尺寸超过上限 \{MAX_IMAGE_DIMENSION}: width=\{width}, height=\{height}",
    )
  }
  // 检查 width * height * channels 是否溢出
  // Int 在 wasm/native 为 32 位有符号，最大值 2147483647
  // 先算 width * height，再乘 channels
  let max_int = 2147483647
  if width > max_int / height {
    raise LoadError::DecodeFailed(
      "图像像素总数溢出: \{width} * \{height}",
    )
  }
  let pixel_count = width * height
  if pixel_count > MAX_TOTAL_PIXELS {
    raise LoadError::DecodeFailed(
      "图像像素总数超过内存安全上限 \{MAX_TOTAL_PIXELS}: \{pixel_count} 像素（\{pixel_count / 1000000} M pixels） Total pixels exceed the memory-safety budget",
    )
  }
  if pixel_count > max_int / channels {
    raise LoadError::DecodeFailed(
      "图像数据大小溢出: \{pixel_count} * \{channels}",
    )
  }
}

///|
/// 判断维度是否在安全范围内（纯函数，可用于证明前提）。 Check if dimensions are within safe bounds (pure function, usable as proof precondition).
///
/// 返回 true 当且仅当 width/height/channels 均为正、不超过 MAX_IMAGE_DIMENSION、且乘积不溢出 Int32。 Returns true iff width/height/channels are all positive, do not exceed MAX_IMAGE_DIMENSION, and product does not overflow Int32.

///|
/// 参数 Parameters:
/// - `w` - 宽度 Width
/// - `h` - 高度 Height
/// - `c` - 通道数 Channels
///
/// 返回 Return:
/// - 维度是否合法 Whether dimensions are valid
pub let dims_valid_check : (Int32, Int32, Int32) -> Bool = @safe_math.dims_valid_check

///|
/// 安全乘法：返回 a * b，溢出时返回 None。 Safe multiplication: returns a * b, or None on overflow.
///
/// 用于在分配大数组前检查是否会溢出。 Used to check for overflow before allocating large arrays.
/// 实际实现和形式化证明在 core/safe_math 包中。 Actual implementation and formal proof are in the core/safe_math package.
///
/// 参数 Parameters:
/// - `a` - 乘数 Multiplicand
/// - `b` - 乘数 Multiplier
///
/// 返回 Return:
/// - `Some(result)` - 乘积 The product
/// - `None` - 溢出 Overflow occurred
pub let safe_mul : (Int32, Int32) -> Int32? = @safe_math.safe_mul

///|
/// 安全三参数乘法：返回 a * b * c，溢出时返回 None。 Safe three-argument multiplication: returns a * b * c, or None on overflow.
///
/// 常用于计算 w * h * channels 的数组大小。 Commonly used to compute array size as w * h * channels.
/// 实际实现和形式化证明在 core/safe_math 包中。 Actual implementation and formal proof are in the core/safe_math package.
///
/// 参数 Parameters:
/// - `a` - 第一乘数 First multiplicand
/// - `b` - 第二乘数 Second multiplicand
/// - `c` - 第三乘数 Third multiplicand
///
/// 返回 Return:
/// - `Some(result)` - 乘积 The product
/// - `None` - 溢出 Overflow occurred
pub let safe_mul3 : (Int32, Int32, Int32) -> Int32? = @safe_math.safe_mul3

///|
/// 通用整数钳制：将 v 限制在 [lo, hi] 范围内。 General integer clamp: constrains v to [lo, hi] range.
///
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
pub let clamp_int : (Int32, Int32, Int32) -> Int32 = @safe_math.clamp_int

///|
/// 像素值钳制：将 value 限制在 [0, 255] 范围内。 Pixel value clamp: constrains value to [0, 255] range.
///
/// 实际实现和形式化证明在 core/safe_math 包中。 Actual implementation and formal proof are in the core/safe_math package.
///
/// 参数 Parameters:
/// - `value` - 输入像素值 Input pixel value
///
/// 返回 Return:
/// - 钳制后的像素值（0-255）Clamped pixel value (0-255)
pub let clamp_pixel_value : (Int32) -> Int32 = @safe_math.clamp_pixel_value

///|
/// 字节钳制：将 Int32 值限制在 [0, 255] 并转为 Byte。 Byte clamp: constrains Int32 value to [0, 255] and converts to Byte.
///
/// 等价于 clamp_pixel_value(v).to_byte()，用于像素赋值。 Equivalent to clamp_pixel_value(v).to_byte(), used for pixel assignment.
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
///
/// 返回 Return:
/// - 钳制后的字节 Clamped byte
pub let clamp_byte : (Int32) -> Byte = @safe_math.clamp_byte

///|
/// 坐标钳制：将坐标 v 限制在 [0, max_val-1] 范围内。 Coordinate clamp: constrains coordinate v to [0, max_val-1] range.
///
/// 用于图像像素坐标的边界检查。 Used for boundary checking of image pixel coordinates.
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `v` - 坐标值 Coordinate value
/// - `max_val` - 最大值（上限为 max_val-1）Maximum value (upper bound is max_val-1)
///
/// 返回 Return:
/// - 钳制后的坐标 Clamped coordinate
pub let clamp_coord : (Int32, Int32) -> Int32 = @safe_math.clamp_coord

///|
/// 浮点钳制：将 Float 值 v 限制在 [lo, hi] 范围内。 Float clamp: constrains Float value v to [lo, hi] range.
///
/// 用于 16-bit/float 图像处理的范围约束。 Used for range constraints in 16-bit/float image processing.
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
pub let clamp_float : (Float, Float, Float) -> Float = @safe_math.clamp_float

///|
/// 双精度浮点钳制：将 Double 值 v 限制在 [lo, hi] 范围内。 Double clamp: constrains Double value v to [lo, hi] range.
///
/// 用于高精度图像处理（HDR/频域）的范围约束。 Used for range constraints in high-precision image processing (HDR/frequency domain).
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
pub let clamp_double : (Double, Double, Double) -> Double = @safe_math.clamp_double

///|
/// 整数最大值：返回 a 和 b 中较大的那个。 Integer maximum: returns the larger of a and b.
///
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `a` - 第一个值 First value
/// - `b` - 第二个值 Second value
///
/// 返回 Return:
/// - 较大值 The larger value
pub let int_max : (Int32, Int32) -> Int32 = @safe_math.int_max

///|
/// 整数最小值：返回 a 和 b 中较小的那个。 Integer minimum: returns the smaller of a and b.
///
/// 实际实现在 core/safe_math 包中。 Actual implementation is in the core/safe_math package.
///
/// 参数 Parameters:
/// - `a` - 第一个值 First value
/// - `b` - 第二个值 Second value
///
/// 返回 Return:
/// - 较小值 The smaller value
pub let int_min : (Int32, Int32) -> Int32 = @safe_math.int_min

// ============================================================================
// Section: 文档测试数据常量 Doc test data constants
// 供跨包文档测试复用的最小合法图像字节串。
// Minimal valid image byte strings for cross-package doc test reuse.
// ============================================================================

///|
/// 文档测试用 1×1 24-bit BMP 字节串（58 字节，红色像素 R=255 G=0 B=0） 1×1 24-bit BMP byte string for doc tests (58 bytes, red pixel R=255 G=0 B=0)
pub const DOC_TEST_BMP_1X1 : Bytes = b"\x42\x4d\x3a\x00\x00\x00\x00\x00\x00\x00\x36\x00\x00\x00\x28\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x18\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\x00"

///|
/// 文档测试用 1×1 RGBA PNG 字节串（73 字节，红色像素 R=255 G=0 B=0 A=255） 1×1 RGBA PNG byte string for doc tests (73 bytes, red pixel R=255 G=0 B=0 A=255)
pub const DOC_TEST_PNG_1X1_RGBA : Bytes = b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\xeb\x89\x2f\x0b\x00\x00\x00\x10\x49\x44\x41\x54\x78\x01\x01\x05\x00\xfa\xff\x00\xff\x00\x00\xff\x05\x00\x01\xff\x0b\x15\xdf\x08\x00\x00\x00\x00\x49\x45\x4e\x44\xf0\x2b\x1d\x59"

///|
/// 文档测试用 1×1 RGB PNM (P6) 字节串（14 字节，红色像素 R=255 G=0 B=0） 1×1 RGB PNM (P6) byte string for doc tests (14 bytes, red pixel R=255 G=0 B=0)
pub const DOC_TEST_PNM_1X1 : Bytes = b"P6\n1 1\n255\n\xff\x00\x00"

///|
/// 文档测试用 1×1 RGBA QOI 字节串（26 字节，红色像素 R=255 G=0 B=0 A=255） 1×1 RGBA QOI byte string for doc tests (26 bytes, red pixel R=255 G=0 B=0 A=255)
pub const DOC_TEST_QOI_1X1 : Bytes = b"\x71\x6f\x69\x66\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\x00\xfe\x00\xff\x00\x00\x00\x00\x00\x00\x00\x01"
