# Konapaper

A powerful and flexible wallpaper rotator script for both Wayland and X11 display servers, designed to fetch high-quality wallpapers from Moebooru-based sites like Konachan.net. It supports multiple wallpaper tools (awww, swaybg, hyprpaper, feh, nitrogen, etc.) with automatic detection and advanced filtering, preloading, and caching features.

## Features

- **Advanced Filtering**: Search by tags, ratings (safe/questionable/explicit), minimum score, artist, and pool IDs
- **Intelligent Caching**: Preloads wallpapers in the background for instant transitions (configurable cache size per rating)
- **Random Tag Selection**: Configure a list of favorite tags and use `--random-tags` to randomly select combinations (preload cache per rating)
- **Discovery Modes**: Explore popular tags, artists, and pools without downloading (configurable limits)
- **Dry Run Mode**: Preview available wallpapers without downloading
- **Pool Support**: Download from curated collections of images
- **Size Limits**: Filter wallpapers by minimum and maximum file size to optimize performance
- **Logging System**: Comprehensive logging with configurable levels and automatic rotation for debugging and monitoring
- **Cross-Platform Support**: Works with both Wayland (Hyprland, Sway, etc.) and X11 display servers
- **Multi-Tool Support**: Compatible with awww, swaybg, hyprpaper, feh, nitrogen, fbsetbg, xwallpaper
- **Auto-Detection**: Automatically detects display server and available wallpaper tools
- **Custom Commands**: Users can configure custom wallpaper setting commands
- **Configurable**: Extensive configuration options via config file or command-line arguments
- **Favorites System**: Save wallpapers you love to a dedicated folder and rotate from your favorites collection
- **Animated Wallpaper Support**: Download and set animated wallpapers (GIF, WebM) with configurable format preferences
- **Interactive Initialization**: Guided setup with color prompts for easy first-time configuration

## Prerequisites

### Required Tools
- **curl**: For API requests and downloads
- **jq**: For JSON parsing
- **xmllint**: For XML parsing (part of libxml2-utils)
- **bash**: Shell environment
- **flock**: For process locking (usually available)

### Wallpaper Tools (One or more required)
#### Wayland Support
- **awww**: A wallpaper daemon for Wayland compositors (recommended)
- **swaybg**: Wallpaper utility for Sway and other wlroots compositors
- **hyprpaper**: Hyprland's wallpaper utility

#### X11 Support
- **feh**: Fast and lightweight image viewer (recommended)
- **nitrogen**: Background browser and setter
- **fbsetbg**: Background setting utility for Fluxbox
- **xwallpaper**: Wallpaper utility for X11

### Display Servers
- **Wayland**: Hyprland, Sway, Westona, GNOME (Wayland)
- **X11**: Any X.Org based desktop environment

## Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/awtawsif/konapaper.git
   cd konapaper
   ```

2. Make the script executable:
   ```bash
   chmod +x konapaper.sh
   ```

3. Initialize the configuration file:
   ```bash
   ./konapaper.sh --init
   ```
   This copies the default config file to `~/.config/konapaper/konapaper.conf`.

4. Run interactively for guided setup with color prompts (recommended for first-time users):
   ```bash
   ./konapaper.sh --init-interactive
   ```
   This provides an interactive wizard that auto-detects your display server and wallpaper tools, then guides you through configuration.

5. Ensure `awww` daemon is running (the script will start it automatically if needed)

## Project Structure

Konapaper uses a modular architecture. The main script (`konapaper.sh`) acts as a thin orchestrator that sources focused modules from the `lib/` directory:

```
konapaper/
├── konapaper.sh              # Main entry point (orchestrator)
├── konapaper.conf            # Default configuration file
├── lib/
│   ├── constants.sh          # Global variables, defaults, ANSI colors
│   ├── config.sh             # Config file loading, random tag processing
│   ├── helpers.sh            # Size converters, aspect ratio & page parsers
│   ├── logging.sh            # Logging initialization, rotation, and log_* functions
│   ├── formats.sh            # Animated format detection, extension parsing
│   ├── display.sh            # Display server detection (Wayland/X11), wallpaper setting
│   ├── download.sh           # API querying, filtering, and image downloading
│   ├── cache.sh              # Preload management, cache cleanup, wallpaper selection
│   ├── discovery.sh          # Tag, artist, and pool discovery
│   ├── favorites.sh          # Save, list, and set wallpapers from favorites
│   ├── init.sh               # Interactive & non-interactive initialization wizard
│   ├── cli.sh                # CLI argument parsing and help text
│   └── notifications.sh      # Desktop notification toasts with progress updates
├── api_doc.md                # Moebooru API documentation
└── README.md
```

Each module is self-contained and responsible for a single area of functionality. All modules share global variables defined in `constants.sh` and set by `cli.sh` via the standard bash `source` mechanism.

## Configuration

Konapaper uses a configuration file (`konapaper.conf`) that allows you to set default values. The script searches for the config file in this order:

1. `~/.config/konapaper/konapaper.conf` (user config directory)
2. The script's directory
3. `./konapaper.conf` (current directory)

### Configuration Options

#### Basic Search Parameters

- **`TAGS`**: Space-separated list of tags to search for (e.g., `"touhou scenic"`)
- **`LIMIT`**: Number of posts to query (default: 50)
- **`RATING`**: Content rating filter - `"s"` (safe), `"q"` (questionable), `"e"` (explicit) (default: `"s"`)
- **`ORDER`**: Sort order - `"random"`, `"score"`, `"date"` (default: `"random"`)
- **`PAGE`**: Page number, 'random', or 'MIN-MAX' range (default: 1)

#### Animated Wallpaper Support

- **`PREFERRED_FORMAT`**: Preferred wallpaper format - `"jpg"`, `"gif"`, or `"webm"` (default: `"jpg"`)
- **`ANIMATED_ONLY`**: When true, ignores user tags and searches only for animated wallpapers (default: false)

#### Advanced Filtering

- **`MAX_FILE_SIZE`**: Maximum file size (e.g., `"500KB"`, `"2MB"`, `"1GB"`; set to `"0"` to disable) (default: `"2MB"`)
- **`MIN_FILE_SIZE`**: Minimum file size (e.g., `"100KB"`, `"1MB"`; set to `"0"` to disable) (default: disabled)
- **`MIN_WIDTH`**: Minimum width in pixels (e.g., `"1920"`) (default: disabled)
- **`MAX_WIDTH`**: Maximum width in pixels (e.g., `"3840"`) (default: disabled)
- **`MIN_HEIGHT`**: Minimum height in pixels (e.g., `"1080"`) (default: disabled)
- **`MAX_HEIGHT`**: Maximum height in pixels (e.g., `"2160"`) (default: disabled)
- **`ASPECT_RATIO`**: Filter by aspect ratio (e.g., `"16:9"`, `"21:9"`, `"4:3"`, `"1:1"`, `"3:2"`, `"5:4"`, `"32:9"` or custom `"X:Y"`) (default: disabled)
- **`MIN_SCORE`**: Minimum score threshold (optional)
- **`ARTIST`**: Filter by specific artist/uploader (optional)
- **`POOL_ID`**: Download from a specific pool ID (overrides tag search) (optional)

#### Random Tag Feature

- **`RANDOM_TAGS_LIST`**: Tags to randomly select from. Can be:
  - A bash array: `("landscape" "scenic" "sky" "clouds")` (use parentheses for tag list)
  - A file path: `"$HOME/.config/konapaper/discovered_tags.txt"` (no parentheses for file path)
- **`RANDOM_TAGS_COUNT`**: Number of random tags to select (default: 0, disabled)
- **CLI Option**: `--random-tags COUNT` - Number of random tags to select

#### Cache and Preloading

- **`PRELOAD_COUNT`**: Number of wallpapers to preload in background (default: 3)
- **`MAX_PRELOAD_CACHE`**: Maximum wallpapers to keep in preload cache (default: 10)

#### Discovery

- **`DISCOVER_LIMIT`**: Number of items to fetch for discovery modes (default: 20)

#### Notification Configuration

- **`ENABLE_NOTIFICATIONS`**: Enable desktop notification toasts using `notify-send` (default: "false")
- **`NOTIFY_TIMEOUT`**: Timeout for completion toast in milliseconds (default: 5000)
- **`NOTIFY_PRELOAD`**: Enable notifications for background preload progress (default: "false")

#### Logging Configuration

- **`ENABLE_LOGGING`**: Enable or disable logging functionality (default: "false")
- **`LOG_FILE`**: Path to the log file where execution details will be stored (default: ~/.config/konapaper/konapaper.log)
- **`LOG_LEVEL`**: Set the level of detail to log - "basic", "detailed", or "verbose" (default: "detailed")
  - **basic**: Log only major events and errors
  - **detailed**: Log major events plus configuration details
  - **verbose**: Log everything including API calls and file operations
- **`LOG_ROTATION`**: Enable automatic log rotation when logs exceed 10MB, keeping up to 5 backup files (default: "true")

#### Custom Wallpaper Commands

- **`WALLPAPER_COMMAND`**: Active wallpaper command (set by init mode or manually)
- **Tool-specific commands**: `WALLPAPER_COMMAND_AWWW`, `WALLPAPER_COMMAND_SWAYBG`, `WALLPAPER_COMMAND_FEH`, etc.
- **Placeholder**: Use `{IMAGE}` in commands - it gets replaced with the wallpaper path

**Examples:**
```bash
# Custom awww command with different transition
WALLPAPER_COMMAND="awww img {IMAGE} --transition-type fade --transition-fps 30"

