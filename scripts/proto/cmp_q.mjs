// Compare our encoded JPEGs (dumped by examples/_jpegcheck) against the source raw via ffmpeg.
import fs from "node:fs";
import { execFileSync } from "node:child_process";

const src = "_build/proto/q_src.raw";
const ref = fs.readFileSync(src);
for (const q of [50, 75, 90]) {
  const jpg = `_build/proto/q${q}.jpg`;
  execFileSync("ffmpeg", ["-y", "-v", "error", "-i", jpg, "-f", "rawvideo", "-pix_fmt", "rgb24", "_build/proto/q_ref.raw"]);
  const out = fs.readFileSync("_build/proto/q_ref.raw");
  let maxd = 0;
  let sum = 0;
  let count = 0;
  for (let i = 0; i < Math.min(out.length, ref.length); i += 4) {
    const d = Math.abs(out[i] - ref[i]);
    if (d > maxd) maxd = d;
    sum += d;
    count++;
  }
  console.log(`Q=${q} ffmpeg max_diff=${maxd} mean=${(sum / count).toFixed(2)} len=${out.length}`);
}
