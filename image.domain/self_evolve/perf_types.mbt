///|
/// # 性能类型 self_evolve/perf_types
///
/// 图像处理库子模块
/// 图像处理库子模块 Image processing library submodule
// 性能回归检测类型 — 静态成本模型
// Performance regression types: static cost model

///|
/// 算子成本估算。
/// 描述 Op cost estimate.
#derive(Eq, @debug.Debug)
pub(all) struct OpCost {
  op_tag : String
  time_complexity : String
  estimated_cost : Int32
}

///|
pub extend OpCost with @debug.Debug::{to_repr}

///|
pub extend OpCost with Eq::{not_equal, equal}

///|
/// 管道性能基线。
/// 管线 Pipeline performance baseline.
#derive(Eq, @debug.Debug)
pub(all) struct PerfBaseline {
  pipeline_desc : String
  total_cost : Int32
  op_count : Int32
  op_costs : Array[OpCost]
}

///|
pub extend PerfBaseline with @debug.Debug::{to_repr}

///|
pub extend PerfBaseline with Eq::{not_equal, equal}

///|
/// 性能回归检测结果。
/// 性能 Performance regression result.
#derive(Eq, @debug.Debug)
pub(all) struct PerfRegression {
  original_cost : Int32
  optimized_cost : Int32
  delta : Int32
  is_regression : Bool
}

///|
pub extend PerfRegression with @debug.Debug::{to_repr}

///|
pub extend PerfRegression with Eq::{not_equal, equal}

///|
/// 优化是否改善性能。
/// 描述 Whether optimization improved performance.
pub fn PerfRegression::is_improvement(self : PerfRegression) -> Bool {
  self.delta < 0
}

///|
/// 改善百分比（0-100）。
/// 描述 Improvement percentage (0-100).
pub fn PerfRegression::improvement_pct(self : PerfRegression) -> Int32 {
  if self.original_cost == 0 {
    0
  } else {
    self.delta * 100 / self.original_cost
  }
}
