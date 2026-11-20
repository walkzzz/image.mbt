///|
fn main {
  let data : Array[Byte] = Array::make(100, b'\x00')
  for y in 0..<10 {
    for x in 0..<10 {
      data[y * 10 + x] = if x < 5 { b'\x00' } else { b'\xFF' }
    }
  }
  let img = @types.Image::{
    width: 10,
    height: 10,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let out = @segment.threshold_otsu(img)
  let mut white = 0
  for i in 0..<100 {
    if out.data[i].to_int() == 255 {
      white += 1
    }
  }
  println("threshold_otsu: black=\{100 - white} white=\{white}")
}
