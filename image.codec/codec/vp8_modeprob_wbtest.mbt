// 白盒测试：VP8 宏块预测模式概率模型
// White-box tests for VP8 macroblock mode probability model.

fn vp8m_bytes(vals : Array[Int]) -> Bytes {
  let out : Array[Byte] = []
  for v in vals {
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

fn vp8m_i16_id(m : Vp8I16x16Mode) -> Int {
  match m {
    Vp8I16x16Mode::I16x16DcPred => 0
    Vp8I16x16Mode::I16x16TrueMotionPred => 1
    Vp8I16x16Mode::I16x16HPred => 2
    Vp8I16x16Mode::I16x16VPred => 3
  }
}

fn vp8m_i4_id(m : Vp8I4x4Mode) -> Int {
  match m {
    Vp8I4x4Mode::I4x4DcPred => 0
    Vp8I4x4Mode::I4x4TrueMotionPred => 1
    Vp8I4x4Mode::I4x4HPred => 2
    Vp8I4x4Mode::I4x4VPred => 3
    Vp8I4x4Mode::I4x4LeftDownPred => 4
    Vp8I4x4Mode::I4x4RightDownPred => 5
    Vp8I4x4Mode::I4x4RightUpPred => 6
    Vp8I4x4Mode::I4x4LeftUpPred => 7
    Vp8I4x4Mode::I4x4VertRightPred => 8
    Vp8I4x4Mode::I4x4HorizDownPred => 9
  }
}

test "vp8m: I16x16 模式解析与计数" {
  let probs = Vp8MbModeProbs::new()
  assert_eq(probs.i16x16_prob[0], 180)
  assert_eq(probs.i16x16_prob[3], 140)
  assert_eq(probs.i4x4_prob[9], 40)
  assert_eq(probs.uv_prob[0], 180)
  assert_eq(probs.submb_type_prob, 150)
  assert_eq(probs.total_mbs, 0)
  // 全 1 → DC
  let m_dc = vp8_parse_i16x16_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(m_dc), 0)
  assert_eq(probs.i16x16_count[0], 1)
  // 首位 0、次位 1 → TM
  let m_tm = vp8_parse_i16x16_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x80, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(m_tm), 1)
  assert_eq(probs.i16x16_count[1], 1)
  // 0,0,1 → H
  let m_h = vp8_parse_i16x16_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x40, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(m_h), 2)
  assert_eq(probs.i16x16_count[2], 1)
  // 全 0 → V
  let m_v = vp8_parse_i16x16_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x00, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(m_v), 3)
  assert_eq(probs.i16x16_count[3], 1)
}

test "vp8m: I4x4 与 UV 模式解析" {
  let probs = Vp8MbModeProbs::new()
  let m_dc = _vp8_parse_i4x4_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  assert_eq(vp8m_i4_id(m_dc), 0)
  assert_eq(probs.i4x4_count[0], 1)
  // 首 0 次 1 → TM
  let m_tm = _vp8_parse_i4x4_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x80, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i4_id(m_tm), 1)
  assert_eq(probs.i4x4_count[1], 1)
  // 全 0 → 末位 HorizDown
  let m_hd = _vp8_parse_i4x4_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x00, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i4_id(m_hd), 9)
  assert_eq(probs.i4x4_count[9], 1)
  // UV 走同一套 4 模式树
  let u_dc = vp8_parse_uv_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(u_dc), 0)
  assert_eq(probs.uv_count[0], 1)
  let u_v = vp8_parse_uv_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0x00, 0x00]), 0),
    probs,
  )
  assert_eq(vp8m_i16_id(u_v), 3)
  assert_eq(probs.uv_count[3], 1)
  // 子宏块类型
  let sb = _vp8_parse_submb_type(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  assert_true(sb)
  assert_eq(probs.submb_type_count, 1)
  let sb2 = _vp8_parse_submb_type(
    Vp8BoolDecoder::new(vp8m_bytes([0x00, 0x00]), 0),
    probs,
  )
  assert_true(!sb2)
  assert_eq(probs.submb_type_count, 1)
}

test "vp8m: 模式概率 EMA 更新" {
  let probs = Vp8MbModeProbs::new()
  // 各记一次 DC
  let _ = vp8_parse_i16x16_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  let _ = vp8_parse_uv_mode(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  let _ = _vp8_parse_submb_type(
    Vp8BoolDecoder::new(vp8m_bytes([0xFF, 0xFF]), 0),
    probs,
  )
  // 未满 16 个宏块：提前返回
  probs.update()
  assert_eq(probs.total_mbs, 1)
  assert_eq(probs.i16x16_prob[0], 180)
  for _ in 0..<15 {
    probs.update()
  }
  assert_eq(probs.total_mbs, 16)
  // i16: total = 1 + 1 = 2 → observed[0] = 128 → (180*7+128)/8 = 173
  assert_eq(probs.i16x16_prob[0], 173)
  assert_eq(probs.i16x16_prob[1], 105)
  assert_eq(probs.i16x16_count[0], 0)
  // i4x4: 无计数 → observed 全 0 → 原值 *7/8
  assert_eq(probs.i4x4_prob[0], 140)
  assert_eq(probs.i4x4_prob[1], 87)
  assert_eq(probs.i4x4_prob[9], 35)
  // uv: total = 1 + 1 = 2 → 与 i16 同样的缩放
  assert_eq(probs.uv_prob[0], 173)
  assert_eq(probs.uv_prob[1], 105)
  assert_eq(probs.uv_prob[2], 87)
  // submb: total = 16 + 1 = 17 → observed = 256/17 = 15 → (150*7+15)/8 = 133
  assert_eq(probs.submb_type_prob, 133)
  assert_eq(probs.submb_type_count, 0)
}

test "vp8m: 环路滤波参数默认值" {
  let lf = Vp8LoopFilterParams::_new()
  assert_eq(lf.filter_level, 0)
  assert_eq(lf._inner_filter_level, 0)
  assert_eq(lf._sharpness_level, 0)
  assert_eq(lf.segment_deltas[2], 0)
  assert_eq(lf.mode_ref_deltas[3], 0)
}
