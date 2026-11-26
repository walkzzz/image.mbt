// 覆盖率测试：检索报告中的特征类型名称映射

fn rqc_feat(t : @retrieval.FeatureType) -> @retrieval.CBIRImageFeature {
  @retrieval.CBIRImageFeature::{
    feature_type: t,
    feature_vector: [0.1, 0.2],
    feature_length: 2,
    image_id: "img-1",
    image_path: "/tmp/img.png",
    width: 4,
    height: 4,
    extraction_time_ms: 1.0,
  }
}

///|
test "rqc: 特征类型名称全枚举" {
  let types : Array[@retrieval.FeatureType] = [
    @retrieval.FeatureType::ColorHistogram,
    @retrieval.FeatureType::Texture,
    @retrieval.FeatureType::Shape,
    @retrieval.FeatureType::SIFT,
    @retrieval.FeatureType::HOG,
    @retrieval.FeatureType::LBP,
    @retrieval.FeatureType::Combined,
    @retrieval.FeatureType::Unknown,
    @retrieval.FeatureType::SURF,
  ]
  for t in types {
    let feat = rqc_feat(t)
    let empty : @retrieval.CBIRRetrievalResultList = {
      results: [],
      num_results: 0,
      query_image_id: "img-1",
      retrieval_time_ms: 1.0,
      total_images_in_index: 0,
    }
    let text = @retrieval.retrieval_report_to_string(empty, feat)
    assert_true(text.contains("img-1"))
  }
}
