#!/usr/bin/env bash
# Prayer-times fetcher for the dashboard prayer widget.
# Mirrors services/Salat.qml:
#   methods table (auto method by nearest authority) -> location
#   (explicit > $SALAT_LOC > $WEATHER_LOC > cache > IP lookup)
#   -> Aladhan calendar month -> cache -> offline solar fallback.
# Deps: curl, jq, python3 (auto-pick + offline fallback), GNU date.
set -euo pipefail

VERSION="1.0.0"
UA="caelestia-shell/${VERSION} (+https://github.com/caelestia-dots/shell)"
ALADHAN="https://api.aladhan.com/v1"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia/salat.json"
# Prayer names in widget order (mirrors Salat.names; also hardcoded in the jq below).

METHOD="${SALAT_METHOD:-auto}"
METHOD_AUTO=0
METHODS_FRESH=0
METHODS_JSON="[]"
SCHOOL="${SALAT_SCHOOL:-0}"
LOC="${SALAT_LOC:-}"
MONTH_ARG=""
FETCH_METHODS=0
REFRESH=0
CLEAR_CACHE=0
TODAY_ONLY=0
QUIET=0

log() { [[ "$QUIET" -eq 1 ]] || echo "[prayer-fetch] $*" >&2; }
warn() { echo "[prayer-fetch] $*" >&2; }
die() { warn "error: $*"; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Mirrors services/Salat.qml for the prayer widget.

Options:
  --loc LAT,LON        Location (default: \$SALAT_LOC, cache, then IP lookup)
  --method ID|auto     Aladhan method id, or auto = nearest authority from
                       the live methods table (default: \$SALAT_METHOD or auto)
  --school 0|1         0=Shafi, 1=Hanafi (default: \$SALAT_SCHOOL or 0)
  --month YYYY-MM      Fetch this month instead of current month
  --cache PATH         Cache file (default: \$XDG_CACHE_HOME/caelestia/salat.json)
  --fetch-methods      Refresh the Aladhan methods table into the cache
  --refresh            Drop this month from cache and refetch
  --clear-cache        Drop all cached timetables and refetch
  --today-only         Print only today's HH:MM map (default prints widget JSON)
  -q, --quiet          Suppress info logs (errors still shown)
  -h, --help           Show this help

Env: SALAT_LOC, SALAT_METHOD, SALAT_SCHOOL, WEATHER_LOC (fallback like Weather.loc),
     XDG_CACHE_HOME.
Output (default): {"date":"DD-MM-YYYY","loc":"..","method":..,"methodAuto":bool,
  "school":..,"prayers":[{"name","time":"HH:MM"},...],
  "nextIndex":N, "next":{"name","time","in":".."},
  "isFriday":false, "source":"cache|aladhan|offline"}
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --loc) LOC="${2:?--loc needs LAT,LON}"; shift 2 ;;
        --method) METHOD="${2:?--method needs id}"; shift 2 ;;
        --school) SCHOOL="${2:?--school needs 0|1}"; shift 2 ;;
        --month) MONTH_ARG="${2:?--month needs YYYY-MM}"; shift 2 ;;
        --cache) CACHE="$2"; shift 2 ;;
        --fetch-methods) FETCH_METHODS=1; shift ;;
        --refresh) REFRESH=1; shift ;;
        --clear-cache) CLEAR_CACHE=1; shift ;;
        --today-only) TODAY_ONLY=1; shift ;;
        -q|--quiet) QUIET=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1 (see --help)" ;;
    esac
done

command -v curl >/dev/null || die "curl is required"
command -v jq >/dev/null || die "jq is required"

[[ "$SCHOOL" == "0" || "$SCHOOL" == "1" ]] || die "--school must be 0 or 1"
[[ "$METHOD" == auto || "$METHOD" =~ ^[0-9]+$ ]] || die "--method must be a numeric id or 'auto'"

mkdir -p "$(dirname "$CACHE")"
[[ -f "$CACHE" ]] || echo '{}' >"$CACHE"
# Ensure valid JSON so later jq merges never fail.
jq -e . "$CACHE" >/dev/null 2>&1 || echo '{}' >"$CACHE"

YEAR=""; MONTH=""
if [[ -n "$MONTH_ARG" ]]; then
    [[ "$MONTH_ARG" =~ ^[0-9]{4}-[0-9]{2}$ ]] || die "--month must be YYYY-MM"
    YEAR="${MONTH_ARG%%-*}"; MONTH="${MONTH_ARG##*-}"; MONTH="$((10#$MONTH))"
else
    YEAR="$(date +%Y)"; MONTH="$(date +%-m)"
