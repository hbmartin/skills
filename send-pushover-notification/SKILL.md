---
name: send-pushover-notification
description: Send a notification after work completes. Use when Codex should alert you about task completion or important milestones.
---

# Send Pushover Notification

Use this skill to send a single completion alert through Pushover at the end of work. Keep message text short and factual.

## Quick Start

```bash
scripts/send_pushover.sh --message "<status>: <summary>"
```


## Workflow

1. Finish the requested task.
2. Compose a concise completion message.
3. Run `scripts/send_pushover.sh --message "<message>"`.
4. If script exits non-zero, report notification failure and the reason.

## Script Contract

- Required option:
  - `--message`
- Optional options:
  - `--title` (default `Codex Task Complete`)
  - `--priority` (default `0`)
