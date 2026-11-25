import fs from "node:fs";

const files = [
  "image.codec/codec/webp_encode_test.mbt",
  "image.codec/codec/webp_vp8_encode_test.mbt",
  "image.codec/codec/webp_vp8_decode_roundtrip_test.mbt",
  "image.codec/codec/webp_vp8_decode_wbtest.mbt",
];
for (const f of files) {
  let t = fs.readFileSync(f, "utf8");
  const lines = t.split(/\r?\n/);
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (/^test "/.test(line)) {
      const prev = out.length ? out[out.length - 1] : "";
      if (!prev.includes('#warnings("-deprecated")')) out.push('#warnings("-deprecated")');
    }
    out.push(line);
  }
  fs.writeFileSync(f, out.join("\n"), "utf8");
  console.log("patched", f);
}
