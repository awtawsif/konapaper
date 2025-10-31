#!/bin/bash
# =================================================================
# HYPRLAND WALLPAPER ROTATOR (Advanced Moebooru Integration)
# Width/Height logic removed per request.
# Supports: tags, pools, artist, score filters, size limits, preload cache, cleanup
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
CLEAN_MODE=false
FORCE_CLEAN=false
INIT_MODE=false
DISCOVER_TAGS=false
DISCOVER_ARTISTS=false
LIST_POOLS=false
SEARCH_POOLS=""
EXPORT_TAGS=false


# --- Config ---
# Priority: 1. User Config -> 2. Script Directory -> 3. Current Directory
CONFIG_FILE="$HOME/.config/konapaper/konapaper.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="$(dirname "$0")/konapaper.conf"
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="./konapaper.conf"
fi

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
    EXPORTED_TAGS_FILE=${EXPORTED_TAGS_FILE:-"$HOME/.config/konapaper/discovered_tags.txt"}
    if [[ -f "$EXPORTED_TAGS_FILE" ]]; then
        mapfile -t RANDOM_TAGS_LIST < "$EXPORTED_TAGS_FILE"
    fi
}

process_random_tags() {
    if [[ "${#RANDOM_TAGS_LIST[@]}" -gt 0 && "$RANDOM_TAGS_COUNT" -gt 0 ]]; then
        local selected_tags
        selected_tags=$(printf "%s\n" "${RANDOM_TAGS_LIST[@]}" | shuf -n "$RANDOM_TAGS_COUNT" | tr '\n' ' ')
        if [[ -n "$TAGS" ]]; then
            TAGS="$TAGS $selected_tags"
        else
            TAGS="$selected_tags"
        fi
        TAGS="${TAGS%"${TAGS##*[![:space:]]}"}"
    fi
}

# Load config before parsing CLI args
load_config
MAX_PRELOAD_CACHE=${MAX_PRELOAD_CACHE:-10}
DISCOVER_LIMIT=${DISCOVER_LIMIT:-20}
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

parse_page_argument() {
    local arg="$1"

    # Handle "random" or "rand" (default range 1-1000)
    if [[ "$arg" == "random" || "$arg" == "rand" ]]; then
        echo $((RANDOM % 1000 + 1))
        return 0
    fi

    # Handle range format: "random:MIN-MAX" or "MIN-MAX"
    if [[ "$arg" =~ ^(random:)?([0-9]+)-([0-9]+)$ ]]; then
        local min="${BASH_REMATCH[2]}"
        local max="${BASH_REMATCH[3]}"

        if (( min >= max )); then
            echo "Error: Invalid range '$arg' (min must be less than max)" >&2
            return 1
        fi

        echo $((RANDOM % (max - min + 1) + min))
        return 0
    fi

    # Handle plain numeric page
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "$arg"
        return 0
    fi

    # Invalid format
    echo "Error: Invalid page format '$arg'. Use number, 'random', or 'MIN-MAX'" >&2
    return 1
}

# --- Parse Args ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -t|--tags) TAGS="$2"; shift ;;
        -l|--limit) LIMIT="$2"; shift ;;
        -p|--page)
            PAGE=$(parse_page_argument "$2")
            if ! PAGE=$(parse_page_argument "$2"); then
                exit 1
            fi
            shift ;;
        -r|--rating) RATING="$2"; shift ;;
        -o|--order) ORDER="$2"; shift ;;
        -s|--max-file-size) MAX_FILE_SIZE="$2"; shift ;;
        -m|--min-score) MIN_SCORE="$2"; shift ;;
        -a|--artist) ARTIST="$2"; shift ;;
        -P|--pool) POOL_ID="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        --discover-tags) DISCOVER_TAGS=true ;;
        --discover-artists) DISCOVER_ARTISTS=true ;;
        --list-pools) LIST_POOLS=true ;;
        --search-pools) SEARCH_POOLS="$2"; LIST_POOLS=true; shift ;;
         --random-tags) RANDOM_TAGS_COUNT="$2"; shift ;;
         --export-tags) EXPORT_TAGS=true ;;
          -cc|--clean-cache) CLEAN_MODE=true ;;
         -cf|--clean-force) CLEAN_MODE=true; FORCE_CLEAN=true ;;
         --init) INIT_MODE=true ;;
         -h|--help)
            echo "Usage: $0 [options]"
            echo "  -t, --tags           Tags (e.g. 'scenic sky')"
            echo "  -r, --rating         s/q/e (default: s)"
            echo "  -o, --order          random, score, date"
            echo "  -l, --limit          Number of posts to query (default: 50)"
             echo "  -p, --page           Page number, 'random', or 'MIN-MAX' range (default: 1)"
             echo "  -s, --max-file-size  Max file size (e.g. 500KB, 2MB; 0 to disable, default: 2MB)"
            echo "  -m, --min-score      Minimum score filter (optional)"
            echo "  -a, --artist         Filter by artist/uploader (optional)"
            echo "  -P, --pool           Use pool ID instead of tag search"
               echo "  -cc, --clean-cache   Clean all preload_* folders (keeps current.jpg)"
              echo "  -cf, --clean-force   Clean without confirmation"
              echo "  --init               Copy config file to user config directory"
              echo "  --dry-run            Show matching results without downloading"
              echo "  --discover-tags      Discover popular tags"
               echo "  --discover-artists   Discover artists"
               echo "  --list-pools         List available pools"
               echo "  --search-pools       Search pools by name"
               echo "  --random-tags        Number of random tags to select from config list"
               echo "  --export-tags        Export discovered tags to file (use with --discover-tags)"
             exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# --- Init Mode ---