fi
TODAY="$(date +%d-%m-%Y)"

# ---- location ---------------------------------------------------------------
# Priority (like Salat.activeLoc): explicit --loc / $SALAT_LOC first,
# then $WEATHER_LOC (Weather.loc fallback), then IP lookup.
fetch_ip_loc() {
    local body lat lon
    # Primary: ipapi.co (needs a UA or it 429s empty clients).
    if body="$(curl -sS -m 15 -A "$UA" -H "Accept: application/json" https://ipapi.co/json/ 2>/dev/null)"; then
        lat="$(echo "$body" | jq -r '.latitude // empty' 2>/dev/null)"
        lon="$(echo "$body" | jq -r '.longitude // empty' 2>/dev/null)"
        if [[ "$lat" =~ ^-?[0-9.]+$ && "$lon" =~ ^-?[0-9.]+$ ]]; then
            echo "${lat},${lon}"
            return 0
        fi
        # 429 → respect rate limit, fall through to secondary instead of hammering.
        if echo "$body" | grep -qi "throttl\|rate"; then
            log "ipapi.co rate-limited, trying ip-api.com"
            sleep 1
        fi
    fi
    # Secondary (same as Weather.qml): ip-api.com, no key needed.
    if body="$(curl -sS -m 15 'http://ip-api.com/json?fields=status,message,city,lat,lon' 2>/dev/null)"; then
        if [[ "$(echo "$body" | jq -r '.status // empty')" == "success" ]]; then
            lat="$(echo "$body" | jq -r '.lat // empty')"
            lon="$(echo "$body" | jq -r '.lon // empty')"
            if [[ "$lat" =~ ^-?[0-9.]+$ && "$lon" =~ ^-?[0-9.]+$ ]]; then
                echo "${lat},${lon}"
                return 0
            fi
        fi
    fi
    return 1
}

if [[ -z "$LOC" && -n "${WEATHER_LOC:-}" && "$WEATHER_LOC" == *","* ]]; then
    LOC="$WEATHER_LOC"
    log "using weather fallback loc $LOC"
fi
if [[ -z "$LOC" ]]; then
    # Reuse most-recent cached loc so offline runs need no network.
    LOC="$(jq -r '.months // {} | keys[] | select(test(",")) | split("|")[0]' "$CACHE" 2>/dev/null | tail -n1 || true)"
    if [[ -n "$LOC" ]]; then
        log "using last cached loc $LOC"
    fi
fi
if [[ -z "$LOC" ]]; then
    log "resolving location via IP..."
    LOC="$(fetch_ip_loc)" || die "could not resolve location (no --loc, no cache, IP lookup failed)"
    log "IP location: $LOC"
fi
[[ "$LOC" == *","* ]] || die "loc must be LAT,LON, got: $LOC"
LAT="$(echo "$LOC" | cut -d, -f1 | xargs)"
LON="$(echo "$LOC" | cut -d, -f2 | xargs)"
[[ "$LAT" =~ ^-?[0-9.]+$ && "$LON" =~ ^-?[0-9.]+$ ]] || die "invalid loc: $LOC"
# LC_NUMERIC=C: printf must always use '.' (e.g. de_DE would reject "41.0082").
LOC_NORM="$(LC_NUMERIC=C printf "%.4f,%.4f" "$LAT" "$LON")"
# NOTE: CACHE_KEY is computed further below, after method resolution
# (auto-pick needs the function definitions that follow).

cache_get_day() {
    jq -c --arg k "$CACHE_KEY" --arg d "$TODAY" '.months[$k][$d] // empty' "$CACHE"
}

# ---- methods table ----------------------------------------------------------
fetch_methods() {
    local body
    log "fetching methods table..."
    body="$(curl -sS -m 20 "$ALADHAN/methods")" || { warn "methods request failed"; return 1; }
    # Validate + normalise to [{id,name,lat,lon}] sorted by id; store for
    # offline use. Locations feed the auto method pick (Salat.pickMethodForLoc).
    local methods
    methods="$(echo "$body" | jq -c '[.data | to_entries[] | {id: (.value.id | tonumber), name: (.value.name // .key), lat: (.value.location.latitude // null), lon: (.value.location.longitude // null)} | select(.id != null)] | sort_by(.id)' 2>/dev/null)" \
        || { warn "unable to parse methods response"; return 1; }
    [[ "$methods" == "[]" || -z "$methods" ]] && { warn "empty methods table"; return 1; }
    local tmp
    tmp="$(mktemp)"
    jq --argjson m "$methods" '
        .methods = $m
    ' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"
    METHODS_FRESH=1
    log "saved $(echo "$methods" | jq 'length') methods"
}

