#!/usr/bin/env bash

DEFAULT_CALENDAR="个人"
DEFAULT_FORMAT="table"
FIELD_DELIM=$'\034'
RECORD_DELIM=$'\036'

calendar_die() {
  local cmd_name="${CALENDAR_CMD_NAME:-calendar}"
  printf '%s: %s\n' "$cmd_name" "$1" >&2
  exit 1
}

trim_whitespace() {
  local value="${1:-}"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "$value"
}

normalize_bucket() {
  local bucket

  bucket="$(trim_whitespace "${1:-}")"
  bucket="$(printf '%s' "$bucket" | tr '[:upper:]' '[:lower:]')"

  case "$bucket" in
    personal|work|life)
      printf '%s\n' "$bucket"
      ;;
    *)
      calendar_die "unsupported bucket '$1' (use personal, work, or life)"
      ;;
  esac
}

list_calendars() {
  osascript -e 'tell application "Calendar" to get name of every calendar' | python3 -c '
import sys
text = sys.stdin.read().strip()
if text:
    for item in text.split(","):
        value = item.strip()
        if value:
            print(value)
'
}

resolve_bucket_calendar() {
  local normalized_bucket="$1"
  local calendars_text="${2:-}"
  local candidate
  local calendar_name

  case "$normalized_bucket" in
    personal)
      set -- "个人" "Personal"
      ;;
    work)
      set -- "工作" "Work"
      ;;
    life)
      set -- "生活" "Life"
      ;;
    *)
      calendar_die "unsupported bucket '$normalized_bucket' (use personal, work, or life)"
      ;;
  esac

  while IFS= read -r candidate; do
    candidate="$(trim_whitespace "$candidate")"
    [[ -n "$candidate" ]] || continue

    for calendar_name in "$@"; do
      if [[ "$candidate" == "$calendar_name" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  done <<< "$calendars_text"

  printf '%s\n' "$DEFAULT_CALENDAR"
}

select_calendar() {
  local calendar="$1"
  local bucket="${2:-}"
  local explicit_calendar="${3:-0}"
  local normalized_bucket
  local calendars_text

  if [[ "$explicit_calendar" -eq 1 ]]; then
    printf '%s\n' "$calendar"
    return 0
  fi

  if [[ -n "$bucket" ]]; then
    normalized_bucket="$(normalize_bucket "$bucket")"
    calendars_text="$(list_calendars)"
    printf '%s\n' "$(resolve_bucket_calendar "$normalized_bucket" "$calendars_text")"
    return 0
  fi

  printf '%s\n' "$calendar"
}

python3_bin() {
  command -v python3
}

validate_datetime() {
  local input="$1"
  "$(python3_bin)" - "$input" <<'PY' >/dev/null 2>&1 || \
    calendar_die "invalid datetime '$input' (expected YYYY-MM-DD HH:MM)"
from datetime import datetime
import sys

datetime.strptime(sys.argv[1], "%Y-%m-%d %H:%M")
PY
}

normalize_time_phrase() {
  local input="$1"

  "$(python3_bin)" - "$input" <<'PY'
import re
import sys

value = sys.argv[1].strip().lower()
match = re.fullmatch(r'(\d{1,2})(?::(\d{2}))?\s*([ap]m)', value)
if not match:
    print(sys.argv[1])
    raise SystemExit(0)

hour = int(match.group(1))
minute = int(match.group(2) or "0")
suffix = match.group(3)
if hour < 1 or hour > 12 or minute > 59:
    raise SystemExit(1)
if suffix == "am":
    hour = 0 if hour == 12 else hour
else:
    hour = 12 if hour == 12 else hour + 12

print(f"{hour:02d}:{minute:02d}")
PY
}

parse_datetime_expression() {
  local input="$1"
  local now_override="${CALENDAR_NOW:-}"

  "$(python3_bin)" - "$input" "$now_override" <<'PY' || \
    calendar_die "invalid datetime '$input' (use YYYY-MM-DD HH:MM, 'today 18:00', 'tomorrow 9am', '+2h', or '+30m')"
from datetime import datetime, timedelta
import re
import sys

expr = sys.argv[1].strip()
now_override = sys.argv[2].strip()

if now_override:
    now = datetime.strptime(now_override, "%Y-%m-%d %H:%M")
else:
    now = datetime.now().replace(second=0, microsecond=0)

def parse_time_component(text: str) -> tuple[int, int]:
    value = text.strip().lower()
    match = re.fullmatch(r'(\d{1,2})(?::(\d{2}))?\s*([ap]m)', value)
    if match:
      hour = int(match.group(1))
      minute = int(match.group(2) or "0")
      if hour < 1 or hour > 12 or minute > 59:
          raise ValueError("invalid time")
      if match.group(3) == "am":
          hour = 0 if hour == 12 else hour
      else:
          hour = 12 if hour == 12 else hour + 12
      return hour, minute

    match = re.fullmatch(r'(\d{1,2}):(\d{2})', value)
    if match:
        hour = int(match.group(1))
        minute = int(match.group(2))
        if hour > 23 or minute > 59:
            raise ValueError("invalid time")
        return hour, minute

    raise ValueError("unsupported time")

strict_match = re.fullmatch(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}', expr)
if strict_match:
    dt = datetime.strptime(expr, "%Y-%m-%d %H:%M")
    print(dt.strftime("%Y-%m-%d %H:%M"))
    raise SystemExit(0)

relative_match = re.fullmatch(r'\+(\d+)([hmHM])', expr)
if relative_match:
    amount = int(relative_match.group(1))
    unit = relative_match.group(2).lower()
    delta = timedelta(hours=amount) if unit == "h" else timedelta(minutes=amount)
    print((now + delta).strftime("%Y-%m-%d %H:%M"))
    raise SystemExit(0)

day_match = re.fullmatch(r'(today|tomorrow)\s+(.+)', expr, flags=re.IGNORECASE)
if day_match:
    base = now if day_match.group(1).lower() == "today" else now + timedelta(days=1)
    hour, minute = parse_time_component(day_match.group(2))
    dt = base.replace(hour=hour, minute=minute, second=0, microsecond=0)
    print(dt.strftime("%Y-%m-%d %H:%M"))
    raise SystemExit(0)

raise ValueError("unsupported datetime")
PY
}

parse_datetime() {
  local input="$1"
  local prefix="$2"
  local normalized

  normalized="$(parse_datetime_expression "$input")"

  printf -v "${prefix}_normalized" '%s' "$normalized"
  printf -v "${prefix}_year" '%s' "${normalized:0:4}"
  printf -v "${prefix}_month" '%s' "${normalized:5:2}"
  printf -v "${prefix}_day" '%s' "${normalized:8:2}"
  printf -v "${prefix}_hour" '%s' "${normalized:11:2}"
  printf -v "${prefix}_minute" '%s' "${normalized:14:2}"
  printf -v "${prefix}_epoch" '%s' "$(
    "$(python3_bin)" - "$normalized" <<'PY'
from datetime import datetime
import sys

dt = datetime.strptime(sys.argv[1], "%Y-%m-%d %H:%M")
print(int(dt.timestamp()))
PY
  )"
}