if $INIT_MODE; then
    config_src="$(dirname "$0")/konapaper.conf"
    config_dest="$HOME/.config/konapaper/konapaper.conf"
    if [[ ! -f "$config_src" ]]; then
        echo "Error: Source config file not found at $config_src"
        exit 1
    fi
    mkdir -p "$HOME/.config/konapaper"
    cp "$config_src" "$config_dest"
    echo "Config file copied to $config_dest"
    exit 0
fi

# Process random tags if specified
process_random_tags

echo "Current run arguments:"
echo "  Limit: $LIMIT"
echo "  Page: $PAGE"
echo "  Rating: $RATING"
echo "  Order: $ORDER"
echo "  Max file size: $MAX_FILE_SIZE"
[[ -n "$TAGS" ]] && echo "  Tags: $TAGS"
[[ -n "$MIN_SCORE" ]] && echo "  Min score: $MIN_SCORE"
[[ -n "$ARTIST" ]] && echo "  Artist: $ARTIST"
[[ -n "$POOL_ID" ]] && echo "  Pool ID: $POOL_ID"
 $DRY_RUN && echo "  Dry run: enabled"
 $DISCOVER_TAGS && echo "  Tag discovery: enabled"
 $DISCOVER_ARTISTS && echo "  Artist discovery: enabled"
 $LIST_POOLS && echo "  Pool listing: enabled"
  [[ -n "$SEARCH_POOLS" ]] && echo "  Pool search: $SEARCH_POOLS"
  [[ "$RANDOM_TAGS_COUNT" -gt 0 ]] && echo "  Random tags count: $RANDOM_TAGS_COUNT"
  $CLEAN_MODE && echo "  Clean mode: enabled"
  $FORCE_CLEAN && echo "  Force clean: enabled"

MAX_FILE_SIZE_BYTES=$(convert_to_bytes "$MAX_FILE_SIZE")

# --- Paths ---
LOCKFILE="/tmp/hypr_wallpaper_setter.lock"
CACHE_DIR="$HOME/.cache/hypr_wallpapers"
mkdir -p "$CACHE_DIR"

PRELOAD_DIR="$CACHE_DIR/preload_$RATING"
mkdir -p "$PRELOAD_DIR"

CURRENT_WALLPAPER="$CACHE_DIR/current.jpg"

# --- Cleanup Mode ---
if $CLEAN_MODE; then
    echo "⚠️  Cleaning preload cache folders in: $CACHE_DIR"
    if ! $FORCE_CLEAN; then
        read -rp "Are you sure? This will delete all preloaded wallpapers but keep the current one. (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
    find "$CACHE_DIR" -maxdepth 1 -type d -name "preload_*" -exec rm -rf {} +
    echo "✅ Preload cache cleaned. Current wallpaper preserved."
    exit 0
