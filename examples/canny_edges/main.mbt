///|
fn main {
  let data : Array[Byte] = Array::make(256, b'\x00')
  for y in 4..<12 {
    for x in 4..<12 {
      data[y * 16 + x] = b'\xFF'
    }
  }
  let img = @types.Image::{
    width: 16,
    height: 16,
    channels: 1,
    data: Bytes::from_array(data),
  }
  try {
    let edges = @edge.canny_edge(img, low_threshold=50, high_threshold=100)
    let mut n = 0
    for i in 0..<256 {
      if edges.data[i].to_int() == 255 {
        n += 1
      }
    }
    println("canny edges: \{n} / 256 pixels")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("canny failed: \{msg}")
    _ => println("canny failed")
  }
}
