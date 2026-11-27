///|
/// # JPEG 渐进式编码（progressive, SOF2）
///
/// 与 baseline（`encode_jpeg_with_quality`）的差别只有三处：
/// 1. 帧头 `SOF0` → `SOF2`；
/// 2. 一条交错扫描 → 四条扫描：DC 首扫（交错 3 分量，`Ss=0 Se=0 Ah=0 Al=0`）+ 每分量一条 AC 首扫
///    （`Ss=1 Se=63 Ah=0 Al=0`，单分量非交错）；
/// 3. 必须先把全图量化系数算完缓存下来——AC 扫描是"回头取每个块的高频系数"，不能边算边写。
///
/// 不带 successive approximation、不带 spectral selection 分段；AC 首扫带 **EOBRUN 合并**
/// （连续**整块全零**的块压成一个 `(rrrr=nbits, ssss=0)` 符号 + nbits 位计数，上限见
/// `PROGRESSIVE_MAX_EOBRUN`；块尾残余零仍按单块 EOB 立即收尾），并**按实际符号频次自建 AC 霍夫曼表**
/// （标准 K.3/K.5 表没有 0x10–0x90 的 EOBn 符号，Kraft 余量也不够追加）。
/// 用途是给解码侧（`jpeg_progressive.mbt`）提供自产样本的闭环，并为后续完整扫描脚本留结构位。
///
/// 体积实测：1280×720 Q55 79,638 B → 73,206 B（−8.1%），128×128 渐变 Q80 3,120 → 2,368 B（−24%）；
/// 与 baseline 解码逐像素相同（同量化表、4:4:4）。

///|
/// 系数缓存上限（像素数）。4:4:4 三分量的量化系数缓存 = `ceil(w/8)*ceil(h/8)*192` 个 Int32，
/// 200 万像素约 24 MB。超限直接拒绝——宁可明确报错，也不在移动端静默吃掉数百 MB。
const PROGRESSIVE_MAX_PIXELS : Int32 = 2000000

///|
/// 单个 EOBRUN 的块数上限。EOBRUN 用 `rrrr=0, ssss=nbits` 的符号表达，nbits ≤ 15；
/// 但标准 AC 霍夫曼表（K.3 / K.5）只定义到 `ssss=10`（符号 0x0A），0x0B–0x0F 缺失，
/// 因此这里取 1023（nbits ≤ 10）。超出就 flush 一次再重新累计，位流仍合法。
const PROGRESSIVE_MAX_EOBRUN : Int32 = 1023

///|
/// 输出挂起的 EOBRUN：先写 `(rrrr=0, ssss=nbits)` 的霍夫曼码，再写 nbits 位余量
/// `eobrun - (1 << nbits)`（解码端按 `(1<<nbits) + bits - 1` 还原，与 libjpeg 同口径）。
/// `eobrun <= 0` 时什么都不写。
fn jpeg_emit_eobrun(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  eobrun : Int32,
) -> Unit {
  if eobrun <= 0 {
    return
  }
  let nbits = jpeg_category(eobrun) - 1
  // 符号是 (rrrr=nbits, ssss=0)，即 nbits << 4；不是符号值 nbits
  let sym = nbits << 4
  jpeg_write_bits(w, enc.codes[sym], enc.lengths[sym])
  if nbits > 0 {
    let extra = eobrun - (1 << nbits)
    jpeg_write_bits(w, jpeg_value_bits(extra, nbits), nbits)
  }
}

///|
/// 把一个 8×8 平面块（已是单个分量的采样值）做 DCT + 量化，结果按**之字形序**写进缓存
/// （`dst[base + k]`，k=0 是 DC）。量化后即按之字形存，好让 AC 扫描顺着 k 递增直接读，不必每次再查 zigzag 表。
fn jpeg_progressive_quantize_block(
  block : Array[Int32],
  inv_quant : Array[Float],
  zz : Array[Int32],
  tmp_i : Array[Int32],
  shifted : Array[Int32],
  dct_out : Array[Int32],
  dst : Array[Int32],
  base : Int32,
) -> Unit {
  for i in 0..<64 {
    shifted[i] = block[i] - 128
  }
  jpeg_fdct_int(shifted, tmp_i, dct_out)
  for k in 0..<64 {
    let i = zz[k]
    let q = Float::from_int(dct_out[i]) * inv_quant[i]
    dst[base + k] = if q >= 0.0F {
      (q + 0.5F).to_int()
    } else {
      -(-q + 0.5F).to_int()
    }
  }
}

