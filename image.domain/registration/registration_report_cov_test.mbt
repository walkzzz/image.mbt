// 覆盖率测试：配准与检索报告中的枚举名称映射

fn rpc_img(w : Int32, h : Int32) -> @types.Image {
  let data : Array[Byte] = Array::make(w * h, b'\x10')
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(data) }
}

fn rpc_result(
  a : @registration.RegistrationAlgorithm,
  t : @registration.TransformType,
) -> @registration.RegistrationResultAdvanced {
  @registration.RegistrationResultAdvanced::{
    registered_image: rpc_img(4, 4),
    algorithm: a,
    transform_type: t,
    transform_matrix: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0],
    translation_x: 1.0,
    translation_y: 2.0,
    rotation_angle: 0.0,
    scale_x: 1.0,
    scale_y: 1.0,
    correlation: 0.9,
    mutual_information: 1.5,
    rmse: 0.1,
    processing_time_ms: 3.0,
    num_feature_points: 10,
    num_inliers: 8,
  }
}

///|
test "rpc: 配准算法与变换名称全枚举" {
  let algos : Array[@registration.RegistrationAlgorithm] = [
    @registration.RegistrationAlgorithm::PhaseCorrelation,
    @registration.RegistrationAlgorithm::FeatureBased,
    @registration.RegistrationAlgorithm::IntensityBased,
    @registration.RegistrationAlgorithm::MutualInformation,
    @registration.RegistrationAlgorithm::NormalizedCrossCorrelation,
  ]
  for a in algos {
    let text = @registration.registration_report_to_string_advanced(
      rpc_result(a, @registration.TransformType::Translation),
    )
    assert_true(text.length() > 0)
  }
  let transforms : Array[@registration.TransformType] = [
    @registration.TransformType::Translation,
    @registration.TransformType::Rigid,
    @registration.TransformType::Similarity,
    @registration.TransformType::Affine,
    @registration.TransformType::Perspective,
    @registration.TransformType::Polynomial,
  ]
  for t in transforms {
    let text = @registration.registration_report_to_string_advanced(
      rpc_result(@registration.RegistrationAlgorithm::PhaseCorrelation, t),
    )
    assert_true(text.contains("配准"))
  }
}


