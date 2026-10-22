#!/usr/bin/env python3
"""
Bastion Rush — draws the placeholder effect sprites (flat cartoon tones + dark
warm outline, Kingdom-Rush look) into godot/assets/art/fx_fallback/<name>.png.
The game uses them only while the real drawn art (assets/art/fx/<name>_<k>.png)
does not exist.   python3 pipeline/tools/make_fx_fallback.py
"""
import math
from pathlib import Path
from PIL import Image, ImageFilter

OUT = Path(__file__).resolve().parents[2] / "godot" / "assets" / "art" / "fx_fallback"
INK = (43, 26, 16, 255)
NONE = None


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def raster(w, h, paint, line):
    ss = 2  # supersample for smooth edges
    W, H = w * ss, h * ss
    fill = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = fill.load()
    for y in range(H):
        for x in range(W):
            c = paint((x + 0.5) / ss, (y + 0.5) / ss)
            if c:
                px[x, y] = c
    mask = fill.getchannel("A").filter(ImageFilter.MaxFilter(line * 2 * ss + 1))
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (W, H), INK), (0, 0), mask)
    out.alpha_composite(fill)
    return out.resize((w, h), Image.LANCZOS)


def tone(v, t):
    return t[0] if v < -0.35 else (t[1] if v < 0.3 else t[2])


def ball(s, tones):
    def f(x, y):
        r = s * 0.5 - 4
        px, py = x - s * 0.5, y - s * 0.5
        if math.hypot(px, py) > r:
            return NONE
        if math.hypot(px + r * 0.35, py + r * 0.35) < r * 0.22:
            return (255, 255, 255, 255)
        return tone((px + py) / (r * 1.4), tones)
    return f


def arrow(w, h, shaft, head, feather):
    head_d = tuple(int(c * 0.75) for c in head[:3]) + (255,)
    feather_d = tuple(int(c * 0.8) for c in feather[:3]) + (255,)

    def f(x, y):
        cy = h * 0.5
        hx = w - 4 - h * 0.9
        if hx < x < w - 4 and abs(y - cy) < (w - 4 - x) / (h * 0.9) * h * 0.36:
            return head if y < cy else head_d
        if 6 < x <= hx and abs(y - cy) < h * 0.09:
            return shaft
        if 4 < x < 4 + h * 1.1 and h * 0.05 < abs(y - cy) < h * 0.34 - (x - 4) * 0.12:
            return feather if y < cy else feather_d
        return NONE
    return f


def star(s):
    def f(x, y):
        px, py = x - s * 0.5, y - s * 0.5
        r = math.hypot(px, py)
        outer = (s * 0.5 - 5) * (0.62 + 0.38 * abs(math.cos(math.atan2(py, px) * 4)))
        if r > outer:
            return NONE
        return hexc("fff6c8") if r < outer * 0.42 else (hexc("ffd23a") if r < outer * 0.72 else hexc("ff8a2a"))
    return f


def puff(s):
    blobs = [(0.36, 0.58, 0.26), (0.62, 0.56, 0.3), (0.5, 0.36, 0.28), (0.5, 0.66, 0.24)]

    def f(x, y):
        hit = -1.0
        for bx, by, br in blobs:
            if math.hypot(x / s - bx, y / s - by) < br - 0.03:
                hit = max(hit, (by - y / s) / br)
        if hit < -0.99:
            return NONE
        return hexc("f2efe8") if hit > 0.25 else (hexc("d6d1c6") if hit > -0.35 else hexc("b5ae9f"))
    return f


def ring(s):
    def f(x, y):
        r = math.hypot(x - s * 0.5, y - s * 0.5) / (s * 0.5 - 3)
        if r > 1 or r < 0.8:
            return NONE
        return (255, 255, 255, 255) if r > 0.9 else hexc("d8d8d8")
    return f


def puddle(s):
    def f(x, y):
        px, py = x / s - 0.5, y / s - 0.5
        a = math.atan2(py, px)
        edge = 0.42 + 0.05 * math.sin(a * 5) + 0.03 * math.cos(a * 3)
        r = math.hypot(px, py)
        if r > edge:
            return NONE
        for bx, by, br in [(-0.12, -0.08, 0.05), (0.1, 0.06, 0.04), (0.02, -0.18, 0.03)]:
            if math.hypot(px - bx, py - by) < br:
                return hexc("d8ffb0")
        return hexc("9be24d") if r < edge * 0.55 else (hexc("6fc23a") if r < edge * 0.85 else hexc("4f9a2a"))
    return f


def zap(w, h):
    def f(x, y):
        t = x / w
        cy = h * 0.5 + math.sin(t * 31) * h * 0.22 + math.sin(t * 11 + 1.3) * h * 0.12
        d = abs(y - cy)
        if x < 2 or x > w - 2 or d > h * 0.16:
            return NONE
        return (255, 255, 255, 255) if d < h * 0.07 else hexc("8fdcff")
    return f


def shadow():
    img = Image.new("RGBA", (64, 64))
    px = img.load()
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 31.5
            px[x, y] = (20, 13, 5, int(max(0.0, min(1.0, (1 - d) * 2)) * 0.4 * 255))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = {
        "arrow": lambda: raster(128, 32, arrow(128, 32, hexc("8a5a32"), hexc("cfd6dc"), hexc("f4ece0")), 2),
        "bolt": lambda: raster(160, 40, arrow(160, 40, hexc("6e4526"), hexc("aab4bc"), hexc("3a6ab0")), 3),
        "orb": lambda: raster(64, 64, ball(64, [hexc("ffffff"), hexc("e6e6e6"), hexc("bdbdbd")]), 3),
        "cannonball": lambda: raster(64, 64, ball(64, [hexc("6a6e78"), hexc("3c4048"), hexc("25282e")]), 3),
        "burst": lambda: raster(128, 128, star(128), 3),
        "smoke": lambda: raster(128, 128, puff(128), 3),
        "ring": lambda: raster(128, 128, ring(128), 2),
        "puddle": lambda: raster(128, 128, puddle(128), 3),
        "zap": lambda: raster(128, 32, zap(128, 32), 2),
        "shadow": shadow,
    }
    for name, make in jobs.items():
        make().save(OUT / ("%s.png" % name), optimize=True)
        print("OK", name)


if __name__ == "__main__":
    main()
