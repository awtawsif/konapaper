#!/bin/bash

save_to_favorites() {
    local source="$1"
    
    if [[ ! -f "$source" ]]; then
        echo "Error: No current wallpaper found at $source" >&2
        echo "Download a wallpaper first before saving to favorites." >&2
        return 1
    fi
    
    local fav_dir="${FAVORITES_DIR:-$DEFAULT_FAVORITES_DIR}"
    mkdir -p "$fav_dir"
    
    local filename
    filename="wallpaper_$(date '+%Y-%m-%d_%H%M%S').jpg"
    local dest="$fav_dir/$filename"
    
    if cp "$source" "$dest"; then
        echo "Saved to favorites: $dest"
        log_success "Wallpaper saved to favorites: $dest"
    else
        echo "Error: Failed to copy wallpaper to favorites" >&2
        log_error "Failed to copy wallpaper to favorites: $source -> $dest"
        return 1
    fi
    
    return 0
}

list_favorites() {
    local fav_dir="${FAVORITES_DIR:-$DEFAULT_FAVORITES_DIR}"
    
    if [[ ! -d "$fav_dir" ]]; then
        echo "No favorites directory found at $fav_dir"
        echo "Run with --fav to save your first favorite!"
        return 0
    fi
    
    local count
    count=$(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) | wc -l)
    
    if (( count == 0 )); then
        echo "No favorites found in $fav_dir"
        echo "Run with --fav to save your first favorite!"
        return 0
    fi
    
    echo "Favorites in $fav_dir:"
    echo ""
    
    local total_size=0
    while IFS= read -r -d '' file; do
        local size
        size=$(stat -c%s "$file")
        total_size=$((total_size + size))
        local size_human
        size_human=$(human_readable_size "$size")
        local name
        name=$(basename "$file")
        echo "  $name  ($size_human)"
    done < <(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) -print0)
    
    echo ""
    echo "Total: $count favorite(s) ($(human_readable_size "$total_size"))"
    
    return 0
}

set_from_favorites() {
    local fav_dir="${FAVORITES_DIR:-$DEFAULT_FAVORITES_DIR}"
    
    if [[ ! -d "$fav_dir" ]]; then
        echo "No favorites directory found at $fav_dir" >&2
        echo "Run with --fav to save your first favorite!" >&2
        return 1
    fi
    
    local wallpapers
    wallpapers=$(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \))
    
    if [[ -z "$wallpapers" ]]; then
        echo "No favorites found in $fav_dir" >&2
        echo "Run with --fav to save your first favorite!" >&2
        return 1
    fi
    
    local selected
    selected=$(echo "$wallpapers" | shuf -n 1)
    
    echo "Selected: $(basename "$selected")"
    set_wallpaper "$selected"
}

clean_cache() {
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
