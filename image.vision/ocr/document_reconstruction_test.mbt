// 覆盖率测试：文档重建（符号 / 图片区域 / 元素分类 / 表格 / 阅读顺序 / 文档组装）

///|
fn dr_block(
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  text : String,
) -> @ocr.TextBlock {
  @ocr.TextBlock::{
    x,
    y,
    width: w,
    height: h,
    block_type: "text",
    text,
    confidence: 0.9,
    reading_order: 0,
  }
}

///|
fn dr_element(
  kind : @ocr.MarkdownElementType,
  x : Int32,
  y : Int32,
  content : String,
) -> @ocr.MarkdownElement {
  @ocr.MarkdownElement::{
    element_type: kind,
    x,
    y,
    width: 100,
    height: 20,
    content,
    confidence: 0.9,
  }
}

///|
fn dr_canvas(w : Int32, h : Int32) -> Array[Byte] {
  let out : Array[Byte] = []
  for _ in 0..<(w * h) {
    out.push(b'\xFF')
  }
  out
}

///|
fn dr_set(out : Array[Byte], w : Int32, x : Int32, y : Int32, v : Byte) -> Unit {
  out[y * w + x] = v
}

///|
fn dr_image(w : Int32, h : Int32, data : Array[Byte]) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: 1,
    data: Bytes::from_array(data),
  }
}

///|
test "dr: 符号识别" {
  let empty = @ocr.recognize_symbols_markdown("")
  assert_true(empty.length() == 0)
  let all = @ocr.recognize_symbols_markdown("任意文本")
  assert_true(all.length() == 47)
  assert_true(all[0].confidence > 0.0)
  assert_true(all[0].unicode.length() > 0)
}

///|
test "dr: 图片区域检测（实心 / 半填充 / 稀疏）" {
  let w = 60
  let h = 60
  // 实心 40x40 → 填充率 1.0 → diagram
  let filled = dr_canvas(w, h)
  for y in 10..<50 {
    for x in 5..<45 {
      dr_set(filled, w, x, y, b'\x00')
    }
  }
  let r1 = @ocr.detect_image_regions_markdown(dr_image(w, h, filled))
  assert_true(r1.length() == 1)
  assert_eq(r1[0].width, 40)
  assert_eq(r1[0].height, 40)
  assert_true(r1[0].image_type == "diagram")
  // 底部实心 25 行 + 顶上一行细线：填充率约 0.74 -> chart
  let chart = dr_canvas(w, h)
  for y in 15..<40 {
    for x in 5..<45 {
      dr_set(chart, w, x, y, b'\x00')
    }
  }
  for x in 5..<45 {
    dr_set(chart, w, x, 5, b'\x00')
  }
  // 竖向连接线，保证两个块连通成同一区域
  for y in 5..<15 {
    dr_set(chart, w, 5, y, b'\x00')
  }
  let r2 = @ocr.detect_image_regions_markdown(dr_image(w, h, chart))
  assert_true(r2.length() == 1)
  assert_true(r2[0].image_type == "chart")
  // 4px 厚的空心方框：面积 576、填充率 0.36 -> photo
  let sparse = dr_canvas(w, h)
  for y in 5..<45 {
    for x in 5..<45 {
      if x < 9 || x >= 41 || y < 9 || y >= 41 {
        dr_set(sparse, w, x, y, b'\x00')
      }
    }
  }
  let r3 = @ocr.detect_image_regions_markdown(dr_image(w, h, sparse))
  assert_true(r3.length() >= 1)
  assert_true(r3[0].image_type == "photo")
  // min_area 过滤
  let r4 = @ocr.detect_image_regions_markdown(
    dr_image(w, h, filled),
    min_area=100000,
  )
  assert_true(r4.length() == 0)
}

