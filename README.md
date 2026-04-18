# Apple Calendar CLI Skill

Tiny agent-first CLIs for the real Apple Calendar on macOS.

Use Apple Calendar and iCloud calendars on macOS through a small set of non-interactive local CLIs:

- `addcal`
- `listcal`
- `delcal`
- `editcal`
- `showcal`
- `batchcal`

Built for Codex, Claude Code, Hermes, and any local agent that can run shell commands.

## Why This Exists

Most calendar automation tools optimize for a different target:

- CalDAV portability
- ad-hoc AppleScript snippets
- large automation or MCP servers

There is also an ecosystem gap on macOS itself:

- Apple ships the built-in `shortcuts` command-line tool, which can drive automation flows including Reminders-oriented workflows
- Apple does not provide an equivalent dedicated CLI for Calendar.app event management

This repo optimizes for one very specific workflow instead:

> Let an agent create, list, and delete events in the user's actual Apple Calendar on macOS, then let iCloud sync the result.

In practice, that means the shortest useful path is:

`agent -> addcal/listcal/delcal -> Calendar.app -> iCloud`

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

## Key Advantages

- **Agent-first**: built for Codex, Claude Code, Hermes, and other shell-capable agents
- **Non-interactive**: create, list, and delete without opening a UI or stepping through prompts
- **Uses the real Apple Calendar**: events land in Calendar.app, not in a sidecar file format
- **iCloud-native through the OS**: if Calendar.app already syncs, these commands sync too
- **Much simpler than CalDAV stacks**: no `vdirsyncer`, no `khal` config, no separate sync troubleshooting
- **Small surface area**: a compact set of focused commands is easy to audit, script, and extend

## What This Solves

Many calendar CLI workflows are built around `khal` + `vdirsyncer` + CalDAV sync. That can be useful, but it adds setup complexity and is often a poor fit when the real goal is simpler:

> Create, list, and delete events in the user's actual Apple Calendar, and let iCloud sync the result.

This skill takes the direct route:

`agent -> addcal/listcal/delcal -> Calendar.app -> iCloud`

Because it writes through macOS Calendar.app, events show up in Apple Calendar and sync through iCloud automatically if the account is already connected.

## Best Fit

Use this skill when:

- you are on macOS
- Calendar.app is already connected to iCloud
- you want a stable local CLI for agents
- you want non-interactive commands that are easy to script

This is a better fit than `khal` when the target is the real Apple Calendar database on a Mac and the caller is an agent or script.

## Requirements

- macOS
- Calendar.app
- Apple Calendar / iCloud calendar already configured in the system
- permission for the calling terminal/app to control Calendar via AppleScript if macOS prompts for it

### First-run permissions

The first run may trigger a macOS Calendar automation prompt. If that happens, approve it once so these CLIs can reach Calendar.app cleanly.

## Files

- [SKILL.md](/Users/mac/skills/apple-calendar-cli/SKILL.md): agent-facing instructions
- `addcal`: create events
- `listcal`: list events
- `delcal`: delete events
- `editcal`: edit an event by id
- `showcal`: inspect one event by id
- `batchcal`: dry-run or apply a JSON event plan
- `calendar-lib.sh`: shared helper library for the CLI scripts

This repository is meant to be self-contained: publish the docs and the three CLI scripts together.

## Installation

Clone the repo, then copy the three scripts into a directory on your `PATH`:

```bash
mkdir -p ~/.local/bin
cp addcal listcal delcal editcal showcal batchcal calendar-lib.sh ~/.local/bin/
chmod +x ~/.local/bin/addcal ~/.local/bin/listcal ~/.local/bin/delcal ~/.local/bin/editcal ~/.local/bin/showcal ~/.local/bin/batchcal
```

Verify:

```bash
addcal --list-calendars
listcal --list-calendars
showcal --help
```

If macOS asks for Calendar automation permission, allow it for the terminal or agent app you are using.

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

Routing is intentionally simple: `--calendar` wins when the exact destination is known, and `--bucket` (`personal`, `work`, or `life`) is only a hint for picking a likely calendar. It first prefers mapped calendars such as `个人`/`Personal`, `工作`/`Work`, or `生活`/`Life`, then falls back to the default calendar if no match exists. This CLI does not try to understand full natural-language requests.

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

## Recommended Agent Workflow

1. Use `--calendar` when the exact destination calendar is known.
2. Use `--bucket` to hint at a likely destination when the exact calendar is not known.
3. Run `listcal --list-calendars` if the choice is still unclear.
4. Use `addcal` to create events.
5. Use `listcal --format tsv` or `showcal --format json` to inspect events and capture event ids.
6. Use `editcal --id ...` for safe updates.
7. Use `delcal --id ...` for reliable deletion.
8. Use `batchcal --dry-run` before large imports.

For automation, prefer deletion by event id rather than by title only.

## Why It Stands Out

Compared with nearby tools, this project makes a different tradeoff:

- compared with `khal` / `vdirsyncer`: it optimizes for macOS-native iCloud control instead of CalDAV portability
- compared with one-off AppleScript snippets: it provides reusable, named CLIs with a stable interface
- compared with large MCP servers: it stays small, local, and easy to adopt

If your target is "make my agent manage my actual Apple Calendar on my Mac", this project is intentionally the shortest path.

## Why Not khal / vdirsyncer?

This skill intentionally does not depend on `khal` or `vdirsyncer`.

Those tools are useful for:

- CalDAV-first workflows
- local `.ics` / vdir storage
- Linux and cross-platform sync setups
- teams already committed to that toolchain

But if the user's machine is a Mac and the goal is simply to operate the real Apple Calendar that already syncs to iCloud, AppleScript through Calendar.app is usually the shortest and most reliable path.

## Limitations

- macOS only
- depends on Calendar.app and AppleScript
- datetime input format accepts `YYYY-MM-DD HH:MM` plus light shortcuts like `today 18:00`, `tomorrow 9am`, and `+2h`
- list output timestamps come from AppleScript / system locale formatting
- this is for real Calendar.app data, not standalone `.ics` files
- alarm handling is still centered on `display alarm`; other alarm types such as audio, email, or open-file alarms are not fully preserved across read/edit flows

## Publishing Notes

If you publish this skill online, keep the repository self-contained:

- `README.md`
- `SKILL.md`
- `addcal`
- `listcal`
- `delcal`

Without the companion CLI commands, the skill text alone is not enough.
