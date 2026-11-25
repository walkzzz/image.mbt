///|
test "redact_region 把区域压成块均值" {
  // 16x16 纯渐变图，整图按 4x4 打码后，同块内应完全相等
  let w = 16
  let img : @types.Image = {
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(Array::make(256, b'\x00').map(fn(_) { b'\x00' })),
  }
  let data : Array[Byte] = []
  for i in 0..<(w * w) {
    data.push((i % 256).to_byte())
  }
  let g : @types.Image = {
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let out = redact_region(g, { x: 0, y: 0, w: 16, h: 16, }, 4)
  // 第一个 4x4 块内 16 个像素必须相等
  let first = out.data[0]
  let mut same = true
  for yy in 0..<4 {
    for xx in 0..<4 {
      if out.data[yy * 16 + xx] != first {
        same = false
      }
    }
  }
  inspect(same, content="true")
  inspect(out.width, content="16")
  ignore(img)
}

///|
test "parse_region 解析与拒绝" {
  let r = parse_region("10,20,30,40")
  inspect(r is Some(_), content="true")
  match r {
    Some(v) => inspect(v.to_string(), content="10,20,30,40")
    None => inspect("none", content="none")
  }
  inspect(parse_region("1,2,3") is None, content="true")
  inspect(parse_region("1,2,x,4") is None, content="true")
}

///|
test "metadata_hits 命中签名" {
  let dirty : Bytes = b"\xff\xe1Exif\x00\x00GPSLatitude"
  inspect(metadata_hits(dirty).length(), content="2")
  let clean : Bytes = b"\x89PNG\r\n\x1a\n"
  inspect(metadata_hits(clean).length(), content="0")
}
