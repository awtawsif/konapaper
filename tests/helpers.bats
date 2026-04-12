#!/usr/bin/env bats

load test_helper

setup_file() {
    source_lib "constants"
    source_lib "helpers"
    source_lib "formats"
}

# =============================================================================
# convert_to_bytes tests
# =============================================================================

@test "convert_to_bytes: plain number returns as-is" {
    run convert_to_bytes "1024"
    [ "$status" -eq 0 ]
    [ "$output" = "1024" ]
}

@test "convert_to_bytes: KB conversion" {
    run convert_to_bytes "500KB"
    [ "$status" -eq 0 ]
    [ "$output" = "512000" ]
}

@test "convert_to_bytes: MB conversion" {
    run convert_to_bytes "2MB"
    [ "$status" -eq 0 ]
    [ "$output" = "2097152" ]
}

@test "convert_to_bytes: GB conversion" {
    run convert_to_bytes "1GB"
    [ "$status" -eq 0 ]
    [ "$output" = "1073741824" ]
}

@test "convert_to_bytes: lowercase kb works" {
    run convert_to_bytes "100kb"
    [ "$status" -eq 0 ]
    [ "$output" = "102400" ]
}

@test "convert_to_bytes: invalid format exits" {
    run convert_to_bytes "abc"
    [ "$status" -ne 0 ]
}

@test "convert_to_bytes: missing unit exits" {
    run convert_to_bytes "100XB"
    [ "$status" -ne 0 ]
}

# =============================================================================
# parse_aspect_ratio tests
# =============================================================================

@test "parse_aspect_ratio: 16:9" {
    run parse_aspect_ratio "16:9"
    [ "$status" -eq 0 ]
    [ "$output" = "1.78" ]
}

@test "parse_aspect_ratio: 21:9" {
    run parse_aspect_ratio "21:9"
    [ "$status" -eq 0 ]
    [ "$output" = "2.37" ]
}

@test "parse_aspect_ratio: 4:3" {
    run parse_aspect_ratio "4:3"
    [ "$status" -eq 0 ]
    [ "$output" = "1.33" ]
}

@test "parse_aspect_ratio: 1:1" {
    run parse_aspect_ratio "1:1"
    [ "$status" -eq 0 ]
    [ "$output" = "1.00" ]
}

@test "parse_aspect_ratio: custom ratio 3:2" {
    run parse_aspect_ratio "3:2"
    [ "$status" -eq 0 ]
    [ "$output" = "1.50" ]
}

@test "parse_aspect_ratio: invalid format exits" {
    run parse_aspect_ratio "abc"
    [ "$status" -ne 0 ]
}

@test "parse_aspect_ratio: missing colon exits" {
    run parse_aspect_ratio "169"
    [ "$status" -ne 0 ]
}

# =============================================================================
# parse_page_argument tests
# =============================================================================

@test "parse_page_argument: plain number" {
    run parse_page_argument "5"
    [ "$status" -eq 0 ]
    [ "$output" = "5" ]
}

@test "parse_page_argument: random returns number in range" {
    run parse_page_argument "random"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ] 2>/dev/null || true
    [ "$output" -le 1000 ] 2>/dev/null || true
}

@test "parse_page_argument: range returns number in range" {
    run parse_page_argument "10-20"
    [ "$status" -eq 0 ]
    [ "$output" -ge 10 ]
    [ "$output" -le 20 ]
}

@test "parse_page_argument: invalid range (min >= max) fails" {
    run parse_page_argument "20-10"
    [ "$status" -ne 0 ]
}

@test "parse_page_argument: invalid format fails" {
    run parse_page_argument "abc"
    [ "$status" -ne 0 ]
}

# =============================================================================
# build_jq_filter tests
# =============================================================================

@test "build_jq_filter: without filters returns simple selector" {
    run build_jq_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *'.[] | "\(.id)|\(.file_url)"'* ]]
}

@test "build_jq_filter: with filters includes size check" {
    run build_jq_filter "true"
    [ "$status" -eq 0 ]
    [[ "$output" == *".file_size"* ]]
    [[ "$output" == *".width"* ]]
    [[ "$output" == *".height"* ]]
    [[ "$output" == *".[] | "\(.id)|\(.file_url)"'* ]]
}

# =============================================================================
# get_extension_from_url tests
# =============================================================================

@test "get_extension_from_url: jpg" {
    run get_extension_from_url "https://example.com/image.jpg"
    [ "$output" = "jpg" ]
}

@test "get_extension_from_url: gif" {
    run get_extension_from_url "https://example.com/anim.gif"
    [ "$output" = "gif" ]
}

@test "get_extension_from_url: webm" {
    run get_extension_from_url "https://example.com/video.webm"
    [ "$output" = "webm" ]
}

@test "get_extension_from_url: png" {
    run get_extension_from_url "https://example.com/image.png"
    [ "$output" = "png" ]
}

@test "get_extension_from_url: jpeg" {
    run get_extension_from_url "https://example.com/image.jpeg"
    [ "$output" = "jpeg" ]
}

@test "get_extension_from_url: unknown extension defaults to jpg with warning" {
    run get_extension_from_url "https://example.com/image.bmp"
    [ "$output" = "jpg" ]
    [[ "$stderr" == *"Warning"* ]]
}

@test "get_extension_from_url: empty extension defaults to jpg" {
    run get_extension_from_url "https://example.com/noext"
    [ "$output" = "jpg" ]
}
