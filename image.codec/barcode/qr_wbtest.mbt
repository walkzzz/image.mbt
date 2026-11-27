// 白盒：QR 解码内部函数分支

///|
fn qwb_bits_of(v : Int32, n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<n {
    out.push((v >> (n - i - 1)) & 1)
  }
  out
}

///|
fn qwb_app(arr : Array[Int32], more : Array[Int32]) -> Array[Int32] {
  let out = arr.copy()
  for b in more {
    out.push(b)
  }
  out
}

///|
fn qwb_gray_image(w : Int32, h : Int32, v : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h, v.to_byte())
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "qwb: hamming_distance 与 is_function_module 各区域" {
  assert_eq(hamming_distance(0, 0), 0)
  assert_eq(hamming_distance(0b1011, 0), 3)
  assert_eq(hamming_distance(0b1111, 0b0101), 2)
  let size = 21
  assert_true(is_function_module(0, 0, size))
  assert_true(is_function_module(8, 8, size))
  assert_true(is_function_module(0, size - 8, size))
  assert_true(is_function_module(size - 8, 0, size))
  assert_true(is_function_module(6, 12, size))
  assert_true(is_function_module(12, 6, size))
  // 行 8 / 列 8 的中间段属数据区（v1 为列 9..12 / 行 9..12）
  assert_true(!is_function_module(8, 12, size))
  assert_true(!is_function_module(12, 8, size))
  // 行 8 的右侧格式副本（col >= size-8）
  assert_true(is_function_module(8, 13, size))
  assert_true(!is_function_module(10, 10, size))
  assert_true(!is_function_module(12, 12, size))
  // v2（25×25）：alignment 中心 (18,18)，5×5 覆盖 16..20
  let v2 = 25
  assert_true(is_function_module(18, 18, v2))
  assert_true(is_function_module(16, 16, v2))
  assert_true(is_function_module(20, 20, v2))
  assert_true(!is_function_module(15, 15, v2))
  assert_true(!is_function_module(8, 12, v2))
}

///|
test "qwb: extract_qr_data_bits 双向扫描" {
  let size = 21
  let zeros : Array[Int32] = Array::make(size * size, 0)
  let bits = extract_qr_data_bits(zeros, size, 1)
  // 21×21 去掉功能模块后应剩相当数量的数据位
  assert_true(bits.length() > 100)
  let ones : Array[Int32] = Array::make(size * size, 1)
  let bits2 = extract_qr_data_bits(ones, size, 1)
  assert_eq(bits2.length(), bits.length())
  for b in bits2 {
    assert_eq(b, 1)
  }
}

///|
test "qwb: apply_qr_mask 八种掩码 + 未知掩码" {
  let size = 21
  let zeros : Array[Int32] = Array::make(size * size, 0)
  for mask in 0..<8 {
    let out = apply_qr_mask(zeros, size, mask)
    assert_eq(out.length(), size * size)
    let mut count = 0
    for v in out {
      count += v
    }
    assert_true(count > 0)
    // 功能模块保持原值（0）
    assert_eq(out[0], 0)
    assert_eq(out[8 * size + 8], 0)
  }
  let unknown = apply_qr_mask(zeros, size, 99)
  let mut c2 = 0
  for v in unknown {
    c2 += v
  }
  assert_eq(c2, 0)
}

///|
test "qwb: read_qr_format_info 小尺寸与 decode_format_info 全表" {
  // qr_size 8：所有 row/col 都 >= 8 → 跳过，format_bits 保持 0
  let size = 8
  let zeros : Array[Int32] = Array::make(size * size, 0)
  let info = read_qr_format_info(zeros, size)
  // 空矩阵 + 表查询：要么命中某个合法码，要么 -1
  assert_true(info == -1 || info >= 0)
  // 与表中每一项都比对：命中项必须返回其 ec/mask
  for (bits, ec, mask) in qr_format_info_table {
    assert_eq(decode_format_info(bits), (ec, mask))
  }
  assert_eq(decode_format_info(-1), (0, 0))
}

