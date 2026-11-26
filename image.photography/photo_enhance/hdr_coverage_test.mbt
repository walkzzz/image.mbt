// 覆盖率测试：HDR（融合 / 色调映射 / 流水线 / 校验分支）

fn hdc_img(w : Int32, h : Int32, c : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h * c) {
    d.push(v)
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn hdc_bad_dims() -> @types.Image {
  hdc_img(0, 2, 1, b'\x00')
}

fn hdc_bad_channels() -> @types.Image {
  hdc_img(2, 2, 5, b'\x00')
}

fn hdc_bad_data() -> @types.Image {
  @types.Image::{
    width: 2,
    height: 2,
    channels: 1,
    data: Bytes::from_array([b'\x01']),
  }
}

test "hdcov: 默认配置" {
  let c = @photo_enhance.hdr_default_config()
  assert_true(c.fusion_method == "weighted")
  assert_true(c.tone_mapping == "reinhard")
  assert_true(c.reinhard_key == 0.18)
  assert_true(c.sigmoid_strength == 5.0)
  assert_true(c.gamma > 0.0)
}

test "hdcov: 平均融合" {
  let a = hdc_img(2, 2, 1, b'\x00')
  let b = hdc_img(2, 2, 1, b'\x80')
  let imgs : Array[@types.Image] = [a, b]
  let r = @photo_enhance.hdr_fusion_average(imgs)
  assert_true(r.width == 2)
  assert_true(r.channels == 1)
  assert_true(r.data[0].to_int() == 64)
  // 单图 → 原样
  let one : Array[@types.Image] = [b]
  let r1 = @photo_enhance.hdr_fusion_average(one)
  assert_true(r1.data[0].to_int() == 128)
  // 三图平均：0 + 128 + 255 = 383/3 = 127.67 → 127
  let big = hdc_img(2, 2, 1, b'\xFF')
  let three : Array[@types.Image] = [a, b, big]
  let r3 = @photo_enhance.hdr_fusion_average(three)
  assert_true(r3.data[0].to_int() == 127)
  // 三通道
  let rgb1 = hdc_img(2, 2, 3, b'\x00')
  let rgb2 = hdc_img(2, 2, 3, b'\xFF')
  let rgbs : Array[@types.Image] = [rgb1, rgb2]
  let rrc = @photo_enhance.hdr_fusion_average(rgbs)
  assert_true(rrc.channels == 3)
  assert_true(rrc.data[0].to_int() == 127)
  // 校验：空数组
  try {
    let e : Array[@types.Image] = []
    let _ = @photo_enhance.hdr_fusion_average(e)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 尺寸为 0
  try {
    let bad : Array[@types.Image] = [hdc_bad_dims()]
    let _ = @photo_enhance.hdr_fusion_average(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 通道越界
  try {
    let bad : Array[@types.Image] = [hdc_bad_channels()]
    let _ = @photo_enhance.hdr_fusion_average(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 尺寸不一致
  try {
    let a2 = hdc_img(2, 2, 1, b'\x00')
    let a3 = hdc_img(3, 2, 1, b'\x00')
    let bad : Array[@types.Image] = [a2, a3]
    let _ = @photo_enhance.hdr_fusion_average(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  try {
    let ok = hdc_img(2, 2, 1, b'\x00')
    let bad : Array[@types.Image] = [ok, hdc_bad_data()]
    let _ = @photo_enhance.hdr_fusion_average(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hdcov: 加权融合" {
  let dark = hdc_img(2, 2, 1, b'\x00')
  let mid = hdc_img(2, 2, 1, b'\x80')
  let imgs : Array[@types.Image] = [dark, mid]
  let r = @photo_enhance.hdr_fusion_weighted(imgs)
  assert_true(r.width == 2)
  // 中间调权重更高，结果偏向中间值
  assert_true(r.data[0].to_int() >= 110)
  assert_true(r.data[0].to_int() <= 128)
  // 三通道（亮度公式走 r/g/b 分支）
  let c1 = hdc_img(1, 1, 3, b'\x00')
  let c2 = hdc_img(1, 1, 3, b'\x80')
  let cs : Array[@types.Image] = [c1, c2]
  let rc = @photo_enhance.hdr_fusion_weighted(cs)
  assert_true(rc.channels == 3)
  assert_true(rc.data[0].to_int() > 0)
  // 两通道（g 分支）
  let t1 = hdc_img(1, 1, 2, b'\x00')
  let t2 = hdc_img(1, 1, 2, b'\x80')
  let ts : Array[@types.Image] = [t1, t2]
  let rt = @photo_enhance.hdr_fusion_weighted(ts)
  assert_true(rt.channels == 2)
  // 校验
  try {
    let e : Array[@types.Image] = []
    let _ = @photo_enhance.hdr_fusion_weighted(e)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let bad : Array[@types.Image] = [hdc_bad_dims()]
    let _ = @photo_enhance.hdr_fusion_weighted(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let bad : Array[@types.Image] = [hdc_bad_channels()]
    let _ = @photo_enhance.hdr_fusion_weighted(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let a2 = hdc_img(2, 2, 1, b'\x00')
    let a3 = hdc_img(2, 3, 1, b'\x00')
    let bad : Array[@types.Image] = [a2, a3]
    let _ = @photo_enhance.hdr_fusion_weighted(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let ok = hdc_img(2, 2, 1, b'\x00')
    let bad : Array[@types.Image] = [ok, hdc_bad_data()]
    let _ = @photo_enhance.hdr_fusion_weighted(bad)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hdcov: Reinhard 色调映射" {
  let flat = hdc_img(2, 2, 1, b'\x80')
  let r = @photo_enhance.tone_mapping_reinhard(flat)
  assert_true(r.width == 2)
  // 0.50196*0.18/0.50206 → 0.17996 → /(1+) → 0.15251 → 38.9 → 38
  assert_true(r.data[0].to_int() == 38)
  // key 越大越亮
  let bright = @photo_enhance.tone_mapping_reinhard(flat, key=2.0)
  assert_true(bright.data[0].to_int() > 38)
  // 全黑图：log_avg ≈ 0.0001 → 强缩放 → 仍为 0
  let black = hdc_img(2, 2, 1, b'\x00')
  let rb = @photo_enhance.tone_mapping_reinhard(black)
  assert_true(rb.data[0].to_int() == 0)
  // 校验
  try {
    let _ = @photo_enhance.tone_mapping_reinhard(flat, key=0.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_reinhard(flat, key=-1.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_reinhard(hdc_bad_dims())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_reinhard(hdc_bad_channels())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_reinhard(hdc_bad_data())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hdcov: Gamma 色调映射" {
  let flat = hdc_img(2, 2, 1, b'\x80')
  // gamma 1.0 → 原值
  let g1 = @photo_enhance.tone_mapping_gamma(flat, gamma=1.0)
  assert_true(g1.data[0].to_int() == 128)
  // gamma 0.5 → sqrt(0.50196)=0.70849 → 180.66 → 180
  let g5 = @photo_enhance.tone_mapping_gamma(flat, gamma=0.5)
  assert_true(g5.data[0].to_int() == 180)
  // 默认 gamma（1/2.2）→ 提亮
  let gd = @photo_enhance.tone_mapping_gamma(flat)
  assert_true(gd.data[0].to_int() > 128)
  // 校验
  try {
    let _ = @photo_enhance.tone_mapping_gamma(flat, gamma=0.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_gamma(hdc_bad_dims())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_gamma(hdc_bad_channels())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_gamma(hdc_bad_data())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hdcov: Sigmoid 色调映射" {
  let flat = hdc_img(2, 2, 1, b'\x80')
  // 中间值附近几乎不变
  let s5 = @photo_enhance.tone_mapping_sigmoid(flat)
  assert_true(s5.data[0].to_int() == 128)
  // 暗部提升：val 0 → 1/(1+exp(2.5)) → 19
  let black = hdc_img(2, 2, 1, b'\x00')
  let sb = @photo_enhance.tone_mapping_sigmoid(black)
  assert_true(sb.data[0].to_int() >= 18)
  assert_true(sb.data[0].to_int() <= 20)
  // 亮部压缩：255 → 1/(1+exp(-2.5)) → 236
  let white = hdc_img(2, 2, 1, b'\xFF')
  let sw = @photo_enhance.tone_mapping_sigmoid(white)
  assert_true(sw.data[0].to_int() >= 235)
  assert_true(sw.data[0].to_int() <= 237)
  // 校验
  try {
    let _ = @photo_enhance.tone_mapping_sigmoid(flat, strength=0.0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_sigmoid(hdc_bad_dims())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_sigmoid(hdc_bad_channels())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @photo_enhance.tone_mapping_sigmoid(hdc_bad_data())
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "hdcov: HDR 流水线" {
  let a = hdc_img(2, 2, 1, b'\x00')
  let b = hdc_img(2, 2, 1, b'\x80')
  let imgs : Array[@types.Image] = [a, b]
  // 默认配置：weighted + reinhard
  let r = @photo_enhance.hdr_process(imgs)
  assert_true(r.width == 2)
  assert_true(r.channels == 1)
  assert_true(r.data[0].to_int() < 128)
  // average + gamma
  let c_gamma = @photo_enhance.HdrConfig::{
    fusion_method: "average",
    tone_mapping: "gamma",
    gamma: 1.0,
    reinhard_key: 0.18,
    sigmoid_strength: 5.0,
  }
  let r2 = @photo_enhance.hdr_process(imgs, config=c_gamma)
  assert_true(r2.data[0].to_int() == 64)
  // average + sigmoid
  let c_sig = @photo_enhance.HdrConfig::{
    fusion_method: "average",
    tone_mapping: "sigmoid",
    gamma: 1.0,
    reinhard_key: 0.18,
    sigmoid_strength: 5.0,
  }
  let r3 = @photo_enhance.hdr_process(imgs, config=c_sig)
  assert_true(r3.data[0].to_int() < 64)
  // 未知融合/映射走回退
  let c_unk = @photo_enhance.HdrConfig::{
    fusion_method: "unknown",
    tone_mapping: "unknown",
    gamma: 1.0,
    reinhard_key: 0.18,
    sigmoid_strength: 5.0,
  }
  let r4 = @photo_enhance.hdr_process(imgs, config=c_unk)
  assert_true(r4.width == 2)
  // 校验：空数组
  try {
    let e : Array[@types.Image] = []
    let _ = @photo_enhance.hdr_process(e)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // gamma 非法
  let bad_gamma = @photo_enhance.HdrConfig::{
    fusion_method: "average",
    tone_mapping: "gamma",
    gamma: 0.0,
    reinhard_key: 0.18,
    sigmoid_strength: 5.0,
  }
  try {
    let _ = @photo_enhance.hdr_process(imgs, config=bad_gamma)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // reinhard_key 非法
  let bad_key = @photo_enhance.HdrConfig::{
    fusion_method: "average",
    tone_mapping: "reinhard",
    gamma: 1.0,
    reinhard_key: 0.0,
    sigmoid_strength: 5.0,
  }
  try {
    let _ = @photo_enhance.hdr_process(imgs, config=bad_key)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // strength 非法
  let bad_sig = @photo_enhance.HdrConfig::{
    fusion_method: "average",
    tone_mapping: "sigmoid",
    gamma: 1.0,
    reinhard_key: 0.18,
    sigmoid_strength: 0.0,
  }
  try {
    let _ = @photo_enhance.hdr_process(imgs, config=bad_sig)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
