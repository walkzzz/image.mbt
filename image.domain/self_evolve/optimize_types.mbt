///|
/// # 优化类型 self_evolve/optimize_types
///
/// 图像处理库子模块
/// 图像处理库子模块 Image processing library submodule
// 算法优化类型 — 优化建议 + 优化报告
// Optimization types: suggestion + report

///|
/// 优化类型。
/// 描述 Optimization kind.
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum OptimizationKind {
  RemoveRedundant // 消除冗余算子对（如 FlipH ∘ FlipH）
  RemoveIdentity // 消除恒等算子（如 Brightness(0)）
  MergeAdjacent // 合并相邻同类算子（如 Brightness(a) ∘ Brightness(b) → Brightness(a+b)）
}

///|
pub extend OptimizationKind with @debug.Debug::{to_repr}

///|
pub extend OptimizationKind with Eq::{not_equal, equal}

///|
/// 优化建议。
/// 描述 Optimization suggestion.
#derive(Eq, @debug.Debug)
pub(all) struct OptimizationSuggestion {
  kind : OptimizationKind
  op_indices : Array[Int32]
  description : String
  before_count : Int32
  after_count : Int32
}

///|
pub extend OptimizationSuggestion with @debug.Debug::{to_repr}

///|
pub extend OptimizationSuggestion with Eq::{not_equal, equal}

///|
/// 优化报告。
/// 描述 Optimization report.
#derive(Eq, @debug.Debug)
pub(all) struct OptimizationReport {
  original_length : Int32
  optimized_length : Int32
  suggestions : Array[OptimizationSuggestion]
  optimized_pipeline : @imgir.IRPipeline
}

///|
pub extend OptimizationReport with @debug.Debug::{to_repr}

///|
pub extend OptimizationReport with Eq::{not_equal, equal}

///|
/// 优化是否减少了算子数。
/// 描述 Whether optimization reduced op count.
pub fn OptimizationReport::is_reduced(self : OptimizationReport) -> Bool {
  self.optimized_length < self.original_length
}

///|
/// 减少的算子数。
/// 描述 Number of ops removed.
pub fn OptimizationReport::reduction(self : OptimizationReport) -> Int32 {
  self.original_length - self.optimized_length
}
