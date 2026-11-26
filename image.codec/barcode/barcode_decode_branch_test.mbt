// 覆盖率测试：条码解码的错误分支、配置门控与空白图路径

fn bdc_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, fill.to_byte())),
  }
}

fn bdc_short(w : Int32, h : Int32, c : Int32, len : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(len, b'\x00')),
  }
}

fn bdc_cfg(
  ean13 : Bool,
  upca : Bool,
  code128 : Bool,
  qr : Bool,
) -> @barcode.BarcodeConfig {
  @barcode.BarcodeConfig::{
    enable_ean13: ean13,
    enable_upca: upca,
    enable_code128: code128,
    enable_qrcode: qr,
    min_bar_width: 1,
    max_bar_width: 20,
    scan_lines: 10,
    quiet_zone_required: true,
  }
}

fn bdc_none(r : @barcode.BarcodeResult?) -> Bool {
  match r {
    None => true
    Some(_) => false
  }
}

test "bdccov: decode_ean13 校验错误与配置门控" {
  // 尺寸非法
  try {
    let _ = @barcode.decode_ean13(bdc_img(0, 10, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道数非法
  try {
    let _ = @barcode.decode_ean13(bdc_img(10, 10, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 数据长度不匹配
  try {
    let _ = @barcode.decode_ean13(bdc_short(10, 10, 1, 10))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 关闭 EAN13 → 直接 None
  let blank = bdc_img(20, 20, 1, 255)
  let off = @barcode.decode_ean13(blank, config=@barcode.BarcodeConfig::{
    enable_ean13: false,
    enable_upca: false,
    enable_code128: false,
    enable_qrcode: false,
    min_bar_width: 1,
    max_bar_width: 20,
    scan_lines: 10,
    quiet_zone_required: true,
  })
  assert_true(bdc_none(off))
  // 空白图无法识别 → None
  let none = @barcode.decode_ean13(blank)
  assert_true(bdc_none(none))
  // 黑图同样无法识别
  let dark = bdc_img(20, 20, 1, 0)
  let none2 = @barcode.decode_ean13(dark)
  assert_true(bdc_none(none2))
}

test "bdccov: decode_qrcode / detect_qr_finder_patterns" {
  // 校验错误
  try {
    let _ = @barcode.decode_qrcode(bdc_img(0, 0, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.decode_qrcode(bdc_img(8, 8, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.decode_qrcode(bdc_short(8, 8, 1, 8))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 关闭 QR → None
  let blank = bdc_img(32, 32, 1, 255)
  let off = @barcode.decode_qrcode(blank, config=bdc_cfg(false, false, false, false))
  assert_true(bdc_none(off))
  // 空白图 → None
  assert_true(bdc_none(@barcode.decode_qrcode(blank)))
  // 定位图案检测：空白图 → 0 个
  let _pats = @barcode.detect_qr_finder_patterns(blank)
  // 定位图案检测错误分支
  try {
    let _ = @barcode.detect_qr_finder_patterns(bdc_img(0, 8, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.detect_qr_finder_patterns(bdc_img(8, 8, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.detect_qr_finder_patterns(bdc_short(8, 8, 1, 8))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "bdccov: decode_barcode 汇总分支" {
  let blank = bdc_img(24, 24, 1, 255)
  // 校验错误
  try {
    let _ = @barcode.decode_barcode(bdc_img(0, 24, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.decode_barcode(bdc_img(24, 24, 7, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @barcode.decode_barcode(bdc_short(24, 24, 1, 24))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 默认配置：空白图 → 无结果
  let r0 = @barcode.decode_barcode(blank)
  assert_true(r0.length() == 0)
  // 全部关闭 → 无结果（两条 None 分支）
  let r1 = @barcode.decode_barcode(blank, config=bdc_cfg(false, false, false, false))
  assert_true(r1.length() == 0)
  // 仅开 EAN13
  let r2 = @barcode.decode_barcode(blank, config=bdc_cfg(true, false, false, false))
  assert_true(r2.length() == 0)
  // 默认配置字段
  let d = @barcode.barcode_default_config()
  assert_true(d.enable_ean13)
  assert_true(d.enable_upca)
  assert_true(!d.enable_code128)
  assert_true(d.enable_qrcode)
  assert_true(d.scan_lines == 10)
}
