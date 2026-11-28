///|
/// # 渐进式 JPEG 逐扫描预览（0.1.33）
///
/// progressive 编码的价值在于「先粗后细」：第 1 条扫描（DC 首扫）就能给出
/// 整幅可辨认的低频轮廓，后续扫描逐位补细节。此前的解码只输出终态，
/// 本模块把「每条扫描解完即成片」的能力开出来，供渐进加载 / 预览场景使用。

///|
/// progressive 解码上下文：系数缓冲与块网格参数（scan 之间共享）
priv struct JpegProgCtx {
  coefs : Array[Array[Int32]]
  bw : Array[Int32]
  bh : Array[Int32]
  stride_x : Array[Int32]
  mcus_x : Int32
  mcus_y : Int32
  max_h : Int32
  max_v : Int32
}

///|
/// 建上下文：校验分量数与采样因子，按 MCU 网格容量分配系数缓冲
fn jpeg_progressive_ctx(
  header : JpegHeader,
) -> JpegProgCtx raise @types.LoadError {
  let width = header.width
  let height = header.height
  let nc = header.num_components
  if nc != 1 && nc != 3 {
    raise @types.LoadError::DecodeFailed(
      "JPEG progressive 仅支持 1 或 3 分量",
    )
  }
  if header.scans.length() == 0 {
    raise @types.LoadError::DecodeFailed("JPEG progressive 缺少扫描数据")
  }
  let mut max_h = 1
  let mut max_v = 1
  for i in 0..<nc {
    if header.component_h[i] > max_h {
      max_h = header.component_h[i]
    }
    if header.component_v[i] > max_v {
      max_v = header.component_v[i]
    }
  }
  if max_h < 1 || max_v < 1 {
    raise @types.LoadError::DecodeFailed("JPEG 采样因子无效")
  }
  let mcu_w = max_h * 8
  let mcu_h = max_v * 8
  let mcus_x = (width + mcu_w - 1) / mcu_w
  let mcus_y = (height + mcu_h - 1) / mcu_h
  let bw : Array[Int32] = Array::make(4, 0)
  let bh : Array[Int32] = Array::make(4, 0)
  let stride_x : Array[Int32] = Array::make(4, 0)
  let coefs : Array[Array[Int32]] = []
  for ci in 0..<nc {
    // 实际块网格（输出用）：ceil(w*h_i/(8*max_h)) × ceil(h*v_i/(8*max_v))
    bw[ci] = (width * header.component_h[ci] + mcu_w - 1) / mcu_w
    bh[ci] = (height * header.component_v[ci] + mcu_h - 1) / mcu_h
    // 系数缓冲按 MCU 网格容量分配：交错扫描会把 padding 块也编进码流
    stride_x[ci] = mcus_x * header.component_h[ci]
    coefs.push(
      Array::make(stride_x[ci] * mcus_y * header.component_v[ci] * 64, 0),
    )
  }
  JpegProgCtx::{ coefs, bw, bh, stride_x, mcus_x, mcus_y, max_h, max_v, }
}

///|
/// 把当前累积到的系数成型为一帧（未到的系数位面按 0 处理，即"粗版"）
fn jpeg_progressive_render(
  header : JpegHeader,
  ctx : JpegProgCtx,
) -> @types.Image {
  jpeg_progressive_output(
    header,
    ctx.coefs,
    ctx.bw,
    ctx.bh,
    ctx.stride_x,
    ctx.max_h,
    ctx.max_v,
  )
}

///|
/// 渐进式 JPEG 的一帧预览：扫描序号（1 起）与当时的图像
pub(all) struct JpegProgPreview {
  scan_index : Int32
  image : @types.Image
}

///|
/// 逐扫描解码 progressive JPEG，在每 `every_scans` 条扫描后产出一帧。
///
/// 参数 Parameters:
/// - `data` - progressive JPEG（SOF2）字节流
/// - `every_scans` - 每解完多少条扫描出一帧；`< 1` 视为 1（最长每扫描一帧）
///
/// 返回 Return:
/// - 预览帧数组，按扫描进度递增排列；**末帧恒为完整解码结果**
pub fn decode_jpeg_progressive_previews(
  data : Bytes,
  every_scans : Int32,
) -> Array[JpegProgPreview] raise @types.LoadError {
  let header = jpeg_parse_header(data)
  if !header.progressive {
    raise @types.LoadError::DecodeFailed(
      "不是 progressive JPEG（SOF2），逐扫描预览不适用",
    )
  }
  @types.check_dims(header.width, header.height, header.num_components)
  let ctx = jpeg_progressive_ctx(header)
  let every = if every_scans < 1 { 1 } else { every_scans }
  let total = header.scans.length()
  let frames : Array[JpegProgPreview] = []
  let mut idx = 0
  for scan in header.scans {
    jpeg_progressive_scan(
      header,
      data,
      scan,
      ctx.coefs,
      ctx.bw,
      ctx.bh,
      ctx.stride_x,
      ctx.mcus_x,
      ctx.mcus_y,
    )
    idx = idx + 1
    if idx % every == 0 || idx == total {
      frames.push(JpegProgPreview::{
        scan_index: idx,
        image: jpeg_progressive_render(header, ctx),
      })
    }
  }
  frames
}

///|
/// 按文件字节解的扫描总数与最终帧（不额外成型中间帧，等价 `decode_jpeg_pure`）
pub fn jpeg_progressive_scan_count(
  data : Bytes,
) -> Int32 raise @types.LoadError {
  let header = jpeg_parse_header(data)
  if !header.progressive {
    raise @types.LoadError::DecodeFailed(
      "不是 progressive JPEG（SOF2），逐扫描预览不适用",
    )
  }
  header.scans.length()
}
