// 覆盖率测试：文档理解（版面分析 / 阅读顺序 / 标题正文提取 / 结构统计 / 多栏）

fn duc_img(w : Int32, h : Int32, f : (Int32, Int32) -> Int32) -> @types.Image {
  let d : Array[Byte] = []
  for y in 0..<h {
    for x in 0..<w {
      d.push(f(x, y).to_byte())
    }
  }
  @types.Image::{ width: w, height: h, channels: 1, data: Bytes::from_array(d) }
}

fn duc_page() -> @types.Image {
  // 200x200：标题行 20..54（高 35），正文行 80..90 / 110..120
  duc_img(200, 200, fn(x, y) {
    let title = y >= 20 && y < 55 && x >= 20 && x < 180
    let body1 = y >= 80 && y < 91 && x >= 20 && x < 180
    let body2 = y >= 110 && y < 121 && x >= 20 && x < 180
    if title || body1 || body2 { 0 } else { 255 }
  })
}

fn duc_elem(
  kind : @ocr.DocumentElementType,
  x : Int32,
  y : Int32,
  text : String,
  size : Int32,
) -> @ocr.DocumentElement {
  @ocr.DocumentElement::{
    element_type: kind,
    x,
    y,
    width: 10,
    height: size,
    text,
    confidence: 0.9,
    font_size: size,
    font_weight: "normal",
    reading_order: 0,
  }
}

fn duc_struct(elements : Array[@ocr.DocumentElement]) -> @ocr.DocumentStructure {
  @ocr.DocumentStructure::{
    elements,
    num_elements: elements.length(),
    title: "",
    num_headings: 0,
    num_paragraphs: 0,
    reading_order: [],
    bounding_box: (0, 0, 0, 0),
  }
}

