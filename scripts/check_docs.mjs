#!/usr/bin/env node
// check_docs.mjs — 文档数字一致性自检（最小闭环 · flutter-ohos-expert 思想 ②⑥③）
//
// 为什么需要它：image 曾发生多处手抄漂移（badge 6526→6574→6580、proof 5→8、
// 双语 badge 不一致 zh=6_526 vs en=6_486、包数 71 vs 实际 72、image.mbt 版本 0.5.0 vs moon.mod 0.1.0）。
// 断言化根治：跨文档/跨语言/跨代码不一致，本脚本变红。
//
// 用法：node scripts/check_docs.mjs [--self-test]
// 退出码：全绿 0；任一断言失败 1。
// 三口径：①没跑过≠通过 ②分母不猜 ③每条断言的 evidence 可第三方复算（文件路径+取值）。

import { readFile, writeFile, mkdir, rm, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

function cap(re, text, file, what) {
  const m = text.match(re);
  if (!m) throw new Error(`${what}: not found in ${file}`);
  return m[1];
}

function capAll(re, text) {
  return [...text.matchAll(re)].map(m => m[1]);
}

async function read(rel, root) {
  return readFile(path.join(root, rel), 'utf8');
}

const norm = s => String(s).replace(/[_ ,]/g, '');

function uniqEqual(label, values) {
  const set = new Set(values.map(norm));
  if (set.size !== 1) {
    throw new Error(`${label} 不一致: ${values.map((v, i) => `${i}=${v}`).join(', ')}`);
  }
  return values[0];
}

async function countPackages(root) {
  const skip = new Set(['_build', '.git', '.mooncakes', 'node_modules', '.tmp-smoke', 'examples', 'playground']);
  let n = 0;
  async function walk(dir) {
    const entries = await readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      if (e.isDirectory()) {
        // benchmarks/gen 是维护用可执行包（生成基准样本），不计入库面口径
        const isTooling = e.name === 'gen' && path.basename(dir) === 'benchmarks';
        if (!skip.has(e.name) && !isTooling) await walk(path.join(dir, e.name));
      } else if (e.name === 'moon.pkg') {
        n++;
      }
    }
  }
  await walk(root);
  return n;
}

