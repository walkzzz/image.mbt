// 把解码主循环换成 RFC 语义：literal / LZ77 长度-距离 / 色彩缓存索引
import fs from "node:fs";

const p = "image.codec/codec/webp_vp8l_decode_rfc.mbt";
let t = fs.readFileSync(p, "utf8");

const old = `  let dist = vp8l_read_prefix_code(br, 40)`;
if (!t.includes(old)) {
  console.log("dist tree line not found");
  process.exit(1);
}
t = t.replace(old, `  let dist_tree = vp8l_read_prefix_code(br, 40)`);

const oldLoop = `    } else if g == 256 {
      if cache_size == 0 {
        raise @types.LoadError::DecodeFailed("VP8L：出现色彩缓存索引但未启用缓存")
      }
      let idx = br.read_bits(cache_bits)
      pixels[i] = cache[idx]
      i += 1
    } else {
      let _ = dist
      raise @types.LoadError::DecodeFailed("VP8L：LZ77 反向引用尚未实现（symbol ≥ 257）")
    }`;

const newLoop = `    } else if g < 256 + 24 {
      // LZ77 反向引用：长度前缀码 + 距离前缀码
      let length = vp8l_prefix_value(br, g - 256)
      let dcode = vp8l_prefix_value(br, dist_tree.decode(br))
      let d = vp8l_map_distance(dcode, width)
      if d <= 0 || i - d < 0 {
        raise @types.LoadError::DecodeFailed("VP8L：反向引用距离越界")
      }
      let mut k = 0
      while k < length && i < n {
        let argb = pixels[i - d]
        pixels[i] = argb
        if cache_size > 0 {
          let prod = argb * 0x1E35A7BD
          cache[(prod >> (32 - cache_bits)) & (cache_size - 1)] = argb
        }
        i += 1
        k += 1
      }
    } else {
      // 色彩缓存索引：symbol = 256 + 24 + index
      if cache_size == 0 {
        raise @types.LoadError::DecodeFailed("VP8L：出现色彩缓存索引但未启用缓存")
      }
      let idx = g - 280
      if idx < 0 || idx >= cache_size {
        raise @types.LoadError::DecodeFailed("VP8L：色彩缓存索引越界")
      }
      pixels[i] = cache[idx]
      i += 1
    }`;

if (!t.includes(oldLoop)) {
  console.log("loop block not found");
  process.exit(1);
}
t = t.replace(oldLoop, newLoop);
fs.writeFileSync(p, t, "utf8");
console.log("patched LZ77");
