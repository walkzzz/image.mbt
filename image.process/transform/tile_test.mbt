///|
/// 分块 / 预算缩略图测试：面积平均采样、等比尺寸、零上采样、预算拒绝、大图低内存。

///|
fn solid(w : Int32, h : Int32, ch : Int32, v : Byte) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h * ch, v)
  @types.Image::{
    width: w,
    height: h,
    channels: ch,
    data: Bytes::from_array(data),
  }
}

///|
fn pixel(img : @types.Image, x : Int32, y : Int32, c : Int32) -> Byte {
  img.data[(y * img.width + x) * img.channels + c]
}

///|
test "tile: 面积平均 = 2x2 块各自的灰度" {
  // 4x4 灰度，四个 2x2 块分别 10 / 20 / 30 / 40
  let data : Array[Byte] = Array::make(16, b'\x00')
  for y in 0..<4 {
    for x in 0..<4 {
      let v = if y < 2 {
        if x < 2 {
          10
        } else {
          20
        }
      } else if x < 2 {
        30
      } else {
        40
      }
      data[y * 4 + x] = v.to_byte()
    }
  }
  let img = @types.Image::{
    width: 4,
    height: 4,
    channels: 1,
    data: Bytes::from_array(data),
  }
  let t = @transform.resize_subsample(img, 2, 2)
  assert_eq(t.width, 2)
  assert_eq(t.height, 2)
  assert_eq(pixel(t, 0, 0, 0), b'\x0a')
  assert_eq(pixel(t, 1, 0, 0), b'\x14')
  assert_eq(pixel(t, 0, 1, 0), b'\x1e')
  assert_eq(pixel(t, 1, 1, 0), b'\x28')
}

///|
test "tile: 同尺寸重采样等价于原图" {
  let img = solid(8, 6, 3, b'\x07')
  let t = @transform.resize_subsample(img, 8, 6)
  assert_eq(t.width, 8)
  assert_eq(t.height, 6)
  assert_eq(t.data.length(), img.data.length())
  for i in 0..<img.data.length() {
    assert_eq(t.data[i], img.data[i])
  }
}

///|
test "tile: 上采样退化为最近邻且尺寸正确" {
  let img = solid(2, 2, 3, b'\x33')
  let t = @transform.resize_subsample(img, 6, 6)
  assert_eq(t.width, 6)
  assert_eq(t.height, 6)
  assert_eq(t.data.length(), 6 * 6 * 3)
  for i in 0..<t.data.length() {
    assert_eq(t.data[i], b'\x33')
  }
}

///|
test "tile: 等比缩略图尺寸（长边压到 max_side）" {
  let (w1, h1) = @transform.thumbnail_dims(800, 400, 200)
  assert_eq(w1, 200)
  assert_eq(h1, 100)
  let (w2, h2) = @transform.thumbnail_dims(400, 800, 200)
  assert_eq(w2, 100)
  assert_eq(h2, 200)
  // 极端窄图至少保留 1 像素
  let (w3, h3) = @transform.thumbnail_dims(4000, 1, 512)
  assert_eq(w3, 512)
  assert_eq(h3, 1)
}

///|
test "tile: 小图不放大、零分配" {
  let img = solid(100, 50, 3, b'\x11')
  let t = @transform.thumbnail(img, 512)
  assert_eq(t.width, 100)
  assert_eq(t.height, 50)
  assert_eq(t.data.length(), img.data.length())
}

///|
test "tile: 大图出缩略图——4000x3000 -> 512 长边" {
  let img = solid(4000, 3000, 3, b'\x2a')
  let t = @transform.thumbnail(img, 512)
  assert_eq(t.width, 512)
  assert_eq(t.height, 384)
  // 唯一分配就是输出：512*384*3 = 589,824 B（底图 36,000,000 B 未被复制）
  assert_eq(t.data.length(), 512 * 384 * 3)
  assert_eq(pixel(t, 0, 0, 0), b'\x2a')
  assert_eq(pixel(t, 511, 383, 2), b'\x2a')
}

///|
test "tile: 输出超预算直接拒绝（不分配）" {
  let img = solid(800, 400, 3, b'\x01')
  // 预算 1000 B，而 200x100x3 = 60,000 B
  let budget : @types.AllocBudget = { max_bytes: 1000L, }
  let rejected = try {
    let _ = @transform.thumbnail_budgeted(img, 200, budget)
    false
  } catch {
    @types.ImageError::Budget(code, _) => code == @types.ErrorCode::LimitBytes
    _ => false
  }
  assert_true(rejected)
}

///|
test "tile: 预算内正常出图" {
  let img = solid(800, 400, 3, b'\x05')
  let t = @transform.thumbnail_budgeted(
    img,
    200,
    @types.AllocBudget::default_budget(),
  )
  assert_eq(t.width, 200)
  assert_eq(t.height, 100)
  assert_eq(t.data.length(), 200 * 100 * 3)
}

///|
test "tile: 非法参数被拒" {
  let img = solid(10, 10, 3, b'\x00')
  let bad = try {
    let _ = @transform.resize_subsample(img, 0, 5)
    false
  } catch {
    @types.LoadError::DecodeFailed(_) => true
    _ => false
  }
  assert_true(bad)
}
