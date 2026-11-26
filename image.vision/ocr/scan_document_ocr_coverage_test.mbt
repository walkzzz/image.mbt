// 覆盖率测试：扫描文档 OCR（质量评估 / 预处理 / 版面分析 / 批量 / 多格式导出）

///|
fn sdc_gray(w : Int32, h : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(f(x, y).to_byte())
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn sdc_flat(w : Int32, h : Int32, v : Int32) -> @types.Image {
  sdc_gray(w, h, fn(_x, _y) { v })
}

///|
fn sdc_rgb(
  w : Int32,
  h : Int32,
  f : (Int32, Int32) -> (Int32, Int32, Int32),
) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let (r, g, b) = f(x, y)
      d.push(r.to_byte())
      d.push(g.to_byte())
      d.push(b.to_byte())
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(d),
  }
}

///|
fn sdc_scan_cfg(bin_method : String) -> @ocr.ScanOCRConfig {
  @ocr.ScanOCRConfig::{
    language: "english",
    dpi: 300,
    deskew: true,
    denoise: true,
    binarization_method: bin_method,
    layout_analysis: true,
    confidence_threshold: 0.6,
  }
}

///|
test "sdcov: 默认配置与质量评估" {
  let cfg = @ocr.scan_ocr_default_config()
  assert_true(cfg.language == "english")
  assert_true(cfg.dpi == 300)
  assert_true(cfg.deskew)
  assert_true(cfg.denoise)
  assert_true(cfg.binarization_method == "otsu")
  assert_true(cfg.layout_analysis)
  assert_true(cfg.confidence_threshold == 0.6)
  // 非平滑纹理灰度图（线性渐变会得到 0 拉普拉斯）
  let grad = sdc_gray(16, 16, fn(x, y) { (x * 37 + y * 91) % 256 })
  let q = @ocr.evaluate_scan_quality(grad)
  assert_true(q.brightness > 0.0 && q.brightness < 255.0)
  assert_true(q.contrast > 0.0)
  assert_true(q.sharpness > 0.0)
  assert_true(q.skew_angle == 0.0)
  assert_true(q.overall_score >= 0.0 && q.overall_score <= 100.0)
  // 全黑 → 过暗
  let black = sdc_flat(8, 8, 0)
  let qb = @ocr.evaluate_scan_quality(black)
  assert_true(qb.brightness == 0.0)
  assert_true(qb.contrast == 0.0)
  assert_true(qb.noise_level == 10.0)
  assert_true(qb.issues.contains("图像过暗"))
  assert_true(qb.issues.contains("对比度不足"))
  // 全白 → 过亮
  let white = sdc_flat(8, 8, 255)
  let qw = @ocr.evaluate_scan_quality(white)
  assert_true(qw.brightness == 255.0)
  assert_true(qw.issues.contains("图像过亮"))
  // 2x2：锐度循环不执行 → 模糊
  let tiny = sdc_flat(2, 2, 100)
  let qt = @ocr.evaluate_scan_quality(tiny)
  assert_true(qt.sharpness == 0.0)
  assert_true(qt.issues.contains("图像模糊"))
  // RGB 分支
  let rgb = sdc_rgb(8, 8, fn(x, y) {
    (x * 10 % 256, y * 10 % 256, (x + y) % 256)
  })
  let qr = @ocr.evaluate_scan_quality(rgb)
  assert_true(qr.brightness > 0.0)
  assert_true(qr.sharpness >= 0.0)
  // 高对比 + 高噪声：噪声较高分支
  let noisy = sdc_gray(16, 16, fn(x, y) {
    if (x + y) % 2 == 0 {
      0
    } else {
      255
    }
  })
  let qn = @ocr.evaluate_scan_quality(noisy)
  assert_true(qn.contrast > 50.0)
  // 校验
  try {
    let _ = @ocr.evaluate_scan_quality(sdc_flat(0, 4, 10))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 5,
    data: Bytes::from_array(Array::make(80, b'\x00')),
  }
  try {
    let _ = @ocr.evaluate_scan_quality(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.evaluate_scan_quality(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "sdcov: 预处理各二值化分支" {
  let img = sdc_gray(16, 16, fn(x, _y) { if x < 8 { 30 } else { 220 } })
  // otsu
  let o = @ocr.scan_document_preprocess(img, sdc_scan_cfg("otsu"))
  assert_true(o.width == 16 && o.height == 16)
  assert_true(o.channels == 1)
  // adaptive
  let a = @ocr.scan_document_preprocess(img, sdc_scan_cfg("adaptive"))
  assert_true(a.data.length() == 256)
  // sauvola
  let s = @ocr.scan_document_preprocess(img, sdc_scan_cfg("sauvola"))
  assert_true(s.data.length() == 256)
  // 未知方法 → otsu
  let u = @ocr.scan_document_preprocess(img, sdc_scan_cfg("weird"))
  assert_true(u.data.length() == 256)
  // 关闭去噪
  let no_denoise = @ocr.ScanOCRConfig::{
    language: "english",
    dpi: 300,
    deskew: true,
    denoise: false,
    binarization_method: "otsu",
    layout_analysis: true,
    confidence_threshold: 0.6,
  }
  let nd = @ocr.scan_document_preprocess(img, no_denoise)
  assert_true(nd.data.length() == 256)
  // 校验
  try {
    let _ = @ocr.scan_document_preprocess(
      sdc_flat(0, 4, 10),
      sdc_scan_cfg("otsu"),
    )
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 6,
    data: Bytes::from_array(Array::make(96, b'\x00')),
  }
  try {
    let _ = @ocr.scan_document_preprocess(bad_ch, sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.scan_document_preprocess(bad_data, sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
fn sdc_doc() -> @types.Image {
  // 20 行 30 列，行 4..7 与 12..15 有黑字（x 2..20）
  sdc_gray(30, 20, fn(x, y) {
    let in_band = (y >= 4 && y <= 7) || (y >= 12 && y <= 15)
    if in_band && x >= 2 && x <= 20 {
      0
    } else {
      255
    }
  })
}

///|
test "sdcov: 版面分析与完整流水线" {
  let doc = sdc_doc()
  // 明显二值图：两行文本块
  let blocks = @ocr.analyze_layout_scan(doc)
  assert_true(blocks.length() == 2)
  assert_true(blocks[0].y >= 4)
  assert_true(blocks[0].block_type == "text")
  assert_true(blocks[0].reading_order == 0)
  assert_true(blocks[1].reading_order == 1)
  assert_true(blocks[0].width > 0)
  // 空白（全白）图 → 无块
  let blank = sdc_flat(30, 20, 255)
  let nb = @ocr.analyze_layout_scan(blank)
  assert_true(nb.length() == 0)
  // 校验
  try {
    let _ = @ocr.analyze_layout_scan(sdc_flat(0, 4, 255))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let rgb = sdc_rgb(4, 4, fn(_x, _y) { (0, 0, 0) })
  try {
    let _ = @ocr.analyze_layout_scan(rgb)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.analyze_layout_scan(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 完整流水线（含版面分析）
  let r = @ocr.scan_ocr_recognize(doc, sdc_scan_cfg("otsu"))
  assert_true(r.page_number == 1)
  assert_true(r.width == 30 && r.height == 20)
  assert_true(r.full_text.length() > 0)
  assert_true(r.average_confidence > 0.0 && r.average_confidence <= 1.0)
  // 关闭版面分析 → 单块占位
  let cfg2 = @ocr.ScanOCRConfig::{
    language: "english",
    dpi: 300,
    deskew: true,
    denoise: true,
    binarization_method: "otsu",
    layout_analysis: false,
    confidence_threshold: 0.6,
  }
  let r2 = @ocr.scan_ocr_recognize(doc, cfg2)
  assert_true(r2.blocks.length() == 1)
  assert_true(r2.blocks[0].width == 30)
  assert_true(r2.full_text.contains("文本块 0"))
  // 无块（全白 + 版面分析）→ 置信度 0
  let r3 = @ocr.scan_ocr_recognize(blank, sdc_scan_cfg("otsu"))
  assert_true(r3.average_confidence >= 0.0)
  // 校验
  try {
    let _ = @ocr.scan_ocr_recognize(sdc_flat(0, 4, 255), sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 4,
    height: 4,
    channels: 5,
    data: Bytes::from_array(Array::make(80, b'\x00')),
  }
  try {
    let _ = @ocr.scan_ocr_recognize(bad_ch, sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "sdcov: 批量处理与导出" {
  let doc = sdc_doc()
  let imgs : Array[@types.Image] = [doc, sdc_flat(32, 32, 255)]
  let rs = @ocr.batch_scan_ocr(imgs, sdc_scan_cfg("otsu"))
  assert_true(rs.length() == 2)
  assert_true(rs[0].page_number == 1)
  assert_true(rs[1].page_number == 2)
  // 校验：空列表
  let empty : Array[@types.Image] = []
  try {
    let _ = @ocr.batch_scan_ocr(empty, sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 校验：含非法图像
  let bad : Array[@types.Image] = [doc, sdc_flat(0, 4, 255)]
  try {
    let _ = @ocr.batch_scan_ocr(bad, sdc_scan_cfg("otsu"))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 文本导出
  let first = rs[0]
  assert_true(@ocr.ocr_result_to_text(first) == first.full_text)
  // hOCR 导出
  let hocr = @ocr.ocr_result_to_hocr(first)
  assert_true(hocr.contains("ocr_page"))
  assert_true(hocr.contains("bbox 0 0 30 20"))
  assert_true(hocr.contains("ocr_line"))
  assert_true(hocr.contains("</html>"))
  // 空块结果 → 仍包含页面框
  let empty_result = @ocr.OCRPageResult::{
    page_number: 3,
    width: 10,
    height: 10,
    blocks: [],
    full_text: "",
    average_confidence: 0.0,
    processing_time_ms: 0.0,
  }
  let h2 = @ocr.ocr_result_to_hocr(empty_result)
  assert_true(h2.contains("bbox 0 0 10 10"))
  // JSON 导出
  let json = @ocr.ocr_result_to_json(first)
  assert_true(json.contains("\"page_number\": 1"))
  assert_true(json.contains("\"width\": 30"))
  assert_true(json.contains("\"blocks\": ["))
  let json2 = @ocr.ocr_result_to_json(empty_result)
  assert_true(json2.contains("\"page_number\": 3"))
}
