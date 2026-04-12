#!/usr/bin/env bun
// check-deps-direction.ts
// Scans imports for dependency direction violations.
// A violation is importing from a layer that comes AFTER you in the chain
// (higher index = higher layer — you must not import "up" the stack).

import { readdirSync, readFileSync, statSync } from "fs";
import { join, resolve, dirname, relative } from "path";

const CLAUDE_MD_PATH = resolve(process.cwd(), "CLAUDE.md");

// ---------------------------------------------------------------------------
// Parse dependency chain from CLAUDE.md
// Look for lines containing → (e.g. "Types → Config → Repo → Service → UI")
// ---------------------------------------------------------------------------
function parseChain(): string[] {
  let content: string;
  try {
    content = readFileSync(CLAUDE_MD_PATH, "utf8");
  } catch {
    console.error("check-deps-direction: CLAUDE.md not found, skipping.");
    process.exit(0);
  }

  for (const line of content.split("\n")) {
    if (line.includes("→")) {
      // Strip markdown formatting and split on →
      const parts = line
        .replace(/`/g, "")
        .split("→")
        .map((s) => s.trim())
        .filter(Boolean);
      if (parts.length >= 2) {
        return parts;
      }
    }
  }

  console.error("check-deps-direction: no dependency chain (→) found in CLAUDE.md, skipping.");
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Collect all .ts / .tsx files recursively, skipping noise directories
// ---------------------------------------------------------------------------
const SKIP_DIRS = new Set(["node_modules", ".next", "dist", ".git", "build", ".turbo"]);

function collectFiles(dir: string, files: string[] = []): string[] {
  for (const entry of readdirSync(dir)) {
    if (SKIP_DIRS.has(entry)) continue;
    const full = join(dir, entry);
    const stat = statSync(full);
    if (stat.isDirectory()) {
      collectFiles(full, files);
    } else if (/\.(ts|tsx)$/.test(entry)) {
      files.push(full);
    }
  }
  return files;
}

// ---------------------------------------------------------------------------
// Determine which chain layer a file path belongs to (case-insensitive)
// ---------------------------------------------------------------------------
function getLayer(filePath: string, chain: string[]): number {
  const lower = filePath.toLowerCase();
  for (let i = 0; i < chain.length; i++) {
    if (lower.includes(chain[i].toLowerCase())) {
      return i;
    }
  }
  return -1; // not categorised
}

// ---------------------------------------------------------------------------
// Extract import paths from a file's source text
// Matches: from '...', import('...'), require('...')
// Only processes relative/alias imports: ., @/, ~/
// ---------------------------------------------------------------------------
const IMPORT_RE = /(?:from\s+|import\s*\(|require\s*\()['"]([^'"]+)['"]/g;

function extractImports(source: string): string[] {
  const imports: string[] = [];
  let m: RegExpExecArray | null;
  while ((m = IMPORT_RE.exec(source)) !== null) {
    const spec = m[1];
    if (spec.startsWith(".") || spec.startsWith("@/") || spec.startsWith("~/")) {
      imports.push(spec);
    }
  }
  return imports;
}

// ---------------------------------------------------------------------------
// Resolve an import specifier to an absolute path (best-effort)
// ---------------------------------------------------------------------------
function resolveImport(spec: string, fromFile: string): string {
  if (spec.startsWith(".")) {
    return resolve(dirname(fromFile), spec);
  }
  // @/ and ~/ are typically aliases for the project root src/ or root
  const root = process.cwd();
  const stripped = spec.replace(/^[@~]\//, "");
  return join(root, stripped);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
const chain = parseChain();
console.log(`check-deps-direction: chain = ${chain.join(" → ")}`);

const root = process.cwd();
const files = collectFiles(root);

if (files.length === 0) {
  console.log("check-deps-direction: no .ts/.tsx files found.");
  process.exit(0);
}

interface Violation {
  file: string;
  fileLayer: string;
  importSpec: string;
  importLayer: string;
}

const violations: Violation[] = [];

for (const file of files) {
  const fileLayerIndex = getLayer(file, chain);
  if (fileLayerIndex === -1) continue; // file not in any known layer

  let source: string;
  try {
    source = readFileSync(file, "utf8");
  } catch {
    continue;
  }

  const imports = extractImports(source);
  for (const spec of imports) {
    const resolved = resolveImport(spec, file);
    const importLayerIndex = getLayer(resolved, chain);
    if (importLayerIndex === -1) continue; // target not in any known layer

    // Violation: file imports from a layer with a HIGHER index (further down the chain)
    if (importLayerIndex > fileLayerIndex) {
      violations.push({
        file: relative(root, file),
        fileLayer: chain[fileLayerIndex],
        importSpec: spec,
        importLayer: chain[importLayerIndex],
      });
    }
  }
}

if (violations.length === 0) {
  console.log("check-deps-direction: no violations found.");
  process.exit(0);
}

console.error(`\ncheck-deps-direction: ${violations.length} violation(s) found:\n`);
for (const v of violations) {
  console.error(`  ${v.file}  [${v.fileLayer}]`);
  console.error(`    imports: ${v.importSpec}  [${v.importLayer}]`);
}
console.error(
  `\nDependency direction: ${chain.join(" → ")}\nLower layers must not import from higher layers.\n`
);
process.exit(1);
