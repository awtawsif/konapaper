# Agent Guidelines for konapaper

## Build/Lint/Test Commands

### Linting
```bash
shellcheck danboorudl.sh
```

### Syntax Check
```bash
bash -n danboorudl.sh
```

### Testing
```bash
# Dry run test (shows what would be downloaded without actually downloading)
./danboorudl.sh --dry-run --tags "test"

# Run with specific parameters for testing
./danboorudl.sh --dry-run --tags "landscape" --rating "s" --limit 5
```

## Code Style Guidelines

### Shell Scripting
- Use `#!/bin/bash` shebang
- Use 4-space indentation consistently
- Use UPPERCASE for global constants and configuration variables
- Use lowercase for local variables and function parameters
- Declare local variables with `local` keyword in functions
- Use double quotes for strings containing variables: `"$variable"`
- Use single quotes for literal strings: `'literal'`
- Use `[[ ]]` for conditional expressions instead of `[ ]`
- Use proper error handling with exit codes
- Use descriptive function names with `snake_case`
- Add comments for complex logic and function purposes

### Error Handling
- Check command success with `if ! command; then`
- Use appropriate exit codes (1 for errors, 0 for success)
- Clean up temporary files with `rm -f` in error paths
- Provide meaningful error messages to stderr

### File Organization
- Group related functions together
- Use clear section headers with `--- Section Name ---`
- Separate configuration, helper functions, and main logic

### Naming Conventions
- Functions: `snake_case` (e.g., `download_wallpaper`, `set_wallpaper`)
- Variables: `UPPERCASE` for globals, `lowercase` for locals
- Constants: `UPPERCASE` with underscores
- Files: `snake_case.sh` for scripts

### Security
- Avoid storing sensitive information in scripts
- Use proper quoting to prevent injection attacks
- Validate user inputs where appropriate