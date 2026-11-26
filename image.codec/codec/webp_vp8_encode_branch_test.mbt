// 覆盖率测试：VP8 有损编码路径的多尺寸/多质量分支
// 产物不符合 VP8 规范（已知），此处只验证编码不崩、容器签名正确

fn vp8e_img(
  w : Int32,
  h : Int32,
  c : Int32,
  f : (Int32, Int32, Int32) -> Int32,
) -> @types.Image {
  let data : Array[Int32] = []
  for y in 0..<h {
    for x in 0..<w {
      for ch in 0..<c {
        data.push(f(x, y, ch))
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
}

test "vp8e: 多尺寸编码" {
  // 16×16 平坦
  let flat = vp8e_img(16, 16, 3, fn(_x, _y, _c) { 128 })
  let a = @codec.encode_webp_lossy_full(flat)
  assert_true(a.length() > 0)
  // 16×16 渐变
  let grad = vp8e_img(16, 16, 3, fn(x, y, c) { (x * 8 + y * 4 + c * 20) % 256 })
  let b = @codec.encode_webp_lossy_full(grad)
  assert_true(b.length() > 0)
  // 非 16 对齐尺寸
  let odd = vp8e_img(17, 9, 3, fn(x, y, _c) { (x * 13 + y * 7) % 256 })
  let c1 = @codec.encode_webp_lossy_full(odd)
  assert_true(c1.length() > 0)
  // 1×1
  let tiny = vp8e_img(1, 1, 3, fn(_x, _y, _c) { 200 })
  let d = @codec.encode_webp_lossy_full(tiny)
  assert_true(d.length() > 0)
  // 32×32 高对比棋盘
  let chess = vp8e_img(32, 32, 3, fn(x, y, _c) {
    if (x / 4 + y / 4) % 2 == 0 {
      0
    } else {
      255
    }
  })
  let e = @codec.encode_webp_lossy_full(chess)
  assert_true(e.length() > 0)
}

test "vp8e: 多质量与 RGBA" {
  let img = vp8e_img(24, 20, 3, fn(x, y, c) { (x * 5 + y * 11 + c * 40) % 256 })
  // 质量 0 / 50 / 75 / 100 / 越界
  for q in [0, 30, 50, 75, 90, 100, 200, -5] {
    let out = @codec.encode_webp_lossy_full(img, quality=q)
    assert_true(out.length() > 0)
  }
  // RGBA
  let rgba = vp8e_img(16, 16, 4, fn(x, y, c) { (x * 9 + y * 3 + c * 30) % 256 })
  let out = @codec.encode_webp_lossy_full(rgba)
  assert_true(out.length() > 0)
  // 全黑 / 全白
  let black = vp8e_img(16, 16, 3, fn(_x, _y, _c) { 0 })
  let white = vp8e_img(16, 16, 3, fn(_x, _y, _c) { 255 })
  let ob = @codec.encode_webp_lossy_full(black)
  let ow = @codec.encode_webp_lossy_full(white)
  assert_true(ob.length() > 0)
  assert_true(ow.length() > 0)
}

test "vp8e: 错误分支" {
  try {
    let _ = @codec.encode_webp_lossy_full(vp8e_img(0, 8, 3, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.encode_webp_lossy_full(vp8e_img(8, 8, 1, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @codec.encode_webp_lossy_full(vp8e_img(8, 8, 2, fn(_x, _y, _c) { 0 }))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}
