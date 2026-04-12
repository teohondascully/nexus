#!/usr/bin/env bun
// scripts/check-hallucinated-imports.ts
// Catches packages imported in code but not in package.json
// Called by lefthook pre-commit and nexus doctor

import { readFileSync, readdirSync, statSync, existsSync } from "fs";
import { join, relative } from "path";
import { builtinModules } from "module";

const root = process.cwd();

// ── Load package.json deps ──────────────────────────────────────
const pkgPath = join(root, "package.json");
if (!existsSync(pkgPath)) {
  // No package.json = nothing to check against
  process.exit(0);
}

const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
const allDeps = new Set([
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.devDependencies || {}),
  ...Object.keys(pkg.peerDependencies || {}),
]);

// ── Node built-ins ──────────────────────────────────────────────
const builtins = new Set([
  ...builtinModules,
  ...builtinModules.map((m) => `node:${m}`),
]);

// ── Collect source files ────────────────────────────────────────
function collectFiles(dir: string, files: string[] = []): string[] {
  const skip = ["node_modules", ".next", "dist", ".git", "build", ".turbo", "scripts"];
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

// ── Extract package names from imports ──────────────────────────
function extractPackageImports(content: string): string[] {
  const packages: string[] = [];
  const patterns = [
    /from\s+['"]([^'"]+)['"]/g,
    /import\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
    /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(content)) !== null) {
      const spec = match[1];
      // Skip relative, alias, and URL imports
      if (spec.startsWith(".") || spec.startsWith("@/") || spec.startsWith("~/") || spec.startsWith("http")) {
        continue;
      }
      // Extract package name (handle scoped packages)
      let pkgName: string;
      if (spec.startsWith("@")) {
        const parts = spec.split("/");
        pkgName = parts.length >= 2 ? `${parts[0]}/${parts[1]}` : spec;
      } else {
        pkgName = spec.split("/")[0];
      }
      packages.push(pkgName);
    }
  }
  return packages;
}

// ── Main ────────────────────────────────────────────────────────
const files = collectFiles(root);

if (files.length === 0) {
  process.exit(0);
}

const hallucinated: { file: string; pkg: string }[] = [];

for (const file of files) {
  const content = readFileSync(file, "utf-8");
  const imports = extractPackageImports(content);

  for (const pkg of imports) {
    if (allDeps.has(pkg) || builtins.has(pkg)) continue;
    hallucinated.push({ file: relative(root, file), pkg });
  }
}

// Deduplicate by package name
const seen = new Set<string>();
const unique = hallucinated.filter(({ file, pkg }) => {
  const key = `${file}:${pkg}`;
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});

if (unique.length > 0) {
  console.log(`Hallucinated imports (${unique.length}):`);
  for (const { file, pkg } of unique) {
    console.log(`  ${file} imports "${pkg}" (not in package.json)`);
  }
  process.exit(1);
}

process.exit(0);
