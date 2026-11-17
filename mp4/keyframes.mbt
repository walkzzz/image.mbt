/// ============================================================================
/// 视频 keyframe（关键帧）定位 — stss/stsz/stsc/stco/stts 组装。
/// ============================================================================

///|
/// 单个关键帧信息。
pub(all) struct KeyframeInfo {
  sample_number : Int32
  timestamp_ms : Int64
  size : Int32
  offset : Int64
}

///|
/// 视频轨信息（含关键帧列表）。
pub(all) struct VideoTrackInfo {
  track_count : Int32
  timescale : Int32
  sample_count : Int32
  keyframe_count : Int32
  keyframes : Array[KeyframeInfo]
  duration_ms : Int64
}

///| stss（Sync Sample Box）payload → 关键帧样本编号数组（1-based）。

///| 结构：version/flags(4) + entry_count(4) + sample_number 数组。

///|
/// 无 stss box → 视频全部样本均为关键帧（all-sync）。
fn parse_stss(
  payload_base : Int32,
  payload_end : Int32,
  data : Bytes,
) -> Array[Int32] {
  let entry_count = payload_u32_at(data, payload_base, 4)
  let arr : Array[Int32] = []
  for i in 0..<entry_count {
    if payload_base + 8 + i * 4 + 4 <= payload_end {
      arr.push(payload_u32_at(data, payload_base, 8 + i * 4))
    }
  }
  arr
}

///| stsz（Sample Size Box）payload → (sample_count, 样本大小数组)。

///|
/// 结构：version/flags(4) + sample_size(4) + sample_count(4) + [逐样本大小]。
fn parse_stsz(
  payload_base : Int32,
  payload_end : Int32,
  data : Bytes,
) -> (Int32, Array[Int32]) {
  let sample_size = payload_u32_at(data, payload_base, 4)
  let sample_count = payload_u32_at(data, payload_base, 8)
  let arr : Array[Int32] = []
  if sample_size != 0 {
    for _i in 0..<sample_count {
      arr.push(sample_size)
    }
  } else {
    for i in 0..<sample_count {
      if payload_base + 12 + i * 4 + 4 <= payload_end {
        arr.push(payload_u32_at(data, payload_base, 12 + i * 4))
      }
    }
  }
  (sample_count, arr)
}

///| stsc（Sample-to-Chunk Box）payload → (first_chunk, samples_per_chunk) 数组。

///|
/// 结构：version/flags(4) + entry_count(4) + [first_chunk(4) + samples_per_chunk(4) + sdi(4)]。
fn parse_stsc(
  payload_base : Int32,
  payload_end : Int32,
  data : Bytes,
) -> Array[(Int32, Int32)] {
  let entry_count = payload_u32_at(data, payload_base, 4)
  let arr : Array[(Int32, Int32)] = []
  for i in 0..<entry_count {
    if payload_base + 8 + i * 12 + 12 <= payload_end {
      let first_chunk = payload_u32_at(data, payload_base, 8 + i * 12)
      let samples_per_chunk = payload_u32_at(data, payload_base, 8 + i * 12 + 4)
      arr.push((first_chunk, samples_per_chunk))
    }
  }
  arr
}

///|
/// stco（32 位）/co64（64 位）payload → chunk 文件偏移数组。
fn parse_chunk_offsets(
  stco : Mp4Box?,
  co64 : Mp4Box?,
  data : Bytes,
) -> Array[Int64] raise Mp4Error {
  let arr : Array[Int64] = []
  match stco {
    Some(b) => {
      let entry_count = payload_u32_at(data, b.payload_start, 4)
      for i in 0..<entry_count {
        if b.payload_start + 8 + i * 4 + 4 <= b.start + b.size {
          // stco：32 位 chunk 偏移
          arr.push(
            Int64::from_int(payload_u32_at(data, b.payload_start, 8 + i * 4)),
          )
        }
      }
    }
    None =>
      match co64 {
        Some(b) => {
          let entry_count = payload_u32_at(data, b.payload_start, 4)
          for i in 0..<entry_count {
            if b.payload_start + 8 + i * 8 + 8 <= b.start + b.size {
              arr.push(payload_u64_at(data, b.payload_start, 8 + i * 8))
            }
          }
        }
        None =>
          raise Mp4Error::NoVideoTrack("neither stco nor co64 found in stbl")
      }
  }
  arr
}

///| stts（Time-to-Sample Box）→ 样本时间戳累计（毫秒，按 timescale 换算）。

