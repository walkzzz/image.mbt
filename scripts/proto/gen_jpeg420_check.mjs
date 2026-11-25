// Generate a temporary native checker: embed a real 4:2:0 JPEG plus sampled rgb24 bytes
// decoded by ffmpeg, then decode with this library and compare sampled channels.
// usage: node scripts/proto/gen_jpeg420_check.mjs [jpg]
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const jpg = process.argv[2] ?? "_build/proto/real420.jpg";
const outdir = process.argv[3] ?? "examples/_jpegcheck";
const src = fs.readFileSync(jpg);

const raw = "_build/proto/real420_ref.raw";
execFileSync("ffmpeg", ["-y", "-v", "error", "-i", jpg, "-f", "rawvideo", "-pix_fmt", "rgb24", raw]);
const ref = fs.readFileSync(raw);

const STEP = 16;
const sampled = Buffer.alloc(Math.ceil(ref.length / STEP));
for (let i = 0, k = 0; i < ref.length; i += STEP, k++) sampled[k] = ref[i];

const esc = (b) => "\\x" + b.toString(16).toUpperCase().padStart(2, "0");
const toLit = (buf) => 'b"' + Array.from(buf, esc).join("") + '"';

fs.mkdirSync(outdir, { recursive: true });
fs.writeFileSync(
  path.join(outdir, "main.mbt"),
  `// generated
fn main raise {
  let data : Bytes = ${toLit(src)}
  let expect : Bytes = ${toLit(sampled)}
  let img = @codec.decode_jpeg_pure(data)
  println("dims=\\{img.width}x\\{img.height} ch=\\{img.channels} sampled=\\{expect.length()}")
  let got = img.data
  let mut maxd = 0
  let mut sumd = 0
  let mut count = 0
  for i in 0..<expect.length() {
    let idx = i * ${STEP}
    if idx >= got.length() { break }
    let a = got[idx].to_int()
    let b = expect[i].to_int()
    let d = if a > b { a - b } else { b - a }
    if d > maxd { maxd = d }
    sumd = sumd + d
    count = count + 1
  }
  let mean = sumd.to_double() / count.to_double()
  println("max_channel_diff=\\{maxd} mean=\\{mean}")
}
`,
);
fs.writeFileSync(
  path.join(outdir, "moon.pkg"),
  `import {
  "walkzzz/image.codec/codec",
}

pkgtype(kind: "executable")
`,
);
console.log(`wrote ${outdir}: jpg=${src.length}B ref=${ref.length}B sampled=${sampled.length}B`);
