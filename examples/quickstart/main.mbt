///|
/// # Quickstart：下游开发者 5 分钟走通的一条路
///
/// 只用子模块（不碰文件系统，native / wasm-gc / js / wasm 都能跑）：
/// 造图 → WebP 无损编码 → 从字节解码 → 缩放 → PNG 编码 → 再解一次校验像素。
///
/// ```bash
/// moon run examples/quickstart --target native
/// ```
///
/// 这条示例同时是 README「快速上手」代码片段的**编译级保证**：示例改坏、README 就不能这么写。

///|
/// 造一张带渐变与色块的 RGB 图（可复现，不依赖随机数）。
fn make_sample(width : Int32, height : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      let r = x * 255 / (width - 1)
      let g = y * 255 / (height - 1)
      let b = if (x / 8 + y / 8) % 2 == 0 { 40 } else { 200 }
      data.push(r.to_byte())
      data.push(g.to_byte())
      data.push(b.to_byte())
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(data), }
}

///|
/// 只对 RGB 求指纹：解码出来的通道数可能是 4（ARGB 统一出口），而源图是 3，
/// 直接按字节比会把"多出来的 alpha=255"当成像素不一致。
fn pixel_digest(img : @types.Image) -> Int64 {
  let mut h = 0L
  let n = img.width * img.height
  for i in 0..<n {
    let base = i * img.channels
    let r = img.data[base].to_int()
    let g = img.data[base + 1].to_int()
    let b = if img.channels >= 3 { img.data[base + 2].to_int() } else { r }
    h = (h * 16777213L + (r * 65536 + g * 256 + b).to_int64()) % 4294967296L
  }
  h
}

///|
fn main {
  let src = make_sample(64, 48)
  println("sample  \{src.width}x\{src.height} ch=\{src.channels}")

  // 1) 编码：WebP 无损（体积小、能逐像素还原）
  let webp = @lib.encode_webp_lossless(src) catch {
    e => {
      println("encode_webp_lossless 失败: \{e}")
      return
    }
  }
  println("webp    \{webp.length()} B")

  // 2) 解码：按魔数自动识别格式，不用自己判断 PNG/JPEG/WebP
  let back = @lib.load_from_bytes_auto(webp) catch {
    e => {
      println("load_from_bytes_auto 失败: \{e}")
      return
    }
  }
  println(
    "decode  \{back.width}x\{back.height} ch=\{back.channels} digest=\{pixel_digest(back)}",
  )
  if pixel_digest(back) != pixel_digest(src) {
    println("!! WebP 往返像素不一致")
    return
  }
  println("        WebP 无损往返像素一致（只比 RGB）")

  // 3) 缩放：cover = 等比铺满后居中裁切
  let small = @transform.resize_to_cover(back, 32, 24) catch {
    e => {
      println("resize_to_cover 失败: \{e}")
      return
    }
  }
  println("resize  \{small.width}x\{small.height}")

  // 4) 出 PNG（给"必须人人能开"的交换场景）
  let png = @lib.encode_png(small)
  println("png     \{png.length()} B")

  // 5) 再解一次，确认出口产物可读
  let again = @lib.load_from_bytes_auto(png) catch {
    e => {
      println("PNG 回读失败: \{e}")
      return
    }
  }
  println(
    "verify  \{again.width}x\{again.height} ch=\{again.channels} ok=\{pixel_digest(again) == pixel_digest(small)}",
  )
}
