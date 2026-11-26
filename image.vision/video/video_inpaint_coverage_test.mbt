// 覆盖率测试：视频修复与去闪烁

fn vi_img(w : Int32, h : Int32, c : Int32, v : Int32) -> @types.Image {
  let n = w * h * c
  let d : Array[Byte] = Array::make(n, v.to_byte())
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn vi_mask(w : Int32, h : Int32, on : Bool) -> Array[Bool] {
  let m : Array[Bool] = []
  for _i in 0..<(w * h) {
    m.push(on)
  }
  m
}

fn vi_cfg(mi : @video.VideoInpaintMethod) -> @video.VideoInpaintConfig {
  @video.VideoInpaintConfig::{
    inpaint_method: mi,
    temporal_radius: 3,
    spatial_radius: 2,
    blend_factor: 0.5,
  }
}

test "vicov: 默认配置" {
  let c = @video.default_inpaint_config()
  assert_true(c.inpaint_method == @video.VideoInpaintMethod::Temporal)
  assert_true(c.temporal_radius == 3)
  assert_true(c.spatial_radius == 5)
  assert_true(c.blend_factor == 0.5)
  let f = @video.default_flicker_config()
  assert_true(f.flicker_method == @video.FlickerMethod::TemporalFlicker)
  assert_true(f.temporal_window == 5)
  assert_true(f.strength == 0.8)
}

test "vicov: temporal_inpaint 与 spatial_inpaint" {
  let cur = vi_img(4, 4, 1, 10)
  let prev = vi_img(4, 4, 1, 200)
  let next = vi_img(4, 4, 1, 100)
  // 全掩码 → 用前帧/后帧混合
  let m_all = vi_mask(4, 4, true)
  let o1 = @video.temporal_inpaint(cur, prev, next, m_all, vi_cfg(@video.VideoInpaintMethod::Temporal))
  assert_true(o1.width == 4)
  assert_true(o1.data.length() == 16)
  // 无掩码 → 原样
  let m_none = vi_mask(4, 4, false)
  let o2 = @video.temporal_inpaint(cur, prev, next, m_none, vi_cfg(@video.VideoInpaintMethod::Temporal))
  assert_true(o2.data[0].to_int() == 10)
  // RGB
  let cur3 = vi_img(4, 4, 3, 30)
  let o3 = @video.temporal_inpaint(
    cur3,
    vi_img(4, 4, 3, 120),
    vi_img(4, 4, 3, 80),
    vi_mask(4, 4, true),
    vi_cfg(@video.VideoInpaintMethod::Temporal),
  )
  assert_true(o3.channels == 3)
  assert_true(o3.data.length() == 48)
  // 空域
  let grid = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array([
      b'\x00', b'\x0a', b'\x14', b'\x1e', b'\x28', b'\x32', b'\x3c', b'\x46', b'\x50',
      b'\x5a', b'\x64', b'\x6e', b'\x78', b'\x82', b'\x8c', b'\x96',
    ]),
  }
  let m2 : Array[Bool] = []
  for i in 0..<16 {
    m2.push(i == 5 || i == 6 || i == 9 || i == 10)
  }
  let s1 = @video.spatial_inpaint(grid, m2, vi_cfg(@video.VideoInpaintMethod::Spatial))
  assert_true(s1.data.length() == 16)
  // 无掩码空域 → 原样
  let s2 = @video.spatial_inpaint(grid, vi_mask(4, 4, false), vi_cfg(@video.VideoInpaintMethod::Hybrid))
  assert_true(s2.data[5].to_int() == 50)
  // 全掩码空域（无邻域可借）也不崩溃
  let s3 = @video.spatial_inpaint(grid, vi_mask(4, 4, true), vi_cfg(@video.VideoInpaintMethod::Spatial))
  assert_true(s3.data.length() == 16)
}

test "vicov: video_inpaint 多帧" {
  let frames : Array[@types.Image] = [
    vi_img(3, 3, 1, 20),
    vi_img(3, 3, 1, 60),
    vi_img(3, 3, 1, 120),
  ]
  let m : Array[Bool] = []
  for i in 0..<9 {
    m.push(i == 4)
  }
  let r = @video.video_inpaint(frames, m, @video.default_inpaint_config())
  assert_true(r.length() == 3)
  assert_true(r[0].width == 3)
  assert_true(r[2].data.length() == 9)
  // 空帧列表
  let empty : Array[@types.Image] = []
  let r0 = @video.video_inpaint(empty, m, @video.default_inpaint_config())
  assert_true(r0.length() == 0)
  // 空间方法
  let cfg_s = vi_cfg(@video.VideoInpaintMethod::Spatial)
  let r1 = @video.video_inpaint(frames, m, cfg_s)
  assert_true(r1.length() == 3)
  // 混合方法
  let cfg_h = vi_cfg(@video.VideoInpaintMethod::Hybrid)
  let r2 = @video.video_inpaint(frames, m, cfg_h)
  assert_true(r2.length() == 3)
}

test "vicov: 闪烁检测与去闪烁" {
  // 少于 2 帧
  let one : Array[@types.Image] = [vi_img(2, 2, 1, 50)]
  let d0 = @video.detect_flicker(one, 10.0)
  assert_true(!d0.has_flicker)
  assert_true(d0.flicker_score == 0.0)
  assert_true(d0.frame_indices.length() == 0)
  // 亮度突变 → 检出闪烁
  let frames : Array[@types.Image] = [
    vi_img(4, 4, 1, 10),
    vi_img(4, 4, 1, 200),
    vi_img(4, 4, 1, 10),
  ]
  let d1 = @video.detect_flicker(frames, 50.0)
  assert_true(d1.frame_indices.length() == 2)
  assert_true(d1.flicker_score > 0.05)
  assert_true(d1.has_flicker)
  // 稳定帧 → 无闪烁
  let stable : Array[@types.Image] = [vi_img(4, 4, 1, 100), vi_img(4, 4, 1, 100)]
  let d2 = @video.detect_flicker(stable, 10.0)
  assert_true(!d2.has_flicker)
  // 时域去闪烁
  let t = @video.deflicker_temporal(frames, @video.default_flicker_config())
  assert_true(t.length() == 3)
  assert_true(t[0].width == 4)
  // 空列表
  let empty : Array[@types.Image] = []
  let t0 = @video.deflicker_temporal(empty, @video.default_flicker_config())
  assert_true(t0.length() == 0)
  // 窗口大于帧数
  let cfg_big = @video.FlickerConfig::{
    flicker_method: @video.FlickerMethod::TemporalFlicker,
    temporal_window: 9,
    strength: 0.5,
  }
  let t1 = @video.deflicker_temporal(frames, cfg_big)
  assert_true(t1.length() == 3)
  // 直方图去闪烁
  let h1 = @video.deflicker_histogram(frames, @video.default_flicker_config())
  assert_true(h1.length() == 3)
  assert_true(h1[0].data[0].to_int() == 10)
  // 空列表
  let h0 = @video.deflicker_histogram(empty, @video.default_flicker_config())
  assert_true(h0.length() == 0)
  // 亮度归一化方法
  let cfg_l = @video.FlickerConfig::{
    flicker_method: @video.FlickerMethod::LuminanceFlicker,
    temporal_window: 3,
    strength: 1.0,
  }
  let l1 = @video.deflicker_temporal(frames, cfg_l)
  assert_true(l1.length() == 3)
  let l2 = @video.deflicker_histogram(frames, cfg_l)
  assert_true(l2.length() == 3)
}
