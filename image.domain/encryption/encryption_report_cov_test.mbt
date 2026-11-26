// 覆盖率测试：加密报告的全部算法/水印类型分支

///|
fn erc_result(
  algo : @encryption.EncryptionAlgorithm,
) -> @encryption.EncryptionResult {
  @encryption.EncryptionResult::{
    encrypted_data: [b'\x01', b'\x02'],
    width: 2,
    height: 1,
    channels: 1,
    algorithm: algo,
    key_hash: "k",
    encryption_time_ms: 1.5,
    file_size_original: 2,
    file_size_encrypted: 2,
  }
}

///|
fn erc_watermark(kind : @encryption.WatermarkType) -> @encryption.WatermarkInfo {
  @encryption.WatermarkInfo::{
    watermark_type: kind,
    watermark_data: [b'\x41'],
    watermark_width: 1,
    watermark_height: 1,
    strength: 0.5,
    embedded: false,
    embedding_position: "corner",
    key: "k",
  }
}

///|
test "加密报告: 七种加密算法名称" {
  let q = @encryption.ImageEncryptionQuality::default()
  let pairs : Array[(@encryption.EncryptionAlgorithm, String)] = [
    (@encryption.XOR, "XOR"),
    (@encryption.AES_Simplified, "AES"),
    (@encryption.Chaotic, "混沌"),
    (@encryption.Arnold, "Arnold"),
    (@encryption.Hill, "Hill"),
    (@encryption.RSA_Simplified, "RSA"),
    (@encryption.EncryptionAlgorithm::Unknown, "未知"),
  ]
  for i in 0..<pairs.length() {
    let (algo, label) = pairs[i]
    let report = @encryption.encryption_report_to_string(
      erc_result(algo),
      erc_watermark(@encryption.Invisible_LSB),
      q,
    )
    assert_true(report.contains(label))
  }
}

///|
test "加密报告: 七种水印类型名称与未嵌入" {
  let q = @encryption.ImageEncryptionQuality::default()
  let pairs : Array[(@encryption.WatermarkType, String)] = [
    (@encryption.Visible, "可见水印"),
    (@encryption.Invisible_LSB, "LSB"),
    (@encryption.Invisible_DCT, "DCT"),
    (@encryption.Invisible_DWT, "DWT"),
    (@encryption.Robust, "鲁棒"),
    (@encryption.Fragile, "脆弱"),
    (@encryption.WatermarkType::Unknown, "未知"),
  ]
  for i in 0..<pairs.length() {
    let (kind, label) = pairs[i]
    let report = @encryption.encryption_report_to_string(
      erc_result(@encryption.XOR),
      erc_watermark(kind),
      q,
    )
    assert_true(report.contains(label))
    assert_true(report.contains("否"))
  }
}

///|
test "加密报告: 质量指标全字段渲染" {
  let q = @encryption.ImageEncryptionQuality::{
    entropy: 7.5,
    correlation_horizontal: 0.1,
    correlation_vertical: 0.2,
    correlation_diagonal: 0.3,
    uaci: 33.0,
    npcr: 66.0,
    key_sensitivity: 0.99,
    psnr: 12.5,
  }
  let report = @encryption.encryption_report_to_string(
    erc_result(@encryption.Chaotic),
    erc_watermark(@encryption.Robust),
    q,
  )
  assert_true(report.contains("信息熵"))
  assert_true(report.contains("NPCR"))
  assert_true(report.contains("UACI"))
  assert_true(report.contains("PSNR"))
  assert_true(report.contains("密钥敏感度"))
}
