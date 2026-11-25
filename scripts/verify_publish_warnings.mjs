#!/usr/bin/env node
// 发布包「零警告」自检：对每个模块执行
//   1) moon package 生成归档 zip
//   2) 解压到 _build/proto/v2/<name>
//   3) 在该目录写 moon.work，把其余六个模块源码目录当 workspace 成员（绕开未发布的 0.1.9 依赖钉）
//   4) moon check --deny-warn，统计 warning 行数
//
// 用途：发布前确认真实归档（裁剪后的文件集）不产生任何 `[0029] unused_package`。
// 用法：node scripts/verify_publish_warnings.mjs [module...]

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const ROOT = process.cwd();
const MODULES = ["image.core", "image.codec", "image.process", "image.photography", "image.vision", "image.domain", "."];
const only = process.argv.slice(2);
const targets = only.length ? only : MODULES;

const OUT = path.join(ROOT, "_build", "proto", "v2");
fs.mkdirSync(OUT, { recursive: true });

function run(cmd, cwd) {
  return execSync(cmd, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], shell: "powershell.exe" });
}

// workspace 下所有模块共用根的 _build/publish；子模块目录自身也可能有 build 产物
function latestZip(mod, startedAt) {
  const publishDirs = [
    path.join(ROOT, "_build", "publish"),
    path.join(ROOT, mod === "." ? "" : mod, "_build", "publish"),
  ];
  const prefix = mod === "." ? "walkzzz-image.mbt-" : `walkzzz-${mod}-`;
  const cands = [];
  for (const dir of publishDirs) {
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir)) {
      if (!f.endsWith(".zip") || !f.startsWith(prefix) || f.includes("verify")) continue;
      const full = path.join(dir, f);
      const t = fs.statSync(full).mtimeMs;
      if (t >= startedAt - 1000) cands.push({ full, t });
    }
  }
  cands.sort((a, b) => b.t - a.t);
  return cands.length ? cands[0].full : null;
}

const results = [];

for (const mod of targets) {
  const modDir = mod === "." ? ROOT : path.join(ROOT, mod);
  const name = mod === "." ? "root" : mod.replace(/\./g, "-");
  const dest = path.join(OUT, name);
  process.stdout.write(`\n=== ${mod} ===\n`);

  const stamp = Date.now();
  try {
    run("moon package", modDir);
  } catch (e) {
    // moon package 在 PowerShell 下常因 stderr 触发非零退出码，产物仍然生成，继续走文件检查
  }
  const zip = latestZip(mod, stamp);
  if (!zip) {
    console.log(`  ✘ 未找到归档 zip`);
    results.push({ mod, ok: false, warnings: -1 });
    continue;
  }
  const zipName = path.basename(zip);
  if (fs.existsSync(dest)) fs.rmSync(dest, { recursive: true, force: true });
  fs.mkdirSync(dest, { recursive: true });
  run(`Expand-Archive -LiteralPath '${zip}' -DestinationPath '${dest}' -Force`, ROOT);

  // workspace：本包 + 其余六个模块的源码目录
  const members = ['"."'];
  for (const other of MODULES) {
    if (other === mod) continue;
    const rel = path.relative(dest, other === "." ? ROOT : path.join(ROOT, other)).replace(/\\/g, "/");
    members.push(`"${rel}"`);
  }
  const work = `members = [\n  ${members.map((m) => m).join(",\n  ")},\n]\n`;
  fs.writeFileSync(path.join(dest, "moon.work"), work, "utf8");

  let out = "";
  let code = 0;
  try {
    out = run("moon check --deny-warn", dest);
  } catch (e) {
    out = `${e.stdout || ""}\n${e.stderr || ""}`;
    code = 1;
  }
  const warnCount = (out.match(/Warning/gi) || []).length;
  const errCount = (out.match(/Error/gi) || []).length;
  const finished = /Finished\. moon: .*?\b(\d+) tasks/.exec(out);
  const filesInZip = countFiles(dest);
  const ok = warnCount === 0 && !/error:/i.test(out) && !/\[0029\]/.test(out);
  console.log(`  zip: ${zipName}  文件 ${filesInZip}`);
  console.log(`  ${ok ? "✔" : "✘"} warnings=${warnCount} errors=${errCount} ${finished ? `tasks=${finished[1]}` : ""}`);
  if (!ok) console.log(out.split("\n").slice(-20).join("\n"));
  results.push({ mod, ok, warnings: warnCount, files: filesInZip });
}

function countFiles(dir) {
  let n = 0;
  const stack = [dir];
  while (stack.length) {
    const d = stack.pop();
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (e.isDirectory()) stack.push(path.join(d, e.name));
      else n++;
    }
  }
  return n - 1; // 排除脚本写入的 moon.work
}

console.log("\n=== 汇总 ===");
for (const r of results) {
  console.log(`${r.ok ? "✔" : "✘"} ${r.mod.padEnd(16)} warnings=${r.warnings} files=${r.files ?? "-"}`);
}
process.exit(results.every((r) => r.ok) ? 0 : 1);
