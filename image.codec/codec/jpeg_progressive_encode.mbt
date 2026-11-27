///|
/// # JPEG 渐进式编码（progressive, SOF2）
///
/// 与 baseline（`encode_jpeg_with_quality`）的差别只有三处：
/// 1. 帧头 `SOF0` → `SOF2`；
/// 2. 一条交错扫描 → 四条扫描：DC 首扫（交错 3 分量，`Ss=0 Se=0 Ah=0 Al=0`）+ 每分量一条 AC 首扫
///    （`Ss=1 Se=63 Ah=0 Al=0`，单分量非交错）；
/// 3. 必须先把全图量化系数算完缓存下来——AC 扫描是"回头取每个块的高频系数"，不能边算边写。
///
/// 这是**最简合法形态**（不带 successive approximation、不带 EOBRUN 合并、不带 spectral selection 分段），
/// 用途是给解码侧（`jpeg_progressive.mbt`）提供自产样本的闭环，并为后续完整扫描脚本留结构位。

///|
/// 系数缓存上限（像素数）。4:4:4 三分量的量化系数缓存 = `ceil(w/8)*ceil(h/8)*192` 个 Int32，
/// 200 万像素约 24 MB。超限直接拒绝——宁可明确报错，也不在移动端静默吃掉数百 MB。
const PROGRESSIVE_MAX_PIXELS : Int32 = 2000000

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
/// JPEG 渐进式编码（纯 MoonBit，全目标可用）。4:4:4 YCbCr + 标准量化表 + 标准霍夫曼表。
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
  let ac_lum_enc = build_huffman_encoder(std_ac_lum_bits(), std_ac_lum_vals())
  let ac_chr_enc = build_huffman_encoder(std_ac_chr_bits(), std_ac_chr_vals())
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
  // ---- DHT（4 张表，与 baseline 一致）
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
  for b in std_ac_lum_bits() {
    dht_data.push(b.to_byte())
  }
  for v in std_ac_lum_vals() {
    dht_data.push(v.to_byte())
  }
  dht_data.push(b'\x11')
  for b in std_ac_chr_bits() {
    dht_data.push(b.to_byte())
  }
  for v in std_ac_chr_vals() {
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
    let slots : Array[Byte] = [if ci == 0 { b'\x00' } else { b'\x11' }]
    let ids : Array[Byte] = [
      (if ci == 0 { 1 } else if ci == 1 { 2 } else { 3 }).to_byte(),
    ]
    jpeg_push_sos(out, 1, ids, slots, 1, 63, 0x00)
    let w = JpegBitWriter::{ out, bit_buf: 0, bit_cnt: 0, }
    let eob = enc.codes[0x00]
    let eob_len = enc.lengths[0x00]
    let zrl = enc.codes[0xF0]
    let zrl_len = enc.lengths[0xF0]
    for by in 0..<blocks_y {
      for bx in 0..<blocks_x {
        let base = (by * blocks_x + bx) * 3 * 64 + ci * 64
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
          jpeg_write_bits(w, eob, eob_len)
        }
      }
    }
    jpeg_flush_bits(w)
  }
  // ---- EOI
  out.push(b'\xFF')
  out.push(b'\xD9')
  Bytes::from_array(out)
}
