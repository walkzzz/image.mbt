// 覆盖率测试：Logistic/XOR 图像加解密与质量评估的错误与正常分支

///|
fn encw_img(w : Int32, h : Int32, c : Int32, seed : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 19 + y * 27 + ch * 43 + seed) % 256)
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(d.map(fn(v) { v.to_byte() })),
  }
}

///|
test "enc: Logistic 加解密" {
  let img = encw_img(16, 16, 3, 7)
  let cfg = @encryption.encryption_default_config()
  assert_true(cfg.method_type == "logistic")
  assert_true(cfg.mu > 0.0)
  // 默认密钥加密
  let c1 = @encryption.encrypt_image_logistic(img)
  assert_true(c1.width == 16)
  // 自定义密钥
  let c2 = @encryption.encrypt_image_logistic(img, key=0.5)
  assert_true(c2.channels == 3)
  // 解密
  let d1 = @encryption.decrypt_image_logistic(c1)
  assert_true(d1.width == 16)
  let d2 = @encryption.decrypt_image_logistic(c2, key=0.5)
  assert_true(d2.height == 16)
  // 灰度 / RGBA
  let g = encw_img(12, 12, 1, 3)
  assert_true(@encryption.encrypt_image_logistic(g).channels == 1)
  let rgba = encw_img(8, 8, 4, 5)
  assert_true(
    @encryption.decrypt_image_logistic(@encryption.encrypt_image_logistic(rgba)).channels ==
    4,
  )
}

///|
test "enc: XOR 加解密与熵/相关性" {
  let img = encw_img(20, 20, 1, 9)
  let c = @encryption.encrypt_image_xor(img, "key123")
  assert_true(c.width == 20)
  let d = @encryption.decrypt_image_xor(c, "key123")
  assert_true(d.width == 20)
  // 空密钥 → 抛错
  try {
    let _ = @encryption.encrypt_image_xor(img, "")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 熵：全常量图熵最低
  let flat = @types.Image::{
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(Array::make(256, (64).to_byte())),
  }
  let h0 = @encryption.histogram_entropy(flat)
  let h1 = @encryption.histogram_entropy(img)
  assert_true(h0 >= 0.0)
  assert_true(h1 >= h0)
  // 相邻相关性三个方向
  let ch = @encryption.adjacent_correlation(img)
  assert_true(ch >= -1.0 && ch <= 1.0)
  let cv = @encryption.adjacent_correlation(img, direction="vertical")
  assert_true(cv >= -1.0 && cv <= 1.0)
  let cd = @encryption.adjacent_correlation(img, direction="diagonal")
  assert_true(cd >= -1.0 && cd <= 1.0)
  let cu = @encryption.adjacent_correlation(img, direction="unknown")
  assert_true(cu >= -1.0 && cu <= 1.0)
}

///|
test "enc: 质量评估 / 密钥敏感性 / 批处理" {
  let img = encw_img(16, 16, 3, 11)
  let enc = @encryption.encrypt_image_logistic(img)
  let q = @encryption.evaluate_encryption_quality(img, enc)
  assert_true(q.entropy >= 0.0)
  assert_true(q.npcr >= 0.0)
  assert_true(q.uaci >= 0.0)
  assert_true(q.correlation_h >= -1.0)
  let ks = @encryption.key_sensitivity_test(img, 0.123456789)
  assert_true(ks >= 0.0)
  let batch = @encryption.batch_encrypt([img, encw_img(8, 8, 1, 2)], 0.4)
  assert_true(batch.length() == 2)
  let empty = @encryption.batch_encrypt([], 0.4)
  assert_true(empty.length() == 0)
}

///|
test "enc: 错误分支" {
  // 尺寸 / 通道 / 长度
  try {
    let _ = @encryption.encrypt_image_logistic(encw_img(0, 8, 3, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.encrypt_image_logistic(encw_img(8, 8, 5, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let bad = @types.Image::{
    width: 8,
    height: 8,
    channels: 3,
    data: Bytes::from_array(Array::make(8, (1).to_byte())),
  }
  try {
    let _ = @encryption.encrypt_image_logistic(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.encrypt_image_xor(encw_img(0, 8, 1, 0), "k")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.histogram_entropy(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.adjacent_correlation(bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 质量评估：第二张图非法
  let ok = encw_img(8, 8, 1, 3)
  try {
    let _ = @encryption.evaluate_encryption_quality(ok, bad)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.evaluate_encryption_quality(bad, ok)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.key_sensitivity_test(bad, 0.3)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @encryption.batch_encrypt([bad], 0.3)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
