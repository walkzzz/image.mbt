// VP8L 最小合法编码器原型（literal-only，无 transform / 无 cache / 单 meta 组）
// 目的：在写 MoonBit 之前，用 ffmpeg 判定我们对 RFC 9649 §3 的理解是否正确。
// 产物写到 _build/probe_vp8l.webp，不参与发布。

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

// 写一个"扁平 8 位"前缀码：256 个符号全部 8 位长，canonical 码即符号本身。
// 码长序列 = 256 个 8，用码长码 {8:1位, 16:1位} 压缩：1 个 8 + 43 个 repeat16。
function writeFlat8PrefixCode(w, reverse) {
  w.writeBits(0, 1); // 0 = normal code length code
  // num_code_lengths = 4 + ReadBits(4) => 写 15 得到 19
  w.writeBits(15, 4);
  // kCodeLengthCodeOrder = [17,18,0,1,2,3,4,5,16,6,7,8,9,10,11,12,13,14,15]
  // 只给符号 8 和 16 长度 1，其余 0
  const order = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  for (const sym of order) {
    w.writeBits(sym === 8 || sym === 16 ? 1 : 0, 3);
  }
  w.writeBits(0, 1); // max_symbol = 字母表大小
  // 码长码 {8: '0', 16: '1'}（单 bit，反向无关）
  w.writeBits(0, 1); // 符号 8
  // 255 个长度 8：42 次 repeat16(6) + 1 次 repeat16(3)
  for (let i = 0; i < 255; i += 6) {
    const take = Math.min(6, 255 - i);
    w.writeBits(1, 1); // 符号 16
    w.writeBits(take - 3, 2); // 额外 2 位：3..6
  }
}

// 写一个"单符号"简单前缀码（0 比特/符号）
function writeSimplePrefixCode(w, symbol, firstIs8Bits) {
  w.writeBits(1, 1); // simple
  w.writeBits(0, 1); // num_symbols = 1
  w.writeBits(firstIs8Bits ? 1 : 0, 1);
  w.writeBits(symbol, firstIs8Bits ? 8 : 1);
}

function encodeVp8l(width, height, rgba, opts = {}) {
  const reverse = opts.reverse ?? true;
  const w = new BitWriter();
  // image-header
  w.writeBits(0x2f, 8);
  w.writeBits(width - 1, 14);
  w.writeBits(height - 1, 14);
  w.writeBits(1, 1); // alpha_is_used
  w.writeBits(0, 3); // version
  // 无 transform
  w.writeBits(0, 1);
  // 无色彩缓存
  w.writeBits(0, 1);
  // 单 meta 前缀码组
  w.writeBits(0, 1);
  // 5 棵前缀码：G/R/B 扁平 8 位；A 单符号 255；dist 单符号 0
  writeFlat8PrefixCode(w, reverse);
  writeFlat8PrefixCode(w, reverse);
  writeFlat8PrefixCode(w, reverse);
  writeSimplePrefixCode(w, 255, true);
  writeSimplePrefixCode(w, 0, false);
  // 像素数据：literal only，顺序 G,R,B（A 由单符号码表给出 255）
  for (let i = 0; i < width * height; i++) {
    const g = rgba[i * 4 + 1];
    const r = rgba[i * 4 + 0];
    const b = rgba[i * 4 + 2];
    const sym = (v) => (reverse ? reverseBits8(v) : v);
    w.writeBits(sym(g), 8);
    w.writeBits(sym(r), 8);
    w.writeBits(sym(b), 8);
  }
  w.flush();

  const payload = w.bytes;
  const out = [];
  const push32le = (v) => out.push(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >>> 24) & 0xff);
  out.push(0x52, 0x49, 0x46, 0x46);
  push32le(4 + 8 + payload.length + (payload.length % 2));
  out.push(0x57, 0x45, 0x42, 0x50);
  out.push(0x56, 0x50, 0x38, 0x4c); // VP8L
  push32le(payload.length);
  for (const b of payload) out.push(b);
  if (payload.length % 2) out.push(0);
  return Buffer.from(out);
}

function reverseBits8(v) {
  let r = 0;
  for (let i = 0; i < 8; i++) r |= ((v >> i) & 1) << (7 - i);
  return r;
}

// 16x16 测试图：R = x*16, G = y*16, B = 128
const W = 16, H = 16;
const rgba = new Uint8Array(W * H * 4);
for (let y = 0; y < H; y++) {
  for (let x = 0; x < W; x++) {
    const i = (y * W + x) * 4;
    rgba[i] = x * 16;
    rgba[i + 1] = y * 16;
    rgba[i + 2] = 128;
    rgba[i + 3] = 255;
  }
}
const fs2 = fs;
for (const reverse of [true, false]) {
  const buf = encodeVp8l(W, H, rgba, { reverse });
  const name = reverse ? "vp8l_rev" : "vp8l_norev";
  fs.writeFileSync(`_build/probe_${name}.webp`, buf);
  console.log(`${name}: ${buf.length} bytes`);
}
