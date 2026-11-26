///|
/// GAP-35 回归：容器声明长度取 `0x7FFFFFF0`（Int32 回绕区）时，
/// 各解码器必须返回 `LoadError`（或被安全 `break`），**不得 panic / 不得越界**。
///
/// 这一族缺陷的共同形态是 `offset + size > len`：当 `size` 接近 `Int32::max` 时
/// 右值回绕成负数，边界检查被绕过。修复统一改为减法形式 `size > len - offset`。

///|
/// 二进制小工具：把 u32 以首字节在前的顺序追加（这里用大端，与 ISO BMFF / ICNS / PSD 一致）。
fn bow_u32_be(out : Array[Byte], v : Int32) -> Unit {
  out.push((v / 16777216 % 256).to_byte())
  out.push((v / 65536 % 256).to_byte())
  out.push((v / 256 % 256).to_byte())
  out.push((v % 256).to_byte())
}

///|
/// 追加 ASCII 串的字节形态。
fn bow_ascii(out : Array[Byte], s : String) -> Unit {
  for c in s {
    out.push(c.to_int().to_byte())
  }
}

///|
test "bounds: 五种容器声明长度 0x7FFFFFF0 均不 panic" {
  // ICNS：magic + 总长 + 一个 'ic09' chunk（声明长度 0x7FFFFFF0）
  let icns : Array[Byte] = []
  bow_ascii(icns, "icns")
  bow_u32_be(icns, 16)
  bow_ascii(icns, "ic09")
  bow_u32_be(icns, 0x7FFFFFF0)
  try {
    ignore(decode_icns_pure(Bytes::from_array(icns)))
    assert_true(false)
  } catch {
    _ => ()
  }
  // PSD：合法头 + 颜色模式数据段声明 0x7FFFFFF0
  let psd : Array[Byte] = []
  bow_ascii(psd, "8BPS")
  psd.push(0)
  psd.push(1)
  for _i in 0..<6 {
    psd.push(0)
  }
  psd.push(0)
  psd.push(3)
  bow_u32_be(psd, 16)
  bow_u32_be(psd, 16)
  psd.push(0)
  psd.push(8)
  psd.push(0)
  psd.push(3)
  bow_u32_be(psd, 0x7FFFFFF0)
  try {
    ignore(decode_psd_pure(Bytes::from_array(psd)))
    assert_true(false)
  } catch {
    _ => ()
  }
  // AVIF：ftyp box 声明 0x7FFFFFF0
  let avif : Array[Byte] = []
  bow_u32_be(avif, 0x7FFFFFF0)
  bow_ascii(avif, "ftypavifavif")
  try {
    ignore(avif_decode(Bytes::from_array(avif)))
    assert_true(false)
  } catch {
    _ => ()
  }
  // HEIF：同形
  let heif : Array[Byte] = []
  bow_u32_be(heif, 0x7FFFFFF0)
  bow_ascii(heif, "ftypheicheic")
  try {
    ignore(heif_decode(Bytes::from_array(heif)))
    assert_true(false)
  } catch {
    _ => ()
  }
  // JPEG-XL：容器 box 声明 0x7FFFFFF0
  let jxl : Array[Byte] = []
  bow_u32_be(jxl, 0x7FFFFFF0)
  bow_ascii(jxl, "JXL xxxx")
  try {
    ignore(jpegxl_decode(Bytes::from_array(jxl)))
    assert_true(false)
  } catch {
    _ => ()
  }
}
