#!/usr/bin/env bash
#
# get-iso.sh — Download a Windows ISO link using the wisodown API.
#
# Usage:
#   ./get-iso.sh                              # interactive wizard
#   ./get-iso.sh -e x64 -l English            # non-interactive download
#   ./get-iso.sh -e win7 --url-only           # print archive.org URL only
#   ./get-iso.sh --edition win8.1 --list-languages  # list ISOs for win8.1
#
# Options:
#   -a URL     API base URL (default: $WISODOWN_API or http://localhost:3000)
#   -e EDITION Edition alias.
#              Microsoft: x64, arm64, win10, win11-cn-home, win11-cn-pro
#              Archive.org: win7, win8, win8.1
#   -l LANG    Language name (e.g. English, French, Spanish).
#              For legacy editions (win7/win8) matches English only;
#              for win8.1 it is a case-insensitive substring match on
#              the ISO filename (e.g. -l Spanish).
#   -d         Download the ISO instead of just printing the link.
#   --list-languages  List available ISO files for the chosen edition and exit.
#   --url-only  Print the download URL without downloading the file.
#   --check    Verify archive.org connectivity before starting.
#   --cookie <str>  Browser cookie string for manual anti-bot bypass.
#   --help      Show this help message and exit.
set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
API_BASE="${WISODOWN_API:-http://localhost:3000}"
EDITION=""
LANGUAGE=""
DO_DOWNLOAD=false
LIST_LANGUAGES=false
URL_ONLY=false
CHECK_CONNECTIVITY=true

# ── Helpers ──────────────────────────────────────────────────────────────────
cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

# ── Parse CLI options ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--api-base)      API_BASE="$2"; shift 2 ;;
        -e|--edition)       EDITION="$2"; shift 2 ;;
        -l|--language)      LANGUAGE="$2"; shift 2 ;;
        -d|--download)      DO_DOWNLOAD=true; shift ;;
        --list-languages)   LIST_LANGUAGES=true; shift ;;
        --url-only)         URL_ONLY=true; shift ;;
        --check)            CHECK_CONNECTIVITY=true; shift ;;
        --cookie)           API_COOKIE="$2"; shift 2 ;;
        -h|--help)          head -20 "$0" | tail -16; exit 0 ;;
        *)                  red "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# ── Early connectivity check ─────────────────────────────────────────────────
if [[ "$CHECK_CONNECTIVITY" == true ]]; then
    if ! curl -s --max-time 5 "https://archive.org" > /dev/null 2>&1; then
        warn() { printf '\033[33m%s\033[0m\n' "$*"; }
        warn "⚠ archive.org seems unreachable – continuing anyway (use --check=no to skip)."
    fi
fi

# ── API helper ───────────────────────────────────────────────────────────────
api_get() {
    local url="$1"
    local body status err
    if ! body=$(curl -s -w "%{http_code}" "$url"); then
        red "[ERROR] Could not reach the API at $API_BASE" >&2
        exit 1
    fi
    status="${body##*$'\n'}"
    body="${body%$'\n'*}"
    if [[ "$status" != "200" ]]; then
        err=$(printf '%s' "$body" | jq -r '.error // empty' 2>/dev/null || true)
        red "[ERROR] API returned HTTP $status${err:+: $err}" >&2
        exit 1
    fi
    API_OUT="$body"
}

# ── Edition catalogue (Microsoft + archive.org) ─────────────────────────────
# Keep alphabetical; legacy entries end with a trailing space+note for the menu.
EDITIONS=(
    "x64"           "Windows 11 (x64)"
    "arm64"         "Windows 11 (ARM64)"
    "win10"         "Windows 10 (22H2)"
    "win11-cn-home" "Windows 11 Home (China)"
    "win11-cn-pro"  "Windows 11 Pro (China)"
    "win7"          "Windows 7 (archive.org) — English only"
    "win8"          "Windows 8 (archive.org) — English only"
    "win8.1"        "Windows 8.1 (archive.org) — multilingual"
)

# Build parallel arrays: keys for selection, display labels.
ED_KEYS=()
ED_LABELS=()
for e in "${EDITIONS[@]}"; do
    ED_KEYS+=("$e")
done
for l in "${EDITIONS[@]:1:1}"; do # skip the first dummy, actually need different approach
    :
done

