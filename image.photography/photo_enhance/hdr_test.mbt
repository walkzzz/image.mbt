///|
fn hdr_make_rgb(w : Int32, h : Int32, base : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 3 + base) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "hdr: 默认配置" {
  let cfg = @photo_enhance.hdr_default_config()
  assert_true(cfg.gamma > 0.0)
}

///|
test "hdr: fusion average/weighted 与三种 tone mapping" {
  let a = hdr_make_rgb(8, 8, 0)
  let b = hdr_make_rgb(8, 8, 40)
  try {
    let avg = @photo_enhance.hdr_fusion_average([a, b])
    assert_eq(avg.width, 8)
    assert_eq(avg.height, 8)
    assert_eq(avg.channels, 3)
    let weighted = @photo_enhance.hdr_fusion_weighted([a, b])
    assert_eq(weighted.width, 8)
    assert_eq(@photo_enhance.tone_mapping_reinhard(avg).channels, 3)
    assert_eq(@photo_enhance.tone_mapping_gamma(avg).width, 8)
    assert_eq(@photo_enhance.tone_mapping_sigmoid(avg).height, 8)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "hdr: hdr_process 无配置与带配置" {
  let a = hdr_make_rgb(8, 8, 10)
  let b = hdr_make_rgb(8, 8, 90)
  try {
    let out = @photo_enhance.hdr_process([a, b])
    assert_eq(out.width, 8)
    let cfg = @photo_enhance.hdr_default_config()
    let out2 = @photo_enhance.hdr_process([a, b], config=cfg)
    assert_eq(out2.channels, 3)
  } catch {
    _ => assert_true(false)
  }
}
