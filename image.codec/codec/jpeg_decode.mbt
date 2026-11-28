///|
/// # JPEG 解码 JPEG Decode
///
/// JPEG baseline 解码实现 JPEG baseline decoding implementation
// 纯 MoonBit JPEG 解码（全目标可用：native/wasm/js）
// 支持 baseline JPEG (SOF0), 8-bit, YCbCr 3 通道或灰度
// 实现: Huffman 解码 + 反量化 + IDCT + YCbCr→RGB + 色度上采样
// 支持 chroma subsampling: 4:4:4, 4:2:2, 4:2:0
// 不支持 progressive (SOF2)、CMYK、arithmetic coding

///|
/// JPEG 位读取器
priv struct JpegBitReader {
  data : Bytes
  len : Int32
  mut pos : Int32
  mut bit_buf : Int32
  mut bit_cnt : Int32
}

///|
/// JPEG Huffman 表（规范解码）
priv struct JpegHuffmanTable {
  maxcode : Array[Int32]
  mincode : Array[Int32]
  valptr : Array[Int32]
  huffval : Array[Int32]
}

///|
/// 空 Huffman 表
fn empty_huffman_table() -> JpegHuffmanTable {
  JpegHuffmanTable::{
    maxcode: Array::make(17, -1),
    mincode: Array::make(17, 0),
    valptr: Array::make(17, 0),
    huffval: [],
  }
}

///|
/// 构建 Huffman 表
fn build_jpeg_huffman(
  counts : Array[Int32],
  values : Array[Int32],
) -> JpegHuffmanTable {
  let maxcode = Array::make(17, -1)
  let mincode = Array::make(17, 0)
  let valptr = Array::make(17, 0)
  let mut code = 0
  let mut k = 0
  for l in 1..<=16 {
    valptr[l] = k
    mincode[l] = code
    code += counts[l - 1]
    if counts[l - 1] > 0 {
      maxcode[l] = code - 1
    }
    k += counts[l - 1]
    code = code << 1
  }
  JpegHuffmanTable::{ maxcode, mincode, valptr, huffval: values, }
}

///|
/// 读取一位
fn jpeg_read_bit(r : JpegBitReader) -> Int32 raise @types.LoadError {
  if r.bit_cnt == 0 {
    if r.pos >= r.len {
      raise @types.LoadError::DecodeFailed("JPEG 数据意外结束")
    }
    let b = r.data[r.pos].to_int()
    r.pos += 1
    if b == 0xFF {
      if r.pos >= r.len {
        raise @types.LoadError::DecodeFailed("JPEG 数据意外结束于 0xFF")
      }
      let next = r.data[r.pos].to_int()
      r.pos += 1
      if next == 0x00 {
        r.bit_buf = 0xFF
      } else if next >= 0xD0 && next <= 0xD7 {
        r.bit_buf = 0
      } else {
        raise @types.LoadError::DecodeFailed("JPEG 无效标记 0xFF")
      }
    } else {
      r.bit_buf = b
    }
    r.bit_cnt = 8
  }
  let bit = (r.bit_buf >> 7) & 1
  r.bit_buf = (r.bit_buf & 0x7F) << 1
  r.bit_cnt -= 1
  bit
}

///|
/// 读取 n 位
fn jpeg_read_bits(r : JpegBitReader, n : Int32) -> Int32 raise @types.LoadError {
  let mut result = 0
  for _ in 0..<n {
    result = (result << 1) | jpeg_read_bit(r)
  }
  result
}

///|
/// Huffman 解码
fn jpeg_decode_huffman(
  r : JpegBitReader,
  table : JpegHuffmanTable,
) -> Int32 raise @types.LoadError {
  let mut code = 0
  for l in 1..<=16 {
    code = (code << 1) | jpeg_read_bit(r)
    if table.maxcode[l] != -1 && code <= table.maxcode[l] {
      let idx = table.valptr[l] + code - table.mincode[l]
      if idx >= 0 && idx < table.huffval.length() {
        return table.huffval[idx]
      }
      raise @types.LoadError::DecodeFailed("JPEG Huffman 索引越界")
    }
  }
  raise @types.LoadError::DecodeFailed("JPEG Huffman 解码失败")
}

