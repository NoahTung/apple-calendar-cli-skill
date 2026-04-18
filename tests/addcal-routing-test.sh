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

mock_calendar_list=""

list_calendars() {
  printf '%s\n' "$mock_calendar_list"
}

assert_eq "personal" "$(normalize_bucket personal)" "normalizes personal bucket"
assert_eq "work" "$(normalize_bucket WORK)" "normalizes uppercase work bucket"
assert_eq "life" "$(normalize_bucket Life)" "normalizes mixed-case life bucket"

mock_calendar_list=$'Work\nPersonal\nErrands'
assert_eq "Personal" "$(resolve_bucket_calendar personal "$mock_calendar_list")" "routes personal bucket to Personal calendar"

mock_calendar_list=$'个人\n工作\n生活'
assert_eq "工作" "$(resolve_bucket_calendar work "$mock_calendar_list")" "routes work bucket to Chinese calendar names"

mock_calendar_list=$'Home\nErrands'
assert_eq "$DEFAULT_CALENDAR" "$(resolve_bucket_calendar life "$mock_calendar_list")" "falls back to default when no matching life calendar exists"

mock_calendar_list=$'Work\nPersonal'
assert_eq "Custom" "$(select_calendar "Custom" work 1)" "explicit calendar wins over bucket"
assert_eq "Foo" "$(select_calendar "Foo" invalid 1)" "explicit calendar bypasses invalid bucket handling"

assert_eq "$DEFAULT_CALENDAR" "$(select_calendar "$DEFAULT_CALENDAR" life 0)" "bucket routing keeps default when no match exists"

mock_calendar_list=$'Personal, Shared\nWork'
assert_eq "$DEFAULT_CALENDAR" "$(select_calendar "$DEFAULT_CALENDAR" personal 0)" "comma in calendar name is preserved during matching"

printf 'addcal routing tests passed\n'
