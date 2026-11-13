"""구조물: 기둥 · 석상 · 제단 · 계단 · 사다리 · 석관 · 받침대 · 난간 · 아치."""
import numpy as np

import sdf
from kit import (F, box, cap, chip, cone, cut_above, cyl, ell, hcyl, pool, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, v3)  # noqa: F401
import mats as M


def _drum(c, r, ln, axis_x=True):
    """누운 기둥 토막."""
    a, b = (v3(c[0] - ln / 2, c[1], c[2]), v3(c[0] + ln / 2, c[1], c[2])) if axis_x else (v3(c[0], c[1] - ln / 2, c[2]), v3(c[0], c[1] + ln / 2, c[2]))
    return lambda p: hcyl(p, a, b, r)


@prop("pillar", "structure", cell=(3, 4), collide=(0.74, 0.6), tags=["stone", "ruin"], name_ko="기둥",
    variants={"intact": {}, "cracked": {"state": "cracked"}, "mossy": {"state": "mossy"}, "broken": {"state": "broken"}, "stump": {"state": "stump"}, "fallen": {"state": "fallen"}})
def pillar(k, state="intact", seed=1):
    h = 2.7
    flute = lambda p: np.cos(np.arctan2(p[:, 1], p[:, 0]) * 10.0) * 0.012
    shaft = lambda p: cyl(p, v3(0, 0, 0.3), 0.235, h - 0.5) + flute(p)
    base = lambda p: np.minimum(box(p, v3(0, 0, 0.09), (0.37, 0.34, 0.09), 0.02), cyl(p, v3(0, 0, 0.17), 0.3, 0.14, 0.04))
    capital = lambda p: np.minimum(cyl(p, v3(0, 0, h - 0.25), 0.29, 0.1, 0.03), box(p, v3(0, 0, h - 0.08), (0.37, 0.34, 0.08), 0.02))
    mat = "stone_m" if state == "mossy" else "stone"
    k.add(rough(base, 0.02, 0.2, seed), "stone_d")
    if state in ("intact", "mossy"):
        k.add(rough(shaft, 0.02, 0.3, seed), mat)
        k.add(rough(capital, 0.02, 0.2, seed + 1), "stone_d")
    elif state == "cracked":
        k.add(chip(rough(shaft, 0.03, 0.3, seed), 0.48, 0.28, seed, 0.07), mat)
        k.add(chip(rough(capital, 0.02, 0.2, seed + 1), 0.5, 0.2, seed + 2, 0.1), "stone_d")
        k.rubble([(0.5, -0.25), (-0.46, -0.3)], "stone", 0.05, 0.09)
    elif state in ("broken", "stump"):
        top = 1.5 if state == "broken" else 0.62
        k.add(cut_above(rough(shaft, 0.03, 0.3, seed), top, 0.3, 0.2, seed, 0.5), mat)
        k.add(rough(_drum((0.78, -0.2, 0.2), 0.22, 0.5), 0.05, 0.2, seed + 3), "stone")
        k.rubble([(0.45, -0.38), (-0.5, -0.2), (1.1, -0.42), (-0.3, -0.42), (0.6, 0.25)], "stone", 0.06, 0.13)
    else:   # fallen: 밑동만 남고 몸통이 옆으로 쓰러져 토막 났다
        k.add(cut_above(rough(shaft, 0.03, 0.3, seed), 0.5, 0.25, 0.2, seed, -0.4), mat)
        for i, (cx, ln, cy, a) in enumerate(((0.75, 0.62, -0.1, 0.05), (1.5, 0.7, -0.02, -0.12))):
            d = _drum((cx, cy, 0.23), 0.225, ln)
            k.add(rough(lambda p, d=d, cx=cx, cy=cy, a=a: d(rot_z(p, a, (cx, cy, 0))) + np.cos(np.arctan2(p[:, 2] - 0.23, p[:, 1] - cy) * 10.0) * 0.012, 0.04, 0.25, seed + i), mat)
        k.rubble([(0.36, -0.35), (1.1, -0.38), (1.95, -0.3), (-0.4, -0.3), (1.1, 0.3)], "stone", 0.06, 0.12)
        return {"dx": -0.7, "cell": (4, 2)}
    return {}


