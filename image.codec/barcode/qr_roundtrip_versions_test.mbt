///|
test "qr: v1..v5 多版本生成 → 解码往返（字节模式）" {
  // 逐档取 10 / 30 / 50 / 70 / 100 字节，分别落在 v1 / v2 / v3 / v4 / v5
  let cases : Array[(Bytes, String, Int32)] = [
    (b"0123456789", "0123456789", 1),
    (b"abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz0123", 2),
    (
      b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX",
      3,
    ),
    (
      b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX01234567890123456789",
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX01234567890123456789", 4,
    ),
    (
      b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX012345678901234567890123456789",
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX012345678901234567890123456789",
      5,
    ),
  ]
  for (payload, expect, v) in cases {
    let img = @testgen.render_qr(payload, module_px=8)
    let size = 17 + 4 * v
    // 渲染尺寸 = (矩阵边长 + 2×静区4) × 模块像素
    assert_eq(img.width, (size + 8) * 8)
    assert_eq(img.height, (size + 8) * 8)
    match @barcode.decode_qrcode_full(img) {
      Some(r) => assert_eq(r.data, expect)
      None => assert_true(false)
    }
  }
}