const ASSERTIONS = [
  {
    id: 'B1', desc: 'moon.mod version == image.mbt pub let version == README zh/en version badge == mooncakes badge',
    async run(root) {
      const mod = extractVersion(await read('moon.mod', root));
      const facade = cap(/pub let version : String = "([^"]+)"/, await read('image.mbt', root), 'image.mbt', 'facade version');
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const zhV = cap(/version-([\d.]+)-orange/, zh, 'README.md', 'zh version badge');
      const enV = cap(/version-([\d.]+)-orange/, en, 'README.en.md', 'en version badge');
      const zhM = cap(/mooncakes-([\d.]+)-orange/, zh, 'README.md', 'zh mooncakes badge');
      const enM = cap(/mooncakes-([\d.]+)-orange/, en, 'README.en.md', 'en mooncakes badge');
      uniqEqual('version', [mod, facade, zhV, enV, zhM, enM]);
      return { moon_mod: mod, facade, zh: zhV, en: enV };
    },
  },
  {
    id: 'B2', desc: 'CHANGELOG 最新条目 == moon.mod version',
    async run(root) {
      const mod = extractVersion(await read('moon.mod', root));
      const latest = cap(/^## \[([^\]]+)\]/m, await read('CHANGELOG.md', root), 'CHANGELOG.md', 'latest entry');
      if (mod !== latest) throw new Error(`CHANGELOG latest=${latest} != moon.mod=${mod}`);
      return { moon_mod: mod, changelog_latest: latest };
    },
  },
  {
    id: 'B3', desc: 'tests 数：zh/en badge == AGENTS == README 正文/目标表/构建命令（禁止 6574/6486/6526 回流）',
    async run(root) {
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const agents = await read('AGENTS.md', root);
      const zhT = cap(/tests-([\d_]+)×4/, zh, 'README.md', 'zh tests badge');
      const enT = cap(/tests-([\d_]+)×4/, en, 'README.en.md', 'en tests badge');
      const agentsN = cap(/(\d+) \(native\) × 4 目标/, agents, 'AGENTS.md', 'agents tests');
      const zhBody = capAll(/([\d,_]{4,})\s*测试/g, zh);
      const enBody = capAll(/([\d,_]{4,})\s*tests/gi, en);
      const zhRows = capAll(/\| ([\d,_]{4,}) \|/g, zh);
      const enRows = capAll(/\| ([\d,_]{4,}) \|/g, en);
      const zhCmd = cap(/（([\d,_]{4,}) × 4 目标）/, zh, 'README.md', 'zh command');
      const enCmd = cap(/\(([\d,_]{4,}) × 4 targets\)/, en, 'README.en.md', 'en command');
      uniqEqual('tests', [zhT, enT, agentsN, zhCmd, enCmd, ...zhBody, ...enBody, ...zhRows, ...enRows]);
      for (const stale of ['6486', '6526']) {
        if (zh.replace(/[_ ,]/g, '').includes(stale) || en.replace(/[_ ,]/g, '').includes(stale)) {
          throw new Error(`README 残留旧测试数 ${stale}`);
        }
      }
      return { zh: zhT, en: enT, agents: agentsN };
    },
  },
  {
    id: 'B4', desc: 'proof goals：zh/en badge == AGENTS == README 正文/对比表（禁止 5 goals 回流）',
    async run(root) {
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const agents = await read('AGENTS.md', root);
      const zhG = cap(/formal__proof-(\d+)%20goals/, zh, 'README.md', 'zh proof badge');
      const enG = cap(/formal__proof-(\d+)%20goals/, en, 'README.en.md', 'en proof badge');
      const agentsG = cap(/`moon prove` \*\*(\d+) goals proved\*\*/, agents, 'AGENTS.md', 'agents goals');
      const zhProved = capAll(/(\d+) goals proved/g, zh);
      const enProved = capAll(/(\d+) goals proved/g, en);
      const zhCompare = capAll(/moon prove: (\d+) goals/g, zh);
      const enCompare = capAll(/moon prove: (\d+) goals/g, en);
      uniqEqual('proof', [zhG, enG, agentsG, ...zhProved, ...enProved, ...zhCompare, ...enCompare]);
      if (/(\d) goals? proved, 溢出/.test(zh) && !zh.includes(`${zhG} goals proved, 溢出`)) {
        throw new Error('README 对比表 goals 与 badge 不一致');
      }
      return { zh: zhG, en: enG, agents: agentsG };
    },
  },
  {
    id: 'B5', desc: 'README zh/en 引用的 docs/*.md 全部存在（防死链）',
    async run(root) {
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const links = [
        ...[...zh.matchAll(/\]\((docs\/[\w.-]+\.md)\)/g)].map(m => m[1]),
        ...[...en.matchAll(/\]\((docs\/[\w.-]+\.md)\)/g)].map(m => m[1]),
      ];
      const missing = [...new Set(links)].filter(f => !existsSync(path.join(root, f)));
      if (missing.length) throw new Error(`missing docs: ${missing.join(', ')}`);
      return { checked: new Set(links).size, files: [...new Set(links)] };
    },
  },
  {
    id: 'B6', desc: 'packages 数：zh/en badge == README 子包标题 == docs/architecture.md == 实际库 moon.pkg 数（排除 examples/playground）',
    async run(root) {
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const arch = await read('docs/architecture.md', root);
      const zhP = cap(/packages-(\d+)-/, zh, 'README.md', 'zh packages badge');
      const enP = cap(/packages-(\d+)-/, en, 'README.en.md', 'en packages badge');
      const zhTitle = cap(/(\d+) 个子包/, zh, 'README.md', 'zh packages title');
      const archP = cap(/（\.mbti 口径，(\d+) 包）/, arch, 'docs/architecture.md', 'architecture packages');
      const actual = String(await countPackages(root));
      uniqEqual('packages', [zhP, enP, zhTitle, archP, actual]);
      return { zh: zhP, en: enP, architecture: archP, actual };
    },
  },
  {
    id: 'B7', desc: 'README/docs 无旧仓库链接（toadium/stb-image、walkzzz/image/ raw 链接）',
    async run(root) {
      const files = ['README.md', 'README.en.md', 'docs/architecture.md', 'docs/notes.md',
        'docs/examples.md', 'docs/contributing.md', 'docs/comparison.md', 'docs/proposal.md'];
      const bad = /toadium\/stb-image|toadium\/image|raw\.githubusercontent\.com\/walkzzz\/image\//;
      const hits = [];
      for (const f of files) {
        const p = path.join(root, f);
        if (!existsSync(p)) continue;
        const t = await read(f, root);
        if (bad.test(t)) hits.push(f);
      }
      if (hits.length) throw new Error(`旧仓库链接残留: ${hits.join(', ')}`);
      return { checked: files.length };
    },
  },
  {
    id: 'B8', desc: 'coverage badge zh/en 一致（single source）',
    async run(root) {
      const zh = await read('README.md', root);
      const en = await read('README.en.md', root);
      const zhC = cap(/coverage-([\d.]+)%25/, zh, 'README.md', 'zh coverage badge');
      const enC = cap(/coverage-([\d.]+)%25/, en, 'README.en.md', 'en coverage badge');
      if (zhC !== enC) throw new Error(`coverage zh=${zhC} en=${enC}`);
      return { coverage: zhC };
    },
  },
  {
    id: 'B9', desc: 'known-gaps 顶部当前口径（版本/测试数/包数/覆盖率）与 README/moon.mod 一致',
    async run(root) {
      const kg = await read('docs/known-gaps.md', root);
      const mod = extractVersion(await read('moon.mod', root));
      const zh = await read('README.md', root);
      const m = kg.match(/当前口径（[^）]*）：版本 ([\d.]+) · ([\d,_]+) 测试 × 4 目标 · (\d+) 包 · 覆盖率 ([\d.]+)%/);
      if (!m) throw new Error('known-gaps 顶部口径行未找到或格式不符');
      const tests = cap(/tests-([\d_]+)×4/, zh, 'README.md', 'zh tests badge');
      const pkgs = cap(/packages-(\d+)-/, zh, 'README.md', 'zh packages badge');
      const cov = cap(/coverage-([\d.]+)%25/, zh, 'README.md', 'zh coverage badge');
      uniqEqual('known-gaps 版本', [mod, m[1]]);
      uniqEqual('known-gaps 测试数', [tests, m[2]]);
      uniqEqual('known-gaps 包数', [pkgs, m[3]]);
      uniqEqual('known-gaps 覆盖率', [cov, m[4]]);
      return { version: m[1], tests: m[2], packages: m[3], coverage: m[4] };
    },
  },
  {
    id: 'B10', desc: '能力表真值：README AUTO 区块 == docs/capabilities.md == ImageFormat 枚举 + Codec trait（gen_capabilities --check）',
    async run(root) {
      const notes = path.join(root, 'docs', 'format_notes.json');
      if (!existsSync(notes)) return { skipped: 'fixtures/无 format_notes.json' };
      const r = spawnSync(process.execPath, [path.join(ROOT, 'scripts', 'gen_capabilities.mjs'), '--check'], {
        cwd: root,
        env: { ...process.env, ROOT: root },
        encoding: 'utf8',
      });
      if (r.status !== 0) {
        let detail = (r.stderr || '').trim();
        try {
          const j = JSON.parse(detail);
          detail = (j.problems || []).join('; ');
        } catch {}
        throw new Error(`能力表漂移: ${detail || 'gen_capabilities --check 失败'}`);
      }
      let j = {};
      try {
        j = JSON.parse((r.stdout || '').trim());
      } catch {}
      return { formats: j.formats, modules: j.modules, pub_fn: j.pub_fn, packages: j.packages };
    },
  },
];

