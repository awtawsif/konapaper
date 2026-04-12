#!/usr/bin/env bats

load test_helper

setup_file() {
    source_lib "constants"
    # Reset globals that may have been modified
    TAGS=""
    RANDOM_TAGS_COUNT=0
}

# =============================================================================
# load_config tests
# =============================================================================

@test "load_config: sources user config when it exists" {
    # Write a test config to the user config path
    cat > "$HOME/.config/konapaper/konapaper.conf" <<'EOF'
TAGS="test_config_tags"
LIMIT=99
RATING="q"
EOF
    # Re-source constants to reset, then load config
    source_lib "config"
    load_config
    [ "$TAGS" = "test_config_tags" ]
    [ "$LIMIT" = "99" ]
    [ "$RATING" = "q" ]
}

@test "load_config: handles missing config gracefully" {
    # Ensure no user config exists
    rm -f "$HOME/.config/konapaper/konapaper.conf"
    # SCRIPT_DIR is set by main script; point to a dir with no config
    local saved_script_dir="$SCRIPT_DIR"
    SCRIPT_DIR="/tmp/nonexistent_konapaper_$$"
    mkdir -p "$SCRIPT_DIR"

    source_lib "config"
    run load_config
    [ "$status" -eq 0 ]

    SCRIPT_DIR="$saved_script_dir"
    rm -rf "$SCRIPT_DIR"
}

# =============================================================================
# process_random_tags tests
# =============================================================================

@test "process_random_tags: selects tags when RANDOM_TAGS_COUNT > 0" {
    RANDOM_TAGS_LIST=("landscape" "scenic" "sky" "clouds")
    RANDOM_TAGS_COUNT=2
    TAGS=""
    process_random_tags
    # Should have 2 space-separated tags
    local count
    count=$(echo "$TAGS" | wc -w)
    [ "$count" -eq 2 ]
}

@test "process_random_tags: appends to existing TAGS" {
    RANDOM_TAGS_LIST=("landscape" "scenic")
    RANDOM_TAGS_COUNT=1
    TAGS="touhou"
    process_random_tags
    [[ "$TAGS" == touhou* ]]
}

@test "process_random_tags: does nothing when RANDOM_TAGS_COUNT is 0" {
    RANDOM_TAGS_LIST=("landscape" "scenic")
    RANDOM_TAGS_COUNT=0
    TAGS="touhou"
    process_random_tags
    [ "$TAGS" = "touhou" ]
}

@test "process_random_tags: does nothing when RANDOM_TAGS_LIST is empty" {
    RANDOM_TAGS_LIST=()
    RANDOM_TAGS_COUNT=3
    TAGS="touhou"
    process_random_tags
    [ "$TAGS" = "touhou" ]
}

@test "process_random_tags: no leading/trailing whitespace" {
    RANDOM_TAGS_LIST=("landscape" "scenic" "sky")
    RANDOM_TAGS_COUNT=2
    TAGS=""
    process_random_tags
    # No leading space
    [[ "$TAGS" != " "* ]]
    # No trailing space
    [[ "$TAGS" != *" " ]] || [ -z "${TAGS##*[! ]}" ]
}

@test "process_random_tags: loads from file path" {
    # Write tags to a file
    local tags_file="$HOME/.config/konapaper/test_tags.txt"
    mkdir -p "$HOME/.config/konapaper"
    printf "landscape\nscenic\nsky\n" > "$tags_file"

    RANDOM_TAGS_LIST="$tags_file"
    RANDOM_TAGS_COUNT=2
    TAGS=""

    source_lib "config"
    load_config
    process_random_tags

    local count
    count=$(echo "$TAGS" | wc -w)
    [ "$count" -eq 2 ]

    rm -f "$tags_file"
}
