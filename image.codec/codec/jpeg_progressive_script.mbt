///|
/// # progressive JPEG · 扫描脚本可配置（`encode_jpeg_progressive_420_scripted`）
///
/// 把"固定 8 条扫描"升级成**按脚本驱动**：每条扫描给出分量集、`Ss/Se`（spectral selection）
/// 与 `Ah/Al`（successive approximation），逐条写自己的 DHT + SOS。
///
/// 默认脚本 `jpeg_progressive_script_libjpeg()` 复刻 libjpeg `jpeg_simple_progression()`
/// 对 YCbCr 的 10 条扫描：DC 首扫 → Y `1–5`(Al=2) → Cr/Cb 全带(Al=1) → Y `6–63`(Al=2) →
/// DC 细化 → Y 全带 `Ah=2 Al=1` → Cr/Cb 全带细化 → Y 全带细化（亮度最低位最后发）。
///
/// 与 4:2:0 固定 8 扫描版共用同一套系数平面（Y `stride_y`、Cb/Cr `stride_c`）与
/// `prog420_pixel_ycbcr` / `jpeg_progressive_quantize_block`；差别只在扫描的组织方式，
/// 顺带把 AC 表改成**逐扫描按频次重建**（libjpeg `optimize_coding` 同口径）。

///|
/// 一条 progressive 扫描（字段与 libjpeg `jpeg_scan_info` 对齐）。
/// `comps` 用本库的分量序号：0 = Y、1 = Cb、2 = Cr。
pub(all) struct JpegProgScan {
  comps : Array[Int32]
  ss : Int32
  se : Int32
  ah : Int32
  al : Int32
}

///|
/// libjpeg `jpeg_simple_progression()` 的 YCbCr 默认 10 条扫描。
pub fn jpeg_progressive_script_libjpeg() -> Array[JpegProgScan] {
  [
    JpegProgScan::{ comps: [0, 1, 2], ss: 0, se: 0, ah: 0, al: 1, },
    JpegProgScan::{ comps: [0], ss: 1, se: 5, ah: 0, al: 2, },
    JpegProgScan::{ comps: [2], ss: 1, se: 63, ah: 0, al: 1, },
    JpegProgScan::{ comps: [1], ss: 1, se: 63, ah: 0, al: 1, },
    JpegProgScan::{ comps: [0], ss: 6, se: 63, ah: 0, al: 2, },
    JpegProgScan::{ comps: [0, 1, 2], ss: 0, se: 0, ah: 1, al: 0, },
    JpegProgScan::{ comps: [0], ss: 1, se: 63, ah: 2, al: 1, },
    JpegProgScan::{ comps: [2], ss: 1, se: 63, ah: 1, al: 0, },
    JpegProgScan::{ comps: [1], ss: 1, se: 63, ah: 1, al: 0, },
    JpegProgScan::{ comps: [0], ss: 1, se: 63, ah: 1, al: 0, },
  ]
}

///|
/// 0.1.30 固定 8 条扫描等价脚本（DC 首扫 Al=1 → 3×AC 首扫 Al=1 → DC 细化 → 3×AC 细化）。
pub fn jpeg_progressive_script_eight() -> Array[JpegProgScan] {
  [
    JpegProgScan::{ comps: [0, 1, 2], ss: 0, se: 0, ah: 0, al: 1, },
    JpegProgScan::{ comps: [0], ss: 1, se: 63, ah: 0, al: 1, },
    JpegProgScan::{ comps: [1], ss: 1, se: 63, ah: 0, al: 1, },
    JpegProgScan::{ comps: [2], ss: 1, se: 63, ah: 0, al: 1, },
    JpegProgScan::{ comps: [0, 1, 2], ss: 0, se: 0, ah: 1, al: 0, },
    JpegProgScan::{ comps: [0], ss: 1, se: 63, ah: 1, al: 0, },
    JpegProgScan::{ comps: [2], ss: 1, se: 63, ah: 1, al: 0, },
    JpegProgScan::{ comps: [1], ss: 1, se: 63, ah: 1, al: 0, },
  ]
}

