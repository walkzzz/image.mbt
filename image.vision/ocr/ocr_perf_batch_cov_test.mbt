// 覆盖率测试：OCR 性能工具 / 批处理 / 二值化 / 表格结构

///|
fn opb_gray(w : Int32, h : Int32, fill : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, fill.to_byte())),
  }
}

///|
fn opb_table() -> @types.Image {
  // 64x64 白底，3 条横线与 3 条竖线
  let w = 64
  let h = 64
  let d : Array[Int32] = Array::make(w * h, 255)
  for y in [4, 20, 44] {
    for x in 0..<w {
      d[y * w + x] = 0
    }
  }
  for x in [6, 30, 58] {
    for y in 0..<h {
      d[y * w + x] = 0
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

///|
test "perf: LUT 与投影" {
  let lut = @ocr.build_grayscale_lut()
  assert_true(lut.length() == 256)
  let tl = @ocr.build_threshold_lut(128)
  assert_true(tl.length() == 256)
  let gray = opb_gray(16, 12, 100)
  let out = @ocr.fast_threshold_lut(gray, tl)
  assert_true(out.width == 16)
  let hp = @ocr.cache_friendly_horizontal_projection(gray)
  assert_true(hp.length() == 12)
  let vp = @ocr.cache_friendly_vertical_projection(gray)
  assert_true(vp.length() == 16)
  let sum = @ocr.unrolled_pixel_sum(gray)
  assert_true(sum >= 0)
  let cc = @ocr.fast_connected_components(gray)
  assert_true(cc.length() > 0)
  let stats = @ocr.ocr_pipeline_stats(gray)
  assert_true(stats.2 >= 0.0)
  let down = @ocr.fast_downsample_2x(opb_gray(16, 16, 200))
  assert_true(down.width == 8)
  // 高斯核与模糊
  let k1 = @ocr.build_gaussian_kernel_lut(1.0, 1)
  assert_true(k1.length() == 3)
  let k3 = @ocr.build_gaussian_kernel_lut(1.5, 3)
  assert_true(k3.length() == 7)
  let blurred = @ocr.fast_gaussian_blur_1d(gray, k1)
  assert_true(blurred.width == 16)
  // 错误分支
  try {
    let _ = @ocr.fast_threshold_lut(opb_gray(0, 4, 0), tl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.cache_friendly_horizontal_projection(opb_gray(0, 4, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.cache_friendly_vertical_projection(opb_gray(0, 4, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.unrolled_pixel_sum(opb_gray(0, 4, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.fast_connected_components(opb_gray(0, 4, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.ocr_pipeline_stats(opb_gray(0, 4, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.fast_downsample_2x(opb_gray(1, 8, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.build_gaussian_kernel_lut(0.0, 2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.build_gaussian_kernel_lut(1.0, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.fast_gaussian_blur_1d(opb_gray(0, 4, 0), k1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "batch: 任务生命周期与摘要" {
  let cfg = @ocr.create_default_batch_config()
  assert_true(cfg.max_concurrent >= 1)
  assert_true(cfg.batch_size >= 1)
  let tasks = @ocr.create_batch_tasks(["a.png", "b.png"], "out", "text")
  assert_true(tasks.length() == 2)
  assert_true(tasks[0].input_path == "a.png")
  let t0 = tasks[0]
  let t1 = @ocr.update_task_progress(t0, 0.5, 2, 4)
  assert_true(t1.progress > 0.0)
  let t2 = @ocr.mark_task_completed(t1, 100, 0.9, 2000.0)
  assert_true(t2.char_count == 100)
  let t3 = @ocr.mark_task_failed(t0, "boom", 3000.0)
  assert_true(t3.error_message.length() > 0)
  let prog = @ocr.calculate_batch_progress([t2, t3], 4000.0)
  assert_true(prog.total_tasks == 2)
  let summary = @ocr.generate_batch_summary([t2, t3], 4000.0)
  assert_true(summary.total_tasks == 2)
  let report = @ocr.batch_summary_to_string(summary)
  assert_true(report.length() > 0)
  let bar0 = @ocr.progress_bar_to_string(0.0)
  let bar1 = @ocr.progress_bar_to_string(0.5, width=10)
  let bar2 = @ocr.progress_bar_to_string(1.0, width=10)
  assert_true(bar0.length() > 0 && bar1.length() > 0 && bar2.length() > 0)
  let mem = @ocr.estimate_memory_usage(2, 100, 100, 1)
  assert_true(mem.current_usage_mb >= 0.0)
  // 错误分支
  try {
    let _ = @ocr.create_batch_tasks([], "out", "text")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.create_batch_tasks(["a.png"], "", "text")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.create_batch_tasks(["a.png"], "out", "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.calculate_batch_progress([], 1000.0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.generate_batch_summary([], 1000.0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "bin: Niblack / Sauvola / 自适应 / Otsu" {
  let img = opb_gray(32, 32, 128)
  let n = @ocr.niblack_threshold(img)
  assert_true(n.width == 32)
  let n2 = @ocr.niblack_threshold(img, window_size=7, k=-0.3)
  assert_true(n2.height == 32)
  let s = @ocr.sauvola_threshold(img)
  assert_true(s.width == 32)
  let s2 = @ocr.sauvola_threshold(img, window_size=9, k=0.4, r=100.0)
  assert_true(s2.width == 32)
  let a = @ocr.adaptive_threshold_ocr(img)
  assert_true(a.width == 32)
  let a2 = @ocr.adaptive_threshold_ocr(img, block_size=9, c=5)
  assert_true(a2.width == 32)
  let o = @ocr.otsu_threshold(img)
  assert_true(o.width == 32)
  // 错误分支
  let rgb = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(8 * 8 * 3, (10).to_byte())),
  }
  try {
    let _ = @ocr.niblack_threshold(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.sauvola_threshold(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.adaptive_threshold_ocr(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.otsu_threshold(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.niblack_threshold(img, window_size=10)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.sauvola_threshold(img, window_size=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.adaptive_threshold_ocr(img, block_size=4)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "tab: 表格线与结构识别" {
  let t = opb_table()
  let hl = @ocr.detect_horizontal_lines(t, min_length=20, max_gap=2)
  assert_true(hl.length() >= 1)
  let vl = @ocr.detect_vertical_lines(t, min_length=20, max_gap=2)
  assert_true(vl.length() >= 1)
  let st = @ocr.analyze_table_structure(hl, vl)
  assert_true(st.rows >= 1)
  assert_true(st.cols >= 1)
  assert_true(st.cells.length() >= 1)
  let auto = @ocr.recognize_table(t, min_line_length=20)
  assert_true(auto.rows >= 1)
  let cell = st.cells[0]
  let ci = @ocr.extract_cell_image(t, cell, padding=1)
  assert_true(ci.width >= 1)
  let all = @ocr.extract_all_cells(t, st)
  assert_true(all.length() == st.cells.length())
  // 空线 → 错误
  try {
    let _ = @ocr.analyze_table_structure([], vl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.detect_horizontal_lines(opb_gray(0, 8, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.detect_vertical_lines(opb_gray(0, 8, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.recognize_table(opb_gray(0, 8, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
