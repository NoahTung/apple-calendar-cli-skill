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

# ── Test json_get_field ─────────────────────────────────────────────
payload='{"calendar":"Personal","title":"Dinner","start":"2026-04-20 19:00","end":"2026-04-20 20:00","notes":"Booked"}'

assert_eq "Personal" "$(json_get_field "$payload" calendar)" "reads calendar from json"
assert_eq "Dinner" "$(json_get_field "$payload" title)" "reads title from json"
assert_eq "Booked" "$(json_get_field "$payload" notes)" "reads notes from json"
assert_eq "" "$(json_get_field "$payload" location)" "missing field returns empty"

# ── Test merge_cli_and_json_field ───────────────────────────────────
merged_title="$(merge_cli_and_json_field "CLI title" "$payload" title)"
assert_eq "CLI title" "$merged_title" "cli value overrides json field"

merged_calendar="$(merge_cli_and_json_field "" "$payload" calendar)"
assert_eq "Personal" "$merged_calendar" "json value used when cli field absent"

merged_location="$(merge_cli_and_json_field "" "$payload" location)"
assert_eq "" "$merged_location" "empty json field stays empty"

# ── Test precedence with explicit empty vs absent ───────────────────
merged_notes="$(merge_cli_and_json_field "" '{"notes":"From JSON"}' notes)"
assert_eq "From JSON" "$merged_notes" "json fills absent cli field"

printf 'json input tests passed\n'
