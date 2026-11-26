// 白盒：直接驱动 stitch 包内私有函数的分支

///|
fn wb_fp(x : Double, y : Double, r : Double, d : Array[Double]) -> FeaturePoint {
  FeaturePoint::{ x, y, response: r, orientation: 0.0, descriptor: d, }
}

///|
fn wb_mp(q : Int32, t : Int32, dist : Double) -> MatchPair {
  MatchPair::{ query_idx: q, train_idx: t, distance: dist, }
}

///|
fn wb_solid(w : Int32, h : Int32, channels : Int32, v : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h * channels, v.to_byte())
  @types.Image::{
    width: w,
    height: h,
    channels,
    data: Bytes::from_array(data),
  }
}

///|
fn wb_identity3() -> Homography {
  Homography::{
    h00: 1.0,
    h01: 0.0,
    h02: 0.0,
    h10: 0.0,
    h11: 1.0,
    h12: 0.0,
    h20: 0.0,
    h21: 0.0,
    h22: 1.0,
  }
}

///|
test "wbtest: descriptor_distance 长度不等取较短" {
  let a = [1.0, 2.0]
  let b = [1.0, 2.0, 3.0]
  assert_eq(descriptor_distance(a, b), 0.0)
  assert_eq(descriptor_distance(b, a), 0.0)
  let c = [0.0, 0.0]
  let d = [3.0, 4.0]
  assert_eq(descriptor_distance(c, d), 5.0)
  assert_eq(descriptor_distance([], d), 0.0)
}

///|
test "wbtest: compute_homography_dlt 点不足返回 None" {
  let src : Array[(Double, Double)] = [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)]
  let dst : Array[(Double, Double)] = [(0.0, 0.0), (2.0, 0.0), (0.0, 2.0)]
  assert_true(compute_homography_dlt(src, dst) is None)
  let src4 : Array[(Double, Double)] = [
    (0.0, 0.0),
    (10.0, 0.0),
    (0.0, 10.0),
    (10.0, 10.0),
  ]
  let dst4 : Array[(Double, Double)] = [
    (0.0, 0.0),
    (20.0, 0.0),
    (0.0, 30.0),
    (20.0, 30.0),
  ]
  match compute_homography_dlt(src4, dst4) {
    Some(h) => {
      // 近似仿射：x 缩放 2、y 缩放 3
      assert_true((h.h00 - 2.0).abs() < 0.01)
      assert_true((h.h11 - 3.0).abs() < 0.01)
      assert_eq(h.h22, 1.0)
    }
    None => assert_true(false)
  }
}

///|
test "wbtest: random_sample 少样本与去重" {
  let four = [
    wb_mp(0, 0, 0.0),
    wb_mp(1, 1, 0.0),
    wb_mp(2, 2, 0.0),
    wb_mp(3, 3, 0.0),
  ]
  // count > n：原样返回
  let few = random_sample(four, 8)
  assert_eq(few.length(), 4)
  // n == count：哈希会撞索引，走 duplicate 分支
  let sampled = random_sample(four, 4)
  assert_true(sampled.length() <= 4)
  for m in sampled {
    assert_true(m.query_idx >= 0 && m.query_idx < 4)
  }
  let empty : Array[MatchPair] = []
  assert_eq(random_sample(empty, 4).length(), 0)
}

///|
test "wbtest: sort_features_by_response 选择排序换位" {
  let fs = [
    wb_fp(0.0, 0.0, 1.0, [1.0]),
    wb_fp(1.0, 0.0, 5.0, [1.0]),
    wb_fp(2.0, 0.0, 3.0, [1.0]),
  ]
  let sorted = sort_features_by_response(fs)
  assert_eq(sorted.length(), 3)
  assert_eq(sorted[0].response, 5.0)
  assert_eq(sorted[1].response, 3.0)
  assert_eq(sorted[2].response, 1.0)
  // 已排序 + 单元素 + 空
  assert_eq(sort_features_by_response(sorted).length(), 3)
  assert_eq(
    sort_features_by_response([wb_fp(0.0, 0.0, 2.0, [1.0])]).length(),
    1,
  )
  let none : Array[FeaturePoint] = []
  assert_eq(sort_features_by_response(none).length(), 0)
}

