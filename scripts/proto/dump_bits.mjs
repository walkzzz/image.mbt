import fs from "node:fs";
const hex = process.argv[2];
const buf = Buffer.from(hex, "hex");
const start = 20;
let bitpos = (start + 1) * 8;
function read(n) {
  let v = 0;
  for (let i = 0; i < n; i++) {
    const byte = buf[bitpos >> 3];
    const bit = (byte >> (bitpos & 7)) & 1; // LSB-first
    v |= bit << i;
    bitpos++;
  }
  return v;
}
console.log("sig", buf[start].toString(16));
console.log("w", read(14) + 1, "h", read(14) + 1, "alpha", read(1), "ver", read(3), "bitpos", bitpos);
console.log("transform-present", read(1), "type", read(2));
