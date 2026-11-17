///|
/// # 回归 self_evolve/regression
///
/// 图像处理库子模块
/// 图像处理库子模块 Image processing library submodule
// 跨版本回归检测 — 检测版本间退化回归
// Cross-version regression detection: detect degradation regressions across versions
//
// Phase 9 v302: 将演化从"调度"推向"回归检测" — 比较历史快照，发现退化回归。

///|
/// 回归类型。
/// 描述 Regression kind.
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum RegressionKind {
  DegradationIncrease
  TestDecrease
  OpCountChange
  NoRegression
}

///|
pub extend RegressionKind with @debug.Debug::{to_repr}

///|
pub extend RegressionKind with Eq::{not_equal, equal}

///|
/// 单个回归案例。
/// 描述 Single regression case.
#derive(Eq, @debug.Debug)
pub(all) struct RegressionCase {
  from_version : String
  to_version : String
  kind : RegressionKind
  delta : Int32
  description : String
}

///|
pub extend RegressionCase with @debug.Debug::{to_repr}

///|
pub extend RegressionCase with Eq::{not_equal, equal}

///|
/// 回归检测报告。
/// 描述 Regression detection report.
#derive(Eq, @debug.Debug)
pub(all) struct RegressionReport {
  cases : Array[RegressionCase]
  total_regressions : Int32
  total_improvements : Int32
  summary : String
}

///|
pub extend RegressionReport with @debug.Debug::{to_repr}

///|
pub extend RegressionReport with Eq::{not_equal, equal}

///|
/// 检测历史快照间的回归。
/// 检测 Detect regressions across history snapshots.
pub fn detect_regressions() -> RegressionReport {
  let log = history_log()
  let entries = log.entries
  let n = entries.length()
  let cases : Array[RegressionCase] = []
  let mut reg_count = 0
  let mut imp_count = 0
  for i in 1..<n {
    let prev = entries[i - 1]
    let curr = entries[i]
    let deg_delta = curr.degradation_count - prev.degradation_count
    let test_delta = curr.test_count - prev.test_count
    if deg_delta > 0 {
      cases.push({
        from_version: prev.version,
        to_version: curr.version,
        kind: DegradationIncrease,
        delta: deg_delta,
        description: prev.version +
        " → " +
        curr.version +
        ": 退化增加 " +
        deg_delta.to_string(),
      })
      reg_count = reg_count + 1
    }
    if test_delta < 0 {
      cases.push({
        from_version: prev.version,
        to_version: curr.version,
        kind: TestDecrease,
        delta: test_delta,
        description: prev.version +
        " → " +
        curr.version +
        ": 测试减少 " +
        (-test_delta).to_string(),
      })
      reg_count = reg_count + 1
    }
    if prev.op_count != curr.op_count {
      cases.push({
        from_version: prev.version,
        to_version: curr.version,
        kind: OpCountChange,
        delta: curr.op_count - prev.op_count,
        description: prev.version +
        " → " +
        curr.version +
        ": 算子数 " +
        prev.op_count.to_string() +
        " → " +
        curr.op_count.to_string(),
      })
    }
    if deg_delta <= 0 && test_delta >= 0 {
      cases.push({
        from_version: prev.version,
        to_version: curr.version,
        kind: NoRegression,
        delta: 0,
        description: prev.version + " → " + curr.version + ": 无回归",
      })
      imp_count = imp_count + 1
    }
  }
  let total = cases.length()
  let summary = "回归检测: " +
    total.to_string() +
    " 个比较, " +
    reg_count.to_string() +
    " 回归, " +
    imp_count.to_string() +
    " 改进"
  {
    cases,
    total_regressions: reg_count,
    total_improvements: imp_count,
    summary,
  }
}

///|
/// 检查指定版本是否有回归（退化数 > 0）。
/// 描述 Whether a specific version has regressions (degradation count > 0).
pub fn has_regression(version : String) -> Bool {
  let log = history_log()
  for e in log.entries {
    if e.version == version {
      return e.degradation_count > 0
    }
  }
  false
}

///|
/// 回归报告是否无回归。
/// 描述 Whether regression report is clean (no regressions).
pub fn RegressionReport::is_clean(self : RegressionReport) -> Bool {
  self.total_regressions == 0
}
