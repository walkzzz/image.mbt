import fs from "node:fs";
import { execFileSync } from "node:child_process";

const hex = fs
  .readFileSync("_build/proto/jpeg_enc.hex", "utf8")
  .trim()
  .replace(/[^0-9a-f]/gi, "");
fs.writeFileSync("_build/proto/jpeg_enc.jpg", Buffer.from(hex, "hex"));
execFileSync("ffmpeg", ["-v", "error", "-y", "-i", "_build/proto/jpeg_enc.jpg", "-f", "rawvideo", "-pix_fmt", "rgb24", "_build/proto/jpeg_enc.raw"]);
const raw = fs.readFileSync("_build/proto/jpeg_enc.raw");
console.log("ffmpeg decoded", raw.length, "bytes");
// 源像素（与 MoonBit 测试同一公式）
let maxDiff = 0;
for (let y = 0; y < 64; y++) {
  for (let x = 0; x < 64; x++) {
    const i = (y * 64 + x) * 3;
    const src = [x * 4 % 256, y * 4 % 256, (x + y) * 2 % 256];
    for (let c = 0; c < 3; c++) {
      const d = Math.abs(raw[i + c] - src[c]);
      if (d > maxDiff) maxDiff = d;
    }
  }
}
console.log("max channel diff vs source =", maxDiff);
