///|
/// 回归：WebP 无损编码在「远距离反向引用」（距离 > 4096，超出长度前缀表范围）
/// 下必须逐像素可逆。此前 `vp8l_encode_length` 被误用于距离前缀，距离超过 4096
/// 时 extra 位数会退化成 -1，产出的码流被解码成错误的颜色块。
///
/// 覆盖两条路径：
/// 1. 三色横条：颜色数 ≤ 256，走 palette；
/// 2. 300 色行重复：颜色数 > 256，palette 被拒，走原样 LZ77，且第二半为
///    距离 12288 的反向引用。
///|
fn vp8l_regr_bands(w : Int32, h : Int32, band_h : Int) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let data : Array[Byte] = Array::make(wi * hi * 3, b'\x00')
  for y in 0..<hi {
    for x in 0..<wi {
      let o = (y * wi + x) * 3
      let band = (y / band_h) % 3
      let v = if band == 0 {
        [200, 30, 30]
      } else if band == 1 {
        [30, 200, 30]
      } else {
        [30, 30, 200]
      }
      for c in 0..<3 {
        data[o + c] = v[c].to_byte()
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: 3, data: Bytes::from_array(data) }
}

///|
fn vp8l_regr_many_colors(w : Int32, h : Int32) -> @types.Image {
  let wi = w.to_int()
  let hi = h.to_int()
  let data : Array[Byte] = Array::make(wi * hi * 3, b'\x00')
  for y in 0..<hi {
    // 96 行一个循环：下半部与上半部完全相同，形成距离约 w*96 的反向引用；
    // 行颜色取 300 种，超过调色板上限，强制走原样 LZ77。
    let row = y % 96
    let v = [
      row % 300,
      (row * 7) % 300,
      (row * 13) % 300,
    ]
    for x in 0..<wi {
      let o = (y * wi + x) * 3
      for c in 0..<3 {
        data[o + c] = v[c].to_byte()
      }
    }
  }
  @types.Image::{ width: w, height: h, channels: 3, data: Bytes::from_array(data) }
}

///|
fn vp8l_regr_diff(img : @types.Image, bytes : Bytes) -> Int raise @types.LoadError {
  let back = @codec.decode_webp_pure(bytes)
  if back.width != img.width || back.height != img.height {
    return -1
  }
  let bc = back.channels.to_int()
  let ch = img.channels.to_int()
  let n = img.width.to_int() * img.height.to_int()
  let mut bad = 0
  for i in 0..<n {
    for c in 0..<ch {
      if back.data[i * bc + c] != img.data[i * ch + c] {
        bad = bad + 1
      }
    }
  }
  bad
}

///|
test "webp lossless 回归：三色横条 128x192（远距离 + palette）" {
  let img = vp8l_regr_bands(128, 192, 24)
  let enc = @codec.encode_webp_lossless(img)
  assert_eq(vp8l_regr_diff(img, enc), 0)
  assert_true(enc.length() < 160)
}

///|
test "webp lossless 回归：300 色行重复 128x192（远距离 + 原样 LZ77）" {
  let img = vp8l_regr_many_colors(128, 192)
  let enc = @codec.encode_webp_lossless(img)
  assert_eq(vp8l_regr_diff(img, enc), 0)
}

///|
test "webp lossless 回归：256x192 纵向渐变（predictor 路径）" {
  let wi = 256
  let hi = 192
  let data : Array[Byte] = Array::make(wi * hi * 3, b'\x00')
  for y in 0..<hi {
    let v = y * 255 / hi
    for x in 0..<wi {
      let o = (y * wi + x) * 3
      data[o] = v.to_byte()
      data[o + 1] = ((v * 2) % 256).to_byte()
      data[o + 2] = (255 - v).to_byte()
    }
  }
  let img : @types.Image = {
    width: 256,
    height: 192,
    channels: 3,
    data: Bytes::from_array(data),
  }
  let enc = @codec.encode_webp_lossless(img)
  assert_eq(vp8l_regr_diff(img, enc), 0)
}
