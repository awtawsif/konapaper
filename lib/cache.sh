#!/bin/bash
# =================================================================
# KONAPAPER — Cache Management
# Preloading, wallpaper selection, cache cleanup, and path helpers
# =================================================================

get_current_wallpaper() {
    local existing
    existing=$(find "$CACHE_DIR" -maxdepth 1 -type f -name "current.*" | head -n1)
    if [[ -n "$existing" ]]; then
        echo "$existing"
    else
        echo "$CACHE_DIR/current.jpg"
    fi
}

run_cache_cleanup() {
    log_write "INFO" "Starting cache cleanup mode"
    echo "⚠️  Cleaning preload cache folders in: $CACHE_DIR"
    if ! $FORCE_CLEAN; then
        read -rp "Are you sure? This will delete all preloaded wallpapers but keep the current one. (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            log_write "INFO" "Cache cleanup aborted by user"
            return 1
        fi
    fi
    find "$CACHE_DIR" -maxdepth 1 -type d -name "preload_*" -exec rm -rf {} +
    echo "✅ Preload cache cleaned. Current wallpaper preserved."
    log_success "Cache cleanup completed"
    return 0
}

preload_wallpapers() {
    local existing
    existing=$(find "$PRELOAD_DIR" -type f \( -name "*.jpg" -o -name "*.gif" -o -name "*.webm" -o -name "*.png" \) | wc -l)
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
    if [[ "$NOTIFY_PRELOAD" == "true" ]]; then
        notify_progress_update "Preloading" "0/$to_preload wallpapers"
    fi
    local completed=0
    for (( i=1; i<=to_preload; i++ )); do
        # Use mktemp for fully unique per-job temp files to avoid race conditions
        local tmpfile
        tmpfile=$(mktemp "$PRELOAD_DIR/preload_job_XXXXXX")
        download_wallpaper "$tmpfile" &
    done
    wait

    # Count successfully preloaded
    completed=$(find "$PRELOAD_DIR" -type f \( -name "*.jpg" -o -name "*.gif" -o -name "*.webm" -o -name "*.png" \) | wc -l)
    completed=$((completed - existing))
    echo "Preloading finished."
    if [[ "$NOTIFY_PRELOAD" == "true" ]]; then
        notify_preload_complete "$completed"
    fi
}

select_next_wallpaper() {
    local next
    next=$(find "$PRELOAD_DIR" -type f \( -name "*.jpg" -o -name "*.gif" -o -name "*.webm" -o -name "*.png" \) | sort | head -n1)
    if [ -n "$next" ]; then
        local ext
        ext=$(get_extension_from_url "$next")
        local current_wallpaper="$CACHE_DIR/current.$ext"
        mv "$next" "$current_wallpaper"
        echo "$current_wallpaper"
    else
        return 1
    fi
}
