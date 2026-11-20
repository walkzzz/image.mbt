#!/usr/bin/env node
// check_coverage.mjs — 覆盖率门槛（解析 `moon coverage report -f summary` 的 Total 行）
//
// 用法：node scripts/check_coverage.mjs [coverage-summary.txt] [--min=77.5]
// 退出码：达标 0；未达标/解析失败 1。
// 口径：百分比 = 已覆盖可执行行 / 可执行行总数；阈值默认 77.5（2026-11-20 基线 77.9% = 30263/38846）。

import { readFile } from 'node:fs/promises';

const parse = text => {
  const m = text.match(/^Total:\s+(\d+)\/(\d+)\s*$/m);
  if (!m) throw new Error('未找到 `Total: <covered>/<total>` 行');
  const covered = Number(m[1]);
  const total = Number(m[2]);
  if (!(total > 0)) throw new Error(`total 非法: ${total}`);
  return { covered, total, percent: Number(((covered / total) * 100).toFixed(2)) };
};

async function main() {
  const args = process.argv.slice(2);
  const file = args.find(a => !a.startsWith('--')) ?? 'coverage-summary.txt';
  const minArg = args.find(a => a.startsWith('--min='));
  const min = minArg ? Number(minArg.split('=')[1]) : 77.5;
  const text = await readFile(file, 'utf8');
  const r = parse(text);
  const ok = r.percent >= min;
  console.log(JSON.stringify({ schema: 'coverage-gate@1', file, min, ...r, ok }, null, 2));
  if (!ok) {
    console.error(`覆盖率 ${r.percent}% 低于门槛 ${min}%（${r.covered}/${r.total}）`);
    process.exit(1);
  }
}

if (process.argv.includes('--self-test')) {
  const good = parse('x\nTotal: 30263/38846\n');
  const bad = parse('x\nTotal: 30000/38846\n');
  if (!(good.percent >= 77.5) || bad.percent >= 77.5) {
    console.error(`self-test failed: good=${good.percent} bad=${bad.percent}`);
    process.exit(1);
  }
  console.log(JSON.stringify({ schema: 'coverage-gate-selftest@1', good: good.percent, bad: bad.percent, ok: true }, null, 2));
} else {
  await main();
}