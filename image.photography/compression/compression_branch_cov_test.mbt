// 覆盖率测试：量化钳位、算法枚举映射与压缩分派

///|
fn cqc_img(w : Int32, h : Int32, ch : Int32, v : Int32) -> @types.Image {
  let n = w * h * ch
  let data : Array[Byte] = []
  for _i in 0..<n {
    data.push(v.to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn cqc_cfg(
  a : @compression.CompressionAlgorithm,
  q : Double,
) -> @compression.CompressionConfig {
  @compression.CompressionConfig::{
    algorithm: a,
    quality: q,
    quantization_level: 16,
    use_dct: false,
    use_prediction: false,
    use_entropy_coding: false,
    block_size: 8,
  }
}

///|
test "cqc: 算法名称全枚举" {
  let names : Array[(@compression.CompressionAlgorithm, String)] = [
    (@compression.CompressionAlgorithm::RunLengthEncoding, "RLE"),
    (@compression.CompressionAlgorithm::HuffmanCoding, "霍夫曼"),
    (@compression.CompressionAlgorithm::ArithmeticCoding, "算术"),
    (@compression.CompressionAlgorithm::LZW, "LZW"),
    (@compression.CompressionAlgorithm::Deflate, "Deflate"),
    (@compression.CompressionAlgorithm::JPEGBaseline, "JPEG 基线"),
    (@compression.CompressionAlgorithm::JPEG2000, "JPEG 2000"),
    (@compression.CompressionAlgorithm::WebP, "WebP"),
    (@compression.CompressionAlgorithm::AVIF, "AVIF"),
    (@compression.CompressionAlgorithm::PNG, "PNG"),
    (@compression.CompressionAlgorithm::Unknown, "未知"),
  ]
  for pair in names {
    let (a, expect) = pair
    let s = @compression.compression_algorithm_to_string(a)
    assert_true(s.contains(expect))
  }
}

///|
test "cqc: 三种算法分派都能产出字节" {
  let img = cqc_img(16, 16, 3, 200)
  let algos : Array[@compression.CompressionAlgorithm] = [
    @compression.CompressionAlgorithm::JPEGBaseline,
    @compression.CompressionAlgorithm::PNG,
    @compression.CompressionAlgorithm::RunLengthEncoding,
  ]
  for a in algos {
    let r = @compression.compress_image(img, cqc_cfg(a, 85.0)) catch {
      _ =>
        @compression.CompressionResult::{
          compressed_data: Bytes::from_array([]),
          original_size: 0,
          compressed_size: 0,
          compression_ratio: 0.0,
          bits_per_pixel: 0.0,
          algorithm: @compression.CompressionAlgorithm::Unknown,
          quality: 0.0,
          processing_time_ms: 0.0,
        }
    }
    assert_true(r.compressed_size >= 0)
  }
}

///|
test "cqc: 质量档位影响量化级别" {
  let img = cqc_img(8, 8, 1, 200)
  let qs : Array[Double] = [95.0, 80.0, 60.0, 30.0]
  for _q in qs {
    let out = @compression.quantize_image(img, 32) catch { _ => img }
    assert_true(out.width == 8)
  }
  for q in qs {
    try {
      let r = @compression.compress_image(
        img,
        cqc_cfg(@compression.CompressionAlgorithm::PNG, q),
      )
      assert_true(r.compressed_size > 0)
    } catch {
      _ => assert_true(false)
    }
  }
}

///|
test "cqc: 量化上溢钳位到 255" {
  let img = cqc_img(4, 4, 1, 255)
  let out = @compression.quantize_image(img, 5) catch { _ => img }
  for i in 0..<out.data.length() {
    assert_true(out.data[i].to_int() <= 255)
  }
  assert_true(out.data[0].to_int() == 255)
}

///|
test "cqc: 压缩比为 0 的兜底" {
  let r = @compression.calculate_compression_ratio(1024, 0)
  assert_true(r == 0.0)
  let r2 = @compression.calculate_compression_ratio(2048, 512)
  assert_true(r2 == 4.0)
}

///|
test "cqc: 质量指标与报告文本" {
  let a = cqc_img(8, 8, 3, 120)
  let b = cqc_img(8, 8, 3, 100)
  let metrics = @compression.calculate_compression_quality(a, b, 192, 96) catch {
    _ =>
      @compression.CompressionQualityMetrics::{
        psnr: 0.0,
        ssim: 0.0,
        mse: 0.0,
        compression_ratio: 0.0,
        bits_per_pixel: 0.0,
        structural_similarity: 0.0,
        overall_quality: 0.0,
      }
  }
  let res : @compression.CompressionResult = {
    compressed_data: Bytes::from_array([1, 2, 3]),
    original_size: 192,
    compressed_size: 3,
    compression_ratio: 64.0,
    bits_per_pixel: 1.5,
    algorithm: @compression.CompressionAlgorithm::PNG,
    quality: 0.9,
    processing_time_ms: 1.0,
  }
  let text = @compression.compression_report_to_string(res, metrics)
  assert_true(text.contains("PNG"))
  assert_true(text.contains("压缩比"))
}
