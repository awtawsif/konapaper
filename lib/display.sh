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
            elif command -v swaybg >/dev/null 2>&1; then
                wallpaper_tool="swaybg"
            elif command -v hyprpaper >/dev/null 2>&1; then
                wallpaper_tool="hyprpaper"
            fi
            ;;
        x11)
            if command -v feh >/dev/null 2>&1; then
                wallpaper_tool="feh"
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
        local cmd="${WALLPAPER_COMMAND//\{IMAGE\}/\"$img\"}"
        echo "Executing: $cmd"
        log_write "INFO" "Using custom wallpaper command: $cmd"
        if eval "$cmd"; then
            log_wallpaper_set "$img" "$cmd"
        else
            log_error "Wallpaper command failed: $cmd"
        fi
        return $?
    fi
    
    # Auto-detect and use default wallpaper tool command from config
    local detection
    detection=$(detect_display_server)
    local display_server="${detection%:*}"
    local wallpaper_tool="${detection#*:}"
    
    echo "Detected display server: $display_server"
    echo "Using wallpaper tool: $wallpaper_tool"
    
    local tool_var="WALLPAPER_COMMAND_${wallpaper_tool^^}"
    local tool_cmd="${!tool_var}"
    
    if [[ -n "$tool_cmd" ]]; then
        echo "Using default command for $wallpaper_tool"
        local cmd="${tool_cmd//\{IMAGE\}/\"$img\"}"
        echo "Executing: $cmd"
        log_write "INFO" "Using default command for $wallpaper_tool: $cmd"
        if eval "$cmd"; then
            log_wallpaper_set "$img" "$cmd"
        else
            log_error "Wallpaper command failed: $cmd"
        fi
        return $?
    else
        echo "Error: No command configured for $wallpaper_tool"
        echo "Please set WALLPAPER_COMMAND in your config file or install a supported tool."
        log_error "No command configured for $wallpaper_tool"
        return 1
    fi
}
