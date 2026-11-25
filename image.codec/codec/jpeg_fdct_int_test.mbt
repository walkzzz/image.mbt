///|
/// JPEG 编码器提速回归：整数 FDCT 后的像素误差与体积。
fn jpeg_sq_gradient(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let src : Array[Byte] = Array::make(wi * hi * 4, b'\x00')
  for y in 0..<hi {
    for x in 0..<wi {
      let i = (y * wi + x) * 4
      src[i] = ((x * 4) % 256).to_byte()
      src[i + 1] = ((y * 4) % 256).to_byte()
      src[i + 2] = (((x + y) * 2) % 256).to_byte()
      src[i + 3] = (255).to_byte()
    }
  }
  @types.Image::{ width: w, height: h, channels: 4, data: Bytes::from_array(src) }
}

///|
/// 平滑渐变（无锯齿高频），用于质量档位的失真断言。
fn jpeg_smooth_gradient(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let src : Array[Byte] = Array::make(wi * hi * 3, b'\x00')
  for y in 0..<hi {
    for x in 0..<wi {
      let i = (y * wi + x) * 3
      src[i] = (x * 255 / wi).to_byte()
      src[i + 1] = (y * 255 / hi).to_byte()
      src[i + 2] = ((x + y) * 255 / (wi + hi)).to_byte()
    }
  }
  @types.Image::{ width: w, height: h, channels: 3, data: Bytes::from_array(src) }
}

///|
/// 纯色图，用于守护"量化表共享引用"这类回归（色彩必须基本不变）。
fn jpeg_solid(w : Int32, h : Int32, r : Int32, g : Int32, b : Int32) -> @types.Image {
  let n = w.to_int() * h.to_int()
  let src : Array[Byte] = Array::make(n * 3, b'\x00')
  for i in 0..<n {
    src[i * 3] = r.to_byte()
    src[i * 3 + 1] = g.to_byte()
    src[i * 3 + 2] = b.to_byte()
  }
  @types.Image::{ width: w, height: h, channels: 3, data: Bytes::from_array(src) }
}

///|
/// 编码 → 解码 → 与源图逐像素最大通道差
fn jpeg_roundtrip_max_diff(img : @types.Image, quality : Int32) -> Int32 raise @types.LoadError {
  let enc = @codec.encode_jpeg_with_quality(img, quality)
  let dec = @codec.decode_jpeg_pure(enc)
  let n = img.width * img.height
  let mut max_diff = 0
  for i in 0..<n {
    for c in 0..<3 {
      let a = dec.data[i * dec.channels + c].to_int()
      let b = img.data[i * img.channels + c].to_int()
      let d = if a > b {
        a - b
      } else {
        b - a
      }
      if d > max_diff {
        max_diff = d
      }
    }
  }
  max_diff
}

///|
/// 整数 FDCT 回归：64² 锯齿梯度，体积与误差只在阈值内断言（位流由 check_jpeg.mjs 外部校验）。
test "jpeg 整数 FDCT：64² 锯齿梯度回环误差 ≤10" {
  let img = jpeg_sq_gradient(64, 64)
  let enc = @codec.encode_jpeg_pure(img)
  let diff = jpeg_roundtrip_max_diff(img, 50)
  println("JPEG 64² 体积=\{enc.length()} 最大通道误差=\{diff}")
  println("JPEGHEX=" + vp8l_to_hex(enc))
  assert_true(enc.length() > 0 && enc.length() < 2048)
  assert_true(diff <= 10)
}

///|
/// 质量档：1024² 平滑渐变，Q=90 误差 ≤6、Q=75 ≤8。
/// 注：在这类近无损设置下误差主要由 IDCT 取整决定，Q90 的 max 不保证严格优于 Q75。
test "jpeg 质量档：1024² 平滑渐变 Q90 ≤6、Q75 ≤8" {
  let img = jpeg_smooth_gradient(1024, 1024)
  let diff90 = jpeg_roundtrip_max_diff(img, 90)
  let diff75 = jpeg_roundtrip_max_diff(img, 75)
  println("JPEG 1024² smooth Q90=\{diff90} Q75=\{diff75}")
  assert_true(diff90 <= 6)
  assert_true(diff75 <= 8)
}

///|
/// 量化表隔离：4:4:4 纯色回环必须几乎无偏色（历史 bug：4 张量化表共享一个数组）。
test "jpeg 纯色回环无偏色（量化表隔离）" {
  let img = jpeg_solid(32, 32, 200, 100, 60)
  let diff = jpeg_roundtrip_max_diff(img, 90)
  println("JPEG 纯色 (200,100,60) Q90 误差=\{diff}")
  assert_true(diff <= 3)
}

///|
/// 质量参数边界：1 与 100 均可编码，且 Q=100 体积大于 Q=1。
test "jpeg 质量参数边界 1/100" {
  let img = jpeg_solid(64, 64, 180, 90, 40)
  let tiny = @codec.encode_jpeg_with_quality(img, 1)
  let best = @codec.encode_jpeg_with_quality(img, 100)
  assert_true(tiny.length() > 0 && best.length() > tiny.length())
}
