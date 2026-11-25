///|
/// M2 体积探针：不同图像内容下 LZ77 与 literal-only 的体积对比。

///|
fn vp8l_probe_solid(width : Int32, height : Int32) -> @types.Image {
  let w = width.to_int()
  let h = height.to_int()
  let src : Array[Byte] = []
  for _y in 0..<h {
    for _x in 0..<w {
      src.push(40)
      src.push(120)
      src.push(200)
      src.push(255)
    }
  }
  @types.Image::{ width, height, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_probe_repeat(width : Int32, height : Int32) -> @types.Image {
  let w = width.to_int()
  let h = height.to_int()
  let src : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      let v = ((x / 8) + (y / 8)) % 2
      src.push(if v == 0 { 30 } else { 220 })
      src.push(if v == 0 { 60 } else { 190 })
      src.push(if v == 0 { 90 } else { 160 })
      src.push(255)
    }
  }
  @types.Image::{ width, height, channels: 4, data: Bytes::from_array(src) }
}

///|
fn vp8l_probe_noise(width : Int32, height : Int32) -> @types.Image {
  let w = width.to_int()
  let h = height.to_int()
  let src : Array[Byte] = []
  let mut seed = 12345
  for _y in 0..<h {
    for _x in 0..<w {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
      src.push((seed / 65536 % 256).to_byte())
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
      src.push((seed / 65536 % 256).to_byte())
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
      src.push((seed / 65536 % 256).to_byte())
      src.push(255)
    }
  }
  @types.Image::{ width, height, channels: 4, data: Bytes::from_array(src) }
}

///|
test "vp8l M2 体积探针" {
  let cases : Array[(String, @types.Image)] = [
    ("纯色 64x64", vp8l_probe_solid(64, 64)),
    ("纯色 256x256", vp8l_probe_solid(256, 256)),
    ("棋盘图案 256x256", vp8l_probe_repeat(256, 256)),
    ("噪声 256x256", vp8l_probe_noise(256, 256)),
  ]
  for (name, img) in cases {
    let lz = try @codec.encode_webp_vp8l_lz77(img) catch {
      _ => Bytes::from_array([])
    }
    let lit = try @codec.encode_webp_vp8l_literal(img) catch {
      _ => Bytes::from_array([])
    }
    let png = @codec.encode_png_pure(img)
    let px = img.width.to_int() * img.height.to_int()
    let ratio = if lz.length() > 0 { 100.0 * lz.length().to_double() / (px * 4).to_double() } else { 0.0 }
    println("\{name}: LZ77=\{lz.length()} literal=\{lit.length()} png=\{png.length()} 原始=\{px * 4} 占比=\{ratio}%")
  }
}

///|
test "vp8l RGBA dump" {
  let src : Array[Byte] = []
  for i in 0..<1024 {
    src.push(((i * 7 + 3) % 256).to_byte())
  }
  let img = @types.Image::{ width: 16, height: 16, channels: 4, data: Bytes::from_array(src) }
  let enc = try @codec.encode_webp_vp8l_lz77(img) catch { _ => Bytes::from_array([]) }
  println("RGBA_HEX=" + vp8l_to_hex(enc))
}

///|
test "vp8l RGBA 尺寸阶梯回环" {
  for side in [2, 4, 8, 16, 32] {
    let n = side * side * 4
    let src : Array[Byte] = []
    for i in 0..<n {
      src.push(((i * 7 + 3) % 256).to_byte())
    }
    let img = @types.Image::{ width: side, height: side, channels: 4, data: Bytes::from_array(src) }
    let enc = try @codec.encode_webp_vp8l_lz77(img) catch { _ => Bytes::from_array([]) }
    let dec = try @codec.decode_webp_vp8l_rfc(enc) catch { _ => img }
    let mut bad = 0
    let mut first = -1
    for i in 0..<n {
      if dec.data[i] != src[i] {
        if first < 0 { first = i }
        bad += 1
      }
    }
    println("side=\{side} 差异=\{bad} 首个=\{first} 体积=\{enc.length()}")
  }
}