# Nearest authority from the methods table by haversine distance
# (mirrors Salat.pickMethodForLoc; entries without a location are skipped).
# Prints the picked id, or nothing when undecidable. Needs python3.
pick_method() {
    local lat="$1" lon="$2" methods_json="$3"
    command -v python3 >/dev/null || return 1
    python3 - "$lat" "$lon" "$methods_json" <<'PY' 2>/dev/null
import sys, json, math
lat, lon = float(sys.argv[1]), float(sys.argv[2])
methods = json.loads(sys.argv[3])
best, bestd = None, float("inf")
for m in methods:
    try:
        mlat, mlon = float(m["lat"]), float(m["lon"])
    except (TypeError, ValueError, KeyError):
        continue
    dlat, dlon = math.radians(mlat - lat), math.radians(mlon - lon)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat)) * math.cos(math.radians(mlat)) * math.sin(dlon / 2) ** 2
    d = 2 * 6371 * math.asin(min(1, math.sqrt(a)))
    if d < bestd:
        best, bestd = int(m["id"]), d
if best is None:
    sys.exit(1)
print(best)
PY
}

# Usable (located) methods table for the auto pick: cache first, live fetch
# second. Sets METHODS_JSON; returns 1 when neither is available.
ensure_methods() {
    METHODS_JSON="$(jq -c '[.methods // [] | .[] | select(.lat != null and .lon != null)]' "$CACHE" 2>/dev/null)"
    if [[ -n "$METHODS_JSON" && "$METHODS_JSON" != "[]" ]]; then
        return 0
    fi
    if [[ "$METHODS_FRESH" -eq 1 ]]; then
        return 1
    fi
    if fetch_methods >/dev/null 2>&1; then
        METHODS_JSON="$(jq -c '[.methods // [] | .[] | select(.lat != null and .lon != null)]' "$CACHE" 2>/dev/null)"
        [[ -n "$METHODS_JSON" && "$METHODS_JSON" != "[]" ]] && return 0
    fi
    return 1
}

# Fallback Fajr/Isha angles per method (Salat.methodAngles); live table wins.
# Prints: "<fajrAngle|empty> <ishaAngle|empty> <ishaInterval|empty>"
angles_for() {
    local fajr="" isha="" interval=""
    if [[ -n "${METHOD_JSON:-}" ]]; then
        fajr="$(echo "$METHOD_JSON" | jq -r '.fajr // empty')"
        isha="$(echo "$METHOD_JSON" | jq -r '.ishaAngle // empty')"
        interval="$(echo "$METHOD_JSON" | jq -r '.ishaInterval // empty')"
    fi
    if [[ -z "$fajr" && -z "$isha" ]]; then
        case "$METHOD" in
            1) fajr=18; isha=18 ;;
            2|7) fajr=15; isha=15 ;;
            3|13) fajr=18; isha=17 ;;
            5) fajr=19.5; isha=17.5 ;;
            *) fajr=18; isha=17 ;;
        esac
    fi
    echo "$fajr $isha $interval"
}

# ---- method resolution ------------------------------------------------------
# Runs here (after all function definitions above) because auto-pick calls
# into them. Explicit --method wins; 'auto' (default, like Salat.methodAuto)
# picks the nearest authority from the live methods table by location -
# nothing is hardcoded. 13 is only a last-resort fallback.
if [[ "$FETCH_METHODS" -eq 1 ]]; then
    fetch_methods || warn "continuing with cached/fallback data"
fi
if [[ "$METHOD" == auto ]]; then
    METHOD_AUTO=1
    if ensure_methods; then
        if PICK="$(pick_method "$LAT" "$LON" "$METHODS_JSON")"; then
            PICK_NAME="$(echo "$METHODS_JSON" | jq -r --argjson id "$PICK" '.[] | select(.id == $id) | .name // empty')"
            log "auto method: ${PICK_NAME:-id $PICK} for $LOC_NORM"
            METHOD="$PICK"
        else
            warn "auto method undecidable, falling back to method 13"
            METHOD=13
        fi
    else
        warn "methods table unavailable, falling back to method 13"
        METHOD=13
    fi
fi
CACHE_KEY="${LOC_NORM}|m${METHOD}s${SCHOOL}|${YEAR}-${MONTH}"

