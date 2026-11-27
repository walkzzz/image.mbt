///|
/// # TGA 解码 TGA Decode
///
/// TGA 图像格式解码 TGA image format decoding
// 纯 MoonBit TGA 解码器
// 支持 image type 2（未压缩 RGB）和 type 10（RLE RGB）
// 24-bit（BGR→RGB）和 32-bit（BGRA→RGBA）
// 规范: https://en.wikipedia.org/wiki/Truevision_TGA

///|
/// 解码 TGA 字节流为 Image（24-bit -> channels=3, 32-bit -> channels=4），支持 image type 2（未压缩 RGB）和 type 10（RLE RGB） Decode TGA byte stream to Image (24-bit -> channels=3, 32-bit -> channels=4), Supports image type 2 (uncompressed RGB) and type 10 (RLE RGB)

///|
/// 参数 Parameters:
/// - `data` - TGA 字节流 TGA byte stream
///
/// 返回 Return:
/// - 解码后的 8-bit Image Decoded 8-bit Image
///
/// 错误 Errors:
/// - `LoadError::DecodeFailed` - 数据过短、不支持的类型/位深、尺寸无效、像素越界 Data too short, unsupported type/bpp, invalid dimensions, pixel out of bounds
///
/// ```mbt check
/// test "doc_decode_tga_pure" {
///   try {
///     let data = Bytes::from_array([b'\xff', b'\x00', b'\x00'])
///     let img = @types.Image::{ width: 1, height: 1, channels: 3, data, }
///     let tga_bytes = @codec.encode_tga_pure(img)
///     let decoded = @codec.decode_tga_pure(tga_bytes)
///     assert_eq(decoded.width, 1)
///     assert_eq(decoded.height, 1)
///     assert_eq(decoded.channels, 3)
///   } catch {
///     _ => assert_true(false)
///   }
/// }
/// ```
pub fn decode_tga_pure(data : Bytes) -> @types.Image raise @types.LoadError {
  let len = data.length()
  // TGA header 18 字节
  if len < 18 {
    raise @types.LoadError::DecodeFailed("TGA 数据过短")
  }
  let id_length = data[0].to_int()
  let color_map_type = data[1].to_int()
  let image_type = data[2].to_int()
  let width = read_u16_le(data, 12)
  let height = read_u16_le(data, 14)
  let bpp = data[16].to_int()
  let descriptor = data[17].to_int()
  // 仅支持无颜色映射
  if color_map_type != 0 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 TGA 颜色映射类型，仅支持无颜色映射",
    )
  }
  // 仅支持 image type 2（未压缩 RGB）和 type 10（RLE RGB）
  if image_type != 2 && image_type != 10 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 TGA image type，仅支持 type 2 和 type 10",
    )
  }
  // 仅支持 24-bit 和 32-bit
  if bpp != 24 && bpp != 32 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 TGA 位深，仅支持 24-bit 和 32-bit",
    )
  }
  // 尺寸校验
  if width == 0 || height == 0 {
    raise @types.LoadError::DecodeFailed("TGA 尺寸无效")
  }
  let bytes_per_pixel = bpp / 8
  let out_channels = bytes_per_pixel
  @types.check_dims(width, height, out_channels)
  // 行序：描述符 bit5（0x20）= top-down，bit4（0x10）= right-to-left（水平镜像）
  // 注意：旧实现误把 bit4 当成 top-down，与规范相反——真实 top-down 文件会被上下翻转。
  let top_down = (descriptor & 0x20) != 0
  let right_to_left = (descriptor & 0x10) != 0
  // 像素数据起始位置
  let pixel_data_start = 18 + id_length
  // 解码像素（BGR(A) → RGB(A)）到 raw_pixels（按文件行序）
  let pixel_count = width * height
  let raw_pixels : Array[Byte] = Array::make(
    pixel_count * out_channels,
    b'\x00',
  )
  let pos = Ref(pixel_data_start)
  let pixel_idx = Ref(0)
  if image_type == 2 {
    // 未压缩
    while pixel_idx.val < pixel_count {
      let p = pos.val
      if p + bytes_per_pixel > len {
        raise @types.LoadError::DecodeFailed("TGA 像素数据越界")
      }
      // BGR(A) → RGB(A)
      let b = data[p].to_int()
      let g = data[p + 1].to_int()
      let r = data[p + 2].to_int()
      let out_idx = pixel_idx.val * out_channels
      raw_pixels[out_idx] = r.to_byte()
      raw_pixels[out_idx + 1] = g.to_byte()
      raw_pixels[out_idx + 2] = b.to_byte()
      if out_channels == 4 {
        let a = data[p + 3].to_int()
        raw_pixels[out_idx + 3] = a.to_byte()
      }
      pos.val += bytes_per_pixel
      pixel_idx.val += 1
    }
  } else {
    // RLE (image_type == 10)
    while pixel_idx.val < pixel_count && pos.val < len {
      let header = data[pos.val].to_int()
      pos.val += 1
      if (header & 0x80) != 0 {
        // RLE packet: run = (header & 0x7F) + 1, 读 1 像素重复 run 次
        let run = (header & 0x7F) + 1
        let p = pos.val
        if p + bytes_per_pixel > len {
          raise @types.LoadError::DecodeFailed("TGA RLE 像素数据越界")
        }
        let b = data[p].to_int()
        let g = data[p + 1].to_int()
        let r = data[p + 2].to_int()
        let a = if out_channels == 4 { data[p + 3].to_int() } else { 0 }
        pos.val += bytes_per_pixel
        for i in 0..<run {
          if pixel_idx.val + i < pixel_count {
            let out_idx = (pixel_idx.val + i) * out_channels
            raw_pixels[out_idx] = r.to_byte()
            raw_pixels[out_idx + 1] = g.to_byte()
            raw_pixels[out_idx + 2] = b.to_byte()
            if out_channels == 4 {
              raw_pixels[out_idx + 3] = a.to_byte()
            }
          }
        }
        pixel_idx.val += run
      } else {
        // raw packet: count = (header & 0x7F) + 1, 读 count 像素
        let count = (header & 0x7F) + 1
        for i in 0..<count {
          let p = pos.val + i * bytes_per_pixel
          if p + bytes_per_pixel > len {
            raise @types.LoadError::DecodeFailed(
              "TGA RLE raw 像素数据越界",
            )
          }
          if pixel_idx.val + i < pixel_count {
            let b = data[p].to_int()
            let g = data[p + 1].to_int()
            let r = data[p + 2].to_int()
            let out_idx = (pixel_idx.val + i) * out_channels
            raw_pixels[out_idx] = r.to_byte()
            raw_pixels[out_idx + 1] = g.to_byte()
            raw_pixels[out_idx + 2] = b.to_byte()
            if out_channels == 4 {
              let a = data[p + 3].to_int()
              raw_pixels[out_idx + 3] = a.to_byte()
            }
          }
        }
        pos.val += count * bytes_per_pixel
        pixel_idx.val += count
      }
    }
  }
  // 行序处理：按输出行序写入 pixels（bottom-up 文件整体上下翻转；bit4 置位时每行再水平镜像）
  let pixels : Array[Byte] = Array::make(pixel_count * out_channels, b'\x00')
  for file_row in 0..<height {
    let out_row = if top_down { file_row } else { height - 1 - file_row }
    for x in 0..<width {
      let src_x = if right_to_left { width - 1 - x } else { x }
      let src_idx = (file_row * width + src_x) * out_channels
      let dst_idx = (out_row * width + x) * out_channels
      for c in 0..<out_channels {
        pixels[dst_idx + c] = raw_pixels[src_idx + c]
      }
    }
  }
  @types.Image::{
    width,
    height,
    channels: out_channels,
    data: Bytes::from_array(pixels),
  }
}
