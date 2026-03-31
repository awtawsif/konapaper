#!/bin/bash

acquire_lock() {
    exec 9>"$LOCKFILE"
    if ! flock -n 9; then
        echo "Another instance is already running. Exiting." >&2
        return 1
    fi
    return 0
}

release_lock() {
    flock -u 9
}

preload_wallpapers() {
    local preload_dir
    preload_dir=$(get_preload_dir)
    mkdir -p "$preload_dir"
    
    local existing
    existing=$(find "$preload_dir" -type f -name "*.jpg" | wc -l)
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
        local tmpfile="$preload_dir/preload_$RANDOM.jpg"
        download_wallpaper "$tmpfile" &
        sleep 0.3
    done
    
    wait
    echo "Preloading finished."
}

download_wallpaper() {
    local outfile="$1"
    local api_url
    api_url=$(build_api_url)
    
    echo "-> Querying API: $api_url"
    log_api_call "$api_url"
    log_file_operation "create" "temp_json_file"
    
    local json
    json=$(query_api "$api_url")
    if [[ $? -ne 0 || -z "$json" ]]; then
        echo "Error: failed to reach $BASE_URL" >&2
        log_error "API request failed: $BASE_URL"
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_write "INFO" "Dry run mode: displaying available posts"
        print_dry_run_results "$json"
        rm -f "$json"
        return 0
    fi
    
    local image_url
    image_url=$(get_image_url_from_json "$json")
    rm -f "$json"
    
    if [[ -z "$image_url" ]]; then
        get_no_image_message
        return 1
    fi
    
    if download_image "$image_url" "$outfile"; then
        return 0
    else
        return 1
    fi
}

select_next_wallpaper() {
    local preload_dir
    preload_dir=$(get_preload_dir)
    
    local next
    next=$(find "$preload_dir" -type f -name "*.jpg" | shuf -n 1)
    
    if [[ -n "$next" ]]; then
        local current_wallpaper
        current_wallpaper=$(get_current_wallpaper)
        mv "$next" "$current_wallpaper"
        echo "$current_wallpaper"
    else
        return 1
    fi
}

run_main() {
    log_write "INFO" "Starting wallpaper selection process"
    
    local next_wall
    next_wall=$(select_next_wallpaper)
    
    if [[ -n "$next_wall" ]]; then
        log_write "INFO" "Using cached wallpaper: $next_wall"
        set_wallpaper "$next_wall"
    else
        log_write "INFO" "No cached wallpapers found, downloading new one"
        echo "No cached wallpapers found; downloading..."
        
        local current_wallpaper
        current_wallpaper=$(get_current_wallpaper)
        
        if download_wallpaper "$current_wallpaper"; then
            set_wallpaper "$current_wallpaper"
        else
            log_error "Failed to download wallpaper"
            echo "Failed to fetch wallpaper." >&2
            return 1
        fi
    fi
    
    log_write "INFO" "Starting preload process"
    preload_wallpapers &
    
    return 0
}
