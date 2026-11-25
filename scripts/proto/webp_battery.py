#!/usr/bin/env python3
"""WebP 无损解码回归：PIL(libwebp) / ffmpeg 编码 + imgtool 解码 + 与 Pillow 解码结果逐像素比对。

为什么拿 Pillow 解码同一份 webp 当基准：源图与 webp 内容不保证等价（Pillow 保存 RGBA
时会重排透明像素、ffmpeg 会做颜色空间转换），拿源图比会把编码器行为误判成解码 bug。

用法：
    python scripts/proto/webp_battery.py            # 全量（PIL 288 例 + ffmpeg 若干）
    python scripts/proto/webp_battery.py --quick    # 快速子集，改动解码器时先跑这个
"""
import os
import random
import subprocess
import sys

from PIL import Image, ImageChops

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXE = os.path.join(ROOT, "_build", "native", "release", "build", "walkzzz", "image.mbt", "cmd", "imgtool", "imgtool.exe")
OUT = os.path.join(ROOT, "_build", "proto", "webpbattery")
FFMPEG = r"C:\ProgramData\chocolatey\bin\ffmpeg.exe"


def src_image(kind, w, h):
    im = Image.new("RGBA", (w, h))
    px = im.load()
    rnd = random.Random(hash((kind, w, h)) & 0xFFFFFFFF)
    for y in range(h):
        for x in range(w):
            if kind == "palette16":
                i = (x // 8 + y // 8) % 16
                px[x, y] = (i * 16, 255 - i * 16, (i * 7) % 256, 255)
            elif kind == "palette4":
                i = (x // 5 + y // 3) % 4
                px[x, y] = (i * 60, i * 30, 255 - i * 60, 255)
            elif kind == "palette2":
                i = (x + y) % 2
                px[x, y] = (0, 0, 0, 255) if i else (255, 255, 255, 255)
            elif kind == "alpha":
                px[x, y] = (x % 256, y % 256, (x + y) % 256, (x * 3) % 256)
            elif kind == "gray":
                g = (x * 255) // max(1, w - 1)
                px[x, y] = (g, g, g, 255)
            elif kind == "noise":
                px[x, y] = (rnd.randrange(256), rnd.randrange(256), rnd.randrange(256), 255)
            elif kind == "noise_alpha":
                px[x, y] = (rnd.randrange(256), rnd.randrange(256), rnd.randrange(256), rnd.randrange(256))
            elif kind == "textui":
                # 近截图：白底 + 黑字条 + 少量彩色图标块，色数少但边缘多
                if (x % 37) < 6 and (y // 9) % 4 != 3 and y % 9 < 6:
                    px[x, y] = (32, 32, 32, 255)
                elif (x // 61) % 3 == 1 and (y // 61) % 3 == 1 and 20 < y % 61 < 40:
                    px[x, y] = ((x * 3) % 256, 90, 200, 255)
                else:
                    px[x, y] = (255, 255, 255, 255)
            else:  # photo-ish：平滑渐变 + 条纹 + 色块
                r = (x * 255) // max(1, w - 1)
                g = (y * 255) // max(1, h - 1)
                b = ((x // 16) % 2) * 120 + (y // 32) * 4
                px[x, y] = ((r + b) % 256, (g + 30) % 256, (b + 90) % 256, 255)
    return im


def check(webp_path, base):
    png = os.path.join(OUT, base + ".ours.png")
    r = subprocess.run([EXE, "decode", webp_path, png, "--format", "png"], capture_output=True, text=True)
    if r.returncode != 0 or '"ok":true' not in r.stdout:
        return "decode failed: " + (r.stdout.strip() or r.stderr.strip())[:120]
    a = Image.open(webp_path).convert("RGBA")
    b = Image.open(png).convert("RGBA")
    if a.size != b.size:
        return f"size {b.size} != {a.size}"
    hist = ImageChops.difference(a, b).histogram()
    bad = sum(hist[i] for i in range(len(hist)) if i % 256 != 0)
    mx = max((i % 256 for i in range(len(hist)) if hist[i]), default=0)
    return None if bad == 0 else f"{bad} 通道差异, maxdiff {mx}"


def pil_cases(quick):
    if quick:
        sizes = [(1, 1), (3, 7), (17, 17), (100, 37)]
        kinds = ["photo", "palette4", "alpha", "noise_alpha", "textui"]
        methods = [0, 6]
    else:
        sizes = [(1, 1), (2, 2), (3, 7), (7, 3), (16, 16), (17, 17), (31, 31), (64, 64),
                 (100, 37), (128, 128), (320, 240), (512, 384)]
        kinds = ["photo", "palette16", "palette4", "palette2", "alpha", "gray", "noise",
                 "noise_alpha", "textui"]
        methods = [0, 4, 6]
    cases = []
    for kind in kinds:
        for (w, h) in sizes:
            for m in methods:
                if kind in ("noise", "noise_alpha") and w * h > 16384:
                    continue
                cases.append((kind, w, h, m))
    return cases


def ffmpeg_cases():
    """"ffmpeg -c:v libwebp -lossless 1" 产物：与 Pillow 走的编码器参数不同，覆盖另一条路径。"""
    out = []
    for (w, h) in [(64, 64), (320, 240), (1024, 768)]:
        for src in ["testsrc2", "smptebars", "mandelbrot"]:
            out.append((src, w, h))
    return out


def main():
    quick = "--quick" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    total = 0
    ok = 0
    fail = []

    for kind, w, h, m in pil_cases(quick):
        im = src_image(kind, w, h)
        base = f"{kind}_{w}x{h}_m{m}"
        wp = os.path.join(OUT, base + ".webp")
        im.save(wp, lossless=True, quality=100, method=m)
        total += 1
        why = check(wp, base)
        if why:
            fail.append((base, why))
        else:
            ok += 1

    if not quick and os.path.exists(FFMPEG):
        for src, w, h in ffmpeg_cases():
            base = f"ff_{src}_{w}x{h}"
            wp = os.path.join(OUT, base + ".webp")
            r = subprocess.run(
                [FFMPEG, "-v", "error", "-y", "-f", "lavfi", "-i",
                 f"{src}=size={w}x{h}:rate=1", "-frames:v", "1", "-c:v", "libwebp", "-lossless", "1", wp],
                capture_output=True, text=True,
            )
            if r.returncode != 0:
                fail.append((base, "ffmpeg encode failed: " + r.stderr.strip()[:100]))
                total += 1
                continue
            total += 1
            why = check(wp, base)
            if why:
                fail.append((base, why))
            else:
                ok += 1

    print(f"cases={total} exact={ok} failed={len(fail)}")
    for name, why in fail[:20]:
        print("  FAIL", name, why)
    return 0 if not fail else 1


if __name__ == "__main__":
    sys.exit(main())