def _figure(seed, y=0.0, z0=0.55):
    """갑옷 입은 수호자 석상의 몸(받침 위 z0부터). 칼을 앞에 짚고 섰다."""
    legs = lambda p: np.minimum(cap(p, v3(-0.13, y, z0), v3(-0.12, y, z0 + 0.75), 0.105, 0.13), cap(p, v3(0.13, y, z0), v3(0.12, y, z0 + 0.75), 0.105, 0.13))
    skirt = lambda p: cap(p, v3(0, y, z0 + 0.55), v3(0, y, z0 + 0.92), 0.27, 0.2)
    torso = lambda p: smin(ell(p, v3(0, y, z0 + 1.17), (0.25, 0.17, 0.3)), ell(p, v3(0, y, z0 + 1.38), (0.33, 0.18, 0.14)), 0.06)
    head = lambda p: smin(sphere(p, v3(0, y - 0.01, z0 + 1.68), 0.135), cone(p, v3(0, y, z0 + 1.7), 0.13, 0.22), 0.05)
    arm = lambda p, s: smin(cap(p, v3(s * 0.33, y, z0 + 1.38), v3(s * 0.3, y - 0.14, z0 + 1.05), 0.085, 0.075), cap(p, v3(s * 0.3, y - 0.14, z0 + 1.05), v3(s * 0.04, y - 0.25, z0 + 0.98), 0.07, 0.065), 0.03)
    body = lambda p: smin(smin(smin(np.minimum(legs(p), skirt(p)), torso(p), 0.05), head(p), 0.03), np.minimum(arm(p, -1), arm(p, 1)), 0.03)
    sword = lambda p: np.minimum(box(p, v3(0, y - 0.27, z0 + 0.5), (0.035, 0.018, 0.5)), box(p, v3(0, y - 0.27, z0 + 0.98), (0.15, 0.03, 0.025)))
    return body, sword, head


@prop("statue", "structure", cell=(3, 4), collide=(0.9, 0.7), tags=["stone", "ruin", "temple"], name_ko="석상",
    variants={"intact": {}, "mossy": {"state": "mossy"}, "headless": {"state": "headless"}, "broken": {"state": "broken"}, "ruined": {"state": "ruined"}})
def statue(k, state="intact", seed=1):
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.1), (0.46, 0.36, 0.1), 0.02), box(p, v3(0, 0, 0.36), (0.38, 0.29, 0.19), 0.02)), 0.025, 0.2, seed), "stone_d")
    body, sword, head = _figure(seed)
    mat = "stone_m" if state == "mossy" else "stone"
    if state in ("intact", "mossy"):
        k.add(rough(body, 0.02, 0.2, seed), mat)
        k.add(sword, mat)
    elif state == "headless":
        k.add(rough(lambda p: np.maximum(body(p), p[:, 2] - 2.1 - sdf.noise(p, 0.1, seed) * 0.1), 0.025, 0.2, seed), mat)
        k.add(sword, mat)
        k.add(rough(lambda p: smin(sphere(p, v3(0.62, -0.3, 0.13), 0.135), cone(rot_y(p, 1.3, (0.62, -0.3, 0.13)), v3(0.62, -0.3, 0.15), 0.13, 0.22), 0.05), 0.03, 0.15, seed), mat)
        k.rubble([(0.45, -0.42), (-0.5, -0.36)], "stone", 0.04, 0.08)
    elif state == "broken":   # 허리 위가 비스듬히 잘려 나갔다
        k.add(rough(lambda p: np.maximum(body(p), p[:, 2] - 1.55 - p[:, 0] * 0.9 - sdf.noise(p, 0.12, seed) * 0.15), 0.03, 0.2, seed), mat)
        k.add(lambda p: np.maximum(sword(p), p[:, 2] - 1.0), mat)
        k.add(rough(lambda p: ell(rot_y(p, 0.5, (-0.7, -0.25, 0.2)), v3(-0.7, -0.25, 0.2), (0.3, 0.19, 0.17)), 0.06, 0.15, seed + 1), mat)
        k.rubble([(0.55, -0.4), (-0.35, -0.45), (0.75, -0.15), (-1.0, -0.4)], "stone", 0.05, 0.11)
    else:   # ruined: 발목만 남았다
        k.add(rough(lambda p: np.maximum(body(p), p[:, 2] - 0.86 - sdf.noise(p, 0.1, seed) * 0.2), 0.03, 0.2, seed), mat)
        k.add(rough(lambda p: ell(p, v3(0.7, -0.2, 0.17), (0.33, 0.24, 0.18)), 0.09, 0.14, seed + 1), mat)
        k.add(rough(lambda p: ell(p, v3(-0.68, -0.32, 0.12), (0.2, 0.16, 0.13)), 0.07, 0.12, seed + 2), mat)
        k.rubble([(0.3, -0.48), (-0.3, -0.5), (1.05, -0.4), (-1.0, -0.15), (0.9, 0.2)], "stone", 0.05, 0.11)
    return {}


