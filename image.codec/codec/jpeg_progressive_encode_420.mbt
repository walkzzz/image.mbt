///|
/// # progressive JPEG · 4:2:0 色度下采样（`encode_jpeg_progressive_420`）
///
/// 与 4:4:4 版（`jpeg_progressive_encode.mbt`）共用同一套 8 扫描脚本与霍夫曼优化表，
/// 差别只在帧头采样因子与块平面布局：
/// - SOF2 分量表：Y `h=2 v=2`，Cb/Cr `h=1 v=1` → MCU 16×16 像素、每 MCU 6 块（Y×4 + Cb + Cr）；
/// - 色度先做 2×2 盒式平均降到半分辨再 8×8 DCT 量化，亮度保持全分辨。
///
/// 单分量 AC 扫描按各分量**有效块网格**（`ceil(w*h_i/(8*h_max))`）推进；padding 块只出现在
/// 交错 DC 扫描里——与 `jpeg_progressive.mbt` 的解码口径逐条对齐。
///
/// 体积收益来自色度平面块数降到 1/4（色度系数与 AC 扫描位流同步缩小），
/// 代价是细节处轻微色度模糊（4:2:0 的固有取舍，与 libjpeg/Pillow 同口径）。

///|
/// 在给定分量平面内写一条 AC 首扫（`Ah=0 Al=al`）；`freq` 非空时只计频、不写位。
/// 符号序列与 `jpeg_progressive_encode.mbt` 的 4:4:4 写码逐分支同构。
fn prog420_ac_first_plane(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  coefs : Array[Int32],
  stride : Int32,
  blocks_x : Int32,
  blocks_y : Int32,
  al : Int32,
) -> Unit {
  let mut eobrun = 0
  for by in 0..<blocks_y {
    for bx in 0..<blocks_x {
      let base = (by * stride + bx) * 64
      let mut has_nz = false
      for k in 1..<64 {
        if jpeg_prog_shift(coefs[base + k], al) != 0 {
          has_nz = true
          break
        }
      }
      if !has_nz {
        eobrun += 1
        if eobrun == PROGRESSIVE_MAX_EOBRUN {
          let nbits = jpeg_category(eobrun) - 1
          jpeg_prog_emit_sym(w, enc, freq, nbits << 4)
          if nbits > 0 {
            jpeg_prog_emit_value(w, freq, eobrun - (1 << nbits), nbits)
          }
          eobrun = 0
        }
        continue
      }
      if eobrun > 0 {
        let nbits = jpeg_category(eobrun) - 1
        jpeg_prog_emit_sym(w, enc, freq, nbits << 4)
        if nbits > 0 {
          jpeg_prog_emit_value(w, freq, eobrun - (1 << nbits), nbits)
        }
        eobrun = 0
      }
      let mut run = 0
      for k in 1..<64 {
        let c = jpeg_prog_shift(coefs[base + k], al)
        if c == 0 {
          run += 1
          continue
        }
        while run > 15 {
          jpeg_prog_emit_sym(w, enc, freq, 0xF0)
          run -= 16
        }
        let size = jpeg_category(c)
        jpeg_prog_emit_sym(w, enc, freq, (run << 4) | size)
        jpeg_prog_emit_value(w, freq, c, size)
        run = 0
      }
      if run > 0 {
        // 块尾残余零：本块立即 EOB 收尾，不进 EOBRUN（否则解码端会多吃一块）
        jpeg_prog_emit_sym(w, enc, freq, 0)
      }
    }
  }
  if eobrun > 0 {
    let nbits = jpeg_category(eobrun) - 1
    jpeg_prog_emit_sym(w, enc, freq, nbits << 4)
    if nbits > 0 {
      jpeg_prog_emit_value(w, freq, eobrun - (1 << nbits), nbits)
    }
  }
}

