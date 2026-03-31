#!/bin/bash

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

parse_aspect_ratio() {
    local ratio="$1"
    case "$ratio" in
        "16:9") echo "1.78" ;;
        "21:9") echo "2.37" ;;
        "4:3") echo "1.33" ;;
        "1:1") echo "1.00" ;;
        "3:2") echo "1.50" ;;
        "5:4") echo "1.25" ;;
        "32:9") echo "3.56" ;;
        *)
            if [[ "$ratio" =~ ^([0-9]+):([0-9]+)$ ]]; then
                awk "BEGIN {printf \"%.2f\", ${BASH_REMATCH[1]}/${BASH_REMATCH[2]}}"
            else
                echo "Error: invalid aspect ratio '$ratio' (use format like '16:9')" >&2
                exit 1
            fi
            ;;
    esac
}

parse_page_argument() {
    local arg="$1"

    if [[ "$arg" == "random" || "$arg" == "rand" ]]; then
        echo $((RANDOM % 1000 + 1))
        return 0
    fi

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

    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "$arg"
        return 0
    fi

    echo "Error: Invalid page format '$arg'. Use number, 'random', or 'MIN-MAX'" >&2
    return 1
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

print_run_arguments() {
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
}
