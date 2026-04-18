---
name: apple-calendar-cli
description: Manage Apple Calendar and iCloud calendars on macOS with non-interactive local CLIs: `addcal`, `listcal`, and `delcal`. Use when an agent needs to create, list, or delete real Calendar.app events that should sync to iCloud.
metadata: {"clawdbot":{"emoji":"🗓️","os":["macos"],"requires":{"bins":["addcal","listcal","delcal"]}}}
---

# Apple Calendar CLI

Use these local commands instead of `khal` when the goal is to manipulate the real macOS Calendar.app data that syncs through iCloud.

## Why this skill

- `addcal`, `listcal`, and `delcal` are non-interactive and agent-friendly.
- They write to Apple Calendar directly through AppleScript.
- If Calendar.app is already connected to iCloud, changes sync automatically.

## Commands

### List calendars

```bash
addcal --list-calendars
listcal --list-calendars
```

### Create an event

```bash
addcal "2026-04-18 19:00" "2026-04-18 20:00" "吃饭"
addcal --calendar "个人" --start "2026-04-18 19:00" --end "2026-04-18 20:00" --title "吃饭"
```

Short form defaults to calendar `个人`.

### List events

```bash
listcal
listcal "个人"
listcal "个人" "2026-04-18 00:00" "2026-04-19 00:00"
listcal --all-calendars --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
```

Use `--format tsv` for agent parsing. Output columns are:

```text
id    calendar    title    start    end
```

### Delete events

Prefer deleting by event id from `listcal --format tsv` when possible:

```bash
delcal --id "0243912F-0D42-4477-A193-A881F73E7434"
```

Or match exactly by calendar + title + time window:

```bash
delcal --calendar "个人" --title "吃饭" --start "2026-04-18 19:00" --end "2026-04-18 20:00"
```

Use `--dry-run` before deletion if the match could be ambiguous.

## Agent workflow

1. Use `listcal --list-calendars` if the target calendar is unknown.
2. Use `addcal` to create new events.
3. Use `listcal --format tsv` to inspect existing events and capture ids.
4. Use `delcal --id ...` for safe deletion.

## Notes

- Datetime format is `YYYY-MM-DD HH:MM`.
- These commands are macOS-only because they depend on Calendar.app.
- This skill is for real Apple Calendar / iCloud data, not local `.ics` files.