///|
/// JPEG 值扩展（符号扩展）
fn jpeg_extend(val : Int32, size : Int32) -> Int32 {
  let vt = 1 << (size - 1)
  if val < vt {
    val - (1 << size) + 1
  } else {
    val
  }
}

///|
/// IDCT 余弦表（已并入 `Cu` 权重，节省最内层判断）
fn idct_cos_table() -> Array[Float] {
  let table = Array::make(64, 0.0F)
  for u in 0..<8 {
    let cu = if u == 0 { 0.70710678F } else { 1.0F }
    for x in 0..<8 {
      table[u * 8 + x] = cu *
        @math.cosf(
          (2.0F * Float::from_int(x) + 1.0F) *
          Float::from_int(u) *
          3.14159265F /
          16.0F,
        )
    }
  }
  table
}

///|
/// 8×8 IDCT（可分离：先行后列，铲掉每块重建余弦表与 4096 次乘法）
fn idct_8x8(
  block : Array[Int32],
  cos_t : Array[Float],
  tmp : Array[Float],
  out : Array[Int32],
) -> Unit {
  for v in 0..<8 {
    for x in 0..<8 {
      let mut sum = 0.0F
      for u in 0..<8 {
        sum += Float::from_int(block[v * 8 + u]) * cos_t[u * 8 + x]
      }
      tmp[v * 8 + x] = sum
    }
  }
  for y in 0..<8 {
    for x in 0..<8 {
      let mut sum = 0.0F
      for v in 0..<8 {
        sum += tmp[v * 8 + x] * cos_t[v * 8 + y]
      }
      let val = (sum * 0.25F + 128.5F).to_int()
      out[y * 8 + x] = val.clamp(min=0, max=255)
    }
  }
}

///|
/// Zigzag 顺序
fn zigzag() -> Array[Int32] {
  [
    0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48,
    41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22,
    15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55,
    62, 63,
  ]
}

///|
/// 解码一个 8x8 块
fn jpeg_decode_block(
  r : JpegBitReader,
  dc_table : JpegHuffmanTable,
  ac_table : JpegHuffmanTable,
  quant : Array[Int32],
  prev_dc : Ref[Int32],
  zz : Array[Int32],
  block : Array[Int32],
) -> Unit raise @types.LoadError {
  for i in 0..<64 {
    block[i] = 0
  }
  let s = jpeg_decode_huffman(r, dc_table)
  let diff = if s == 0 {
    0
  } else {
    let bits = jpeg_read_bits(r, s)
    jpeg_extend(bits, s)
  }
  block[0] = prev_dc.val + diff
  prev_dc.val = block[0]
  let mut k = 1
  while k < 64 {
    let rs = jpeg_decode_huffman(r, ac_table)
    let run = (rs >> 4) & 0x0F
    let size = rs & 0x0F
    if size == 0 {
      if run == 15 {
        k += 16
        continue
      } else {
        break
      }
    }
    k += run
    if k >= 64 {
      break
    }
    let bits = jpeg_read_bits(r, size)
    block[zz[k]] = jpeg_extend(bits, size)
    k += 1
  }
  for i in 0..<64 {
    block[i] = block[i] * quant[i]
  }
}

///|
/// YCbCr → RGB 色彩空间转换（整数定点，16 位权重，与浮点版差 ≤1 LSB）
fn ycbcr_to_rgb(y : Int32, cb : Int32, cr : Int32) -> (Int32, Int32, Int32) {
  let cbf = cb - 128
  let crf = cr - 128
  let r = y + ((91881 * crf) >> 16)
  let g = y - ((22554 * cbf + 46802 * crf) >> 16)
  let b = y + ((116130 * cbf) >> 16)
  (r.clamp(min=0, max=255), g.clamp(min=0, max=255), b.clamp(min=0, max=255))
}

