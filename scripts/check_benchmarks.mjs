#!/usr/bin/env node
// ============================================================================
// 公开基准集校验器（S20）
//
// 用法：
//   node scripts/check_benchmarks.mjs            # 校验（CI / 发布前）
//   node scripts/check_benchmarks.mjs --update   # 依据当前样本重建 manifest（需先构建 imgtool）
//   node scripts/check_benchmarks.mjs --regen    # 重跑 benchmarks/gen，比对「磁盘 ↔ 当前生成器产出」（GAP-53）
//
// 契约（manifest 即契约，校验方不手写期望值）：
//   1. golden 26 张，文件名 `gNN_<内容>_<W>x<H>.<ext>`，尺寸必须与文件名一致；
//   2. malformed 8 个，文件名 `mN_<类别>.<ext>`，必须在预算时间内被拒绝（exit≠0 + ok:false），
//      且不得出现 panic；
//   3. 每张样本 sha256 / 字节数必须与 manifest 完全一致（漂移即红灯）；
//   4. 总体积与单文件体积有上限，防止样本集悄悄膨胀；
//   5. magic bytes 与 imgtool 报出的 format 必须一致（探测层与解码层不许各说各话）。
//
// 环境变量：
//   ROOT           仓库根（默认脚本上一级）——self-test 夹具用
//   IMGTOOL        imgtool 可执行路径（默认 _build/native/release/.../imgtool.exe）
//   BENCH_TIMEOUT  单个样本解码超时毫秒（默认 5000）
// ============================================================================

import { createHash } from 'node:crypto';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
  statSync,
} from 'node:fs';
import { resolveImgtool } from './imgtool_path.mjs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = resolve(process.env.ROOT || join(import.meta.dirname, '..'));
const GOLDEN_DIR = join(ROOT, 'benchmarks', 'golden');
const MALFORMED_DIR = join(ROOT, 'benchmarks', 'malformed');
const MANIFEST_PATH = join(ROOT, 'benchmarks', 'manifest.json');
const IMGTOOL = resolveImgtool(ROOT);
const TIMEOUT_MS = Number(process.env.BENCH_TIMEOUT || 5000);

const LIMITS = {
  golden_count: 26,
  malformed_count: 8,
  file_bytes: 400 * 1024,
  total_bytes: 1600 * 1024,
};

// 不由 `benchmarks/gen` 产出的 golden：MoonBit 编码器只出 baseline JPEG（roadmap F-01），
// progressive / progressive+RST 样本改由 Python 脚本生成，`--regen` 比对时跳过并与 manifest 的
// `generator` 字段互校（漏标即红灯）。
const EXTERNAL_GENERATORS = {
  'g25_jpeg_progressive_640x400.jpg': 'scripts/gen_progressive_samples.py',
  'g26_jpeg_progressive_restart_480x320.jpg': 'scripts/gen_progressive_samples.py',
};
const DEFAULT_GENERATOR = 'benchmarks/gen';

const fails = [];
const fail = (what, detail) => fails.push({ what, detail });

// ---------------------------------------------------------------- 工具函数
const sha256 = (buf) => createHash('sha256').update(buf).digest('hex');
const listDir = (dir) => (existsSync(dir) ? readdirSync(dir).filter((f) => !f.startsWith('.')).sort() : []);
const mtimeStable = (name) => name.replace(/\\/g, '/');

function imgtool(args) {
  if (!existsSync(IMGTOOL)) {
    fail('imgtool', `未找到 ${IMGTOOL}，先跑 moon build --release cmd/imgtool`);
    return null;
  }
  const r = spawnSync(IMGTOOL, args, { encoding: 'utf8', timeout: TIMEOUT_MS, windowsHide: true });
  const out = `${r.stdout || ''}${r.stderr || ''}`.trim();
  return { status: r.status, signal: r.signal, out, timedOut: Boolean(r.error && r.error.code === 'ETIMEDOUT') };
}

// 每行一个 JSON 对象的输出契约：取最后一条可解析的 JSON
function lastJson(text) {
  for (const line of text.split(/\r?\n/).reverse()) {
    const t = line.trim();
    if (t.startsWith('{') && t.endsWith('}')) {
      try {
        return JSON.parse(t);
      } catch {
        /* 继续往上找 */
      }
    }
  }
  return null;
}

