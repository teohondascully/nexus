#!/usr/bin/env bun
// scripts/check-orphaned-files.ts
// Detects files that nothing imports (agent leftovers)
// Called by nexus doctor

import { readFileSync, readdirSync, statSync } from "fs";
import { join, relative, basename, dirname } from "path";

const root = process.cwd();

// ── Next.js / framework convention files (never orphaned) ───────
const conventionFiles = new Set([
  "page.tsx", "page.ts", "page.jsx", "page.js",
  "layout.tsx", "layout.ts", "layout.jsx", "layout.js",
  "loading.tsx", "loading.ts",
  "error.tsx", "error.ts",
  "not-found.tsx", "not-found.ts",
  "route.ts", "route.js",
  "middleware.ts", "middleware.js",
  "global-error.tsx", "global-error.ts",
  "default.tsx", "default.ts",
  "template.tsx", "template.ts",
  "opengraph-image.tsx", "twitter-image.tsx",
  "sitemap.ts", "robots.ts",
  "manifest.ts",
]);

// ── Config files (never orphaned) ───────────────────────────────
const configPatterns = [
  /\.config\.(ts|js|mjs|cjs)$/,
  /tailwind/,
  /postcss/,
  /next\.config/,
  /drizzle\.config/,
  /vitest\.config/,
  /jest\.config/,
  /playwright\.config/,
  /eslint/,
  /prettier/,
  /tsconfig/,
];

// ── Collect source files ────────────────────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts", ".claude"];
  for (const entry of readdirSync(dir)) {
    if (skip.includes(entry)) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      collectFiles(full, files);
    } else if (/\.(ts|tsx|js|jsx)$/.test(entry)) {
      files.push(full);
    }
  }
  return files;
}

function isConventionFile(filePath: string): boolean {
  const name = basename(filePath);
  if (conventionFiles.has(name)) return true;
  if (name === "index.ts" || name === "index.tsx" || name === "index.js") return true;
  for (const pattern of configPatterns) {
    if (pattern.test(filePath)) return true;
  }
  return false;
}

function isReferencedByOtherFile(filePath: string, allFiles: string[]): boolean {
  const rel = relative(root, filePath);
  const nameNoExt = basename(filePath).replace(/\.(ts|tsx|js|jsx)$/, "");
  const dirName = basename(dirname(filePath));

  for (const other of allFiles) {
    if (other === filePath) continue;
    const content = readFileSync(other, "utf-8");
    // Check for various import patterns that could resolve to this file
    if (content.includes(nameNoExt) || content.includes(rel)) {
      return true;
    }
  }
  return false;
}

// ── Main ────────────────────────────────────────────────────────
const files = collectFiles(root);

// Skip if project is too small
if (files.length < 10) {
  process.exit(0);
}

const orphaned: string[] = [];

for (const file of files) {
  if (isConventionFile(file)) continue;
  if (!isReferencedByOtherFile(file, files)) {
    orphaned.push(relative(root, file));
  }
}

if (orphaned.length > 0) {
  console.log(`Orphaned files (${orphaned.length}):`);
  for (const f of orphaned) {
    console.log(`  ${f}`);
  }
  process.exit(1);
}

process.exit(0);
