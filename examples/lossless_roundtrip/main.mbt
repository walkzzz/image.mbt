///|
fn same_pixels(a : @types.Image, b : @types.Image) -> Bool {
  if a.width != b.width || a.height != b.height || a.channels != b.channels {
    return false
  }
  for i in 0..<a.data.length() {
    if a.data[i] != b.data[i] {
      return false
    }
  }
  true
}

///|
fn main {
  let data : Array[Byte] = []
  for i in 0..<48 {
    data.push((i * 5 % 256).to_byte())
  }
  let img = @types.Image::{
    width: 4,
    height: 4,
    channels: 3,
    data: Bytes::from_array(data),
  }
  let bmp = @codec.encode_bmp_pure(img)
  try {
    let back = @codec.decode_bmp_pure(bmp)
    println("bmp: \{bmp.length()} bytes, pixel-exact=\{same_pixels(img, back)}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("bmp failed: \{msg}")
    _ => println("bmp failed")
  }
  try {
    let qoi = @codec.encode_qoi_pure(img)
    let back = @codec.decode_qoi_pure(qoi)
    println("qoi: \{qoi.length()} bytes, pixel-exact=\{same_pixels(img, back)}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("qoi failed: \{msg}")
    _ => println("qoi failed")
  }
}