// magic bytes → 期望格式（只做「字节层」独立复核，不信任文件名）
function sniff(buf) {
  const hex = (i) => buf[i];
  if (buf.length >= 8 && buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) return 'png';
  if (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xd8) return 'jpeg';
  if (buf.length >= 2 && buf[0] === 0x42 && buf[1] === 0x4d) return 'bmp';
  if (buf.length >= 6 && buf[0] === 0x47 && buf[1] === 0x49 && buf[2] === 0x46) return 'gif';
  if (buf.length >= 12 && buf[0] === 0x52 && buf[1] === 0x49 && buf[8] === 0x57 && buf[9] === 0x45) return 'webp';
  if (buf.length >= 4 && buf[0] === 0x71 && buf[1] === 0x6f && buf[2] === 0x69 && buf[3] === 0x66) return 'qoi';
  if (buf.length >= 2 && buf[0] === 0x50 && buf[1] >= 0x31 && buf[1] <= 0x36) return 'pnm';
  if (buf.length >= 4 && buf[0] === 0x38 && buf[1] === 0x42 && buf[2] === 0x50 && buf[3] === 0x53) return 'psd';
  if (buf.length >= 4 && buf[0] === 0x69 && buf[1] === 0x63 && buf[2] === 0x6e && buf[3] === 0x73) return 'icns';
  if (buf.length >= 10 && buf[0] === 0x23 && buf[1] === 0x3f && buf[2] === 0x52) return 'hdr';
  if (buf.length >= 4 && ((buf[0] === 0x49 && buf[1] === 0x49) || (buf[0] === 0x4d && buf[1] === 0x4d))) {
    if (buf[2] === 0x2a || buf[3] === 0x2a) return 'tiff';
  }
  if (buf.length >= 6 && buf[0] === 0x00 && buf[1] === 0x00 && buf[2] === 0x01 && buf[3] === 0x00) return 'ico';
  // TGA：无强魔数，按头部字段（color map / image type / bpp）
  if (buf.length >= 18) {
    const cmap = hex(1);
    const itype = hex(2);
    const bpp = hex(16);
    if ((cmap === 0 || cmap === 1) && [1, 2, 3, 9, 10, 11].includes(itype) && [8, 15, 16, 24, 32].includes(bpp)) {
      return 'tga';
    }
  }
  return 'unknown';
}

// 文件名契约：gNN_<what>_<W>x<H>.<ext>
const GOLDEN_NAME = /^g(\d{2})_([a-z0-9_]+)_(\d+)x(\d+)\.([a-z]+)$/;
const MALFORMED_NAME = /^m(\d)_([a-z0-9_]+)\.([a-z]+)$/;

// ---------------------------------------------------------------- 主流程
function collect() {
  const golden = listDir(GOLDEN_DIR).map((name) => {
    const path = join(GOLDEN_DIR, name);
    const buf = readFileSync(path);
    const m = GOLDEN_NAME.exec(name);
    if (!m) {
      fail('golden/naming', `${name} 不符合 gNN_<内容>_<W>x<H>.<ext>`);
      return null;
    }
    return {
      name: mtimeStable(name),
      path,
      bytes: buf.length,
      sha256: sha256(buf),
      declared: { width: Number(m[3]), height: Number(m[4]) },
      sniffed: sniff(buf),
    };
  }).filter(Boolean);

  const malformed = listDir(MALFORMED_DIR).map((name) => {
    const path = join(MALFORMED_DIR, name);
    const buf = readFileSync(path);
    const m = MALFORMED_NAME.exec(name);
    if (!m) {
      fail('malformed/naming', `${name} 不符合 mN_<类别>.<ext>`);
      return null;
    }
    return {
      name: mtimeStable(name),
      path,
      bytes: buf.length,
      sha256: sha256(buf),
      class: m[2],
      sniffed: sniff(buf),
    };
  }).filter(Boolean);

  return { golden, malformed };
}

function probeGolden(rows) {
  for (const row of rows) {
    const r = imgtool(['info', row.path]);
    if (!r) return;
    if (r.timedOut) {
      fail(`golden/${row.name}`, `info 超时（>${TIMEOUT_MS}ms）`);
      continue;
    }
    const j = lastJson(r.out);
    if (r.status !== 0 || !j || j.ok !== true) {
      fail(`golden/${row.name}`, `info 失败：exit=${r.status} ${r.out.slice(0, 160)}`);
      continue;
    }
    row.format = j.format;
    row.width = j.width;
    row.height = j.height;
    if (j.format !== row.sniffed && !(j.format === 'apng' && row.sniffed === 'png')) {
      fail(`golden/${row.name}`, `magic 判定 ${row.sniffed} 与 imgtool 报出的 ${j.format} 不一致`);
    }
    if (j.width !== row.declared.width || j.height !== row.declared.height) {
      fail(
        `golden/${row.name}`,
        `尺寸 ${j.width}x${j.height} 与文件名声明的 ${row.declared.width}x${row.declared.height} 不一致`,
      );
    }
  }
}

