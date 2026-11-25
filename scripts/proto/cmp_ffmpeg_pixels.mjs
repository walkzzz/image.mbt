import fs from "node:fs";
import { execFileSync } from "node:child_process";

const pairs = [
  ["solid_enc.webp", "solid_64_libwebp.webp"],
  ["checker_enc.webp", "checker_256_libwebp.webp"],
  ["grad_enc.webp", "grad64.webp"],
  ["noise64.raw", null],
];
const ff = (args) =>
  execFileSync("ffmpeg", args, { stdio: ["ignore", "ignore", "pipe"] });

function decode(file, out) {
  ff(["-v", "error", "-y", "-i", file, "-f", "rawvideo", "-pix_fmt", "rgba", out]);
  return fs.readFileSync(out);
}

for (const [a, b] of pairs) {
  if (!b) continue;
  const ra = decode(`_build/proto/${a}`, `_build/proto/${a}.a.raw`);
  const rb = decode(`_build/proto/${b}`, `_build/proto/${b}.b.raw`);
  let bad = 0;
  if (ra.length !== rb.length) {
    console.log(`${a}: LEN MISMATCH ${ra.length} vs ${rb.length}`);
    continue;
  }
  for (let i = 0; i < ra.length; i++) if (ra[i] !== rb[i]) bad++;
  console.log(`${a} vs ${b}: 字节差异=${bad} / ${ra.length}`);
}