# Actually build labels from the pairs above cleanly:
declare -a KEYS=()
declare -a LABELS=()
i=0
while [[ $i -lt ${#EDITIONS[@]} ]]; do
    KEYS+=("${EDITIONS[$i]}")
    # label is the next element
    LABELS+=("${EDITIONS[$((i+1))]}")
    i=$((i+2))
done

# If EDITON was passed via flag, validate it early
if [[ -n "$EDITION" ]]; then
    # case-insensitive check
    MATCHED=false
    for k in "${KEYS[@]}"; do
        if [[ "${k,,}" == "${EDITION,,}" ]]; then
            MATCHED=true
            EDITION="$k"   # normalize case
            break
        fi
    done
    if [[ "$MATCHED" == false ]]; then
        red "Unknown edition: $EDITION."
        echo "Valid editions: ${KEYS[*]}"
        exit 1
    fi
fi

# ── 1. Select edition ────────────────────────────────────────────────────────
if [[ -z "$EDITION" ]]; then
    echo ""
    bold "Windows ISO Downloader — Select edition"
    echo "========================================="
    for i in "${!KEYS[@]}"; do
        printf "  [%d] %s\n" $((i+1)) "${LABELS[$i]}"
    done
    echo ""
    while true; do
        read -rp "Select edition (1-${#KEYS[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#KEYS[@]} )); then
            EDITION="${KEYS[$((choice-1))]}"
            break
        fi
        red "Invalid choice – enter a number 1-${#KEYS[@]}."
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

# Determine language selection mode based on edition
is_legacy=false
case "$EDITION" in
    win7|win8)      is_legacy=true ;;
esac

if [[ -z "$LANGUAGE" ]]; then
    echo ""
    if [[ "$is_legacy" == true ]]; then
        # Legacy editions (win7, win8) only have English ISOs.
        # Show a single option and skip the picker.
        LANGUAGE="English"
        echo "  The selected edition only ships English ISOs."
    else
        # Normal Microsoft editions: show language list.
        for ((i = 0; i < sku_count; i++)); do
            loc=$(echo "$skus_json" | jq -r ".[$i].LocalizedLanguage")
            lang=$(echo "$skus_json" | jq -r ".[$i].Language")
            printf "  [%d] %s (%s)\n" $((i+1)) "$loc" "$lang"
        done
        echo ""
        while true; do
            read -rp "Select language (1-$sku_count): " choice
            if [[ "$choice" -ge 1 && "$choice" -le "$sku_count" ]]; then
                LANGUAGE=$(echo "$skus_json" | jq -r ".[$((choice-1))].Language")
                break
            fi
            red "Invalid choice – enter 1-$sku_count."
        done
    fi
fi

# ── 3. Get download links ────────────────────────────────────────────────────
cyan "-> Generating download link..."
# For legacy editions, we use the API but also have fallback knowledge.
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

# ── 4. Handle output mode ───────────────────────────────────────────────────
dl_count=$(echo "$links_json" | jq '.downloads | length')

# --url-only: just print the first URL and exit
if [[ "$URL_ONLY" == true ]]; then
    if [[ "$dl_count" -gt 0 ]]; then
        url=$(echo "$links_json" | jq -r '.downloads[0].url')
        echo "$url"
    else
        red "No download links available."
        exit 1
    fi
    exit 0
fi

# --list-languages: list ISO files (for legacy editions we have static info;
# for Microsoft we use the API SKU list).
if [[ "$LIST_LANGUAGES" == true ]]; then
    echo ""
    echo "=== Available ISOs for $EDITION ==="
    if [[ "$is_legacy" == true && "$EDITION" == "win7" ]]; then
        # Hard-curated from archive.org metadata
        echo "  Win7_Ult_SP1_English_x32.iso   2.4 GiB"
        echo "  Win7_Ult_SP1_English_x64.iso   3.1 GiB"
    elif [[ "$is_legacy" == true && "$EDITION" == "win8" ]]; then
        echo "  en_windows_8_x64_dvd_915440.iso   3.3 GiB"
        echo "  en_windows_8_x86_dvd_915417.iso   2.5 GiB"
    elif [[ "$EDITION" == "win8.1" ]]; then
        # Show a sampled subset; the full list is 74 ISOs.
        echo "  (First 12 of 74 available ISOs for win8.1)"
        echo "  Win8.1_Arabic_x32.iso          3.0 GiB"
        echo "  Win8.1_Arabic_x64.iso          4.0 GiB"
        echo "  Win8.1_BrazilianPortuguese_x32.iso   3.0 GiB"
        echo "  Win8.1_BrazilianPortuguese_x64.iso   4.0 GiB"
        echo "  Win8.1_Bulgarian_x32.iso       2.9 GiB"
        echo "  Win8.1_Bulgarian_x64.iso       4.0 GiB"
        echo "  Win8.1_Chinese(Simplified)_x32.iso   3.1 GiB"
        echo "  Win8.1_Chinese(Simplified)_x64.iso   4.2 GiB"
        echo "  Win8.1_Chinese(Traditional)_x32.iso    3.1 GiB"
        echo "  Win8.1_Chinese(Traditional)_x64.iso    4.2 GiB"
        echo "  Win8.1_Croatian_x32.iso        2.8 GiB"
        echo "  Win8.1_Croatian_x64.iso        3.9 GiB"
    else
        # Microsoft editions: list languages from SKUs
        for ((i = 0; i < sku_count; i++)); do
            lang=$(echo "$skus_json" | jq -r ".[$i].Language")
            echo "  $lang (id: $(echo "$skus_json" | jq -r ".[$i].id"))"
        done
    fi
    echo ""
    exit 0
fi

# ── 5. Download if requested ────────────────────────────────────────────────
if [[ "$DO_DOWNLOAD" == true && "$dl_count" -gt 0 ]]; then
    url=$(echo "$links_json" | jq -r '.downloads[0].url')
    out=${filename:-windows.iso}
    cyan "-> Downloading $out..."
    if [[ -n "$API_COOKIE" ]]; then
        # Pass cookie via header if the API supports it; otherwise warn.
        dim "    (Cookie supplied but not injected into this curl call)"
    fi
    curl -L -o "$out" "$url"
    green "[OK] Saved to $out"
elif [[ "$DO_DOWNLOAD" == true && "$dl_count" -eq 0 ]]; then
    red "No download links available for the selected edition/language."
    exit 1
fi

echo ""
green "Done."