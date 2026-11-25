// VP8L 分阶段验证 A：2 色值图像，5 棵码表全走 simple 码表（0/1 bit 每符号）
// 目的：先确认 RIFF/VP8L 头、transform 结束位、cache 位、meta 位、像素顺序与位序正确。

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

function writeSimple1(w, symbol, firstIs8) {
  w.writeBits(1, 1); // simple
  w.writeBits(0, 1); // 1 symbol
  w.writeBits(firstIs8 ? 1 : 0, 1);
  w.writeBits(symbol, firstIs8 ? 8 : 1);
}

function writeSimple2(w, s0, s1) {
  w.writeBits(1, 1); // simple
  w.writeBits(1, 1); // 2 symbols
  w.writeBits(0, 1); // first symbol 1 bit
  w.writeBits(s0, 1);
  w.writeBits(s1, 8);
}

function container(payload) {
  const out = [];
  const u32 = (v) => out.push(v & 0xff, (v >>> 8) & 0xff, (v >>> 16) & 0xff, (v >>> 24) & 0xff);
  out.push(0x52, 0x49, 0x46, 0x46);
  const pad = payload.length % 2;
  u32(4 + 8 + payload.length + pad);
  out.push(0x57, 0x45, 0x42, 0x50);
  out.push(0x56, 0x50, 0x38, 0x4c);
  u32(payload.length);
  for (const b of payload) out.push(b);
  if (pad) out.push(0);
  return Buffer.from(out);
}

// 16x16：棋盘格，颜色 A=(255,0,0) B=(0,0,255)，即 R∈{255,0}、G=0、B∈{255,0}
const W = 16, H = 16;
const w = new BitWriter();
w.writeBits(0x2f, 8);
w.writeBits(W - 1, 14);
w.writeBits(H - 1, 14);
w.writeBits(0, 1); // alpha_is_used = 0
w.writeBits(0, 3); // version
w.writeBits(0, 1); // 无 transform
w.writeBits(0, 1); // 无 color cache
w.writeBits(0, 1); // 单 meta 前缀组
// G: 只有符号 0 -> 单符号
writeSimple1(w, 0, true);
// R: 符号 0 与 255 -> 2 符号（码 0 = 0, 码 1 = 255）
writeSimple2(w, 0, 255);
// B: 符号 0 与 255
writeSimple2(w, 0, 255);
// A: 单符号 255
writeSimple1(w, 255, true);
// dist: 单符号 0
writeSimple1(w, 0, false);
// 像素：G 不消耗比特；R/B 各 1 比特
for (let y = 0; y < H; y++) {
  for (let x = 0; x < W; x++) {
    const isA = (x + y) % 2 === 0; // A: R=255,B=0
    w.writeBits(isA ? 1 : 0, 1); // R 码
    w.writeBits(isA ? 0 : 1, 1); // B 码
  }
}
w.flush();
const buf = container(w.bytes);
fs.writeFileSync("_build/probe_vp8l_stageA.webp", buf);
console.log(`stageA: ${buf.length} bytes`);