# Custom feh command with different scaling
WALLPAPER_COMMAND="feh --bg-tile {IMAGE}"

# Multi-monitor setup with hyprpaper
WALLPAPER_COMMAND="hyprctl hyprpaper preload {IMAGE}; hyprctl hyprpaper wallpaper 'DP-1,{IMAGE}'"
```

#### Favorites Configuration

- **`FAVORITES_DIR`**: Directory to save favorite wallpapers (default: `$HOME/Pictures/Wallpapers`)

#### Display Server Configuration

- **`DISPLAY_SERVER`**: Auto-detected display server ("wayland" or "x11")

## Usage

### Basic Usage

```bash
# Set a random wallpaper with default settings (safe rating)
./konapaper.sh

# Search for specific tags
./konapaper.sh --tags "landscape sky"

# Use questionable rating with score filter
./konapaper.sh --rating "q" --min-score 20

# Download from a specific pool
./konapaper.sh --pool 1234

# Use animated wallpapers (GIF or WebM)
./konapaper.sh --format gif
./konapaper.sh --format webm

# Search animated wallpapers only (ignores user tags)
./konapaper.sh --animated-only
```

### Command-Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--tags` | `-t` | Space-separated tags | None |
| `--limit` | `-l` | Number of posts to query | 50 |
| `--page` | `-p` | Page number, 'random', or 'MIN-MAX' range | 1 |
| `--rating` | `-r` | Rating: s/q/e | s |
| `--order` | `-o` | Order: random/score/date | random |
| `--max-file-size` | `-s` | Max file size (e.g., 500KB, 2MB; 0 to disable) | 2MB |
| `--min-file-size` | `-z` | Min file size (e.g., 100KB, 1MB; 0 to disable) | disabled |
| `--min-width` | | Minimum width in pixels (e.g., 1920) | disabled |
| `--max-width` | | Maximum width in pixels (e.g., 3840) | disabled |
| `--min-height` | | Minimum height in pixels (e.g., 1080) | disabled |
| `--max-height` | | Maximum height in pixels (e.g., 2160) | disabled |
| `--aspect-ratio` | | Aspect ratio (e.g., 16:9, 21:9, 4:3, 1:1, 3:2, 5:4, 32:9 or custom X:Y) | disabled |
| `--min-score` | `-m` | Minimum score | None |
| `--artist` | `-a` | Filter by artist | None |
| `--pool` | `-P` | Pool ID | None |
| `--dry-run` | `-d` | Show results without downloading | false |
| `--discover-tags` | `-D` | Discover popular tags | false |
| `--discover-artists` | `-A` | Discover artists | false |
| `--list-pools` | `-L` | List available pools | false |
| `--search-pools` | `-S` | Search pools by name | None |
| `--random-tags` | `-R` | Number of random tags to select from config list | 0 |
| `--export-tags` | `-E` | Export discovered tags to file (use with --discover-tags) | false |
| `--clean-cache` | `-cc` | Clean preload cache | false |
| `--clean-force` | `-cf` | Clean without confirmation | false |
| `--fav` | | Save current wallpaper to favorites | false |
| `--list-favs` | | List saved favorites | false |
| `--from-favs` | | Set random wallpaper from favorites | false |
| `--init` | `-I` | Initialize config (interactive prompts) | false |
| `--init-interactive` | `-ii` | Non-interactive init with auto-detection | false |
| `--format` | `-f` | Preferred format: jpg/gif/webm (default: jpg) | jpg |
| `--animated-only` | | Ignore user tags, search animated only | false |
| `--help` | `-h` | Show help | |

