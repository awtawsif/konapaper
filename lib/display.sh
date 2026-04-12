#!/bin/bash
# =================================================================
# KONAPAPER — Display Server Detection & Wallpaper Setting
# Detects Wayland/X11 and available wallpaper tools
# =================================================================

detect_display_server() {
    local display_server="unknown"
    local wallpaper_tool=""
    
    # Method 1: Environment variables (most reliable)
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        display_server="wayland"
    elif [[ -n "$XDG_SESSION_TYPE" ]]; then
        case "$XDG_SESSION_TYPE" in
            wayland) display_server="wayland" ;;
            x11) display_server="x11" ;;
        esac
    elif [[ -n "$DISPLAY" ]]; then
        display_server="x11"
    fi
    
    # Method 2: Process detection (fallback)
    if [[ "$display_server" == "unknown" ]]; then
        if pgrep -x "Xorg" >/dev/null 2>&1 || pgrep -x "Xwayland" >/dev/null 2>&1; then
            display_server="x11"
        elif pgrep -x "sway" >/dev/null 2>&1 || pgrep -x "hyprland" >/dev/null 2>&1 || \
             pgrep -x "weston" >/dev/null 2>&1 || pgrep -x "gnome-shell" >/dev/null 2>&1; then
            display_server="wayland"
        fi
    fi
    
    # Method 3: loginctl detection (another fallback)
    if [[ "$display_server" == "unknown" ]] && command -v loginctl >/dev/null 2>&1; then
        local session_id
        session_id=$(loginctl | grep "$(whoami)" | awk '{print $1}' | head -n1)
        if [[ -n "$session_id" ]]; then
            local session_type
            session_type=$(loginctl show-session "$session_id" -p Type 2>/dev/null | cut -d'=' -f2)
            case "$session_type" in
                wayland) display_server="wayland" ;;
                x11) display_server="x11" ;;
            esac
        fi
    fi
    
    # Detect available wallpaper tools
    case "$display_server" in
        wayland)
            if command -v awww >/dev/null 2>&1; then
                wallpaper_tool="awww"
            elif command -v mpvpaper >/dev/null 2>&1; then
                wallpaper_tool="mpvpaper"
            elif command -v swaybg >/dev/null 2>&1; then
                wallpaper_tool="swaybg"
            elif command -v hyprpaper >/dev/null 2>&1; then
                wallpaper_tool="hyprpaper"
            fi
            ;;
        x11)
            if command -v feh >/dev/null 2>&1; then
                wallpaper_tool="feh"
            elif command -v mpvpaper >/dev/null 2>&1; then
                wallpaper_tool="mpvpaper"
            elif command -v nitrogen >/dev/null 2>&1; then
                wallpaper_tool="nitrogen"
            elif command -v fbsetbg >/dev/null 2>&1; then
                wallpaper_tool="fbsetbg"
            elif command -v xwallpaper >/dev/null 2>&1; then
                wallpaper_tool="xwallpaper"
            fi
            ;;
    esac
    
    echo "$display_server:$wallpaper_tool"
}

set_wallpaper() {
    local img="$1"

    # Use configured wallpaper command if specified
    if [[ -n "$WALLPAPER_COMMAND" ]]; then
        echo "Using wallpaper command..."
        # Execute via bash -c to avoid eval; {IMAGE} becomes $1
        local cmd="${WALLPAPER_COMMAND//\{IMAGE\}/\$1}"
        local display="Executing: ${WALLPAPER_COMMAND//\{IMAGE\}/\"$img\"}"
        echo "$display"
        log_write "INFO" "Using custom wallpaper command: $display"
        if bash -c "$cmd" _ "$img"; then
            log_wallpaper_set "$img" "$display"
        else
            log_error "Wallpaper command failed: $display"
            notify_error "Wallpaper Failed" "Custom command failed: $(basename "$img")"
        fi
        return $?
    fi

    # Auto-detect and use default wallpaper tool command from config
    # (cached during bootstrap; fall back to detection if not set)
    local display_server="${_DETECTED_DISPLAY_SERVER:-}"
    local wallpaper_tool="${_DETECTED_WALLPAPER_TOOL:-}"

    if [[ -z "$display_server" || -z "$wallpaper_tool" ]]; then
        local detection
        detection=$(detect_display_server)
        display_server="${detection%:*}"
        wallpaper_tool="${detection#*:}"
    fi

    echo "Detected display server: $display_server"
    echo "Using wallpaper tool: $wallpaper_tool"

    # Special handling for awww with daemon management and GIF support
    if [[ "$wallpaper_tool" == "awww" ]]; then
        set_wallpaper_awww "$img"
        return $?
    fi

    local tool_var="WALLPAPER_COMMAND_${wallpaper_tool^^}"
    local tool_cmd="${!tool_var}"

    if [[ -n "$tool_cmd" ]]; then
        echo "Using default command for $wallpaper_tool"
        # Execute via bash -c; {IMAGE} becomes $1 for safe argument passing
        local cmd="${tool_cmd//\{IMAGE\}/\$1}"
        local display="Executing: ${tool_cmd//\{IMAGE\}/\"$img\"}"
        echo "$display"
        log_write "INFO" "Using default command for $wallpaper_tool: $display"
        if bash -c "$cmd" _ "$img"; then
            log_wallpaper_set "$img" "$display"
        else
            log_error "Wallpaper command failed: $display"
            notify_error "Wallpaper Failed" "$wallpaper_tool failed to set $(basename "$img")"
        fi
        return $?
    else
        echo "Error: no command configured for $wallpaper_tool" >&2
        echo "Please set WALLPAPER_COMMAND in your config file or install a supported tool." >&2
        log_error "No command configured for $wallpaper_tool"
        notify_error "No Wallpaper Tool" "No command configured for $wallpaper_tool"
        return 1
    fi
}

set_wallpaper_awww() {
    local img="$1"
    local ext="${img##*.}"
    local attempt=0
    local max_attempts=3
    local success=false

    if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
        echo "Starting awww-daemon..."
        awww-daemon --no-fade &
        sleep 2
    fi

    if [[ "$ext" == "gif" ]]; then
        awww clear-cache
        sleep 0.5
        while [[ $attempt -lt $max_attempts ]]; do
            ((attempt++))
            echo "Setting wallpaper (GIF attempt $attempt/$max_attempts)..."
            if awww img "$img" --transition-type any --transition-fps 60 --transition-duration 1; then
                success=true
                break
            fi
            sleep 1
        done

        if [[ "$success" == "false" ]]; then
            echo "Clearing awww cache and retrying..."
            awww clear-cache
            sleep 1
            awww img "$img" --transition-type any --transition-fps 60 --transition-duration 1
        fi
    else
        while [[ $attempt -lt $max_attempts ]]; do
            ((attempt++))
            echo "Setting wallpaper (attempt $attempt/$max_attempts)..."
            if awww img "$img" --transition-type any --transition-fps 60 --transition-duration 1; then
                success=true
                break
            fi
            sleep 1
        done

        if [[ "$success" == "false" ]]; then
            log_error "awww failed to set wallpaper after $max_attempts attempts"
            notify_error "Wallpaper Failed" "awww failed: $(basename "$img")"
            return 1
        fi
    fi

    log_wallpaper_set "$img" "awww img"
    return 0
}
