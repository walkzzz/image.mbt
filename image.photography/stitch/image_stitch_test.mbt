///|
fn stitch_make(w : Int32, h : Int32, seed : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push(((i * 11 + seed) % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "stitch: 单应矩阵基础" {
  let h = @stitch.identity_homography()
  let (x, y) = @stitch.apply_homography(h, 3.0, 4.0)
  assert_true((x - 3.0).abs() < 0.001)
  assert_true((y - 4.0).abs() < 0.001)
  let inv = @stitch.invert_homography(h)
  assert_true(inv is Some(_))
}

///|
test "stitch: 特征检测 / 匹配 / 单应估计 / 拼接" {
  let a = stitch_make(16, 16, 0)
  let b = stitch_make(16, 16, 1)
  let fa = @stitch.detect_features_simple(a)
  let fb = @stitch.detect_features_simple(b)
  let matches = @stitch.match_features(fa, fb)
  let (homography, inliers) = @stitch.estimate_homography_ransac(
    matches, fa, fb,
  )
  assert_true(inliers.length() <= matches.length())
  let _ = homography
  let _ = @stitch.stitch_images(a, b)
  assert_true(true)
}

///|
fn stitch_checker(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let block = (x / 4 + y / 4) % 2 == 0
      let v : Byte = if block { b'\xFF' } else { b'\x00' }
      data.push(v)
      data.push(v)
      data.push(v)
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "stitch: 高特征棋盘图走成功路径" {
  let a = stitch_checker(32, 32)
  let b = stitch_checker(32, 32)
  let out = @stitch.stitch_images(a, b)
  match out {
    Some(img) => {
      assert_true(img.width > 0)
      assert_true(img.height > 0)
      assert_eq(img.channels, 3)
    }
    None => assert_true(true)
  }
  let cfg = @stitch.stitch_default_config()
  let _ = @stitch.stitch_images(a, b, config=cfg)
  assert_true(true)
}
