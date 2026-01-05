# Agent Guidelines for konapaper

## Project Overview
Konapaper is a bash-based wallpaper rotator for both Wayland and X11 display servers, designed to fetch high-quality wallpapers from Moebooru-based sites like Konachan.net. It features cross-platform support, advanced filtering, intelligent caching, and automatic wallpaper tool detection with customizable commands.

## Build/Lint/Test Commands

### Essential Commands
- **Lint:** `shellcheck konapaper.sh`
- **Syntax:** `bash -n konapaper.sh`

### Testing Commands
- **Single Test (Quick):** `./konapaper.sh --dry-run --tags "test" --limit 1`
- **Single Test (Realistic):** `./konapaper.sh --dry-run --tags "landscape" --limit 3`
- **Full Feature Test:** `./konapaper.sh --dry-run --tags "landscape" --rating "s" --limit 5`
- **Size Filtering Test:** `./konapaper.sh --dry-run --min-file-size "500KB" --max-file-size "2MB" --tags "landscape" --limit 5`
- **Resolution Test:** `./konapaper.sh --dry-run --aspect-ratio "16:9" --min-width "1920" --min-height "1080" --limit 3`
- **Discovery Test:** `./konapaper.sh --discover-tags --limit 10`
- **Pool Test:** `./konapaper.sh --list-pools --limit 5`

### Configuration Test
- **Init Mode Test:** `./konapaper.sh --init` (interactive)
- **Non-interactive Init:** `echo "3" | ./konapaper.sh --init`

### Wallpaper Tool Tests
- **Auto-detection Test:** Check that appropriate tool command is selected
- **Custom Command Test:** Set `WALLPAPER_COMMAND="echo 'Test: {IMAGE}'"` in config
- **Cross-platform Test:** Test on both Wayland and X11 environments

## Code Style Guidelines

### Shell Scripting Standards
- **Shebang:** `#!/bin/bash` (always at line 1)
- **Indentation:** 4 spaces, no tabs (strict enforcement)
- **Line Length:** Maximum 120 characters for readability
- **File Encoding:** UTF-8, Unix line endings

### Variables and Constants
- **Global Variables:** `UPPERCASE_WITH_UNDERSCORES` (e.g., `BASE_URL`, `MAX_FILE_SIZE`)
- **Local Variables:** `lowercase_with_underscores` (declare with `local` keyword)
- **Constants:** Use `readonly` for immutable values
- **Arrays:** Indexed arrays with `declare -a`, access with `${array[index]}`
- **Variable Expansion:** Always quote variables: `"$variable"` not `$variable`
- **Parameter Expansion:** Use `${VAR:-default}` for defaults, `${variable#pattern}` for string manipulation

### Functions
- **Naming:** `snake_case` (e.g., `download_wallpaper`, `parse_aspect_ratio`)
- **Declaration:** Declare functions before use, group related functions
- **Headers:** Add descriptive comments for complex functions
- **Return Values:** Use `return 0` for success, `return 1` for failure
- **Parameters:** Use `$1`, `$2`, etc., validate inputs before use
- **Single Responsibility:** Each function should do one thing well

### Control Structures
- **Conditionals:** Use `[[ ]]` for tests, avoid `[ ]` (legacy)
- **Loops:** Prefer `for` loops over `while` when possible
- **Case Statements:** Use for parsing command-line arguments and mode selection
- **Error Handling:** Check exit codes with `if ! command; then` and handle failures gracefully

### String and Array Handling
- **String Literals:** `'single quotes'` for constants, `"double quotes"` for variables
- **String Operations:** Use bash parameter expansion (`${variable#pattern}`, `${variable%pattern}`)
- **Arrays:** Use `mapfile` for reading files into arrays
- **Path Handling:** Use `dirname` and `basename` for path manipulation

### Error Handling and Security
- **Exit Codes:** Always check command exit codes, return meaningful values
- **Error Messages:** Redirect to stderr (`>&2`) with descriptive messages
- **Input Validation:** Validate all user inputs and parameters before processing
- **Temp Files:** Use `mktemp` for temporary files, clean up properly with trap if needed
- **Security:** Quote all variables, avoid eval with user input, use safe parsing
- **Resource Cleanup:** Always clean up temporary files and background processes

### File Operations
- **File Descriptors:** Use exec redirection for locks (`exec 9>"$LOCKFILE"`)
- **File Testing:** Use `-f`, `-d`, `-r` tests before file operations
- **Permissions:** Ensure proper file permissions for cache/config directories
- **Atomic Operations:** Use temp files and mv for atomic writes when needed
- **Directory Creation:** Use `mkdir -p` for recursive directory creation

### Configuration Management
- **Config Loading:** Source with `source "$file"` after shellcheck disable comment
- **Priority Order:** User config > script directory > current directory
- **Default Values:** Use parameter expansion (`${VAR:-default}`) for fallbacks
- **Environment Variables:** Support environment variable overrides where appropriate
- **Template System:** Use placeholder replacement for configurable commands (e.g., `{IMAGE}`)