///|
/// 一个扫描（SOS 段 + 熵数据区间）的参数。baseline 只用第 0 个；progressive 逐段累积。
priv struct JpegScanSpec {
  ns : Int32
  comp_idx : Array[Int32]
  // 扫描开始时的 Huffman 表快照：progressive 文件会在扫描之间重定义同号表，
  // 必须按扫描时刻取表，不能用文件末尾的最终版本。
  dc_tabs : Array[JpegHuffmanTable]
  ac_tabs : Array[JpegHuffmanTable]
  ss : Int32
  se : Int32
  ah : Int32
  al : Int32
  entropy_start : Int32
  entropy_end : Int32
}

///|
/// JPEG 解码头部信息
priv struct JpegHeader {
  width : Int32
  height : Int32
  num_components : Int32
  quant_tables : Array[Array[Int32]]
  huff_dc : Array[JpegHuffmanTable]
  huff_ac : Array[JpegHuffmanTable]
  component_h : Array[Int32]
  component_v : Array[Int32]
  component_qt : Array[Int32]
  restart_interval : Int32
  scan_comp_idx : Array[Int32]
  scan_dc_table : Array[Int32]
  scan_ac_table : Array[Int32]
  scan_ns : Int32
  entropy_start : Int32
  progressive : Bool
  scans : Array[JpegScanSpec]
}

///|
/// 从熵数据起点前推，定位下一个真实标记（跳过 0xFF00 填充字节与 RSTn 重启标记）。
/// 返回该标记的 0xFF 位置；到文件末尾则返回 len。
fn jpeg_skip_entropy_to_marker(data : Bytes, from : Int32) -> Int32 {
  let len = data.length()
  let mut p = from
  while p < len - 1 {
    if data[p].to_int() == 0xFF {
      let m = data[p + 1].to_int()
      if m != 0x00 && !(m >= 0xD0 && m <= 0xD7) {
        return p
      }
      p += 2
      continue
    }
    p += 1
  }
  len
}

