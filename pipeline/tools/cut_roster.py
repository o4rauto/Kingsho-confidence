#!/usr/bin/env python3
"""
Bastion Rush — cuts a character roster sheet (characters on parchment, a soft
grey shadow under each, the id written below) into one transparent PNG per
character: godot/assets/art/portraits/<id>.png.

    python3 pipeline/tools/cut_roster.py FOLHA.jpg id1 id2 id3 ...   (reading order)
    python3 pipeline/tools/cut_roster.py FOLHA.jpg ... --out /tmp/test   (try first)

Background and shadows are removed by flooding from the borders through
light, low-saturation, smooth pixels (the thick dark outline stops the flood);
enclosed pockets of parchment (inside a coiled tail, between arm and staff)
are removed too. Each character is a big blob; small blobs near it (sparks,
floating rocks) join it, and the name written under the feet is dropped.
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "godot" / "assets" / "art" / "portraits"


def _flood(allowed, seeds):
    h, w = allowed.shape
    flat = allowed.ravel()
    seen = np.zeros(h * w, bool)
    front = seeds[flat[seeds]]
    seen[front] = True
    while front.size:
        x = front % w
        nb = np.concatenate([front[x > 0] - 1, front[x < w - 1] + 1,
                             front[front >= w] - w, front[front < (h - 1) * w] + w])
        nb = np.unique(nb)
        nb = nb[flat[nb] & ~seen[nb]]
        seen[nb] = True
        front = nb
    return seen.reshape(h, w)


def _components(mask, min_area=1):
    """[(area, y0, y1, x0, x1, bool mask)] of the 4-connected blobs."""
    left = mask.copy()
    out = []
    flat = left.ravel()
    while True:
        i = int(np.argmax(flat))
        if not flat[i]:
            break
        comp = _flood(left, np.array([i]))
        left &= ~comp
        flat = left.ravel()
        ys, xs = np.nonzero(comp)
        if ys.size >= min_area:
            out.append((ys.size, ys.min(), ys.max() + 1, xs.min(), xs.max() + 1, comp))
    return out


def masks(rgb):
    h, w, _ = rgb.shape
    f = rgb.astype(np.int16)
    lum = f.mean(axis=2)
    sat = f.max(axis=2) - f.min(axis=2)
    gx = np.zeros((h, w), np.int16)
    gy = np.zeros((h, w), np.int16)
    gx[:, 1:] = np.abs(f[:, 1:] - f[:, :-1]).sum(axis=2)
    gy[1:, :] = np.abs(f[1:, :] - f[:-1, :]).sum(axis=2)
    grad = np.maximum(gx, gy)
    grad = np.maximum(grad, np.roll(grad, -1, 0))
    grad = np.maximum(grad, np.roll(grad, -1, 1))
    allowed = (lum > 118) & (sat < 72) & (grad < 120)
    seeds = np.concatenate([np.arange(w), (h - 1) * w + np.arange(w),
                            np.arange(h) * w, np.arange(h) * w + w - 1])
    bg = _flood(allowed, seeds)
    return bg, allowed & ~bg


def cut(sheet, names, out_dir=OUT):
    im = Image.open(sheet).convert("RGB")
    rgb = np.asarray(im)
    h, w, _ = rgb.shape
    bg, pockets = masks(rgb)
    fg = ~bg
    paper = rgb[bg].astype(float)
    paper_col = np.median(paper, axis=0)
    small = max(6, (h * w) // 200000)
    comps = [c for c in _components(fg, small) if c[4] - c[3] < w * 0.6]
    bodies = [c for c in comps if c[2] - c[1] > h * 0.06 and c[0] > h * w * 0.002
              and (c[1] + c[2]) / 2 > h * 0.1]
    # a body in floating pieces (a golem of loose rocks) is one character
    bodies.sort(key=lambda b: -b[0])
    merged = []
    for b in bodies:
        host = next((m for m in merged if b[0] < m[0] * 0.5
                     and max(m[1] - b[2], b[1] - m[2], m[3] - b[4], b[3] - m[4]) < h * 0.015), None)
        if host is None:
            merged.append(list(b))
        else:
            host[0] += b[0]
            host[1], host[2] = min(host[1], b[1]), max(host[2], b[2])
            host[3], host[4] = min(host[3], b[3]), max(host[4], b[4])
            host[5] = host[5] | b[5]
    bodies = [tuple(m) for m in merged]
    if len(bodies) != len(names):
        sys.exit("found %d characters, expected %d: %s"
                 % (len(bodies), len(names), [(b[1], b[3]) for b in bodies]))
    # reading order: rows (by vertical overlap), then left to right
    bodies.sort(key=lambda b: b[1])
    rows, cur = [], [bodies[0]]
    for b in bodies[1:]:
        if b[1] < np.mean([c[2] for c in cur]) - h * 0.03:
            cur.append(b)
        else:
            rows.append(cur)
            cur = [b]
    rows.append(cur)
    order = [b for r in rows for b in sorted(r, key=lambda b: b[3])]
    parts = {id(b): [b[5]] for b in order}
    top = min(b[1] for b in order)
    for c in comps:
        if any(c is b for b in order):
            continue
        cw_, ch_ = c[4] - c[3], c[2] - c[1]
        if cw_ > 8 * ch_ or ch_ > 8 * cw_:
            continue  # a ruled line / page frame, not a body part
        if c[2] <= top + h * 0.005 and c[2] - c[1] < h * 0.05:
            continue  # the sheet's title above everyone
        best, dist = None, 1e9
        for b in order:
            dx = max(b[3] - c[4], c[3] - b[4], 0)
            dy = max(b[1] - c[2], c[1] - b[2], 0)
            d = (dx * dx + dy * dy) ** 0.5
            if d < dist:
                best, dist = b, d
        bh = best[2] - best[1]
        bw = best[4] - best[3]
        if dist > bh * 0.18:
            continue  # a stray speck
        if c[3] < best[3] - bw * 0.3 or c[4] > best[4] + bw * 0.3:
            continue  # wider than the character: a title banner
        if c[1] >= best[2] - bh * 0.02:
            continue  # below its feet: the name
        cx = (c[3] + c[4]) / 2
        if any(c[1] >= b[2] - (b[2] - b[1]) * 0.02 and c[1] - b[2] < h * 0.07
               and b[3] - (b[4] - b[3]) * 0.3 <= cx <= b[4] + (b[4] - b[3]) * 0.3
               for b in order):
            continue  # the name written under the feet of the row above
        parts[id(best)].append(c[5])
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, b in zip(names, order):
        mask = np.zeros((h, w), bool)
        for p in parts[id(b)]:
            mask |= p
        ys, xs = np.nonzero(mask)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        mask = mask[y0:y1, x0:x1].copy()
        sub = rgb[y0:y1, x0:x1].astype(float)
        # enclosed parchment pockets
        for p in _components(pockets[y0:y1, x0:x1], 20):
            col = sub[p[5]].mean(axis=0)
            if np.abs(col - paper_col).max() < 16:
                mask &= ~p[5]
        a = Image.fromarray((mask * 255).astype(np.uint8))
        a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
        piece = im.crop((x0, y0, x1, y1)).convert("RGBA")
        piece.putalpha(a)
        piece.save(out_dir / ("%s.png" % name), optimize=True)
        print("OK %-16s %dx%d" % (name, piece.width, piece.height))


if __name__ == "__main__":
    args = sys.argv[1:]
    out = OUT
    if "--out" in args:
        i = args.index("--out")
        out = args[i + 1]
        del args[i:i + 2]
    if len(args) < 2:
        sys.exit(__doc__)
    cut(args[0], args[1:], out)
