import fs from "node:fs";
const buf = Buffer.from(
  "524946461a000000574542505650384c0e0000002f3fc00f0038de45518adcffd47f",
  "hex",
);
const start = 20;
const base = (start + 1) * 8;
for (let i = 0; i < 60; i++) {
  const p = base + i;
  const bit = (buf[(p >> 3)] >> (p & 7)) & 1;
  process.stdout.write(String(bit));
  if (i % 8 === 7) process.stdout.write(" ");
}
console.log("\nbase bit", base, " (green tree starts at 203)");
