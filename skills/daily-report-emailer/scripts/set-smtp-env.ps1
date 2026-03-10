[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$SmtpHost,

  [Parameter(Mandatory = $true)]
  [int]$Port,

  [Parameter(Mandatory = $true)]
  [string]$Username,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  [string]$From,

  [string]$UseSsl = "true"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($From)) {
  $From = $Username
}

$normalizedUseSsl = [System.Convert]::ToBoolean($UseSsl)

[Environment]::SetEnvironmentVariable("SMTP_HOST", $SmtpHost, "User")
[Environment]::SetEnvironmentVariable("SMTP_PORT", [string]$Port, "User")
[Environment]::SetEnvironmentVariable("SMTP_USERNAME", $Username, "User")
[Environment]::SetEnvironmentVariable("SMTP_PASSWORD", $Password, "User")
[Environment]::SetEnvironmentVariable("SMTP_FROM", $From, "User")
[Environment]::SetEnvironmentVariable("SMTP_USE_SSL", [string]$normalizedUseSsl, "User")

Write-Output "SMTP environment variables saved for current user."
Write-Output "Open a new terminal session before sending email."
