#!/bin/bash

log_init() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir"
    
    if $LOG_ROTATION && [[ -f "$LOG_FILE" ]]; then
        local log_size
        log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        
        if (( log_size > DEFAULT_LOG_MAX_SIZE )); then
            for (( i=4; i>=1; i-- )); do
                if [[ -f "${LOG_FILE}.${i}" ]]; then
                    mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
                fi
            done
            if [[ -f "$LOG_FILE" ]]; then
                mv "$LOG_FILE" "${LOG_FILE}.1"
            fi
        fi
    fi
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo ""
        echo "=== KONAPAPER EXECUTION SESSION ==="
        echo "Timestamp: $timestamp"
        echo "Script: $0"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "PID: $$"
        echo "=================================="
    } >> "$LOG_FILE"
}

log_write() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$LOG_LEVEL" in
        "basic")
            [[ "$level" == "DEBUG" ]] && return 0
            ;;
        "detailed")
            [[ "$level" == "TRACE" ]] && return 0
            ;;
        "verbose")
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_command_args() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    log_write "INFO" "Command line arguments:"
    log_write "INFO" "  Tags: '$TAGS'"
    log_write "INFO" "  Limit: $LIMIT"
    log_write "INFO" "  Page: $PAGE"
    log_write "INFO" "  Rating: $RATING"
    log_write "INFO" "  Order: $ORDER"
    log_write "INFO" "  Max file size: $MAX_FILE_SIZE"
    [[ -n "$MIN_FILE_SIZE" ]] && log_write "INFO" "  Min file size: $MIN_FILE_SIZE"
    [[ -n "$MIN_WIDTH" ]] && log_write "INFO" "  Min width: $MIN_WIDTH"
    [[ -n "$MAX_WIDTH" ]] && log_write "INFO" "  Max width: $MAX_WIDTH"
    [[ -n "$MIN_HEIGHT" ]] && log_write "INFO" "  Min height: $MIN_HEIGHT"
    [[ -n "$MAX_HEIGHT" ]] && log_write "INFO" "  Max height: $MAX_HEIGHT"
    [[ -n "$ASPECT_RATIO" ]] && log_write "INFO" "  Aspect ratio: $ASPECT_RATIO"
    [[ -n "$MIN_SCORE" ]] && log_write "INFO" "  Min score: $MIN_SCORE"
    [[ -n "$ARTIST" ]] && log_write "INFO" "  Artist: $ARTIST"
    [[ -n "$POOL_ID" ]] && log_write "INFO" "  Pool ID: $POOL_ID"
    $DRY_RUN && log_write "INFO" "  Dry run: enabled"
    $DISCOVER_TAGS && log_write "INFO" "  Tag discovery: enabled"
    $DISCOVER_ARTISTS && log_write "INFO" "  Artist discovery: enabled"
    $LIST_POOLS && log_write "INFO" "  Pool listing: enabled"
    [[ -n "$SEARCH_POOLS" ]] && log_write "INFO" "  Pool search: $SEARCH_POOLS"
    [[ "$RANDOM_TAGS_COUNT" -gt 0 ]] && log_write "INFO" "  Random tags count: $RANDOM_TAGS_COUNT"
    $CLEAN_MODE && log_write "INFO" "  Clean mode: enabled"
    $FORCE_CLEAN && log_write "INFO" "  Force clean: enabled"
}

log_api_call() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    local api_url="$1"
    log_write "DEBUG" "API call: $api_url"
}

log_file_operation() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    local operation="$1"
    local filepath="$2"
    local extra_info="$3"
    
    if [[ "$LOG_LEVEL" == "verbose" ]]; then
        if [[ -n "$extra_info" ]]; then
            log_write "TRACE" "File operation: $operation - $filepath ($extra_info)"
        else
            log_write "TRACE" "File operation: $operation - $filepath"
        fi
    fi
}

log_wallpaper_set() {
    if ! $ENABLE_LOGGING; then
        return 0
    fi
    
    local wallpaper_path="$1"
    local command="$2"
    
    if [[ -f "$wallpaper_path" ]]; then
        local file_size
        file_size=$(stat -c%s "$wallpaper_path" 2>/dev/null || echo 0)
        log_write "INFO" "Wallpaper set: $wallpaper_path ($(human_readable_size "$file_size"))"
        log_write "DEBUG" "Command executed: $command"
    else
        log_write "ERROR" "Wallpaper file not found: $wallpaper_path"
    fi
}

log_error() {
    local message="$1"
    log_write "ERROR" "$message"
}

log_warning() {
    local message="$1"
    log_write "WARNING" "$message"
}

log_success() {
    local message="$1"
    log_write "INFO" "$message"
}

log_debug() {
    local message="$1"
    log_write "DEBUG" "$message"
}

log_trace() {
    local message="$1"
    log_write "TRACE" "$message"
}