///|
/// 写一个 SOS 段头。`ncomp` 为扫描内分量数，`ids` / `tab_slots` 分别是分量 ID 与 `(Td<<4)|Ta` 字节。
fn jpeg_push_sos(
  out : Array[Byte],
  ncomp : Int32,
  ids : Array[Byte],
  tab_slots : Array[Byte],
  ss : Int32,
  se : Int32,
  ahal : Int32,
) -> Unit {
  out.push(b'\xFF')
  out.push(b'\xDA')
  let seg_len = 2 + 1 + ncomp * 2 + 3
  out.push(((seg_len >> 8) & 0xFF).to_byte())
  out.push((seg_len & 0xFF).to_byte())
  out.push(ncomp.to_byte())
  for i in 0..<ncomp {
    out.push(ids[i])
    out.push(tab_slots[i])
  }
  out.push(ss.to_byte())
  out.push(se.to_byte())
  out.push(ahal.to_byte())
}

///|
/// 统计一组分量各自 AC 首扫（`Ss=1 Se=63 Ah=0 Al=0`）的符号频次。
/// 与 `encode_jpeg_progressive` 的 AC 写码逻辑逐分支对应（含 EOBRUN 合并上限与 ZRL），
/// 统计与编码必须完全同构，否则频次为 0 的符号会在位流里缺码。
/// 返回长度 257 的数组，下标是符号值（普通为 `(run<<4)|size`，EOBRUN 为 `nbits<<4`）。
fn jpeg_progressive_ac_freq(
  cis : Array[Int32],
  coefs : Array[Int32],
  blocks_x : Int32,
  blocks_y : Int32,
) -> Array[Int32] {
  let freq = Array::make(257, 0)
  for ci in cis {
    let mut eobrun = 0
    for by in 0..<blocks_y {
      for bx in 0..<blocks_x {
        let base = (by * blocks_x + bx) * 3 * 64 + ci * 64
        let mut has_nz = false
        for k in 1..<64 {
          if coefs[base + k] != 0 {
            has_nz = true
            break
          }
        }
        if !has_nz {
          // 整块没有 AC 系数：并入 EOBRUN，攒满上限或遇到非全零块再写出
          eobrun += 1
          if eobrun == PROGRESSIVE_MAX_EOBRUN {
            let sym = (jpeg_category(eobrun) - 1) << 4
            freq[sym] = freq[sym] + 1
            eobrun = 0
          }
          continue
        }
        // 非全零块：先把挂起的 EOBRUN 写掉（它覆盖的是前面那些整块全零的块）
        if eobrun > 0 {
          let sym = (jpeg_category(eobrun) - 1) << 4
          freq[sym] = freq[sym] + 1
          eobrun = 0
        }
        let mut run = 0
        for k in 1..<64 {
          let c = coefs[base + k]
          if c == 0 {
            run += 1
            continue
          }
          while run > 15 {
            freq[0xF0] = freq[0xF0] + 1
            run -= 16
          }
          let size = jpeg_category(c)
          let sym = (run << 4) | size
          freq[sym] = freq[sym] + 1
          run = 0
        }
        if run > 0 {
          // 块尾剩余全零：本块立即以 EOB 收尾（不进 EOBRUN，避免与后续块错位）
          freq[0] = freq[0] + 1
        }
      }
    }
    if eobrun > 0 {
      let sym = (jpeg_category(eobrun) - 1) << 4
      freq[sym] = freq[sym] + 1
    }
  }
  freq
}