@prop("statue_robed", "structure", cell=(3, 4), collide=(0.9, 0.7), tags=["stone", "temple", "ritual"], name_ko="두건 쓴 석상",
    variants={"intact": {}, "weeping": {"state": "weeping"}})
def statue_robed(k, state="intact", seed=1):
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.1), (0.44, 0.36, 0.1), 0.02), cyl(p, v3(0, 0, 0.18), 0.33, 0.3, 0.03)), 0.025, 0.2, seed), "stone_d")
    z0 = 0.48
    folds = lambda p: np.sin(np.arctan2(p[:, 1], p[:, 0]) * 9.0 + p[:, 2] * 2.0) * 0.018 * np.clip(1.7 - p[:, 2], 0, 1)
    robe = lambda p: smin(cap(p, v3(0, 0, z0), v3(0, 0, z0 + 1.2), 0.34, 0.2), ell(p, v3(0, 0, z0 + 1.32), (0.3, 0.2, 0.17)), 0.1) + folds(p)
    hood = lambda p: sub(smin(sphere(p, v3(0, 0.02, z0 + 1.62), 0.17), ell(p, v3(0, 0.08, z0 + 1.5), (0.2, 0.18, 0.2)), 0.06), sphere(p, v3(0, -0.14, z0 + 1.6), 0.105))
    hands = lambda p: smin(cap(p, v3(-0.28, 0, z0 + 1.3), v3(0, -0.22, z0 + 1.02), 0.085, 0.07), cap(p, v3(0.28, 0, z0 + 1.3), v3(0, -0.22, z0 + 1.02), 0.085, 0.07), 0.04)
    k.add(rough(lambda p: smin(smin(robe(p), hood(p), 0.05), hands(p), 0.04), 0.02, 0.2, seed), "stone")
    k.add(lambda p: sphere(p, v3(0, -0.09, z0 + 1.6), 0.1), "void")
    k.add(rough(lambda p: np.minimum(cyl(p, v3(0, -0.26, z0 + 0.98), 0.1, 0.05, 0.01), cyl(p, v3(0, -0.26, z0 + 0.9), 0.04, 0.1)), 0.01), "stone_d")   # 받쳐 든 그릇
    if state == "weeping":
        k.add(lambda p: np.minimum(cap(p, v3(-0.03, -0.165, z0 + 1.56), v3(-0.04, -0.2, z0 + 1.3), 0.012), cap(p, v3(0.04, -0.165, z0 + 1.56), v3(0.05, -0.2, z0 + 1.36), 0.012)), "blood")
        k.add(lambda p: cyl(p, v3(0, -0.26, z0 + 1.0), 0.08, 0.035), "blood")
    return {}


@prop("altar", "structure", cell=(4, 3), collide=(1.8, 0.8), tags=["stone", "temple", "ritual"], name_ko="제단", interact="altar",
    variants={"plain": {}, "bloody": {"state": "bloody"}, "ritual": {"state": "ritual", "frames": 3}, "broken": {"state": "broken"}})
