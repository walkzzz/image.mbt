#Requires -Version 5.1
<#
  11 rings, published one by one: moon publish -> moon update, stop at the first failure.

  Order (dependencies are one-way; the root module last):
    image.core -> image.codec -> image.process -> image.photography -> image.vision
    -> image.domain -> image.doc -> image.media -> image.commerce -> image.pro -> root

  Usage:
    .\scripts\publish.ps1            # real publish
    .\scripts\publish.ps1 -DryRun    # same sequence with --dry-run (registry untouched)

  The root ring is dry-run checked once before its real publish (it is the most expensive
  pack, and one bad publish there cannot be undone).
#>
param([switch]$DryRun)

$root = Split-Path -Parent $PSScriptRoot
$mods = @(
  'image.core', 'image.codec', 'image.process', 'image.photography', 'image.vision',
  'image.domain', 'image.doc', 'image.media', 'image.commerce', 'image.pro', '.'
)
$mode = if ($DryRun) { 'DRY-RUN' } else { 'PUBLISH' }
Write-Host "publish 11 rings | $mode" -ForegroundColor Cyan

foreach ($m in $mods) {
  $dir = if ($m -eq '.') { $root } else { Join-Path $root $m }
  $label = if ($m -eq '.') { 'walkzzz/image.mbt (root)' } else { "walkzzz/$m" }
  Write-Host "`n=== publish $label ===" -ForegroundColor Cyan

  Push-Location $dir
  try {
    if ($m -eq '.' -and -not $DryRun) {
      Write-Host 'root dry-run check first' -ForegroundColor DarkGray
      moon publish --dry-run
      if ($LASTEXITCODE -ne 0) {
        Write-Host 'root dry-run failed, stopped before publishing the root' -ForegroundColor Red
        exit 2
      }
    }
    if ($DryRun) { moon publish --dry-run } else { moon publish }
    $code = $LASTEXITCODE
  }
  finally { Pop-Location }

  if ($code -ne 0) {
    Write-Host "publish failed, stopped at: $label" -ForegroundColor Red
    exit 2
  }

  if (-not $DryRun) {
    Write-Host '=== moon update ===' -ForegroundColor Yellow
    Push-Location $root
    try { moon update; $code = $LASTEXITCODE }
    finally { Pop-Location }
    if ($code -ne 0) {
      Write-Host "moon update failed after publishing $label - fix the registry view before continuing" -ForegroundColor Red
      exit 2
    }
  }
}

Write-Host "`nall 11 rings done ($mode)" -ForegroundColor Green
