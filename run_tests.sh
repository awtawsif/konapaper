#!/bin/bash
# Test runner for Konapaper
# Runs all bats tests or selected test files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# Check if bats is available
if ! command -v bats &>/dev/null; then
    echo "Error: bats (bats-core) is required to run tests." >&2
    echo "Install it with: brew install bats-core  (macOS)" >&2
    echo "  or:  npm install -g bats             (any platform)" >&2
    exit 1
fi

# Run all tests or specific files
if [[ "$#" -gt 0 ]]; then
    TEST_FILES=("$@")
else
    TEST_FILES=("$TESTS_DIR"/*.bats)
fi

echo "Running Konapaper tests..."
echo ""

# Run with pretty output
bats --print-output-on-failure "${TEST_FILES[@]}"
