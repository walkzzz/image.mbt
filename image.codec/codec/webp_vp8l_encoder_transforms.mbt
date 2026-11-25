///|
/// # VP8L 编码变换：palette / predictor / subtract-green 与对外单入口

///|
fn vp8l_write_header(bw : Vp8lBits, w : Int, h : Int, alpha_solid : Bool) -> Unit {
  bw.write(0x2F, 8)
  bw.write(w - 1, 14)
  bw.write(h - 1, 14)
  bw.write(if alpha_solid { 0 } else { 1 }, 1)
  bw.write(0, 3)
}

///|
fn vp8l_alpha_solid(pixels : Array[Int]) -> Bool {
  for i in 0..<pixels.length() {
    if vp8l_ch(pixels[i], 24) != 255 {
      return false
    }
  }
  true
}

// ==================== 变换：subtract-green ====================

///|
fn vp8l_apply_subtract_green(pixels : Array[Int]) -> Array[Int] {
  let out : Array[Int] = Array::make(pixels.length(), 0)
  for i in 0..<pixels.length() {
    let argb = pixels[i]
    let g = vp8l_ch(argb, 8)
    let r = (vp8l_ch(argb, 16) - g) & 0xFF
    let b = (vp8l_ch(argb, 0) - g) & 0xFF
    out[i] = (vp8l_ch(argb, 24) << 24) | (r << 16) | (g << 8) | b
  }
  out
}

// ==================== 变换：predictor ====================

///|
fn vp8l_predict_value(mode : Int, l : Int, t : Int, tl : Int, tr : Int) -> Int {
  if mode == 0 {
    0xFF000000
  } else if mode == 1 {
    l
  } else if mode == 2 {
    t
  } else if mode == 3 {
    tr
  } else if mode == 4 {
    tl
  } else if mode == 5 {
    vp8l_avg2(vp8l_avg2(l, tr), t)
  } else if mode == 6 {
    vp8l_avg2(l, tl)
  } else if mode == 7 {
    vp8l_avg2(l, t)
  } else if mode == 8 {
    vp8l_avg2(tl, t)
  } else if mode == 9 {
    vp8l_avg2(t, tr)
  } else if mode == 10 {
    vp8l_avg2(vp8l_avg2(l, tl), vp8l_avg2(t, tr))
  } else if mode == 11 {
    vp8l_select(l, t, tl)
  } else if mode == 12 {
    vp8l_clamp_add_full(l, t, tl)
  } else {
    vp8l_clamp_add_half(vp8l_avg2(l, t), tl)
  }
}

///|
/// 按 RFC 边界规则取预测值（编码侧邻居用原图，解码侧邻居是已重建像素，两者等价）
fn vp8l_predict_pixel(
  pixels : Array[Int],
  w : Int,
  x : Int,
  y : Int,
  mode : Int,
) -> Int {
  let i = y * w + x
  if y == 0 {
    if x == 0 {
      0xFF000000
    } else {
      pixels[i - 1]
    }
  } else if x == 0 {
    pixels[i - w]
  } else {
    let l = pixels[i - 1]
    let t = pixels[i - w]
    let tl = pixels[i - w - 1]
    let tr = if x + 1 < w { pixels[i - w + 1] } else { pixels[y * w] }
    vp8l_predict_value(mode, l, t, tl, tr)
  }
}

///|
/// 残差代价：四通道环差绝对值之和。四个通道手工展开 —— 这里在内层 14×像素 的循环里
/// 每像素调用一次，用 `for shift in [...]` 会在每次调用分配一个数组。
fn vp8l_residual_cost(orig : Int, pred : Int) -> Int {
  let mut c = 0
  let d0 = (vp8l_ch(orig, 24) - vp8l_ch(pred, 24)) & 0xFF
  c += if d0 < 128 { d0 } else { 256 - d0 }
  let d1 = (vp8l_ch(orig, 16) - vp8l_ch(pred, 16)) & 0xFF
  c += if d1 < 128 { d1 } else { 256 - d1 }
  let d2 = (vp8l_ch(orig, 8) - vp8l_ch(pred, 8)) & 0xFF
  c += if d2 < 128 { d2 } else { 256 - d2 }
  let d3 = (vp8l_ch(orig, 0) - vp8l_ch(pred, 0)) & 0xFF
  c += if d3 < 128 { d3 } else { 256 - d3 }
  c
}

