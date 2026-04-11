# Konapaper

A powerful and flexible wallpaper rotator for **Linux (Wayland/X11)** and **Windows**, designed to fetch high-quality wallpapers from Moebooru-based sites like Konachan.net. On Linux, it supports multiple wallpaper tools (awww, swaybg, hyprpaper, feh, nitrogen, etc.) with automatic detection. On Windows, it uses native PowerShell and the Windows API for a seamless experience.

## Features

- **Advanced Filtering**: Search by tags, ratings (safe/questionable/explicit), minimum score, artist, and pool IDs
- **Intelligent Caching**: Preloads wallpapers in the background for instant transitions (configurable cache size per rating)
- **Random Tag Selection**: Configure a list of favorite tags and use `--random-tags` to randomly select combinations (preload cache per rating); export discovered tags to override the list
- **Discovery Modes**: Explore popular tags, artists, and pools without downloading (configurable limits)
- **Dry Run Mode**: Preview available wallpapers without downloading
- **Pool Support**: Download from curated collections of images
- **Size Limits**: Filter wallpapers by minimum and maximum file size to optimize performance
- **Logging System**: Comprehensive logging with configurable levels and automatic rotation for debugging and monitoring
- **Cross-Platform Support**: Works with both Wayland (Hyprland, Sway, etc.) and X11 display servers on Linux, and natively on Windows
- **Multi-Tool Support (Linux)**: Compatible with awww, swaybg, hyprpaper, feh, nitrogen, fbsetbg, xwallpaper
- **Native Windows Support**: No WSL or third-party tools required — uses PowerShell and Windows API
- **Auto-Detection (Linux)**: Automatically detects display server and available wallpaper tools
- **Custom Commands (Linux)**: Users can configure custom wallpaper setting commands
- **Configurable**: Extensive configuration options via config file or command-line arguments
- **Favorites System**: Save wallpapers you love to a dedicated folder and rotate from your favorites collection
- **Animated Wallpaper Support (Linux)**: Download and set animated wallpapers (GIF, WebM) with configurable format preferences
- **Interactive Initialization (Linux)**: Guided setup with color prompts for easy first-time configuration

## Prerequisites

### Linux Prerequisites
- **curl**: For API requests and downloads
- **jq**: For JSON parsing
- **xmllint**: For XML parsing (part of libxml2-utils)
- **bash**: Shell environment
- **flock**: For process locking (usually available)

### Windows Prerequisites
- **PowerShell 5.1+**: Built into Windows 10/11 (no installation required)
- **Internet connection**: For API access and wallpaper downloads

No additional tools are required on Windows — the script uses native PowerShell cmdlets and the Windows API.

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

## Windows Tutorial

This guide walks you through setting up Konapaper on Windows from scratch — no prior experience with PowerShell or command-line tools required.

### Step 1: Download Konapaper

