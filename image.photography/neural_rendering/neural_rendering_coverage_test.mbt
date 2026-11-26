// 覆盖率测试：神经渲染与 3D 重建（射线 / 体渲染 / NeRF / 高斯泼溅 / 重建 / 报告）

///|
fn nr_cam(
  w : Int32,
  h : Int32,
  focal : Double,
) -> @neural_rendering.CameraParams {
  @neural_rendering.CameraParams::{
    position: [0.0, 0.0, 0.0],
    rotation: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0],
    focal_length: focal,
    principal_point: [w.to_double() / 2.0, h.to_double() / 2.0],
    image_width: w,
    image_height: h,
    near_plane: 0.1,
    far_plane: 100.0,
  }
}

///|
fn nr_voxel(
  occ : Bool,
  density : Double,
  r : Double,
) -> @neural_rendering.Voxel {
  @neural_rendering.Voxel::{
    position: [0.0, 0.0, 1.0],
    size: 0.1,
    density,
    color: [r, 0.0, 0.0],
    is_occupied: occ,
  }
}

///|
fn nr_gauss(x : Double, y : Double, r : Double) -> @neural_rendering.Gaussian3D {
  @neural_rendering.Gaussian3D::{
    position: [x, y, 0.0],
    rotation: [1.0, 0.0, 0.0, 0.0],
    scale: [0.1, 0.1, 0.1],
    opacity: 0.8,
    color: [r, 0.0, 0.0],
    sh_coefficients: [],
  }
}

///|
fn nr_grad_img(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(((x * 20 + y * 3) % 256).to_byte())
    }
  }
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(d),
  }
}

///|
fn nr_pt(
  x : Double,
  y : Double,
  z : Double,
  r : Double,
) -> @neural_rendering.Point3D {
  @neural_rendering.Point3D::{
    position: [x, y, z],
    color: [r, 10.0, 20.0],
    normal: [0.0, 0.0, 1.0],
    confidence: 0.5,
  }
}

///|
test "nrcov: 默认配置" {
  let nerf = @neural_rendering.create_default_nerf_config()
  assert_true(nerf.num_samples_per_ray == 64)
  assert_true(nerf.num_importance_samples == 128)
  assert_true(nerf.near_plane == 2.0)
  assert_true(nerf.far_plane == 6.0)
  assert_true(nerf.use_perturbation)
  assert_true(!nerf.use_white_background)
  let gs = @neural_rendering.create_default_gaussian_config()
  assert_true(gs.num_gaussians == 100000)
  assert_true(gs.sh_degree == 3)
  assert_true(gs.opacity_threshold == 0.005)
  assert_true(gs.scale_activation == "exp")
  let cam = @neural_rendering.create_default_camera()
  assert_true(cam.focal_length == 500.0)
  assert_true(cam.image_width == 640)
  assert_true(cam.image_height == 480)
  assert_true(cam.principal_point[0] == 320.0)
}

///|
test "nrcov: 射线生成" {
  let cam = nr_cam(2, 2, 2.0)
  let rays = @neural_rendering.generate_rays(cam)
  assert_true(rays.length() == 4)
  // 左上角：ndc = (0-1)/2 = -0.5
  assert_true(rays[0].direction.length() == 3)
  assert_true(rays[0].direction[0] == -0.5)
  assert_true(rays[0].direction[1] == -0.5)
  assert_true(rays[0].direction[2] == 1.0)
  assert_true(rays[0].t_min == 0.1)
  assert_true(rays[0].t_max == 100.0)
  assert_true(rays[0].origin.length() == 3)
  // 中心像素（1,1）：ndc 0
  assert_true(rays[3].direction[0] == 0.0)
  assert_true(rays[3].direction[1] == 0.0)
}

///|
test "nrcov: 体渲染" {
  let cfg = @neural_rendering.create_default_nerf_config()
  let ray = @neural_rendering.Ray::{
    origin: [0.0, 0.0, 0.0],
    direction: [0.0, 0.0, 1.0],
    t_min: 0.1,
    t_max: 100.0,
  }
  // 空样本
  let none : Array[@neural_rendering.Voxel] = []
  let (c0, a0) = @neural_rendering.volume_render(ray, none, cfg)
  assert_true(a0 == 0.0)
  assert_true(c0[0] == 0.0)
  // 未占据样本被跳过
  let skip = nr_voxel(false, 0.5, 200.0)
  let skips : Array[@neural_rendering.Voxel] = [skip]
  let (c1, a1) = @neural_rendering.volume_render(ray, skips, cfg)
  assert_true(a1 == 0.0)
  assert_true(c1[0] == 0.0)
  // 密度为 0 被跳过
  let zero_d = nr_voxel(true, 0.0, 200.0)
  let zeros : Array[@neural_rendering.Voxel] = [zero_d]
  let (_, a2) = @neural_rendering.volume_render(ray, zeros, cfg)
  assert_true(a2 == 0.0)
  // 单样本 density 1.0 → alpha_i 0.1 → 颜色 0.1*200 = 20
  let one = nr_voxel(true, 1.0, 200.0)
  let ones : Array[@neural_rendering.Voxel] = [one]
  let (c3, a3) = @neural_rendering.volume_render(ray, ones, cfg)
  assert_true(a3 > 0.09 && a3 < 0.11)
  assert_true(c3[0] > 19.0 && c3[0] < 21.0)
  // 两样本：0.1 + 0.9*0.1 = 0.19
  let two : Array[@neural_rendering.Voxel] = [one, one]
  let (c4, a4) = @neural_rendering.volume_render(ray, two, cfg)
  assert_true(a4 > 0.18 && a4 < 0.2)
  assert_true(c4[0] > 37.0 && c4[0] < 39.0)
}

