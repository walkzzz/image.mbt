///|
/// # 动画入口 Animation entry
///
/// 统一 GIF / APNG 的帧与延迟读取，并提供 APNG 编码包装。

///|
/// 解码动画（GIF / APNG），返回帧数组与每帧延迟（毫秒）。
/// 非动画格式报 `DecodeFailed`。
pub fn decode_animation(
  data : Bytes,
) -> (Array[@types.Image], Array[Int32]) raise @types.LoadError {
  match detect_format(data) {
    @types.ImageFormat::Apng => {
      let anim = @codec.decode_apng_pure(data)
      (anim.frames, anim.delays)
    }
    @types.ImageFormat::Gif => {
      let anim = @codec.decode_gif_animation_pure(data)
      (anim.frames, anim.delays)
    }
    _ =>
      raise @types.LoadError::DecodeFailed(
        "decode_animation 仅支持 GIF / APNG",
      )
  }
}

///|
/// 将帧序列 + 延迟（毫秒）编码为 APNG。
/// 帧数必须 ≥1，`delays` 长度必须与 `frames` 一致，所有帧尺寸必须相同。
pub fn encode_apng(
  frames : Array[@types.Image],
  delays : Array[Int32],
) -> Bytes raise @types.LoadError {
  if frames.length() == 0 {
    raise @types.LoadError::EncodeFailed("APNG 至少需要一帧")
  }
  if delays.length() != frames.length() {
    raise @types.LoadError::EncodeFailed(
      "APNG frames 与 delays 长度不一致",
    )
  }
  @codec.encode_apng_pure(@types.PngAnimation::{ frames, delays, })
}
