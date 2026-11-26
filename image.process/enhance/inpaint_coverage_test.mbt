// 覆盖率测试：图像修复（inpaint_advanced / create_rect_mask / remove_small_objects / remove_watermark）

fn ip_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        d.push(f(x, y).to_byte())
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn ip_gray(w : Int32, h : Int32) -> @types.Image {
  ip_img(w, h, 1, fn(x, y) { 40 + (x * 7 + y * 11) % 200 })
}

fn ip_params() -> @types.Image {
  @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
}

test "ipcov: 默认配置与矩形掩码" {
  let cfg = @enhance.inpaint_default_config()
  assert_true(cfg.radius == 5)
  assert_true(cfg.method_type == "telea")
  assert_true(cfg.max_iterations == 1000)
  // 掩码内部 255、外部 0
  let m = @enhance.create_rect_mask(8, 8, 2, 2, 3, 3)
  assert_true(m.width == 8)
  assert_true(m.height == 8)
  assert_true(m.channels == 1)
  assert_true(m.data.length() == 64)
  assert_true(m.data[2 * 8 + 2].to_int() == 255)
  assert_true(m.data[4 * 8 + 4].to_int() == 255)
  assert_true(m.data[0].to_int() == 0)
  assert_true(m.data[5 * 8 + 5].to_int() == 0)
  // 全图掩码
  let full = @enhance.create_rect_mask(4, 4, 0, 0, 4, 4)
  assert_true(full.data[15].to_int() == 255)
  // 错误
  try {
    let _ = @enhance.create_rect_mask(0, 4, 0, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.create_rect_mask(4, 4, -1, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.create_rect_mask(4, 4, 0, 0, 0, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.create_rect_mask(4, 4, 3, 3, 2, 2)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "ipcov: inpaint_advanced 主流程" {
  // 灰度
  let g = ip_gray(8, 8)
  let mask = @enhance.create_rect_mask(8, 8, 3, 3, 2, 2)
  let o1 = @enhance.inpaint_advanced(g, mask)
  assert_true(o1.width == 8)
  assert_true(o1.channels == 1)
  assert_true(o1.data.length() == 64)
  // 自定义 radius
  let o2 = @enhance.inpaint_advanced(g, mask, radius=2)
  assert_true(o2.data.length() == 64)
  // 3 通道
  let rgb = ip_img(8, 8, 3, fn(x, y) { (x * 20 + y * 10) % 256 })
  let o3 = @enhance.inpaint_advanced(rgb, mask, radius=1)
  assert_true(o3.channels == 3)
  assert_true(o3.data.length() == 192)
  // 4 通道
  let rgba = ip_img(8, 8, 4, fn(x, y) { if (x + y) % 2 == 0 { 200 } else { 50 } })
  let o4 = @enhance.inpaint_advanced(rgba, mask, radius=1)
  assert_true(o4.channels == 4)
  // 无掩码区域 → 原样
  let empty_mask = @enhance.create_rect_mask(8, 8, 0, 0, 1, 1)
  let blank = ip_gray(8, 8)
  let o5 = @enhance.inpaint_advanced(blank, empty_mask)
  assert_true(o5.data.length() == 64)
  // 错误：尺寸 / 通道 / 数据 / 掩码尺寸 / 掩码通道 / radius
  try {
    let _ = @enhance.inpaint_advanced(ip_img(0, 4, 1, fn(_x, _y) { 1 }), mask)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.inpaint_advanced(ip_img(4, 4, 5, fn(_x, _y) { 1 }), @enhance.create_rect_mask(4, 4, 0, 0, 1, 1))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.inpaint_advanced(ip_params(), mask)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.inpaint_advanced(g, @enhance.create_rect_mask(4, 4, 0, 0, 1, 1))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.inpaint_advanced(g, mask, radius=0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "ipcov: remove_small_objects 与 remove_watermark" {
  // 含孤立亮点的图
  let speck = ip_img(8, 8, 1, fn(x, y) {
    if x == 2 && y == 2 { 255 } else { 10 }
  })
  let o1 = @enhance.remove_small_objects(speck, max_size=10)
  assert_true(o1.width == 8)
  assert_true(o1.channels == 1)
  // 大物体（整块）不应被移除
  let block = ip_img(8, 8, 1, fn(x, y) { if x < 4 && y < 4 { 255 } else { 10 } })
  let o2 = @enhance.remove_small_objects(block, max_size=4)
  assert_true(o2.data.length() == 64)
  // 3 通道
  let rgb = ip_img(8, 8, 3, fn(x, y) { if x == 1 && y == 1 { 200 } else { 20 } })
  let o3 = @enhance.remove_small_objects(rgb, max_size=20)
  assert_true(o3.channels == 3)
  // 错误
  try {
    let _ = @enhance.remove_small_objects(ip_img(0, 4, 1, fn(_x, _y) { 1 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.remove_small_objects(ip_params())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // remove_watermark
  let img = ip_gray(8, 8)
  let w1 = @enhance.remove_watermark(img, 2, 2, 2, 2)
  assert_true(w1.width == 8)
  assert_true(w1.data.length() == 64)
  let rgb2 = ip_img(8, 8, 3, fn(x, y) { (x * 30 + y) % 256 })
  let w2 = @enhance.remove_watermark(rgb2, 1, 1, 3, 3)
  assert_true(w2.channels == 3)
  // 错误
  try {
    let _ = @enhance.remove_watermark(ip_img(0, 4, 1, fn(_x, _y) { 1 }), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.remove_watermark(ip_img(4, 4, 5, fn(_x, _y) { 1 }), 0, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.remove_watermark(img, -1, 0, 1, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.remove_watermark(img, 0, 0, 0, 1)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @enhance.remove_watermark(img, 6, 6, 4, 4)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
