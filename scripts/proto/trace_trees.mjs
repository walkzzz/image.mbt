import fs from "node:fs";

const file = process.argv[2];
const buf = fs.readFileSync(file);
const start = 20;
let bitpos = (start + 1) * 8;
const read = (n) => {
  let v = 0;
  for (let i = 0; i < n; i++) {
    const bit = (buf[bitpos >> 3] >> (bitpos & 7)) & 1;
    v |= bit << i;
    bitpos++;
  }
  return v;
};

console.log("w", read(14) + 1, "h", read(14) + 1, "alpha", read(1), "ver", read(3));
const hasT = read(1);
console.log("transform", hasT ? read(2) : "none");
const cache = read(1);
let cacheBits = 0;
if (cache) cacheBits = read(4);
const meta = read(1);
console.log({ cache, cacheBits, meta, bitpos });

const ORDER = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
function readTree(name, alphabet) {
  const simple = read(1);
  if (simple) {
    const n = read(1) + 1;
    const first8 = read(1);
    const s0 = first8 ? read(8) : read(1);
    let s1 = -1;
    if (n === 2) s1 = read(8);
    console.log(
      `${name}: SIMPLE n=${n} s0=${s0} s1=${s1} sym0_is8=${first8} bitpos=${bitpos}`,
    );
    return;
  }
  const numCL = 4 + read(4);
  const clLens = new Array(19).fill(0);
  for (let i = 0; i < numCL; i++) clLens[ORDER[i]] = read(3);
  const useMax = read(1);
  let maxSymbol = alphabet;
  if (useMax) maxSymbol = 2 + read(3) * 8 + read(7);
  const lens = [];
  let prev = 8;
  while (lens.length < maxSymbol) {
    const code = "cad"; // placeholder
    // decode cl tree
    break;
  }
  console.log(
    `${name}: NORMAL numCL=${numCL} clLens=${JSON.stringify(clLens)} maxSym=${maxSymbol} bitpos=${bitpos}`,
  );
  return { clLens, maxSymbol };
}

const G = 256 + 24 + (cache ? 1 << cacheBits : 0);
readTree("green", G);
readTree("red", 256);
readTree("blue", 256);
readTree("alpha", 256);
readTree("dist", 40);
console.log("trees done bitpos", bitpos);
