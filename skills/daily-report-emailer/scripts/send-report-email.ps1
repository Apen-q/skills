[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$To,

  [Parameter(Mandatory = $true)]
  [string]$Subject,

  [Parameter(Mandatory = $true)]
  [string]$Body,

  [string]$SmtpHost = $env:SMTP_HOST,
  [int]$Port = $(if ($env:SMTP_PORT) { [int]$env:SMTP_PORT } else { 587 }),
  [string]$Username = $env:SMTP_USERNAME,
  [string]$Password = $env:SMTP_PASSWORD,
  [string]$From = $(if ($env:SMTP_FROM) { $env:SMTP_FROM } else { $env:SMTP_USERNAME }),
  [string]$UseSsl = $(if ($env:SMTP_USE_SSL) { [string]$env:SMTP_USE_SSL } else { "true" }),
  [switch]$BodyAsHtml,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-RequiredValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw "Missing required value: $Name"
  }
}

Test-RequiredValue -Name "To" -Value $To
Test-RequiredValue -Name "Subject" -Value $Subject
Test-RequiredValue -Name "Body" -Value $Body
Test-RequiredValue -Name "SmtpHost" -Value $SmtpHost
Test-RequiredValue -Name "Username" -Value $Username
Test-RequiredValue -Name "Password" -Value $Password
Test-RequiredValue -Name "From" -Value $From

$normalizedUseSsl = [System.Convert]::ToBoolean($UseSsl)

if ($DryRun) {
  [PSCustomObject]@{
    To         = $To
    Subject    = $Subject
    SmtpHost   = $SmtpHost
    Port       = $Port
    Username   = $Username
    From       = $From
    UseSsl     = $normalizedUseSsl
    BodyAsHtml = [bool]$BodyAsHtml
    BodyLength = $Body.Length
    Mode       = "dry-run"
  } | Format-List | Out-String | Write-Output
  exit 0
}

$message = New-Object System.Net.Mail.MailMessage
$message.From = $From
$null = $message.To.Add($To)
$message.Subject = $Subject
$message.Body = $Body
$message.IsBodyHtml = [bool]$BodyAsHtml
$message.BodyEncoding = [System.Text.Encoding]::UTF8
$message.SubjectEncoding = [System.Text.Encoding]::UTF8

$client = New-Object System.Net.Mail.SmtpClient($SmtpHost, $Port)
$client.EnableSsl = $normalizedUseSsl
$client.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)

try {
  $client.Send($message)
  Write-Output "Email sent to $To"
}
finally {
  $message.Dispose()
  $client.Dispose()
}
