#Requires -Version 5.1
<#
  Publish the 11 modules one by one: moon publish -> moon update, stop at the first failure.

  Order (dependencies are one-way; the root module last):
    image.core -> image.codec -> image.process -> image.photography -> image.vision
    -> image.domain -> image.doc -> image.media -> image.commerce -> image.pro -> root

  Usage:
    .\scripts\publish.ps1                        # real publish, from the first ring
    .\scripts\publish.ps1 -From image.codec      # resume after a stop / after a manual ring
    .\scripts\publish.ps1 -DryRun                # same sequence with --dry-run

  Success is read from the output text, not from the exit code: on this machine `moon publish`
  has returned 0 while nothing was uploaded (registry stayed at the previous version for ten
  rings). The reliable marker is `Server status: 200 OK` (real publish) / `202 Accepted`
  (dry-run); any `Error:` line means the ring failed.
#>
param([switch]$DryRun, [string]$From)

$root = Split-Path -Parent $PSScriptRoot
$all = @(
  'image.core', 'image.codec', 'image.process', 'image.photography', 'image.vision',
  'image.domain', 'image.doc', 'image.media', 'image.commerce', 'image.pro', '.'
)

if ($From) {
  $idx = [array]::IndexOf($all, $From)
  if ($idx -lt 0) {
    Write-Host "unknown -From '$From' (use one of: $($all -join ', '))" -ForegroundColor Red
    exit 2
  }
  $all = $all[$idx..($all.Count - 1)]
}

# Run moon with both streams redirected to one log file through cmd.exe, then print it.
# Direct 2>&1 piping in PowerShell 5.1 either scatters NativeCommandError noise across the
# console or drops the stderr text entirely, and the stderr text is where moon reports failure.
function Invoke-Moon([string[]]$MoonArgs, [string]$Dir) {
  $log = Join-Path $env:TEMP ('moonpub_' + [guid]::NewGuid().ToString('N') + '.log')
  Push-Location $Dir
  try {
    & cmd /c ('moon ' + ($MoonArgs -join ' ') + ' > "' + $log + '" 2>&1') | Out-Null
    $code = $LASTEXITCODE
  }
  finally { Pop-Location }
  $text = if (Test-Path $log) { Get-Content $log -Raw -Encoding UTF8 } else { '' }
  if ($null -eq $text) { $text = '' }
  Remove-Item $log -Force -ErrorAction SilentlyContinue
  $trimmed = $text.TrimEnd()
  if ($trimmed) { Write-Host $trimmed }
  return New-Object PSObject -Property @{ Text = $text; Code = $code }
}

function Test-Published($r) {
  if ($r.Text -match '(?m)^\s*Error:') { return $false }
  return [bool]($r.Text -match 'Server status:\s*(200 OK|202 Accepted)')
}

Write-Host ("publish rings | {0} | from {1}" -f $(if ($DryRun) { 'DRY-RUN' } else { 'PUBLISH' }), $all[0]) -ForegroundColor Cyan

# Refresh the registry index BEFORE the first ring: a ring published in an earlier session is
# only resolvable from an empty directory once `moon update` has pulled the new index entry.
Write-Host "`n=== moon update (refresh registry index) ===" -ForegroundColor Yellow
$u0 = Invoke-Moon @('update') $root
if ($u0.Text -match '(?m)^\s*Error:') {
  Write-Host 'moon update failed, cannot resolve freshly published versions' -ForegroundColor Red
  exit 2
}

foreach ($m in $all) {
  $dir = if ($m -eq '.') { $root } else { Join-Path $root $m }
  $label = if ($m -eq '.') { 'walkzzz/image.mbt (root)' } else { "walkzzz/$m" }
  Write-Host "`n=== publish $label ===" -ForegroundColor Cyan

  if ($m -eq '.' -and -not $DryRun) {
    Write-Host 'root dry-run check first' -ForegroundColor DarkGray
    $pre = Invoke-Moon @('publish', '--dry-run') $dir
    if (-not (Test-Published $pre)) {
      Write-Host 'root dry-run failed, root not published' -ForegroundColor Red
      exit 2
    }
  }

  $moonArgs = if ($DryRun) { @('publish', '--dry-run') } else { @('publish') }
  $r = Invoke-Moon $moonArgs $dir
  if (-not (Test-Published $r)) {
    Write-Host "publish failed, stopped at: $label" -ForegroundColor Red
    Write-Host "resume with: .\scripts\publish.ps1$(if ($DryRun) { ' -DryRun' }) -From $m"
    exit 2
  }

  if (-not $DryRun) {
    Write-Host '=== moon update ===' -ForegroundColor Yellow
    $u = Invoke-Moon @('update') $root
    if ($u.Text -match '(?m)^\s*Error:') {
      Write-Host "moon update failed after publishing $label - fix the registry view before continuing" -ForegroundColor Red
      exit 2
    }
  }
}

Write-Host "`nall rings done ($(if ($DryRun) { 'DRY-RUN' } else { 'PUBLISH' }))" -ForegroundColor Green
