#!/usr/bin/env node
// ============================================================================
// 收口核对（S21）：一条命令跑完 docs/release.md §九 的门禁清单
//
// 用法：
//   node scripts/check_release_ready.mjs               # 全量（含慢项，约 10 分钟）
//   node scripts/check_release_ready.mjs --skip-slow   # 跳过 moon test / check / pages 构建（约 1 分钟）
//   node scripts/check_release_ready.mjs --json        # 机读输出
//
// 每条都是"真跑"，不读缓存、不看历史结论。任一条失败 → 退出码 1，并打印该步骤输出尾部。
//
// 为什么需要它：发布是 11 环、13 条门禁，靠人记顺序必然漏。脚本是唯一顺序真值，
// 发布前把它跑绿，再按 docs/release.md §9.2 的顺序 `moon publish`。
// ============================================================================

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.env.ROOT
  ? resolve(process.env.ROOT)
  : resolve(dirname(fileURLToPath(import.meta.url)), '..');
const skipSlow = process.argv.includes('--skip-slow');
const asJson = process.argv.includes('--json');

const exeName = process.platform === 'win32' ? 'imgtool.exe' : 'imgtool';
const imgtool = join(root, '_build', 'native', 'release', 'build', 'walkzzz', 'image.mbt', 'cmd', 'imgtool', exeName);
const ink = (s) => process.stdout.write(s);

const steps = [
  { id: 'version', what: '11 个 moon.mod / 门面 / CLI / playground / 页面 / 徽章 版本一致', cmd: ['node', 'scripts/check_version.mjs'], slow: false },
  { id: 'docs', what: '文档真值 B1–B14（含场景、能力、弃用、链接）', cmd: ['node', 'scripts/check_docs.mjs'], slow: false },
  { id: 'api_index', what: 'API 索引无漂移', cmd: ['node', 'scripts/gen_api_index.mjs', '--check'], slow: false },
  { id: 'capabilities', what: '能力矩阵无漂移', cmd: ['node', 'scripts/gen_capabilities.mjs', '--check'], slow: false },
  { id: 'scenes', what: '4 个场景入口无漂移', cmd: ['node', 'scripts/gen_scenes.mjs', '--check'], slow: false },
  { id: 'imports', what: 'moon.pkg 零冗余导入', cmd: ['node', 'scripts/check_pkg_imports.mjs'], slow: false },
  { id: 'deprecations', what: '弃用清单 ⇄ 代码一致', cmd: ['node', 'scripts/check_deprecations.mjs', '--json'], slow: false },
  { id: 'links', what: '相对链接 / README 文档表 / 子模块 README', cmd: ['node', 'scripts/check_links.mjs', '--json'], slow: false },
  { id: 'pages_numbers', what: 'Pages 首页数字 = README + coverage.json', cmd: ['node', 'scripts/sync_pages.mjs', '--check'], slow: false },
  { id: 'npm', what: 'JS 绑定 15 项', cmd: ['node', 'npm/test.mjs'], slow: false },
  {
    id: 'dart',
    what: 'Dart 绑定 6 项（decode→resize→encode）',
    cmd: ['node', 'scripts/check_dart_binding.mjs', '--no-build'],
    slow: false,
    skipIf: () => !existsSync(imgtool),
    skipReason: 'imgtool 未构建（先 moon build --release cmd/imgtool）',
  },
  { id: 'fmt', what: 'moon fmt --check', cmd: ['moon', 'fmt', '--check'], slow: false },
  { id: 'check', what: 'moon check --deny-warn --target all（四目标零警告）', cmd: ['moon', 'check', '--deny-warn', '--target', 'all'], slow: true },
  { id: 'test', what: 'moon test --target native（7,395）', cmd: ['moon', 'test', '--target', 'native'], slow: true },
  { id: 'pages', what: 'Pages 展示页 49 项（构建 playground js）', cmd: ['node', 'scripts/check_pages.mjs'], slow: true },
];

function runStep(step) {
  if (step.skipIf?.()) {
    return { id: step.id, ok: true, skipped: step.skipReason, ms: 0 };
  }
  const started = Date.now();
  const r = spawnSync(step.cmd[0], step.cmd.slice(1), {
    cwd: root,
    encoding: 'utf8',
    shell: process.platform === 'win32' && step.cmd[0] !== 'node',
  });
  const ms = Date.now() - started;
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  const ok = r.status === 0;
  return { id: step.id, ok, ms, tail: ok ? '' : out.trim().split('\n').slice(-12).join('\n') };
}

const results = [];
for (const step of steps) {
  if (skipSlow && step.slow) {
    results.push({ id: step.id, ok: true, skipped: '--skip-slow', ms: 0 });
    continue;
  }
  if (!asJson) ink(`… ${step.id.padEnd(14)} ${step.what}\n`);
  const r = runStep(step);
  results.push(r);
  if (!asJson) {
    const tag = r.skipped ? 'skip' : r.ok ? 'ok  ' : 'FAIL';
    ink(`  ${tag} ${step.id}  ${(r.ms / 1000).toFixed(1)}s${r.skipped ? `  (${r.skipped})` : ''}\n`);
    if (!r.ok && r.tail) ink(`${r.tail}\n`);
  }
}

const failed = results.filter((r) => !r.ok);
const skipped = results.filter((r) => r.skipped);
const report = {
  schema: 'release-ready@1',
  ok: failed.length === 0,
  ran: results.length - skipped.length,
  skipped: skipped.map((r) => `${r.id}: ${r.skipped}`),
  failed: failed.map((r) => r.id),
  seconds: Math.round(results.reduce((a, r) => a + r.ms, 0) / 1000),
};
if (asJson) {
  console.log(JSON.stringify(report, null, 2));
} else {
  ink(
    `\n=== release-ready: ${report.ok ? 'PASS' : `FAIL (${failed.length})`} · ${report.ran} 项执行` +
      `${skipped.length ? ` · ${skipped.length} 项跳过` : ''} · ${report.seconds}s ===\n`,
  );
}
if (!report.ok) process.exit(1);
