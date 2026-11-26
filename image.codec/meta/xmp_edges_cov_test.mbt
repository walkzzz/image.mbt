// 覆盖率测试：XMP 扫描分支（非 XMP APP1 / 其他段 / 裸字节 / 替换 / 非 ASCII）

///|
fn xec_some(o : @meta.XmpInfo?) -> Bool {
  match o {
    Some(_) => true
    None => false
  }
}

///|
fn xec_none(o : @meta.XmpInfo?) -> Bool {
  match o {
    Some(_) => false
    None => true
  }
}

///|
fn xec_app1(payload : Bytes) -> Array[Byte] {
  let seg_len = payload.length() + 2
  let seg : Array[Byte] = [
    0xFF,
    0xE1,
    (seg_len >> 8).to_byte(),
    (seg_len & 0xFF).to_byte(),
  ]
  for i in 0..<payload.length() {
    seg.push(payload[i])
  }
  seg
}

///|
fn xec_concat(a : Array[Byte], b : Array[Byte]) -> Array[Byte] {
  let out : Array[Byte] = []
  for i in 0..<a.length() {
    out.push(a[i])
  }
  for i in 0..<b.length() {
    out.push(b[i])
  }
  out
}

///|
fn xec_info(title : String) -> @meta.XmpInfo {
  @meta.XmpInfo::{
    creator: "tester",
    title,
    description: "",
    subject: "",
    keywords: "",
    rights: "",
    create_date: "",
    modify_date: "",
    software: "imgtool",
    rating: 3,
    raw_xml: "",
  }
}

///|
fn xec_xmp_payload(xml : String) -> Bytes {
  let out : Array[Byte] = []
  let ns = "http://ns.adobe.com/xap/1.0/"
  for c in ns.to_array() {
    out.push(c.to_int().to_byte())
  }
  out.push(b'\x00')
  for c in xml.to_array() {
    out.push(c.to_int().to_byte())
  }
  Bytes::from_array(out)
}

///|
test "xmp 扫描: 非 XMP 的 APP1 段被跳过" {
  let app1 = xec_app1(Bytes::from_array([b'j', b'u', b'n', b'k']))
  let jpeg = Bytes::from_array(
    xec_concat(xec_concat([0xFF, 0xD8], app1), [
      0xFF, 0xDA, 0x00, 0x02, 0xFF, 0xD9,
    ]),
  )
  assert_true(xec_none(@meta.read_xmp_from_bytes(jpeg)))
  let written = @meta.write_xmp_to_bytes(xec_info("N"), jpeg) catch {
    _ => Bytes::from_array([])
  }
  assert_true(written.length() > jpeg.length())
  assert_true(xec_some(@meta.read_xmp_from_bytes(written)))
}

///|
test "xmp 扫描: 其他 0xFF 段按长度跳过" {
  let jpeg = Bytes::from_array([
    0xFF, 0xD8, 0xFF, 0xDB, 0x00, 0x04, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x02, 0xFF,
    0xD9,
  ])
  assert_true(xec_none(@meta.read_xmp_from_bytes(jpeg)))
  let written = @meta.write_xmp_to_bytes(xec_info("S"), jpeg) catch {
    _ => Bytes::from_array([])
  }
  assert_true(written.length() > jpeg.length())
  assert_true(xec_some(@meta.read_xmp_from_bytes(written)))
}

///|
test "xmp 扫描: 非标记字节逐字节前进" {
  let jpeg = Bytes::from_array([0xFF, 0xD8, 0x00, 0x11, 0xFF, 0xDA, 0x00, 0x02])
  assert_true(xec_none(@meta.read_xmp_from_bytes(jpeg)))
  let written = @meta.write_xmp_to_bytes(xec_info("B"), jpeg) catch {
    _ => Bytes::from_array([])
  }
  assert_true(written.length() > jpeg.length())
}

///|
test "xmp 扫描: 声明长度超出数据的 APP1 返回 None" {
  // 段长为 0x0100，但实际只有少量数据
  let payload = xec_xmp_payload("<dc:title>T</dc:title>")
  let seg : Array[Byte] = [0xFF, 0xE1, 0x01, 0x00]
  for i in 0..<payload.length() {
    seg.push(payload[i])
  }
  let jpeg = Bytes::from_array(
    xec_concat([0xFF, 0xD8], xec_concat(seg, [0xFF, 0xD9])),
  )
  assert_true(xec_none(@meta.read_xmp_from_bytes(jpeg)))
}

///|
test "xmp 替换: 已有 XMP 段原位替换" {
  let old = @meta.write_xmp_to_bytes(
    xec_info("OLD"),
    Bytes::from_array([b'\xff', b'\xd8', b'\xff', b'\xd9']),
  ) catch {
    _ => Bytes::from_array([])
  }
  let fresh = @meta.write_xmp_to_bytes(xec_info("NEW"), old) catch {
    _ => Bytes::from_array([])
  }
  assert_true(fresh.length() > 0)
  match @meta.read_xmp_from_bytes(fresh) {
    Some(v) => assert_true(v.title == "NEW")
    None => assert_true(false)
  }
}

///|
test "xmp 评分: 负数/正号/非法文本" {
  let neg = Bytes::from_array(
    xec_concat(
      [0xFF, 0xD8],
      xec_concat(xec_app1(xec_xmp_payload("<xmp:Rating>-3</xmp:Rating>")), [
        0xFF, 0xDA, 0x00, 0x02,
      ]),
    ),
  )
  match @meta.read_xmp_from_bytes(neg) {
    Some(v) => assert_true(v.rating == -3)
    None => assert_true(false)
  }
  let plus = Bytes::from_array(
    xec_concat(
      [0xFF, 0xD8],
      xec_concat(xec_app1(xec_xmp_payload("<xmp:Rating>+7</xmp:Rating>")), [
        0xFF, 0xDA, 0x00, 0x02,
      ]),
    ),
  )
  match @meta.read_xmp_from_bytes(plus) {
    Some(v) => assert_true(v.rating == 7)
    None => assert_true(false)
  }
  let bad = Bytes::from_array(
    xec_concat(
      [0xFF, 0xD8],
      xec_concat(xec_app1(xec_xmp_payload("<xmp:Rating>xx</xmp:Rating>")), [
        0xFF, 0xDA, 0x00, 0x02,
      ]),
    ),
  )
  match @meta.read_xmp_from_bytes(bad) {
    Some(v) => assert_true(v.rating == 0)
    None => assert_true(false)
  }
}

///|
test "xmp 段构造: 非 ASCII 字段写成问号" {
  let seg = @meta.create_xmp_segment(xec_info("中文标题"))
  let mut question = 0
  for i in 0..<seg.length() {
    if seg[i].to_int() == 0x3F {
      question = question + 1
    }
  }
  assert_true(question > 0)
  // 所有输出字节均落在 ASCII 范围
  let mut ascii_only = true
  for i in 0..<seg.length() {
    if seg[i].to_int() > 0x7F {
      ascii_only = false
    }
  }
  assert_true(ascii_only)
}
