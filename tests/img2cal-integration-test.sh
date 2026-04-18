#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

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

# ── Test 1: movie draft ─────────────────────────────────────────────
output="$("$repo_root/img2cal" --type movie --title "奥本海默" --start "2026-05-01 19:30" --location "万达影城" --seat "8排12座" --hall "IMAX 3号厅" --draft)"
assert_contains "$output" '"ticket_type": "movie"' "movie draft type"
assert_contains "$output" '"title": "看电影：奥本海默"' "movie draft title prefix"
assert_contains "$output" '"start": "2026-05-01 19:30"' "movie draft start"
assert_contains "$output" '"end": "2026-05-01 22:00"' "movie draft end (+150min)"
assert_contains "$output" '"location": "万达影城"' "movie draft location"
assert_contains "$output" "座位" "movie draft notes seat"
assert_contains "$output" "影厅" "movie draft notes hall"
printf 'test 1 passed: movie draft\n'

# ── Test 2: concert draft with missing end ──────────────────────────
output="$("$repo_root/img2cal" --type concert --title "周杰伦嘉年华" --start "2026-08-10 19:00" --location "上海体育场" --zone "内场A区" --row "第5排" --draft)"
assert_contains "$output" '"end": "2026-08-10 22:00"' "concert draft end (+180min)"
assert_contains "$output" "区域" "concert draft notes zone"
assert_contains "$output" "排号" "concert draft notes row"
printf 'test 2 passed: concert draft\n'

# ── Test 3: train draft missing end ─────────────────────────────────
output="$("$repo_root/img2cal" --type train --title "G1234" --start "2026-06-15 08:00" --location "上海虹桥站" --carriage "05车" --draft)"
assert_contains "$output" '"missing_fields"' "train draft missing end"
assert_contains "$output" "车厢" "train draft notes carriage"
printf 'test 3 passed: train draft missing end\n'

# ── Test 4: stdin JSON mode ─────────────────────────────────────────
output="$(printf '%s' '{"seat": "12A", "boarding_gate": "58", "terminal": "T2"}' | "$repo_root/img2cal" --type flight --title "CA9876" --start "2026-07-20 14:00" --end "2026-07-20 16:30" --location "上海浦东" --stdin --draft)"
assert_contains "$output" '"title": "航班：CA9876"' "flight stdin title"
assert_contains "$output" "座位" "flight stdin notes seat"
assert_contains "$output" "登机口" "flight stdin notes boarding_gate"
assert_contains "$output" "航站楼" "flight stdin notes terminal"
printf 'test 4 passed: stdin JSON mode\n'

# ── Test 5: apply blocked on missing end for train ──────────────────
if "$repo_root/img2cal" --type train --title "G1234" --start "2026-06-15 08:00" --location "上海虹桥" --apply >/dev/null 2>&1; then
  fail "apply should block on missing end"
fi
printf 'test 5 passed: apply blocked on missing end\n'

# ── Test 6: location resolution via context ─────────────────────────
context_file="$(mktemp)"
cat > "$context_file" <<'EOF'
{
  "common_venues": {
    "万达影城": "Wanda Cinema, Shanghai"
  }
}
EOF
output="$("$repo_root/img2cal" --type movie --title "流浪地球3" --start "2026-10-01 14:00" --location "万达影城" --context "$context_file" --draft)"
assert_contains "$output" '"location": "Wanda Cinema, Shanghai"' "context location resolution"
rm "$context_file"
printf 'test 6 passed: location resolution via context\n'

printf '\nAll img2cal integration tests passed\n'