1. Go to the [GitHub Releases page](https://github.com/awtawsif/konapaper/releases) of this repository.
2. Find the latest release with Windows support (look for the tag containing `windows`).
3. Download the **Windows zip file** (`konapaper-windows-vX.X.zip`) from the Assets section.
4. Extract the zip file to a folder of your choice, for example:
   ```
   C:\Users\YourName\konapaper\
   ```

   The extracted folder should contain these files:
   - `konapaper.ps1` — The main PowerShell script
   - `konapaper.bat` — The double-click launcher
   - `konapaper.psd1` — The configuration file
   - `README.md` — This documentation

### Step 2: Run for the First Time

1. Open the folder where you extracted Konapaper.
2. **Double-click `konapaper.bat`**.
3. A black window (Command Prompt) will appear briefly and then disappear — this is normal. The script runs, downloads a wallpaper, sets it, and exits.
4. Check your desktop — your wallpaper should have changed!

> **Note:** The first run may take a few seconds as it creates cache folders and downloads the wallpaper. Subsequent runs will be faster thanks to preloaded wallpapers.

### Step 3: Customize Your Preferences

To control what kind of wallpapers you get, edit the configuration file:

1. Right-click `konapaper.psd1` and select **Open with → Notepad** (or any text editor).
2. Change the values to your liking. Here's a recommended starter config:

   ```powershell
   @{
       # Search for scenic wallpapers
       TAGS = "landscape scenic sky"

       # Safe content only
       RATING = "s"

       # Only Full HD and above
       MIN_WIDTH = 1920
       MIN_HEIGHT = 1080

       # Max file size to avoid slow downloads
       MAX_FILE_SIZE = "5MB"

       # Preload more wallpapers for variety
       PRELOAD_COUNT = 5
       MAX_PRELOAD_CACHE = 15

       # Enable logging for troubleshooting
       ENABLE_LOGGING = $true
       LOG_LEVEL = "detailed"
   }
   ```

3. Press **Ctrl+S** to save.
4. Run `konapaper.bat` again to apply your new settings.

### Step 4: Use Tags to Find Wallpapers You Like

Konapaper searches the Konachan image board. You can combine multiple tags to narrow down results. Some popular tag combinations:

| What You Want | Tags to Use |
|---|---|
| Nature scenery | `landscape scenic` |
| Night cityscapes | `cityscape night` |
| Fantasy art | `fantasy original` |
| Ocean/beach | `ocean beach water` |
| Mountains | `mountain snow sky` |
| Space/galaxy | `space galaxy stars` |
| Anime style | `anime original` |
| Minimalist | `minimalist simple` |

To use tags, edit `konapaper.psd1` and change the `TAGS` line:
```powershell
TAGS = "mountain snow sky"
```

Or run from Command Prompt with specific tags:
```cmd
konapaper.bat --tags "mountain snow sky"
```

### Step 5: Set Up Automatic Wallpaper Changes

Instead of manually running the script, let Windows do it for you:

1. Press **Windows key** and type **Task Scheduler**, then open it.
2. In the right panel, click **Create Basic Task...**
3. Give it a name like `Konapaper Wallpaper` and click **Next**.
4. Choose how often you want wallpapers to change:
   - **Daily** — changes once per day
   - **Hourly** — changes every hour
   - Choose your preference and click **Next**.
5. Set the start time (e.g., 9:00 AM) and click **Next**.
6. Select **Start a program** and click **Next**.
7. Click **Browse...** and navigate to your `konapaper.bat` file. Select it.
   - Alternatively, paste the full path, e.g.: `C:\Users\YourName\konapaper\konapaper.bat`
8. Click **Next**, then **Finish**.

That's it! Your wallpaper will now change automatically on schedule. You can close Task Scheduler.

### Step 6: Save Wallpapers You Love

If you find a wallpaper you really like, save it to your favorites:

1. After running Konapaper, open **Command Prompt** or **PowerShell**.
2. Navigate to your Konapaper folder:
   ```cmd
   cd C:\Users\YourName\konapaper
   ```
3. Run:
   ```cmd
   konapaper.bat --fav
   ```
4. The current wallpaper is copied to your `Pictures\Wallpapers` folder.

To browse your saved favorites:
```cmd
konapaper.bat --list-favs
```

To set a random wallpaper from your favorites collection:
```cmd
konapaper.bat --from-favs
```

### Step 7: Troubleshooting

**Nothing happens when I double-click `konapaper.bat`:**
- Right-click the file and select **Edit** to open it in Notepad. Make sure the path to `konapaper.ps1` is correct.
- Try running from Command Prompt: `konapaper.bat --help`. If you see the help menu, the script is working.

**I get an "Execution Policy" error:**
- Open PowerShell as Administrator and run:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- Or always run with bypass: `powershell -ExecutionPolicy Bypass -File konapaper.ps1`

**My wallpaper isn't changing:**
- Some apps like **Wallpaper Engine** or **Lively Wallpaper** override the Windows wallpaper setting. Close them first.
- Check the log file at `%APPDATA%\konapaper\konapaper.log` for error messages.

**The downloaded wallpaper is the wrong resolution:**
- Set `MIN_WIDTH` and `MIN_HEIGHT` in `konapaper.psd1` to match your monitor's resolution.
- Use `--aspect-ratio 16:9` (or your monitor's ratio) to filter by proportions.

## Windows Support

### Installation

1. Clone or download the repository:
   ```powershell
   git clone https://github.com/awtawsif/konapaper.git
   cd konapaper
   ```

2. No additional setup required — PowerShell is built into Windows 10/11.

3. (Optional) Edit `konapaper.psd1` to customize default settings:
   ```powershell
   notepad konapaper.psd1
   ```

### Usage

#### Double-Click Launcher
Simply double-click `konapaper.bat` to fetch and set a random wallpaper. The script will:
- Query the Konachan API for a random wallpaper
- Download it to your local cache (`%LOCALAPPDATA%\konapaper`)
- Set it as your desktop wallpaper
- Preload additional wallpapers in the background for faster subsequent runs

#### Command-Line Usage
Open PowerShell or Command Prompt and run:
```powershell
# Using the batch launcher
konapaper.bat --tags "landscape sky" --rating "s"

# Or directly with PowerShell
powershell -ExecutionPolicy Bypass -File .\konapaper.ps1 --tags "landscape sky"
```

#### Command-Line Options (Windows)
Most Linux options work identically on Windows:

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
| `--aspect-ratio` | | Aspect ratio (e.g., 16:9, 21:9, 4:3) | disabled |
| `--min-score` | `-m` | Minimum score | None |
| `--artist` | `-a` | Filter by artist | None |
| `--pool` | `-P` | Pool ID | None |
| `--dry-run` | `-d` | Show results without downloading | false |
| `--discover-tags` | `-D` | Discover popular tags | false |
| `--discover-artists` | `-A` | Discover artists | false |
| `--list-pools` | `-L` | List available pools | false |
| `--search-pools` | `-S` | Search pools by name | None |
| `--random-tags` | `-R` | Number of random tags to select from config list | 0 |
| `--clean-cache` | `-cc` | Clean preload cache | false |
| `--clean-force` | `-cf` | Clean without confirmation | false |
| `--fav` | | Save current wallpaper to favorites | false |
| `--list-favs` | | List saved favorites | false |
| `--from-favs` | | Set random wallpaper from favorites | false |
| `--help` | `-h` | Show help | |

#### Examples
```powershell
# Set a random wallpaper with default settings
konapaper.bat

# Search for specific tags
konapaper.bat --tags "landscape sky"

# Use questionable rating with score filter
konapaper.bat --rating "q" --min-score 20

# Download from a specific pool
konapaper.bat --pool 1234

# Resolution filtering
konapaper.bat --min-width 1920 --min-height 1080 --aspect-ratio 16:9

# Preview without downloading
konapaper.bat --dry-run --tags "touhou" --limit 10

# Save current wallpaper to favorites
konapaper.bat --fav

# Set random wallpaper from favorites
konapaper.bat --from-favs

# Discover popular tags
konapaper.bat --discover-tags
```

#### Automation with Task Scheduler

Set up automatic wallpaper changes on a schedule:

1. Open **Task Scheduler** (search for it in the Start menu)
2. Click **Create Basic Task**
3. Set a trigger (e.g., Daily, or every 6 hours)
4. For the action, select **Start a program**
5. Browse to `konapaper.bat` or enter its full path
6. Finish the wizard

The wallpaper will now change automatically at your chosen interval — no user interaction needed.

#### Configuration (Windows)

Edit `konapaper.psd1` to customize default behavior:

```powershell
# Open the config file
notepad konapaper.psd1

# Edit values, for example:
@{
    TAGS = "landscape scenic"
    LIMIT = 100
    RATING = "s"
    MAX_FILE_SIZE = "5MB"
    MIN_WIDTH = 1920
    MIN_HEIGHT = 1080
    PREFERRED_FORMAT = "jpg"
    PRELOAD_COUNT = 5
    FAVORITES_DIR = "C:\Users\YourName\Pictures\Wallpapers"
    ENABLE_LOGGING = $true
}
```

The config file is searched for in this order:
1. `%APPDATA%\konapaper\konapaper.psd1` (user config directory)
2. The script's directory
3. The current working directory

### Windows Limitations

The following features are **not available** on Windows in the current version:

- **Animated Wallpapers**: Windows `SystemParametersInfo` API only supports static images. For animated wallpapers, consider third-party tools like Lively Wallpaper or Wallpaper Engine.
- **Notifications**: Desktop notifications require the third-party BurntToast PowerShell module.
- **Interactive Init Wizard**: The guided setup with color prompts is Linux-only.

These features may be added in future releases.

## Project Structure

Konapaper uses a modular architecture. The Linux version (`konapaper.sh`) acts as a thin orchestrator that sources focused modules from the `lib/` directory. The Windows version (`konapaper.ps1`) is a self-contained PowerShell script with all logic built-in.

### Linux Structure
```
konapaper/
├── konapaper.sh              # Main entry point (Linux orchestrator)
├── konapaper.conf            # Default configuration file (Linux)
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

### Windows Structure
```
konapaper/
├── konapaper.ps1             # Main PowerShell script (Windows)
├── konapaper.bat             # Double-click launcher (Windows)
├── konapaper.psd1            # PowerShell config data file (Windows)
└── README.md
```

Each Linux module is self-contained and responsible for a single area of functionality. All modules share global variables defined in `constants.sh` and set by `cli.sh` via the standard bash `source` mechanism.

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

- **`RANDOM_TAGS_LIST`**: Array of tags to randomly select from (e.g., `("landscape" "scenic" "sky" "clouds")`)
- **CLI Option**: `--random-tags COUNT` - Number of random tags to select (default: 0, disabled)

#### Cache and Preloading

- **`PRELOAD_COUNT`**: Number of wallpapers to preload in background (default: 3)
- **`MAX_PRELOAD_CACHE`**: Maximum wallpapers to keep in preload cache (default: 10)

#### Discovery

- **`DISCOVER_LIMIT`**: Number of items to fetch for discovery modes (default: 20)
- **`EXPORTED_TAGS_FILE`**: Path to file where discovered tags are exported (default: ~/.config/konapaper/discovered_tags.txt)

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

## Windows-Specific Usage Notes

### Dry Run Mode (Windows)
```powershell
konapaper.bat --dry-run --tags "touhou" --limit 10
```
Displays a table of matching posts with ID, score, author, dimensions, size, and tags.

### Cache Management (Windows)
```powershell
# Clean preload cache (keeps current wallpaper)
konapaper.bat --clean-cache

# Force clean without confirmation
konapaper.bat --clean-force
```
The preload cache is stored in `%LOCALAPPDATA%\konapaper\preload_<rating>\` and is limited to `MAX_PRELOAD_CACHE` wallpapers.

### Favorites (Windows)
```powershell
# Save current wallpaper to favorites
konapaper.bat --fav

# List all saved favorites
konapaper.bat --list-favs

# Set a random wallpaper from favorites
konapaper.bat --from-favs
```
The favorites directory defaults to `Pictures\Wallpapers`. You can customize this in `konapaper.psd1`:
```powershell
FAVORITES_DIR = "C:\Users\YourName\Pictures\Wallpapers"
```

### Logging (Windows)
Enable logging in `konapaper.psd1`:
```powershell
ENABLE_LOGGING = $true
LOG_LEVEL = "verbose"  # basic, detailed, or verbose
LOG_FILE = "C:\path\to\konapaper.log"
LOG_ROTATION = $true
```
Log files are stored in `%APPDATA%\konapaper\` by default and include session timestamps, API calls, file operations, and errors.

### Notifications (Windows)
Desktop notifications are **not available** in the current Windows version. This feature requires the third-party BurntToast PowerShell module and may be added in a future release.

## Examples

### Daily Wallpaper Rotation

**Linux (Cron Job):**
```bash
# Every hour, random landscape wallpaper
0 * * * * /path/to/konapaper.sh --tags "landscape scenic" --rating "s"
```

**Windows (Task Scheduler):**
Set up via Task Scheduler to run `konapaper.bat --tags "landscape scenic" --rating "s"` on a schedule (see Automation section above).

### Themed Collections

**Linux:**
```bash
# Anime-style landscapes
./konapaper.sh --tags "landscape anime" --rating "s" --min-score 15
```

**Windows:**
```powershell
konapaper.bat --tags "landscape anime" --rating "s" --min-score 15
```

```bash
# High-quality artwork (Linux)
./konapaper.sh --tags "original" --rating "s" --min-score 50 --min-file-size "500KB" --max-file-size "5MB"

# Artist-specific wallpapers (Linux)
./konapaper.sh --artist "k-eke" --rating "s"
```

```powershell
# High-quality artwork (Windows)
konapaper.bat --tags "original" --rating "s" --min-score 50 --min-file-size "500KB" --max-file-size "5MB"

# Artist-specific wallpapers (Windows)
konapaper.bat --artist "k-eke" --rating "s"
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

Alternatively, discover and export tags:

```bash
./konapaper.sh --discover-tags --export-tags
```

This saves the top tags to EXPORTED_TAGS_FILE, which overrides RANDOM_TAGS_LIST if the file exists.

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

### Common Issues (Linux)

1. **"No suitable wallpaper tool found"**: Install a supported wallpaper tool for your display server (awww/swaybg/hyprpaper for Wayland, feh/nitrogen/fbsetbg/xwallpaper for X11).

2. **"Error: No command configured for [tool]"**: Set `WALLPAPER_COMMAND` in your config file or run `./konapaper.sh --init` to auto-configure.

3. **"No suitable image found"**: Try different tags, lower the minimum score, increase the limit, or adjust file size filters.

4. **"Error: failed to reach https://konachan.net"**: Check internet connection and API availability.

5. **Large file downloads**: Adjust `MAX_FILE_SIZE` in config or use `--max-file-size` option.

6. **Permission errors**: Ensure the cache directory (`~/.cache/konapaper`) is writable.

7. **Wrong wallpaper tool being used**: Run `./konapaper.sh --init` to re-detect and configure your wallpaper tool, or manually set `WALLPAPER_COMMAND` in config.

8. **Intermittent issues**: Enable logging to track execution details and identify patterns: `ENABLE_LOGGING="true"` in config.

9. **Partial/corrupted wallpaper**: If wallpapers appear incomplete or filled with random colors when running the script quickly multiple times, this is prevented by atomic download handling. Downloads use a temporary file (`.tmp`) that is only renamed to the final file after completion, ensuring incomplete downloads are never used.

### Common Issues (Windows)

1. **"Another instance is already running"**: The script uses a mutex to prevent concurrent runs. Wait for the current run to finish or restart your computer if it's stuck.

2. **"Execution Policy" errors**: Run the script with `-ExecutionPolicy Bypass` flag or run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` in an elevated PowerShell prompt.

3. **"Invoke-RestMethod" errors**: Check your internet connection. Windows firewall or antivirus may be blocking PowerShell from accessing the internet.

4. **Permission errors**: Ensure `%LOCALAPPDATA%\konapaper` is writable. Run as Administrator if needed.

5. **Wallpaper not changing**: Some third-party wallpaper apps (Wallpaper Engine, Lively) may override the Windows wallpaper setting. Close them first or use their built-in wallpaper switching.

### Debug Mode

**Linux:**
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

**Windows:**
```powershell
# Check API response
Invoke-RestMethod -Uri "https://konachan.net/post.json?limit=1&tags=rating:s"

# Enable verbose logging (edit konapaper.psd1)
ENABLE_LOGGING = $true
LOG_LEVEL = "verbose"

# Check recent log entries
Get-Content "$env:APPDATA\konapaper\konapaper.log" -Tail 50

# Test favorites functionality
konapaper.bat --list-favs

# Clean up stale download files if needed
Remove-Item "$env:LOCALAPPDATA\konapaper\*.tmp" -Force -ErrorAction SilentlyContinue
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
