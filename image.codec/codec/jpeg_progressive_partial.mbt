///|
/// # 渐进 JPEG 的半扫描增量推进（0.1.37）
///
/// `JpegProgStream`（0.1.36）的步长是「整条扫描」：一条扫描的熵数据没到齐，
/// 就只能等。本模块把步长压到 **MCU**：字节只到一半时也能解出当前扫描里
/// 已经完整的 MCU，只是后续 MCU 需要更多输入。
///
/// 做法：单位（interleaved 为 MCU、单分量扫描为块）逐个解码；每个单位开始前
/// 快照 reader 三字段、DC 预测值、EOBRUN 与该单位覆盖的系数块旧值。
/// 单位中途读到字节末尾（`JpegBitReader.suspended`）就整体回滚到该单位起点，
/// 返回 `stuck=true`——保证「已确认完成的单位」永远只增不减，重启后可续。
///
/// 语义边界：跨扫描边界时 reader 按 SOS 的 `entropy_start` 重定位，不需要回滚；
/// `max_units` 是本次调用的推进上限，与 `stuck` 无关。

///|
/// 半扫描推进器的状态
pub struct JpegProgPartial {
  header : JpegHeader
  data : Bytes
  ctx : JpegProgCtx
  mut visible : Int32
  mut scan_idx : Int32
  mut unit_idx : Int32
  mut started : Bool
  mut r_pos : Int32
  mut r_bit_buf : Int32
  mut r_bit_cnt : Int32
  mut pred : Array[Int32]
  mut eobrun : Int32
}

///|
/// 一次推进的结果
pub(all) struct JpegProgAdvance {
  scan_index : Int32
  unit_done : Int32
  unit_total : Int32
  scan_complete : Bool
  stuck : Bool
  finished : Bool
}

///|
/// 打开推进器：解析头部并校验，字节缓冲从传入前缀开始（可为空）
pub fn jpeg_progressive_partial_open(
  data : Bytes,
) -> JpegProgPartial raise @types.LoadError {
  let header = jpeg_parse_header(data)
  if !header.progressive {
    raise @types.LoadError::DecodeFailed(
      "不是 progressive JPEG（SOF2），半扫描推进不适用",
    )
  }
  @types.check_dims(header.width, header.height, header.num_components)
  let ctx = jpeg_progressive_ctx(header)
  JpegProgPartial::{
    header,
    data,
    ctx,
    visible: 0,
    scan_idx: 0,
    unit_idx: 0,
    started: false,
    r_pos: 0,
    r_bit_buf: 0,
    r_bit_cnt: 0,
    pred: [],
    eobrun: 0,
  }
}

///|
/// 推进可见窗口：声明「前 up_to 字节已收到」
///
/// `data` 在 open 时就要给完整文件（头部与各条 SOS 的熵区间靠它定位）；
/// 这里的可见长度只限制熵解码能读多远，模拟网络边收边解。
pub fn jpeg_progressive_partial_feed(
  p : JpegProgPartial,
  up_to : Int32,
) -> Unit {
  let mut n = up_to
  if n < 0 {
    n = 0
  }
  if n > p.data.length() {
    n = p.data.length()
  }
  if n > p.visible {
    p.visible = n
  }
}

///|
/// 当前成型一帧（未到的系数位面按 0 处理）
pub fn jpeg_progressive_partial_image(p : JpegProgPartial) -> @types.Image {
  jpeg_progressive_render(p.header, p.ctx)
}

///|
/// 当前状态快照（只读诊断用）
pub fn jpeg_progressive_partial_position(p : JpegProgPartial) -> (Int32, Int32) {
  (p.scan_idx, p.unit_idx)
}

///|
/// 把一条扫描里被写入的块备份 / 还原（一个块 = 64 个系数）
fn jpeg_partial_save_block(
  coefs : Array[Int32],
  base : Int32,
  out : Array[Int32],
) -> Unit {
  for i in 0..<64 {
    out.push(coefs[base + i])
  }
}

///|
/// 还原备份块
fn jpeg_partial_restore_block(
  coefs : Array[Int32],
  base : Int32,
  saved : Array[Int32],
) -> Unit {
  for i in 0..<64 {
    coefs[base + i] = saved[i]
  }
}

