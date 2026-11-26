// 覆盖率测试：人脸识别系统（配置 / 检测 / 特征 / 库 / 表情 / 年龄性别 / 质量 / 报告）

fn fa_img(w : Int32, h : Int32, c : Int32, d : Array[Byte]) -> @types.Image {
  @types.Image::{ width: w, height: h, channels: c, data: Bytes::from_array(d) }
}

fn fa_const(w : Int32, h : Int32, v : Byte) -> @types.Image {
  let d : Array[Byte] = []
  for _ in 0..<(w * h) {
    d.push(v)
  }
  fa_img(w, h, 1, d)
}

fn fa_gradient(w : Int32, h : Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push((x * 7 + y * 3).to_byte())
    }
  }
  fa_img(w, h, 1, d)
}

fn fa_face(bx : Double, by : Double, bw : Double, bh : Double) -> @face_recognition.FaceDetectionResult {
  @face_recognition.FaceDetectionResult::{
    bounding_box: [bx, by, bw, bh],
    confidence: 0.75,
    landmarks: [],
    num_landmarks: 0,
    face_id: 0,
    is_frontal: true,
    yaw: 0.0,
    pitch: 0.0,
    roll: 0.0,
  }
}

fn fa_ok(img : @types.Image) -> Bool {
  img.width > 0 && img.height > 0
}

test "facov: 配置与空库" {
  let cfg = @face_recognition.create_default_face_config()
  assert_true(cfg.detection_threshold == 0.7)
  assert_true(cfg.recognition_threshold == 0.5)
  assert_true(cfg.min_face_size == 40)
  assert_true(cfg.max_num_faces == 10)
  assert_true(cfg.use_landmarks)
  assert_true(cfg.feature_dimension == 512)
  let db = @face_recognition.create_face_database(@face_recognition.ArcFace, 0.5)
  assert_true(db.num_faces == 0)
  assert_true(db.faces.length() == 0)
  assert_true(db.threshold == 0.5)
  assert_true(db.algorithm == @face_recognition.ArcFace)
}

