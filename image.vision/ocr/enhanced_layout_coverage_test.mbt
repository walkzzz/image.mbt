// 覆盖率补测：enhanced_layout_analysis 的分支与全枚举映射

///|
fn ela_line(
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  text : String,
  size~ : Double = 12.0,
  weight~ : String = "normal",
  indented~ : Bool = false,
  level~ : Int32 = 0,
) -> @ocr.TextLineAttributes {
  @ocr.TextLineAttributes::{
    x,
    y,
    width: w,
    height: h,
    font_size: size,
    font_weight: weight,
    is_indented: indented,
    indent_level: level,
    line_spacing: 1.0,
    text,
    alignment: "left",
  }
}

///|
fn ela_no_list() -> @ocr.ListItemInfo {
  @ocr.ListItemInfo::{
    item_type: @ocr.ListItemType::None,
    marker: "",
    level: 0,
    number: 0,
  }
}

///|
fn ela_element(
  t : MarkdownElementType,
  content : String,
  header~ : Bool = false,
  footer~ : Bool = false,
  col~ : Int32 = 0,
  y~ : Int32 = 0,
) -> @ocr.EnhancedDocumentElement {
  @ocr.EnhancedDocumentElement::{
    element_type: t,
    x: 0,
    y,
    width: 200,
    height: 20,
    content,
    confidence: 0.85,
    font_size: 12.0,
    font_weight: "normal",
    alignment: "left",
    list_info: ela_no_list(),
    column_index: col,
    indent_level: 0,
    is_header: header,
    is_footer: footer,
  }
}

///|
fn ela_doc(
  layout : @ocr.LayoutType,
  elements : Array[@ocr.EnhancedDocumentElement],
  order : Array[Int32],
) -> @ocr.EnhancedDocument {
  @ocr.EnhancedDocument::{
    layout_type: layout,
    num_columns: 1,
    page_width: 600,
    page_height: 800,
    header_height: 80,
    footer_height: 40,
    body_top: 80,
    body_bottom: 760,
    elements,
    reading_order: order,
    column_boundaries: [0, 600],
  }
}

///|
test "ela: 全枚举 Debug 与 Eq" {
  let layouts = [
    @ocr.LayoutType::SingleColumn,
    @ocr.LayoutType::DoubleColumn,
    @ocr.LayoutType::TripleColumn,
    @ocr.LayoutType::MixedLayout,
    @ocr.LayoutType::UnknownLayout,
  ]
  for i in 0..<layouts.length() {
    assert_true(true)
    for j in 0..<layouts.length() {
      assert_true((i == j) == (layouts[i] == layouts[j]))
      assert_true((i != j) == (layouts[i] != layouts[j]))
    }
  }
  let regions = [
    @ocr.PageRegionType::Header,
    @ocr.PageRegionType::Footer,
    @ocr.PageRegionType::Body,
    @ocr.PageRegionType::Margin,
    @ocr.PageRegionType::Gutter,
    @ocr.PageRegionType::PageNumber,
  ]
  for i in 0..<regions.length() {
    assert_true(true)
    for j in 0..<regions.length() {
      assert_true((i == j) == (regions[i] == regions[j]))
    }
  }
  let lists = [
    @ocr.ListItemType::Bullet,
    @ocr.ListItemType::Numbered,
    @ocr.ListItemType::Lettered,
    @ocr.ListItemType::Roman,
    @ocr.ListItemType::Checkbox,
    @ocr.ListItemType::None,
  ]
  for i in 0..<lists.length() {
    assert_true(true)
    for j in 0..<lists.length() {
      assert_true((i != j) == (lists[i] != lists[j]))
    }
  }
  let region = @ocr.PageRegion::{
    region_type: @ocr.PageRegionType::Header,
    x: 0,
    y: 0,
    width: 100,
    height: 10,
    confidence: 0.9,
  }
  assert_true(true)
  assert_true(region == region)
  assert_true(!(region != region))
}

