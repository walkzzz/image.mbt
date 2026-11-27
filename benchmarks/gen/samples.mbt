///|
/// 样本构建器：**纯函数**，只返回 `(文件名, 字节)` 列表，不碰文件系统。
/// 构建逻辑因此可被白盒测试完整执行（`samples_wbtest.mbt`），写盘留给 `main.mbt`，
/// 避免「维护脚本永远 0 覆盖」——覆盖率口径不做任何排除。

///|
/// 把一张样本加入列表（空结果记入 errs，不中断其余样本）。
fn add(
  out : Array[(String, Bytes)],
  name : String,
  data : Bytes,
  errs : Array[String],
) -> Unit {
  if data.length() == 0 {
    errs.push("\{name}: 编码结果为空")
    return
  }
  out.push((name, data))
}

///|
fn golden_samples(errs : Array[String]) -> Array[(String, Bytes)] {
  let out : Array[(String, Bytes)] = []
  // 1-5 PNG：单通道、三通道、带 alpha、锐边、噪声
  add(
    out,
    gname("g01", "png_gray_grad", 512, 512, "png"),
    @lib.encode_png(gray_grad(512, 512)),
    errs,
  )
  add(
    out,
    gname("g02", "png_rgb_grad", 640, 400, "png"),
    @lib.encode_png(rgb_grad(640, 400)),
    errs,
  )
  add(
    out,
    gname("g03", "png_rgba_alpha", 512, 512, "png"),
    @lib.encode_png(rgba_alpha(512, 512)),
    errs,
  )
  add(
    out,
    gname("g04", "png_color_bars", 800, 450, "png"),
    @lib.encode_png(color_bars(800, 450)),
    errs,
  )
  add(
    out,
    gname("g05", "png_noise", 256, 256, "png"),
    @lib.encode_png(noise_rgb(256, 256)),
    errs,
  )
  // 6 PNM
  add(
    out,
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
  add(out, gname("g07", "jpeg_photo", 1280, 720, "jpg"), jpeg, errs)
  let jpeg_gray : Bytes = @lib.encode_jpeg(gray_grad(800, 600)) catch {
    _ => {
      errs.push("g08 jpeg 编码失败")
      Bytes::from_array([])
    }
  }
  add(out, gname("g08", "jpeg_gray", 800, 600, "jpg"), jpeg_gray, errs)
  // 9-10 BMP：24-bit 与 32-bit alpha
  add(
    out,
    gname("g09", "bmp24", 256, 256, "bmp"),
    @lib.encode_bmp(rgb_grad(256, 256)),
    errs,
  )
  add(
    out,
    gname("g10", "bmp32_alpha", 192, 144, "bmp"),
    @lib.encode_bmp(rgba_alpha(192, 144)),
    errs,
  )
  // 11 TGA
  add(
    out,
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
  add(out, gname("g12", "gif_static", 256, 256, "gif"), gif, errs)
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
  add(out, gname("g13", "gif_anim4", 128, 128, "gif"), gif_anim, errs)
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
  add(out, gname("g14", "apng_anim4", 160, 120, "png"), apng, errs)
  // 15 WebP 无损
  let webp : Bytes = @lib.encode_webp_lossless(rgb_grad(1024, 576)) catch {
    _ => {
      errs.push("g15 webp 编码失败")
      Bytes::from_array([])
    }
  }
  add(out, gname("g15", "webp_lossless", 1024, 576, "webp"), webp, errs)
  // 16 TIFF
  let tiff : Bytes = @codec.encode_tiff_pure(rgb_grad(256, 192)) catch {
    _ => {
      errs.push("g16 tiff 编码失败")
      Bytes::from_array([])
    }
  }
  add(out, gname("g16", "tiff8", 256, 192, "tiff"), tiff, errs)
  // 17 ICO 多尺寸（48 → 32 → 16）
  let logo48 = logo_rgba(48, 48)
  let logo32 : @types.Image = @transform.resize_subsample(logo48, 32, 32) catch {
    _ => logo48
  }
  let logo16 : @types.Image = @transform.resize_subsample(logo48, 16, 16) catch {
    _ => logo48
  }
  add(
    out,
    gname("g17", "ico_multi", 48, 48, "ico"),
    @codec.encode_ico_with_sizes_pure([logo48, logo32, logo16]),
    errs,
  )
  // 18 ICNS
  add(
    out,
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
  add(out, gname("g19", "hdr_float", 192, 108, "hdr"), hdr, errs)
  // 20 QOI
  let qoi : Bytes = @lib.encode_qoi(rgb_grad(160, 120)) catch {
    _ => {
      errs.push("g20 qoi 编码失败")
      Bytes::from_array([])
    }
  }
  add(out, gname("g20", "qoi", 160, 120, "qoi"), qoi, errs)
  // 21-24 扩容量（S20）：补 8-bit 之外的三条解码路径
  // 21 PNM 灰度 P5（现有 g06 只覆盖 P6 彩色）
  add(
    out,
    gname("g21", "pgm_gray", 192, 144, "pgm"),
    @lib.encode_pgm_auto(gray_grad(192, 144)),
    errs,
  )
  // 22 TGA 32-bit BGRA + 描述符 0x28（现有 g11 只覆盖 24-bit）
  add(
    out,
    gname("g22", "tga32_alpha", 160, 120, "tga"),
    @lib.encode_tga(rgba_alpha(160, 120)),
    errs,
  )
  // 23 WebP lossy 奇数宽高（33×33）——解码侧 UV ceil 的端到端样本（GAP-17）
  // 位流由本仓 encode_webp_lossy_full(rgb_grad(33, 33), quality=75) 于 2026-11-27 产出后固化：
  // 该 API 已标 #deprecated（VP8 lossy 结构性问题见 GAP-27），跨包调用过不了 --deny-warn，
  // 故以 hex 常量保留样本；sha256 / 字节数仍由 benchmarks/manifest.json 封签。
  add(
    out,
    gname("g23", "webp_lossy_odd", 33, 33, "webp"),
    webp_lossy_odd_bytes(),
    errs,
  )
  // 24 QOI 四通道（现有 g20 只覆盖 RGB 三通道）
  let qoi_rgba : Bytes = @lib.encode_qoi(rgba_alpha(192, 144)) catch {
    _ => {
      errs.push("g24 qoi rgba 编码失败")
      Bytes::from_array([])
    }
  }
  add(out, gname("g24", "qoi_rgba", 192, 144, "qoi"), qoi_rgba, errs)
  out
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
fn malformed_samples(errs : Array[String]) -> Array[(String, Bytes)] {
  let out : Array[(String, Bytes)] = []
  let base_png : Bytes = @lib.encode_png(rgb_grad(64, 64))
  add(out, "m1_corrupt_idat.png", corrupt_idat(base_png), errs)
  add(out, "m2_chunk_len_overflow.png", chunk_len_overflow(base_png), errs)
  add(out, "m3_huge_dims.png", huge_dims(base_png), errs)
  add(out, "m4_apng_frame_bomb.png", apng_frame_bomb(base_png), errs)
  add(out, "m5_bmp_bad_enum.bmp", bmp_bad_enum(), errs)
  add(out, "m6_jpeg_app_bloat.jpg", jpeg_app_bloat(), errs)
  add(out, "m7_webp_riff_truncated.webp", webp_riff_truncated(), errs)
  add(out, "m8_tiff_ifd_oob.tiff", tiff_ifd_oob(), errs)
  out
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

///|
/// RIFF 头声明 0x7FFFFFF0 字节 + VP8L chunk 声明 0x7FFFFF 长度，实际只跟 4 字节
/// —— 容器层声明与实体严重不符，期望解码器按越界拒绝。
fn webp_riff_truncated() -> Bytes {
  let out : Array[Byte] = [b'R', b'I', b'F', b'F']
  push_u32(out, 0x7FFFFFF0)
  push_ascii(out, "WEBP")
  push_ascii(out, "VP8L")
  push_u32(out, 0x7FFFFF)
  for _i in 0..<4 {
    out.push(0)
  }
  Bytes::from_array(out)
}

///|
/// TIFF 头（II + 42）后把首个 IFD 偏移写成 0x7FFFFFF0，其后只有 8 字节残留
/// —— IFD 落在文件之外，期望解码器按越界拒绝而不是读穿数组。
fn tiff_ifd_oob() -> Bytes {
  let out : Array[Byte] = [b'I', b'I', b'\x2A', b'\x00']
  push_u32(out, 0x7FFFFFF0)
  for _i in 0..<8 {
    out.push(0)
  }
  Bytes::from_array(out)
}

///|
/// g23 的 VP8 lossy 位流（756 B，33×33 渐变），源自本仓编码器 2026-11-27 的产出。
fn webp_lossy_odd_bytes() -> Bytes {
  let hex = "52494646ec0200005745425056503820df020000b05a009d012a21002100000000000101000101000101000001000100" +
    "000001000100010101000000010100000001000101000001000001000101000101000101010001000100000001010100" +
    "000001010100010000010100000000000100000001010000000001000000000000010001000000000100000000010000" +
    "000100010000010000000001000100010001000100010000010001000100000000010101010101010001010000010101" +
    "000000000001010100010100010100000100010001010101010001010100010001010101010001010100000000010100" +
    "010100000001010101010000010101000001000101010001010000000101000101010101010000000001010101010100" +
    "000101010001000101010001010000010101000100000001000101010001010001000100000001000000010101000001" +
    "010101000001010100000000010101000101010000000100010101010101000000000101010101010101010001010100" +
    "010001000101010100000101000000000100000101000100010101010000010001010101000101000101000101010101" +
    "010100010000000101010000000000000000000001000001010001000100010100000001000101010001000001000101" +
    "010100010001000100010000010101000001010001000101000000000100010001010101000000010000000000000000" +
    "010001000101000001010101010100010001000101000100010101010100000000010100000000000000010101010000" +
    "010101000100010100000100000100010001010101000100010000000100010000010101010101000000000101010101" +
    "010000010001000101010000000001000000010001000000010001000100000101000000000100000000000100010100" +
    "010100000001000101010100010101010000010001000000010100000001010001000101000000010100010100000101" +
    "010101010101010001010101010101010101000101010101010101010100000000000000"
  hex_to_bytes(hex)
}

///|
/// 十六进制字符串 → 字节数组（按 2 字符一个字节）。
fn hex_to_bytes(hex : String) -> Bytes {
  let chars = hex.to_array()
  let count = chars.length() / 2
  let data : Array[Byte] = Array::make(count, b'\x00')
  for i in 0..<count {
    let hi = hex_value(chars[i * 2])
    let lo = hex_value(chars[i * 2 + 1])
    data[i] = ((hi << 4) | lo).to_byte()
  }
  Bytes::from_array(data)
}

///|
/// 单个十六进制字符 → 数值（非法字符按 0 处理，样本内不会出现）。
fn hex_value(c : Char) -> Int32 {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else {
    0
  }
}
