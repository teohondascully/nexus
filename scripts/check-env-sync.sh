#!/usr/bin/env bash
# check-env-sync.sh
# Warns when env vars referenced in code are not declared in .env.example.

set -euo pipefail

ENV_EXAMPLE="${1:-.env.example}"

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  echo "check-env-sync: $ENV_EXAMPLE not found, skipping." >&2
  exit 0
fi

# Read declared var names from .env.example (skip comments and blank lines)
declared=()
while IFS= read -r line; do
  # Skip blank lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue
  varname="${line%%=*}"
  [[ -n "$varname" ]] && declared+=("$varname")
done < "$ENV_EXAMPLE"

# Detect env var pattern based on ecosystem
if [ -f "package.json" ]; then
  PATTERN='(process\.env|Bun\.env)\.[A-Z_][A-Z0-9_]*'
  STRIP='s/(process\.env|Bun\.env)\.//'
  INCLUDES='--include=*.ts --include=*.tsx --include=*.js --include=*.jsx'
elif [ -f "go.mod" ]; then
  PATTERN='os\.Getenv\("[A-Z_][A-Z0-9_]*"\)'
  STRIP='s/os\.Getenv\("//;s/"\)//'
  INCLUDES='--include=*.go'
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  PATTERN='os\.environ\[?"[A-Z_][A-Z0-9_]*"\]?|os\.getenv\("[A-Z_][A-Z0-9_]*"\)'
  STRIP='s/os\.environ\[?"//;s/"\]?//;s/os\.getenv\("//;s/"\)//'
  INCLUDES='--include=*.py'
elif [ -f "Cargo.toml" ]; then
  PATTERN='std::env::var\("[A-Z_][A-Z0-9_]*"\)'
  STRIP='s/std::env::var\("//;s/"\)//'
  INCLUDES='--include=*.rs'
else
  # No ecosystem detected, nothing to check
  exit 0
fi

# Grep for env var references in source files
used_raw=$(
  eval grep -rEh $INCLUDES \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    --exclude-dir=dist \
    --exclude-dir=target \
    --exclude-dir=__pycache__ \
    --exclude-dir=.venv \
    --exclude-dir=vendor \
    "'$PATTERN'" \
    . 2>/dev/null || true
)

# Extract just the variable names
used_vars=$(
  printf '%s\n' "$used_raw" \
  | grep -oE "$PATTERN" \
  | sed -E "$STRIP" \
  | sort -u \
  || true
)

if [[ -z "$used_vars" ]]; then
  echo "check-env-sync: no env vars referenced in source files."
  exit 0
fi

# Find missing vars (used in code but not declared in .env.example)
missing=()
while IFS= read -r var; do
  [[ -z "$var" ]] && continue
  found=0
  for d in "${declared[@]}"; do
    [[ "$d" == "$var" ]] && found=1 && break
  done
  [[ "$found" -eq 0 ]] && missing+=("$var")
done <<< "$used_vars"

if [[ "${#missing[@]}" -eq 0 ]]; then
  echo "check-env-sync: all env vars are declared in $ENV_EXAMPLE."
  exit 0
fi

echo "check-env-sync: the following env vars are used in code but missing from $ENV_EXAMPLE:" >&2
for v in "${missing[@]}"; do
  echo "  - $v" >&2
done
exit 1
