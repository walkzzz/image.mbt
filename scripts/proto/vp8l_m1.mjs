// VP8L M1 原型：literal-only，normal 码表（全字母表长度）
// 相比 vp8l_proto.mjs 的三处修正：
//   1) 绿树按 280 个符号写码长（256 literal + 24 长度码），而不是只写 256；
//   2) 码长码只含 {8, 18}，num_code_lengths = 12（必须覆盖 order 里的 8 和 18），Kraft 完整；
//   3) 尾部 24 个长度码用符号 18 写 11..138 的零游程。
import fs from "node:fs";

class BitWriter {
  constructor() {
    this.bytes = [];
    this.cur = 0;
    this.n = 0;
  }
  writeBits(value, nbits) {
    for (let i = 0; i < nbits; i++) {
      const bit = (value >> i) & 1;
      this.cur |= bit << this.n;
      this.n++;
      if (this.n === 8) {
        this.bytes.push(this.cur);
        this.cur = 0;
        this.n = 0;
      }
    }
  }
  flush() {
    if (this.n > 0) {
      this.bytes.push(this.cur);
      this.cur = 0;
      this.n = 0;
    }
  }
}

const ORDER = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

// 写一棵 "前 256 个符号长 8、其余长 0" 的 normal 码表。
// 码长码：{8: code 0, 18: code 1}（各 1 位，Kraft 完整）。
function writeFlat8NormalCode(w, alphabetSize) {
  w.writeBits(0, 1); // 0 = normal
  w.writeBits(8, 4); // num_code_lengths = 4 + 8 = 12 → 覆盖 17..8
  const lenFor = (sym) => (sym === 8 || sym === 18 ? 1 : 0);
  for (let i = 0; i < 12; i++) w.writeBits(lenFor(ORDER[i]), 3);
  w.writeBits(0, 1); // max_symbol 标志 = 0 → 读满整个字母表

  // 256 个符号长度 8 → 码长码符号 8 = 码 0，写 256 个 0 位
  for (let i = 0; i < 256; i++) w.writeBits(0, 1);
  // 余下 (alphabetSize - 256) 个符号长度 0 → 符号 18 = 码 1 + 7 位 (run-11)
  const zeros = alphabetSize - 256;
  if (zeros > 0) {
    const runs = [];
    let left = zeros;
    while (left > 0) {
      const take = Math.min(138, left);
      runs.push(take);
      left -= take;
    }
    for (const r of runs) {
      w.writeBits(1, 1); // 符号 18
      w.writeBits(r - 11, 7);
    }
  }
}

function writeSimpleCode(w, symbols) {
  w.writeBits(1, 1); // simple
  if (symbols.length === 1) {
    w.writeBits(0, 1);
    const big = symbols[0] > 1;
    w.writeBits(big ? 1 : 0, 1); // is_first_8bits
    w.writeBits(symbols[0], big ? 8 : 1);
  } else {
    w.writeBits(1, 1);
    w.writeBits(0, 1);
    w.writeBits(symbols[0], 8);
    w.writeBits(symbols[1], 8);
  }
}

const reverseBits8 = (v) => {
  let r = 0;
  for (let i = 0; i < 8; i++) r |= ((v >> i) & 1) << (7 - i);
  return r;
};
const reverseBits1 = (v) => v;

function encode(width, height, rgba) {
  const w = new BitWriter();
  w.writeBits(0x2f, 8);
  w.writeBits(width - 1, 14);
  w.writeBits(height - 1, 14);
  w.writeBits(1, 1); // alpha_is_used
  w.writeBits(0, 3); // version
  w.writeBits(0, 1); // 无 transform
  w.writeBits(0, 1); // 无 color cache
  w.writeBits(0, 1); // 单 meta 组
  writeFlat8NormalCode(w, 280); // G（含 24 个长度码）
  writeFlat8NormalCode(w, 256); // R
  writeFlat8NormalCode(w, 256); // B
  writeSimpleCode(w, [255]); // A 单符号
  writeSimpleCode(w, [0]); // dist 单符号

  for (let i = 0; i < width * height; i++) {
    w.writeBits(reverseBits8(rgba[i * 4 + 1]), 8);
    w.writeBits(reverseBits8(rgba[i * 4 + 0]), 8);
    w.writeBits(reverseBits8(rgba[i * 4 + 2]), 8);
    // alpha 单符号：0 位
  }
  w.flush();

  const payload = w.bytes;
  const out = [];
  const push32le = (v) => out.push(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff);
  out.push(0x52, 0x49, 0x46, 0x46);
  push32le(4 + 8 + payload.length + (payload.length % 2));
  out.push(0x57, 0x45, 0x42, 0x50);
  out.push(0x56, 0x50, 0x38, 0x4c);
  push32le(payload.length);
  for (const b of payload) out.push(b);
  if (payload.length % 2) out.push(0);
  return Buffer.from(out);
}

function makeImage(W, H) {
  const rgba = new Uint8Array(W * H * 4);
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const i = (y * W + x) * 4;
      rgba[i] = (x * 255 / Math.max(1, W - 1)) | 0;
      rgba[i + 1] = (y * 255 / Math.max(1, H - 1)) | 0;
      rgba[i + 2] = ((x + y) * 3) & 0xff;
      rgba[i + 3] = 255;
    }
  }
  return rgba;
}

for (const size of [16, 64, 1024]) {
  const rgba = makeImage(size, size);
  const buf = encode(size, size, rgba);
  const name = `_build/proto/m1_${size}.webp`;
  fs.writeFileSync(name, buf);
  console.log(`${name}: ${buf.length} bytes`);
}
