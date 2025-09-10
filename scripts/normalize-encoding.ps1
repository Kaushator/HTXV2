# Normalize file encodings to UTF-8 (no BOM)
# Usage examples:
#   pwsh -File scripts/normalize-encoding.ps1 -Paths docs/dev-journal.md,docs/setup-guide.md
#   pwsh -File scripts/normalize-encoding.ps1 -Paths docs/**/*.md -Exclude docs/project-report.md

param(
  [Parameter(Mandatory=$true)]
  [string[]]$Paths,
  [string[]]$Exclude = @(),
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[void][System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$cp1251 = [System.Text.Encoding]::GetEncoding(1251)

function Test-IsUtf8Strict([byte[]]$bytes) {
  try {
    [void]$utf8Strict.GetString($bytes)
    return $true
  } catch {
    return $false
  }
}

function Convert-FileUtf8([string]$path) {
  $bytes = [System.IO.File]::ReadAllBytes($path)
  if (Test-IsUtf8Strict $bytes) {
    Write-Host "OK UTF-8: $path" -ForegroundColor DarkGray
    return $false
  }

  $text1251 = $cp1251.GetString($bytes)
  if ($DryRun) {
    Write-Host "DRYRUN CONVERT: $path (cp1251 -> utf8)" -ForegroundColor Yellow
    return $true
  }

  # Backup once
  $bak = "$path.bak"
  if (-not (Test-Path $bak)) { [System.IO.File]::Copy($path, $bak) }
  [System.IO.File]::WriteAllText($path, $text1251, $utf8NoBom)
  Write-Host "CONVERTED: $path (cp1251 -> utf8)" -ForegroundColor Green
  return $true
}

$resolved = @()

# Allow comma-separated single arg usage
if ($Paths.Count -eq 1 -and $Paths[0] -match ',') {
  $Paths = $Paths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

foreach ($p in $Paths) {
  if (Test-Path $p -PathType Leaf) { $resolved += (Resolve-Path $p).Path; continue }
  $resolved += (Get-ChildItem -Path $p -File -Recurse | ForEach-Object { $_.FullName })
}

if ($Exclude.Count -gt 0) {
  $excludeResolved = $Exclude | ForEach-Object {
    if (Test-Path $_ -PathType Leaf) { (Resolve-Path $_).Path } else { $_ }
  }
  $resolved = $resolved | Where-Object { $item = $_; -not ($excludeResolved | ForEach-Object { $item -like $_ } | Where-Object { $_ } ) }
}

$resolved = $resolved | Sort-Object -Unique

$converted = 0
foreach ($file in $resolved) {
  try {
    if (Convert-FileUtf8 $file) { $converted++ }
  } catch {
    Write-Host "ERROR: $file :: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Host "Done. Converted: $converted / $($resolved.Count)" -ForegroundColor Cyan
