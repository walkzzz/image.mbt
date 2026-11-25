import fs from "node:fs";

const p1 = "image.codec/codec/webp_vp8l_encoder_core.mbt";
let a = fs.readFileSync(p1, "utf8");
a = a.replace("fn vp8l_tokenize(pixels : Array[Int], width : Int) -> Vp8lTokenStream {", "fn vp8l_tokenize(pixels : Array[Int]) -> Vp8lTokenStream {");
a = a.replace("let tok = vp8l_tokenize(pixels, width)", "let tok = vp8l_tokenize(pixels)");
fs.writeFileSync(p1, a, "utf8");

const p2 = "image.codec/codec/webp_vp8l_encoder_transforms.mbt";
let b = fs.readFileSync(p2, "utf8");
b = b.replace("  packed_width : Int\n  width_bits : Int\n}", "  packed_width : Int\n}");
b = b.replace("Some(Vp8lPalette::{ colors, packed, packed_width, width_bits })", "Some(Vp8lPalette::{ colors, packed, packed_width })");
b = b.replace("fn vp8l_encode_palette_variant(\n  pixels : Array[Int],\n  w : Int,", "fn vp8l_encode_palette_variant(\n  w : Int,");
b = b.replace("vp8l_encode_palette_variant(pixels, w, h, pal, alpha_solid)", "vp8l_encode_palette_variant(w, h, pal, alpha_solid)");
fs.writeFileSync(p2, b, "utf8");
console.log("cleaned warnings");
