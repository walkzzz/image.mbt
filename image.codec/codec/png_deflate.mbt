///|
/// # PNG 用的 DEFLATE（fixed Huffman + LZ77）
///
/// 此前 `png_encode` 用 stored block（无压缩），640×360 的图能写出 691 KB，
/// 且因 CRC 算术右移错误，外部工具（PIL/ffmpeg）根本打不开。这里给出一个
/// 可用的压缩器：单个 fixed-Huffman 块 + 32 KB 窗口的 hash-chain LZ77，
/// 输出是标准 RFC 1951/1950 流，`zlib.decompress` / PIL / ffmpeg 均可读。
///
/// 定位：够用且确定性，不为极致压缩率做 optimal parse（那是后续 Sprint 的事）。

///|
/// LSB-first 位写入器；Huffman 码需先按 MSB 顺序反转再写入。
priv struct BitWriter {
  out : Array[Byte]
  mut buf : Int32
  mut cnt : Int32
}

///|
fn BitWriter::new() -> BitWriter {
  { out: [], buf: 0, cnt: 0 }
}

///|
fn BitWriter::put(self : BitWriter, value : Int32, nbits : Int32) -> Unit {
  self.buf = self.buf | ((value & ((1 << nbits) - 1)) << self.cnt)
  self.cnt += nbits
  while self.cnt >= 8 {
    self.out.push((self.buf & 0xFF).to_byte())
    self.buf = (self.buf >> 8) & 0x00FFFFFF
    self.cnt -= 8
  }
}

///|
fn BitWriter::put_huff(self : BitWriter, code : Int32, nbits : Int32) -> Unit {
  let mut rev = 0
  let mut i = 0
  while i < nbits {
    rev = (rev << 1) | ((code >> i) & 1)
    i += 1
  }
  self.put(rev, nbits)
}

///|
fn BitWriter::finish(self : BitWriter) -> Bytes {
  if self.cnt > 0 {
    self.out.push((self.buf & 0xFF).to_byte())
    self.buf = 0
    self.cnt = 0
  }
  Bytes::from_array(self.out)
}

///|
/// fixed Huffman 字面/长度码（RFC 1951 §3.2.6）。
fn put_litlen(bw : BitWriter, sym : Int32) -> Unit {
  if sym <= 143 {
    bw.put_huff(0x30 + sym, 8)
  } else if sym <= 255 {
    bw.put_huff(0x190 + (sym - 144), 9)
  } else if sym <= 279 {
    bw.put_huff(sym - 256, 7)
  } else {
    bw.put_huff(0xC0 + (sym - 280), 8)
  }
}

///|
fn len_base(i : Int32) -> Int32 {
  match i {
    0 => 3
    1 => 4
    2 => 5
    3 => 6
    4 => 7
    5 => 8
    6 => 9
    7 => 10
    8 => 11
    9 => 13
    10 => 15
    11 => 17
    12 => 19
    13 => 23
    14 => 27
    15 => 31
    16 => 35
    17 => 43
    18 => 51
    19 => 59
    20 => 67
    21 => 83
    22 => 99
    23 => 115
    24 => 131
    25 => 163
    26 => 195
    27 => 227
    _ => 258
  }
}

///|
fn len_extra(i : Int32) -> Int32 {
  if i <= 7 {
    0
  } else if i <= 11 {
    1
  } else if i <= 15 {
    2
  } else if i <= 19 {
    3
  } else if i <= 23 {
    4
  } else if i <= 27 {
    5
  } else {
    0
  }
}

///|
fn dist_base(i : Int32) -> Int32 {
  match i {
    0 => 1
    1 => 2
    2 => 3
    3 => 4
    4 => 5
    5 => 7
    6 => 9
    7 => 13
    8 => 17
    9 => 25
    10 => 33
    11 => 49
    12 => 65
    13 => 97
    14 => 129
    15 => 193
    16 => 257
    17 => 385
    18 => 513
    19 => 769
    20 => 1025
    21 => 1537
    22 => 2049
    23 => 3073
    24 => 4097
    25 => 6145
    26 => 8193
    27 => 12289
    28 => 16385
    _ => 24577
  }
}

