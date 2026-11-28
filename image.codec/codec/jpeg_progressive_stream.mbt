///|
/// # 渐进 JPEG 的扫描游标（0.1.36）
///
/// `decode_jpeg_progressive_previews` 一次跑完全部扫描，调用方拿不到「解到一半就停」
/// 的能力。对大图或只想要缩略轮廓的场景（scan 1 的 DC 首扫已经够看），
/// 后续扫描的熵解码与全图 IDCT 都是纯浪费。
///
/// `JpegProgStream` 把「解析头部」与「推进扫描」拆开：`open` 解析一次 SOI/SOF/DHT/DQT
/// 与全部 SOS 边界，`step` 每次只解一条扫描并成型一帧，`remaining` 给出还剩几条，
/// `finish` 补齐剩余扫描并返回终态（等价 `decode_jpeg_pure`）。
/// 系数缓冲在游标生命周期内共享，不重复分配、不重复解已解过的扫描。

///|
/// 渐进解码游标：头部、字节流、系数上下文与下一条待解扫描的下标。
/// 字段私有——外部只能通过 `step` / `remaining` / `done` / `finish` 使用。
pub struct JpegProgStream {
  header : JpegHeader
  data : Bytes
  ctx : JpegProgCtx
  mut next : Int32
}

///|
/// 打开游标：解析头部并校验分量数、尺寸上限与扫描表非空。
///
/// 参数 Parameters:
/// - `data` - progressive JPEG（SOF2）字节流
///
/// 返回 Return:
/// - 游标（首条扫描尚未解码）
pub fn jpeg_progressive_stream_open(
  data : Bytes,
) -> JpegProgStream raise @types.LoadError {
  let header = jpeg_parse_header(data)
  if !header.progressive {
    raise @types.LoadError::DecodeFailed(
      "不是 progressive JPEG（SOF2），扫描游标不适用",
    )
  }
  @types.check_dims(header.width, header.height, header.num_components)
  let ctx = jpeg_progressive_ctx(header)
  JpegProgStream::{ header, data, ctx, next: 0, }
}

///|
/// 推进一条扫描并成型一帧；扫描已解完时返回 `None`。
///
/// 返回的帧与 `decode_jpeg_progressive_previews(data, 1)` 中同序号帧逐字节相同。
pub fn jpeg_progressive_stream_step(
  s : JpegProgStream,
) -> JpegProgPreview? raise @types.LoadError {
  let scans = s.header.scans
  if s.next >= scans.length() {
    return None
  }
  let scan = scans[s.next]
  jpeg_progressive_scan(
    s.header,
    s.data,
    scan,
    s.ctx.coefs,
    s.ctx.bw,
    s.ctx.bh,
    s.ctx.stride_x,
    s.ctx.mcus_x,
    s.ctx.mcus_y,
  )
  s.next = s.next + 1
  Some(JpegProgPreview::{
    scan_index: s.next,
    image: jpeg_progressive_render(s.header, s.ctx),
  })
}

///|
/// 还剩多少条扫描没解（含已解完的 0）。
pub fn jpeg_progressive_stream_remaining(s : JpegProgStream) -> Int32 {
  s.header.scans.length() - s.next
}

///|
/// 已解了多少条扫描（即当前累积系数对应的进度）。
pub fn jpeg_progressive_stream_done(s : JpegProgStream) -> Int32 {
  s.next
}

///|
/// 补齐剩余扫描并返回终态图像（与 `decode_jpeg_pure` 逐字节一致）；
/// 已解完时直接成型当前系数，不重复解码。
pub fn jpeg_progressive_stream_finish(
  s : JpegProgStream,
) -> @types.Image raise @types.LoadError {
  let scans = s.header.scans
  while s.next < scans.length() {
    let scan = scans[s.next]
    jpeg_progressive_scan(
      s.header,
      s.data,
      scan,
      s.ctx.coefs,
      s.ctx.bw,
      s.ctx.bh,
      s.ctx.stride_x,
      s.ctx.mcus_x,
      s.ctx.mcus_y,
    )
    s.next = s.next + 1
  }
  jpeg_progressive_render(s.header, s.ctx)
}
