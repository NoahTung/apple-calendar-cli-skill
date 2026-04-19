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

assert_exit_nonzero() {
  local cmd="$1"
  local message="$2"
  if (eval "$cmd") >/dev/null 2>&1; then
    fail "$message (expected non-zero exit)"
  fi
}

# ── Mock calendar_is_writable for require_writable_calendar tests ───

calendar_is_writable() {
  case "$1" in
    "Personal"|"Work"|"个人"|"工作")
      printf '1\n'
      ;;
    "Subscribed Holidays"|"Read-Only Cal")
      printf '0\n'
      ;;
    *)
      printf '1\n'
      ;;
  esac
}

assert_eq "1" "$(calendar_is_writable "Personal")" "writable calendar returns 1"
assert_eq "0" "$(calendar_is_writable "Subscribed Holidays")" "read-only calendar returns 0"

# require_writable_calendar should succeed for writable calendars
require_writable_calendar "Personal" || fail "require_writable_calendar should pass for Personal"
require_writable_calendar "Work" || fail "require_writable_calendar should pass for Work"

# require_writable_calendar should fail for read-only calendars
assert_exit_nonzero 'require_writable_calendar "Subscribed Holidays"' "require_writable_calendar should fail for read-only"
assert_exit_nonzero 'require_writable_calendar "Read-Only Cal"' "require_writable_calendar should fail for read-only"

printf 'calendar writable tests passed\n'
