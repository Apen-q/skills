[CmdletBinding()]
param(
  [string]$Subject = "",
  [string]$Body = "",
  [string]$HistoryPath = $(Join-Path $env:USERPROFILE ".codex\skills-data\daily-report-emailer\send-history.json"),
  [switch]$KeepLastContent,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "send-report-email.ps1"

$args = @{
  UseLastRecipients  = $true
  UseLastAttachments = $true
  HistoryPath        = $HistoryPath
}

if ($KeepLastContent) {
  $args.UseLastContent = $true
}
else {
  if (-not [string]::IsNullOrWhiteSpace($Subject)) {
    $args.Subject = $Subject
  }
  if (-not [string]::IsNullOrWhiteSpace($Body)) {
    $args.Body = $Body
  }
}

if ($DryRun) {
  $args.DryRun = $true
}

& $scriptPath @args
