///|
fn vid_make(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 7 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "video_effects: 六种滤镜" {
  let img = vid_make(8, 8, 0)
  let types : Array[@video.VideoFilterType] = [
    @video.VideoFilterType::Blur,
    @video.VideoFilterType::Sharpen,
    @video.VideoFilterType::Vintage,
    @video.VideoFilterType::Grayscale,
    @video.VideoFilterType::Vignette,
    @video.VideoFilterType::Sepia,
  ]
  for t in types {
    let p = @video.default_video_filter_params(t)
    let out = @video.apply_video_filter(img, p)
    assert_eq(out.width, 8)
    assert_eq(out.height, 8)
    assert_eq(out.channels, 3)
  }
}

///|
test "video_effects: 转场生成" {
  let a = vid_make(8, 8, 0)
  let b = vid_make(8, 8, 90)
  let p = @video.default_transition_params(@video.TransitionType::Fade)
  let frames = @video.generate_transition(a, b, p)
  assert_true(frames.length() >= 1)
}

///|
test "video_effects: 叠层/时间戳/水印/流水线" {
  let img = vid_make(16, 16, 0)
  let overlay = @video.add_text_overlay(img, 2, 2, 4, 4, b'\xFF')
  assert_eq(overlay.width, 16)
  let ts = @video.add_timestamp(img, 1, 10)
  assert_eq(ts.height, 16)
  let wm = vid_make(4, 4, 200)
  let marked = @video.add_watermark(img, wm, 1, 1, 0.5)
  assert_eq(marked.width, 16)
  let f = @video.default_video_filter_params(@video.VideoFilterType::Blur)
  let t = @video.default_transition_params(@video.TransitionType::Fade)
  let out = @video.video_effects_pipeline([img, overlay], Some(f), Some(t))
  assert_true(out.length() >= 1)
}

///|
test "video_effects: 五种转场类型" {
  let a = vid_make(8, 8, 0)
  let b = vid_make(8, 8, 90)
  let types : Array[@video.TransitionType] = [
    @video.TransitionType::Fade,
    @video.TransitionType::Dissolve,
    @video.TransitionType::Slide,
    @video.TransitionType::Wipe,
    @video.TransitionType::Push,
  ]
  for t in types {
    let p = @video.default_transition_params(t)
    let frames = @video.generate_transition(a, b, p)
    assert_true(frames.length() >= 1)
  }
}