///|
test "nrcov: NeRF 渲染" {
  let cam = nr_cam(4, 4, 2.0)
  let cfg = @neural_rendering.create_default_nerf_config()
  let r = @neural_rendering.render_nerf(cam, cfg)
  assert_true(r.image.width == 4)
  assert_true(r.image.channels == 3)
  assert_true(r.image.data.length() == 48)
  // 中心像素命中球体：200/100/50
  let mid = (2 * 4 + 2) * 3
  assert_true(r.image.data[mid].to_int() == 200)
  assert_true(r.image.data[mid + 1].to_int() == 100)
  assert_true(r.image.data[mid + 2].to_int() == 50)
  // 深度：球体 3.0*25 = 75，背景 10*25 = 250
  assert_true(r.depth_map.data[2 * 4 + 2].to_int() == 75)
  assert_true(r.depth_map.data[0].to_int() == 250)
  // 左上背景：t = -0.5 → r = 75, g = 125, b = 200
  assert_true(r.image.data[0].to_int() == 75)
  assert_true(r.image.data[1].to_int() == 125)
  assert_true(r.image.data[2].to_int() == 200)
  // 法线/透明度图为常量
  assert_true(r.normal_map.data[0].to_int() == 128)
  assert_true(r.alpha_map.data[0].to_int() == 255)
  assert_true(r.psnr == 0.0)
}

///|
test "nrcov: 高斯泼溅渲染" {
  let cam = nr_cam(4, 4, 2.0)
  let cfg = @neural_rendering.create_default_gaussian_config()
  // 无高斯 → 全黑（weight_sum 0 且不做归一）
  let empty : Array[@neural_rendering.Gaussian3D] = []
  let r0 = @neural_rendering.render_gaussian_splatting(cam, empty, cfg)
  assert_true(r0.image.data[0].to_int() == 0)
  assert_true(r0.image.width == 4)
  // 中心处高斯 → 归一化后返回原色 200
  let gs : Array[@neural_rendering.Gaussian3D] = [nr_gauss(0.0, 0.0, 200.0)]
  let r1 = @neural_rendering.render_gaussian_splatting(cam, gs, cfg)
  let mid = (2 * 4 + 2) * 3
  assert_true(r1.image.data[mid].to_int() == 200)
  // 深度图固定 128，透明度固定 255
  assert_true(r1.depth_map.data[0].to_int() == 128)
  assert_true(r1.alpha_map.data[0].to_int() == 255)
  // 远离中心（负权重）→ 钳到 0
  let far = nr_gauss(10.0, 10.0, 200.0)
  let fs : Array[@neural_rendering.Gaussian3D] = [far]
  let r2 = @neural_rendering.render_gaussian_splatting(cam, fs, cfg)
  assert_true(r2.image.data[0].to_int() == 0)
}

///|
test "nrcov: 示例高斯生成" {
  let none = @neural_rendering.generate_sample_gaussians(0)
  assert_true(none.length() == 0)
  let gs = @neural_rendering.generate_sample_gaussians(5)
  assert_true(gs.length() == 5)
  assert_true(gs[0].position.length() == 3)
  assert_true(gs[0].opacity == 0.8)
  assert_true(gs[0].scale[0] == 0.1)
  assert_true(gs[0].rotation[0] == 1.0)
  assert_true(gs[0].sh_coefficients.length() == 0)
  // 位置在 [-1, 1] 内
  assert_true(gs[0].position[0] >= -1.0 && gs[0].position[0] <= 1.0)
  assert_true(gs[4].color[0] >= 0.0 && gs[4].color[0] <= 255.0)
}

