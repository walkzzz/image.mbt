///|
test "testgen-drive: Code39 往返 ABC" {
  let img = @testgen.render_code39([10, 11, 12], module_px=1)
  try {
    match @barcode.decode_code39(img) {
      Some(r) => assert_eq(r.data, "ABC")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}

///|
test "testgen-drive: QR 往返 hello" {
  let img = @testgen.render_qr(b"hello")
  try {
    match @barcode.decode_qrcode_full(img) {
      Some(r) => assert_eq(r.data, "hello")
      None => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}
