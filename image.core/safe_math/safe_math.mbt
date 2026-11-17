///|
/// # 安全算术与核心证明模块 Safe Arithmetic & Core Proof Module
///
/// 提供溢出安全的整数运算、钳制函数、索引检查、编解码核心算法。 Provides overflow-safe integer arithmetic, clamp functions, index checks, and codec core algorithms.
/// 带 `proof_ensure` 的函数附带形式化验证契约（moon prove）， Functions with `proof_ensure` carry formal verification contracts (moon prove),
/// 确保 SMT 可机检的数学正确性。 ensuring SMT-machine-checkable mathematical correctness.
///
/// 证明谓词定义在 `safe_math.mbtp` 中。 Proof predicates are defined in `safe_math.mbtp`.
///
/// 核心函数 Core functions:
/// - `safe_mul` / `safe_mul3` - 溢出安全乘法 Overflow-safe multiplication
/// - `dims_valid_check` - 维度合法性检查 Dimension validity check
/// - `clamp_int` / `clamp_pixel_value` / `clamp_byte` / `clamp_coord` - 整数钳制 Integer clamp
/// - `clamp_float` / `clamp_double` - 浮点钳制 Float clamp
/// - `int_max` / `int_min` - 整数极值 Integer extrema
/// - `is_valid_index` / `is_valid_2d_index` - 索引合法性 Index validity
/// - `rotate90_power_is_identity` - 旋转恒等性 Rotation identity
/// - `paeth_predict` / `qoi_hash` / `quantize_332` / `hamming_distance` - 编解码核心 Codec core
///
/// MoonBit 证明系统限制（实验性）： MoonBit proof system limitations (experimental):
/// - 契约函数体中不支持：raise、return、let mut、while、.abs()、>>、& Contract function bodies do not support: raise, return, let mut, while, .abs(), >>, &
/// - 谓词中不支持：>>、&、=>（用 !P || Q 替代）、match Bool Predicates do not support: >>, &, => (use !P || Q instead), match Bool
/// - 含复杂类型（Bytes/Array）的包导致 Why3 翻译失败 Packages with complex types (Bytes/Array) cause Why3 translation failure

///|
/// 图像维度上限（单边最大像素数）。 Maximum image dimension limit (max pixels per side).
///
/// 65535 覆盖常见图像格式最大尺寸（PNG/TIFF 32-bit、JPEG 65500、BMP 32-bit）。 65535 covers max sizes of common formats (PNG/TIFF 32-bit, JPEG 65500, BMP 32-bit).
pub const MAX_IMAGE_DIMENSION : Int32 = 65535

// ============================================================================
// Section: 溢出安全乘法 Overflow-safe multiplication
// ============================================================================

///|
/// 安全乘法：返回 a * b，溢出时返回 None。
/// 安全乘法：返回 a * b，溢出时返回 None。 Safe multiplication: returns a * b, or None on overflow.
///
/// 用于在分配大数组前检查是否会溢出。
/// 用于在分配大数组前检查是否会溢出。 Used to check for overflow before allocating large arrays.
///
/// ✅ 形式化验证：证明后置条件 safe_mul_ok 成立。 ✅ Formal verification: proves postcondition safe_mul_ok holds.
///
/// 参数 Parameters:
/// - `a` - 乘数 Multiplicand
/// - `b` - 乘数 Multiplier
///
/// 返回 Return:
/// - `Some(result)` - 乘积 The product
/// - `None` - 溢出 Overflow occurred
///
/// 示例 Example:
/// ```mbt check
/// test "doc_safe_mul_normal" {
///   assert_eq(@safe_math.safe_mul(3, 4), Some(12))
/// }
/// ```
///
/// ```mbt check
/// test "doc_safe_mul_overflow" {
///   assert_eq(@safe_math.safe_mul(1073741824, 2), None)
/// }
/// ```
///
/// ```mbt check
/// test "doc_safe_mul_zero" {
///   assert_eq(@safe_math.safe_mul(0, 100), Some(0))
/// }
/// ```
pub fn safe_mul(
  a : Int32,
  b : Int32,
) -> Int32? where {
  proof_ensure: result => safe_mul_ok(a, b, result),
} {
  if a <= 0 || b <= 0 {
    Some(0)
  } else {
    let max_int = 2147483647
    if a > max_int / b {
      None
    } else {
      Some(a * b)
    }
  }
}

