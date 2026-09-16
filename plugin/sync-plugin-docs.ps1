# sync-plugin-docs.ps1 - reconcile plugin/setup-dsh-plugins.cmd PLUGINS list and
# the marker-guarded plugin list inside PLUGIN-SYNC.md against the active dsh
# "web" profile's package.json dependencies (the single source of truth for
# user-installed plugins). Existing descriptive bullet lines are preserved;
# removed plugins drop out, new plugins get a bare-name bullet. Idempotent;
# does NOT touch git.
$ErrorActionPreference = 'Stop'

function Get-ProfileDir {
  if ($env:DSH_HOME) { return Join-Path $env:DSH_HOME 'profiles\web' }
  return Join-Path $HOME '.dsh\profiles\web'
}

$profileDir = Get-ProfileDir
$manifestPath = Join-Path $profileDir 'package.json'
if (-not (Test-Path $manifestPath)) {
  Write-Host "[sync-plugin-docs] profile manifest not found: $manifestPath" -ForegroundColor Red
  Write-Host "Boot 'dsh web' once on this machine, then re-run."
  exit 1
}

$pkg = Get-Content $manifestPath -Raw | ConvertFrom-Json
$deps = $pkg.dependencies
if ($null -eq $deps) { $names = @() } else { $names = @($deps.PSObject.Properties.Name) }

$setup = Join-Path $PSScriptRoot 'setup-dsh-plugins.cmd'
$md = Join-Path $PSScriptRoot 'PLUGIN-SYNC.md'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1) Rewrite the PLUGINS line in the setup script.
$setupText = [System.IO.File]::ReadAllText($setup)
$pluginsLine = 'set "PLUGINS=' + ($names -join ' ') + '"'
$setupNext = [regex]::Replace($setupText, '(?m)^set "PLUGINS=.*$', $pluginsLine)
if ($setupNext -ceq $setupText) {
  Write-Host '[sync-plugin-docs] error: could not find the PLUGINS line in setup-dsh-plugins.cmd' -ForegroundColor Red
  exit 1
}
[System.IO.File]::WriteAllText($setup, $setupNext, $utf8NoBom)

# 2) Reconcile the marker-guarded plugin list inside PLUGIN-SYNC.md.
$mdText = [System.IO.File]::ReadAllText($md)
$marker = '(?s)<!-- PLUGIN-LIST-START -->.*?<!-- PLUGIN-LIST-END -->'
$match = [regex]::Match($mdText, $marker)
if (-not $match.Success) {
  Write-Host '[sync-plugin-docs] error: could not find the PLUGIN-LIST markers in PLUGIN-SYNC.md' -ForegroundColor Red
  exit 1
}

$existing = @{}
foreach ($line in ($match.Value -split "`n")) {
  $trimmed = $line.Trim()
  $item = [regex]::Match($trimmed, '^- `([^`]+)`(.*)$')
  if ($item.Success) { $existing[$item.Groups[1].Value] = $trimmed }
}
$lines = foreach ($name in $names) {
  if ($existing.ContainsKey($name)) { $existing[$name] } else { "- ``$name``" }
}
$block = "<!-- PLUGIN-LIST-START -->`n" + ($lines -join "`n") + "`n<!-- PLUGIN-LIST-END -->"
$mdNext = $mdText.Substring(0, $match.Index) + $block + $mdText.Substring($match.Index + $match.Length)
[System.IO.File]::WriteAllText($md, $mdNext, $utf8NoBom)

Write-Host "[sync-plugin-docs] ok - plugins synced:"
if ($names.Count -eq 0) { Write-Host '  (none)' }
foreach ($name in $names) { Write-Host "  - $name" }
Write-Host "Files updated: $setup , $md"
Write-Host 'Commit and push them as usual (git add plugin && git commit && git push).'
