#!/usr/bin/env node
// 检查每个 moon.pkg 的导入是否有「多余项」：
//   1. 同一目标（"" / "test" / "wbtest"）内重复导入同一包；
//   2. `for "test"` 块里重复了 plain 块已导入的包（plain 导入对测试同样可见）；
//   3. 空块。
//
// 这些冗余正是 `moon publish` 的 verify 阶段刷 `Warning: [0029] unused_package` 的燃料：
// 一旦发布归档裁掉测试文件，只在测试里被引用的导入就变成「未使用的包」。
//
// 用法：
//   node scripts/check_pkg_imports.mjs           # 只报告，退出码 1 表示有问题
//   node scripts/check_pkg_imports.mjs --fix     # 就地清理

import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const SKIP_DIR = new Set(["_build", ".mooncakes", "node_modules", ".git", ".tmp-smoke"]);

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP_DIR.has(e.name)) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name === "moon.pkg") out.push(p);
  }
  return out;
}

// 解析 `import { "a", "b" @x }` + 可选 `for "test"`
function parseBlocks(src) {
  const blocks = [];
  let i = 0;
  while (i < src.length) {
    const start = src.indexOf("import", i);
    if (start < 0) break;
    const braceAt = src.indexOf("{", start);
    if (braceAt < 0) break;
    // 找配对的右花括号
    let depth = 0, end = -1;
    for (let j = braceAt; j < src.length; j++) {
      if (src[j] === "{") depth++;
      else if (src[j] === "}") { depth--; if (depth === 0) { end = j; break; } }
    }
    if (end < 0) break;
    const body = src.slice(braceAt + 1, end);
    // 可选 `for "test"` 后缀
    const rest = src.slice(end + 1);
    const m = rest.match(/^[ \t]*for[ \t]+"([^"]+)"/);
    const target = m ? m[1] : "";
    const afterEnd = end + 1 + (m ? m[0].length : 0);
    blocks.push({ rawStart: braceAt + 1, rawEnd: end, body, target, tailEnd: afterEnd });
    i = end + 1;
  }
  return blocks;
}

// 单条导入 -> { pkg, alias }
function parseEntry(text) {
  const s = text.trim();
  const m = s.match(/^"([^"]+)"(?:[ \t]+@([^\s,}]+))?$/);
  if (!m) return null;
  return { pkg: m[1], alias: m[2] || null };
}

function entriesOf(body) {
  return body
    .split("\n")
    .map((l) => l.replace(/,?\s*$/, ""))
    .filter((l) => l.trim().length > 0)
    .map(parseEntry)
    .filter(Boolean);
}

function pkgNameOf(file) {
  return path.relative(ROOT, file).replace(/\\/g, "/");
}

const files = walk(ROOT).sort();
const problems = [];
const fixes = new Map(); // file -> new source

for (const file of files) {
  const src = fs.readFileSync(file, "utf8");
  const blocks = parseBlocks(src);
  if (blocks.length === 0) continue;

  const plain = new Set();
  const issues = [];

  for (const b of blocks) {
    const entries = entriesOf(b.body);
    const seen = new Map();
    for (const e of entries) {
      if (seen.has(e.pkg)) issues.push({ kind: "dup-in-block", target: b.target, pkg: e.pkg });
      seen.set(e.pkg, true);
    }
    if (b.target === "") for (const e of entries) plain.add(e.pkg);
  }

  // 测试块里与 plain 重复的条目
  for (const b of blocks) {
    if (b.target === "") continue;
    for (const e of entriesOf(b.body)) {
      if (plain.has(e.pkg)) issues.push({ kind: "dup-plain-vs-" + b.target, target: b.target, pkg: e.pkg });
    }
  }

  if (issues.length === 0) continue;
  problems.push({ file: pkgNameOf(file), issues });

  // 生成修正版本：plain 块去重；测试块去掉与 plain 重复者，空块整块删除
  let out = src;
  const rebuilt = [];
  for (const b of blocks) {
    const entries = entriesOf(b.body);
    const keep = [];
    const seen = new Set();
    for (const e of entries) {
      if (seen.has(e.pkg)) continue;
      if (b.target !== "" && plain.has(e.pkg)) continue;
      seen.add(e.pkg);
      keep.push(e);
    }
    rebuilt.push({ target: b.target, keep });
  }

  // 按原始顺序重新序列化所有块（丢弃空块）
  out = rebuild(src, blocks, rebuilt);
  fixes.set(file, out);
}

function fmtEntry(e) {
  return e.alias ? `"${e.pkg}" @${e.alias}` : `"${e.pkg}"`;
}

function rebuild(src, blocks, rebuilt) {
  // 逐块替换原文，从后往前以免偏移失效
  let out = src;
  for (let idx = blocks.length - 1; idx >= 0; idx--) {
    const b = blocks[idx];
    const keep = rebuilt[idx].keep;
    const headStart = out.lastIndexOf("import", b.rawStart);
    if (keep.length === 0) {
      // 删除整块（含可能的空行）
      let end = b.tailEnd;
      while (end < out.length && (out[end] === "\n" || out[end] === " " || out[end] === "\t")) end++;
      // 连同前面的空行一起吞掉，避免留下双空行
      let start = headStart;
      while (start > 0 && out[start - 1] === "\n") start--;
      out = out.slice(0, start) + "\n" + out.slice(end);
      continue;
    }
    const blockText =
      `import {\n` + keep.map((e) => `  ${fmtEntry(e)},\n`).join("") + `}` +
      (blocks[idx].target ? ` for "${blocks[idx].target}"` : "");
    out = out.slice(0, headStart) + blockText + out.slice(b.tailEnd);
  }
  return out;
}

const fix = process.argv.includes("--fix");

if (problems.length === 0) {
  console.log(`✔ moon.pkg 导入干净：${files.length} 个包，0 处冗余`);
  process.exit(0);
}

for (const p of problems) {
  console.log(`✘ ${p.file}`);
  for (const i of p.issues) console.log(`    - ${i.kind}: ${i.pkg}`);
}

if (!fix) {
  console.log(`\n共 ${problems.length} 个包有冗余导入（加 --fix 自动清理）`);
  process.exit(1);
}

for (const [file, content] of fixes) fs.writeFileSync(file, content, "utf8");
console.log(`\n✔ 已清理 ${fixes.size} 个包的冗余导入`);
