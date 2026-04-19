# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-04-19

### Added

- Initial public release of `apple-calendar-cli`
- Non-interactive local CLI commands for Apple Calendar on macOS:
  - `addcal`
  - `listcal`
  - `showcal`
  - `editcal`
  - `delcal`
  - `batchcal`
  - `img2cal`
- Hermes-first `SKILL.md` packaging with ClawHub-compatible metadata
- README positioning, badges, install guidance, and CalDAV comparison
- Shell test coverage for routing, calendar helpers, conflict behavior, batch planning, and ticket workflows

### Features

- Create events with explicit calendar selection or semantic bucket routing
- Inspect events in table, TSV, or JSON formats
- Edit and delete events safely by id
- Import event plans from JSON via `batchcal`
- Normalize ticket-style event payloads via `img2cal`
- Support JSON stdin for structured event mutations
- Support all-day events
- Support friendly recurrence DSL and native `--rrule`
- Default conflict checking for new events

### Notes

- macOS-only by design
- Writes to real Calendar.app data and relies on iCloud sync through the OS
