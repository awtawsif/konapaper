# Agent Guidelines for konapaper

## Build/Lint/Test Commands
- **Lint:** `shellcheck konapaper.sh`
- **Syntax Check:** `bash -n konapaper.sh`
- **Dry Run Test:** `./konapaper.sh --dry-run --tags "test"`
- **Single Test:** `./konapaper.sh --dry-run --tags "test" --limit 1`
- **Full Test Suite:** `./konapaper.sh --dry-run --tags "landscape" --rating "s" --limit 5`

## Code Style Guidelines
- **Shebang:** `#!/bin/bash`
- **Indentation:** 4 spaces, no tabs
- **Variables:** `UPPERCASE` for globals/constants, `lowercase` for locals (use `local` keyword)
- **Functions:** `snake_case` naming, declare before use
- **Conditionals:** Use `[[ ]]` for tests, avoid `[ ]`
- **Strings:** `"$variable"` for expansion, `'literal'` for constants
- **Arrays:** Use indexed arrays, access with `${array[index]}`
- **Error Handling:** Check exit codes with `if ! command; then`, redirect errors to stderr
- **Security:** Quote all variables, validate inputs, use `mktemp` for temp files
- **Comments:** Add function headers, explain complex logic, use `# --- Section ---` for major sections
- **Imports:** Source config files with `source "$file"` after shellcheck disable comment
