// 覆盖率测试：视频特效（滤镜 / 转场 / 叠加 / 水印 / 流水线）

///|
fn vc_img(w : Int32, h : Int32, c : Int32, v : Byte) -> @types.Image {
  let data : Array[Byte] = []
  for _ in 0..<(w * h * c) {
    data.push(v)
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(data),
  }
}

///|
test "vcov: 默认参数" {
  let fp = @video.default_video_filter_params(@video.VideoFilterType::Blur)
  assert_true(fp.intensity == 0.5)
  assert_true(fp.filter_type == @video.VideoFilterType::Blur)
  let tp = @video.default_transition_params(@video.TransitionType::Fade)
  assert_true(tp.duration == 10)
  assert_true(tp.direction == 0)
  assert_true(tp.transition_type == @video.TransitionType::Fade)
}

///|
test "vcov: 滤镜分支" {
  let flat = vc_img(4, 4, 1, b'\x64')
  // Blur：平坦图保持原值；intensity 0 → 半径仍为 1
  let b0 = @video.apply_video_filter(flat, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Blur,
    intensity: 0.0,
  })
  assert_true(b0.data[0].to_int() == 100)
  assert_true(b0.channels == 1)
  // Sharpen：平坦图差分 0 → 保持原值
  let s = @video.apply_video_filter(flat, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Sharpen,
    intensity: 0.5,
  })
  assert_true(s.data[0].to_int() == 100)
  // Vintage：100*0.9 + 20*0.5 = 100
  let v = @video.apply_video_filter(flat, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Vintage,
    intensity: 0.5,
  })
  assert_true(v.data[0].to_int() == 100)
  // Vintage intensity 1.0：100*0.9+20 = 110
  let v1 = @video.apply_video_filter(flat, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Vintage,
    intensity: 1.0,
  })
  assert_true(v1.data[0].to_int() == 110)
  // Grayscale：单通道直接返回原图
  let g1 = @video.apply_video_filter(flat, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Grayscale,
    intensity: 0.5,
  })
  assert_true(g1.data[0].to_int() == 100)
  // Grayscale 三通道：等值像素灰度仍等值
  let rgb = vc_img(2, 2, 3, b'\x64')
  let g3 = @video.apply_video_filter(rgb, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Grayscale,
    intensity: 0.5,
  })
  assert_true(g3.data[0].to_int() == 100)
  assert_true(g3.data.length() == 12)
  // Grayscale 两通道也走回退
  let two = vc_img(2, 2, 2, b'\x10')
  let g2 = @video.apply_video_filter(two, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Grayscale,
    intensity: 0.5,
  })
  assert_true(g2.data[0].to_int() == 16)
  // Sepia：两通道直接返回
  let sp2 = @video.apply_video_filter(two, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Sepia,
    intensity: 0.5,
  })
  assert_true(sp2.data[0].to_int() == 16)
  // Sepia 四通道：alpha 保留原值
  let rgba_data : Array[Byte] = Array::make(4 * 4, b'\x05')
  let rgba = @types.Image::{
    width: 2,
    height: 2,
    channels: 4,
    data: Bytes::from_array(rgba_data),
  }
  let sp4 = @video.apply_video_filter(rgba, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Sepia,
    intensity: 1.0,
  })
  assert_true(sp4.data.length() == 16)
  assert_true(sp4.data[3].to_int() == 5)
  // Sepia intensity 0 → 原值
  let sp0 = @video.apply_video_filter(rgb, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Sepia,
    intensity: 0.0,
  })
  assert_true(sp0.data[0].to_int() == 100)
  // Vignette：中心不变、角点变暗
  let vig = vc_img(4, 4, 1, b'\x64')
  let vg = @video.apply_video_filter(vig, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Vignette,
    intensity: 1.0,
  })
  assert_true(vg.data[0].to_int() == 0)
  assert_true(vg.data[2 * 4 + 2].to_int() == 100)
  let vg0 = @video.apply_video_filter(vig, @video.VideoFilterParams::{
    filter_type: @video.VideoFilterType::Vignette,
    intensity: 0.0,
  })
  assert_true(vg0.data[0].to_int() == 100)
}

