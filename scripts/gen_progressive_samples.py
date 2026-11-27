#!/usr/bin/env python3
# gen_progressive_samples.py — 生成 progressive JPEG 基准样本（F-05 / F-03）
#
# 为什么用 Python 而不是 benchmarks/gen：MoonBit 侧编码器只输出 baseline JPEG
# （见 docs/roadmap.md F-01），无法产出 SOF2 多扫描样本。本脚本用 Pillow 生成的
# 样本只用于**解码回归**（验证 image.codec 能解 progressive 与 progressive+RST），
# 不参与编码基准。参数与像素算法在此写死，保证可复现。
#
# 用法：python scripts/gen_progressive_samples.py
# 输出：benchmarks/golden/g25_jpeg_progressive_640x400.jpg
#       benchmarks/golden/g26_jpeg_progressive_restart_480x320.jpg
#
# 依赖：Pillow（>= 10.0，需支持 progressive=True 与 restart_marker_blocks）

import hashlib
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "benchmarks" / "golden"


def rgb_grad(w: int, h: int) -> Image.Image:
    """确定性渐变：R 随 x、G 随 y、B 随 x+y（与 benchmarks/gen 的 rgb_grad 同构）。"""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = (
                (x * 255) // max(1, w - 1),
                (y * 255) // max(1, h - 1),
                ((x + y) * 255) // max(1, (w - 1) + (h - 1)),
            )
    return img


def emit(name: str, img: Image.Image, **save_kw) -> None:
    path = GOLDEN / name
    img.save(path, format="JPEG", **save_kw)
    data = path.read_bytes()
    if len(data) > 400 * 1024:
        sys.exit(f"{name}: {len(data)} B 超过单文件上限 400 KiB")
    print(f"{name}  {len(data)} B  sha256={hashlib.sha256(data).hexdigest()}")


def main() -> None:
    if not GOLDEN.is_dir():
        sys.exit(f"缺少目录 {GOLDEN}")
    # g25：普通 progressive（SOF2，多次扫描）
    emit("g25_jpeg_progressive_640x400.jpg", rgb_grad(640, 400), quality=80, progressive=True)
    # g26：progressive + restart interval（SOF2 + DRI，验证 jpeg_skip_to_restart 在多扫描下有效）
    emit(
        "g26_jpeg_progressive_restart_480x320.jpg",
        rgb_grad(480, 320),
        quality=75,
        progressive=True,
        restart_marker_blocks=8,
    )


if __name__ == "__main__":
    main()
