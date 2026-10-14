#!/usr/bin/env bash
#
# get-iso.sh — Download a Windows ISO link using the wisodown API.
#
# Usage:
#   ./get-iso.sh                              # interactive
#   ./get-iso.sh -e x64 -l English            # non-interactive
#   ./get-iso.sh -e arm64 -l Japanese -d       # download directly
#
# Options:
#   -a URL     API base URL (default: $WISODOWN_API or http://localhost:3000)
#   -e EDITION Edition: x64, arm64, win10, win11-cn-home, win11-cn-pro
#   -l LANG    Language name (e.g. English, French)
#   -d         Download the ISO instead of just printing the link

set -euo pipefail

# API base URL: -a flag wins, then $WISODOWN_API, then a local server.
API_BASE="${WISODOWN_API:-http://localhost:3000}"
EDITION=""
LANGUAGE=""
DO_DOWNLOAD=false

while getopts "a:e:l:dh" opt; do
    case $opt in
        a) API_BASE="$OPTARG" ;;
        e) EDITION="$OPTARG" ;;
        l) LANGUAGE="$OPTARG" ;;
        d) DO_DOWNLOAD=true ;;
        h)
            head -14 "$0" | tail -12
            exit 0
            ;;
        *) exit 1 ;;
    esac
done

# Check for curl and jq
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is required but not installed." >&2
        exit 1
    fi
done

cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

# GET a JSON endpoint, storing the body in $API_OUT. Fails with a helpful
# message (and exits the script) if the API cannot be reached or errors out.
api_get() {
    local body status err
    if ! body=$(curl -s -w $'\n%{http_code}' "$1"); then
        red "[ERROR] Could not reach the API at $API_BASE" >&2
        red "        Start a local server:" >&2
        red "          cargo run --release --features server -- --port 3000" >&2
        red "        or point elsewhere with -a <url> / WISODOWN_API=<url>." >&2
        exit 1
    fi
    status=${body##*$'\n'}
    body=${body%$'\n'*}
    if [[ "$status" != "200" ]]; then
        err=$(printf '%s' "$body" | jq -r '.error // empty' 2>/dev/null || true)
        red "[ERROR] API returned HTTP $status${err:+: $err}" >&2
        exit 1
    fi
    API_OUT="$body"
}

# ── 1. Select edition ────────────────────────────────────────────────────────

editions=("x64" "arm64" "win10" "win11-cn-home" "win11-cn-pro")
labels=("Windows 11 (x64)" "Windows 11 (ARM64)" "Windows 10" "Windows 11 Home China" "Windows 11 Pro China")

if [[ -z "$EDITION" ]]; then
    echo ""
    bold "Windows ISO Downloader"
    echo "======================"
    echo ""
    for i in "${!editions[@]}"; do
        printf "  [%d] %s\n" $((i + 1)) "${labels[$i]}"
    done
    echo ""
    while true; do
        read -rp "Select edition (1-${#editions[@]}): " choice
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            EDITION="${editions[$((choice - 1))]}"
            break
        fi
    done
fi

# ── 2. Fetch languages ───────────────────────────────────────────────────────

cyan "-> Fetching languages for '$EDITION'..."
api_get "$API_BASE/api/skus?edition=$EDITION"
skus_json="$API_OUT"

if echo "$skus_json" | jq -e '.error' &>/dev/null; then
    red "[ERROR] $(echo "$skus_json" | jq -r '.error')"
    exit 1
fi

sku_count=$(echo "$skus_json" | jq 'length')

if [[ -z "$LANGUAGE" ]]; then
    echo ""
    for ((i = 0; i < sku_count; i++)); do
        loc=$(echo "$skus_json" | jq -r ".[$i].LocalizedLanguage")
        lang=$(echo "$skus_json" | jq -r ".[$i].Language")
        printf "  [%d] %s (%s)\n" $((i + 1)) "$loc" "$lang"
    done
    echo ""
    while true; do
        read -rp "Select language (1-$sku_count): " choice
        if [[ "$choice" -ge 1 && "$choice" -le "$sku_count" ]]; then
            LANGUAGE=$(echo "$skus_json" | jq -r ".[$((choice - 1))].Language")
            break
        fi
    done
fi

# ── 3. Get download links ────────────────────────────────────────────────────

cyan "-> Generating download link..."
api_get "$API_BASE/api/links?edition=$EDITION&language=$(printf '%s' "$LANGUAGE" | jq -sRr @uri)"
links_json="$API_OUT"

if echo "$links_json" | jq -e '.error' &>/dev/null; then
    red "[ERROR] $(echo "$links_json" | jq -r '.error')"
    exit 1
fi

loc_lang=$(echo "$links_json" | jq -r '.localizedLanguage')
filename=$(echo "$links_json" | jq -r '.filename // empty')
expires=$(echo "$links_json" | jq -r '.expiresAt // empty')

echo ""
green "[OK] $loc_lang"
[[ -n "$filename" ]] && dim "  File: $filename"
[[ -n "$expires" ]]  && dim "  Expires: $expires"
echo ""

dl_count=$(echo "$links_json" | jq '.downloads | length')
for ((i = 0; i < dl_count; i++)); do
    name=$(echo "$links_json" | jq -r ".downloads[$i].name")
    url=$(echo "$links_json" | jq -r ".downloads[$i].url")
    bold "  $name"
    printf '  \033[33m%s\033[0m\n\n' "$url"
done

# ── 4. Show hashes ───────────────────────────────────────────────────────────

hash_count=$(echo "$links_json" | jq '.hashes | length')
if [[ "$hash_count" -gt 0 ]]; then
    bold "SHA-256 Hashes:"
    echo "$links_json" | jq -r '.hashes | to_entries[] | "  \(.key): \(.value)"'
    echo ""
fi

# ── 5. Download if requested ─────────────────────────────────────────────────

if $DO_DOWNLOAD && [[ "$dl_count" -gt 0 ]]; then
    url=$(echo "$links_json" | jq -r '.downloads[0].url')
    out=${filename:-windows.iso}
    cyan "-> Downloading $out..."
    curl -L -o "$out" "$url"
    green "[OK] Saved to $out"
fi