///|
test "vcov: 淡入淡出 / 溶解" {
  let from = vc_img(4, 2, 1, b'\x0A')
  let to_ = vc_img(4, 2, 1, b'\xC8')
  let fade = @video.TransitionParams::{
    transition_type: @video.TransitionType::Fade,
    duration: 2,
    direction: 0,
  }
  let f0 = @video.create_transition_frame(from, to_, 0.0, fade)
  assert_true(f0.data[0].to_int() == 10)
  let f1 = @video.create_transition_frame(from, to_, 1.0, fade)
  assert_true(f1.data[0].to_int() == 200)
  // progress 越界钳制：-0.5 → 0，1.5 → 1
  let fneg = @video.create_transition_frame(from, to_, -0.5, fade)
  assert_true(fneg.data[0].to_int() == 10)
  let fbig = @video.create_transition_frame(from, to_, 1.5, fade)
  assert_true(fbig.data[0].to_int() == 200)
  // 中间值：10*(1-0.5) + 200*0.5 = 105
  let fh = @video.create_transition_frame(from, to_, 0.5, fade)
  assert_true(fh.data[0].to_int() == 105)
  // 溶解与淡入一致
  let diss = @video.create_transition_frame(from, to_, 0.5, @video.TransitionParams::{
    transition_type: @video.TransitionType::Dissolve,
    duration: 2,
    direction: 0,
  })
  assert_true(diss.data[0].to_int() == 105)
}

///|
fn vc_trans(t : @video.TransitionType, dir : Int32) -> @video.TransitionParams {
  @video.TransitionParams::{ transition_type: t, duration: 4, direction: dir, }
}

///|
test "vcov: 滑动转场四方向" {
  let from = vc_img(8, 4, 1, b'\x0A')
  let to_ = vc_img(8, 4, 1, b'\xC8')
  // 方向 0：左半来自目标图
  let s0 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Slide, 0),
  )
  assert_true(s0.data[0].to_int() == 200)
  assert_true(s0.data[0 * 8 + 5].to_int() == 10)
  // 方向 1：右半来自目标图
  let s1 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Slide, 1),
  )
  assert_true(s1.data[0].to_int() == 10)
  assert_true(s1.data[0 * 8 + 5].to_int() == 200)
  // 方向 2：上半来自目标图（h=4，offset=2）
  let s2 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Slide, 2),
  )
  assert_true(s2.data[0].to_int() == 200)
  assert_true(s2.data[3 * 8].to_int() == 10)
  // 方向 3：下半来自目标图
  let s3 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Slide, 3),
  )
  assert_true(s3.data[0].to_int() == 10)
  assert_true(s3.data[3 * 8].to_int() == 200)
}

///|
test "vcov: 擦除转场四方向" {
  let from = vc_img(8, 4, 1, b'\x0A')
  let to_ = vc_img(8, 4, 1, b'\xC8')
  let w0 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Wipe, 0),
  )
  assert_true(w0.data[0].to_int() == 200)
  assert_true(w0.data[7].to_int() == 10)
  let w1 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Wipe, 1),
  )
  assert_true(w1.data[0].to_int() == 10)
  assert_true(w1.data[7].to_int() == 200)
  let w2 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Wipe, 2),
  )
  assert_true(w2.data[0].to_int() == 200)
  assert_true(w2.data[3 * 8].to_int() == 10)
  let w3 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Wipe, 3),
  )
  assert_true(w3.data[0].to_int() == 10)
  assert_true(w3.data[3 * 8].to_int() == 200)
}

///|
test "vcov: 推送转场四方向" {
  let from = vc_img(8, 4, 1, b'\x0A')
  let to_ = vc_img(8, 4, 1, b'\xC8')
  let p0 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Push, 0),
  )
  assert_true(p0.data[0].to_int() == 200)
  assert_true(p0.data[7].to_int() == 10)
  let p1 = @video.create_transition_frame(
    from,
    to_,
    0.5,
    vc_trans(@video.TransitionType::Push, 1),
  )
  assert_true(p1.data[0].to_int() == 10)
  assert_true(p1.data[7].to_int() == 200)
  let p2 = @video.create_transition_frame(
    from,
    to_,
    0.25,
    vc_trans(@video.TransitionType::Push, 2),
  )
  assert_true(p2.data[0].to_int() == 200)
  assert_true(p2.data[3 * 8].to_int() == 10)
  let p3 = @video.create_transition_frame(
    from,
    to_,
    0.25,
    vc_trans(@video.TransitionType::Push, 3),
  )
  assert_true(p3.data[0].to_int() == 10)
  assert_true(p3.data[3 * 8].to_int() == 200)
}

///|
test "vcov: 转场序列生成" {
  let from = vc_img(4, 4, 1, b'\x0A')
  let to_ = vc_img(4, 4, 1, b'\xC8')
  let frames = @video.generate_transition(
    from,
    to_,
    vc_trans(@video.TransitionType::Fade, 0),
  )
  assert_true(frames.length() == 4)
  assert_true(frames[0].data[0].to_int() == 10)
  // 最后一帧 progress = 3/4 = 0.75 → 10*0.25 + 200*0.75 = 152.5 → 152
  assert_true(frames[3].data[0].to_int() == 152)
}

