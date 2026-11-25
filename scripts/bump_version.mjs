#!/usr/bin/env node
// bump_version.mjs — 一 Sprint 一 patch 的版本号升级（0.1.x 三段号，四段号被 mooncakes 拒绝）
//
// 改到的地方（全部由 `node scripts/check_version.mjs` 守护，漏一处就红）：
//   moon.mod × 7（根 + 6 子模块）、image.mbt 门面 `pub let version`、
//   imgcli/imgtool.mbt 的 CLI `pub let version`、
//   README.md / README.en.md 的 version 与 mooncakes 徽章、docs/known-gaps.md 的「当前口径」行。
//
// 用法：
//   node scripts/bump_version.mjs              # 当前 0.1.6 → 0.1.7
//   node scripts/bump_version.mjs --to 0.1.8   # 显式指定目标
//   node scripts/bump_version.mjs -n           # 只打印将要改什么（dry-run）

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const MODULES = [
  'moon.mod',
  'image.core/moon.mod',
  'image.codec/moon.mod',
  'image.process/moon.mod',
  'image.photography/moon.mod',
  'image.vision/moon.mod',
  'image.domain/moon.mod',
];

const args = process.argv.slice(2);
const dry = args.includes('-n') || args.includes('--dry-run');
const toIdx = args.indexOf('--to');
const explicit = toIdx >= 0 ? args[toIdx + 1] : null;

const read = rel => readFile(path.join(ROOT, rel), 'utf8');
const write = (rel, text) => writeFile(path.join(ROOT, rel), text, 'utf8');

const rootMod = await read('moon.mod');
const from = rootMod.match(/^version = "([^"]+)"/m)?.[1];
if (!from) throw new Error('moon.mod 里找不到 version');

let to = explicit;
if (!to) {
  const m = from.match(/^0\.1\.(\d+)$/);
  if (!m) throw new Error(`当前版本 ${from} 不是 0.1.x，无法自动 +1（用 --to 指定）`);
  to = `0.1.${Number(m[1]) + 1}`;
}
if (!/^0\.1\.\d+$/.test(to)) throw new Error(`目标版本 ${to} 不是 0.1.x（三段号）`);

const edits = [];
const bump = (rel, re, make) => {
  edits.push({ rel, re, make });
};

for (const rel of MODULES) bump(rel, /^version = "([^"]+)"/m, () => `version = "${to}"`);
bump('image.mbt', /pub let version : String = "([^"]+)"/, () => `pub let version : String = "${to}"`);
bump('imgcli/imgtool.mbt', /pub let version : String = "([^"]+)"/, () => `pub let version : String = "${to}"`);
bump('README.md', /badge\/version-([\d.]+)-orange/, () => `badge/version-${to}-orange`);
bump('README.en.md', /badge\/version-([\d.]+)-orange/, () => `badge/version-${to}-orange`);
bump('README.md', /badge\/mooncakes-([\d.]+)-orange/, () => `badge/mooncakes-${to}-orange`);
bump('README.en.md', /badge\/mooncakes-([\d.]+)-orange/, () => `badge/mooncakes-${to}-orange`);
bump('docs/known-gaps.md', /版本 ([\d.]+) · /, () => `版本 ${to} · `);

let changed = 0;
for (const { rel, re, make } of edits) {
  const text = await read(rel);
  if (!re.test(text)) {
    console.error(`✗ ${rel}: 找不到匹配 ${re}`);
    process.exit(1);
  }
  const next = text.replace(re, (...m) => make(m[1]));
  if (next !== text) {
    changed += 1;
    if (!dry) await write(rel, next);
    console.log(`${dry ? 'would change' : 'changed'}: ${rel}`);
  }
}

console.log(JSON.stringify({ schema: 'bump-version@1', from, to, filesChanged: changed, dryRun: dry }, null, 2));
