#!/bin/bash
# =================================================================
# KONAPAPER — Animated Format Helpers
# Format detection, resolution, extension parsing, and warnings
# =================================================================

detect_animated_support() {
    local tool="$1"
    local animated_formats=""

    case "$tool" in
        awww)    animated_formats="gif" ;;
        mpvpaper) animated_formats="gif,webm,mp4" ;;
        swaybg)  animated_formats="" ;;
        hyprpaper) animated_formats="" ;;
        feh)     animated_formats="" ;;
        nitrogen) animated_formats="" ;;
        fbsetbg) animated_formats="" ;;
        xwallpaper) animated_formats="" ;;
    esac

    echo "$animated_formats"
}

get_extension_from_url() {
    local url="$1"
    local ext="${url##*.}"
    case "$ext" in
        jpg|jpeg|png|gif|webm) echo "$ext" ;;
        *) echo "jpg" ;;
    esac
}

get_format_filter() {
    local preferred_format="$1"

    # Only add animated for explicit gif/webm preference
    if [[ "$preferred_format" == "gif" || "$preferred_format" == "webm" ]]; then
        echo "animated"
    fi
}

resolve_format() {
    local preferred_format="$1"
    local tool="$2"

    if [[ "$preferred_format" != "auto" ]]; then
        echo "$preferred_format"
        return
    fi

    local animated_support
    animated_support=$(detect_animated_support "$tool")

    if [[ "$animated_support" == *"webm"* ]]; then
        echo "webm"
    elif [[ "$animated_support" == *"gif"* ]]; then
        echo "gif"
    else
        echo "jpg"
    fi
}

print_tool_animated_warning() {
    local tool="$1"
    local supported

    supported=$(detect_animated_support "$tool")

    if [[ -z "$supported" ]]; then
        echo "  ⚠️ Your wallpaper tool ($tool) does not support animated wallpapers"
        echo "  For animated support, consider installing:"
        echo "    - awww (GIF): https://codeberg.org/LGFae/awww"
        echo "    - mpvpaper (GIF, WebM, MP4): https://github.com/GhostNaN/mpvpaper"
    elif [[ "$supported" == "gif" ]]; then
        echo "  ℹ️ Your wallpaper tool ($tool) supports animated: $supported"
        echo "  For video (WebM/MP4) support, install: mpvpaper"
    else
        echo "  ℹ️ Your wallpaper tool ($tool) supports animated: $supported"
    fi
}
