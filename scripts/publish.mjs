#!/usr/bin/env node
// publish.mjs — 11 环发布流水线（门禁 → 逐环 dry-run / publish → 汇总）
//
// 为什么要有这个脚本：`moon publish` 必须按依赖顺序一环一环发，任一环落后一版，下游编译就会撞
// API 缺失。手工敲 11 次命令容易漏环、漏 `moon update`、漏掉失败后的续发位置。这里把顺序、
// 版本读取、dry-run 预检、中断续发、失败诊断全部固化，发布动作本身仍由维护者亲自执行。
//
// 用法（默认 dry-run，不写 registry）：
//   node scripts/publish.mjs                     # 全 11 环 dry-run 预检（202/409 判定）
//   node scripts/publish.mjs --exec               # 真发（逐环 moon publish，需已 moon login）
//   node scripts/publish.mjs --from=image.codec   # 从指定环开始（中断后续发）
//   node scripts/publish.mjs --only=image.core,image.codec
//   node scripts/publish.mjs --skip-gates         # 跳过 check_release_ready（不建议）
//   node scripts/publish.mjs --help
//
// 退出码：全部成功 0；任一环失败 2（打印该环手动命令与失败分类）；前置门禁失败 3。

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const IS_WIN = process.platform === 'win32';

// 依赖顺序：前 6 环原子模块有单向依赖；4 个场景入口只依赖原子模块（此处仍排在根之前）；
// 根模块依赖全部 10 环，必须最后发。
const MODULES = [
  { width: 20, id: 'image.core', mod: 'image.core/moon.mod', label: 'walkzzz/image.core' },
  { width: 20, id: 'image.codec', mod: 'image.codec/moon.mod', label: 'walkzzz/image.codec' },
  { width: 20, id: 'image.process', mod: 'image.process/moon.mod', label: 'walkzzz/image.process' },
  { width: 20, id: 'image.photography', mod: 'image.photography/moon.mod', label: 'walkzzz/image.photography' },
  { width: 20, id: 'image.vision', mod: 'image.vision/moon.mod', label: 'walkzzz/image.vision' },
  { width: 20, id: 'image.domain', mod: 'image.domain/moon.mod', label: 'walkzzz/image.domain' },
  { width: 20, id: 'image.doc', mod: 'image.doc/moon.mod', label: 'walkzzz/image.doc' },
  { width: 20, id: 'image.media', mod: 'image.media/moon.mod', label: 'walkzzz/image.media' },
  { width: 20, id: 'image.commerce', mod: 'image.commerce/moon.mod', label: 'walkzzz/image.commerce' },
  { width: 20, id: 'image.pro', mod: 'image.pro/moon.mod', label: 'walkzzz/image.pro' },
  { width: 20, id: '.', mod: 'moon.mod', label: 'walkzzz/image.mbt（根）' },
];

function parseArgs(argv) {
  const opts = { exec: false, skipGates: false, from: null, only: null, help: false };
  for (const a of argv) {
    if (a === '--exec' || a === '--publish') opts.exec = true;
    else if (a === '--dry-run') opts.exec = false;
    else if (a === '--skip-gates') opts.skipGates = true;
    else if (a === '--help' || a === '-h') opts.help = true;
    else if (a.startsWith('--from=')) opts.from = a.slice('--from='.length).trim();
    else if (a.startsWith('--only=')) opts.only = a.slice('--only='.length).split(',').map((s) => s.trim()).filter(Boolean);
    else throw new Error(`未知参数: ${a}（--help 查看用法）`);
  }
  return opts;
}

function usage() {
  console.log(`publish.mjs — 11 环发布流水线

  node scripts/publish.mjs                     全部 11 环 dry-run（默认，不写 registry）
  node scripts/publish.mjs --exec               全部 11 环正式发布（需 moon login）
  node scripts/publish.mjs --from=image.codec   从该环开始（中断续发）
  node scripts/publish.mjs --only=image.core,image.codec
  node scripts/publish.mjs --skip-gates         跳过 check_release_ready

环顺序（不可打乱）：core → codec → process → photography → vision → domain
                  → doc → media → commerce → pro → 根`);
}

async function readVersion(rel) {
  const p = path.join(ROOT, rel);
  if (!existsSync(p)) throw new Error(`缺少 ${rel}`);
  const text = await readFile(p, 'utf8');
  const m = text.match(/^version\s*=\s*"([^"]+)"/m);
  if (!m) throw new Error(`${rel} 里找不到 version`);
  return m[1];
}

// moon 的退出码语义：0 成功；非 0 时输出里区分「版本已存在（409）」「校验失败（202）」「认证失败」。
function classify(out) {
  if (/409|already exists|Conflict/i.test(out)) return '409 版本已占用（该环需先 bump_version 或改用新 patch 号）';
  if (/401|403|Unauthorized|not logged in|token/i.test(out)) return '认证失败（先 moon login，或检查 ~/.moon/credentials.json）';
  if (/error|failed|invalid/i.test(out)) return '编译/校验失败（解包后在空目录按 registry 依赖重编不过，通常是依赖钉落后一版）';
  return '未知失败（看上面的完整输出）';
}

