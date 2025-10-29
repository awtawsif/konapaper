# Agent Guidelines for konapaper

## Build/Lint/Test Commands

- **Lint:** `shellcheck danboorudl.sh`
- **Syntax Check:** `bash -n danboorudl.sh`
- **Dry Run Test:** `./danboorudl.sh --dry-run --tags "test"`
- **Run with specific parameters for testing:** `./danboorudl.sh --dry-run --tags "landscape" --rating "s" --limit 5`

## Code Style Guidelines

- **Shebang:** `#!/bin/bash`
- **Indentation:** 4 spaces
- **Variables:** `UPPERCASE` for globals, `lowercase` for locals (declared with `local`)
- **Functions:** `snake_case`
- **Conditionals:** `[[ ]]`
- **Strings:** `"$variable"` for variables, `'literal'` for literals
- **Error Handling:** Check command success with `if ! command; then`, use exit codes, and provide meaningful error messages to stderr.
- **Security:** Use proper quoting to prevent injection attacks and validate user inputs.
