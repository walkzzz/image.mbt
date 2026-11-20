#!/usr/bin/env node
// check_version.mjs — 七模块版本一致性门禁
//
// 校验：根模块 + 6 子模块 moon.mod 的 version 一致；
//       等于 image.mbt 门面 pub let version、README zh/en 的 version badge 与 mooncakes badge。
// 用法：node scripts/check_version.mjs
// 退出码：一致 0；任一不一致 1。

import { readFile } from 'node:fs/promises';
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

const readText = rel => readFile(path.join(ROOT, rel), 'utf8');

function cap(re, text, file, what) {
  const m = text.match(re);
  if (!m) throw new Error(`${what}: not found in ${file}`);
  return m[1];
}

const versions = {};
for (const rel of MODULES) {
  versions[rel] = cap(/^version = "([^"]+)"/m, await readText(rel), rel, 'version');
}
versions['image.mbt (facade)'] = cap(/pub let version : String = "([^"]+)"/, await readText('image.mbt'), 'image.mbt', 'facade version');
const zh = await readText('README.md');
const en = await readText('README.en.md');
versions['README.md version badge'] = cap(/version-([\d.]+)-orange/, zh, 'README.md', 'version badge');
versions['README.en.md version badge'] = cap(/version-([\d.]+)-orange/, en, 'README.en.md', 'version badge');
versions['README.md mooncakes badge'] = cap(/mooncakes-([\d.]+)-orange/, zh, 'README.md', 'mooncakes badge');
versions['README.en.md mooncakes badge'] = cap(/mooncakes-([\d.]+)-orange/, en, 'README.en.md', 'mooncakes badge');

const unique = [...new Set(Object.values(versions))];
if (unique.length !== 1) {
  console.error(JSON.stringify({ schema: 'version-gate@1', ok: false, versions }, null, 2));
  console.error(`版本不一致: ${unique.join(', ')}`);
  process.exit(1);
}
console.log(JSON.stringify({ schema: 'version-gate@1', ok: true, version: unique[0], checked: Object.keys(versions).length }, null, 2));