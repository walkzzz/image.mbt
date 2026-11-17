///|
/// # QOI 解码器 QOI Decoder
///
/// 纯 MoonBit QOI 解码器，支持全部 QOI 标签（INDEX/DIFF/LUMA/RUN/RGB/RGBA）。 Pure MoonBit QOI decoder, supporting all QOI tags (INDEX/DIFF/LUMA/RUN/RGB/RGBA).
///
/// 核心函数 Core functions:
/// - `decode_qoi_pure` - 解码 QOI 字节流为 Image Decode QOI byte stream to Image

// 纯 MoonBit QOI 解码器
// 规范: https://qoiformat.org/qoi-specification.pdf
// 移植自 src/format/qoi.mbt 的 decode_qoi，仅替换类型引用：
//   @core.Image -> @types.Image, @core.LoadError -> @types.LoadError

// QOI 哈希函数: (r*3 + g*5 + b*7 + a*11) % 64

///|
fn qoi_hash(r : Int32, g : Int32, b : Int32, a : Int32) -> Int32 {
  (r * 3 + g * 5 + b * 7 + a * 11) % 64
}

///|
/// 解码 QOI 字节流为 Image（channels=3 或 4）支持全部 QOI 操作标签 Supports all QOI operation tags

///|
/// 参数 Parameters:
/// - `data` - QOI 字节流 QOI byte stream
///
/// 返回 Return:
/// - 解码后的 8-bit Image Decoded 8-bit Image
///
/// 错误 Errors:
/// - `LoadError::DecodeFailed` - 数据过短、magic 不匹配、尺寸无效 Data too short, magic mismatch, invalid dimensions
///
/// ```mbt check
/// test "doc_decode_qoi_pure" {
///   try {
///     let img = @codec.decode_qoi_pure(@types.DOC_TEST_QOI_1X1)
///     assert_eq(img.width, 1)
///     assert_eq(img.height, 1)
///     assert_eq(img.channels, 4)
///   } catch {
///     _ => assert_true(false)
///   }
/// }
/// ```
pub fn decode_qoi_pure(data : Bytes) -> @types.Image raise @types.LoadError {
  let len = data.length()
  if len < 14 {
    raise @types.LoadError::DecodeFailed("QOI 数据过短")
  }
  if data[0].to_int() != 0x71 ||
    data[1].to_int() != 0x6F ||
    data[2].to_int() != 0x69 ||
    data[3].to_int() != 0x66 {
    raise @types.LoadError::DecodeFailed("QOI magic 不匹配")
  }
  let width = (data[4].to_int() << 24) |
    (data[5].to_int() << 16) |
    (data[6].to_int() << 8) |
    data[7].to_int()
  let height = (data[8].to_int() << 24) |
    (data[9].to_int() << 16) |
    (data[10].to_int() << 8) |
    data[11].to_int()
  let channels = data[12].to_int()
  if width <= 0 || height <= 0 {
    raise @types.LoadError::DecodeFailed("QOI 尺寸无效")
  }
  let out_channels = if channels == 3 { 3 } else { 4 }
  @types.check_dims(width, height, out_channels)
  let pixel_count = width * height
  let pixels : Array[Byte] = Array::make(pixel_count * out_channels, b'\x00')
  let index_r : Array[Int32] = Array::make(64, 0)
  let index_g : Array[Int32] = Array::make(64, 0)
  let index_b : Array[Int32] = Array::make(64, 0)
  let index_a : Array[Int32] = Array::make(64, 0)
  let px_r = Ref(0)
  let px_g = Ref(0)
  let px_b = Ref(0)
  let px_a = Ref(255)
  let pos = Ref(14)
  let pixel_idx = Ref(0)
  while pixel_idx.val < pixel_count && pos.val < len {
    let tag = data[pos.val].to_int()
    pos.val += 1
    if tag == 0xFE {
      if pos.val + 2 >= len {
        raise @types.LoadError::DecodeFailed("QOI 数据截断: OP_RGB")
      }
      px_r.val = data[pos.val].to_int()
      px_g.val = data[pos.val + 1].to_int()
      px_b.val = data[pos.val + 2].to_int()
      pos.val += 3
    } else if tag == 0xFF {
      if pos.val + 3 >= len {
        raise @types.LoadError::DecodeFailed("QOI 数据截断: OP_RGBA")
      }
      px_r.val = data[pos.val].to_int()
      px_g.val = data[pos.val + 1].to_int()
      px_b.val = data[pos.val + 2].to_int()
      px_a.val = data[pos.val + 3].to_int()
      pos.val += 4
    } else if (tag & 0xC0) == 0x00 {
      let idx = tag & 0x3F
      px_r.val = index_r[idx]
      px_g.val = index_g[idx]
      px_b.val = index_b[idx]
      px_a.val = index_a[idx]
    } else if (tag & 0xC0) == 0x40 {
      px_r.val = (px_r.val + ((tag >> 4) & 0x03) - 2) & 0xFF
      px_g.val = (px_g.val + ((tag >> 2) & 0x03) - 2) & 0xFF
      px_b.val = (px_b.val + (tag & 0x03) - 2) & 0xFF
    } else if (tag & 0xC0) == 0x80 {
      if pos.val >= len {
        raise @types.LoadError::DecodeFailed("QOI 数据截断: OP_LUMA")
      }
      let dg = (tag & 0x3F) - 32
      px_g.val = (px_g.val + dg) & 0xFF
      let b2 = data[pos.val].to_int()
      pos.val += 1
      let dr_dg = (b2 >> 4) - 8
      let db_dg = (b2 & 0x0F) - 8
      px_r.val = (px_r.val + dr_dg + dg) & 0xFF
      px_b.val = (px_b.val + db_dg + dg) & 0xFF
    } else {
      let run = (tag & 0x3F) + 1
      for _ in 0..<run {
        if pixel_idx.val < pixel_count {
          pixels[pixel_idx.val * out_channels] = px_r.val.to_byte()
          pixels[pixel_idx.val * out_channels + 1] = px_g.val.to_byte()
          pixels[pixel_idx.val * out_channels + 2] = px_b.val.to_byte()
          if out_channels == 4 {
            pixels[pixel_idx.val * out_channels + 3] = px_a.val.to_byte()
          }
          pixel_idx.val += 1
        }
      }
      continue
    }
    pixels[pixel_idx.val * out_channels] = px_r.val.to_byte()
    pixels[pixel_idx.val * out_channels + 1] = px_g.val.to_byte()
    pixels[pixel_idx.val * out_channels + 2] = px_b.val.to_byte()
    if out_channels == 4 {
      pixels[pixel_idx.val * out_channels + 3] = px_a.val.to_byte()
    }
    pixel_idx.val += 1
    let h = qoi_hash(px_r.val, px_g.val, px_b.val, px_a.val)
    index_r[h] = px_r.val
    index_g[h] = px_g.val
    index_b[h] = px_b.val
    index_a[h] = px_a.val
  }
  @types.Image::{
    width,
    height,
    channels: out_channels,
    data: Bytes::from_array(pixels),
  }
}