///|
/// libjpeg `jpeg_gen_optimal_table` 的移植：由 257 项符号频次生成 `(bits[16], vals[])`。
/// `freq[256]` 在函数内置 1 作哨兵（T.81 K.2：最长码长组留一个空位，保证没有全 1 码字）。
/// 码长超过 16 时按 K.2 的"两两折半"规则重分配（不保证最优，但偏差极小）。
fn jpeg_gen_optimal_table(
  freq_in : Array[Int32],
) -> (Array[Int32], Array[Int32]) {
  let max_clen : Int32 = 32
  let bits = Array::make(max_clen + 2, 0)
  let codesize = Array::make(257, 0)
  let nz_index = Array::make(257, 0)
  let others = Array::make(257, -1)
  let freq = Array::make(257, 0)
  for i in 0..<257 {
    freq[i] = freq_in[i]
  }
  freq[256] = 1
  // 把非零频次压到前段（256 恒在末尾），后续只在前段找最小
  let mut num_nz = 0
  for i in 0..<257 {
    if freq[i] != 0 {
      nz_index[num_nz] = i
      freq[num_nz] = freq[i]
      num_nz += 1
    }
  }
  // Huffman 合并：1000000001 表示"已并入别的分支"
  let mut all_merged = false
  while !all_merged {
    let mut c1 = -1
    let mut c2 = -1
    let mut v = 1000000000
    let mut v2 = 1000000000
    for idx in 0..<num_nz {
      let fi = freq[idx]
      if fi <= v2 {
        if fi <= v {
          c2 = c1
          v2 = v
          v = fi
          c1 = idx
        } else {
          v2 = fi
          c2 = idx
        }
      }
    }
    if c2 < 0 {
      all_merged = true
      continue
    }
    freq[c1] = freq[c1] + freq[c2]
    freq[c2] = 1000000001
    let mut p1 = c1
    codesize[p1] = codesize[p1] + 1
    while others[p1] >= 0 {
      p1 = others[p1]
      codesize[p1] = codesize[p1] + 1
    }
    others[p1] = c2
    let mut p2 = c2
    codesize[p2] = codesize[p2] + 1
    while others[p2] >= 0 {
      p2 = others[p2]
      codesize[p2] = codesize[p2] + 1
    }
  }
  // 每个码长的符号数
  for idx in 0..<num_nz {
    let cs = if codesize[idx] > max_clen { max_clen } else { codesize[idx] }
    bits[cs] = bits[cs] + 1
  }
  // 码长上限 16（T.81 B.2.4.2）
  let mut li = max_clen
  while li > 16 {
    while bits[li] > 0 {
      let mut j = li - 2
      while bits[j] == 0 {
        j -= 1
      }
      bits[li] = bits[li] - 2
      bits[li - 1] = bits[li - 1] + 1
      bits[j + 1] = bits[j + 1] + 2
      bits[j] = bits[j] - 1
    }
    li -= 1
  }
  // 去掉伪符号 256 占的那一个最长码位
  let mut top = 16
  while bits[top] == 0 {
    top -= 1
  }
  bits[top] = bits[top] - 1
  let out_bits = Array::make(16, 0)
  for l in 1..<=16 {
    out_bits[l - 1] = bits[l]
  }
  // 组装 vals：按原始码长升序（同长按符号号升序）重新排列。编码端 build_huffman_encoder
  // 与解码端 DHT 解析都按同一 (bits, vals) 逐码长分配码字，只要数量相符、符号不重复
  // 位流就是合法的；限长重分配带来的只是极小的非最优（同 K.2 的近似做法）。
  // 不能沿用 libjpeg 的 bit_pos 定位：限长后 bits 被改写而 codesize 未变，
  // 长码符号会落到表的尾部之外，留下重复/缺失的槽位。
  let n_keep = num_nz - 1
  let vals = Array::make(n_keep, 0)
  let taken = Array::make(num_nz, false)
  for j in 0..<n_keep {
    let mut pick = -1
    let mut pick_cs = 0
    for idx in 0..<n_keep {
      if taken[idx] {
        continue
      }
      let cs = codesize[idx]
      if pick < 0 ||
        cs < pick_cs ||
        (cs == pick_cs && nz_index[idx] < nz_index[pick]) {
        pick = idx
        pick_cs = cs
      }
    }
    vals[j] = nz_index[pick]
    taken[pick] = true
  }
  (out_bits, vals)
}

