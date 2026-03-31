#!/bin/bash

build_api_url() {
    local encoded_tags
    encoded_tags="${TAGS// /+}"

    if [[ -n "$POOL_ID" ]]; then
        echo "${BASE_URL}/pool/show.json?id=${POOL_ID}"
        return
    fi

    local url="${BASE_URL}${POST_ENDPOINT}?limit=${LIMIT}&page=${PAGE}&tags=${encoded_tags}+rating:${RATING}+order:${ORDER}"
    [[ -n "$MIN_SCORE" ]] && url="${url}+score:>=$MIN_SCORE"
    [[ -n "$ARTIST" ]] && url="${url}+user:${ARTIST}"
    echo "$url"
}

query_api() {
    local api_url="$1"
    local json
    json=$(mktemp)

    if ! curl -sf "$api_url" > "$json"; then
        echo "Error: failed to reach $BASE_URL" >&2
        rm -f "$json"
        return 1
    fi

    echo "$json"
}

get_filter_jq() {
    local jq_filter
    
    if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )) && \
       [[ -z "$MIN_WIDTH" && -z "$MAX_WIDTH" && -z "$MIN_HEIGHT" && -z "$MAX_HEIGHT" && "$ASPECT_RATIO_FLOAT" == "0" ]]; then
        echo '.'
        return
    fi

    jq_filter='select(
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
    )'

    echo "$jq_filter"
}

get_image_url_from_json() {
    local json="$1"
    local jq_filter
    jq_filter=$(get_filter_jq)

    if [[ "$jq_filter" == '.' ]]; then
        jq -r 'if type == "array" then . else .posts? // . end | .[].file_url' "$json" | shuf -n 1
    else
        jq -r --argjson max_size "$MAX_FILE_SIZE_BYTES" --argjson min_size "$MIN_FILE_SIZE_BYTES" \
            --argjson max_width "$MAX_WIDTH_NUM" --argjson min_width "$MIN_WIDTH_NUM" \
            --argjson max_height "$MAX_HEIGHT_NUM" --argjson min_height "$MIN_HEIGHT_NUM" \
            --argjson aspect_ratio "$ASPECT_RATIO_FLOAT" \
            "if type == \"array\" then . else .posts? // . end | map($jq_filter) | .[].file_url" "$json" | shuf -n 1
    fi
}

print_dry_run_results() {
    local json="$1"
    local jq_filter
    jq_filter=$(get_filter_jq)

    echo "---- Available Posts ----"
    printf "ID\tScore\tAuthor\tWidth\tHeight\tSize\tTags\n"

    if [[ "$jq_filter" == '.' ]]; then
        jq -r 'if type == "array" then . else .posts? // . end | map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | .[] | @tsv' "$json"
    else
        jq -r --argjson max_size "$MAX_FILE_SIZE_BYTES" --argjson min_size "$MIN_FILE_SIZE_BYTES" \
            --argjson max_width "$MAX_WIDTH_NUM" --argjson min_width "$MIN_WIDTH_NUM" \
            --argjson max_height "$MAX_HEIGHT_NUM" --argjson min_height "$MIN_HEIGHT_NUM" \
            --argjson aspect_ratio "$ASPECT_RATIO_FLOAT" \
            "if type == \"array\" then . else .posts? // . end | map($jq_filter) | map([.id, (.score // 0), (.author // \"unknown\"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | .[] | @tsv" "$json"
    fi
}

download_image() {
    local image_url="$1"
    local outfile="$2"

    log_write "INFO" "Downloading image: $image_url"
    log_file_operation "download" "$outfile" "from $image_url"
    
    local tmpfile="${outfile}.tmp"
    if ! curl -sfL "$image_url" -o "$tmpfile"; then
        echo "Error: download failed." >&2
        log_error "Download failed: $image_url"
        log_file_operation "delete" "$tmpfile"
        rm -f "$tmpfile"
        return 1
    fi
    
    mv "$tmpfile" "$outfile"

    local size
    size=$(stat -c%s "$outfile")
    if (( MAX_FILE_SIZE_BYTES > 0 && size > MAX_FILE_SIZE_BYTES )); then
        echo "Skipped (too large: $(human_readable_size "$size"))" >&2
        log_warning "Image skipped due to size limit: $(human_readable_size "$size")) > $MAX_FILE_SIZE"
        log_file_operation "delete" "$outfile" "size limit exceeded"
        rm -f "$outfile"
        return 1
    fi
    if (( MIN_FILE_SIZE_BYTES > 0 && size < MIN_FILE_SIZE_BYTES )); then
        echo "Skipped (too small: $(human_readable_size "$size"))" >&2
        log_warning "Image skipped due to minimum size: $(human_readable_size "$size")) < $MIN_FILE_SIZE"
        log_file_operation "delete" "$outfile" "below minimum size"
        rm -f "$outfile"
        return 1
    fi

    echo "-> Download complete ($(human_readable_size "$size"))"
    log_success "Image downloaded successfully: $outfile ($(human_readable_size "$size"))"
    return 0
}

get_no_image_message() {
    if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )); then
        echo "No suitable image found."
    elif (( MAX_FILE_SIZE_BYTES > 0 && MIN_FILE_SIZE_BYTES == 0 )); then
        echo "No suitable image found under ${MAX_FILE_SIZE}."
    elif (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES > 0 )); then
        echo "No suitable image found over ${MIN_FILE_SIZE}."
    else
        echo "No suitable image found between ${MIN_FILE_SIZE} and ${MAX_FILE_SIZE}."
    fi
}
