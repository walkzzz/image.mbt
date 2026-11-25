// 修正 M2 编码器：单符号树不写每位符号
import fs from "node:fs";

const p = "image.codec/codec/webp_vp8l_lz77_encode.mbt";
let t = fs.readFileSync(p, "utf8");

const helper = `///|
/// 判断码表是否只有一个符号（单符号树的符号位宽为 0，编码时不得写任何比特）
fn vp8l_is_single(lens : Array[Int], alphabet : Int) -> Bool {
  let mut count = 0
  for i in 0..<alphabet {
    if lens[i] > 0 {
      count += 1
    }
  }
  count <= 1
}

///|
/// 32 位像素哈希（4096 槽）`;
t = t.replace(`///|
/// 32 位像素哈希（4096 槽）`, helper);

t = t.replace(
  `  vp8l_write_prefix_table(bw, glens, 280)`,
  `  let g_single = vp8l_is_single(glens, 280)
  let r_single = vp8l_is_single(rlens, 256)
  let b_single = vp8l_is_single(blens, 256)
  let a_single = vp8l_is_single(alens, 256)
  let d_single = vp8l_is_single(dlens, 40)
  vp8l_write_prefix_table(bw, glens, 280)`,
);

t = t.replace(
  `      vp8l_write_code(bw, gcodes[g], glens[g])
      vp8l_write_code(bw, rcodes[r], rlens[r])
      vp8l_write_code(bw, bcodes[b], blens[b])
      vp8l_write_code(bw, acodes[a], alens[a])`,
  `      if !g_single {
        vp8l_write_code(bw, gcodes[g], glens[g])
      }
      if !r_single {
        vp8l_write_code(bw, rcodes[r], rlens[r])
      }
      if !b_single {
        vp8l_write_code(bw, bcodes[b], blens[b])
      }
      if !a_single {
        vp8l_write_code(bw, acodes[a], alens[a])
      }`,
);

t = t.replace(
  `      let (prefix, extra, ebits) = vp8l_encode_length(len)
      vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      bw.write(extra, ebits)
      let dcode = vp8l_distance_code(v2[t], w)
      let (dprefix, dextra, debits) = vp8l_encode_length(dcode)
      vp8l_write_code(bw, dcodes[dprefix], dlens[dprefix])
      bw.write(dextra, debits)`,
  `      let (prefix, extra, ebits) = vp8l_encode_length(len)
      vp8l_write_code(bw, gcodes[256 + prefix], glens[256 + prefix])
      bw.write(extra, ebits)
      let dcode = vp8l_distance_code(v2[t], w)
      if !d_single {
        let (dprefix, dextra, debits) = vp8l_encode_length(dcode)
        vp8l_write_code(bw, dcodes[dprefix], dlens[dprefix])
        bw.write(dextra, debits)
      }`,
);

fs.writeFileSync(p, t, "utf8");
console.log("patched single-symbol bit skip");
