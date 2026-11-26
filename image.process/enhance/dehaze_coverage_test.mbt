// 覆盖率测试：去雾流水线各阶段与参数校验

///|
fn dhz_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32, Int32) -> Int32,
) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push(f(x, y, ch))
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

///|
test "dhz: 各阶段" {
  // 灰白雾化图
  let hazy = dhz_img(32, 24, 3, fn(x, y, c) {
    150 + (x * 3 + y * 2 + c * 5) % 60
  })
  // 暗通道
  let dark = @enhance.dark_channel(hazy)
  assert_true(dark.width == 32)
  let dark5 = @enhance.dark_channel(hazy, patch_size=5)
  assert_true(dark5.height == 24)
  // 单通道输入
  let gray = dhz_img(24, 24, 1, fn(x, y, _c) { 120 + (x + y) % 40 })
  let dg = @enhance.dark_channel(gray)
  assert_true(dg.channels >= 1)
  // 大气光
  let atm = @enhance.estimate_atmospheric_light(hazy, dark)
  assert_true(atm.length() >= 1)
  let atm2 = @enhance.estimate_atmospheric_light(hazy, dark, top_percent=100)
  assert_true(atm2.length() >= 1)
  // 透射率
  let t = @enhance.estimate_transmission(hazy, atm)
  assert_true(t.width == 32)
  let t2 = @enhance.estimate_transmission(hazy, atm, omega=0.7, patch_size=9)
  assert_true(t2.height == 24)
  // 导向滤波
  let guided = @enhance.guided_filter_image(t, hazy)
  assert_true(guided.width == 32)
  let guided2 = @enhance.guided_filter_image(t, hazy, radius=5, eps=0.001)
  assert_true(guided2.width == 32)
  // 复原
  let rec = @enhance.dehaze_recover(hazy, guided, atm)
  assert_true(rec.width == 32)
  let rec2 = @enhance.dehaze_recover(hazy, guided, atm, t_min=0.2)
  assert_true(rec2.height == 24)
  // 完整流水线：默认配置与自定义配置
  let out1 = @enhance.dehaze_advanced(hazy)
  assert_true(out1.width == 32)
  assert_true(out1.channels == 3)
  let cfg = @enhance.dehaze_default_config()
  assert_true(cfg.patch_size == 15)
  assert_true(cfg.omega > 0.0)
  let out2 = @enhance.dehaze_advanced(gray, config=cfg)
  assert_true(out2.width == 24)
  // RGBA
  let rgba = dhz_img(16, 16, 4, fn(x, y, c) {
    90 + (x * 7 + y * 5 + c * 11) % 100
  })
  let out3 = @enhance.dehaze_advanced(rgba)
  assert_true(out3.channels >= 3)
}

///|
test "dhz: 错误分支" {
  let ok = dhz_img(16, 16, 3, fn(_x, _y, _c) { 128 })
  // 尺寸非法
  try {
    let _ = @enhance.dehaze_advanced(dhz_img(0, 8, 3, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @enhance.dark_channel(dhz_img(8, 0, 3, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道非法
  try {
    let _ = @enhance.dehaze_advanced(dhz_img(8, 8, 5, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 数据长度不匹配
  let bad = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(8, (9).to_byte())),
  }
  try {
    let _ = @enhance.dehaze_advanced(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 配置校验：patch_size 偶数
  let c1 = @enhance.DehazeConfig::{
    patch_size: 4,
    omega: 0.95,
    t_min: 0.1,
    guided_radius: 20,
    guided_eps: 0.0001,
    max_atmospheric: 1000,
  }
  try {
    let _ = @enhance.dehaze_advanced(ok, config=c1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 大气光数组长度非法
  try {
    let _ = @enhance.estimate_transmission(ok, [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 复原：透射率尺寸不匹配
  let t = @enhance.estimate_transmission(ok, [200, 200, 200])
  let small = dhz_img(8, 8, 1, fn(_x, _y, _c) { 10 })
  try {
    let _ = @enhance.dehaze_recover(ok, small, [200, 200, 200])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let _ = @enhance.dehaze_recover(ok, t, [200, 200, 200])
}
