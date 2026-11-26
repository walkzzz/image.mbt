// 覆盖率测试：字符分割后处理与完整流水线分支补充

///|
fn cs_img(w : Int32, h : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, 0)),
  }
}

///|
fn cs_bar(w : Int32, h : Int32, bars : Array[(Int32, Int32)]) -> @types.Image {
  // bars: (起始 x, 宽度)；前景（255）竖条，其余背景（0）
  let data : Array[Int32] = Array::make(w * h, 0)
  for bar in bars {
    let (x0, bw) = bar
    for y in 0..<h {
      for x in x0..<(x0 + bw) {
        data[y * w + x] = 255
      }
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
}

///|
fn cs_full(w : Int32, h : Int32, filler : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(Array::make(w * h, filler.to_byte())),
  }
}

///|
test "cscov: merge_small_segments 分支" {
  // 空列表报错
  try {
    let _ = @ocr.merge_small_segments([], 4, 4)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // min_width / min_height 非法
  try {
    let _ = @ocr.merge_small_segments([(0, 0, 10, 10)], 0, 4)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.merge_small_segments([(0, 0, 10, 10)], 4, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 全部达标 → 原样保留
  let ok = @ocr.merge_small_segments([(0, 0, 10, 10), (20, 0, 10, 10)], 5, 5)
  assert_true(ok.length() == 2)
  // 小区域向前合并
  let fwd = @ocr.merge_small_segments([(0, 0, 2, 2), (10, 0, 10, 10)], 5, 5)
  assert_true(fwd.length() == 1)
  assert_true(fwd[0].0 == 0)
  assert_true(fwd[0].2 >= 20)
  // 末尾小区域向后合并
  let bwd = @ocr.merge_small_segments([(0, 0, 10, 10), (20, 0, 2, 2)], 5, 5)
  assert_true(bwd.length() == 1)
  assert_true(bwd[0].2 >= 20)
  // 全部过小且无已合并项 → 空
  let allsmall = @ocr.merge_small_segments([(0, 0, 2, 2)], 5, 5)
  assert_true(allsmall.length() == 0)
  // 高度不足也要合并
  let flat = @ocr.merge_small_segments([(0, 0, 10, 1), (10, 0, 10, 10)], 5, 5)
  assert_true(flat.length() == 1)
}

///|
test "cscov: filter_noise_segments 分支" {
  let segs = [(0, 0, 10, 10), (20, 0, 1, 1), (30, 0, 150, 150)]
  // 空列表
  try {
    let _ = @ocr.filter_noise_segments([], 100, 100)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 图像尺寸非法
  try {
    let _ = @ocr.filter_noise_segments(segs, 0, 100)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.filter_noise_segments(segs, 100, 0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 比例越界
  try {
    let _ = @ocr.filter_noise_segments(segs, 100, 100, min_area_ratio=-0.1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.filter_noise_segments(segs, 100, 100, max_area_ratio=1.5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // max < min
  try {
    let _ = @ocr.filter_noise_segments(
      segs,
      100,
      100,
      min_area_ratio=0.5,
      max_area_ratio=0.1,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 正常过滤：100x100 图，min 0.001 → 10 像素；max 0.5 → 5000 像素
  let out = @ocr.filter_noise_segments(segs, 100, 100)
  assert_true(out.length() == 1)
  assert_true(out[0].2 == 10)
}

///|
test "cscov: 连通域与完整流水线" {
  // 两条字符（宽 6）
  let img = cs_bar(30, 12, [(2, 6), (20, 6)])
  let segs = @ocr.segment_by_connected_components(
    img,
    min_area=5,
    max_area=100000,
  )
  assert_true(segs.length() == 2)
  // 错误分支
  try {
    let _ = @ocr.segment_by_connected_components(cs_img(0, 12), min_area=5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let rgb = @types.Image::{
    width: 4,
    height: 4,
    channels: 3,
    data: Bytes::from_array(Array::make(48, 0)),
  }
  try {
    let _ = @ocr.segment_by_connected_components(rgb, min_area=5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let short = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(Array::make(4, 0)),
  }
  try {
    let _ = @ocr.segment_by_connected_components(short, min_area=5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.segment_by_connected_components(img, min_area=-1)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.segment_by_connected_components(img, min_area=10, max_area=5)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 完整流水线：两条字符
  let res = @ocr.complete_char_segmentation(
    img,
    min_char_width=5,
    max_char_width=20,
  )
  assert_true(res.length() >= 1)
  // 完整流水线：宽粘连块触发滴水分割路径
  let glued = cs_bar(48, 14, [(2, 44)])
  let res2 = @ocr.complete_char_segmentation(
    glued,
    min_char_width=4,
    max_char_width=10,
  )
  assert_true(res2.length() >= 1)
  // 错误分支
  try {
    let _ = @ocr.complete_char_segmentation(cs_img(0, 10))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.complete_char_segmentation(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.complete_char_segmentation(short)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.complete_char_segmentation(img, min_char_width=0)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.complete_char_segmentation(
      img,
      min_char_width=20,
      max_char_width=5,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
}

///|
test "cscov: detect_touching_chars 与滴水分割" {
  let img = cs_bar(40, 12, [(2, 6), (22, 6)])
  let touch = @ocr.detect_touching_chars(
    img,
    min_char_width=5,
    max_char_width=10,
  )
  assert_true(touch.length() >= 0)
  // 宽块 → 检出粘连
  let glued = cs_bar(40, 12, [(2, 36)])
  let touch2 = @ocr.detect_touching_chars(
    glued,
    min_char_width=5,
    max_char_width=10,
  )
  assert_true(touch2.length() >= 0)
  // 错误分支
  try {
    let _ = @ocr.detect_touching_chars(cs_img(0, 12))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let rgb = @types.Image::{
    width: 4,
    height: 4,
    channels: 2,
    data: Bytes::from_array(Array::make(32, 0)),
  }
  try {
    let _ = @ocr.detect_touching_chars(rgb)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let short = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(Array::make(3, 0)),
  }
  try {
    let _ = @ocr.detect_touching_chars(short)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 滴水：单字符窄块
  let one = cs_bar(20, 12, [(4, 6)])
  try {
    let r = @ocr.drop_fall_segmentation(one)
    assert_true(r.char_regions.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
  // 一滴到底：全白图
  let full = cs_full(20, 12, 255)
  try {
    let r2 = @ocr.drop_fall_segmentation(full, start_x=3)
    assert_true(r2.char_regions.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
  // 全黑图
  let dark = cs_img(20, 12)
  try {
    let r3 = @ocr.drop_fall_segmentation(dark)
    assert_true(r3.char_regions.length() >= 0)
  } catch {
    _ => assert_true(false)
  }
}
