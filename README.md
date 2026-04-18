# Apple Calendar CLI Skill

Agent-first Apple Calendar and iCloud automation for macOS.

Use Apple Calendar and iCloud calendars on macOS through a small set of non-interactive local CLIs:

- `addcal`
- `listcal`
- `delcal`

This setup is designed for agents such as Codex, Claude Code, Hermes, or any tool that can run shell commands locally.

## Why This Project Exists

Most calendar automation on GitHub falls into one of these buckets:

- CalDAV-first tools like `khal` and `vdirsyncer`
- generic AppleScript snippets
- large MCP or automation servers that do far more than calendar operations

This project targets a narrower and more practical use case:

> Give coding agents a tiny, reliable command-line interface for the user's real Apple Calendar on macOS.

That means:

- no interactive TTY workflow
- no extra CalDAV sync layer
- no local `.ics`-only detour
- no giant automation framework required

Just:

`agent -> addcal/listcal/delcal -> Calendar.app -> iCloud`

## Key Advantages

- **Agent-first**: built for Codex, Claude Code, Hermes, and other shell-capable agents
- **Non-interactive**: create, list, and delete without opening a UI or stepping through prompts
- **Uses the real Apple Calendar**: events land in Calendar.app, not in a sidecar file format
- **iCloud-native through the OS**: if Calendar.app already syncs, these commands sync too
- **Much simpler than CalDAV stacks**: no `vdirsyncer`, no `khal` config, no separate sync troubleshooting
- **Small surface area**: three commands are easy to audit, script, and extend

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

## Files

- [SKILL.md](/Users/mac/skills/apple-calendar-cli/SKILL.md): agent-facing instructions
- `addcal`: create events
- `listcal`: list events
- `delcal`: delete events

This repository is meant to be self-contained: publish the docs and the three CLI scripts together.

## Installation

Clone the repo, then copy the three scripts into a directory on your `PATH`:

```bash
mkdir -p ~/.local/bin
cp addcal listcal delcal ~/.local/bin/
chmod +x ~/.local/bin/addcal ~/.local/bin/listcal ~/.local/bin/delcal
```

Verify:

```bash
addcal --list-calendars
listcal --list-calendars
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
```

### List events

```bash
listcal
listcal "Personal"
listcal "Personal" "2026-04-18 00:00" "2026-04-19 00:00"
listcal --all-calendars --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
```

For agents, prefer TSV output:

```bash
listcal --calendar "Personal" --start "2026-04-18 00:00" --end "2026-04-19 00:00" --format tsv
```

Columns:

```text
id    calendar    title    start    end
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

## Recommended Agent Workflow

1. Run `listcal --list-calendars` if the target calendar is unknown.
2. Use `addcal` to create events.
3. Use `listcal --format tsv` to inspect events and capture event ids.
4. Use `delcal --id ...` for reliable deletion.

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
- datetime input format is `YYYY-MM-DD HH:MM`
- list output timestamps come from AppleScript / system locale formatting
- this is for real Calendar.app data, not standalone `.ics` files

## Publishing Notes

If you publish this skill online, keep the repository self-contained:

- `README.md`
- `SKILL.md`
- `addcal`
- `listcal`
- `delcal`

Without the companion CLI commands, the skill text alone is not enough.
