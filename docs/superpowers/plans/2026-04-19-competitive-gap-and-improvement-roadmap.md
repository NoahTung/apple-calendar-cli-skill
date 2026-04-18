# Competitive Gap And Improvement Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `apple-calendar-cli` into the Hermes-first default skill for Apple Calendar on macOS by improving packaging, structured inputs, safety defaults, and differentiated agent workflows.

**Architecture:** Keep the existing multi-command CLI architecture, but add a shared mutation field model across `addcal`, `editcal`, and related docs. Prioritize Hermes-facing packaging first, then implement structured input and safety layers that reinforce the repo's agent-safe positioning.

**Tech Stack:** Bash, AppleScript via `osascript`, Markdown docs, shell test scripts

---

## File Structure

- Modify: `README.md`
  - Reposition the project as a Hermes-first Apple Calendar skill and document install, permissions, privacy, and capabilities more clearly.
- Modify: `SKILL.md`
  - Align agent guidance with Hermes-first packaging, structured mutation flows, and stronger safety defaults.
- Modify: `addcal`
  - Add JSON stdin support, all-day support, stronger conflict-check behavior, and writable-calendar enforcement.
- Modify: `editcal`
  - Add JSON stdin support, all-day editing semantics where feasible, and writable-calendar enforcement.
- Modify: `listcal`
  - Expose any new output fields needed for all-day and calendar writeability when practical.
- Modify: `showcal`
  - Expose all-day and recurrence details consistently with `listcal`/`addcal`.
- Modify: `calendar-lib.sh`
  - Centralize shared parsing, validation, JSON helpers, and calendar capability checks where practical.
- Modify: `batchcal`
  - Prepare for future idempotence improvements and align its field model with direct mutation commands.
- Modify: `img2cal`
  - Align with a draft-check-apply lifecycle and stronger conflict surfacing.
- Modify: `personal-context.json`
  - Only if needed to support richer `img2cal` examples or routing documentation.
- Create: `tests/json-input-test.sh`
  - Validate JSON stdin handling for write commands without requiring live Calendar mutations.
- Create: `tests/addcal-all-day-test.sh`
  - Validate all-day parsing and flag precedence.
- Create: `tests/calendar-writable-test.sh`
  - Validate writable/read-only calendar checks in shared helpers.
- Create: `tests/conflict-defaults-test.sh`
  - Validate stronger conflict-check defaults and override behavior.
- Modify: `tests/addcal-routing-test.sh`
  - Extend existing routing coverage to ensure new inputs do not break current behavior.
- Modify: `tests/calendar-lib-test.sh`
  - Add coverage for shared helper functions introduced during this roadmap.

This plan is deliberately ordered so Phase 1 delivers Hermes packaging value early, while later phases add CLI capabilities without losing backward compatibility.

### Task 1: Reposition docs for Hermes-first distribution

**Files:**
- Modify: `README.md`
- Modify: `SKILL.md`
- Test: `README.md`

- [ ] **Step 1: Rewrite the README opening to lead with Hermes-first positioning**

Update the first screen of `README.md` so it immediately communicates:

- this is a Hermes-friendly Apple Calendar skill for macOS
- it manages real Calendar.app data
- it offers full CRUD, batch import, and ticket normalization

Use an opening block like:

```md
# Apple Calendar CLI Skill

Hermes-first local CLIs for the real Apple Calendar on macOS.

Manage Calendar.app and iCloud calendars through small non-interactive commands built for Hermes and other shell-capable agents:

- `addcal`
- `listcal`
- `showcal`
- `editcal`
- `delcal`
- `batchcal`
- `img2cal`
```

- [ ] **Step 2: Add a Hermes-first install section to `README.md`**

Create a dedicated section that explains:

- expected install path for Hermes-oriented local use
- how to copy the scripts into a directory on `PATH`
- how a Hermes user can keep the repo in `~/skills` or install under `~/.hermes/skills/`

Add commands such as:

```bash
mkdir -p ~/.local/bin
cp addcal listcal delcal editcal showcal batchcal img2cal calendar-lib.sh ~/.local/bin/
chmod +x ~/.local/bin/addcal ~/.local/bin/listcal ~/.local/bin/delcal ~/.local/bin/editcal ~/.local/bin/showcal ~/.local/bin/batchcal ~/.local/bin/img2cal
```

And explain that Hermes can then call these commands from skill workflows.

- [ ] **Step 3: Add trust, privacy, and permissions guidance to `README.md`**