///|
/// 解析 JPEG 标记段（SOF0/DQT/DHT/DRI/SOS），返回头部信息
fn jpeg_parse_header(data : Bytes) -> JpegHeader raise @types.LoadError {
  let len = data.length()
  if len < 2 || data[0].to_int() != 0xFF || data[1].to_int() != 0xD8 {
    raise @types.LoadError::DecodeFailed("JPEG SOI marker 错误")
  }
  let mut pos = 2
  let mut width = 0
  let mut height = 0
  // 注意：Array::make(4, Array::make(64,0)) 会让 4 个槽共享同一个数组实体，
  // 后写入的表会覆盖先写入的表（亮度表被色度表覆盖 → 解码整体偏色/失真）。必须逐个新建。
  let quant_tables : Array[Array[Int32]] = []
  for _ in 0..<4 {
    quant_tables.push(Array::make(64, 0))
  }
  let huff_dc : Array[JpegHuffmanTable] = []
  let huff_ac : Array[JpegHuffmanTable] = []
  for _ in 0..<4 {
    huff_dc.push(empty_huffman_table())
    huff_ac.push(empty_huffman_table())
  }
  let mut num_components = 3
  let component_ids : Array[Int32] = Array::make(4, 0)
  let component_h : Array[Int32] = Array::make(4, 1)
  let component_v : Array[Int32] = Array::make(4, 1)
  let component_qt : Array[Int32] = Array::make(4, 0)
  let mut restart_interval = 0
  let scan_comp_idx : Array[Int32] = Array::make(4, 0)
  let scan_dc_table : Array[Int32] = Array::make(4, 0)
  let scan_ac_table : Array[Int32] = Array::make(4, 0)
  let mut scan_ns = 0
  let mut entropy_start = 0
  let mut progressive = false
  let scans : Array[JpegScanSpec] = []
  let zz = zigzag()
  while pos < len {
    if data[pos].to_int() != 0xFF {
      pos += 1
      continue
    }
    let marker = data[pos + 1].to_int()
    pos += 2
    match marker {
      0xC0 => {
        // SOF0: length(2) + precision(1) + height(2) + width(2) + num_components(1)
        if pos + 9 > len {
          raise @types.LoadError::DecodeFailed("JPEG SOF0 过短")
        }
        let _precision = data[pos + 2].to_int()
        height = data[pos + 3].to_int() * 256 + data[pos + 4].to_int()
        width = data[pos + 5].to_int() * 256 + data[pos + 6].to_int()
        num_components = data[pos + 7].to_int()
        pos += 8
        for i in 0..<num_components {
          if pos + 3 > len {
            raise @types.LoadError::DecodeFailed("JPEG SOF0 component 过短")
          }
          component_ids[i] = data[pos].to_int()
          let hv = data[pos + 1].to_int()
          component_h[i] = (hv >> 4) & 0x0F
          component_v[i] = hv & 0x0F
          component_qt[i] = data[pos + 2].to_int()
          pos += 3
        }
      }
      0xC2 => {
        // SOF2：与 SOF0 字段布局一致，只多一个「这张是 progressive」的标记
        if pos + 9 > len {
          raise @types.LoadError::DecodeFailed("JPEG SOF2 过短")
        }
        let _precision2 = data[pos + 2].to_int()
        height = data[pos + 3].to_int() * 256 + data[pos + 4].to_int()
        width = data[pos + 5].to_int() * 256 + data[pos + 6].to_int()
        num_components = data[pos + 7].to_int()
        if num_components < 1 || num_components > 4 {
          raise @types.LoadError::DecodeFailed("JPEG SOF2 分量数越界")
        }
        pos += 8
        progressive = true
        for i in 0..<num_components {
          if pos + 3 > len {
            raise @types.LoadError::DecodeFailed("JPEG SOF2 component 过短")
          }
          component_ids[i] = data[pos].to_int()
          let hv = data[pos + 1].to_int()
          component_h[i] = (hv >> 4) & 0x0F
          component_v[i] = hv & 0x0F
          component_qt[i] = data[pos + 2].to_int()
          pos += 3
        }
      }
      0xDB => {
        // DQT
        let seg_len = data[pos].to_int() * 256 + data[pos + 1].to_int()
        let seg_end = pos + seg_len
        pos += 2
        while pos < seg_end {
          let pq = data[pos].to_int()
          let precision = pq >> 4
          let tq = pq & 0x0F
          pos += 1
          let step = if precision == 0 { 1 } else { 2 }
          if tq < 4 {
            for i in 0..<64 {
              let v = if precision == 0 {
                data[pos].to_int()
              } else {
                data[pos].to_int() * 256 + data[pos + 1].to_int()
              }
              quant_tables[tq][zz[i]] = v
              pos += step
            }
          } else {
            pos += 64 * step
          }
        }
      }
      0xC4 => {
        // DHT
        let seg_len = data[pos].to_int() * 256 + data[pos + 1].to_int()
        let seg_end = pos + seg_len
        pos += 2
        while pos < seg_end {
          let tc_th = data[pos].to_int()
          let tc = (tc_th >> 4) & 0x0F
          let th = tc_th & 0x0F
          pos += 1
          let counts = Array::make(16, 0)
          for i in 0..<16 {
            counts[i] = data[pos + i].to_int()
          }
          pos += 16
          let total = {
            let mut s = 0
            for c in counts {
              s += c
            }
            s
          }
          let values = Array::make(total, 0)
          for i in 0..<total {
            values[i] = data[pos + i].to_int()
          }
          pos += total
          if th < 4 {
            let table = build_jpeg_huffman(counts, values)
            if tc == 0 {
              huff_dc[th] = table
            } else {
              huff_ac[th] = table
            }
          }
        }
      }
      0xDD => {
        // DRI
        let seg_len = data[pos].to_int() * 256 + data[pos + 1].to_int()
        restart_interval = data[pos + 2].to_int() * 256 + data[pos + 3].to_int()
        pos += seg_len
      }
      0xDA => {
        // SOS
        let seg_len = data[pos].to_int() * 256 + data[pos + 1].to_int()
        scan_ns = data[pos + 2].to_int()
        let scomp : Array[Int32] = Array::make(4, 0)
        let sdc : Array[Int32] = Array::make(4, 0)
        let sac : Array[Int32] = Array::make(4, 0)
        let sdc_tab : Array[JpegHuffmanTable] = []
        let sac_tab : Array[JpegHuffmanTable] = []
        for _ in 0..<4 {
          sdc_tab.push(empty_huffman_table())
          sac_tab.push(empty_huffman_table())
        }
        let mut p = pos + 3
        for i in 0..<scan_ns {
          let cs = data[p].to_int()
          let td_ta = data[p + 1].to_int()
          let mut cidx = 0
          for j in 0..<num_components {
            if component_ids[j] == cs {
              cidx = j
              break
            }
          }
          scan_comp_idx[i] = cidx
          scan_dc_table[i] = (td_ta >> 4) & 0x0F
          scan_ac_table[i] = td_ta & 0x0F
          scomp[i] = cidx
          sdc[i] = (td_ta >> 4) & 0x0F
          sac[i] = td_ta & 0x0F
          if progressive {
            let td = sdc[i]
            let ta = sac[i]
            sdc_tab[i] = huff_dc[td]
            sac_tab[i] = huff_ac[ta]
          }
          p += 2
        }
        pos += seg_len
        entropy_start = pos
        if progressive {
          // SOS 尾部 3 字节：Ss / Se / AhAl
          let tail = pos - 3
          let ss = if tail >= 0 && tail < len { data[tail].to_int() } else { 0 }
          let se = if tail + 1 >= 0 && tail + 1 < len {
            data[tail + 1].to_int()
          } else {
            0
          }
          let ahal = if tail + 2 >= 0 && tail + 2 < len {
            data[tail + 2].to_int()
          } else {
            0
          }
          let e_end = jpeg_skip_entropy_to_marker(data, entropy_start)
          scans.push(JpegScanSpec::{
            ns: scan_ns,
            comp_idx: scomp,
            dc_tabs: sdc_tab,
            ac_tabs: sac_tab,
            ss,
            se,
            ah: (ahal >> 4) & 0x0F,
            al: ahal & 0x0F,
            entropy_start,
            entropy_end: e_end,
          })
          // 继续解析后续扫描；下一轮从标记处开始
          pos = e_end
          continue
        }
        break
      }
      0xD9 => break
      _ =>
        if pos + 2 <= len {
          let seg_len = data[pos].to_int() * 256 + data[pos + 1].to_int()
          pos += seg_len
        }
    }
  }
  JpegHeader::{
    width,
    height,
    num_components,
    quant_tables,
    huff_dc,
    huff_ac,
    component_h,
    component_v,
    component_qt,
    restart_interval,
    scan_comp_idx,
    scan_dc_table,
    scan_ac_table,
    scan_ns,
    entropy_start,
    progressive,
    scans,
  }
}

