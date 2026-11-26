#!/usr/bin/env node
// gen_capabilities.mjs — 能力表真值生成器（S19）
//
// 真值来源（全部机器可读，不接受手写数字）：
//   1. `image.core/types/pkg.generated.mbti` 里的 `enum ImageFormat` 变体清单（由 moon info 生成）
//   2. `image.codec/codec/codec_trait.mbt` 里 `Codec for ImageFormat` 的 4 个 impl 体
//      （format_name / can_encode / can_decode / is_lossless 的实际 match 分支）
//   3. 各包 `pkg.generated.mbti` 的 pub fn / 公开类型计数（模块矩阵）
//   4. `docs/format_notes.json` 只提供逐格式的人类可读备注；缺失即失败，保证新增格式必须补说明
//
// 用法：
//   node scripts/gen_capabilities.mjs            # 写入 docs/capabilities.md 并填充两份 README 的 AUTO 区块
//   node scripts/gen_capabilities.mjs --check    # 只校验（不写盘），漂移则 exit 1（供 CI / check_docs B10 使用）
//   ROOT=<dir> 环境变量可覆盖仓库根（自测夹具用）

import { readFile, writeFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(process.env.ROOT || path.join(import.meta.dirname, '..'));
const OUT_DOC = path.join(ROOT, 'docs', 'capabilities.md');
const NOTES = path.join(ROOT, 'docs', 'format_notes.json');
const MBTI_ENUM = path.join(ROOT, 'image.core', 'types', 'pkg.generated.mbti');
const TRAIT = path.join(ROOT, 'image.codec', 'codec', 'codec_trait.mbt');
const CHECK = process.argv.includes('--check');

const SKIP_DIRS = new Set(['_build', '.git', '.mooncakes', 'node_modules', 'examples', 'scripts', 'playground']);

/* ---------- 解析 ---------- */

function parseEnumVariants(src, enumName) {
  const lines = src.split(/\r?\n/);
  const heads = [`pub(all) enum ${enumName} {`, `pub enum ${enumName} {`];
  const start = lines.findIndex(l => heads.includes(l.trim()));
  if (start < 0) throw new Error(`枚举 ${enumName} 未在 .mbti 中找到`);
  const out = [];
  for (let i = start + 1; i < lines.length; i++) {
    const l = lines[i];
    if (/^\}/.test(l)) break;
    const m = l.match(/^\s{2,}([A-Za-z][A-Za-z0-9_]*)\s*$/);
    if (m) out.push(m[1]);
  }
  if (!out.length) throw new Error(`枚举 ${enumName} 变体为空`);
  return out;
}

// 从 `pub impl Codec for @types.ImageFormat with fn <name>(self) {` 的 match 块里取分支值
function parseImplArms(src, implName) {
  const lines = src.split(/\r?\n/);
  const re = new RegExp(`pub impl Codec for @types\\\\.ImageFormat with fn ${implName}(?:\\\\(self\\\\))? \\\\{`);
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes(`with fn ${implName}(`)) { start = i; break; }
  }
  if (start < 0) throw new Error(`Codec impl ${implName} 未找到`);
  const arms = new Map();
  let fallback = null;
  for (let i = start + 1; i < lines.length; i++) {
    const l = lines[i];
    if (/^\}/.test(l)) break;
    const arm = l.match(/@types\.ImageFormat::([A-Za-z][A-Za-z0-9_]*)\s*=>\s*(.+)$/);
    if (arm) { arms.set(arm[1], arm[2].trim().replace(/,$/, '')); continue; }
    const wild = l.match(/(?:_|@types\.ImageFormat::\.\.)\s*=>\s*(.+)$/);
    if (wild) { fallback = wild[1].trim().replace(/,$/, ''); continue; }
  }
  return { arms, fallback };
}

function asBool(expr) {
  if (expr === 'true') return true;
  if (expr === 'false') return false;
  throw new Error(`预期 true/false，实际是 ${expr}`);
}

function asString(expr) {
  const m = expr.match(/^"([^"]*)"$/);
  if (!m) throw new Error(`预期字符串字面量，实际是 ${expr}`);
  return m[1];
}

async function collectMbti(dir, out = []) {
  const entries = await readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.isDirectory()) {
      if (!SKIP_DIRS.has(e.name)) await collectMbti(path.join(dir, e.name), out);
    } else if (e.name === 'pkg.generated.mbti') {
      out.push(path.join(dir, e.name));
    }
  }
  return out;
}

/* ---------- 组装 ---------- */

const enumSrc = await readFile(MBTI_ENUM, 'utf8');
const traitSrc = await readFile(TRAIT, 'utf8');
const notesJson = JSON.parse(await readFile(NOTES, 'utf8'));
const notes = notesJson.notes || {};

