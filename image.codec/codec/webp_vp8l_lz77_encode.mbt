///|
/// # WebP VP8L LZ77 编码器（M2）
///
/// 与 `webp_vp8l_encode.mbt` 的 literal-only 版相比，多了三件事：
/// 1. 贪心 LZ77 匹配（哈希链，最短 3、最长 4096）；
/// 2. 每幅图按统计频次构建长度受限（≤15 位）的 canonical Huffman 码表；
/// 3. 码表按 RFC 9649 §3.7.2.1.2 的"码长码 + 零游程"写法输出。
///
/// 未实现（M3）：subtract-green / predictor / palette 变换、色彩缓存、meta 多组。

///|
/// 位数反转（写码时用：流里是 canonical 码的 MSB-first 顺序，写入器是 LSB-first）
fn vp8l_rev_bits(v : Int, n : Int) -> Int {
  let mut r = 0
  for i in 0..<n {
    r = r | (((v >> i) & 1) << (n - 1 - i))
  }
  r
}

///|
/// 由码长表算 canonical 码值表（与解码侧同一规则）
fn vp8l_canonical_codes(lens : Array[Int], alphabet : Int) -> Array[Int] {
  let codes : Array[Int] = Array::make(alphabet, 0)
  let mut max_len = 0
  for i in 0..<alphabet {
    if lens[i] > max_len {
      max_len = lens[i]
    }
  }
  if max_len == 0 {
    return codes
  }
  let bl_count : Array[Int] = Array::make(max_len + 1, 0)
  for i in 0..<alphabet {
    if lens[i] > 0 {
      bl_count[lens[i]] += 1
    }
  }
  let next_code : Array[Int] = Array::make(max_len + 1, 0)
  let mut code = 0
  for bits in 1..<=max_len {
    code = (code + bl_count[bits - 1]) << 1
    next_code[bits] = code
  }
  for s in 0..<alphabet {
    let l = lens[s]
    if l > 0 {
      codes[s] = next_code[l]
      next_code[l] += 1
    }
  }
  codes
}

