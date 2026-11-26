// 白盒：VP8 纯函数分支（IDCT / WHT / 帧内预测 / 滤波 / 插值）

///|
fn vpw_arr(n : Int32, v : Int32) -> Array[Int32] {
  Array::make(n, v)
}

///|
fn vpw_16() -> Array[Int32] {
  vpw_arr(16, 100)
}

///|
test "vpw: IDCT 与 WHT 直流/全零" {
  // 全零 → 全零
  let z = vp8_idct_4x4(vpw_arr(16, 0))
  for v in z {
    assert_eq(v, 0)
  }
  // 仅 DC=64：行变换后每行 a0=64 → b0=64*85627*2, (b0)>>17 = 64*2/2? 检查对称性
  let dc = vp8_idct_4x4([64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  assert_eq(dc[0], dc[15])
  assert_eq(dc[0], dc[3])
  // WHT 全零
  let wz = vp8_wht_4x4(vpw_arr(16, 0))
  for v in wz {
    assert_eq(v, 0)
  }
  // WHT 全 1：行 b0=2,b1=0,b2=2,b3=0 → 行结果为 [4,0,0,4]…列再变换
  let w1 = vp8_wht_4x4(vpw_arr(16, 1))
  assert_true(w1[0] > 0)
  // 常量 100 经 WHT：DC 项放大
  let wc = vp8_wht_4x4(vpw_arr(16, 100))
  assert_eq(wc[0], 800)
}

///|
test "vpw: I16x16 四种预测模式" {
  let above = vpw_arr(16, 128)
  let left = vpw_arr(16, 128)
  let dc = vp8_intra_predict_16x16(I16x16DcPred, above, left, 10)
  assert_eq(dc.length(), 256)
  // (2*10 + 32*128 + 16) >> 5 = (20 + 4096 + 16) >> 5 = 129
  assert_eq(dc[0], 129)
  assert_eq(dc[255], 129)
  let tm = vp8_intra_predict_16x16(I16x16TrueMotionPred, above, left, 10)
  // x=0,y=0: (128+128+10 + 1) / 2 = 133
  assert_eq(tm[0], 133)
  // x=1,y=0: (256+128+10 + 1)/3 = 131
  assert_eq(tm[1], 131)
  let hp = vp8_intra_predict_16x16(I16x16HPred, above, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], 0)
  assert_eq(hp[0], 1)
  assert_eq(hp[15], 1)
  assert_eq(hp[16], 2)
  let vp = vp8_intra_predict_16x16(I16x16VPred, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], left, 0)
  assert_eq(vp[0], 1)
  assert_eq(vp[15], 16)
  assert_eq(vp[16], 1)
}