compute_range_from_preset() {
  local preset="$1"
  local now_override="${CALENDAR_NOW:-}"

  "$(python3_bin)" - "$preset" "$now_override" <<'PY' || calendar_die "unsupported preset '$preset'"
from datetime import datetime, timedelta
import sys

preset = sys.argv[1]
now_override = sys.argv[2].strip()

if now_override:
    now = datetime.strptime(now_override, "%Y-%m-%d %H:%M")
else:
    now = datetime.now().replace(second=0, microsecond=0)

start = now.replace(hour=0, minute=0)
if preset == "today":
    end = start + timedelta(days=1)
elif preset == "tomorrow":
    start = start + timedelta(days=1)
    end = start + timedelta(days=1)
elif preset == "this-week":
    start = start - timedelta(days=start.weekday())
    end = start + timedelta(days=7)
else:
    raise ValueError("unsupported preset")

print(start.strftime("%Y-%m-%d %H:%M"))
print(end.strftime("%Y-%m-%d %H:%M"))
PY
}

default_end_from_start() {
  local start="$1"

  "$(python3_bin)" - "$start" <<'PY'
from datetime import datetime, timedelta
import sys

dt = datetime.strptime(sys.argv[1], "%Y-%m-%d %H:%M")
print((dt + timedelta(days=7)).strftime("%Y-%m-%d %H:%M"))
PY
}

