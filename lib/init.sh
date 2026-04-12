#!/bin/bash
# =================================================================
# KONAPAPER — Init Mode
# Interactive and non-interactive initialization wizard
# =================================================================

# --- Interactive Init Helper Functions ---

print_section_header() {
    local title="$1"
    local width=50
    local pad_len=$(( (width - ${#title} - 2) / 2 ))
    local pad=""
    for (( i=0; i<pad_len; i++ )); do pad+="─"; done
    echo "" >/dev/tty
    echo "${C_BOLD_CYAN}${pad} ${title} ${pad}${C_RESET}" >/dev/tty
}

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local example="$3"
    
    local display_default
    if [[ -z "$default" ]]; then
        display_default="${C_DIM}(empty)${C_RESET}"
    else
        display_default="${C_CYAN}${default}${C_RESET}"
    fi
    
    echo -n "  ${C_BOLD_WHITE}${prompt}${C_RESET} [${display_default}]" >/dev/tty
    if [[ -n "$example" ]]; then
        echo -n " ${C_DIM}(${C_YELLOW}${example}${C_DIM})${C_RESET}" >/dev/tty
    fi
    echo "" >/dev/tty
    echo -n "  ${C_GREEN}▸${C_RESET} " >/dev/tty
    
    local input
    IFS= read -r input </dev/tty
    if [[ -z "$input" ]]; then
        echo "$default"
    else
        echo "$input"
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    
    local display_default
    case "$default" in
        true|yes|y) display_default="${C_BOLD_GREEN}Y${C_RESET}/${C_DIM}n${C_RESET}" ;;
        false|no|n|"") display_default="${C_DIM}y${C_RESET}/${C_BOLD_RED}N${C_RESET}" ;;
    esac
    
    echo -n "  ${C_BOLD_WHITE}${prompt}${C_RESET} [${display_default}]" >/dev/tty
    echo "" >/dev/tty
    echo -n "  ${C_GREEN}▸${C_RESET} " >/dev/tty
    
    local input
    read -r input </dev/tty
    
    if [[ -z "$input" ]]; then
        echo "$default"
        return
    fi
    
    case "$input" in
        y|Y|yes|Yes|YES) echo "true" ;;
        n|N|no|No|NO) echo "false" ;;
        *) echo "$default" ;;
    esac
}

prompt_tool_selection() {
    local detected="$1"
    local display_server="$2"
    
    echo "" >/dev/tty
    echo "  ${C_BOLD_WHITE}Available wallpaper tools:${C_RESET}" >/dev/tty
    echo "    ${C_CYAN}Wayland${C_RESET}${C_DIM}:${C_RESET} awww, mpvpaper, swaybg, hyprpaper" >/dev/tty
    echo "    ${C_CYAN}X11${C_RESET}${C_DIM}:${C_RESET}    feh, nitrogen, fbsetbg, xwallpaper, mpvpaper" >/dev/tty
    echo "    ${C_DIM}Or enter a custom command (use${C_RESET} ${C_YELLOW}{IMAGE}${C_RESET} ${C_DIM}as placeholder)${C_RESET}" >/dev/tty
    echo "" >/dev/tty
    
    if [[ -n "$detected" ]]; then
        echo -n "  ${C_BOLD_WHITE}Wallpaper Tool${C_RESET} [${C_CYAN}${detected}${C_RESET}]" >/dev/tty
    else
        echo -n "  ${C_BOLD_WHITE}Wallpaper Tool${C_RESET}" >/dev/tty
    fi
    echo "" >/dev/tty
    echo -n "  ${C_GREEN}▸${C_RESET} " >/dev/tty
    
    local input
    read -r input </dev/tty
    
    if [[ -z "$input" ]]; then
        echo "$detected"
    else
        echo "$input"
    fi
}

prompt_array() {
    local prompt="$1"
    shift
    local items=("$@")
    
    echo "  ${C_BOLD_WHITE}${prompt}${C_RESET} ${C_DIM}(comma-separated)${C_RESET}" >/dev/tty
    echo -n "  ${C_GREEN}▸${C_RESET} " >/dev/tty
    local input
    read -r input </dev/tty
    
    if [[ -z "$input" ]]; then
        return 1
    else
        echo "($(echo "$input" | tr ',' ' '))"
    fi
}

