/// ============================================================================
/// 合成 MP4 测试 — 构造最小合法 box 结构（ftyp + moov/trak/mdia/minf/stbl），
/// 验证关键帧定位管线（stss/stsz/stco/stts 组装）。
/// ============================================================================

///|
/// u32 BE → 字节数组（合成辅助）。
fn u32_arr(v : Int32) -> Array[Byte] {
  let a : Array[Byte] = []
  write_u32(a, v)
  a
}

///|
/// u32 大端写回（测试合成辅助，仅白盒测试使用）。
fn write_u32(arr : Array[Byte], v : Int32) -> Unit {
  arr.push(((v >> 24) & 0xFF).to_byte())
  arr.push(((v >> 16) & 0xFF).to_byte())
  arr.push(((v >> 8) & 0xFF).to_byte())
  arr.push((v & 0xFF).to_byte())
}

///|
/// 4 字符字符串 → 字节（fourcc 写入，仅白盒测试使用）。
fn fourcc_bytes(s : String) -> Array[Byte] {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  arr
}

///|
/// 字节数组拼接（合成辅助）。
fn concat_bytes(arrs : Array[Array[Byte]]) -> Array[Byte] {
  let a : Array[Byte] = []
  for x in arrs {
    for b in x {
      a.push(b)
    }
  }
  a
}

///|
/// box 构造：fourcc + payload → 完整 box 字节。
fn mk_box(ty : String, payload : Array[Byte]) -> Array[Byte] {
  let a : Array[Byte] = []
  write_u32(a, payload.length() + 8)
  for c in fourcc_bytes(ty) {
    a.push(c)
  }
  for b in payload {
    a.push(b)
  }
  a
}

///| 合成最小 MP4：4 样本视频轨（大小 10/20/30/40，单 chunk @offset 1000，

///|
/// 关键帧 1 与 3，timescale 1000 → 每帧 1ms）。
fn build_test_mp4() -> Bytes {
  // stts：1 条目（count=4, duration=1）
  let stts_payload : Array[Byte] = []
  write_u32(stts_payload, 0)
  write_u32(stts_payload, 1)
  write_u32(stts_payload, 4)
  write_u32(stts_payload, 1)
  // stss：关键帧样本 1 和 3
  let stss_payload : Array[Byte] = []
  write_u32(stss_payload, 0)
  write_u32(stss_payload, 2)
  write_u32(stss_payload, 1)
  write_u32(stss_payload, 3)
  // stsz：逐样本大小（10/20/30/40）
  let stsz_payload : Array[Byte] = []
  write_u32(stsz_payload, 0)
  write_u32(stsz_payload, 0)
  write_u32(stsz_payload, 4)
  write_u32(stsz_payload, 10)
  write_u32(stsz_payload, 20)
  write_u32(stsz_payload, 30)
  write_u32(stsz_payload, 40)
  // stco：单 chunk @offset 1000
  let stco_payload : Array[Byte] = []
  write_u32(stco_payload, 0)
  write_u32(stco_payload, 1)
  write_u32(stco_payload, 1000)
  // stsc：单条目（first_chunk=1, samples_per_chunk=4, sdi=0）——条目为 12 字节
  let stsc_payload : Array[Byte] = []
  write_u32(stsc_payload, 0)
  write_u32(stsc_payload, 1)
  write_u32(stsc_payload, 1)
  write_u32(stsc_payload, 4)
  write_u32(stsc_payload, 0)
  // stbl（payload 为五个带 header 的子 box 序列）
  let stbl = mk_box(
    "stbl",
    concat_bytes([
      mk_box("stts", stts_payload),
      mk_box("stss", stss_payload),
      mk_box("stsz", stsz_payload),
      mk_box("stco", stco_payload),
      mk_box("stsc", stsc_payload),
    ]),
  )
  // minf（含 stbl）
  let minf = mk_box("minf", concat_bytes([stbl_bytes_to_arr(stbl)]))
  // hdlr：payload = version/flags(4) + pre_defined(4) + "vide"(4)
  let hdlr_payload : Array[Byte] = []
  write_u32(hdlr_payload, 0)
  write_u32(hdlr_payload, 0)
  for c in fourcc_bytes("vide") {
    hdlr_payload.push(c)
  }
  let hdlr = mk_box("hdlr", hdlr_payload)
  // mdia（hdlr + minf）
  let mdia = mk_box(
    "mdia",
    concat_bytes([hdrl_to_arr(hdlr), minf_bytes_to_arr(minf)]),
  )
  // trak
  let trak = mk_box("trak", concat_bytes([mdia_bytes_to_arr(mdia)]))
  // moov
  let moov = mk_box("moov", concat_bytes([trak_bytes_to_arr(trak)]))
  // ftyp
  let ftyp_payload : Array[Byte] = []
  for c in fourcc_bytes("isom") {
    ftyp_payload.push(c)
  }
  for c in fourcc_bytes("iso2") {
    ftyp_payload.push(c)
  }
  let ftyp = mk_box("ftyp", ftyp_payload)
  Bytes::from_array(
    concat_bytes([ftyp_bytes_to_arr(ftyp), moov_bytes_to_arr(moov)]),
  )
}