///|
/// JPEG 渐进式编码（纯 MoonBit，全目标可用）。4:4:4 YCbCr + 标准量化表；
///
/// 参数 Parameters:
/// - `img` - 输入图像 Input image（1 或 3 通道；1 通道按灰度复制到三通道）
/// - `quality` - 质量 1–100，50 等价标准量化表
///
/// 返回 Return:
/// - progressive JPEG（SOF2）字节流
///
/// 错误 Errors:
/// - `LoadError::EncodeFailed` - 尺寸无效、像素数超上限（`PROGRESSIVE_MAX_PIXELS`）
pub fn encode_jpeg_progressive(
  img : @types.Image,
  quality : Int32,
) -> Bytes raise @types.LoadError {
  let width = img.width
  let height = img.height
  if width <= 0 || height <= 0 {
    raise @types.LoadError::EncodeFailed("JPEG 尺寸无效")
  }
  // 乘积防溢出：先除后比
  if height > PROGRESSIVE_MAX_PIXELS / width {
    raise @types.LoadError::EncodeFailed(
      "progressive 编码暂支持 ≤ 2,000,000 像素（量化系数缓存上限），大图请用 baseline；若确需支持，先改成三条扫描分别重算 DCT",
    )
  }
  let channels = img.channels
  let data = img.data
  let zz = jpeg_zigzag()
  let quant_lum = jpeg_scaled_quant(std_quant_luminance(), quality)
  let quant_chr = jpeg_scaled_quant(std_quant_chrominance(), quality)
  let dc_lum_enc = build_huffman_encoder(std_dc_lum_bits(), std_dc_lum_vals())
  let dc_chr_enc = build_huffman_encoder(std_dc_chr_bits(), std_dc_chr_vals())
  let blocks_x = (width + 7) / 8
  let blocks_y = (height + 7) / 8
  let out : Array[Byte] = []
  // ---- SOI
  out.push(b'\xFF')
  out.push(b'\xD8')
  // ---- DQT（与 baseline 字节序一致：表 0 亮度、表 1 色度，按之字形书写）
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
  // ---- SOF2（字段布局与 SOF0 完全相同，只把 marker 换成 0xC2）
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
  out.push(b'\x11')
  out.push(b'\x00')
  out.push(b'\x02')
  out.push(b'\x11')
  out.push(b'\x01')
  out.push(b'\x03')
  out.push(b'\x11')
  out.push(b'\x01')
  // ---- DHT（DC 用标准表；AC 用按频次优化出的表，见下）
  // ---- 量化系数缓存（全图一次算完）
  let coefs : Array[Int32] = Array::make(blocks_x * blocks_y * 3 * 64, 0)
  let inv_lum : Array[Float] = Array::make(64, 0.0F)
  let inv_chr : Array[Float] = Array::make(64, 0.0F)
  for i in 0..<64 {
    inv_lum[i] = 1.0F / (Float::from_int(quant_lum[i]) * 8.0F)
    inv_chr[i] = 1.0F / (Float::from_int(quant_chr[i]) * 8.0F)
  }
  let tmp_i : Array[Int32] = Array::make(64, 0)
  let shifted : Array[Int32] = Array::make(64, 0)
  let dct_out : Array[Int32] = Array::make(64, 0)
  let y_block : Array[Int32] = Array::make(64, 128)
  let cb_block : Array[Int32] = Array::make(64, 128)
  let cr_block : Array[Int32] = Array::make(64, 128)
  for by in 0..<blocks_y {
    for bx in 0..<blocks_x {
      for py in 0..<8 {
        for px in 0..<8 {
          let ix = bx * 8 + px
          let iy = by * 8 + py
          // 边界块用边缘像素填充（与 baseline 同口径）
          let sx = if ix >= width { width - 1 } else { ix }
          let sy = if iy >= height { height - 1 } else { iy }
          let didx = sy * width * channels + sx * channels
          let r = data[didx].to_int()
          let g = if channels >= 2 { data[didx + 1].to_int() } else { r }
          let b = if channels >= 3 { data[didx + 2].to_int() } else { r }
          let (y, cb, cr) = rgb_to_ycbcr(r, g, b)
          let o = py * 8 + px
          y_block[o] = y
          cb_block[o] = cb
          cr_block[o] = cr
        }
      }
      let base = (by * blocks_x + bx) * 3 * 64
      jpeg_progressive_quantize_block(
        y_block, inv_lum, zz, tmp_i, shifted, dct_out, coefs, base,
      )
      jpeg_progressive_quantize_block(
        cb_block,
        inv_chr,
        zz,
        tmp_i,
        shifted,
        dct_out,
        coefs,
        base + 64,
      )
      jpeg_progressive_quantize_block(
        cr_block,
        inv_chr,
        zz,
        tmp_i,
        shifted,
        dct_out,
        coefs,
        base + 128,
      )
    }
  }
  // ---- 统计两条 AC 扫描的符号频次，生成优化 Huffman 表
  // EOBRUN 的符号是 `rrrr=nbits, ssss=0`（0x10..0x90），标准 K.3 / K.5 表里没有这些符号，
  // 且其 Kraft 余量只剩约 1 个 16 位槽位，无法简单追加；按频次自建表（同 libjpeg optimize）。
  let freq_lum = jpeg_progressive_ac_freq([0], coefs, blocks_x, blocks_y)
  let freq_chr = jpeg_progressive_ac_freq([1, 2], coefs, blocks_x, blocks_y)
  let (ac_lum_bits, ac_lum_vals) = jpeg_gen_optimal_table(freq_lum)
  let (ac_chr_bits, ac_chr_vals) = jpeg_gen_optimal_table(freq_chr)
  let ac_lum_enc = build_huffman_encoder(ac_lum_bits, ac_lum_vals)
  let ac_chr_enc = build_huffman_encoder(ac_chr_bits, ac_chr_vals)
  // ---- DHT：DC 标准表 + 上面生成的两张 AC 表
  let dht_data : Array[Byte] = []
  dht_data.push(b'\x00')
  for b in std_dc_lum_bits() {
    dht_data.push(b.to_byte())
  }
  for v in std_dc_lum_vals() {
    dht_data.push(v.to_byte())
  }
  dht_data.push(b'\x01')
  for b in std_dc_chr_bits() {
    dht_data.push(b.to_byte())
  }
  for v in std_dc_chr_vals() {
    dht_data.push(v.to_byte())
  }
  dht_data.push(b'\x10')
  for b in ac_lum_bits {
    dht_data.push(b.to_byte())
  }
  for v in ac_lum_vals {
    dht_data.push(v.to_byte())
  }
  dht_data.push(b'\x11')
  for b in ac_chr_bits {
    dht_data.push(b.to_byte())
  }
  for v in ac_chr_vals {
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
  // ---- 扫描 1：DC 首扫（交错 3 分量）
  jpeg_push_sos(
    out,
    3,
    [b'\x01', b'\x02', b'\x03'],
    [b'\x00', b'\x11', b'\x11'],
    0,
    0,
    0x00,
  )
  let w1 = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
  let prev : Array[Ref[Int32]] = [Ref(0), Ref(0), Ref(0)]
  for by in 0..<blocks_y {
    for bx in 0..<blocks_x {
      let base = (by * blocks_x + bx) * 3 * 64
      for ci in 0..<3 {
        let dc = coefs[base + ci * 64]
        let diff = dc - prev[ci].val
        prev[ci].val = dc
        let cat = jpeg_category(diff)
        let enc = if ci == 0 { dc_lum_enc } else { dc_chr_enc }
        jpeg_write_bits(w1, enc.codes[cat], enc.lengths[cat])
        if cat > 0 {
          jpeg_write_bits(w1, jpeg_value_bits(diff, cat), cat)
        }
      }
    }
  }
  jpeg_flush_bits(w1)
  // ---- 扫描 2–4：AC 首扫（单分量，Ss=1 Se=63）
  for ci in 0..<3 {
    let enc = if ci == 0 { ac_lum_enc } else { ac_chr_enc }
    let mut eobrun = 0
    let slots : Array[Byte] = [if ci == 0 { b'\x00' } else { b'\x11' }]
    let ids : Array[Byte] = [
      (if ci == 0 { 1 } else if ci == 1 { 2 } else { 3 }).to_byte(),
    ]
    jpeg_push_sos(out, 1, ids, slots, 1, 63, 0x00)
    let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
    let zrl = enc.codes[0xF0]
    let zrl_len = enc.lengths[0xF0]
    for by in 0..<blocks_y {
      for bx in 0..<blocks_x {
        let base = (by * blocks_x + bx) * 3 * 64 + ci * 64
        // 块内是否还有非零系数（k=1..63）
        let mut has_nz = false
        for k in 1..<64 {
          if coefs[base + k] != 0 {
            has_nz = true
            break
          }
        }
        if !has_nz {
          // 整块没有 AC 系数：并入 EOBRUN，攒满上限或遇到非全零块再写出
          eobrun += 1
          if eobrun == PROGRESSIVE_MAX_EOBRUN {
            jpeg_emit_eobrun(w, enc, eobrun)
            eobrun = 0
          }
          continue
        }
        // 非全零块：先把挂起的 EOBRUN 写掉（它覆盖的是前面那些整块全零的块）
        if eobrun > 0 {
          jpeg_emit_eobrun(w, enc, eobrun)
          eobrun = 0
        }
        let mut run = 0
        for k in 1..<64 {
          let c = coefs[base + k]
          if c == 0 {
            run += 1
            continue
          }
          while run > 15 {
            jpeg_write_bits(w, zrl, zrl_len)
            run -= 16
          }
          let size = jpeg_category(c)
          let sym = (run << 4) | size
          jpeg_write_bits(w, enc.codes[sym], enc.lengths[sym])
          jpeg_write_bits(w, jpeg_value_bits(c, size), size)
          run = 0
        }
        if run > 0 {
          // 块尾剩余全零：本块立即以 EOB 收尾（不进 EOBRUN，避免与后续块错位）
          jpeg_emit_eobrun(w, enc, 1)
        }
      }
    }
    if eobrun > 0 {
      jpeg_emit_eobrun(w, enc, eobrun)
    }
    jpeg_flush_bits(w)
  }
  // ---- EOI
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}