const variants = parseEnumVariants(enumSrc, 'ImageFormat');
const nameArms = parseImplArms(traitSrc, 'format_name');
const encArms = parseImplArms(traitSrc, 'can_encode');
const decArms = parseImplArms(traitSrc, 'can_decode');
const lossArms = parseImplArms(traitSrc, 'is_lossless');

function resolve(arms, v, kind) {
  const raw = arms.arms.get(v) ?? arms.fallback;
  if (raw == null) throw new Error(`${kind}: ${v} 既无显式分支也无默认分支`);
  return kind === 'name' ? asString(raw) : asBool(raw);
}

const rows = [];
for (const v of variants) {
  if (v === 'Unknown') continue;
  const note = notes[v];
  if (!note || !note.zh || !note.en) {
    throw new Error(`docs/format_notes.json 缺少 ${v} 的 zh/en 备注（新增格式必须补说明）`);
  }
  rows.push({
    variant: v,
    name: resolve(nameArms, v, 'name'),
    decode: resolve(decArms, v, 'decode'),
    encode: resolve(encArms, v, 'encode'),
    lossless: resolve(lossArms, v, 'lossless'),
    zh: note.zh,
    en: note.en,
  });
}
// 备注里不允许出现已删除的格式（防止 notes 长期堆积假条目）
for (const k of Object.keys(notes)) {
  if (!variants.includes(k)) throw new Error(`docs/format_notes.json 含未知格式 ${k}`);
}

const mark = (b) => (b ? '✅' : '—');

// 模块矩阵
const mbtiFiles = await collectMbti(ROOT);
const modules = new Map();
let totalFn = 0;
let totalTy = 0;
let totalPkg = 0;
for (const f of mbtiFiles) {
  const text = await readFile(f, 'utf8');
  const rel = path.relative(ROOT, path.dirname(f)).split(path.sep).join('/');
  const mod = rel.includes('/') ? rel.split('/')[0] : '(root)';
  const fn = text.split('\n').filter(l => /^pub fn /.test(l)).length;
  const ty =
    text.split('\n').filter(l => /^pub(?:\(all\))? (?:struct|enum|type)\b/.test(l)).length +
    text.split('\n').filter(l => /^pub trait /.test(l)).length;
  const rec = modules.get(mod) || { pkgs: 0, fn: 0, ty: 0 };
  rec.pkgs += 1;
  rec.fn += fn;
  rec.ty += ty;
  modules.set(mod, rec);
  totalFn += fn;
  totalTy += ty;
  totalPkg += 1;
}
const moduleOrder = ['(root)', 'image.core', 'image.codec', 'image.process', 'image.photography', 'image.vision', 'image.domain'];
const moduleRows = [...modules.keys()]
  .sort((a, b) => {
    const ia = moduleOrder.indexOf(a);
    const ib = moduleOrder.indexOf(b);
    return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib) || a.localeCompare(b);
  })
  .map(m => ({ mod: m, ...modules.get(m) }));

/* ---------- 渲染 ---------- */

function formatTableZh() {
  const head = ['| 格式 | 解码 | 编码 | 备注 |', '|:----:|:----:|:----:|------|'];
  const body = rows.map(r => `| **${r.name}** | ${mark(r.decode)} | ${mark(r.encode)} | ${r.zh} |`);
  return [...head, ...body].join('\n');
}

function formatTableEn() {
  const head = ['| Format | Decode | Encode | Notes |', '|:----:|:----:|:----:|------|'];
  const body = rows.map(r => `| **${r.name}** | ${mark(r.decode)} | ${mark(r.encode)} | ${r.en} |`);
  return [...head, ...body].join('\n');
}

const traitTable = () =>
  [
    '| 变体 | format_name | can_decode | can_encode | is_lossless |',
    '|---|---|:----:|:----:|:----:|',
    ...variants.map(v => {
      const isU = v === 'Unknown';
      const n = resolve(nameArms, v, 'name');
      return `| \`${v}\` | \`${n}\` | ${mark(resolve(decArms, v, 'decode'))} | ${mark(resolve(encArms, v, 'encode'))} | ${mark(resolve(lossArms, v, 'lossless'))} |`;
    }),
  ].join('\n');

const moduleTable = () =>
  [
    '| 模块 | 包数 | pub fn | 公开类型/trait |',
    '|---|---:|---:|---:|',
    ...moduleRows.map(r => `| \`${r.mod}\` | ${r.pkgs} | ${r.fn} | ${r.ty} |`),
    `| **合计** | **${totalPkg}** | **${totalFn}** | **${totalTy}** |`,
  ].join('\n');

