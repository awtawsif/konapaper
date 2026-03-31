#!/bin/bash

detect_display_server() {
    local display_server="unknown"
    local wallpaper_tool=""
    
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
    
    if [[ "$display_server" == "unknown" ]]; then
        if pgrep -x "Xorg" >/dev/null 2>&1 || pgrep -x "Xwayland" >/dev/null 2>&1; then
            display_server="x11"
        elif pgrep -x "sway" >/dev/null 2>&1 || pgrep -x "hyprland" >/dev/null 2>&1 || \
             pgrep -x "weston" >/dev/null 2>&1 || pgrep -x "gnome-shell" >/dev/null 2>&1; then
            display_server="wayland"
        fi
    fi
    
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
    
    detect_wallpaper_tool "$display_server"
    
    echo "$display_server:$wallpaper_tool"
}

detect_wallpaper_tool() {
    local display_server="$1"
    
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
}

set_wallpaper() {
    local img="$1"
    
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
        echo "Error: No command configured for $wallpaper_tool" >&2
        echo "Please set WALLPAPER_COMMAND in your config file or install a supported tool." >&2
        log_error "No command configured for $wallpaper_tool"
        return 1
    fi
}

init_config() {
    local config_src="$(dirname "${BASH_SOURCE[0]}")/../konapaper.conf"
    local config_dest="$HOME/.config/konapaper/konapaper.conf"
    
    if [[ ! -f "$config_src" ]]; then
        echo "Error: Source config file not found at $config_src" >&2
        return 1
    fi
    
    echo "=== Konapaper Initialization ==="
    echo "Detecting your display environment..."
    
    local detection
    detection=$(detect_display_server)
    local display_server="${detection%:*}"
    local wallpaper_tool="${detection#*:}"
    
    echo "Detected display server: $display_server"
    if [[ -n "$wallpaper_tool" ]]; then
        echo "Available wallpaper tool: $wallpaper_tool"
    else
        echo "No suitable wallpaper tool found"
        echo "Please install a wallpaper tool for your display server:"
        print_tool_installation_hints "$display_server"
    fi
    
    mkdir -p "$HOME/.config/konapaper"
    cp "$config_src" "$config_dest"
    
    if ! grep -q "^DISPLAY_SERVER=" "$config_dest"; then
        echo "DISPLAY_SERVER=\"$display_server\"" >> "$config_dest"
    else
        sed -i "s/^DISPLAY_SERVER=.*/DISPLAY_SERVER=\"$display_server\"/" "$config_dest"
    fi
    
    if [[ -n "$wallpaper_tool" ]]; then
        local tool_var="WALLPAPER_COMMAND_${wallpaper_tool^^}"
        local tool_cmd
        tool_cmd=$(grep "^${tool_var}=" "$config_dest" | cut -d'=' -f2- | tr -d '"')
        
        if [[ -n "$tool_cmd" ]]; then
            if ! grep -q "^WALLPAPER_COMMAND=" "$config_dest"; then
                echo "WALLPAPER_COMMAND=\"$tool_cmd\"" >> "$config_dest"
            else
                sed -i "s|^WALLPAPER_COMMAND=.*|WALLPAPER_COMMAND=\"$tool_cmd\"|" "$config_dest"
            fi
        fi
    fi
    
    print_init_summary "$config_dest" "$display_server" "$wallpaper_tool"
    
    return 0
}

print_tool_installation_hints() {
    local display_server="$1"
    if [[ "$display_server" == "wayland" ]]; then
        echo "  - awww (recommended)"
        echo "  - swaybg"
        echo "  - hyprpaper"
    else
        echo "  - feh (recommended)"
        echo "  - nitrogen"
        echo "  - fbsetbg"
        echo "  - xwallpaper"
    fi
}

print_init_summary() {
    local config_dest="$1"
    local display_server="$2"
    local wallpaper_tool="$3"
    
    echo ""
    echo "📋 Configuration Summary:"
    echo "  Display Server: $display_server"
    if [[ -n "$wallpaper_tool" ]]; then
        echo "  Wallpaper Tool: $wallpaper_tool"
    fi
    echo ""
    echo "🔧 Default Settings (from config file):"
    echo "  Rating: s (Safe)"
    echo "  Order: random (for variety)"
    echo "  Limit: 50 posts per query"
    echo "  Max file size: 2MB"
    echo "  Preload cache: 10 wallpapers"
    echo "  Random tags list: landscape, scenic, sky, clouds, water, original, touhou, building"
    echo ""
    echo "✅ Configuration complete!"
    echo "Config file: $config_dest"
    echo "Cache directory: $HOME/.cache/konapaper"
    echo ""
    echo "You can now run konapaper normally. Edit the config file to customize settings."
}
