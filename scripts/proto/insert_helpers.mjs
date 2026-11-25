// 把距离映射表与 LZ77 辅助函数插入解码器源码（一次性）
import fs from "node:fs";

const p = "image.codec/codec/webp_vp8l_decode_rfc.mbt";
let t = fs.readFileSync(p, "utf8");
const snip = fs.readFileSync("scripts/proto/distance_table.mbt.snippet", "utf8");

const helpers = `${snip}
///|
/// LZ77 前缀码取值（RFC 9649 §3.6.2.2）
fn vp8l_prefix_value(br : BitReader, prefix : Int32) -> Int32 {
  if prefix < 4 {
    return prefix + 1
  }
  let extra_bits = (prefix - 2) >> 1
  let offset = (2 + (prefix & 1)) << extra_bits
  offset + br.read_bits(extra_bits) + 1
}

///|
/// 把距离码转成扫描行序距离（<120 走邻域映射，≥120 直接减 120）
fn vp8l_map_distance(code : Int32, width : Int32) -> Int32 {
  if code > 120 {
    return code - 120
  }
  let idx = code - 1
  if idx < 0 || idx >= 120 {
    return 1
  }
  let d = vp8l_distance_dx[idx] + vp8l_distance_dy[idx] * width
  if d < 1 { 1 } else { d }
}

`;

const marker = `///|
/// RFC 合规的 VP8L 解码`;
if (!t.includes(marker)) {
  console.log("marker not found");
  process.exit(1);
}
t = t.replace(marker, helpers + marker);
fs.writeFileSync(p, t, "utf8");
console.log("inserted");
