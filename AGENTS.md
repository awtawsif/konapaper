# Agent Guidelines for konapaper

## Project Overview
Konapaper is a bash-based wallpaper rotator for Wayland and X11, fetching wallpapers from Moebooru-based sites like Konachan.net. Features include advanced filtering, intelligent caching, favorites management, and cross-platform wallpaper tool support.

## Build/Lint/Test Commands

### Essential Commands
```bash
shellcheck konapaper.sh    # Lint
bash -n konapaper.sh       # Syntax check
```

### Testing Commands
```bash
# Quick tests
./konapaper.sh --dry-run --tags "landscape" --limit 3

# Feature tests
./konapaper.sh --discover-tags --limit 10
./konapaper.sh --list-pools --limit 5
./konapaper.sh --discover-artists --limit 10

# Filter tests
./konapaper.sh --dry-run --aspect-ratio "16:9" --min-width 1920 --min-height 1080 --limit 3
./konapaper.sh --dry-run --min-file-size "500KB" --max-file-size "2MB" --tags "landscape" --limit 5

# Favorites tests
./konapaper.sh --fav                          # Save current to favorites
./konapaper.sh --list-favs                    # List favorites
./konapaper.sh --from-favs                    # Set from favorites

# Help validation
./konapaper.sh --help | grep -E "^\s+--"       # Verify all flags documented
```

### Config/Lock Tests
```bash
./konapaper.sh --init                          # Non-interactive init (auto-detects)
./konapaper.sh --init-interactive             # Interactive wizard with color prompts
echo "" | ./konapaper.sh --init                # Non-interactive init via stdin
./konapaper.sh --clean-cache                   # Cache cleanup (requires confirmation)
./konapaper.sh --clean-force                   # Force cleanup
```

### Animated Format Tests
```bash
./konapaper.sh --format gif --dry-run          # Test GIF format filtering
./konapaper.sh --format webm --dry-run         # Test WebM format filtering
./konapaper.sh --animated-only --dry-run       # Test animated-only search
```

## Code Style Guidelines

### Shell Scripting Standards
- **Shebang:** `#!/bin/bash` (line 1)
- **Indentation:** 4 spaces, no tabs
- **Line Length:** Max 120 characters
- **File Encoding:** UTF-8, Unix line endings

### Variables and Constants
- **Global:** `UPPERCASE_WITH_UNDERSCORES` (e.g., `BASE_URL`, `MAX_FILE_SIZE`)
- **Local:** `lowercase_with_underscores` (use `local` keyword)
- **Constants:** Use `readonly`
- **Expansion:** Always quote: `"$variable"`, use `${VAR:-default}` for defaults

### Functions
- **Naming:** `snake_case` (e.g., `download_wallpaper`)
- **Declaration:** Declare before use, group related functions
- **Return Values:** `return 0` success, `return 1` failure
- **Single Responsibility:** Each function does one thing well

### Control Structures
- **Conditionals:** Use `[[ ]]`, avoid `[ ]`
- **Case Statements:** For CLI argument parsing and mode selection
- **Error Handling:** Check exit codes with `if ! command; then`

### String and Array Handling
- **Strings:** `'single quotes'` for constants, `"double quotes"` for variables
- **Arrays:** Use `mapfile` for reading files, indexed arrays with `${array[index]}`
- **Path Handling:** Use `dirname` and `basename`

### Error Handling and Security
- **Exit Codes:** Always check command exit codes, return meaningful values
- **Error Messages:** Redirect to stderr (`>&2`)
- **Input Validation:** Validate all user inputs before processing
- **Temp Files:** Use `mktemp`, clean up with trap if needed
- **Security:** Quote all variables, avoid `eval` with user input

### File Operations
- **File Descriptors:** Use `exec 9>"$LOCKFILE"` for locks
- **File Testing:** Use `-f`, `-d`, `-r` tests before operations
- **Atomic Operations:** Download to `.tmp`, rename after completion
  ```bash
  curl -sfL "$URL" -o "${outfile}.tmp" && mv "${outfile}.tmp" "$outfile"
  ```
- **Directory Creation:** Use `mkdir -p`

## Architecture Patterns

### Code Organization (top to bottom)
1. Shebang and header comment
2. Global variables and constants
3. Config file loading
4. Helper functions (converters, parsers)
5. Logging functions
6. CLI argument parsing
7. Mode-specific functions (discovery, favorites, etc.)
8. Main execution logic

### Configuration Priority
1. User config: `~/.config/konapaper/konapaper.conf`
2. Script directory: `$(dirname "$0")/konapaper.conf`
3. Current directory: `./konapaper.conf`

### API Integration
- **URL Building:** Encode parameters, use HTTPS only
- **JSON Parsing:** Use `jq`, validate responses
- **HTTP Requests:** `curl -sf` with proper error handling
- **Response Validation:** Check structure before processing

### Process Management
- **Locking:** Use `flock` to prevent concurrent execution
- **Background Jobs:** Use `&` and `wait` for preloading
- **Daemon Check:** Verify awww daemon is running if needed

## Dependencies

### Required Tools
`curl`, `jq`, `xmllint`, `flock`, `shuf`, `awk`, `stat`, `find`

### Wallpaper Tools
- **Wayland:** `awww` (recommended), `swaybg`, `hyprpaper`
- **X11:** `feh` (recommended), `nitrogen`, `fbsetbg`, `xwallpaper`

## Development Workflow

### Before Making Changes
1. Run `shellcheck` and `bash -n` to verify clean state
2. Test current functionality before modifications
3. Plan changes considering all supported platforms

### After Making Changes
1. Run linting: `shellcheck konapaper.sh && bash -n konapaper.sh`
2. Test with `--dry-run` to verify behavior
3. Update `--help` text if adding new flags
4. Update `README.md` and `konapaper.conf` if adding config options

## Special Considerations

### Race Condition Prevention
Downloads use atomic rename pattern to prevent incomplete wallpapers:
```bash
tmpfile="${outfile}.tmp"
curl -sfL "$IMAGE_URL" -o "$tmpfile" && mv "$tmpfile" "$outfile"
```
Only `.jpg` files are selected; `.tmp` files are automatically skipped.

### Favorites System
- Directory: `FAVORITES_DIR` (default: `~/Pictures/Wallpapers`)
- Filename format: `wallpaper_YYYY-MM-DD_HHMMSS.jpg`
- No metadata storage—simple file-based management

### CLI Flag Conventions
- Short flags: single letter options (e.g., `-t`, `-l`)
- Long flags: `--verbose-name` format
- Boolean flags: `FLAG_NAME=true` in code, no value on CLI
- Value flags: `--flag value` pattern, shift in case statement
- Special cases: `-ii` for `--init-interactive`, `-cc`/`-cf` for cache cleanup
