// 对照实验：与 gen_lz77_fixture.mjs 相同的双符号 normal 码表，但只发 literal（无 LZ77）。
// 用于判断"码表写法"是否合法；若此样本能过 ffmpeg，则问题只出在 LZ77 段。
import fs from "node:fs";

class BitWriter {
  constructor() {
    this.bytes = [];
    this.cur = 0;
    this.n = 0;
  }
  writeBits(value, nbits) {
    for (let i = 0; i < nbits; i++) {
      this.cur |= ((value >> i) & 1) << this.n;
      this.n++;
      if (this.n === 8) {
        this.bytes.push(this.cur);
        this.cur = 0;
        this.n = 0;
      }
    }
  }
  flush() {
    if (this.n > 0) this.bytes.push(this.cur);
  }
}

const ORDER = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
const rev = (v, n) => {
  let r = 0;
  for (let i = 0; i < n; i++) r |= ((v >> i) & 1) << (n - 1 - i);
  return r;
};

function sym3(w) {
  w.writeBits(rev(0b0, 1), 1);
}
function sym28(w, extra) {
  w.writeBits(rev(0b11, 2), 2);
  w.writeBits(extra, 7);
}
function sym17(w, extra) {
  w.writeBits(rev(0b10, 2), 2);
  w.writeBits(extra, 3);
}

function writeGreenTable(w, symB) {
  w.writeBits(0, 1);
  w.writeBits(0, 4);
  for (let i = 0; i < 4; i++) {
    const s = ORDER[i];
    const len = s === 1 ? 1 : s === 17 || s === 18 ? 2 : 0;
    w.writeBits(len, 3);
  }
  w.writeBits(0, 1);
  sym28(w, 16 - 11);
  sym3(w);
  sym28(w, 138 - 11);
  sym28(w, 116 - 11);
  sym3(w);
  sym17(w, 8 - 3);
}

function writeSimple(w, symbol) {
  w.writeBits(1, 1);
  w.writeBits(0, 1);
  if (symbol > 1) {
    w.writeBits(1, 1);
    w.writeBits(symbol, 8);
  } else {
    w.writeBits(0, 1);
    w.writeBits(symbol, 1);
  }
}

const W = 16;
const H = 16;
const w = new BitWriter();
w.writeBits(0x2f, 8);
w.writeBits(W - 1, 14);
w.writeBits(H - 1, 14);
w.writeBits(1, 1);
w.writeBits(0, 3);
w.writeBits(0, 1);
w.writeBits(0, 1);
w.writeBits(0, 1);
// 绿树：符号 16（literal）与 271（占位，不发）
writeGreenTable(w, 271);
writeSimple(w, 0x20);
writeSimple(w, 0x30);
writeSimple(w, 0xff);
writeSimple(w, 1);
// 256 个像素全部发绿码 0（literal 16）
for (let i = 0; i < W * H; i++) w.writeBits(rev(0b0, 1), 1);
w.flush();

const payload = w.bytes;
const out = [];
const u32 = (v) => out.push(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >>> 24) & 0xff);
out.push(0x52, 0x49, 0x46, 0x46);
u32(4 + 8 + payload.length + (payload.length % 2));
out.push(0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x4c);
u32(payload.length);
out.push(...payload);
if (payload.length % 2) out.push(0);
fs.writeFileSync("_build/proto/two_sym_16.webp", Buffer.from(out));
console.log(`two_sym_16.webp: ${out.length} 字节`);