///|
/// 安全三参数乘法：返回 a * b * c，溢出时返回 None。 Safe three-argument multiplication: returns a * b * c, or None on overflow.
///
/// 常用于计算 w * h * channels 的数组大小。 Commonly used to compute array size as w * h * channels.
///
/// 参数 Parameters:
/// - `a` - 第一乘数 First multiplicand
/// - `b` - 第二乘数 Second multiplicand
/// - `c` - 第三乘数 Third multiplicand
///
/// 返回 Return:
/// - `Some(result)` - 乘积 The product
/// - `None` - 溢出 Overflow occurred
///
/// 示例 Example:
/// ```mbt check
/// test "doc_safe_mul3_normal" {
///   assert_eq(@safe_math.safe_mul3(2, 3, 4), Some(24))
/// }
/// ```
///
/// ```mbt check
/// test "doc_safe_mul3_overflow" {
///   assert_eq(@safe_math.safe_mul3(1073741824, 2, 1), None)
/// }
/// ```
pub fn safe_mul3(a : Int32, b : Int32, c : Int32) -> Int32? {
  match safe_mul(a, b) {
    Some(ab) =>
      match safe_mul(ab, c) {
        Some(abc) => Some(abc)
        None => None
      }
    None => None
  }
}

///|
/// 判断维度是否在安全范围内（纯函数）。 Check if dimensions are within safe bounds (pure function).
///
/// 返回 true 当且仅当 width/height/channels 均为正、不超过 MAX_IMAGE_DIMENSION、且乘积不溢出 Int32。 Returns true iff width/height/channels are all positive, do not exceed MAX_IMAGE_DIMENSION, and product does not overflow Int32.

///|
/// ✅ 形式化验证：证明结果等价于维度合法性谓词。 ✅ Formal verification: proves result is equivalent to dimension validity predicate.
///
/// 参数 Parameters:
/// - `w` - 宽度 Width
/// - `h` - 高度 Height
/// - `c` - 通道数 Channels
///
/// 返回 Return:
/// - 维度是否合法 Whether dimensions are valid
///
/// 示例 Example:
/// ```mbt check
/// test "doc_dims_valid_check_valid" {
///   assert_true(@safe_math.dims_valid_check(100, 200, 3))
/// }
/// ```
///
/// ```mbt check
/// test "doc_dims_valid_check_invalid" {
///   assert_true(!@safe_math.dims_valid_check(0, 100, 3))
/// }
/// ```
#inline
pub fn dims_valid_check(
  w : Int32,
  h : Int32,
  c : Int32,
) -> Bool where {
  proof_ensure: result => dims_valid_pred(w, h, c, result),
} {
  1 <= w &&
  w <= 65535 &&
  1 <= h &&
  h <= 65535 &&
  1 <= c &&
  w <= 2147483647 / h &&
  w * h <= 500000000 &&
  w * h <= 2147483647 / c
}

// ============================================================================
// Section: 钳制函数（Clamp）
// ============================================================================