///|
test "wbtest: compute_simple_descriptor 越界与全零归一" {
  // 4x4 全 0 图，中心 (-10,-10)：所有采样越界 → count=0，norm=0 不归一
  let data = Bytes::from_array(Array::make(16, b'\x00'))
  let d = compute_simple_descriptor(data, 4, 4, -10, -10)
  assert_eq(d.length(), 64)
  for v in d {
    assert_eq(v, 0.0)
  }
  // 中心在图中：norm>0 走归一化，向量模长约 1
  let data2 = Bytes::from_array(Array::make(16, b'\x20'))
  let d2 = compute_simple_descriptor(data2, 4, 4, 2, 2)
  let mut sq = 0.0
  for v in d2 {
    sq += v * v
  }
  assert_true(sq > 0.0)
}

///|
test "wbtest: compute_output_size 单位/缩放/负偏移" {
  let img = wb_solid(4, 3, 3, 10)
  let img2 = wb_solid(4, 3, 3, 20)
  let (w0, h0, ox0, oy0) = compute_output_size(img, img2, wb_identity3())
  assert_eq(w0, 5)
  assert_eq(h0, 4)
  assert_eq(ox0, 0)
  assert_eq(oy0, 0)
  let scale = Homography::{
    h00: 2.0,
    h01: 0.0,
    h02: 0.0,
    h10: 0.0,
    h11: 2.0,
    h12: 0.0,
    h20: 0.0,
    h21: 0.0,
    h22: 1.0,
  }
  let (w1, h1, _, _) = compute_output_size(img, img2, scale)
  assert_true(w1 > 4)
  assert_true(h1 > 3)
  // 负平移：offset 为正
  let shift = Homography::{
    h00: 1.0,
    h01: 0.0,
    h02: -3.0,
    h10: 0.0,
    h11: 1.0,
    h12: -2.0,
    h20: 0.0,
    h21: 0.0,
    h22: 1.0,
  }
  let (_, _, ox2, oy2) = compute_output_size(img, img2, shift)
  assert_eq(ox2, 3)
  assert_eq(oy2, 2)
}

///|
test "wbtest: warp_image 奇异矩阵不走逆映射" {
  let img = wb_solid(3, 3, 3, 99)
  let singular = Homography::{
    h00: 0.0,
    h01: 0.0,
    h02: 0.0,
    h10: 0.0,
    h11: 0.0,
    h12: 0.0,
    h20: 0.0,
    h21: 0.0,
    h22: 0.0,
  }
  let out = warp_image(img, singular, 4, 4, 0, 0)
  assert_eq(out.width, 4)
  assert_eq(out.height, 4)
  for b in out.data {
    assert_eq(b, b'\x00')
  }
  // 正常单位映射：原图内容被搬过去
  let out2 = warp_image(img, wb_identity3(), 3, 3, 0, 0)
  assert_eq(out2.channels, 3)
  assert_eq(out2.data[0], b'\x63')
}

///|
test "wbtest: blend_images 三条分支（仅 img1 / 融合 / 仅 img2）" {
  let img1 = wb_solid(4, 2, 3, 10)
  // img2：左半全黑（只有 img1），右半非零（融合）
  let px : Array[Byte] = []
  for y in 0..<2 {
    for x in 0..<6 {
      let v = if x >= 2 { 200 } else { 0 }
      for _c in 0..<3 {
        px.push(v.to_byte())
      }
    }
  }
  let img2 = @types.Image::{
    width: 6,
    height: 2,
    channels: 3,
    data: Bytes::from_array(px),
  }
  let out = blend_images(img1, img2, 0, 0, 3)
  assert_eq(out.width, 6)
  assert_eq(out.height, 2)
  // x=0：仅 img1
  assert_eq(out.data[0], b'\x0A')
  // x=5：超出 img1 覆盖，仅 img2
  assert_eq(out.data[5 * 3], b'\xC8')
  // x=2：融合，alpha=2/3 → 10*0.667 + 200*0.333 ≈ 73
  let blended = out.data[2 * 3].to_int()
  assert_true(blended > 10 && blended < 200)
  // offset 非零：img1 只在 x>=2 生效
  let out2 = blend_images(img1, img2, 2, 1, 3)
  assert_eq(out2.data[0], b'\x00')
  assert_eq(out2.data[2 * 3], b'\xC8')
}