///|
test "qwb: decode_qr_data 位数不足与四种模式" {
  // 少于 4 位
  assert_eq(decode_qr_data([1, 0], 1), ("", 0))
  // 数字模式：3 位数字
  let mut digit = qwb_bits_of(1, 4) // mode 0001
  digit = qwb_app(digit, qwb_bits_of(3, 10)) // char_count=3
  digit = qwb_app(digit, qwb_bits_of(12, 10)) // 012
  let (d1, _) = decode_qr_data(digit, 1)
  assert_eq(d1, "012")
  // 数字模式：2 位（7 位编码）
  let mut digit2 = qwb_bits_of(1, 4)
  digit2 = qwb_app(digit2, qwb_bits_of(2, 10))
  digit2 = qwb_app(digit2, qwb_bits_of(34, 7))
  digit2 = qwb_app(digit2, qwb_bits_of(0, 10)) // 补齐填充位
  let (d2, _) = decode_qr_data(digit2, 1)
  assert_eq(d2, "34")
  // 数字模式：1 位（4 位编码）
  let mut digit3 = qwb_bits_of(1, 4)
  digit3 = qwb_app(digit3, qwb_bits_of(1, 10))
  digit3 = qwb_app(digit3, qwb_bits_of(7, 4))
  digit3 = qwb_app(digit3, qwb_bits_of(0, 10))
  let (d3, _) = decode_qr_data(digit3, 1)
  assert_eq(d3, "7")
  // 字母数字模式：两位
  let mut alnum = qwb_bits_of(2, 4)
  alnum = qwb_app(alnum, qwb_bits_of(2, 9))
  alnum = qwb_app(alnum, qwb_bits_of(10 * 45 + 11, 11)) // 'A','B'
  let (a1, _) = decode_qr_data(alnum, 1)
  assert_eq(a1, "AB")
  // 字母数字模式：一位（6 位编码）
  let mut alnum2 = qwb_bits_of(2, 4)
  alnum2 = qwb_app(alnum2, qwb_bits_of(1, 9))
  alnum2 = qwb_app(alnum2, qwb_bits_of(10, 6))
  alnum2 = qwb_app(alnum2, qwb_bits_of(0, 6))
  let (a2, _) = decode_qr_data(alnum2, 1)
  assert_eq(a2, "A")
  // 字母数字模式：越界索引被跳过（value 全 1 → 45 / 45）
  let mut alnum3 = qwb_bits_of(2, 4)
  alnum3 = qwb_app(alnum3, qwb_bits_of(2, 9))
  alnum3 = qwb_app(alnum3, qwb_bits_of(2047, 11))
  let (a3, _) = decode_qr_data(alnum3, 1)
  assert_true(a3.length() <= 2)
  // 字节模式：可打印 + 非可打印
  let mut byte = qwb_bits_of(4, 4)
  byte = qwb_app(byte, qwb_bits_of(2, 8))
  byte = qwb_app(byte, qwb_bits_of(65, 8))
  byte = qwb_app(byte, qwb_bits_of(200, 8))
  let (b1, _) = decode_qr_data(byte, 1)
  assert_eq(b1, "A?")
  // 未知模式返回空
  let mut unknown = qwb_bits_of(7, 4)
  unknown = qwb_app(unknown, qwb_bits_of(0, 8))
  let (u1, _) = decode_qr_data(unknown, 1)
  assert_eq(u1, "")
}

///|
test "qwb: sample_qr_modules 与 finder 包装函数" {
  let img = qwb_gray_image(21, 21, 200)
  let modules = sample_qr_modules(img.data, 21, 21, 0, 0, 21, 21, 21)
  assert_eq(modules.length(), 21 * 21)
  for m in modules {
    assert_eq(m, 0)
  }
  let dark = qwb_gray_image(21, 21, 10)
  let m2 = sample_qr_modules(dark.data, 21, 21, 0, 0, 21, 21, 21)
  for m in m2 {
    assert_eq(m, 1)
  }
  // 检测包装函数在纯色图上不抛异常
  let pats = detect_qr_finder_patterns_full(img)
  assert_eq(pats.length() >= 0, true)
}