### Discovery Modes

```bash
# Discover popular tags
./konapaper.sh --discover-tags

# Discover artists
./konapaper.sh --discover-artists

# List available pools
./konapaper.sh --list-pools

# Search pools by name
./konapaper.sh --search-pools "landscape"
```

### Dry Run Mode

Preview available wallpapers without downloading:

```bash
./konapaper.sh --dry-run --tags "touhou" --limit 10
```

This will display a table of matching posts with ID, score, author, dimensions, size, and tags.

### Cache Management

```bash
# Clean preload cache (keeps current wallpaper)
./konapaper.sh --clean-cache

# Force clean without confirmation
./konapaper.sh --clean-force
```

The preload cache uses separate folders per rating (e.g., preload_s, preload_q), each limited to MAX_PRELOAD_CACHE wallpapers. The current wallpaper is always preserved during cache cleanup.

### Favorites

Save wallpapers you love and rotate from your favorites collection:

```bash
# Save current wallpaper to favorites
./konapaper.sh --fav

# List all saved favorites
./konapaper.sh --list-favs

# Set a random wallpaper from your favorites
./konapaper.sh --from-favs
```

The favorites directory defaults to `~/Pictures/Wallpapers`. You can customize this in your config:

```bash
FAVORITES_DIR="/path/to/your/favorites"
```

### Notifications

Konapaper supports desktop notification toasts that provide real-time progress updates as wallpapers are fetched and applied. Notifications use `notify-send` (freedesktop notifications) and are disabled by default.

```bash
# Enable notifications in config file
echo 'ENABLE_NOTIFICATIONS="true"' >> ~/.config/konapaper/konapaper.conf

# Set completion toast timeout (milliseconds)
echo 'NOTIFY_TIMEOUT=5000' >> ~/.config/konapaper/konapaper.conf

# Enable preload progress notifications (optional, runs in background)
echo 'NOTIFY_PRELOAD="true"' >> ~/.config/konapaper/konapaper.conf
```

**Progress Flow:**
Notifications update in-place using a single toast that changes as the script progresses:

1. 🔍 **Querying API** — Shows tags, rating, and order being used
2. ⬇️ **Downloading** — Fetching image from Konachan
3. 🖼️ **Setting Wallpaper** — Applying via detected wallpaper tool
4. ✅ **Wallpaper Set** — Final confirmation with filename

**Additional Notifications:**
- ⭐ **Favorite Saved** — Confirms wallpaper saved to favorites
- ⏳ **Preloading** — Background preload progress (when `NOTIFY_PRELOAD=true`)
- ❌ **Errors** — API failures, download failures, no matching results, wallpaper tool failures

### Logging

Konapaper includes a comprehensive logging system for debugging and monitoring:

```bash
# Enable logging in config file
echo 'ENABLE_LOGGING="true"' >> ~/.config/konapaper/konapaper.conf

# Set different log levels
echo 'LOG_LEVEL="verbose"' >> ~/.config/konapaper/konapaper.conf  # All details
echo 'LOG_LEVEL="basic"' >> ~/.config/konapaper/konapaper.conf    # Only major events

# Custom log file location
echo 'LOG_FILE="/var/log/konapaper.log"' >> ~/.config/konapaper/konapaper.conf

# Disable log rotation (not recommended for long-term use)
echo 'LOG_ROTATION="false"' >> ~/.config/konapaper/konapaper.conf
```

**Log File Contents:**
- Session timestamps and execution details
- Command-line arguments used
- API calls and responses
- File operations and downloads
- Wallpaper setting commands and results
- Errors and warnings with context

**Log Rotation:**
- Automatically rotates logs when they exceed 10MB
- Keeps up to 5 backup files (konapaper.log.1, .2, etc.)
- Prevents disk space issues from long-running scripts

### Custom Wallpaper Commands