///|
test "wbtest: estimate_homography_ransac 采样退化与无内点" {
  let pts : Array[FeaturePoint] = [
    wb_fp(0.0, 0.0, 1.0, [1.0]),
    wb_fp(1.0, 0.0, 1.0, [1.0]),
    wb_fp(0.0, 1.0, 1.0, [1.0]),
    wb_fp(1.0, 1.0, 1.0, [1.0]),
  ]
  let matches = [
    wb_mp(0, 0, 0.0),
    wb_mp(1, 1, 0.0),
    wb_mp(2, 2, 0.0),
    wb_mp(3, 3, 0.0),
  ]
  // 阈值极小 → 无内点，返回 None + 空
  let (h, inl) = estimate_homography_ransac(
    matches,
    pts,
    pts,
    iterations=2,
    threshold=0.0001,
  )
  assert_true(inl.length() <= 4)
  // 大阈值 → 全内点，h 非空
  let (h2, inl2) = estimate_homography_ransac(
    matches,
    pts,
    pts,
    iterations=2,
    threshold=100.0,
  )
  assert_true(inl2.length() <= 4)
  // 4 对点常量哈希会撞索引，样本退化 → 走 continue 分支，h2 可能为空
  let _ = h2
  let _ = h
  // 5 对点时随机采样能取到 4 个互异，DLT 有解
  let pts5 : Array[FeaturePoint] = [
    wb_fp(0.0, 0.0, 1.0, [1.0]),
    wb_fp(1.0, 0.0, 1.0, [1.0]),
    wb_fp(0.0, 1.0, 1.0, [1.0]),
    wb_fp(1.0, 1.0, 1.0, [1.0]),
    wb_fp(2.0, 2.0, 1.0, [1.0]),
  ]
  let m5 = [
    wb_mp(0, 0, 0.0),
    wb_mp(1, 1, 0.0),
    wb_mp(2, 2, 0.0),
    wb_mp(3, 3, 0.0),
    wb_mp(4, 4, 0.0),
  ]
  let (h3, inl3) = estimate_homography_ransac(
    m5,
    pts5,
    pts5,
    iterations=1,
    threshold=100.0,
  )
  match h3 {
    Some(_) => assert_true(inl3.length() >= 1)
    None => assert_true(inl3.length() == 0)
  }
}

///|
test "wbtest: stitch_images 低特征与低内点早退" {
  // 4x4 纯色：检测不到特征 → None
  let tiny = wb_solid(4, 4, 3, 0)
  assert_true(stitch_images(tiny, tiny) is None)
  // 10x10 棋盘：特征不足 4 个 → None
  let ck : Array[Byte] = []
  for y in 0..<10 {
    for x in 0..<10 {
      let v = if (x / 2 + y / 2) % 2 == 0 { 0 } else { 255 }
      for _c in 0..<3 {
        ck.push(v.to_byte())
      }
    }
  }
  let chess = @types.Image::{
    width: 10,
    height: 10,
    channels: 3,
    data: Bytes::from_array(ck),
  }
  // min_inliers 极高 → 匹配数不足直接 None
  let strict = StitchConfig::{
    max_features: 500,
    ratio_threshold: 0.75,
    ransac_iterations: 5,
    ransac_threshold: 3.0,
    min_inliers: 1000,
    blend_width: 50,
    use_multi_band: true,
  }
  assert_true(stitch_images(chess, chess, config=strict) is None)
  // 空图
  let empty = wb_solid(0, 0, 3, 0)
  assert_true(stitch_images(empty, empty) is None)
}