test "ducov: 版面分析流水线" {
  let page = duc_page()
  let st = @ocr.analyze_document_layout(page)
  assert_true(st.num_elements == st.elements.length())
  assert_true(st.num_elements >= 1)
  assert_true(st.reading_order.length() == st.elements.length())
  assert_true(st.elements.length() >= 1)
  let e0 = st.elements[0]
  assert_true(e0.confidence == 0.8)
  assert_true(e0.x >= 0 && e0.y >= 0)
  assert_true(e0.width > 0 && e0.height > 0)
  assert_true(e0.font_size == e0.height)
  assert_true(e0.font_weight == "normal" || e0.font_weight == "bold")
  assert_true(st.bounding_box.2 >= 0)
  assert_true(st.bounding_box.3 >= 0)
  // 空白页：预处理可能留下噪点，只要求一致性与无标题
  let blank = duc_img(64, 64, fn(_x, _y) { 255 })
  let sb = @ocr.analyze_document_layout(blank)
  assert_true(sb.num_elements == sb.elements.length())
  assert_true(sb.title == "")
  // 校验
  try {
    let _ = @ocr.analyze_document_layout(duc_img(0, 8, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 8,
    height: 8,
    channels: 5,
    data: Bytes::from_array(Array::make(320, b'\x00')),
  }
  try {
    let _ = @ocr.analyze_document_layout(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_data = @types.Image::{
    width: 8,
    height: 8,
    channels: 1,
    data: Bytes::from_array([b'\x00']),
  }
  try {
    let _ = @ocr.analyze_document_layout(bad_data)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

test "ducov: 阅读顺序与标题提取" {
  // 乱序元素 → 按 (y, x) 排序
  let elems : Array[@ocr.DocumentElement] = [
    duc_elem(@ocr.DocumentElementType::Body, 50, 100, "c", 12),
    duc_elem(@ocr.DocumentElementType::Title, 20, 10, "大标题", 30),
    duc_elem(@ocr.DocumentElementType::Body, 20, 100, "b", 12),
    duc_elem(@ocr.DocumentElementType::Header, 10, 10, "页眉", 12),
  ]
  let order = @ocr.compute_reading_order(elems)
  assert_true(order.length() == 4)
  // 第 0 位应是 y=10 且 x=10 的页眉，第 1 位是 x=20 的标题
  assert_true(order[0] == 3)
  assert_true(order[1] == 1)
  assert_true(order[2] == 2)
  assert_true(order[3] == 0)
  // 空列表报错
  let empty : Array[@ocr.DocumentElement] = []
  try {
    let _ = @ocr.compute_reading_order(empty)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 标题：优先 Title
  let st1 = duc_struct(elems)
  assert_true(@ocr.extract_title(st1) == "大标题")
  // 无 Title 但有大字号 → 该元素
  let elems2 : Array[@ocr.DocumentElement] = [
    duc_elem(@ocr.DocumentElementType::Body, 0, 0, "正文", 12),
    duc_elem(@ocr.DocumentElementType::Body, 0, 20, "大字号", 26),
  ]
  assert_true(@ocr.extract_title(duc_struct(elems2)) == "大字号")
  // 都没有 → 空串
  let elems3 : Array[@ocr.DocumentElement] = [
    duc_elem(@ocr.DocumentElementType::Body, 0, 0, "正文", 12),
  ]
  assert_true(@ocr.extract_title(duc_struct(elems3)) == "")
}

test "ducov: 标题/正文/阅读顺序/统计" {
  let elems : Array[@ocr.DocumentElement] = [
    duc_elem(@ocr.DocumentElementType::Title, 0, 0, "题目", 30),
    duc_elem(@ocr.DocumentElementType::Heading1, 0, 40, "一级", 20),
    duc_elem(@ocr.DocumentElementType::Heading2, 0, 60, "二级", 16),
    duc_elem(@ocr.DocumentElementType::Heading3, 0, 80, "三级", 14),
    duc_elem(@ocr.DocumentElementType::Body, 0, 100, "正文1", 12),
    duc_elem(@ocr.DocumentElementType::Body, 0, 120, "正文2", 12),
    duc_elem(@ocr.DocumentElementType::List, 0, 140, "列表", 12),
    duc_elem(@ocr.DocumentElementType::Image, 0, 160, "", 50),
    duc_elem(@ocr.DocumentElementType::Caption, 0, 200, "图注", 10),
  ]
  let headings = @ocr.extract_headings(duc_struct(elems))
  assert_true(headings.length() == 4)
  let paragraphs = @ocr.extract_paragraphs(duc_struct(elems))
  assert_true(paragraphs.length() == 2)
  // 阅读顺序取元素（含越界索引跳过）
  let st = @ocr.DocumentStructure::{
    elements: elems,
    num_elements: elems.length(),
    title: "题目",
    num_headings: 3,
    num_paragraphs: 2,
    reading_order: [2, 0, 99],
    bounding_box: (0, 0, 10, 500),
  }
  let ordered = @ocr.get_elements_in_reading_order(st)
  assert_true(ordered.length() == 2)
  assert_true(ordered[0].text == "二级")
  assert_true(ordered[1].text == "题目")
  // 统计
  let (t, h, p, l, i) = @ocr.document_structure_stats(st)
  assert_true(t == 1)
  assert_true(h == 3)
  assert_true(p == 2)
  assert_true(l == 1)
  assert_true(i == 1)
}

test "ducov: 多栏检测与完整理解" {
  let page = duc_page()
  let cols = @ocr.detect_document_columns(page)
  assert_true(cols >= 1)
  // 双栏：左右两块中间留白
  let two = duc_img(200, 100, fn(x, y) {
    let left = x >= 10 && x < 80 && y >= 20 && y < 80
    let right = x >= 120 && x < 190 && y >= 20 && y < 80
    if left || right { 0 } else { 255 }
  })
  let cols2 = @ocr.detect_document_columns(two)
  assert_true(cols2 >= 1)
  // 校验
  try {
    let _ = @ocr.detect_document_columns(duc_img(0, 8, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  let bad_ch = @types.Image::{
    width: 8,
    height: 8,
    channels: 5,
    data: Bytes::from_array(Array::make(320, b'\x00')),
  }
  try {
    let _ = @ocr.detect_document_columns(bad_ch)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 完整流水线
  let st = @ocr.understand_document(page)
  assert_true(st.num_elements >= 1)
  assert_true(st.reading_order.length() == st.num_elements)
  assert_true(st.num_elements == st.elements.length())
  // 空白页：预处理可能留下噪点，只要求结构自洽
  let blank = duc_img(32, 32, fn(_x, _y) { 255 })
  let s2 = @ocr.understand_document(blank)
  assert_true(s2.num_elements == s2.elements.length())
  assert_true(s2.title == "")
  // 输入校验
  try {
    let _ = @ocr.understand_document(duc_img(0, 8, fn(_x, _y) { 0 }))
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}