fi

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
    ENCODED_TAGS="${TAGS// /+}"

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
        printf "ID\tScore\tAuthor\tWidth\tHeight\tSize\tTags\n"
        jq -r 'if type == "array" then .[] else .posts? // . end |
               [.id, (.score // 0), (.author // "unknown"),
                .width, .height, (.file_size|tostring), (.tags | .[0:50])] | @tsv' "$json"
        rm -f "$json"
        return 0
    fi

    local IMAGE_URL
    if (( MAX_FILE_SIZE_BYTES == 0 )); then
        IMAGE_URL=$(jq -r 'if type == "array" then . else .posts? // . end | .[].file_url' "$json" | shuf -n 1)
    else
        IMAGE_URL=$(jq -r --argjson max "$MAX_FILE_SIZE_BYTES" 'if type == "array" then . else .posts? // . end | map(select(.file_size != null and .file_size <= $max)) | .[].file_url' "$json" | shuf -n 1)
    fi

    rm -f "$json"

    if [ -z "$IMAGE_URL" ]; then
        if (( MAX_FILE_SIZE_BYTES == 0 )); then
            echo "No suitable image found."
        else
            echo "No suitable image found under ${MAX_FILE_SIZE}."
        fi
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
    if (( MAX_FILE_SIZE_BYTES > 0 && size > MAX_FILE_SIZE_BYTES )); then
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
    local existing
    existing=$(find "$PRELOAD_DIR" -type f -name "*.jpg" | wc -l)
    local available_slots=$(( MAX_PRELOAD_CACHE - existing ))
    if (( available_slots <= 0 )); then
        echo "Preload cache full ($existing wallpapers)."
        return
    fi
    local to_preload=$PRELOAD_COUNT
    if (( to_preload > available_slots )); then
        to_preload=$available_slots
    fi
    echo "Preloading up to $to_preload wallpapers..."
    for (( i=1; i<=to_preload; i++ )); do
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

# --- Discovery Functions ---
discover_tags() {
    local pattern="${1:-}"
    local order="${2:-count}"
    local limit="${3:-$DISCOVER_LIMIT}"

    echo "Discovering tags..."
    local api_url="${BASE_URL}/tag.xml?order=${order}&limit=${limit}"
    [[ -n "$pattern" ]] && api_url="${api_url}&name_pattern=${pattern}"

    local xml
    xml=$(mktemp)
    if curl -sf "$api_url" > "$xml"; then
        local tags_output
        tags_output=$(xmllint --xpath '//tag' "$xml" | sed -n 's/.*name="\([^"]*\)".*count="\([^"]*\)".*/\1 (\2 posts)/p' | head -"$limit")
        if $EXPORT_TAGS; then
            local tags_list
            tags_list=$(xmllint --xpath '//tag' "$xml" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | head -"$limit")
            mkdir -p "$(dirname "$EXPORTED_TAGS_FILE")"
            echo "$tags_list" > "$EXPORTED_TAGS_FILE"
            echo "Exported $limit tags to $EXPORTED_TAGS_FILE"
        else
            echo "$tags_output"
        fi
    else
        echo "Error: Failed to fetch tags"
    fi
    rm -f "$xml"
}

discover_artists() {
    local pattern="${1:-}"
    local limit="${2:-$DISCOVER_LIMIT}"

    echo "Discovering artists..."
    local api_url="${BASE_URL}/artist.xml?order=name&limit=${limit}"
    [[ -n "$pattern" ]] && api_url="${api_url}&name=${pattern}"

    local xml
    xml=$(mktemp)
    if curl -sf "$api_url" > "$xml"; then
        xmllint --xpath '//artist' "$xml" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | head -"$limit"
    else
        echo "Error: Failed to fetch artists"
    fi
    rm -f "$xml"
}

list_pools() {
    local query="${1:-}"
    local limit="${2:-$DISCOVER_LIMIT}"

    echo "Listing pools..."
    local api_url="${BASE_URL}/pool.xml?limit=${limit}"
    [[ -n "$query" ]] && api_url="${api_url}&query=${query}"

    local xml
    xml=$(mktemp)
    if curl -sf "$api_url" > "$xml"; then
        xmllint --xpath '//pool' "$xml" | sed -n 's/.*id="\([^"]*\)".*name="\([^"]*\)".*post_count="\([^"]*\)".*/\1: \2 (\3 posts)/p' | head -"$limit"
    else
        echo "Error: Failed to fetch pools"
    fi
    rm -f "$xml"
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

# --- Discovery Modes ---
if $DISCOVER_TAGS; then
    discover_tags
    flock -u 9
    exit 0
fi

if $DISCOVER_ARTISTS; then
    discover_artists
    flock -u 9
    exit 0
fi

if $LIST_POOLS; then
    list_pools "$SEARCH_POOLS"
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
