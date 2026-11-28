/// # JPEG 色度上采样（libjpeg fancy upsampling 移植）
///
/// 4:2:0 / 4:2:2 的色度分辨率是亮度的一半，解码时要放大回亮度网格。以前用最近邻
/// （一个色度值铺满 2×2 像素），放大处会出现方块状边缘；libjpeg 默认用"三角滤波"
/// （`h2v2_fancy_upsample` / `h2v1_fancy_upsample`）——按 3/4·近邻 + 1/4·远邻 加权，
/// 相当于权重 9/16、3/16、3/16、1/16 的双线性，边缘平滑很多。
///
/// 本文件按 libjpeg `jdsample.c` 的公式逐位复刻，只依赖整数运算：
/// - `h2v1`：水平 2:1，偶数列 `(3·this + last + 2) >> 2`、奇数列 `(3·this + next + 1) >> 2`；
/// - `h2v2`：水平 + 垂直各 2:1，先算列和 `colsum = 3·近行 + 远行`，
///   偶数列 `(3·colsum + lastsum + 8) >> 4`、奇数列 `(3·colsum + nextsum + 7) >> 4`。
///
/// 边界（首/末行、首/末列）用复制钳制，与 libjpeg 在输入数组两侧填 context 行的效果一致。

///|
/// 把 `v` 钳到 `[lo, hi]`
fn jpeg_clamp_i32(v : Int32, lo : Int32, hi : Int32) -> Int32 {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
/// 一列上的"行加权和"：`3·近行 + 远行`（libjpeg 的 `colsum`）
fn jpeg_colsum(
  plane : Array[Int32],
  stride : Int32,
  near_row : Int32,
  far_row : Int32,
  c : Int32,
) -> Int32 {
  plane[near_row * stride + c] * 3 + plane[far_row * stride + c]
}

///|
/// 水平 2:1 三角滤波上采样（libjpeg `h2v1_fancy_upsample`）
///
/// `stride` 是原平面的行跨距（可能大于有效宽 `dw`，块对齐留下的余量）。
/// 返回 `(放大后的平面, 宽, 高)`；宽 = `dw * 2`，高不变。
fn jpeg_fancy_h2v1(
  plane : Array[Int32],
  stride : Int32,
  dw : Int32,
  dh : Int32,
) -> (Array[Int32], Int32, Int32) {
  let uw = dw * 2
  let out : Array[Int32] = Array::make(uw * dh, 0)
  for y in 0..<dh {
    for x in 0..<uw {
      let cx = x >> 1
      let near = plane[y * stride + cx]
      let neighbor = if (x & 1) == 0 {
        plane[y * stride + jpeg_clamp_i32(cx - 1, 0, dw - 1)]
      } else {
        plane[y * stride + jpeg_clamp_i32(cx + 1, 0, dw - 1)]
      }
      out[y * uw + x] = if (x & 1) == 0 {
        (near * 3 + neighbor + 2) >> 2
      } else {
        (near * 3 + neighbor + 1) >> 2
      }
    }
  }
  (out, uw, dh)
}

///|
/// 水平 + 垂直各 2:1 三角滤波上采样（libjpeg `h2v2_fancy_upsample`）
///
/// 返回 `(放大后的平面, 宽, 高)`；宽高各 ×2。权重合计 9/16、3/16、3/16、1/16（见 libjpeg 注释）。
fn jpeg_fancy_h2v2(
  plane : Array[Int32],
  stride : Int32,
  dw : Int32,
  dh : Int32,
) -> (Array[Int32], Int32, Int32) {
  let uw = dw * 2
  let uh = dh * 2
  let out : Array[Int32] = Array::make(uw * uh, 0)
  for y in 0..<uh {
    let cy = y >> 1
    // 偶数行离上一行近，奇数行离下一行近（越界复制边缘行）
    let far = if (y & 1) == 0 {
      jpeg_clamp_i32(cy - 1, 0, dh - 1)
    } else {
      jpeg_clamp_i32(cy + 1, 0, dh - 1)
    }
    for x in 0..<uw {
      let cx = x >> 1
      let this_sum = jpeg_colsum(plane, stride, cy, far, cx)
      let neighbor_sum = if (x & 1) == 0 {
        jpeg_colsum(plane, stride, cy, far, jpeg_clamp_i32(cx - 1, 0, dw - 1))
      } else {
        jpeg_colsum(plane, stride, cy, far, jpeg_clamp_i32(cx + 1, 0, dw - 1))
      }
      out[y * uw + x] = if (x & 1) == 0 {
        (this_sum * 3 + neighbor_sum + 8) >> 4
      } else {
        (this_sum * 3 + neighbor_sum + 7) >> 4
      }
    }
  }
  (out, uw, uh)
}

///|
/// 按采样因子选择上采样方式：2×2 → `h2v2` 三角滤波，2×1 → `h2v1` 三角滤波，
/// 其他（整分辨或罕见比例）保持原平面并按最近邻取样。
///
/// 第四项 `true` 表示返回平面已在亮度网格上，取样直接用 `(ox, oy)`。
fn jpeg_upsample_plane(
  plane : Array[Int32],
  stride : Int32,
  dw : Int32,
  dh : Int32,
  scale_h : Int32,
  scale_v : Int32,
) -> (Array[Int32], Int32, Int32, Bool) {
  if scale_h == 2 && scale_v == 2 {
    let (up, uw, uh) = jpeg_fancy_h2v2(plane, stride, dw, dh)
    (up, uw, uh, true)
  } else if scale_h == 2 && scale_v == 1 {
    let (up, uw, uh) = jpeg_fancy_h2v1(plane, stride, dw, dh)
    (up, uw, uh, true)
  } else {
    // 保持原平面：返回的"宽"必须是真实行跨距（块对齐留下 padding 列），
    // 取样按 neighest 索引 stride，边界钳制交给调用方按有效宽处理
    (plane, stride, dh, false)
  }
}

///|
/// 从（可能已上采样的）分量平面取样一个像素
fn jpeg_plane_pixel(
  planes : Array[Array[Int32]],
  plane_w : Array[Int32],
  plane_h : Array[Int32],
  on_luma_grid : Array[Bool],
  ci : Int32,
  ox : Int32,
  oy : Int32,
  hi : Int32,
  vi : Int32,
  max_h : Int32,
  max_v : Int32,
) -> Int32 {
  let pw = plane_w[ci]
  let ph = plane_h[ci]
  if on_luma_grid[ci] {
    planes[ci][jpeg_clamp_i32(oy, 0, ph - 1) * pw +
    jpeg_clamp_i32(ox, 0, pw - 1)]
  } else {
    let sx = jpeg_clamp_i32(ox * hi / max_h, 0, pw - 1)
    let sy = jpeg_clamp_i32(oy * vi / max_v, 0, ph - 1)
    planes[ci][sy * pw + sx]
  }
}

///|
/// 分量平面 → RGB（灰度复制三通道）。色度走三角滤波上采样，其余按采样因子最近邻取样。
///
/// 这是 baseline（`jpeg_decode_scan`）与 progressive（`jpeg_progressive_output`）共用的收尾步骤：
/// 两者解码阶段都产出"每分量按块网格铺好的整幅平面"，差别只在系数怎么攒。
fn jpeg_planes_to_rgb(
  header : JpegHeader,
  planes : Array[Array[Int32]],
  plane_w : Array[Int32],
  max_h : Int32,
  max_v : Int32,
) -> @types.Image {
  let width = header.width
  let height = header.height
  let nc = header.num_components
  let out : Array[Byte] = Array::make(width * height * 3, b'\x00')
  // 每分量：上采样后的平面 + 宽高 + 是否已落在亮度网格
  let s_planes : Array[Array[Int32]] = []
  let s_w : Array[Int32] = Array::make(4, 0)
  let s_h : Array[Int32] = Array::make(4, 0)
  let on_grid : Array[Bool] = Array::make(4, false)
  for ci in 0..<nc {
    let hi = header.component_h[ci]
    let vi = header.component_v[ci]
    let dw = (width * hi + max_h - 1) / max_h
    let dh = (height * vi + max_v - 1) / max_v
    let (p, pw, ph, up) = jpeg_upsample_plane(
      planes[ci],
      plane_w[ci],
      dw,
      dh,
      max_h / hi,
      max_v / vi,
    )
    s_planes.push(p)
    s_w[ci] = pw
    s_h[ci] = ph
    on_grid[ci] = up
  }
  let h0 = header.component_h[0]
  let v0 = header.component_v[0]
  for oy in 0..<height {
    for ox in 0..<width {
      let oidx = (oy * width + ox) * 3
      if nc == 1 {
        let v = jpeg_plane_pixel(
          s_planes, s_w, s_h, on_grid, 0, ox, oy, h0, v0, max_h, max_v,
        )
        let vb = v.to_byte()
        out[oidx] = vb
        out[oidx + 1] = vb
        out[oidx + 2] = vb
      } else {
        let yv = jpeg_plane_pixel(
          s_planes, s_w, s_h, on_grid, 0, ox, oy, h0, v0, max_h, max_v,
        )
        let cb = jpeg_plane_pixel(
          s_planes,
          s_w,
          s_h,
          on_grid,
          1,
          ox,
          oy,
          header.component_h[1],
          header.component_v[1],
          max_h,
          max_v,
        )
        let cr = jpeg_plane_pixel(
          s_planes,
          s_w,
          s_h,
          on_grid,
          2,
          ox,
          oy,
          header.component_h[2],
          header.component_v[2],
          max_h,
          max_v,
        )
        let (r, g, b) = ycbcr_to_rgb(yv, cb, cr)
        out[oidx] = r.to_byte()
        out[oidx + 1] = g.to_byte()
        out[oidx + 2] = b.to_byte()
      }
    }
  }
  @types.Image::{ width, height, channels: 3, data: Bytes::from_array(out), }
}
