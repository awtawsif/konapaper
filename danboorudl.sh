#!/bin/bash
# =================================================================
# HYPRLAND WALLPAPER ROTATOR (Advanced Moebooru Integration)
# Width/Height logic removed per request.
# Supports: tags, pools, artist, score filters, size limits, preload cache
# =================================================================

BASE_URL="https://konachan.net"
POST_ENDPOINT="/post.json"

# --- Default Parameters ---
TAGS=""
LIMIT=50
PAGE=1
RATING="s"
ORDER="random"
MAX_FILE_SIZE="2MB"
MIN_SCORE=""
ARTIST=""
POOL_ID=""
PRELOAD_COUNT=3
DRY_RUN=false

# --- Helpers ---
convert_to_bytes() {
    local size_str="$1"
    size_str=$(echo "$size_str" | tr '[:lower:]' '[:upper:]')
    if [[ "$size_str" =~ ^[0-9]+$ ]]; then
        echo "$size_str"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)KB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024}"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)MB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024 * 1024}"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)GB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024 * 1024 * 1024}"
    else
        echo "Error: invalid size format '$1' (use e.g. 500KB or 2MB)" >&2
        exit 1
    fi
}

human_readable_size() {
    local bytes="$1"
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        awk "BEGIN {printf \"%.1fKB\", $bytes/1024}"
    else
        awk "BEGIN {printf \"%.2fMB\", $bytes/1048576}"
    fi
}

# --- Parse Args ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -t|--tags) TAGS="$2"; shift ;;
        -l|--limit) LIMIT="$2"; shift ;;
        -p|--page) PAGE="$2"; shift ;;
        -r|--rating) RATING="$2"; shift ;;
        -o|--order) ORDER="$2"; shift ;;
        -s|--max-file-size) MAX_FILE_SIZE="$2"; shift ;;
        -m|--min-score) MIN_SCORE="$2"; shift ;;
        -a|--artist) ARTIST="$2"; shift ;;
        -P|--pool) POOL_ID="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "  -t, --tags           Tags (e.g. 'scenic sky')"
            echo "  -r, --rating         s/q/e (default: s)"
            echo "  -o, --order          random, score, date"
            echo "  -l, --limit          Number of posts to query (default: 50)"
            echo "  -p, --page           Page number (default: 1)"
            echo "  -s, --max-file-size  Max file size (e.g. 500KB, 2MB, default: 2MB)"
            echo "  -m, --min-score      Minimum score filter (optional)"
            echo "  -a, --artist         Filter by artist/uploader (optional)"
            echo "  -P, --pool           Use pool ID instead of tag search"
            echo "  --dry-run            Show matching results without downloading"
            exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

MAX_FILE_SIZE_BYTES=$(convert_to_bytes "$MAX_FILE_SIZE")

# --- Paths ---
LOCKFILE="/tmp/hypr_wallpaper_setter.lock"
CACHE_DIR="$HOME/.cache/hypr_wallpapers"
mkdir -p "$CACHE_DIR"

ARGS_HASH=$(echo "${TAGS}_${RATING}_${ORDER}_${MAX_FILE_SIZE_BYTES}_${MIN_SCORE}_${ARTIST}_${POOL_ID}" | md5sum | awk '{print $1}')
PRELOAD_DIR="$CACHE_DIR/preload_$ARGS_HASH"
mkdir -p "$PRELOAD_DIR"

CURRENT_WALLPAPER="$CACHE_DIR/current.jpg"

# --- Lock Handling ---
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Another instance is already running. Exiting."
    exit 1
fi

