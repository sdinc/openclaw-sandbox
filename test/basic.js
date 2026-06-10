 /**
 * Basic sandbox toolchain assertions.
 *
 * Verifies that every tool the image is supposed to provide is
 * installed, executable, and returns a plausible version string.
 * Run inside the container (via `make test-basic`) or directly
 * with `node test/basic.js`.
 */
'use strict';

import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import assert from 'node:assert';

const execAsync = promisify(exec);

// ---------- helpers --------------------------------------------------

const tools = [
  { name: 'openclaw',   args: '--version',  re: /^[vV]?20[0-9]{2}\.[0-9]+\.[0-9]+/ },
  { name: 'node',       args: '--version',  re: /^v[0-9]+\./ },
  { name: 'npm',        args: '--version',  re: /^[0-9]+\.[0-9]+\.[0-9]+$/ },
  { name: 'python',     args: '--version',  re: /^Python [0-9]+\./ },
  { name: 'uv',         args: '--version',  re: /^uv/ },
  { name: 'gh',         args: '--version',  re: /^[vV]?[0-9]+\.[0-9]+\.[0-9]+/ },
  { name: 'zsh',        args: '--version',  re: /^zsh [0-9]+\./ },
];

// Chrome is optional — skip if not present
let chromePresent = true;
try {
  const { stdout } = await execAsync('which google-chrome-stable');
  chromePresent = !!stdout.trim();
} catch {
  chromePresent = false;
}
if (chromePresent) {
  tools.push({ name: 'google-chrome-stable', args: '--version', re: /Google.*Chrome/ });
}

// Playwright import is optional inside the container (might run before pip install)
let playwrightImportable = true;
try {
  await execAsync("python -c 'import playwright'");
} catch {
  playwrightImportable = false;
}
if (playwrightImportable) {
  tools.push({ name: 'playwright (Python)', args: "-c 'import playwright'", re: /$/ }); // any output
}

// ---------- assertions -----------------------------------------------

let passCount = 0;
let failCount = 0;

for (const { name, args, re } of tools) {
  try {
    const { stdout } = await execAsync(`${name} ${args}`);
    const match = stdout.trim().match(re);
    assert(match, `${name} output did not match expected pattern /${re.source}/: ${stdout.trim()}`);
    console.log(`  ✅ ${name}: ${stdout.trim()}`);
    passCount++;
  } catch (err) {
    console.error(`  ❌ ${name}: ${err.message}`);
    failCount++;
  }
}

// ---------- summary --------------------------------------------------

const total = passCount + failCount;
console.log(`\n${passCount}/${total} checks passed`);

if (failCount > 0) {
  console.error(`\n[${failCount} failed] Sandbox toolchain verification failed.`);
  process.exit(1);
}