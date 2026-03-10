[CmdletBinding()]
param(
  [string]$To = "18547135961@163.com"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "send-report-email.ps1"
$subject = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("5q+P5pel5o+Q6YaS"))
$body = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("6Ieq5pG45pe26Ze05Yiw5LqG"))

& $scriptPath `
  -To $To `
  -Subject $subject `
  -Body $body
