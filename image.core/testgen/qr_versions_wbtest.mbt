///|
/// 构造 n 字节 ASCII 载荷（'A' 填充）。长度即语义，内容不影响容量判定。
fn qr_test_payload(n : Int32) -> Bytes {
  Bytes::make(n, b'A')
}

///|
test "qr: 版本选择边界与容量表一致（17/32/53/78/106）" {
  assert_eq(qr_v1_max_bytes(), 17)
  assert_eq(qr_max_bytes(), 106)
  // 边界两侧：17→v1、18→v2、32→v2、33→v3、53→v3、54→v4、78→v4、79→v5、106→v5
  let bounds : Array[(Int32, Int32)] = [
    (17, 1),
    (18, 2),
    (32, 2),
    (33, 3),
    (53, 3),
    (54, 4),
    (78, 4),
    (79, 5),
    (106, 5),
  ]
  for (n, v) in bounds {
    let payload = qr_test_payload(n)
    assert_eq(qr_version_for(payload), v)
    assert_eq(qr_matrix_size(payload), 17 + 4 * v)
  }
  assert_true(qr_fits(qr_test_payload(106)))
  assert_true(!qr_fits(qr_test_payload(107)))
  // 历史 API 语义不变：v1 上限仍是 17
  assert_true(qr_fits_v1(qr_test_payload(17)))
  assert_true(!qr_fits_v1(qr_test_payload(18)))
}

///|
test "qr: v2 起的 alignment pattern 落在 (size-7, size-7)，5×5 环 + 中心" {
  // 18 字节 → v2，25×25，对齐中心 (18, 18)
  let m = qr_modules(qr_test_payload(18))
  let size = 25
  assert_eq(m.length(), 625)
  assert_eq(m[18 * size + 18], 1) // 中心
  assert_eq(m[16 * size + 16], 1) // 外环左上角
  assert_eq(m[20 * size + 20], 1) // 外环右下角
  assert_eq(m[17 * size + 17], 0) // 内环（白）
  assert_eq(m[19 * size + 19], 0)
  // v1 没有对齐图案：21×21 的同一相对位置属数据区，矩阵里不应出现完整的 5×5 环
  let m1 = qr_modules(qr_test_payload(10))
  assert_eq(m1.length(), 441)
}

///|
test "qr: dark module 固定在 (size-8, 8)，随版本右移" {
  let cases : Array[(Int32, Int32)] = [
    (10, 21),
    (18, 25),
    (33, 29),
    (54, 33),
    (79, 37),
  ]
  for (n, size) in cases {
    let m = qr_modules(qr_test_payload(n))
    assert_eq(m.length(), (size * size).to_int())
    assert_eq(m[(size - 8) * size + 8], 1)
  }
}

///|
test "qr: timing pattern 在行/列 6，从 8 到 size-9 隔一取黑" {
  // v3（33 字节 → 29×29）
  let m = qr_modules(qr_test_payload(33))
  let size = 29
  for i in 8..<(size - 8) {
    let expect = if i % 2 == 0 { 1 } else { 0 }
    assert_eq(m[6 * size + i], expect)
    assert_eq(m[i * size + 6], expect)
  }
}