///|
/// 前向 predictor：逐 16² 块选模式，返回 (残差像素, 模式图)
fn vp8l_forward_predictor(
  pixels : Array[Int],
  w : Int,
  h : Int,
  block_bits : Int,
) -> (Array[Int], Array[Int], Int) {
  let bs = 1 << block_bits
  let bx = (w + bs - 1) / bs
  let by = (h + bs - 1) / bs
  let modes : Array[Int] = Array::make(bx * by, 0)
  for bloc_y in 0..<by {
    for bloc_x in 0..<bx {
      let x0 = bloc_x * bs
      let y0 = bloc_y * bs
      let x1 = if x0 + bs > w { w } else { x0 + bs }
      let y1 = if y0 + bs > h { h } else { y0 + bs }
      let mut best_mode = 1
      let mut best_cost = -1
      for mode in 0..<14 {
        let mut cost = 0
        for yy in y0..<y1 {
          for xx in x0..<x1 {
            let i = yy * w + xx
            let pred = vp8l_predict_pixel(pixels, w, xx, yy, mode)
            cost += vp8l_residual_cost(pixels[i], pred)
          }
        }
        if best_cost < 0 || cost < best_cost {
          best_cost = cost
          best_mode = mode
        }
      }
      modes[bloc_y * bx + bloc_x] = best_mode
    }
  }
  let resid : Array[Int] = Array::make(w * h, 0)
  for y in 0..<h {
    for x in 0..<w {
      let i = y * w + x
      let mode = if y < (by * bs) && x < (bx * bs) {
        modes[(y / bs) * bx + (x / bs)]
      } else {
        1
      }
      let pred = vp8l_predict_pixel(pixels, w, x, y, mode)
      let a = (vp8l_ch(pixels[i], 24) - vp8l_ch(pred, 24)) & 0xFF
      let r = (vp8l_ch(pixels[i], 16) - vp8l_ch(pred, 16)) & 0xFF
      let g = (vp8l_ch(pixels[i], 8) - vp8l_ch(pred, 8)) & 0xFF
      let b = (vp8l_ch(pixels[i], 0) - vp8l_ch(pred, 0)) & 0xFF
      resid[i] = (a << 24) | (r << 16) | (g << 8) | b
    }
  }
  (resid, modes, bx)
}

// ==================== 变换：palette ====================

///|
priv struct Vp8lPalette {
  colors : Array[Int]
  packed : Array[Int]
  packed_width : Int
}

///|
fn vp8l_try_palette(pixels : Array[Int], w : Int) -> Option[Vp8lPalette] {
  let table : Array[Int] = Array::make(1024, -1)
  let colors : Array[Int] = []
  let indices : Array[Int] = Array::make(pixels.length(), 0)
  for i in 0..<pixels.length() {
    let argb = pixels[i]
    let mut slot = ((argb * 0x9E3779B1) & 0x3FF)
    let mut found = -1
    while table[slot] >= 0 {
      if colors[table[slot]] == argb {
        found = table[slot]
        break
      }
      slot = (slot + 1) & 0x3FF
    }
    if found < 0 {
      if colors.length() == 256 {
        return None
      }
      colors.push(argb)
      found = colors.length() - 1
      table[slot] = found
    }
    indices[i] = found
  }
  let n = colors.length()
  let mut width_bits = if n <= 2 { 3 } else if n <= 4 { 2 } else if n <= 16 { 1 } else { 0 }
  // 宽度不能整除时退回不打包，避免解码侧展开后宽度越界
  if width_bits > 0 && w % (1 << width_bits) != 0 {
    width_bits = 0
  }
  let bundle = 1 << width_bits
  let bits_per = 8 >> width_bits
  let packed_width = (w + bundle - 1) / bundle
  let packed : Array[Int] = Array::make(packed_width * (pixels.length() / w), 0)
  for y in 0..<(pixels.length() / w) {
    for sx in 0..<packed_width {
      let mut v = 0
      for j in 0..<bundle {
        let x = sx * bundle + j
        if x < w {
          let idx = indices[y * w + x]
          v = v | (idx << (j * bits_per))
        }
      }
      packed[y * packed_width + sx] = (255 << 24) | (v << 8)
    }
  }
  Some(Vp8lPalette::{ colors, packed, packed_width })
}

