///|
/// RAW RGB 像素 → PNG 编码 → 解码校验（零外部文件依赖）。
fn make_rgb(w : Int32, h : Int32, pixels : Array[Int32]) -> @types.Image {
  let data : Array[Byte] = []
  for p in pixels {
    data.push(p.to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
fn main {
  let img = make_rgb(2, 2, [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0])
  let png = @codec.encode_png_pure(img)
  println("PNG bytes: \{png.length()}")
  try {
    let back = @codec.decode_png_pure(png)
    println("decoded: \{back.width}x\{back.height} channels=\{back.channels}")
    let mut same = back.width == img.width &&
      back.height == img.height &&
      back.channels == img.channels
    for i in 0..<img.data.length() {
      if back.data[i] != img.data[i] {
        same = false
      }
    }
    println("pixel-exact roundtrip: \{same}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("decode failed: \{msg}")
    _ => println("decode failed")
  }
}