///|
test "nrcov: 多视图重建" {
  // 输入不足：空点云但保留元信息
  let one : Array[@types.Image] = [nr_grad_img(10, 10)]
  let cam = nr_cam(10, 10, 5.0)
  let cams_one : Array[@neural_rendering.CameraParams] = [cam]
  let r0 = @neural_rendering.multiview_stereo_reconstruction(one, cams_one)
  assert_true(r0.point_cloud.length() == 0)
  assert_true(r0.num_points == 0)
  assert_true(r0.num_cameras == 1)
  assert_true(r0.coverage == 0.6)
  assert_true(r0.accuracy == 0.7)
  // 双图双相机：40x40 上 10 的倍数位置（10,20,30）共 9 个点
  let imgs : Array[@types.Image] = [nr_grad_img(40, 40), nr_grad_img(40, 40)]
  let cams : Array[@neural_rendering.CameraParams] = [
    nr_cam(40, 40, 20.0),
    nr_cam(40, 40, 20.0),
  ]
  let r1 = @neural_rendering.multiview_stereo_reconstruction(imgs, cams)
  assert_true(r1.num_points == 9)
  assert_true(r1.point_cloud[0].confidence == 0.7)
  assert_true(r1.point_cloud[0].position[2] > 0.0)
  assert_true(r1.num_cameras == 2)
  // 相机不足
  let r2 = @neural_rendering.multiview_stereo_reconstruction(imgs, cams_one)
  assert_true(r2.point_cloud.length() == 0)
}

///|
test "nrcov: 点云可视化" {
  // 空点云 → 全黑
  let empty : Array[@neural_rendering.Point3D] = []
  let img = @neural_rendering.visualize_point_cloud(empty, 8, 8)
  assert_true(img.width == 8)
  assert_true(img.channels == 3)
  assert_true(img.data.length() == 192)
  assert_true(img.data[0].to_int() == 0)
  // 中心点：px = 0*500/5 + 4 = 4
  let pts : Array[@neural_rendering.Point3D] = [nr_pt(0.0, 0.0, 5.0, 10.0)]
  let img2 = @neural_rendering.visualize_point_cloud(pts, 8, 8)
  let idx = (4 * 8 + 4) * 3
  assert_true(img2.data[idx].to_int() == 10)
  assert_true(img2.data[idx + 1].to_int() == 10)
  assert_true(img2.data[idx + 2].to_int() == 20)
  // z <= 0.1 跳过
  let behind : Array[@neural_rendering.Point3D] = [nr_pt(0.0, 0.0, 0.0, 99.0)]
  let img3 = @neural_rendering.visualize_point_cloud(behind, 8, 8)
  assert_true(img3.data[(4 * 8 + 4) * 3].to_int() == 0)
  // 投影到画布外 → 跳过
  let outside : Array[@neural_rendering.Point3D] = [
    nr_pt(1000.0, 0.0, 1.0, 99.0),
  ]
  let img4 = @neural_rendering.visualize_point_cloud(outside, 8, 8)
  assert_true(img4.data[0].to_int() == 0)
}

///|
test "nrcov: 报告" {
  let cam = nr_cam(2, 2, 2.0)
  let cfg = @neural_rendering.create_default_nerf_config()
  let res = @neural_rendering.render_nerf(cam, cfg)
  let r1 = @neural_rendering.neural_rendering_report_to_string(
    res,
    @neural_rendering.NeuralRenderingAlgorithm::NeRF,
  )
  assert_true(r1.contains("神经渲染报告"))
  assert_true(r1.contains("NeRF"))
  assert_true(r1.contains("2x2"))
  let r2 = @neural_rendering.neural_rendering_report_to_string(
    res,
    @neural_rendering.NeuralRenderingAlgorithm::GaussianSplatting,
  )
  assert_true(r2.contains("3D 高斯泼溅"))
  let r3 = @neural_rendering.neural_rendering_report_to_string(
    res,
    @neural_rendering.NeuralRenderingAlgorithm::InstantNGP,
  )
  assert_true(r3.contains("Instant-NGP"))
  let r4 = @neural_rendering.neural_rendering_report_to_string(
    res,
    @neural_rendering.NeuralRenderingAlgorithm::TensoRF,
  )
  assert_true(r4.contains("TensoRF"))
  let r5 = @neural_rendering.neural_rendering_report_to_string(
    res,
    @neural_rendering.NeuralRenderingAlgorithm::Unknown,
  )
  assert_true(r5.contains("未知"))
  // 重建报告
  let imgs : Array[@types.Image] = []
  let cams : Array[@neural_rendering.CameraParams] = []
  let rec = @neural_rendering.multiview_stereo_reconstruction(imgs, cams)
  let q1 = @neural_rendering.reconstruction_report_to_string(
    rec,
    @neural_rendering.ReconstructionAlgorithm::MultiViewStereo,
  )
  assert_true(q1.contains("3D 重建报告"))
  assert_true(q1.contains("多视图立体"))
  assert_true(q1.contains("60"))
  let q2 = @neural_rendering.reconstruction_report_to_string(
    rec,
    @neural_rendering.ReconstructionAlgorithm::StructureFromMotion,
  )
  assert_true(q2.contains("运动恢复结构"))
  let q3 = @neural_rendering.reconstruction_report_to_string(
    rec,
    @neural_rendering.ReconstructionAlgorithm::PhotometricStereo,
  )
  assert_true(q3.contains("光度立体"))
  let q4 = @neural_rendering.reconstruction_report_to_string(
    rec,
    @neural_rendering.ReconstructionAlgorithm::Unknown,
  )
  assert_true(q4.contains("未知"))
}
