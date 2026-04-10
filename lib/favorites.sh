#!/bin/bash
# =================================================================
# KONAPAPER — Favorites Management
# Save, list, and set wallpapers from favorites
# =================================================================

save_to_favorites() {
    local source
    source=$(get_current_wallpaper)
    
    if [[ ! -f "$source" ]]; then
        echo "Error: No current wallpaper found at $source"
        echo "Download a wallpaper first before saving to favorites."
        return 1
    fi
    
    local fav_dir="${FAVORITES_DIR:-$HOME/Pictures/Wallpapers}"
    mkdir -p "$fav_dir"
    
    local ext
    ext=$(get_extension_from_url "$source")
    local filename
    filename="wallpaper_$(date '+%Y-%m-%d_%H%M%S').${ext}"
    local dest="$fav_dir/$filename"
    
    if cp "$source" "$dest"; then
        echo "Saved to favorites: $dest"
        log_success "Wallpaper saved to favorites: $dest"
    else
        echo "Error: Failed to copy wallpaper to favorites"
        log_error "Failed to copy wallpaper to favorites: $source -> $dest"
        return 1
    fi
    
    return 0
}

list_favorites() {
    local fav_dir="${FAVORITES_DIR:-$HOME/Pictures/Wallpapers}"
    
    if [[ ! -d "$fav_dir" ]]; then
        echo "No favorites directory found at $fav_dir"
        echo "Run with --fav to save your first favorite!"
        return 0
    fi
    
    local count
    count=$(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.webm" \) | wc -l)
    
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
    done < <(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.webm" \) -print0)
    
    echo ""
    echo "Total: $count favorite(s) ($(human_readable_size "$total_size"))"
    
    return 0
}

set_from_favorites() {
    local fav_dir="${FAVORITES_DIR:-$HOME/Pictures/Wallpapers}"
    
    if [[ ! -d "$fav_dir" ]]; then
        echo "No favorites directory found at $fav_dir"
        echo "Run with --fav to save your first favorite!"
        return 1
    fi
    
    local wallpapers
    wallpapers=$(find "$fav_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.webm" \))
    
    if [[ -z "$wallpapers" ]]; then
        echo "No favorites found in $fav_dir"
        echo "Run with --fav to save your first favorite!"
        return 1
    fi
    
    local selected
    selected=$(echo "$wallpapers" | shuf -n 1)
    
    echo "Selected: $(basename "$selected")"
    set_wallpaper "$selected"
}
