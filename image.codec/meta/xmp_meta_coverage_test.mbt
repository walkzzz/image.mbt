// 覆盖率测试：XMP 元数据读写往返与容错分支

///|
fn xmc_some(o : @meta.XmpInfo?) -> Bool {
  match o {
    Some(_) => true
    None => false
  }
}

///|
fn xmc_none(o : @meta.XmpInfo?) -> Bool {
  match o {
    Some(_) => false
    None => true
  }
}

///|
fn xmp_full_info() -> @meta.XmpInfo {
  @meta.XmpInfo::{
    creator: "tester",
    title: "Demo",
    description: "a demo image",
    subject: "subj",
    keywords: "kw",
    rights: "CC0",
    create_date: "2026:11:26 10:00:00",
    modify_date: "2026:11:26 11:00:00",
    software: "imgtool",
    rating: 4,
    raw_xml: "",
  }
}

///|
test "xmp: 段构造与字段裁剪" {
  let seg = @meta.create_xmp_segment(xmp_full_info())
  assert_true(seg.length() > 0)
  // 空 info：不写可选字段
  let empty = @meta.create_xmp_segment(@meta.XmpInfo::default())
  assert_true(empty.length() > 0)
  assert_true(empty.length() < seg.length())
  // 只给 rating 与软件
  let partial = @meta.create_xmp_segment(@meta.XmpInfo::{
    creator: "",
    title: "",
    description: "",
    subject: "",
    keywords: "",
    rights: "",
    create_date: "",
    modify_date: "",
    software: "x",
    rating: 1,
    raw_xml: "",
  })
  assert_true(partial.length() > 0)
}

///|
test "xmp: JPEG 写入与读回" {
  // 最小 JPEG：SOI + EOI
  let jpeg = Bytes::from_array([b'\xff', b'\xd8', b'\xff', b'\xd9'])
  let with_xmp = @meta.write_xmp_to_bytes(xmp_full_info(), jpeg) catch {
    _ => Bytes::from_array([])
  }
  assert_true(with_xmp.length() > jpeg.length())
  // 读回
  let info = @meta.read_xmp_from_bytes(with_xmp)
  assert_true(xmc_some(info))
  match info {
    Some(v) => {
      assert_true(v.creator == "tester")
      assert_true(v.title == "Demo")
      assert_true(v.software == "imgtool")
      assert_true(v.rating == 4)
      assert_true(v.raw_xml.length() > 0)
    }
    None => assert_true(false)
  }
  // 无 XMP 的裸 JPEG → None
  assert_true(xmc_none(@meta.read_xmp_from_bytes(jpeg)))
  // 非 JPEG → None
  assert_true(
    xmc_none(@meta.read_xmp_from_bytes(Bytes::from_array([0, 1, 2, 3, 4]))),
  )
  assert_true(xmc_none(@meta.read_xmp_from_bytes(Bytes::from_array([]))))
  // 已有 XMP 再写一次（替换路径）
  let again = @meta.write_xmp_to_bytes(xmp_full_info(), with_xmp) catch {
    _ => Bytes::from_array([])
  }
  assert_true(again.length() > 0)
  // 写入非 JPEG → 抛错
  try {
    let _ = @meta.write_xmp_to_bytes(
      xmp_full_info(),
      Bytes::from_array([0, 1, 2, 3]),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @meta.write_xmp_to_bytes(
      xmp_full_info(),
      Bytes::from_array([b'\xff', b'\xd8']),
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
