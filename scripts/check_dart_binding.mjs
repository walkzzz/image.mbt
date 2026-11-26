#!/usr/bin/env node
// ============================================================================
// Dart 绑定自测（S17）
//
// 用法：
//   node scripts/check_dart_binding.mjs            # 构建 release imgtool 后跑 Dart 自测
//   node scripts/check_dart_binding.mjs --no-build # 复用已构建的 imgtool
//
// 验收口径（roadmap S17）：Dart 侧跑通 decode → resize → encode。
//
// 为什么不在 Dart 里载 wasm：
//   * `package:wasm`（0.1.0+1）已废弃，且需 Rust + MSVC link.exe 现编 Wasmer；
//   * Dart VM 没有 WebAssembly 运行时；
//   * MoonBit 官方明确 native 不产出静态/动态库，`dart:ffi` 无库可载。
//   因此 Dart 绑定以 `imgtool` 进程为 ABI，实现不重复（详见 bindings/dart/README.md）。
//
// 环境变量：
//   ROOT     仓库根（默认脚本上一级）
//   IMGTOOL  imgtool 可执行路径（默认 _build/native/release/.../imgtool.exe，可覆盖）
// ============================================================================

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.env.ROOT
  ? resolve(process.env.ROOT)
  : resolve(dirname(fileURLToPath(import.meta.url)), '..');
const noBuild = process.argv.includes('--no-build');
const exeName = process.platform === 'win32' ? 'imgtool.exe' : 'imgtool';
const imgtool =
  process.env.IMGTOOL ??
  join(root, '_build', 'native', 'release', 'build', 'walkzzz', 'image.mbt', 'cmd', 'imgtool', exeName);

function run(cmd, args, opts = {}) {
  const res = spawnSync(cmd, args, { cwd: opts.cwd ?? root, encoding: 'utf8', env: { ...process.env, ...(opts.env ?? {}) } });
  const out = `${res.stdout ?? ''}${res.stderr ?? ''}`;
  if (out) process.stdout.write(out);
  if (res.error) throw res.error;
  if (res.status !== 0) throw new Error(`${cmd} 退出码 ${res.status}`);
  return out;
}

function probe(cmd) {
  const res = spawnSync(cmd, ['--version'], { encoding: 'utf8' });
  return res.status === 0;
}

if (!probe('dart')) {
  console.error('dart 不在 PATH：先装 Dart SDK（>=3.6）或跳过本检查。');
  process.exit(2);
}

if (!noBuild) {
  run('moon', ['build', '--release', 'cmd/imgtool']);
}
if (!existsSync(imgtool)) {
  throw new Error(`imgtool 不存在: ${imgtool}（先跑 moon build --release cmd/imgtool）`);
}

console.log(`imgtool = ${imgtool}`);
run('dart', ['run', 'tool/selftest.dart'], {
  cwd: join(root, 'bindings', 'dart'),
  env: { IMGTOOL: imgtool },
});
console.log('Dart binding check passed');
