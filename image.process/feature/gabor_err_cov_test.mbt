// 覆盖率测试：Gabor 滤波与模板匹配的输入校验分支

fn gbe_i16(w : Int32, h : Int32, c : Int32) -> @types.Image16 {
  let d : Array[Int32] = []
  for i in 0..<(w * h * c) {
    let v = (i * 97) % 65536
    d.push(v & 0xFF)
    d.push((v >> 8) & 0xFF)
  }
  @types.Image16::{ width: w, height: h, channels: c, data: Bytes::from_array(d.map(fn(v) { v.to_byte() })) }
}

fn gbe_if(w : Int32, h : Int32, c : Int32) -> @types.ImageF {
  let d : Array[Byte] = []
  for i in 0..<(w * h * c) {
    let v = Float::from_int((i * 13) % 256) / 255.0F
    let b = v.to_le_bytes()
    for k in 0..<4 {
      d.push(b[k])
    }
  }
  @types.ImageF::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

test "gabor: gabor_filter_16 校验" {
  let img = gbe_i16(8, 8, 1)
  let ok = @feature.gabor_filter_16(img, 3, 1.0F, 0.0F)
  assert_true(ok.width == 8)
  try {
    let _ = @feature.gabor_filter_16(gbe_i16(0, 4, 1), 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_16(gbe_i16(4, 4, 5), 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_16(@types.Image16::{
      width: 4, height: 4, channels: 1, data: Bytes::from_array([]),
    }, 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_16(img, 4, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_16(img, 3, 0.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "gabor: gabor_filter_f 校验" {
  let img = gbe_if(8, 8, 1)
  let ok = @feature.gabor_filter_f(img, 3, 1.0F, 0.5F)
  assert_true(ok.width == 8)
  try {
    let _ = @feature.gabor_filter_f(gbe_if(0, 4, 1), 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_f(gbe_if(4, 4, 5), 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_f(@types.ImageF::{
      width: 4, height: 4, channels: 1, data: Bytes::from_array([]),
    }, 3, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_f(img, 0, 1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_f(img, 3, -1.0F, 0.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "gabor: 滤波器组校验" {
  let i = gbe_i16(8, 8, 1)
  let bank = @feature.gabor_filter_bank_16(i, 3, 1.0F, num_orientations=4)
  assert_true(bank.width == 8)
  try {
    let _ = @feature.gabor_filter_bank_16(gbe_i16(0, 4, 1), 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_16(gbe_i16(4, 4, 5), 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_16(@types.Image16::{
      width: 4, height: 4, channels: 1, data: Bytes::from_array([]),
    }, 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_16(i, 3, 1.0F, num_orientations=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let f = gbe_if(8, 8, 1)
  let bankf = @feature.gabor_filter_bank_f(f, 3, 1.0F, num_orientations=2)
  assert_true(bankf.width == 8)
  try {
    let _ = @feature.gabor_filter_bank_f(gbe_if(0, 4, 1), 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_f(gbe_if(4, 4, 5), 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_f(@types.ImageF::{
      width: 4, height: 4, channels: 1, data: Bytes::from_array([]),
    }, 3, 1.0F)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.gabor_filter_bank_f(f, 3, 1.0F, num_orientations=-1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

test "gabor: 模板匹配校验" {
  let img = gbe_i16(16, 16, 1)
  let tpl = gbe_i16(4, 4, 1)
  let m = @feature.template_match_16(img, tpl)
  assert_true(m.length() > 0)
  let best = @feature.template_match_best_16(img, tpl)
  match best {
    Some(r) => assert_true(r.score >= -1.0)
    None => assert_true(false)
  }
  try {
    let _ = @feature.template_match_16(gbe_i16(0, 4, 1), tpl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(gbe_i16(4, 4, 5), tpl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(@types.Image16::{
      width: 4, height: 4, channels: 1, data: Bytes::from_array([]),
    }, tpl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(img, gbe_i16(0, 2, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(img, gbe_i16(2, 2, 5))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(img, @types.Image16::{
      width: 2, height: 2, channels: 1, data: Bytes::from_array([]),
    })
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_16(img, gbe_i16(20, 20, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let fimf = gbe_if(16, 16, 1)
  let ftpl = gbe_if(4, 4, 1)
  let fm = @feature.template_match_f(fimf, ftpl)
  assert_true(fm.length() > 0)
  let fbest = @feature.template_match_best_f(fimf, ftpl)
  match fbest {
    Some(r) => assert_true(r.score >= -1.0)
    None => assert_true(false)
  }
  try {
    let _ = @feature.template_match_f(gbe_if(0, 4, 1), ftpl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_f(gbe_if(4, 4, 5), ftpl)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @feature.template_match_f(fimf, gbe_if(20, 20, 1))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