///|
/// 发挂起的 EOBRUN（不带修正位缓冲；AC 首扫用）。
fn prog_emit_eobrun(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  eobrun : Int32,
) -> Unit {
  if eobrun > 0 {
    let nbits = jpeg_category(eobrun) - 1
    jpeg_prog_emit_sym(w, enc, freq, nbits << 4)
    if nbits > 0 {
      jpeg_prog_emit_value(w, freq, eobrun - (1 << nbits), nbits)
    }
  }
}

///|
/// 一条 AC 首扫（单分量平面，band `Ss..Se`，点变换 `Al`）。`freq` 非空时只计频。
fn prog_ac_first_scan(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  plane : Array[Int32],
  stride : Int32,
  bx_max : Int32,
  by_max : Int32,
  ss : Int32,
  se : Int32,
  al : Int32,
) -> Unit {
  let mut eobrun = 0
  for by in 0..<by_max {
    for bx in 0..<bx_max {
      let base = (by * stride + bx) * 64
      let mut has_nz = false
      let mut k = ss
      while k <= se {
        if jpeg_prog_shift(plane[base + k], al) != 0 {
          has_nz = true
          k = se
        }
        k = k + 1
      }
      if !has_nz {
        eobrun += 1
        if eobrun == PROGRESSIVE_MAX_EOBRUN {
          prog_emit_eobrun(w, enc, freq, eobrun)
          eobrun = 0
        }
        continue
      }
      if eobrun > 0 {
        prog_emit_eobrun(w, enc, freq, eobrun)
        eobrun = 0
      }
      let mut run = 0
      k = ss
      while k <= se {
        let c = jpeg_prog_shift(plane[base + k], al)
        if c == 0 {
          run += 1
        } else {
          while run > 15 {
            jpeg_prog_emit_sym(w, enc, freq, 0xF0)
            run -= 16
          }
          let size = jpeg_category(c)
          jpeg_prog_emit_sym(w, enc, freq, (run << 4) | size)
          jpeg_prog_emit_value(w, freq, c, size)
          run = 0
        }
        k = k + 1
      }
      if run > 0 {
        // 块尾残余零：立即 EOB 收尾（不进 EOBRUN），与 0.1.30 固定脚本同口径
        jpeg_prog_emit_sym(w, enc, freq, 0)
      }
    }
  }
  if eobrun > 0 {
    prog_emit_eobrun(w, enc, freq, eobrun)
  }
}

