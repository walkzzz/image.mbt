#!/usr/bin/env node
// mutation_test.mjs — 变异测试最小闭环（3 个高价值包 / 7 个变异点）
//
// 原理：逐个注入语义变异 → 运行该包测试 → 测试失败即 KILLED（测试能发现变异）；
//       全部通过即 SURVIVED（测试盲区）。恢复原文件后输出报告。
// 用法：node scripts/mutation_test.mjs [--min-kill=80] [--dry-run]
// 退出码：达标（killRate >= min）0；未达标/基线不绿 1。

import { readFile, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

const MUTANTS = [
  {
    id: 'M01', pkg: 'walkzzz/image.core/types', file: 'image.core/types/image_types.mbt',
    find: 'if width <= 0 || height <= 0 || channels <= 0 {',
    replace: 'if width < 0 || height <= 0 || channels <= 0 {',
    desc: 'check_dims 漏检零宽',
  },
  {
    id: 'M02', pkg: 'walkzzz/image.core/types', file: 'image.core/types/image_types.mbt',
    find: 'if width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION {',
    replace: 'if width >= MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION {',
    desc: 'check_dims 边界 65535 误拒',
  },
  {
    id: 'M03', pkg: 'walkzzz/image.core/types', file: 'image.core/types/image_types.mbt',
    find: '|| channels <= 0 {',
    replace: '|| channels < 0 {',
    desc: 'check_dims 漏检零通道',
  },
  {
    id: 'M04', pkg: 'walkzzz/image.codec/util', file: 'image.codec/util/resize.mbt',
    find: 'if out_w <= 0 || out_h <= 0 {',
    replace: 'if out_w < 0 || out_h <= 0 {',
    desc: 'resize 漏检零宽输出',
  },
  {
    id: 'M05', pkg: 'walkzzz/image.codec/util', file: 'image.codec/util/resize.mbt',
    find: 'sx_xi[dx] = (sx + 0.5F).to_int().clamp(min=0, max=w_minus_1)',
    replace: 'sx_xi[dx] = sx.to_int().clamp(min=0, max=w_minus_1)',
    desc: 'resize 最近邻 x 取整偏移',
  },
  {
    id: 'M06', pkg: 'walkzzz/image.process/segment', file: 'image.process/segment/segmentation.mbt',
    find: 'if variance > max_variance {',
    replace: 'if variance < max_variance {',
    desc: 'threshold_otsu 方差比较反转',
  },
  {
    id: 'M07', pkg: 'walkzzz/image.process/segment', file: 'image.process/segment/advanced_segmentation.mbt',
    find: '  if img.channels < 1 || img.channels > 4 {\n    raise @types.LoadError::DecodeFailed(\n      "otsu_threshold_value: 通道数必须在1-4之间",',
    replace: '  if img.channels < 1 || img.channels > 5 {\n    raise @types.LoadError::DecodeFailed(\n      "otsu_threshold_value: 通道数必须在1-4之间",',
    desc: 'otsu_threshold_value 通道上限放宽',
  },
];

function runTests(pkg) {
  try {
    const out = execFileSync('moon', ['test', '--target', 'native', '-p', pkg], {
      cwd: ROOT, encoding: 'utf8', timeout: 300_000, stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { ok: true, out };
  } catch (e) {
    return { ok: false, out: `${e.stdout ?? ''}\n${e.stderr ?? ''}`, status: e.status };
  }
}

const failedTests = out => {
  const m = out.match(/failed:\s*(\d+)/);
  return m ? Number(m[1]) : 0;
};

async function main() {
  const args = process.argv.slice(2);
  const dry = args.includes('--dry-run');
  const minArg = args.find(a => a.startsWith('--min-kill='));
  const min = minArg ? Number(minArg.split('=')[1]) : 80;

  if (dry) {
    for (const m of MUTANTS) console.log(`${m.id} ${m.pkg} — ${m.desc}`);
    return;
  }

  // 基线：每个包必须先全绿
  const pkgs = [...new Set(MUTANTS.map(m => m.pkg))];
  for (const pkg of pkgs) {
    const r = runTests(pkg);
    if (!r.ok) throw new Error(`基线不绿，拒绝变异（${pkg}）: ${r.out.slice(-300)}`);
    console.log(`baseline OK: ${pkg}`);
  }

  const results = [];
  for (const m of MUTANTS) {
    const p = path.join(ROOT, m.file);
    const original = await readFile(p, 'utf8');
    const n = original.split(m.find).length - 1;
    if (n !== 1) {
      results.push({ id: m.id, desc: m.desc, pkg: m.pkg, verdict: 'SKIPPED', reason: `变异点出现 ${n} 次` });
      continue;
    }
    let verdict = 'SURVIVED', detail = '测试全部通过（盲区）';
    try {
      await writeFile(p, original.replace(m.find, m.replace), 'utf8');
      const r = runTests(m.pkg);
      if (!r.ok) {
        verdict = 'KILLED';
        const f = failedTests(r.out);
        detail = f > 0 ? `测试失败 ${f} 个` : '编译/运行失败';
      }
    } finally {
      await writeFile(p, original, 'utf8');
      const restored = await readFile(p, 'utf8');
      if (restored !== original) throw new Error(`恢复失败: ${m.file}`);
    }
    results.push({ id: m.id, desc: m.desc, pkg: m.pkg, verdict, detail });
    console.log(`${m.id} ${verdict} — ${m.desc}`);
  }

  const total = results.length;
  const killed = results.filter(r => r.verdict === 'KILLED').length;
  const skipped = results.filter(r => r.verdict === 'SKIPPED').length;
  const killRate = total ? Number(((killed / total) * 100).toFixed(1)) : 0;
  const report = { schema: 'mutation-report@1', date: new Date().toISOString().slice(0, 10), total, killed, skipped, killRate, min, ok: killRate >= min, results };
  await writeFile(path.join(ROOT, 'mutation-report.json'), JSON.stringify(report, null, 2) + '\n', 'utf8');
  console.log(JSON.stringify({ total, killed, skipped, killRate, min, ok: report.ok }));
  if (!report.ok) process.exit(1);
}

await main().catch(e => { console.error(String(e.message)); process.exit(1); });