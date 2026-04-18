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

plan_json='{
  "calendar": "个人",
  "events": [
    {
      "type": "single",
      "title": "Math Class",
      "start": "2026-09-01 09:00",
      "end": "2026-09-01 10:30"
    },
    {
      "type": "recurring",
      "title": "Gym",
      "start": "2026-04-18 18:00",
      "end": "2026-04-18 19:00",
      "recurrence": "weekly 1,3,5",
      "alarm": "15",
      "source_key": "gym-plan"
    }
  ]
}'

output="$(printf '%s' "$plan_json" | "$repo_root/batchcal" --stdin --dry-run)"
assert_contains "$output" 'Planned events: 2' "prints total planned events"
assert_contains "$output" 'Math Class' "shows single event title"
assert_contains "$output" 'Gym' "shows recurring event title"
assert_contains "$output" 'recurrence: weekly 1,3,5' "shows recurrence"
assert_contains "$output" 'source_key: gym-plan' "shows source_key"

if printf '%s' '{"events":[{"title":"Bad","start":"next Tuesday","end":"2026-04-18 19:00"}]}' | "$repo_root/batchcal" --stdin --dry-run >/tmp/batchcal-invalid.out 2>&1; then
  fail "invalid datetime should fail"
fi
assert_contains "$(cat /tmp/batchcal-invalid.out)" "invalid datetime 'next Tuesday'" "reports invalid start datetime"

if printf '%s' '{"events":[{"title":"Bad bucket","start":"2026-04-18 18:00","end":"2026-04-18 19:00","bucket":"weird"}]}' | "$repo_root/batchcal" --stdin --apply >/tmp/batchcal-apply.out 2>&1; then
  fail "apply should stop on addcal failure"
fi
assert_contains "$(cat /tmp/batchcal-apply.out)" "unsupported bucket" "propagates addcal failure during apply"

printf 'batchcal dry-run tests passed\n'
