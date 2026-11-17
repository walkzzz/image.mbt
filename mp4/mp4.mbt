/// ============================================================================
/// MP4 容器解析公开 API — 纯 MoonBit 零依赖实现（关键帧定位）。
///
/// 能力：ISO BMFF box 遍历 → moov → 视频 trak（hdlr handler_type == 'vide'）
///       → stbl → stss/stsz/stsc/stco/stts → 关键帧元数据（样本号/时间戳/大小/文件偏移）。
/// 限制：单视频轨（多视频轨取第一个 'vide'）；不解码编码流（H.264 等），
///       帧图像提取由外部工具（ffmpeg）完成——见 cmd/video-keyframes。
/// ============================================================================

///|
/// MP4 解析错误。
pub(all) suberror Mp4Error {
  InvalidBox(String)
  Truncated(String)
  NoVideoTrack(String)
}

///|
/// MP4 视频轨关键帧信息集合。
pub(all) struct Mp4Info {
  timescale : Int32
  sample_count : Int32
  keyframe_count : Int32
  duration_ms : Int64
  keyframes : Array[KeyframeInfo]
}

///| 提取视频轨关键帧信息。

///|
/// 管线：moov → traks（hdlr 判定 vide）→ mdia/minf/stbl → 采样表组装。
pub fn extract_video_keyframes(data : Bytes) -> Mp4Info raise Mp4Error {
  let total = data.length()
  let moov = match find_box(data, 0, total, "moov") {
    Some(b) => b
    None => raise Mp4Error::NoVideoTrack("no moov box found")
  }
  let traks = collect_boxes(
    data,
    moov.payload_start,
    moov.start + moov.size,
    "trak",
  )
  if traks.is_empty() {
    raise Mp4Error::NoVideoTrack("no trak box found in moov")
  }
  let (video_stbl, timescale) = find_video_stbl(data, traks)
  let st = collect_stbl_boxes(data, video_stbl)
  let stsz_box = match st.stsz {
    Some(b) => b
    None => raise Mp4Error::InvalidBox("stbl missing stsz box")
  }
  let stsc_box = match st.stsc {
    Some(b) => b
    None => raise Mp4Error::InvalidBox("stbl missing stsc box")
  }
  let stts_box = match st.stts {
    Some(b) => b
    None => raise Mp4Error::InvalidBox("stbl missing stts box")
  }
  let chunk_offsets = parse_chunk_offsets(st.stco, st.co64, data)
  let (sample_count, sizes) = parse_stsz(
    stsz_box.payload_start,
    stsz_box.start + stsz_box.size,
    data,
  )
  let stsc_entries = parse_stsc(
    stsc_box.payload_start,
    stsc_box.start + stsc_box.size,
    data,
  )
  let keyframe_samples = match st.stss {
    Some(b) => parse_stss(b.payload_start, b.start + b.size, data)
    None => {
      // 无 stss：全部样本均为关键帧（all-sync 视频）
      let all : Array[Int32] = []
      for i in 1..<=sample_count {
        all.push(i)
      }
      all
    }
  }
  let keyframes = assemble_keyframes(
    data, keyframe_samples, sizes, stsc_entries, chunk_offsets, stts_box, timescale,
  )
  let duration_ms = track_duration_ms(stts_box, data, sample_count, timescale)
  {
    timescale,
    sample_count,
    keyframe_count: keyframes.length(),
    duration_ms,
    keyframes,
  }
}

///|
/// 在 moov 内找 handler_type == 'vide' 的视频轨（返回其 stbl 与 timescale）。
fn find_video_stbl(
  data : Bytes,
  traks : Array[Mp4Box],
) -> (Mp4Box, Int32) raise Mp4Error {
  for trak in traks {
    let trak_end = trak.start + trak.size
    let mdia = match find_box(data, trak.payload_start, trak_end, "mdia") {
      Some(b) => b
      None => continue
    }
    let mdia_end = mdia.start + mdia.size
    match find_box(data, mdia.payload_start, mdia_end, "hdlr") {
      Some(hdlr) => {
        let handler = fourcc(data, hdlr.payload_start + 8)
        if handler != "vide" {
          continue
        }
      }
      None => continue
    }
    let timescale = match find_box(data, mdia.payload_start, mdia_end, "mdhd") {
      Some(mdhd) => payload_u32_at(data, mdhd.payload_start, 12)
      None => 1000
    }
    let minf = match find_box(data, mdia.payload_start, mdia_end, "minf") {
      Some(b) => b
      None => continue
    }
    let minf_end = minf.start + minf.size
    match find_box(data, minf.payload_start, minf_end, "stbl") {
      Some(b) => return (b, timescale)
      None => continue
    }
  }
  raise Mp4Error::NoVideoTrack("no video track (hdlr handler_type != 'vide')")
}

///|
/// 关键帧元数据 JSON 输出。
pub fn keyframes_to_json(info : Mp4Info) -> String {
  let buf : StringBuilder = StringBuilder()
  buf.write_string(
    "{\"timescale\":\{info.timescale},\"sample_count\":\{info.sample_count},\"duration_ms\":\{info.duration_ms},\"keyframe_count\":\{info.keyframe_count},\"keyframes\":[",
  )
  for i, kf in info.keyframes {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string(
      "{\"sample_number\":\{kf.sample_number},\"timestamp_ms\":\{kf.timestamp_ms},\"size\":\{kf.size},\"offset\":\{kf.offset}}",
    )
  }
  buf.write_string("]}")
  buf.to_string()
}
