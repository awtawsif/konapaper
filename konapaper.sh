#!/bin/bash
# =================================================================
# KONAPAPER - Wallpaper Rotator for Wayland and X11
# Fetches wallpapers from Moebooru-based sites like Konachan.net
# =================================================================

set -euo pipefail

_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
readonly KONAPAPER_LIB_DIR="$_lib_dir"
unset _lib_dir

source "$KONAPAPER_LIB_DIR/config.sh"
source "$KONAPAPER_LIB_DIR/logging.sh"
source "$KONAPAPER_LIB_DIR/helpers.sh"
source "$KONAPAPER_LIB_DIR/api.sh"
source "$KONAPAPER_LIB_DIR/wallpaper.sh"
source "$KONAPAPER_LIB_DIR/discovery.sh"
source "$KONAPAPER_LIB_DIR/favorites.sh"
source "$KONAPAPER_LIB_DIR/core.sh"

main() {
    load_config
    process_cli_args "$@"
    
    ensure_directories
    log_init
    log_command_args
    
    if $INIT_MODE; then
        init_config
        return $?
    fi
    
    if ! acquire_lock; then
        return 1
    fi
    
    if $CLEAN_MODE; then
        clean_cache
        release_lock
        return $?
    fi
    
    if $FAV_MODE; then
        local current_wallpaper
        current_wallpaper=$(get_current_wallpaper)
        save_to_favorites "$current_wallpaper"
        release_lock
        return $?
    fi
    
    if $LIST_FAVS; then
        list_favorites
        release_lock
        return $?
    fi
    
    if $FROM_FAVS; then
        set_from_favorites
        release_lock
        return $?
    fi
    
    if $DISCOVER_TAGS; then
        discover_tags
        release_lock
        return $?
    fi
    
    if $DISCOVER_ARTISTS; then
        discover_artists
        release_lock
        return $?
    fi
    
    if $LIST_POOLS; then
        list_pools "$SEARCH_POOLS"
        release_lock
        return $?
    fi
    
    if $DRY_RUN; then
        print_run_arguments
        process_random_tags
        convert_filters
        download_wallpaper "/dev/null"
        release_lock
        return $?
    fi
    
    print_run_arguments
    
    process_random_tags
    
    convert_filters
    
    run_main
    
    log_success "Script execution completed successfully"
    echo "Done."
    
    release_lock
}

convert_filters() {
    MAX_FILE_SIZE_BYTES=$(convert_to_bytes "$MAX_FILE_SIZE")
    
    if [[ -n "$MIN_FILE_SIZE" ]]; then
        MIN_FILE_SIZE_BYTES=$(convert_to_bytes "$MIN_FILE_SIZE")
    else
        MIN_FILE_SIZE_BYTES=0
    fi
    
    if [[ -n "$ASPECT_RATIO" ]]; then
        if ! ASPECT_RATIO_FLOAT=$(parse_aspect_ratio "$ASPECT_RATIO"); then
            return 1
        fi
    else
        ASPECT_RATIO_FLOAT="0"
    fi
    
    MIN_WIDTH_NUM=${MIN_WIDTH:-0}
    MAX_WIDTH_NUM=${MAX_WIDTH:-0}
    MIN_HEIGHT_NUM=${MIN_HEIGHT:-0}
    MAX_HEIGHT_NUM=${MAX_HEIGHT:-0}
}

main "$@"
