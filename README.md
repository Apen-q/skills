# daily-report-emailer

GitHub-ready repository layout for the `daily-report-emailer` Codex skill.

## Repository Layout

```text
skills/
  daily-report-emailer/
```

Install from the skill folder path, not from the repository root.

## Install

After publishing this repository to GitHub, install with Codex using the skill folder URL:

```text
$skill-installer https://github.com/<owner>/<repo>/tree/main/skills/daily-report-emailer
```

Or copy the folder manually into:

```text
~/.codex/skills/daily-report-emailer
```

## Configuration

This skill does not include SMTP credentials.

Each user must configure their own:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_FROM`
- `SMTP_USE_SSL`

The configuration helper script is inside:

```text
skills/daily-report-emailer/scripts/set-smtp-env.ps1
```

## Security

- Do not commit real SMTP passwords or authorization codes.
- Do not hardcode personal email accounts into scripts before publishing.
- Rotate any credential that was ever exposed in chat, terminal history, or git history.
