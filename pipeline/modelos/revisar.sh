#!/bin/bash
# Review sheet for a built character: pipeline/modelos/revisar.sh <id> [portrait_id]
# Needs the skill blender-image-to-3d (review_render.py, compose_review.py) and `blender` on PATH.
# Output: pipeline/modelos/<id>/review/folha.png (+ compare_ref.png and compare_ref.json with the IoU).
set -e
ID=$1; PORT=${2:-$1}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SK=${SKILL_DIR:-/root/.claude/skills/blender-image-to-3d}/scripts
D=$ROOT/pipeline/modelos/$ID; R=$D/review; B=$D/${ID}_master.blend
REF=$ROOT/godot/assets/art/portraits/$PORT.png
AF=$(python3 -c "import json;print(json.load(open('$D/stats.json'))['attack_frame'])")
mkdir -p "$R"
# the skill renders material mode with AgX, which washes out flat cartoon colours; the game shows albedo
# under flat light, so review with the Standard view transform instead (patched copy, skill untouched)
RRP=$R/.review_render_standard.py
sed 's/"AgX" if a.mode == "material" else "Standard"/"Standard"/' $SK/review_render.py > "$RRP"
rr() { blender --background --python "$RRP" -- --blend "$B" --collections EXPORT --mode material \
       --engine cycles --samples 14 "$@" >/dev/null 2>&1; }
rr --out "$R/vistas" --views front,threequarter --ref-cam 0 15 50 --gameplay-px 96 --res 512
rr --out "$R/jogo" --views front --ref-cam 0 55 0 --res 384
rr --out "$R/ataque" --views threequarter --res 384 --action attack --frame "$AF"
rr --out "$R/corrida" --views threequarter --res 384 --action run --frame 5
if [ -f "$REF" ]; then
  python3 $SK/compose_review.py --ref "$REF" --render "$R/vistas/material_ref.png" --out "$R/compare_ref.png" \
    --measure --gameplay-px 96 2>&1 | grep -E "IoU" || true
fi
python3 - "$R" "$REF" "$ID" <<'EOF'
import sys, os
from PIL import Image, ImageDraw
R, REF, ID = sys.argv[1:4]
cells = [("desenho", REF), ("frente", R + "/vistas/material_ref.png"), ("3/4", R + "/vistas/material_threequarter.png"),
         ("jogo 55°", R + "/jogo/material_ref.png"), ("ataque", R + "/ataque/material_threequarter.png"),
         ("corrida", R + "/corrida/material_threequarter.png"), ("96 px", R + "/vistas/material_gameplay_96px.png")]
h = 300
row = []
for label, p in cells:
    if not os.path.exists(p):
        continue
    im = Image.open(p).convert("RGBA")
    bb = im.getbbox()
    if bb:
        im = im.crop(bb)
    k = (h - 30) / im.height if label != "96 px" else 1.0
    im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))))
    row.append((label, im))
W = sum(max(i.width, 90) + 16 for _, i in row) + 16
s = Image.new("RGB", (W, h + 24), (52, 60, 50))
d = ImageDraw.Draw(s)
x = 16
for label, im in row:
    s.paste(im, (x, h + 12 - im.height), im)
    d.text((x, 4), label, fill=(255, 255, 255))
    x += max(im.width, 90) + 16
d.text((W - 120, 4), ID, fill=(255, 220, 120))
s.save(R + "/folha.png")
print("folha", R + "/folha.png")
EOF
