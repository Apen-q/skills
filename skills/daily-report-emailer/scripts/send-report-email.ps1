[CmdletBinding()]
param(
  [string[]]$To = @(),
  [string[]]$Cc = @(),
  [string[]]$Bcc = @(),
  [string]$Subject = "",
  [string]$Body = "",
  [string]$SmtpHost = $env:SMTP_HOST,
  [int]$Port = $(if ($env:SMTP_PORT) { [int]$env:SMTP_PORT } else { 587 }),
  [string]$Username = $env:SMTP_USERNAME,
  [string]$Password = $env:SMTP_PASSWORD,
  [string]$From = $(if ($env:SMTP_FROM) { $env:SMTP_FROM } else { $env:SMTP_USERNAME }),
  [string]$UseSsl = $(if ($env:SMTP_USE_SSL) { [string]$env:SMTP_USE_SSL } else { "true" }),
  [string[]]$AttachmentPaths = @(),
  [string]$HistoryPath = $(Join-Path $env:USERPROFILE ".codex\skills-data\daily-report-emailer\send-history.json"),
  [switch]$UseLastRecipients,
  [switch]$UseLastContent,
  [switch]$UseLastAttachments,
  [switch]$BodyAsHtml,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-StringArray {
  param(
    [AllowNull()]
    [object[]]$Values
  )

  $result = @()
  foreach ($value in @($Values)) {
    if ($null -eq $value) {
      continue
    }
    $text = [string]$value
    if (-not [string]::IsNullOrWhiteSpace($text)) {
      $result += $text.Trim()
    }
  }
  return ,@($result)
}

function Test-RequiredValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    if ($Name -eq "Password") {
      throw "Missing required value: Password. Set SMTP_PASSWORD or pass -Password explicitly. Many email providers require an SMTP app password or authorization code instead of the login password."
    }
    elseif ($Name -eq "Username") {
      throw "Missing required value: Username. Set SMTP_USERNAME or pass -Username explicitly."
    }
    elseif ($Name -eq "SmtpHost") {
      throw "Missing required value: SmtpHost. Set SMTP_HOST or pass -SmtpHost explicitly."
    }
    elseif ($Name -eq "From") {
      throw "Missing required value: From. Set SMTP_FROM or pass -From explicitly."
    }
    elseif ($Name -eq "To") {
      throw "Missing required value: To. Pass at least one recipient via -To or use -UseLastRecipients."
    }
    else {
      throw "Missing required value: $Name"
    }
  }
}

function Assert-FileExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Attachment file not found: $Path"
  }
}

function Ensure-ParentDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $parent = Split-Path -Path $Path -Parent
  if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
}

function Read-History {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return $null
  }

  $raw = Get-Content -LiteralPath $Path -Raw -Encoding utf8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $null
  }

  return $raw | ConvertFrom-Json
}

function Write-History {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [object]$Entry
  )

  $history = Read-History -Path $Path
  $previousEntries = @()
  if ($null -ne $history -and $null -ne $history.history) {
    $previousEntries = @($history.history)
  }

  $newHistory = @($Entry) + $previousEntries
  if ($newHistory.Count -gt 20) {
    $newHistory = @($newHistory[0..19])
  }

  $payload = [PSCustomObject]@{
    last    = $Entry
    history = $newHistory
  }

  Ensure-ParentDirectory -Path $Path
  $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding utf8
}

$history = Read-History -Path $HistoryPath
$lastEntry = if ($null -ne $history) { $history.last } else { $null }

$resolvedTo = Normalize-StringArray -Values $To
$resolvedCc = Normalize-StringArray -Values $Cc
$resolvedBcc = Normalize-StringArray -Values $Bcc
$resolvedAttachmentPaths = Normalize-StringArray -Values $AttachmentPaths

if ($UseLastRecipients) {
  if ($null -eq $lastEntry) {
    throw "No previous send history found. Cannot use last recipients."
  }
  if ($resolvedTo.Count -eq 0) {
    $resolvedTo = Normalize-StringArray -Values $lastEntry.to
  }
  if ($resolvedCc.Count -eq 0) {
    $resolvedCc = Normalize-StringArray -Values $lastEntry.cc
  }
  if ($resolvedBcc.Count -eq 0) {
    $resolvedBcc = Normalize-StringArray -Values $lastEntry.bcc
  }
}