///|
/// 推进若干单位；命中字节末尾时回滚该单位并返回 `stuck`
pub fn jpeg_progressive_partial_advance(
  p : JpegProgPartial,
  max_units : Int32,
) -> JpegProgAdvance raise @types.LoadError {
  let scans = p.header.scans
  let total_scans = scans.length()
  if p.scan_idx >= total_scans {
    return JpegProgAdvance::{
      scan_index: total_scans,
      unit_done: 0,
      unit_total: 0,
      scan_complete: true,
      stuck: false,
      finished: true,
    }
  }
  let scan = scans[p.scan_idx]
  let nc = p.header.num_components
  let interleaved = scan.ns > 1
  let ci_lone = scan.comp_idx[0]
  let units_x = if interleaved { p.ctx.mcus_x } else { p.ctx.bw[ci_lone] }
  let units_y = if interleaved { p.ctx.mcus_y } else { p.ctx.bh[ci_lone] }
  let unit_total = units_x * units_y
  if !p.started {
    p.r_pos = scan.entropy_start
    p.r_bit_buf = 0
    p.r_bit_cnt = 0
    p.pred = []
    for _ in 0..<nc {
      p.pred.push(0)
    }
    p.eobrun = 0
    p.started = true
  }
  let data = p.data
  let zz = zigzag()
  let mut budget = if max_units < 1 { 1 } else { max_units }
  let mut stuck = false
  while p.unit_idx < unit_total && budget > 0 {
    let reader = JpegBitReader::{
      data,
      len: p.visible,
      pos: p.r_pos,
      bit_buf: p.r_bit_buf,
      bit_cnt: p.r_bit_cnt,
      suspended: false,
    }
    // 重启间隔：单位序号命中间隔时跳过 RST 标记；找不到说明字节还没到齐
    if p.header.restart_interval > 0 &&
      p.unit_idx > 0 &&
      p.unit_idx % p.header.restart_interval == 0 {
      reader.bit_cnt = 0
      reader.bit_buf = 0
      let mut found = false
      while reader.pos < reader.len - 1 {
        if reader.data[reader.pos].to_int() == 0xFF &&
          reader.data[reader.pos + 1].to_int() >= 0xD0 &&
          reader.data[reader.pos + 1].to_int() <= 0xD7 {
          reader.pos += 2
          found = true
          break
        }
        reader.pos += 1
      }
      if !found {
        stuck = true
        break
      }
    }
    // 快照：reader 三字段 + DC 预测 + EOBRUN
    let snap_pos = reader.pos
    let snap_bit_buf = reader.bit_buf
    let snap_bit_cnt = reader.bit_cnt
    let snap_pred : Array[Int32] = []
    for i in 0..<nc {
      snap_pred.push(p.pred[i])
    }
    let snap_eobrun = p.eobrun
    // 该单位将写入的块（可能多个分量）
    let ux = p.unit_idx % units_x
    let uy = p.unit_idx / units_x
    let targets : Array[(Int32, Int32)] = []
    if interleaved {
      for si in 0..<scan.ns {
        let ci = scan.comp_idx[si]
        let hi = p.header.component_h[ci]
        let vi = p.header.component_v[ci]
        for bi in 0..<(hi * vi) {
          let gx = ux * hi + bi % hi
          let gy = uy * vi + bi / hi
          targets.push((ci, (gy * p.ctx.stride_x[ci] + gx) * 64))
        }
      }
    } else if ux < p.ctx.bw[ci_lone] && uy < p.ctx.bh[ci_lone] {
      targets.push((ci_lone, (uy * p.ctx.stride_x[ci_lone] + ux) * 64))
    }
    // 备份这些块的旧值
    let saved : Array[Array[Int32]] = []
    for t in targets {
      let s : Array[Int32] = []
      jpeg_partial_save_block(p.ctx.coefs[t.0], t.1, s)
      saved.push(s)
    }
    let pred_refs : Array[Ref[Int32]] = []
    for i in 0..<nc {
      pred_refs.push(Ref(p.pred[i]))
    }
    let eob = Ref(p.eobrun)
    let decoded = try {
      if interleaved {
        for si in 0..<scan.ns {
          let ci = scan.comp_idx[si]
          let hi = p.header.component_h[ci]
          let vi = p.header.component_v[ci]
          for bi in 0..<(hi * vi) {
            let gx = ux * hi + bi % hi
            let gy = uy * vi + bi / hi
            jpeg_progressive_block(
              reader,
              p.ctx.coefs[ci],
              (gy * p.ctx.stride_x[ci] + gx) * 64,
              scan,
              zz,
              scan.dc_tabs[si],
              scan.ac_tabs[si],
              pred_refs[ci],
              eob,
            )
          }
        }
      } else {
        jpeg_progressive_block(
          reader,
          p.ctx.coefs[ci_lone],
          (uy * p.ctx.stride_x[ci_lone] + ux) * 64,
          scan,
          zz,
          scan.dc_tabs[0],
          scan.ac_tabs[0],
          pred_refs[ci_lone],
          eob,
        )
      }
      Ok(true)
    } catch {
      e => Err(e)
    }
    match decoded {
      Ok(_) => {
        p.r_pos = reader.pos
        p.r_bit_buf = reader.bit_buf
        p.r_bit_cnt = reader.bit_cnt
        for i in 0..<nc {
          p.pred[i] = pred_refs[i].val
        }
        p.eobrun = eob.val
        p.unit_idx = p.unit_idx + 1
        budget = budget - 1
      }
      Err(e) => {
        if reader.suspended {
          // 回滚到该单位起点：系数、预测、reader 位置全部复原
          for k in 0..<targets.length() {
            jpeg_partial_restore_block(
              p.ctx.coefs[targets[k].0],
              targets[k].1,
              saved[k],
            )
          }
          for i in 0..<nc {
            p.pred[i] = snap_pred[i]
          }
          p.eobrun = snap_eobrun
          p.r_pos = snap_pos
          p.r_bit_buf = snap_bit_buf
          p.r_bit_cnt = snap_bit_cnt
          stuck = true
        } else {
          raise e
        }
        break
      }
    }
  }
  let scan_complete = p.unit_idx >= unit_total
  let done = p.unit_idx
  let idx_now = p.scan_idx
  if scan_complete && !stuck {
    p.scan_idx = p.scan_idx + 1
    p.unit_idx = 0
    p.started = false
    p.pred = []
    p.eobrun = 0
  }
  JpegProgAdvance::{
    scan_index: idx_now + 1,
    unit_done: done,
    unit_total,
    scan_complete,
    stuck,
    finished: p.scan_idx >= total_scans,
  }
}
