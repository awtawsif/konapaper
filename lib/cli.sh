#!/bin/bash
# =================================================================
# KONAPAPER — CLI Argument Parsing
# Parses command-line arguments and displays help text
# =================================================================

display_help() {
    echo ""
    echo "${C_BOLD_CYAN}╔══════════════════════════════════════════════════════════╗${C_RESET}"
    echo "${C_BOLD_CYAN}║${C_RESET}               ${C_BOLD_MAGENTA}✦  Konapaper  —  Help Menu  ✦${C_RESET}               ${C_BOLD_CYAN}║${C_RESET}"
    echo "${C_BOLD_CYAN}╚══════════════════════════════════════════════════════════╝${C_RESET}"
    echo "${C_BOLD_WHITE}Usage:${C_RESET} ${C_CYAN}$0${C_RESET} [options]"
    echo ""

    echo "  ${C_BOLD_YELLOW}🔍  Search & Discovery${C_RESET}"
    echo "    ${C_BOLD_WHITE}-t, --tags${C_RESET} ${C_CYAN}<tags>${C_RESET}       Search tags (e.g. 'scenic sky')"
    echo "    ${C_BOLD_WHITE}-R, --random-tags${C_RESET} ${C_CYAN}<n>${C_RESET}   Select <n> random tags from config"
    echo "    ${C_BOLD_WHITE}-D, --discover-tags${C_RESET}     Discover and show popular tags"
    echo "    ${C_BOLD_WHITE}-A, --discover-artists${C_RESET}  Discover and show popular artists"
    echo "    ${C_BOLD_WHITE}-E, --export-tags${C_RESET}       Export discovered tags to file"
    echo ""

    echo "  ${C_BOLD_GREEN}🎯  Filters & Constraints${C_RESET}"
    echo "    ${C_BOLD_WHITE}-r, --rating${C_RESET} ${C_CYAN}<r>${C_RESET}      s (safe), q (questionable), e (explicit)"
    echo "    ${C_BOLD_WHITE}-o, --order${C_RESET} ${C_CYAN}<o>${C_RESET}       random, score, date"
    echo "    ${C_BOLD_WHITE}-l, --limit${C_RESET} ${C_CYAN}<n>${C_RESET}       Number of posts to fetch (default: 50)"
    echo "    ${C_BOLD_WHITE}-p, --page${C_RESET} ${C_CYAN}<p>${C_RESET}        Page number, 'random', or 'MIN-MAX' range"
    echo "    ${C_BOLD_WHITE}-s, --max-file-size${C_RESET} ${C_CYAN}<sz>${C_RESET} Max file size (e.g. 2MB, 0 to disable)"
    echo "    ${C_BOLD_WHITE}-z, --min-file-size${C_RESET} ${C_CYAN}<sz>${C_RESET} Min file size (e.g. 500KB)"
    echo "    ${C_BOLD_WHITE}-m, --min-score${C_RESET} ${C_CYAN}<n>${C_RESET}     Minimum score filter"
    echo "    ${C_BOLD_WHITE}-a, --artist${C_RESET} ${C_CYAN}<name>${C_RESET}    Filter by artist/uploader"
    echo ""

    echo "  ${C_BOLD_CYAN}📐  Resolution & Media${C_RESET}"
    echo "    ${C_BOLD_WHITE}--min-width${C_RESET} ${C_CYAN}<px>${C_RESET}       Minimum width in pixels"
    echo "    ${C_BOLD_WHITE}--max-width${C_RESET} ${C_CYAN}<px>${C_RESET}       Maximum width in pixels"
    echo "    ${C_BOLD_WHITE}--min-height${C_RESET} ${C_CYAN}<px>${C_RESET}      Minimum height in pixels"
    echo "    ${C_BOLD_WHITE}--max-height${C_RESET} ${C_CYAN}<px>${C_RESET}      Maximum height in pixels"
    echo "    ${C_BOLD_WHITE}--aspect-ratio${C_RESET} ${C_CYAN}<r>${C_RESET}   Aspect ratio (e.g. 16:9, 21:9, 4:3)"
    echo "    ${C_BOLD_WHITE}-f, --format${C_RESET} ${C_CYAN}<fmt>${C_RESET}     Preferred: jpg, gif, webm"
    echo "    ${C_BOLD_WHITE}--animated-only${C_RESET}       Search animated content only"
    echo ""

    echo "  ${C_BOLD_MAGENTA}⭐  Favorites & Pools${C_RESET}"
    echo "    ${C_BOLD_WHITE}-P, --pool${C_RESET} ${C_CYAN}<id>${C_RESET}        Use pool ID instead of tag search"
    echo "    ${C_BOLD_WHITE}-L, --list-pools${C_RESET}       List available pools"
    echo "    ${C_BOLD_WHITE}-S, --search-pools${C_RESET} ${C_CYAN}<str>${C_RESET} Search pools by name"
    echo "    ${C_BOLD_WHITE}--fav${C_RESET}                  Save current wallpaper to favorites"
    echo "    ${C_BOLD_WHITE}--list-favs${C_RESET}            List saved favorites"
    echo "    ${C_BOLD_WHITE}--from-favs${C_RESET}            Set random wallpaper from favorites"
    echo ""

    echo "  ${C_BOLD_BLUE}⚙  System & Maintenance${C_RESET}"
    echo "    ${C_BOLD_WHITE}-I, --init${C_RESET}             Run initialization wizard"
    echo "    ${C_BOLD_WHITE}-ii, --init-interactive${C_RESET} Force interactive init mode"
    echo "    ${C_BOLD_WHITE}-cc, --clean-cache${C_RESET}      Clean preload folders"
    echo "    ${C_BOLD_WHITE}-cf, --clean-force${C_RESET}      Force clean without confirmation"
    echo "    ${C_BOLD_WHITE}-d, --dry-run${C_RESET}           Show results without downloading"
    echo "    ${C_BOLD_WHITE}-h, --help${C_RESET}              Show this beautiful help menu"
    echo ""
}

