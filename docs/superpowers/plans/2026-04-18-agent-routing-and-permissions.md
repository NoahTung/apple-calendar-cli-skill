# Agent Routing And Permissions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a thin agent-facing routing layer to `addcal`, document first-run permissions clearly, and update the skill so agents infer calendar placement before falling back safely.

**Architecture:** Keep semantic routing lightweight by adding a small bucket-to-calendar resolver in shell, while leaving most intent inference in `SKILL.md`. Avoid a natural-language parser in the CLI; the command should accept explicit `--calendar` or a lightweight `--bucket` hint and resolve against real Calendar.app calendars.

**Tech Stack:** Bash, AppleScript via `osascript`, Markdown docs

---

## File Structure

- Modify: `README.md`
  - Add a `First-run permissions` section and explain the new routing behavior at a high level.
- Modify: `SKILL.md`
  - Teach agents the routing order: explicit calendar override, semantic inference, calendar inspection, fallback.
- Modify: `addcal`
  - Add explicit tracking for `--calendar`, add `--bucket personal|work|life`, resolve buckets against existing calendars, and report the resolved calendar.
- Create: `tests/addcal-routing-test.sh`
  - Shell-level regression checks for bucket normalization and calendar resolution helpers without hitting Calendar.app.
- Optional Create: `tests/test-lib.sh`
  - Tiny assertion helpers if repeated shell assertions become noisy.

This plan intentionally excludes `updatecal`, `getcal`, `freebusycal`, and `movecal`. Those should be planned separately after this routing/documentation slice is complete.

### Task 1: Add shell tests for bucket routing behavior

**Files:**
- Create: `tests/addcal-routing-test.sh`
- Optional Create: `tests/test-lib.sh`
- Modify: `addcal`

- [ ] **Step 1: Add a small test harness for shell assertions**

Create `tests/addcal-routing-test.sh` with a self-contained runner that sources helper functions from `addcal` without calling `osascript`.

```bash
#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/addcal"

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

- [ ] **Step 2: Add failing tests for bucket normalization and resolution**

Extend `tests/addcal-routing-test.sh` with cases that describe the desired behavior before implementation.

```bash
assert_eq "personal" "$(normalize_bucket personal)" "normalizes personal bucket"
assert_eq "work" "$(normalize_bucket WORK)" "normalizes uppercase work bucket"
assert_eq "life" "$(normalize_bucket Life)" "normalizes mixed-case life bucket"

resolved="$(resolve_bucket_calendar personal $'Work\nPersonal\nErrands')"
assert_eq "Personal" "$resolved" "routes personal bucket to Personal calendar"

resolved="$(resolve_bucket_calendar work $'个人\n工作\n生活')"
assert_eq "工作" "$resolved" "routes work bucket to Chinese calendar names"

