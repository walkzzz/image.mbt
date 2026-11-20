# scripts/run_bench.ps1 — walkzzz/image.mbt 性能基准一键复现（flutter-ohos-expert 思想④：可复现性即生态信任）
#
# 要求：moon 0.1.20261104+（PATH 含 ~/.moon/bin；安装：curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash 或 PowerShell 版）
# 产出：docs/performance_report.md「真实尺寸基准」节的全部数字（1024²/4096² PNG 编解码 + resize_cover）
#
# 用法：
#   .\scripts\run_bench.ps1              # 默认 native
#   .\scripts\run_bench.ps1 -Target wasm-gc
param([string]$Target = "native")

Write-Host "=== walkzzz/image.mbt benchmark (target: $Target) ==="
Write-Host "env : $env:COMPUTERNAME | $(Get-Date -Format 'yyyy-MM-dd HH:mm') | moon $(moon version 2>$null)"
Write-Host ""

moon bench --target $Target

Write-Host ""
Write-Host "=== 完整报告与环境口径见 docs/performance_report.md ==="
Write-Host "=== 历史口径（ARM aarch64 + 128² 固定小图，46 项）见同文件上半部 ==="
