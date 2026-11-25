// 生成"literal + 单次 LZ77 反向引用"的 VP8L 最小样本：
// 16x16 纯色 (G=0x10,R=0x20,B=0x30,A=0xFF)。第 1 像素 literal，其余 255 像素由一次
// length=255 / distance=1 的反向引用产生。
// 用途：验证 MoonBit 解码器按 RFC 9649 处理长度前缀码、距离前缀码与 120 项邻域映射。
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

// 写 3 位宽度的"码长码"符号（canonical 后按位反转写入）
// cl 码表：1 → 1 位码 0；17 → 2 位码 10；18 → 2 位码 11
function sym3(w) {
  // 符号 1（长度 1）
  w.writeBits(rev(0b0, 1), 1);
}
function sym28(w, extra) {
  // 符号 18：11..138 个零
  w.writeBits(rev(0b11, 2), 2);
  w.writeBits(extra, 7);
}
function sym17(w, extra) {
  // 符号 17：3..10 个零
  w.writeBits(rev(0b10, 2), 2);
  w.writeBits(extra, 3);
}

function writeGreenTable(w) {
  w.writeBits(0, 1); // normal code
  w.writeBits(0, 4); // num_code_lengths = 4 → 覆盖 17,18,0,1
  for (let i = 0; i < 4; i++) {
    const s = ORDER[i];
    const len = s === 1 ? 1 : s === 17 || s === 18 ? 2 : 0;
    w.writeBits(len, 3);
  }
  w.writeBits(0, 1); // max_symbol 标志 = 0
  sym28(w, 16 - 11); // 0..15 长度 0
  sym3(w); // 16 长度 1
  sym28(w, 138 - 11); // 17..154 长度 0
  sym28(w, 116 - 11); // 155..270 长度 0
  sym3(w); // 271 长度 1
  sym17(w, 8 - 3); // 272..279 长度 0
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
w.writeBits(0, 1); // no transform
w.writeBits(0, 1); // no color cache
w.writeBits(0, 1); // single prefix group
writeGreenTable(w); // 符号 16（绿）与 271（长度前缀 15）
writeSimple(w, 0x20); // red 常值
writeSimple(w, 0x30); // blue 常值
writeSimple(w, 0xff); // alpha 常值
writeSimple(w, 1); // distance 前缀 1 → 值 2 → (1,0) → dist = 1

w.writeBits(rev(0b0, 1), 1); // 绿码 0 → literal（green = 16）
w.writeBits(rev(0b1, 1), 1); // 绿码 1 → 长度符号 271
w.writeBits(62, 6); // 长度前缀 15 的 6 个 extra bits：192 + 62 + 1 = 255
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
const buf = Buffer.from(out);
fs.writeFileSync("_build/proto/lz77_16.webp", buf);
console.log(`lz77_16.webp: ${buf.length} 字节`);
console.log("HEX=" + buf.toString("hex"));
