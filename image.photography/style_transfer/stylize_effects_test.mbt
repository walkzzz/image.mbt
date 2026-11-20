///|
fn styl_make_rgb(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push((i * 11 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "stylize: 油画/素描/水彩/卡通" {
  let img = styl_make_rgb(8, 8)
  let oil = @style_transfer.oil_paint(img, radius=2, intensity=10)
  assert_eq(oil.width, 8)
  assert_eq(oil.channels, 3)
  assert_eq(@style_transfer.sketch(img).width, 8)
  assert_eq(@style_transfer.watercolor(img).height, 8)
  assert_eq(
    @style_transfer.cartoon(img, levels=8, edge_threshold=30.0).channels,
    3,
  )
  assert_true(@style_transfer.stylize_default_config().oil_paint_radius > 0)
}

///|
test "stylize: style 分派与自定义配置" {
  let img = styl_make_rgb(8, 8)
  let cfg = @style_transfer.stylize_default_config()
  try {
    let s1 = @style_transfer.stylize(img, "oil")
    assert_eq(s1.width, 8)
    let s2 = @style_transfer.stylize(img, "sketch", config=cfg)
    assert_eq(s2.channels, 3)
  } catch {
    _ => assert_true(false)
  }
}
