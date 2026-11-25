// RFC 9649 §3 VP8L 参考解码器（Node，用于交叉校验 MoonBit 实现与调试）
// 支持：transforms(subtract-green / predictor / cross-color / palette 暂不支持 → 报错)、
// color cache、meta 分组、5 棵前缀码、LZ77、120 项距离映射。
import fs from "node:fs";

const ORDER = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

const DIST = `(0, 1), (1, 0), (1, 1), (-1, 1), (0, 2), (2, 0), (1, 2),
(-1, 2), (2, 1), (-2, 1), (2, 2), (-2, 2), (0, 3), (3, 0),
(1, 3), (-1, 3), (3, 1), (-3, 1), (2, 3), (-2, 3), (3, 2),
(-3, 2), (0, 4), (4, 0), (1, 4), (-1, 4), (4, 1), (-4, 1),
(3, 3), (-3, 3), (2, 4), (-2, 4), (4, 2), (-4, 2), (0, 5),
(3, 4), (-3, 4), (4, 3), (-4, 3), (5, 0), (1, 5), (-1, 5),
(5, 1), (-5, 1), (2, 5), (-2, 5), (5, 2), (-5, 2), (4, 4),
(-4, 4), (3, 5), (-3, 5), (5, 3), (-5, 3), (0, 6), (6, 0),
(1, 6), (-1, 6), (6, 1), (-6, 1), (2, 6), (-2, 6), (6, 2),
(-6, 2), (4, 5), (-4, 5), (5, 4), (-5, 4), (3, 6), (-3, 6),
(6, 3), (-6, 3), (0, 7), (7, 0), (1, 7), (-1, 7), (5, 5),
(-5, 5), (7, 1), (-7, 1), (4, 6), (-4, 6), (6, 4), (-6, 4),
(2, 7), (-2, 7), (7, 2), (-7, 2), (3, 7), (-3, 7), (7, 3),
(-7, 3), (5, 6), (-5, 6), (6, 5), (-6, 5), (8, 0), (4, 7),
(-4, 7), (7, 4), (-7, 4), (8, 1), (8, 2), (6, 6), (-6, 6),
(8, 3), (5, 7), (-5, 7), (7, 5), (-7, 5), (8, 4), (6, 7),
(-6, 7), (7, 6), (-7, 6), (8, 5), (7, 7), (-7, 7), (8, 6),
(8, 7)`;
const MAP = [...DIST.matchAll(/\((-?\d+),\s*(-?\d+)\)/g)].map((m) => [Number(m[1]), Number(m[2])]);

class Bits {
  constructor(buf, byteOffset) {
    this.b = buf;
    this.p = byteOffset * 8;
  }
  bit() {
    const v = (this.b[this.p >> 3] >> (this.p & 7)) & 1;
    this.p++;
    return v;
  }
  bits(n) {
    let v = 0;
    for (let i = 0; i < n; i++) v |= this.bit() << i;
    return v;
  }
}

function buildTree(lens, alphabetSize) {
  let maxLen = 0;
  for (let i = 0; i < alphabetSize; i++) if (lens[i] > maxLen) maxLen = lens[i];
  if (maxLen === 0) return { single: 0 };
  const blCount = new Array(maxLen + 1).fill(0);
  for (let i = 0; i < alphabetSize; i++) if (lens[i] > 0) blCount[lens[i]]++;
  const nextCode = new Array(maxLen + 1).fill(0);
  let code = 0;
  for (let bits = 1; bits <= maxLen; bits++) {
    code = (code + blCount[bits - 1]) << 1;
    nextCode[bits] = code;
  }
  const codes = [];
  let count = 0;
  for (let s = 0; s < alphabetSize; s++) {
    if (lens[s] > 0) {
      codes.push({ code: nextCode[lens[s]]++, len: lens[s], sym: s });
      count++;
    }
  }
  if (count === 1) return { single: codes[0].sym };
  return { codes, maxLen };
}

function decodeSym(tree, br) {
  if ("single" in tree) return tree.single;
  let code = 0;
  let len = 0;
  for (;;) {
    code = (code << 1) | br.bit();
    len++;
    const hit = tree.codes.find((c) => c.len === len && c.code === code);
    if (hit) return hit.sym;
    if (len > tree.maxLen) throw new Error("无效 Huffman 码");
  }
}

function readPrefix(br, alphabetSize, label) {
  const isSimple = br.bit();
  if (isSimple) {
    const num = br.bit() + 1;
    const is8 = br.bit();
    const s0 = is8 ? br.bits(8) : br.bits(1);
    if (num === 2) {
      const s1 = br.bits(8);
      const lens = new Array(alphabetSize).fill(0);
      lens[s0] = 1;
      lens[s1] = 1;
      return buildTree(lens, alphabetSize);
    }
    return { single: s0 };
  }
  const numCodeLengths = br.bits(4) + 4;
  const clLens = new Array(19).fill(0);
  for (let i = 0; i < numCodeLengths; i++) clLens[ORDER[i]] = br.bits(3);
  const clTree = buildTree(clLens, 19);
  let maxSymbol = alphabetSize;
  if (br.bit()) {
    const lengthNbits = 2 + 2 * br.bits(3);
    maxSymbol = 2 + br.bits(lengthNbits);
  }
  const lens = new Array(alphabetSize).fill(0);
  let idx = 0;
  while (idx < maxSymbol && idx < alphabetSize) {
    const sym = decodeSym(clTree, br);
    if (sym < 16) {
      lens[idx++] = sym;
    } else if (sym === 16) {
      const rep = 3 + br.bits(2);
      const prev = idx > 0 ? lens[idx - 1] : 8;
      for (let k = 0; k < rep && idx < alphabetSize; k++) lens[idx++] = prev;
    } else if (sym === 17) {
      const rep = 3 + br.bits(3);
      idx += rep;
    } else if (sym === 18) {
      const rep = 11 + br.bits(7);
      idx += rep;
    } else throw new Error("码长码越界");
  }
  return buildTree(lens, alphabetSize);
}

