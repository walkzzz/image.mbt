// 校验 M1 产物：ffmpeg 解出的 RGBA 必须与源图逐字节一致。
import fs from "node:fs";
import { execFileSync } from "node:child_process";

function makeImage(W, H) {
  const rgba = new Uint8Array(W * H * 4);
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const i = (y * W + x) * 4;
      rgba[i] = (x * 255 / Math.max(1, W - 1)) | 0;
      rgba[i + 1] = (y * 255 / Math.max(1, H - 1)) | 0;
      rgba[i + 2] = ((x + y) * 3) & 0xff;
      rgba[i + 3] = 255;
    }
  }
  return rgba;
}

for (const size of [16, 64, 1024]) {
  const file = `_build/proto/m1_${size}.webp`;
  const raw = `_build/proto/m1_${size}.raw`;
  execFileSync("ffmpeg", ["-v", "error", "-y", "-i", file, "-f", "rawvideo", "-pix_fmt", "rgba", raw], {
    stdio: ["ignore", "ignore", "inherit"],
  });
  const got = new Uint8Array(fs.readFileSync(raw));
  const want = makeImage(size, size);
  if (got.length !== want.length) {
    console.log(`${size}: 尺寸不符 got=${got.length} want=${want.length}`);
    continue;
  }
  let diff = 0;
  let firstBad = -1;
  for (let i = 0; i < got.length; i++) {
    if (got[i] !== want[i]) {
      diff++;
      if (firstBad < 0) firstBad = i;
    }
  }
  const px = firstBad >= 0 ? `(x=${Math.floor((firstBad / 4) % size)}, y=${Math.floor(firstBad / 4 / size)}, c=${firstBad % 4})` : "";
  console.log(`${size}: ${diff === 0 ? "像素逐字节一致" : `差 ${diff} 字节，首个 ${firstBad} ${px}`}`);
}
