import fs from "node:fs";
import { decodeVp8l } from "./vp8l_decode_ref.mjs";

const buf = Buffer.from(
  "524946461a000000574542505650384c0e0000002f3fc00f0018de45518adcffd47f",
  "hex",
);
try {
  const img = decodeVp8l(buf, true);
  console.log("decoded", img.width, img.height, img.pixels.slice(0, 3));
} catch (e) {
  console.log("ref decode failed:", e.message);
}