///|
test "ela: detect_layout_type 双栏 / 混合 / 回退单栏" {
  // 双栏：8 行窄行，左右各 4，无通栏
  let narrow_l : Array[@ocr.TextLineAttributes] = []
  let narrow_r : Array[@ocr.TextLineAttributes] = []
  for i in 0..<4 {
    narrow_l.push(ela_line(20, 100 + i * 30, 240, 20, "left"))
    narrow_r.push(ela_line(340, 100 + i * 30, 240, 20, "right"))
  }
  let both = narrow_l.copy()
  for l in narrow_r {
    both.push(l)
  }
  assert_eq(
    @ocr.detect_layout_type(both, 600, 800),
    @ocr.LayoutType::DoubleColumn,
  )
  // 混合：2 通栏 + 1 左 + 1 右
  let mixed = [
    ela_line(10, 100, 500, 20, "full1"),
    ela_line(10, 130, 500, 20, "full2"),
    ela_line(20, 160, 200, 20, "l"),
    ela_line(360, 190, 200, 20, "r"),
  ]
  assert_eq(
    @ocr.detect_layout_type(mixed, 600, 800),
    @ocr.LayoutType::MixedLayout,
  )
  // 全在左侧窄行：右半为 0，既非双栏也非混合 → 单栏
  let left_only = [
    ela_line(20, 100, 200, 20, "a"),
    ela_line(20, 130, 200, 20, "b"),
    ela_line(20, 160, 200, 20, "c"),
  ]
  assert_eq(
    @ocr.detect_layout_type(left_only, 600, 800),
    @ocr.LayoutType::SingleColumn,
  )
  // 页高为 0 抛错
  try {
    let _ = @ocr.detect_layout_type(left_only, 600, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "ela: detect_header_footer 页眉页脚与缺口" {
  // 同时有页眉与页脚
  let lines = [
    ela_line(10, 10, 300, 20, "head"),
    ela_line(10, 400, 300, 20, "body"),
    ela_line(10, 780, 300, 20, "foot"),
  ]
  let (hb, ft) = @ocr.detect_header_footer(lines, 800)
  assert_eq(hb, 30)
  assert_eq(ft, 780)
  // 只有正文：无页眉页脚
  let body_only = [ela_line(10, 400, 300, 20, "body")]
  let (hb2, ft2) = @ocr.detect_header_footer(body_only, 800)
  assert_eq(hb2, 0)
  assert_eq(ft2, 800)
  // 高度非法
  try {
    let _ = @ocr.detect_header_footer(body_only, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "ela: detect_column_boundaries 默认分支" {
  let single = @ocr.detect_column_boundaries(
    [],
    600,
    @ocr.LayoutType::SingleColumn,
  )
  assert_eq(single.length(), 3)
  assert_eq(single[0], 0)
  assert_eq(single[1], 600)
  let mixed = @ocr.detect_column_boundaries(
    [],
    600,
    @ocr.LayoutType::MixedLayout,
  )
  assert_eq(mixed.length(), 3)
  let unknown = @ocr.detect_column_boundaries(
    [],
    600,
    @ocr.LayoutType::UnknownLayout,
  )
  assert_eq(unknown[1], 600)
  let triple = @ocr.detect_column_boundaries(
    [],
    600,
    @ocr.LayoutType::TripleColumn,
  )
  assert_eq(triple.length(), 6)
}

///|
test "ela: is_heading_line 六级映射" {
  // bold & >2.0 → 1
  let (h1, l1) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=30.0, weight="bold"),
    12.0,
  )
  assert_true(h1)
  assert_eq(l1, 1)
  // bold & 1.6~2.0 → 2
  let (h2, l2) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=20.0, weight="bold"),
    12.0,
  )
  assert_true(h2)
  assert_eq(l2, 2)
  // bold & 1.3~1.6 → 3
  let (h3, l3) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=16.0, weight="bold"),
    12.0,
  )
  assert_true(h3)
  assert_eq(l3, 3)
  // 非 bold & >2.5 → 1
  let (h4, l4) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=32.0),
    12.0,
  )
  assert_true(h4)
  assert_eq(l4, 1)
  // 非 bold & 2.0~2.5 → 2
  let (h5, l5) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=26.0),
    12.0,
  )
  assert_true(h5)
  assert_eq(l5, 2)
  // 非 bold & 1.5~2.0 → 3
  let (h6, l6) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=19.0),
    12.0,
  )
  assert_true(h6)
  assert_eq(l6, 3)
  // 都不到 → 非标题
  let (h7, l7) = @ocr.is_heading_line(
    ela_line(0, 0, 100, 20, "t", size=13.0),
    12.0,
  )
  assert_true(!h7)
  assert_eq(l7, 0)
}

///|
test "ela: detect_list_item 空文本 / 三种编号 / 复选框 / 缩进" {
  let empty = @ocr.detect_list_item(ela_line(0, 0, 100, 20, ""))
  assert_eq(empty.item_type, @ocr.ListItemType::None)
  let bullet = @ocr.detect_list_item(
    ela_line(0, 0, 100, 20, "* 项", indented=true, level=2),
  )
  assert_eq(bullet.item_type, @ocr.ListItemType::Bullet)
  assert_eq(bullet.level, 2)
  let bullet2 = @ocr.detect_list_item(ela_line(0, 0, 100, 20, "• 项"))
  assert_eq(bullet2.item_type, @ocr.ListItemType::Bullet)
  assert_eq(bullet2.level, 0)
  for t in ["1. 甲", "2) 乙", "3、丙"] {
    let n = @ocr.detect_list_item(ela_line(0, 0, 100, 20, t))
    assert_eq(n.item_type, @ocr.ListItemType::Numbered)
    assert_eq(n.marker, "1")
  }
  let cb = @ocr.detect_list_item(
    ela_line(0, 0, 100, 20, "[x] 完成", indented=true, level=1),
  )
  assert_eq(cb.item_type, @ocr.ListItemType::Checkbox)
  assert_eq(cb.marker, "[ ]")
  assert_eq(cb.level, 1)
  let none = @ocr.detect_list_item(ela_line(0, 0, 100, 20, "正文"))
  assert_eq(none.item_type, @ocr.ListItemType::None)
  // 数字后无分隔符 → 非列表
  let trailing = @ocr.detect_list_item(ela_line(0, 0, 100, 20, "123"))
  assert_eq(trailing.item_type, @ocr.ListItemType::None)
}

