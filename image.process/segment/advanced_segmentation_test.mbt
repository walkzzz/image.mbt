///|
fn advseg_make_rgb(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = []
  for i in 0..<(w * h * 3) {
    data.push((i * 13 % 256).to_byte())
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 3,
    data: Bytes::from_array(data),
  }
}

///|
test "advanced_segmentation: kmeans / superpixel / watershed / grabcut" {
  let img = advseg_make_rgb(8, 8)
  try {
    let km = @segment.kmeans_segmentation(
      img,
      @segment.create_default_kmeans_config(),
    )
    assert_eq(km.width, 8)
    assert_eq(km.height, 8)
    let sp = @segment.superpixel_segmentation(img, 4)
    assert_true(sp.width > 0)
    let ws = @segment.watershed_segmentation(
      img,
      @segment.create_default_watershed_config(),
    )
    assert_eq(ws.width, 8)
    let gc = @segment.grabcut_segmentation(
      img,
      1,
      1,
      6,
      6,
      @segment.create_default_grabcut_config(),
    )
    assert_eq(gc.height, 8)
  } catch {
    _ => assert_true(false)
  }
}

///|
test "advanced_segmentation: 指标 / 可视化 / 报告" {
  let pred = [0, 0, 1, 1, 2, 2]
  let truth = [0, 0, 1, 2, 2, 2]
  let metrics = @segment.calculate_segmentation_metrics(pred, truth, 3)
  assert_true(metrics.pixel_accuracy >= 0.0)
  let img = advseg_make_rgb(4, 4)
  try {
    let res = @segment.kmeans_segmentation(
      img,
      @segment.create_default_kmeans_config(),
    )
    let vis = @segment.segmentation_to_image(res)
    assert_eq(vis.width, 4)
    let report = @segment.segmentation_report_to_string(res, metrics)
    assert_true(report.length() > 0)
  } catch {
    _ => assert_true(false)
  }
}
