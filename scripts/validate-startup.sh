#!/usr/bin/env bash
# validate-startup.sh
# Crashes on boot if required env vars are missing.
# "Required" means a line in .env.example where the value after = is empty.

set -euo pipefail

ENV_EXAMPLE="${1:-.env.example}"

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  echo "validate-startup: $ENV_EXAMPLE not found, skipping." >&2
  exit 0
fi

required=()
while IFS= read -r line; do
  # Skip blank lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  varname="${line%%=*}"
  value="${line#*=}"

  # A var is required when the value after = is empty
  if [[ -z "$value" ]]; then
    [[ -n "$varname" ]] && required+=("$varname")
  fi
done < "$ENV_EXAMPLE"

if [[ "${#required[@]}" -eq 0 ]]; then
  echo "validate-startup: no required env vars defined in $ENV_EXAMPLE."
  exit 0
fi

missing=()
for var in "${required[@]}"; do
  # Check that the variable is set and non-empty in the current environment
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ "${#missing[@]}" -eq 0 ]]; then
  echo "validate-startup: all required env vars are set."
  exit 0
fi

echo "validate-startup: missing required environment variables:" >&2
for v in "${missing[@]}"; do
  echo "  - $v" >&2
done
exit 1
