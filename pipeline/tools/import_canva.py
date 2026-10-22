#!/usr/bin/env python3
"""
Bastion Rush — puts the art generated in Canva into the game.

The list (pipeline/canva_art.json / pipeline/CANVA_ARTES.md) is in a fixed
order. Run this, then open each Canva link IN ORDER and click Download
(PNG). The script notices every new file in ~/Downloads, removes the plain
white background from characters/logo, resizes, and copies it to the right
slot(s) in godot/assets/art/. Already-filled slots are skipped.

  python3 pipeline/tools/import_canva.py            # start (or resume)
  python3 pipeline/tools/import_canva.py --list     # what is missing
  python3 pipeline/tools/import_canva.py --downloads ~/Transferências
  python3 pipeline/tools/import_canva.py --file 3 ~/Downloads/foo.png   # place one file by number

While waiting: s+Enter skips the current image, q+Enter quits.
Needs Pillow:  sudo apt install python3-pil   (or pip install pillow)
"""
import argparse
import os
import json
import select
import sys
import time
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ART = ROOT / "godot" / "assets" / "art"
LIST = ROOT / "pipeline" / "canva_art.json"
IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp"}


def strip_white(im):
    """Flood-fill the near-white background from the borders → transparent."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))

    def is_bg(p):
        r, g, b, a = p
        return r > 232 and g > 232 and b > 232

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (255, 255, 255, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return im


def place(src, slots):
    from PIL import Image
    im = Image.open(src)
    im.load()
    first = slots[0]
    if first.endswith(".sheet"):     # anims/<id>/<anim>.sheet  -> 4 animation frames
        from split_sheet import split
        cid, anim = first[len("anims/"):-len(".sheet")].split("/")
        n = split(im, cid, anim, 4)
        print("   OK -> %d quadros em anims/%s/%s_*.png" % (n, cid, anim))
        return
    transparent = first.startswith(("portraits/", "towers/", "anims/", "fx/")) or first == "ui/logo.png"
    if transparent:
        im = strip_white(im)
        box = im.getbbox()           # trim empty margins: feet sit on the image bottom
        if box:
            im = im.crop(box)
    else:
        im = im.convert("RGB")
    im.thumbnail((1536, 1536) if first.startswith("realms/") else (1024, 1024))
    for s in slots:
        out = ART / s
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out, "PNG", optimize=True)
        print("   OK ->", out.relative_to(ROOT))


def _ok(path):
    """A slot counts as done only with a full-size image (the 200px Canva
    previews placed by Claude are provisional and get replaced)."""
    if path.suffix == ".sheet":
        return path.with_name(path.stem + "_0.png").exists() and not path.with_suffix(".preview").exists()
    if not path.exists():
        return False
    try:
        from PIL import Image
        return max(Image.open(path).size) >= 400
    except Exception:
        return False


def missing(entries):
    return [e for e in entries if not e.get("obsolete") and not all(_ok(ART / s) for s in e["slots"])]


def newest(folder, since, known):
    best = None
    for f in folder.iterdir():
        if f.suffix.lower() not in IMAGE_EXT or f.name in known:
            continue
        m = f.stat().st_mtime
        if m >= since and (best is None or m > best[0]):
            best = (m, f)
    return best[1] if best else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--downloads", default=None)
    ap.add_argument("--file", nargs=2, metavar=("NUM", "PATH"))
    a = ap.parse_args()
    try:
        import PIL  # noqa: F401
    except ImportError:
        sys.exit("Instale o Pillow primeiro:  sudo apt install python3-pil")
    entries = json.loads(LIST.read_text())
    if a.file:
        e = next(x for x in entries if x["n"] == int(a.file[0]))
        place(Path(a.file[1]).expanduser(), e["slots"])
        return
    todo = missing(entries)
    print("\nFaltam %d de %d imagens.\n" % (len(todo), len(entries)))
    if a.list or not todo:
        for e in todo:
            print("  %2d. %s  %s" % (e["n"], e["title"], e["link"]))
        return
    dl = Path(a.downloads).expanduser() if a.downloads else None
    if dl is None:
        for c in ("~/Downloads", "~/Transferências", "~/Descargas"):
            if Path(c).expanduser().is_dir():
                dl = Path(c).expanduser()
                break
    if dl is None:
        sys.exit("Não achei a pasta de downloads. Use --downloads /caminho")
    print("Vigiando:", dl)
    known = {f.name for f in dl.iterdir()}
    for e in todo:
        print("=" * 64)
        print("%2d/%d  %s" % (e["n"], len(entries), e["title"]))
        print("    Abra:  %s" % e["link"])
        print("    No Canva clique em Baixar (PNG). Esperando o arquivo...  [s=pular, q=sair]")
        start = time.time() - 2
        while True:
            if select.select([sys.stdin], [], [], 0)[0]:
                cmd = sys.stdin.readline().strip().lower()
                if cmd == "q":
                    print("Até mais! Rode de novo para continuar.")
                    return
                if cmd == "s":
                    break
            f = newest(dl, start, known)
            if f:
                last = -1
                for _ in range(40):
                    sz = f.stat().st_size
                    if sz == last and sz > 0:
                        break
                    last = sz
                    time.sleep(0.25)
                known.add(f.name)
                place(f, e["slots"])
                break
            time.sleep(0.5)
    print("\nPronto! Para mandar pro GitHub:")
    print("  git add godot/assets/art && git commit -m 'Artes do Canva' && git push")


if __name__ == "__main__":
    main()
