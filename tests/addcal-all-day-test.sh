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

# ── Test date-only normalization ────────────────────────────────────
assert_eq "2026-04-20 00:00" "$(normalize_date_input "2026-04-20")" "date-only normalizes to midnight"
assert_eq "2026-04-20 18:00" "$(normalize_date_input "2026-04-20 18:00")" "datetime passes through"

# ── Test all-day end inference ──────────────────────────────────────
assert_eq "2026-04-21 00:00" "$(infer_all_day_end "2026-04-20 00:00")" "all-day end defaults to next day midnight"
assert_eq "2026-05-01 00:00" "$(infer_all_day_end "2026-04-30 00:00")" "all-day end crosses month boundary"

# ── Test is_date_only ───────────────────────────────────────────────
assert_eq "1" "$(is_date_only "2026-04-20")" "detects date-only string"
assert_eq "0" "$(is_date_only "2026-04-20 18:00")" "detects datetime string"
assert_eq "0" "$(is_date_only "today 18:00")" "detects non-ISO date string"

# ── Test all-day flag from JSON ─────────────────────────────────────
payload='{"calendar":"Personal","title":"Holiday","start":"2026-04-20","all_day":true}'
assert_eq "1" "$(json_get_field "$payload" all_day)" "reads boolean all_day from json as string 1"

printf 'addcal all-day tests passed\n'
