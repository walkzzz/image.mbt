// 覆盖率测试：加密与水印（XOR / 混沌 / Arnold / LSB / 可见水印 / 指标 / 报告）

///|
fn cv_img(w : Int32, h : Int32, c : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d),
  }
}

///|
fn cv_pattern(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push((x * 11 + y * 37).to_byte())
    }
  }
  cv_img(w, h, 1, d)
}

///|
fn cv_flat(w : Int32, h : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(v)
  }
  cv_img(w, h, 1, d)
}

///|
fn cv_bad_dims() -> @types.Image {
  cv_img(0, 4, 1, [])
}

///|
fn cv_bad_channels() -> @types.Image {
  cv_img(2, 2, 5, [])
}

///|
fn cv_bad_data() -> @types.Image {
  cv_img(2, 2, 1, [b'\x00'])
}

///|
test "encov: 默认参数与 XOR 往返" {
  let cp = @encryption.create_default_chaotic_params()
  assert_true(cp.x0 == 0.1)
  assert_true(cp.a == 10.0)
  assert_true(cp.b == 28.0)
  assert_true(cp.iterations == 1000)
  let ap = @encryption.create_default_arnold_params()
  assert_true(ap.iterations == 10)
  assert_true(ap.a == 1)
  assert_true(ap.b == 1)
  // XOR 加密 → 解密应完全还原
  let img = cv_pattern(8, 8)
  let key : Array[Byte] = [b'\x0F', b'\xF0']
  let r = @encryption.xor_encrypt(img, key)
  assert_true(r.algorithm == @encryption.XOR)
  assert_true(r.encrypted_data.length() == 64)
  assert_true(r.width == 8)
  assert_true(r.height == 8)
  assert_true(r.channels == 1)
  assert_true(r.key_hash == "xor_key_hash")
  assert_true(r.encrypted_data[0].to_int() == (0 ^ 15))
  let back = @encryption.xor_decrypt(r, key)
  assert_true(back.width == 8)
  assert_true(back.data[0].to_int() == img.data[0].to_int())
  assert_true(back.data[63].to_int() == img.data[63].to_int())
  // 四类校验
  try {
    let _ = @encryption.xor_encrypt(cv_bad_dims(), key)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.xor_encrypt(cv_bad_channels(), key)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.xor_encrypt(cv_bad_data(), key)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let empty_key : Array[Byte] = []
    let _ = @encryption.xor_encrypt(img, empty_key)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "encov: 混沌序列与加密" {
  let params = @encryption.create_default_chaotic_params()
  let seq = @encryption.generate_chaotic_sequence_enc(params, 20)
  assert_true(seq.length() == 20)
  // 序列不确定但应有变化
  let mut changed = 0
  for i in 1..<20 {
    if (seq[i] - seq[i - 1]).abs() > 0.0 {
      changed += 1
    }
  }
  assert_true(changed > 0)
  // 长度 0 的序列
  assert_true(
    @encryption.generate_chaotic_sequence_enc(params, 0).length() == 0,
  )
  // 混沌加密：输出长度一致且发生改变
  let img = cv_pattern(6, 6)
  let r = @encryption.chaotic_encrypt(img, params)
  assert_true(r.algorithm == @encryption.Chaotic)
  assert_true(r.encrypted_data.length() == 36)
  assert_true(r.key_hash == "chaotic_key_hash")
  let mut diff_count = 0
  for i in 0..<36 {
    if r.encrypted_data[i].to_int() != img.data[i].to_int() {
      diff_count += 1
    }
  }
  assert_true(diff_count > 0)
  // 三类校验
  try {
    let _ = @encryption.chaotic_encrypt(cv_bad_dims(), params)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.chaotic_encrypt(cv_bad_channels(), params)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.chaotic_encrypt(cv_bad_data(), params)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "encov: Arnold 置乱" {
  let img = cv_pattern(8, 8)
  let p = @encryption.create_default_arnold_params()
  let r = @encryption.arnold_scramble(img, p)
  assert_true(r.algorithm == @encryption.Arnold)
  assert_true(r.encrypted_data.length() == 64)
  assert_true(r.key_hash == "arnold_key_hash")
  // 置乱后像素顺序改变（数据分布仍为原集合）
  let mut rearranged = 0
  for i in 0..<64 {
    if r.encrypted_data[i].to_int() != img.data[i].to_int() {
      rearranged += 1
    }
  }
  assert_true(rearranged > 0)
  // 迭代 0 次：保持原图
  let p0 = @encryption.ArnoldParams::{ iterations: 0, a: 1, b: 1, }
  let r0 = @encryption.arnold_scramble(img, p0)
  assert_true(r0.encrypted_data[0].to_int() == img.data[0].to_int())
  // 三类校验
  try {
    let _ = @encryption.arnold_scramble(cv_bad_dims(), p)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.arnold_scramble(cv_bad_channels(), p)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.arnold_scramble(cv_bad_data(), p)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "encov: LSB 水印嵌入与提取" {
  let img = cv_flat(16, 16, b'\x40')
  let wm : Array[Byte] = [b'\x41', b'\x42', b'\x43', b'\x44']
  let (marked, info) = @encryption.embed_watermark_lsb(img, wm, 0)
  assert_true(marked.width == 16)
  assert_true(marked.data.length() == 256)
  assert_true(info.embedded)
  assert_true(info.watermark_type == @encryption.Invisible_LSB)
  assert_true(info.embedding_position == "LSB")
  assert_true(info.strength == 0.0)
  // 提取应与原水印完全一致
  let ext = @encryption.extract_watermark_lsb(marked, 4, 0)
  assert_true(ext.extracted)
  assert_true(ext.similarity == 1.0)
  assert_true(ext.watermark_data.length() == 4)
  assert_true(ext.watermark_data[0].to_int() == 65)
  assert_true(ext.watermark_data[3].to_int() == 68)
  // strength=1 改变次低位
  let (marked2, info2) = @encryption.embed_watermark_lsb(img, wm, 1)
  assert_true(info2.strength == 1.0)
  let ext2 = @encryption.extract_watermark_lsb(marked2, 4, 1)
  assert_true(ext2.watermark_data[0].to_int() == 65)
  // 水印超过像素容量：多余部分保持原样
  let big_wm : Array[Byte] = Array::make(100, b'\xFF')
  let (marked3, info3) = @encryption.embed_watermark_lsb(img, big_wm, 0)
  assert_true(info3.embedded)
  assert_true(marked3.data.length() == 256)
  // 校验：空水印 / 尺寸 / 通道 / 数据
  try {
    let empty_wm : Array[Byte] = []
    let _ = @encryption.embed_watermark_lsb(img, empty_wm, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_watermark_lsb(cv_bad_dims(), wm, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_watermark_lsb(cv_bad_channels(), wm, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_watermark_lsb(cv_bad_data(), wm, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 提取校验：长度 <= 0
  try {
    let _ = @encryption.extract_watermark_lsb(img, 0, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.extract_watermark_lsb(cv_bad_dims(), 4, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.extract_watermark_lsb(cv_bad_channels(), 4, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.extract_watermark_lsb(cv_bad_data(), 4, 0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "encov: 可见水印" {
  let img = cv_flat(32, 32, b'\x00')
  let r = @encryption.embed_visible_watermark(img, "AB", 2, 2, 1.0)
  assert_true(r.width == 32)
  assert_true(r.data.length() == 1024)
  // 区域 (2,2) 起始，宽 2*8，高 16 → 完全不透明 → 255
  assert_true(r.data[2 * 32 + 2].to_int() == 255)
  assert_true(r.data[2 * 32 + 17].to_int() == 255)
  // 区域外保持原值
  assert_true(r.data[0].to_int() == 0)
  assert_true(r.data[20 * 32].to_int() == 0)
  // 半透明 opacity 0.5：0 → 127
  let half = @encryption.embed_visible_watermark(img, "A", 0, 0, 0.5)
  assert_true(half.data[0].to_int() == 127)
  // 校验：空文本 / 尺寸 / 通道 / 数据
  try {
    let _ = @encryption.embed_visible_watermark(img, "", 0, 0, 1.0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_visible_watermark(cv_bad_dims(), "A", 0, 0, 1.0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_visible_watermark(
      cv_bad_channels(),
      "A",
      0,
      0,
      1.0,
    )
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.embed_visible_watermark(cv_bad_data(), "A", 0, 0, 1.0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "encov: 熵 / 相关性 / PSNR / 质量" {
  let flat = cv_flat(8, 8, b'\x80')
  let noise = cv_pattern(8, 8)
  let e_flat = @encryption.calculate_image_entropy(flat)
  let e_noise = @encryption.calculate_image_entropy(noise)
  assert_true(e_flat <= 0.0)
  assert_true(e_noise > e_flat)
  // 相关性：同一图像为 1；平坦图方差 0 → 0
  let c_same = @encryption.calculate_correlation(noise, noise)
  assert_true(c_same > 0.99)
  assert_true(@encryption.calculate_correlation(flat, flat) == 0.0)
  // PSNR：完全相同 → 100；不同 → 有限正值
  assert_true(@encryption.calculate_psnr(noise, noise) == 100.0)
  let p_diff = @encryption.calculate_psnr(noise, flat)
  assert_true(p_diff > 0.0)
  // 质量评估：完全相同的图 → npcr 0
  let q_same = @encryption.evaluate_image_encryption_quality(noise, noise)
  assert_true(q_same.npcr == 0.0)
  assert_true(q_same.uaci == 0.0)
  assert_true(q_same.psnr == 100.0)
  assert_true(q_same.correlation_horizontal > 0.99)
  assert_true(q_same.key_sensitivity == 0.99)
  // 不同图 → npcr > 0
  let q_diff = @encryption.evaluate_image_encryption_quality(noise, flat)
  assert_true(q_diff.npcr > 0.0)
  assert_true(q_diff.uaci == q_diff.npcr * 0.5)
  // 报告（需要 加密结果 + 水印信息 + 质量三项）
  let enc_res = @encryption.xor_encrypt(noise, [b'\x01', b'\x02'])
  let (_, wm_info) = @encryption.embed_watermark_lsb(noise, [b'\x41'], 0)
  let report = @encryption.encryption_report_to_string(enc_res, wm_info, q_diff)
  assert_true(report.contains("加密"))
  // 校验（熵 / 相关性 / PSNR / 质量各测一条最小分支）
  try {
    let _ = @encryption.calculate_image_entropy(cv_bad_data())
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.calculate_correlation(cv_bad_data(), noise)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.calculate_correlation(noise, cv_bad_channels())
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.calculate_psnr(cv_bad_data(), noise)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @encryption.evaluate_image_encryption_quality(cv_bad_data(), noise)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
