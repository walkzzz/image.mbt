///|
/// 样本构建器自检：不写盘也能把 24 张 golden + 8 个畸形样本的**全部构建逻辑**跑一遍。
/// 这是把「维护脚本永远 0 覆盖」补回来的关键——覆盖率口径不做任何排除。

///|
test "gen/samples: golden 24 张 + malformed 8 个，命名与字节契约不变" {
  let errs : Array[String] = []
  let golden = golden_samples(errs)
  let malformed = malformed_samples(errs)
  // 条数与无错误：任何一张编码失败都会进 errs
  assert_eq(golden.length(), 24)
  assert_eq(malformed.length(), 8)
  assert_eq(errs.length(), 0)
  // 文件名唯一、按 gNN/mN 编号
  let names : Array[String] = []
  for (name, data) in golden {
    assert_true(data.length() > 0)
    assert_true(name.has_prefix("g"))
    assert_true(name.contains("_"))
    names.push(name)
  }
  for (name, data) in malformed {
    assert_true(data.length() > 0)
    assert_true(name.has_prefix("m"))
    names.push(name)
  }
  for i in 0..<names.length() {
    for j in (i + 1)..<names.length() {
      assert_true(names[i] != names[j])
    }
  }
  // 生成器确定：重跑两次必须逐字节一致（封签 sha256 才有意义）
  let errs2 : Array[String] = []
  let golden2 = golden_samples(errs2)
  let malformed2 = malformed_samples(errs2)
  assert_eq(errs2.length(), 0)
  for i in 0..<golden.length() {
    assert_true(golden[i].1 == golden2[i].1)
  }
  for i in 0..<malformed.length() {
    assert_true(malformed[i].1 == malformed2[i].1)
  }
}

///|
test "gen/samples: 空字节进 errs 而不是入列（add 的错误臂）" {
  let errs : Array[String] = []
  let out : Array[(String, Bytes)] = []
  add(out, "empty.png", Bytes::from_array([]), errs)
  assert_eq(out.length(), 0)
  assert_eq(errs.length(), 1)
  add(out, "one.png", Bytes::from_array([b'\x00']), errs)
  assert_eq(out.length(), 1)
  assert_eq(errs.length(), 1)
}

///|
test "gen/samples: 畸形样本保留容器魔数，只破坏目标字段" {
  let errs : Array[String] = []
  let malformed = malformed_samples(errs)
  assert_eq(malformed[0].0.has_prefix("m1"), true)
  // m1-m4 仍是 PNG 魔数：解码器认出格式、再在 chunk/deflate/预算层拒绝
  for i in 0..<4 {
    let data = malformed[i].1
    assert_true(data.length() > 8)
    assert_eq(data[0], b'\x89')
    assert_eq(data[1], b'\x50')
  }
  let bmp = malformed[4].1
  assert_eq(bmp[0], b'\x42')
  assert_eq(bmp[1], b'\x4D')
  let jpg = malformed[5].1
  assert_eq(jpg[0], b'\xFF')
  assert_eq(jpg[1], b'\xD8')
  // m7 保留 RIFF 魔数、m8 保留 TIFF 魔数：容器先被认出，再在越界层拒绝
  let webp = malformed[6].1
  assert_eq(webp[0], b'R')
  assert_eq(webp[1], b'I')
  assert_eq(webp[8], b'W')
  assert_eq(webp[9], b'E')
  let tiff = malformed[7].1
  assert_eq(tiff[0], b'I')
  assert_eq(tiff[1], b'I')
  assert_eq(tiff[2], b'\x2A')
}

///|
test "gen/samples: g23 固化的 VP8 lossy 位流仍是合法 WebP 头" {
  let errs : Array[String] = []
  let golden = golden_samples(errs)
  let g23 = golden[22]
  assert_eq(g23.0, "g23_webp_lossy_odd_33x33.webp")
  let data = g23.1
  assert_eq(data.length(), 756)
  assert_eq(data[0], b'R')
  assert_eq(data[1], b'I')
  assert_eq(data[2], b'F')
  assert_eq(data[3], b'F')
  assert_eq(data[8], b'W')
  // VP8 有损位流（不是 VP8L / VP8X）
  assert_eq(data[12], b'V')
  assert_eq(data[13], b'P')
  assert_eq(data[14], b'8')
  assert_eq(data[15], b' ')
}