const docContent = `# 能力矩阵（自动生成）

> 本文件由 \`node scripts/gen_capabilities.mjs\` 生成，**请勿手工编辑**。
> 数据源（全部机器可读）：
> 1. \`image.core/types/pkg.generated.mbti\` 的 \`enum ImageFormat\` 变体清单；
> 2. \`image.codec/codec/codec_trait.mbt\` 的 \`Codec for ImageFormat\` 四个 impl 体的实际分支；
> 3. 各包 \`pkg.generated.mbti\` 的公开 API 计数；
> 4. \`docs/format_notes.json\` 的逐格式备注（只含人类可读说明，缺一条即生成失败）。
>
> 校验：\`node scripts/gen_capabilities.mjs --check\`（\`check_docs\` 的 B10 门禁会调用）。

## 格式能力（面向使用者）

> 口径：解码/编码来自 \`Codec::can_decode\` / \`Codec::can_encode\`，与 README 表格同源同渲染。

${formatTableZh()}

## Codec trait 全量口径（含无损位）

> \`is_lossless\` 是**枚举级**声明：WebP 的 VP8 lossy 编码路径已弃用、当前只承诺 VP8L 无损，
> 但枚举位仍返回 \`false\`（历史口径），使用时请以「备注」列与实际编解码路径为准。
> \`Unknown\` 不是真实格式，仅为探测失败占位。

${traitTable()}

## 模块矩阵（公开 API 面）

${moduleTable()}

统计口径：包 = 含 \`pkg.generated.mbti\` 的目录（排除 \`examples\` / \`playground\` / \`scripts\`）；
\`pub fn\` 只计顶层函数；公开类型 = \`pub\`/\`pub(all)\` 的 \`struct|enum|type\` + \`pub trait\`。
`;

/* ---------- README AUTO 区块 ---------- */

const MARK_START = '<!-- AUTO:formats:start -->';
const MARK_END = '<!-- AUTO:formats:end -->';
const NOTES_MARK = '> 🔒 本表由 `node scripts/gen_capabilities.mjs` 从 `ImageFormat` 枚举与 `Codec` trait 生成，手工修改会被 B10 门禁拦下。';

async function patchReadme(fileName, table, lang) {
  const p = path.join(ROOT, fileName);
  const text = await readFile(p, 'utf8');
  if (!text.includes(MARK_START) || !text.includes(MARK_END)) return { file: fileName, block: null };
  const block = `${MARK_START}\n${table}\n\n${NOTES_MARK}\n${MARK_END}`;
  const s = text.indexOf(MARK_START);
  const e = text.indexOf(MARK_END) + MARK_END.length;
  const next = text.slice(0, s) + block + text.slice(e);
  const current = text.slice(s, e);
  return { file: fileName, block, next, current, lang };
}

/* ---------- 运行 ---------- */

const readmes = [
  await patchReadme('README.md', formatTableZh(), 'zh'),
  await patchReadme('README.en.md', formatTableEn(), 'en'),
].filter(r => r.block !== null);

// 标题里的「· 18 种」也要与枚举对齐
async function headingCheck(fileName, expected) {
  const text = await readFile(path.join(ROOT, fileName), 'utf8');
  const m = text.match(/^## .*格式支持 · (\d+) 种$/m) || text.match(/^## .*Format Support · (\d+)$/m);
  if (!m) return { file: fileName, ok: true, skipped: 'heading not found' };
  return { file: fileName, ok: Number(m[1]) === expected, found: Number(m[1]), expected };
}

const headZh = await headingCheck('README.md', rows.length);
const headEn = await headingCheck('README.en.md', rows.length);

const problems = [];
if (!headZh.ok) problems.push(`README.md 标题写「${headZh.found} 种」，枚举实际 ${headZh.expected} 种`);
if (!headEn.ok) problems.push(`README.en.md 标题写「${headEn.found}」，枚举实际 ${headEn.expected}`);

const existingDoc = existsSync(OUT_DOC) ? await readFile(OUT_DOC, 'utf8') : '';
if (existingDoc !== docContent) {
  problems.push(`docs/capabilities.md 与生成结果不一致（${existingDoc ? '内容漂移' : '文件缺失'}）`);
}
for (const r of readmes) {
  if (r.current !== r.block) problems.push(`${r.file} 的 AUTO:formats 区块与生成结果不一致`);
}

if (CHECK) {
  if (problems.length) {
    console.error(JSON.stringify({ schema: 'capabilities@1', ok: false, problems }, null, 2));
    process.exit(1);
  }
  console.log(JSON.stringify({ schema: 'capabilities@1', ok: true, formats: rows.length, modules: moduleRows.length, pub_fn: totalFn, pub_types: totalTy, packages: totalPkg }, null, 2));
  process.exit(0);
}

await writeFile(OUT_DOC, docContent);
for (const r of readmes) await writeFile(path.join(ROOT, r.file), r.next);
for (const p of problems.filter((x) => x.includes('标题写'))) console.warn('warn: ' + p);
console.log(JSON.stringify({ schema: 'capabilities@1', wrote: ['docs/capabilities.md', ...readmes.map(r => r.file)], formats: rows.length, modules: moduleRows.length, pub_fn: totalFn, pub_types: totalTy, packages: totalPkg }, null, 2));
