///|
/// walkzzz/image.mbt 基准运行器指引 — 真实尺寸基准已迁移至 moon bench 框架。
fn main {
  println("walkzzz/image.mbt benchmarks")
  println("")
  println(
    "真实尺寸基准（1024²/4096² PNG 编解码 + resize）使用 MoonBit bench 框架：",
  )
  println("  moon bench --target native")
  println("")
  println(
    "基准实现：根包 bench_real.mbt（png_encode/decode_1024 & 4096、resize_cover_1024_to_512）",
  )
  println(
    "完整报告（46 项历史基准 + 真实尺寸数据）：docs/performance_report.md",
  )
}