///|
/// 长度受限 Huffman：按频次生成 ≤`max_bits` 位的码长表。
///
/// 做法：先建普通 Huffman 得深度，再按 JPEG Annex K.3 的"深度钳制 + Kraft 补偿"把
/// 超过 `max_bits` 的部分压回，最后按频次降序重新分配长度。
fn vp8l_build_lengths(
  counts : Array[Int],
  alphabet : Int,
  max_bits : Int,
) -> Array[Int] {
  let lens : Array[Int] = Array::make(alphabet, 0)
  // 收集使用中的符号
  let used : Array[Int] = []
  for s in 0..<alphabet {
    if counts[s] > 0 {
      used.push(s)
    }
  }
  let nu = used.length()
  if nu == 0 {
    return lens
  }
  if nu == 1 {
    lens[used[0]] = 1
    return lens
  }
  // 普通 Huffman：反复合并两个最小频次，记录每个符号的深度
  let weights : Array[Int] = Array::make(2 * nu - 1, 0)
  let parents : Array[Int] = Array::make(2 * nu - 1, -1)
  let symbols : Array[Int] = Array::make(2 * nu - 1, -1)
  for k in 0..<nu {
    weights[k] = counts[used[k]]
    symbols[k] = used[k]
  }
  let mut active : Array[Int] = []
  for k in 0..<nu {
    active.push(k)
  }
  let mut next = nu
  while active.length() > 1 {
    // 找两个最小
    let mut a = 0
    let mut b = 1
    if weights[active[b]] < weights[active[a]] {
      let t = a
      a = b
      b = t
    }
    for k in 2..<active.length() {
      let idx = active[k]
      if weights[idx] < weights[active[a]] {
        b = a
        a = k
      } else if weights[idx] < weights[active[b]] {
        b = k
      }
    }
    let na = active[a]
    let nb = active[b]
    let node = next
    next += 1
    weights[node] = weights[na] + weights[nb]
    parents[na] = node
    parents[nb] = node
    let hi = if a > b { a } else { b }
    let lo = if a > b { b } else { a }
    let rebuilt : Array[Int] = []
    for k in 0..<active.length() {
      if k != lo && k != hi {
        rebuilt.push(active[k])
      }
    }
    rebuilt.push(node)
    active = rebuilt
  }
  // 由父链算深度（先钳到 max_bits）
  let depths : Array[Int] = Array::make(nu, 0)
  for s in 0..<nu {
    let mut d = 0
    let mut p = parents[s]
    while p >= 0 {
      d += 1
      p = parents[p]
    }
    depths[s] = if d > max_bits { max_bits } else { d }
  }
  for s in 0..<nu {
    lens[used[s]] = depths[s]
  }
  // Kraft 补偿：以 2^-max_bits 为单位，K = Σ 2^(max_bits - len) 必须正好等于 2^max_bits
  let unit = 1 << max_bits
  let mut kraft = 0
  for s in 0..<nu {
    kraft = kraft + (1 << (max_bits - depths[s]))
  }
  // 超出：把"最深但仍短于 max_bits"的符号加深一位（优先动低频符号）
  while kraft > unit {
    let mut pick = -1
    for s in 0..<nu {
      if depths[s] < max_bits {
        if pick < 0 ||
          depths[s] > depths[pick] ||
          (depths[s] == depths[pick] && counts[used[s]] < counts[used[pick]]) {
          pick = s
        }
      }
    }
    if pick < 0 {
      break
    }
    kraft = kraft - (1 << (max_bits - depths[pick] - 1))
    depths[pick] += 1
  }
  // 不足：把最短的符号缩短一位（同样优先低频）
  while kraft < unit {
    let mut pick = -1
    for s in 0..<nu {
      if depths[s] > 1 {
        if pick < 0 ||
          depths[s] < depths[pick] ||
          (depths[s] == depths[pick] && counts[used[s]] < counts[used[pick]]) {
          pick = s
        }
      }
    }
    if pick < 0 {
      break
    }
    depths[pick] -= 1
    kraft = kraft + (1 << (max_bits - depths[pick]))
  }
  // 写回码长表
  for s in 0..<nu {
    lens[used[s]] = depths[s]
  }
  lens
}

///|
/// 写一个符号的 canonical 码（位反转后按 LSB-first 写入）
fn vp8l_write_code(w : Vp8lBits, code : Int, len : Int) -> Unit {
  w.write(vp8l_rev_bits(code, len), len)
}

///|
/// 统计长度码 token（0..18）的使用次数，用于构建码长码
fn vp8l_count_length_tokens(lens : Array[Int], alphabet : Int, out : Array[Int]) -> Unit {
  let mut i = 0
  let mut prev = -1
  while i < alphabet {
    let v = lens[i]
    if v == 0 {
      let mut z = 0
      while i + z < alphabet && lens[i + z] == 0 {
        z += 1
      }
      let mut left = z
      while left >= 11 {
        let take = if left > 138 { 138 } else { left }
        out[18] += 1
        left -= take
      }
      while left >= 3 {
        let take = if left > 10 { 10 } else { left }
        out[17] += 1
        left -= take
      }
      while left > 0 {
        out[0] += 1
        left -= 1
      }
      i += z
      prev = 0
    } else {
      let mut run = 1
      while i + run < alphabet && lens[i + run] == v {
        run += 1
      }
      out[v] += 1
      let mut left = run - 1
      i += 1
      while left > 0 {
        if left >= 3 {
          let take = if left > 6 { 6 } else { left }
          out[16] += 1
          left -= take
          i += take
        } else {
          out[v] += 1
          left -= 1
          i += 1
        }
      }
      prev = v
    }
  }
  let _ = prev
}

