///|
/// GF(2^8) 乘法（多项式 0x11D），不依赖查表。
fn qr_gf_mul(a : Int32, b : Int32) -> Int32 {
  let mut x = a & 0xFF
  let mut y = b & 0xFF
  let mut r = 0
  for _ in 0..<8 {
    if (y & 1) == 1 {
      r = r ^ x
    }
    x = x << 1
    if (x & 0x100) != 0 {
      x = x ^ 0x11D
    }
    y = y >> 1
  }
  r & 0xFF
}

///|
fn qr_gf_pow(base : Int32, exp : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<exp {
    r = qr_gf_mul(r, base)
  }
  r
}

///|
/// 计算 Reed-Solomon 纠错码字（返回 ecc_len 个字节）。
fn qr_rs_encode(data : Array[Int32], ecc_len : Int32) -> Array[Int32] {
  // 生成多项式 g(x) = (x - α^0)(x - α^1)...（系数从高次到低次）
  let mut gen : Array[Int32] = [1]
  for i in 0..<ecc_len {
    let alpha = qr_gf_pow(2, i)
    let next : Array[Int32] = Array::make(gen.length() + 1, 0)
    for j in 0..<gen.length() {
      next[j] = next[j] ^ gen[j]
      next[j + 1] = next[j + 1] ^ qr_gf_mul(gen[j], alpha)
    }
    gen = next
  }
  let rem : Array[Int32] = Array::make(ecc_len, 0)
  for b in data {
    let factor = (b & 0xFF) ^ rem[0]
    for i in 1..<ecc_len {
      rem[i - 1] = rem[i]
    }
    rem[ecc_len - 1] = 0
    for i in 0..<ecc_len {
      rem[i] = rem[i] ^ qr_gf_mul(gen[i + 1], factor)
    }
  }
  rem
}

///|
/// BCH(15,5) 格式信息编码，返回 15 位整数。
/// L=01 + mask 000 必须得到 0x77C4（标准串 111011111000100）。
fn qr_format_bits(ec_level : Int32, mask : Int32) -> Int32 {
  let data = ((ec_level & 3) << 3) | (mask & 7)
  // BCH(15,5)：rem = data << 10，对高 5 位（bit14..bit10）做长除法，
  // 生成多项式 0x537 (10100110111) 按当前位对齐（shift 4..0）。
  let mut rem = data << 10
  for i in 0..<5 {
    if ((rem >> (14 - i)) & 1) == 1 {
      rem = rem ^ (0x537 << (4 - i))
    }
  }
  (((data << 10) | (rem & 0x3FF)) ^ 0x5412) & 0x7FFF
}