# --- Main Init Mode Logic ---
run_init_mode() {
    config_src="${SCRIPT_DIR}/konapaper.conf"
    config_dest="$HOME/.config/konapaper/konapaper.conf"
    if [[ ! -f "$config_src" ]]; then
        echo "${C_BOLD_RED}✗ Error:${C_RESET} Source config file not found at ${C_YELLOW}${config_src}${C_RESET}"
        exit 1
    fi

    echo ""
    echo "${C_BOLD_CYAN}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo "${C_BOLD_CYAN}║${C_RESET}        ${C_BOLD_MAGENTA}✦  Konapaper Initialization  ✦${C_RESET}        ${C_BOLD_CYAN}║${C_RESET}"
    echo "${C_BOLD_CYAN}╚══════════════════════════════════════════════════╝${C_RESET}"
    detection=$(detect_display_server)
    display_server="${detection%:*}"
    wallpaper_tool="${detection#*:}"

    mkdir -p "$HOME/.config/konapaper"

    if $INIT_INTERACTIVE; then
        echo ""
        echo "  ${C_DIM}Interactive mode detected. You'll be prompted for each setting.${C_RESET}"
        echo "  ${C_DIM}Press ${C_BOLD_WHITE}Enter${C_RESET}${C_DIM} to accept the default value shown in ${C_CYAN}[brackets]${C_RESET}${C_DIM}.${C_RESET}"

        print_section_header "🖥  Display & Wallpaper Tool"
        input=$(prompt_with_default "Display Server" "$display_server" "wayland, x11")
        display_server="${input:-$display_server}"

        input=$(prompt_tool_selection "$wallpaper_tool" "$display_server")
        walltool_input="$input"

        tool_var="WALLPAPER_COMMAND_${walltool_input^^}"
        tool_cmd=$(grep "^${tool_var}=" "$config_src" 2>/dev/null | cut -d'=' -f2- | tr -d '"')

        if [[ -z "$tool_cmd" ]]; then
            echo "" >/dev/tty
            echo "  ${C_BOLD_WHITE}Custom wallpaper command${C_RESET} ${C_DIM}(use ${C_YELLOW}{IMAGE}${C_DIM} as placeholder)${C_RESET}" >/dev/tty
            echo -n "  ${C_GREEN}▸${C_RESET} " >/dev/tty
            read -r wallpaper_command </dev/tty
        else
            wallpaper_command="$tool_cmd"
        fi

        print_section_header "🔍  Basic Search"
        input=$(prompt_with_default "Search Tags" "" "touhou scenic sky")
        tags="$input"

        input=$(prompt_with_default "Limit (posts to fetch)" "50" "100")
        limit="$input"

        input=$(prompt_with_default "Rating" "s" "s=safe, q=questionable, e=explicit")
        rating="$input"

        input=$(prompt_with_default "Order" "random" "random / score / date")
        order="$input"

        input=$(prompt_with_default "Page" "1" "1, random, 1-100")
        page="$input"

        print_section_header "⚙  Advanced Filters"
        input=$(prompt_with_default "Max File Size" "2MB" "2MB, 5MB, 0=disable")
        max_file_size="$input"

        input=$(prompt_with_default "Min File Size" "" "500KB, 0=disable")
        min_file_size="$input"

        input=$(prompt_with_default "Min Score" "" "20, 0=disable")
        min_score="$input"

        input=$(prompt_with_default "Artist filter" "" "k-eke")
        artist="$input"

        input=$(prompt_with_default "Pool ID" "" "1234")
        pool_id="$input"

        print_section_header "📐  Resolution"
        input=$(prompt_with_default "Min Width" "" "1920, 0=disable")
        min_width="$input"

        input=$(prompt_with_default "Max Width" "" "3840, 0=disable")
        max_width="$input"

        input=$(prompt_with_default "Min Height" "" "1080, 0=disable")
        min_height="$input"

        input=$(prompt_with_default "Max Height" "" "2160, 0=disable")
        max_height="$input"

        input=$(prompt_with_default "Aspect Ratio" "" "16:9, 21:9, 4:3")
        aspect_ratio="$input"

        print_section_header "🎨  Content"
        input=$(prompt_with_default "Preferred Format" "jpg" "jpg / gif / webm")
        preferred_format="$input"

        input=$(prompt_yes_no "Animated Only (ignore tags, search animated only)" "false")
        animated_only="$input"

        print_section_header "🎲  Random Tags"
        input=$(prompt_yes_no "Enable Random Tags" "false")
        enable_random_tags="$input"

        if [[ "$enable_random_tags" == "true" ]]; then
            input=$(prompt_yes_no "Discover and Export Tags from API" "false")
            discover_export_tags="$input"

            if [[ "$discover_export_tags" == "true" ]]; then
                input=$(prompt_with_default "Number of Tags to Discover" "50" "100")
                discover_count="$input"

                echo ""
                echo "  ${C_BOLD_WHITE}Discovering tags...${C_RESET}"
                EXPORTED_TAGS_FILE="$HOME/.config/konapaper/discovered_tags.txt"
                discover_tags "" count "$discover_count"

                random_tags_list="\"$HOME/.config/konapaper/discovered_tags.txt\""

                input=$(prompt_with_default "Random Tags Count" "3" "5")
                random_tags_count="$input"
            else
                input=$(prompt_with_default "Random Tags Count" "3" "5")
                random_tags_count="$input"

                echo "  ${C_BOLD_WHITE}Random Tags List${C_RESET} ${C_DIM}(comma-separated, stored as bash array)${C_RESET}"
                echo -n "  ${C_GREEN}▸${C_RESET} "
                read -r input </dev/tty
                if [[ -n "$input" ]]; then
                    random_tags_list_parsed=$(echo "$input" | tr ',' '\n' | while read -r tag; do echo "\"$tag\""; done | tr '\n' ' ')
                    random_tags_list="($random_tags_list_parsed)"
                else
                    random_tags_list="(\"landscape\" \"scenic\" \"sky\" \"clouds\" \"water\" \"original\" \"touhou\" \"building\")"
                fi
            fi
        else
            random_tags_count="0"
            random_tags_list="(\"landscape\" \"scenic\" \"sky\" \"clouds\" \"water\" \"original\" \"touhou\" \"building\")"
        fi

        print_section_header "⚡  Cache & Performance"
        input=$(prompt_with_default "Preload Count (wallpapers to pre-fetch)" "3" "5")
        preload_count="$input"

        input=$(prompt_with_default "Max Preload Cache" "10" "20")
        max_preload_cache="$input"

        print_section_header "⭐  Favorites"
        input=$(prompt_with_default "Favorites Directory" "$HOME/Pictures/Wallpapers" "/path/to/favorites")
        favorites_dir="$input"

        print_section_header "🔔  Notifications"
        input=$(prompt_yes_no "Enable Desktop Notifications (notify-send)" "false")
        enable_notifications="$input"

        if [[ "$enable_notifications" == "true" ]]; then
            input=$(prompt_with_default "Completion Toast Timeout (ms)" "5000" "3000, 5000, 8000")
            notify_timeout="$input"

            input=$(prompt_yes_no "Notify on Background Preload Progress" "false")
            notify_preload="$input"
        else
            notify_timeout="5000"
            notify_preload="false"
        fi

        print_section_header "📋  Logging"
        input=$(prompt_yes_no "Enable Logging" "false")
        enable_logging="$input"

        if [[ "$enable_logging" == "true" ]]; then
            input=$(prompt_with_default "Log File" "$HOME/.config/konapaper/konapaper.log" "/path/to/log")
            log_file="$input"

            input=$(prompt_with_default "Log Level" "detailed" "basic / detailed / verbose")
            log_level="$input"

            input=$(prompt_yes_no "Log Rotation (rotate when >10MB)" "true")
            log_rotation="$input"
        else
            log_file="$HOME/.config/konapaper/konapaper.log"
            log_level="detailed"
            log_rotation="true"
        fi

        print_section_header "💾  Writing Configuration"
        {
            echo "# Konapaper Configuration - Generated $(date)"
            echo ""
            echo "# --- Display Server ---"
            echo "DISPLAY_SERVER=\"$display_server\""
            echo ""
            echo "# --- Wallpaper Command ---"
            echo "WALLPAPER_COMMAND=\"$wallpaper_command\""
            echo ""
            echo "# --- Basic Search Parameters ---"
            [[ -n "$tags" ]] && echo "TAGS=\"$tags\""
            echo "LIMIT=$limit"
            echo "RATING=\"$rating\""
            echo "ORDER=\"$order\""
            echo "PAGE=$page"
            echo ""
            echo "# --- Advanced Filters ---"
            echo "MAX_FILE_SIZE=\"$max_file_size\""
            [[ -n "$min_file_size" ]] && echo "MIN_FILE_SIZE=\"$min_file_size\""
            [[ -n "$min_score" ]] && echo "MIN_SCORE=\"$min_score\""
            [[ -n "$artist" ]] && echo "ARTIST=\"$artist\""
            [[ -n "$pool_id" ]] && echo "POOL_ID=\"$pool_id\""
            echo ""
            echo "# --- Resolution ---"
            [[ -n "$min_width" ]] && echo "MIN_WIDTH=\"$min_width\""
            [[ -n "$max_width" ]] && echo "MAX_WIDTH=\"$max_width\""
            [[ -n "$min_height" ]] && echo "MIN_HEIGHT=\"$min_height\""
            [[ -n "$max_height" ]] && echo "MAX_HEIGHT=\"$max_height\""
            [[ -n "$aspect_ratio" ]] && echo "ASPECT_RATIO=\"$aspect_ratio\""
            echo ""
            echo "# --- Content ---"
            echo "PREFERRED_FORMAT=\"$preferred_format\""
            echo "ANIMATED_ONLY=$animated_only"
            echo ""
            echo "# --- Random Tags ---"
            echo "RANDOM_TAGS_COUNT=$random_tags_count"
            echo "RANDOM_TAGS_LIST=$random_tags_list"
            echo ""
            echo "# --- Cache & Performance ---"
            echo "PRELOAD_COUNT=$preload_count"
            echo "MAX_PRELOAD_CACHE=$max_preload_cache"
            echo ""
            echo "# --- Favorites ---"
            echo "FAVORITES_DIR=\"$favorites_dir\""
            echo ""
            echo "# --- Notifications ---"
            echo "ENABLE_NOTIFICATIONS=$enable_notifications"
            echo "NOTIFY_TIMEOUT=$notify_timeout"
            echo "NOTIFY_PRELOAD=$notify_preload"
            echo ""
            echo "# --- Logging ---"
            echo "ENABLE_LOGGING=$enable_logging"
            [[ "$enable_logging" == "true" ]] && echo "LOG_FILE=\"$log_file\""
            [[ "$enable_logging" == "true" ]] && echo "LOG_LEVEL=\"$log_level\""
            [[ "$enable_logging" == "true" ]] && echo "LOG_ROTATION=$log_rotation"
        } > "$config_dest"

        echo "  ${C_BOLD_GREEN}✓${C_RESET} Config written to ${C_CYAN}${config_dest}${C_RESET}"

    else
        echo ""
        echo "  ${C_DIM}Non-interactive mode. Using auto-detection and defaults.${C_RESET}"
        echo ""

        echo "  ${C_BOLD_WHITE}Display server:${C_RESET}  ${C_CYAN}${display_server}${C_RESET}"
        if [[ -n "$wallpaper_tool" ]]; then
            echo "  ${C_BOLD_WHITE}Wallpaper tool:${C_RESET}  ${C_GREEN}${wallpaper_tool}${C_RESET}"
            print_tool_animated_warning "$wallpaper_tool"
        else
            echo "  ${C_BOLD_YELLOW}⚠ No suitable wallpaper tool found${C_RESET}"
            echo "  ${C_DIM}Please install one for your display server:${C_RESET}"
            if [[ "$display_server" == "wayland" ]]; then
                echo "    ${C_GREEN}•${C_RESET} awww ${C_DIM}(recommended, supports GIF)${C_RESET}"
                echo "    ${C_GREEN}•${C_RESET} mpvpaper ${C_DIM}(supports GIF, WebM, MP4)${C_RESET}"
                echo "    ${C_DIM}•${C_RESET} swaybg"
                echo "    ${C_DIM}•${C_RESET} hyprpaper"
            else
                echo "    ${C_GREEN}•${C_RESET} feh ${C_DIM}(recommended)${C_RESET}"
                echo "    ${C_DIM}•${C_RESET} nitrogen"
                echo "    ${C_DIM}•${C_RESET} fbsetbg"
                echo "    ${C_DIM}•${C_RESET} xwallpaper"
                echo "    ${C_GREEN}•${C_RESET} mpvpaper ${C_DIM}(supports GIF, WebM, MP4)${C_RESET}"
            fi
        fi

        cp "$config_src" "$config_dest"

        if ! grep -q "^DISPLAY_SERVER=" "$config_dest"; then
            echo "DISPLAY_SERVER=\"$display_server\"" >> "$config_dest"
        else
            sed -i "s/^DISPLAY_SERVER=.*/DISPLAY_SERVER=\"$display_server\"/" "$config_dest"
        fi

        if [[ -n "$wallpaper_tool" ]]; then
            tool_var="WALLPAPER_COMMAND_${wallpaper_tool^^}"
            tool_cmd=$(grep "^${tool_var}=" "$config_dest" | cut -d'=' -f2- | tr -d '"')

            if [[ -n "$tool_cmd" ]]; then
                if ! grep -q "^WALLPAPER_COMMAND=" "$config_dest"; then
                    echo "WALLPAPER_COMMAND=\"$tool_cmd\"" >> "$config_dest"
                else
                    sed -i "s|^WALLPAPER_COMMAND=.*|WALLPAPER_COMMAND=\"$tool_cmd\"|" "$config_dest"
                fi
            fi
        fi

        echo ""
        echo "  ${C_BOLD_GREEN}✓${C_RESET} Config written to ${C_CYAN}${config_dest}${C_RESET}"
    fi

    echo ""
    echo "${C_BOLD_GREEN}  ✓ Configuration complete!${C_RESET}"
    echo "  ${C_DIM}Cache directory:${C_RESET} ${C_CYAN}$HOME/.cache/konapaper${C_RESET}"
    echo ""
    echo "  ${C_BOLD_WHITE}You can now run konapaper normally.${C_RESET}"
    echo ""
    exit 0
}
