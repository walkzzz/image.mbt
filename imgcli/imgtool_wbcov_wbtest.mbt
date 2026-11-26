// 覆盖率测试（白盒）：imgtool 格式推断、Flags 取值、错误 JSON 与分发兜底

///|
fn[T] iwo_some(o : T?) -> Bool {
  match o {
    Some(_) => true
    None => false
  }
}

///|
fn itw_flags(pairs : Array[(String, String)]) -> Flags {
  let pos : Array[String] = []
  let vals : Map[String, String] = Map([])
  for (k, v) in pairs {
    vals[k] = v
  }
  { positional: pos, values: vals, }
}

///|
test "itw: 格式名与解析" {
  assert_true(format_name(@types.ImageFormat::Png) == "png")
  assert_true(format_name(@types.ImageFormat::Jpeg) == "jpeg")
  assert_true(format_name(@types.ImageFormat::Bmp) == "bmp")
  assert_true(format_name(@types.ImageFormat::Gif) == "gif")
  assert_true(format_name(@types.ImageFormat::Webp) == "webp")
  assert_true(format_name(@types.ImageFormat::Qoi) == "qoi")
  assert_true(format_name(@types.ImageFormat::Pnm) == "pnm")
  assert_true(format_name(@types.ImageFormat::Tga) == "tga")
  assert_true(format_name(@types.ImageFormat::Tiff) == "tiff")
  assert_true(format_name(@types.ImageFormat::Ico) == "ico")
  assert_true(format_name(@types.ImageFormat::Cur) == "cur")
  assert_true(format_name(@types.ImageFormat::Icns) == "icns")
  assert_true(format_name(@types.ImageFormat::Apng) == "apng")
  assert_true(format_name(@types.ImageFormat::Avif) == "avif")
  assert_true(format_name(@types.ImageFormat::Heif) == "heif")
  assert_true(format_name(@types.ImageFormat::JpegXl) == "jpeg-xl")
  assert_true(format_name(@types.ImageFormat::Unknown) == "unknown")
  // parse_format：合法别名
  assert_true(parse_format("png") == @types.ImageFormat::Png)
  assert_true(parse_format("jpg") == @types.ImageFormat::Jpeg)
  assert_true(parse_format("jpeg") == @types.ImageFormat::Jpeg)
  assert_true(parse_format("bmp") == @types.ImageFormat::Bmp)
  assert_true(parse_format("webp") == @types.ImageFormat::Webp)
  assert_true(parse_format("qoi") == @types.ImageFormat::Qoi)
  assert_true(parse_format("ppm") == @types.ImageFormat::Pnm)
  assert_true(parse_format("tga") == @types.ImageFormat::Tga)
  assert_true(parse_format("gif") == @types.ImageFormat::Gif)
  // 非法 → 抛错
  try {
    let _ = parse_format("heif")
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 可写格式判定
  assert_true(is_writable_format(@types.ImageFormat::Png))
  assert_true(is_writable_format(@types.ImageFormat::Gif))
  assert_true(!is_writable_format(@types.ImageFormat::Tiff))
  assert_true(!is_writable_format(@types.ImageFormat::Ico))
  assert_true(!is_writable_format(@types.ImageFormat::Avif))
}

///|
test "itw: 扩展名推断与输出格式优先级" {
  assert_true(format_from_ext("a.png") == Some(@types.ImageFormat::Png))
  assert_true(format_from_ext("A.PNG") == Some(@types.ImageFormat::Png))
  assert_true(format_from_ext("a.jpg") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.jpeg") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.jpe") == Some(@types.ImageFormat::Jpeg))
  assert_true(format_from_ext("a.webp") == Some(@types.ImageFormat::Webp))
  assert_true(format_from_ext("a.bmp") == Some(@types.ImageFormat::Bmp))
  assert_true(format_from_ext("a.qoi") == Some(@types.ImageFormat::Qoi))
  assert_true(format_from_ext("a.pnm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.ppm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.pgm") == Some(@types.ImageFormat::Pnm))
  assert_true(format_from_ext("a.tga") == Some(@types.ImageFormat::Tga))
  assert_true(format_from_ext("a.gif") == Some(@types.ImageFormat::Gif))
  // 不支持或不可写 → None
  assert_true(format_from_ext("a.tiff") == None)
  assert_true(format_from_ext("a.txt") == None)
  assert_true(format_from_ext("noext") == None)
  // out_format：显式 --format 优先
  let f1 = itw_flags([("format", "webp")])
  assert_true(
    out_format(f1, "x.png", @types.ImageFormat::Png) == @types.ImageFormat::Webp,
  )
  // format=auto 视为未指定 → 走扩展名
  let f2 = itw_flags([("format", "auto")])
  assert_true(
    out_format(f2, "x.gif", @types.ImageFormat::Png) == @types.ImageFormat::Gif,
  )
  // 无 format、无可识别扩展名 → fallback
  let f3 = itw_flags([])
  assert_true(
    out_format(f3, "x.tiff", @types.ImageFormat::Bmp) == @types.ImageFormat::Bmp,
  )
  // 非法 --format → 抛错
  try {
    let _ = out_format(
      itw_flags([("format", "ico")]),
      "x.png",
      @types.ImageFormat::Png,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 源格式：可写沿袭，不可写退 PNG
  let png = @lib.save_image_with_quality(
    @types.Image::{
      width: 2,
      height: 2,
      channels: 3,
      data: Bytes::from_array(Array::make(12, (128).to_byte())),
    },
    @types.ImageFormat::Png,
    80,
  ) catch {
    _ => Bytes::from_array([])
  }
  assert_true(src_out_format(png) == @types.ImageFormat::Png)
  assert_true(src_out_format(Bytes::from_array([])) == @types.ImageFormat::Png)
}

///|
test "itw: Flags 取值与限制" {
  let f = itw_flags([("width", "120"), ("mode", "cover"), ("sigma", "2.5")])
  assert_true(f.int("width", 0) == 120)
  assert_true(f.int("missing", 7) == 7)
  assert_true(f.str("mode", "contain") == "cover")
  assert_true(f.str("missing", "dflt") == "dflt")
  let sf = f.float("sigma", 1.0)
  assert_true(sf.to_double() > 1.0)
  let mf = f.float("missing", 3.0)
  assert_true(mf.to_double() > 0.0)
  assert_true(f.has("width"))
  assert_true(!f.has("height"))
  // 非法数字 → 默认
  let bad = itw_flags([("width", "abc"), ("sigma", "xyz")])
  assert_true(bad.int("width", 9) == 9)
  let bf = bad.float("sigma", 1.5)
  assert_true(bf.to_double() > 0.0)
  // limits_of：默认 / mem-budget / max-pixels
  let base = limits_of(itw_flags([]))
  assert_true(base.max_bytes > 0L)
  let budget = limits_of(itw_flags([("mem-budget", "8000000")]))
  assert_true(budget.max_bytes == 8000000L)
  assert_true(budget.max_pixels == 1000000L)
  let px = limits_of(
    itw_flags([("max-pixels", "500000"), ("mem-budget", "8000000")]),
  )
  assert_true(px.max_pixels == 500000L)
  // 非法 mem-budget 视为 0 → 保持默认
  let neg = limits_of(itw_flags([("mem-budget", "-100")]))
  assert_true(neg.max_bytes == base.max_bytes)
}

///|
test "itw: ASCII 搜索与错误 JSON" {
  // 空 needle → false；非法（n==0）分支
  assert_true(contains_ascii(Bytes::from_array([b'a', b'b', b'c']), "bc"))
  assert_true(!contains_ascii(Bytes::from_array([b'a', b'b']), "abc"))
  assert_true(!contains_ascii(Bytes::from_array([]), "a"))
  // error_json
  let err = @types.ImageError::Process(
    @types.ErrorCode::InvalidArgument,
    "测试错误",
  )
  let out = error_json(err)
  assert_true(iwo_some(out.get("ok")))
  assert_true(iwo_some(out.get("code")))
  assert_true(iwo_some(out.get("message")))
  assert_true(iwo_some(out.get("hint")))
  // help / version 文本
  let help = help_text()
  assert_true(help.contains("imgtool"))
  assert_true(help.contains("convert"))
  let ver = version_text()
  assert_true(ver.contains("imgtool"))
  // 分发：空参数与未知子命令走 usage；help 同样兜底
  assert_true(iwo_some(dispatch([]).get("code")))
  assert_true(iwo_some(dispatch(["unknown"]).get("code")))
  assert_true(iwo_some(dispatch(["help"]).get("code")))
}
