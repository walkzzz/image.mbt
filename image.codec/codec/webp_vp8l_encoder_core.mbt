///|
/// # VP8L 编码核心：可复用的图像流写入 + 变换选择
///
/// 分层：
/// - `vp8l_pack_argb`：Image → RFC 顺序 ARGB 像素数组（a<<24 | r<<16 | g<<8 | b）
/// - `vp8l_tokenize`：贪心 LZ77 切 token
/// - `vp8l_write_image_stream`：写一条图像流（cache-info + [meta] + 5 棵树 + token）
/// - `encode_webp_lossless`：对外单入口，自动选 palette / predictor / subtract-green

///|
priv struct Vp8lTokenStream {
  kinds : Array[Int]
  v1 : Array[Int]
  v2 : Array[Int]
}

///|
/// 打包为 RFC 顺序 ARGB（alpha 31..24、red 23..16、green 15..8、blue 7..0）
fn vp8l_pack_argb(img : @types.Image) -> (Array[Int], Int, Int) raise @types.LoadError {
  let w = img.width.to_int()
  let h = img.height.to_int()
  let ch = img.channels.to_int()
  if w <= 0 || h <= 0 {
    raise @types.LoadError::DecodeFailed("WebP 编码：图像尺寸无效")
  }
  if w > 16384 || h > 16384 {
    raise @types.LoadError::DecodeFailed("WebP 编码：尺寸超出 VP8L 上限 16384")
  }
  if ch != 3 && ch != 4 {
    raise @types.LoadError::DecodeFailed("WebP 编码：仅支持 3/4 通道")
  }
  let n = w * h
  let out : Array[Int] = Array::make(n, 0)
  for i in 0..<n {
    let base = i * ch
    let r = img.data[base].to_int()
    let g = img.data[base + 1].to_int()
    let b = img.data[base + 2].to_int()
    let a = if ch == 4 { img.data[base + 3].to_int() } else { 255 }
    out[i] = (a << 24) | (r << 16) | (g << 8) | b
  }
  (out, w, h)
}

///|
fn vp8l_tokenize(pixels : Array[Int]) -> Vp8lTokenStream {
  let n = pixels.length()
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
      let hv = vp8l_hash_pixel(pixels[i])
      let mut j = head[hv]
      let mut steps = 0
      while j >= 0 && steps < 16 {
        if pixels[j] == pixels[i] {
          let mut l = 1
          while l < 4096 && i + l < n && j + l < n && pixels[j + l] == pixels[i + l] {
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
          let hv = vp8l_hash_pixel(pixels[i + k])
          chain[i + k] = head[hv]
          head[hv] = i + k
        }
      }
      i += best_len
    } else {
      kinds.push(0)
      v1.push(pixels[i])
      v2.push(0)
      if i + 3 < n {
        let hv = vp8l_hash_pixel(pixels[i])
        chain[i] = head[hv]
        head[hv] = i
      }
      i += 1
    }
  }
  Vp8lTokenStream::{ kinds, v1, v2 }
}

///|
fn vp8l_ch(argb : Int, shift : Int) -> Int {
  (argb >> shift) & 0xFF
}

///|
/// 写一条图像流。`level0 = true` 时写 meta 位（主图），子分辨率图像不写。
fn vp8l_write_image_stream(
  bw : Vp8lBits,
  pixels : Array[Int],
  width : Int,
  level0 : Bool,
) -> Unit {
  let tok = vp8l_tokenize(pixels)
  bw.write(0, 1) // 无色彩缓存
  if level0 {
    bw.write(0, 1) // 单组前缀码
  }
  let cg : Array[Int] = Array::make(280, 0)
  let cr : Array[Int] = Array::make(256, 0)
  let cb : Array[Int] = Array::make(256, 0)
  let ca : Array[Int] = Array::make(256, 0)
  let cd : Array[Int] = Array::make(40, 0)
  for t in 0..<tok.kinds.length() {
    if tok.kinds[t] == 0 {
      let argb = tok.v1[t]
      cg[vp8l_ch(argb, 8)] += 1
      cr[vp8l_ch(argb, 16)] += 1
      cb[vp8l_ch(argb, 0)] += 1
      ca[vp8l_ch(argb, 24)] += 1
    } else {
      let (prefix, _, _) = vp8l_encode_length(tok.v1[t])
      cg[256 + prefix] += 1
      let dcode = vp8l_distance_code(tok.v2[t], width)
      let (dsym, _, _) = vp8l_encode_length(dcode)
      cd[dsym] += 1
    }
  }
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
  for t in 0..<tok.kinds.length() {
    if tok.kinds[t] == 0 {
      let argb = tok.v1[t]
      if !g_single {
        let g = vp8l_ch(argb, 8)
        vp8l_write_code(bw, gcodes[g], glens[g])
      }
      if !r_single {
        let r = vp8l_ch(argb, 16)
        vp8l_write_code(bw, rcodes[r], rlens[r])
      }
      if !b_single {
        let b = vp8l_ch(argb, 0)
        vp8l_write_code(bw, bcodes[b], blens[b])
      }
      if !a_single {
        let a = vp8l_ch(argb, 24)
        vp8l_write_code(bw, acodes[a], alens[a])
      }
    } else {
      let (prefix, extra, ebits) = vp8l_encode_length(tok.v1[t])
      if !g_single {
        vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      }
      bw.write(extra, ebits)
      let dcode = vp8l_distance_code(tok.v2[t], width)
      let (dsym, dextra, debits) = vp8l_encode_length(dcode)
      if !d_single {
        vp8l_write_code(bw, dcodes[dsym], dlens[dsym])
      }
      bw.write(dextra, debits)
    }
  }
}
