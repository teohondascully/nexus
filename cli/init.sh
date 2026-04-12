#!/bin/bash
# cli/init.sh — nexus init (zero questions)

cmd_init() {
  # Disable set -e — drop_file_silent returns 1 on skip, which is expected
  set +e

  check_git

  # Detect or create project
  if [ -n "${1:-}" ]; then
    if [ ! -d "$1" ]; then
      mkdir -p "$1"
      cd "$1"
      git init --quiet
      echo -e "  ${GREEN}created${NC} $1/"
    else
      cd "$1"
    fi
  fi

  if [ ! -d ".git" ]; then
    git init --quiet
    echo -e "  ${GREEN}initialized${NC} git"
  fi

  echo ""
  echo -e "  ${BOLD}nexus init${NC}"
  echo ""

  # ── Drop templates ──────────────────────────────────────────────
  drop_file_silent "$TEMPLATES/CLAUDE.md" "CLAUDE.md"
  drop_file_silent "$TEMPLATES/justfile" "justfile"
  drop_file_silent "$TEMPLATES/gitignore" ".gitignore"
  drop_file_silent "$TEMPLATES/env.example" ".env.example"
  drop_file_silent "$TEMPLATES/mise.toml" ".mise.toml"

  mkdir -p .github
  drop_file_silent "$TEMPLATES/pr-template.md" ".github/pull_request_template.md"

  # ── Drop scripts ────────────────────────────────────────────────
  mkdir -p scripts
  for script in sync-claude-md.sh check-env-sync.sh check-deps-direction.ts check-dead-exports.ts check-hallucinated-imports.ts check-orphaned-files.ts validate-startup.sh; do
    if [ -f "$SCRIPTS/$script" ]; then
      drop_file_silent "$SCRIPTS/$script" "scripts/$script"
    fi
  done
  chmod +x scripts/*.sh scripts/*.ts 2>/dev/null || true

  # ── Drop hooks ──────────────────────────────────────────────────
  drop_file_silent "$TEMPLATES/lefthook.yml" "lefthook.yml"

  # Claude Code hooks — strip onStop if Superpowers detected
  if [ ! -f ".claude/settings.json" ]; then
    mkdir -p .claude
    if [ -d "$HOME/.claude/plugins" ] && ls "$HOME/.claude/plugins" 2>/dev/null | grep -q superpowers; then
      # Strip onStop block — Superpowers handles it
      python3 -c "
import sys, json
with open(sys.argv[1]) as f:
    data = json.load(f)
if 'hooks' in data and 'onStop' in data['hooks']:
    del data['hooks']['onStop']
json.dump(data, sys.stdout, indent=2)
" "$TEMPLATES/claude-settings.json" > .claude/settings.json 2>/dev/null || cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json ${DIM}(superpowers mode)${NC}"
    else
      cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json"
    fi
    update_checksum ".claude/settings.json"
  else
    print_skip "settings.json (already exists)"
  fi

  # ── Post-setup ──────────────────────────────────────────────────

  # Add .nexus-checksums and .nexus-version to gitignore
  append_to_file ".gitignore" ".nexus-checksums" ".nexus-checksums" > /dev/null 2>&1 || true
  append_to_file ".gitignore" ".nexus-version" ".nexus-version" > /dev/null 2>&1 || true

  # Stamp version
  cp "$NEXUS_DIR/VERSION" ".nexus-version"

  # Sync CLAUDE.md file structure
  if [ -f "scripts/sync-claude-md.sh" ] && [ -f "CLAUDE.md" ]; then
    bash scripts/sync-claude-md.sh 2>/dev/null && echo -e "  ${GREEN}synced${NC} CLAUDE.md file structure" || true
  fi

  # Trust mise config if available
  if has_cmd mise && [ -f ".mise.toml" ]; then
    mise trust > /dev/null 2>&1 && echo -e "  ${GREEN}trusted${NC} .mise.toml" || true
  fi

  # Install lefthook if available
  if has_cmd lefthook && [ -f "lefthook.yml" ]; then
    lefthook install > /dev/null 2>&1 && echo -e "  ${GREEN}activated${NC} pre-commit hooks" || true
  fi

  # ── Summary ─────────────────────────────────────────────────────
  echo ""
  printf "  Commit? [Y/n]: "
  read -r commit_ans < /dev/tty || true
  if [ "${commit_ans:-y}" != "n" ] && [ "${commit_ans:-y}" != "N" ]; then
    git add -A
    git commit -m "chore: initialize project with nexus" --quiet 2>/dev/null || true
    echo -e "  ${GREEN}committed${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Done.${NC} Your project now has invisible guardrails."
  echo ""
  echo -e "  ${BOLD}What's active${NC}"
  echo ""
  echo -e "  ${GREEN}On every commit${NC} ${DIM}(lefthook pre-commit)${NC}"
  echo -e "    Env vars in code match .env.example"
  echo -e "    Import direction follows your dependency chain"
  echo -e "    No packages imported that aren't in package.json"
  echo -e "    Typecheck and lint pass"
  echo ""
  echo -e "  ${GREEN}While AI agents code${NC} ${DIM}(Claude Code hooks)${NC}"
  echo -e "    CLAUDE.md file structure auto-syncs on every file write"
  echo -e "    Doctor runs on stop to catch drift"
  echo ""
  echo -e "  ${GREEN}On demand${NC}"
  echo -e "    ${DIM}nexus${NC}            Check project health + recommendations"
  echo -e "    ${DIM}nexus doctor --fix${NC} Auto-repair what it can"
  echo -e "    ${DIM}nexus update${NC}      Pull latest conventions from nexus"
  echo ""
  echo -e "  ${DIM}CLAUDE.md adapts as your project grows. Just build.${NC}"
  echo ""
}
