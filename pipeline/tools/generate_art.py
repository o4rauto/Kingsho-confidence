#!/usr/bin/env python3
"""
Bastion Rush — art generator using ChatGPT's image model (OpenAI gpt-image-1).

Step 1 of the asset pipeline (it replaces "Nano Banana" from the reference
video). Every prompt shares one STYLE BIBLE so the whole game reads as a single,
cohesive chunky-cartoon mobile style.

What it makes (all from pipeline/game_content.json, exported from the game):
  concept/<id>_turnaround.png  full-body reference, plain bg  -> feed to Tripo (3D)
  concept/<id>_parts.png       head/torso/legs/props split, made FROM the
                               turnaround so it's the same character (video method)
  godot/assets/art/portraits/<id>.png   card portraits (transparent)  -> used in-game
  godot/assets/art/realms/<id>.png      realm key art                 -> used in-game
  godot/assets/art/boons/<id>.png       boon icons (transparent)      -> used in-game
  godot/assets/art/ui/*.png             menu background, logo, currencies

Usage (needs internet + an OpenAI API key with image access):
  export OPENAI_API_KEY=...            # never commit this
  python3 pipeline/tools/generate_art.py --dry-run          # see prompts + cost estimate
  python3 pipeline/tools/generate_art.py --only portraits   # one category
  python3 pipeline/tools/generate_art.py                    # everything (resumable)
  python3 pipeline/tools/generate_art.py --force --ids warden pyre_knight

Files that already exist are skipped, so you can stop and resume any time.
Only Python 3.8+ standard library is required.
"""
import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "pipeline" / "game_content.json"
CONCEPT = ROOT / "pipeline" / "concept"
ART = ROOT / "godot" / "assets" / "art"
API = "https://api.openai.com/v1/images"
MODEL = os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1")

# The aesthetic is described in plain words (not by naming another game):
# descriptive prompts steer the model better and keep the look our own.
STYLE = (
    "Stylized 3D cartoon mobile-game art. Chunky, toy-like proportions: big head, "
    "large expressive eyes, sturdy hands and feet, thick readable silhouette. "
    "Smooth hand-painted materials with soft gradients, saturated warm colors, "
    "gentle rim light, soft studio lighting from the top-left, subtle ambient "
    "occlusion. Friendly, punchy, polished, family-friendly. No text, no logos, "
    "no watermark."
)
WORLD = (
    "Fantasy world of Aethelgard: a besieged fortress called the Bastion holds back "
    "'the Rush', corrupted rift creatures. Heroes have ember-gold accents."
)
ROLE = {
    "melee": "armored frontline fighter holding a melee weapon",
    "ranged": "agile ranged attacker with a bow",
    "tower": "magical stone turret with a floating glowing crystal on a plinth (not a person)",
    "support": "spellcaster holding a glowing staff",
}
KIND = {
    "runner": "small fast creature",
    "brute": "huge heavy hulking creature",
    "flyer": "winged flying creature",
    "caster": "robed floating spellcaster creature",
    "boss": "giant menacing boss monster, imposing but still cartoon-cute",
}
PRICE = {"low": 0.011, "medium": 0.042, "high": 0.167}  # approx USD per 1024² image


def hexname(h):
    return "#" + h.lstrip("#")[:6]


