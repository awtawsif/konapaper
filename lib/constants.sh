#!/bin/bash
# =================================================================
# KONAPAPER — Constants & Default Variables
# Global variables, default values, and ANSI color definitions
# =================================================================

VERSION="1.3.0"

# API base URL (can be overridden via config file for other Moebooru instances)
BASE_URL="${BASE_URL:-https://konachan.net}"
POST_ENDPOINT="/post.json"

# --- Default Parameters ---
TAGS=""
LIMIT=50
PAGE=1
RATING="s"
ORDER="random"
MAX_FILE_SIZE="2MB"
MIN_FILE_SIZE=""
MIN_WIDTH=""
MAX_WIDTH=""
MIN_HEIGHT=""
MAX_HEIGHT=""
ASPECT_RATIO=""
MIN_SCORE=""
ARTIST=""
POOL_ID=""
PRELOAD_COUNT=3
PREFERRED_FORMAT="jpg"
ANIMATED_ONLY=false
DRY_RUN=false
CLEAN_MODE=false
FORCE_CLEAN=false
INIT_MODE=false
INIT_INTERACTIVE=false
DISCOVER_TAGS=false
DISCOVER_ARTISTS=false
LIST_POOLS=false
SEARCH_POOLS=""
EXPORT_TAGS=false

FAV_MODE=false
LIST_FAVS=false
FROM_FAVS=false

# --- Logging Variables ---
ENABLE_LOGGING=false
LOG_FILE="$HOME/.config/konapaper/konapaper.log"
LOG_LEVEL="detailed"
LOG_ROTATION=true

# --- Download Tracking ---
DOWNLOADED_IDS_FILE="$HOME/.config/konapaper/downloaded_ids"

# --- Notification Variables ---
ENABLE_NOTIFICATIONS=false
NOTIFY_TIMEOUT=5000
NOTIFY_PRELOAD=false

# --- ANSI Color Constants ---
if [[ -t 1 ]] || [[ -w /dev/tty ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_ITALIC=$'\033[3m'
    C_CYAN=$'\033[36m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_MAGENTA=$'\033[35m'
    C_BLUE=$'\033[34m'
    C_WHITE=$'\033[97m'
    C_BOLD_CYAN=$'\033[1;36m'
    C_BOLD_GREEN=$'\033[1;32m'
    C_BOLD_YELLOW=$'\033[1;33m'
    C_BOLD_RED=$'\033[1;31m'
    C_BOLD_MAGENTA=$'\033[1;35m'
    C_BOLD_WHITE=$'\033[1;97m'
    C_BG_CYAN=$'\033[46m'
else
    C_RESET="" C_BOLD="" C_DIM="" C_ITALIC=""
    C_CYAN="" C_GREEN="" C_YELLOW="" C_RED="" C_MAGENTA="" C_BLUE="" C_WHITE=""
    C_BOLD_CYAN="" C_BOLD_GREEN="" C_BOLD_YELLOW="" C_BOLD_RED=""
    C_BOLD_MAGENTA="" C_BOLD_WHITE="" C_BG_CYAN=""
fi