resolved="$(resolve_bucket_calendar life $'Home\nErrands')"
assert_eq "" "$resolved" "returns empty when no matching life calendar exists"
```

- [ ] **Step 3: Run the test file and verify it fails**

Run:

```bash
bash tests/addcal-routing-test.sh
```

Expected: failure because `normalize_bucket` and `resolve_bucket_calendar` do not exist yet, or because the assertions do not pass.

- [ ] **Step 4: Refactor `addcal` so helper functions can be sourced in tests**

Wrap CLI execution in a main guard near the bottom of `addcal`.

```bash
main() {
  # existing argument parsing and event creation flow
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
```

- [ ] **Step 5: Commit the failing-test scaffold**

```bash
git add addcal tests/addcal-routing-test.sh
git commit -m "test: add addcal routing harness"
```

### Task 2: Implement bucket-aware routing in `addcal`

**Files:**
- Modify: `addcal`
- Test: `tests/addcal-routing-test.sh`

- [ ] **Step 1: Add parsing for `--bucket` and explicit-calendar tracking**

Update the argument parsing in `addcal` so it can distinguish:

- default calendar fallback
- user-provided `--calendar`
- user- or agent-provided `--bucket`

Add variables near the top:

```bash
DEFAULT_CALENDAR="个人"
calendar="$DEFAULT_CALENDAR"
explicit_calendar=0
bucket=""
```

Update parsing:

```bash
      --calendar)
        [[ $# -ge 2 ]] || die "missing value for --calendar"
        calendar="$2"
        explicit_calendar=1
        shift 2
        ;;
      --bucket)
        [[ $# -ge 2 ]] || die "missing value for --bucket"
        bucket="$2"
        shift 2
        ;;
```

- [ ] **Step 2: Add helper functions for bucket normalization and calendar matching**

Add lightweight helpers above `main`.

```bash
normalize_bucket() {
  local raw="${1:-}"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$raw" in
    personal|work|life)
      printf '%s\n' "$raw"
      ;;
    *)
      die "unsupported bucket '$1' (use personal, work, or life)"
      ;;
  esac
}

resolve_bucket_calendar() {
  local normalized_bucket="$1"
  local calendars_text="$2"
  local candidate

  case "$normalized_bucket" in
    personal) set -- "个人" "Personal" ;;
    work) set -- "工作" "Work" ;;
    life) set -- "生活" "Life" ;;
  esac

  for candidate in "$@"; do
    while IFS= read -r calendar_name; do
      [[ -n "$calendar_name" ]] || continue
      if [[ "$calendar_name" == "$candidate" ]]; then
        printf '%s\n' "$calendar_name"
        return 0
      fi
    done <<< "$calendars_text"
  done

  return 1
}
```

- [ ] **Step 3: Apply the routing priority order before event creation**

After parsing but before the `osascript` event creation block, implement:

```bash
if [[ -n "$bucket" && "$explicit_calendar" -eq 0 ]]; then
  normalized_bucket="$(normalize_bucket "$bucket")"
  available_calendars="$(list_calendars | tr ', ' '\n' | sed '/^$/d')"
  resolved_calendar="$(resolve_bucket_calendar "$normalized_bucket" "$available_calendars" || true)"
  if [[ -n "$resolved_calendar" ]]; then
    calendar="$resolved_calendar"
  fi
fi
```

Keep the rule simple:

- explicit `--calendar` always wins
- `--bucket` only influences routing when `--calendar` was not explicitly set
- if no matching calendar exists, keep using `DEFAULT_CALENDAR`

- [ ] **Step 4: Update usage text and success output**

Extend the usage block with examples and document the new flag.

```text
  addcal --bucket work --start "2026-04-18 17:00" --end "2026-04-18 18:00" --title "Deep work"
```

Update the success message so resolved routing is visible:

```bash
if [[ -n "$bucket" && "$explicit_calendar" -eq 0 ]]; then
  printf 'Created event via bucket %s in %s: %s (%s -> %s) [id=%s]\n' \
    "$normalized_bucket" "$calendar" "$title" "$start" "$end" "$event_id"
else
  printf 'Created event in %s: %s (%s -> %s) [id=%s]\n' \
    "$calendar" "$title" "$start" "$end" "$event_id"
fi
```

- [ ] **Step 5: Run the routing test file and verify it passes**

Run:

```bash
bash tests/addcal-routing-test.sh
```

Expected: PASS with no output or a single success line, depending on the test runner implementation.

- [ ] **Step 6: Run CLI help verification**

Run:

```bash
bash addcal --help
```

Expected: usage output that includes `--bucket personal|work|life`.

- [ ] **Step 7: Commit the routing implementation**

```bash
git add addcal tests/addcal-routing-test.sh
git commit -m "feat: add bucket-aware routing to addcal"
```

### Task 3: Update the agent skill with routing and permission guidance

**Files:**
- Modify: `SKILL.md`

- [ ] **Step 1: Add a First-run permissions note**

Insert a short note under `## Notes` or directly after `## Why this skill`.

```markdown
## First-run permissions

- macOS may ask the terminal or agent app for permission to control Calendar.
- Hermes or similar runtimes may also request access related to Python, the script directory, or the current workspace folder.
- These prompts are expected during initial setup and do not necessarily indicate a tool failure.
```

- [ ] **Step 2: Add explicit routing order to the skill**

Extend the event-creation guidance so agents follow this order:

```markdown
When choosing a calendar for a new event:

1. If the user explicitly names a calendar, use it.
2. Otherwise, infer a bucket such as `personal`, `work`, or `life` from the event meaning.
3. Prefer matching real calendars such as `个人`/`Personal`, `工作`/`Work`, or `生活`/`Life`.
4. If the available calendars are unclear, run `listcal --list-calendars` first.
5. Fall back to the default calendar only when no better match exists.
```

