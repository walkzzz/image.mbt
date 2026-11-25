#!/usr/bin/env python3
"""生成 VP8L 回归样本：码长码（19 符号字母表）只有 16 号一个符号 → 单叶子零比特。

背景：`noise_17x17_m0.webp` 等噪声图里 libwebp 会给红/蓝通道输出「256 个符号码长全等于 8」
的树，码长码只剩 16 号（重复上一个非零码长）一个符号。码长码是单叶子前缀码，按 RFC 9649
§3.7.2.1 解码**不消耗比特**；早期实现按 1 位读，整条流错位、报「前缀码树不完整」。

本脚本手工拼一份 4×4 的最小样本（绿/alpha 恒定，红蓝按 x+y 变化），输出前用 Pillow 解码校验，
校验通过后把字节数组贴进 `image.codec/codec/webp_vp8l_rfc_test.mbt`。

用法：python scripts/proto/gen_vp8l_fixtures.py
"""
import os
import struct

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "_build", "proto", "fixtures")


class W:
    def __init__(self):
        self.bits = []

    def put(self, value, n):
        for i in range(n):
            self.bits.append((value >> i) & 1)

    def put_code(self, code, n):
        """canonical 码：MSB 先写。"""
        for i in reversed(range(n)):
            self.bits.append((code >> i) & 1)

    def blob(self):
        out = bytearray()
        cur = 0
        cnt = 0
        for b in self.bits:
            cur |= b << cnt
            cnt += 1
            if cnt == 8:
                out.append(cur)
                cur = 0
                cnt = 0
        if cnt:
            out.append(cur)
        return bytes(out)


def canonical(lens):
    """按 RFC 9649 §3.7.2.1 生成 canonical 码表：{symbol: (code, len)}。"""
    max_len = max(lens) if lens else 0
    bl = [0] * (max_len + 1)
    for l in lens:
        if l:
            bl[l] += 1
    nxt = [0] * (max_len + 1)
    code = 0
    for bits in range(1, max_len + 1):
        code = (code + bl[bits - 1]) << 1
        nxt[bits] = code
    table = {}
    for sym, l in enumerate(lens):
        if l:
            table[sym] = (nxt[l], l)
            nxt[l] += 1
    return table


def simple1(w, sym, first8=True):
    w.put(1, 1)          # simple
    w.put(0, 1)          # num_symbols = 1
    w.put(1 if first8 else 0, 1)
    w.put(sym, 8 if first8 else 1)


def all_eight_tree(w, alphabet):
    """normal 码树：256 个符号码长全 8（只有 alphabet=256 时 Kraft 合法）。"""
    assert alphabet == 256
    cl_lens = [0] * 19
    cl_lens[16] = 1      # 码长码只剩 16 号一个符号 → 单叶子、零比特
    cl_order = [17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    # 写出 CL 描述：normal + num_cl=6（覆盖 order 前 6 项里我们用的 16 号需要 num_cl>=9）
    w.put(0, 1)          # normal
    w.put(9 - 4, 4)      # num_code_lengths = 9（order 前 9 项含 16）
    for name in cl_order[:9]:
        w.put(cl_lens[name], 3)
    w.put(0, 1)          # max_symbol 标志：未置位 → alphabet 个码
    # 每个码都是 16 号：3 + 2 位 = 最多 6 个 8。256 = 6*42 + 4
    for _ in range(42):
        w.put(6 - 3, 2)
    w.put(4 - 3, 2)
    # 平码表：所有 256 个符号长度 8，canonical 码即符号值本身
    return {sym: (sym, 8) for sym in range(256)}


def build(width=4, height=4):
    w = W()
    w.put(0x2F, 8)                       # VP8L 签名
    w.put(width - 1, 14)
    w.put(height - 1, 14)
    w.put(1, 1)                          # alpha 提示位
    w.put(0, 3)                          # version
    w.put(0, 1)                          # 无变换
    w.put(0, 1)                          # 无色彩缓存
    w.put(0, 1)                          # 无 meta 多组
    # 绿树：恒定 0x80 → simple1
    simple1(w, 0x80)
    red_tbl = all_eight_tree(w, 256)
    blue_tbl = all_eight_tree(w, 256)
    simple1(w, 0xFF)                     # alpha 恒定
    simple1(w, 0, first8=False)          # dist（用不到，1 位符号 0）
    # 像素：literal，绿 0x80、红蓝按 (x+y)、alpha 由树给 0xFF
    for y in range(height):
        for x in range(width):
            w.put_code(*red_tbl[(x + y) * 16 % 256])
            w.put_code(*blue_tbl[(x + y) * 8 % 256])
    payload = w.blob()
    body = b"VP8L" + struct.pack("<I", len(payload)) + payload + (b"\0" if len(payload) & 1 else b"")
    return b"RIFF" + struct.pack("<I", 4 + len(body)) + b"WEBP" + body


def main():
    os.makedirs(OUT, exist_ok=True)
    data = build()
    path = os.path.join(OUT, "cl16.webp")
    with open(path, "wb") as f:
        f.write(data)
    im = Image.open(path).convert("RGBA")
    px = im.load()
    bad = []
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            want = ((x + y) * 16 % 256, 0x80, (x + y) * 8 % 256, 255)
            if px[x, y] != want:
                bad.append((x, y, px[x, y], want))
    print("file:", path, "bytes:", len(data), "size:", im.size)
    print("pillow decode mismatch:", len(bad), bad[:4])
    print("bytes array:")
    for i in range(0, len(data), 12):
        print("    " + ", ".join("0x%02X" % b for b in data[i:i + 12]) + ",")


if __name__ == "__main__":
    main()