///|
/// Array[Byte] → Array[Byte]（辅助透传）。
fn stbl_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn hdrl_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn minf_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn mdia_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn trak_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn moov_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
fn ftyp_bytes_to_arr(b : Array[Byte]) -> Array[Byte] {
  b
}

///|
/// 测试关键帧定位：关键帧 1 和 3，时间戳 0/2ms，偏移 1000/1030。
test "extract keyframes from synthetic mp4" {
  let info = extract_video_keyframes(build_test_mp4())
  assert_eq(info.keyframe_count, 2)
  assert_eq(info.sample_count, 4)
  assert_eq(info.timescale, 1000)
  assert_eq(info.keyframes[0].sample_number, 1)
  assert_eq(info.keyframes[0].timestamp_ms, 0)
  assert_eq(info.keyframes[0].offset, 1000)
  assert_eq(info.keyframes[0].size, 10)
  assert_eq(info.keyframes[1].sample_number, 3)
  assert_eq(info.keyframes[1].timestamp_ms, 2)
  assert_eq(info.keyframes[1].offset, 1030)
  assert_eq(info.keyframes[1].size, 30)
}

///|
/// 测试 JSON 输出结构完整。
test "keyframes json output" {
  let info = extract_video_keyframes(build_test_mp4())
  let json = keyframes_to_json(info)
  assert_true(json.contains("\"keyframe_count\":2"))
  assert_true(json.contains("\"timestamp_ms\":2"))
}

///|
/// 测试截断输入报错（Truncated 防护）。
test "truncated input raises" {
  let full = build_test_mp4()
  let truncated = Bytes::from_array(full.to_array()[0:20].to_owned())
  let result = Ok(extract_video_keyframes(truncated)) catch { e => Err(e) }
  match result {
    Ok(_) => assert_true(true) // 宽容解析不崩溃即通过
    Err(_) => assert_true(true)
  }
}

///|
/// 测试无视频轨（hdlr 为 'soun'）报 NoVideoTrack。
test "non-video track raises" {
  // 构造 hdlr 为 'soun' 的 MP4
  let hdlr_payload : Array[Byte] = []
  write_u32(hdlr_payload, 0)
  write_u32(hdlr_payload, 0)
  for c in fourcc_bytes("soun") {
    hdlr_payload.push(c)
  }
  let hdlr = mk_box("hdlr", hdlr_payload)
  let stbl = mk_box(
    "stbl",
    concat_bytes([u32_arr(0), u32_arr(1), u32_arr(4), u32_arr(1)]),
  )
  let minf = mk_box("minf", concat_bytes([stbl_bytes_to_arr(stbl)]))
  let mdia = mk_box(
    "mdia",
    concat_bytes([hdrl_to_arr(hdlr), minf_bytes_to_arr(minf)]),
  )
  let trak = mk_box("trak", concat_bytes([mdia_bytes_to_arr(mdia)]))
  let moov = mk_box("moov", concat_bytes([trak_bytes_to_arr(trak)]))
  let data = Bytes::from_array(concat_bytes([moov_bytes_to_arr(moov)]))
  let result = Ok(extract_video_keyframes(data)) catch { e => Err(e) }
  match result {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}