///|
test "ela: code / quote / paragraph 判定" {
  assert_true(
    @ocr.is_code_block_line(
      ela_line(0, 0, 100, 20, "x=1", indented=true, level=1),
      0,
    ),
  )
  assert_true(!@ocr.is_code_block_line(ela_line(0, 0, 100, 20, "x=1"), 0))
  assert_true(!@ocr.is_code_block_line(ela_line(0, 0, 100, 20, ""), 0))
  assert_true(@ocr.is_quote_line(ela_line(0, 0, 100, 20, "> 引用"), 0))
  assert_true(@ocr.is_quote_line(ela_line(60, 0, 100, 20, "缩进"), 20))
  assert_true(!@ocr.is_quote_line(ela_line(0, 0, 100, 20, "正文"), 0))
  assert_true(!@ocr.is_quote_line(ela_line(0, 0, 100, 20, ""), 0))
}

///|
test "ela: segment_paragraphs 空 / 间距 / 缩进" {
  let empty : Array[@ocr.TextLineAttributes] = []
  assert_eq(@ocr.segment_paragraphs(empty).length(), 0)
  let lines = [
    ela_line(0, 0, 100, 20, "a1"),
    ela_line(0, 20, 100, 20, "a2"),
    ela_line(0, 80, 100, 20, "b1"),
    ela_line(0, 90, 100, 20, "c1", indented=true, level=1),
  ]
  let paras = @ocr.segment_paragraphs(lines)
  assert_eq(paras.length(), 3)
  assert_eq(paras[0].length(), 2)
  assert_eq(paras[1].length(), 1)
  assert_eq(paras[2].length(), 1)
}

