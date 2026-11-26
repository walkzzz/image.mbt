// 白盒测试：VP8 帧头 / 量化 / 分段 / 残差解析
// White-box tests for VP8 frame header, quantization, segmentation and residuals.

fn vpb_pack(bits : Array[Int]) -> Bytes {
  let n = (bits.length() + 7) / 8
  let out : Array[Byte] = []
  for b in 0..<n {
    let mut v = 0
    for j in 0..<8 {
      let idx = b * 8 + j
      let bit = if idx < bits.length() {
        bits[idx]
      } else {
        0
      }
      v = (v << 1) | bit
    }
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

fn vpb_u(bits : Array[Int], v : Int, n : Int) -> Unit {
  for j in 1..=n {
    bits.push((v >> (n - j)) & 1)
  }
}

fn vpb_zeros(bits : Array[Int], n : Int) -> Unit {
  for _ in 0..<n {
    bits.push(0)
  }
}

fn vpb_bytes(vals : Array[Int]) -> Bytes {
  let out : Array[Byte] = []
  for v in vals {
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

test "vpb: 帧头关键帧解析" {
  // tag 小端：version=2, show=1, first_part=4 → 148
  let data = vpb_bytes([148, 0, 0, 0x9D, 0x01, 0x2A, 0x40, 0x01, 0xF0, 0x00])
  let h = parse_vp8_frame_header(Vp8BitReader::new(data, 0))
  assert_true(h.key_frame)
  assert_eq(h._version, 2)
  assert_true(h._show_frame)
  assert_eq(h._first_part_size, 4)
  assert_eq(h.width, 320)
  assert_eq(h.height, 240)
  assert_eq(h._horizontal_scale, 0)
  assert_eq(h._vertical_scale, 0)
}

test "vpb: 帧头非关键帧与缩放位" {
  let inter = vpb_bytes([1, 0, 0])
  let h = parse_vp8_frame_header(Vp8BitReader::new(inter, 0))
  assert_true(!h.key_frame)
  assert_eq(h.width, 0)
  assert_eq(h.height, 0)
  assert_eq(h._version, 0)
  assert_true(!h._show_frame)
  // 关键帧 + 缩放 3（高 2 位为 11）
  let scaled = vpb_bytes([0, 0, 0, 0x9D, 0x01, 0x2A, 0x40, 0xC1, 0xF0, 0xC0])
  let hs = parse_vp8_frame_header(Vp8BitReader::new(scaled, 0))
  assert_eq(hs.width, 320)
  assert_eq(hs._horizontal_scale, 3)
  assert_eq(hs.height, 0xF0)
  assert_eq(hs._vertical_scale, 3)
}

test "vpb: 量化参数无增量与有增量" {
  // y_ac=30，三个 delta 标志全 0
  let bits : Array[Int] = []
  vpb_u(bits, 30, 7)
  vpb_zeros(bits, 3)
  let q = parse_quantization(Vp8BitReader::new(vpb_pack(bits), 0))
  assert_eq(q.y_ac, 30)
  assert_eq(q.y_dc, 30)
  assert_eq(q.uv_ac, 30)
  assert_eq(q.uv_dc, 30)
  // y_ac=20；y_dc_delta: flag=1, 4 位 1001=9 → 9-16=-7 → 13
  // uv_ac_delta: flag=1, 4 位 0011=3 → 23
  // uv_dc_delta: flag=0
  let b2 : Array[Int] = []
  vpb_u(b2, 20, 7)
  b2.push(1)
  vpb_u(b2, 9, 4)
  b2.push(1)
  vpb_u(b2, 3, 4)
  b2.push(0)
  let q2 = parse_quantization(Vp8BitReader::new(vpb_pack(b2), 0))
  assert_eq(q2.y_ac, 20)
  assert_eq(q2.y_dc, 13)
  assert_eq(q2.uv_ac, 23)
  assert_eq(q2.uv_dc, 13)
}

test "vpb: 分段参数默认与完整解析" {
  // enabled=0：其余保持默认
  let off = parse_segmentation(Vp8BitReader::new(vpb_pack([0]), 0))
  assert_true(!off.enabled)
  assert_true(!off.update_map)
  assert_true(!off.update_features)
  assert_eq(off.quantizer_deltas[0], 0)
  assert_eq(off.mb_segment_tree_probs[0], 255)
  // enabled=1, update_map=1, update_features=1, mode=absolute
  let bits : Array[Int] = [1, 1, 1, 1]
  // 量化增量：seg0 flag=1 + 7 位 1000001=65 → 65-128=-63；seg1 flag=0；seg2 flag=1 + 5；seg3 flag=0
  bits.push(1)
  vpb_u(bits, 65, 7)
  bits.push(0)
  bits.push(1)
  vpb_u(bits, 5, 7)
  bits.push(0)
  // 滤波增量全 0
  vpb_zeros(bits, 4)
  // 树概率：200 / 默认 / 255
  bits.push(1)
  vpb_u(bits, 200, 8)
  bits.push(0)
  bits.push(1)
  vpb_u(bits, 255, 8)
  let seg = parse_segmentation(Vp8BitReader::new(vpb_pack(bits), 0))
  assert_true(seg.enabled)
  assert_true(seg.update_map)
  assert_true(seg.update_features)
  assert_eq(seg.feature_mode, 1)
  assert_eq(seg.quantizer_deltas[0], -63)
  assert_eq(seg.quantizer_deltas[1], 0)
  assert_eq(seg.quantizer_deltas[2], 5)
  assert_eq(seg.quantizer_deltas[3], 0)
  assert_eq(seg.filter_deltas[3], 0)
  assert_eq(seg.mb_segment_tree_probs[0], 200)
  assert_eq(seg.mb_segment_tree_probs[1], 255)
  assert_eq(seg.mb_segment_tree_probs[2], 255)
}

test "vpb: 分段量化与滤波级别换算" {
  let base = Vp8QuantParams::{ y_ac: 20, y_dc: 18, uv_ac: 22, uv_dc: 16 }
  let seg = Vp8SegmentParams::new()
  // 未启用：原样返回
  let q0 = vp8_get_quant_for_segment(base, seg, 2)
  assert_eq(q0.y_ac, 20)
  assert_eq(q0.y_dc, 18)
  assert_eq(q0.uv_ac, 22)
  assert_eq(q0.uv_dc, 16)
  assert_eq(vp8_get_filter_level_for_segment(30, seg, 1), 30)
  // delta 模式
  let seg_delta = Vp8SegmentParams::{
    enabled: true,
    update_map: false,
    update_features: true,
    feature_mode: 0,
    quantizer_deltas: [3, -5, 0, 7],
    filter_deltas: [10, -20, 0, 100],
    mb_segment_tree_probs: [255, 255, 255],
  }
  let q1 = vp8_get_quant_for_segment(base, seg_delta, 1)
  assert_eq(q1.y_ac, 15)
  assert_eq(q1.y_dc, 13)
  assert_eq(q1.uv_ac, 17)
  assert_eq(q1.uv_dc, 11)
  // 越界 segment id 原样返回
  let q2 = vp8_get_quant_for_segment(base, seg_delta, 4)
  assert_eq(q2.y_ac, 20)
  assert_eq(vp8_get_filter_level_for_segment(30, seg_delta, 0), 40)
  assert_eq(vp8_get_filter_level_for_segment(30, seg_delta, 1), 10)
  assert_eq(vp8_get_filter_level_for_segment(30, seg_delta, 2), 30)
  // 越上限夹到 63
  assert_eq(vp8_get_filter_level_for_segment(30, seg_delta, 3), 63)
  // absolute 模式
  let seg_abs = Vp8SegmentParams::{
    enabled: true,
    update_map: false,
    update_features: true,
    feature_mode: 1,
    quantizer_deltas: [3, -5, 0, 7],
    filter_deltas: [10, -20, 0, 100],
    mb_segment_tree_probs: [255, 255, 255],
  }
  let q3 = vp8_get_quant_for_segment(base, seg_abs, 0)
  assert_eq(q3.y_ac, 3)
  assert_eq(q3.y_dc, 3)
  assert_eq(q3.uv_ac, 3)
  assert_eq(q3.uv_dc, 3)
  assert_eq(vp8_get_filter_level_for_segment(30, seg_abs, 2), 0)
  // 负值夹到 0
  assert_eq(vp8_get_filter_level_for_segment(30, seg_abs, 1), 0)
}

test "vpb: 宏块 segment id 二叉树" {
  let p128 : Array[Int32] = [128, 128, 128]
  // 全 0xFF：两跳都取 1 → 3
  let bd_hi = Vp8BoolDecoder::new(vpb_bytes([0xFF, 0xFF]), 0)
  assert_eq(vp8_parse_mb_segment_id(bd_hi, p128), 3)
  // 全 0x00：两跳都取 0 → 0
  let bd_lo = Vp8BoolDecoder::new(vpb_bytes([0x00, 0x00]), 0)
  assert_eq(vp8_parse_mb_segment_id(bd_lo, p128), 0)
  // 首 0 次 1 → 1
  let p_a : Array[Int32] = [255, 0, 0]
  let bd_1 = Vp8BoolDecoder::new(vpb_bytes([0x80, 0x00]), 0)
  assert_eq(vp8_parse_mb_segment_id(bd_1, p_a), 1)
  // 首 1 次 0 → 2
  let p_b : Array[Int32] = [0, 255, 255]
  let bd_2 = Vp8BoolDecoder::new(vpb_bytes([0x80, 0x00]), 0)
  assert_eq(vp8_parse_mb_segment_id(bd_2, p_b), 2)
}

test "vpb: 残差 4x4 全零 EOB 与全非零" {
  let probs = Vp8AdaptiveProbs::new()
  // 全 0xFF：首位置零系数命中，i>0 后 EOB 命中，块立刻结束
  let bd_hi = Vp8BoolDecoder::new(vpb_bytes([0xFF, 0xFF]), 0)
  let c0 = vp8_parse_residual_4x4(bd_hi, probs, true)
  for v in c0 {
    assert_eq(v, 0)
  }
  assert_true(probs.count_zero[0] == 1)
  assert_true(probs.count_eob[1] == 1)
  assert_true(probs.total_blocks == 1)
  // 全 0x00：系数恒为 0 态之外 → is_one=0 → extra=1 → 值 2，符号正 → 每位置 2
  let probs2 = Vp8AdaptiveProbs::new()
  let bd_lo = Vp8BoolDecoder::new(vpb_bytes([0x00, 0x00]), 0)
  let c1 = vp8_parse_residual_4x4(bd_lo, probs2, false)
  for i in 0..<16 {
    assert_eq(c1[i], 2)
  }
  assert_true(probs2.count_sign_pos == 16)
  assert_true(probs2.count_extra[15] == 1)
  // DC 版本包装一致
  let probs3 = Vp8AdaptiveProbs::new()
  let bd_dc = Vp8BoolDecoder::new(vpb_bytes([0x00, 0x00]), 0)
  let c2 = vp8_parse_dc_coeffs_16x16(bd_dc, probs3)
  assert_eq(c2[0], 2)
  // zig-zag 顺序：位置 1 的 zigzag 索引是 1 → 仍然每格 2
  assert_eq(c2[1], 2)
}
