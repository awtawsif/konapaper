#!/bin/bash
# =================================================================
# KONAPAPER — Wallpaper Rotator for Wayland and X11
# Fetches wallpapers from Moebooru-based sites like Konachan.net
# Supports: tags, pools, artist, score filters, size limits, preload cache, cleanup
# =================================================================

# Resolve script directory for sourcing modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all modules (order matters for dependencies)
# shellcheck source=lib/constants.sh
source "$LIB_DIR/constants.sh"
# shellcheck source=lib/config.sh
source "$LIB_DIR/config.sh"
# shellcheck source=lib/helpers.sh
source "$LIB_DIR/helpers.sh"
# shellcheck source=lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=lib/formats.sh
source "$LIB_DIR/formats.sh"
# shellcheck source=lib/display.sh
source "$LIB_DIR/display.sh"
# shellcheck source=lib/download.sh
source "$LIB_DIR/download.sh"
# shellcheck source=lib/cache.sh
source "$LIB_DIR/cache.sh"
# shellcheck source=lib/discovery.sh
source "$LIB_DIR/discovery.sh"
# shellcheck source=lib/favorites.sh
source "$LIB_DIR/favorites.sh"
# shellcheck source=lib/init.sh
source "$LIB_DIR/init.sh"
# shellcheck source=lib/cli.sh
source "$LIB_DIR/cli.sh"

# --- Bootstrap ---
# Load config before parsing CLI args
load_config

# Set defaults for format options
PREFERRED_FORMAT="${PREFERRED_FORMAT:-auto}"
ANIMATED_ONLY="${ANIMATED_ONLY:-false}"

# Initialize logging
log_init
MAX_PRELOAD_CACHE=${MAX_PRELOAD_CACHE:-10}
DISCOVER_LIMIT=${DISCOVER_LIMIT:-20}

# --- Parse CLI ---
parse_cli_args "$@"

# Process random tags if specified
process_random_tags

# Log command arguments
log_command_args

# Only show run arguments for non-init modes
if ! $INIT_MODE; then
    echo "Current run arguments:"
    echo "  Limit: $LIMIT"
    echo "  Page: $PAGE"
    echo "  Rating: $RATING"
    echo "  Order: $ORDER"
    echo "  Max file size: $MAX_FILE_SIZE"
    [[ -n "$MIN_FILE_SIZE" ]] && echo "  Min file size: $MIN_FILE_SIZE"
    [[ -n "$MIN_WIDTH" ]] && echo "  Min width: $MIN_WIDTH"
    [[ -n "$MAX_WIDTH" ]] && echo "  Max width: $MAX_WIDTH"
    [[ -n "$MIN_HEIGHT" ]] && echo "  Min height: $MIN_HEIGHT"
    [[ -n "$MAX_HEIGHT" ]] && echo "  Max height: $MAX_HEIGHT"
    [[ -n "$ASPECT_RATIO" ]] && echo "  Aspect ratio: $ASPECT_RATIO"
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
fi

# --- Convert sizes and dimensions ---
MAX_FILE_SIZE_BYTES=$(convert_to_bytes "$MAX_FILE_SIZE")
if [[ -n "$MIN_FILE_SIZE" ]]; then
    MIN_FILE_SIZE_BYTES=$(convert_to_bytes "$MIN_FILE_SIZE")
else
    MIN_FILE_SIZE_BYTES=0
fi

# Convert aspect ratio if specified
ASPECT_RATIO_FLOAT="0"
if [[ -n "$ASPECT_RATIO" ]]; then
    if ! ASPECT_RATIO_FLOAT=$(parse_aspect_ratio "$ASPECT_RATIO"); then
        exit 1
    fi
fi

# Convert width/height to numeric or 0 for jq
MIN_WIDTH_NUM=${MIN_WIDTH:-0}
MAX_WIDTH_NUM=${MAX_WIDTH:-0}
MIN_HEIGHT_NUM=${MIN_HEIGHT:-0}
MAX_HEIGHT_NUM=${MAX_HEIGHT:-0}

# --- Paths ---
LOCKFILE="/tmp/konapaper_setter.lock"
CACHE_DIR="$HOME/.cache/konapaper"
mkdir -p "$CACHE_DIR"

PRELOAD_DIR="$CACHE_DIR/preload_$RATING"
mkdir -p "$PRELOAD_DIR"

# --- Cleanup Mode ---
if $CLEAN_MODE; then
    run_cache_cleanup
fi

# --- Lock Handling ---
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Another instance is already running. Exiting."
    exit 1
fi

# --- Init Mode ---
if $INIT_MODE; then
    run_init_mode
fi

# --- Main ---

# --- Favorites Modes ---
if $FAV_MODE; then
    save_to_favorites
    flock -u 9
    exit 0
fi

if $LIST_FAVS; then
    list_favorites
    flock -u 9
    exit 0
fi

if $FROM_FAVS; then
    set_from_favorites
    flock -u 9
    exit 0
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

log_write "INFO" "Starting wallpaper selection process"
next_wall=$(select_next_wallpaper)
if [ -n "$next_wall" ]; then
    log_write "INFO" "Using cached wallpaper: $next_wall"
    set_wallpaper "$next_wall"
else
    log_write "INFO" "No cached wallpapers found, downloading new one"
    echo "No cached wallpapers found; downloading..."
    
    temp_wallpaper="$CACHE_DIR/current.tmp"
    if download_wallpaper "$temp_wallpaper"; then
        ext=$(get_extension_from_url "$(cat "$CACHE_DIR/.last_url" 2>/dev/null)")
        final_wallpaper="$CACHE_DIR/current.$ext"
        [[ -f "${temp_wallpaper}.${ext}" ]] && mv "${temp_wallpaper}.${ext}" "$final_wallpaper"
        set_wallpaper "$final_wallpaper"
    else
        log_error "Failed to download wallpaper"
        echo "Failed to fetch wallpaper."
        flock -u 9
        exit 1
    fi
fi

log_write "INFO" "Starting preload process"
preload_wallpapers &
flock -u 9
log_success "Script execution completed successfully"
echo "Done."
