///|
/// # progressive 的 successive approximation（`Ah>0`）编码
///
/// 这里放三件东西：
/// 1. `jpeg_prog_shift`：AC 系数的点变换（按绝对值右移，向零取整，同 libjpeg）；
/// 2. AC 细化扫描（`Ah=1 Al=0`）的写码与频次统计——同一份遍历代码，靠 `freq.length() > 0`
///    切换"计数"与"写位"，保证统计与位流严格同构；
/// 3. 符号发射小工具（EOBRUN + 缓冲修正位一起发）。
///
/// 位流顺序严格照 libjpeg `encode_mcu_AC_refine`：
/// - 块内有新非零系数时，先 flush 挂起的 EOBRUN（连同跨块修正位），再写 `(r<<4)|1`、
///   一位符号位，然后发本块已缓的修正位；
/// - 只有旧非零系数时，只把修正位塞进本块缓冲，块尾计一个 EOBRUN 并把缓冲并入跨块缓冲；
/// - `r > 15` 且还没到最后一个新非零位置时折 ZRL，ZRL 之前发跨块量、之后发本块缓冲。
fn jpeg_prog_shift(value : Int32, al : Int32) -> Int32 {
  if al <= 0 {
    value
  } else if value < 0 {
    -(-value >> al)
  } else {
    value >> al
  }
}

///|
fn jpeg_prog_emit_sym(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  sym : Int32,
) -> Unit {
  if freq.length() > 0 {
    freq[sym] = freq[sym] + 1
  } else {
    jpeg_write_bits(w, enc.codes[sym], enc.lengths[sym])
  }
}

///|
fn jpeg_prog_emit_bit(
  w : JpegBitWriter,
  freq : Array[Int32],
  bit : Int32,
) -> Unit {
  if freq.length() == 0 {
    jpeg_write_bits(w, bit, 1)
  }
}

///|
fn jpeg_prog_emit_value(
  w : JpegBitWriter,
  freq : Array[Int32],
  value : Int32,
  length : Int32,
) -> Unit {
  if freq.length() == 0 && length > 0 {
    jpeg_write_bits(w, jpeg_value_bits(value, length), length)
  }
}

///|
/// 发挂起的 EOBRUN（若有），随后把跨块累积的修正位缓冲倒出去。发出后必须清空，避免重复。
fn jpeg_prog_flush_eobrun(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  eobrun : Int32,
  be : Array[Int32],
) -> Unit {
  if eobrun > 0 {
    let nbits = jpeg_category(eobrun) - 1
    let sym = nbits << 4
    jpeg_prog_emit_sym(w, enc, freq, sym)
    if nbits > 0 {
      jpeg_prog_emit_value(w, freq, eobrun - (1 << nbits), nbits)
    }
  }
  for b in be {
    jpeg_prog_emit_bit(w, freq, b)
  }
  be.clear()
}

///|
fn jpeg_prog_flush_corr(
  w : JpegBitWriter,
  freq : Array[Int32],
  br : Array[Int32],
) -> Unit {
  for b in br {
    jpeg_prog_emit_bit(w, freq, b)
  }
  br.clear()
}

///|
/// 一条 AC 细化扫描（单分量，`Ah=1 Al=0`）。`freq` 非空时只统计符号频次、不写位；
/// 为空时写进 `w`（此时调用方需已推好 SOS）。
///
/// 两个修正位缓冲对应 libjpeg 的 `BE`（跨块累积，随 EOBRUN 发出）与 `BR`（本块新增，
/// 跟随 ZRL 或新系数符号之后发出）。搞混顺序会让解码端在错误的位置读修正位。
fn jpeg_progressive_ac_refine_scan(
  w : JpegBitWriter,
  enc : JpegHuffmanEncoder,
  freq : Array[Int32],
  coefs : Array[Int32],
  blocks_x : Int32,
  blocks_y : Int32,
  ci : Int32,
) -> Unit {
  let absv = Array::make(64, 0)
  let be : Array[Int32] = []
  let br : Array[Int32] = []
  let mut eobrun = 0
  for by in 0..<blocks_y {
    for bx in 0..<blocks_x {
      let base = (by * blocks_x + bx) * 3 * 64 + ci * 64
      // 预处理：|c|（Al=0，不再移位），顺带记下最后一个新非零位置
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
      // 本块有系数要写时，先把上一批挂起的 EOBRUN（连同其修正位）发掉
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
        // 还没到最后一个新非零位置时，超过 15 的零run 折成 ZRL：
        // 先发挂起量 → ZRL 符号 → 本块已缓的修正位
        while r > 15 && k <= eob {
          jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
          eobrun = 0
          jpeg_prog_emit_sym(w, enc, freq, 0xF0)
          r -= 16
          jpeg_prog_flush_corr(w, freq, br)
        }
        if av > 1 {
          // 旧非零：只缓存一位修正位（绝对值的最低位）
          br.push(av & 1)
          k += 1
          continue
        }
        // 新非零：flush 挂起量 → (r<<4)|1 → 符号位 → 本块已缓的修正位
        jpeg_prog_flush_eobrun(w, enc, freq, eobrun, be)
        eobrun = 0
        let sym = (r << 4) | 1
        jpeg_prog_emit_sym(w, enc, freq, sym)
        jpeg_prog_emit_bit(w, freq, if coefs[base + k] < 0 { 0 } else { 1 })
        jpeg_prog_flush_corr(w, freq, br)
        r = 0
        k += 1
      }
      // 块尾还有零或本块修正位：计一个 EOBRUN，本块修正位并入跨块缓冲
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
