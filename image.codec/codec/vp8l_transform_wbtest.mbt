// 白盒测试：VP8L 逆变换（predictor / cross-color / color indexing / 像素辅助）
// White-box tests for VP8L inverse transforms.

///|
fn vp8t_argb(a : Int32, r : Int32, g : Int32, b : Int32) -> Int32 {
  (a << 24) | (r << 16) | (g << 8) | b
}

test "vp8t: 像素辅助函数" {
  assert_eq(vp8l_c1(vp8t_argb(0x11, 0x22, 0x33, 0x44), 24), 0x11)
  assert_eq(vp8l_c1(vp8t_argb(0x11, 0x22, 0x33, 0x44), 16), 0x22)
  assert_eq(vp8l_c1(vp8t_argb(0x11, 0x22, 0x33, 0x44), 8), 0x33)
  assert_eq(vp8l_c1(vp8t_argb(0x11, 0x22, 0x33, 0x44), 0), 0x44)
  // 逐通道取平均（向下取整）
  let avg = vp8l_avg2(vp8t_argb(0x10, 0x20, 0x30, 0x40), vp8t_argb(0x30, 0x40, 0x50, 0x60))
  assert_eq(avg, vp8t_argb(0x20, 0x30, 0x40, 0x50))
  // 奇数相加向下取整
  assert_eq(vp8l_avg2(0x01, 0x02), 0x01)
  // clamp
  assert_eq(vp8l_clamp8(-7), 0)
  assert_eq(vp8l_clamp8(300), 255)
  assert_eq(vp8l_clamp8(128), 128)
  // a + b - c
  let full = vp8l_clamp_add_full(
    vp8t_argb(0x10, 0x20, 0x30, 0x40), vp8t_argb(0x20, 0x40, 0x60, 0x80),
    vp8t_argb(0x10, 0x10, 0x10, 0x10),
  )
  assert_eq(full, vp8t_argb(0x20, 0x50, 0x80, 0xB0))
  // 低通道相减为负 → 夹到 0
  let neg = vp8l_clamp_add_full(0x00000001, 0x00000001, 0x00000005)
  assert_eq(neg, 0x00000000)
  // 高位溢出 → 255
  let over = vp8l_clamp_add_full(0xFF000001, 0xFF000001, 0x00000001)
  assert_eq(over, 0xFF000001)
  // a + (a - b) / 2
  let half = vp8l_clamp_add_half(0x0A, 0x14)
  assert_eq(half, 0x05)
  let half2 = vp8l_clamp_add_half(0x14, 0x0A)
  assert_eq(half2, 0x19)
  let half3 = vp8l_clamp_add_half(0x00, 0xF0)
  assert_eq(half3, 0x00)
  assert_eq(vp8l_abs32(-5), 5)
  assert_eq(vp8l_abs32(5), 5)
  assert_eq(vp8l_abs32(0), 0)
  assert_eq(vp8l_div_round_up(7, 4), 2)
  assert_eq(vp8l_div_round_up(8, 4), 2)
  assert_eq(vp8l_div_round_up(0, 4), 0)
}

test "vp8t: 色彩缓存哈希与 cross-color" {
  // 哈希取无符号 32 位乘法的高 bits 位，结果必落在 [0, 2^bits)
  for bits in [1, 2, 3, 4] {
    let h = vp8l_cache_hash(0x1E35A7BD, bits)
    assert_true(h >= 0)
    assert_true(h < (1 << bits))
  }
  assert_eq(vp8l_cache_hash(0, 4), 0)
  // color_delta：两个通道都按有符号处理
  assert_eq(vp8l_color_delta(100, 100), 312)
  assert_eq(vp8l_color_delta(200, 100), -175)
  assert_eq(vp8l_color_delta(8, 8), 2)
  assert_eq(vp8l_color_delta(0, 0), 0)
  assert_eq(vp8l_color_delta(200, 200), 98)
  // 正负抵消
  assert_eq(vp8l_color_delta(200, 56), -98)
}

test "vp8t: Select 预测器距离比较" {
  // p = l + t - tl 后比较谁更近
  let l = vp8t_argb(0x10, 0x20, 0x30, 0x40)
  let t = vp8t_argb(0x20, 0x40, 0x60, 0x80)
  let tl = vp8t_argb(0x15, 0x25, 0x35, 0x45)
  assert_eq(vp8l_select(l, t, tl), t)
  // t == tl → p == l → 选 l
  let tl2 = t
  assert_eq(vp8l_select(l, t, tl2), l)
  // 完全相同 → dist 相等 → 取 t
  assert_eq(vp8l_select(l, l, l), l)
}

