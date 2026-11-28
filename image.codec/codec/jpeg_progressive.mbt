///|
/// # JPEG 渐进式（progressive，SOF2）解码
///
/// 与 baseline 的差别是「一条扫描一次算完」变成「多条扫描累积 DCT 系数」：
/// 每条 SOS 只贡献一部分系数位面（DC 首扫 / DC 细化 / AC 首扫 / AC 细化），
/// 全部扫描结束后再统一反量化 + IDCT + 上采样输出。

///|
/// 重置并跳到下一个 RSTn 重启标记之后（与 baseline 路径同口径）
fn jpeg_skip_to_restart(r : JpegBitReader) -> Unit {
  r.bit_cnt = 0
  r.bit_buf = 0
  while r.pos < r.len - 1 {
    if r.data[r.pos].to_int() == 0xFF &&
      r.data[r.pos + 1].to_int() >= 0xD0 &&
      r.data[r.pos + 1].to_int() <= 0xD7 {
      r.pos += 2
      return
    }
    r.pos += 1
  }
}

///|
/// DC 首扫：Huffman 差分 → 累加到预测值 → 左移 Al 位写入系数 0
fn jpeg_dc_first_block(
  r : JpegBitReader,
  table : JpegHuffmanTable,
  buf : Array[Int32],
  base : Int32,
  al : Int32,
  pred : Ref[Int32],
) -> Unit raise @types.LoadError {
  let s = jpeg_decode_huffman(r, table)
  let diff = if s == 0 { 0 } else { jpeg_extend(jpeg_read_bits(r, s), s) }
  pred.val = pred.val + diff
  buf[base] = pred.val << al
}

///|
/// DC 细化：读 1 位，置位 1<<Al（对负数补码而言等价于加上 +-1<<Al）
fn jpeg_dc_refine_block(
  r : JpegBitReader,
  buf : Array[Int32],
  base : Int32,
  al : Int32,
) -> Unit raise @types.LoadError {
  if jpeg_read_bit(r) == 1 {
    buf[base] = buf[base] | (1 << al)
  }
}

///|
/// AC 首扫：run/size 解码，EOB run 跨块生效，系数左移 Al 位写入
fn jpeg_ac_first_block(
  r : JpegBitReader,
  table : JpegHuffmanTable,
  zz : Array[Int32],
  buf : Array[Int32],
  base : Int32,
  ss : Int32,
  se : Int32,
  al : Int32,
  eobrun : Ref[Int32],
) -> Unit raise @types.LoadError {
  if eobrun.val > 0 {
    eobrun.val = eobrun.val - 1
    return
  }
  let mut k = ss
  while k <= se {
    let rs = jpeg_decode_huffman(r, table)
    let run = (rs >> 4) & 0x0F
    let size = rs & 0x0F
    if size == 0 {
      if run == 15 {
        k += 16
        continue
      }
      let mut e = 1 << run
      if run > 0 {
        e = e + jpeg_read_bits(r, run)
      }
      eobrun.val = e - 1
      return
    }
    k += run
    // 与 libjpeg 一致：k 越过 Se 时直接结束本块，不再读幅度位
    if k > se {
      return
    }
    buf[base + zz[k]] = jpeg_extend(jpeg_read_bits(r, size), size) << al
    k += 1
  }
}

///|
/// 细化扫描中的单个系数修正：读 1 位，按符号加 +-1<<Al
fn jpeg_refine_coef(
  r : JpegBitReader,
  buf : Array[Int32],
  idx : Int32,
  p1 : Int32,
  m1 : Int32,
) -> Unit raise @types.LoadError {
  let bit = jpeg_read_bit(r)
  if bit == 1 {
    let v = buf[idx]
    // 该位面已置位时不再累加（libjpeg 同口径）
    if (v & p1) == 0 {
      buf[idx] = if v > 0 { v + p1 } else { v + m1 }
    }
  }
}