You can override the default wallpaper tool behavior by setting `WALLPAPER_COMMAND` in your config file:

```bash
# Example: Custom awww with different transition
WALLPAPER_COMMAND="awww img {IMAGE} --transition-type fade --transition-fps 30"

# Example: Custom feh with different scaling
WALLPAPER_COMMAND="feh --bg-center {IMAGE}"

# Example: Multi-monitor setup
WALLPAPER_COMMAND="hyprctl hyprpaper preload {IMAGE}; hyprctl hyprpaper wallpaper 'all,{IMAGE}'"
```

The `{IMAGE}` placeholder gets replaced with the actual wallpaper path. If `WALLPAPER_COMMAND` is not set, the script auto-detects and uses the appropriate tool's default command.

### Initialization

```bash
# Initialize configuration (non-interactive, auto-detects display server and wallpaper tool)
./konapaper.sh --init

# Interactive mode with guided setup and color prompts (recommended for first-time users)
./konapaper.sh --init-interactive
```

The `--init` command:
- Detects your display server (Wayland/X11)
- Finds available wallpaper tools
- Sets up the configuration file with appropriate defaults
- Configures the active wallpaper command for your detected tool

The `--init-interactive` command provides a guided wizard with:
- Color-coded prompts and feedback
- Auto-detection of your display server and wallpaper tools
- Guided configuration of options
- Non-interactive mode with auto-detection using `--init`

## Examples

### Daily Wallpaper Rotation

Set up a cron job or systemd timer to change wallpapers periodically:

```bash
# Every hour, random landscape wallpaper
0 * * * * /path/to/konapaper.sh --tags "landscape scenic" --rating "s"
```

### Themed Collections

```bash
# Anime-style landscapes
./konapaper.sh --tags "landscape anime" --rating "s" --min-score 15

# High-quality artwork
./konapaper.sh --tags "original" --rating "s" --min-score 50 --min-file-size "500KB" --max-file-size "5MB"

# Artist-specific wallpapers
./konapaper.sh --artist "k-eke" --rating "s"
```

### Resolution Filtering

```bash
# Only Full HD (1920x1080) and higher
./konapaper.sh --min-width 1920 --min-height 1080

# 16:9 aspect ratio wallpapers
./konapaper.sh --aspect-ratio 16:9

# Ultra-wide 21:9 wallpapers
./konapaper.sh --aspect-ratio 21:9

# 4K wallpapers (3840x2160 range)
./konapaper.sh --min-width 3840 --min-height 2160 --max-width 4000 --max-height 2300

# Custom aspect ratio (e.g., 16:10)
./konapaper.sh --aspect-ratio 16:10

# Combined filtering: 16:9, Full HD minimum, reasonable file size
./konapaper.sh --aspect-ratio 16:9 --min-width 1920 --min-height 1080 --min-file-size "1MB" --max-file-size "8MB"
```

### Pool Downloads

```bash
# Download from a curated pool
./konapaper.sh --pool 5678
```

### Random Tag Combinations

With the following config:

```bash
RANDOM_TAGS_LIST=("landscape" "scenic" "sky" "clouds" "water" "original" "touhou" "building")
```

Run with:

```bash
./konapaper.sh --random-tags 3
```

The script will randomly select 3 tags from the list for each run, ensuring variety. Preload cache is per rating.

To use discovered tags as the random tag list:

```bash
# First, discover and export tags to a file
./konapaper.sh --discover-tags --export-tags

# Then set RANDOM_TAGS_LIST in config to the file path:
# RANDOM_TAGS_LIST="$HOME/.config/konapaper/discovered_tags.txt"
```

### Favorites Management

```bash
# First, set a wallpaper normally
./konapaper.sh --tags "landscape"

# Save it to your favorites
./konapaper.sh --fav

# View your collection
./konapaper.sh --list-favs

# Later, rotate from your favorites
./konapaper.sh --from-favs
```

## API Documentation

Konapaper uses the Moebooru API (compatible with Danbooru v1.13.0+). The API documentation is included in `api_doc.md` and covers:

- Posts (listing, creating, updating)
- Tags (listing, updating)
- Artists (listing, creating, updating)
- Pools (listing, showing posts)
- Comments, Wiki, Notes, Users, Forum
- Authentication and error handling

