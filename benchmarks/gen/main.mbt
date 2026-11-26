///|
/// 基准集生成器（native 可执行，只在仓库维护者本地跑）：
///
/// ```text
/// moon run benchmarks/gen                 # 写 benchmarks/golden + benchmarks/malformed
/// moon run benchmarks/gen -- 目标目录 恶意样本目录
/// ```
///
/// 输出文件名即契约：`gNN_<格式>_<内容>_<W>x<H>.<ext>` / `mN_<类别>.<ext>`，
/// `scripts/check_benchmarks.mjs` 依赖这个命名解析格式与期望尺寸。

///|
fn main {
  let argv = @env.args()
  let golden = if argv.length() > 1 { argv[1] } else { "benchmarks/golden" }
  let malformed = if argv.length() > 2 {
    argv[2]
  } else {
    "benchmarks/malformed"
  }
  let errs : Array[String] = []
  emit_golden(golden, errs)
  emit_malformed(malformed, errs)
  if errs.length() > 0 {
    println("生成失败 \{errs.length()} 项：")
    for e in errs {
      println("  - \{e}")
    }
    @env.exit(1)
  }
  println("benchmarks: 已写入 \{golden} 与 \{malformed}")
}

///|
/// 写一个文件（失败记入 errs，不中断其余样本）。
fn put(dir : String, name : String, data : Bytes, errs : Array[String]) -> Unit {
  if data.length() == 0 {
    errs.push("\{name}: 编码结果为空")
    return
  }
  @imgcli.write_bytes(dir + "/" + name, data) catch {
    _ => errs.push("\{name}: 写盘失败")
  }
  println("  \{name}  \{data.length()} B")
}