def build_jobs(data, quality):
    jobs = []

    def add(cat, out, prompt, size="1024x1024", transparent=False, ref=None, q=None):
        jobs.append({"cat": cat, "out": out, "prompt": prompt, "size": size,
                     "transparent": transparent, "ref": ref, "quality": q or quality})

    heroes = [{"id": "warden", "name": "Kael", "title": "the Last Keeper of the Flame",
               "role": "ranged", "color": "ffbf5e",
               "lore": "a young hero archer, former lighthouse apprentice, in ember-gold armor with a short red cape, "
                       "a radiant bow and a small flame floating above his hand"}]
    heroes += data["champions"]

    # Characters: turnaround (for Tripo) + parts sheet (video method) + portrait.
    for c in heroes:
        desc = (f"{c['name']}, {c.get('title', '')}: {ROLE.get(c['role'], '')}. "
                f"Main color {hexname(c['color'])}. {c.get('lore', '')}")
        turn = CONCEPT / f"{c['id']}_turnaround.png"
        add("concept", turn,
            f"{STYLE} {WORLD} Character reference sheet of {desc}. Single full-body view, "
            "front-facing, standing in a relaxed A-pose with arms slightly away from the body, "
            "whole figure visible head to toe, centered, plain flat light-grey background, "
            "no shadow on the floor, no other characters. Clean shapes suitable for 3D modelling.",
            size="1024x1536")
        add("parts", CONCEPT / f"{c['id']}_parts.png",
            f"{STYLE} Using the reference character, create a modelling parts sheet of the SAME "
            "character with identical colors and design: separate, non-overlapping isolated pieces "
            "laid out on a plain light-grey background — the head (front view), the torso with arms, "
            "the legs and feet, and each accessory/weapon on its own. Every piece fully visible, "
            "evenly spaced, no labels.",
            size="1536x1024", ref=turn)
        add("portraits", ART / "portraits" / f"{c['id']}.png",
            f"{STYLE} {WORLD} Collectible card portrait of {desc}. Heroic three-quarter view from "
            "the waist up, dynamic confident pose, character fills the frame, transparent background.",
            transparent=True)

    for e in data["enemies"]:
        desc = f"{e['name']}: {KIND.get(e['kind'], 'creature')}, main color {hexname(e['color'])}"
        add("concept", CONCEPT / f"{e['id']}_turnaround.png",
            f"{STYLE} {WORLD} Creature reference sheet of {desc}, one of the Rush. Single full-body "
            "front view, centered, whole creature visible, plain flat light-grey background, "
            "no floor shadow. Clean shapes suitable for 3D modelling.",
            size="1024x1536")
        if e["kind"] == "boss":
            add("portraits", ART / "portraits" / f"{e['id']}.png",
                f"{STYLE} {WORLD} Boss card portrait of {desc}. Menacing three-quarter view, "
                "fills the frame, transparent background.", transparent=True)

    for r in data["realms"]:
        add("realms", ART / "realms" / f"{r['id']}.png",
            f"{STYLE} {WORLD} Key art of the realm '{r['name']}' — {r['subtitle']}. Biome: {r['biome']}, "
            f"time of day: {r['tod']}, weather: {r['weather']}, accent color {hexname(r['accent'])}. "
            "Top-down three-quarter view of a battlefield with winding dirt lanes leading to a small "
            "fortress at the bottom, rich environment props, no characters, no text.",
            size="1536x1024")

    for b in data["boons"]:
        add("boons", ART / "boons" / f"{b['id']}.png",
            f"{STYLE} Game ability icon for '{b['name']}' ({b['desc']}). A single bold symbolic "
            f"object, glossy, centered, {b['rarity']} rarity glow, transparent background.",
            transparent=True, q="low" if quality != "high" else "medium")

    ui = ART / "ui"
    add("ui", ui / "menu_bg.png",
        f"{STYLE} {WORLD} Vertical mobile main-menu background: the Bastion fortress glowing with "
        "ember light on a hill at dusk, dark rift clouds above, warm and cold contrast, empty space "
        "at the top for a logo and at the bottom for buttons, no text.", size="1024x1536")
    add("ui", ui / "logo.png",
        f"{STYLE} Game logo artwork reading exactly 'BASTION RUSH' in huge chunky beveled fantasy "
        "letters, ember-gold and orange with a dark outline, a small sword and shield emblem, "
        "transparent background.", size="1536x1024", transparent=True)
    for name, what in [("gold", "a shiny gold coin"), ("shards", "a glowing blue crystal shard"),
                       ("cores", "a glowing orange ember core orb")]:
        add("ui", ui / f"currency_{name}.png",
            f"{STYLE} Currency icon: {what}, glossy, centered, transparent background.",
            transparent=True, q="low")
    return jobs


# ── OpenAI calls (stdlib only) ───────────────────────────────
def _post_json(url, payload, key):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.loads(r.read())