///|
/// 通用整数钳制：将 v 限制在 [lo, hi] 范围内。 General integer clamp: constrains v to [lo, hi] range.
///
/// 谓词 clamp_int_ok 保证结果在 [lo, hi] 范围内。 Predicate clamp_int_ok guarantees the result is in [lo, hi] range.
/// 注意：当前 moon prove 对此函数后置条件求解超时，待优化。 Note: current moon prove solver times out on this postcondition, pending optimization.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_int_within" {
///   assert_eq(@safe_math.clamp_int(5, 0, 10), 5)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_int_below" {
///   assert_eq(@safe_math.clamp_int(-3, 0, 10), 0)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_int_above" {
///   assert_eq(@safe_math.clamp_int(15, 0, 10), 10)
/// }
/// ```
#inline
pub fn clamp_int(v : Int32, lo : Int32, hi : Int32) -> Int32 {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
/// 像素值钳制：将 value 限制在 [0, 255] 范围内。 Pixel value clamp: constrains value to [0, 255] range.
///
/// ✅ 形式化验证：证明结果在 [0, 255] 范围内。 ✅ Formal verification: proves result is in [0, 255] range.
///
/// 参数 Parameters:
/// - `value` - 输入像素值 Input pixel value
///
/// 返回 Return:
/// - 钳制后的像素值（0-255）Clamped pixel value (0-255)
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_pixel_value_normal" {
///   assert_eq(@safe_math.clamp_pixel_value(128), 128)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_pixel_value_negative" {
///   assert_eq(@safe_math.clamp_pixel_value(-10), 0)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_pixel_value_overflow" {
///   assert_eq(@safe_math.clamp_pixel_value(300), 255)
/// }
/// ```
pub fn clamp_pixel_value(
  value : Int32,
) -> Int32 where {
  proof_ensure: result => clamp_pixel_ok(value, result),
} {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
/// 坐标钳制：将坐标 v 限制在 [0, max_val-1] 范围内。 Coordinate clamp: constrains coordinate v to [0, max_val-1] range.
///
/// 用于图像像素坐标的边界检查。 Used for boundary checking of image pixel coordinates.
/// 谓词 clamp_coord_ok 保证结果在 [0, max_val-1] 范围内（当 max > 0）。 Predicate clamp_coord_ok guarantees result is in [0, max_val-1] range (when max > 0).
/// 注意：当前 moon prove 对此函数后置条件求解超时，待优化。 Note: current moon prove solver times out on this postcondition, pending optimization.
///
/// 参数 Parameters:
/// - `v` - 坐标值 Coordinate value
/// - `max_val` - 最大值（上限为 max_val-1）Maximum value (upper bound is max_val-1)
///
/// 返回 Return:
/// - 钳制后的坐标 Clamped coordinate
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_coord_within" {
///   assert_eq(@safe_math.clamp_coord(5, 10), 5)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_coord_negative" {
///   assert_eq(@safe_math.clamp_coord(-1, 10), 0)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_coord_exceeds" {
///   assert_eq(@safe_math.clamp_coord(15, 10), 9)
/// }
/// ```
#inline
pub fn clamp_coord(v : Int32, max_val : Int32) -> Int32 {
  if v < 0 {
    0
  } else if v >= max_val {
    max_val - 1
  } else {
    v
  }
}

///|
/// 字节钳制：将 Int32 值限制在 [0, 255] 并转为 Byte。 Byte clamp: constrains Int32 value to [0, 255] and converts to Byte.
///
/// 等价于 clamp_pixel_value(v).to_byte()，用于像素赋值。 Equivalent to clamp_pixel_value(v).to_byte(), used for pixel assignment.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
///
/// 返回 Return:
/// - 钳制后的字节 Clamped byte
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_byte_normal" {
///   assert_eq(@safe_math.clamp_byte(100), b'\x64')
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_byte_overflow" {
///   assert_eq(@safe_math.clamp_byte(500), b'\xff')
/// }
/// ```
#inline
pub fn clamp_byte(v : Int32) -> Byte {
  clamp_pixel_value(v).to_byte()
}

///|
/// 浮点钳制：将 Float 值 v 限制在 [lo, hi] 范围内。 Float clamp: constrains Float value v to [lo, hi] range.
///
/// 用于 16-bit/float 图像处理的范围约束。 Used for range constraints in 16-bit/float image processing.
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_float_within" {
///   assert_eq(@safe_math.clamp_float(0.5F, 0.0F, 1.0F), 0.5F)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_float_below" {
///   assert_eq(@safe_math.clamp_float(-0.5F, 0.0F, 1.0F), 0.0F)
/// }
/// ```
#inline
pub fn clamp_float(v : Float, lo : Float, hi : Float) -> Float {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
/// 双精度浮点钳制：将 Double 值 v 限制在 [lo, hi] 范围内。 Double clamp: constrains Double value v to [lo, hi] range.
///
/// 用于高精度图像处理（HDR/频域）的范围约束。 Used for range constraints in high-precision image processing (HDR/frequency domain).
///
/// 参数 Parameters:
/// - `v` - 输入值 Input value
/// - `lo` - 下界 Lower bound
/// - `hi` - 上界 Upper bound
///
/// 返回 Return:
/// - 钳制后的值 Clamped value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_clamp_double_within" {
///   assert_eq(@safe_math.clamp_double(0.5, 0.0, 1.0), 0.5)
/// }
/// ```
///
/// ```mbt check
/// test "doc_clamp_double_above" {
///   assert_eq(@safe_math.clamp_double(1.5, 0.0, 1.0), 1.0)
/// }
/// ```
#inline
pub fn clamp_double(v : Double, lo : Double, hi : Double) -> Double {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

// ============================================================================
// Section: 整数 min/max（替代散布全项目的私有 min_/max_ 函数）
// Integer min/max (replaces scattered private min_/max_ functions across the project)
// ============================================================================

///|
/// 整数最大值：返回 a 和 b 中较大的那个。 Integer maximum: returns the larger of a and b.
///
/// ✅ 形式化验证：证明结果确实是 a 和 b 中的较大者。 ✅ Formal verification: proves the result is indeed the larger of a and b.
///
/// 参数 Parameters:
/// - `a` - 第一个值 First value
/// - `b` - 第二个值 Second value
///
/// 返回 Return:
/// - 较大值 The larger value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_int_max_a_larger" {
///   assert_eq(@safe_math.int_max(10, 5), 10)
/// }
/// ```
///
/// ```mbt check
/// test "doc_int_max_b_larger" {
///   assert_eq(@safe_math.int_max(3, 7), 7)
/// }
/// ```
#inline
pub fn int_max(
  a : Int32,
  b : Int32,
) -> Int32 where {
  proof_ensure: result => int_max_ok(a, b, result),
} {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// 整数最小值：返回 a 和 b 中较小的那个。 Integer minimum: returns the smaller of a and b.
///
/// ✅ 形式化验证：证明结果确实是 a 和 b 中的较小者。 ✅ Formal verification: proves the result is indeed the smaller of a and b.
///
/// 参数 Parameters:
/// - `a` - 第一个值 First value
/// - `b` - 第二个值 Second value
///
/// 返回 Return:
/// - 较小值 The smaller value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_int_min_a_smaller" {
///   assert_eq(@safe_math.int_min(3, 7), 3)
/// }
/// ```
///
/// ```mbt check
/// test "doc_int_min_equal" {
///   assert_eq(@safe_math.int_min(5, 5), 5)
/// }
/// ```
#inline
pub fn int_min(
  a : Int32,
  b : Int32,
) -> Int32 where {
  proof_ensure: result => int_min_ok(a, b, result),
} {
  if a < b {
    a
  } else {
    b
  }
}

// ============================================================================
// Section: 索引合法性检查 Index validity checks
// ============================================================================

///|
/// 安全的一维索引检查：0 <= index < length。 Safe 1D index check: 0 <= index < length.
///
/// ✅ 形式化验证：证明结果正确判定索引合法性。 ✅ Formal verification: proves result correctly determines index validity.
///
/// 参数 Parameters:
/// - `index` - 索引值 Index value
/// - `length` - 数组长度 Array length
///
/// 返回 Return:
/// - 索引是否合法 Whether the index is valid
///
/// 示例 Example:
/// ```mbt check
/// test "doc_is_valid_index_valid" {
///   assert_true(@safe_math.is_valid_index(2, 5))
/// }
/// ```
///
/// ```mbt check
/// test "doc_is_valid_index_out_of_bounds" {
///   assert_true(!@safe_math.is_valid_index(5, 5))
/// }
/// ```
#inline
pub fn is_valid_index(
  index : Int32,
  length : Int32,
) -> Bool where {
  proof_ensure: result => valid_index(index, length, result),
} {
  index >= 0 && index < length
}

///|
/// 安全的二维索引检查：0 <= x < width && 0 <= y < height。 Safe 2D index check: 0 <= x < width && 0 <= y < height.
///
/// ✅ 形式化验证：证明结果正确判定 2D 索引合法性。 ✅ Formal verification: proves result correctly determines 2D index validity.
///
/// 参数 Parameters:
/// - `x` - x 坐标 x coordinate
/// - `y` - y 坐标 y coordinate
/// - `width` - 图像宽度 Image width
/// - `height` - 图像高度 Image height
///
/// 返回 Return:
/// - 索引是否合法 Whether the index is valid
///
/// 示例 Example:
/// ```mbt check
/// test "doc_is_valid_2d_index_valid" {
///   assert_true(@safe_math.is_valid_2d_index(1, 2, 10, 20))
/// }
/// ```
///
/// ```mbt check
/// test "doc_is_valid_2d_index_invalid" {
///   assert_true(!@safe_math.is_valid_2d_index(-1, 5, 10, 20))
/// }
/// ```
#inline
pub fn is_valid_2d_index(
  x : Int32,
  y : Int32,
  width : Int32,
  height : Int32,
) -> Bool where {
  proof_ensure: result => valid_2d_index(x, y, width, height, result),
} {
  x >= 0 && x < width && y >= 0 && y < height
}

// ============================================================================
// Section: 几何/旋转恒等性 Geometry/rotation identity
// ============================================================================

///|
/// 判断 Rotate90 的连续次数是否为恒等变换。 Determine whether n consecutive Rotate90 operations result in identity.
///
/// 当 n 是 4 的倍数时，连续旋转 n 次 90° 回到原始状态。 When n is a multiple of 4, rotating 90° n times returns to the original state.
///
/// ✅ 形式化验证：证明结果等价于 n % 4 == 0。 ✅ Formal verification: proves result is equivalent to n % 4 == 0.
///
/// 参数 Parameters:
/// - `n` - 旋转次数 Number of rotations
///
/// 返回 Return:
/// - 是否为恒等变换 Whether it is an identity transformation
///
/// 示例 Example:
/// ```mbt check
/// test "doc_rotate90_identity" {
///   assert_true(@safe_math.rotate90_power_is_identity(4))
///   assert_true(@safe_math.rotate90_power_is_identity(8))
///   assert_true(!@safe_math.rotate90_power_is_identity(3))
/// }
/// ```
#inline
pub fn rotate90_power_is_identity(
  n : Int32,
) -> Bool where {
  proof_ensure: result => rotate90_identity(n, result),
} {
  n % 4 == 0
}

// ============================================================================
// Section: 编解码核心算法 Codec core algorithms
// 注意：以下函数使用位运算/方法调用，当前 moon prove 不支持在
// 契约函数体中使用，因此不带 proof_ensure 契约。
// 仍提供安全范围谓词供未来证明系统扩展时使用。
//
// Note: The following functions use bitwise operations/method calls,
// which the current moon prove does not support in contract bodies,
// so they do not carry proof_ensure contracts.
// Safety range predicates are still provided for future proof system extensions.
// ============================================================================

///|
/// PNG Paeth 预测函数。PNG Paeth predictor function.
///
/// 选择 a、b、c 中最接近预测值 p = a + b - c 的那个。 Selects the one among a, b, c closest to the predicted value p = a + b - c.
/// 结果必为 {a, b, c} 之一（PNG 规范保证）。 The result is guaranteed to be one of {a, b, c} (PNG spec guarantee).
///
/// 参数 Parameters:
/// - `a` - 左方像素 Left pixel
/// - `b` - 上方像素 Above pixel
/// - `c` - 左上方像素 Upper-left pixel
///
/// 返回 Return:
/// - 预测值 Predicted value
///
/// 示例 Example:
/// ```mbt check
/// test "doc_paeth_predict_equal" {
/// // 当 pa == pb == pc 时选 a assert_eq(@safe_math.paeth_predict(0, 0, 0), 0)

///|
/// }
/// ```
#inline
pub fn paeth_predict(a : Int32, b : Int32, c : Int32) -> Int32 {
  let p = a + b - c
  let pa = (p - a).abs()
  let pb = (p - b).abs()
  let pc = (p - c).abs()
  if pa <= pb && pa <= pc {
    a
  } else if pb <= pc {
    b
  } else {
    c
  }
}

///|
/// QOI 哈希函数：将 RGBA 像素映射到 [0, 63] 的索引。 QOI hash function: maps RGBA pixel to an index in [0, 63].
///
/// 结果在 [0, 63] 范围内（QOI 规范保证）。 Result is guaranteed in [0, 63] range (QOI spec guarantee).
///
/// 参数 Parameters:
/// - `r` - 红色通道 Red channel
/// - `g` - 绿色通道 Green channel
/// - `b` - 蓝色通道 Blue channel
/// - `a` - 透明通道 Alpha channel
///
/// 返回 Return:
/// - 哈希索引（0-63）Hash index (0-63)
///
/// 示例 Example:
/// ```mbt check
/// test "doc_qoi_hash" {
///   let h = @safe_math.qoi_hash(255, 0, 0, 255)
///   assert_true(h >= 0 && h < 64)
/// }
/// ```
#inline
pub fn qoi_hash(r : Int32, g : Int32, b : Int32, a : Int32) -> Int32 {
  (r * 3 + g * 5 + b * 7 + a * 11) % 64
}

///|
/// GIF 3-3-2 量化：将 RGB 像素映射到 256 色调色板索引。 GIF 3-3-2 quantization: maps RGB pixel to 256-color palette index.
///
/// 结果在 [0, 255] 范围内。 Result is guaranteed in [0, 255] range.
///
/// 参数 Parameters:
/// - `r` - 红色通道（0-255）Red channel (0-255)
/// - `g` - 绿色通道（0-255）Green channel (0-255)
/// - `b` - 蓝色通道（0-255）Blue channel (0-255)
///
/// 返回 Return:
/// - 调色板索引（0-255）Palette index (0-255)
///
/// 示例 Example:
/// ```mbt check
/// test "doc_quantize_332" {
///   let idx = @safe_math.quantize_332(255, 128, 0)
///   assert_true(idx >= 0 && idx <= 255)
/// }
/// ```
#inline
pub fn quantize_332(r : Int32, g : Int32, b : Int32) -> Int32 {
  let r_level = (r >> 5) & 0x07
  let g_level = (g >> 5) & 0x07
  let b_level = (b >> 6) & 0x03
  r_level * 32 + g_level * 4 + b_level
}

///|
/// 汉明距离：计算两个整数在二进制表示下不同位的数量。 Hamming distance: counts the number of differing bits between two integers.
///
/// 结果 >= 0。 Result >= 0.
///
/// 参数 Parameters:
/// - `a` - 第一个整数 First integer
/// - `b` - 第二个整数 Second integer
///
/// 返回 Return:
/// - 不同位的数量 Number of differing bits
///
/// 示例 Example:
/// ```mbt check
/// test "doc_hamming_distance" {
///   // 0b1010 (10) vs 0b1100 (12): 2 bits differ
///   assert_eq(@safe_math.hamming_distance(10, 12), 2)
/// }
/// ```
///
/// ```mbt check
/// test "doc_hamming_distance_same" {
///   assert_eq(@safe_math.hamming_distance(42, 42), 0)
/// }
/// ```
#inline
pub fn hamming_distance(a : Int32, b : Int32) -> Int32 {
  let xor_val = a ^ b
  let mut count = 0
  let mut x = xor_val
  while x > 0 {
    count += x & 1
    x = x >> 1
  }
  count
}