def altar(k, state="plain", seed=1, f=0):
    import fx
    k.add(rough(lambda p: box(p, v3(0, 0, 0.07), (0.98, 0.5, 0.07), 0.02), 0.02, 0.2, seed), "stone_d")
    body = lambda p: sub(box(p, v3(0, 0, 0.42), (0.78, 0.36, 0.3), 0.02), np.minimum(box(p, v3(-0.38, -0.36, 0.42), (0.26, 0.04, 0.2), 0.02), box(p, v3(0.38, -0.36, 0.42), (0.26, 0.04, 0.2), 0.02)))
    slab = lambda p: box(p, v3(0, 0, 0.8), (0.92, 0.44, 0.08), 0.025)
    if state == "broken":
        k.add(chip(rough(body, 0.03, 0.2, seed), 0.5, 0.3, seed, 0.1), "masonry")
        k.add(rough(lambda p: np.maximum(slab(p), p[:, 0] - 0.18 - p[:, 1] * 0.5 - sdf.noise(p, 0.1, seed) * 0.1), 0.02), "stone")
        k.add(rough(lambda p: np.maximum(slab(rot_y(p, -0.62, (0.95, 0, 0.4)) + 0.0), -(p[:, 0] - 0.26 - p[:, 1] * 0.5)), 0.03, 0.2, seed + 2), "stone")
        k.rubble([(0.3, -0.52), (1.2, -0.42), (-0.6, -0.55), (0.75, -0.6)], "stone", 0.05, 0.1)
        return {}
    k.add(rough(body, 0.02, 0.2, seed), "masonry")
    k.add(rough(slab, 0.015, 0.2, seed + 1), "stone")
    k.add(lambda p: np.minimum(disc := np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.42) - 0.15, np.abs(p[:, 1] + 0.37) - 0.02), 1e9), "carved")
    extra = {}
    if state in ("bloody", "ritual"):
        k.add(lambda p: np.minimum(pool(p, v3(0.1, -0.05, 0.885), 0.42, 0.24) + (sdf.noise(p, 0.12, seed) - 0.5) * 0.08, pool(p, v3(-0.5, 0.1, 0.885), 0.16, 0.12)), "blood")
        for x, ln in ((0.22, 0.34), (0.05, 0.2), (0.38, 0.5), (-0.5, 0.26)):
            k.add(lambda p, x=x, ln=ln: cap(p, v3(x, -0.445, 0.86), v3(x + 0.01, -0.445, 0.86 - ln), 0.016, 0.009), "blood")
    if state == "ritual":
        cands = [(-0.72, -0.2, 0.2), (-0.56, 0.2, 0.3), (0.74, -0.18, 0.26), (0.6, 0.22, 0.16)]
        for x, y, hh in cands:
            k.add(lambda p, x=x, y=y, hh=hh: smin(cyl(p, v3(x, y, 0.88), 0.04, hh, 0.01), cyl(p, v3(x, y, 0.88), 0.06, 0.02), 0.03), "wax")
        k.add(lambda p: smin(sphere(p, v3(-0.18, 0.05, 0.99), 0.11), box(p, v3(-0.18, -0.03, 0.93), (0.07, 0.06, 0.04), 0.02), 0.03), "bone")
        k.add(lambda p: np.minimum(sphere(p, v3(-0.22, -0.06, 1.0), 0.03), sphere(p, v3(-0.13, -0.06, 1.0), 0.03)), "void")
        extra["post"] = [lambda img, vw, c=c, i=i: fx.flame(img, *vw.px(c[0], c[1], 0.88 + c[2] + 0.01), 9, seed + i, f, "fire", 0.36, 2.4, 0.3) for i, c in enumerate(cands)]
    return extra


@prop("stairs_up", "structure", cell=(4, 4), collide=[(-1.0, -0.1, 0.22, 1.7), (0.78, -0.1, 0.22, 1.7)], tags=["stone"], name_ko="올라가는 계단", interact="stairs",
    variants={"stone": {}, "worn": {"state": "worn"}})