///|
/// 真正把码长表写进流：simple（1/2 个符号）或 normal（码长码 + 零游程）
fn vp8l_write_prefix_table(w : Vp8lBits, lens : Array[Int], alphabet : Int) -> Unit {
  let used : Array[Int] = []
  for s in 0..<alphabet {
    if lens[s] > 0 {
      used.push(s)
    }
  }
  if used.length() == 0 {
    // 空表按单符号 0 写（解码器视作零比特）
    vp8l_write_simple_single(w, 0)
    return
  }
  if used.length() == 1 {
    vp8l_write_simple_single(w, used[0])
    return
  }
  let mut all_one_bit = true
  for s in used {
    if lens[s] != 1 {
      all_one_bit = false
    }
  }
  if all_one_bit && used.length() == 2 {
    // 双符号 simple 码表：符号必须能塞进 8 位
    w.write(1, 1)
    w.write(1, 1)
    w.write(0, 1)
    w.write(used[0], 8)
    w.write(used[1], 8)
    return
  }
  // normal：先构建码长码
  let tokens : Array[Int] = Array::make(19, 0)
  vp8l_count_length_tokens(lens, alphabet, tokens)
  let cl_lens = vp8l_build_lengths(tokens, 19, 7)
  // num_code_lengths：覆盖所有非零码长码符号在 order 中的位置
  let mut num_code_lengths = 4
  for i in 0..<19 {
    if cl_lens[vp8l_code_length_order[i]] > 0 && i + 1 > num_code_lengths {
      num_code_lengths = i + 1
    }
  }
  w.write(0, 1)
  w.write(num_code_lengths - 4, 4)
  for i in 0..<num_code_lengths {
    w.write(cl_lens[vp8l_code_length_order[i]], 3)
  }
  w.write(0, 1) // max_symbol = 字母表大小
  let cl_codes = vp8l_canonical_codes(cl_lens, 19)
  // 按同一规则重新遍历并写 token
  let mut i = 0
  while i < alphabet {
    let v = lens[i]
    if v == 0 {
      let mut z = 0
      while i + z < alphabet && lens[i + z] == 0 {
        z += 1
      }
      let mut left = z
      while left >= 11 {
        let take = if left > 138 { 138 } else { left }
        vp8l_write_code(w, cl_codes[18], cl_lens[18])
        w.write(take - 11, 7)
        left -= take
      }
      while left >= 3 {
        let take = if left > 10 { 10 } else { left }
        vp8l_write_code(w, cl_codes[17], cl_lens[17])
        w.write(take - 3, 3)
        left -= take
      }
      while left > 0 {
        vp8l_write_code(w, cl_codes[0], cl_lens[0])
        left -= 1
      }
      i += z
    } else {
      let mut run = 1
      while i + run < alphabet && lens[i + run] == v {
        run += 1
      }
      vp8l_write_code(w, cl_codes[v], cl_lens[v])
      let mut left = run - 1
      i += 1
      while left > 0 {
        if left >= 3 {
          let take = if left > 6 { 6 } else { left }
          vp8l_write_code(w, cl_codes[16], cl_lens[16])
          w.write(take - 3, 2)
          left -= take
          i += take
        } else {
          vp8l_write_code(w, cl_codes[v], cl_lens[v])
          left -= 1
          i += 1
        }
      }
    }
  }
}

///|
/// 长度值 → (前缀码, extra 值, extra 位数)
fn vp8l_encode_length(len : Int) -> (Int, Int, Int) {
  if len <= 4 {
    (len - 1, 0, 0)
  } else {
    let mut prefix = 0
    let mut found = false
    let mut p = 4
    while !found && p < 24 {
      let eb = (p - 2) >> 1
      let off = (2 + (p & 1)) << eb
      if len >= off + 1 && len <= off + (1 << eb) {
        prefix = p
        found = true
      }
      p += 1
    }
    let eb = (prefix - 2) >> 1
    let off = (2 + (prefix & 1)) << eb
    (prefix, len - off - 1, eb)
  }
}

