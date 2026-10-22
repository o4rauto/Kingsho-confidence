#!/usr/bin/env python3
"""
Bastion Rush — cuts a hand-drawn sprite sheet (frames side by side on a white
background) into the frame files the game plays:

  python3 pipeline/tools/split_sheet.py SHEET.png <id> <anim> [--frames N]
  -> godot/assets/art/anims/<id>/<anim>_0.png, _1.png ...

anim = idle | walk | attack | cast | hit | die | fly
Frames are found by the empty columns between them (or cut in N equal parts
with --frames), the white background is removed, every frame is scaled so the
smallest pose is 256 px tall (= the body height the game expects) and placed
bottom-centred on a shared canvas, so the feet never jump between frames.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from import_canva import strip_white, ART  # noqa: E402,F401

BODY = 256


def find_columns(im, n=None):
    w, h = im.size
    if n:
        return [(round(i * w / n), round((i + 1) * w / n)) for i in range(n)]
    alpha = im.getchannel("A").point(lambda v: 255 if v > 30 else 0)
    px = alpha.load()
    filled = [any(px[x, y] for y in range(0, h, 2)) for x in range(w)]
    runs, start = [], None
    for x, f in enumerate(filled + [False]):
        if f and start is None:
            start = x
        elif not f and start is not None:
            if x - start > w * 0.03:      # ignore specks
                runs.append((start, x))
            start = None
    # merge runs separated by tiny gaps (a sword tip, a loose spark)
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] < w * 0.015:
            merged[-1] = (merged[-1][0], r[1])
        else:
            merged.append(r)
    return merged


def split(im, cid, anim, n=None):
    """Cut a sheet image into anims/<cid>/<anim>_<k>.png. Returns frame count."""
    from PIL import Image
    small = im.width < 1000          # a Canva preview: mark it provisional
    im = strip_white(im)
    cols = find_columns(im, n)
    frames = []
    for x0, x1 in cols:
        f = im.crop((x0, 0, x1, im.height))
        box = f.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
        if box:
            frames.append(f.crop(box))
    if not frames:
        return 0
    k = BODY / min(f.height for f in frames)
    frames = [f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS) for f in frames]
    cw = max(f.width for f in frames)
    ch = max(f.height for f in frames)
    out = ART / "anims" / cid
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("%s_*.png" % anim):
        old.unlink()
    for i, f in enumerate(frames):
        c = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        c.paste(f, ((cw - f.width) // 2, ch - f.height), f)
        c.save(out / ("%s_%d.png" % (anim, i)), optimize=True)
    mark = out / ("%s.preview" % anim)
    if small:
        mark.write_text("provisional low-res frames\n")
    elif mark.exists():
        mark.unlink()
    return len(frames)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sheet")
    ap.add_argument("id")
    ap.add_argument("anim")
    ap.add_argument("--frames", type=int, default=None)
    a = ap.parse_args()
    from PIL import Image
    n = split(Image.open(a.sheet), a.id, a.anim, a.frames)
    if not n:
        sys.exit("Nenhum quadro encontrado.")
    print("%d quadros -> godot/assets/art/anims/%s/%s_*.png" % (n, a.id, a.anim))

if __name__ == "__main__":
    main()
