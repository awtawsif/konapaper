#!/bin/bash
# =================================================================
# KONAPAPER — Download Function
# Handles API querying, filtering, and image downloading
# =================================================================

download_wallpaper() {
    local outfile="$1"
    local ENCODED_TAGS
    
    # Get wallpaper tool for format decisions
    local detection
    detection=$(detect_display_server)
    local wallpaper_tool="${detection#*:}"
    
    # Determine effective tags based on ANIMATED_ONLY
    local effective_tags
    if [[ "$ANIMATED_ONLY" == "true" ]]; then
        effective_tags="animated"
    else
        effective_tags="$TAGS"
    fi
    
    # Add animated tag if needed
    local format_filter
    format_filter=$(get_format_filter "$PREFERRED_FORMAT")
    if [[ -n "$format_filter" && "$effective_tags" != *"$format_filter"* ]]; then
        if [[ -n "$effective_tags" ]]; then
            effective_tags="${effective_tags}+${format_filter}"
        else
            effective_tags="${format_filter}"
        fi
    fi
    
    local encoded_effective_tags="${effective_tags// /+}"

    local API_URL
    if [[ -n "$POOL_ID" ]]; then
        API_URL="${BASE_URL}/pool/show.json?id=${POOL_ID}"
    else
        API_URL="${BASE_URL}${POST_ENDPOINT}?limit=${LIMIT}&page=${PAGE}&tags=${encoded_effective_tags}+rating:${RATING}+order:${ORDER}"
        [[ -n "$MIN_SCORE" ]] && API_URL="${API_URL}+score:>=${MIN_SCORE}"
        [[ -n "$ARTIST" ]] && API_URL="${API_URL}+user:${ARTIST}"
    fi

    echo "-> Querying API: $API_URL"
    log_api_call "$API_URL"
    log_file_operation "create" "temp_json_file"
    local json
    json=$(mktemp)
    if ! curl -sf "$API_URL" > "$json"; then
        echo "Error: failed to reach $BASE_URL"
        log_error "API request failed: $BASE_URL"
        log_file_operation "delete" "$json"
        rm -f "$json"
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_write "INFO" "Dry run mode: displaying available posts"
        echo "---- Available Posts ----"
        printf "ID\tScore\tAuthor\tWidth\tHeight\tSize\tTags\n"
        if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )) && [[ -z "$MIN_WIDTH" && -z "$MAX_WIDTH" && -z "$MIN_HEIGHT" && -z "$MAX_HEIGHT" && "$ASPECT_RATIO_FLOAT" == "0" ]]; then
            jq -r 'if type == "array" then . else .posts? // . end | map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | .[] | @tsv' "$json"
        else
            jq -r --argjson max_size "$MAX_FILE_SIZE_BYTES" --argjson min_size "$MIN_FILE_SIZE_BYTES" \
                --argjson max_width "$MAX_WIDTH_NUM" --argjson min_width "$MIN_WIDTH_NUM" \
                --argjson max_height "$MAX_HEIGHT_NUM" --argjson min_height "$MIN_HEIGHT_NUM" \
                --argjson aspect_ratio "$ASPECT_RATIO_FLOAT" \
