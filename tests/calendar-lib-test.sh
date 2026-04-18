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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$message (missing=$needle output=$haystack)"
}

CALENDAR_NOW="2026-04-18 10:00"

assert_eq "2026-04-18 18:00" "$(parse_datetime_expression "today 18:00")" "parses today preset"
assert_eq "2026-04-19 09:00" "$(parse_datetime_expression "tomorrow 9am")" "parses tomorrow am time"
assert_eq "2026-04-18 12:00" "$(parse_datetime_expression "+2h")" "parses relative hours"
assert_eq "2026-04-18 10:30" "$(parse_datetime_expression "+30m")" "parses relative minutes"
assert_eq "2026-04-25 18:00" "$(default_end_from_start "2026-04-18 18:00")" "defaults end to seven days later"

{
  IFS= read -r today_start
  IFS= read -r today_end
} < <(compute_range_from_preset today)
assert_eq "2026-04-18 00:00" "$today_start" "today preset starts at midnight"
assert_eq "2026-04-19 00:00" "$today_end" "today preset ends next midnight"

{
  IFS= read -r week_start
  IFS= read -r week_end
} < <(compute_range_from_preset this-week)
assert_eq "2026-04-13 00:00" "$week_start" "this-week starts on Monday"
assert_eq "2026-04-20 00:00" "$week_end" "this-week ends next Monday"

assert_eq "15" "$(normalize_alarm 15)" "keeps minute alarm"
assert_eq "none" "$(normalize_alarm none)" "normalizes none alarm"
assert_eq "FREQ=DAILY;INTERVAL=1" "$(normalize_repeat daily)" "supports daily repeat"
assert_eq "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR" "$(normalize_repeat "weekly 1,3,5")" "supports weekday repeat"

json_output="$(json_from_records $'evt-1\034Work\034Title\0342026-04-18 09:00\0342026-04-18 10:00\034Office\034Prep\034https://example.com\034-15\034FREQ=DAILY;INTERVAL=1\036')"
assert_contains "$json_output" '"id": "evt-1"' "json output includes id"
assert_contains "$json_output" '"location": "Office"' "json output includes location"
assert_contains "$json_output" '"alarm": "-15"' "json output includes alarm"
assert_eq "1" "$(count_records $'evt-1\034Work\034Title\036')" "counts one encoded record"

printf 'calendar lib tests passed\n'
