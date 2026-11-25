import fs from "node:fs";

// 1) core 里宽度参数改为 Int
const core = "image.codec/codec/webp_vp8l_encoder_core.mbt";
let c = fs.readFileSync(core, "utf8");
c = c.replace("fn vp8l_tokenize(pixels : Array[Int], width : Int32) -> Vp8lTokenStream {", "fn vp8l_tokenize(pixels : Array[Int], width : Int) -> Vp8lTokenStream {");
c = c.replace("fn vp8l_write_image_stream(\n  bw : Vp8lBits,\n  pixels : Array[Int],\n  width : Int32,\n  level0 : Bool,\n) -> Unit {", "fn vp8l_write_image_stream(\n  bw : Vp8lBits,\n  pixels : Array[Int],\n  width : Int,\n  level0 : Bool,\n) -> Unit {");
fs.writeFileSync(core, c, "utf8");

// 2) 旧编码器改成薄封装
const p = "image.codec/codec/webp_vp8l_lz77_encode.mbt";
let t = fs.readFileSync(p, "utf8");
const idx = t.indexOf("///|\n/// M2 编码器：贪心 LZ77");
if (idx < 0) {
  throw new Error("encoder entry not found");
}
const wrapper = `///|
/// M2 编码器：贪心 LZ77 + 频次驱动 Huffman（无变换）。
///
/// 变换版本见 encode_webp_lossless。
pub fn encode_webp_vp8l_lz77(img : @types.Image) -> Bytes raise @types.LoadError {
  let (pixels, w, h) = vp8l_pack_argb(img)
  let mut alpha_solid = true
  for i in 0..<pixels.length() {
    if vp8l_ch(pixels[i], 24) != 255 {
      alpha_solid = false
    }
  }
  let bw = Vp8lBits::new()
  bw.write(0x2F, 8)
  bw.write(w - 1, 14)
  bw.write(h - 1, 14)
  bw.write(if alpha_solid { 0 } else { 1 }, 1)
  bw.write(0, 3)
  bw.write(0, 1) // 无变换
  vp8l_write_image_stream(bw, pixels, w, true)
  vp8l_wrap_riff(bw.finish())
}
`;
t = t.slice(0, idx) + wrapper;
fs.writeFileSync(p, t, "utf8");
console.log("refactored encoder entry");
