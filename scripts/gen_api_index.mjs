#!/usr/bin/env node
// gen_api_index.mjs — 从各包 pkg.generated.mbti 自动生成 API 索引（防手工快照过时）
//
// 用法：node scripts/gen_api_index.mjs [--check]
//   默认：写入 docs/api_index.md
//   --check：只比较（不写入），发现漂移则 exit 1（供 CI 使用）
// 口径：pub fn 行数 + pub struct/enum/type/trait 行数；包 = 含 moon.pkg 的目录。

import { readFile, writeFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const OUT = path.join(ROOT, 'docs', 'api_index.md');
const SKIP = new Set(['_build', '.git', '.mooncakes', 'node_modules', 'examples', 'scripts']);

async function collect(dir, out = []) {
  const entries = await readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.isDirectory()) {
      if (!SKIP.has(e.name)) await collect(path.join(dir, e.name), out);
    } else if (e.name === 'pkg.generated.mbti') {
      out.push(path.join(dir, e.name));
    }
  }
  return out;
}

function count(text, re) {
  return text.split('\n').filter(l => re.test(l)).length;
}

const files = await collect(ROOT);
const rows = [];
let totalFn = 0;
let totalTy = 0;
for (const f of files) {
  const text = await readFile(f, 'utf8');
  const pkg = path.relative(ROOT, path.dirname(f)).split(path.sep).join('/') || '(root)';
  const fn = count(text, /^pub fn /);
  const ty = count(text, /^pub(\(all\))? (struct|enum|type)\b/) + count(text, /^pub trait /);
  totalFn += fn;
  totalTy += ty;
  rows.push({ pkg, fn, ty });
}
rows.sort((a, b) => a.pkg.localeCompare(b.pkg));

const table = rows.map(r => `| \`${r.pkg}\` | ${r.fn} | ${r.ty} |`).join('\n');
const content = `# API 索引（自动生成）

> 由 \`node scripts/gen_api_index.mjs\` 从各包 \`pkg.generated.mbti\` 生成，请勿手工编辑。
> 生成日期口径：每次运行覆盖；当前共 **${rows.length}** 个包、**${totalFn}** 个 \`pub fn\`、**${totalTy}** 个公开类型/trait。
> 详细用法见各包 \`.mbti\` 与 [api_reference.md](api_reference.md)（后者为历史快照，以本索引与 \`.mbti\` 为准）。

| 包 | pub fn | 公开类型/trait |
|----|-------:|---------------:|
${table}
| **合计** | **${totalFn}** | **${totalTy}** |
`;

const checkMode = process.argv.includes('--check');
if (checkMode) {
  const old = existsSync(OUT) ? await readFile(OUT, 'utf8') : '';
  if (old !== content) {
    console.error('api_index drift: docs/api_index.md 与 .mbti 不一致，请运行 node scripts/gen_api_index.mjs');
    process.exit(1);
  }
  console.log(JSON.stringify({ ok: true, packages: rows.length, pub_fn: totalFn, pub_types: totalTy }));
} else {
  await writeFile(OUT, content, 'utf8');
  console.log(JSON.stringify({ written: 'docs/api_index.md', packages: rows.length, pub_fn: totalFn, pub_types: totalTy }));
}