// imgtool_path.mjs — 跨平台解析 `moon build --release cmd/imgtool` 的产物路径
//
// 为什么单独抽出来：MoonBit 的 native 后端在不同平台/版本下产物命名不一致——
// 本机（Windows）是 `_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe`，
// 而 GitHub Linux runner 上实测同样输出成 `imgtool.exe`（Linux 也带 .exe 后缀），
// 但脚本里若按 `process.platform` 猜 `imgtool`（无后缀）就会误判"未找到"，
// 直接让 quality 的基准门禁与 bindings 的 Dart 自测整条红（2026-11-27 实测两次）。
//
// 策略：先认 IMGTOOL 环境变量，再认固定路径（两种后缀都试），最后在 _build/native/release 下扫。

import { existsSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const CANDIDATE_NAMES = ['imgtool.exe', 'imgtool'];

export function resolveImgtool(root) {
  const env = process.env.IMGTOOL;
  if (env && existsSync(env)) return env;

  const dir = join(root, '_build', 'native', 'release', 'build', 'walkzzz', 'image.mbt', 'cmd', 'imgtool');
  for (const name of CANDIDATE_NAMES) {
    const p = join(dir, name);
    if (existsSync(p) && !statSync(p).isDirectory()) return p;
  }

  // 兜底：build 目录层级随 moon 版本变过，直接扫（深度限制 4 层，够到 cmd/imgtool/<bin>）
  const base = join(root, '_build', 'native', 'release', 'build');
  const hits = [];
  const walk = (d, depth) => {
    if (depth > 4) return;
    let entries;
    try {
      entries = readdirSync(d, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of entries) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p, depth + 1);
      else if (CANDIDATE_NAMES.includes(e.name)) hits.push(p);
    }
  };
  walk(base, 0);
  if (hits.length) return hits.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];

  return join(dir, CANDIDATE_NAMES[0]);
}