///|
/// AC 细化：已非零系数逐位修正；新系数只置 1<<Al 的符号位；EOB run 继续
fn jpeg_ac_refine_block(
  r : JpegBitReader,
  table : JpegHuffmanTable,
  zz : Array[Int32],
  buf : Array[Int32],
  base : Int32,
  ss : Int32,
  se : Int32,
  al : Int32,
  eobrun : Ref[Int32],
) -> Unit raise @types.LoadError {
  let p1 = 1 << al
  let m1 = -p1
  let mut k = ss
  // 本块仍处于上一块设定的 EOB 区间：整块只做修正，不读任何 run/size
  if eobrun.val > 0 {
    while k <= se {
      let idx = base + zz[k]
      if buf[idx] != 0 {
        jpeg_refine_coef(r, buf, idx, p1, m1)
      }
      k += 1
    }
    eobrun.val = eobrun.val - 1
    return
  }
  // libjpeg 结构：每块先读一个 Huffman 码，再按 run 推进；已非零系数的修正位
  // 只在“跳过零位”途中读取，块首不能先修正（否则整条扫描的位流会整体错位）。
  while k <= se {
    let rs = jpeg_decode_huffman(r, table)
    let mut run = (rs >> 4) & 0x0F
    let size = rs & 0x0F
    let mut new_val = 0
    if size != 0 {
      // 新系数：细化扫描里 size 恒为 1，只读 1 位符号（无后续幅度位）
      let sign = jpeg_read_bit(r)
      new_val = if sign == 1 { p1 } else { m1 }
    } else if run != 15 {
      // EOB run：本块剩余位置只做修正
      let mut e = 1 << run
      if run > 0 {
        e = e + jpeg_read_bits(r, run)
      }
      while k <= se {
        let i2 = base + zz[k]
        if buf[i2] != 0 {
          jpeg_refine_coef(r, buf, i2, p1, m1)
        }
        k += 1
      }
      eobrun.val = e - 1
      return
    }
    // 跳过 run 个零位，途中遇已非零系数读修正位（ZRL 时 run 保持 15，不写新值）
    while k <= se {
      let i2 = base + zz[k]
      if buf[i2] != 0 {
        jpeg_refine_coef(r, buf, i2, p1, m1)
      } else {
        if run == 0 {
          break
        }
        run -= 1
      }
      k += 1
    }
    if size != 0 && k <= se {
      buf[base + zz[k]] = new_val
    }
    // 与 libjpeg 的外层 for 自增一致：ZRL 跳 15 个零后落在第 16 个零位置，
    // 此处再前进一格，合计跳过 16 个零位。
    k += 1
  }
}

///|
/// 解一个 8x8 块（按扫描参数分发到 DC/AC 首扫或细化）
fn jpeg_progressive_block(
  reader : JpegBitReader,
  buf : Array[Int32],
  base : Int32,
  scan : JpegScanSpec,
  zz : Array[Int32],
  dc_tab : JpegHuffmanTable,
  ac_tab : JpegHuffmanTable,
  pred : Ref[Int32],
  eobrun : Ref[Int32],
) -> Unit raise @types.LoadError {
  if scan.ss == 0 && scan.se == 0 {
    if scan.ah == 0 {
      jpeg_dc_first_block(reader, dc_tab, buf, base, scan.al, pred)
    } else {
      jpeg_dc_refine_block(reader, buf, base, scan.al)
    }
  } else if scan.ah == 0 {
    jpeg_ac_first_block(
      reader,
      ac_tab,
      zz,
      buf,
      base,
      scan.ss,
      scan.se,
      scan.al,
      eobrun,
    )
  } else {
    jpeg_ac_refine_block(
      reader,
      ac_tab,
      zz,
      buf,
      base,
      scan.ss,
      scan.se,
      scan.al,
      eobrun,
    )
  }
}

