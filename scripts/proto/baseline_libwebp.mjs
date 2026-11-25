// 用 libwebp（ffmpeg -lossless）给同样的四种内容做体积基线
import fs from "node:fs";
import { execFileSync } from "node:child_process";

const W = 256, H = 256;
const cases = {
  solid: (x, y) => [40, 120, 200, 255],
  checker: (x, y) => {
    const v = (Math.floor(x / 8) + Math.floor(y / 8)) % 2;
    return v === 0 ? [30, 60, 90, 255] : [220, 190, 160, 255];
  },
  noise: null,
};

const dir = "_build/proto";
fs.mkdirSync(dir, { recursive: true });

let seed = 12345;
const noise = (x, y) => {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  const r = Math.floor(seed / 65536) % 256;
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  const g = Math.floor(seed / 65536) % 256;
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  const b = Math.floor(seed / 65536) % 256;
  return [r, g, b, 255];
};

for (const [name, fn] of Object.entries(cases)) {
  const gen = fn || noise;
  const files = [];
  for (const [w, h] of [[64, 64], [256, 256]]) {
    if (name === "noise" && w === 64) continue;
    seed = 12345;
    const buf = Buffer.alloc(w * h * 4);
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const px = name === "solid" ? [40, 120, 200, 255] : gen(x, y);
        buf.set(px, (y * w + x) * 4);
      }
    }
    const raw = `${dir}/${name}_${w}.raw`;
    fs.writeFileSync(raw, buf);
    const webp = `${dir}/${name}_${w}_libwebp.webp`;
    const png = `${dir}/${name}_${w}_libwebp.png`;
    execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", `${w}x${h}`, "-i", raw, "-lossless", "1", "-compression_level", "6", webp]);
    execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", `${w}x${h}`, "-i", raw, png]);
    files.push(`${name} ${w}x${h}: libwebp=${fs.statSync(webp).size} png=${fs.statSync(png).size} raw=${w * h * 4}`);
  }
  for (const f of files) console.log(f);
}
