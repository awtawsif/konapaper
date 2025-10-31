# Konapaper

A powerful and flexible wallpaper rotator script for Hyprland, designed to fetch high-quality wallpapers from Moebooru-based sites like Konachan.net. It integrates seamlessly with the `swww` wallpaper daemon for smooth transitions and supports advanced filtering, preloading, and caching features.

## Features

- **Advanced Filtering**: Search by tags, ratings (safe/questionable/explicit), minimum score, artist, and pool IDs
- **Intelligent Caching**: Preloads wallpapers in the background for instant transitions (configurable cache size per rating)
- **Random Tag Selection**: Configure a list of favorite tags and use `--random-tags` to randomly select combinations (preload cache per rating); export discovered tags to override the list
- **Discovery Modes**: Explore popular tags, artists, and pools without downloading (configurable limits)
- **Dry Run Mode**: Preview available wallpapers without downloading
- **Pool Support**: Download from curated collections of images
- **Size Limits**: Filter wallpapers by minimum and maximum file size to optimize performance
- **Hyprland Integration**: Native support for Hyprland's `swww` wallpaper daemon
- **Configurable**: Extensive configuration options via config file or command-line arguments

## Prerequisites

- **Hyprland**: A dynamic tiling Wayland compositor
- **swww**: A wallpaper daemon for Wayland compositors (install via your package manager)
- **curl**: For API requests and downloads
- **jq**: For JSON parsing
- **xmllint**: For XML parsing (part of libxml2-utils)
- **bash**: Shell environment
- **flock**: For process locking (usually available)

## Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/yourusername/konapaper.git
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

4. Ensure `swww` daemon is running (the script will start it automatically if needed)

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

#### Advanced Filtering

- **`MAX_FILE_SIZE`**: Maximum file size (e.g., `"500KB"`, `"2MB"`, `"1GB"`; set to `"0"` to disable) (default: `"2MB"`)
- **`MIN_FILE_SIZE`**: Minimum file size (e.g., `"100KB"`, `"1MB"`; set to `"0"` to disable) (default: disabled)
- **`MIN_SCORE`**: Minimum score threshold (optional)
- **`ARTIST`**: Filter by specific artist/uploader (optional)
- **`POOL_ID`**: Download from a specific pool ID (overrides tag search) (optional)

#### Random Tag Feature

- **`RANDOM_TAGS_LIST`**: Array of tags to randomly select from (e.g., `("landscape" "scenic" "sky" "clouds")`)
- **CLI Option**: `--random-tags COUNT` - Number of random tags to select (default: 0, disabled)

#### Cache and Preloading

- **`PRELOAD_COUNT`**: Number of wallpapers to preload in background (default: 3)
- **`MAX_PRELOAD_CACHE`**: Maximum wallpapers to keep in preload cache (default: 10)

#### Discovery

- **`DISCOVER_LIMIT`**: Number of items to fetch for discovery modes (default: 20)
- **`EXPORTED_TAGS_FILE`**: Path to file where discovered tags are exported (default: ~/.config/konapaper/discovered_tags.txt)

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
| `--init` | `-I` | Copy config file to user config directory | false |
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

The preload cache uses separate folders per rating (e.g., preload_s, preload_q), each limited to MAX_PRELOAD_CACHE wallpapers.

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

Alternatively, discover and export tags:

```bash
./konapaper.sh --discover-tags --export-tags
```

This saves the top tags to EXPORTED_TAGS_FILE, which overrides RANDOM_TAGS_LIST if the file exists.

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
# Lint with shellcheck
shellcheck konapaper.sh

# Syntax check
bash -n konapaper.sh

# Dry run test
./konapaper.sh --dry-run --tags "test" --limit 1

# Test with size filters
./konapaper.sh --dry-run --min-file-size "500KB" --max-file-size "2MB" --tags "landscape" --limit 5
```

### Code Style

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

1. **"swww-daemon not running"**: Ensure `swww` is installed and the script can start the daemon.

2. **"No suitable image found"**: Try different tags, lower the minimum score, or increase the limit.

3. **"Error: failed to reach konachan.net"**: Check internet connection and API availability.

4. **Large file downloads**: Adjust `MAX_FILE_SIZE` in config or use `--max-file-size` option.

5. **Permission errors**: Ensure the cache directory (`~/.cache/hypr_wallpapers`) is writable.

### Debug Mode

For debugging, run with verbose output or check the API responses manually:

```bash
# Check API response
curl "https://konachan.net/post.json?limit=1&tags=rating:s"
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

- Built for the Hyprland community
- Uses the Moebooru API (Konachan.net)
- Inspired by various wallpaper rotators and booru downloaders
- Thanks to the swww developers for the wallpaper daemon</content>