///|
test "dr: 图片区域检测校验错误" {
  // 零尺寸
  try {
    let _ = @ocr.detect_image_regions_markdown(dr_image(0, 4, []))
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 非单通道
  let rgb : Array[Byte] = []
  for _ in 0..<16 {
    rgb.push(b'\x00')
  }
  let img3 = @types.Image::{
    width: 2,
    height: 2,
    channels: 3,
    data: Bytes::from_array(rgb),
  }
  try {
    let _ = @ocr.detect_image_regions_markdown(img3)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 数据大小不匹配
  let img2 = dr_image(4, 4, [b'\x00', b'\x00'])
  try {
    let _ = @ocr.detect_image_regions_markdown(img2)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 非法 min_area
  let ok = dr_image(4, 4, [
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  try {
    let _ = @ocr.detect_image_regions_markdown(ok, min_area=0)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "dr: 元素类型分类" {
  // 高度 64 / 字号 16 = 4 且 y<100 → 标题
  let title = @ocr.classify_markdown_element(dr_block(0, 10, 300, 64, "T"))
  assert_true(title == @ocr.MarkdownElementType::Title)
  // 同样字号但 y>=100 → Heading1
  let h1b = @ocr.classify_markdown_element(dr_block(0, 200, 300, 64, "T"))
  assert_true(h1b == @ocr.MarkdownElementType::Heading1)
  let h1 = @ocr.classify_markdown_element(dr_block(0, 10, 300, 40, "H1"))
  assert_true(h1 == @ocr.MarkdownElementType::Heading1)
  let h2 = @ocr.classify_markdown_element(dr_block(0, 10, 300, 28, "H2"))
  assert_true(h2 == @ocr.MarkdownElementType::Heading2)
  let h3 = @ocr.classify_markdown_element(dr_block(0, 10, 300, 20, "H3"))
  assert_true(h3 == @ocr.MarkdownElementType::Heading3)
  // 扁而宽 → 分隔线
  let hr = @ocr.classify_markdown_element(dr_block(0, 10, 200, 4, "---"))
  assert_true(hr == @ocr.MarkdownElementType::HorizontalRule)
  // 普通段落
  let p = @ocr.classify_markdown_element(dr_block(0, 10, 300, 16, "body"))
  assert_true(p == @ocr.MarkdownElementType::Paragraph)
  // 自定义平均字号：32 → 32/32 = 1 → 段落
  let big = @ocr.classify_markdown_element(
    dr_block(0, 10, 300, 32, "b"),
    avg_font_size=32.0,
  )
  assert_true(big == @ocr.MarkdownElementType::Paragraph)
}

///|
test "dr: 表格转 Markdown" {
  let cells : Array[Array[String]] = [["a", "b"], ["1", "2"]]
  let with_header = @ocr.MarkdownTable::{
    rows: 2,
    cols: 2,
    cells,
    has_header: true,
  }
  let md1 = @ocr.markdown_table_to_string(with_header)
  assert_true(md1 == "| a | b | \n| --- | --- | \n| 1 | 2 | \n")
  let no_header = @ocr.MarkdownTable::{
    rows: 2,
    cols: 2,
    cells,
    has_header: false,
  }
  let md2 = @ocr.markdown_table_to_string(no_header)
  assert_true(md2 == "| a | b | \n| 1 | 2 | \n")
  // 行数少于 cells → 缺列补空
  let ragged : Array[Array[String]] = [["a", "b"], ["only"]]
  let r1 = @ocr.MarkdownTable::{
    rows: 3,
    cols: 2,
    cells: ragged,
    has_header: true,
  }
  let md3 = @ocr.markdown_table_to_string(r1)
  assert_true(md3.length() > 0)
  // 空表
  let empty_cells : Array[Array[String]] = []
  let e0 = @ocr.MarkdownTable::{
    rows: 0,
    cols: 2,
    cells: empty_cells,
    has_header: true,
  }
  assert_true(@ocr.markdown_table_to_string(e0) == "")
}

///|
test "dr: 阅读顺序" {
  // 同一行（y 差 < 20）按 x 升序
  let els : Array[@ocr.MarkdownElement] = [
    dr_element(@ocr.MarkdownElementType::Paragraph, 200, 10, "b"),
    dr_element(@ocr.MarkdownElementType::Paragraph, 10, 10, "a"),
  ]
  let order = @ocr.determine_reading_order_markdown(els)
  assert_true(order.length() == 2)
  assert_eq(order[0], 1)
  assert_eq(order[1], 0)
  // 不同行按 y 升序
  let els2 : Array[@ocr.MarkdownElement] = [
    dr_element(@ocr.MarkdownElementType::Paragraph, 0, 300, "c"),
    dr_element(@ocr.MarkdownElementType::Paragraph, 0, 100, "a"),
    dr_element(@ocr.MarkdownElementType::Paragraph, 0, 200, "b"),
  ]
  let o2 = @ocr.determine_reading_order_markdown(els2)
  assert_eq(o2[0], 1)
  assert_eq(o2[1], 2)
  assert_eq(o2[2], 0)
  // 空输入
  let empty : Array[@ocr.MarkdownElement] = []
  assert_true(@ocr.determine_reading_order_markdown(empty).length() == 0)
}

///|
test "dr: 文档转 Markdown 覆盖全部元素类型" {
  let kinds : Array[@ocr.MarkdownElementType] = [
    @ocr.MarkdownElementType::Title,
    @ocr.MarkdownElementType::Heading1,
    @ocr.MarkdownElementType::Heading2,
    @ocr.MarkdownElementType::Heading3,
    @ocr.MarkdownElementType::Paragraph,
    @ocr.MarkdownElementType::ListItem,
    @ocr.MarkdownElementType::Table,
    @ocr.MarkdownElementType::Image,
    @ocr.MarkdownElementType::Quote,
    @ocr.MarkdownElementType::CodeBlock,
    @ocr.MarkdownElementType::HorizontalRule,
    @ocr.MarkdownElementType::PageBreak,
    @ocr.MarkdownElementType::Unknown,
  ]
  let els : Array[@ocr.MarkdownElement] = []
  let order : Array[Int32] = []
  for i in 0..<kinds.length() {
    els.push(dr_element(kinds[i], 0, i * 30, "x"))
    order.push(i)
  }
  let tables : Array[@ocr.MarkdownTable] = []
  let images : Array[@ocr.MarkdownImage] = []
  let symbols : Array[@ocr.MarkdownSymbol] = []
  let doc = @ocr.MarkdownDocument::{
    title: "Doc",
    elements: els,
    tables,
    images,
    symbols,
    reading_order: order,
  }
  let md = @ocr.markdown_document_to_string(doc)
  assert_true(md.length() > 0)
  // 无标题版本
  let doc2 = @ocr.MarkdownDocument::{
    title: "",
    elements: els,
    tables,
    images,
    symbols,
    reading_order: order,
  }
  // 无标题时首元素仍是 Title 元素，输出以 "# " 开头，只校验非空
  assert_true(@ocr.markdown_document_to_string(doc2).length() > 0)
  // 越界索引跳过
  let doc3 = @ocr.MarkdownDocument::{
    title: "T",
    elements: els,
    tables,
    images,
    symbols,
    reading_order: [0, 99],
  }
  assert_true(@ocr.markdown_document_to_string(doc3).length() > 0)
}

///|
test "dr: 构建文档与分布统计" {
  let blocks : Array[@ocr.TextBlock] = [
    dr_block(0, 10, 300, 64, "标题块"),
    dr_block(0, 100, 300, 40, "一级标题"),
    dr_block(0, 200, 300, 28, "二级标题"),
    dr_block(0, 300, 300, 16, "正文段落"),
  ]
  let page = @ocr.OCRPageResult::{
    page_number: 1,
    width: 600,
    height: 800,
    blocks,
    full_text: "",
    average_confidence: 0.9,
    processing_time_ms: 1.0,
  }
  let doc = @ocr.build_markdown_document(page, title="报告")
  assert_true(doc.title == "报告")
  assert_true(doc.elements.length() == 4)
  assert_true(doc.reading_order.length() == 4)
  assert_true(doc.symbols.length() > 0)
  // 无标题参数
  let doc2 = @ocr.build_markdown_document(page)
  assert_true(doc2.title.length() == 0)
  // 空块列表 → 错误
  let empty_page = @ocr.OCRPageResult::{
    page_number: 1,
    width: 0,
    height: 0,
    blocks: [],
    full_text: "",
    average_confidence: 0.0,
    processing_time_ms: 0.0,
  }
  try {
    let _ = @ocr.build_markdown_document(empty_page)
    assert_true(false)
  } catch {
    @types.DecodeFailed(_) => assert_true(true)
    _ => assert_true(false)
  }
  // 分布统计
  let dist = @ocr.analyze_markdown_element_distribution(doc)
  assert_true(dist.length() == 8)
  assert_eq(dist[0].0, "标题")
  assert_eq(dist[0].1, 1)
  // 图片占位符
  let img = @ocr.MarkdownImage::{
    x: 10,
    y: 20,
    width: 100,
    height: 50,
    image_type: "diagram",
    confidence: 0.7,
  }
  let ph = @ocr.generate_markdown_image_placeholder(img, 3)
  assert_true(ph.has_prefix("![图片3"))
  assert_true(ph.has_suffix("image_3.png)"))
  assert_true(ph.contains("diagram"))
}