'if type == "array" then . else .posts? // . end | 
 map(select(
    type == "object" and 
    .file_size != null and 
    .width != null and 
    .height != null and
    (.file_size <= $max_size or $max_size == 0) and 
    (.file_size >= $min_size or $min_size == 0) and
    (.width <= $max_width or $max_width == 0) and
    (.width >= $min_width or $min_width == 0) and
    (.height <= $max_height or $max_height == 0) and
    (.height >= $min_height or $min_height == 0) and
    ($aspect_ratio == 0 or (.width / .height >= ($aspect_ratio - 0.02) and .width / .height <= ($aspect_ratio + 0.02)))
 )) | 
 map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | 
 .[] | @tsv' "$json"
        fi
        log_file_operation "delete" "$json"
        rm -f "$json"
        return 0
    fi

    local IMAGE_URL
    if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )) && [[ -z "$MIN_WIDTH" && -z "$MAX_WIDTH" && -z "$MIN_HEIGHT" && -z "$MAX_HEIGHT" && "$ASPECT_RATIO_FLOAT" == "0" ]]; then
        IMAGE_URL=$(jq -r 'if type == "array" then . else .posts? // . end | .[].file_url' "$json" | shuf -n 1)
    else
        IMAGE_URL=$(jq -r --argjson max_size "$MAX_FILE_SIZE_BYTES" --argjson min_size "$MIN_FILE_SIZE_BYTES" \
            --argjson max_width "$MAX_WIDTH_NUM" --argjson min_width "$MIN_WIDTH_NUM" \
            --argjson max_height "$MAX_HEIGHT_NUM" --argjson min_height "$MIN_HEIGHT_NUM" \
            --argjson aspect_ratio "$ASPECT_RATIO_FLOAT" \
'if type == "array" then . else .posts? // . end | 
 map(select(
    type == "object" and 
    .file_size != null and 
    .width != null and 
    .height != null and
    (.file_size <= $max_size or $max_size == 0) and 
    (.file_size >= $min_size or $min_size == 0) and
    (.width <= $max_width or $max_width == 0) and
    (.width >= $min_width or $min_width == 0) and
    (.height <= $max_height or $max_height == 0) and
    (.height >= $min_height or $min_height == 0) and
    ($aspect_ratio == 0 or (.width / .height >= ($aspect_ratio - 0.02) and .width / .height <= ($aspect_ratio + 0.02)))
 )) | 
 .[].file_url' "$json" | shuf -n 1)
    fi

    rm -f "$json"

    if [ -z "$IMAGE_URL" ]; then
        if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )); then
            echo "No suitable image found."
        elif (( MAX_FILE_SIZE_BYTES > 0 && MIN_FILE_SIZE_BYTES == 0 )); then
            echo "No suitable image found under ${MAX_FILE_SIZE}."
        elif (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES > 0 )); then
            echo "No suitable image found over ${MIN_FILE_SIZE}."
        else
            echo "No suitable image found between ${MIN_FILE_SIZE} and ${MAX_FILE_SIZE}."
        fi
        return 1
    fi

    echo "-> Downloading: $IMAGE_URL"
    log_write "INFO" "Downloading image: $IMAGE_URL"
    log_file_operation "download" "$outfile" "from $IMAGE_URL"
    
    # Get extension from URL and update outfile path
    local ext
    ext=$(get_extension_from_url "$IMAGE_URL")
    local outfile_with_ext="${outfile}.${ext}"
    
    # Store the actual URL for extension reference
    echo "$IMAGE_URL" > "${CACHE_DIR}/.last_url"
    
    local tmpfile="${outfile_with_ext}.tmp"
    if ! curl -sfL "$IMAGE_URL" -o "$tmpfile"; then
        echo "Error: download failed."
        log_error "Download failed: $IMAGE_URL"
        log_file_operation "delete" "$tmpfile"
        rm -f "$tmpfile"
        return 1
    fi
    
    mv "$tmpfile" "$outfile_with_ext"

    local size
    size=$(stat -c%s "$outfile_with_ext")
    if (( MAX_FILE_SIZE_BYTES > 0 && size > MAX_FILE_SIZE_BYTES )); then
        echo "Skipped (too large: $(human_readable_size "$size"))"
        log_warning "Image skipped due to size limit: $(human_readable_size "$size") > $MAX_FILE_SIZE"
        log_file_operation "delete" "$outfile_with_ext" "size limit exceeded"
        rm -f "$outfile_with_ext"
        return 1
    fi
    if (( MIN_FILE_SIZE_BYTES > 0 && size < MIN_FILE_SIZE_BYTES )); then
        echo "Skipped (too small: $(human_readable_size "$size"))"
        log_warning "Image skipped due to minimum size: $(human_readable_size "$size") < $MIN_FILE_SIZE"
        log_file_operation "delete" "$outfile_with_ext" "below minimum size"
        rm -f "$outfile_with_ext"
        return 1
    fi

    echo "-> Download complete ($(human_readable_size "$size"))"
    log_success "Image downloaded successfully: $outfile_with_ext ($(human_readable_size "$size"))"
    return 0
}
