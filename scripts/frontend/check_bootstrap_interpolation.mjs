#!/usr/bin/env node

/**
 * Flags Bootstrap CSS utility classes built via string interpolation, e.g.
 *
 *   `rounded-${this.position}`   (JS/Vue template literal)
 *   "position-#{side}-0"         (Ruby/HAML interpolation)
 *
 * The bootstrap -> Tailwind codemod (container_queries_migration.mjs) only
 * rewrites *literal* utility tokens, so interpolated ones slip through the
 * migration. This check surfaces them so they can be migrated by hand.
 *
 * Prefixes are derived from the same BOOTSTRAP_MIGRATIONS map the codemod
 * uses, so the two stay in sync.
 *
 * Usage:
 *   node scripts/frontend/check_bootstrap_interpolation.mjs            # scan tracked files
 *   node scripts/frontend/check_bootstrap_interpolation.mjs file ...   # scan given files
 */

import { readFileSync, existsSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { BOOTSTRAP_MIGRATIONS } from './lib/bootstrap_tailwind_equivalents.mjs';

const EXTENSIONS = ['vue', 'js', 'ts', 'haml', 'rb', 'erb'];
const EXCLUSIONS_FILE = 'scripts/frontend/bootstrap_interpolation_exclusions.txt';

// Same standalone-class-token boundary the codemod uses, so this check agrees
// with what the migration considers a real utility token.
const CLASS_CHARS = ['-', '\\w', '!', ':'].join('|');
const INTERPOLATION = ['\\$\\{', '#\\{'].join('|'); // ${ ...}  or  #{ ...}

function buildPrefixes(migrations) {
  const keys = Object.keys(migrations);

  // Count how many keys share each "strip the last segment" prefix, so we only
  // treat a prefix as a variant family when the map actually has variants.
  // `position-absolute/relative/sticky` -> `position` (3 keys, a real family);
  // `no-gutters`, `fixed-top` -> stripped prefix seen once -> NOT a family.
  const familyCounts = new Map();
  for (const key of keys) {
    const parts = key.split('-');
    if (parts.length > 1) {
      const stripped = parts.slice(0, -1).join('-');
      familyCounts.set(stripped, (familyCounts.get(stripped) ?? 0) + 1);
    }
  }

  const prefixes = new Set();
  for (const key of keys) {
    prefixes.add(key); // whole-key utils: `rounded-${x}`, `border-${x}`
    const parts = key.split('-');
    if (parts.length > 1) {
      const stripped = parts.slice(0, -1).join('-');
      if (familyCounts.get(stripped) >= 2) prefixes.add(stripped);
    }
  }
  // Longest first so `align-items` is tried before `align`.
  return [...prefixes].sort((a, b) => b.length - a.length);
}

function buildRegExp(prefixes) {
  const escaped = prefixes.map((p) => p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  const alternation = escaped.join('|');
  return new RegExp(`(?<!${CLASS_CHARS})(${alternation})-(${INTERPOLATION})`, 'g');
}

function loadExclusions() {
  if (!existsSync(EXCLUSIONS_FILE)) return [];
  return readFileSync(EXCLUSIONS_FILE, 'utf-8')
    .split('\n')
    .map((line) => line.split('#')[0].trim())
    .filter(Boolean)
    .map((pattern) => new RegExp(pattern));
}

function listFiles() {
  const out = execSync('git ls-files', { encoding: 'utf-8', maxBuffer: 64 * 1024 * 1024 });
  const extRe = new RegExp(`\\.(${EXTENSIONS.join('|')})$`);
  return out.split('\n').filter((f) => f && extRe.test(f));
}

function main() {
  const prefixes = buildPrefixes(BOOTSTRAP_MIGRATIONS);
  const regExp = buildRegExp(prefixes);
  const exclusions = loadExclusions();

  const argFiles = process.argv.slice(2);
  const files = argFiles.length ? argFiles : listFiles();

  const offenses = [];

  for (const file of files) {
    let content;
    try {
      content = readFileSync(file, 'utf-8');
    } catch {
      continue;
    }
    const lines = content.split('\n');
    lines.forEach((line, i) => {
      regExp.lastIndex = 0;
      while (regExp.exec(line) !== null) {
        const location = `${file}:${i + 1}`;
        if (exclusions.some((re) => re.test(location) || re.test(line))) continue;
        offenses.push({ location, text: line.trim() });
      }
    });
  }

  if (offenses.length === 0) {
    console.log('No interpolated Bootstrap utility classes found.');
    process.exit(0);
  }

  console.error(`Found ${offenses.length} interpolated Bootstrap utility class(es):\n`);
  for (const { location, text } of offenses) {
    console.error(`  ${location}\n    ${text}`);
  }
  console.error(
    `\nThese cannot be auto-migrated by the bootstrap->Tailwind codemod.` +
      `\nMigrate them by hand (see ${'scripts/frontend/lib/bootstrap_tailwind_equivalents.mjs'}),` +
      `\nor add a false positive to ${EXCLUSIONS_FILE}.`,
  );
  process.exit(1);
}

main();