///|
/// 扫描行距离 → 距离码（先查 120 项邻域映射，命中用 1..120，否则 dist + 120）
fn vp8l_distance_code(d : Int, width : Int) -> Int {
  for k in 0..<120 {
    let xi = vp8l_distance_dx[k].to_int()
    let yi = vp8l_distance_dy[k].to_int()
    let cand = xi + yi * width
    if cand == d && cand >= 1 {
      return k + 1
    }
  }
  d + 120
}

///|
/// 判断码表是否只有一个符号（单符号树的符号位宽为 0，编码时不得写任何比特）
fn vp8l_is_single(lens : Array[Int], alphabet : Int) -> Bool {
  let mut count = 0
  for i in 0..<alphabet {
    if lens[i] > 0 {
      count += 1
    }
  }
  count <= 1
}

///|
/// 32 位像素哈希（4096 槽）
fn vp8l_hash_pixel(argb : Int) -> Int {
  (((argb * 0x1E35A7BD) & 0xFFFFFFFF) >> 20) & 0xFFF
}

///|
/// M2 编码器：贪心 LZ77 + 频次驱动的 Huffman 码表。
///
/// 体积目标是"进入 PNG 量级"，最终优于 PNG 要靠 M3 的变换。
pub fn encode_webp_vp8l_lz77(img : @types.Image) -> Bytes raise @types.LoadError {
  let w = img.width.to_int()
  let h = img.height.to_int()
  if w <= 0 || h <= 0 {
    raise @types.LoadError::DecodeFailed("WebP 编码：图像尺寸无效")
  }
  if w > 16384 || h > 16384 {
    raise @types.LoadError::DecodeFailed("WebP 编码：尺寸超出 VP8L 上限 16384")
  }
  let ch = img.channels.to_int()
  if ch != 3 && ch != 4 {
    raise @types.LoadError::DecodeFailed("WebP 编码：仅支持 3/4 通道")
  }
  let n = w * h
  let argb : Array[Int] = Array::make(n, 0)
  let mut alpha_solid = true
  for i in 0..<n {
    let base = i * ch
    let r = img.data[base].to_int()
    let g = img.data[base + 1].to_int()
    let b = img.data[base + 2].to_int()
    let a = if ch == 4 {
      img.data[base + 3].to_int()
    } else {
      255
    }
    if a != 255 {
      alpha_solid = false
    }
    argb[i] = (a << 24) | (b << 16) | (g << 8) | r
  }
  // ---- 贪心 LZ77 ----
  let kinds : Array[Int] = []
  let v1 : Array[Int] = []
  let v2 : Array[Int] = []
  let head : Array[Int] = Array::make(4096, -1)
  let chain : Array[Int] = Array::make(n, -1)
  let mut i = 0
  while i < n {
    let mut best_len = 0
    let mut best_dist = 0
    if i + 3 < n {
      let hv = vp8l_hash_pixel(argb[i])
      let mut j = head[hv]
      let mut steps = 0
      while j >= 0 && steps < 16 {
        if argb[j] == argb[i] {
          let mut l = 1
          while l < 4096 && i + l < n && j + l < n && argb[j + l] == argb[i + l] {
            l += 1
          }
          if l >= 3 && l > best_len {
            best_len = l
            best_dist = i - j
          }
        }
        j = chain[j]
        steps += 1
      }
    }
    if best_len >= 3 {
      kinds.push(1)
      v1.push(best_len)
      v2.push(best_dist)
      for k in 0..<best_len {
        if i + k + 3 < n {
          let hv = vp8l_hash_pixel(argb[i + k])
          chain[i + k] = head[hv]
          head[hv] = i + k
        }
      }
      i += best_len
    } else {
      kinds.push(0)
      v1.push(argb[i])
      v2.push(0)
      if i + 3 < n {
        let hv = vp8l_hash_pixel(argb[i])
        chain[i] = head[hv]
        head[hv] = i
      }
      i += 1
    }
  }
  // ---- 统计频次 ----
  let cg : Array[Int] = Array::make(280, 0)
  let cr : Array[Int] = Array::make(256, 0)
  let cb : Array[Int] = Array::make(256, 0)
  let ca : Array[Int] = Array::make(256, 0)
  let cd : Array[Int] = Array::make(40, 0)
  for t in 0..<kinds.length() {
    if kinds[t] == 0 {
      let argb_v = v1[t]
      let g = (argb_v >> 8) & 0xFF
      let r = argb_v & 0xFF
      let b = (argb_v >> 16) & 0xFF
      let a = (argb_v >> 24) & 0xFF
      cg[g] += 1
      cr[r] += 1
      cb[b] += 1
      ca[a] += 1
    } else {
      let (prefix, _, _) = vp8l_encode_length(v1[t])
      cg[256 + prefix] += 1
      let dcode = vp8l_distance_code(v2[t], w)
      if dcode < 40 {
        cd[dcode] += 1
      } else {
        cd[39] += 1
      }
    }
  }
  // ---- 构建码表 ----
  let glens = vp8l_build_lengths(cg, 280, 15)
  let rlens = vp8l_build_lengths(cr, 256, 15)
  let blens = vp8l_build_lengths(cb, 256, 15)
  let alens = vp8l_build_lengths(ca, 256, 15)
  let dlens = vp8l_build_lengths(cd, 40, 15)
  let gcodes = vp8l_canonical_codes(glens, 280)
  let rcodes = vp8l_canonical_codes(rlens, 256)
  let bcodes = vp8l_canonical_codes(blens, 256)
  let acodes = vp8l_canonical_codes(alens, 256)
  let dcodes = vp8l_canonical_codes(dlens, 40)
  // ---- 写流 ----
  let bw = Vp8lBits::new()
  bw.write(0x2F, 8)
  bw.write(w - 1, 14)
  bw.write(h - 1, 14)
  bw.write(if alpha_solid { 0 } else { 1 }, 1)
  bw.write(0, 3)
  bw.write(0, 1) // 无 transform
  bw.write(0, 1) // 无色彩缓存
  bw.write(0, 1) // 单组
  let g_single = vp8l_is_single(glens, 280)
  let r_single = vp8l_is_single(rlens, 256)
  let b_single = vp8l_is_single(blens, 256)
  let a_single = vp8l_is_single(alens, 256)
  let d_single = vp8l_is_single(dlens, 40)
  vp8l_write_prefix_table(bw, glens, 280)
  vp8l_write_prefix_table(bw, rlens, 256)
  vp8l_write_prefix_table(bw, blens, 256)
  vp8l_write_prefix_table(bw, alens, 256)
  vp8l_write_prefix_table(bw, dlens, 40)
  for t in 0..<kinds.length() {
    if kinds[t] == 0 {
      let argb_v = v1[t]
      let g = (argb_v >> 8) & 0xFF
      let r = argb_v & 0xFF
      let b = (argb_v >> 16) & 0xFF
      let a = (argb_v >> 24) & 0xFF
      if !g_single {
        vp8l_write_code(bw, gcodes[g], glens[g])
      }
      if !r_single {
        vp8l_write_code(bw, rcodes[r], rlens[r])
      }
      if !b_single {
        vp8l_write_code(bw, bcodes[b], blens[b])
      }
      if !a_single {
        vp8l_write_code(bw, acodes[a], alens[a])
      }
    } else {
      let len = v1[t]
      let (prefix, extra, ebits) = vp8l_encode_length(len)
      vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      bw.write(extra, ebits)
      let dcode = vp8l_distance_code(v2[t], w)
      if !d_single {
        let (dprefix, dextra, debits) = vp8l_encode_length(dcode)
        vp8l_write_code(bw, dcodes[dprefix], dlens[dprefix])
        bw.write(dextra, debits)
      }
    }
  }
  vp8l_wrap_riff(bw.finish())
}
