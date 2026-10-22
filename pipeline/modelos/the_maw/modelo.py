"""CR_TheMaw — boss "A Bocarra": a round pink beast that is mostly mouth, ivory spikes on the back,
stubby legs and a spiked tail. Reference: portraits/the_maw.png. Biped family without arms.
The upper jaw rides DEF-head (opens/closes in the bite); body and lower jaw ride DEF-spine/DEF-chest.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_TheMaw"
ATAQUE_QUADRO = 11
PALETA = {"Skin": "D8579A", "SkinDark": "A83A74", "Spot": "B84784", "Mouth": "5A1020", "Tongue": "E0607A",
          "Tooth": "F2E6CC", "Spike": "EADFC0"}

BODY = Vector((0, 0, 0.56))
P = BP.params(
    arms=False, hunch=0.0, head_c=(0, -0.05, 0.62), head_r=(0.40, 0.36, 0.42),
    pelvis_z=0.30, waist_z=0.42, chest_z=0.56, neck0_z=0.70, neck1_z=0.78,
    hip_x=0.17, hip_z=0.26, knee_x=0.21, knee_y=-0.03, knee_z=0.14, ankle_x=0.23, ankle_z=0.07, foot_len=0.17,
    r_pelvis=(0.2, 0.15), r_waist=(0.2, 0.15), r_chest=(0.2, 0.15), r_neck0=(0.15, 0.12), r_neck1=(0.12, 0.1),
    r_hip=0.085, r_knee=0.075, r_ankle=0.065,
)


def pecas():
    J = BP.body("Legs", P, role="Skin")
    BP.feet("", J, P, role="Skin", style="toes3", size=1.2, toe_role="Tooth")
    K.sphere("Belly", "Skin", "DEF-spine", BODY + Vector((0, 0.04, -0.07)), (0.40, 0.37, 0.36), u=22, v=14)
    K.sphere("Crown", "Skin", "DEF-head", BODY + Vector((0, 0.03, 0.10)), (0.40, 0.36, 0.34), u=22, v=14)
    # the mouth: dark cavity, tongue, upper and lower rows of teeth on the rim
    K.sphere("Mouth", "Mouth", "DEF-spine", BODY + Vector((0, -0.25, 0.0)), (0.29, 0.14, 0.27), u=18, v=10)
    K.sphere("Tongue", "Tongue", "DEF-spine", BODY + Vector((0, -0.31, -0.15)), (0.17, 0.09, 0.07), u=14, v=8)
    for i in range(9):
        a = math.radians(-150 + 300 * i / 8)      # around the rim, front-facing
        x, z = math.sin(a) * 0.27, math.cos(a) * 0.25
        top = z > -0.05
        root = BODY + Vector((x, -0.36 + 0.06 * abs(math.sin(a)), z))
        tip = root + Vector((-x * 0.25, -0.02, -0.11 if top else 0.11))
        K.along("Tooth%d" % i, "Tooth", "DEF-head" if top else "DEF-spine", root, tip, 0.035, 0.004, segments=8)
    # ivory spikes on the crown and back (portrait: big ones on top, smaller down the back)
    spikes = [((0, -0.2, 1), 0.2), ((0.45, 0.1, 0.9), 0.18), ((-0.45, 0.1, 0.9), 0.18), ((0.15, 0.6, 0.8), 0.17),
              ((-0.2, 0.6, 0.78), 0.16), ((0.75, 0.3, 0.5), 0.15), ((-0.75, 0.3, 0.5), 0.15), ((0, 0.9, 0.35), 0.15),
              ((0.45, 0.85, 0.1), 0.12), ((-0.45, 0.85, 0.1), 0.12)]
    for i, (d, ln) in enumerate(spikes):
        d = Vector(d).normalized()
        root = BODY + Vector((d.x * 0.36, d.y * 0.32, 0.06 + d.z * 0.36))
        K.along("Spike%d" % i, "Spike", "DEF-head" if d.z > 0.4 else "DEF-spine", root, root + d * ln, 0.055, 0.004, segments=8)
    for i, p in enumerate(((0.3, 0.1, 0.75), (-0.32, 0.0, 0.7), (0.38, -0.05, 0.45), (-0.36, 0.1, 0.4), (0.2, 0.3, 0.3))):
        K.sphere("Spot%d" % i, "Spot", "DEF-spine", p, (0.03, 0.03, 0.03), u=8, v=5)
    # tail
    t0, t1 = BODY + Vector((0, 0.3, -0.3)), BODY + Vector((0, 0.62, -0.42))
    K.along("Tail", "Skin", "DEF-pelvis", t0, t1, 0.1, 0.02, segments=10)
    for i in range(3):
        p = t0 + (t1 - t0) * (0.25 + 0.25 * i)
        K.along("TailSpike%d" % i, "Spike", "DEF-pelvis", p + Vector((0, 0, 0.05)), p + Vector((0, 0.03, 0.12)), 0.025, 0.003, segments=6)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=0)
    BP.run(arm, lean=6, stride=30)
    BP.attack(arm, "slam")
    BP.die(arm)
