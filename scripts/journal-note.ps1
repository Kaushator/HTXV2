Param(
  [Parameter(Mandatory=$true)][string]$Message
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$date = Get-Date -Format 'yyyy-MM-dd'
$file = "docs/journal/$date.md"

if (!(Test-Path "docs/journal")) { New-Item -ItemType Directory -Path "docs/journal" | Out-Null }
if (!(Test-Path $file)) { "## $date`n" | Out-File -FilePath $file -Encoding utf8 -Append }

"- $Message" | Out-File -FilePath $file -Encoding utf8 -Append
Write-Host "Appended to $file"

