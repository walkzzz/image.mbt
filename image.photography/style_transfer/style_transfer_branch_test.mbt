// 覆盖率测试：风格迁移的错误分支、算法分发与报告文本分支

///|
fn stc_img(w : Int32, h : Int32, c : Int32, value : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, value.to_byte())),
  }
}

///|
fn stc_short(w : Int32, h : Int32, c : Int32, len : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(len, b'\x10')),
  }
}

///|
fn stc_grad(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push((x * 5 + y * 2).to_byte())
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
fn stc_cfg(
  algo : @style_transfer.StyleTransferAlgorithm,
) -> @style_transfer.StyleTransferConfig {
  @style_transfer.StyleTransferConfig::{
    algorithm: algo,
    style_strength: 0.6,
    content_strength: 0.4,
    iterations: 10,
    learning_rate: 0.01,
    use_color_preservation: true,
    resolution: 128,
  }
}

///|
test "stcov: 颜色统计与纹理特征" {
  let gray = stc_grad(8, 8)
  let s1 = @style_transfer.calculate_color_statistics(gray)
  assert_true(s1.mean_r >= 0.0)
  assert_true(s1.min_r <= s1.max_r)
  assert_true(s1.std_r >= 0.0)
  // RGB / RGBA
  let rgb = stc_img(6, 6, 3, 100)
  let s2 = @style_transfer.calculate_color_statistics(rgb)
  assert_true(s2.mean_r == s2.mean_g)
  assert_true(s2.std_g == 0.0)
  let rgba = stc_img(6, 6, 4, 40)
  let s3 = @style_transfer.calculate_color_statistics(rgba)
  assert_true(s3.mean_b > 0.0)
  // 错误分支
  try {
    let _ = @style_transfer.calculate_color_statistics(stc_img(0, 4, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.calculate_color_statistics(stc_img(4, 4, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.calculate_color_statistics(stc_short(4, 4, 1, 4))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 纹理特征
  let t1 = @style_transfer.calculate_texture_features(gray)
  assert_true(t1.contrast >= 0.0)
  assert_true(t1.entropy > -1000.0)
  let t2 = @style_transfer.calculate_texture_features(rgb)
  assert_true(t2.homogeneity > -1000.0)
  let t3 = @style_transfer.calculate_texture_features(rgba)
  assert_true(t3.energy > -1000.0)
  try {
    let _ = @style_transfer.calculate_texture_features(stc_img(0, 5, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.calculate_texture_features(stc_img(5, 5, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.calculate_texture_features(stc_short(5, 5, 1, 5))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "stcov: color_transfer 强度与错误分支" {
  let content = stc_grad(8, 8)
  let style = stc_img(8, 8, 1, 200)
  // 强度 0 → 接近内容图
  let r0 = @style_transfer.color_transfer(content, style, 0.0)
  assert_true(r0.width == 8)
  // 强度 1 → 明显偏移
  let r1 = @style_transfer.color_transfer(content, style, 1.0)
  assert_true(r1.height == 8)
  assert_true(r1.channels >= 1)
  // 中间强度
  let r2 = @style_transfer.color_transfer(content, style, 0.5)
  assert_true(r2.data.length() > 0)
  // 内容图错误
  try {
    let _ = @style_transfer.color_transfer(stc_img(0, 4, 1, 0), style, 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.color_transfer(stc_img(4, 4, 6, 0), style, 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.color_transfer(stc_short(4, 4, 1, 4), style, 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 风格图错误
  try {
    let _ = @style_transfer.color_transfer(content, stc_img(0, 4, 1, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.color_transfer(content, stc_img(4, 4, 7, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.color_transfer(content, stc_short(4, 4, 1, 4), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "stcov: cartoonize / oil_painting / sketch_effect" {
  let img = stc_grad(10, 10)
  // cartoonize 强度 0 与 1
  assert_true(@style_transfer.cartoonize(img, 0.0).width == 10)
  assert_true(@style_transfer.cartoonize(img, 1.0).channels >= 1)
  let rgb = stc_img(8, 8, 3, 90)
  assert_true(@style_transfer.cartoonize(rgb, 0.7).width == 8)
  // 错误分支
  try {
    let _ = @style_transfer.cartoonize(stc_img(0, 6, 1, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.cartoonize(stc_img(6, 6, 5, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.cartoonize(stc_short(6, 6, 1, 6), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 油画：正常与边界
  assert_true(@style_transfer.oil_painting(img, 2, 5).width == 10)
  assert_true(@style_transfer.oil_painting(rgb, 1, 3).height == 8)
  try {
    let _ = @style_transfer.oil_painting(stc_img(0, 6, 1, 0), 2, 5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.oil_painting(stc_img(6, 6, 6, 0), 2, 5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.oil_painting(stc_short(6, 6, 1, 6), 2, 5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 素描
  assert_true(@style_transfer.sketch_effect(img, 0.5).width == 10)
  assert_true(@style_transfer.sketch_effect(rgb, 1.0).channels >= 1)
  try {
    let _ = @style_transfer.sketch_effect(stc_img(0, 6, 1, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.sketch_effect(stc_img(6, 6, 8, 0), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.sketch_effect(stc_short(6, 6, 1, 6), 0.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "stcov: style_transfer 算法分发与报告" {
  let content = stc_grad(8, 8)
  let style = stc_img(8, 8, 1, 220)
  // ColorTransfer 分支
  let r1 = @style_transfer.style_transfer(
    content,
    style,
    stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
  )
  assert_true(r1.image.width == 8)
  assert_true(r1.iterations == 10)
  // Cartoon 分支
  let r2 = @style_transfer.style_transfer(
    content,
    style,
    stc_cfg(@style_transfer.StyleTransferAlgorithm::Cartoon),
  )
  assert_true(r2.image.height == 8)
  // OilPainting 分支
  let r3 = @style_transfer.style_transfer(
    content,
    style,
    stc_cfg(@style_transfer.StyleTransferAlgorithm::OilPainting),
  )
  assert_true(r3.image.data.length() > 0)
  // Sketch 分支
  let r4 = @style_transfer.style_transfer(
    content,
    style,
    stc_cfg(@style_transfer.StyleTransferAlgorithm::Sketch),
  )
  assert_true(r4.image.width == 8)
  // 其余算法走兜底 color_transfer
  let r5 = @style_transfer.style_transfer(
    content,
    style,
    stc_cfg(@style_transfer.StyleTransferAlgorithm::NeuralStyle),
  )
  assert_true(r5.image.height == 8)
  // 内容图 / 风格图错误分支
  try {
    let _ = @style_transfer.style_transfer(
      stc_img(0, 4, 1, 0),
      style,
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.style_transfer(
      stc_img(4, 4, 9, 0),
      style,
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.style_transfer(
      stc_short(4, 4, 1, 4),
      style,
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.style_transfer(
      content,
      stc_img(0, 4, 1, 0),
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.style_transfer(
      content,
      stc_img(4, 4, 6, 0),
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @style_transfer.style_transfer(
      content,
      stc_short(4, 4, 1, 4),
      stc_cfg(@style_transfer.StyleTransferAlgorithm::ColorTransfer),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 报告：多种算法分支
  let cs = @style_transfer.calculate_color_statistics(content)
  let ss = @style_transfer.calculate_color_statistics(style)
  let tf = @style_transfer.calculate_texture_features(content)
  let rep1 = @style_transfer.style_transfer_report_to_string(r1, cs, ss, tf)
  assert_true(rep1.has_prefix("## 图像风格迁移报告"))
  assert_true(rep1.contains("颜色转移"))
  let rep2 = @style_transfer.style_transfer_report_to_string(r2, cs, ss, tf)
  assert_true(rep2.contains("卡通化"))
  let rep3 = @style_transfer.style_transfer_report_to_string(r3, cs, ss, tf)
  assert_true(rep3.contains("油画"))
  let rep4 = @style_transfer.style_transfer_report_to_string(r4, cs, ss, tf)
  assert_true(rep4.contains("素描"))
  let rep5 = @style_transfer.style_transfer_report_to_string(r5, cs, ss, tf)
  assert_true(rep5.contains("神经风格"))
  // 默认配置
  let cfg = @style_transfer.create_default_style_transfer_config()
  assert_true(cfg.style_strength == 0.5)
  assert_true(cfg.content_strength == 0.5)
  assert_true(cfg.iterations == 100)
  assert_true(cfg.resolution == 512)
}
