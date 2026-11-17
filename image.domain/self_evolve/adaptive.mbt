///|
/// # 自适应 self_evolve/adaptive
///
/// 图像处理库子模块
/// 图像处理库子模块 Image processing library submodule
// 自适应测试策略 — 根据覆盖率自动调整测试优先级
// Adaptive test strategy: auto-adjust test priority based on coverage
//
// Phase 7 v292: 将测试生成从"均匀"推向"自适应" — 低覆盖算子优先。

///|
/// 测试优先级。
/// 描述 Test priority level.
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum TestPriority {
  HighPriority
  MediumPriority
  LowPriority
}

///|
pub extend TestPriority with @debug.Debug::{to_repr}

///|
pub extend TestPriority with Eq::{not_equal, equal}

///|
/// 单算子自适应策略。
/// 自适应 Adaptive strategy for a single op.
#derive(Eq, @debug.Debug)
pub(all) struct AdaptiveStrategy {
  op_tag : String
  current_coverage : Int32
  priority : TestPriority
  suggested_tests : Int32
}

///|
pub extend AdaptiveStrategy with @debug.Debug::{to_repr}

///|
pub extend AdaptiveStrategy with Eq::{not_equal, equal}

///|
/// 自适应报告。
/// 自适应 Adaptive report.
#derive(Eq, @debug.Debug)
pub(all) struct AdaptiveReport {
  strategies : Array[AdaptiveStrategy]
  total_prioritized : Int32
  high_priority_count : Int32
  summary : String
}

///|
pub extend AdaptiveReport with @debug.Debug::{to_repr}

///|
pub extend AdaptiveReport with Eq::{not_equal, equal}

///|
/// 根据覆盖度建议测试数量。
/// 描述 Suggest test count based on coverage (0-100).
pub fn suggest_test_count(coverage : Int32) -> Int32 {
  if coverage >= 80 {
    2
  } else if coverage >= 50 {
    5
  } else if coverage >= 25 {
    8
  } else {
    12
  }
}

///|
/// 根据覆盖度判定优先级。
/// 描述 Determine priority based on coverage.
pub fn priority_from_coverage(coverage : Int32) -> TestPriority {
  if coverage >= 50 {
    LowPriority
  } else if coverage >= 25 {
    MediumPriority
  } else {
    HighPriority
  }
}

///|
/// 分析单算子自适应策略。
/// 描述 Analyze adaptive strategy for a single op.
pub fn adaptive_strategy(op : @imgir.IROp) -> AdaptiveStrategy {
  let degs = detect_degradation(op)
  let coverage = if degs.length() == 0 {
    100
  } else {
    100 / (degs.length() + 1)
  }
  let priority = priority_from_coverage(coverage)
  let suggested = suggest_test_count(coverage)
  {
    op_tag: op.tag(),
    current_coverage: coverage,
    priority,
    suggested_tests: suggested,
  }
}

///|
/// 对全部 19 种算子分析自适应策略。
/// 描述 Analyze adaptive strategy for all 19 ops.
pub fn adaptive_strategy_all() -> AdaptiveReport {
  let strategies : Array[AdaptiveStrategy] = []
  let mut high_count = 0
  for op in all_ops() {
    let s = adaptive_strategy(op)
    if s.priority is HighPriority {
      high_count = high_count + 1
    }
    strategies.push(s)
  }
  let total = strategies.length()
  let summary = "自适应策略: " +
    total.to_string() +
    " 个算子, " +
    high_count.to_string() +
    " 个高优先级"
  {
    strategies,
    total_prioritized: total,
    high_priority_count: high_count,
    summary,
  }
}

///|
/// 获取高优先级算子标签。
/// 获取 Get high-priority op tags.
pub fn high_priority_ops() -> Array[String] {
  let result : Array[String] = []
  for s in adaptive_strategy_all().strategies {
    if s.priority is HighPriority {
      result.push(s.op_tag)
    }
  }
  result
}

///|
/// 自适应报告是否全部高覆盖。
/// 描述 Whether adaptive report is all high coverage.
pub fn AdaptiveReport::is_well_covered(self : AdaptiveReport) -> Bool {
  self.high_priority_count == 0
}
