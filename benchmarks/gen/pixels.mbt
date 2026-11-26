///|
/// 基准集的像素合成器：所有样本都由本仓代码在运行时生成，
/// 不含任何第三方素材（照片 / 字体 / 图标），因此可自由分发。
///
/// 设计约束：
/// 1. 全部为确定性函数（无随机源、无时钟），同版本 o`moon run` 生成的字节完全一致；
/// 2. 尺寸刻意压小（总体积 < 1 MB），让样本能进仓库而不依赖 Git LFS；
/// 3. 覆盖「好压 / 难压 / 有 alpha / 高动态范围 / 多通道」五种像素分布。

///|
/// 由已铺好的字节数组构造 `Image`。
fn mkimg(w : Int32, h : Int32, ch : Int32, px : Array[Byte]) -> @types.Image {
  { width: w, height: h, channels: ch, data: Bytes::from_array(px), }
}

///|
/// 饱和到 0..255 的字节化。
fn clamp8(v : Int32) -> Byte {
  if v < 0 {
    b'\x00'
  } else if v > 255 {
    b'\xFF'
  } else {
    v.to_byte()
  }
}

///|
/// 8-bit 单通道横向渐变（好压缩的正则数据）。
fn gray_grad(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  for y in 0..<h {
    for x in 0..<w {
      ignore(y)
      px.push(clamp8(x.to_int() * 255 / wi))
    }
  }
  mkimg(w, h, 1, px)
}

///|
/// 8-bit RGB 双轴渐变 + 对角分量。
fn rgb_grad(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  for y in 0..<h {
    for x in 0..<w {
      px.push(clamp8(x.to_int() * 255 / wi))
      px.push(clamp8(y.to_int() * 255 / hi))
      px.push(clamp8((x.to_int() + y.to_int()) * 255 / (wi + hi)))
    }
  }
  mkimg(w, h, 3, px)
}

///|
/// 8-bit RGBA：颜色走对角渐变，alpha 走横向斜坡（用于 alpha 通道 / 预乘路径）。
fn rgba_alpha(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  for y in 0..<h {
    for x in 0..<w {
      px.push(clamp8(x.to_int() * 255 / wi))
      px.push(clamp8(y.to_int() * 255 / hi))
      px.push(clamp8((x.to_int() + y.to_int()) * 255 / (wi + hi)))
      px.push(clamp8(x.to_int() * 255 / wi))
    }
  }
  mkimg(w, h, 4, px)
}

///|
/// 8 色竖条 + 横向亮度阶梯：锐边 + 平坦面，用来测调色板量化与边缘滤波。
fn color_bars(w : Int32, h : Int32) -> @types.Image {
  let bars : Array[(Int32, Int32, Int32)] = [
    (255, 255, 255),
    (255, 255, 0),
    (0, 255, 255),
    (0, 255, 0),
    (255, 0, 255),
    (255, 0, 0),
    (0, 0, 255),
    (0, 0, 0),
  ]
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  for y in 0..<h {
    let step = y.to_int() * 8 / hi
    for x in 0..<w {
      let (r, g, b) = bars[x.to_int() * bars.length() / wi]
      let dim = 7 - step
      px.push(clamp8(r * (dim + 1) / 8))
      px.push(clamp8(g * (dim + 1) / 8))
      px.push(clamp8(b * (dim + 1) / 8))
    }
  }
  mkimg(w, h, 3, px)
}

///|
/// 确定性伪噪声（无 PRNG）：几乎不可压缩，用来压 PNG/WebP 的最坏情况。
fn noise_rgb(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let mut seed = 7
  for y in 0..<h {
    for x in 0..<w {
      seed = (seed * 1103 + 12345 + x.to_int() * 31 + y.to_int() * 17) % 251
      px.push(clamp8(seed * 251 / 251))
      seed = (seed * 1103 + 12345) % 251
      px.push(clamp8(seed * 251 / 251))
      seed = (seed * 1103 + 12345) % 251
      px.push(clamp8(255 - seed * 251 / 251))
    }
  }
  mkimg(w, h, 3, px)
}

///|
/// 照片近似：径向柔和亮场 + 8×8 区块纹理，模拟 JPEG 的自然图像分布。
fn photo_rgb(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  let cx = wi / 2
  let cy = hi / 2
  for y in 0..<h {
    for x in 0..<w {
      let dx = x.to_int() - cx
      let dy = y.to_int() - cy
      let d2 = dx * dx + dy * dy
      let r = 210 - d2 * 220 / (wi * wi / 4 + 1)
      let g = 190 - d2 * 180 / (wi * wi / 4 + 1) + x.to_int() % 16 * 2
      let b = 150 + d2 * 200 / (wi * wi / 4 + 1)
      px.push(clamp8(r))
      px.push(clamp8(g))
      px.push(clamp8(b))
    }
  }
  mkimg(w, h, 3, px)
}

///|
/// 图标素材：圆形 alpha 切边 + 内部冷暖渐变（ICO / ICNS 用）。
fn logo_rgba(w : Int32, h : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  let r = wi / 2
  let cx = r
  let cy = hi / 2
  for y in 0..<h {
    for x in 0..<w {
      let dx = x.to_int() - cx
      let dy = y.to_int() - cy
      let d2 = dx * dx + dy * dy
      if d2 > r * r {
        px.push(0)
        px.push(0)
        px.push(0)
        px.push(0)
      } else {
        let t = d2 * 255 / (r * r + 1)
        px.push(clamp8(40 + t))
        px.push(clamp8(120 + t / 2))
        px.push(clamp8(230 - t))
        px.push(255)
      }
    }
  }
  mkimg(w, h, 4, px)
}

///|
/// 单精度浮点三通道（HDR）：0..1 的柔和渐变，带一个超白高光斑。
fn hdr_float(w : Int32, h : Int32) -> @types.ImageF {
  let px : Array[Byte] = []
  let wi = w.to_int()
  let hi = h.to_int()
  let cx = wi / 3
  let cy = hi / 2
  for y in 0..<h {
    for x in 0..<w {
      let dx = x.to_int() - cx
      let dy = y.to_int() - cy
      let d2 = dx * dx + dy * dy
      let spot : Float = 4.0F / (1.0F + Float::from_int(d2 / 64))
      push_f32(px, Float::from_int(x.to_int() * 3) / Float::from_int(wi))
      push_f32(px, Float::from_int(y.to_int() * 2) / Float::from_int(hi) + spot)
      push_f32(px, 0.5F + spot / 2.0F)
    }
  }
  { width: w, height: h, channels: 3, data: Bytes::from_array(px), }
}

///|
/// 把 Float 以 IEEE 754 小端序追加到字节数组（`ImageF.data` 的约定）。
fn push_f32(px : Array[Byte], v : Float) -> Unit {
  let bs = v.to_le_bytes()
  for i in 0..<4 {
    px.push(bs[i])
  }
}

///|
/// 动画帧：竖条按相位平移，制造帧间差异（GIF / APNG 用）。
fn anim_frame(w : Int32, h : Int32, phase : Int32) -> @types.Image {
  let px : Array[Byte] = []
  let wi = w.to_int()
  for y in 0..<h {
    for x in 0..<w {
      let band = (x.to_int() + phase.to_int() * wi / 4) % wi * 4 / wi
      px.push(clamp8(band * 60 + 15))
      px.push(clamp8(y.to_int() * 255 / h.to_int()))
      px.push(clamp8(255 - band * 60))
    }
  }
  mkimg(w, h, 3, px)
}
