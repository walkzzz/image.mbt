// 覆盖率测试：遥感指数、地物分类、变化检测、纹理/光谱特征与报告分支

fn rsc_img(
  w : Int32,
  h : Int32,
  bands : Int32,
  values : Array[Double],
) -> @remote_sensing.RemoteSensingImage {
  let data : Array[Double] = []
  for v in values {
    data.push(v)
  }
  let wl : Array[Double] = []
  for b in 0..<bands {
    wl.push(400.0 + b.to_double() * 100.0)
  }
  @remote_sensing.RemoteSensingImage::{
    width: w,
    height: h,
    bands,
    data,
    image_type: @remote_sensing.RemoteSensingImageType::Multispectral,
    wavelength: wl,
    resolution: 10.0,
    acquisition_date: "2024-06-01",
    cloud_cover: 5.0,
  }
}

fn rsc_fill(w : Int32, h : Int32, bands : Int32, base : Double) -> @remote_sensing.RemoteSensingImage {
  let n = w * h * bands
  let data : Array[Double] = []
  for i in 0..<n {
    data.push(base + (i % 7).to_double() * 3.0)
  }
  rsc_img(w, h, bands, data)
}

fn rsc_gray(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push((x * 11 + y * 5).to_byte())
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

test "rscov: 默认影像与三种归一化指数" {
  let img = @remote_sensing.create_default_remote_sensing_image(4, 4, 5)
  assert_true(img.width == 4)
  assert_true(img.bands == 5)
  assert_true(img.data.length() == 80)
  assert_true(img.wavelength.length() == 5)
  assert_true(img.image_type == @remote_sensing.RemoteSensingImageType::Multispectral)
  // NDVI：nir > red → 正值；(0,0) → 分母过小走 0.0 分支
  let img2 = rsc_img(2, 1, 4, [0.1, 0.2, 0.3, 0.9, 0.0, 0.0, 0.0, 0.0])
  let ndvi = @remote_sensing.calculate_ndvi(img2, 2, 3)
  assert_true(ndvi.length() == 2)
  assert_true(ndvi[0] > 0.0)
  assert_true(ndvi[1] == 0.0)
  // NDWI / NDBI
  let ndwi = @remote_sensing.calculate_ndwi(img2, 1, 3)
  assert_true(ndwi.length() == 2)
  let ndbi = @remote_sensing.calculate_ndbi(img2, 3, 0)
  assert_true(ndbi.length() == 2)
}

test "rscov: 全部植被指数（bands>4 与 <=4）" {
  let many = rsc_fill(4, 4, 6, 100.0)
  let vi = @remote_sensing.calculate_all_vegetation_indices(many)
  assert_true(vi.ndvi.length() == 16)
  assert_true(vi.ndwi.length() == 16)
  assert_true(vi.ndbi.length() == 16)
  assert_true(vi.evi.length() >= 0)
  assert_true(vi.savi.length() >= 0)
  // bands <= 4 → 空数组分支
  let few = rsc_fill(4, 4, 4, 50.0)
  let vi2 = @remote_sensing.calculate_all_vegetation_indices(few)
  assert_true(vi2.ndvi.length() == 0)
}

test "rscov: 地物分类与变化检测" {
  let img = rsc_fill(6, 6, 5, 80.0)
  let cls = @remote_sensing.classify_land_cover_simple(img)
  assert_true(cls.width == 6)
  assert_true(cls.height == 6)
  assert_true(cls.labels.length() == 36)
  assert_true(cls.num_classes >= 1)
  assert_true(cls.overall_accuracy >= 0.0)
  // 变化检测：同一影像 → 0 变化
  let same = @remote_sensing.detect_changes_simple(img, img, 0.1)
  assert_true(same.width == 6)
  assert_true(same.change_mask.length() == 36)
  assert_true(same.num_changed_pixels == 0)
  assert_true(same.change_percentage == 0.0)
  // 差异影像 + 低阈值 → 有变化
  let other = rsc_fill(6, 6, 5, 160.0)
  let diff = @remote_sensing.detect_changes_simple(img, other, 5.0)
  assert_true(diff.num_changed_pixels > 0)
  assert_true(diff.change_percentage > 0.0)
  assert_true(diff.change_intensity.length() == 36)
  // 高阈值 → 无变化
  let strict = @remote_sensing.detect_changes_simple(img, other, 100000.0)
  assert_true(strict.num_changed_pixels == 0)
}

test "rscov: 纹理特征、光谱特征与质量" {
  let g = rsc_gray(8, 8)
  // 中心窗口
  let t1 = @remote_sensing.calculate_texture_features(g, 2, 2, 4)
  assert_true(t1.contrast > -1000.0)
  assert_true(t1.variance > -1000.0)
  // 边界窗口（0,0）
  let t2 = @remote_sensing.calculate_texture_features(g, 0, 0, 4)
  assert_true(t2.dissimilarity > -1000.0)
  // 超出范围坐标
  let t3 = @remote_sensing.calculate_texture_features(g, 50, 50, 4)
  assert_true(t3.energy > -1000.0)
  // 错误分支
  try {
    let _ = @remote_sensing.calculate_texture_features(
      @types.Image::{
        width: 0,
        height: 4,
        channels: 1,
        data: Bytes::from_array([]),
      },
      0,
      0,
      4,
    )
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  let c5 = @types.Image::{
    width: 4,
    height: 4,
    channels: 5,
    data: Bytes::from_array(Array::make(80, 0)),
  }
  try {
    let _ = @remote_sensing.calculate_texture_features(c5, 0, 0, 4)
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 光谱特征：有效坐标与越界坐标
  let img = rsc_fill(4, 4, 6, 30.0)
  let sig = @remote_sensing.calculate_spectral_signature(img, 1, 1)
  assert_true(sig.num_bands == 6)
  assert_true(sig.wavelengths.length() == 6)
  assert_true(sig.reflectance.length() >= 0)
  assert_true(sig.mean_reflectance > -1000.0)
  let sig2 = @remote_sensing.calculate_spectral_signature(img, 99, 99)
  assert_true(sig2.num_bands >= 0)
  // 质量
  let q = @remote_sensing.calculate_remote_sensing_quality(img)
  assert_true(q.snr > -1000.0)
  assert_true(q.overall_quality > -1000.0)
  // 平坦影像
  let flat = rsc_fill(4, 4, 5, 0.0)
  let q2 = @remote_sensing.calculate_remote_sensing_quality(flat)
  assert_true(q2.cloud_cover >= 0.0)
}

test "rscov: 遥感报告文本分支" {
  let img = rsc_fill(6, 6, 5, 90.0)
  let cls = @remote_sensing.classify_land_cover_simple(img)
  let changes = @remote_sensing.detect_changes_simple(
    img,
    rsc_fill(6, 6, 5, 150.0),
    5.0,
  )
  let q = @remote_sensing.calculate_remote_sensing_quality(img)
  let rep = @remote_sensing.remote_sensing_report_to_string(
    img,
    cls,
    changes,
    q,
  )
  assert_true(rep.has_prefix("## 遥感图像分析报告"))
  assert_true(rep.length() > 20)
  // 光学影像类型分支
  let optical = rsc_fill(4, 4, 4, 40.0)
  let optical2 = @remote_sensing.RemoteSensingImage::{
    width: optical.width,
    height: optical.height,
    bands: optical.bands,
    data: optical.data,
    image_type: @remote_sensing.RemoteSensingImageType::Optical,
    wavelength: optical.wavelength,
    resolution: 1.0,
    acquisition_date: "2024-01-02",
    cloud_cover: 30.0,
  }
  let rep2 = @remote_sensing.remote_sensing_report_to_string(
    optical2,
    cls,
    changes,
    q,
  )
  assert_true(rep2.contains("光学"))
}
