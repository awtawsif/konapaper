#!/bin/bash
# =================================================================
# KONAPAPER — CLI Argument Parsing
# Parses command-line arguments and displays help text
# =================================================================

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
                echo "Usage: $0 [options]"
                echo "  -t, --tags           Tags (e.g. 'scenic sky')"
                echo "  -r, --rating         s/q/e (default: s)"
                echo "  -o, --order          random, score, date"
                echo "  -l, --limit          Number of posts to query (default: 50)"
                 echo "  -p, --page           Page number, 'random', or 'MIN-MAX' range (default: 1)"
                 echo "  -s, --max-file-size  Max file size (e.g. 500KB, 2MB; 0 to disable, default: 2MB)"
                echo "  -z, --min-file-size  Min file size (e.g. 100KB, 1MB; 0 to disable, default: disabled)"
                echo "  --min-width         Minimum width in pixels (e.g., 1920)"
                echo "  --max-width         Maximum width in pixels (e.g., 3840)"
                echo "  --min-height        Minimum height in pixels (e.g., 1080)"
                echo "  --max-height        Maximum height in pixels (e.g., 2160)"
                echo "  --aspect-ratio      Aspect ratio (e.g., 16:9, 21:9, 4:3, 1:1, 3:2, 5:4, 32:9 or custom X:Y)"
                echo "  -m, --min-score      Minimum score filter (optional)"
                echo "  -a, --artist         Filter by artist/uploader (optional)"
                echo "  -P, --pool           Use pool ID instead of tag search"
                echo "  -f, --format         Preferred format: jpg, gif, webm (default: jpg)"
                echo "  --animated-only      Ignore user tags, search animated only"
                   echo "  -cc, --clean-cache   Clean all preload_* folders (keeps current.jpg)"
                    echo "  -cf, --clean-force   Clean without confirmation"
                    echo "  -I, --init           Initialize config (interactive prompts)"
                    echo "  -d, --dry-run        Show matching results without downloading"
                   echo "  -D, --discover-tags  Discover popular tags"
                    echo "  -A, --discover-artists Discover artists"
                    echo "  -L, --list-pools     List available pools"
                    echo "  -S, --search-pools   Search pools by name"
                     echo "  -R, --random-tags    Number of random tags to select from config list"
                     echo "  -E, --export-tags    Export discovered tags to file (use with --discover-tags)"
                     echo "  --fav                Save current wallpaper to favorites"
                     echo "  --list-favs          List saved favorites"
                     echo "  --from-favs          Set random wallpaper from favorites"
                  exit 0 ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
}
