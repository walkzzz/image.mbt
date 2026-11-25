import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import zlib from 'node:zlib';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const wasmOut = join(root, '_build', 'wasm', 'release', 'build', 'walkzzz', 'image.mbt', 'wasm', 'wasm.wasm');
const npmDir = join(root, 'npm');
const npmWasm = join(npmDir, 'image.wasm');
const LIMIT = 1.2 * 1024 * 1024;
const noTest = process.argv.includes('--no-test');

function run(cmd, args) {
  console.log(`$ ${cmd} ${args.join(' ')}`);
  // moon 在 Windows 上会把进度写到 stderr；这里统一捕获再从 stdout 输出，
  // 避免 PowerShell 把子进程 stderr 当成 NativeCommandError 让脚本整体退出码变 1。
  const res = spawnSync(cmd, args, { cwd: root, encoding: 'utf8' });
  const out = `${res.stdout ?? ''}${res.stderr ?? ''}`;
  if (out) process.stdout.write(out);
  if (res.status !== 0) throw new Error(`${cmd} 退出码 ${res.status}`);
}

run('moon', ['build', 'wasm', '--target', 'wasm', '--release']);
if (!existsSync(wasmOut)) throw new Error(`wasm 产物不存在: ${wasmOut}`);

mkdirSync(npmDir, { recursive: true });
copyFileSync(wasmOut, npmWasm);

const raw = readFileSync(npmWasm);
const gz = zlib.gzipSync(raw, { level: 9 });
const module_ = new WebAssembly.Module(raw);
const exportsList = WebAssembly.Module.exports(module_);
const importsList = WebAssembly.Module.imports(module_);

console.log(`\nwasm: ${(raw.length / 1024).toFixed(1)} KiB raw, ${(gz.length / 1024).toFixed(1)} KiB gzip`);
console.log(`exports: ${exportsList.map((e) => e.name).join(', ')}`);
console.log(`imports: ${importsList.length}`);

if (gz.length > LIMIT) {
  throw new Error(`gzip ${(gz.length / 1024).toFixed(1)} KiB 超过 1.2 MiB 上限`);
}
if (importsList.length !== 0) {
  throw new Error('wasm 不应有 import（Node 侧需零 shim）');
}
for (const name of ['memory', 'abi_alloc', 'abi_info', 'abi_convert', 'abi_resize']) {
  if (!exportsList.some((e) => e.name === name)) throw new Error(`缺少导出 ${name}`);
}

// 同步 npm 包版本与仓库版本，避免两边漂移。
const modText = readFileSync(join(root, 'moon.mod'), 'utf8');
const version = modText.match(/version\s*=\s*"([^"]+)"/)?.[1];
if (!version) throw new Error('读不到 moon.mod 版本');
const pkgPath = join(npmDir, 'package.json');
const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
if (pkg.version !== version) {
  pkg.version = version;
  writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`);
  console.log(`package.json 版本同步为 ${version}`);
}

// 冒烟：直接跑 npm 自测，确保拷贝过去的 wasm 真能实例化。
if (!noTest) run('node', [join(npmDir, 'test.mjs')]);

console.log('\nS12 npm-wasm 构建完成');