///|
/// 在给定分量平面内写一条 AC 细化扫描（`Ah=1 Al=0`）；`freq` 非空时只计频。
/// 修正位发射与 `jpeg_progressive_ac_refine_scan` 同口径（`BE` 跨块 / `BR` 本块双缓冲）。
fn prog420_ac_refine_plane(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  coefs : Array[Int32],
  stride : Int32,
  blocks_x : Int32,
  blocks_y : Int32,
) -> Unit {
  let absv = Array::make(64, 0)
  let be : Array[Int32] = []
  let br : Array[Int32] = []
  let mut eobrun = 0
  for by in 0..<blocks_y {
    for bx in 0..<blocks_x {
      let base = (by * stride + bx) * 64
      let mut has_nz = false
      let mut eob = 0
      for k in 1..<64 {
        let c = coefs[base + k]
        let a = if c < 0 { -c } else { c }
        absv[k] = a
        if a != 0 {
          has_nz = true
        }
        if a == 1 {
          eob = k
        }
      }
      if has_nz && eobrun > 0 {
        jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
        eobrun = 0
      }
      let mut r = 0
      let mut k = 1
      while k < 64 {
        let av = absv[k]
        if av == 0 {
          r += 1
          k += 1
          continue
        }
        while r > 15 && k <= eob {
          jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
          eobrun = 0
          jpeg_prog_emit_sym(w, enc, freq, 0xF0)
          r -= 16
          jpeg_prog_flush_corr(w, freq, br)
        }
        if av > 1 {
          br.push(av & 1)
          k += 1
          continue
        }
        jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
        eobrun = 0
        jpeg_prog_emit_sym(w, enc, freq, (r << 4) | 1)
        jpeg_prog_emit_bit(w, freq, if coefs[base + k] < 0 { 0 } else { 1 })
        jpeg_prog_flush_corr(w, freq, br)
        r = 0
        k += 1
      }
      if r > 0 || br.length() > 0 {
        eobrun += 1
        for b in br {
          be.push(b)
        }
        br.clear()
        if eobrun == PROGRESSIVE_MAX_EOBRUN {
          jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
          eobrun = 0
        }
      }
    }
  }
  if eobrun > 0 || be.length() > 0 {
    jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
  }
  jpeg_prog_flush_corr(w, freq, br)
}

///|
/// 取一个像素的 (Y, Cb, Cr)；越界按边缘复制，通道不足按灰度。
fn prog420_pixel_ycbcr(
  data : Bytes,
  channels : Int32,
  width : Int32,
  height : Int32,
  x : Int32,
  y : Int32,
) -> (Int32, Int32, Int32) {
  let sx = if x >= width { width - 1 } else if x < 0 { 0 } else { x }
  let sy = if y >= height { height - 1 } else if y < 0 { 0 } else { y }
  let didx = sy * width * channels + sx * channels
  let r = data[didx].to_int()
  let g = if channels >= 2 { data[didx + 1].to_int() } else { r }
  let b = if channels >= 3 { data[didx + 2].to_int() } else { r }
  rgb_to_ycbcr(r, g, b)
}