///|
/// 解码 JPEG 扫描数据（MCU 循环），返回 RGB 像素
fn jpeg_decode_scan(
  header : JpegHeader,
  data : Bytes,
) -> @types.Image raise @types.LoadError {
  let width = header.width
  let height = header.height
  let num_components = header.num_components
  let zz = zigzag()
  let reader = JpegBitReader::{
    data,
    len: data.length(),
    pos: header.entropy_start,
    bit_buf: 0,
    bit_cnt: 0,
  }
  let mut max_h = 1
  let mut max_v = 1
  for i in 0..<num_components {
    if header.component_h[i] > max_h {
      max_h = header.component_h[i]
    }
    if header.component_v[i] > max_v {
      max_v = header.component_v[i]
    }
  }
  let mcu_width = max_h * 8
  let mcu_height = max_v * 8
  let mcus_x = (width + mcu_width - 1) / mcu_width
  let mcus_y = (height + mcu_height - 1) / mcu_height
  let dc_pred : Array[Ref[Int32]] = []
  for _ in 0..<num_components {
    dc_pred.push(Ref(0))
  }
  let mut mcu_count = 0
  // 全图复用：IDCT 余弦表、块/空间/浮点暂存、各分量整幅平面
  let cos_t = idct_cos_table()
  let tmpf : Array[Float] = Array::make(64, 0.0F)
  let block : Array[Int32] = Array::make(64, 0)
  let spatial : Array[Int32] = Array::make(64, 0)
  // 每个分量一块整幅平面（行跨距按 8 对齐），供最后统一做色度上采样与 RGB 转换
  let plane_stride : Array[Int32] = Array::make(num_components, 0)
  let comp_data : Array[Array[Int32]] = []
  for i in 0..<num_components {
    let hi = header.component_h[i]
    let vi = header.component_v[i]
    let dw = (width * hi + max_h - 1) / max_h
    let dh = (height * vi + max_v - 1) / max_v
    let stride = (dw + 7) / 8 * 8
    let ph = (dh + 7) / 8 * 8
    plane_stride[i] = stride
    comp_data.push(Array::make(stride * ph, 0))
  }
  for _my in 0..<mcus_y {
    for _mx in 0..<mcus_x {
      let my = _my
      let mx = _mx
      if header.restart_interval > 0 &&
        mcu_count > 0 &&
        mcu_count % header.restart_interval == 0 {
        for i in 0..<num_components {
          dc_pred[i].val = 0
        }
        reader.bit_cnt = 0
        while reader.pos < reader.len - 1 {
          if reader.data[reader.pos].to_int() == 0xFF &&
            reader.data[reader.pos + 1].to_int() >= 0xD0 &&
            reader.data[reader.pos + 1].to_int() <= 0xD7 {
            reader.pos += 2
            break
          }
          reader.pos += 1
        }
      }
      for si in 0..<header.scan_ns {
        let ci = header.scan_comp_idx[si]
        let hi = header.component_h[ci]
        let vi = header.component_v[ci]
        let nblocks = hi * vi
        let dc_tab = header.huff_dc[header.scan_dc_table[si]]
        let ac_tab = header.huff_ac[header.scan_ac_table[si]]
        let qt = header.quant_tables[header.component_qt[ci]]
        for bi in 0..<nblocks {
          jpeg_decode_block(reader, dc_tab, ac_tab, qt, dc_pred[ci], zz, block)
          idct_8x8(block, cos_t, tmpf, spatial)
          // 全局块坐标：MCU 内的块序 → 整幅块网格
          let bx = mx * hi + bi % hi
          let by = my * vi + bi / hi
          let stride = plane_stride[ci]
          let plane = comp_data[ci]
          let plane_len = plane.length()
          for py in 0..<8 {
            for px in 0..<8 {
              let gx = bx * 8 + px
              let gy = by * 8 + py
              let idx = gy * stride + gx
              if idx >= 0 && idx < plane_len {
                plane[idx] = spatial[py * 8 + px]
              }
            }
          }
        }
      }
      mcu_count += 1
    }
  }
  jpeg_planes_to_rgb(header, comp_data, plane_stride, max_h, max_v)
}

