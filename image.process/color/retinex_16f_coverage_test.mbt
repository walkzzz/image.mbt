// 覆盖率测试：多尺度 Retinex 16-bit / float 变体（SSR / MSR / MSRCR）

fn r16_img(w : Int32, h : Int32, ch : Int32, v : Int32) -> @types.Image16 {
  let n = w * h * ch
  let d : Array[Byte] = Array::make(n * 2, b'\x00')
  for i in 0..<n {
    d[i * 2] = (v & 0xFF).to_byte()
    d[i * 2 + 1] = ((v >> 8) & 0xFF).to_byte()
  }
  @types.Image16::{ width: w, height: h, channels: ch, data: Bytes::from_array(d) }
}

fn rf_img(w : Int32, h : Int32, ch : Int32, v : Float) -> @types.ImageF {
  let n = w * h * ch
  let d : Array[Byte] = Array::make(n * 4, b'\x00')
  for i in 0..<n {
    let bits = v.reinterpret_as_int()
    d[i * 4] = (bits & 0xFF).to_byte()
    d[i * 4 + 1] = ((bits >> 8) & 0xFF).to_byte()
    d[i * 4 + 2] = ((bits >> 16) & 0xFF).to_byte()
    d[i * 4 + 3] = ((bits >> 24) & 0xFF).to_byte()
  }
  @types.ImageF::{ width: w, height: h, channels: ch, data: Bytes::from_array(d) }
}

fn r16_read(d : Bytes, idx : Int32) -> Int32 {
  d[idx].to_int() | (d[idx + 1].to_int() << 8)
}

fn rf_read(d : Bytes, idx : Int32) -> Float {
  let b0 = d[idx].to_int()
  let b1 = d[idx + 1].to_int()
  let b2 = d[idx + 2].to_int()
  let b3 = d[idx + 3].to_int()
  Float::reinterpret_from_int(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
}

fn r16_bad_ch() -> @types.Image16 {
  r16_img(2, 2, 2, 128)
}

fn r16_bad_data() -> @types.Image16 {
  @types.Image16::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x01']),
  }
}

fn rf_bad_ch() -> @types.ImageF {
  rf_img(2, 2, 2, 0.5F)
}

