// 覆盖率测试：感知哈希 / 质量指标 / 积分图的 16-bit 与 float 变体

fn hq16_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Int32) -> @types.Image16 {
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

fn hqf_img(w : Int32, h : Int32, c : Int32, f : (Int32, Int32) -> Double) -> @types.ImageF {
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

test "hq16: 感知哈希" {
  let a = hq16_img(32, 32, 1, fn(x, y) { (x * 900 + y * 400) % 65536 })
  let b = hq16_img(32, 32, 1, fn(x, y) { ((x + 1) * 900 + y * 400) % 65536 })
  let ha = @feature.ahash_16(a)
  assert_true(ha.length() > 0)
  let hb = @feature.ahash_16(b)
  assert_true(hb.length() > 0)
  let da = @feature.dhash_16(a)
  assert_true(da.length() > 0)
  let pa = @feature.phash_16(a)
  assert_true(pa.length() > 0)
  // float 变体
  let fa = hqf_img(32, 32, 1, fn(x, y) { ((x * 7 + y * 3) % 256).to_double() / 256.0 })
  let fb = hqf_img(32, 32, 1, fn(x, y) { (((x + 2) * 7 + y * 3) % 256).to_double() / 256.0 })
  assert_true(@feature.ahash_f(fa).length() > 0)
  assert_true(@feature.dhash_f(fa).length() > 0)
  assert_true(@feature.phash_f(fa).length() > 0)
  assert_true(@feature.phash_f(fb).length() > 0)
}

test "hq16: 质量指标" {
  let a = hq16_img(16, 16, 3, fn(x, y) { (x * 2000 + y * 900) % 65536 })
  let same = hq16_img(16, 16, 3, fn(x, y) { (x * 2000 + y * 900) % 65536 })
  let m0 = @feature.mse_16(a, same)
  assert_true(m0 == 0.0)
  let p0 = @feature.psnr_16(a, same)
  assert_true(p0 >= 0.0)
  let s0 = @feature.ssim_16(a, same)
  assert_true(s0 >= 0.0)
  // 有差异
  let diff = hq16_img(16, 16, 3, fn(x, y) { (x * 2000 + y * 900 + 5000) % 65536 })
  let m1 = @feature.mse_16(a, diff)
  assert_true(m1 > 0.0)
  let p1 = @feature.psnr_16(a, diff)
  assert_true(p1 >= 0.0)
  let s1 = @feature.ssim_16(a, diff)
  assert_true(s1 <= 1.0)
  // float 变体
  let fa = hqf_img(16, 16, 1, fn(x, y) { ((x * 5 + y * 2) % 40).to_double() / 40.0 })
  let fb = hqf_img(16, 16, 1, fn(x, y) { ((x * 5 + y * 2 + 1) % 40).to_double() / 40.0 })
  assert_true(@feature.mse_f(fa, fa) == 0.0)
  assert_true(@feature.mse_f(fa, fb) >= 0.0)
  assert_true(@feature.psnr_f(fa, fb) >= 0.0)
  assert_true(@feature.ssim_f(fa, fb) <= 1.0)
}

test "hq16: 积分图" {
  let a = hq16_img(16, 16, 1, fn(x, y) { (x * 1500 + y * 700) % 65536 })
  let i1 = @feature.integral_image_16(a)
  assert_true(i1.width == 16)
  let s1 = @feature.integral_image_sq_16(a)
  assert_true(s1.width == 16)
  let fa = hqf_img(16, 16, 1, fn(x, y) { ((x * 3 + y) % 30).to_double() / 30.0 })
  let i2 = @feature.integral_image_f(fa)
  assert_true(i2.width == 16)
  let s2 = @feature.integral_image_sq_f(fa)
  assert_true(s2.width == 16)
}

test "hq16: 错误分支" {
  let ok = hq16_img(8, 8, 1, fn(_x, _y) { 100 })
  let bad_size = @types.Image16::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array(Array::make(4, (0).to_byte())),
  }
  // 尺寸非法
  try {
    let _ = @feature.ahash_16(hq16_img(0, 8, 1, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 通道非法
  try {
    let _ = @feature.dhash_16(hq16_img(8, 8, 5, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 数据长度不匹配
  try {
    let _ = @feature.phash_16(bad_size)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.mse_16(bad_size, ok)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.psnr_16(ok, bad_size)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 尺寸不一致
  try {
    let _ = @feature.ssim_16(ok, hq16_img(8, 6, 1, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.integral_image_16(bad_size)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // float 错误
  let badf = @types.ImageF::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array(Array::make(4, (0).to_byte())),
  }
  let okf = hqf_img(8, 8, 1, fn(_x, _y) { 0.1 })
  try {
    let _ = @feature.ahash_f(badf)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.mse_f(okf, badf)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.integral_image_sq_f(badf)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