parse_cli_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -t|--tags) TAGS="$2"; shift ;;
            -l|--limit) LIMIT="$2"; shift ;;
            -p|--page)
                PAGE=$(parse_page_argument "$2")
                if ! PAGE=$(parse_page_argument "$2"); then
                    exit 1
                fi
                shift ;;
            -r|--rating) RATING="$2"; shift ;;
            -o|--order) ORDER="$2"; shift ;;
             -s|--max-file-size) MAX_FILE_SIZE="$2"; shift ;;
             -z|--min-file-size) MIN_FILE_SIZE="$2"; shift ;;
             --min-width) MIN_WIDTH="$2"; shift ;;
             --max-width) MAX_WIDTH="$2"; shift ;;
             --min-height) MIN_HEIGHT="$2"; shift ;;
             --max-height) MAX_HEIGHT="$2"; shift ;;
             --aspect-ratio) ASPECT_RATIO="$2"; shift ;;
             -m|--min-score) MIN_SCORE="$2"; shift ;;
             -a|--artist) ARTIST="$2"; shift ;;
            -P|--pool) POOL_ID="$2"; shift ;;
            -f|--format) PREFERRED_FORMAT="$2"; shift ;;
            --animated-only) ANIMATED_ONLY=true ;;
            -d|--dry-run) DRY_RUN=true ;;
            -D|--discover-tags) DISCOVER_TAGS=true ;;
            -A|--discover-artists) DISCOVER_ARTISTS=true ;;
            -L|--list-pools) LIST_POOLS=true ;;
            -S|--search-pools) SEARCH_POOLS="$2"; LIST_POOLS=true; shift ;;
             -R|--random-tags) RANDOM_TAGS_COUNT="$2"; shift ;;
-E|--export-tags) EXPORT_TAGS=true ;;
              -cc|--clean-cache) CLEAN_MODE=true ;;
              -cf|--clean-force) CLEAN_MODE=true; FORCE_CLEAN=true ;;
              -I|--init) INIT_MODE=true ;;
              -ii|--init-interactive) INIT_MODE=true; INIT_INTERACTIVE=true ;;
              --fav) FAV_MODE=true ;;
              --list-favs) LIST_FAVS=true ;;
              --from-favs) FROM_FAVS=true ;;
              -h|--help)
                display_help
                exit 0 ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
}