///|
/// 构造 QR 模块矩阵（21×21，版本 1），1 = 黑。
fn qr_build_matrix(payload : Bytes) -> Array[Int32] {
  let size = 21
  let modules : Array[Int32] = Array::make(size * size, 0)
  let is_func : Array[Bool] = Array::make(size * size, false)
  let set = fn(idx : Int32, v : Int32) {
    modules[idx] = v
    is_func[idx] = true
  }
  // finder + separator（三个角）
  let finder_pos : Array[(Int32, Int32)] = [(0, 0), (0, 14), (14, 0)]
  for (fr, fc) in finder_pos {
    for r in -1..<8 {
      for c in -1..<8 {
        let rr = fr + r
        let cc = fc + c
        if rr >= 0 && rr < size && cc >= 0 && cc < size {
          let in_core = r >= 0 && r <= 6 && c >= 0 && c <= 6
          let mut v = 0
          if in_core {
            let border = r == 0 || r == 6 || c == 0 || c == 6
            let center = r >= 2 && r <= 4 && c >= 2 && c <= 4
            v = if border || center { 1 } else { 0 }
          }
          set(rr * size + cc, v)
        }
      }
    }
  }
  // timing pattern
  for i in 8..<13 {
    set(6 * size + i, if i % 2 == 0 { 1 } else { 0 })
    set(i * size + 6, if i % 2 == 0 { 1 } else { 0 })
  }
  // dark module
  set(13 * size + 8, 1)
  // 格式信息占位（先写 0，稍后覆盖；标记为 function）
  let fmt_pos_a : Array[(Int32, Int32)] = [
    (8, 0),
    (8, 1),
    (8, 2),
    (8, 3),
    (8, 4),
    (8, 5),
    (8, 7),
    (8, 8),
    (7, 8),
    (5, 8),
    (4, 8),
    (3, 8),
    (2, 8),
    (1, 8),
    (0, 8),
  ]
  for (r, c) in fmt_pos_a {
    set(r * size + c, 0)
  }
  for i in 0..<7 {
    set((size - 1 - i) * size + 8, 0)
  }
  for i in 0..<8 {
    set(8 * size + (size - 8 + i), 0)
  }
  // 数据位流：mode 0100 + 长度(8) + payload
  let bits : Array[Int32] = []
  bits.push(0)
  bits.push(1)
  bits.push(0)
  bits.push(0)
  for i in 0..<8 {
    bits.push((payload.length() >> (7 - i)) & 1)
  }
  for i in 0..<payload.length() {
    let b = payload[i].to_int()
    for k in 0..<8 {
      bits.push((b >> (7 - k)) & 1)
    }
  }
  // 数据容量：版本1-L = 19 数据码字 = 152 位
  let data_capacity = 19 * 8
  if bits.length() > data_capacity {
    // 超容量：截断（生成器定位为小载荷）
    while bits.length() > data_capacity {
      let _ = bits.pop()
    }
  }
  // 终止符
  for _ in 0..<4 {
    if bits.length() < data_capacity {
      bits.push(0)
    }
  }
  while bits.length() % 8 != 0 {
    bits.push(0)
  }
  // 填充码字 0xEC / 0x11
  let mut pad_toggle = true
  while bits.length() < data_capacity {
    let byte_val = if pad_toggle { 0xEC } else { 0x11 }
    for k in 0..<8 {
      bits.push((byte_val >> (7 - k)) & 1)
    }
    pad_toggle = !pad_toggle
  }
  // 数据码字
  let data_codes : Array[Int32] = Array::make(19, 0)
  for i in 0..<19 {
    let mut v = 0
    for k in 0..<8 {
      v = (v << 1) | bits[i * 8 + k]
    }
    data_codes[i] = v
  }
  let ecc = qr_rs_encode(data_codes, 7)
  let all_codes : Array[Int32] = []
  for c in data_codes {
    all_codes.push(c)
  }
  for c in ecc {
    all_codes.push(c)
  }
  // zigzag 放置（右列优先，跳过第 6 列）
  let mut bit_idx = 0
  let total_bits = all_codes.length() * 8
  let mut col = size - 1
  let mut upward = true
  while col > 0 {
    if col == 6 {
      col -= 1
    }
    for step in 0..<size {
      let r = if upward { size - 1 - step } else { step }
      for dc in 0..<2 {
        let c = col - dc
        let idx = r * size + c
        if !is_func[idx] {
          let bit = if bit_idx < total_bits {
            let byte = all_codes[bit_idx / 8]
            (byte >> (7 - bit_idx % 8)) & 1
          } else {
            0
          }
          modules[idx] = bit
          bit_idx += 1
        }
      }
    }
    upward = !upward
    col -= 2
  }
  // 掩码 0：(r + c) % 2 == 0 翻转（仅数据模块）
  for r in 0..<size {
    for c in 0..<size {
      let idx = r * size + c
      if !is_func[idx] && (r + c) % 2 == 0 {
        modules[idx] = if modules[idx] == 1 { 0 } else { 1 }
      }
    }
  }
  // 写入格式信息（L 级 = 01，mask 0）
  // 规范要求 15 位按 MSB-first 铺到位置上（bit14 在 (8,0)，bit0 在 (0,8)）。
  // 旧实现用 (fmt >> i) 从 LSB 开始铺，等价于把整串反序写入：读码器按标准读出的
  // ECC/掩码与实际掩码不符 → 数据区被错误去掩码 → Reed–Solomon 校验失败（S23 F1）。
  let fmt = qr_format_bits(1, 0)
  for i in 0..<15 {
    let bit = (fmt >> (14 - i)) & 1
    let (r, c) = fmt_pos_a[i]
    modules[r * size + c] = bit
  }
  // 格式信息副本 2（ISO 18004 标准布局）：
  //   bit0..bit7  → 行 8、列 20..13（bit0 在最右列 size-1）
  //   bit8..bit14 → 列 8、行 14..20（bit8 在 row size-15+8 = 14）
  // dark module 固定在 (size-8, 8) = (13, 8)，不参与这两段。
  for i in 0..<8 {
    let bit = (fmt >> i) & 1
    modules[8 * size + (size - 1 - i)] = bit
  }
  for i in 8..<15 {
    let bit = (fmt >> i) & 1
    modules[(size - 15 + i) * size + 8] = bit
  }
  modules
}

///|
/// 把 QR 矩阵渲染为灰度图（白底 255 / 黑模块 0），默认 4 模块 quiet zone。
pub fn render_qr(
  payload : Bytes,
  module_px~ : Int32 = 8,
  quiet_zone~ : Int32 = 4,
) -> @types.Image {
  let size = 21
  let mp = if module_px < 1 { 1 } else { module_px }
  let qz = if quiet_zone < 0 { 0 } else { quiet_zone }
  let modules = qr_build_matrix(payload)
  let px = (size + 2 * qz) * mp
  let data : Array[Byte] = Array::make(px * px, b'\xFF')
  for r in 0..<size {
    for c in 0..<size {
      if modules[r * size + c] == 1 {
        for dy in 0..<mp {
          for dx in 0..<mp {
            let y = (r + qz) * mp + dy
            let x = (c + qz) * mp + dx
            data[y * px + x] = b'\x00'
          }
        }
      }
    }
  }
  @types.Image::{
    width: px,
    height: px,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
/// 返回 21×21 的 QR 模块矩阵（1 = 黑），供精确断言使用。
pub fn qr_modules(payload : Bytes) -> Array[Int32] {
  qr_build_matrix(payload)
}

///|
/// 版本 1-L 字节模式的最大载荷（字节）：19 数据码字 × 8 = 152 位，
/// 减去 4 位模式指示 + 8 位字符计数 + 4 位终止符 → 136 位 = 17 字节。
pub fn qr_v1_max_bytes() -> Int32 {
  17
}

///|
/// 载荷能否由本生成器（版本 1-L）无损编码。超出时调用方必须报错，
/// 不能静默截断——截断后生成的图与用户输入不符（S23 F2）。
pub fn qr_fits_v1(payload : Bytes) -> Bool {
  payload.length() <= qr_v1_max_bytes()
}
