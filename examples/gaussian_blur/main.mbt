///|
fn center(img : @types.Image) -> Int32 {
  let cx = img.width / 2
  let cy = img.height / 2
  img.data[cy * img.width + cx].to_int()
}

///|
fn main {
  let data : Array[Byte] = Array::make(81, b'\x00')
  data[4 * 9 + 4] = b'\xFF'
  let img = @types.Image::{
    width: 9,
    height: 9,
    channels: 1,
    data: Bytes::from_array(data),
  }
  println("center before blur: \{center(img)}")
  try {
    let blurred = @filter.gaussian_blur(img, 2, 1.5F)
    println("center after blur: \{center(blurred)}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("blur failed: \{msg}")
    _ => println("blur failed")
  }
}