# ---- calendar month ---------------------------------------------------------
fetch_month() {
    local year="$1" month="$2" attempt="${3:-0}"
    local url="https://api.aladhan.com/v1/calendar/${year}/${month}?latitude=${LAT}&longitude=${LON}&method=${METHOD}&school=${SCHOOL}"
    local resp code body tmp schedules key
    # Politeness pace: min 120ms between upstream requests (Salat.fetchMonth).
    sleep 0.12
    log "fetching ${year}-${month} (attempt $((attempt + 1)))..."
    resp="$(curl -sS -m 30 -w $'\n%{http_code}' "$url" 2>/dev/null)" || resp=""
    code="$(echo "$resp" | tail -n1)"
    body="$(echo "$resp" | sed '$d')"
    if [[ ! "$code" =~ ^2[0-9][0-9]$ || -z "$body" ]]; then
        log "request failed (http ${code:-none})"
        return 1
    fi
    # Keep only fully-usable days: DD-MM-YYYY + all six timings, suffix stripped.
    schedules="$(echo "$body" | jq -c '[
        (.data // [])[]
        | select((.date.gregorian.date // "") | test("^[0-9]{2}-[0-9]{2}-[0-9]{4}$"))
        | {key: .date.gregorian.date,
           value: {fajr: (.timings.Fajr // .timings.fajr // empty | split(" ")[0]),
               sunrise: (.timings.Sunrise // .timings.sunrise // empty | split(" ")[0]),
               dhuhr: (.timings.Dhuhr // .timings.dhuhr // empty | split(" ")[0]),
               asr: (.timings.Asr // .timings.asr // empty | split(" ")[0]),
               maghrib: (.timings.Maghrib // .timings.maghrib // empty | split(" ")[0]),
               isha: (.timings.Isha // .timings.isha // empty | split(" ")[0])}}
        | select(.value.fajr and .value.sunrise and .value.dhuhr and .value.asr and .value.maghrib and .value.isha)
    ] | from_entries' 2>/dev/null)" || schedules=""
    if [[ -z "$schedules" || "$schedules" == "{}" || "$schedules" == "null" ]]; then
        warn "no usable days in response"
        return 1
    fi
    key="${LOC_NORM}|m${METHOD}s${SCHOOL}|${year}-${month}"
    tmp="$(mktemp)"
    jq --arg k "$key" --argjson s "$schedules" --argjson mid "$METHOD" --argjson sch "$SCHOOL" '
        .months[$k] = $s
        | .method = $mid | .school = $sch
        | .months |= with_entries(select(.key | test("\\|m")))
    ' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"
    log "cached $(echo "$schedules" | jq 'keys | length') days under $key"
    return 0
}

fetch_month_retry() {
    local attempt=0
    while [[ $attempt -lt 3 ]]; do
        if fetch_month "$YEAR" "$MONTH" "$attempt"; then
            return 0
        fi
        attempt=$((attempt + 1))
        if [[ $attempt -lt 3 ]]; then
            # Backoff mirrors Salat.fetchFailed: 600ms * attempt.
            sleep "0.$((6 * attempt))"
        fi
    done
    return 1
}

# ---- offline solar fallback (Salat.offlineCompute) --------------------------
offline_compute_day() {
    command -v python3 >/dev/null || die "offline fallback needs python3"
    read -r FAJR_ANGLE ISHA_ANGLE ISHA_INTERVAL <<<"$(angles_for)"
    FAJR_ANGLE="${FAJR_ANGLE:-18}"
    python3 - "$LAT" "$LON" "$FAJR_ANGLE" "${ISHA_ANGLE:-}" "${ISHA_INTERVAL:-}" "$SCHOOL" <<'PY'
import sys, math, datetime
lat, lon = float(sys.argv[1]), float(sys.argv[2])
fajr_angle = float(sys.argv[3])
isha_arg, interval_arg, school = sys.argv[4], sys.argv[5], int(sys.argv[6])
isha_angle = float(isha_arg) if isha_arg not in ("", "null", "-1") else None
try: isha_interval = int(float(interval_arg))
except ValueError: isha_interval = -1
now = datetime.datetime.now()
# QML: startOfYear = new Date(y,0,0) = Dec 31 of prev year; n = floor((now-start)/86400)
n = (now - datetime.datetime(now.year - 1, 12, 31)).days
latR = math.radians(lat)
declR = math.radians(-23.44 * math.cos(2 * math.pi * (n + 10) / 365.25))
b = 2 * math.pi * (n - 81) / 364
eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b)
# QML: tzHours = -getTimezoneOffset()/60; getTimezoneOffset() = UTC-local,
# while utcoffset() = local-UTC, so tz = +utcoffset (no negation).
tz = datetime.datetime(now.year, now.month, now.day).astimezone().utcoffset().total_seconds() / 3600
transit = 720 - eot - 4 * (lon - 15 * tz)
def off(alt):
    aR = math.radians(alt)
    c = max(-1, min(1, (math.sin(aR) - math.sin(latR) * math.sin(declR)) / (math.cos(latR) * math.cos(declR))))
    return math.degrees(math.acos(c)) * 4
def fmt(t):
    t = (t % 1440 + 1440) % 1440
    h, m = int(t // 60), int(round(t % 60))
    if m == 60: m, h = 0, h + 1
    return f"{h % 24:02d}:{m:02d}"
sun, faj = off(-0.833), off(-fajr_angle)
ish = off(-isha_angle) if isha_angle is not None else -1
zen = abs(lat - math.degrees(declR))
asr_alt = math.degrees(math.atan(1 / (math.tan(math.radians(zen)) + (2 if school == 1 else 1))))
mag = transit + sun
out = {"fajr": fmt(transit - faj), "sunrise": fmt(transit - sun), "dhuhr": fmt(transit),
       "asr": fmt(transit + off(asr_alt)), "maghrib": fmt(mag),
       "isha": fmt(transit + ish) if ish >= 0 else fmt(mag + (isha_interval if isha_interval >= 0 else 90))}
import json; print(json.dumps(out))
PY
}

# ---- main -------------------------------------------------------------------
if [[ "$CLEAR_CACHE" -eq 1 ]]; then
    log "clearing timetable cache..."
    tmp="$(mktemp)"
    jq '.months = {}' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"
fi

# Live params for the offline fallback when available.
# (Methods table already handled above for --fetch-methods / auto.)
METHOD_JSON="$(jq -c --argjson mid "$METHOD" '.methods // [] | map(select(.id == $mid)) | .[0] // empty' "$CACHE" 2>/dev/null || true)"

SOURCE="cache"
DAY_JSON=""
if [[ "$REFRESH" -eq 1 ]]; then
    tmp="$(mktemp)"
    jq --arg k "$CACHE_KEY" 'del(.months[$k])' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"
fi

DAY_JSON="$(cache_get_day)"
# Legacy entries saved before Sunrise existed are refetched (Salat.applyDay).
if [[ -n "$DAY_JSON" ]] && ! echo "$DAY_JSON" | jq -e '.sunrise // empty' >/dev/null; then
    DAY_JSON=""
fi

if [[ -z "$DAY_JSON" ]]; then
    if fetch_month_retry; then
        DAY_JSON="$(cache_get_day)"
        SOURCE="aladhan"
    else
        warn "Aladhan request failed, falling back to offline calculator"
        DAY_JSON="$(offline_compute_day)"
        SOURCE="offline"
        # Persist offline day so the widget still renders while offline.
        tmp="$(mktemp)"
        jq --arg k "$CACHE_KEY" --arg d "$TODAY" --argjson v "$DAY_JSON" '
            .months[$k][$d] = $v
        ' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"
    fi
fi
[[ -n "$DAY_JSON" ]] || die "no prayer data available"

if [[ "$TODAY_ONLY" -eq 1 ]]; then
    echo "$DAY_JSON" | jq .
    exit 0
fi

# Next-prayer computation (Salat.updateNext): strictly < so the current
# minute stays current; wraps to index 0 (tomorrow's first) after Isha.
NOW_MINS=$((10#$(date +%H) * 60 + 10#$(date +%M)))
DOW="$(date +%u)" # 1=Mon..7=Sun; Friday=5
jq -n --argjson day "$DAY_JSON" --argjson now "$NOW_MINS" --arg date "$TODAY" \
    --arg loc "$LOC_NORM" --argjson method "$METHOD" --argjson school "$SCHOOL" \
    --arg source "$SOURCE" --argjson friday "$([ "$DOW" = "5" ] && echo true || echo false)" \
    --argjson methodAuto "$([ "$METHOD_AUTO" -eq 1 ] && echo true || echo false)" '
    ["Fajr","Sunrise","Dhuhr","Asr","Maghrib","Isha"] as $names
    | ($names | map({name: ., time: ($day[(. | ascii_downcase)])})) as $prayers
    | ($prayers | map(.time | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) ) as $mins
    | (first(range(0; 6) | select($mins[.] >= $now)) // 0) as $next
    | ((($mins[$next] - $now + 1440) % 1440)) as $left
    | {
        date: $date, loc: $loc, method: $method, methodAuto: $methodAuto, school: $school, source: $source,
        isFriday: $friday,
        prayers: $prayers,
        nextIndex: $next,
        next: {
          name: $prayers[$next].name,
          time: $prayers[$next].time,
          in: (if $left <= 0 then "now" elif ($left / 60 | floor) > 0
               then "\($left / 60 | floor)h \($left % 60)m" else "\($left)m" end)
        }
      }'
