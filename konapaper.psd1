# =================================================================
# KONAPAPER - PowerShell Configuration Data File
# This file is loaded by konapaper.ps1 on Windows
# =================================================================

@{
    # --- Basic Search Parameters ---
    TAGS               = ""
    LIMIT              = 100
    RATING             = "s"
    ORDER              = "random"
    PAGE               = "random"

    # --- Advanced Filters ---
    MAX_FILE_SIZE      = "30MB"
    MIN_FILE_SIZE      = "10MB"
    MIN_SCORE          = ""
    ARTIST             = ""
    POOL_ID            = ""

    # --- Resolution ---
    MIN_WIDTH          = 0
    MAX_WIDTH          = 0
    MIN_HEIGHT         = 0
    MAX_HEIGHT         = 0
    ASPECT_RATIO       = "16:9"

    # --- Content ---
    PREFERRED_FORMAT   = "jpg"
    ANIMATED_ONLY      = $false

    # --- Random Tags ---
    RANDOM_TAGS_COUNT  = 0
    RANDOM_TAGS_LIST   = @(
        "landscape", "scenic", "sky", "clouds",
        "water", "original", "touhou", "building"
    )

    # --- Cache & Performance ---
    PRELOAD_COUNT      = 3
    MAX_PRELOAD_CACHE  = 20

    # --- Discovery ---
    DISCOVER_LIMIT     = 20
    EXPORTED_TAGS_FILE = ""

    # --- Favorites ---
    FAVORITES_DIR      = ""

    # --- Logging ---
    ENABLE_LOGGING     = $false
    LOG_FILE           = ""
    LOG_LEVEL          = "detailed"
    LOG_ROTATION       = $true
}