#!/usr/bin/env node
// ============================================================================
// GitHub Pages 首页数字同步（S21）
//
// 用法：
//   node scripts/sync_pages.mjs           # 就地改写 docs/index.html 的指标槽位
//   node scripts/sync_pages.mjs --check   # 只校验，不写（CI / 门禁用）
//
// 真值来源（页面不自己造数）：
//   moon.mod                → 版本号（brand-ver / hero-version / 安装命令的 @x.y.z）
//   README.md 徽章          → 每后端测试数 / 覆盖率 / 子包数
//   docs/coverage.json      → 覆盖率分子分母、百分比、门槛
//
// 为什么单独一个脚本：首页是静态 HTML，数字不会自己变；bump_version 升版本后
// 若忘改首页，页面就会挂旧口径（0.1.1 / 6664 / 83.4% 那次就是这么留下的）。
// ============================================================================

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.env.ROOT
  ? resolve(process.env.ROOT)
  : resolve(dirname(fileURLToPath(import.meta.url)), '..');
const checkOnly = process.argv.includes('--check');

const index = join(root, 'docs', 'index.html');
const readme = readFileSync(join(root, 'README.md'), 'utf8');
const moon = readFileSync(join(root, 'moon.mod'), 'utf8');
const cov = JSON.parse(readFileSync(join(root, 'docs', 'coverage.json'), 'utf8'));

const version = moon.match(/^version = "([^"]+)"/m)?.[1];
const tests = Number((readme.match(/badge\/tests-([\d_]+)/)?.[1] ?? '').replace(/_/g, ''));
const coveragePct = readme.match(/badge\/coverage-([\d.]+)/)?.[1];
const packages = Number(readme.match(/badge\/packages-(\d+)/)?.[1] ?? 0);

const problems = [];
if (!version) problems.push('moon.mod 缺 version');
if (!Number.isFinite(tests) || tests <= 0) problems.push('README 缺 tests 徽章');
if (!coveragePct) problems.push('README 缺 coverage 徽章');
if (!packages) problems.push('README 缺 packages 徽章');
if (coveragePct && Number(coveragePct) !== Number(cov.percent)) {
  problems.push(`README 覆盖率 ${coveragePct}% ≠ docs/coverage.json ${cov.percent}%`);
}
if (problems.length) {
  console.error(JSON.stringify({ ok: false, problems }, null, 2));
  process.exit(1);
}

const total = tests * 4;
let html = readFileSync(index, 'utf8');
const before = html;

/** 一条槽位替换：命中必须非零，否则报出来（避免静默漏改）。 */
const slots = [];
const sub = (name, re, to) => {
  const hits = html.match(re);
  if (!hits) {
    slots.push({ name, ok: false, detail: '槽位未找到' });
    return;
  }
  html = html.replace(re, to);
  slots.push({ name, ok: true, from: hits[0].slice(0, 60), to: String(to).slice(0, 60) });
};

sub('brand 版本', /class="brand-ver">v[\d.]+</, `class="brand-ver">v${version}<`);
sub('hero 版本', /id="hero-version">[\d.]+</, `id="hero-version">${version}<`);
sub('hero 徽章 测试数', /<li>[\d,]+ × 4 测试<\/li>/, `<li>${tests} × 4 测试</li>`);
sub('hero 徽章 覆盖率', /<li>覆盖率 [\d.]+%<\/li>/, `<li>覆盖率 ${coveragePct}%</li>`);
sub('统计 每后端', /<strong>[\d,]+<\/strong><span>每后端测试<\/span>/, `<strong>${tests}</strong><span>每后端测试</span>`);
sub('统计 四后端合计', /<strong>[\d,]+<\/strong><span>四后端合计<\/span>/, `<strong>${total}</strong><span>四后端合计</span>`);
sub('统计 覆盖率', /<strong>[\d.]+%<\/strong><span>核心覆盖率<\/span>/, `<strong>${coveragePct}%</strong><span>核心覆盖率</span>`);
sub('统计 子包', /<strong>[\d,]+<\/strong><span>子包<\/span>/, `<strong>${packages}</strong><span>子包</span>`);
sub('og 描述测试数', /；[\d,]+×4 测试全绿/, `；${tests}×4 测试全绿`);
sub('安装命令版本', /(moon add walkzzz\/image\.[a-z]+)@[\d.]+/g, `$1@${version}`);
sub(
  '覆盖率口径行',
  /<strong>覆盖率口径<\/strong>：[\d,]+\/[\d,]+ = [\d.]+%，门槛 [\d.]+%/,
  `<strong>覆盖率口径</strong>：${cov.covered.toLocaleString('en-US')}/${cov.total.toLocaleString('en-US')} = ${cov.percent}%，门槛 ${cov.threshold}%`,
);
sub('质量段测试数', /跑 [\d,]+ 测试；<code>check_pages\.mjs<\/code>/, `跑 ${tests} 测试；<code>check_pages.mjs</code>`);

const failed = slots.filter((s) => !s.ok);
const dirty = html !== before;

if (failed.length) {
  console.error(JSON.stringify({ ok: false, slots, problems: failed.map((s) => s.name) }, null, 2));
  process.exit(1);
}

if (checkOnly) {
  if (dirty) {
    console.error(
      JSON.stringify(
        {
          ok: false,
          problems: ['docs/index.html 与真值不一致：跑 node scripts/sync_pages.mjs 修'],
          slots: slots.map((s) => `${s.name}: ${s.from} → ${s.to}`),
        },
        null,
        2,
      ),
    );
    process.exit(1);
  }
  console.log(`pages 数字一致：${slots.length} 个槽位（${version} / ${tests} / ${coveragePct}% / ${packages} 包）`);
} else {
  writeFileSync(index, html);
  console.log(`pages 数字已同步：${slots.length} 个槽位（${version} / ${tests} / ${coveragePct}% / ${packages} 包）`);
}