def _post_multipart(url, fields, files, key):
    boundary = uuid.uuid4().hex
    body = b""
    for k, v in fields.items():
        body += f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode()
    for k, (fname, blob, mime) in files.items():
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"; filename=\"{fname}\"\r\n"
                 f"Content-Type: {mime}\r\n\r\n").encode() + blob + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    req = urllib.request.Request(url, data=body, headers={
        "Authorization": f"Bearer {key}", "Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.loads(r.read())


def generate(job, key):
    fields = {"model": MODEL, "prompt": job["prompt"], "size": job["size"], "quality": job["quality"], "n": 1}
    if job["transparent"]:
        fields["background"] = "transparent"
    for attempt in range(5):
        try:
            if job["ref"] and Path(job["ref"]).exists():
                res = _post_multipart(f"{API}/edits", {k: str(v) for k, v in fields.items()},
                                      {"image[]": (Path(job["ref"]).name, Path(job["ref"]).read_bytes(), "image/png")}, key)
            else:
                res = _post_json(f"{API}/generations", fields, key)
            blob = base64.b64decode(res["data"][0]["b64_json"])
            job["out"].parent.mkdir(parents=True, exist_ok=True)
            job["out"].write_bytes(blob)
            return f"ok   {job['out'].relative_to(ROOT)}"
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="ignore")[:300]
            if e.code in (429, 500, 502, 503) and attempt < 4:
                time.sleep(2 ** attempt * 3)
                continue
            return f"FAIL {job['out'].relative_to(ROOT)} HTTP {e.code}: {msg}"
        except Exception as e:  # network hiccup
            if attempt < 4:
                time.sleep(2 ** attempt * 3)
                continue
            return f"FAIL {job['out'].relative_to(ROOT)}: {e}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", nargs="*", help="categories: concept parts portraits realms boons ui")
    ap.add_argument("--ids", nargs="*", help="limit to these ids (e.g. warden pyre_knight)")
    ap.add_argument("--quality", default="medium", choices=["low", "medium", "high"])
    ap.add_argument("--force", action="store_true", help="regenerate even if the file exists")
    ap.add_argument("--dry-run", action="store_true", help="write prompts.md + cost estimate, call nothing")
    ap.add_argument("--workers", type=int, default=3)
    a = ap.parse_args()

    data = json.loads(CONTENT.read_text())
    jobs = build_jobs(data, a.quality)
    if a.only:
        jobs = [j for j in jobs if j["cat"] in a.only]
    if a.ids:
        jobs = [j for j in jobs if any(j["out"].stem.startswith(i) for i in a.ids)]
    todo = [j for j in jobs if a.force or not j["out"].exists()]
    # Parts sheets depend on their turnaround: run them after everything else.
    todo.sort(key=lambda j: j["cat"] == "parts")
    cost = sum(PRICE[j["quality"]] * (1.5 if j["size"] != "1024x1024" else 1.0) for j in todo)
    print(f"{len(todo)} image(s) to generate ({len(jobs) - len(todo)} already exist) — est. ~US${cost:.2f}")

    if a.dry_run:
        out = ROOT / "pipeline" / "prompts.md"
        lines = ["# Generated art prompts\n", f"Model: {MODEL} · est. cost ~US${cost:.2f}\n"]
        for j in jobs:
            lines.append(f"\n## {j['out'].relative_to(ROOT)}\n`{j['size']}` · {j['quality']}"
                         f"{' · transparent' if j['transparent'] else ''}"
                         f"{' · from ' + str(Path(j['ref']).name) if j['ref'] else ''}\n\n{j['prompt']}\n")
        out.write_text("".join(lines))
        print(f"wrote {out.relative_to(ROOT)}")
        return
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        sys.exit("OPENAI_API_KEY is not set. Export it in your shell (never commit it).")

    first = [j for j in todo if j["cat"] != "parts"]
    later = [j for j in todo if j["cat"] == "parts"]
    for batch in (first, later):
        with ThreadPoolExecutor(max_workers=a.workers) as pool:
            for f in as_completed([pool.submit(generate, j, key) for j in batch]):
                print(f.result(), flush=True)
    print("Done. Open the Godot project: new art is imported and used automatically.")


if __name__ == "__main__":
    main()