///|
test "vpw: I4x4 十种预测模式" {
  let above8 = [10, 20, 30, 40, 50, 60, 70, 80]
  let left8 = [11, 21, 31, 41, 51, 61, 71, 81]
  // DC
  let dc = _vp8_intra_predict_4x4(I4x4DcPred, above8, left8, 0)
  let sum = 10 + 20 + 30 + 40 + 11 + 21 + 31 + 41
  assert_eq(dc[0], (sum + 4) >> 3)
  assert_eq(dc[0], dc[15])
  // TrueMotion：夹取上下界
  let tm = _vp8_intra_predict_4x4(I4x4TrueMotionPred, vpw_arr(8, 10), vpw_arr(8, 10), 100)
  assert_eq(tm[0], 0)
  let tm2 = _vp8_intra_predict_4x4(I4x4TrueMotionPred, vpw_arr(8, 200), vpw_arr(8, 200), 100)
  assert_eq(tm2[0], 255)
  let tm3 = _vp8_intra_predict_4x4(I4x4TrueMotionPred, above8, left8, 5)
  // x=0,y=0: 10+11-5=16
  assert_eq(tm3[0], 16)
  // H / V
  let hp = _vp8_intra_predict_4x4(I4x4HPred, above8, left8, 0)
  assert_eq(hp[0], 11)
  assert_eq(hp[4], 21)
  let vp = _vp8_intra_predict_4x4(I4x4VPred, above8, left8, 0)
  assert_eq(vp[0], 10)
  assert_eq(vp[3], 40)
  // LeftDown：idx<=6 与 idx==7
  let ld = _vp8_intra_predict_4x4(I4x4LeftDownPred, above8, left8, 0)
  assert_eq(ld[0], (10 + 20 + 1) >> 1)
  assert_eq(ld[15], 75)
  // RightDown：x>=y 与 x<y 两支
  let rd = _vp8_intra_predict_4x4(I4x4RightDownPred, above8, left8, 0)
  assert_eq(rd[0], (10 + 20 + 1) >> 1)
  assert_eq(rd[4], (11 + 21 + 1) >> 1) // y=1,x=0 → left[0],left[1]
  // RightUp / LeftUp
  let ru = _vp8_intra_predict_4x4(I4x4RightUpPred, above8, left8, 0)
  assert_eq(ru[0], (10 + 20 + 11 + 1) >> 2)
  let lu = _vp8_intra_predict_4x4(I4x4LeftUpPred, above8, left8, 0)
  assert_eq(lu[0], (11 + 21 + 10 + 1) >> 2)
  // VertRight：y==0 与 y>0
  let vr = _vp8_intra_predict_4x4(I4x4VertRightPred, above8, left8, 0)
  assert_eq(vr[0], (10 + 20 + 1) >> 1)
  assert_eq(vr[4], (10 + 11 + 1) >> 1)
  // HorizDown：x==0 与 x>0
  let hd = _vp8_intra_predict_4x4(I4x4HorizDownPred, above8, left8, 0)
  assert_eq(hd[0], (11 + 21 + 1) >> 1)
  assert_eq(hd[1], (11 + 10 + 1) >> 1)
}

///|
test "vpw: 环路滤波级别计算与夹取" {
  let params = Vp8LoopFilterParams::{
    filter_level: 10,
    _inner_filter_level: 4,
    _sharpness_level: 0,
    segment_deltas: [2, 0, -5, 3],
    mode_ref_deltas: [-3, 5, 0, 0],
  }
  assert_eq(_vp8_calc_filter_level(params, 0, true), 9)
  assert_eq(_vp8_calc_filter_level(params, 2, false), 10 - 5 + 5)
  assert_eq(_vp8_calc_filter_level(params, -1, true), 7)
  assert_eq(_vp8_calc_filter_level(params, 4, false), 15)
  let neg = Vp8LoopFilterParams::{
    filter_level: 1,
    _inner_filter_level: 0,
    _sharpness_level: 0,
    segment_deltas: [-5, 0, 0, 0],
    mode_ref_deltas: [-5, 0, 0, 0],
  }
  assert_eq(_vp8_calc_filter_level(neg, 0, true), 0)
  let big = Vp8LoopFilterParams::{
    filter_level: 63,
    _inner_filter_level: 0,
    _sharpness_level: 0,
    segment_deltas: [3, 0, 0, 0],
    mode_ref_deltas: [3, 0, 0, 0],
  }
  assert_eq(_vp8_calc_filter_level(big, 0, true), 63)
}

