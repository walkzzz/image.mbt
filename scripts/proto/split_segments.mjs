// Split combined DQT/DHT segments into separate marker segments (libjpeg style),
// to test whether our decoder mis-parses multi-table segments.
import fs from "node:fs";

const src = fs.readFileSync("_build/proto/q90.jpg");
const out = [src.subarray(0, 2)];

let i = 2;
while (i < src.length - 1) {
  if (src[i] !== 0xff) {
    i++;
    continue;
  }
  const m = src[i + 1];
  if (m === 0xda || m === 0xd9) {
    out.push(src.subarray(i));
    break;
  }
  const len = src[i + 2] * 256 + src[i + 3];
  const seg = src.subarray(i, i + 2 + len);
  if (m === 0xdb && len > 67) {
    const body = seg.subarray(4);
    for (let p = 0; p < body.length; p += 65) {
      out.push(Buffer.from([0xff, 0xdb, 0x00, 67]));
      out.push(body.subarray(p, p + 65));
    }
  } else if (m === 0xc4 && len > 31) {
    const body = seg.subarray(4);
    let p = 0;
    while (p < body.length) {
      const counts = body.subarray(p + 1, p + 17);
      const total = [...counts].reduce((a, b) => a + b, 0);
      const one = body.subarray(p, p + 17 + total);
      out.push(Buffer.from([0xff, 0xc4, 0x00, one.length + 2]));
      out.push(one);
      p += 17 + total;
    }
  } else {
    out.push(seg);
  }
  i += 2 + len;
}

fs.writeFileSync("_build/proto/q90_split.jpg", Buffer.concat(out));
console.log("wrote q90_split.jpg", Buffer.concat(out).length);
