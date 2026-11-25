///|
/// # 区域解码入口 Region decode entry
///
/// 按魔数自动识别 PNG / BMP / QOI，只解码请求矩形。
pub fn decode_region(
  data : Bytes,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.Image raise @types.LoadError {
  match detect_format(data) {
    @types.ImageFormat::Png => @codec.decode_png_region(data, x, y, w, h)
    @types.ImageFormat::Bmp => @codec.decode_bmp_region(data, x, y, w, h)
    @types.ImageFormat::Qoi => @codec.decode_qoi_region(data, x, y, w, h)
    _ =>
      raise @types.LoadError::DecodeFailed(
        "decode_region 暂只支持 PNG / BMP / QOI",
      )
  }
}
