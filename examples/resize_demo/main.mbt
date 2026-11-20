///|
fn make_gray(w : Int32, h : Int32, pixels : Array[Int32]) -> @types.Image {
  let data : Array[Byte] = []
  for p in pixels {
    data.push(p.to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
fn main {
  let pixels : Array[Int32] = []
  for y in 0..<4 {
    for x in 0..<4 {
      pixels.push((x + y) * 16)
    }
  }
  let img = make_gray(4, 4, pixels)
  println("source: 4x4 (values 0..96)")
  try {
    let up = @util.resize_pure(img, 8, 8)
    println(
      "upscale: \{up.width}x\{up.height} first=\{up.data[0].to_int()} last=\{up.data[up.data.length() - 1].to_int()}",
    )
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("resize failed: \{msg}")
    _ => println("resize failed")
  }
  try {
    let down = @util.resize_pure(img, 2, 2)
    println("downscale: \{down.width}x\{down.height}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("resize failed: \{msg}")
    _ => println("resize failed")
  }
}