///|
test "vpw: 垂直/水平 4 像素滤波三分支" {
  // 垂直：x<=0 直接返回
  let p0 = vpw_arr(16, 100)
  vp8_filter_vertical_4(p0, 0, 1, 4, 10, 5)
  assert_eq(p0[0], 100)
  // 阈值跳过：p0/q0 差极大
  let p1 = [50, 50, 0, 200, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50]
  vp8_filter_vertical_4(p1, 2, 1, 4, 1, 0)
  assert_eq(p1[2], 0)
  // 正常滤波：p1,p0=50 / q0,q1=50 → 全 50 不变；改成 40/60
  let p2 = [40, 50, 60, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  vp8_filter_vertical_4(p2, 2, 0, 4, 20, 15)
  // filter_val = (40 + 2*50 + 2*60 + 50 + 4)/8 = 314/8 = 39
  assert_eq(p2[1], 39)
  assert_eq(p2[2], 39)
  // inner_level>0：p1 与 p0_new 平均
  assert_true(p2[0] <= 40)
  // 水平：y<=0 直接返回
  let h0 = vpw_arr(16, 100)
  vp8_filter_horizontal_4(h0, 1, 0, 4, 10, 5)
  assert_eq(h0[0], 100)
  // 水平阈值跳过
  let h1 = [0, 0, 0, 0, 50, 50, 50, 50, 0, 200, 0, 0, 50, 50, 50, 50]
  vp8_filter_horizontal_4(h1, 1, 2, 4, 1, 0)
  assert_eq(h1[9], 200)
  // 水平正常滤波：行 0/2 为 40/60，行 1/3 为 50/50
  let h2 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  for x in 0..<4 {
    h2[x] = 40
    h2[4 + x] = 50
    h2[8 + x] = 60
    h2[12 + x] = 50
  }
  vp8_filter_horizontal_4(h2, 1, 2, 4, 20, 15)
  assert_eq(h2[5], 39)
  assert_eq(h2[9], 39)
  assert_true(h2[1] <= 40)
}

///|
test "vpw: 6 抽头插值三种夹取" {
  // 常量 100：sum=3200 → (3232)>>6 = 50
  assert_eq(vp8_interpolate_6tap(100, 100, 100, 100, 100, 100), 50)
  // 全 0 → 0
  assert_eq(vp8_interpolate_6tap(0, 0, 0, 0, 0, 0), 0)
  // 全 255：sum=255*31=7905 → (7937)>>6=124？实际未超 255
  let hi = vp8_interpolate_6tap(255, 255, 255, 255, 255, 255)
  assert_eq(hi, 128)
  // 大正权重 → 超 255 被截
  let over = vp8_interpolate_6tap(0, 0, 255, 255, 0, 0)
  assert_eq(over, 159)
  // 负值被截到 0
  let under = vp8_interpolate_6tap(255, 255, 0, 0, 255, 255)
  assert_eq(under, 0)
}

///|
test "vpw: get_ref_pixel 边界钳制" {
  let plane : Array[Int32] = []
  for i in 0..<16 {
    plane.push(i)
  }
  assert_eq(vp8_get_ref_pixel(plane, 2, 1, 4, 4), 6)
  assert_eq(vp8_get_ref_pixel(plane, -3, 0, 4, 4), 0)
  assert_eq(vp8_get_ref_pixel(plane, 7, 0, 4, 4), 3)
  assert_eq(vp8_get_ref_pixel(plane, 0, -1, 4, 4), 0)
  assert_eq(vp8_get_ref_pixel(plane, 0, 9, 4, 4), 12)
}

///|
test "vpw: 亚像素插值四条路径" {
  // 8×8 渐变平面
  let plane : Array[Int32] = []
  for i in 0..<64 {
    plane.push((i % 8) * 20 + (i / 8) * 10)
  }
  // 整数像素
  assert_eq(vp8_interpolate_subpixel(plane, 0, 0, 0, 0, 8, 8), plane[0])
  assert_eq(vp8_interpolate_subpixel(plane, 2, 2, 0, 0, 8, 8), plane[2 * 8 + 2])
  // 仅水平偏移（frac_x=1, frac_y=0）
  let hx = vp8_interpolate_subpixel(plane, 1, 1, 1, 0, 8, 8)
  assert_true(hx >= 0 && hx <= 255)
  // 仅垂直偏移（frac_x=0, frac_y=1）
  let vy = vp8_interpolate_subpixel(plane, 1, 1, 0, 1, 8, 8)
  assert_true(vy >= 0 && vy <= 255)
  // 半像素偏移（frac_x=2, frac_y=0）走 6 抽头
  let half = vp8_interpolate_subpixel(plane, 1, 1, 2, 0, 8, 8)
  assert_true(half >= 0 && half <= 255)
  // 双向偏移（frac_x=1, frac_y=1）走四角双线性
  let both = vp8_interpolate_subpixel(plane, 2, 2, 1, 1, 8, 8)
  assert_true(both >= 0 && both <= 255)
  // 负偏移（int 部分为负）触发边界钳制
  let neg = vp8_interpolate_subpixel(plane, 0, 0, -4, -4, 8, 8)
  assert_true(neg >= 0)
}