test "r16cov: ssr_16 正常与校验" {
  // 平坦图：log 差 0 → 32768
  let flat = r16_img(3, 3, 1, 128)
  let s = @color.ssr_16(flat, sigma=10.0F)
  assert_true(s.width == 3)
  assert_true(s.channels == 1)
  assert_true(r16_read(s.data, 0) == 32768)
  // 三通道
  let rgb = r16_img(3, 3, 3, 128)
  let sr = @color.ssr_16(rgb, sigma=10.0F)
  assert_true(sr.channels == 3)
  assert_true(r16_read(sr.data, 0) == 32768)
  // 默认 sigma
  let sd = @color.ssr_16(rgb)
  assert_true(sd.width == 3)
  // 四通道：alpha 原样透传
  let rgba = r16_img(3, 3, 4, 128)
  let sa = @color.ssr_16(rgba, sigma=10.0F)
  assert_true(sa.channels == 4)
  assert_true(r16_read(sa.data, 3 * 2) == 128)
  assert_true(r16_read(sa.data, 0) == 32768)
  // 零尺寸 → 原样返回
  let zero = r16_img(0, 4, 1, 0)
  let sz = @color.ssr_16(zero, sigma=10.0F)
  assert_true(sz.width == 0)
  // 负尺寸
  try {
    let neg = @types.Image16::{
      width: -1,
      height: 2,
      channels: 1,
      data: Bytes::from_array([]),
    }
    let _ = @color.ssr_16(neg, sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道非法
  try {
    let _ = @color.ssr_16(r16_bad_ch(), sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  try {
    let _ = @color.ssr_16(r16_bad_data(), sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigma 非法
  try {
    let _ = @color.ssr_16(flat, sigma=0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "r16cov: ssr_f 正常与校验" {
  let flat = rf_img(3, 3, 1, 0.5F)
  let s = @color.ssr_f(flat, sigma=10.0F)
  assert_true(s.channels == 1)
  // 平坦图 retinex ≈ 0
  assert_true(rf_read(s.data, 0) > -1.0F && rf_read(s.data, 0) < 1.0F)
  // 三通道 + gain/offset
  let rgb = rf_img(3, 3, 3, 0.5F)
  let sr = @color.ssr_f(rgb, sigma=10.0F, gain=2.0F, offset=0.5F)
  assert_true(sr.channels == 3)
  // 四通道 alpha 透传
  let rgba = rf_img(3, 3, 4, 0.5F)
  let sa = @color.ssr_f(rgba, sigma=10.0F)
  assert_true(rf_read(sa.data, 3 * 4) == 0.5F)
  // 零尺寸
  let zero = rf_img(0, 2, 1, 0.0F)
  assert_true(@color.ssr_f(zero, sigma=10.0F).width == 0)
  // 负尺寸
  try {
    let neg = @types.ImageF::{
      width: -1,
      height: 2,
      channels: 1,
      data: Bytes::from_array([]),
    }
    let _ = @color.ssr_f(neg, sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道非法
  try {
    let _ = @color.ssr_f(rf_bad_ch(), sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  try {
    let bad = @types.ImageF::{
      width: 2,
      height: 2,
      channels: 1,
      data: Bytes::from_array([b'\x00']),
    }
    let _ = @color.ssr_f(bad, sigma=10.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigma 非法
  try {
    let _ = @color.ssr_f(flat, sigma=0.0F)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "r16cov: msr_16 正常与校验" {
  let flat = r16_img(3, 3, 1, 128)
  let sigmas : Array[Float] = [5.0F, 10.0F]
  let m = @color.msr_16(flat, sigmas=sigmas)
  assert_true(m.width == 3)
  assert_true(r16_read(m.data, 0) == 32768)
  // 三通道 + gain/offset
  let rgb = r16_img(3, 3, 3, 128)
  let mr = @color.msr_16(rgb, sigmas=sigmas, gain=2.0F, offset=0.5F)
  assert_true(mr.channels == 3)
  // 四通道 alpha 透传
  let rgba = r16_img(3, 3, 4, 128)
  let ma = @color.msr_16(rgba, sigmas=sigmas)
  assert_true(r16_read(ma.data, 3 * 2) == 128)
  // 默认 sigmas
  let md = @color.msr_16(flat)
  assert_true(md.width == 3)
  // 尺寸 <= 0
  try {
    let zero = r16_img(0, 4, 1, 0)
    let _ = @color.msr_16(zero)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道非法
  try {
    let _ = @color.msr_16(r16_bad_ch())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  try {
    let _ = @color.msr_16(r16_bad_data())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigmas 为空
  try {
    let empty : Array[Float] = []
    let _ = @color.msr_16(flat, sigmas=empty)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigma 非法
  try {
    let bad : Array[Float] = [0.0F]
    let _ = @color.msr_16(flat, sigmas=bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "r16cov: msr_f 正常与校验" {
  let flat = rf_img(3, 3, 1, 0.5F)
  let sigmas : Array[Float] = [5.0F, 10.0F]
  let m = @color.msr_f(flat, sigmas=sigmas)
  assert_true(m.channels == 1)
  assert_true(rf_read(m.data, 0) > -1.0F && rf_read(m.data, 0) < 1.0F)
  // 三通道 + 参数
  let rgb = rf_img(3, 3, 3, 0.5F)
  let mr = @color.msr_f(rgb, sigmas=sigmas, gain=2.0F, offset=1.0F)
  assert_true(mr.channels == 3)
  // 四通道 alpha 透传
  let rgba = rf_img(3, 3, 4, 0.5F)
  let ma = @color.msr_f(rgba, sigmas=sigmas)
  assert_true(rf_read(ma.data, 3 * 4) == 0.5F)
  // 零尺寸
  let zero = rf_img(0, 4, 1, 0.0F)
  assert_true(@color.msr_f(zero, sigmas=sigmas).width == 0)
  // 通道非法
  try {
    let _ = @color.msr_f(rf_bad_ch(), sigmas=sigmas)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigmas 为空
  try {
    let empty : Array[Float] = []
    let _ = @color.msr_f(flat, sigmas=empty)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigma 非法
  try {
    let bad : Array[Float] = [-1.0F]
    let _ = @color.msr_f(flat, sigmas=bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "r16cov: msrcr_16 正常与校验" {
  let sigmas : Array[Float] = [5.0F, 10.0F]
  // 3 通道灰：crf = ln(125*128/(384+1))*46 ≈ 174.95 → 38016
  let rgb = r16_img(2, 2, 3, 128)
  let r = @color.msrcr_16(rgb, sigmas=sigmas)
  assert_true(r.channels == 3)
  assert_true(r16_read(r.data, 0) > 32768)
  let v0 = r16_read(r.data, 0)
  let v1 = r16_read(r.data, 2)
  let v2 = r16_read(r.data, 4)
  assert_true(v0 == v1)
  assert_true(v1 == v2)
  // 4 通道 alpha 透传
  let rgba = r16_img(2, 2, 4, 128)
  let ra = @color.msrcr_16(rgba, sigmas=sigmas)
  assert_true(ra.channels == 4)
  assert_true(r16_read(ra.data, 3 * 2) == 128)
  // 单通道非法
  try {
    let _ = @color.msrcr_16(r16_img(2, 2, 1, 128), sigmas=sigmas)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 尺寸 <= 0
  try {
    let _ = @color.msrcr_16(r16_img(0, 2, 3, 128), sigmas=sigmas)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  try {
    let bad = @types.Image16::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array([b'\x01']),
    }
    let _ = @color.msrcr_16(bad, sigmas=sigmas)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigmas 为空
  try {
    let empty : Array[Float] = []
    let _ = @color.msrcr_16(rgb, sigmas=empty)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "r16cov: msrcr_f 正常与校验" {
  let sigmas : Array[Float] = [5.0F, 10.0F]
  let rgb = rf_img(2, 2, 3, 0.5F)
  let r = @color.msrcr_f(rgb, sigmas=sigmas)
  assert_true(r.channels == 3)
  let v0 = rf_read(r.data, 0)
  let v1 = rf_read(r.data, 4)
  assert_true(v0 == v1)
  assert_true(v0 > 0.0F)
  // 4 通道 alpha 透传
  let rgba = rf_img(2, 2, 4, 0.5F)
  let ra = @color.msrcr_f(rgba, sigmas=sigmas)
  assert_true(rf_read(ra.data, 3 * 4) == 0.5F)
  // 零尺寸
  let zero = rf_img(0, 2, 3, 0.0F)
  assert_true(@color.msrcr_f(zero, sigmas=sigmas).width == 0)
  // 单通道非法
  try {
    let _ = @color.msrcr_f(rf_img(2, 2, 1, 0.5F), sigmas=sigmas)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // sigmas 为空
  try {
    let empty : Array[Float] = []
    let _ = @color.msrcr_f(rgb, sigmas=empty)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