///|
/// 结构：version/flags(4) + entry_count(4) + [sample_count(4) + duration(4)]。
fn stts_timestamp_ms(
  stts : Mp4Box,
  data : Bytes,
  sample_number : Int32,
  timescale : Int32,
) -> Int64 {
  let entry_count = payload_u32_at(data, stts.payload_start, 4)
  let mut elapsed_units : Int64 = 0
  let mut remaining = sample_number - 1
  let stts_end = stts.start + stts.size
  for i in 0..<entry_count {
    if remaining <= 0 {
      break
    }
    let count_base = stts.payload_start + 8 + i * 8
    if count_base + 8 > stts_end {
      break
    }
    let count = payload_u32_at(data, count_base, 0)
    let duration = payload_u32_at(data, count_base, 4)
    if count >= remaining {
      elapsed_units = elapsed_units +
        Int64::from_int(duration) * Int64::from_int(remaining)
      break
    } else {
      elapsed_units = elapsed_units +
        Int64::from_int(duration) * Int64::from_int(count)
      remaining = remaining - count
    }
  }
  if timescale > 0 {
    elapsed_units * 1000 / Int64::from_int(timescale)
  } else {
    elapsed_units
  }
}

///|
/// stbl 范围内收集五个采样表 box。
priv struct StblState {
  stss : Mp4Box?
  stsz : Mp4Box?
  stsc : Mp4Box?
  stco : Mp4Box?
  co64 : Mp4Box?
  stts : Mp4Box?
}

///|
/// 在 stbl 范围内收集采样表 box（stss/stsz/stsc/stco/co64/stts）。
fn collect_stbl_boxes(data : Bytes, stbl : Mp4Box) -> StblState {
  let stbl_payload_start = stbl.payload_start
  let stbl_end = stbl.start + stbl.size
  let stss = find_box(data, stbl_payload_start, stbl_end, "stss")
  let stsz = find_box(data, stbl_payload_start, stbl_end, "stsz")
  let stsc = find_box(data, stbl_payload_start, stbl_end, "stsc")
  let stco = find_box(data, stbl_payload_start, stbl_end, "stco")
  let co64 = find_box(data, stbl_payload_start, stbl_end, "co64")
  let stts = find_box(data, stbl_payload_start, stbl_end, "stts")
  { stss, stsz, stsc, stco, co64, stts, }
}

///| 精确偏移组装：由 stsz 大小数组 + stsc 映射 + stco 偏移计算样本文件偏移。

///|
/// 样本 n（1-based）：定位其所在 chunk（stsc 累计），chunk 基址 + chunk 内前置样本大小累计。
fn compute_sample_offset(
  sizes : Array[Int32],
  stsc_entries : Array[(Int32, Int32)],
  chunk_offsets : Array[Int64],
  sample_number : Int32,
) -> Int64 {
  let mut samples_before : Int32 = 0
  for i, entry in stsc_entries {
    let (first_chunk, spc) = entry
    let next_first = if i + 1 < stsc_entries.length() {
      stsc_entries[i + 1].0
    } else {
      chunk_offsets.length() + 1
    }
    let chunks_in_entry = next_first - first_chunk
    let samples_in_entry = chunks_in_entry * spc
    if sample_number <= samples_before + samples_in_entry {
      let offset_in_entry = sample_number - samples_before - 1
      let chunk_index = first_chunk + offset_in_entry / spc
      let within_chunk = offset_in_entry % spc
      if chunk_index <= 0 || chunk_index > chunk_offsets.length() {
        return 0
      }
      let mut base = chunk_offsets[chunk_index - 1]
      let chunk_first_sample = samples_before +
        (chunk_index - first_chunk) * spc +
        1
      for s in chunk_first_sample..<sample_number {
        if s >= 1 && s - 1 < sizes.length() {
          base = base + Int64::from_int(sizes[s - 1])
        }
      }
      let _ = within_chunk
      return base
    }
    samples_before = samples_before + samples_in_entry
  }
  0
}

///|
/// 组装关键帧数组：stss 样本编号 × stsz 大小 × compute_sample_offset 偏移 × stts 时间戳。
fn assemble_keyframes(
  data : Bytes,
  keyframe_samples : Array[Int32],
  sizes : Array[Int32],
  stsc_entries : Array[(Int32, Int32)],
  chunk_offsets : Array[Int64],
  stts : Mp4Box,
  timescale : Int32,
) -> Array[KeyframeInfo] {
  let arr : Array[KeyframeInfo] = []
  for n in keyframe_samples {
    let offset = compute_sample_offset(sizes, stsc_entries, chunk_offsets, n)
    let size = if n - 1 < sizes.length() { sizes[n - 1] } else { 0 }
    let ts = stts_timestamp_ms(stts, data, n, timescale)
    arr.push({ sample_number: n, timestamp_ms: ts, size, offset, })
  }
  arr
}

///|
/// 视频 track 时长（最后样本累计，毫秒）。
fn track_duration_ms(
  stts : Mp4Box,
  data : Bytes,
  sample_count : Int32,
  timescale : Int32,
) -> Int64 {
  if sample_count > 0 {
    stts_timestamp_ms(stts, data, sample_count + 1, timescale)
  } else {
    0
  }
}