///|
fn dist_extra(i : Int32) -> Int32 {
  if i <= 3 {
    0
  } else {
    (i - 2) / 2
  }
}

///|
fn hash3(data : Bytes, pos : Int32) -> Int32 {
  let a = data[pos].to_int()
  let b = data[pos + 1].to_int()
  let c = data[pos + 2].to_int()
  ((a * 0x9E37 + b * 0x1B1 + c) & 0x7FFF)
}

///|
/// 原始 DEFLATE 流（单块，BTYPE=01）。
fn deflate_fixed(data : Bytes) -> Bytes {
  let n = data.length()
  let bw = BitWriter::new()
  // BFINAL=1, BTYPE=01
  bw.put(1, 1)
  bw.put(1, 2)
  let head : Array[Int32] = Array::make(32768, -1)
  let prev : Array[Int32] = Array::make(32768, -1)
  let mut pos = 0
  while pos < n {
    let mut best_len = 0
    let mut best_dist = 0
    if pos + 2 < n {
      let h = hash3(data, pos)
      let mut cand = head[h]
      let mut chain = 0
      let max_match = if n - pos > 258 { 258 } else { n - pos }
      while cand >= 0 && chain < 32 && pos - cand <= 32768 {
        let mut l = 0
        while l < max_match && data[cand + l] == data[pos + l] {
          l += 1
        }
        if l > best_len && l >= 3 {
          best_len = l
          best_dist = pos - cand
        }
        if best_len >= max_match {
          break
        }
        cand = prev[cand & 0x7FFF]
        chain += 1
      }
    }
    if best_len >= 3 {
      // 长度码
      let mut li = 0
      while li < 28 && len_base(li + 1) <= best_len {
        li += 1
      }
      put_litlen(bw, 257 + li)
      let eb = len_extra(li)
      if eb > 0 {
        bw.put(best_len - len_base(li), eb)
      }
      // 距离码
      let mut di = 0
      while di < 29 && dist_base(di + 1) <= best_dist {
        di += 1
      }
      bw.put_huff(di, 5)
      let deb = dist_extra(di)
      if deb > 0 {
        bw.put(best_dist - dist_base(di), deb)
      }
      // 把匹配覆盖的所有位置都插入哈希表
      let mut k = 0
      while k < best_len {
        if pos + k + 2 < n {
          let h2 = hash3(data, pos + k)
          prev[(pos + k) & 0x7FFF] = head[h2]
          head[h2] = pos + k
        }
        k += 1
      }
      pos += best_len
    } else {
      put_litlen(bw, data[pos].to_int())
      if pos + 2 < n {
        let h = hash3(data, pos)
        prev[pos & 0x7FFF] = head[h]
        head[h] = pos
      }
      pos += 1
    }
  }
  // 块结束符号 256
  put_litlen(bw, 256)
  bw.finish()
}

///|
/// zlib 包装（RFC 1950）：CMF/FLG + DEFLATE + Adler-32。
pub fn zlib_compress(data : Bytes) -> Bytes {
  let body = deflate_fixed(data)
  let out : Array[Byte] = []
  // CMF=0x78, FLG=0x9C（默认压缩级别，0x789C % 31 == 0）
  out.push(b'\x78')
  out.push(b'\x9C')
  for i in 0..<body.length() {
    out.push(body[i])
  }
  let adler = @util.adler32(data)
  out.push(((adler >> 24) & 0xFF).to_byte())
  out.push(((adler >> 16) & 0xFF).to_byte())
  out.push(((adler >> 8) & 0xFF).to_byte())
  out.push((adler & 0xFF).to_byte())
  Bytes::from_array(out)
}
