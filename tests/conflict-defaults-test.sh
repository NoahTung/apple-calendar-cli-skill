#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$message (missing=$needle output=$haystack)"
}

# ── Verify addcal help mentions conflict flags ──────────────────────
help_output="$(bash "$repo_root/addcal" --help)"
assert_contains "$help_output" "--no-check-conflict" "addcal help mentions --no-check-conflict"
assert_contains "$help_output" "--check-conflict" "addcal help mentions --check-conflict"

# ── Verify default conflict-check behavior in addcal source ─────────
if ! grep -q 'local check_conflict=1' "$repo_root/addcal"; then
  fail "addcal should default check_conflict to 1"
fi

# ── Verify --no-check-conflict parsing exists ───────────────────────
if ! grep -q '\-\-no-check-conflict)' "$repo_root/addcal"; then
  fail "addcal should parse --no-check-conflict"
fi

printf 'conflict defaults tests passed\n'
