// 白盒测试：VP8 环路滤波 / 参考帧 / 运动补偿 / Golomb / 帧解码错误路径
// White-box tests for loop filter, reference frames, motion compensation, Golomb and decode errors.

///|
fn vp8b_bytes(vals : Array[Int32]) -> Bytes {
  let out : Array[Byte] = []
  for v in vals {
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

///|
fn vp8b_ref_id(f : Vp8RefFrame) -> Int32 {
  match f {
    Vp8RefFrame::RefLast => 0
    Vp8RefFrame::RefGolden => 1
    Vp8RefFrame::RefAltref => 2
  }
}

///|
fn vp8b_mv(x : Int32, y : Int32) -> Vp8MotionVector {
  let mv = Vp8MotionVector::new()
  mv.mv_x = x
  mv.mv_y = y
  mv
}

///|
test "vp8b: 环路滤波宏块入口" {
  let w = 32
  let h = 32
  let y : Array[Int32] = Array::make(w * h, 100)
  let u : Array[Int32] = Array::make(16 * 16, 100)
  let v : Array[Int32] = Array::make(16 * 16, 100)
  // filter_level = 0 直接返回，像素不变
  vp8_loop_filter_mb(y, u, v, 1, 1, w, h, 0)
  for px in y {
    assert_eq(px, 100)
  }
  // 非零强度：滤波会就地改动像素，取值必须仍在合法范围
  let y2 : Array[Int32] = Array::make(w * h, 100)
  vp8_loop_filter_mb(y2, u, v, 1, 1, w, h, 8)
  assert_true(y2.length() == w * h)
  for px in y2 {
    assert_true(px >= 0)
    assert_true(px <= 255)
  }
}

///|
test "vp8b: 参考帧初始化与更新" {
  let refs = Vp8ReferenceFrames::new(16, 16)
  assert_eq(refs.width, 16)
  assert_eq(refs.height, 16)
  assert_true(refs.last_y.length() == 256)
  assert_true(refs.last_u.length() == 64)
  assert_eq(refs.last_y[0], 128)
  assert_eq(refs.golden_y[0], 128)
  assert_eq(refs.altref_v[63], 128)
  let y : Array[Int32] = Array::make(256, 42)
  let u : Array[Int32] = Array::make(64, 7)
  let v : Array[Int32] = Array::make(64, 9)
  refs.update(y, u, v)
  assert_eq(refs.last_y[255], 42)
  assert_eq(refs.last_u[63], 7)
  assert_eq(refs.last_v[0], 9)
  // 只有 last 被更新
  assert_eq(refs.golden_y[0], 128)
  assert_eq(refs.altref_u[0], 128)
}

///|
test "vp8b: 运动补偿整数像素与边界钳制" {
  let w = 32
  let h = 32
  let ref_y : Array[Int32] = Array::make(w * h, 0)
  let ref_u : Array[Int32] = Array::make(16 * 16, 0)
  let ref_v : Array[Int32] = Array::make(16 * 16, 0)
  // 填充可识别的梯度
  for i in 0..<(w * h) {
    ref_y[i] = i % 256
  }
  let (py, pu, pv) = _vp8_motion_compensate_16x16(
    ref_y,
    ref_u,
    ref_v,
    1,
    1,
    vp8b_mv(0, 0),
    w,
    h,
  )
  assert_true(py.length() == 256)
  assert_true(pu.length() == 64)
  assert_eq(py[0], ref_y[16 * w + 16])
  assert_eq(py[255], ref_y[31 * w + 31])
  assert_eq(pu[0], 0)
  ignore(pv)
  // 负向运动向量 → 钳到 0 行/列
  let (py0, _, _) = _vp8_motion_compensate_16x16(
    ref_y,
    ref_u,
    ref_v,
    1,
    1,
    vp8b_mv(-100, -100),
    w,
    h,
  )
  assert_eq(py0[0], ref_y[0])
  // 正向越界 → 钳到 width-1 / height-1
  let (py1, _, _) = _vp8_motion_compensate_16x16(
    ref_y,
    ref_u,
    ref_v,
    0,
    0,
    vp8b_mv(100, 100),
    w,
    h,
  )
  assert_eq(py1[0], ref_y[(h - 1) * w + (w - 1)])
}

///|
test "vp8b: Golomb 编码解析" {
  // 全 1：首位即 1 → leading_zeros=0 → 0
  let bd_hi = Vp8BoolDecoder::new(vp8b_bytes([0xFF, 0xFF]), 0)
  assert_eq(vp8_read_ue_golomb(bd_hi), 0)
  // 全 0：leading_zeros 超过 31 → 直接返回 0
  let bd_lo = Vp8BoolDecoder::new(vp8b_bytes([0x00, 0x00]), 0)
  assert_eq(vp8_read_ue_golomb(bd_lo), 0)
  // 位序列 0,1,0 → ue = 1
  let bd_mid = Vp8BoolDecoder::new(vp8b_bytes([0x40, 0x00]), 0)
  assert_eq(vp8_read_ue_golomb(bd_mid), 1)
  // 同一序列的有符号版本
  let bd_se = Vp8BoolDecoder::new(vp8b_bytes([0x40, 0x00]), 0)
  assert_eq(vp8_read_se_golomb(bd_se), 1)
  // se(0) = 0
  let bd_zero = Vp8BoolDecoder::new(vp8b_bytes([0xFF, 0xFF]), 0)
  assert_eq(vp8_read_se_golomb(bd_zero), 0)
  // 残差按 1/4 像素放大
  let bd_res = Vp8BoolDecoder::new(vp8b_bytes([0x40, 0x00]), 0)
  assert_eq(vp8_parse_mv_residual(bd_res, 128), 4)
}

///|
test "vp8b: 参考帧选择与平面获取" {
  // ref_prob=0 时首位必为 1 → last
  let bd_last = Vp8BoolDecoder::new(vp8b_bytes([0x01, 0x00]), 0)
  assert_eq(vp8b_ref_id(vp8_parse_ref_frame(bd_last, 0)), 0)
  // 首 0 次 1 → golden
  let bd_golden = Vp8BoolDecoder::new(vp8b_bytes([0x80, 0x00]), 0)
  assert_eq(vp8b_ref_id(vp8_parse_ref_frame(bd_golden, 255)), 1)
  // 两跳都 0 → altref
  let bd_alt = Vp8BoolDecoder::new(vp8b_bytes([0x00, 0x00]), 0)
  assert_eq(vp8b_ref_id(vp8_parse_ref_frame(bd_alt, 255)), 2)

  let refs = Vp8ReferenceFrames::new(16, 16)
  let (ly, lu, lv) = vp8_get_ref_planes(refs, Vp8RefFrame::RefLast)
  ignore(lv)
  let (gy, gu, gv) = vp8_get_ref_planes(refs, Vp8RefFrame::RefGolden)
  ignore(gv)
  let (ay, au, av) = vp8_get_ref_planes(refs, Vp8RefFrame::RefAltref)
  ignore(au)
  assert_eq(ly[0], 128)
  assert_eq(gy[0], 128)
  assert_eq(ay[0], 128)
  assert_eq(lu[0], 128)
  assert_eq(gu[0], 128)
  assert_eq(av[63], 128)
}

///|
test "vp8b: 运动向量预测中值" {
  // x: left=2, above=8, above_left=5 → 中值 5
  let p = vp8_predict_motion_vector(vp8b_mv(2, 1), vp8b_mv(8, 3), vp8b_mv(5, 2))
  assert_eq(p.mv_x, 5)
  assert_eq(p.mv_y, 2)
  // 三者相同
  let same = vp8_predict_motion_vector(
    vp8b_mv(4, 4),
    vp8b_mv(4, 4),
    vp8b_mv(4, 4),
  )
  assert_eq(same.mv_x, 4)
  assert_eq(same.mv_y, 4)
  // 负值中值
  let neg = vp8_predict_motion_vector(
    vp8b_mv(-3, -3),
    vp8b_mv(-1, -1),
    vp8b_mv(-2, -2),
  )
  assert_eq(neg.mv_x, -2)
  assert_eq(neg.mv_y, -2)
  // 简化解析直接复制预测值
  let bd = Vp8BoolDecoder::new(vp8b_bytes([0x00, 0x00]), 0)
  let mv = _vp8_parse_motion_vector(bd, vp8b_mv(6, -6))
  assert_eq(mv.mv_x, 6)
  assert_eq(mv.mv_y, -6)
  // 使用预测时按 1/4 像素放大
  let bd_pred = Vp8BoolDecoder::new(vp8b_bytes([0x01, 0x00]), 0)
  let (fx, fy) = vp8_parse_full_motion_vector(bd_pred, vp8b_mv(3, -2), 0)
  assert_eq(fx, 12)
  assert_eq(fy, -8)
}

///|
test "vp8b: 帧解码错误路径与最小关键帧" {
  // 非关键帧
  let inter = vp8b_bytes([1, 0, 0])
  try {
    let _ = decode_vp8_frame(inter, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 零尺寸
  let zero = vp8b_bytes([0, 0, 0, 0x9D, 0x01, 0x2A, 0, 0, 0, 0])
  try {
    let _ = decode_vp8_frame(zero, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 奇数宽 → 明确错误而非 panic
  let odd = vp8b_bytes([0, 0, 0, 0x9D, 0x01, 0x2A, 15, 0, 16, 0])
  try {
    let _ = decode_vp8_frame(odd, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 16x16 全零位流：能解出图像（量化 0 → 基准灰）
  let tiny = vp8b_bytes([0, 0, 0, 0x9D, 0x01, 0x2A, 16, 0, 16, 0])
  let img = decode_vp8_frame(tiny, 0)
  assert_eq(img.width, 16)
  assert_eq(img.height, 16)
  assert_eq(img.channels, 3)
  assert_true(img.data.length() == 16 * 16 * 3)
}

///|
test "vp8b: inter 帧入口与参考帧回填" {
  // 关键帧走常规解码并写回参考帧
  let tiny = vp8b_bytes([0, 0, 0, 0x9D, 0x01, 0x2A, 16, 0, 16, 0])
  let refs = Vp8ReferenceFrames::new(8, 8)
  let (img, new_refs) = decode_vp8_inter_frame(tiny, 0, refs)
  assert_eq(img.width, 16)
  assert_eq(new_refs.width, 16)
  assert_eq(new_refs.height, 16)
  assert_eq(new_refs.last_u[0], 128)
  // inter 帧 + 空参考帧 → 尺寸无效
  try {
    let _ = decode_vp8_inter_frame(
      inter_frame_tag(),
      0,
      Vp8ReferenceFrames::new(0, 0),
    )
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
fn inter_frame_tag() -> Bytes {
  vp8b_bytes([1, 0, 0])
}