///|
/// 20 张 golden 样本：13 种可编码格式，覆盖好压 / 难压 / alpha / 浮点 / 动画。
fn emit_golden(dir : String, errs : Array[String]) -> Unit {
  // 1-5 PNG：单通道、三通道、带 alpha、锐边、噪声
  put(
    dir,
    gname("g01", "png_gray_grad", 512, 512, "png"),
    @lib.encode_png(gray_grad(512, 512)),
    errs,
  )
  put(
    dir,
    gname("g02", "png_rgb_grad", 640, 400, "png"),
    @lib.encode_png(rgb_grad(640, 400)),
    errs,
  )
  put(
    dir,
    gname("g03", "png_rgba_alpha", 512, 512, "png"),
    @lib.encode_png(rgba_alpha(512, 512)),
    errs,
  )
  put(
    dir,
    gname("g04", "png_color_bars", 800, 450, "png"),
    @lib.encode_png(color_bars(800, 450)),
    errs,
  )
  put(
    dir,
    gname("g05", "png_noise", 256, 256, "png"),
    @lib.encode_png(noise_rgb(256, 256)),
    errs,
  )
  // 6 PNM
  put(
    dir,
    gname("g06", "ppm_rgb", 256, 256, "ppm"),
    @lib.encode_ppm_auto(rgb_grad(256, 256)),
    errs,
  )
  // 7-8 JPEG：彩色照片近似 + 灰度
  let jpeg : Bytes = @lib.encode_jpeg(photo_rgb(1280, 720)) catch {
    _ => {
      errs.push("g07 jpeg 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g07", "jpeg_photo", 1280, 720, "jpg"), jpeg, errs)
  let jpeg_gray : Bytes = @lib.encode_jpeg(gray_grad(800, 600)) catch {
    _ => {
      errs.push("g08 jpeg 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g08", "jpeg_gray", 800, 600, "jpg"), jpeg_gray, errs)
  // 9-10 BMP：24-bit 与 32-bit alpha
  put(
    dir,
    gname("g09", "bmp24", 256, 256, "bmp"),
    @lib.encode_bmp(rgb_grad(256, 256)),
    errs,
  )
  put(
    dir,
    gname("g10", "bmp32_alpha", 192, 144, "bmp"),
    @lib.encode_bmp(rgba_alpha(192, 144)),
    errs,
  )
  // 11 TGA
  put(
    dir,
    gname("g11", "tga24", 256, 256, "tga"),
    @lib.encode_tga(rgb_grad(256, 256)),
    errs,
  )
  // 12 静态 GIF
  let gif : Bytes = @lib.encode_gif(color_bars(256, 256)) catch {
    _ => {
      errs.push("g12 gif 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g12", "gif_static", 256, 256, "gif"), gif, errs)
  // 13 GIF 4 帧动画
  let anim : @types.GifAnimation = {
    frames: [
      anim_frame(128, 128, 0),
      anim_frame(128, 128, 1),
      anim_frame(128, 128, 2),
      anim_frame(128, 128, 3),
    ],
    delays: [80, 80, 80, 80],
  }
  let gif_anim : Bytes = @codec.encode_gif_animation_pure(anim) catch {
    _ => {
      errs.push("g13 gif 动画编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g13", "gif_anim4", 128, 128, "gif"), gif_anim, errs)
  // 14 APNG 4 帧
  let apng : Bytes = @lib.encode_apng(
    [
      anim_frame(160, 120, 0),
      anim_frame(160, 120, 1),
      anim_frame(160, 120, 2),
      anim_frame(160, 120, 3),
    ],
    [100, 100, 100, 100],
  ) catch {
    _ => {
      errs.push("g14 apng 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g14", "apng_anim4", 160, 120, "png"), apng, errs)
  // 15 WebP 无损
  let webp : Bytes = @lib.encode_webp_lossless(rgb_grad(1024, 576)) catch {
    _ => {
      errs.push("g15 webp 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g15", "webp_lossless", 1024, 576, "webp"), webp, errs)
  // 16 TIFF
  let tiff : Bytes = @codec.encode_tiff_pure(rgb_grad(256, 192)) catch {
    _ => {
      errs.push("g16 tiff 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g16", "tiff8", 256, 192, "tiff"), tiff, errs)
  // 17 ICO 多尺寸（48 → 32 → 16）
  let logo48 = logo_rgba(48, 48)
  let logo32 : @types.Image = @transform.resize_subsample(logo48, 32, 32) catch {
    _ => logo48
  }
  let logo16 : @types.Image = @transform.resize_subsample(logo48, 16, 16) catch {
    _ => logo48
  }
  put(
    dir,
    gname("g17", "ico_multi", 48, 48, "ico"),
    @codec.encode_ico_with_sizes_pure([logo48, logo32, logo16]),
    errs,
  )
  // 18 ICNS
  put(
    dir,
    gname("g18", "icns256", 256, 256, "icns"),
    @codec.encode_icns_pure(logo_rgba(256, 256)),
    errs,
  )
  // 19 HDR 浮点
  let hdr : Bytes = @lib.encode_hdr(hdr_float(192, 108)) catch {
    _ => {
      errs.push("g19 hdr 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g19", "hdr_float", 192, 108, "hdr"), hdr, errs)
  // 20 QOI
  let qoi : Bytes = @lib.encode_qoi(rgb_grad(160, 120)) catch {
    _ => {
      errs.push("g20 qoi 编码失败")
      Bytes::from_array([])
    }
  }
  put(dir, gname("g20", "qoi", 160, 120, "qoi"), qoi, errs)
}

///|
/// 组装 golden 文件名：`gNN_<内容>_<W>x<H>.<ext>`。
fn gname(
  idx : String,
  what : String,
  w : Int32,
  h : Int32,
  ext : String,
) -> String {
  "\{idx}_\{what}_\{w}x\{h}.\{ext}"
}

///|
/// 6 类恶意样本：全部为手工构造的畸形字节，目标是「被拒绝而不是崩溃」。
fn emit_malformed(dir : String, errs : Array[String]) -> Unit {
  let base_png : Bytes = @lib.encode_png(rgb_grad(64, 64))
  put(dir, "m1_corrupt_idat.png", corrupt_idat(base_png), errs)
  put(dir, "m2_chunk_len_overflow.png", chunk_len_overflow(base_png), errs)
  put(dir, "m3_huge_dims.png", huge_dims(base_png), errs)
  put(dir, "m4_apng_frame_bomb.png", apng_frame_bomb(base_png), errs)
  put(dir, "m5_bmp_bad_enum.bmp", bmp_bad_enum(), errs)
  put(dir, "m6_jpeg_app_bloat.jpg", jpeg_app_bloat(), errs)
}

///|
/// 追加 ASCII 字节串（避免逐字写 byte literal）。
fn push_ascii(out : Array[Byte], s : String) -> Unit {
  for c in s {
    out.push(c.to_int().to_byte())
  }
}

///|
/// 追加 little-endian 32 位无符号整数。
fn push_u32(out : Array[Byte], v : Int32) -> Unit {
  out.push((v % 256).to_byte())
  out.push((v / 256 % 256).to_byte())
  out.push((v / 65536 % 256).to_byte())
  out.push((v / 16777216 % 256).to_byte())
}

///|
/// 把 IDAT 数据流头部改写成 0xFF（deflate 保留块类型）→ inflate 必然报错。
fn corrupt_idat(base : Bytes) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<base.length() {
    out.push(base[i])
  }
  // 定位 "IDAT"（长度字段 4 + 类型 4 之后即数据起点）
  let mut at = -1
  let mut i = 8
  while i + 8 < out.length() && at < 0 {
    if out[i] == b'I' &&
      out[i + 1] == b'D' &&
      out[i + 2] == b'A' &&
      out[i + 3] == b'T' {
      at = i + 4
    }
    i = i + 1
  }
  if at > 0 {
    for k in 0..<8 {
      if at + k < out.length() {
        out[at + k] = b'\xFF'
      }
    }
  }
  Bytes::from_array(out)
}

///|
/// 复制 base 的签名 + IHDR（前 33 字节），再追加一个声明长度极大的 IDAT 头。
fn chunk_len_overflow(base : Bytes) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<33 {
    out.push(base[i])
  }
  out.push(b'\x7F')
  out.push(b'\xFF')
  out.push(b'\xFF')
  out.push(b'\xF0')
  push_ascii(out, "IDAT")
  Bytes::from_array(out)
}

///|
/// IHDR 的宽高改写成 20000×20000（偏移 16/20），其余原样、CRC 不修。
fn huge_dims(base : Bytes) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<33 {
    out.push(base[i])
  }
  let big = (20000 : Int32)
  out[16] = (big % 256).to_byte()
  out[17] = (big / 256 % 256).to_byte()
  out[18] = b'\x00'
  out[19] = b'\x00'
  out[20] = (big % 256).to_byte()
  out[21] = (big / 256 % 256).to_byte()
  out[22] = b'\x00'
  out[23] = b'\x00'
  Bytes::from_array(out)
}

///|
/// acTL 声明 1,000,000 帧、0 次循环，随后直接 IEND（没有任何 fcTL/fdAT）。
fn apng_frame_bomb(base : Bytes) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<33 {
    out.push(base[i])
  }
  push_u32(out, 8)
  push_ascii(out, "acTL")
  push_u32(out, 1000000)
  push_u32(out, 0)
  for _i in 0..<4 {
    out.push(0)
  }
  push_u32(out, 0)
  push_ascii(out, "IEND")
  for _i in 0..<4 {
    out.push(0)
  }
  Bytes::from_array(out)
}

///|
/// 64×64 / 1 平面 / bpp=37 / compression=99 的 BMP（两个字段都是非法枚举值）。
fn bmp_bad_enum() -> Bytes {
  let out : Array[Byte] = [b'\x42', b'\x4D']
  push_u32(out, 14 + 40 + 64 * 64 * 3)
  push_u32(out, 0)
  push_u32(out, 54)
  push_u32(out, 40)
  push_u32(out, 64)
  push_u32(out, 64)
  out.push(1)
  out.push(0)
  out.push(37)
  out.push(0)
  out.push(99)
  out.push(0)
  out.push(0)
  out.push(0)
  for _i in 0..<16 {
    out.push(0)
  }
  Bytes::from_array(out)
}

///|
/// SOI + APP1（声明 65535 字节，实际 20 字节）→ 段被截断。
fn jpeg_app_bloat() -> Bytes {
  let out : Array[Byte] = [b'\xFF', b'\xD8', b'\xFF', b'\xE1', b'\xFF', b'\xFF']
  for i in 0..<20 {
    out.push((65 + i % 26).to_byte())
  }
  Bytes::from_array(out)
}
