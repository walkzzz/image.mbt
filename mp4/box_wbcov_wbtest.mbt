// 白盒覆盖：MP4 box 解析（fourcc / u32/u64 读取 / 单层遍历 / 查找与收集）

fn mbx_box(size : Int32, ty : String) -> Array[Byte] {
  let out : Array[Byte] = []
  out.push((size >> 24).to_byte())
  out.push(((size >> 16) & 0xFF).to_byte())
  out.push(((size >> 8) & 0xFF).to_byte())
  out.push((size & 0xFF).to_byte())
  for i in 0..<4 {
    out.push(ty[i].to_int().to_byte())
  }
  for _ in 0..<(size - 8) {
    out.push((0).to_byte())
  }
  out
}

test "mp4box: fourcc 与整数读取" {
  let data = Bytes::from_array([
    (0x66).to_byte(), (0x74).to_byte(), (0x79).to_byte(), (0x70).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
  ])
  assert_true(fourcc(data, 0) == "ftyp")
  // 非 ASCII 字节 → U+FFFD
  let weird = Bytes::from_array([
    (0xFF).to_byte(), (0x00).to_byte(), (0x41).to_byte(), (0xFE).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
  ])
  let s = fourcc(weird, 0)
  let _ = s
  assert_true(read_u32(data, 0) == 0x66747970)
  assert_true(read_u64(weird, 8) == 0L)
  // 大端 u64
  let big = Bytes::from_array([
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (1).to_byte(),
  ])
  assert_true(read_u64(big, 0) == 1L)
  assert_true(read_u32(weird, 4) == 0)
}

test "mp4box: 单层遍历各分支" {
  // 普通 box：ftyp(16) + moov(24)
  let ftyp = mbx_box(16, "ftyp")
  let moov = mbx_box(24, "moov")
  let buf : Array[Byte] = []
  for b in ftyp {
    buf.push(b)
  }
  for b in moov {
    buf.push(b)
  }
  let data = Bytes::from_array(buf)
  let seen : Array[String] = []
  walk_boxes_one_level(data, 0, data.length(), fn(b) {
    seen.push(b.box_type)
  })
  assert_true(seen.length() == 2)
  assert_true(seen[0] == "ftyp")
  assert_true(seen[1] == "moov")

  // size==0：延伸至末尾（修复后应解析出 2 个 box）
  let z : Array[Byte] = [
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (16).to_byte(),
    (0x66).to_byte(), (0x74).to_byte(), (0x79).to_byte(), (0x70).to_byte(),
    (1).to_byte(), (2).to_byte(), (3).to_byte(), (4).to_byte(),
    (5).to_byte(), (6).to_byte(), (7).to_byte(), (8).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0x6d).to_byte(), (0x64).to_byte(), (0x61).to_byte(), (0x74).to_byte(),
    (1).to_byte(), (2).to_byte(),
  ]
  let zeros = Bytes::from_array(z)
  let got : Array[Int32] = []
  let got_ty : Array[String] = []
  walk_boxes_one_level(zeros, 0, zeros.length(), fn(b) {
    got.push(b.size)
    got_ty.push(b.box_type)
  })
  assert_true(got.length() == 2)
  assert_true(got[1] == zeros.length() - 16)

  // size==1：largesize 合法（总长 32 = 16 头 + 16 负载）
  let l1 : Array[Byte] = [
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (1).to_byte(),
    (0x6d).to_byte(), (0x6f).to_byte(), (0x6f).to_byte(), (0x76).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0x20).to_byte(),
    (7).to_byte(), (7).to_byte(), (7).to_byte(), (7).to_byte(),
    (7).to_byte(), (7).to_byte(), (7).to_byte(), (7).to_byte(),
    (7).to_byte(), (7).to_byte(), (7).to_byte(), (7).to_byte(),
    (7).to_byte(), (7).to_byte(), (7).to_byte(), (7).to_byte(),
  ]
  let large = Bytes::from_array(l1)
  assert_true(large.length() == 32)
  assert_true(read_u32(large, 0) == 1)
  assert_true(read_u64(large, 8) == 32L)
  let got2 : Array[Int32] = []
  let got2s : Array[Int32] = []
  walk_boxes_one_level(large, 0, large.length(), fn(b) {
    got2.push(b.payload_start)
    got2s.push(b.size)
  })
  assert_true(got2.length() == 1)
  println(large.length().to_string() + "/" + got2.length().to_string())
  assert_true(got2[0] == 16)
  assert_true(got2s[0] == 32)

  // size==1 且 largesize 越界 → 提前返回
  let l2 = Bytes::from_array([
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (1).to_byte(),
    (0x6d).to_byte(), (0x6f).to_byte(), (0x6f).to_byte(), (0x76).to_byte(),
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (0).to_byte(),
    (0).to_byte(), (0).to_byte(), (1).to_byte(), (0).to_byte(),
  ])
  let out3 : Array[String] = []
  walk_boxes_one_level(l2, 0, l2.length(), fn(b) {
    out3.push(b.box_type)
  })
  assert_true(out3.length() == 0)

  // 非法 size（< header）→ 停止
  let bad = Bytes::from_array([
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (4).to_byte(),
    (0x61).to_byte(), (0x62).to_byte(), (0x63).to_byte(), (0x64).to_byte(),
  ])
  let out4 : Array[String] = []
  walk_boxes_one_level(bad, 0, bad.length(), fn(b) {
    out4.push(b.box_type)
  })
  assert_true(out4.length() == 0)

  // off+total 越界 → 停止
  let trunc = Bytes::from_array([
    (0).to_byte(), (0).to_byte(), (0).to_byte(), (100).to_byte(),
    (0x61).to_byte(), (0x62).to_byte(), (0x63).to_byte(), (0x64).to_byte(),
  ])
  let out5 : Array[String] = []
  walk_boxes_one_level(trunc, 0, trunc.length(), fn(b) {
    out5.push(b.box_type)
  })
  assert_true(out5.length() == 0)
}

test "mp4box: find / collect" {
  let a = mbx_box(16, "ftyp")
  let b1 = mbx_box(16, "trak")
  let b2 = mbx_box(16, "trak")
  let buf : Array[Byte] = []
  for x in a {
    buf.push(x)
  }
  for x in b1 {
    buf.push(x)
  }
  for x in b2 {
    buf.push(x)
  }
  let data = Bytes::from_array(buf)
  let found = find_box(data, 0, data.length(), "trak")
  match found {
    Some(bx) => assert_true(bx.start == 16)
    None => assert_true(false)
  }
  let none = find_box(data, 0, data.length(), "mdat")
  match none {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  let all = collect_boxes(data, 0, data.length(), "trak")
  assert_true(all.length() == 2)
  // 第二个同类型命中时走 Some(_) 分支
  let dups : Array[Byte] = []
  for x in a {
    dups.push(x)
  }
  for x in a {
    dups.push(x)
  }
  let d2 = Bytes::from_array(dups)
  let f2 = find_box(d2, 0, d2.length(), "ftyp")
  match f2 {
    Some(bx) => assert_true(bx.start == 0)
    None => assert_true(false)
  }
  assert_true(payload_u32_at(d2, 0, 0) > 0)
  assert_true(payload_u64_at(d2, 0, 0) >= 0L)
}