function probeMalformed(rows, workDir) {
  for (const row of rows) {
    const dst = join(workDir, `probe_${row.name.replace(/\.[a-z]+$/, '')}.png`);
    const started = Date.now();
    const r = imgtool(['convert', row.path, dst]);
    if (!r) return;
    const elapsed = Date.now() - started;
    row.behavior = { status: r.status, ms: elapsed };
    if (r.timedOut) {
      fail(`malformed/${row.name}`, `解码超时（>${TIMEOUT_MS}ms）：DoS 面未收口`);
      continue;
    }
    if (/PanicError|moonbit_panic|panicked/i.test(r.out)) {
      fail(`malformed/${row.name}`, `解码触发 panic（应以 JSON 错误返回）：${r.out.slice(0, 160)}`);
      continue;
    }
    if (r.status === 0) {
      fail(`malformed/${row.name}`, `畸形样本被接受（exit=0），期望拒绝`);
      continue;
    }
    const j = lastJson(r.out);
    if (!j || j.ok !== false || typeof j.code !== 'string') {
      fail(`malformed/${row.name}`, `拒绝结果不是契约 JSON：${r.out.slice(0, 160)}`);
      continue;
    }
    row.behavior.code = j.code;
  }
}

function checkBudget(rows) {
  const all = [...rows.golden, ...rows.malformed];
  const total = all.reduce((s, r) => s + r.bytes, 0);
  for (const r of all) {
    if (r.bytes > LIMITS.file_bytes) {
      fail('budget/file', `${r.name} ${r.bytes} B > ${LIMITS.file_bytes} B`);
    }
    if (r.bytes === 0) fail('budget/file', `${r.name} 是空文件`);
  }
  if (total > LIMITS.total_bytes) fail('budget/total', `样本集 ${total} B > ${LIMITS.total_bytes} B`);
  return total;
}

function checkManifest(rows) {
  if (!existsSync(MANIFEST_PATH)) {
    fail('manifest', '缺少 benchmarks/manifest.json（先跑 --update）');
    return null;
  }
  const m = JSON.parse(readFileSync(MANIFEST_PATH, 'utf8'));
  const cmp = (kind, entries) => {
    const got = rows[kind];
    if (entries.length !== got.length) {
      fail(`manifest/${kind}`, `条数 ${entries.length} ≠ 目录 ${got.length}`);
    }
    for (const e of entries) {
      const g = got.find((r) => r.name === e.name);
      if (!g) {
        fail(`manifest/${kind}`, `${e.name} 在目录中不存在`);
        continue;
      }
      if (e.sha256 !== g.sha256) fail(`manifest/${kind}`, `${e.name} sha256 漂移`);
      if (e.bytes !== g.bytes) fail(`manifest/${kind}`, `${e.name} 字节数漂移`);
      if (kind === 'golden') {
        const want = EXTERNAL_GENERATORS[e.name] || DEFAULT_GENERATOR;
        if (e.generator !== want) {
          fail('manifest/generator', `${e.name} generator=${e.generator} ≠ ${want}（漏标会让 --regen 静默跳过）`);
        }
      }
    }
  };
  cmp('golden', m.golden || []);
  cmp('malformed', m.malformed || []);
  return m;
}

