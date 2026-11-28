// JPEG 色度上采样（libjpeg fancy upsampling 移植）测试
// 覆盖：h2v1 / h2v2 的逐点数值与 libjpeg 公式一致、边界钳制、未知比例回退最近邻

///|
test "upsample: clamp helper" {
  assert_eq(jpeg_clamp_i32(-3, 0, 5), 0)
  assert_eq(jpeg_clamp_i32(9, 0, 5), 5)
  assert_eq(jpeg_clamp_i32(3, 0, 5), 3)
}

///|
test "upsample: h2v1 fancy matches libjpeg arithmetic" {
  // plane = [10, 20]（1 行 2 列）→ 放大到 4 列
  // 偶数列 (3·this + last + 2) >> 2、奇数列 (3·this + next + 1) >> 2，首尾复制钳制
  let plane : Array[Int32] = [10, 20]
  let (out, uw, uh) = jpeg_fancy_h2v1(plane, 2, 2, 1)
  assert_eq(uw, 4)
  assert_eq(uh, 1)
  assert_eq(out[0], 10) // (3·10 + 10 + 2) >> 2 = 42 >> 2
  assert_eq(out[1], 12) // (3·10 + 20 + 1) >> 2 = 51 >> 2
  assert_eq(out[2], 18) // (3·20 + 10 + 2) >> 2 = 72 >> 2
  assert_eq(out[3], 20) // (3·20 + 20 + 1) >> 2 = 81 >> 2
}

///|
test "upsample: h2v2 fancy matches libjpeg arithmetic" {
  // 2×2 → 4×4，权重 9/16、3/16、3/16、1/16
  let plane : Array[Int32] = [10, 20, 30, 40]
  let (out, uw, uh) = jpeg_fancy_h2v2(plane, 2, 2, 2)
  assert_eq(uw, 4)
  assert_eq(uh, 4)
  let expect : Array[Int32] = [
    10, 12, 18, 20, 15, 17, 23, 25, 25, 27, 33, 35, 30, 32, 38, 40,
  ]
  for i in 0..<16 {
    assert_eq(out[i], expect[i])
  }
}

///|
test "upsample: h2v2 keeps a constant plane constant" {
  // 平坦色度（全 128）上采样后仍是 128，不引入振铃
  let plane : Array[Int32] = [128, 128, 128, 128, 128, 128, 128, 128, 128]
  let (out, uw, uh) = jpeg_fancy_h2v2(plane, 3, 3, 3)
  assert_eq(uw, 6)
  assert_eq(uh, 6)
  for i in 0..<36 {
    assert_eq(out[i], 128)
  }
}

///|
test "upsample: ramp stays monotonic within each row through h2v2" {
  // 单调斜坡（0,10,…,80）上采样后每行内仍单调不减，不出现过冲
  let plane : Array[Int32] = [0, 10, 20, 30, 40, 50, 60, 70, 80]
  let (out, uw, uh) = jpeg_fancy_h2v2(plane, 3, 3, 3)
  assert_eq(uw, 6)
  assert_eq(uh, 6)
  for row in 0..<uh {
    let mut prev = out[row * uw]
    for col in 1..<uw {
      assert_true(out[row * uw + col] >= prev)
      prev = out[row * uw + col]
    }
  }
  assert_eq(out[0], 0)
  assert_eq(out[35], 80)
}

///|
test "upsample: plane dispatch picks fancy only for 2x subsampling" {
  let plane : Array[Int32] = [1, 2, 3, 4]
  // 2×2 → 三角滤波，宽高各翻倍
  let (a, aw, ah, aup) = jpeg_upsample_plane(plane, 2, 2, 2, 2, 2)
  assert_true(aup)
  assert_eq(aw, 4)
  assert_eq(ah, 4)
  // 2×1 → 只翻宽
  let (b, bw, bh, bup) = jpeg_upsample_plane(plane, 2, 2, 2, 2, 1)
  assert_true(bup)
  assert_eq(bw, 4)
  assert_eq(bh, 2)
  // 1×1（整分辨）→ 原样返回，行跨距保持调用方给的 stride
  let (c, cw, ch, cup) = jpeg_upsample_plane(plane, 4, 2, 2, 1, 1)
  assert_true(!cup)
  assert_eq(cw, 4)
  assert_eq(ch, 2)
  assert_eq(c.length(), 4)
}