Document:

- macOS Calendar automation prompts
- whether commands log anything by default
- why JSON stdin will be preferred for rich mutation payloads
- that the project writes to local Calendar.app data rather than a sidecar file

Add a short policy section like:

```md
## Privacy And Permissions

- Commands run locally on macOS and talk to Calendar.app through AppleScript.
- Persistent event logging is disabled by default.
- The first run may trigger a macOS automation permission prompt for Calendar.
- When possible, prefer JSON via stdin for long notes or structured payloads instead of exposing them in process arguments.
```

- [ ] **Step 4: Update `SKILL.md` to frame Hermes as the primary early audience**

Adjust the description and workflow guidance so Hermes is named first, while still keeping the skill usable for Codex and other agents.

Add a note like:

```md
Use this skill first when Hermes on macOS needs to create, inspect, update, delete, batch-import, or normalize events in the user's real Apple Calendar.
```

- [ ] **Step 5: Verify the updated docs for internal consistency**

Run:

```bash
rg -n "Hermes|Privacy|Permissions|JSON stdin|all-day|rrule" README.md SKILL.md
```

Expected: the updated docs include Hermes-first positioning, privacy guidance, and references to the new structured-input roadmap.

- [ ] **Step 6: Commit the docs repositioning**

```bash
git add README.md SKILL.md
git commit -m "docs: position calendar skill for Hermes"
```

### Task 2: Add failing tests for shared JSON mutation input

**Files:**
- Create: `tests/json-input-test.sh`
- Modify: `addcal`
- Modify: `editcal`
- Modify: `calendar-lib.sh`

- [ ] **Step 1: Add a shell test harness for JSON payload parsing**

Create `tests/json-input-test.sh` with a self-contained runner that sources shared helpers without invoking Calendar mutations.

```bash
#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/calendar-lib.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  [[ "$expected" == "$actual" ]] || fail "$message (expected=$expected actual=$actual)"
}
```

- [ ] **Step 2: Add failing tests for JSON field extraction and precedence**

Extend `tests/json-input-test.sh` with cases like:

```bash
payload='{"calendar":"Personal","title":"Dinner","start":"2026-04-20 19:00","end":"2026-04-20 20:00","notes":"Booked"}'

assert_eq "Personal" "$(json_get_field "$payload" calendar)" "reads calendar from json"
assert_eq "Dinner" "$(json_get_field "$payload" title)" "reads title from json"
assert_eq "Booked" "$(json_get_field "$payload" notes)" "reads notes from json"

merged_title="$(merge_cli_and_json_field "CLI title" "$payload" title)"
assert_eq "CLI title" "$merged_title" "cli value overrides json field"

merged_calendar="$(merge_cli_and_json_field "" "$payload" calendar)"
assert_eq "Personal" "$merged_calendar" "json value used when cli field absent"
```

- [ ] **Step 3: Run the JSON test file and verify it fails**

Run:

```bash
bash tests/json-input-test.sh
```

Expected: failure because `json_get_field` and merge helpers do not exist yet.

- [ ] **Step 4: Add main guards if needed so commands remain sourceable for tests**

Ensure `addcal` and `editcal` both end with:

```bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
```

- [ ] **Step 5: Commit the failing JSON-input tests**

```bash
git add addcal editcal calendar-lib.sh tests/json-input-test.sh
git commit -m "test: add json mutation input coverage"
```

### Task 3: Implement shared JSON stdin support for mutations

**Files:**
- Modify: `calendar-lib.sh`
- Modify: `addcal`
- Modify: `editcal`
- Test: `tests/json-input-test.sh`

- [ ] **Step 1: Add shared JSON helpers to `calendar-lib.sh`**

Implement small helpers using `python3` or `osascript -l JavaScript` only if needed, but prefer a minimal, deterministic approach already compatible with the repo.

Add helpers such as:

```bash
json_get_field() {
  local payload="$1"
  local field="$2"
  python3 - "$field" <<'PY'
import json, sys
field = sys.argv[1]
payload = json.load(sys.stdin)
value = payload.get(field, "")
if value is None:
    value = ""
print(value)
PY
}
```

If a different implementation is chosen, keep the interface equivalent and document any dependency assumptions.

- [ ] **Step 2: Add `--stdin-json` parsing to `addcal`**

Update `addcal` usage and parsing:

```text
addcal --stdin-json [--calendar "..."] [--title "..."] ...
```

