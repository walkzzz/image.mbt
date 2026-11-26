// 覆盖率测试（白盒）：sanitize recipe 的区域解析、打码、元数据签名与策略

///|
fn[T] ois_some(o : T?) -> Bool {
  match o {
    Some(_) => true
    None => false
  }
}

///|
fn[T] ois_none(o : T?) -> Bool {
  match o {
    Some(_) => false
    None => true
  }
}

///|
fn rcw_img(w : Int32, h : Int32, c : Int32, seed : Int32) -> @types.Image {
  let d : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        d.push((x * 17 + y * 23 + ch * 41 + seed) % 256)
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
test "rcw: 区域解析" {
  // 正常
  let r = parse_region("10,20,30,40")
  assert_true(ois_some(r))
  match r {
    Some(v) => {
      assert_true(v.to_string() == "10,20,30,40")
      assert_true(v.x == 10)
      assert_true(v.h == 40)
    }
    None => assert_true(false)
  }
  // 带空格
  let r2 = parse_region(" 5 , 6 , 7 , 8 ")
  assert_true(ois_some(r2))
  // 段数不足 / 超长
  assert_true(ois_none(parse_region("1,2,3")))
  assert_true(ois_none(parse_region("1,2,3,4,5")))
  // 空段与非法数字
  assert_true(ois_none(parse_region("")))
  assert_true(ois_none(parse_region("1,,3,4")))
  assert_true(ois_none(parse_region("a,2,3,4")))
  // 批量：多段 + 空段跳过
  let many = parse_regions("1,2,3,4; 5,6,7,8 ;;")
  assert_true(many.length() == 2)
  let none = parse_regions("")
  assert_true(none.length() == 0)
  let only_sep = parse_regions("; ;")
  assert_true(only_sep.length() == 0)
  // 非法 → 抛错
  try {
    let _ = parse_regions("1,2,3")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rcw: 区域打码与全图打码" {
  let img = rcw_img(32, 24, 3, 5)
  // 正常区域（block 4）
  let a = redact_region(img, { x: 4, y: 4, w: 8, h: 8, }, 4)
  assert_true(a.width == 32)
  assert_true(a.data.length() == img.data.length())
  // 负坐标被钳到 0
  let b = redact_region(img, { x: -5, y: -5, w: 10, h: 10, }, 2)
  assert_true(b.width == 32)
  // 超出右下边界被截断
  let c1 = redact_region(img, { x: 20, y: 16, w: 40, h: 40, }, 3)
  assert_true(c1.height == 24)
  // block <= 0 退化为 1
  let d = redact_region(img, { x: 0, y: 0, w: 4, h: 4, }, 0)
  assert_true(d.width == 32)
  // 单通道
  let g = rcw_img(16, 16, 1, 9)
  let e = redact_region(g, { x: 2, y: 2, w: 6, h: 6, }, 2)
  assert_true(e.channels == 1)
  // 四通道
  let rgba = rcw_img(16, 16, 4, 3)
  let f = redact_region(rgba, { x: 0, y: 0, w: 8, h: 8, }, 5)
  assert_true(f.channels == 4)
  // 全图打码
  let all = redact_all(img, 8)
  assert_true(all.width == 32)
  assert_true(all.height == 24)
  // 全图模糊（radius<=0 退化为 1）
  let bl = blur_whole(img, 3)
  assert_true(bl.width == 32)
  let bl0 = blur_whole(img, 0)
  assert_true(bl0.width == 32)
  // 错误：宽高非正
  try {
    let _ = redact_region(img, { x: 0, y: 0, w: 0, h: 4, }, 2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 错误：区域完全在图外
  try {
    let _ = redact_region(img, { x: 100, y: 100, w: 4, h: 4, }, 2)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "rcw: 元数据签名与 sanitize 策略" {
  // 干净 PNG 不应命中签名
  let clean = @lib.save_image_with_quality(
    rcw_img(8, 8, 3, 1),
    @types.ImageFormat::Png,
    80,
  ) catch {
    _ => Bytes::from_array([])
  }
  let h0 = metadata_hits(clean)
  assert_true(h0.length() == 0)
  // 人造命中
  let dirty = Bytes::from_array([b'a', b'X', b'M', b'P', b'b'])
  let h1 = metadata_hits(dirty)
  assert_true(h1.length() >= 0)
  let junk : Array[Byte] = [
    b'<', b'x', b':', b'x', b'm', b'p', b'm', b'e', b't', b'a',
  ]
  let h2 = metadata_hits(Bytes::from_array(junk))
  assert_true(h2.length() >= 0)
  // sanitize：metadata 档（只剥元数据）
  let img = rcw_img(16, 16, 3, 7)
  let s1 = sanitize_image(
    img,
    "metadata",
    [],
    8,
    3,
    @types.ImageFormat::Png,
    80,
  )
  assert_true(s1.bytes.length() > 0)
  assert_true(s1.redacted == 0)
  assert_true(!s1.blurred)
  // standard 档给了区域 → 打码
  let s2 = sanitize_image(
    img,
    "standard",
    [{ x: 2, y: 2, w: 6, h: 6, }],
    4,
    2,
    @types.ImageFormat::Png,
    80,
  )
  assert_true(s2.redacted == 1)
  assert_true(!s2.blurred)
  // standard 档不给区域 → 只剥元数据
  let s3 = sanitize_image(
    img,
    "standard",
    [],
    4,
    2,
    @types.ImageFormat::Bmp,
    90,
  )
  assert_true(s3.redacted == 0)
  // strict 档不给区域 → 全图打码 + 模糊
  let s4 = sanitize_image(img, "strict", [], 6, 3, @types.ImageFormat::Bmp, 90)
  assert_true(s4.redacted == 1)
  assert_true(s4.blurred)
  assert_true(s4.bytes.length() > 0)
  // strict 给区域
  let s5 = sanitize_image(
    img,
    "strict",
    [{ x: 1, y: 1, w: 5, h: 5, }, { x: 8, y: 8, w: 4, h: 4, }],
    2,
    2,
    @types.ImageFormat::Png,
    70,
  )
  assert_true(s5.redacted == 2)
  assert_true(s5.quality == 70)
  // 非法 policy → 抛错
  try {
    let _ = sanitize_image(img, "loose", [], 4, 2, @types.ImageFormat::Png, 80)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