if ($UseLastContent) {
  if ($null -eq $lastEntry) {
    throw "No previous send history found. Cannot use last content."
  }
  if ([string]::IsNullOrWhiteSpace($Subject)) {
    $Subject = [string]$lastEntry.subject
  }
  if ([string]::IsNullOrWhiteSpace($Body)) {
    $Body = [string]$lastEntry.body
  }
}

if ($UseLastAttachments) {
  if ($null -eq $lastEntry) {
    throw "No previous send history found. Cannot use last attachments."
  }
  if ($resolvedAttachmentPaths.Count -eq 0) {
    $resolvedAttachmentPaths = Normalize-StringArray -Values $lastEntry.attachment_paths
  }
}

Test-RequiredValue -Name "To" -Value ($resolvedTo -join ";")
Test-RequiredValue -Name "Subject" -Value $Subject
Test-RequiredValue -Name "Body" -Value $Body
Test-RequiredValue -Name "SmtpHost" -Value $SmtpHost
Test-RequiredValue -Name "Username" -Value $Username
Test-RequiredValue -Name "Password" -Value $Password
Test-RequiredValue -Name "From" -Value $From

$normalizedUseSsl = [System.Convert]::ToBoolean($UseSsl)

foreach ($attachmentPath in $resolvedAttachmentPaths) {
  Assert-FileExists -Path $attachmentPath
}

if ($DryRun) {
  [PSCustomObject]@{
    To                 = ($resolvedTo -join "; ")
    Cc                 = ($resolvedCc -join "; ")
    Bcc                = ($resolvedBcc -join "; ")
    Subject            = $Subject
    SmtpHost           = $SmtpHost
    Port               = $Port
    Username           = $Username
    From               = $From
    UseSsl             = $normalizedUseSsl
    BodyAsHtml         = [bool]$BodyAsHtml
    BodyLength         = $Body.Length
    AttachmentCount    = $resolvedAttachmentPaths.Count
    AttachmentPaths    = ($resolvedAttachmentPaths -join "; ")
    HistoryPath        = $HistoryPath
    UseLastRecipients  = [bool]$UseLastRecipients
    UseLastContent     = [bool]$UseLastContent
    UseLastAttachments = [bool]$UseLastAttachments
    Mode               = "dry-run"
  } | Format-List | Out-String | Write-Output
  exit 0
}

$message = New-Object System.Net.Mail.MailMessage
$message.From = $From
foreach ($recipient in $resolvedTo) {
  $null = $message.To.Add($recipient)
}
foreach ($recipient in $resolvedCc) {
  $null = $message.CC.Add($recipient)
}
foreach ($recipient in $resolvedBcc) {
  $null = $message.Bcc.Add($recipient)
}
$message.Subject = $Subject
$message.Body = $Body
$message.IsBodyHtml = [bool]$BodyAsHtml
$message.BodyEncoding = [System.Text.Encoding]::UTF8
$message.SubjectEncoding = [System.Text.Encoding]::UTF8

foreach ($attachmentPath in $resolvedAttachmentPaths) {
  $attachment = New-Object System.Net.Mail.Attachment($attachmentPath)
  $null = $message.Attachments.Add($attachment)
}

$client = New-Object System.Net.Mail.SmtpClient($SmtpHost, $Port)
$client.EnableSsl = $normalizedUseSsl
$client.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)

try {
  $client.Send($message)

  $entry = [PSCustomObject]@{
    sent_at          = [DateTime]::Now.ToString("s")
    to               = $resolvedTo
    cc               = $resolvedCc
    bcc              = $resolvedBcc
    subject          = $Subject
    body             = $Body
    attachment_paths = $resolvedAttachmentPaths
    body_as_html     = [bool]$BodyAsHtml
  }
  Write-History -Path $HistoryPath -Entry $entry

  Write-Output ("Email sent to " + ($resolvedTo -join ", "))
}
catch [System.Net.Mail.SmtpException] {
  $baseMessage = $_.Exception.Message
  $innerMessage = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { "" }
  throw "SMTP send failed. $baseMessage $innerMessage Check SMTP host, port, SSL, and whether the SMTP authorization code/app password is valid."
}
finally {
  $message.Dispose()
  $client.Dispose()
}
