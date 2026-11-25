///|
test "parse_flags 分离位置参数与 --key value" {
  let f = parse_flags([
    "in.png", "out.png", "--format", "jpeg", "--quality", "88",
  ])
  inspect(f.positional.length(), content="2")
  inspect(f.positional[0], content="in.png")
  inspect(f.str("format", "png"), content="jpeg")
  inspect(f.int("quality", 90), content="88")
}

///|
test "parse_flags 缺值 flag 记作 true 且不吞后续 flag" {
  let f = parse_flags(["in.png", "--fast", "--width", "64"])
  inspect(f.str("fast", ""), content="true")
  inspect(f.int("width", -1), content="64")
  inspect(f.has("fast"), content="true")
}

///|
test "parse_flags 非数字回落到默认值" {
  let f = parse_flags(["--quality", "abc"])
  inspect(f.int("quality", 90), content="90")
}

///|
test "contains_ascii 命中与未命中" {
  let data : Bytes = b"\x00Exif\x00GPSLatitude"
  inspect(contains_ascii(data, "Exif"), content="true")
  inspect(contains_ascii(data, "GPS"), content="true")
  inspect(contains_ascii(data, "XMP"), content="false")
  inspect(contains_ascii(b"", "Exif"), content="false")
}

///|
test "limits_of 把 --mem-budget 折成像素与字节上限" {
  let f = parse_flags(["--mem-budget", "1048576"])
  let l = limits_of(f)
  inspect(l.max_bytes, content="1048576")
  inspect(l.max_pixels, content="131072")
  let d = limits_of(parse_flags(([] : Array[String])))
  inspect(
    d.max_bytes == @types.DecodeLimits::default_limits().max_bytes,
    content="true",
  )
}
