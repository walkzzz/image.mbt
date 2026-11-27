import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const WASM_PATH = process.env.IMAGE_MBT_WASM
  ? process.env.IMAGE_MBT_WASM
  : fileURLToPath(new URL('./image.wasm', import.meta.url));

const wasmModule = new WebAssembly.Module(readFileSync(WASM_PATH));
const instance = new WebAssembly.Instance(wasmModule, {});
const ex = instance.exports;

const FORMAT_CODES = {
  png: 1,
  jpeg: 2,
  jpg: 2,
  webp: 3,
  gif: 4,
  bmp: 5,
  qoi: 6,
  pnm: 7,
  ppm: 7,
  tga: 8,
  best: 9,
};

const FORMAT_NAMES = {
  1: 'png',
  2: 'jpeg',
  3: 'webp',
  4: 'gif',
  5: 'bmp',
  6: 'qoi',
  7: 'pnm',
  8: 'tga',
};

function memory() {
  return new Uint8Array(ex.memory.buffer);
}

function toBytes(input) {
  if (input instanceof Uint8Array) return input;
  if (input instanceof ArrayBuffer) return new Uint8Array(input);
  if (ArrayBuffer.isView(input)) {
    return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
  }
  throw new TypeError('输入必须是 Buffer / Uint8Array / ArrayBuffer');
}

function stage(input) {
  const bytes = toBytes(input);
  if (bytes.length === 0) throw new TypeError('输入字节为空');
  const ptr = ex.abi_alloc(bytes.length);
  memory().set(bytes, ptr);
  return ptr;
}

function fail() {
  const ptr = ex.abi_last_error();
  const len = ex.abi_last_len();
  const text = Buffer.from(memory().subarray(ptr, ptr + len)).toString('utf8');
  const [code = 'unknown', message = '', hint = ''] = text.split('\n');
  const err = new Error(message || code);
  err.code = code;
  err.hint = hint;
  throw err;
}

function formatCode(name) {
  const code = FORMAT_CODES[String(name).toLowerCase()];
  if (!code) {
    throw new TypeError(
      `不支持的格式: ${name}（可用 ${Object.keys(FORMAT_CODES).join('/')}）`,
    );
  }
  return code;
}

function meta() {
  return {
    format: FORMAT_NAMES[ex.abi_last_format()] || 'unknown',
    width: ex.abi_last_width(),
    height: ex.abi_last_height(),
    channels: ex.abi_last_channels(),
  };
}

function take(ptr) {
  const len = ex.abi_last_len();
  return Buffer.from(memory().subarray(ptr, ptr + len));
}

// Starts a chain: input staging + call + result/metadata read happen in one
// synchronous block so the shared state cannot be observed half-updated.
function run(input, call) {
  const ptr = stage(input);
  const out = call(ptr);
  if (!ex.abi_last_ok()) return fail();
  const info = meta();
  return { data: take(out), ...info };
}

/**
 * 探测图片：不完整解码，只读头部（宽高、格式、体积）。
 *
 * `channels` 恒为 `null`：函数名是 info 但只读头部，`abi_info` 不解码像素，
 * wasm 侧把 channels 写 0；若原样透出，调用方会把 0 当「单通道灰度图」。
 * 需要真实通道数时用 `convertMeta` / `resizeMeta`（那条路径解过码）。
 * @param {Buffer|Uint8Array|ArrayBuffer} input
 * @returns {{format: string, width: number, height: number, channels: null, bytes: number}}
 */
export function info(input) {
  const ptr = stage(input);
  ex.abi_info(ptr);
  if (!ex.abi_last_ok()) return fail();
  const m = meta();
  return {
    format: m.format,
    width: m.width,
    height: m.height,
    channels: null,
    bytes: ex.abi_last_len(),
  };
}

/**
 * 解码后按目标格式重新编码。
 * @param {Buffer|Uint8Array|ArrayBuffer} input
 * @param {{format?: string, quality?: number}} [options]
 * @returns {Buffer}
 */
export function convert(input, options = {}) {
  const code = formatCode(options.format ?? 'png');
  const quality = options.quality ?? 90;
  return run(input, (ptr) => ex.abi_convert(ptr, code, quality)).data;
}

/**
 * 同 convert，但同时返回输出格式与实际宽高。
 * @returns {{data: Buffer, format: string, width: number, height: number, channels: number}}
 */
export function convertMeta(input, options = {}) {
  const code = formatCode(options.format ?? 'png');
  const quality = options.quality ?? 90;
  return run(input, (ptr) => ex.abi_convert(ptr, code, quality));
}

/**
 * 缩放（cover 裁切填充 / contain 白底留边），再编码。
 * @param {Buffer|Uint8Array|ArrayBuffer} input
 * @param {{width: number, height: number, mode?: 'cover'|'contain', format?: string, quality?: number}} options
 * @returns {Buffer}
 */
export function resize(input, options) {
  return resizeMeta(input, options).data;
}

/**
 * 同 resize，但同时返回输出格式与实际宽高。
 */
export function resizeMeta(input, options) {
  const width = options?.width;
  const height = options?.height;
  if (!Number.isInteger(width) || !Number.isInteger(height) || width <= 0 || height <= 0) {
    throw new TypeError('resize 需要正整数 width / height');
  }
  const mode = options.mode === 'contain' ? 1 : 0;
  const code = formatCode(options.format ?? 'png');
  const quality = options.quality ?? 90;
  return run(input, (ptr) => ex.abi_resize(ptr, width, height, mode, code, quality));
}

/** 支持的输出格式名（best = 逐候选实编取最小）。 */
export const formats = Object.keys(FORMAT_CODES);

export default { info, convert, convertMeta, resize, resizeMeta, formats };