- [ ] **Step 3: Show a bucket-based example**

Add one agent-facing example:

```bash
addcal --bucket work --start "2026-04-18 19:00" --end "2026-04-18 20:00" --title "Write code"
```

- [ ] **Step 4: Review the skill text for consistency**

Check that:

- `--calendar` is still presented as the explicit override
- `--bucket` is framed as an agent hint, not a replacement for real calendars
- the examples match the CLI usage text exactly

- [ ] **Step 5: Commit the skill update**

```bash
git add SKILL.md
git commit -m "docs: add agent routing guidance to skill"
```

### Task 4: Update the README for permissions and routing behavior

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a First-run permissions section near installation or requirements**

Insert a short section after installation verification:

```markdown
## First-run permissions

On first use, macOS may ask your terminal or agent app for permission to control Calendar.app.

Agent runtimes such as Hermes may also ask for access related to Python, the script directory, or the current workspace folder. These prompts are expected during setup. Once approved, event creation should work normally.
```

- [ ] **Step 2: Add a short routing explanation in the usage or agent workflow area**

Add a paragraph like:

```markdown
For agent-driven use, calendar selection can be explicit or inferred. If the user names a calendar, use that directly. Otherwise an agent can infer a semantic bucket such as `personal`, `work`, or `life`, resolve it against the user's existing calendars, and fall back to the default calendar when no strong match exists.
```

- [ ] **Step 3: Add a bucket-based creation example**

Add one example under `### Create events`:

```bash
addcal --bucket work --start "2026-04-18 17:00" --end "2026-04-18 18:00" --title "Deep work"
```

- [ ] **Step 4: Review the README top section for consistency with the new routing message**

Check that:

- the repo still reads as a thin CLI layer
- the README does not imply the CLI itself performs full natural-language understanding
- the permissions note matches the validated Hermes behavior

- [ ] **Step 5: Commit the README update**

```bash
git add README.md
git commit -m "docs: add routing and permissions guidance"
```

### Task 5: End-to-end verification

**Files:**
- Verify only

- [ ] **Step 1: Run shell-level routing tests**

Run:

```bash
bash tests/addcal-routing-test.sh
```

Expected: PASS.

- [ ] **Step 2: Verify help output**

Run:

```bash
bash addcal --help
bash listcal --help
bash delcal --help
```

Expected: `addcal` shows the new routing flag, while `listcal` and `delcal` remain unchanged.

- [ ] **Step 3: Verify calendar listing still works**

Run:

```bash
bash addcal --list-calendars
bash listcal --list-calendars
```

Expected: both commands still list available calendars without regression.

- [ ] **Step 4: Manual create verification with explicit and bucket routing**

Run:

```bash
bash addcal --calendar "个人" --start "2026-04-20 19:00" --end "2026-04-20 20:00" --title "Routing explicit smoke test"
bash addcal --bucket work --start "2026-04-20 20:00" --end "2026-04-20 21:00" --title "Routing bucket smoke test"
```

Expected:

- first command creates the event in the explicit calendar
- second command creates the event in a matched work calendar if present, otherwise the default calendar

- [ ] **Step 5: Clean up smoke-test events**

Find the created event ids and delete them:

```bash
bash listcal --all-calendars --start "2026-04-20 00:00" --end "2026-04-21 00:00" --format tsv
bash delcal --id "<explicit-test-id>"
bash delcal --id "<bucket-test-id>"
```

Expected: both temporary events are removed cleanly.

- [ ] **Step 6: Commit the verified implementation**

```bash
git add README.md SKILL.md addcal tests/addcal-routing-test.sh
git commit -m "feat: ship agent routing and permission docs"
```

## Self-Review Notes

- Spec coverage: This plan covers first-run permissions, semantic routing, explicit override behavior, and the thin CLI boundary. It does not implement `updatecal`, `getcal`, `freebusycal`, or `movecal`; that is intentional and matches the scope split stated in the file structure section.
- Placeholder scan: All tasks name exact files, concrete commands, and the target behavior for each step.
- Type consistency: The plan consistently uses `--bucket`, `explicit_calendar`, `normalize_bucket`, and `resolve_bucket_calendar`.

