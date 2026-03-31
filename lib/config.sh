#!/bin/bash

readonly BASE_URL="https://konachan.net"
readonly POST_ENDPOINT="/post.json"
readonly DEFAULT_LIMIT=50
readonly DEFAULT_PAGE=1
readonly DEFAULT_RATING="s"
readonly DEFAULT_ORDER="random"
readonly DEFAULT_MAX_FILE_SIZE="2MB"
readonly DEFAULT_PRELOAD_COUNT=3
readonly DEFAULT_MAX_PRELOAD_CACHE=10
readonly DEFAULT_DISCOVER_LIMIT=20

readonly DEFAULT_CONFIG_FILE="$HOME/.config/konapaper/konapaper.conf"
readonly DEFAULT_CACHE_DIR="$HOME/.cache/konapaper"
readonly DEFAULT_LOCKFILE="/tmp/konapaper_setter.lock"
readonly DEFAULT_FAVORITES_DIR="$HOME/Pictures/Wallpapers"
readonly DEFAULT_LOG_FILE="$HOME/.config/konapaper/konapaper.log"
readonly DEFAULT_LOG_LEVEL="detailed"
readonly DEFAULT_LOG_MAX_SIZE=10485760

readonly CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
readonly CACHE_DIR="${CACHE_DIR:-$DEFAULT_CACHE_DIR}"
readonly LOCKFILE="${LOCKFILE:-$DEFAULT_LOCKFILE}"
readonly FAVORITES_DIR="${FAVORITES_DIR:-$DEFAULT_FAVORITES_DIR}"
readonly LOG_FILE="${LOG_FILE:-$DEFAULT_LOG_FILE}"
readonly LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"

readonly MAX_FILE_SIZE_BYTES
readonly MIN_FILE_SIZE_BYTES
readonly MIN_WIDTH_NUM
readonly MAX_WIDTH_NUM
readonly MIN_HEIGHT_NUM
readonly MAX_HEIGHT_NUM
readonly ASPECT_RATIO_FLOAT

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi

    load_defaults
}

load_defaults() {
    TAGS="${TAGS:-}"
    LIMIT="${LIMIT:-$DEFAULT_LIMIT}"
    PAGE="${PAGE:-$DEFAULT_PAGE}"
    RATING="${RATING:-$DEFAULT_RATING}"
    ORDER="${ORDER:-$DEFAULT_ORDER}"
    MAX_FILE_SIZE="${MAX_FILE_SIZE:-$DEFAULT_MAX_FILE_SIZE}"
    MIN_FILE_SIZE="${MIN_FILE_SIZE:-}"
    MIN_WIDTH="${MIN_WIDTH:-}"
    MAX_WIDTH="${MAX_WIDTH:-}"
    MIN_HEIGHT="${MIN_HEIGHT:-}"
    MAX_HEIGHT="${MAX_HEIGHT:-}"
    ASPECT_RATIO="${ASPECT_RATIO:-}"
    MIN_SCORE="${MIN_SCORE:-}"
    ARTIST="${ARTIST:-}"
    POOL_ID="${POOL_ID:-}"
    PRELOAD_COUNT="${PRELOAD_COUNT:-$DEFAULT_PRELOAD_COUNT}"
    MAX_PRELOAD_CACHE="${MAX_PRELOAD_CACHE:-$DEFAULT_MAX_PRELOAD_CACHE}"
    DISCOVER_LIMIT="${DISCOVER_LIMIT:-$DEFAULT_DISCOVER_LIMIT}"

    DRY_RUN="${DRY_RUN:-false}"
    CLEAN_MODE="${CLEAN_MODE:-false}"
    FORCE_CLEAN="${FORCE_CLEAN:-false}"
    INIT_MODE="${INIT_MODE:-false}"
    DISCOVER_TAGS="${DISCOVER_TAGS:-false}"
    DISCOVER_ARTISTS="${DISCOVER_ARTISTS:-false}"
    LIST_POOLS="${LIST_POOLS:-false}"
    SEARCH_POOLS="${SEARCH_POOLS:-}"
    EXPORT_TAGS="${EXPORT_TAGS:-false}"
    RANDOM_TAGS_COUNT="${RANDOM_TAGS_COUNT:-0}"

    FAV_MODE="${FAV_MODE:-false}"
    LIST_FAVS="${LIST_FAVS:-false}"
    FROM_FAVS="${FROM_FAVS:-false}"

    ENABLE_LOGGING="${ENABLE_LOGGING:-false}"
    LOG_ROTATION="${LOG_ROTATION:-true}"

    EXPORTED_TAGS_FILE="${EXPORTED_TAGS_FILE:-$HOME/.config/konapaper/discovered_tags.txt}"
    if [[ -f "$EXPORTED_TAGS_FILE" ]]; then
        mapfile -t RANDOM_TAGS_LIST < "$EXPORTED_TAGS_FILE"
    fi

    WALLPAPER_COMMAND="${WALLPAPER_COMMAND:-}"
    DISPLAY_SERVER="${DISPLAY_SERVER:-}"
}

