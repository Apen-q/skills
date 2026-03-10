[CmdletBinding()]
param(
  [string]$HistoryPath = $(Join-Path $env:USERPROFILE ".codex\skills-data\daily-report-emailer\send-history.json"),
  [int]$Limit = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $HistoryPath -PathType Leaf)) {
  throw "No send history found at: $HistoryPath"
}

$raw = Get-Content -LiteralPath $HistoryPath -Raw -Encoding utf8
if ([string]::IsNullOrWhiteSpace($raw)) {
  throw "Send history file is empty: $HistoryPath"
}

$history = $raw | ConvertFrom-Json
$entries = @()
if ($null -ne $history.history) {
  $entries = @($history.history)
}
elseif ($null -ne $history.last) {
  $entries = @($history.last)
}

if ($entries.Count -eq 0) {
  throw "No send history entries found in: $HistoryPath"
}

$count = [Math]::Min([Math]::Max($Limit, 1), $entries.Count)
$selected = @($entries[0..($count - 1)])

$selected |
  Select-Object `
    @{ Name = "SentAt"; Expression = { $_.sent_at } }, `
    @{ Name = "To"; Expression = { (@($_.to) -join "; ") } }, `
    @{ Name = "Cc"; Expression = { (@($_.cc) -join "; ") } }, `
    @{ Name = "Bcc"; Expression = { (@($_.bcc) -join "; ") } }, `
    @{ Name = "Subject"; Expression = { $_.subject } }, `
    @{ Name = "Body"; Expression = { $_.body } }, `
    @{ Name = "AttachmentPaths"; Expression = { (@($_.attachment_paths) -join "; ") } } |
  Format-List | Out-String | Write-Output
