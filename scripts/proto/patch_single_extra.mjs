import fs from "node:fs";

const p = "image.codec/codec/webp_vp8l_lz77_encode.mbt";
let t = fs.readFileSync(p, "utf8");

// 长度分支：单符号树仍要写 extra bits
t = t.replace(
  `      let (prefix, extra, ebits) = vp8l_encode_length(len)
      vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      bw.write(extra, ebits)`,
  `      let (prefix, extra, ebits) = vp8l_encode_length(len)
      if !g_single {
        vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      }
      bw.write(extra, ebits)`,
);

// 距离分支：单符号树仍要写 extra bits（此前整块跳过，extra 丢失）
t = t.replace(
  `      let dcode = vp8l_distance_code(v2[t], w)
      if !d_single {
        let (dprefix, dextra, debits) = vp8l_encode_length(dcode)
        vp8l_write_code(bw, dcodes[dprefix], dlens[dprefix])
        bw.write(dextra, debits)
      }`,
  `      let dcode = vp8l_distance_code(v2[t], w)
      let (dprefix, dextra, debits) = vp8l_encode_length(dcode)
      if !d_single {
        vp8l_write_code(bw, dcodes[dprefix], dlens[dprefix])
      }
      bw.write(dextra, debits)`,
);

// 关掉调试输出
t = t.replace("  let debug_tokens = true", "  let debug_tokens = false");

fs.writeFileSync(p, t, "utf8");
console.log("patched extra-bits for single-symbol trees");
