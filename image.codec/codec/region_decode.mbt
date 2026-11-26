///|
/// # 区域解码 Region Decode
///
/// PNG / BMP / QOI 的矩形区域解码：只产出请求的 tile，避免整图输出缓冲。
/// PNG 的解压仍走整条 IDAT 流（zlib 无流式接口），但反滤波只保留上一行 + 当前行，
/// 输出缓冲按 tile 尺寸分配；BMP 无压缩可直接按行寻址；QOI 顺序解码但只写 tile。
// 区域解码：PNG / BMP / QOI
// 目标：4096² 只解需要的 tile（输出侧不分配整图）

///|
/// 校验区域参数：x/y ≥ 0、w/h > 0、x+w ≤ W、y+h ≤ H。
fn check_region_bounds(
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  img_w : Int32,
  img_h : Int32,
) -> Unit raise @types.LoadError {
  if x < 0 || y < 0 || w <= 0 || h <= 0 {
    raise @types.LoadError::DecodeFailed(
      "区域参数无效：x/y 不能为负，w/h 必须大于 0",
    )
  }
  if x + w > img_w || y + h > img_h {
    raise @types.LoadError::DecodeFailed(
      "区域越界：x+w 或 y+h 超出图像尺寸",
    )
  }
}

///|
/// PNG 区域解码。输出通道数与 `decode_png_pure` 默认一致（gray=1、RGB=3、GA=2、RGBA=4、palette=1）。
/// 仅支持 8-bit、非 interlace（与 `decode_png_pure` 相同）。
pub fn decode_png_region(
  data : Bytes,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.Image raise @types.LoadError {
  let len = data.length()
  if len < 8 || !is_png_signature(data, 0) {
    raise @types.LoadError::DecodeFailed("PNG signature 错误")
  }
  let mut pos = 8
  let mut width = 0
  let mut height = 0
  let mut bit_depth = 0
  let mut color_type = 0
  let mut interlace = 0
  let palette : Array[(Int32, Int32, Int32)] = []
  let idat_data : Array[Byte] = []
  let mut found_ihdr = false
  let mut found_iend = false
  while pos < len && !found_iend {
    if pos + 8 > len {
      raise @types.LoadError::DecodeFailed("PNG chunk 头部过短")
    }
    let chunk_len = read_u32_be(data, pos)
    if chunk_len < 0 {
      raise @types.LoadError::DecodeFailed("PNG chunk 长度无效")
    }
    let chunk_key = read_u32_be(data, pos + 4)
    pos += 8
    if chunk_len > len - pos {
      raise @types.LoadError::DecodeFailed("PNG chunk 数据越界")
    }
    match chunk_key {
      0x49484452 => {
        if chunk_len < 13 {
          raise @types.LoadError::DecodeFailed("PNG IHDR 过短")
        }
        width = read_u32_be(data, pos)
        height = read_u32_be(data, pos + 4)
        bit_depth = data[pos + 8].to_int()
        color_type = data[pos + 9].to_int()
        interlace = data[pos + 12].to_int()
        found_ihdr = true
      }
      0x504C5445 => {
        let num_colors = chunk_len / 3
        for i in 0..<num_colors {
          palette.push(
            (
              data[pos + i * 3].to_int(),
              data[pos + i * 3 + 1].to_int(),
              data[pos + i * 3 + 2].to_int(),
            ),
          )
        }
      }
      0x49444154 =>
        for i in 0..<chunk_len {
          idat_data.push(data[pos + i])
        }
      0x49454E44 => found_iend = true
      _ => ()
    }
    pos += chunk_len + 4
  }
  if !found_ihdr {
    raise @types.LoadError::DecodeFailed("PNG 无 IHDR chunk")
  }
  if width <= 0 || height <= 0 {
    raise @types.LoadError::DecodeFailed("PNG 尺寸无效")
  }
  if interlace != 0 {
    raise @types.LoadError::DecodeFailed("PNG interlace 不支持")
  }
  if bit_depth != 8 {
    raise @types.LoadError::DecodeFailed("PNG 仅支持 8-bit bit depth")
  }
  let ch = match png_channels(color_type) {
    Some(c) => c
    None => raise @types.LoadError::DecodeFailed("PNG 无效 color type")
  }
  @types.check_dims(width, height, ch)
  check_region_bounds(x, y, w, h, width, height)
  if color_type == 3 && palette.length() == 0 {
    raise @types.LoadError::DecodeFailed("PNG palette 缺失")
  }
  let raw = @util.zlib_inflate(Bytes::from_array(idat_data))
  let bpp = ch
  let stride = width * bpp
  // 只保留上一行 + 当前行；输出按 tile 分配
  let prev : Array[Byte] = Array::make(stride, b'\x00')
  let cur : Array[Byte] = Array::make(stride, b'\x00')
  let out : Array[Byte] = Array::make(w * h * ch, b'\x00')
  let mut raw_pos = 0
  for row in 0..<height {
    if raw_pos >= raw.length() {
      raise @types.LoadError::DecodeFailed("PNG 解压数据过短")
    }
    let filter_type = raw[raw_pos].to_int()
    raw_pos += 1
    for i in 0..<stride {
      if raw_pos >= raw.length() {
        raise @types.LoadError::DecodeFailed("PNG 解压数据过短")
      }
      let raw_byte = raw[raw_pos].to_int()
      raw_pos += 1
      let a = if i >= bpp { cur[i - bpp].to_int() } else { 0 }
      let b = if row > 0 { prev[i].to_int() } else { 0 }
      let c = if i >= bpp && row > 0 { prev[i - bpp].to_int() } else { 0 }
      let val = match filter_type {
        0 => raw_byte
        1 => (raw_byte + a) & 0xFF
        2 => (raw_byte + b) & 0xFF
        3 => (raw_byte + (a + b) / 2) & 0xFF
        4 => (raw_byte + paeth_predict(a, b, c)) & 0xFF
        _ => raise @types.LoadError::DecodeFailed("PNG 无效 filter type")
      }
      cur[i] = val.to_byte()
    }
    if row >= y && row < y + h {
      let out_row = row - y
      for px in x..<(x + w) {
        let (r, g, b, a) = match color_type {
          3 => {
            let idx = cur[px].to_int()
            if idx >= palette.length() {
              raise @types.LoadError::DecodeFailed("PNG palette 索引越界")
            }
            let (pr, pg, pb) = palette[idx]
            (pr, pg, pb, 255)
          }
          0 => {
            let v = cur[px].to_int()
            (v, v, v, 255)
          }
          2 => {
            let o = px * 3
            (cur[o].to_int(), cur[o + 1].to_int(), cur[o + 2].to_int(), 255)
          }
          4 => {
            let o = px * 2
            let v = cur[o].to_int()
            (v, v, v, cur[o + 1].to_int())
          }
          _ => {
            let o = px * 4
            (
              cur[o].to_int(),
              cur[o + 1].to_int(),
              cur[o + 2].to_int(),
              cur[o + 3].to_int(),
            )
          }
        }
        let o = (out_row * w + (px - x)) * ch
        match ch {
          1 => {
            let gray = (r * 299 + g * 587 + b * 114) / 1000
            out[o] = gray.to_byte()
          }
          2 => {
            let gray = (r * 299 + g * 587 + b * 114) / 1000
            out[o] = gray.to_byte()
            out[o + 1] = a.to_byte()
          }
          3 => {
            out[o] = r.to_byte()
            out[o + 1] = g.to_byte()
            out[o + 2] = b.to_byte()
          }
          _ => {
            out[o] = r.to_byte()
            out[o + 1] = g.to_byte()
            out[o + 2] = b.to_byte()
            out[o + 3] = a.to_byte()
          }
        }
      }
    }
    // 行轮换：cur → prev，cur 重置
    for i in 0..<stride {
      prev[i] = cur[i]
      cur[i] = b'\x00'
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(out),
  }
}

///|
/// BMP 区域解码。仅支持 BITMAPINFOHEADER + BI_RGB 的 24/32-bit（与 `decode_bmp_pure` 相同）。
/// 无压缩格式可按行直接寻址，不分配整图缓冲。
pub fn decode_bmp_region(
  data : Bytes,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.Image raise @types.LoadError {
  let len = data.length()
  if len < 54 {
    raise @types.LoadError::DecodeFailed("BMP 数据过短")
  }
  if data[0].to_int() != 0x42 || data[1].to_int() != 0x4D {
    raise @types.LoadError::DecodeFailed("BMP magic 不匹配")
  }
  let data_offset = read_u32_le(data, 10)
  let dib_size = read_u32_le(data, 14)
  if dib_size != 40 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 BMP DIB 头大小，仅支持 BITMAPINFOHEADER（40 字节）",
    )
  }
  let width = read_u32_le(data, 18)
  let height = read_u32_le(data, 22)
  let bpp = read_u16_le(data, 28)
  let compression = read_u32_le(data, 30)
  if bpp != 24 && bpp != 32 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 BMP 位深，仅支持 24-bit 和 32-bit",
    )
  }
  if compression != 0 {
    raise @types.LoadError::DecodeFailed(
      "不支持的 BMP 压缩方式，仅支持 BI_RGB（无压缩）",
    )
  }
  if width <= 0 || height == 0 {
    raise @types.LoadError::DecodeFailed("BMP 尺寸无效")
  }
  let abs_width = if width < 0 { -width } else { width }
  let abs_height = if height < 0 { -height } else { height }
  let bottom_up = height > 0
  let bytes_per_pixel = bpp / 8
  let row_size = (abs_width * bytes_per_pixel + 3) / 4 * 4
  @types.check_dims(abs_width, abs_height, bytes_per_pixel)
  check_region_bounds(x, y, w, h, abs_width, abs_height)
  let out : Array[Byte] = Array::make(w * h * bytes_per_pixel, b'\x00')
  for ry in 0..<h {
    let out_row = ry
    let file_row = if bottom_up { abs_height - 1 - (y + ry) } else { y + ry }
    let row_start = data_offset + file_row * row_size
    for rx in 0..<w {
      let pixel_offset = row_start + (x + rx) * bytes_per_pixel
      if pixel_offset + bytes_per_pixel > len {
        raise @types.LoadError::DecodeFailed("BMP 像素数据越界")
      }
      let b = data[pixel_offset].to_int()
      let g = data[pixel_offset + 1].to_int()
      let r = data[pixel_offset + 2].to_int()
      let out_idx = (out_row * w + rx) * bytes_per_pixel
      out[out_idx] = r.to_byte()
      out[out_idx + 1] = g.to_byte()
      out[out_idx + 2] = b.to_byte()
      if bytes_per_pixel == 4 {
        out[out_idx + 3] = data[pixel_offset + 3]
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: bytes_per_pixel,
    data: Bytes::from_array(out),
  }
}

///|
/// QOI 区域解码。QOI 为顺序码流，仍需从头解码；但输出缓冲只分配 tile，
/// 区域外像素只推进状态、不落内存。
pub fn decode_qoi_region(
  data : Bytes,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> @types.Image raise @types.LoadError {
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
  let out_ch = if channels == 3 { 3 } else { 4 }
  @types.check_dims(width, height, out_ch)
  check_region_bounds(x, y, w, h, width, height)
  let pixel_count = width * height
  let out : Array[Byte] = Array::make(w * h * out_ch, b'\x00')
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
          let cx = pixel_idx.val % width
          let cy = pixel_idx.val / width
          if cy >= y && cy < y + h && cx >= x && cx < x + w {
            let o = ((cy - y) * w + (cx - x)) * out_ch
            out[o] = px_r.val.to_byte()
            out[o + 1] = px_g.val.to_byte()
            out[o + 2] = px_b.val.to_byte()
            if out_ch == 4 {
              out[o + 3] = px_a.val.to_byte()
            }
          }
          pixel_idx.val += 1
        }
      }
      continue
    }
    let cx = pixel_idx.val % width
    let cy = pixel_idx.val / width
    if cy >= y && cy < y + h && cx >= x && cx < x + w {
      let o = ((cy - y) * w + (cx - x)) * out_ch
      out[o] = px_r.val.to_byte()
      out[o + 1] = px_g.val.to_byte()
      out[o + 2] = px_b.val.to_byte()
      if out_ch == 4 {
        out[o + 3] = px_a.val.to_byte()
      }
    }
    pixel_idx.val += 1
    let hsh = qoi_hash(px_r.val, px_g.val, px_b.val, px_a.val)
    index_r[hsh] = px_r.val
    index_g[hsh] = px_g.val
    index_b[hsh] = px_b.val
    index_a[hsh] = px_a.val
  }
  @types.Image::{
    width: w,
    height: h,
    channels: out_ch,
    data: Bytes::from_array(out),
  }
}