### API Integration
- **URL Building:** Encode parameters properly, use HTTPS only
- **JSON Parsing:** Use `jq` for JSON processing, validate responses before use
- **XML Parsing:** Use `xmllint` for XML, handle namespaces properly
- **HTTP Requests:** Use `curl` with proper error handling (`-sf` flags)
- **Rate Limiting:** Implement appropriate delays between API calls
- **Response Validation:** Check API response structure before processing

### Process Management
- **Background Jobs:** Use `&` for background processes like preloading
- **Process Synchronization:** Use `wait` to synchronize background jobs
- **Process Locking:** Use `flock` to prevent concurrent execution of the same script
- **Daemon Management:** Check and start required daemons (swww-daemon) if not running
- **Signal Handling:** Trap signals for cleanup if needed (though not currently implemented)

### Performance Considerations
- **Caching Strategy:** Implement intelligent caching for API responses and images
- **Preloading:** Use background processes for preloading wallpapers
- **Memory Management:** Clean up temporary files and unset variables when done
- **Network Efficiency:** Minimize API calls, use appropriate limits and filters
- **Atomic Operations:** Minimize system calls, batch operations where possible

### Dependencies and External Tools
- **Required Tools:** `curl`, `jq`, `xmllint`, `flock`, `shuf`, `awk`, `stat`, `find`
- **Wallpaper Tools (Wayland):** `swww` (recommended), `swaybg`, `hyprpaper`
- **Wallpaper Tools (X11):** `feh` (recommended), `nitrogen`, `fbsetbg`, `xwallpaper`
- **System Tools:** `pgrep`, `loginctl`, `bash`, `mktemp`
- **Error Checking:** Verify tool availability before use, provide helpful installation guidance

### Comments and Documentation
- **Function Headers:** Describe purpose, parameters, and return values for complex functions
- **Section Comments:** Use `# --- Section Name ---` for major code blocks
- **Inline Comments:** Explain complex logic, business rules, and non-obvious operations
- **TODO Comments:** Mark future improvements with `# TODO:` for easy tracking
- **Configuration Comments:** Explain what each configuration option does and acceptable values

### Code Organization
- **Structure:** Group related functionality (helpers, parsers, main logic, API functions)
- **Constants:** Define all constants and global variables at the beginning of the script
- **Imports:** Source external files at the top with proper error handling
- **Main Logic:** Keep main execution flow clean and readable
- **Modularity:** Write reusable functions with clear interfaces

### Testing and Validation
- **Dry Run Mode:** Implement `--dry-run` for testing without side effects
- **Parameter Validation:** Validate all command-line arguments with meaningful error messages
- **API Testing:** Test API endpoints and handle failures gracefully
- **Cache Testing:** Verify cache directory creation and permissions
- **Cross-Platform Testing:** Test on both Wayland and X11 environments
- **Edge Cases:** Handle empty responses, network failures, permission errors

## Architecture Patterns

### Modular Design
- **Configuration Layer:** Priority-based loading with environment support
- **Helper Functions:** Reusable utilities for common operations
- **API Layer:** Centralized API interaction with error handling
- **Service Layer:** Wallpaper tool detection and command execution
- **Cache Layer:** Intelligent caching with size management

### Error Recovery
- **Graceful Degradation:** Fallback mechanisms for tool detection
- **User Guidance:** Provide clear error messages and installation instructions
- **Resource Management:** Always clean up resources, even on failure
- **Lock Management:** Prevent concurrent execution conflicts

### Cross-Platform Support
- **Display Server Detection:** Multiple methods for reliable detection
- **Tool Agnostic:** Template-based command system for any wallpaper tool
- **Auto-Configuration:** Initialize with appropriate settings automatically

## Development Workflow

### Before Making Changes
1. **Run Tests:** Execute all test commands to ensure current state is working
2. **Read AGENTS.md:** Review these guidelines before coding
3. **Plan Changes:** Consider impact on all supported platforms and tools

### Making Changes
1. **Follow Style:** Adhere to all style guidelines in this document
2. **Test Incrementally:** Test each change with the test commands
3. **Update Documentation:** Update README.md and help text if needed

### After Making Changes
1. **Run Full Test Suite:** Execute all test commands
2. **Lint and Syntax Check:** Run shellcheck and bash -n
3. **Test Cross-Platform:** Verify on both Wayland and X11 if possible
4. **Update Configuration:** Update config file template if adding new options

## Special Considerations

### Security
- **No Eval with User Input:** Never use eval with unchecked user input
- **Path Sanitization:** Validate all file paths before use
- **Network Security:** Use HTTPS only, validate SSL certificates

### Performance
- **Background Processing:** Use for long-running operations like downloads
- **Caching Strategy:** Balance between speed and disk usage
- **API Efficiency:** Filter client-side rather than downloading large responses

### User Experience
- **Helpful Errors:** Provide actionable error messages with suggested solutions
- **Auto-Detection:** Make initialization as seamless as possible
- **Clear Documentation:** Explain all options with practical examples