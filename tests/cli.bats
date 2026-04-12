#!/usr/bin/env bats

load test_helper

setup_file() {
    source_lib "constants"
    source_lib "helpers"
    source_lib "cli"
}

# =============================================================================
# parse_cli_args tests
# =============================================================================

@test "parse_cli_args: --help exits 0" {
    run parse_cli_args "--help"
    # display_help calls exit 0, so status should be 0
    [ "$status" -eq 0 ]
}

@test "parse_cli_args: --version exits 0" {
    run parse_cli_args "--version"
    [ "$status" -eq 0 ]
}

@test "parse_cli_args: --tags sets TAGS" {
    TAGS=""
    parse_cli_args --tags "landscape scenic"
    [ "$TAGS" = "landscape scenic" ]
}

@test "parse_cli_args: --tags without value fails" {
    run parse_cli_args --tags
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "parse_cli_args: --limit sets LIMIT" {
    LIMIT=50
    parse_cli_args --limit 100
    [ "$LIMIT" = "100" ]
}

@test "parse_cli_args: --limit with non-number fails" {
    run parse_cli_args --limit abc
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --limit with zero fails" {
    run parse_cli_args --limit 0
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --rating s is accepted" {
    RATING="q"
    parse_cli_args --rating s
    [ "$RATING" = "s" ]
}

@test "parse_cli_args: --rating q is accepted" {
    RATING="s"
    parse_cli_args --rating Q
    [ "$RATING" = "q" ]
}

@test "parse_cli_args: --rating e is accepted" {
    RATING="s"
    parse_cli_args --rating e
    [ "$RATING" = "e" ]
}

@test "parse_cli_args: --rating with invalid value fails" {
    run parse_cli_args --rating x
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --order random is accepted" {
    ORDER="score"
    parse_cli_args --order random
    [ "$ORDER" = "random" ]
}

@test "parse_cli_args: --order score is accepted" {
    parse_cli_args --order score
    [ "$ORDER" = "score" ]
}

@test "parse_cli_args: --order date is accepted" {
    parse_cli_args --order date
    [ "$ORDER" = "date" ]
}

@test "parse_cli_args: --order with invalid value fails" {
    run parse_cli_args --order name
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --pool with numeric ID" {
    POOL_ID=""
    parse_cli_args --pool 12345
    [ "$POOL_ID" = "12345" ]
}

@test "parse_cli_args: --pool with non-numeric fails" {
    run parse_cli_args --pool abc
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --format jpg is accepted" {
    PREFERRED_FORMAT="gif"
    parse_cli_args --format jpg
    [ "$PREFERRED_FORMAT" = "jpg" ]
}

@test "parse_cli_args: --format gif is accepted" {
    parse_cli_args --format gif
    [ "$PREFERRED_FORMAT" = "gif" ]
}

@test "parse_cli_args: --format webm is accepted" {
    parse_cli_args --format webm
    [ "$PREFERRED_FORMAT" = "webm" ]
}

@test "parse_cli_args: --format with invalid value fails" {
    run parse_cli_args --format bmp
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --dry-run sets DRY_RUN" {
    DRY_RUN=false
    parse_cli_args --dry-run
    [ "$DRY_RUN" = "true" ]
}

@test "parse_cli_args: --min-width with number" {
    MIN_WIDTH=""
    parse_cli_args --min-width 1920
    [ "$MIN_WIDTH" = "1920" ]
}

@test "parse_cli_args: --min-width with non-number fails" {
    run parse_cli_args --min-width abc
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: --aspect-ratio" {
    ASPECT_RATIO=""
    parse_cli_args --aspect-ratio "16:9"
    [ "$ASPECT_RATIO" = "16:9" ]
}

@test "parse_cli_args: --search-pools with value" {
    SEARCH_POOLS=""
    LIST_POOLS=false
    parse_cli_args --search-pools "landscape"
    [ "$SEARCH_POOLS" = "landscape" ]
    [ "$LIST_POOLS" = "true" ]
}

@test "parse_cli_args: --search-pools without value fails" {
    run parse_cli_args --search-pools
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: unknown parameter fails" {
    run parse_cli_args --unknown-flag
    [ "$status" -ne 0 ]
}

@test "parse_cli_args: short option -t works" {
    TAGS=""
    parse_cli_args -t "touhou"
    [ "$TAGS" = "touhou" ]
}

@test "parse_cli_args: short option -l works" {
    LIMIT=50
    parse_cli_args -l 25
    [ "$LIMIT" = "25" ]
}

@test "parse_cli_args: short option -r works" {
    RATING="s"
    parse_cli_args -r q
    [ "$RATING" = "q" ]
}
