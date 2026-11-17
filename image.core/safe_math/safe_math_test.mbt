///|
/// 安全算术与核心证明函数测试

// === safe_mul ===

test "safe_mul: normal multiplication" {
  assert_eq(@safe_math.safe_mul(100, 200), Some(20000))
  assert_eq(@safe_math.safe_mul(0, 100), Some(0))
  assert_eq(@safe_math.safe_mul(1, 1), Some(1))
}

///|
test "safe_mul: overflow returns None" {
  assert_eq(@safe_math.safe_mul(100000, 100000), None)
  assert_eq(@safe_math.safe_mul(46341, 46341), None)
}

///|
test "safe_mul: boundary values" {
  assert_eq(@safe_math.safe_mul(46340, 46340), Some(2147395600))
  assert_eq(@safe_math.safe_mul(46340, 46341), Some(2147441940))
}

///|
test "safe_mul: negative inputs" {
  assert_eq(@safe_math.safe_mul(-1, 100), Some(0))
  assert_eq(@safe_math.safe_mul(100, -1), Some(0))
  assert_eq(@safe_math.safe_mul(-5, -3), Some(0))
}

// === safe_mul3 ===

///|
test "safe_mul3: normal multiplication" {
  assert_eq(@safe_math.safe_mul3(100, 200, 3), Some(60000))
  assert_eq(@safe_math.safe_mul3(1920, 1080, 3), Some(6220800))
}

///|
test "safe_mul3: overflow returns None" {
  assert_eq(@safe_math.safe_mul3(10000, 10000, 100), None)
}

///|
test "safe_mul3: overflow in second multiply" {
  assert_eq(@safe_math.safe_mul3(50000, 50000, 1), None)
  assert_eq(@safe_math.safe_mul3(20000, 20000, 100), None)
}

// === dims_valid_check ===

///|
test "dims_valid_check: valid dimensions" {
  assert_true(@safe_math.dims_valid_check(100, 100, 3))
  assert_true(@safe_math.dims_valid_check(1, 1, 1))
  assert_true(@safe_math.dims_valid_check(65535, 1, 4))
  assert_true(@safe_math.dims_valid_check(1920, 1080, 3))
}

///|
test "dims_valid_check: invalid dimensions" {
  assert_true(!@safe_math.dims_valid_check(0, 100, 3))
  assert_true(!@safe_math.dims_valid_check(100, 0, 3))
  assert_true(!@safe_math.dims_valid_check(-1, 100, 3))
  assert_true(!@safe_math.dims_valid_check(65536, 100, 3))
}

///|
test "dims_valid_check: overflow detection" {
  assert_true(!@safe_math.dims_valid_check(50000, 50000, 1))
  assert_true(!@safe_math.dims_valid_check(40000, 40000, 4))
}

// === clamp_int ===

///|
test "clamp_int: within range" {
  assert_eq(@safe_math.clamp_int(50, 0, 100), 50)
  assert_eq(@safe_math.clamp_int(0, 0, 100), 0)
  assert_eq(@safe_math.clamp_int(100, 0, 100), 100)
}

///|
test "clamp_int: below range" {
  assert_eq(@safe_math.clamp_int(-10, 0, 100), 0)
  assert_eq(@safe_math.clamp_int(-1, 0, 255), 0)
}

///|
test "clamp_int: above range" {
  assert_eq(@safe_math.clamp_int(200, 0, 100), 100)
  assert_eq(@safe_math.clamp_int(300, 0, 255), 255)
}

// === clamp_pixel_value ===

///|
test "clamp_pixel_value: within [0,255]" {
  assert_eq(@safe_math.clamp_pixel_value(128), 128)
  assert_eq(@safe_math.clamp_pixel_value(0), 0)
  assert_eq(@safe_math.clamp_pixel_value(255), 255)
}

///|
test "clamp_pixel_value: negative clamped to 0" {
  assert_eq(@safe_math.clamp_pixel_value(-1), 0)
  assert_eq(@safe_math.clamp_pixel_value(-100), 0)
}

///|
test "clamp_pixel_value: above 255 clamped to 255" {
  assert_eq(@safe_math.clamp_pixel_value(256), 255)
  assert_eq(@safe_math.clamp_pixel_value(1000), 255)
}

// === clamp_coord ===

///|
test "clamp_coord: within bounds" {
  assert_eq(@safe_math.clamp_coord(5, 10), 5)
  assert_eq(@safe_math.clamp_coord(0, 10), 0)
  assert_eq(@safe_math.clamp_coord(9, 10), 9)
}

///|
test "clamp_coord: negative clamped to 0" {
  assert_eq(@safe_math.clamp_coord(-1, 10), 0)
  assert_eq(@safe_math.clamp_coord(-100, 100), 0)
}

///|
test "clamp_coord: at or above max clamped to max-1" {
  assert_eq(@safe_math.clamp_coord(10, 10), 9)
  assert_eq(@safe_math.clamp_coord(100, 50), 49)
}

// === is_valid_index ===

///|
test "is_valid_index: valid" {
  assert_true(@safe_math.is_valid_index(0, 10))
  assert_true(@safe_math.is_valid_index(9, 10))
  assert_true(@safe_math.is_valid_index(5, 100))
}

///|
test "is_valid_index: invalid" {
  assert_true(!@safe_math.is_valid_index(-1, 10))
  assert_true(!@safe_math.is_valid_index(10, 10))
  assert_true(!@safe_math.is_valid_index(5, 0))
}

// === is_valid_2d_index ===

///|
test "is_valid_2d_index: valid" {
  assert_true(@safe_math.is_valid_2d_index(0, 0, 10, 10))
  assert_true(@safe_math.is_valid_2d_index(9, 9, 10, 10))
}

