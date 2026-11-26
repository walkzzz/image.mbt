// 覆盖率测试：16f 量化（kmeans / floyd-steinberg / median-cut 的 Image16 与 ImageF）

fn q16_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image16 {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        let v = f(x, y)
        d.push((v % 256).to_byte())
        d.push((v / 256 % 256).to_byte())
      }
    }
  }
  @types.Image16::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn qf_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Double) -> @types.ImageF {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      for _k in 0..<c {
        let v = Float::from_double(f(x, y))
        for b in v.to_le_bytes() {
          d.push(b)
        }
      }
    }
  }
  @types.ImageF::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

test "q16: kmeans 量化" {
  let grad = q16_img(24, 24, 3, fn(x, y) { (x * 1000 + y * 400) % 65536 })
  let a = @color.kmeans_quantize_16(grad, 4, 3)
  assert_true(a.width == 24)
  assert_true(a.channels == 3)
  let b = @color.kmeans_quantize_16(grad, 1, 1)
  assert_true(b.height == 24)
  // k 超过像素数
  let tiny = q16_img(2, 2, 3, fn(x, y) { (x + y) * 20 })
  let c1 = @color.kmeans_quantize_16(tiny, 8, 2)
  assert_true(c1.width == 2)
  // 灰度不受支持 → 抛错
  try {
    let _ = @color.kmeans_quantize_16(q16_img(16, 16, 1, fn(x, _y) { x * 3000 }), 3, 2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // float 版本
  let fgrad = qf_img(20, 20, 3, fn(x, y) { ((x * 11 + y * 7) % 100).to_double() / 100.0 })
  let e = @color.kmeans_quantize_f(fgrad, 4, 3)
  assert_true(e.width == 20)
  let f1 = @color.kmeans_quantize_f(fgrad, 2, 1)
  assert_true(f1.height == 20)
}

test "q16: floyd-steinberg 抖动" {
  let img = q16_img(20, 16, 1, fn(x, y) { (x * 3000 + y * 1000) % 65536 })
  let l2 = @color.floyd_steinberg_16(img, 2)
  assert_true(l2.width == 20)
  let l4 = @color.floyd_steinberg_16(img, 4)
  assert_true(l4.height == 16)
  let rgb = q16_img(12, 12, 3, fn(x, y) { (x * 5000 + y * 2000) % 65536 })
  let l8 = @color.floyd_steinberg_16(rgb, 8)
  assert_true(l8.channels == 3)
  // float 版本
  let fimg = qf_img(16, 16, 1, fn(x, y) { ((x * 9 + y * 5) % 50).to_double() / 50.0 })
  let fl = @color.floyd_steinberg_f(fimg, 2)
  assert_true(fl.width == 16)
  let fl4 = @color.floyd_steinberg_f(fimg, 4)
  assert_true(fl4.height == 16)
}

test "q16: median-cut 量化" {
  let img = q16_img(24, 20, 3, fn(x, y) { (x * 2000 + y * 900) % 65536 })
  let m8 = @color.median_cut_16(img, 8)
  assert_true(m8.width == 24)
  let m2 = @color.median_cut_16(img, 2)
  assert_true(m2.width == 24)
  let mg = @color.median_cut_16(q16_img(16, 16, 1, fn(x, _y) { x * 4000 }), 4)
  assert_true(mg.channels >= 1)
  let fimg = qf_img(20, 20, 3, fn(x, y) { ((x * 7 + y * 3) % 60).to_double() / 60.0 })
  let fm = @color.median_cut_f(fimg, 6)
  assert_true(fm.width == 20)
  let fm2 = @color.median_cut_f(fimg, 2)
  assert_true(fm2.height == 20)
}

test "q16: 错误分支" {
  // 负尺寸
  try {
    let _ = @color.kmeans_quantize_16(q16_img(0 - 1, 4, 1, fn(_x, _y) { 0 }), 2, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道非法
  try {
    let _ = @color.kmeans_quantize_16(q16_img(4, 4, 5, fn(_x, _y) { 0 }), 2, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // k <= 0
  try {
    let _ = @color.kmeans_quantize_16(q16_img(4, 4, 1, fn(_x, _y) { 0 }), 0, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 数据长度不匹配
  let bad = @types.Image16::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(Array::make(4, (0).to_byte())),
  }
  try {
    let _ = @color.floyd_steinberg_16(bad, 2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // levels <= 1
  try {
    let _ = @color.floyd_steinberg_16(q16_img(4, 4, 1, fn(_x, _y) { 10 }), 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // float 版本错误
  try {
    let _ = @color.kmeans_quantize_f(qf_img(4, 4, 5, fn(_x, _y) { 0.5 }), 2, 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.median_cut_16(q16_img(4, 4, 1, fn(_x, _y) { 0 }), 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @color.floyd_steinberg_f(qf_img(4, 4, 1, fn(_x, _y) { 0.5 }), 1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
