# Apple Calendar CLI Skill

![version](https://img.shields.io/badge/version-0.1.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS-black)
![calendar](https://img.shields.io/badge/calendar-Apple%20Calendar-red)
![sync](https://img.shields.io/badge/sync-iCloud-blue)
![interface](https://img.shields.io/badge/interface-local%20CLI-orange)
![mode](https://img.shields.io/badge/mode-non--interactive-yellow)

Hermes-first local CLIs for the real Apple Calendar on macOS.

Manage Calendar.app and iCloud calendars through small non-interactive commands built for Hermes and other shell-capable agents:

- `addcal`
- `listcal`
- `delcal`
- `editcal`
- `showcal`
- `batchcal`
- `img2cal`

Use this repo when you want:

- direct writes to the real Calendar.app database
- iCloud sync through the OS
- non-interactive local CLI commands for CRUD, batch import, and ticket normalization
- a macOS-native workflow instead of a CalDAV stack, cache DB, or `.ics` mirror

This repo is built for one very specific path:

`Hermes -> local calendar CLIs -> Calendar.app -> iCloud`

The same commands work for Codex, Claude Code, and any other shell-capable agent, but the packaging and defaults are designed with Hermes workflows in mind first.

## Best Fit

Use this skill when:

- you are on macOS
- Calendar.app is already connected to iCloud
- you want a stable local CLI for agents
- you want non-interactive commands that are easy to script

This is a better fit than `khal` when the target is the real Apple Calendar database on a Mac and the caller is an agent or script.

## Why This Exists

Most calendar automation tools optimize for a different target:

- CalDAV portability
- ad-hoc AppleScript snippets
- large automation or MCP servers

There is also an ecosystem gap on macOS itself:

- Apple ships the built-in `shortcuts` command-line tool, which can drive automation flows including Reminders-oriented workflows
- Apple does not provide an equivalent dedicated CLI for Calendar.app event management

This repo exists to let a local agent create, inspect, update, delete, batch-import, and ticket-normalize events in the user's actual Apple Calendar on macOS.

## Why This Repo Instead

| Option | Good for | Tradeoff | This repo's angle |
| --- | --- | --- | --- |
| `khal` + `vdirsyncer` | CalDAV-first and cross-platform workflows | extra sync layer, more config, not aimed at Calendar.app directly | skip the CalDAV stack when the target is already Apple Calendar on a Mac |
| Apple Shortcuts + Reminders flows | first-party automation building blocks on macOS | not a dedicated Calendar event CLI, and usually one layer farther from shell-friendly CRUD | provide direct shell commands for Calendar.app events |
| Random AppleScript snippets | quick one-off experiments | no stable CLI contract, harder for agents to reuse safely | package the behavior as named, repeatable commands |
| Large MCP / automation servers | broad assistant integrations | much larger surface area than simple calendar CRUD | keep the interface tiny, local, and auditable |
| **This repo** | **agent-driven Apple Calendar automation on macOS** | **macOS-only by design** | **small non-interactive CLIs for real Calendar.app data** |

That means:

- no interactive TTY workflow
- no extra CalDAV sync layer
- no local `.ics`-only detour
- no giant automation framework required

## Compared With CalDAV Toolchains

`khal` + `vdirsyncer` and similar CalDAV stacks are good tools, but they optimize for a different workflow.

Choose a CalDAV toolchain when you want:

- cross-platform calendar access
- provider-agnostic sync across iCloud, Google, Fastmail, Nextcloud, and other CalDAV services
- a local `.ics` mirror and explicit sync control
- a workflow centered on `khal` and `vdirsyncer`

Choose this repo when you want:

- macOS-native control of the real Calendar.app data
- the shortest path from agent command to Apple Calendar event
- non-interactive local CLI commands for CRUD, batch import, and ticket normalization
- no extra sync layer, CalDAV config, cache DB, or separate `.ics` storage to manage

The tradeoff is intentional:

- CalDAV toolchains are broader and more portable
- this repo is narrower, but much better aligned with Hermes-style local agent workflows on macOS

In other words:

- if your goal is "manage calendars everywhere through CalDAV," use `khal` / `vdirsyncer`
- if your goal is "let my local agent manage my actual Apple Calendar on this Mac," this repo is usually the better fit

## Requirements

- macOS
- Calendar.app
- Apple Calendar / iCloud calendar already configured in the system
- permission for the calling terminal/app to control Calendar via AppleScript if macOS prompts for it

### First-run permissions

The first run may trigger a macOS Calendar automation prompt. If that happens, approve it once so these CLIs can reach Calendar.app cleanly.

## Installation

### General install (any macOS user)

Clone the repo, then copy the CLI scripts into a directory on your `PATH`:

```bash
mkdir -p ~/.local/bin
cp addcal listcal delcal editcal showcal batchcal img2cal calendar-lib.sh ~/.local/bin/
chmod +x ~/.local/bin/addcal ~/.local/bin/listcal ~/.local/bin/delcal ~/.local/bin/editcal ~/.local/bin/showcal ~/.local/bin/batchcal ~/.local/bin/img2cal
```

Verify:

```bash
addcal --list-calendars
listcal --list-calendars
showcal --help
img2cal --help
```

### Hermes skill install

For Hermes users, keep the repo in `~/skills` or link it under `~/.hermes/skills/`:

```bash
mkdir -p ~/skills
git clone <repo-url> ~/skills/apple-calendar-cli
# Or symlink if you already cloned elsewhere
ln -s ~/skills/apple-calendar-cli ~/.hermes/skills/apple-calendar-cli
```

Hermes can then call these commands directly from skill workflows using full paths or by ensuring `~/.local/bin` is on `PATH`.

## Privacy And Permissions

- Commands run locally on macOS and talk to Calendar.app through AppleScript.
- Persistent event logging is **disabled by default**.
- The first run may trigger a macOS automation permission prompt for Calendar. Approve it once for the terminal or agent app you are using.
- When possible, prefer **JSON via stdin** for long notes or structured payloads instead of exposing them in process arguments. This reduces visibility in shell history and process listings.
- This project writes to your real local Calendar.app data, not a sidecar file or separate `.ics` store.
- Event details passed as command-line arguments may appear in shell history. Use `--stdin-json` (where supported) or pipe data for sensitive content.

## Command Usage

### List calendars

```bash
addcal --list-calendars
listcal --list-calendars
```

### Create events

Short form:

```bash
addcal "2026-04-18 19:00" "2026-04-18 20:00" "Dinner"
addcal "Work" "2026-04-18 17:00" "2026-04-18 18:00" "Deep work"
```

Structured form:

```bash
addcal --calendar "Personal" --start "2026-04-18 19:00" --end "2026-04-18 20:00" --title "Dinner"
addcal --bucket work --start "2026-04-18 09:00" --end "2026-04-18 09:30" --title "Team standup"
addcal --calendar "Personal" --start "today 18:00" --end "today 19:00" --title "Dinner" --location "Mall" --notes "Booked" --alarm 15
addcal --calendar "Personal" --start "2026-04-18 18:00" --end "2026-04-18 19:00" --title "Gym" --repeat "weekly 1,3,5"
```

JSON stdin (preferred for agent workflows to avoid shell-history leakage):

```bash
echo '{"calendar":"Personal","title":"Dinner","start":"2026-04-20 19:00","end":"2026-04-20 20:00","notes":"Booked"}' | addcal --stdin-json
echo '{"calendar":"Personal","title":"All-day event","start":"2026-04-20","all_day":true}' | addcal --stdin-json
```

Routing is intentionally simple: `--calendar` wins when the exact destination is known, and `--bucket` (`personal`, `work`, or `life`) is only a hint for picking a likely calendar. It first prefers mapped calendars such as `个人`/`Personal`, `工作`/`Work`, or `生活`/`Life`, then falls back to the default calendar if no match exists. This CLI does not try to understand full natural-language requests.

Recurrence can be specified with the friendly `--repeat` DSL or with `--rrule` for native recurrence rules. `--rrule` overrides `--repeat` when both are provided.

### List events

```bash
listcal
listcal "Personal"
listcal "Personal" "2026-04-18 00:00" "2026-04-19 00:00"
listcal --all-calendars --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
listcal --today --format json
listcal --this-week --title-contains "Gym"
```

For agents, prefer TSV output:

```bash
listcal --calendar "Personal" --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
```

Columns:

```text
id    calendar    title    start    end    location    notes    url    alarm    recurrence
```

### Show one event

```bash
showcal --id "0243912F-0D42-4477-A193-A881F73E7434"
showcal --id "0243912F-0D42-4477-A193-A881F73E7434" --format json
```

### Edit an event

```bash
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --start "2026-04-18 21:00" --end "2026-04-18 22:00"
editcal --id "0243912F-0D42-4477-A193-A881F73E7434" --title "剪辑视频v2" --alarm 10 --dry-run
```

JSON stdin:

```bash
echo '{"id":"0243912F-0D42-4477-A193-A881F73E7434","title":"Dinner v2"}' | editcal --stdin-json
```

### Delete events

Safest form, by id:

```bash
delcal --id "0243912F-0D42-4477-A193-A881F73E7434"
```

Exact-match form:

```bash
delcal --calendar "Personal" --title "Dinner" --start "2026-04-18 19:00" --end "2026-04-18 20:00"
```

Preview before deleting:

```bash
delcal --calendar "Personal" --title "Dinner" --start "2026-04-18 19:00" --end "2026-04-18 20:00" --dry-run
```

### Batch import from JSON

```bash
batchcal --plan semester.json --dry-run
batchcal --plan semester.json --apply
cat birthdays.json | batchcal --stdin --dry-run
```

### Normalize ticket data into calendar event

`img2cal` does **not** perform image recognition. The agent or LLM must extract structured ticket fields first, then pass them to `img2cal` for normalization and calendar creation.

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

- Adds a title prefix (`看电影：`, `高铁：`, `汽车：`, `航班：`, `演唱会：`)
- Computes default `end` times (`movie` +150 min, `concert` +180 min)
- Formats extra fields (seat, gate, terminal, etc.) into `notes`
- Resolves `location` via `personal-context.json` `common_venues`
- Chooses `bucket` or `calendar` via `personal-context.json` preferences
- Checks for conflicts before `--apply` when an explicit calendar is known

## Recommended Agent Workflow

1. Resolve the destination with `--calendar`, or use `--bucket` if the exact calendar is not known.
2. Run `listcal` first to inspect the time range and avoid accidental overlap.
3. Create with `addcal`; for agent-generated payloads, prefer `echo '{...}' | addcal --stdin-json`.
4. Capture exact ids with `listcal --format tsv` or `showcal --format json`, then update with `editcal --id ...` or delete with `delcal --id ...`.
5. Use `batchcal --dry-run` for large imports and `img2cal --draft` before ticket-based event creation.

For automation, prefer deletion by event id rather than by title only.

The safest mutation path is **id-first**: list, capture the exact id, then edit or delete by that id. This avoids ambiguity when multiple events share similar titles.

## Limitations

- macOS only
- depends on Calendar.app and AppleScript
- datetime input format accepts `YYYY-MM-DD HH:MM` plus light shortcuts like `today 18:00`, `tomorrow 9am`, and `+2h`
- all-day events use the same `YYYY-MM-DD` date input and are created as true all-day events in Calendar.app
- list output timestamps come from AppleScript / system locale formatting
- this is for real Calendar.app data, not standalone `.ics` files
- alarm handling is still centered on `display alarm`; other alarm types such as audio, email, or open-file alarms are not fully preserved across read/edit flows
- conflict checking is enabled by default for new events; use `--no-check-conflict` to bypass intentionally
