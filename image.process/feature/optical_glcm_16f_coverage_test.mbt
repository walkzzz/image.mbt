// 覆盖率测试：光流与 GLCM 的 16-bit / float 变体

///|
fn og16_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32) -> Int32,
) -> @types.Image16 {
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
  @types.Image16::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn ogf_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32) -> Double,
) -> @types.ImageF {
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
  @types.ImageF::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
test "og16: Lucas-Kanade 16/" {
  // 平移到右下的合成图案
  let prev = og16_img(32, 32, 1, fn(x, y) { (x * 700 + y * 300) % 65536 })
  let next = og16_img(32, 32, 1, fn(x, y) {
    ((x + 1) * 700 + (y + 1) * 300) % 65536
  })
  let pts = [(16, 16), (8, 24)]
  let r = @feature.lucas_kanade_16(prev, next, pts)
  assert_true(r.length() == 2)
  let r2 = @feature.lucas_kanade_16(prev, next, pts, window_size=7, max_iter=5)
  assert_true(r2.length() == 2)
  // 空点集 → 抛错
  try {
    let _ = @feature.lucas_kanade_16(prev, next, [])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // float 版
  let fprev = ogf_img(32, 32, 1, fn(x, y) {
    ((x * 41 + y * 17) % 255).to_double() / 255.0
  })
  let fnext = ogf_img(32, 32, 1, fn(x, y) {
    (((x + 1) * 41 + (y + 1) * 17) % 255).to_double() / 255.0
  })
  let fr = @feature.lucas_kanade_f(fprev, fnext, pts)
  assert_true(fr.length() == 2)
}

///|
test "og16: Horn-Schunck 16/" {
  let prev = og16_img(24, 24, 1, fn(x, y) { (x * 1200 + y * 500) % 65536 })
  let next = og16_img(24, 24, 1, fn(x, y) { ((x + 1) * 1200 + y * 500) % 65536 })
  let (ux, uy) = @feature.horn_schunck_16(prev, next)
  assert_true(ux.length() <= 4096)
  assert_true(uy.length() <= 4096)
  let fprev = ogf_img(24, 24, 1, fn(x, y) {
    ((x * 9 + y * 3) % 64).to_double() / 64.0
  })
  let fnext = ogf_img(24, 24, 1, fn(x, y) {
    (((x + 1) * 9 + y * 3) % 64).to_double() / 64.0
  })
  let (fux, fuy) = @feature.horn_schunck_f(fprev, fnext)
  assert_true(fux.length() <= 4096)
  assert_true(fuy.length() <= 4096)
}

///|
test "og16: GLCM 与多方向特征" {
  let tex = og16_img(20, 20, 1, fn(x, y) { (x * 3000 + y * 1200) % 65536 })
  let m = @feature.compute_glcm_16(tex, 1, 0)
  assert_true(m.length() > 0)
  let m2 = @feature.compute_glcm_16(tex, 0, 1, levels=64)
  assert_true(m2.length() > 0)
  // 多通道
  let rgb = og16_img(16, 16, 3, fn(x, y) { (x * 4000 + y * 2000) % 65536 })
  let m3 = @feature.compute_glcm_16(rgb, 1, 1)
  assert_true(m3.length() > 0)
  let feats = @feature.glcm_features_multi_direction_16(tex)
  assert_true(feats.length() > 0)
  let feats2 = @feature.glcm_features_multi_direction_16(tex, levels=32)
  assert_true(feats2.length() > 0)
  // float 变体
  let ftex = ogf_img(20, 20, 1, fn(x, y) {
    ((x * 13 + y * 7) % 256).to_double() / 256.0
  })
  let fm = @feature.compute_glcm_f(ftex, 1, 0)
  assert_true(fm.length() > 0)
  let ff = @feature.glcm_features_multi_direction_f(ftex)
  assert_true(ff.length() > 0)
}

///|
test "og16: 错误分支" {
  let ok16 = og16_img(8, 8, 1, fn(_x, _y) { 10 })
  let okf = ogf_img(8, 8, 1, fn(_x, _y) { 0.1 })
  // 尺寸 / 通道 / 长度 / levels
  try {
    let _ = @feature.lucas_kanade_16(
      og16_img(0, 8, 1, fn(_x, _y) { 0 }),
      ok16,
      [(1, 1)],
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.lucas_kanade_16(
      ok16,
      og16_img(8, 8, 5, fn(_x, _y) { 0 }),
      [(1, 1)],
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let bad16 = @types.Image16::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array(Array::make(4, (0).to_byte())),
  }
  try {
    let _ = @feature.horn_schunck_16(bad16, ok16)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.compute_glcm_16(ok16, 1, 0, levels=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.glcm_features_multi_direction_16(ok16, levels=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let badf = @types.ImageF::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array(Array::make(4, (0).to_byte())),
  }
  try {
    let _ = @feature.lucas_kanade_f(badf, okf, [(1, 1)])
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.horn_schunck_f(okf, badf)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.compute_glcm_f(okf, 1, 0, levels=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