///|
test "vcov: 文字叠加 / 时间戳" {
  let img = vc_img(8, 6, 1, b'\x00')
  let o = @video.add_text_overlay(img, 2, 1, 3, 2, b'\xFF')
  assert_true(o.data[1 * 8 + 2].to_int() == 255)
  assert_true(o.data[1 * 8 + 4].to_int() == 255)
  assert_true(o.data[1 * 8 + 5].to_int() == 0)
  assert_true(o.data[0].to_int() == 0)
  // 越界区域不影响
  let o2 = @video.add_text_overlay(img, 20, 20, 4, 4, b'\xFF')
  assert_true(o2.data[0].to_int() == 0)
  // 时间戳：w=10,h=8 → bar_width=3,bar_y=5,bar_height=2
  let ts = vc_img(10, 8, 1, b'\x05')
  let t0 = @video.add_timestamp(ts, 0, 10)
  assert_true(t0.data[5 * 10].to_int() == 128)
  let t5 = @video.add_timestamp(ts, 5, 10)
  // progress 0.5 → filled = 1 → px 0 填充 255，px 1、2 为 128
  assert_true(t5.data[5 * 10].to_int() == 255)
  assert_true(t5.data[5 * 10 + 1].to_int() == 128)
  assert_true(t5.data[0].to_int() == 5)
  let t10 = @video.add_timestamp(ts, 10, 10)
  assert_true(t10.data[5 * 10 + 2].to_int() == 255)
  // total_frames 0 → total_duration 1.0 → progress 巨大 → 全填充
  let tz = @video.add_timestamp(ts, 3, 0)
  assert_true(tz.data[5 * 10 + 2].to_int() == 255)
}

///|
test "vcov: 水印叠加" {
  let img = vc_img(8, 8, 1, b'\x00')
  let wm = vc_img(2, 2, 1, b'\xFF')
  let r = @video.add_watermark(img, wm, 1, 1, 0.5)
  assert_true(r.data[1 * 8 + 1].to_int() == 127)
  assert_true(r.data[0].to_int() == 0)
  assert_true(r.data[3 * 8 + 3].to_int() == 0)
  // opacity 越界钳制为 1
  let r1 = @video.add_watermark(img, wm, 0, 0, 5.0)
  assert_true(r1.data[0].to_int() == 255)
  // opacity 0 → 原样
  let r0 = @video.add_watermark(img, wm, 0, 0, 0.0)
  assert_true(r0.data[0].to_int() == 0)
  // 水印通道少于图像：c % wm_ch 取通道
  let rgb = vc_img(4, 4, 3, b'\x00')
  let wm1 = vc_img(2, 2, 1, b'\xFF')
  let r3 = @video.add_watermark(rgb, wm1, 0, 0, 1.0)
  assert_true(r3.data.length() == 48)
  assert_true(r3.data[0].to_int() == 255)
  assert_true(r3.data[1].to_int() == 255)
  assert_true(r3.data[2].to_int() == 255)
}

///|
test "vcov: 流水线" {
  let empty : Array[@types.Image] = []
  let none = @video.video_effects_pipeline(empty, None, None)
  assert_true(none.length() == 0)
  let f1 = vc_img(4, 4, 3, b'\x0A')
  let f2 = vc_img(4, 4, 3, b'\xC8')
  let frames : Array[@types.Image] = [f1, f2]
  // 无滤镜无转场：原帧返回
  let plain = @video.video_effects_pipeline(frames, None, None)
  assert_true(plain.length() == 2)
  // 有滤镜无转场
  let fp = @video.default_video_filter_params(@video.VideoFilterType::Grayscale)
  let filtered = @video.video_effects_pipeline(frames, Some(fp), None)
  assert_true(filtered.length() == 2)
  // 有转场：2 帧 + 1 段 × duration 2 = 4
  let tp = @video.TransitionParams::{
    transition_type: @video.TransitionType::Fade,
    duration: 2,
    direction: 0,
  }
  let both = @video.video_effects_pipeline(frames, Some(fp), Some(tp))
  assert_true(both.length() == 4)
  let only_trans = @video.video_effects_pipeline(frames, None, Some(tp))
  assert_true(only_trans.length() == 4)
  // 单帧不产生转场
  let single : Array[@types.Image] = [f1]
  let one = @video.video_effects_pipeline(single, Some(fp), Some(tp))
  assert_true(one.length() == 1)
}