def stairs_up(k, state="stone", seed=1):
    n, w = 6, 0.78
    for i in range(n):
        y0 = -0.1 + i * 0.3
        st = lambda p, i=i, y0=y0: box(p, v3(0, y0 + (n - i) * 0.15, (i + 1) * 0.11), (w, (n - i) * 0.15, (i + 1) * 0.11), 0.015)
        k.add(rough(st, 0.05 if state == "worn" else 0.018, 0.25, seed + i), "stone" if i % 2 == 0 else "stone_l")
    for s in (-1, 1):
        wall = lambda p, s=s: np.maximum(box(p, v3(s * (w + 0.11), 0.8, 0.6), (0.11, 0.92, 0.6), 0.02), p[:, 2] - 0.34 - (p[:, 1] + 0.1) * 0.37)
        k.add(rough(wall, 0.025, 0.25, seed + 9), "masonry")
        k.add(rough(lambda p, s=s: box(p, v3(s * (w + 0.11), -0.12, 0.22), (0.15, 0.14, 0.22), 0.02), 0.02, 0.2, seed), "stone_d")
    if state == "worn":
        k.rubble([(-0.5, -0.35), (0.62, -0.3), (0.2, 0.2)], "stone", 0.04, 0.08)
    return {"far": 9.0}


@prop("stairs_down", "structure", layer="decal", cell=(3, 3), tags=["stone"], name_ko="내려가는 계단", interact="stairs", variants={"stone": {}})
def stairs_down(k, seed=1):
    """바닥에 뚫린 내려가는 계단: 낮은 돌 테 안에서 디딤판이 북쪽으로 갈수록 어둠에 잠긴다."""
    base = M.hexc("#77746a")

    def steps(p, n):
        t = np.clip((p[:, 1] + 0.62) / 1.3, 0, 1)
        i = np.floor(t * 6.0)
        fr = t * 6.0 - i
        c = base[None, :] * ((1.0 - i / 6.0) ** 1.7 * 0.95 + 0.03)[:, None] * (1.0 - (fr > 0.82) * 0.55)[:, None] * (0.9 + sdf.noise(p, 0.08, seed)[:, None] * 0.2)
        return c.astype(F), i.astype(F), np.ones(len(p), F)
    k.mat("steps", steps)
    k.add(lambda p: box(p, v3(0, 0.03, 0.006), (0.6, 0.66, 0.006)), "steps")
    rim = lambda p: sub(box(p, v3(0, 0.05, 0.07), (0.78, 0.84, 0.07), 0.02), box(p, v3(0, -0.1, 0.07), (0.6, 0.8, 0.3)))
    k.add(rough(rim, 0.025, 0.2, seed), "stone_d")
    return {"shadow": 0.2}


@prop("ladder", "structure", cell=(2, 4), tags=["wood"], name_ko="사다리", interact="ladder",
    variants={"wall": {}, "broken": {"state": "broken"}, "hatch": {"state": "hatch"}})
def ladder(k, state="wall", seed=1):
    if state == "hatch":   # 바닥 뚜껑문에서 올라온 사다리 머리
        frame = lambda p: sub(box(p, v3(0, 0.05, 0.05), (0.5, 0.5, 0.05), 0.015), box(p, v3(0, 0.05, 0.05), (0.38, 0.38, 0.2)))
        k.add(rough(frame, 0.015, 0.2, seed), "plank_x")
        k.add(lambda p: box(p, v3(0, 0.05, 0.004), (0.38, 0.38, 0.004)), "void")
        for s in (-1, 1):
            k.add(lambda p, s=s: cap(p, v3(s * 0.2, 0.3, 0.0), v3(s * 0.2, 0.34, 0.62), 0.03), "wood")
        for z in (0.2, 0.46):
            k.add(lambda p, z=z: cap(p, v3(-0.2, 0.3 + z * 0.06, z), v3(0.2, 0.3 + z * 0.06, z), 0.022), "wood_l")
        return {"cell": (2, 2)}
    top, lean = 2.5, 0.42
    pos = lambda s, t: v3(s * 0.22, -0.2 + lean * t, top * t)
    for s in (-1, 1):
        t1 = 0.55 if (state == "broken" and s > 0) else 1.0
        k.add(rough(lambda p, s=s, t1=t1: cap(p, pos(s, 0), pos(s, t1), 0.034), 0.012, 0.2, seed), "wood")
    for i in range(8):
        t = 0.1 + i * 0.115
        if state == "broken" and i in (3, 5, 6, 7):
            if i == 3:
                k.add(lambda p, t=t: cap(p, pos(-1, t), pos(-1, t) + v3(0.24, 0, -0.12), 0.024), "wood_l")
            continue
        k.add(lambda p, t=t: cap(p, pos(-1, t), pos(1, t), 0.024), "wood_l")
    if state == "broken":
        k.add(lambda p: cap(p, v3(0.1, -0.5, 0.03), v3(0.6, -0.36, 0.03), 0.03), "wood")
        k.add(lambda p: cap(p, v3(-0.3, -0.5, 0.025), v3(0.05, -0.62, 0.025), 0.022), "wood_l")
    return {}


