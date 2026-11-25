import fs from "node:fs";
const w = 64,
  h = 64;
const b = Buffer.alloc(w * h * 4);
let seed = 12345;
for (let i = 0; i < w * h; i++) {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  b[i * 4] = (seed / 65536) % 256;
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  b[i * 4 + 1] = (seed / 65536) % 256;
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  b[i * 4 + 2] = (seed / 65536) % 256;
  b[i * 4 + 3] = 255;
}
fs.writeFileSync("_build/proto/noise64.raw", b);
console.log("noise raw ok");
