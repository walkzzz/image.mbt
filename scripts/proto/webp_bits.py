#!/usr/bin/env python3
"""打印 VP8L 文件某比特区间的原始比特值（LSB-first 读取，按 bit index 展示）。"""
import sys

sys.path.insert(0, "scripts/proto")


def load_bits(path):
    data = open(path, "rb").read()
    pos = 12
    start = None
    while pos + 8 <= len(data):
        tag = data[pos:pos + 4]
        size = int.from_bytes(data[pos + 4:pos + 8], "little")
        if tag == b"VP8L":
            start = pos + 8
            break
        pos += 8 + size + (size & 1)
    # 展开全部比特（LSB-first 每字节）
    bits = []
    byte = start
    while byte < len(data):
        b = data[byte]
        for i in range(8):
            bits.append((b >> i) & 1)
        byte += 1
    return bits


def main():
    path = sys.argv[1]
    lo = int(sys.argv[2])
    hi = int(sys.argv[3])
    bits = load_bits(path)
    out = []
    for i in range(lo, hi):
        out.append(f"{i}:{bits[i]}")
    print(" ".join(out))


if __name__ == "__main__":
    main()