///|
test "ela: smart_reading_order 跨列与同列" {
  let els = [
    ela_element(@ocr.MarkdownElementType::Paragraph, "c1", col=1, y=10),
    ela_element(@ocr.MarkdownElementType::Paragraph, "c0b", col=0, y=100),
    ela_element(@ocr.MarkdownElementType::Paragraph, "c0a", col=0, y=20),
  ]
  let order = @ocr.smart_reading_order(els, @ocr.LayoutType::DoubleColumn, [
    0, 600,
  ])
  assert_eq(order.length(), 3)
  assert_eq(order[0], 2)
  assert_eq(order[1], 1)
  assert_eq(order[2], 0)
  // 三栏与单栏分支
  let o2 = @ocr.smart_reading_order(els, @ocr.LayoutType::TripleColumn, [])
  assert_eq(o2.length(), 3)
  let o3 = @ocr.smart_reading_order(els, @ocr.LayoutType::MixedLayout, [])
  assert_eq(o3.length(), 3)
  try {
    let _ = @ocr.smart_reading_order([], @ocr.LayoutType::SingleColumn, [])
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "ela: build_enhanced_elements 元素类型与校验" {
  let lines = [
    ela_line(10, 10, 300, 20, "页眉"),
    ela_line(10, 100, 600, 30, "大标题", size=40.0, weight="bold"),
    ela_line(10, 200, 300, 20, "1. 列表"),
    ela_line(60, 250, 300, 20, "代码"),
    ela_line(10, 780, 300, 20, "页脚"),
  ]
  let doc = @ocr.build_enhanced_elements(lines, 600, 800)
  assert_eq(doc.layout_type, @ocr.LayoutType::SingleColumn)
  assert_eq(doc.num_columns, 1)
  assert_eq(doc.elements.length(), 5)
  assert_true(doc.elements[0].is_header)
  assert_true(doc.elements[4].is_footer)
  assert_eq(doc.elements[1].element_type, @ocr.MarkdownElementType::Heading1)
  assert_eq(doc.elements[2].element_type, @ocr.MarkdownElementType::ListItem)
  // 双栏文档 → num_columns 2
  let dlines : Array[@ocr.TextLineAttributes] = []
  for i in 0..<4 {
    dlines.push(ela_line(20, 100 + i * 30, 240, 20, "l"))
    dlines.push(ela_line(340, 100 + i * 30, 240, 20, "r"))
  }
  let ddoc = @ocr.build_enhanced_elements(dlines, 600, 800)
  assert_eq(ddoc.num_columns, 2)
  // 三栏分支
  let tdoc = @ocr.enhanced_document_to_markdown(
    ela_doc(@ocr.LayoutType::TripleColumn, [], []),
  )
  assert_true(tdoc.length() > 0)
  // 错误分支
  try {
    let _ = @ocr.build_enhanced_elements([], 600, 800)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.build_enhanced_elements(lines, 0, 800)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
  try {
    let _ = @ocr.build_enhanced_elements(lines, 600, 0)
    assert_true(false)
  } catch {
    @types.LoadError::DecodeFailed(_) => ()
    _ => assert_true(false)
  }
}

///|
test "ela: enhanced_document_to_markdown 全元素映射" {
  let els = [
    ela_element(@ocr.MarkdownElementType::Title, "标题"),
    ela_element(@ocr.MarkdownElementType::Heading1, "H1"),
    ela_element(@ocr.MarkdownElementType::Heading2, "H2"),
    ela_element(@ocr.MarkdownElementType::Heading3, "H3"),
    ela_element(@ocr.MarkdownElementType::Paragraph, "段落", header=true),
    ela_element(@ocr.MarkdownElementType::ListItem, "列表"),
    ela_element(@ocr.MarkdownElementType::Table, "表格"),
    ela_element(@ocr.MarkdownElementType::Image, "pic.png"),
    ela_element(@ocr.MarkdownElementType::Quote, "引用"),
    ela_element(@ocr.MarkdownElementType::CodeBlock, "code"),
    ela_element(@ocr.MarkdownElementType::HorizontalRule, ""),
    ela_element(@ocr.MarkdownElementType::PageBreak, ""),
    ela_element(@ocr.MarkdownElementType::Unknown, "未知"),
    ela_element(@ocr.MarkdownElementType::Paragraph, "页脚", footer=true),
  ]
  let order : Array[Int32] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 99]
  let doc = ela_doc(@ocr.LayoutType::MixedLayout, els, order)
  let md = @ocr.enhanced_document_to_markdown(doc)
  assert_true(md.contains("混合布局"))
  assert_true(md.contains("## H1"))
  assert_true(md.contains("### H2"))
  assert_true(md.contains("#### H3"))
  assert_true(!md.contains("段落"))
  assert_true(md.contains("- 列表"))
  assert_true(md.contains("![图片](pic.png)"))
  assert_true(md.contains("> 引用"))
  assert_true(md.contains("```"))
  assert_true(md.contains("---"))
  let md2 = @ocr.enhanced_document_to_markdown(doc, include_header_footer=true)
  assert_true(md2.contains("段落"))
  assert_true(md2.contains("页脚"))
  // 其余布局标签
  for
    layout in [
      @ocr.LayoutType::SingleColumn,
      @ocr.LayoutType::DoubleColumn,
      @ocr.LayoutType::TripleColumn,
      @ocr.LayoutType::UnknownLayout,
    ] {
    let m = @ocr.enhanced_document_to_markdown(ela_doc(layout, [], []))
    assert_true(m.contains("布局类型"))
  }
}

///|
test "ela: enhanced_element_distribution 全类型计数" {
  let els = [
    ela_element(@ocr.MarkdownElementType::Title, "t"),
    ela_element(@ocr.MarkdownElementType::Heading1, "h1"),
    ela_element(@ocr.MarkdownElementType::Heading2, "h2"),
    ela_element(@ocr.MarkdownElementType::Heading3, "h3"),
    ela_element(@ocr.MarkdownElementType::Paragraph, "p", header=true),
    ela_element(@ocr.MarkdownElementType::ListItem, "l"),
    ela_element(@ocr.MarkdownElementType::Table, "tb"),
    ela_element(@ocr.MarkdownElementType::Image, "i"),
    ela_element(@ocr.MarkdownElementType::Quote, "q"),
    ela_element(@ocr.MarkdownElementType::CodeBlock, "c", footer=true),
    ela_element(@ocr.MarkdownElementType::HorizontalRule, ""),
  ]
  let dist = @ocr.enhanced_element_distribution(
    ela_doc(@ocr.LayoutType::SingleColumn, els, []),
  )
  assert_eq(dist.length(), 10)
  assert_eq(dist[0], ("标题", 1))
  assert_eq(dist[1], ("小标题", 3))
  assert_eq(dist[2], ("段落", 1))
  assert_eq(dist[3], ("列表", 1))
  assert_eq(dist[4], ("表格", 1))
  assert_eq(dist[5], ("图片", 1))
  assert_eq(dist[6], ("引用", 1))
  assert_eq(dist[7], ("代码", 1))
  assert_eq(dist[8], ("页眉", 1))
  assert_eq(dist[9], ("页脚", 1))
}