normalize_alarm() {
  local input="${1:-}"

  if [[ -z "$input" ]]; then
    printf '\n'
    return 0
  fi

  case "$input" in
    none|NONE|None)
      printf 'none\n'
      ;;
    *)
      [[ "$input" =~ ^[0-9]+$ ]] || calendar_die "unsupported alarm '$input' (use minutes, 0, or none)"
      printf '%s\n' "$input"
      ;;
  esac
}

normalize_repeat() {
  local input="${1:-}"
  local normalized

  [[ -n "$input" ]] || {
    printf '\n'
    return 0
  }

  normalized="$(trim_whitespace "$input")"
  normalized="$(printf '%s' "$normalized" | tr '[:upper:]' '[:lower:]')"

  case "$normalized" in
    daily)
      printf 'FREQ=DAILY;INTERVAL=1\n'
      ;;
    weekly)
      printf 'FREQ=WEEKLY;INTERVAL=1\n'
      ;;
    monthly)
      printf 'FREQ=MONTHLY;INTERVAL=1\n'
      ;;
    yearly)
      printf 'FREQ=YEARLY;INTERVAL=1\n'
      ;;
    weekly\ *)
      "$(python3_bin)" - "$normalized" <<'PY' || calendar_die "unsupported repeat '$input' (use daily, weekly, monthly, yearly, or 'weekly 1,3,5')"
import re
import sys

value = sys.argv[1]
match = re.fullmatch(r'weekly\s+([1-7](?:,[1-7])*)', value)
if not match:
    raise SystemExit(1)

mapping = {
    "1": "MO",
    "2": "TU",
    "3": "WE",
    "4": "TH",
    "5": "FR",
    "6": "SA",
    "7": "SU",
}

days = [mapping[part] for part in match.group(1).split(",")]
print(f"FREQ=WEEKLY;INTERVAL=1;BYDAY={','.join(days)}")
PY
      ;;
    *)
      calendar_die "unsupported repeat '$input' (use daily, weekly, monthly, yearly, or 'weekly 1,3,5')"
      ;;
  esac
}

json_from_records() {
  local records="$1"

  "$(python3_bin)" - <<'PY' "$records"
import json
import sys

field_delim = "\034"
record_delim = "\036"
records = sys.argv[1]
items = []

if records:
    for raw_record in records.split(record_delim):
        if not raw_record.strip():
            continue
        parts = raw_record.split(field_delim)
        while len(parts) < 10:
            parts.append("")
        item = {
            "id": parts[0],
            "calendar": parts[1],
            "title": parts[2],
            "start": parts[3],
            "end": parts[4],
            "location": parts[5],
            "notes": parts[6],
            "url": parts[7],
            "alarm": parts[8],
            "recurrence": parts[9],
        }
        items.append(item)

print(json.dumps(items, ensure_ascii=False, indent=2))
PY
}

count_records() {
  local records="$1"

  "$(python3_bin)" - "$records" <<'PY'
import sys

print(sum(1 for part in sys.argv[1].split("\036") if part.strip()))
PY
}

event_records_to_table() {
  local records="$1"
  local show_extra="${2:-0}"
  local record
  local event_id
  local calendar
  local title
  local start
  local end
  local location
  local notes
  local url
  local alarm
  local recurrence

  while IFS= read -r -d "$RECORD_DELIM" record; do
    [[ -n "$record" ]] || continue
    IFS="$FIELD_DELIM" read -r event_id calendar title start end location notes url alarm recurrence <<< "$record"
    printf '[%s] %s | %s | %s -> %s\n' "$calendar" "$title" "$event_id" "$start" "$end"
    if [[ "$show_extra" -eq 1 ]]; then
      [[ -n "$location" ]] && printf '  location: %s\n' "$location"
      [[ -n "$notes" ]] && printf '  notes: %s\n' "$notes"
      [[ -n "$url" ]] && printf '  url: %s\n' "$url"
      [[ -n "$alarm" ]] && printf '  alarm: %s\n' "$alarm"
      [[ -n "$recurrence" ]] && printf '  recurrence: %s\n' "$recurrence"
    fi
  done < <(printf '%s' "$records")
}

find_record_by_id() {
  local records="$1"
  local target_id="$2"
  local record
  local event_id

  while IFS= read -r -d "$RECORD_DELIM" record; do
    IFS="$FIELD_DELIM" read -r event_id _ <<< "$record"
    if [[ "$event_id" == "$target_id" ]]; then
      printf '%s' "$record"
      return 0
    fi
  done < <(printf '%s' "$records")

  return 1
}
