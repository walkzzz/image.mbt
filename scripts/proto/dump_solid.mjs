import fs from "node:fs";
const hex = "524946461a000000574542505650384c0e0000002f3fc00f0038de45518adcffd47f";
fs.writeFileSync("_build/proto/solid_enc.webp", Buffer.from(hex, "hex"));
console.log("bytes", Buffer.from(hex, "hex").length);
