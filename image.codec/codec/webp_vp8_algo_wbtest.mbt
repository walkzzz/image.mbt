///|
test "wbtest: IDCT 4x4（直流与交流系数）" {
  let dc : Array[Int32] = Array::make(16, 0)
  dc[0] = 100
  let r1 = vp8_idct_4x4(dc)
  assert_eq(r1.length(), 16)
  assert_true(r1[0] != 0)
  let ac : Array[Int32] = Array::make(16, 0)
  ac[1] = 40
  ac[5] = -20
  ac[10] = 15
  let r2 = vp8_idct_4x4(ac)
  assert_eq(r2.length(), 16)
  assert_true(r2[5] != 0)
}

///|
test "wbtest: WHT 4x4" {
  let b : Array[Int32] = Array::make(16, 0)
  b[0] = 8
  b[5] = -4
  let r = vp8_wht_4x4(b)
  assert_eq(r.length(), 16)
  assert_true(r[0] != 0)
}

///|
test "wbtest: 16x16 帧内四种预测模式" {
  let above : Array[Int32] = Array::make(16, 128)
  let left : Array[Int32] = Array::make(16, 96)
  let modes : Array[Vp8I16x16Mode] = [
    Vp8I16x16Mode::I16x16DcPred,
    Vp8I16x16Mode::I16x16TrueMotionPred,
    Vp8I16x16Mode::I16x16HPred,
    Vp8I16x16Mode::I16x16VPred,
  ]
  for m in modes {
    let p = vp8_intra_predict_16x16(m, above, left, 100)
    assert_eq(p.length(), 256)
  }
}

///|
test "wbtest: 滤波级别与参考平面" {
  let seg = Vp8SegmentParams::new()
  assert_eq(vp8_get_filter_level_for_segment(8, seg, 0), 8)
  let refs = Vp8ReferenceFrames::new(16, 16)
  let (y1, u1, v1) = vp8_get_ref_planes(refs, Vp8RefFrame::RefLast)
  assert_eq(y1.length(), 256)
  assert_true(u1.length() > 0)
  assert_true(v1.length() > 0)
  let _ = vp8_get_ref_planes(refs, Vp8RefFrame::RefGolden)
  let _ = vp8_get_ref_planes(refs, Vp8RefFrame::RefAltref)
}
