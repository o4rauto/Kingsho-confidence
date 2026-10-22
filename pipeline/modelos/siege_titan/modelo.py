"""CR_SiegeTitan — boss "Titã de Cerco": a walking siege engine in red plate with bronze trim, tiny
helmeted head sunk between huge spiked pauldrons, two smokestacks on the back, both forearms ending in
steel drills, grey mechanical joints, stomping red boots. Ref: portraits/siege_titan.png. Biped. H 1.3.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_SiegeTitan"
ATAQUE_QUADRO = 11
PALETA = {"Red": ("C8402A", 0.5, 0.25), "RedDark": ("8E2A1E", 0.55, 0.25), "Bronze": ("D8963A", 0.4, 0.55),
          "Joint": ("6E6862", 0.5, 0.45), "Steel": ("C4C8D0", 0.3, 0.65), "SteelDark": ("70767E", 0.4, 0.6),
          "Visor": "181212", "Eye": "FFB03A", "Soot": "2A2622"}
BRILHO = ("Eye",)

P = BP.params(hunch=0.04, head_c=(0, -0.1, 1.02), head_r=(0.1, 0.1, 0.11),
              neck0_z=0.93, neck1_z=0.97, chest_z=0.8, waist_z=0.62, pelvis_z=0.52,
              shoulder_z=0.9, shoulder_x=0.26, elbow_out=0.08, elbow_z=0.68, wrist_x=0.36, wrist_y=-0.2, wrist_z=0.5,
              hand_bottom=0.4, hand_size=0.1, hip_x=0.13, hip_z=0.48, knee_x=0.18, knee_y=-0.04, knee_z=0.27,
              ankle_x=0.2, ankle_z=0.1, foot_len=0.26,
              r_pelvis=(0.18, 0.13), r_waist=(0.13, 0.1), r_chest=(0.25, 0.18), r_neck0=(0.09, 0.08), r_neck1=(0.08, 0.07),
              r_shoulder=0.085, r_elbow=0.07, r_wrist=0.07, r_hip=0.085, r_knee=0.075, r_ankle=0.07)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Helm", "Red", "DEF-head", c, (hr[0] + 0.012, hr[1] + 0.012, hr[2]), u=16, v=10)
    K.arc_strip("HelmCrest", "Bronze", "DEF-head", c, hr[0] + 0.012, hr[1] + 0.024, hr[2] + 0.014, 0.04)
    fy = c.y - hr[1] - 0.01
    K.box("Faceplate", "Bronze", "DEF-head", (0, fy, c.z - 0.015), (0.14, 0.03, 0.13), bevel=0.014)
    K.box("SlitH", "Visor", "DEF-head", (0, fy - 0.016, c.z + 0.012), (0.11, 0.01, 0.026), bevel=0.004)
    K.box("SlitV", "Visor", "DEF-head", (0, fy - 0.016, c.z - 0.03), (0.024, 0.01, 0.07), bevel=0.004)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", (s * 0.03, fy - 0.022, c.z + 0.012), (0.014, 0.006, 0.01), u=6, v=4)


def torso(J):
    K.sphere("Chestplate", "Red", "DEF-chest", (0, -0.02, 0.8), (0.27, 0.2, 0.17), u=18, v=12)
    K.band("ChestTrim", "Bronze", "DEF-chest", (0, -0.01, 0.68), 0.25, 0.18, 0.04)
    K.box("Plate", "Bronze", "DEF-chest", (0, -0.2, 0.79), (0.2, 0.03, 0.12), bevel=0.02)
    K.box("PlateInner", "Red", "DEF-chest", (0, -0.214, 0.79), (0.15, 0.02, 0.08), bevel=0.012)
    for s in (1, -1):
        for z in (0.83, 0.75):
            K.sphere("Rivet%d%d" % (s > 0, z * 100), "Bronze", "DEF-chest", (s * 0.15, -0.19, z), (0.016, 0.012, 0.016), u=6, v=4)
    K.band("Collar", "Bronze", "DEF-neck", (0, -0.05, 0.93), 0.11, 0.1, 0.05)
    for z in (0.6, 0.64):
        K.band("WaistRing%d" % int(z * 100), "SteelDark", "DEF-spine", (0, -0.005, z), 0.135, 0.105, 0.02)
    K.skirt("Hips", "Red", "AUTO", 0.57, 0.4, 0.18, 0.21, side_lift=0.04, thickness=0.02)
    K.band("Belt", "Bronze", "DEF-pelvis", (0, 0, 0.56), 0.19, 0.145, 0.04)
    for s in (1, -1):   # smokestacks
        a, b = Vector((s * 0.12, 0.13, 0.9)), Vector((s * 0.15, 0.2, 1.22))
        K.along("Stack%d" % (s > 0), "Bronze", "DEF-chest", a, b, 0.052, 0.05, segments=12)
        K.band("StackRim%d" % (s > 0), "RedDark", "DEF-chest", b - Vector((0.0, 0.0, 0.02)), 0.062, 0.062, 0.04)
        K.band("StackBand%d" % (s > 0), "RedDark", "DEF-chest", a + (b - a) * 0.45, 0.058, 0.058, 0.03)
        K.sphere("StackSoot%d" % (s > 0), "Soot", "DEF-chest", b + Vector((0, 0, 0.002)), (0.042, 0.042, 0.01), u=10, v=4)


def arms(J):
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        bone = "DEF-upper_arm." + sd
        K.dome("Pauldron." + sd, "Red", bone, sh + Vector((s * 0.03, 0, 0.02)), (0.15, 0.14, 0.12))
        K.band("PauldronRim." + sd, "Bronze", bone, sh + Vector((s * 0.03, 0, 0.02)), 0.152, 0.142, 0.03)
        K.sphere("PauldronBolt." + sd, "Bronze", bone, sh + Vector((s * 0.12, -0.06, 0.06)), (0.03, 0.03, 0.03), u=8, v=6)
        K.along("Spike." + sd, "Steel", bone, sh + Vector((s * 0.08, 0.02, 0.1)), sh + Vector((s * 0.16, 0.04, 0.22)), 0.04, 0.004, segments=8)
        K.sphere("Elbow." + sd, "Bronze", "DEF-forearm." + sd, el, (0.08, 0.08, 0.08), u=12, v=8)
        d = (wr - el).normalized()
        K.along("Gauntlet." + sd, "Red", "DEF-forearm." + sd, el, wr + d * 0.03, 0.115, 0.13, 0.2, 1.0, segments=16)
        for k, t in enumerate((0.45, 0.9)):
            K.along("GauntletBand%d.%s" % (k, sd), "Bronze", "DEF-forearm." + sd, el + (wr - el) * t - d * 0.02,
                    el + (wr - el) * t + d * 0.02, 0.135, segments=16)
        base = wr + d * 0.03
        K.along("DrillCollar." + sd, "SteelDark", "DEF-hand." + sd, base, base + d * 0.05, 0.1, 0.1, segments=16)
        r, p = 0.095, base + d * 0.05
        for k in range(4):   # stepped cone reads as a spiral bit
            q = p + d * 0.085
            K.along("Drill%d.%s" % (k, sd), "Steel" if k % 2 == 0 else "SteelDark", "DEF-hand." + sd, p, q, r, r * 0.68, segments=14)
            p, r = q - d * 0.01, r * 0.74
        K.along("DrillTip." + sd, "Steel", "DEF-hand." + sd, p, p + d * 0.07, r, 0.002, segments=10)


def legs(J):
    for s, sd in ((1, "L"), (-1, "R")):
        kn, an = Vector(J["kn" + sd]), Vector(J["an" + sd])
        K.along("Boot." + sd, "Red", "DEF-shin." + sd, an, kn, 0.1, 0.095, 0.0, 0.8, segments=14)
        K.band("BootTrim." + sd, "Bronze", "DEF-shin." + sd, an + (kn - an) * 0.8, 0.1, 0.1, 0.03)
        K.sphere("Knee." + sd, "Bronze", "DEF-shin." + sd, kn + Vector((0, -0.05, 0)), (0.07, 0.05, 0.065), u=12, v=8)


def pecas():
    J = BP.body("Body", P, role="Joint")
    BP.feet("", J, P, role="RedDark", style="boot", size=1.7)
    head(P["head_c"], P["head_r"])
    torso(J)
    arms(J)
    legs(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=8)
    BP.run(arm, lean=8, stride=22, arm_swing=12)
    BP.attack(arm, "slam")
    BP.die(arm)
