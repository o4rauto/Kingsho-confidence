"""Rock-chunk cladding for lava and stone creatures: flat-shaded boxes laid tangent to a limb or a body
ellipsoid, so the glowing body shows through the gaps as cracks."""
import math
import random
from mathutils import Vector, Quaternion
import kit as K


def _place(name, role, bone, p, n, w, h, t, rnd):
    ob = K.box(name, role, bone, p, (w, h, t))
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n) @ Quaternion((0, 0, 1), rnd.uniform(-0.5, 0.5))
    return ob


def limb(prefix, bone, a, b, r, rings, per_ring, size, roles=("Rock", "RockDark"), seed=1, t0=0.0, t1=1.0):
    rnd = random.Random(seed)
    a, b = Vector(a), Vector(b)
    d = b - a
    axis = d.normalized()
    side = axis.orthogonal().normalized()
    up = axis.cross(side)
    for i in range(rings):
        t = t0 + (t1 - t0) * (i + 0.5) / rings
        for k in range(per_ring):
            ang = 2 * math.pi * k / per_ring + (i % 2) * math.pi / per_ring + rnd.uniform(-0.2, 0.2)
            n = side * math.cos(ang) + up * math.sin(ang)
            s = size * rnd.uniform(0.85, 1.15)
            _place("%s%d_%d" % (prefix, i, k), roles[rnd.randrange(len(roles))], bone, a + d * t + n * r, n,
                   s, s * rnd.uniform(0.8, 1.2) * (1.0 + 0.6 * d.length / (rings * s * 2)), s * 0.35, rnd)


def shell(prefix, bone, center, radii, count, size, roles=("Rock", "RockDark"), seed=1, min_z=-0.4, skip=None):
    """Plates over an ellipsoid (Fibonacci directions), skipping the underside below min_z (unit units)
    and any direction where skip(u) is true (e.g. keep the face clear)."""
    rnd = random.Random(seed)
    c = Vector(center)
    golden = math.pi * (3 - math.sqrt(5))
    n_total = int(count / max(0.05, (1 - min_z) / 2))
    placed = 0
    for i in range(n_total):
        z = 1 - 2 * (i + 0.5) / n_total
        if z < min_z:
            continue
        rr = math.sqrt(1 - z * z)
        th = golden * i
        u = Vector((math.cos(th) * rr, math.sin(th) * rr, z))
        if skip and skip(u):
            continue
        p = c + Vector((u.x * radii[0], u.y * radii[1], u.z * radii[2]))
        n = Vector((u.x / radii[0], u.y / radii[1], u.z / radii[2])).normalized()
        s = size * rnd.uniform(0.85, 1.2)
        _place("%s%d" % (prefix, i), roles[rnd.randrange(len(roles))], bone, p, n, s, s * rnd.uniform(0.8, 1.2), s * 0.35, rnd)
        placed += 1
    return placed


def _crack(name, role, bone, p, n, length, width, rnd):
    ob = K.sphere(name, role, bone, p, (width, length, width * 0.6), u=5, v=3)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n) @ Quaternion((0, 0, 1), rnd.uniform(0, math.pi))
    return ob


def cracks(prefix, bone, center, radii, count, length, role="Lava", seed=1, min_z=-0.4, skip=None, width=0.012):
    """Glowing crack strips lying on an ellipsoid surface (a rock body with lava showing through)."""
    rnd = random.Random(seed)
    c = Vector(center)
    golden = math.pi * (3 - math.sqrt(5))
    n_total = int(count / max(0.05, (1 - min_z) / 2))
    for i in range(n_total):
        z = 1 - 2 * (i + 0.5) / n_total
        if z < min_z:
            continue
        rr = math.sqrt(1 - z * z)
        th = golden * i
        u = Vector((math.cos(th) * rr, math.sin(th) * rr, z))
        if skip and skip(u):
            continue
        p = c + Vector((u.x * radii[0], u.y * radii[1], u.z * radii[2])) * 1.005
        n = Vector((u.x / radii[0], u.y / radii[1], u.z / radii[2])).normalized()
        _crack("%s%d" % (prefix, i), role, bone, p, n, length * rnd.uniform(0.7, 1.3), width, rnd)


def limb_cracks(prefix, bone, a, b, r, count, length, role="Lava", seed=1, width=0.01):
    rnd = random.Random(seed)
    a, b = Vector(a), Vector(b)
    d = b - a
    side = d.normalized().orthogonal().normalized()
    up = d.normalized().cross(side)
    for i in range(count):
        t = rnd.uniform(0.1, 0.9)
        ang = rnd.uniform(0, 2 * math.pi)
        n = side * math.cos(ang) + up * math.sin(ang)
        _crack("%s%d" % (prefix, i), role, bone, a + d * t + n * r * 1.01, n, length * rnd.uniform(0.7, 1.3), width, rnd)