///|
/// JPEG 渐进式编码 · 4:2:0（亮度全分辨、色度 2×2 盒式平均），8 条扫描。
///
/// 参数 Parameters:
/// - `img` - 输入图像（1 或 3 通道；1 通道按灰度处理）
/// - `quality` - 质量 1–100，50 等价标准量化表
///
/// 返回 Return:
/// - progressive JPEG（SOF2，Y `2×2`、Cb/Cr `1×1`）字节流
///
/// 错误 Errors:
/// - `LoadError::EncodeFailed` - 尺寸无效、像素数超上限
pub fn encode_jpeg_progressive_420(
  img : @types.Image,
  quality : Int32,
) -> Bytes raise @types.LoadError {
  let width = img.width
  let height = img.height
  if width <= 0 || height <= 0 {
    raise @types.LoadError::EncodeFailed("JPEG 尺寸无效")
  }
  if height > PROGRESSIVE_MAX_PIXELS / width {
    raise @types.LoadError::EncodeFailed(
      "progressive 编码暂支持 ≤ 2,000,000 像素（量化系数缓存上限）",
    )
  }
  let channels = img.channels
  let data = img.data
  let zz = jpeg_zigzag()
  let quant_lum = jpeg_scaled_quant(std_quant_luminance(), quality)
  let quant_chr = jpeg_scaled_quant(std_quant_chrominance(), quality)
  let dc_lum_enc = build_huffman_encoder(std_dc_lum_bits(), std_dc_lum_vals())
  let dc_chr_enc = build_huffman_encoder(std_dc_chr_bits(), std_dc_chr_vals())
  // ---- 网格：MCU 16×16；Y 每 MCU 2×2 块、Cb/Cr 各 1 块
  let mcus_x = (width + 15) / 16
  let mcus_y = (height + 15) / 16
  let stride_y = mcus_x * 2
  let stride_c = mcus_x
  // 单分量扫描的有效块网格（不含 padding），与解码器 bw/bh 一致
  let y_fx = (width + 7) / 8
  let y_fy = (height + 7) / 8
  let c_fx = (width + 15) / 16
  let c_fy = (height + 15) / 16
  let coefs_y : Array[Int32] = Array::make(stride_y * (mcus_y * 2) * 64, 0)
  let coefs_cb : Array[Int32] = Array::make(stride_c * c_fy * 64, 0)
  let coefs_cr : Array[Int32] = Array::make(stride_c * c_fy * 64, 0)
  let inv_lum : Array[Float] = Array::make(64, 0.0F)
  let inv_chr : Array[Float] = Array::make(64, 0.0F)
  for i in 0..<64 {
    inv_lum[i] = 1.0F / (Float::from_int(quant_lum[i]) * 8.0F)
    inv_chr[i] = 1.0F / (Float::from_int(quant_chr[i]) * 8.0F)
  }
  let tmp_i : Array[Int32] = Array::make(64, 0)
  let shifted : Array[Int32] = Array::make(64, 0)
  let dct_out : Array[Int32] = Array::make(64, 0)
  let block : Array[Int32] = Array::make(64, 128)
  let block_cr : Array[Int32] = Array::make(64, 128)
  // ---- 亮度：全分辨（padding 块用边缘复制，只影响体积不影响像素）
  for by in 0..<(mcus_y * 2) {
    for bx in 0..<stride_y {
      for py in 0..<8 {
        for px in 0..<8 {
          let (yv, _, _) = prog420_pixel_ycbcr(
            data,
            channels,
            width,
            height,
            bx * 8 + px,
            by * 8 + py,
          )
          block[py * 8 + px] = yv
        }
      }
      jpeg_progressive_quantize_block(
        block,
        inv_lum,
        zz,
        tmp_i,
        shifted,
        dct_out,
        coefs_y,
        (by * stride_y + bx) * 64,
      )
    }
  }
  // ---- 色度：每块覆盖 16×16 像素，2×2 盒式平均成 8×8 采样
  for by in 0..<c_fy {
    for bx in 0..<c_fx {
      for py in 0..<8 {
        for px in 0..<8 {
          let sx = bx * 16 + px * 2
          let sy = by * 16 + py * 2
          let (_, cb0, cr0) = prog420_pixel_ycbcr(
            data, channels, width, height, sx, sy,
          )
          let (_, cb1, cr1) = prog420_pixel_ycbcr(
            data,
            channels,
            width,
            height,
            sx + 1,
            sy,
          )
          let (_, cb2, cr2) = prog420_pixel_ycbcr(
            data,
            channels,
            width,
            height,
            sx,
            sy + 1,
          )
          let (_, cb3, cr3) = prog420_pixel_ycbcr(
            data,
            channels,
            width,
            height,
            sx + 1,
            sy + 1,
          )
          let o = py * 8 + px
          block[o] = (cb0 + cb1 + cb2 + cb3) / 4
          block_cr[o] = (cr0 + cr1 + cr2 + cr3) / 4
        }
      }
      let base = (by * stride_c + bx) * 64
      jpeg_progressive_quantize_block(
        block, inv_chr, zz, tmp_i, shifted, dct_out, coefs_cb, base,
      )
      jpeg_progressive_quantize_block(
        block_cr, inv_chr, zz, tmp_i, shifted, dct_out, coefs_cr, base,
      )
    }
  }
  let out : Array[Byte] = []
  out.push(b'\xFF')
  out.push(b'\xD8')
  // ---- DQT（表 0 亮度 / 表 1 色度，之字形写）
  out.push(b'\xFF')
  out.push(b'\xDB')
  out.push(b'\x00')
  out.push(b'\x84')
  out.push(b'\x00')
  for k in 0..<64 {
    out.push(quant_lum[zz[k]].to_byte())
  }
  out.push(b'\x01')
  for k in 0..<64 {
    out.push(quant_chr[zz[k]].to_byte())
  }
  // ---- SOF2：Y 采样因子 0x22，Cb/Cr 0x11
  out.push(b'\xFF')
  out.push(b'\xC2')
  out.push(b'\x00')
  out.push(b'\x11')
  out.push(b'\x08')
  out.push(((height >> 8) & 0xFF).to_byte())
  out.push((height & 0xFF).to_byte())
  out.push(((width >> 8) & 0xFF).to_byte())
  out.push((width & 0xFF).to_byte())
  out.push(b'\x03')
  out.push(b'\x01')
  out.push(b'\x22')
  out.push(b'\x00')
  out.push(b'\x02')
  out.push(b'\x11')
  out.push(b'\x01')
  out.push(b'\x03')
  out.push(b'\x11')
  out.push(b'\x01')
  // ---- 频次统计（只计频）：AC 首扫（Al=1）与 AC 细化（Al=0）各一套，亮度/色度分开
  let scratch_out : Array[Byte] = Array::make(1, b'\x00')
  let freq_f_y = Array::make(257, 0)
  let freq_f_c = Array::make(257, 0)
  prog420_ac_first_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_lum_enc,
    freq_f_y,
    coefs_y,
    stride_y,
    y_fx,
    y_fy,
    1,
  )
  prog420_ac_first_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_chr_enc,
    freq_f_c,
    coefs_cb,
    stride_c,
    c_fx,
    c_fy,
    1,
  )
  prog420_ac_first_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_chr_enc,
    freq_f_c,
    coefs_cr,
    stride_c,
    c_fx,
    c_fy,
    1,
  )
  let freq_r_y = Array::make(257, 0)
  let freq_r_c = Array::make(257, 0)
  prog420_ac_refine_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_lum_enc,
    freq_r_y,
    coefs_y,
    stride_y,
    y_fx,
    y_fy,
  )
  prog420_ac_refine_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_chr_enc,
    freq_r_c,
    coefs_cb,
    stride_c,
    c_fx,
    c_fy,
  )
  prog420_ac_refine_plane(
    JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
    dc_chr_enc,
    freq_r_c,
    coefs_cr,
    stride_c,
    c_fx,
    c_fy,
  )
  let (af_y_bits, af_y_vals) = jpeg_gen_optimal_table(freq_f_y)
  let (af_c_bits, af_c_vals) = jpeg_gen_optimal_table(freq_f_c)
  let (ar_y_bits, ar_y_vals) = jpeg_gen_optimal_table(freq_r_y)
  let (ar_c_bits, ar_c_vals) = jpeg_gen_optimal_table(freq_r_c)
  let af_y_enc = build_huffman_encoder(af_y_bits, af_y_vals)
  let af_c_enc = build_huffman_encoder(af_c_bits, af_c_vals)
  let ar_y_enc = build_huffman_encoder(ar_y_bits, ar_y_vals)
  let ar_c_enc = build_huffman_encoder(ar_c_bits, ar_c_vals)
  // ---- DHT：DC 两张标准 + AC 首扫/细化各两张优化表
  let dht_data : Array[Byte] = []
  let push_table = fn(tc_th : Int32, bits : Array[Int32], vals : Array[Int32]) {
    dht_data.push(tc_th.to_byte())
    for b in bits {
      dht_data.push(b.to_byte())
    }
    for v in vals {
      dht_data.push(v.to_byte())
    }
  }
  push_table(0x00, std_dc_lum_bits(), std_dc_lum_vals())
  push_table(0x01, std_dc_chr_bits(), std_dc_chr_vals())
  push_table(0x10, af_y_bits, af_y_vals)
  push_table(0x11, af_c_bits, af_c_vals)
  push_table(0x12, ar_y_bits, ar_y_vals)
  push_table(0x13, ar_c_bits, ar_c_vals)
  let dht_len = 2 + dht_data.length()
  out.push(b'\xFF')
  out.push(b'\xC4')
  out.push(((dht_len >> 8) & 0xFF).to_byte())
  out.push((dht_len & 0xFF).to_byte())
  for b in dht_data {
    out.push(b)
  }
  // ---- 扫描 1：DC 首扫（交错 3 分量，Ah=0 Al=1）
  jpeg_push_sos(
    out,
    3,
    [b'\x01', b'\x02', b'\x03'],
    [b'\x00', b'\x11', b'\x11'],
    0,
    0,
    0x01,
  )
  let w1 = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
  let prev : Array[Ref[Int32]] = [Ref(0), Ref(0), Ref(0)]
  for my in 0..<mcus_y {
    for mx in 0..<mcus_x {
      for bi in 0..<4 {
        let gx = mx * 2 + bi % 2
        let gy = my * 2 + bi / 2
        let dc = coefs_y[(gy * stride_y + gx) * 64] >> 1
        let diff = dc - prev[0].val
        prev[0].val = dc
        let cat = jpeg_category(diff)
        jpeg_write_bits(w1, dc_lum_enc.codes[cat], dc_lum_enc.lengths[cat])
        if cat > 0 {
          jpeg_write_bits(w1, jpeg_value_bits(diff, cat), cat)
        }
      }
      let cbase = (my * stride_c + mx) * 64
      let dc_cb = coefs_cb[cbase] >> 1
      let diff_cb = dc_cb - prev[1].val
      prev[1].val = dc_cb
      let cat_cb = jpeg_category(diff_cb)
      jpeg_write_bits(w1, dc_chr_enc.codes[cat_cb], dc_chr_enc.lengths[cat_cb])
      if cat_cb > 0 {
        jpeg_write_bits(w1, jpeg_value_bits(diff_cb, cat_cb), cat_cb)
      }
      let dc_cr = coefs_cr[cbase] >> 1
      let diff_cr = dc_cr - prev[2].val
      prev[2].val = dc_cr
      let cat_cr = jpeg_category(diff_cr)
      jpeg_write_bits(w1, dc_chr_enc.codes[cat_cr], dc_chr_enc.lengths[cat_cr])
      if cat_cr > 0 {
        jpeg_write_bits(w1, jpeg_value_bits(diff_cr, cat_cr), cat_cr)
      }
    }
  }
  jpeg_flush_bits(w1)
  // ---- 扫描 2–4：AC 首扫（单分量，Ss=1 Se=63，Ah=0 Al=1）
  for ci in 0..<3 {
    let enc = if ci == 0 { af_y_enc } else { af_c_enc }
    let slots : Array[Byte] = [if ci == 0 { b'\x00' } else { b'\x11' }]
    let ids : Array[Byte] = [
      (if ci == 0 { 1 } else if ci == 1 { 2 } else { 3 }).to_byte(),
    ]
    jpeg_push_sos(out, 1, ids, slots, 1, 63, 0x01)
    let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
    if ci == 0 {
      prog420_ac_first_plane(w, enc, [], coefs_y, stride_y, y_fx, y_fy, 1)
    } else if ci == 1 {
      prog420_ac_first_plane(w, enc, [], coefs_cb, stride_c, c_fx, c_fy, 1)
    } else {
      prog420_ac_first_plane(w, enc, [], coefs_cr, stride_c, c_fx, c_fy, 1)
    }
    jpeg_flush_bits(w)
  }
  // ---- 扫描 5：DC 细化（交错，Ah=1 Al=0）
  jpeg_push_sos(
    out,
    3,
    [b'\x01', b'\x02', b'\x03'],
    [b'\x00', b'\x11', b'\x11'],
    0,
    0,
    0x10,
  )
  let w5 = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
  for my in 0..<mcus_y {
    for mx in 0..<mcus_x {
      for bi in 0..<4 {
        let gx = mx * 2 + bi % 2
        let gy = my * 2 + bi / 2
        jpeg_write_bits(w5, coefs_y[(gy * stride_y + gx) * 64] & 1, 1)
      }
      let cbase = (my * stride_c + mx) * 64
      jpeg_write_bits(w5, coefs_cb[cbase] & 1, 1)
      jpeg_write_bits(w5, coefs_cr[cbase] & 1, 1)
    }
  }
  jpeg_flush_bits(w5)
  // ---- 扫描 6–8：AC 细化（单分量，Ss=1 Se=63，Ah=1 Al=0）
  for ci in 0..<3 {
    let enc = if ci == 0 { ar_y_enc } else { ar_c_enc }
    let slots : Array[Byte] = [if ci == 0 { b'\x02' } else { b'\x13' }]
    let ids : Array[Byte] = [
      (if ci == 0 { 1 } else if ci == 1 { 2 } else { 3 }).to_byte(),
    ]
    jpeg_push_sos(out, 1, ids, slots, 1, 63, 0x10)
    let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
    if ci == 0 {
      prog420_ac_refine_plane(w, enc, [], coefs_y, stride_y, y_fx, y_fy)
    } else if ci == 1 {
      prog420_ac_refine_plane(w, enc, [], coefs_cb, stride_c, c_fx, c_fy)
    } else {
      prog420_ac_refine_plane(w, enc, [], coefs_cr, stride_c, c_fx, c_fy)
    }
    jpeg_flush_bits(w)
  }
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}