@prop("sarcophagus", "structure", cell=(4, 3), collide=(1.9, 0.9), tags=["stone", "tomb"], name_ko="석관", interact="container",
    variants={"closed": {}, "ajar": {"state": "ajar"}, "open": {"state": "open"}, "broken": {"state": "broken"}})
def sarcophagus(k, state="closed", seed=1):
    L, W, H = 0.9, 0.4, 0.56
    k.add(rough(lambda p: box(p, v3(0, 0, 0.06), (L + 0.1, W + 0.1, 0.06), 0.02), 0.02, 0.2, seed), "stone_d")
    chest = lambda p: sub(box(p, v3(0, 0, 0.12 + H / 2), (L, W, H / 2), 0.02), box(p, v3(0, 0, 0.3 + H / 2), (L - 0.09, W - 0.09, H / 2)))
    panel = lambda p: np.minimum.reduce([box(p, v3(x, -W, 0.12 + H / 2), (0.2, 0.025, H / 2 - 0.1), 0.02) for x in (-0.58, 0, 0.58)])
    k.add(rough(lambda p: sub(chest(p), panel(p)), 0.02, 0.2, seed), "stone" if state != "broken" else "stone_m")
    lid = lambda p: smin(box(p, v3(0, 0, 0), (L + 0.05, W + 0.05, 0.06), 0.02), smin(ell(p, v3(0.08, 0, 0.07), (0.6, 0.2, 0.09)), sphere(p, v3(-0.62, 0, 0.09), 0.12), 0.05), 0.03)   # 뚜껑 위에 누운 사람 돋을새김
    zl = 0.12 + H + 0.06
    if state == "closed":
        k.add(rough(lambda p: lid(p - v3(0, 0, zl)), 0.02, 0.2, seed + 1), "stone_l")
    elif state == "ajar":
        k.add(rough(lambda p: lid(rot_z(p - v3(0.12, -0.16, zl), 0.2)), 0.02, 0.2, seed + 1), "stone_l")
        k.add(lambda p: box(p, v3(0, 0, 0.36), (L - 0.09, W - 0.09, 0.02)), "void")
    else:
        k.add(lambda p: box(p, v3(0, 0, 0.3), (L - 0.09, W - 0.09, 0.02)), "void")
        if state == "open":   # 뚜껑은 앞에 기대 놓였고 안에 유골
            k.add(rough(lambda p: lid(rot_x(p - v3(0.1, -0.66, 0.3), -1.05)), 0.02, 0.2, seed + 1), "stone_l")
            k.add(lambda p: smin(sphere(p, v3(-0.58, 0, 0.43), 0.1), ell(p, v3(-0.2, 0, 0.4), (0.22, 0.14, 0.07)), 0.03), "bone")
            k.add(lambda p: np.minimum(cap(p, v3(0.05, -0.07, 0.38), v3(0.6, -0.09, 0.38), 0.03), cap(p, v3(0.05, 0.07, 0.38), v3(0.6, 0.1, 0.38), 0.03)), "bone")
        else:                 # broken: 뚜껑이 두 동강 나 바닥에
            k.add(rough(lambda p: np.maximum(lid(rot_z(p - v3(-0.5, -0.74, 0.07), 0.25)), p[:, 0] + 0.35 + sdf.noise(p, 0.1, seed) * 0.12), 0.03, 0.2, seed + 1), "stone_l")
            k.add(rough(lambda p: np.maximum(lid(rot_x(p - v3(0.5, -0.6, 0.26), -0.9)), -(p[:, 0] - 0.1 + sdf.noise(p, 0.1, seed) * 0.12)), 0.03, 0.2, seed + 2), "stone_l")
            k.rubble([(0.0, -0.75), (1.1, -0.6), (-1.15, -0.5)], "stone", 0.04, 0.09)
    return {"foot": 1.1}


