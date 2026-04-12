#!/usr/bin/env bash
# sync-claude-md.sh
# Regenerates the file structure section in CLAUDE.md between
# FILE_STRUCTURE_START and FILE_STRUCTURE_END markers.

set -euo pipefail

CLAUDE_MD="${1:-CLAUDE.md}"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "sync-claude-md: $CLAUDE_MD not found, skipping." >&2
  exit 0
fi

# Check for required markers
if ! grep -q "FILE_STRUCTURE_START" "$CLAUDE_MD" || ! grep -q "FILE_STRUCTURE_END" "$CLAUDE_MD"; then
  echo "sync-claude-md: no FILE_STRUCTURE markers found in $CLAUDE_MD, skipping." >&2
  exit 0
fi

# Build the file tree (full file listing, sorted, max 80 lines)
TREE=$(find . \
  -not \( \
    -path "*/node_modules/*" -o \
    -path "*/.git/*" -o \
    -path "*/.next/*" -o \
    -path "*/dist/*" -o \
    -path "*/build/*" -o \
    -path "*/.turbo/*" -o \
    -path "*/coverage/*" -o \
    -path "*/.vercel/*" -o \
    -name ".DS_Store" -o \
    -name "*.tsbuildinfo" \
  \) \
  -print \
  | sort \
  | head -80)

LINE_COUNT=$(printf '%s\n' "$TREE" | wc -l | tr -d ' ')

# Fall back to directory-only view if too many lines
if [[ "$LINE_COUNT" -gt 60 ]]; then
  TREE=$(find . \
    -type d \
    -not \( \
      -path "*/node_modules/*" -o \
      -path "*/.git/*" -o \
      -path "*/.next/*" -o \
      -path "*/dist/*" -o \
      -path "*/build/*" -o \
      -path "*/.turbo/*" -o \
      -path "*/coverage/*" -o \
      -path "*/.vercel/*" \
    \) \
    -print \
    | sort \
    | head -40)
fi

# Build replacement block
REPLACEMENT="<!-- FILE_STRUCTURE_START -->
\`\`\`
${TREE}
\`\`\`
<!-- FILE_STRUCTURE_END -->"

# Use awk to replace the content between the markers (inclusive)
awk -v replacement="$REPLACEMENT" '
  /<!-- FILE_STRUCTURE_START -->/ { printing=1; print replacement; next }
  /<!-- FILE_STRUCTURE_END -->/   { printing=0; next }
  printing                         { next }
  { print }
' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp"

mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"

echo "sync-claude-md: updated file structure in $CLAUDE_MD (${LINE_COUNT} lines)."