///|
/// 一条 AC 细化扫描（单分量平面，band `Ss..Se`，`Ah>0`，点变换 `Al`）。
/// 新非零判据是 `|c|>>Al == 1`（libjpeg `encode_mcu_AC_refine` 的 `temp == 1`），
/// `|c|>>Al > 1` 的系数是"更高位已发过"，只补一位修正位；修正位取 `|c|>>Al` 的最低位。
fn prog_ac_refine_scan(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  plane : Array[Int32],
  stride : Int32,
  bx_max : Int32,
  by_max : Int32,
  ss : Int32,
  se : Int32,
  al : Int32,
) -> Unit {
  let absv = Array::make(64, 0)
  let be : Array[Int32] = []
  let br : Array[Int32] = []
  let mut eobrun = 0
  for by in 0..<by_max {
    for bx in 0..<bx_max {
      let base = (by * stride + bx) * 64
      let mut has_nz = false
      let mut eob = ss - 1
      let mut k = ss
      while k <= se {
        let c = plane[base + k]
        let a = if c < 0 { -c } else { c }
        let av = a >> al
        absv[k] = av
        if av != 0 {
          has_nz = true
        }
        if av == 1 {
          eob = k
        }
        k = k + 1
      }
      if has_nz && eobrun > 0 {
        jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
        eobrun = 0
      }
      let mut r = 0
      k = ss
      while k <= se {
        let av = absv[k]
        if av == 0 {
          r += 1
          k = k + 1
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
        } else {
          jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
          eobrun = 0
          jpeg_prog_emit_sym(w, enc, freq, (r << 4) | 1)
          jpeg_prog_emit_bit(w, freq, if plane[base + k] < 0 { 0 } else { 1 })
          jpeg_prog_flush_corr(w, freq, br)
          r = 0
        }
        k = k + 1
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
/// 一条交错 DC 首扫（4:2:0 的 MCU 顺序：4 个 Y 块 + Cb + Cr）。
fn prog420_dc_first(
  w : JpegBitWriter,
  enc_lum : JpegHuffmanEncoder,
  enc_chr : JpegHuffmanEncoder,
  coefs_y : Array[Int32],
  coefs_cb : Array[Int32],
  coefs_cr : Array[Int32],
  stride_y : Int32,
  stride_c : Int32,
  mcus_x : Int32,
  mcus_y : Int32,
  al : Int32,
) -> Unit {
  let prev : Array[Ref[Int32]] = [Ref(0), Ref(0), Ref(0)]
  for my in 0..<mcus_y {
    for mx in 0..<mcus_x {
      for bi in 0..<4 {
        let gx = mx * 2 + bi % 2
        let gy = my * 2 + bi / 2
        let dc = coefs_y[(gy * stride_y + gx) * 64] >> al
        let diff = dc - prev[0].val
        prev[0].val = dc
        let cat = jpeg_category(diff)
        jpeg_write_bits(w, enc_lum.codes[cat], enc_lum.lengths[cat])
        if cat > 0 {
          jpeg_write_bits(w, jpeg_value_bits(diff, cat), cat)
        }
      }
      let cbase = (my * stride_c + mx) * 64
      let dc_cb = coefs_cb[cbase] >> al
      let diff_cb = dc_cb - prev[1].val
      prev[1].val = dc_cb
      let cat_cb = jpeg_category(diff_cb)
      jpeg_write_bits(w, enc_chr.codes[cat_cb], enc_chr.lengths[cat_cb])
      if cat_cb > 0 {
        jpeg_write_bits(w, jpeg_value_bits(diff_cb, cat_cb), cat_cb)
      }
      let dc_cr = coefs_cr[cbase] >> al
      let diff_cr = dc_cr - prev[2].val
      prev[2].val = dc_cr
      let cat_cr = jpeg_category(diff_cr)
      jpeg_write_bits(w, enc_chr.codes[cat_cr], enc_chr.lengths[cat_cr])
      if cat_cr > 0 {
        jpeg_write_bits(w, jpeg_value_bits(diff_cr, cat_cr), cat_cr)
      }
    }
  }
}

///|
/// 一条交错 DC 细化扫描：每块只发 `(DC >> Al) & 1`。
fn prog420_dc_refine(
  w : JpegBitWriter,
  coefs_y : Array[Int32],
  coefs_cb : Array[Int32],
  coefs_cr : Array[Int32],
  stride_y : Int32,
  stride_c : Int32,
  mcus_x : Int32,
  mcus_y : Int32,
  al : Int32,
) -> Unit {
  for my in 0..<mcus_y {
    for mx in 0..<mcus_x {
      for bi in 0..<4 {
        let gx = mx * 2 + bi % 2
        let gy = my * 2 + bi / 2
        jpeg_write_bits(w, (coefs_y[(gy * stride_y + gx) * 64] >> al) & 1, 1)
      }
      let cbase = (my * stride_c + mx) * 64
      jpeg_write_bits(w, (coefs_cb[cbase] >> al) & 1, 1)
      jpeg_write_bits(w, (coefs_cr[cbase] >> al) & 1, 1)
    }
  }
}

///|
/// 校验脚本合法性（照 ITU-T T.81 对 progressive 参数的约束 + 本库 3 分量布局）。
fn prog_script_check(
  script : Array[JpegProgScan],
) -> Unit raise @types.LoadError {
  if script.length() == 0 {
    raise @types.LoadError::EncodeFailed("progressive 扫描脚本为空")
  }
  for s in script {
    if s.ss < 0 || s.se > 63 || s.ss > s.se {
      raise @types.LoadError::EncodeFailed(
        "progressive 扫描脚本 Ss/Se 越界",
      )
    }
    if s.ah < 0 || s.ah > 13 || s.al < 0 || s.al > 13 {
      raise @types.LoadError::EncodeFailed(
        "progressive 扫描脚本 Ah/Al 越界",
      )
    }
    if s.comps.length() == 0 || s.comps.length() > 3 {
      raise @types.LoadError::EncodeFailed(
        "progressive 扫描脚本分量数无效",
      )
    }
    if s.ss != 0 && s.comps.length() != 1 {
      raise @types.LoadError::EncodeFailed(
        "progressive 的 AC 扫描只能是单分量",
      )
    }
    if s.ss == 0 && s.se != 0 {
      raise @types.LoadError::EncodeFailed(
        "progressive 的 DC 扫描必须 Ss=Se=0",
      )
    }
    for ci in s.comps {
      if ci < 0 || ci > 2 {
        raise @types.LoadError::EncodeFailed(
          "progressive 扫描脚本分量序号越界（仅 0/1/2）",
        )
      }
    }
  }
}

///|
/// 4:2:0 渐进式编码 · 扫描脚本可配置。
///
/// 参数 Parameters:
/// - `img` - 输入图像（1 或 3 通道）
/// - `quality` - 质量 1–100
/// - `script` - 扫描脚本（`jpeg_progressive_script_libjpeg()` 为 libjpeg 默认 10 段）
///
/// 返回 Return:
/// - progressive JPEG（SOF2，Y `2×2`、Cb/Cr `1×1`）字节流
///
/// 错误 Errors:
/// - `LoadError::EncodeFailed` - 尺寸无效、像素数超上限、脚本非法
pub fn encode_jpeg_progressive_420_scripted(
  img : @types.Image,
  quality : Int32,
  script : Array[JpegProgScan],
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
  prog_script_check(script)
  let channels = img.channels
  let data = img.data
  let zz = jpeg_zigzag()
  let quant_lum = jpeg_scaled_quant(std_quant_luminance(), quality)
  let quant_chr = jpeg_scaled_quant(std_quant_chrominance(), quality)
  let dc_lum_enc = build_huffman_encoder(std_dc_lum_bits(), std_dc_lum_vals())
  let dc_chr_enc = build_huffman_encoder(std_dc_chr_bits(), std_dc_chr_vals())
  let mcus_x = (width + 15) / 16
  let mcus_y = (height + 15) / 16
  let stride_y = mcus_x * 2
  let stride_c = mcus_x
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
      let cbase = (by * stride_c + bx) * 64
      jpeg_progressive_quantize_block(
        block, inv_chr, zz, tmp_i, shifted, dct_out, coefs_cb, cbase,
      )
      jpeg_progressive_quantize_block(
        block_cr, inv_chr, zz, tmp_i, shifted, dct_out, coefs_cr, cbase,
      )
    }
  }
  let out : Array[Byte] = []
  out.push(b'\xFF')
  out.push(b'\xD8')
  // ---- DQT
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
  // ---- SOF2（Y 2×2、Cb/Cr 1×1）
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
  // ---- DHT：先给 DC 标准两张（AC 表按扫描逐条重建，紧跟各自 SOS）
  let dc_dht : Array[Byte] = []
  dc_dht.push(b'\x00')
  for b in std_dc_lum_bits() {
    dc_dht.push(b.to_byte())
  }
  for v in std_dc_lum_vals() {
    dc_dht.push(v.to_byte())
  }
  dc_dht.push(b'\x01')
  for b in std_dc_chr_bits() {
    dc_dht.push(b.to_byte())
  }
  for v in std_dc_chr_vals() {
    dc_dht.push(v.to_byte())
  }
  let dc_dht_len = 2 + dc_dht.length()
  out.push(b'\xFF')
  out.push(b'\xC4')
  out.push(((dc_dht_len >> 8) & 0xFF).to_byte())
  out.push((dc_dht_len & 0xFF).to_byte())
  for b in dc_dht {
    out.push(b)
  }
  // ---- 逐扫描：AC 扫描两遍（计频 → 建表 → 写 DHT → SOS → 位流）
  let scratch_out : Array[Byte] = Array::make(1, b'\x00')
  for scan in script {
    let is_dc = scan.ss == 0
    if is_dc && scan.ah == 0 {
      let ids : Array[Byte] = []
      let slots : Array[Byte] = []
      for ci in scan.comps {
        ids.push((ci + 1).to_byte())
        slots.push(if ci == 0 { b'\x00' } else { b'\x11' })
      }
      jpeg_push_sos(
        out,
        ids.length(),
        ids,
        slots,
        0,
        0,
        (scan.ah << 4) | scan.al,
      )
      let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
      prog420_dc_first(
        w,
        dc_lum_enc,
        dc_chr_enc,
        coefs_y,
        coefs_cb,
        coefs_cr,
        stride_y,
        stride_c,
        mcus_x,
        mcus_y,
        scan.al,
      )
      jpeg_flush_bits(w)
    } else if is_dc {
      let ids : Array[Byte] = []
      let slots : Array[Byte] = []
      for ci in scan.comps {
        ids.push((ci + 1).to_byte())
        slots.push(if ci == 0 { b'\x00' } else { b'\x11' })
      }
      jpeg_push_sos(
        out,
        ids.length(),
        ids,
        slots,
        0,
        0,
        (scan.ah << 4) | scan.al,
      )
      let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
      prog420_dc_refine(
        w,
        coefs_y,
        coefs_cb,
        coefs_cr,
        stride_y,
        stride_c,
        mcus_x,
        mcus_y,
        scan.al,
      )
      jpeg_flush_bits(w)
    } else {
      let ci = scan.comps[0]
      let (plane, stride, bx_max, by_max) = if ci == 0 {
        (coefs_y, stride_y, y_fx, y_fy)
      } else if ci == 1 {
        (coefs_cb, stride_c, c_fx, c_fy)
      } else {
        (coefs_cr, stride_c, c_fx, c_fy)
      }
      let slot : Byte = if ci == 0 { b'\x00' } else { b'\x11' }
      let id : Array[Byte] = [(ci + 1).to_byte()]
      let slots : Array[Byte] = [slot]
      if scan.ah == 0 {
        let freq = Array::make(257, 0)
        prog_ac_first_scan(
          JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
          if ci == 0 {
            dc_lum_enc
          } else {
            dc_chr_enc
          },
          freq,
          plane,
          stride,
          bx_max,
          by_max,
          scan.ss,
          scan.se,
          scan.al,
        )
        let (bits, vals) = jpeg_gen_optimal_table(freq)
        let enc = build_huffman_encoder(bits, vals)
        let dht_data : Array[Byte] = []
        dht_data.push(if ci == 0 { b'\x10' } else { b'\x11' })
        for b in bits {
          dht_data.push(b.to_byte())
        }
        for v in vals {
          dht_data.push(v.to_byte())
        }
        let dht_len = 2 + dht_data.length()
        out.push(b'\xFF')
        out.push(b'\xC4')
        out.push(((dht_len >> 8) & 0xFF).to_byte())
        out.push((dht_len & 0xFF).to_byte())
        for b in dht_data {
          out.push(b)
        }
        jpeg_push_sos(
          out,
          1,
          id,
          slots,
          scan.ss,
          scan.se,
          (scan.ah << 4) | scan.al,
        )
        let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
        prog_ac_first_scan(
          w,
          enc,
          [],
          plane,
          stride,
          bx_max,
          by_max,
          scan.ss,
          scan.se,
          scan.al,
        )
        jpeg_flush_bits(w)
      } else {
        let freq = Array::make(257, 0)
        prog_ac_refine_scan(
          JpegBitWriter::{ out: scratch_out, bit_buf: 0, bit_cnt: 0, },
          if ci == 0 {
            dc_lum_enc
          } else {
            dc_chr_enc
          },
          freq,
          plane,
          stride,
          bx_max,
          by_max,
          scan.ss,
          scan.se,
          scan.al,
        )
        let (bits, vals) = jpeg_gen_optimal_table(freq)
        let enc = build_huffman_encoder(bits, vals)
        let dht_data : Array[Byte] = []
        dht_data.push(if ci == 0 { b'\x10' } else { b'\x11' })
        for b in bits {
          dht_data.push(b.to_byte())
        }
        for v in vals {
          dht_data.push(v.to_byte())
        }
        let dht_len = 2 + dht_data.length()
        out.push(b'\xFF')
        out.push(b'\xC4')
        out.push(((dht_len >> 8) & 0xFF).to_byte())
        out.push((dht_len & 0xFF).to_byte())
        for b in dht_data {
          out.push(b)
        }
        jpeg_push_sos(
          out,
          1,
          id,
          slots,
          scan.ss,
          scan.se,
          (scan.ah << 4) | scan.al,
        )
        let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
        prog_ac_refine_scan(
          w,
          enc,
          [],
          plane,
          stride,
          bx_max,
          by_max,
          scan.ss,
          scan.se,
          scan.al,
        )
        jpeg_flush_bits(w)
      }
    }
  }
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}
