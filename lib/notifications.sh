#!/bin/bash
# =================================================================
# KONAPAPER — Notification Toasts
# Progressive progress toasts using notify-send with replace-id
# =================================================================

# shellcheck disable=SC2034

# Global replace-id counter for toast updates
NOTIFY_REPLACE_ID=0

# --- Detection ---

notify_send_check() {
    if command -v notify-send >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# --- Core Notification Functions ---

# Send a new notification and capture its ID for later replacement.
# Usage: notify_new "summary" "body" [urgency] [timeout_ms]
notify_new() {
    local summary="$1"
    local body="$2"
    local urgency="${3:-normal}"
    local timeout="${4:-2000}"

    if [[ "$ENABLE_NOTIFICATIONS" != "true" ]]; then
        return 0
    fi

    if ! notify_send_check; then
        return 1
    fi

    NOTIFY_REPLACE_ID=$(notify-send \
        --app-name="Konapaper" \
        --urgency="$urgency" \
        --expire-time="$timeout" \
        --print-id \
        "$summary" \
        "$body" 2>/dev/null)

    log_write "INFO" "Notification sent: $summary — $body"
}

# Update an existing notification by replace-id.
# Usage: notify_update "summary" "body" [urgency] [timeout_ms]
notify_update() {
    local summary="$1"
    local body="$2"
    local urgency="${3:-normal}"
    local timeout="${4:-2000}"

    if [[ "$ENABLE_NOTIFICATIONS" != "true" ]]; then
        return 0
    fi

    if [[ "$NOTIFY_REPLACE_ID" -eq 0 ]] 2>/dev/null; then
        # No active toast to update; send a new one
        notify_new "$summary" "$body" "$urgency" "$timeout"
        return $?
    fi

    if ! notify_send_check; then
        return 1
    fi

    notify-send \
        --app-name="Konapaper" \
        --urgency="$urgency" \
        --expire-time="$timeout" \
        --replace-id="$NOTIFY_REPLACE_ID" \
        "$summary" \
        "$body" 2>/dev/null

    log_write "INFO" "Notification updated: $summary — $body"
}

# --- Convenience Wrappers ---

# Send the initial progress toast.
# Usage: notify_progress_start "stage" "details"
notify_progress_start() {
    local stage="$1"
    local details="${2:-}"

    local body=""
    if [[ -n "$details" ]]; then
        body="$details"
    fi

    notify_new "🔍 Konapaper" "$body" "normal" 0
}

# Update the progress toast with a new stage.
# Usage: notify_progress_update "stage" "details"
notify_progress_update() {
    local stage="$1"
    local details="${2:-}"

    local body=""
    if [[ -n "$details" ]]; then
        body="$details"
    fi

    notify_update "🔍 Konapaper" "$body" "normal" 0
}

# Send the final completion toast.
# Usage: notify_complete "details"
notify_complete() {
    local details="${1:-}"

    local timeout="${NOTIFY_TIMEOUT:-5000}"

    if [[ -n "$details" ]]; then
        notify_update "✅ Wallpaper Set" "$details" "normal" "$timeout"
    else
        notify_update "✅ Wallpaper Set" "Wallpaper changed successfully" "normal" "$timeout"
    fi

    NOTIFY_REPLACE_ID=0
}

# Send an error toast.
# Usage: notify_error "summary" "details"
notify_error() {
    local summary="${1:-Error}"
    local details="${2:-An error occurred}"
    local timeout="${NOTIFY_TIMEOUT:-8000}"

    notify_new "❌ $summary" "$details" "critical" "$timeout"
    NOTIFY_REPLACE_ID=0
}

# Send a favorites-saved toast.
# Usage: notify_favorite_saved "filename"
notify_favorite_saved() {
    local filename="$1"

    notify_new "⭐ Favorite Saved" "Saved: $filename" "normal" "${NOTIFY_TIMEOUT:-5000}"
    NOTIFY_REPLACE_ID=0
}

# Send a preload progress toast (optional, background).
# Usage: notify_preload_progress "count" "total"
notify_preload_progress() {
    local count="$1"
    local total="$2"

    if [[ "$NOTIFY_PRELOAD" != "true" ]]; then
        return 0
    fi

    notify_update "⏳ Preloading" "$count/$total wallpapers downloaded" "low" 0
}

# Send a preload completion toast.
# Usage: notify_preload_complete "count"
notify_preload_complete() {
    local count="$1"

    if [[ "$NOTIFY_PRELOAD" != "true" ]]; then
        return 0
    fi

    notify_update "✅ Preload Done" "$count wallpapers preloaded" "low" 3000
    NOTIFY_REPLACE_ID=0
}