///|
/// JPEG 解码（纯 MoonBit，全目标可用）。支持 baseline JPEG (SOF0), 8-bit, YCbCr 3 通道。不支持 progressive (SOF2)、CMYK、arithmetic coding。 JPEG decoding (pure MoonBit, all targets). Supports baseline JPEG (SOF0), 8-bit, YCbCr 3 channels. Does not support progressive (SOF2), CMYK, or arithmetic coding.

///|
/// 参数 Parameters:
/// - `data` - JPEG 字节流 JPEG byte stream
///
/// 返回 Return:
/// - 解码后的 8-bit Image Decoded 8-bit Image
///
/// 错误 Errors:
/// - `LoadError::DecodeFailed` - 数据过短、SOI 标记缺失、不支持的颜色空间、Huffman 解码失败 Data too short, missing SOI marker, unsupported color space, Huffman decode failure
pub fn decode_jpeg_pure(data : Bytes) -> @types.Image raise @types.LoadError {
  let header = jpeg_parse_header(data)
  if header.width <= 0 || header.height <= 0 {
    raise @types.LoadError::DecodeFailed("JPEG 尺寸无效")
  }
  @types.check_dims(header.width, header.height, header.num_components)
  if header.progressive {
    jpeg_decode_progressive(header, data)
  } else {
    jpeg_decode_scan(header, data)
  }
}
