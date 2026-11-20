///|
fn fmt_name(f : @types.ImageFormat) -> String {
  match f {
    @types.ImageFormat::Png => "Png"
    @types.ImageFormat::Bmp => "Bmp"
    @types.ImageFormat::Qoi => "Qoi"
    @types.ImageFormat::Jpeg => "Jpeg"
    _ => "Other"
  }
}

///|
fn main {
  let img = @types.Image::{
    width: 2,
    height: 2,
    channels: 3,
    data: b"\xFF\x00\x00\x00\xFF\x00\x00\x00\xFF\xFF\xFF\x00",
  }
  let png = @codec.encode_png_pure(img)
  let bmp = @codec.encode_bmp_pure(img)
  println("png bytes=\{png.length()} -> \{fmt_name(@lib.detect_format(png))}")
  println("bmp bytes=\{bmp.length()} -> \{fmt_name(@lib.detect_format(bmp))}")
  try {
    let qoi = @codec.encode_qoi_pure(img)
    println("qoi bytes=\{qoi.length()} -> \{fmt_name(@lib.detect_format(qoi))}")
  } catch {
    @types.LoadError::DecodeFailed(msg) => println("qoi failed: \{msg}")
    _ => println("qoi failed")
  }
}