# --- Download Function ---
download_wallpaper() {
    local outfile="$1"
    local ENCODED_TAGS
    ENCODED_TAGS=$(echo "$TAGS" | sed 's/ /+/g')

    local API_URL
    if [[ -n "$POOL_ID" ]]; then
        API_URL="${BASE_URL}/pool/show.json?id=${POOL_ID}"
    else
        API_URL="${BASE_URL}${POST_ENDPOINT}?limit=${LIMIT}&page=${PAGE}&tags=${ENCODED_TAGS}+rating:${RATING}+order:${ORDER}"
        [[ -n "$MIN_SCORE" ]] && API_URL="${API_URL}+score:>=${MIN_SCORE}"
        [[ -n "$ARTIST" ]] && API_URL="${API_URL}+user:${ARTIST}"
    fi

    echo "-> Querying API: $API_URL"
    local json
    json=$(mktemp)
    if ! curl -sf "$API_URL" > "$json"; then
        echo "Error: failed to reach $BASE_URL"
        rm -f "$json"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "---- Available Posts ----"
        # For pool responses, posts are inside .posts; otherwise top-level array
        jq -r '.posts? // . | [.id, .file_url, (.file_size|tostring), .width, .height] | @tsv' "$json"
        rm -f "$json"
        return 0
    fi

    # Select an image whose file_size exists and is <= max
    local IMAGE_URL
    IMAGE_URL=$(jq -r --argjson max "$MAX_FILE_SIZE_BYTES" \
        '.posts? // . | map(select(.file_size != null and .file_size <= $max)) | .[].file_url' "$json" | shuf -n 1)

    rm -f "$json"

    if [ -z "$IMAGE_URL" ]; then
        echo "No suitable image found under ${MAX_FILE_SIZE}."
        return 1
    fi

    echo "-> Downloading: $IMAGE_URL"
    if ! curl -sfL "$IMAGE_URL" -o "$outfile"; then
        echo "Error: download failed."
        rm -f "$outfile"
        return 1
    fi

    local size
    size=$(stat -c%s "$outfile")
    if (( size > MAX_FILE_SIZE_BYTES )); then
        echo "Skipped (too large: $(human_readable_size "$size"))"
        rm -f "$outfile"
        return 1
    fi

    echo "-> Download complete ($(human_readable_size "$size"))"
    return 0
}

# --- Wallpaper Handling ---
set_wallpaper() {
    local img="$1"
    echo "Setting wallpaper: $img"
    swww img "$img" --transition-type any --transition-fps 60 --transition-duration 1
}

# --- Preload Handling ---
preload_wallpapers() {
    echo "Preloading up to $PRELOAD_COUNT wallpapers..."
    local existing
    existing=$(find "$PRELOAD_DIR" -type f -name "*.jpg" | wc -l)
    if (( existing >= PRELOAD_COUNT )); then
        echo "Preload cache already has $existing wallpapers."
        return
    fi
    local needed=$(( PRELOAD_COUNT - existing ))
    echo "Need $needed new wallpapers."
    for (( i=1; i<=needed; i++ )); do
        local tmpfile="$PRELOAD_DIR/preload_$RANDOM.jpg"
        download_wallpaper "$tmpfile" &
        sleep 0.3
    done
    wait
    echo "Preloading finished."
}

select_next_wallpaper() {
    local next
    next=$(find "$PRELOAD_DIR" -type f -name "*.jpg" | shuf -n 1)
    if [ -n "$next" ]; then
        mv "$next" "$CURRENT_WALLPAPER"
        echo "$CURRENT_WALLPAPER"
    else
        return 1
    fi
}

# --- Main ---
if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon &
    sleep 0.5
fi

if [[ "$DRY_RUN" == true ]]; then
    download_wallpaper "/dev/null"
    flock -u 9
    exit 0
fi

next_wall=$(select_next_wallpaper)
if [ -n "$next_wall" ]; then
    set_wallpaper "$next_wall"
else
    echo "No cached wallpapers found; downloading..."
    if download_wallpaper "$CURRENT_WALLPAPER"; then
        set_wallpaper "$CURRENT_WALLPAPER"
    else
        echo "Failed to fetch wallpaper."
        flock -u 9
        exit 1
    fi
fi

preload_wallpapers &
flock -u 9
echo "Done."
