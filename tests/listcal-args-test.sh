#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/listcal"

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

capture_file="$(mktemp)"
trap 'rm -f "$capture_file"' EXIT

query_events() {
  printf '%s\n%s\n' "$start_normalized" "$end_normalized" >"$capture_file"
  printf 'evt-1%s个人%s示例%s2026-04-18 00:00%s2026-04-18 01:00%s%s%s%s%s%s' \
    "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$FIELD_DELIM" "$RECORD_DELIM"
}

event_records_to_table() {
  :
}

main "个人" "2026-04-18 00:00" >/dev/null

captured_start="$(sed -n '1p' "$capture_file")"
captured_end="$(sed -n '2p' "$capture_file")"

assert_eq "2026-04-18 00:00" "$captured_start" "two-argument mode uses second positional as start"
assert_eq "2026-04-25 00:00" "$captured_end" "two-argument mode defaults end to seven days later"

printf 'listcal args tests passed\n'