process_cli_args() {
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
            -z|--min-file-size) MIN_FILE_SIZE="$2"; shift ;;
            --min-width) MIN_WIDTH="$2"; shift ;;
            --max-width) MAX_WIDTH="$2"; shift ;;
            --min-height) MIN_HEIGHT="$2"; shift ;;
            --max-height) MAX_HEIGHT="$2"; shift ;;
            --aspect-ratio) ASPECT_RATIO="$2"; shift ;;
            -m|--min-score) MIN_SCORE="$2"; shift ;;
            -a|--artist) ARTIST="$2"; shift ;;
            -P|--pool) POOL_ID="$2"; shift ;;
            -d|--dry-run) DRY_RUN=true ;;
            -D|--discover-tags) DISCOVER_TAGS=true ;;
            -A|--discover-artists) DISCOVER_ARTISTS=true ;;
            -L|--list-pools) LIST_POOLS=true ;;
            -S|--search-pools) SEARCH_POOLS="$2"; LIST_POOLS=true; shift ;;
            -R|--random-tags) RANDOM_TAGS_COUNT="$2"; shift ;;
            -E|--export-tags) EXPORT_TAGS=true ;;
            -cc|--clean-cache) CLEAN_MODE=true ;;
            -cf|--clean-force) CLEAN_MODE=true; FORCE_CLEAN=true ;;
            -I|--init) INIT_MODE=true ;;
            --fav) FAV_MODE=true ;;
            --list-favs) LIST_FAVS=true ;;
            --from-favs) FROM_FAVS=true ;;
            -h|--help)
                print_help
                exit 0 ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
}

print_help() {
    echo "Usage: $0 [options]"
    echo "  -t, --tags           Tags (e.g. 'scenic sky')"
    echo "  -r, --rating         s/q/e (default: s)"
    echo "  -o, --order          random, score, date"
    echo "  -l, --limit          Number of posts to query (default: 50)"
    echo "  -p, --page           Page number, 'random', or 'MIN-MAX' range (default: 1)"
    echo "  -s, --max-file-size  Max file size (e.g. 500KB, 2MB; 0 to disable, default: 2MB)"
    echo "  -z, --min-file-size  Min file size (e.g. 100KB, 1MB; 0 to disable, default: disabled)"
    echo "  --min-width         Minimum width in pixels (e.g., 1920)"
    echo "  --max-width         Maximum width in pixels (e.g., 3840)"
    echo "  --min-height        Minimum height in pixels (e.g., 1080)"
    echo "  --max-height        Maximum height in pixels (e.g., 2160)"
    echo "  --aspect-ratio      Aspect ratio (e.g., 16:9, 21:9, 4:3, 1:1, 3:2, 5:4, 32:9 or custom X:Y)"
    echo "  -m, --min-score      Minimum score filter (optional)"
    echo "  -a, --artist         Filter by artist/uploader (optional)"
    echo "  -P, --pool           Use pool ID instead of tag search"
    echo "  -cc, --clean-cache   Clean all preload_* folders (keeps current.jpg)"
    echo "  -cf, --clean-force   Clean without confirmation"
    echo "  -I, --init           Copy config file to user config directory"
    echo "  -d, --dry-run        Show matching results without downloading"
    echo "  -D, --discover-tags  Discover popular tags"
    echo "  -A, --discover-artists Discover artists"
    echo "  -L, --list-pools     List available pools"
    echo "  -S, --search-pools   Search pools by name"
    echo "  -R, --random-tags    Number of random tags to select from config list"
    echo "  -E, --export-tags    Export discovered tags to file (use with --discover-tags)"
    echo "  --fav                Save current wallpaper to favorites"
    echo "  --list-favs          List saved favorites"
    echo "  --from-favs          Set random wallpaper from favorites"
}

ensure_directories() {
    mkdir -p "$CACHE_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$FAVORITES_DIR"
}

get_preload_dir() {
    local rating="${1:-$RATING}"
    echo "$CACHE_DIR/preload_$rating"
}

get_current_wallpaper() {
    echo "$CACHE_DIR/current.jpg"
}
