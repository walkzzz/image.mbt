// 覆盖率测试：mse / psnr / ssim 的错误分支与 ssim 大尺寸内积分支
// 约定：出错时 helper 返回 -1.0

fn iq_img(w : Int32, h : Int32, c : Int32, fill : Int32) -> @types.Image {
  let n = w * h * c
  let d : Array[Byte] = []
  for i in 0..<n {
    d.push((fill + i).to_byte())
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn iq_blank(w : Int32, h : Int32, c : Int32) -> @types.Image {
  let n = w * h * c
  let d : Array[Byte] = []
  for _ in 0..<n {
    d.push(b'\x00')
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn iq_mse(r1 : @types.Image, r2 : @types.Image) -> Double {
  try {
    @feature.mse(r1, r2)
  } catch {
    _ => -1.0
  }
}

fn iq_psnr(r1 : @types.Image, r2 : @types.Image) -> Double {
  try {
    @feature.psnr(r1, r2)
  } catch {
    _ => -1.0
  }
}

fn iq_ssim(r1 : @types.Image, r2 : @types.Image) -> Double {
  try {
    @feature.ssim(r1, r2)
  } catch {
    _ => -1.0
  }
}

fn iq_bad(w : Int32, h : Int32, c : Int32, len : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<len {
    d.push(b'\x01')
  }
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

test "iqcov: mse 数值与错误分支" {
  let a = iq_img(2, 2, 1, 0)
  assert_true(iq_mse(a, a) >= 0.0)
  assert_true(iq_mse(a, a) == 0.0)
  // 单点差异 → MSE = 1
  let b = iq_bad(2, 2, 1, 4)
  assert_true(iq_mse(a, b) > 0.0)
  // 图像 1 / 图像 2 尺寸非法
  assert_true(iq_mse(iq_bad(0, 2, 1, 0), a) < 0.0)
  assert_true(iq_mse(a, iq_bad(0, 2, 1, 0)) < 0.0)
  // 通道数非法
  assert_true(iq_mse(iq_bad(2, 2, 5, 0), a) < 0.0)
  assert_true(iq_mse(a, iq_bad(2, 2, 5, 0)) < 0.0)
  // 尺寸不一致
  assert_true(iq_mse(a, iq_img(3, 3, 1, 0)) < 0.0)
  // 通道数不一致
  assert_true(iq_mse(a, iq_img(2, 2, 3, 0)) < 0.0)
  // 数据长度不匹配
  assert_true(iq_mse(iq_bad(2, 2, 1, 1), a) < 0.0)
  assert_true(iq_mse(a, iq_bad(2, 2, 1, 1)) < 0.0)
}

test "iqcov: psnr 数值与错误分支" {
  let black = iq_blank(4, 4, 1)
  // 相同图像 → MSE 0 → PSNR 极大值
  assert_true(iq_psnr(black, black) > 1000.0)
  // 有差异 → 有限值
  let white = iq_img(4, 4, 1, 200)
  let p1 = iq_psnr(black, white)
  assert_true(p1 > 0.0 && p1 < 100.0)
  // 错误分支
  assert_true(iq_psnr(iq_bad(0, 1, 1, 0), black) < 0.0)
  assert_true(iq_psnr(black, iq_bad(0, 1, 1, 0)) < 0.0)
  assert_true(iq_psnr(iq_bad(4, 4, 6, 0), black) < 0.0)
  assert_true(iq_psnr(black, iq_bad(4, 4, 6, 0)) < 0.0)
  assert_true(iq_psnr(black, iq_blank(2, 2, 1)) < 0.0)
  assert_true(iq_psnr(black, iq_blank(4, 4, 3)) < 0.0)
  assert_true(iq_psnr(iq_bad(4, 4, 1, 1), black) < 0.0)
  assert_true(iq_psnr(black, iq_bad(4, 4, 1, 1)) < 0.0)
}

test "iqcov: ssim 内积分支与错误分支" {
  // 20x20：触发内部区域积分图路径（win=8, half=4）
  let a = iq_img(20, 20, 1, 30)
  let s1 = iq_ssim(a, a)
  assert_true(s1 > 0.9 && s1 <= 1.0)
  // 噪声图 → 更低
  let s2 = iq_ssim(a, iq_blank(20, 20, 1))
  assert_true(s2 >= 0.0 && s2 < s1)
  // 彩色三通道小图（仅边界路径）
  let c1x = iq_img(6, 6, 3, 10)
  assert_true(iq_ssim(c1x, c1x) > 0.9)
  // 4 通道
  let c4x = iq_img(6, 6, 4, 10)
  assert_true(iq_ssim(c4x, c4x) > 0.9)
  // 错误分支
  assert_true(iq_ssim(iq_bad(0, 6, 1, 0), c1x) < 0.0)
  assert_true(iq_ssim(c1x, iq_bad(0, 6, 1, 0)) < 0.0)
  assert_true(iq_ssim(iq_bad(6, 6, 5, 0), iq_bad(6, 6, 5, 0)) < 0.0)
  assert_true(iq_ssim(c1x, iq_bad(6, 6, 5, 0)) < 0.0)
  assert_true(iq_ssim(c1x, iq_blank(4, 4, 3)) < 0.0)
  assert_true(iq_ssim(c1x, iq_blank(6, 6, 1)) < 0.0)
  assert_true(iq_ssim(iq_bad(6, 6, 3, 1), c1x) < 0.0)
  assert_true(iq_ssim(c1x, iq_bad(6, 6, 3, 1)) < 0.0)
}