///|
test "is_valid_2d_index: invalid" {
  assert_true(!@safe_math.is_valid_2d_index(-1, 0, 10, 10))
  assert_true(!@safe_math.is_valid_2d_index(10, 0, 10, 10))
  assert_true(!@safe_math.is_valid_2d_index(0, -1, 10, 10))
  assert_true(!@safe_math.is_valid_2d_index(0, 10, 10, 10))
}

// === rotate90_power_is_identity ===

///|
test "rotate90_power_is_identity: multiples of 4" {
  assert_true(@safe_math.rotate90_power_is_identity(0))
  assert_true(@safe_math.rotate90_power_is_identity(4))
  assert_true(@safe_math.rotate90_power_is_identity(8))
  assert_true(@safe_math.rotate90_power_is_identity(-4))
}

///|
test "rotate90_power_is_identity: non-multiples of 4" {
  assert_true(!@safe_math.rotate90_power_is_identity(1))
  assert_true(!@safe_math.rotate90_power_is_identity(2))
  assert_true(!@safe_math.rotate90_power_is_identity(3))
  assert_true(!@safe_math.rotate90_power_is_identity(5))
}

// === paeth_predict ===

///|
test "paeth_predict: basic" {
  assert_eq(@safe_math.paeth_predict(0, 0, 0), 0)
  // p=10+20-5=25, pa=15, pb=5, pc=20 → pb 最小 → 返回 b=20
  assert_eq(@safe_math.paeth_predict(10, 20, 5), 20)
  // 核心属性：结果必为 {a, b, c} 之一
  let result = @safe_math.paeth_predict(100, 50, 75)
  assert_true(result == 100 || result == 50 || result == 75)
}

///|
test "paeth_predict: PNG spec guarantee" {
  // 核心属性：结果必为 {a, b, c} 之一
  let r1 = @safe_math.paeth_predict(10, 20, 30)
  assert_true(r1 == 10 || r1 == 20 || r1 == 30)
  let r2 = @safe_math.paeth_predict(0, 0, 0)
  assert_true(r2 == 0)
}

// === qoi_hash ===

///|
test "qoi_hash: range [0, 63]" {
  let h = @safe_math.qoi_hash(255, 128, 64, 32)
  assert_true(h >= 0 && h < 64)
  let h2 = @safe_math.qoi_hash(0, 0, 0, 0)
  assert_true(h2 >= 0 && h2 < 64)
  assert_eq(h2, 0)
}

// === quantize_332 ===

///|
test "quantize_332: range [0, 255]" {
  let q = @safe_math.quantize_332(255, 255, 255)
  assert_true(q >= 0 && q <= 255)
  let q2 = @safe_math.quantize_332(0, 0, 0)
  assert_true(q2 >= 0 && q2 <= 255)
  assert_eq(q2, 0)
}

// === hamming_distance ===

///|
test "hamming_distance: basic" {
  assert_eq(@safe_math.hamming_distance(0, 0), 0)
  assert_eq(@safe_math.hamming_distance(0, 1), 1)
  assert_eq(@safe_math.hamming_distance(0b1111, 0b0000), 4)
}

// === clamp_byte ===

///|
test "clamp_byte: within [0,255]" {
  assert_eq(@safe_math.clamp_byte(128), (128 : Int32).to_byte())
  assert_eq(@safe_math.clamp_byte(0), (0 : Int32).to_byte())
  assert_eq(@safe_math.clamp_byte(255), (255 : Int32).to_byte())
}

///|
test "clamp_byte: negative clamped to 0" {
  assert_eq(@safe_math.clamp_byte(-1), (0 : Int32).to_byte())
  assert_eq(@safe_math.clamp_byte(-100), (0 : Int32).to_byte())
}

///|
test "clamp_byte: above 255 clamped to 255" {
  assert_eq(@safe_math.clamp_byte(256), (255 : Int32).to_byte())
  assert_eq(@safe_math.clamp_byte(1000), (255 : Int32).to_byte())
}

// === clamp_float ===

///|
test "clamp_float: within range" {
  assert_eq(@safe_math.clamp_float(0.5F, 0.0F, 1.0F), 0.5F)
  assert_eq(@safe_math.clamp_float(0.0F, 0.0F, 1.0F), 0.0F)
  assert_eq(@safe_math.clamp_float(1.0F, 0.0F, 1.0F), 1.0F)
}

///|
test "clamp_float: below range" {
  assert_eq(@safe_math.clamp_float(-0.5F, 0.0F, 1.0F), 0.0F)
}

///|
test "clamp_float: above range" {
  assert_eq(@safe_math.clamp_float(1.5F, 0.0F, 1.0F), 1.0F)
}

// === clamp_double ===

///|
test "clamp_double: within range" {
  assert_eq(@safe_math.clamp_double(0.5, 0.0, 1.0), 0.5)
  assert_eq(@safe_math.clamp_double(0.0, 0.0, 1.0), 0.0)
  assert_eq(@safe_math.clamp_double(1.0, 0.0, 1.0), 1.0)
}

///|
test "clamp_double: below range" {
  assert_eq(@safe_math.clamp_double(-0.5, 0.0, 1.0), 0.0)
}

///|
test "clamp_double: above range" {
  assert_eq(@safe_math.clamp_double(1.5, 0.0, 1.0), 1.0)
}

// === MAX_IMAGE_DIMENSION ===

///|
test "MAX_IMAGE_DIMENSION value" {
  assert_eq(@safe_math.MAX_IMAGE_DIMENSION, 65535)
}