test "facov: 人脸检测" {
  let img = fa_gradient(64, 64)
  let cfg = @face_recognition.create_default_face_config()
  let faces = @face_recognition.detect_faces(img, cfg)
  assert_true(faces.length() == 1)
  assert_true(faces[0].bounding_box.length() == 4)
  assert_true(faces[0].num_landmarks == 5)
  assert_true(faces[0].landmarks.length() == 5)
  assert_true(faces[0].is_frontal)
  assert_true(faces[0].confidence > 0.0 && faces[0].confidence <= 1.0)
  // 小图（< 32 块）走默认中心
  let tiny = @face_recognition.detect_faces(fa_const(8, 8, b'\x80'), cfg)
  assert_true(tiny.length() == 1)
  assert_true(tiny[0].bounding_box[0] == 4.0 - 50.0)
  // 三类校验
  try {
    let _ = @face_recognition.detect_faces(fa_img(0, 4, 1, []), cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.detect_faces(fa_img(2, 2, 5, []), cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.detect_faces(fa_img(2, 2, 1, [b'\x00']), cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "facov: 特征提取与余弦相似度" {
  let img = fa_gradient(64, 64)
  let cfg = @face_recognition.create_default_face_config()
  let face = fa_face(10.0, 10.0, 20.0, 20.0)
  let f1 = @face_recognition.extract_face_feature(img, face, cfg)
  assert_true(f1.dimension == 512)
  assert_true(f1.vector.length() == 512)
  assert_true(f1.norm > 0.0)
  assert_true(!f1.is_normalized)
  // 自定义维度
  let cfg16 = @face_recognition.FaceRecognitionConfig::{
    detection_algorithm: @face_recognition.MTCNN,
    recognition_algorithm: @face_recognition.ArcFace,
    detection_threshold: 0.7,
    recognition_threshold: 0.5,
    min_face_size: 40,
    max_num_faces: 10,
    use_landmarks: true,
    use_alignment: true,
    feature_dimension: 16,
  }
  let f16 = @face_recognition.extract_face_feature(img, face, cfg16)
  assert_true(f16.dimension == 16)
  assert_true(f16.vector.length() == 16)
  // 超出边界的框：count 0 → mean 0，特征仍可生成
  let out = @face_recognition.extract_face_feature(img, fa_face(200.0, 200.0, 30.0, 30.0), cfg16)
  assert_true(out.vector.length() == 16)
  // 相似度
  let self_sim = @face_recognition.calculate_cosine_similarity(f1, f1)
  assert_true(self_sim > 0.99 && self_sim <= 1.0001)
  assert_true(@face_recognition.calculate_cosine_similarity(f1, f16) == 0.0)
  // 零范数特征 → 0
  let zero = @face_recognition.FaceFeature::{
    vector: [0.0, 0.0],
    dimension: 2,
    norm: 0.0,
    is_normalized: true,
  }
  let zero2 = @face_recognition.FaceFeature::{
    vector: [1.0, 1.0],
    dimension: 2,
    norm: 1.0,
    is_normalized: true,
  }
  assert_true(@face_recognition.calculate_cosine_similarity(zero, zero2) == 0.0)
  // 校验
  try {
    let _ = @face_recognition.extract_face_feature(fa_img(0, 4, 1, []), face, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.extract_face_feature(fa_img(2, 2, 5, []), face, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.extract_face_feature(fa_img(2, 2, 1, [b'\x00']), face, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "facov: 人脸库与识别" {
  let img = fa_gradient(64, 64)
  let cfg = @face_recognition.create_default_face_config()
  let face = fa_face(10.0, 10.0, 20.0, 20.0)
  let feat = @face_recognition.extract_face_feature(img, face, cfg)
  // 空库 → unknown
  let empty_db = @face_recognition.create_face_database(@face_recognition.ArcFace, 0.5)
  let r0 = @face_recognition.recognize_face_in_database(empty_db, feat, face.bounding_box)
  assert_true(!r0.is_known)
  assert_true(r0.identity == "unknown")
  assert_true(r0.matched_face_id == -1)
  // 加入库后同一特征 → 已知
  let db1 = @face_recognition.add_face_to_database(empty_db, feat, "alice")
  assert_true(db1.num_faces == 1)
  assert_true(db1.identities.length() == 1)
  assert_true(db1.identities[0] == "alice")
  let r1 = @face_recognition.recognize_face_in_database(db1, feat, face.bounding_box)
  assert_true(r1.is_known)
  assert_true(r1.identity == "alice")
  assert_true(r1.matched_face_id == 0)
  assert_true(r1.similarity > 0.99)
  assert_true(r1.bounding_box.length() == 4)
  // 再加一人：不同图像特征差距大，仍匹配到最相似者
  let img2 = fa_const(64, 64, b'\x40')
  let feat2 = @face_recognition.extract_face_feature(img2, face, cfg)
  let db2 = @face_recognition.add_face_to_database(db1, feat2, "bob")
  assert_true(db2.num_faces == 2)
  assert_true(db2.identities[1] == "bob")
  let r2 = @face_recognition.recognize_face_in_database(db2, feat2, face.bounding_box)
  assert_true(r2.is_known)
  assert_true(r2.identity == "bob")
  assert_true(r2.matched_face_id == 1)
  // 阈值 1.5（不可达）→ unknown，但 similarity 保留
  let strict = @face_recognition.create_face_database(@face_recognition.ArcFace, 1.5)
  let db3 = @face_recognition.add_face_to_database(strict, feat, "carol")
  let r3 = @face_recognition.recognize_face_in_database(db3, feat, face.bounding_box)
  assert_true(!r3.is_known)
  assert_true(r3.similarity > 0.99)
}

test "facov: 表情识别三分支" {
  let cfg = @face_recognition.create_default_face_config()
  ignore(cfg)
  let face = fa_face(8.0, 8.0, 32.0, 32.0)
  // 嘴部高亮 → happy
  let bright_d : Array[Byte] = []
  for y in 0..<64 {
    for x in 0..<64 {
      bright_d.push(if y >= 32 { b'\xFA' } else { b'\x80' })
    }
  }
  let bright = fa_img(64, 64, 1, bright_d)
  let happy = @face_recognition.recognize_expression(bright, face)
  assert_true(happy.expression == @face_recognition.Happy)
  assert_true(happy.dominant_expression == "happy")
  assert_true(happy.num_classes == 8)
  assert_true(happy.probabilities.length() == 8)
  // 嘴部暗 → sad
  let dark_d : Array[Byte] = []
  for y in 0..<64 {
    for x in 0..<64 {
      dark_d.push(if y >= 32 { b'\x10' } else { b'\x80' })
    }
  }
  let dark = fa_img(64, 64, 1, dark_d)
  let sad = @face_recognition.recognize_expression(dark, face)
  assert_true(sad.expression == @face_recognition.Sad)
  assert_true(sad.dominant_expression == "sad")
  // 中等亮度 → neutral
  let mid = @face_recognition.recognize_expression(fa_const(64, 64, b'\x80'), face)
  assert_true(mid.expression == @face_recognition.Neutral)
  assert_true(mid.dominant_expression == "neutral")
  assert_true(mid.confidence == 0.55)
  // 校验
  try {
    let _ = @face_recognition.recognize_expression(fa_img(0, 4, 1, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.recognize_expression(fa_img(2, 2, 5, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.recognize_expression(fa_img(2, 2, 1, [b'\x00']), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "facov: 年龄性别与质量评估" {
  let face = fa_face(8.0, 8.0, 32.0, 32.0)
  // 平坦脸：纹理 0 → 女性、年龄 20
  let flat = fa_const(64, 64, b'\x80')
  let ag = @face_recognition.estimate_age_gender(flat, face)
  assert_true(ag.age == 20.0)
  assert_true(ag.age_range.length() == 2)
  assert_true(ag.age_range[0] == 15.0)
  assert_true(ag.age_range[1] == 25.0)
  assert_true(ag.gender == "female")
  assert_true(!ag.is_male)
  // 纹理复杂图 → 男性、年龄更大
  let tex = @face_recognition.estimate_age_gender(fa_gradient(64, 64), face)
  assert_true(tex.age > 20.0)
  // 质量：暗且平坦 → 低分
  let q_dark = @face_recognition.evaluate_face_quality(flat, face)
  assert_true(q_dark >= 0.0 && q_dark <= 1.0)
  // 校验（三个函数共用同一组判断，各测一种）
  try {
    let _ = @face_recognition.estimate_age_gender(fa_img(0, 4, 1, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.estimate_age_gender(fa_img(2, 2, 5, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.evaluate_face_quality(fa_img(2, 2, 1, [b'\x00']), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.evaluate_face_quality(fa_img(0, 4, 1, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.evaluate_face_quality(fa_img(2, 2, 5, []), face)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "facov: 属性分析与报告" {
  let img = fa_gradient(64, 64)
  let cfg = @face_recognition.create_default_face_config()
  let face = fa_face(10.0, 10.0, 20.0, 20.0)
  let db = @face_recognition.create_face_database(@face_recognition.ArcFace, 0.0)
  let a = @face_recognition.analyze_face_attributes(img, face, db, cfg)
  assert_true(a.face_quality >= 0.0 && a.face_quality <= 1.0)
  assert_true(a.brightness >= 0.0)
  assert_true(a.occlusion_rate == 0.0)
  assert_true(a.detection.bounding_box.length() == 4)
  assert_true(a.age_gender.age >= 20.0)
  let report = @face_recognition.face_recognition_report_to_string(a)
  assert_true(report.contains("人脸识别与表情识别报告"))
  assert_true(report.contains("人脸检测"))
  assert_true(report.contains("人脸识别"))
  assert_true(report.contains("表情识别"))
  assert_true(report.contains("年龄性别估计"))
  assert_true(report.contains("unknown"))
  // 已知身份也出现在报告中
  let feat = @face_recognition.extract_face_feature(img, face, cfg)
  let db2 = @face_recognition.add_face_to_database(
    @face_recognition.create_face_database(@face_recognition.ArcFace, 0.0),
    feat,
    "alice",
  )
  let a2 = @face_recognition.analyze_face_attributes(img, face, db2, cfg)
  assert_true(a2.recognition.is_known)
  let report2 = @face_recognition.face_recognition_report_to_string(a2)
  assert_true(report2.contains("alice"))
  // 校验
  try {
    let _ = @face_recognition.analyze_face_attributes(fa_img(0, 4, 1, []), face, db, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.analyze_face_attributes(fa_img(2, 2, 5, []), face, db, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  try {
    let _ = @face_recognition.analyze_face_attributes(fa_img(2, 2, 1, [b'\x00']), face, db, cfg)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  assert_true(fa_ok(img))
}
