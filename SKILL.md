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

## First-run permissions

- The first run may prompt for Calendar automation permission.
- Some host environments such as Hermes may also show their own access prompts for scripts or workspace files.
- If a prompt appears, approve it once so the CLI can reach Calendar.app cleanly.

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
addcal --bucket work --start "2026-04-18 09:00" --end "2026-04-18 09:30" --title "Team standup"
```

`--calendar` is the explicit override.
`--bucket` is an agent hint (`personal`, `work`, `life`), not a replacement for real calendars.
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

Route events in this order:

1. Use `--calendar` when the exact calendar is known.
2. Use `--bucket` to infer a likely destination calendar.
3. Prefer the exact mapped calendars for that bucket when they exist: `个人`/`Personal`, `工作`/`Work`, or `生活`/`Life`.
4. Use `listcal --list-calendars` if the choice is still unclear.
5. Fall back to the default calendar only when nothing else fits.

Then:

1. Use `addcal` to create new events.
2. Use `listcal --format tsv` to inspect existing events and capture ids.
3. Use `delcal --id ...` for safe deletion.

## Notes

- Datetime format is `YYYY-MM-DD HH:MM`.
- These commands are macOS-only because they depend on Calendar.app.
- This skill is for real Apple Calendar / iCloud data, not local `.ics` files.

## Pitfalls

- **No `--alarm` option**: `addcal` does not support `--alarm`. Calendar.app default alert settings apply automatically.
- **Install location**: This skill lives at `~/skills/apple-calendar-cli/`, not `~/.hermes/skills/`. Use full path `/Users/mac/skills/apple-calendar-cli/addcal` if the skill is not installed in the Hermes skills directory.
- **Always check `--help` first**: The CLI syntax may differ from intuition (e.g. short form `addcal "start" "end" "title"` vs long form with `--start`, `--end`, `--title`, `--calendar`).
