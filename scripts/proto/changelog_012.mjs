import fs from "node:fs";

const entry = `## [0.1.2] - 2026-11-25

### Added

- **WebP VP8L lossless encoder**: \`encode_webp_lossless(img)\` — palette / predictor / subtract-green / LZ77 candidates, each encoded once and the smallest payload wins. Output byte-verified against libwebp via ffmpeg (solid / checker / gradient / noise).
- **VP8L RFC decoder path**: \`decode_webp_vp8l_rfc(bytes)\` — four inverse transforms (predictor 14 modes, cross-color, subtract-green, color indexing), meta prefix groups, color cache.

### Changed

- \`save_image\` / \`save_image_with_quality\` now route WebP to the lossless encoder; \`quality\` is ignored for WebP.
- \`encode_webp_lossy_pure\` / \`encode_webp_lossy_full\` marked \`#deprecated\` (invalid VP8 partitions, see GAP-27).
- Bench: \`webp_encode_1024\` now measures the lossless encoder (244.83 ms / 4.28 MP/s, x86 release).
- Docs: \`docs/performance.md\` rewritten WebP row and stale "331 MP/s" conclusion; \`docs/webp-encoder.md\` M3 log + volume table; \`docs/roadmap.md\` S02 closed.

### Fixed

- **simple code length code (2 symbols)**: first symbol must honour \`is_first_8bits\`; writing 8 bits unconditionally shifted the whole tree.
- **simple code only spans symbols [0..255]**: green tree mixes literals and length prefix codes — length symbols were silently truncated (279 → 23). Guard: all symbols < 256.
- **single leaf with symbol > 255 must use the normal code length code** (all other lengths zero, leaf length 1), per RFC 9649 §3.7.2.1.
- \`vp8l_residual_cost\`: hoisted the per-call array literal out of the 14-mode × pixel loop → predictor candidate 3.3x faster.

`;

let t = fs.readFileSync("CHANGELOG.md", "utf8");
const idx = t.indexOf("\n## [");
if (idx < 0) throw new Error("no version heading found");
t = t.slice(0, idx) + "\n" + entry + t.slice(idx + 1);
fs.writeFileSync("CHANGELOG.md", t, "utf8");
console.log("changelog updated");
