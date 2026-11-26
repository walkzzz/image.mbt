// 白盒测试：VP8 位读取器 / 布尔解码器 / 自适应概率模型
// White-box tests for VP8 bit reader, bool decoder and adaptive probability model.

///|
fn vpw_bytes(vals : Array[Int32]) -> Bytes {
  let out : Array[Byte] = []
  for v in vals {
    out.push(v.to_byte())
  }
  Bytes::from_array(out)
}

///|
test "vpw: Vp8BitReader 大端读取与越界补零" {
  let br = Vp8BitReader::new(vpw_bytes([0xAA, 0x0F]), 0)
  assert_eq(br.read_bits(4), 10)
  assert_eq(br.read_bits(4), 10)
  assert_eq(br.read_bits(8), 15)
  // 数据已耗尽：补零
  assert_eq(br.read_bits(8), 0)
  assert_eq(br.read_bit(), 0)
  let br2 = Vp8BitReader::new(vpw_bytes([0x80, 0x01]), 1)
  assert_eq(br2.read_bit(), 0)
  assert_eq(br2.read_bit(), 0)
  assert_eq(br2.read_bit(), 0)
  assert_eq(br2.read_bit(), 0)
  assert_eq(br2.read_bits(3), 0)
  // read_bool 是 read_bit 的简化版，prob 不参与
  let br3 = Vp8BitReader::new(vpw_bytes([0x80]), 0)
  assert_eq(br3.read_bool(0), 1)
  assert_eq(br3.read_bool(255), 0)
}

///|
test "vpw: Vp8BoolDecoder 初始化与解码" {
  // 空数据：内部值补零，读出的都是一位 0
  let empty = Vp8BoolDecoder::new(Bytes::make(0, b'\x00'), 0)
  assert_eq(empty.range, 255)
  assert_eq(empty.value, 0)
  assert_eq(empty.bit_count, 16)
  assert_eq(empty.read_bool(128), 0)
  // 全 0xFF：value = 0xFFFF，首字节高概率直接命中 1
  let hi = Vp8BoolDecoder::new(vpw_bytes([0xFF, 0xFF]), 0)
  assert_eq(hi.value, 0xFFFF)
  assert_eq(hi.read_bool(128), 1)
  assert_eq(hi.range, 254)
  assert_eq(hi.value, 65534)
  assert_eq(hi.bit_count, 15)
  // 归一化后仍需读到下一次归一化才消耗 bit_count
  assert_eq(hi.read_bool(128), 1)
  // 起点偏移：从第 2 字节开始
  let off = Vp8BoolDecoder::new(vpw_bytes([0x00, 0xFF, 0x00]), 1)
  assert_eq(off.value, 0xFF00)
  assert_eq(off.read_bool(128), 1)
}

///|
test "vpw: Vp8BoolDecoder 字面值读取" {
  let z = Vp8BoolDecoder::new(vpw_bytes([0x00, 0x00]), 0)
  assert_eq(z._read_literal(0), 0)
  let low = Vp8BoolDecoder::new(vpw_bytes([0x00, 0x00]), 0)
  assert_eq(low._read_literal(3), 0)
  let hi = Vp8BoolDecoder::new(vpw_bytes([0xFF, 0xFF]), 0)
  assert_eq(hi._read_literal(3), 7)
}

///|
test "vpw: Vp8AdaptiveProbs 默认表与越界回退" {
  let p = Vp8AdaptiveProbs::new()
  assert_eq(p.prob_zero[0], 200)
  assert_eq(p.prob_zero[15], 40)
  assert_eq(p.prob_one[0], 180)
  assert_eq(p.prob_one[15], 30)
  assert_eq(p.prob_eob[0], 100)
  assert_eq(p.prob_eob[15], 250)
  assert_eq(p.prob_extra[3], 140)
  assert_eq(p.prob_sign, 128)
  assert_eq(p.total_blocks, 0)
  assert_eq(p.get_zero_prob(0), 200)
  assert_eq(p.get_zero_prob(-1), 150)
  assert_eq(p.get_zero_prob(16), 150)
  assert_eq(p.get_one_prob(15), 30)
  assert_eq(p.get_one_prob(99), 170)
  assert_eq(p.get_eob_prob(0), 100)
  assert_eq(p.get_eob_prob(-2), 100)
  assert_eq(p.get_extra_prob(9), 140)
  assert_eq(p.get_extra_prob(40), 140)
}

///|
test "vpw: Vp8AdaptiveProbs 计数与 EMA 更新" {
  let p = Vp8AdaptiveProbs::new()
  // 非法位置只被忽略，不计数
  p.record_zero(-1)
  p.record_zero(16)
  p.record_one(-1)
  p.record_one(20)
  p.record_eob(17)
  p.record_extra(-3)
  assert_true(p.count_zero[0] == 0)
  assert_true(p.count_one[0] == 0)
  assert_true(p.count_eob[0] == 0)
  assert_true(p.count_extra[0] == 0)
  // 合法位置计数
  for _ in 0..<8 {
    p.record_zero(0)
  }
  p.record_one(0)
  p.record_eob(2)
  p.record_extra(3)
  p.record_sign(true)
  p.record_sign(false)
  assert_true(p.count_zero[0] == 8)
  assert_true(p.count_one[0] == 1)
  assert_true(p.count_eob[2] == 1)
  assert_true(p.count_extra[3] == 1)
  assert_true(p.count_sign_pos == 1)
  assert_true(p.count_sign_neg == 1)
  // 未满 8 块时提前返回，概率不变
  p.update()
  assert_true(p.total_blocks == 1)
  assert_true(p.prob_zero[0] == 200)
  // 累计到第 8 块才更新
  for _ in 0..<7 {
    p.update()
  }
  assert_true(p.total_blocks == 8)
  // zero: total = 8 + 1 + 1 = 10 -> observed = 8*256/10 = 204 -> (200*7+204)/8 = 200
  assert_true(p.prob_zero[0] == 200)
  // one: non_zero = 1 + 1 = 2 → observed = 256 → (180*7+256)/8 = 189
  assert_true(p.prob_one[0] == 173)
  // eob: pos2 total = 1 + 1 = 2 → observed = 128 → (120*7+128)/8 = 121
  assert_true(p.prob_eob[2] == 121)
  // extra: pos3 total = 1 + 1 = 2 → observed = 128 → (140*7+128)/8 = 138
  assert_true(p.prob_extra[3] == 138)
  // sign: total = 2 + 1 = 3 → observed = 1*256/3 = 85 → (128*7+85)/8 = 122
  assert_true(p.prob_sign == 122)
  // 计数器减半
  assert_true(p.count_zero[0] == 4)
  assert_true(p.count_one[0] == 0)
  assert_true(p.count_eob[2] == 0)
  assert_true(p.count_sign_pos == 0)
  assert_true(p.count_sign_neg == 0)
}
