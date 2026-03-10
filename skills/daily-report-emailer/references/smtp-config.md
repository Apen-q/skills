# SMTP 配置

本文件中的示例值仅用于说明，不应替换成真实密码后再随 skill 一起分发。

发送脚本 `scripts/send-report-email.ps1` 默认优先从以下环境变量读取 SMTP 配置：

- `SMTP_HOST`: SMTP 服务器地址，例如 `smtp.163.com`
- `SMTP_PORT`: SMTP 端口，例如 `25`
- `SMTP_USERNAME`: SMTP 登录账号
- `SMTP_PASSWORD`: SMTP 登录密码或授权码
- `SMTP_FROM`: 发件人邮箱，默认回退到 `SMTP_USERNAME`
- `SMTP_USE_SSL`: 是否启用 SSL，支持 `true` / `false`

当前环境下已验证可用的网易 163 组合：

- `SMTP_HOST=smtp.163.com`
- `SMTP_PORT=25`
- `SMTP_USE_SSL=false`

这不是所有邮箱服务商的通用默认值；其他邮箱、企业邮箱或不同网络环境下，端口和 SSL 配置可能不同。

## 调用方式

以下示例假设你已经先配置好了环境变量：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\daily-report-emailer\scripts\send-report-email.ps1 `
  -To "target@example.com" `
  -Subject "今日日报 - 2026-03-10" `
  -Body "今日完成：...`n明日计划：..." `
  -SmtpHost "smtp.163.com" `
  -Port 25 `
  -UseSsl "false"
```

## 显式覆盖配置

如果不希望使用环境变量，可以显式传入完整 SMTP 参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\daily-report-emailer\scripts\send-report-email.ps1 `
  -To "target@example.com" `
  -Subject "测试邮件" `
  -Body "这是一封测试邮件" `
  -SmtpHost "smtp.example.com" `
  -Port 587 `
  -Username "sender@example.com" `
  -Password "smtp-password" `
  -From "sender@example.com" `
  -UseSsl "true"
```

## 干跑模式

先验证参数是否完整，而不真正发信：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\daily-report-emailer\scripts\send-report-email.ps1 `
  -To "target@example.com" `
  -Subject "测试邮件" `
  -Body "这是一封测试邮件" `
  -DryRun
```

## 写入 Windows 用户环境变量

如果希望给 `daily-report-emailer` 长期使用，可以运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\daily-report-emailer\scripts\set-smtp-env.ps1 `
  -SmtpHost "smtp.163.com" `
  -Port 25 `
  -Username "your-163-email@163.com" `
  -Password "smtp-password" `
  -From "your-163-email@163.com" `
  -UseSsl "false"
```

写入后需重新打开终端，新的环境变量才会在后续会话中生效。

## 分享给其他人时

- 可以分享整个 `daily-report-emailer` skill 文件夹。
- 不要把真实 `SMTP_PASSWORD`、邮箱账号或其他密钥写入脚本后再发给别人。
- 让对方在自己的机器上单独执行 `set-smtp-env.ps1`，或在发信时自己传参。