@prop("pedestal", "structure", cell=(2, 3), collide=(0.6, 0.5), tags=["stone", "temple"], name_ko="받침대", interact="pedestal",
    variants={"empty": {}, "orb": {"state": "orb"}, "orb_red": {"state": "orb", "col": "r"}, "idol": {"state": "idol"}, "broken": {"state": "broken"}},
    light={"color": "#70b0f0", "radius": 2.0, "at": (0, 0, 1.2), "flicker": 0.15, "variants": ["orb", "orb_red"]})
def pedestal(k, state="empty", col="b", seed=1):
    import fx
    col_ = lambda p: np.minimum.reduce([box(p, v3(0, 0, 0.07), (0.3, 0.26, 0.07), 0.02), box(p, v3(0, 0, 0.5), (0.2, 0.17, 0.4), 0.03) + np.abs(np.sin(p[:, 0] * 26.0)) * 0.008, box(p, v3(0, 0, 0.95), (0.28, 0.24, 0.06), 0.02)])
    if state == "broken":
        k.add(cut_above(rough(col_, 0.03, 0.2, seed), 0.55, 0.3, 0.2, seed, 0.6), "stone")
        k.add(rough(lambda p: box(rot_y(p, 0.4, (0.55, -0.2, 0.1)), v3(0.55, -0.2, 0.1), (0.26, 0.2, 0.07), 0.02), 0.03, 0.2, seed), "stone")
        k.rubble([(-0.4, -0.3), (0.3, -0.42), (0.85, -0.38)], "stone", 0.04, 0.09)
        return {}
    k.add(rough(col_, 0.018, 0.2, seed), "stone")
    if state == "orb":
        g = "glow_b" if col == "b" else "glow_r"
        k.add(lambda p: cyl(p, v3(0, 0, 1.0), 0.09, 0.05, 0.01), "brass")
        k.add(lambda p: sphere(p, v3(0, 0, 1.2), 0.15), k.mat("orb", M.plain("#2e4a78" if col == "b" else "#7a2630", 0.5, 0.08)))
        c = "#70b0f0" if col == "b" else "#e04848"
        return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 1.2), 9, c, 0.9), [vw.px(-0.05, -0.1, 1.27)])], "glow": [(0, 0, 1.2, 44, c, 0.45)]}
    if state == "idol":
        k.add(lambda p: smin(smin(ell(p, v3(0, 0, 1.17), (0.12, 0.1, 0.16)), sphere(p, v3(0, 0, 1.4), 0.09), 0.04), box(p, v3(0, 0, 1.03), (0.13, 0.11, 0.03), 0.01), 0.03), "gold")
    return {}


@prop("railing", "structure", cell=(2, 2), collide=(1.0, 0.25), tags=["stone"], name_ko="난간", meta={"tile_w": 1},
    variants={"straight": {}, "post": {"state": "post"}, "broken": {"state": "broken"}, "side": {"state": "side"}})
