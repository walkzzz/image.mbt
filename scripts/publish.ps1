#Requires -Version 5.1
<#
  publish.ps1 - image.mbt 11-module publish pipeline (PowerShell, no Node needed)

  Order (must not be shuffled; root module goes last):
    core -> codec -> process -> photography -> vision -> domain
    -> doc -> media -> commerce -> pro -> root

  Usage:
    .\scripts\publish.ps1                      # all 11, dry-run only (nothing written to registry)
    .\scripts\publish.ps1 -Exec                # real publish (moon publish + moon update per ring)
    .\scripts\publish.ps1 -From image.codec    # resume from this ring after a failure
    .\scripts\publish.ps1 -Only image.core     # only these rings (comma separated)
    .\scripts\publish.ps1 -SkipGates           # skip check_release_ready (not recommended)

  Exit code: 0 all green; 2 a ring failed / bad argument; 3 pre-gate failed.

  Notes
    - Every ring must carry the same version: the script reads the 11 moon.mod files first
      and refuses to start on a mismatch (run bump_version.mjs first).
    - dry-run is the default: it runs `moon publish --dry-run`, which packs the module, unpacks
      it into an empty directory and re-runs `moon check` against registry dependencies.
    - Success is judged from output text (`Server status: 200 OK` / `202 Accepted`), because
      moon on Windows can report a non-zero exit code while the operation actually succeeded.
