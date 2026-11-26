// 覆盖率测试：智能视觉（目标检测 / 车道 / 标志 / 缺陷 / 入侵 / 作物 / 星体 / 报告）

fn iv_img(w : Int32, h : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

fn iv_checker(w : Int32, h : Int32, lo : Byte, hi : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(if (x + y) % 2 == 0 { lo } else { hi })
    }
  }
  iv_img(w, h, d)
}

fn iv_flat(w : Int32, h : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(v)
  }
  iv_img(w, h, d)
}

fn iv_cfg(conf : Double, max_det : Int32) -> @intelligent_vision.IntelligentVisionConfig {
  @intelligent_vision.IntelligentVisionConfig::{
    confidence_threshold: conf,
    nms_threshold: 0.45,
    max_detections: max_det,
    input_size: 640,
    use_gpu: false,
    model_type: "yolov8",
  }
}

test "ivcov: 默认配置与目标检测" {
  let cfg = @intelligent_vision.create_default_intelligent_vision_config()
  assert_true(cfg.confidence_threshold == 0.5)
  assert_true(cfg.nms_threshold == 0.45)
  assert_true(cfg.max_detections == 100)
  assert_true(cfg.input_size == 640)
  assert_true(!cfg.use_gpu)
  assert_true(cfg.model_type == "yolov8")
  // 棋盘 128x128（2x2 网格）：每格方差极大 → 4 个检测
  let dets = @intelligent_vision.detect_objects_iv(iv_checker(128, 128, b'\x00', b'\xFF'), cfg)
  assert_true(dets.length() == 4)
  assert_true(dets[0].class_name == "object")
  assert_true(dets[0].confidence == 0.8)
  assert_true(dets[0].bounding_box.length() == 4)
  assert_true(dets[3].bounding_box[0] == 64.0)
  assert_true(dets[3].bounding_box[1] == 64.0)
  // max_detections 限制
  let limited = @intelligent_vision.detect_objects_iv(
    iv_checker(128, 128, b'\x00', b'\xFF'),
    iv_cfg(0.5, 1),
  )
  assert_true(limited.length() == 1)
  // 中间方差（80/160 → std 40）→ 置信度 0.6
  let mid = @intelligent_vision.detect_objects_iv(iv_checker(128, 128, b'\x50', b'\xA0'), cfg)
  assert_true(mid.length() == 4)
  assert_true(mid[0].confidence == 0.6)
  // 置信度阈值 0.7 → 过滤掉 0.6
  let strict = @intelligent_vision.detect_objects_iv(
    iv_checker(128, 128, b'\x50', b'\xA0'),
    iv_cfg(0.7, 10),
  )
  assert_true(strict.length() == 0)
  // 平坦图无检测
  let flat = @intelligent_vision.detect_objects_iv(iv_flat(128, 128, b'\x80'), cfg)
  assert_true(flat.length() == 0)
  // 小图（不足一个网格）
  assert_true(@intelligent_vision.detect_objects_iv(iv_flat(32, 32, b'\x80'), cfg).length() == 0)
}

test "ivcov: 车道与交通标志" {
  let cfg = @intelligent_vision.create_default_intelligent_vision_config()
  let r = @intelligent_vision.detect_lanes(iv_flat(300, 300, b'\x80'), cfg)
  assert_true(r.num_lanes == 2)
  assert_true(r.lanes.length() == 2)
  assert_true(r.lanes[0].length() == 10)
  assert_true(r.lanes[1].length() == 10)
  assert_true(r.lane_type == "solid")
  assert_true(r.confidence == 0.7)
  assert_true(r.curvature == 0.05)
  // 交通标志：高置信度 → speed_limit
  let signs = @intelligent_vision.recognize_traffic_signs(
    iv_checker(64, 64, b'\x00', b'\xFF'),
    cfg,
  )
  assert_true(signs.length() == 1)
  assert_true(signs[0].sign_type == "speed_limit")
  assert_true(signs[0].sign_value == "60")
  assert_true(signs[0].num_signs == 1)
  // 低置信度（0.6，阈值 0.55）→ warning
  let warn = @intelligent_vision.recognize_traffic_signs(
    iv_checker(64, 64, b'\x50', b'\xA0'),
    iv_cfg(0.55, 100),
  )
  assert_true(warn.length() == 1)
  assert_true(warn[0].sign_type == "warning")
  assert_true(warn[0].sign_value == "caution")
  // 无检测 → 空结果
  let none = @intelligent_vision.recognize_traffic_signs(iv_flat(64, 64, b'\x80'), cfg)
  assert_true(none.length() == 0)
}

