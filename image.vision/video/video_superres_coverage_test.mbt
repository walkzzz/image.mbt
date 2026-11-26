// 覆盖率测试：视频超分三种方法与质量评估分支

///|
fn vsr_img(w : Int32, h : Int32, c : Int32, seed : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 21 + y * 13 + ch * 37 + seed) % 256)
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
test "vsr: 三种超分方法" {
  let f1 = vsr_img(8, 8, 1, 0)
  let f2 = vsr_img(8, 8, 1, 30)
  let f3 = vsr_img(8, 8, 1, 60)
  let frames = [f1, f2, f3]
  // 双线性 2× / 4×
  assert_true(@video.bilinear_upscale(f1, 2).width == 16)
  assert_true(@video.bilinear_upscale(f1, 4).height == 32)
  assert_true(@video.bilinear_upscale(vsr_img(6, 4, 3, 9), 2).channels == 3)
  // 双三次批量
  let cfg2 = @video.VideoSRConfig::{
    sr_method: @video.VideoSRMethod::BicubicSR,
    scale_factor: 2,
    temporal_window: 3,
    blend_factor: 0.5,
  }
  let r1 = @video.bicubic_super_resolve(frames, cfg2)
  assert_true(r1.length() == 3)
  assert_true(r1[0].width == 16)
  // 时空
  let cfg3 = @video.VideoSRConfig::{
    sr_method: @video.VideoSRMethod::SpatioTemporal,
    scale_factor: 2,
    temporal_window: 3,
    blend_factor: 0.4,
  }
  let r2 = @video.spatio_temporal_sr(frames, cfg3)
  assert_true(r2.length() == 3)
  assert_true(@video.spatio_temporal_sr([], cfg3).length() == 0)
  // 递归（2× / 4× / 1× 直通）
  let cfg4 = @video.VideoSRConfig::{
    sr_method: @video.VideoSRMethod::RecursiveSR,
    scale_factor: 4,
    temporal_window: 3,
    blend_factor: 0.5,
  }
  let r3 = @video.recursive_sr(frames, cfg4)
  assert_true(r3[0].width == 32)
  let cfg1 = @video.VideoSRConfig::{
    sr_method: @video.VideoSRMethod::RecursiveSR,
    scale_factor: 1,
    temporal_window: 3,
    blend_factor: 0.5,
  }
  let r4 = @video.recursive_sr(frames, cfg1)
  assert_true(r4.length() == 3)
  // 主流程分发三种方法
  let a = @video.video_super_resolve(frames, cfg2)
  assert_true(a.frames.length() == 3)
  assert_true(a.quality_score >= 0.0)
  let b = @video.video_super_resolve(frames, cfg3)
  assert_true(b.scale_factor == 2)
  let c1 = @video.video_super_resolve(frames, cfg4)
  assert_true(c1.frames[0].width == 32)
  // sr_pipeline 等价入口
  let d = @video.sr_pipeline(frames, cfg2)
  assert_true(d.frames.length() == 3)
  // 默认配置
  let def = @video.default_sr_config()
  assert_true(def.scale_factor == 2)
  assert_true(def.sr_method == @video.VideoSRMethod::BicubicSR)
}

///|
test "vsr: 质量评估分支" {
  let orig = [vsr_img(8, 8, 1, 0), vsr_img(8, 8, 1, 20)]
  let sr = [
    @video.bilinear_upscale(orig[0], 2),
    @video.bilinear_upscale(orig[1], 2),
  ]
  let q = @video.compute_sr_quality(orig, sr, 2)
  assert_true(q >= 0.0)
  assert_true(q <= 1.0)
  // 尺寸不匹配 → 跳过（分数 0）
  let q2 = @video.compute_sr_quality(orig, sr, 4)
  assert_true(q2 == 0.0)
  // 空数组
  assert_true(@video.compute_sr_quality([], sr, 2) == 0.0)
  assert_true(@video.compute_sr_quality(orig, [], 2) == 0.0)
  // 空帧序列主流程
  let cfg = @video.default_sr_config()
  let empty = @video.video_super_resolve([], cfg)
  assert_true(empty.frames.length() == 0)
}