#>
[CmdletBinding()]
param(
  [switch]$Exec,
  [switch]$SkipGates,
  [string]$From,
  [string[]]$Only
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot

$Chain = @(
  @{ Id = 'image.core';        Dir = 'image.core' }
  @{ Id = 'image.codec';       Dir = 'image.codec' }
  @{ Id = 'image.process';     Dir = 'image.process' }
  @{ Id = 'image.photography'; Dir = 'image.photography' }
  @{ Id = 'image.vision';      Dir = 'image.vision' }
  @{ Id = 'image.domain';      Dir = 'image.domain' }
  @{ Id = 'image.doc';         Dir = 'image.doc' }
  @{ Id = 'image.media';       Dir = 'image.media' }
  @{ Id = 'image.commerce';    Dir = 'image.commerce' }
  @{ Id = 'image.pro';         Dir = 'image.pro' }
  @{ Id = '.';                 Dir = '.' }
)

function Get-Label([string]$dir) {
  if ($dir -eq '.') { return 'walkzzz/image.mbt (root)' }
  return 'walkzzz/' + $dir
}

function Get-ModVersion([string]$dir) {
  $modPath = if ($dir -eq '.') { Join-Path $Root 'moon.mod' } else { Join-Path $Root (Join-Path $dir 'moon.mod') }
  if (-not (Test-Path $modPath)) { throw "missing $modPath" }
  $hit = Select-String -Path $modPath -Pattern '^version\s*=\s*"([^"]+)"' | Select-Object -First 1
  if (-not $hit) { throw "no version line in $modPath" }
  return $hit.Matches[0].Groups[1].Value
}

function Invoke-Moon([string[]]$MoonArgs, [string]$Dir) {
  $work = if ($Dir -eq '.') { $Root } else { Join-Path $Root $Dir }
  # PowerShell 5.1 turns anything moon writes to stderr into a NativeCommandError record and
  # prints it even when the command succeeded. Silence the error stream for this call only and
  # stringify the records so the text still reaches our parser / the console as plain output.
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  Push-Location $work
  try {
    $raw = & moon @MoonArgs 2>&1 | ForEach-Object { "$_" } | Out-String
    $code = $LASTEXITCODE
  }
  finally {
    Pop-Location
    $ErrorActionPreference = $prevEap
  }
  $trimmed = $raw.TrimEnd()
  if ($trimmed) { Write-Host $trimmed }
  return New-Object PSObject -Property @{ Output = $raw; Code = $code }
}

function Test-PublishOk($Result) {
  if ($Result.Output -match '(?m)^\s*(Error|error):') { return $false }
  if ($Result.Output -match 'failed to (verify|parse|compile)') { return $false }
  if ($Result.Output -match 'Server status:\s*(200 OK|202 Accepted)') { return $true }
  return ($Result.Code -eq 0)
}

function Get-FailReason($Result) {
  $out = $Result.Output
  if ($out -match '409|already exists|Conflict') { return '409 version already taken (bump the patch number; published versions cannot be deleted)' }
  if ($out -match '401|403|Unauthorized|not logged in|token') { return 'auth failed (run moon login first)' }
  if ($out -match 'failed to verify|error:|Error:') { return 're-check in an empty dir failed (usually a dependency pin one version behind; see check_version.mjs)' }
  return "unknown failure (exit code $($Result.Code); read the output above)"
}

# ---- 1. plan ----
$plan = $Chain
if ($From) {
  $idx = -1
  for ($k = 0; $k -lt $plan.Count; $k++) { if ($plan[$k].Id -eq $From) { $idx = $k; break } }
  if ($idx -lt 0) {
    Write-Host "-From does not know '$From' (choose: $(($plan | ForEach-Object { $_.Id }) -join ' / '))" -ForegroundColor Red
    exit 2
  }
  $plan = @($plan | Select-Object -Skip $idx)
}
if ($Only) {
  $known = $Chain | ForEach-Object { $_.Id }
  $unknown = @($Only | Where-Object { $known -notcontains $_ })
  if ($unknown.Count -gt 0) {
    Write-Host "-Only does not know: $($unknown -join ', ')" -ForegroundColor Red
    exit 2
  }
  $plan = @($Chain | Where-Object { $Only -contains $_.Id })
}

# ---- 2. version consistency ----
$versions = @{}
foreach ($m in $Chain) { $versions[$m.Id] = Get-ModVersion $m.Dir }
$distinct = @($versions.Values | Sort-Object -Unique)
if ($distinct.Count -ne 1) {
  Write-Host 'Version mismatch across the 11 moon.mod files:' -ForegroundColor Red
  foreach ($m in $Chain) { Write-Host ("   {0,-26} {1}" -f (Get-Label $m.Dir), $versions[$m.Id]) }
  Write-Host '   Run node scripts/bump_version.mjs <version> first.' -ForegroundColor Yellow
  exit 2
}
$version = $distinct[0]

Write-Host ''
if ($Exec) {
  Write-Host "publish pipeline | version $version | mode PUBLISH (writes registry, irreversible)" -ForegroundColor Cyan
} else {
  Write-Host "publish pipeline | version $version | mode DRY-RUN (registry untouched)" -ForegroundColor Cyan
}
Write-Host ("planned {0} ring(s): {1}" -f $plan.Count, (($plan | ForEach-Object { $_.Id }) -join ' -> '))
if ($Exec) {
  Write-Host 'moon publish is irreversible: a taken version can only be superseded, never deleted. Ctrl-C keeps the rings already published.' -ForegroundColor Yellow
}

# ---- 3. pre-gate ----
if (-not $SkipGates) {
  Write-Host "`n== pre-gate =="
  $gateArgs = if ($Exec) { @('scripts/check_release_ready.mjs') } else { @('scripts/check_release_ready.mjs', '--skip-slow') }
  Push-Location $Root
  try {
    $gate = & node @gateArgs 2>&1 | Out-String
    $gateCode = $LASTEXITCODE
  }
  finally { Pop-Location }
  Write-Host $gate.TrimEnd()
  if ($gateCode -ne 0 -or ($gate -match '"ok": false')) {
    Write-Host 'pre-gate failed, publish aborted (use -SkipGates only if you know why)' -ForegroundColor Red
    exit 3
  }
} else {
  Write-Host "`n== pre-gate skipped (-SkipGates) =="
}

# ---- 4. publish rings ----
$results = @()
$sw = [Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $plan.Count; $i++) {
  $m = $plan[$i]
  $label = Get-Label $m.Dir
  Write-Host ("`n[{0}/{1}] {2} {3}" -f ($i + 1), $plan.Count, $label, $versions[$m.Id]) -ForegroundColor Cyan
  $t0 = [Diagnostics.Stopwatch]::StartNew()
  $moonArgs = if ($Exec) { @('publish') } else { @('publish', '--dry-run') }
  $r = Invoke-Moon $moonArgs $m.Dir
  $t0.Stop()
  $ok = Test-PublishOk $r
  $results += New-Object PSObject -Property @{
    Ring = $label
    Version = $versions[$m.Id]
    Result = $(if ($ok) { 'ok' } else { 'FAIL' })
    Time = ('{0:N1}s' -f $t0.Elapsed.TotalSeconds)
  }

  if (-not $ok) {
    Write-Host ("`nFAIL {0}: {1}" -f $label, (Get-FailReason $r)) -ForegroundColor Red
    $manual = if ($m.Dir -eq '.') { 'repo root' } else { $m.Dir }
    Write-Host "   retry by hand: cd $manual; moon publish --dry-run"
    $resume = "   resume: .\scripts\publish.ps1 $(if ($Exec) { '-Exec ' }) -From $($m.Id) -SkipGates"
    Write-Host $resume
    break
  }
  if ($Exec) {
    Write-Host '   -> moon update (refresh registry view)'
    $null = Invoke-Moon @('update') '.'
  }
}
$sw.Stop()

# ---- 5. summary ----
Write-Host "`n== summary =="
$results | Format-Table Ring, Version, Result, Time -AutoSize | Out-String | Write-Host
$failed = @($results | Where-Object { $_.Result -ne 'ok' }).Count
$done = $results.Count
$minutes = [math]::Round($sw.Elapsed.TotalMinutes, 1)
if ($failed -eq 0 -and $done -eq $plan.Count) {
  Write-Host "OK $done/$($plan.Count) rings, $minutes min" -ForegroundColor Green
  if (-not $Exec) { Write-Host 'dry-run all green: run .\scripts\publish.ps1 -Exec to publish for real' -ForegroundColor Green }
  exit 0
}
Write-Host "FAILED $($done - $failed)/$($plan.Count) rings, $minutes min" -ForegroundColor Red
exit 2