function writeManifest(rows, total) {
  const manifest = {
    schema: 'benchmarks@1',
    generator: 'moon run benchmarks/gen',
    note: '全部样本由本仓自有代码合成，无第三方素材；sha256 与体积为分发契约。',
    limits: LIMITS,
    total_bytes: total,
    golden: rows.golden.map((r) => ({
      name: r.name,
      format: r.format,
      width: r.width,
      height: r.height,
      bytes: r.bytes,
      sha256: r.sha256,
      generator: EXTERNAL_GENERATORS[r.name] || DEFAULT_GENERATOR,
    })),
    malformed: rows.malformed.map((r) => ({
      name: r.name,
      class: r.class,
      expect: 'reject',
      bytes: r.bytes,
      sha256: r.sha256,
      rejects_with: r.behavior ? r.behavior.code : undefined,
    })),
  };
  writeFileSync(MANIFEST_PATH, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  return manifest;
}

// GAP-53：manifest 只封「文件 ↔ 封签」，不封「文件 ↔ 当前生成器产出」。
// --regen 重跑生成器到 _build/benchmarks_regen，逐文件比 sha256：
// 生成器是确定性的（同代码同输入 → 同字节），任何落后于编码器修复的样本都会在此暴露。
function regenCompare(rows) {
  const tmp = join(ROOT, '_build', 'benchmarks_regen');
  const genGolden = join(tmp, 'golden');
  const genMalformed = join(tmp, 'malformed');
  mkdirSync(genGolden, { recursive: true });
  mkdirSync(genMalformed, { recursive: true });
  const started = Date.now();
  const r = spawnSync(
    'moon',
    ['run', 'benchmarks/gen', '--target', 'native', '--', genGolden, genMalformed],
    { encoding: 'utf8', cwd: ROOT, timeout: 900000, shell: true, windowsHide: true },
  );
  const ms = Date.now() - started;
  if (r.status !== 0) {
    fail('regen/run', `benchmarks/gen 退出码 ${r.status}：${`${r.stdout || ''}${r.stderr || ''}`.trim().slice(-240)}`);
    return { mode: 'regen', ok: false, ms };
  }
  const hashOf = (dir, name) => sha256(readFileSync(join(dir, name)));
  let verified = 0;
  const skipped = [];
  for (const row of rows.golden) {
    if (EXTERNAL_GENERATORS[row.name]) {
      skipped.push(row.name);
      continue;
    }
    const path = join(genGolden, row.name);
    if (!existsSync(path)) {
      fail('regen/missing', `${row.name} 不在生成器产出中——磁盘有、生成器没有`);
      continue;
    }
    const h = hashOf(genGolden, row.name);
    if (h !== row.sha256) fail('regen/sha256', `${row.name} 与当前生成器产出不一致（样本已落后于代码）`);
    else verified += 1;
  }
  for (const name of listDir(genGolden)) {
    if (!rows.golden.some((g) => g.name === name) && !EXTERNAL_GENERATORS[name]) {
      fail('regen/extra', `${name} 只存在于生成器产出中——生成器有、磁盘没有`);
    }
  }
  for (const row of rows.malformed) {
    const path = join(genMalformed, row.name);
    if (!existsSync(path)) {
      fail('regen/missing', `${row.name} 不在生成器产出中`);
      continue;
    }
    if (hashOf(genMalformed, row.name) !== row.sha256) {
      fail('regen/sha256', `${row.name} 与当前生成器产出不一致`);
    } else verified += 1;
  }
  return {
    mode: 'regen',
    ms,
    verified,
    skipped: skipped.length,
    skipped_by: [...new Set(Object.values(EXTERNAL_GENERATORS))],
  };
}

function main() {
  const update = process.argv.includes('--update');
  const regen = process.argv.includes('--regen');
  if (!existsSync(GOLDEN_DIR) || !existsSync(MALFORMED_DIR)) {
    console.log(JSON.stringify({ ok: false, fail: 'benchmarks 目录缺失' }));
    return 1;
  }
  const rows = collect();
  const total = checkBudget(rows);

  if (rows.golden.length !== LIMITS.golden_count) {
    fail('count/golden', `${rows.golden.length} ≠ ${LIMITS.golden_count}`);
  }
  if (rows.malformed.length !== LIMITS.malformed_count) {
    fail('count/malformed', `${rows.malformed.length} ≠ ${LIMITS.malformed_count}`);
  }

  probeGolden(rows.golden);
  probeMalformed(rows.malformed, join(ROOT, '_build'));

  if (update) {
    const m = writeManifest(rows, total);
    const report = {
      ok: fails.length === 0,
      mode: 'update',
      golden: m.golden.length,
      malformed: m.malformed.length,
      total_bytes: total,
      fail: fails.length ? fails[0].what : null,
      fails,
    };
    console.log(JSON.stringify(report, null, 2));
    return fails.length === 0 ? 0 : 1;
  }

  const manifest = checkManifest(rows);
  const regenReport = regen ? regenCompare(rows) : null;
  const formats = [...new Set(rows.golden.map((r) => r.format))].sort();
  console.log(
    JSON.stringify(
      {
        ok: fails.length === 0,
        golden: rows.golden.length,
        malformed: rows.malformed.length,
        formats,
        total_bytes: total,
        manifest: manifest ? manifest.schema : null,
        regen: regenReport,
        failed: fails.length,
        fails,
      },
      null,
      2,
    ),
  );
  return fails.length === 0 ? 0 : 1;
}

process.exit(main());