function extractVersion(text) {
  const m = text.match(/^version = "([^"]+)"/m);
  if (!m) throw new Error('version not found in moon.mod');
  return m[1];
}

async function runAssertions(root) {
  const results = [];
  for (const a of ASSERTIONS) {
    try {
      const evidence = await a.run(root);
      results.push({ id: a.id, desc: a.desc, ok: true, evidence });
    } catch (e) {
      results.push({ id: a.id, desc: a.desc, ok: false, fail: String(e.message) });
    }
  }
  const failed = results.filter(r => !r.ok).length;
  return { schema: 'check_docs@2', root, total: results.length, failed, results };
}

async function selfTest() {
  const tmp = path.join(os.tmpdir(), `checkdocs-selftest-${Date.now()}`);
  await mkdir(path.join(tmp, 'docs'), { recursive: true });
  const out = [];
  const writeFixtures = async (version, tests, goals, packages) => {
    await writeFile(path.join(tmp, 'moon.mod'), `name = "walkzzz/image.mbt"\n\nversion = "${version}"\n`);
    await writeFile(path.join(tmp, 'image.mbt'), `pub let version : String = "${version}"\n`);
    await writeFile(path.join(tmp, 'moon.pkg'), '{}\n');
    const badge = `[![Version](https://img.shields.io/badge/version-${version}-orange)]()\n` +
      `[![mooncakes](https://img.shields.io/badge/mooncakes-${version}-orange)]()\n` +
      `[![Tests](https://img.shields.io/badge/tests-${tests}×4-green)]()\n` +
      `[![Proved](https://img.shields.io/badge/formal__proof-${goals}%20goals-purple)]()\n` +
      `[![Coverage](https://img.shields.io/badge/coverage-90.4%25-green)]()\n` +
      `[![Packages](https://img.shields.io/badge/packages-${packages}-purple)]()\n`;
    const body = `\n正文 ${tests} 测试 × 4 目标全绿。形式化验证 ${goals} goals proved。\n` +
      `| **native** | x | ${tests} | ok |\n| **wasm-gc** | x | ${tests} | ok |\n` +
      `| **js** | x | ${tests} | ok |\n| **wasm** | x | ${tests} | ok |\n` +
      `### ${packages} 个子包\n` +
      `| **形式化验证** | ❌ | ✅ (moon prove: ${goals} goals proved, 溢出安全) |\n` +
      `\`\`\`\n# 运行测试（${tests} × 4 目标）\n\`\`\`\n` +
      `| [docs/api.md](docs/api.md) | x |\n`;
    await writeFile(path.join(tmp, 'README.md'), badge + body);
    const enBody = body
      .replace(/运行测试（([\d,_]+) × 4 目标）/g, 'Run tests ($1 × 4 targets)')
      .replace(/测试/g, 'tests')
      .replace(/子包/g, 'packages');
    await writeFile(path.join(tmp, 'README.en.md'), badge + enBody);
    await writeFile(path.join(tmp, 'CHANGELOG.md'), `## [${version}] - 2026-11-13\n`);
    await writeFile(path.join(tmp, 'AGENTS.md'),
      `| 测试 | ${norm(tests)} (native) × 4 目标 |\n| 形式化验证 | core/safe_math \`moon prove\` **${goals} goals proved**（x） |\n`);
    await writeFile(path.join(tmp, 'docs', 'architecture.md'),
      `> 版本 ${version} | 3,748 公开函数 + 710 公开类型（.mbti 口径，${packages} 包）| ${tests} 测试 × 4 目标\n`);
    await writeFile(path.join(tmp, 'docs', 'api.md'), '# api\n');
    await writeFile(path.join(tmp, 'docs', 'known-gaps.md'),
      `# gaps\n\n> 当前口径（2026-11-20）：版本 ${version} · ${tests} 测试 × 4 目标 · ${packages} 包 · 覆盖率 90.4% = 1/1\n`);
    await writeFile(path.join(tmp, 'docs', 'contributing.md'), 'git clone git@github.com:walkzzz/image.mbt.git\n');
  };
  const assertFails = async (id, expectId) => {
    const r = await runAssertions(tmp);
    const hit = r.results.find(x => x.id === expectId);
    if (!hit || hit.ok !== false) throw new Error(`${id}: expected ${expectId} to FAIL, but it passed`);
    out.push(`${id}: OK (${expectId} failed: ${String(hit.fail).slice(0, 60)})`);
  };
  const assertPasses = async (id, ids) => {
    const r = await runAssertions(tmp);
    for (const want of ids) {
      const hit = r.results.find(x => x.id === want);
      if (!hit || !hit.ok) throw new Error(`${id}: expected ${want} to PASS (${hit && hit.fail})`);
      out.push(`${id}: OK (${want} passed)`);
    }
  };
  try {
    // 负向 1：双语 tests badge 不一致
    await writeFixtures('0.1.0', '6_580', '8', '1');
    await writeFile(path.join(tmp, 'README.en.md'),
      (await readFile(path.join(tmp, 'README.en.md'), 'utf8')).replace('tests-6_580×4', 'tests-6_574×4'));
    await assertFails('ST1', 'B3');
    // 负向 2：proof badge 漂移（5 vs 8）
    await writeFixtures('0.1.0', '6_580', '8', '1');
    await writeFile(path.join(tmp, 'README.md'),
      (await readFile(path.join(tmp, 'README.md'), 'utf8')).replace('formal__proof-8%20goals', 'formal__proof-5%20goals'));
    await assertFails('ST2', 'B4');
    // 负向 3：image.mbt 版本与 moon.mod 分离
    await writeFixtures('0.1.0', '6_580', '8', '1');
    await writeFile(path.join(tmp, 'image.mbt'), 'pub let version : String = "0.5.0"\n');
    await assertFails('ST3', 'B1');
    // 负向 4：包数 badge 与实际 moon.pkg 不符
    await writeFixtures('0.1.0', '6_580', '8', '71');
    await assertFails('ST4', 'B6');
    // 负向 5：旧仓库链接
    await writeFixtures('0.1.0', '6_580', '8', '1');
    await writeFile(path.join(tmp, 'docs', 'contributing.md'), 'git clone git@github.com:toadium/stb-image.git\n');
    await assertFails('ST5', 'B7');
    // 正向：全一致
    await writeFixtures('0.1.0', '6_580', '8', '1');
    await assertPasses('ST6', ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B9']);
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
  return { schema: 'check_docs-selftest@2', assertions: out };
}

const selftest = process.argv.includes('--self-test');
if (selftest) {
  const r = await selfTest().catch(e => { console.error(String(e.message)); process.exit(1); });
  console.log(JSON.stringify(r, null, 2));
  process.exit(0);
} else {
  runAssertions(ROOT).then(r => {
    console.log(JSON.stringify(r, null, 2));
    process.exit(r.failed === 0 ? 0 : 1);
  });
}