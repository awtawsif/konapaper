#!/usr/bin/env bats

# Test helper — sets up a clean environment for each test
# Usage: source this file at the top of test files

# Project root (parent of tests/)
PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"

# Create a temporary config directory for tests
setup() {
    TEST_TMPDIR=$(mktemp -d)
    export HOME="$TEST_TMPDIR"
    mkdir -p "$HOME/.config/konapaper"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

# Source a single library file with its dependencies
source_lib() {
    local lib_name="$1"
    # shellcheck source=/dev/null
    source "$LIB_DIR/$lib_name.sh"
}
