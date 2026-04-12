# Cursor

> AI-native IDE (VS Code fork) with inline editing, multi-file context, and chat.

---

## What It Is
A fork of VS Code with AI deeply integrated: inline completions, multi-file editing with visual diffs, chat panel, and project-level rules.

## Key Features

### .cursor/rules/
Directory of rule files scoped by file pattern. More granular than CLAUDE.md — you can have rules that only apply to test files, API routes, components, etc.

### Composer
Multi-file editing mode. Describe a change, Cursor proposes edits across multiple files, you review diffs visually and accept/reject per-file.

### Tab Completion
Context-aware autocomplete that predicts multi-line edits based on what you're doing.

## Best For
- Interactive editing where you want to see and approve each change
- Visual diff review across files
- Pair-programming style: you drive, AI assists

## Limitations
- Agent loop less mature than Claude Code for autonomous tasks
- Hook/verification system not as developed
- Subscription pricing

## Harness Ceiling
Level 2-3. Rules files provide context, but limited lifecycle hooks.

---

#tools #cursor
