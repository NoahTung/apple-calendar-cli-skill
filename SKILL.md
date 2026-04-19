---
name: apple-calendar-cli
description: Hermes-first local CLIs for creating, listing, editing, deleting, batch-importing, and ticket-normalizing real Apple Calendar events on macOS with iCloud sync through Calendar.app.
version: 0.1.0
platforms:
  - macos
metadata:
  hermes:
    tags:
      - apple
      - calendar
      - productivity
      - automation
      - cli
      - hermes
    category: productivity
  openclaw:
    emoji: "🗓️"
    homepage: https://github.com/NoahTung/apple-calendar-cli-skill
    os:
      - macos
    requires:
      bins:
        - addcal
        - listcal
        - delcal
        - editcal
        - showcal
        - batchcal
        - img2cal
---

# Apple Calendar CLI

## When to Use

Use this skill when Hermes on macOS needs to manipulate the user's real Apple Calendar data through small, non-interactive local commands.

This skill is a strong fit when:

- the target is Calendar.app, not a generic CalDAV sync layer
- the user already has Apple Calendar or iCloud Calendar configured on macOS
- an agent needs safe local CRUD instead of interactive editing
- the workflow benefits from machine-readable output, batch imports, or ticket-to-calendar normalization

Prefer this skill over `khal` / `vdirsyncer` when the goal is:

- "manage my actual Apple Calendar on this Mac"
- "let Hermes or another local agent update Calendar.app directly"
- "avoid extra CalDAV configuration, sync caches, and `.ics` mirrors"

The same commands also work well for Codex, Claude Code, and other shell-capable agents, but the packaging and defaults are optimized for Hermes workflows first.

## Procedure

### 1. Confirm the calendar context

Before writing anything:

```bash
addcal --list-calendars
listcal --list-calendars
```

Use `--calendar` when the exact destination is known. Otherwise use `--bucket personal|work|life` as a routing hint.

### 2. Inspect before mutating

Before creating or changing events in a time range, inspect current events first:

```bash
listcal --calendar "个人" --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
```

Prefer `--format tsv` or `--format json` for agent workflows.

### 3. Create events

Short form:

```bash
addcal "2026-04-18 19:00" "2026-04-18 20:00" "吃饭"
```

Structured form:

```bash
addcal --calendar "个人" --start "2026-04-18 19:00" --end "2026-04-18 20:00" --title "吃饭"
addcal --bucket work --start "tomorrow 9am" --end "tomorrow 10am" --title "Standup" --alarm 15
addcal --calendar "个人" --start "2026-04-18 18:00" --end "2026-04-18 19:00" --title "健身" --repeat "weekly 1,3,5"
addcal --calendar "个人" --start "2026-04-20" --title "请假" --all-day
```

For sensitive or structured payloads, prefer JSON stdin:

```bash
echo '{"calendar":"个人","title":"吃饭","start":"2026-04-20 19:00","end":"2026-04-20 20:00","notes":"已订位"}' | addcal --stdin-json
echo '{"calendar":"个人","title":"全天事项","start":"2026-04-20","all_day":true}' | addcal --stdin-json
```

Recurrence options:

```bash
addcal --calendar "个人" --start "2026-04-18 18:00" --end "2026-04-18 19:00" --title "健身" --repeat "weekly 1,3,5"
addcal --calendar "个人" --start "2026-04-18 18:00" --end "2026-04-18 19:00" --title "值班" --rrule "FREQ=WEEKLY;BYDAY=MO,WE,FR"
```

`--rrule` overrides `--repeat` when both are provided.

### 4. Inspect a single event or capture ids

Use one of these:

```bash
showcal --id "0243912F-0D42-4477-A193-A881F73E7434"
showcal --id "0243912F-0D42-4477-A193-A881F73E7434" --format json
listcal --calendar "个人" --today --format tsv
```

Safe mutation starts with an exact event id whenever possible.

### 5. Edit events

Update by id:

```bash
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --start "2026-04-18 21:00" --end "2026-04-18 22:00"
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --title "剪辑视频v2" --alarm 10 --dry-run
```

JSON stdin is also supported:

```bash
echo '{"id":"0243912F-0D42-4477-A193-A881F73E7434","title":"Dinner v2"}' | editcal --stdin-json
```

### 6. Delete events

Prefer deletion by id:

```bash
delcal --id "0243912F-0D42-4477-A193-A881F73E7434"
```

If matching by title and time, preview first:

```bash
delcal --calendar "个人" --title "吃饭" --start "2026-04-18 19:00" --end "2026-04-18 20:00" --dry-run
```

### 7. Use batch import for larger schedules

`batchcal` is JSON-first:

```bash
batchcal --plan semester.json --dry-run
batchcal --plan semester.json --apply
cat birthdays.json | batchcal --stdin --dry-run
```

### 8. Use `img2cal` for ticket-style events

`img2cal` does not perform OCR itself. The agent should extract structured fields first, then normalize or create the event.

Examples:

```bash
img2cal --type movie --title "奥本海默" --start "2026-05-01 19:30" --location "万达影城" --seat "8排12座" --draft
img2cal --type train --title "G1234" --start "2026-06-15 08:00" --end "2026-06-15 12:30" --location "上海虹桥站" --carriage "05车" --gate "12A" --apply
echo '{"seat":"12A","boarding_gate":"58","terminal":"T2"}' | img2cal --type flight --title "CA9876" --start "2026-07-20 14:00" --end "2026-07-20 16:30" --location "上海浦东" --stdin --draft
```

Recommended workflow:

1. Extract structured ticket fields from the user's image or message
2. Create a draft with `img2cal --draft`
3. Surface conflicts in the target time range
4. Only apply after confirmation

## Pitfalls

- Always inspect the relevant time range with `listcal` before creating or moving events. This avoids accidental overlap.
- Prefer `--calendar` when the target is explicit. Use `--bucket` only as a routing hint.
- Prefer deletion and editing by event id, not by fuzzy title matches.
- `batchcal` does not parse natural language. The agent must produce JSON first.
- Prefer `--stdin-json` for sensitive or structured payloads so details stay out of shell history and process arguments.
- Conflict checking is enabled by default for new events. Use `--no-check-conflict` only when overlap is intentional.
- All-day events use `YYYY-MM-DD` input and can be created with `--all-day` or `"all_day": true` in JSON stdin.
- `--rrule` is the advanced recurrence path and overrides `--repeat`.
- This skill is macOS-only and depends on Calendar.app through AppleScript.
- Calendar.app or Hermes may prompt for first-run permissions; approve those prompts once.
- This skill works on real Apple Calendar / iCloud data, not standalone `.ics` files.
- Alarm handling is centered on `display alarm`; audio, email, and open-file alarm types are not fully preserved across inspect/edit flows.
- `img2cal` normalizes already-extracted ticket fields. It is not an OCR tool by itself.

## Verification

After any meaningful operation, verify the result with one of:

```bash
listcal --calendar "个人" --today --format tsv
showcal --id "<event-id>" --format json
```

Useful checks:

- the event appears in the expected calendar
- `start`, `end`, `location`, `notes`, `alarm`, and `recurrence` match the intended values
- all-day events are represented as all-day in Calendar.app
- no unexpected overlaps were introduced unless intentionally allowed

If you are debugging a mutation issue, reduce the payload first:

1. try title + start + end only
2. add `location`, `notes`, `url`, `alarm`, or `recurrence` one field at a time
3. compare behavior between iCloud calendars and local calendars if sync errors appear