test "vp8t: predictor 逆变换全模式" {
  // 4x4 单块（block_bits=2）逐模式跑一遍，覆盖 match 全分支
  for mode in 0..<14 {
    let w = 4
    let h = 4
    let px : Array[Int32] = Array::make(w * h, 0)
    // 首行/首列给非零残差，保证各模式计算路径都被走到
    for x in 0..<w {
      px[x] = vp8t_argb(0xFF, 0x10, 0x20, 0x30)
    }
    for y in 0..<h {
      px[y * w] = vp8t_argb(0xFF, 0x40, 0x50, 0x60)
    }
    let modes : Array[Int32] = [mode << 8]
    vp8l_inverse_predictor(px, w, h, modes, 2, 1)
    assert_true(px.length() == w * h)
    // 输出必须仍是 4 字节打包像素
    assert_true(px.length() == w * h)
  }
  // 空模式表 → 走默认 mode 0（不透明黑）
  let w = 4
  let h = 4
  let px2 : Array[Int32] = Array::make(w * h, vp8t_argb(0, 0x11, 0x22, 0x33))
  let empty : Array[Int32] = []
  vp8l_inverse_predictor(px2, w, h, empty, 2, 1)
  assert_eq(px2[0], vp8t_argb(0xFF, 0x11, 0x22, 0x33))
  // 非 4 的整数倍宽：覆盖 topright 回退到同行最左的分支
  let w3 = 5
  let h3 = 3
  let px3 : Array[Int32] = Array::make(w3 * h3, vp8t_argb(0, 1, 2, 3))
  let modes3 : Array[Int32] = [3 << 8]
  vp8l_inverse_predictor(px3, w3, h3, modes3, 1, 2)
  assert_true(px3.length() == w3 * h3)
}

test "vp8t: cross-color 逆变换" {
  // e = green_to_red 100 | green_to_blue 50 << 8 | red_to_blue 8 << 16
  let e : Int32 = 100 | (50 << 8) | (8 << 16)
  let cte : Array[Int32] = [e]
  let px : Array[Int32] = [vp8t_argb(0xFF, 10, 100, 20)]
  vp8l_inverse_color_transform(px, 1, 1, cte, 0, 1)
  // r = (10 + 312) & 0xFF = 66；b = 20 + 156 + 16 = 192
  assert_eq(px[0], vp8t_argb(0xFF, 66, 100, 192))
  // 空 cte：mi 越界直接 continue，不修改像素
  let px2 : Array[Int32] = [vp8t_argb(0xFF, 10, 100, 20)]
  let empty : Array[Int32] = []
  vp8l_inverse_color_transform(px2, 1, 1, empty, 0, 1)
  assert_eq(px2[0], vp8t_argb(0xFF, 10, 100, 20))
  // 多块：两个 4x4 块共用一张表
  let px3 : Array[Int32] = Array::make(8 * 4, vp8t_argb(0xFF, 0, 0, 0))
  let cte3 : Array[Int32] = [0, e]
  vp8l_inverse_color_transform(px3, 8, 4, cte3, 2, 2)
  assert_true(px3.length() == 32)
}

test "vp8t: color indexing 未打包与打包" {
  let pal : Array[Int32] = [vp8t_argb(0xFF, 1, 2, 3), vp8t_argb(0xFF, 4, 5, 6)]
  // 未打包：索引取 green 通道
  let px : Array[Int32] = [
    vp8t_argb(0, 0, 0, 0),
    vp8t_argb(0, 0, 1, 0),
    vp8t_argb(0, 0, 9, 0),
  ]
  let (out0, w0) = vp8l_inverse_color_indexing(px, 3, 1, pal, 0, 3)
  assert_eq(w0, 3)
  assert_eq(out0[0], pal[0])
  assert_eq(out0[1], pal[1])
  assert_eq(out0[2], 0)
}

test "vp8t: color indexing 打包展开" {
  let pal : Array[Int32] = [
    vp8t_argb(0xFF, 0, 0, 0),
    vp8t_argb(0xFF, 0x10, 0x11, 0x12),
    vp8t_argb(0xFF, 0x20, 0x21, 0x22),
    vp8t_argb(0xFF, 0x30, 0x31, 0x32),
  ]
  // width_bits=1：一个字节装 2 个 4 位索引
  let px : Array[Int32] = [vp8t_argb(0, 0, 0x12, 0)]
  let (o1, w1) = vp8l_inverse_color_indexing(px, 1, 1, pal, 1, 2)
  assert_eq(w1, 2)
  assert_eq(o1[0], pal[2])
  assert_eq(o1[1], pal[1])
  // width_bits=2：一个字节装 4 个 2 位索引
  let px2 : Array[Int32] = [vp8t_argb(0, 0, 0xE4, 0)]
  let (o2, w2) = vp8l_inverse_color_indexing(px2, 1, 1, pal, 2, 4)
  assert_eq(w2, 4)
  assert_eq(o2[0], pal[0])
  assert_eq(o2[1], pal[1])
  assert_eq(o2[2], pal[2])
  assert_eq(o2[3], pal[3])
  // width_bits=3：一个字节装 8 个 1 位索引（0b10101010 → 0,1,0,1,...）
  let px3 : Array[Int32] = [vp8t_argb(0, 0, 0xAA, 0)]
  let (o3, w3) = vp8l_inverse_color_indexing(px3, 1, 1, pal, 3, 8)
  assert_eq(w3, 8)
  assert_eq(o3[0], pal[0])
  assert_eq(o3[1], pal[1])
  assert_eq(o3[2], pal[0])
  assert_eq(o3[7], pal[1])
  // 最后一组槽数可能不足：4 像素图 width_bits=3
  let px4 : Array[Int32] = [vp8t_argb(0, 0, 0x0F, 0)]
  let (o4, w4) = vp8l_inverse_color_indexing(px4, 1, 1, pal, 3, 4)
  assert_eq(w4, 4)
  // 0x0F：j=0..3 位为 1 → 前 4 个槽取索引 1，其余取索引 0
  assert_eq(o4[0], pal[1])
  assert_eq(o4[3], pal[1])
}
