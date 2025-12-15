# Agent Guidelines for konapaper

## Build/Lint/Test Commands
- **Lint:** `shellcheck konapaper.sh`
- **Syntax:** `bash -n konapaper.sh`
- **Single Test:** `./konapaper.sh --dry-run --tags "test" --limit 1`
- **Full Test:** `./konapaper.sh --dry-run --tags "landscape" --rating "s" --limit 5`
- **Size Test:** `./konapaper.sh --dry-run --min-file-size "500KB" --max-file-size "2MB" --tags "landscape" --limit 5`

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
- **File Descriptors:** Use exec redirection for locks (e.g., `exec 9>"$LOCKFILE"`)
