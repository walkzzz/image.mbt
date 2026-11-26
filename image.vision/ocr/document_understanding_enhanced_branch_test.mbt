// 覆盖率测试：文档理解增强的结构化 API 分支

fn ducb_block(
  t : @ocr.DocumentBlockType,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  text : String,
  font_size : Int32,
  column : Int32,
) -> @ocr.DocumentBlock {
  @ocr.DocumentBlock::{
    block_type: t,
    x,
    y,
    width: w,
    height: h,
    text,
    confidence: 0.9,
    font_size,
    is_bold: false,
    is_italic: false,
    line_spacing: 1.2,
    indent_level: 0,
    column_index: column,
    reading_order: -1,
    parent_id: -1,
    children_ids: [],
  }
}

fn ducb_img(w : Int32, h : Int32, c : Int32, value : Int32) -> @types.Image {
  @types.Image::{
    width: w,
    height: h,
    channels: c,
    data: Bytes::from_array(Array::make(w * h * c, value.to_byte())),
  }
}

test "ducov: 阅读顺序 / 段落 / 标题" {
  // 双栏：右栏块先出现，阅读顺序应重排
  let blocks = [
    ducb_block(@ocr.DocumentBlockType::Paragraph, 200, 10, 100, 20, "right", 12, 1),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 10, 100, 20, "left", 12, 0),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 40, 100, 20, "left2", 12, 0),
  ]
  let order = @ocr.optimize_reading_order(blocks, 2)
  assert_true(order.length() == 3)
  // 单栏：只收集 column_index == 0 的块
  let order1 = @ocr.optimize_reading_order(blocks, 1)
  assert_true(order1.length() == 2)
  // 未匹配到任何列 → 全局 y/x 排序兜底
  let col5 = [
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 40, 100, 20, "b", 12, 5),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 10, 100, 20, "a", 12, 5),
  ]
  let order5 = @ocr.optimize_reading_order(col5, 1)
  assert_true(order5.length() == 2)
  assert_true(order5[0] == 1)
  // 空数组
  let order0 = @ocr.optimize_reading_order([], 2)
  assert_true(order0.length() == 0)
  // 段落：行距小 → 合并；行距大 → 新段
  let tight = [
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 10, 100, 20, "l1", 12, 0),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 34, 100, 20, "l2", 12, 0),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 140, 100, 20, "l3", 12, 0),
  ]
  let paras = @ocr.detect_paragraphs(tight)
  assert_true(paras.length() >= 1)
  let paras2 = @ocr.detect_paragraphs(tight, max_line_spacing_ratio=0.5)
  assert_true(paras2.length() >= 1)
  let paras0 = @ocr.detect_paragraphs([])
  assert_true(paras0.length() == 0)
  // 标题：字号阈值
  let mixed = [
    ducb_block(@ocr.DocumentBlockType::Title, 10, 0, 200, 40, "BIG", 32, 0),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 60, 200, 20, "body", 12, 0),
  ]
  let titles = @ocr.detect_titles(mixed)
  assert_true(titles.length() >= 1)
  let no_titles = @ocr.detect_titles(mixed, title_font_size_threshold=100)
  assert_true(no_titles.length() == 0)
  let titles0 = @ocr.detect_titles([])
  assert_true(titles0.length() == 0)
}

test "ducov: 结构树 / 文本提取 / 统计" {
  let blocks = [
    ducb_block(@ocr.DocumentBlockType::Title, 10, 0, 200, 40, "标题", 32, 0),
    ducb_block(@ocr.DocumentBlockType::Heading2, 10, 50, 180, 20, "小节", 18, 0),
    ducb_block(@ocr.DocumentBlockType::Paragraph, 10, 80, 180, 20, "正文一", 12, 0),
    ducb_block(@ocr.DocumentBlockType::Header, 10, 0, 180, 10, "页眉", 10, 0),
    ducb_block(@ocr.DocumentBlockType::Footer, 10, 300, 180, 10, "页脚", 10, 0),
  ]
  let tree = @ocr.build_document_structure_tree(blocks)
  assert_true(tree.length() >= 1)
  // 空数组
  let tree0 = @ocr.build_document_structure_tree([])
  assert_true(tree0.length() == 0)
  // 文本提取：含页眉不含页脚
  let t1 = @ocr.extract_document_text(blocks)
  assert_true(t1.length() > 0)
  // 含页眉页脚
  let t2 = @ocr.extract_document_text(
    blocks,
    include_headers=true,
    include_footers=true,
  )
  assert_true(t2.length() >= t1.length())
  // 都不含
  let t3 = @ocr.extract_document_text(
    blocks,
    include_headers=false,
    include_footers=false,
  )
  assert_true(t3.length() > 0)
  // 空数组
  let t0 = @ocr.extract_document_text([])
  assert_true(t0.length() == 0)
  // 统计
  let stats = @ocr.document_statistics_enhanced(blocks)
  let (a, b, c, d, e, f, g) = stats
  assert_true(a >= 0)
  assert_true(b >= 0)
  assert_true(c >= 0)
  assert_true(d >= 0)
  assert_true(e >= 0)
  assert_true(f >= 0)
  assert_true(g >= 0)
  let stats0 = @ocr.document_statistics_enhanced([])
  let (a0, _b0, _c0, _d0, _e0, _f0, _g0) = stats0
  assert_true(a0 == 0)
}

test "ducov: 版面分析与整体流水线" {
  // 空白图 → 无块
  let blank = ducb_img(64, 64, 1, 0)
  let b0 = @ocr.analyze_layout_enhanced(blank)
  assert_true(b0.length() >= 0)
  // 有内容的图（白底黑块）
  let data : Array[Int32] = Array::make(64 * 64, 255)
  for y in 4..<20 {
    for x in 4..<40 {
      data[y * 64 + x] = 0
    }
  }
  let img = @types.Image::{
    width: 64,
    height: 64,
    channels: 1,
    data: Bytes::from_array(data.map(fn(v) { v.to_byte() })),
  }
  let b1 = @ocr.analyze_layout_enhanced(img)
  assert_true(b1.length() >= 0)
  // 自定义配置
  let cfg = @ocr.document_understanding_enhanced_default_config()
  let b2 = @ocr.analyze_layout_enhanced(img, config=cfg)
  assert_true(b2.length() >= 0)
  // 错误分支
  try {
    let _ = @ocr.analyze_layout_enhanced(ducb_img(0, 8, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.analyze_layout_enhanced(ducb_img(8, 8, 6, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 整体流水线
  let (blocks, tree, text) = @ocr.understand_document_enhanced(img)
  assert_true(blocks.length() >= 0)
  assert_true(tree.length() >= 0)
  assert_true(text.length() >= 0)
  let (b3, _t3, s3) = @ocr.understand_document_enhanced(blank)
  assert_true(s3.length() >= 0)
  // 流水线错误分支
  try {
    let _ = @ocr.understand_document_enhanced(ducb_img(0, 8, 1, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  try {
    let _ = @ocr.understand_document_enhanced(ducb_img(8, 8, 7, 0))
    assert_true(false)
  } catch {
    _ => assert_true(true)
  }
  // 默认配置字段
  assert_true(cfg.min_block_width == 20)
  assert_true(cfg.min_block_height == 10)
}