function run(cmd, args, cwd) {
  // stdin 交给子进程（moon publish 需要交互确认 / token），stdout/stderr 转发的同时留一份供失败分类
  const r = spawnSync(cmd, args, { cwd, stdio: ['inherit', 'pipe', 'pipe'], encoding: 'utf8', shell: IS_WIN });
  const out = `${r.stdout || ''}${r.stderr || ''}`;
  if (out) process.stdout.write(out);
  return { ok: r.status === 0, out };
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (e) {
    console.error(`✗ ${e.message}`);
    process.exit(2);
  }
  if (opts.help) return usage();

  // 只保留实际要发的环
  let plan = MODULES.slice();
  if (opts.from) {
    const idx = plan.findIndex((m) => m.id === opts.from);
    if (idx < 0) {
      console.error(`✗ --from 不认识 "${opts.from}"（可选：${plan.map((m) => m.id).join(' / ')}）`);
      process.exit(2);
    }
    plan = plan.slice(idx);
  }
  if (opts.only) {
    const ids = new Set(opts.only);
    const missing = [...ids].filter((id) => !MODULES.some((m) => m.id === id));
    if (missing.length) {
      console.error(`✗ --only 不认识: ${missing.join(', ')}`);
      process.exit(2);
    }
    plan = MODULES.filter((m) => ids.has(m.id));
  }

  // 版本读取：11 环必须同号，否则先跑 bump_version
  const versions = {};
  for (const m of MODULES) versions[m.id] = await readVersion(m.mod);
  const uniq = new Set(Object.values(versions));
  if (uniq.size !== 1) {
    console.error('✗ 11 环版本不一致：');
    for (const m of MODULES) console.error(`   ${m.label.padEnd(30)} ${versions[m.id]}`);
    console.error('   先跑 node scripts/bump_version.mjs <version> 再发布');
    process.exit(2);
  }
  const version = [...uniq][0];

  console.log(`发布流水线 · 版本 ${version} · 模式 ${opts.exec ? 'PUBLISH（写 registry，不可逆）' : 'DRY-RUN（不写 registry）'}`);
  console.log(`本次计划 ${plan.length} 环：${plan.map((m) => m.id).join(' → ')}`);
  if (opts.exec) {
    console.log('注意：moon publish 不可撤销；版本号一旦占用无法删除，只可升号。Ctrl-C 可中止，已发的环保留。');
  }

  // 前置门禁：默认跑快跑档；--exec 时改跑全量档（含 moon test / pages 构建）
  if (!opts.skipGates) {
    console.log('\n== 前置门禁 ==');
    const args = opts.exec ? ['scripts/check_release_ready.mjs'] : ['scripts/check_release_ready.mjs', '--skip-slow'];
    const gate = run('node', args, ROOT);
    if (!gate.ok) {
      console.error('✗ 前置门禁未通过，发布中止（确认要跳过的用 --skip-gates，不建议）');
      process.exit(3);
    }
  } else {
    console.log('\n== 前置门禁（已按 --skip-gates 跳过）==');
  }

  // 逐环发布
  const results = [];
  const started = Date.now();
  for (let i = 0; i < plan.length; i++) {
    const m = plan[i];
    const cwd = m.id === '.' ? ROOT : path.join(ROOT, m.id);
    const head = `\n[${i + 1}/${plan.length}] ${m.label} ${versions[m.id]}`;
    console.log(head);
    const t0 = Date.now();
    const ok = opts.exec ? run('moon', ['publish'], cwd) : run('moon', ['publish', '--dry-run'], cwd);
    const ms = Date.now() - t0;
    results.push({ ...m, version: versions[m.id], ok: ok.ok, ms });
    if (!ok.ok) {
      console.error(`\n✗ ${m.label} 失败：${classify(ok.out)}`);
      console.error(`  手动重试：cd ${m.id === '.' ? '仓库根' : m.id}; moon publish --dry-run`);
      console.error(`  续发：node scripts/publish.mjs ${opts.exec ? '--exec ' : ''}--from=${m.id} --skip-gates`);
      break;
    }
    // 每发完一环刷新本工作区对 registry 的依赖视图，下一环的 dry-run 才看得到新版本
    if (opts.exec) {
      console.log('  → moon update（刷新 registry 依赖）');
      const up = run('moon', ['update'], ROOT);
      if (!up.ok) console.log('  ! moon update 非零退出（不影响已完成的发布，继续下一环）');
    }
  }

  // 汇总
  const total = Date.now() - started;
  console.log('\n== 汇总 ==');
  console.log('环'.padEnd(28) + '版本'.padEnd(10) + '结果'.padEnd(8) + '耗时');
  for (const r of results) {
    console.log(`${r.label.padEnd(26)}${r.version.padEnd(9)}${(r.ok ? 'ok' : 'FAIL').padEnd(8)}${(r.ms / 1000).toFixed(1)}s`);
  }
  const failed = results.filter((r) => !r.ok).length;
  const skipped = plan.length - results.length;
  console.log(`\n${failed === 0 && skipped === 0 ? '✓' : '✗'} ${results.length - failed}/${plan.length} 环完成 · 共 ${(total / 60000).toFixed(1)} 分钟`);
  if (failed === 0 && skipped === 0 && !opts.exec) {
    console.log('dry-run 全绿：可以执行 node scripts/publish.mjs --exec 正式发布');
  }
  process.exit(failed === 0 && skipped === 0 ? 0 : 2);
}

main().catch((e) => {
  console.error(`✗ ${e.stack || e.message}`);
  process.exit(2);
});