test "ivcov: 缺陷/入侵/作物" {
  let cfg = @intelligent_vision.create_default_intelligent_vision_config()
  let hi = iv_checker(64, 64, b'\x00', b'\xFF')
  let lo = iv_checker(64, 64, b'\x50', b'\xA0')
  // 缺陷：0.8 → crack / medium
  let d1 = @intelligent_vision.detect_defects(hi, cfg)
  assert_true(d1.length() == 1)
  assert_true(d1[0].defect_type == "crack")
  assert_true(d1[0].severity == "medium")
  assert_true(d1[0].defect_area == 4096.0)
  // 0.6 → scratch / low
  let d2 = @intelligent_vision.detect_defects(lo, iv_cfg(0.55, 100))
  assert_true(d2.length() == 1)
  assert_true(d2[0].defect_type == "scratch")
  assert_true(d2[0].severity == "low")
  // 入侵：ROI 覆盖检测框 → 命中
  let hit = @intelligent_vision.detect_intrusion(hi, [0.0, 0.0, 64.0, 64.0], cfg)
  assert_true(hit.is_intrusion)
  assert_true(hit.num_intrusions == 1)
  assert_true(hit.object_type == "object")
  assert_true(hit.confidence == 0.8)
  assert_true(hit.intrusion_region.length() == 4)
  // ROI 完全错开 → 无入侵
  let miss = @intelligent_vision.detect_intrusion(hi, [100.0, 100.0, 10.0, 10.0], cfg)
  assert_true(!miss.is_intrusion)
  assert_true(miss.num_intrusions == 0)
  assert_true(miss.object_type == "none")
  assert_true(miss.intrusion_region.length() == 0)
  // 作物：0.8 → wheat / moderate / mature
  let c1 = @intelligent_vision.detect_crops(hi, cfg)
  assert_true(c1.length() == 1)
  assert_true(c1[0].crop_type == "wheat")
  assert_true(c1[0].health_status == "moderate")
  assert_true(c1[0].growth_stage == "mature")
  // 0.6 → corn / stressed / growing
  let c2 = @intelligent_vision.detect_crops(lo, iv_cfg(0.55, 100))
  assert_true(c2.length() == 1)
  assert_true(c2[0].crop_type == "corn")
  assert_true(c2[0].health_status == "stressed")
  assert_true(c2[0].growth_stage == "growing")
}

test "ivcov: 星体检测与报告" {
  let cfg = @intelligent_vision.create_default_intelligent_vision_config()
  // 只在偶数行偶数列取点；埋入两个亮星
  let d : Array[Byte] = []
  for y in 0..<16 {
    for x in 0..<16 {
      let star = (x == 2 && y == 2) || (x == 10 && y == 8)
      d.push(if star { b'\xFF' } else { b'\x20' })
    }
  }
  let img = iv_img(16, 16, d)
  let r = @intelligent_vision.detect_stars(img, cfg)
  assert_true(r.num_stars == 2)
  assert_true(r.stars.length() == 2)
  assert_true(r.magnitudes.length() == 2)
  assert_true(r.magnitudes[0] == 25.0 - 255.0 / 10.0)
  assert_true(r.brightest_star[0] == 2.0)
  assert_true(r.brightest_star[1] == 2.0)
  assert_true(r.sky_background > 0.0)
  // 全亮图：无背景样本 → sky_background 0
  let all_bright = @intelligent_vision.detect_stars(iv_flat(8, 8, b'\xFF'), cfg)
  assert_true(all_bright.num_stars == 16)
  assert_true(all_bright.sky_background == 0.0)
  // 全暗图：无星体，背景为原值
  let dark = @intelligent_vision.detect_stars(iv_flat(8, 8, b'\x10'), cfg)
  assert_true(dark.num_stars == 0)
  assert_true(dark.sky_background == 16.0)
  // 报告
  let report = @intelligent_vision.intelligent_vision_report_to_string(
    "目标检测",
    4,
    0.8,
    cfg,
  )
  assert_true(report.contains("智能视觉报告"))
  assert_true(report.contains("目标检测"))
  assert_true(report.contains("yolov8"))
  assert_true(report.contains("640"))
}