///|
/// 解码一条扫描，把系数累积进 coefs（不反量化、不 IDCT）
fn jpeg_progressive_scan(
  header : JpegHeader,
  data : Bytes,
  scan : JpegScanSpec,
  coefs : Array[Array[Int32]],
  bw : Array[Int32],
  bh : Array[Int32],
  stride_x : Array[Int32],
  mcus_x : Int32,
  mcus_y : Int32,
) -> Unit raise @types.LoadError {
  let reader = JpegBitReader::{
    data,
    len: scan.entropy_end,
    pos: scan.entropy_start,
    bit_buf: 0,
    bit_cnt: 0,
  }
  let zz = zigzag()
  let pred : Array[Ref[Int32]] = []
  for _ in 0..<header.num_components {
    pred.push(Ref(0))
  }
  let eobrun = Ref(0)
  let mut mcu_count = 0
  // 单分量扫描按该分量实际块网格光栅序推进；多分量交错扫描按 MCU 网格推进，
  // 且 padding 块（超出图像边界的整块）同样编码在码流里，必须一起解，不能裁剪。
  let interleaved = scan.ns > 1
  let ci_lone = scan.comp_idx[0]
  let units_x = if interleaved { mcus_x } else { bw[ci_lone] }
  let units_y = if interleaved { mcus_y } else { bh[ci_lone] }
  for uy in 0..<units_y {
    for ux in 0..<units_x {
      if header.restart_interval > 0 &&
        mcu_count > 0 &&
        mcu_count % header.restart_interval == 0 {
        for i in 0..<header.num_components {
          pred[i].val = 0
        }
        eobrun.val = 0
        jpeg_skip_to_restart(reader)
      }
      if interleaved {
        for si in 0..<scan.ns {
          let ci = scan.comp_idx[si]
          let hi = header.component_h[ci]
          let vi = header.component_v[ci]
          for bi in 0..<(hi * vi) {
            let gx = ux * hi + bi % hi
            let gy = uy * vi + bi / hi
            jpeg_progressive_block(
              reader,
              coefs[ci],
              (gy * stride_x[ci] + gx) * 64,
              scan,
              zz,
              scan.dc_tabs[si],
              scan.ac_tabs[si],
              pred[ci],
              eobrun,
            )
          }
        }
      } else if ux < bw[ci_lone] && uy < bh[ci_lone] {
        jpeg_progressive_block(
          reader,
          coefs[ci_lone],
          (uy * stride_x[ci_lone] + ux) * 64,
          scan,
          zz,
          scan.dc_tabs[0],
          scan.ac_tabs[0],
          pred[ci_lone],
          eobrun,
        )
      }
      mcu_count += 1
    }
  }
}

///|
/// 全图输出：逐组件块反量化 + IDCT 到组件平面，再按采样因子合成为 RGB
fn jpeg_progressive_output(
  header : JpegHeader,
  coefs : Array[Array[Int32]],
  bw : Array[Int32],
  bh : Array[Int32],
  stride_x : Array[Int32],
  max_h : Int32,
  max_v : Int32,
) -> @types.Image {
  let nc = header.num_components
  let cos_t = idct_cos_table()
  let tmpf : Array[Float] = Array::make(64, 0.0F)
  let block : Array[Int32] = Array::make(64, 0)
  let spatial : Array[Int32] = Array::make(64, 0)
  let planes : Array[Array[Int32]] = []
  let plane_w : Array[Int32] = Array::make(4, 0)
  for ci in 0..<nc {
    let pw = bw[ci] * 8
    let ph = bh[ci] * 8
    plane_w[ci] = pw
    let p : Array[Int32] = Array::make(pw * ph, 0)
    let qt = header.quant_tables[header.component_qt[ci]]
    for by in 0..<bh[ci] {
      for bx in 0..<bw[ci] {
        let base = (by * stride_x[ci] + bx) * 64
        for i in 0..<64 {
          block[i] = coefs[ci][base + i] * qt[i]
        }
        idct_8x8(block, cos_t, tmpf, spatial)
        for py in 0..<8 {
          for px in 0..<8 {
            p[(by * 8 + py) * pw + bx * 8 + px] = spatial[py * 8 + px]
          }
        }
      }
    }
    planes.push(p)
  }
  jpeg_planes_to_rgb(header, planes, plane_w, max_h, max_v)
}

///|
/// progressive 主流程：解析出的每条扫描依次累积，最后一次成型
fn jpeg_decode_progressive(
  header : JpegHeader,
  data : Bytes,
) -> @types.Image raise @types.LoadError {
  let ctx = jpeg_progressive_ctx(header)
  for scan in header.scans {
    jpeg_progressive_scan(
      header,
      data,
      scan,
      ctx.coefs,
      ctx.bw,
      ctx.bh,
      ctx.stride_x,
      ctx.mcus_x,
      ctx.mcus_y,
    )
  }
  jpeg_progressive_render(header, ctx)
}
