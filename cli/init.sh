#!/bin/bash
# cli/init.sh — nexus init (zero-footprint, detection-aware)

cmd_init() {
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

  # ── Detect ecosystem ────────────────────────────────────────────
  local eco
  eco=$(detect_ecosystem)

  # ── Drop templates ──────────────────────────────────────────────
  drop_template "$TEMPLATES/CLAUDE.md" "CLAUDE.md"

  # Append Node conventions if detected
  if [ "$eco" = "node" ] && [ -f "CLAUDE.md" ] && [ -f "$TEMPLATES/CLAUDE.md.node" ]; then
    if ! grep -q "nexus:conventions-node" "CLAUDE.md" 2>/dev/null; then
      printf "\n" >> "CLAUDE.md"
      cat "$TEMPLATES/CLAUDE.md.node" >> "CLAUDE.md"
      echo -e "  ${GREEN}added${NC} Node conventions"
    fi
  fi

  drop_template "$TEMPLATES/gitignore" ".gitignore"
  drop_template "$TEMPLATES/env.example" ".env.example"
  drop_template "$TEMPLATES/mise.toml" ".mise.toml"

  mkdir -p .github
  drop_template "$TEMPLATES/pr-template.md" ".github/pull_request_template.md"

  # ── Drop hooks ──────────────────────────────────────────────────

  # Lefthook — universal base, append Node hooks if detected
  if [ ! -f "lefthook.yml" ]; then
    cp "$TEMPLATES/lefthook.yml" "lefthook.yml"
    if [ "$eco" = "node" ] && [ -f "$TEMPLATES/lefthook.yml.node" ]; then
      cat "$TEMPLATES/lefthook.yml.node" >> "lefthook.yml"
    fi
    echo -e "  ${GREEN}created${NC} lefthook.yml"
  else
    print_skip "lefthook.yml (already exists)"
  fi

  # Claude Code hooks — strip Stop hook if Superpowers detected
  if [ ! -f ".claude/settings.json" ]; then
    mkdir -p .claude
    if [ -d "$HOME/.claude/plugins" ] && ls "$HOME/.claude/plugins" 2>/dev/null | grep -q superpowers; then
      python3 -c "
import sys, json
with open(sys.argv[1]) as f:
    data = json.load(f)
if 'hooks' in data and 'Stop' in data['hooks']:
    del data['hooks']['Stop']
json.dump(data, sys.stdout, indent=2)
" "$TEMPLATES/claude-settings.json" > .claude/settings.json 2>/dev/null || cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json ${DIM}(superpowers mode)${NC}"
    else
      cp "$TEMPLATES/claude-settings.json" .claude/settings.json
      echo -e "  ${GREEN}created${NC} settings.json"
    fi
  else
    print_skip "settings.json (already exists)"
  fi

  # Justfile — only if no build system exists
  if ! has_build_system; then
    drop_template "$TEMPLATES/justfile" "justfile"
  fi

  # ── Post-setup ──────────────────────────────────────────────────

  # Ensure .nexus/ and .nexus-version are gitignored
  append_to_file ".gitignore" ".nexus/" ".nexus/" > /dev/null 2>&1 || true
  append_to_file ".gitignore" ".nexus-version" ".nexus-version" > /dev/null 2>&1 || true

  # Stamp version
  cp "$NEXUS_DIR/VERSION" ".nexus-version"

  # Create .nexus/ and run session sync to populate context
  mkdir -p .nexus
  if [ -f "$NEXUS_DIR/scripts/session-sync.sh" ]; then
    bash "$NEXUS_DIR/scripts/session-sync.sh" 2>/dev/null || true
    echo -e "  ${GREEN}synced${NC} project context"
  fi

  # Sync CLAUDE.md file structure
  if [ -f "CLAUDE.md" ] && [ -f "$NEXUS_DIR/scripts/sync-claude-md.sh" ]; then
    bash "$NEXUS_DIR/scripts/sync-claude-md.sh" > /dev/null 2>&1 && echo -e "  ${GREEN}synced${NC} CLAUDE.md file structure" || true
  fi

  # Trust mise config if available
  if has_cmd mise && [ -f ".mise.toml" ]; then
    mise trust > /dev/null 2>&1 && echo -e "  ${GREEN}trusted${NC} .mise.toml" || true
  fi

  # Install lefthook if available
  if has_cmd lefthook && [ -f "lefthook.yml" ]; then
    lefthook install > /dev/null 2>&1 && echo -e "  ${GREEN}activated${NC} pre-commit hooks" || true
  fi

  # ── Detection summary ──────────────────────────────────────────
  echo ""
  case "$eco" in
    node)
      local fw=""
      if [ -f "package.json" ]; then
        for f in next express hono fastify remix svelte astro nuxt; do
          if grep -q "\"$f\"" package.json 2>/dev/null; then
            fw="$f"
            break
          fi
        done
      fi
      if [ -n "$fw" ]; then
        echo -e "  ${BOLD}Detected:${NC} Node (${fw})"
      else
        echo -e "  ${BOLD}Detected:${NC} Node"
      fi
      ;;
    go)     echo -e "  ${BOLD}Detected:${NC} Go" ;;
    python) echo -e "  ${BOLD}Detected:${NC} Python" ;;
    rust)   echo -e "  ${BOLD}Detected:${NC} Rust" ;;
    *)      echo -e "  ${BOLD}Detected:${NC} Generic project" ;;
  esac

  # ── Commit ─────────────────────────────────────────────────────
  echo ""
  printf "  Commit? [Y/n]: "
  read -r commit_ans < /dev/tty || true
  if [ "${commit_ans:-y}" != "n" ] && [ "${commit_ans:-y}" != "N" ]; then
    git add -A
    git commit -m "chore: initialize project with nexus" --quiet 2>/dev/null || true
    echo -e "  ${GREEN}committed${NC}"
  fi

  # ── Summary ─────────────────────────────────────────────────────
  echo ""
  echo -e "  ${BOLD}Your project has invisible guardrails.${NC}"
  echo ""
  echo -e "  ${GREEN}On every commit${NC} ${DIM}(lefthook pre-commit)${NC}"
  if [ "$eco" = "node" ]; then
    echo -e "    Env vars in code match .env.example"
    echo -e "    Import direction follows your dependency chain"
    echo -e "    No packages imported that aren't in package.json"
    echo -e "    Typecheck and lint pass"
  elif [ "$eco" = "generic" ]; then
    echo -e "    CLAUDE.md file structure is accurate"
  else
    echo -e "    Env vars in code match .env.example"
    echo -e "    CLAUDE.md file structure is accurate"
  fi
  echo ""
  echo -e "  ${GREEN}While AI agents code${NC} ${DIM}(Claude Code hooks)${NC}"
  echo -e "    Project context stays fresh across sessions"
  echo -e "    Doctor catches drift on session end"
  echo ""
  echo -e "  ${GREEN}On demand${NC}"
  echo -e "    ${DIM}nexus${NC}               Check project health"
  echo -e "    ${DIM}nexus doctor --fix${NC}   Auto-repair what it can"
  echo -e "    ${DIM}nexus update${NC}         Pull latest conventions"
  echo ""

  # ── Git remote hint ─────────────────────────────────────────────
  if ! git remote get-url origin > /dev/null 2>&1; then
    echo -e "  ${DIM}No remote detected. To connect to GitHub:${NC}"
    echo -e "    ${DIM}gh repo create <name> --private --source .${NC}"
    echo -e "    ${DIM}git push -u origin main${NC}"
    echo ""
  fi
}