///|
/// 调色板子图：1×N，delta 编码
fn vp8l_palette_delta(colors : Array[Int]) -> Array[Int] {
  let out : Array[Int] = Array::make(colors.length(), 0)
  out[0] = 0
  let mut prev = 0
  for k in 0..<colors.length() {
    let c = colors[k]
    let a = (vp8l_ch(c, 24) - vp8l_ch(prev, 24)) & 0xFF
    let r = (vp8l_ch(c, 16) - vp8l_ch(prev, 16)) & 0xFF
    let g = (vp8l_ch(c, 8) - vp8l_ch(prev, 8)) & 0xFF
    let b = (vp8l_ch(c, 0) - vp8l_ch(prev, 0)) & 0xFF
    out[k] = (a << 24) | (r << 16) | (g << 8) | b
    prev = c
  }
  out
}

// ==================== 对外单入口 ====================

///|
fn vp8l_encode_palette_variant(
  w : Int,
  h : Int,
  pal : Vp8lPalette,
  alpha_solid : Bool,
) -> Bytes {
  let bw = Vp8lBits::new()
  vp8l_write_header(bw, w, h, alpha_solid)
  bw.write(1, 1)
  bw.write(3, 2)
  bw.write(pal.colors.length() - 1, 8)
  vp8l_write_image_stream(bw, vp8l_palette_delta(pal.colors), pal.colors.length(), false)
  bw.write(0, 1)
  vp8l_write_image_stream(bw, pal.packed, pal.packed_width, true)
  bw.finish()
}

///|
/// 无损 WebP 编码单入口：自动在 palette / subtract-green / predictor 之间选体积最小者。
///
/// 体积选择靠"实际编码一遍比长度"，不做估计 —— 编码成本换确定性。
pub fn encode_webp_lossless(img : @types.Image) -> Bytes raise @types.LoadError {
  let (pixels, w, h) = vp8l_pack_argb(img)
  let alpha_solid = vp8l_alpha_solid(pixels)
  // 候选 1：palette（颜色数 ≤256 且平均每色 ≥4 像素时值得试）
  let mut best : Bytes = Bytes::from_array([])
  match vp8l_try_palette(pixels, w) {
    Some(pal) => {
      let n = pal.colors.length()
      if n * 4 <= pixels.length() {
        best = vp8l_encode_palette_variant(w, h, pal, alpha_solid)
      }
    }
    None => ()
  }
  // 候选 2：原样
  let plain = {
    let bw = Vp8lBits::new()
    vp8l_write_header(bw, w, h, alpha_solid)
    bw.write(0, 1)
    vp8l_write_image_stream(bw, pixels, w, true)
    bw.finish()
  }
  if best.length() == 0 || plain.length() < best.length() {
    best = plain
  }
  // 候选 3：subtract-green
  let sg_pixels = vp8l_apply_subtract_green(pixels)
  let sg = {
    let bw = Vp8lBits::new()
    vp8l_write_header(bw, w, h, alpha_solid)
    bw.write(1, 1)
    bw.write(2, 2)
    bw.write(0, 1)
    vp8l_write_image_stream(bw, sg_pixels, w, true)
    bw.finish()
  }
  if sg.length() < best.length() {
    best = sg
  }
  // 候选 4：predictor（+subtract-green）
  let (resid, modes, mode_w) = vp8l_forward_predictor(pixels, w, h, 4)
  let mode_pixels : Array[Int] = Array::make(modes.length(), 0)
  for i in 0..<modes.length() {
    mode_pixels[i] = (255 << 24) | (modes[i] << 8)
  }
  let pred_resid = vp8l_apply_subtract_green(resid)
  let pred = {
    let bw = Vp8lBits::new()
    vp8l_write_header(bw, w, h, alpha_solid)
    bw.write(1, 1)
    bw.write(0, 2)
    bw.write(4 - 2, 3)
    vp8l_write_image_stream(bw, mode_pixels, mode_w, false)
    bw.write(1, 1)
    bw.write(2, 2)
    bw.write(0, 1)
    vp8l_write_image_stream(bw, pred_resid, w, true)
    bw.finish()
  }
  if pred.length() < best.length() {
    best = pred
  }
  vp8l_wrap_riff(best)
}
