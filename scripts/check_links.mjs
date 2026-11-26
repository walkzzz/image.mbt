#!/usr/bin/env node
// ============================================================================
// 文档链接与文档表治理（S21）
//
// 用法：
//   node scripts/check_links.mjs           # 校验（CI / 发布前）
//   node scripts/check_links.mjs --json    # 机读输出
//
// 三件事：
//   1. 相对链接可达：`](path)` / `](../path)` 解析到仓库内真实文件（忽略 http(s)、mailto、纯锚点）。
//   2. README 文档表完整：docs/*.md 每个都要在 README.md 的文档表里出现（内部历史快照除外）。
//   3. 子模块 README 齐备：11 个模块都有 README.md（场景模块允许由 docs/scenes.md 兜底的短版）。
//
// 排除：_build/、.mooncakes/、node_modules/、.git/。
// 环境变量 ROOT 可覆盖仓库根（fixtures / CI 用）。
// ============================================================================

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.env.ROOT
  ? resolve(process.env.ROOT)
  : resolve(dirname(fileURLToPath(import.meta.url)), '..');
const asJson = process.argv.includes('--json');

const SKIP_DIRS = new Set(['_build', '.git', '.mooncakes', 'node_modules', '.dart_tool', '.arts']);

/** 收集参与治理的 markdown 文件（根 + docs + 子模块）。 */
function collect() {
  const files = [];
  const pushIfMd = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) continue;
      if (entry.name.endsWith('.md')) files.push(join(dir, entry.name));
    }
  };
  pushIfMd(root);
  if (existsSync(join(root, 'docs'))) pushIfMd(join(root, 'docs'));
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (SKIP_DIRS.has(entry.name)) continue;
    if (!entry.name.startsWith('image.')) continue;
    const readme = join(root, entry.name, 'README.md');
    if (existsSync(readme)) files.push(readme);
  }
  return files;
}

/** 抽 `](target)` 里的相对路径，过滤外链与纯锚点。 */
function linksIn(text) {
  const out = [];
  for (const m of text.matchAll(/\]\(([^)\s]+)\)/g)) {
    const target = m[1];
    if (/^(https?:|mailto:|tel:)/i.test(target)) continue;
    if (target.startsWith('#')) continue;
    out.push(target);
  }
  return out;
}

const problems = [];
const files = collect();
let linkCount = 0;

for (const file of files) {
  const rel = relative(root, file).split('\\').join('/');
  const text = readFileSync(file, 'utf8');
  for (const target of linksIn(text)) {
    const clean = decodeURIComponent(target.split('#')[0].split('?')[0]).trim();
    if (!clean) continue;
    linkCount += 1;
    const abs = resolve(dirname(file), clean);
    if (existsSync(abs)) continue;
    // 允许指向目录（README 里偶尔写 `docs/`）
    if (clean.endsWith('/') && existsSync(abs)) continue;
    problems.push(`链接失效 ${rel} → ${target}`);
  }
}

// 2) README 文档表完整性
const readme = readFileSync(join(root, 'README.md'), 'utf8');
const tableTargets = new Set(linksIn(readme));
const docsFiles = existsSync(join(root, 'docs'))
  ? readdirSync(join(root, 'docs'), { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith('.md'))
      .map((e) => `docs/${e.name}`)
  : [];
// 内部/历史快照不要求进表（体量过大或纯归档）
const INTERNAL = new Set(['docs/changelog.md', 'docs/roadmap-history.md', 'docs/api_reference.md']);
for (const f of docsFiles) {
  if (INTERNAL.has(f)) continue;
  if (tableTargets.has(f) || tableTargets.has(`./${f}`)) continue;
  problems.push(`README 文档表缺行：${f}`);
}

// 3) 子模块 README 齐备
for (const mod of [
  'image.core',
  'image.codec',
  'image.process',
  'image.photography',
  'image.vision',
  'image.domain',
  'image.doc',
  'image.media',
  'image.commerce',
  'image.pro',
]) {
  if (!existsSync(join(root, mod, 'README.md'))) problems.push(`子模块缺 README：${mod}/README.md`);
}

const report = {
  ok: problems.length === 0,
  files: files.length,
  links: linkCount,
  docs: docsFiles.length,
  problems,
};
if (asJson) console.log(JSON.stringify(report, null, 2));
else if (report.ok) console.log(`文档链接与文档表一致：${files.length} 个 md / ${linkCount} 条链接 / ${docsFiles.length} 篇 docs`);
else console.error(JSON.stringify(report, null, 2));
if (!report.ok) process.exit(1);
