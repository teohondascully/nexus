#!/usr/bin/env bun
// check-dead-exports.ts
// Flags exported symbols that nothing in the project imports.

import { readdirSync, readFileSync, statSync } from "fs";
import { join, relative, basename } from "path";

// ---------------------------------------------------------------------------
// Directories and files to skip when collecting source files
// ---------------------------------------------------------------------------
const SKIP_DIRS = new Set(["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts"]);

// Barrel / index files and common config files — skip exporting analysis for these
// because they re-export everything intentionally
const SKIP_FILE_PATTERNS = [
  /^index\.(ts|tsx)$/,
  /^(next\.config|tailwind\.config|postcss\.config|jest\.config|vitest\.config|bun\.config|eslint\.config|drizzle\.config)\.(ts|tsx|js|mjs|cjs)$/,
];

// Common framework-reserved / dynamic exports that are deliberately not imported
const DYNAMIC_EXPORT_NAMES = new Set([
  "default",
  "metadata",
  "generateMetadata",
  "revalidate",
  "dynamic",
  "fetchCache",
  "runtime",
  "preferredRegion",
  "maxDuration",
  "generateStaticParams",
  "generateViewport",
  "viewport",
  "loader",
  "action",
  "links",
  "headers",
]);

// ---------------------------------------------------------------------------
// Collect all .ts / .tsx files recursively
// ---------------------------------------------------------------------------
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
// Extract exported names from a file's source text
// Handles:
//   export const/let/var/function/class/type/interface/enum NAME
//   export { name1, name2, name3 as alias }
// ---------------------------------------------------------------------------
const NAMED_EXPORT_RE = /^export\s+(?:const|let|var|function|class|type|interface|enum)\s+([A-Za-z_$][A-Za-z0-9_$]*)/gm;
const BRACE_EXPORT_RE = /^export\s*\{([^}]+)\}/gm;

function extractExports(source: string): string[] {
  const names: string[] = [];

  let m: RegExpExecArray | null;

  // Named keyword exports
  while ((m = NAMED_EXPORT_RE.exec(source)) !== null) {
    names.push(m[1]);
  }

  // Brace exports: export { foo, bar as baz }
  while ((m = BRACE_EXPORT_RE.exec(source)) !== null) {
    for (const part of m[1].split(",")) {
      // Handle "name as alias" — the exported name is the alias
      const aliasMatch = part.trim().match(/^.*\bas\b\s+([A-Za-z_$][A-Za-z0-9_$]*)$/);
      if (aliasMatch) {
        names.push(aliasMatch[1]);
      } else {
        const raw = part.trim().match(/^([A-Za-z_$][A-Za-z0-9_$]*)/);
        if (raw) names.push(raw[1]);
      }
    }
  }

  return names;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
const root = process.cwd();
const allFiles = collectFiles(root);

if (allFiles.length < 5) {
  console.log("check-dead-exports: fewer than 5 files found — project too small, skipping.");
  process.exit(0);
}

// Read all file contents up front (we'll need them for the "is used anywhere" check)
const fileContents = new Map<string, string>();
for (const file of allFiles) {
  try {
    fileContents.set(file, readFileSync(file, "utf8"));
  } catch {
    // ignore unreadable files
  }
}

interface DeadExport {
  file: string;
  name: string;
}

const dead: DeadExport[] = [];

for (const file of allFiles) {
  const name = basename(file);

  // Skip barrel / config files
  if (SKIP_FILE_PATTERNS.some((re) => re.test(name))) continue;

  const source = fileContents.get(file);
  if (!source) continue;

  const exports = extractExports(source);
  for (const exportName of exports) {
    // Skip dynamic / framework-reserved names
    if (DYNAMIC_EXPORT_NAMES.has(exportName)) continue;

    // Check if any OTHER file references this name
    let found = false;
    for (const [otherFile, otherSource] of fileContents) {
      if (otherFile === file) continue;
      if (otherSource.includes(exportName)) {
        found = true;
        break;
      }
    }

    if (!found) {
      dead.push({ file: relative(root, file), name: exportName });
    }
  }
}

if (dead.length === 0) {
  console.log("check-dead-exports: no dead exports found.");
  process.exit(0);
}

console.error(`\ncheck-dead-exports: ${dead.length} potentially dead export(s) found:\n`);
for (const d of dead) {
  console.error(`  ${d.file}  →  ${d.name}`);
}
console.error("\nThese names are exported but not referenced anywhere else in the project.\n");
process.exit(1);