Add a flag flow like:

```bash
stdin_json=0
json_payload=""

--stdin-json)
  stdin_json=1
  shift
  ;;
```

And load stdin after argument parsing:

```bash
if [[ "$stdin_json" -eq 1 ]]; then
  json_payload="$(cat)"
fi
```

- [ ] **Step 3: Merge CLI fields over JSON fields in `addcal` and `editcal`**

Apply consistent precedence:

- explicit CLI flags win
- JSON fills missing fields
- conflicting duplicate sources do not silently disagree

Use logic like:

```bash
calendar="$(merge_cli_and_json_field "$calendar" "$json_payload" calendar)"
title="$(merge_cli_and_json_field "$title" "$json_payload" title)"
start="$(merge_cli_and_json_field "$start" "$json_payload" start)"
end="$(merge_cli_and_json_field "$end" "$json_payload" end)"
notes="$(merge_cli_and_json_field "$notes" "$json_payload" notes)"
```

- [ ] **Step 4: Update command help and examples**

Add examples such as:

```bash
echo '{"calendar":"Personal","title":"Dinner","start":"2026-04-20 19:00","end":"2026-04-20 20:00","notes":"Booked"}' | addcal --stdin-json

echo '{"id":"0243912F-0D42-4477-A193-A881F73E7434","title":"Dinner v2"}' | editcal --stdin-json
```

- [ ] **Step 5: Run the JSON test file and verify it passes**

Run:

```bash
bash tests/json-input-test.sh
```

Expected: PASS with no failures.

- [ ] **Step 6: Run help verification**

Run:

```bash
bash addcal --help
bash editcal --help
```

Expected: both usage outputs mention `--stdin-json`.

- [ ] **Step 7: Commit the JSON mutation implementation**

```bash
git add calendar-lib.sh addcal editcal tests/json-input-test.sh
git commit -m "feat: add json stdin for calendar mutations"
```

### Task 4: Add all-day event support through tests first

**Files:**
- Create: `tests/addcal-all-day-test.sh`
- Modify: `addcal`
- Modify: `showcal`
- Modify: `listcal`

- [ ] **Step 1: Add failing tests for all-day normalization**

Create `tests/addcal-all-day-test.sh` with assertions like:

```bash
assert_eq "1" "$(normalize_all_day_flag --all-day)" "all-day flag enables mode"
assert_eq "2026-04-20 00:00" "$(normalize_all_day_start "2026-04-20")" "all-day start normalizes to midnight"
assert_eq "2026-04-21 00:00" "$(infer_all_day_end "2026-04-20")" "all-day end defaults to next day midnight"
```

- [ ] **Step 2: Run the all-day test file and verify it fails**

Run:

```bash
bash tests/addcal-all-day-test.sh
```

Expected: failure because all-day helpers do not exist yet.

- [ ] **Step 3: Implement all-day helpers in shared code**

Add helpers in `calendar-lib.sh` or `addcal` for:

- normalizing all-day inputs
- inferring default end for all-day events
- validating that timed and all-day semantics do not conflict silently

- [ ] **Step 4: Add `--all-day` support to `addcal`**

Update argument parsing and creation flow:

```bash
all_day=0

--all-day)
  all_day=1
  shift
  ;;
```

When `all_day=1`:

- allow `--start "YYYY-MM-DD"` or equivalent normalized date input
- infer the next-day end if none is provided
- create the Calendar event as an all-day event in AppleScript if supported by the repo's current event creation model

- [ ] **Step 5: Expose all-day state in inspect/list commands**

Update `showcal` and `listcal` output so an agent can tell whether an event is all-day. If a new field is added to TSV/JSON output, document it and keep ordering stable.

- [ ] **Step 6: Run the all-day test file and verify it passes**

Run:

```bash
bash tests/addcal-all-day-test.sh
```

Expected: PASS.

- [ ] **Step 7: Commit the all-day implementation**

```bash
git add addcal listcal showcal calendar-lib.sh tests/addcal-all-day-test.sh
git commit -m "feat: add all-day calendar event support"
```

### Task 5: Add native recurrence-rule input while keeping the friendly DSL

**Files:**
- Modify: `addcal`
- Modify: `editcal`
- Modify: `README.md`
- Modify: `SKILL.md`
- Modify: `tests/calendar-lib-test.sh`

- [ ] **Step 1: Add failing tests for recurrence precedence**

Extend `tests/calendar-lib-test.sh` with cases like:

```bash
assert_eq "FREQ=WEEKLY;BYDAY=MO,WE,FR" "$(resolve_recurrence_input "" "FREQ=WEEKLY;BYDAY=MO,WE,FR")" "uses explicit rrule"
assert_eq "weekly 1,3,5" "$(resolve_recurrence_input "weekly 1,3,5" "")" "falls back to friendly repeat"
```

- [ ] **Step 2: Run the recurrence tests and verify they fail**

Run:

```bash
bash tests/calendar-lib-test.sh
```

Expected: failure because the resolver does not exist yet.

- [ ] **Step 3: Add `--rrule` support to `addcal` and `editcal`**

Introduce parsing:

```bash
rrule=""

--rrule)
  [[ $# -ge 2 ]] || calendar_die "missing value for --rrule"
  rrule="$2"
  shift 2
  ;;
```

Apply precedence:

- `--rrule` wins over `--repeat`
- invalid combinations fail with a clear message

- [ ] **Step 4: Document recurrence behavior**

Update docs so they explicitly say:

- friendly `--repeat` remains supported
- `--rrule` is the advanced path
- `--rrule` overrides `--repeat`

- [ ] **Step 5: Re-run shared helper tests**

Run:

```bash
bash tests/calendar-lib-test.sh
```

Expected: PASS, with recurrence precedence covered.

- [ ] **Step 6: Commit the recurrence work**

```bash
git add addcal editcal README.md SKILL.md tests/calendar-lib-test.sh
git commit -m "feat: support native recurrence rules"
```

### Task 6: Enforce writable-calendar checks before mutation

**Files:**
- Create: `tests/calendar-writable-test.sh`
- Modify: `calendar-lib.sh`
- Modify: `addcal`
- Modify: `editcal`
- Modify: `delcal`

- [ ] **Step 1: Add failing tests for calendar writeability checks**

Create `tests/calendar-writable-test.sh` with cases such as:

```bash
assert_eq "1" "$(calendar_is_writable_fixture "Personal:1")" "writable fixture recognized"
assert_eq "0" "$(calendar_is_writable_fixture "Subscribed Holidays:0")" "read-only fixture recognized"
```

If direct AppleScript mocking is awkward, isolate the parser/adapter so the test targets deterministic shell helpers.

- [ ] **Step 2: Run the writable-calendar test file and verify it fails**

Run:

```bash
bash tests/calendar-writable-test.sh
```

Expected: failure because the helpers do not exist yet.

- [ ] **Step 3: Add calendar capability helpers to `calendar-lib.sh`**

Create helpers that can:

- inspect available calendars
- identify whether the target calendar is writable
- fail fast when a mutation targets a read-only calendar

Keep the interface simple:

```bash
require_writable_calendar() {
  local calendar="$1"
  # resolve calendar and exit non-zero with a clear error if not writable
}
```

- [ ] **Step 4: Call `require_writable_calendar` from mutation commands**

Before `addcal`, `editcal`, or exact-match deletion proceeds, enforce:

```bash
require_writable_calendar "$calendar"
```

For deletion by id, first resolve the event's owning calendar, then enforce writeability.

- [ ] **Step 5: Run the writable-calendar tests and smoke-check help output**

Run:

```bash
bash tests/calendar-writable-test.sh
```

Expected: PASS.

- [ ] **Step 6: Commit writable-calendar enforcement**

```bash
git add calendar-lib.sh addcal editcal delcal tests/calendar-writable-test.sh
git commit -m "feat: enforce writable calendar checks"
```

### Task 7: Strengthen conflict detection defaults

**Files:**
- Create: `tests/conflict-defaults-test.sh`
- Modify: `addcal`
- Modify: `img2cal`
- Modify: `README.md`
- Modify: `SKILL.md`

- [ ] **Step 1: Add failing tests for new conflict-check defaults**

Create `tests/conflict-defaults-test.sh` with behavior checks like:

```bash
assert_eq "1" "$(default_conflict_check_enabled)" "conflict checks enabled by default"
assert_eq "0" "$(resolve_conflict_check_mode --no-check-conflict)" "explicit opt-out disables default checks"
```

- [ ] **Step 2: Run the conflict test file and verify it fails**

Run:

```bash
bash tests/conflict-defaults-test.sh
```

Expected: failure because the helpers do not exist yet.

- [ ] **Step 3: Change `addcal` to default to conflict checking**

Replace the current opt-in flow with:

- default conflict check when the resolved calendar is known
- explicit bypass via a new flag such as `--no-check-conflict`

Use logic like:

```bash
check_conflict=1

--no-check-conflict)
  check_conflict=0
  shift
  ;;
```

- [ ] **Step 4: Align `img2cal` with the stronger conflict model**

Ensure that draft or apply flows surface conflicts consistently, especially when `--apply` is requested.

- [ ] **Step 5: Update docs and skill guidance**

Document that:

- conflict checking is now part of the default safe path
- users can bypass intentionally
- agents should treat conflict warnings as a confirmation point, not necessarily a hard block

- [ ] **Step 6: Re-run the conflict tests**

Run:

```bash
bash tests/conflict-defaults-test.sh
```

Expected: PASS.

- [ ] **Step 7: Commit stronger conflict defaults**

```bash
git add addcal img2cal README.md SKILL.md tests/conflict-defaults-test.sh
git commit -m "feat: enable conflict checks by default"
```

### Task 8: Align `batchcal` and `img2cal` with differentiated workflow goals

**Files:**
- Modify: `batchcal`
- Modify: `img2cal`
- Modify: `README.md`
- Modify: `SKILL.md`

- [ ] **Step 1: Add a dry-run diff or duplicate-summary design to `batchcal`**

Implement a minimal but useful enhancement, such as a summary that reports:

- planned creates
- likely duplicates
- items missing required fields

Prefer a conservative first step over speculative matching complexity.

- [ ] **Step 2: Standardize `img2cal` around draft -> conflict check -> apply**

Ensure the docs and command behavior clearly separate:

- normalization
- preview
- conflict surfacing
- final creation

- [ ] **Step 3: Update examples to highlight these workflows**

Add examples in `README.md` and `SKILL.md` showing:

```bash
img2cal --type movie --title "Example" --start "2026-05-01 19:30" --draft
img2cal --type movie --title "Example" --start "2026-05-01 19:30" --apply
batchcal --plan semester.json --dry-run
batchcal --plan semester.json --apply
```

- [ ] **Step 4: Run existing regression tests**

Run:

```bash
bash tests/addcal-routing-test.sh
bash tests/calendar-lib-test.sh
bash tests/listcal-args-test.sh
bash tests/batchcal-plan-test.sh
bash tests/img2cal-integration-test.sh
```

Expected: PASS with no regressions from the workflow changes.

- [ ] **Step 5: Commit differentiated workflow improvements**

```bash
git add batchcal img2cal README.md SKILL.md
git commit -m "feat: strengthen batch and ticket workflows"
```

### Task 9: Final verification and release-readiness pass

**Files:**
- Modify: any touched files that need cleanup after verification

- [ ] **Step 1: Run the full test suite**

Run:

```bash
bash tests/addcal-routing-test.sh
bash tests/json-input-test.sh
bash tests/addcal-all-day-test.sh
bash tests/calendar-writable-test.sh
bash tests/conflict-defaults-test.sh
bash tests/calendar-lib-test.sh
bash tests/listcal-args-test.sh
bash tests/batchcal-plan-test.sh
bash tests/img2cal-integration-test.sh
```

Expected: all tests pass.

- [ ] **Step 2: Manually verify help text for the main commands**

Run:

```bash
bash addcal --help
bash editcal --help
bash listcal --help
bash showcal --help
bash batchcal --help
bash img2cal --help
```

Expected: help output is coherent, mentions new flags, and does not contradict the README.

- [ ] **Step 3: Review the docs against the final behavior**

Run:

```bash
rg -n "stdin-json|all-day|rrule|Hermes|conflict|writable|privacy" README.md SKILL.md
```

Expected: docs reflect the actual implemented feature set.

- [ ] **Step 4: Create the final release commit**

```bash
git add README.md SKILL.md addcal editcal listcal showcal delcal batchcal img2cal calendar-lib.sh tests
git commit -m "feat: ship Hermes-first calendar roadmap"
```

## Self-Review

- Spec coverage:
  - Hermes-first positioning is covered in Task 1.
  - Structured input and event-model upgrades are covered in Tasks 2-5.
  - Safety defaults are covered in Tasks 6-7.
  - Differentiated workflow improvements are covered in Task 8.
- Placeholder scan:
  - Every task includes concrete files, commands, and expected outcomes.
- Type consistency:
  - Shared helper names are used consistently across JSON, all-day, recurrence, writable-calendar, and conflict-check tasks.