function prefixValue(br, prefix) {
  if (prefix < 4) return prefix + 1;
  const extraBits = (prefix - 2) >> 1;
  const offset = (2 + (prefix & 1)) << extraBits;
  return offset + br.bits(extraBits) + 1;
}

function decodeVp8l(buf, verbose = false) {
  // 找 VP8L chunk
  let pos = 12;
  let start = -1;
  while (pos + 8 <= buf.length) {
    const id = buf.readUInt32LE(pos);
    const size = buf.readUInt32LE(pos + 4);
    if (id === 0x4c385056) {
      start = pos + 8;
      break;
    }
    pos += 8 + size + (size & 1);
  }
  if (start < 0) throw new Error("无 VP8L chunk");
  if (buf[start] !== 0x2f) throw new Error("签名错");
  const br = new Bits(buf, start + 1);
  const width = br.bits(14) + 1;
  const height = br.bits(14) + 1;
  const alphaUsed = br.bit();
  const version = br.bits(3);
  if (verbose) console.log({ width, height, alphaUsed, version });
  const transforms = [];
  while (br.bit()) {
    const t = br.bits(2);
    transforms.push(t);
    if (verbose) console.log("transform", t);
    if (t === 2) continue;
    throw new Error(`transform ${t} 未实现`);
  }
  const useCache = br.bit();
  const cacheBits = useCache ? br.bits(4) : 0;
  const cacheSize = cacheBits ? 1 << cacheBits : 0;
  if (verbose) console.log({ useCache, cacheBits, cacheSize });
  const useMeta = br.bit();
  if (verbose) console.log({ useMeta });
  if (useMeta) throw new Error("meta 未实现");
  const green = readPrefix(br, 256 + 24 + cacheSize, "green");
  const red = readPrefix(br, 256, "red");
  const blue = readPrefix(br, 256, "blue");
  const alpha = readPrefix(br, 256, "alpha");
  const dist = readPrefix(br, 40, "dist");
  if (verbose) console.log("trees ok, bitpos", br.p);
  const n = width * height;
  const px = new Array(n).fill(0);
  const cache = new Array(cacheSize).fill(0);
  let i = 0;
  let symCount = 0;
  while (i < n) {
    const g = decodeSym(green, br);
    symCount++;
    if (g < 256) {
      const r = decodeSym(red, br);
      const b = decodeSym(blue, br);
      const a = decodeSym(alpha, br);
      const argb = ((a << 24) | (b << 16) | (g << 8) | r) >>> 0;
      px[i++] = argb;
      if (cacheSize) cache[(Math.imul(argb | 0, 0x1e35a7bd) >>> (32 - cacheBits)) & (cacheSize - 1)] = argb;
    } else if (g < 256 + 24) {
      const len = prefixValue(br, g - 256);
      const dc = prefixValue(br, decodeSym(dist, br));
      let d = dc - 120;
      if (dc <= 120) {
        const [xi, yi] = MAP[dc - 1];
        d = xi + yi * width;
        if (d < 1) d = 1;
      }
      if (verbose && symCount < 10) console.log({ sym: g, len, dcode: dc, dist: d, at: i });
      for (let k = 0; k < len && i < n; k++) {
        const argb = px[i - d];
        px[i++] = argb;
        if (cacheSize) cache[(Math.imul(argb | 0, 0x1e35a7bd) >>> (32 - cacheBits)) & (cacheSize - 1)] = argb;
      }
    } else {
      const idx = g - 280;
      px[i++] = cache[idx];
    }
  }
  if (transforms.includes(2)) {
    for (let k = 0; k < n; k++) {
      const argb = px[k];
      const a = (argb >>> 24) & 0xff;
      const r = (argb + ((argb >>> 8) & 0xff)) & 0xff;
      const g = (argb >>> 8) & 0xff;
      const b = ((argb >>> 16) & 0xff) + g;
      px[k] = ((a << 24) | ((b & 0xff) << 16) | (g << 8) | r) >>> 0;
    }
  }
  return { width, height, px };
}

const file = process.argv[2];
const buf = fs.readFileSync(file);
const res = decodeVp8l(buf, true);
console.log("decoded", res.width, res.height, "px[0] =", res.px[0].toString(16));
const out = [];
for (const v of res.px) {
  out.push(v & 0xff, (v >>> 8) & 0xff, (v >>> 16) & 0xff, (v >>> 24) & 0xff);
}
fs.writeFileSync(file.replace(/\.webp$/, ".node.raw"), Buffer.from(out));
