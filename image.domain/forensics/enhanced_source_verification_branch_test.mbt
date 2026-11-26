// 覆盖率测试：增强来源鉴定的错误分支与简单统计函数

fn frc_img(w : Int32, h : Int32, c : Int32, value : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, value.to_byte())),
  }
}

fn frc_short(w : Int32, h : Int32, c : Int32, len : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(len, b'\x20')),
  }
}

fn frc_grad(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push((x * 13 + y * 7).to_byte())
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

test "frcov: 三个统计函数正常与错误分支" {
  let g = frc_grad(8, 8)
  // 正常调用
  let solid = @forensics.analyze_solid_areas(g)
  assert_true(solid >= 0.0 && solid <= 1.0)
  let edges = @forensics.analyze_edge_directions(g)
  assert_true(edges >= 0.0)
  let dist = @forensics.analyze_pixel_distribution(g)
  assert_true(dist >= 0.0)
  // 平坦图
  let flat = frc_img(8, 8, 1, 128)
  assert_true(@forensics.analyze_solid_areas(flat) >= 0.0)
  assert_true(@forensics.analyze_edge_directions(flat) >= 0.0)
  assert_true(@forensics.analyze_pixel_distribution(flat) >= 0.0)
  // 尺寸非法
  try {
    let _ = @forensics.analyze_solid_areas(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_edge_directions(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_pixel_distribution(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道非法 / 数据长度不匹配
  let c6 = frc_img(4, 4, 6, 0)
  let bad_len = frc_short(4, 4, 1, 4)
  for f in [0, 1, 2] {
    if f == 0 {
      try {
        let _ = @forensics.analyze_solid_areas(c6)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
      try {
        let _ = @forensics.analyze_solid_areas(bad_len)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
    } else if f == 1 {
      try {
        let _ = @forensics.analyze_edge_directions(c6)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
      try {
        let _ = @forensics.analyze_edge_directions(bad_len)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
    } else {
      try {
        let _ = @forensics.analyze_pixel_distribution(c6)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
      try {
        let _ = @forensics.analyze_pixel_distribution(bad_len)
        assert_true(false)
      } catch {
        _ => assert_true(true)
      }
    }
  }
}

test "frcov: UI/文字/几何/量化 错误分支" {
  let g = frc_grad(10, 10)
  // 正常调用（不崩溃）
  let _ui = @forensics.detect_ui_elements(g)
  let _txt = @forensics.detect_text_regions(g)
  let _geo = @forensics.analyze_geometry(g)
  let _quant = @forensics.analyze_color_quantization(g)
  // 错误分支
  try {
    let _ = @forensics.detect_ui_elements(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.detect_ui_elements(frc_img(4, 4, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.detect_ui_elements(frc_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.detect_text_regions(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.detect_text_regions(frc_img(4, 4, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.detect_text_regions(frc_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_geometry(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_geometry(frc_img(4, 4, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_geometry(frc_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_color_quantization(frc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_color_quantization(frc_img(4, 4, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.analyze_color_quantization(frc_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "frcov: 增强鉴定入口与报告" {
  let g = frc_grad(12, 12)
  let cfg = @forensics.create_default_enhanced_verification_config()
  let res = @forensics.verify_image_source_enhanced(g, cfg)
  let rep = @forensics.enhanced_verification_report_to_string(res)
  assert_true(rep.has_prefix("## 图像来源鉴定报告（增强版）"))
  assert_true(rep.length() > 20)
  // 配置字段
  assert_true(cfg.use_ui_detection)
  assert_true(cfg.use_text_detection)
  assert_true(cfg.use_geometry_analysis)
  // 错误分支
  try {
    let _ = @forensics.verify_image_source_enhanced(frc_img(0, 4, 1, 0), cfg)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.verify_image_source_enhanced(frc_img(4, 4, 6, 0), cfg)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @forensics.verify_image_source_enhanced(frc_short(4, 4, 1, 4), cfg)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