def railing(k, state="straight", seed=1):
    if state == "side":   # 깊이 방향으로 놓인 난간(세로 줄)
        k.yaw = np.pi / 2
        state = "straight"
    bal = lambda p, x: smin(cyl(p, v3(x, 0, 0.1), 0.05, 0.56), ell(p, v3(x, 0, 0.3), (0.085, 0.085, 0.14)), 0.04)
    xs = (-0.375, -0.125, 0.125, 0.375)
    if state == "post":
        k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.42), (0.13, 0.13, 0.42), 0.02), smin(box(p, v3(0, 0, 0.88), (0.16, 0.16, 0.04), 0.01), sphere(p, v3(0, 0, 1.0), 0.1), 0.03)), 0.015, 0.2, seed), "stone")
        return {}
    cutx = 0.05
    keep = (lambda p: p[:, 0] - cutx - sdf.noise(p, 0.1, seed) * 0.15) if state == "broken" else (lambda p: np.full(len(p), -1.0, F))
    k.add(rough(lambda p: np.maximum(box(p, v3(0, 0, 0.05), (0.5, 0.11, 0.05)), keep(p)), 0.012, 0.2, seed), "stone_d")
    k.add(rough(lambda p: np.maximum(box(p, v3(0, 0, 0.71), (0.5, 0.1, 0.05), 0.01), keep(p)), 0.012, 0.2, seed + 1), "stone_d")
    for x in xs:
        if state == "broken" and x > cutx:
            continue
        k.add(lambda p, x=x: bal(p, x), "stone")
    if state == "broken":
        k.add(lambda p: bal(rot_y(p, 1.45, (0.3, -0.25, 0.07)), 0.3) + (p[:, 1] * 0 + 0), "stone")
        k.rubble([(0.2, -0.3), (0.42, 0.05), (0.1, 0.2)], "stone", 0.04, 0.07)
    return {}


@prop("arch", "structure", cell=(5, 5), collide=[(-1.35, -0.3, 0.6, 0.6), (0.75, -0.3, 0.6, 0.6)], tags=["stone", "ruin"], name_ko="아치",
    variants={"intact": {}, "mossy": {"state": "mossy"}, "ruined": {"state": "ruined"}})
def arch(k, state="intact", seed=1):
    R, pier_h, d = 0.78, 1.7, 0.26
    mat = "masonry_m" if state != "intact" else "masonry"
    pier = lambda p, s: np.minimum(box(p, v3(s * 1.05, 0, pier_h / 2), (0.25, d, pier_h / 2), 0.02), np.minimum(box(p, v3(s * 1.05, 0, 0.1), (0.32, d + 0.06, 0.1), 0.02), box(p, v3(s * 1.05, 0, pier_h), (0.31, d + 0.05, 0.07), 0.02)))
    ring = lambda p: np.maximum(np.maximum(np.abs(np.hypot(p[:, 0], p[:, 2] - pier_h) - (R + 0.27)) - 0.27, np.abs(p[:, 1]) - d), pier_h - 0.02 - p[:, 2])
    key = lambda p: box(p, v3(0, 0, pier_h + R + 0.3), (0.13, d + 0.04, 0.3), 0.02)
    if state == "ruined":
        gone = lambda p: (p[:, 0] - 0.1) * 0.8 + (p[:, 2] - 1.9) * 0.6 + (sdf.fbm(p, 0.3, seed, 2) - 0.5) * 0.5   # 오른쪽 위가 무너졌다
        k.add(rough(lambda p: pier(p, -1), 0.03, 0.25, seed), mat)
        k.add(rough(lambda p: np.maximum(pier(p, 1), p[:, 2] - 0.95 - sdf.noise(p, 0.15, seed) * 0.35), 0.03, 0.25, seed + 1), mat)
        k.add(rough(lambda p: np.maximum(ring(p), gone(p)), 0.03, 0.2, seed + 2), k.mat("vous", M.masonry("#86837a", 0.3, 0.3, "#4a5236", 5)))
        for i, (x, y, a) in enumerate(((0.9, -0.55, 0.3), (1.5, -0.3, 1.1), (0.4, -0.7, -0.4))):
            k.add(rough(lambda p, x=x, y=y, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.13), (0.24, 0.16, 0.13), 0.03), 0.04, 0.15, seed + i), "stone")
        k.rubble(k.scatter(8, 0.9, 0.3, 1.0, -0.5), "stone", 0.05, 0.1)
    else:
        k.add(rough(lambda p: np.minimum(pier(p, -1), pier(p, 1)), 0.025, 0.25, seed), mat)
        k.add(rough(ring, 0.025, 0.2, seed + 2), k.mat("vous", M.masonry("#86837a", 0.3, 0.3, "#4a5236" if state == "mossy" else None, 5)))
        k.add(rough(key, 0.02, 0.2, seed + 3), "stone_l")
    return {"far": 9.0}
