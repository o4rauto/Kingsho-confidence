#!/usr/bin/env python3
"""
Bastion Rush — make the art with YOUR ChatGPT (the app/site you already pay for),
no API key, no extra credits.

How it works (semi-automatic, one image at a time):
  1. The script copies the next prompt to your clipboard (and prints it).
  2. You paste it into ChatGPT (Ctrl+V, Enter) and wait for the image.
  3. You click the image's download button.
  4. The script notices the new file in ~/Downloads, converts/resizes it and
     moves it into the right game folder (godot/assets/art/...). Next prompt.

Usage:
  python3 pipeline/tools/chatgpt_helper.py                 # in-game art, most important first
  python3 pipeline/tools/chatgpt_helper.py --list          # just show what is missing
  python3 pipeline/tools/chatgpt_helper.py --only realms   # one category
  python3 pipeline/tools/chatgpt_helper.py --all           # also the 3D reference sheets (Tripo)
  python3 pipeline/tools/chatgpt_helper.py --downloads ~/Transferências

While waiting: type  s + Enter  to skip an image,  q + Enter  to quit.
Already-filled slots are skipped, so you can stop and resume any time.
Optional: `pip install pillow` (converts JPG/WEBP to PNG and shrinks big files).
"""
import argparse
import json
import os
import select
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_art as ga  # noqa: E402  (shares the same style bible + prompt list)

IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp"}
ORDER = ["ui", "realms", "portraits", "boons", "concept", "parts"]
SHAPE = {"1024x1024": "QUADRADA (1:1)", "1024x1536": "VERTICAL (2:3)", "1536x1024": "HORIZONTAL (3:2)"}


def to_clipboard(text):
    for cmd in (["wl-copy"], ["xclip", "-selection", "clipboard"], ["xsel", "--clipboard", "--input"]):
        if shutil.which(cmd[0]):
            try:
                subprocess.run(cmd, input=text.encode(), check=True, timeout=5)
                return True
            except Exception:
                pass
    return False


def chat_prompt(job):
    p = "Gere UMA imagem. Formato %s. " % SHAPE.get(job["size"], "QUADRADA")
    if job["transparent"]:
        p += "Fundo TRANSPARENTE (PNG). "
    if job.get("ref"):
        p += ("Use como referência a imagem do mesmo personagem que eu anexei "
              "(arraste o arquivo %s para o chat junto com este texto). " % Path(job["ref"]).name)
    return p + "\n\n" + job["prompt"]


def newest_download(folder, since, known):
    best = None
    for f in folder.iterdir():
        if f.suffix.lower() not in IMAGE_EXT or f.name in known:
            continue
        try:
            m = f.stat().st_mtime
        except OSError:
            continue
        if m >= since and (best is None or m > best[0]):
            best = (m, f)
    return best[1] if best else None


def wait_stable(f):
    last = -1
    for _ in range(40):
        s = f.stat().st_size
        if s == last and s > 0:
            return
        last = s
        time.sleep(0.25)


def place(src, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        from PIL import Image
        im = Image.open(src)
        im.load()
        if im.mode not in ("RGB", "RGBA"):
            im = im.convert("RGBA")
        im.thumbnail((1024, 1024))
        im.save(out, "PNG", optimize=True)
        src.unlink()
        return True
    except ImportError:
        if src.suffix.lower() != ".png":
            print("   ! O arquivo não é PNG e o Pillow não está instalado (pip install pillow). Pulei.")
            return False
        shutil.move(str(src), str(out))
        return True


def ask_line():
    if select.select([sys.stdin], [], [], 0)[0]:
        return sys.stdin.readline().strip().lower()
    return ""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", nargs="*", help="categorias: ui realms portraits boons concept parts")
    ap.add_argument("--ids", nargs="*", help="só estes ids/arquivos (ex.: warden broken_gate logo)")
    ap.add_argument("--all", action="store_true", help="inclui as fichas de referência 3D (concept/parts)")
    ap.add_argument("--list", action="store_true", help="só lista o que falta")
    ap.add_argument("--downloads", default=None, help="pasta onde o navegador salva (padrão: ~/Downloads)")
    args = ap.parse_args()

    data = json.loads(ga.CONTENT.read_text())
    jobs = ga.build_jobs(data, "medium")
    cats = args.only or (ORDER if args.all else ["ui", "realms", "portraits", "boons"])
    jobs = [j for j in jobs if j["cat"] in cats and not Path(j["out"]).exists()]
    jobs = [j for j in jobs if not j["out"].name.startswith("currency_")]
    if args.ids:
        jobs = [j for j in jobs if any(i in j["out"].name for i in args.ids)]
    jobs.sort(key=lambda j: ORDER.index(j["cat"]))

    print("\nFaltam %d imagem(ns).\n" % len(jobs))
    if args.list or not jobs:
        for j in jobs:
            print("  -", j["out"].relative_to(ga.ROOT))
        return

    dl = Path(args.downloads).expanduser() if args.downloads else None
    if dl is None:
        for cand in ("~/Downloads", "~/Transferências", "~/Descargas"):
            if Path(cand).expanduser().is_dir():
                dl = Path(cand).expanduser()
                break
    if dl is None or not dl.is_dir():
        sys.exit("Não achei a pasta de downloads. Use --downloads /caminho/da/pasta")
    print("Vigiando a pasta: %s" % dl)
    print("Abra o ChatGPT (chatgpt.com ou o app) numa conversa NOVA.\n")

    known = {f.name for f in dl.iterdir()}
    done = 0
    for n, job in enumerate(jobs, 1):
        text = chat_prompt(job)
        print("=" * 70)
        print("[%d/%d]  ->  %s" % (n, len(jobs), job["out"].relative_to(ga.ROOT)))
        print("-" * 70)
        print(text)
        print("-" * 70)
        if to_clipboard(text):
            print("PROMPT COPIADO! Cole no ChatGPT (Ctrl+V) e envie.")
        else:
            print("(Instale 'xclip' para copiar sozinho: sudo apt install xclip) — copie o texto acima.")
        print("Depois BAIXE a imagem. Estou esperando o arquivo...   [s+Enter = pular, q+Enter = sair]")
        start = time.time() - 2
        while True:
            cmd = ask_line()
            if cmd == "q":
                print("\nAté mais! Rode de novo para continuar de onde parou. (%d feitas)" % done)
                return
            if cmd == "s":
                print("   pulada.")
                break
            f = newest_download(dl, start, known)
            if f:
                wait_stable(f)
                known.add(f.name)
                if place(f, job["out"]):
                    done += 1
                    print("   OK! salvo em %s\n" % job["out"].relative_to(ga.ROOT))
                break
            time.sleep(0.5)
    print("\nPronto: %d imagem(ns) colocadas no jogo. Abra o Godot para ver." % done)
    print("Para mandar pro GitHub:  git add godot/assets/art pipeline/concept && git commit -m 'Arte do ChatGPT' && git push")


if __name__ == "__main__":
    main()
