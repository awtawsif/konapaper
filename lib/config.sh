#!/bin/bash
# =================================================================
# KONAPAPER — Configuration Loading
# Config file resolution, loading, and random tag processing
# =================================================================

# --- Config File Resolution ---
# Priority: 1. User Config -> 2. Script Directory -> 3. Current Directory
CONFIG_FILE="$HOME/.config/konapaper/konapaper.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="${SCRIPT_DIR}/konapaper.conf"
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="./konapaper.conf"
fi

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi

    # If RANDOM_TAGS_LIST is a file path (no parentheses) and exists, load tags from it
    if [[ -n "$RANDOM_TAGS_LIST" && "$RANDOM_TAGS_LIST" != *'('* && -f "$RANDOM_TAGS_LIST" ]]; then
        mapfile -t RANDOM_TAGS_LIST < "$RANDOM_TAGS_LIST"
    fi

    WALLPAPER_COMMAND=${WALLPAPER_COMMAND:-""}
    
    # Load logging configuration
    ENABLE_LOGGING=${ENABLE_LOGGING:-false}
    LOG_FILE=${LOG_FILE:-"$HOME/.config/konapaper/konapaper.log"}
    LOG_LEVEL=${LOG_LEVEL:-"detailed"}
    LOG_ROTATION=${LOG_ROTATION:-true}
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
