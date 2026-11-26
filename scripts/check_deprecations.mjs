#!/usr/bin/env node
// ============================================================================
// 弃用清单校验（S21）
//
// 用法：
//   node scripts/check_deprecations.mjs           # 校验（CI / 发布前）
//   node scripts/check_deprecations.mjs --json    # 机读输出
//
 // 真值方向：代码是事实，`docs/deprecation.md` 是登记表；两边必须一一对应。
//   * 代码里有 `#deprecated` 而表里没登记的符号 → 红灯（漏登记）
//   * 表里登记了而代码里已经没有的符号 → 红灯（该走 Removed 流程）
//   * 替换目标不一致（表里的 `<新符号>` 与 `#deprecated` 文案抽出的不一致）→ 红灯
//
// 排除目录：`.mooncakes/`（第三方依赖自带弃用）、`_build/`（构建产物）。
// 环境变量 ROOT 可覆盖仓库根（fixtures / CI 用）。
// ============================================================================

import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.env.ROOT
  ? resolve(process.env.ROOT)
  : resolve(dirname(fileURLToPath(import.meta.url)), '..');
const asJson = process.argv.includes('--json');

const SKIP_DIRS = new Set(['_build', '.git', '.mooncakes', 'node_modules', '.dart_tool']);

function walk(dir, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (SKIP_DIRS.has(entry.name)) continue;
    const p = join(dir, entry.name);
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.mbt')) out.push(p);
  }
  return out;
}

/** 从 `#deprecated("...")` 文案里抽替换目标。 */
function replacementOf(text) {
  const en = text.match(/Use\s+([A-Za-z_][A-Za-z0-9_]*)\s+instead/);
  if (en) return en[1];
  const zh = text.match(/请改用\s+([A-Za-z_][A-Za-z0-9_]*)/);
  if (zh) return zh[1];
  return null;
}

function scanCode() {
  const found = [];
  for (const file of walk(root)) {
    const lines = readFileSync(file, 'utf8').split('\n');
    lines.forEach((line, i) => {
      if (!line.includes('#deprecated(')) return;
      const decl = lines
        .slice(i + 1, i + 4)
        .map((s) => s.trim())
        .find((s) => s && !s.startsWith('///') && !s.startsWith('#'));
      if (!decl) return;
      const m = decl.match(/(?:pub\s+)?fn(?:\[[^\]]*\])?\s+([A-Za-z_][A-Za-z0-9_]*)/);
      if (!m) return;
      found.push({
        symbol: m[1],
        pkg: relative(root, file).split('\\').join('/').split('/').slice(0, 2).join('/'),
        replacement: replacementOf(line),
        file: relative(root, file).split('\\').join('/'),
        line: i + 1,
      });
    });
  }
  return found;
}

function parseTable() {
  const p = join(root, 'docs', 'deprecation.md');
  if (!existsSync(p)) return [];
  const rows = [];
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    if (!line.startsWith('| `')) continue;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    if (cells.length < 4) continue;
    const clean = (s) => s.replace(/`/g, '').trim();
    rows.push({
      symbol: clean(cells[0]),
      pkg: clean(cells[1]),
      replacement: clean(cells[2]),
    });
  }
  return rows;
}

const code = scanCode();
const table = parseTable();
const problems = [];

for (const c of code) {
  const row = table.find((t) => t.symbol === c.symbol && t.pkg === c.pkg);
  if (!row) problems.push(`未登记：${c.symbol}（${c.pkg}，${c.file}:${c.line}）`);
  else if (c.replacement && row.replacement !== c.replacement) {
    problems.push(`替换目标不一致：${c.symbol} 代码=${c.replacement} 表=${row.replacement}`);
  } else if (!c.replacement) {
    problems.push(`弃用文案缺替换目标：${c.symbol}（${c.file}:${c.line}）`);
  }
}
for (const t of table) {
  if (!code.some((c) => c.symbol === t.symbol && c.pkg === t.pkg)) {
    problems.push(`已移除但仍在表内：${t.symbol}（${t.pkg}）——走 Removed 流程并删表行`);
  }
}

const report = { ok: problems.length === 0, code: code.length, table: table.length, problems };
if (asJson) {
  console.log(JSON.stringify(report, null, 2));
} else if (report.ok) {
  console.log(`弃用清单一致：${code.length} 条（代码 == docs/deprecation.md）`);
} else {
  console.error(JSON.stringify(report, null, 2));
}
if (!report.ok) process.exit(1);
