---
name: apple-calendar-cli
description: Manage Apple Calendar and iCloud calendars on macOS with non-interactive local CLIs: `addcal`, `listcal`, `delcal`, `editcal`, `showcal`, `batchcal`, and `img2cal`. Use when an agent needs to create, inspect, update, delete, batch-import, or ticket-normalize real Calendar.app events that should sync to iCloud.
metadata: {"clawdbot":{"emoji":"🗓️","os":["macos"],"requires":{"bins":["addcal","listcal","delcal"]}}}
---

# Apple Calendar CLI

Use these local commands instead of `khal` when the goal is to manipulate the real macOS Calendar.app data that syncs through iCloud.

## Why this skill

- `addcal`, `listcal`, `delcal`, `editcal`, `showcal`, and `batchcal` are non-interactive and agent-friendly.
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
addcal --calendar "个人" --start "today 18:00" --end "today 19:00" --title "海底捞晚饭" --location "万达广场3楼" --notes "已订位，4人" --alarm 15
addcal --calendar "个人" --start "2026-04-18 18:00" --end "2026-04-18 19:00" --title "健身" --repeat "weekly 1,3,5"
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
id    calendar    title    start    end    location    notes    url    alarm    recurrence
```

### Inspect an event

```bash
showcal --id "0243912F-0D42-4477-A193-A881F73E7434"
showcal --id "0243912F-0D42-4477-A193-A881F73E7434" --format json
```

### Edit an event

```bash
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --start "2026-04-18 21:00" --end "2026-04-18 22:00"
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --title "剪辑视频v2" --alarm 10 --dry-run
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

### Batch import from JSON

```bash
batchcal --plan semester.json --dry-run
batchcal --plan semester.json --apply
cat birthdays.json | batchcal --stdin --dry-run
```

### Normalize ticket data into calendar event

`img2cal` does **not** perform image recognition. The agent/LLM must extract structured ticket fields first, then pass them to `img2cal` for normalization and calendar creation.

```bash
# Preview the normalized draft
img2cal --type movie --title "奥本海默" --start "2026-05-01 19:30" --location "万达影城" --seat "8排12座" --draft

# Create the event directly
img2cal --type train --title "G1234" --start "2026-06-15 08:00" --end "2026-06-15 12:30" --location "上海虹桥站" --carriage "05车" --gate "12A" --apply

# Pass extra fields via stdin JSON
echo '{"seat": "12A", "boarding_gate": "58", "terminal": "T2"}' | img2cal --type flight --title "CA9876" --start "2026-07-20 14:00" --end "2026-07-20 16:30" --location "上海浦东" --stdin --draft
```

Supported `--type` values: `movie`, `train`, `bus`, `flight`, `concert`.

`img2cal` automatically:
- Adds a title prefix (`看电影：`, `高铁：`, `航班：`, `演唱会：`)
- Computes default `end` times (`movie` +150 min, `concert` +180 min)
- Formats extra fields (seat, gate, terminal, etc.) into `notes`
- Resolves `location` via `personal-context.json` `common_venues`
- Chooses `bucket`/`calendar` via `personal-context.json` preferences
- Checks for conflicts before `--apply` (when explicit calendar is known)

## Agent workflow

Route events in this order:

1. **Before creating anything**, use `listcal --format tsv` to check existing events in the target time range. This avoids overlaps and conflicts.
2. Use `--calendar` when the exact calendar is known.
3. Use `--bucket` to infer a likely destination calendar.
4. Prefer the exact mapped calendars for that bucket when they exist: `个人`/`Personal`, `工作`/`Work`, or `生活`/`Life`.
5. Use `listcal --list-calendars` if the choice is still unclear.
6. Fall back to the default calendar only when nothing else fits.

Then:

1. Use `addcal` to create new events.
2. Use `listcal --format tsv` or `showcal --format json` to inspect existing events and capture ids.
3. Use `editcal --id ...` for safe updates.
4. Use `delcal --id ...` for safe deletion.
5. Use `batchcal --dry-run` before any large import.
6. Use `img2cal --draft` to normalize and preview ticket data before creating events.
7. Use `img2cal --apply` after the user confirms the ticket draft.

## Notes

- Datetime format is `YYYY-MM-DD HH:MM`.
- These commands are macOS-only because they depend on Calendar.app.
- This skill is for real Apple Calendar / iCloud data, not local `.ics` files.
- Alarm support is still centered on `display alarm`; audio, email, and open-file alarms are not fully preserved across inspect/edit flows.

## Ticket / Receipt Image Workflow

When the user sends a ticket image (movie, train, flight, bus, concert) or describes a ticket in natural language, follow this flow instead of immediately calling `addcal`:

1. **Extract structured fields** from the image or description:
   - `title`, `start`, `end`, `location`, `notes`
   - Infer missing `end` times using sensible defaults only when the intent is unambiguous (e.g. movie +150 min, concert +180 min).
   - If start time or title cannot be determined, stop and ask the user for clarification.

2. **Present a draft to the user** for confirmation:
   - Show the parsed fields in a concise summary.
   - Ask: "是否将此事件添加到日历？" or "Add this event to your calendar?"
   - If the user confirms, proceed to step 3. If they decline or request changes, stop.

3. **Before creating**, run `listcal` in the target time window to surface conflicts:
   - `listcal --calendar "<resolved-calendar>" --start "<start>" --end "<end>" --format tsv`
   - If conflicts exist, warn the user and ask whether to proceed.

4. **Create the event** via `addcal`:
   - Use `--calendar` if the exact calendar is known.
   - Otherwise use `--bucket` (`personal`, `work`, `life`) and let `addcal` resolve it.
   - Pass `--location`, `--notes`, `--alarm` as appropriate.

## Pitfalls

- **Agent 操作日历前应先 `listcal` 检查现有事件**：避免创建重叠或冲突的日程。用户明确反馈过这个问题。
- **Batch input is JSON-first**: `batchcal` does not parse natural language directly. The agent should turn user requests into JSON first, then run `batchcal`.
- **Install location**: This skill lives at `~/skills/apple-calendar-cli/`, not `~/.hermes/skills/`. Use full path `/Users/mac/skills/apple-calendar-cli/addcal` if the skill is not installed in the Hermes skills directory.
- **Always check `--help` first**: The CLI syntax may differ from intuition (e.g. short form `addcal "start" "end" "title"` vs long form with `--start`, `--end`, `--title`, `--calendar`).
- **No `--alarm` in older versions**: If you see `unknown option: --alarm`, the `addcal` script needs updating. Alarm support was added in a later revision.
- **Location auto-fill is not built-in yet**: `--auto-location` (calling map APIs) is a planned Phase 3 feature, not yet implemented.