For more details, refer to `api_doc.md` or the official Moebooru documentation.

## Development

### Testing

Run linting and syntax checks:

```bash
# Lint all files with shellcheck
shellcheck konapaper.sh lib/*.sh

# Syntax check all files
bash -n konapaper.sh
for f in lib/*.sh; do bash -n "$f"; done

# Dry run test
./konapaper.sh --dry-run --tags "test" --limit 1

# Test with size filters
./konapaper.sh --dry-run --min-file-size "500KB" --max-file-size "2MB" --tags "landscape" --limit 5

# Test logging functionality
ENABLE_LOGGING="true" LOG_LEVEL="detailed" ./konapaper.sh --dry-run --tags "test" --limit 1
```

### Code Style

For detailed development guidelines, see `AGENTS.md`.

Follow these guidelines for contributions:

- **Shebang**: `#!/bin/bash`
- **Indentation**: 4 spaces, no tabs
- **Variables**: `UPPERCASE` for globals/constants, `lowercase` for locals (use `local` keyword)
- **Functions**: `snake_case` naming, declare before use
- **Conditionals**: Use `[[ ]]` for tests, avoid `[ ]`
- **Strings**: `"$variable"` for expansion, `'literal'` for constants
- **Arrays**: Use indexed arrays, access with `${array[index]}`
- **Error Handling**: Check exit codes with `if ! command; then`, redirect errors to stderr
- **Security**: Quote all variables, validate inputs, use `mktemp` for temp files
- **Comments**: Add function headers, explain complex logic, use `# --- Section ---` for major sections
- **Imports**: Source config files with `source "$file"` after shellcheck disable comment

## Troubleshooting

### Common Issues

1. **"No suitable wallpaper tool found"**: Install a supported wallpaper tool for your display server (awww/swaybg/hyprpaper for Wayland, feh/nitrogen/fbsetbg/xwallpaper for X11).

2. **"Error: No command configured for [tool]"**: Set `WALLPAPER_COMMAND` in your config file or run `./konapaper.sh --init` to auto-configure.

3. **"No suitable image found"**: Try different tags, lower the minimum score, increase the limit, or adjust file size filters.

4. **"Error: failed to reach https://konachan.net"**: Check internet connection and API availability.

5. **Large file downloads**: Adjust `MAX_FILE_SIZE` in config or use `--max-file-size` option.

6. **Permission errors**: Ensure the cache directory (`~/.cache/konapaper`) is writable.

7. **Wrong wallpaper tool being used**: Run `./konapaper.sh --init` to re-detect and configure your wallpaper tool, or manually set `WALLPAPER_COMMAND` in config.

8. **Intermittent issues**: Enable logging to track execution details and identify patterns: `ENABLE_LOGGING="true"` in config.

9. **Partial/corrupted wallpaper**: If wallpapers appear incomplete or filled with random colors when running the script quickly multiple times, this is prevented by atomic download handling. Downloads use a temporary file (`.tmp`) that is only renamed to the final file after completion, ensuring incomplete downloads are never used.

### Debug Mode

For debugging, run with verbose output, enable logging, or check the API responses manually:

```bash
# Check API response
curl "https://konachan.net/post.json?limit=1&tags=rating:s"

# Enable verbose logging temporarily
ENABLE_LOGGING="true" LOG_LEVEL="verbose" ./konapaper.sh --dry-run --tags "test" --limit 1

# Check recent log entries
tail -f ~/.config/konapaper/konapaper.log

# Test favorites functionality
./konapaper.sh --list-favs

# Clean up stale download files if needed
find ~/.cache/konapaper -name "*.tmp" -delete
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes following the code style guidelines
4. Test thoroughly with dry runs and actual downloads
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Built for the Linux desktop community (Wayland and X11)
- Uses the Moebooru API (Konachan.net)
- Inspired by various wallpaper rotators and booru downloaders
- Thanks to developers of all supported wallpaper tools:
  - awww (Wayland wallpaper daemon)
  - swaybg (Sway wallpaper utility)
  - hyprpaper (Hyprland wallpaper utility)
  - feh (X11 image viewer)
  - nitrogen (X11 wallpaper setter)
  - fbsetbg (X11 wallpaper utility)
  - xwallpaper (X11 wallpaper utility)</content>
