///|
/// 基准集生成器（native 可执行，只在仓库维护者本地跑）：
///
/// ```text
/// moon run benchmarks/gen                 # 写 benchmarks/golden + benchmarks/malformed
/// moon run benchmarks/gen -- 目标目录 恶意样本目录
/// ```
///
/// 输出文件名即契约：`gNN_<格式>_<内容>_<W>x<H>.<ext>` / `mN_<类别>.<ext>`，
/// `scripts/check_benchmarks.mjs` 依赖这个命名解析格式与期望尺寸。
/// 样本本身由 `samples.mbt` 的纯构建器产出（可被白盒测试覆盖），本文件只负责写盘。

///|
fn main {
  let argv = @env.args()
  let golden = if argv.length() > 1 { argv[1] } else { "benchmarks/golden" }
  let malformed = if argv.length() > 2 {
    argv[2]
  } else {
    "benchmarks/malformed"
  }
  let errs : Array[String] = []
  for (name, data) in golden_samples(errs) {
    put(golden, name, data, errs)
  }
  for (name, data) in malformed_samples(errs) {
    put(malformed, name, data, errs)
  }
  if errs.length() > 0 {
    println("生成失败 \{errs.length()} 项：")
    for e in errs {
      println("  - \{e}")
    }
    @env.exit(1)
  }
  println("benchmarks: 已写入 \{golden} 与 \{malformed}")
}

///|
/// 写一个文件（失败记入 errs，不中断其余样本）。
fn put(dir : String, name : String, data : Bytes, errs : Array[String]) -> Unit {
  @imgcli.write_bytes(dir + "/" + name, data) catch {
    _ => errs.push("\{name}: 写盘失败")
  }
  println("  \{name}  \{data.length()} B")
}
