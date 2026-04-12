#!/bin/bash
# =================================================================
# KONAPAPER — Helper Functions
# Size converters, aspect ratio parser, page argument parser
# =================================================================

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

    # Handle "random" or "rand" (default range 1-1000)
    if [[ "$arg" == "random" || "$arg" == "rand" ]]; then
        echo $((RANDOM % 1000 + 1))
        return 0
    fi

    # Handle range format: "random:MIN-MAX" or "MIN-MAX"
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

    # Handle plain numeric page
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "$arg"
        return 0
    fi

    # Invalid format
    echo "Error: Invalid page format '$arg'. Use number, 'random', or 'MIN-MAX'" >&2
    return 1
}

# Build the jq filter for selecting posts with optional dimension/size filtering.
# Returns a jq filter string that selects posts matching the given constraints.
# Globals used: MAX_FILE_SIZE_BYTES, MIN_FILE_SIZE_BYTES, MIN_WIDTH_NUM,
#   MAX_WIDTH_NUM, MIN_HEIGHT_NUM, MAX_HEIGHT_NUM, ASPECT_RATIO_FLOAT.
build_jq_filter() {
    local use_filters="$1"  # "true" if dimension/size filters are active

    if [[ "$use_filters" == "true" ]]; then
        cat <<'JQFILTER'
if type == "array" then . else .posts? // . end |
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
 .[] | "\(.id)|\(.file_url)"
JQFILTER
    else
        echo 'if type == "array" then . else .posts? // . end | .[] | "\(.id)|\(.file_url)"'
    fi
}

# Build the jq filter for dry-run display output (tabular format).
build_jq_dry_run_filter() {
    local use_filters="$1"

    if [[ "$use_filters" == "true" ]]; then
        cat <<'JQFILTER'
if type == "array" then . else .posts? // . end |
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
 .[] | @tsv
JQFILTER
    else
        echo 'if type == "array" then . else .posts? // . end | map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | .[] | @tsv'
    fi
}
