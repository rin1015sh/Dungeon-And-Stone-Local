"""망자의 땅 소품 · 큰 구조물 빚기(tools/f2_art/props.py가 부른다). 한 함수 = 한 그림: (Scene, 재질 표, 덧붙임)을 돌려준다.
좌표는 칸 단위(sdf.py), 원점 = 발 칸 가운데. 덧붙임 {"glow": [(x, y, z, 반지름 px, 색, 세기)], "shadow": 바닥 그림자 세기}."""
import numpy as np

import mats as M
import sdf
from sdf import Scene, box, cap, cone, cyl, ell, gable, smin, sphere, sub, v3

F = np.float32
STONE, STONE_D, MOSS = "#7d7a70", "#55534c", "#4a5236"
IRON, WOODC = "#3a3a3c", "#4a3a2a"


def rough(fn, amp=0.035, scale=0.25, seed=1):
    """표면을 잡음으로 흔든다(닳고 깨진 돌 · 굽은 나무)."""
    return lambda p: fn(p) + (sdf.fbm(p, scale, seed, 2) - 0.5) * amp


def rot_z(p, c, a):
    q = p - c
    ca, sa = np.cos(a), np.sin(a)
    return np.stack([q[:, 0] * ca + q[:, 1] * sa, -q[:, 0] * sa + q[:, 1] * ca, q[:, 2]], 1) + c


def rot_y(p, c, a):
    q = p - c
    ca, sa = np.cos(a), np.sin(a)
    return np.stack([q[:, 0] * ca + q[:, 2] * sa, q[:, 1], -q[:, 0] * sa + q[:, 2] * ca], 1) + c


def rubble(sc, pts, seed, mat="stone"):
    rng = np.random.default_rng(seed)
    for x, y in pts:
        r = rng.uniform(0.09, 0.2)
        c = v3(x, y, r * 0.6)
        sc.add(rough(lambda p, c=c, r=r: ell(p, c, (r * 1.2, r, r * 0.75)), 0.05, 0.12, int(rng.integers(99))), mat)


def pickets(sc, x0, x1, n, h, y=0.0, r=0.028, tip=0.16, rails=(0.25, 0.8)):
    """쇠창살 줄: 창끝 달린 살 n개 + 가로대."""
    for k in range(n):
        x = x0 + (x1 - x0) * (k + 0.5) / n
        hh = h * (1.0 + 0.06 * np.sin(k * 2.3))
        if tip > 0.0:
            sc.add(lambda p, x=x, hh=hh: np.minimum(cap(p, v3(x, y, 0), v3(x, y, hh), r), cone(p, v3(x, y, hh - 0.02), r * 2.4, tip)), "iron")
        else:
            sc.add(lambda p, x=x, hh=hh: cap(p, v3(x, y, 0), v3(x, y, hh), r), "iron")
    for z in rails:
        sc.add(lambda p, z=z: cap(p, v3(x0, y, h * z), v3(x1, y, h * z), r * 0.9), "iron")


def base_mats():
    return {"stone": M.stone(STONE, MOSS), "stone2": M.stone("#605e57", MOSS, 5), "masonry": M.masonry(STONE, moss=MOSS),
        "iron": M.metal(IRON, "#5a4234", 8, 0.3), "wood": M.wood(WOODC), "roof": M.masonry("#6c6a64", 0.3, 0.7, MOSS, 9), "void": M.void(), "dirt": M.plain("#4a443c", 0.4, 0.15),
        "bone": M.plain("#c8c0aa", 0.2), "bronze": M.metal("#5e5240", "#7a4e32", 3, 0.6)}


def mausoleum():
    sc, m = Scene(), base_mats()
    w, d, hgt, y0 = 2.5, 1.3, 2.7, 1.2   # 몸 반폭 · 반깊이 · 높이 · 가운데 y
    sc.add(rough(lambda p: np.minimum(box(p, v3(0, y0, 0.14), (w + 0.6, d + 0.55, 0.14), 0.03), box(p, v3(0, y0, 0.4), (w + 0.3, d + 0.3, 0.14), 0.03)), 0.03), "stone2")
    door = lambda p: np.minimum(box(p, v3(0, y0 - d, 1.15), (0.5, 0.5, 0.65)), sdf.length((p - v3(0, 0, 1.8))[:, [0, 2]]) - 0.5)
    sc.add(rough(lambda p: sub(box(p, v3(0, y0, 0.54 + hgt / 2), (w, d, hgt / 2), 0.02), np.maximum(door(p), np.abs(p[:, 1] - (y0 - d)) - 0.45)), 0.025), "masonry")
    sc.add(lambda p: box(p, v3(0, y0 - d + 0.4, 1.4), (0.52, 0.03, 0.95)), "void")
    for k in range(5):
        x = -0.36 + k * 0.18
        sc.add(lambda p, x=x: cap(p, v3(x, y0 - d + 0.16, 0.55), v3(x, y0 - d + 0.16, 2.25), 0.03), "iron")
    sc.add(lambda p: cap(p, v3(-0.48, y0 - d + 0.16, 1.4), v3(0.48, y0 - d + 0.16, 1.4), 0.03), "iron")
    for x in (-2.15, -1.25, 1.25, 2.15):   # 기둥
        sc.add(rough(lambda p, x=x: np.minimum(np.minimum(cyl(p, v3(x, y0 - d - 0.22, 0.54), 0.19, hgt - 0.1), box(p, v3(x, y0 - d - 0.22, 0.62), (0.27, 0.27, 0.09), 0.02)),
            box(p, v3(x, y0 - d - 0.22, 0.5 + hgt - 0.12), (0.27, 0.27, 0.09), 0.02)), 0.02), "stone")
    top = 0.54 + hgt
    sc.add(rough(lambda p: box(p, v3(0, y0 - 0.1, top + 0.13), (w + 0.25, d + 0.35, 0.13), 0.02), 0.02), "stone")
    roof = lambda p: gable(p, v3(0, y0 - 0.1, top + 0.26), d + 0.4, w + 0.3, 1.0, 1)
    sc.add(rough(lambda p: sub(roof(p), np.maximum(gable(p, v3(0, y0 - 0.1, top + 0.36), d + 0.6, w - 0.25, 0.72, 1), p[:, 1] - (y0 - d - 0.38))), 0.03, 0.3), "roof")
    sc.add(lambda p: np.minimum(ell(p, v3(0, y0 - d - 0.42, top + 0.66), (0.2, 0.1, 0.22)), box(p, v3(0, y0 - d - 0.42, top + 0.46), (0.1, 0.06, 0.07), 0.02)), "bone")
    rubble(sc, [(2.9, -0.2), (3.2, 0.1), (2.6, -0.45), (-3.0, -0.3), (3.4, -0.35)], 3)
    return sc, m, {}


def angel():
    sc, m = Scene(), base_mats()
    y = 0.5
    sc.add(rough(lambda p: np.minimum(box(p, v3(0, y, 0.16), (0.95, 0.8, 0.16), 0.03), box(p, v3(0, y, 0.72), (0.7, 0.58, 0.42), 0.03)), 0.03), "stone2")
    robe = lambda p: smin(cap(p, v3(0, y, 1.1), v3(0, y, 2.3), 0.56, 0.3), ell(p, v3(0, y, 2.5), (0.46, 0.27, 0.26)), 0.14)          # 옷자락 · 어깨
    head = lambda p: smin(sphere(p, v3(0, y - 0.05, 2.98), 0.18), ell(p, v3(0, y + 0.07, 3.0), (0.25, 0.25, 0.3)), 0.04)               # 두건 쓴 머리(숙였다)
    arms = lambda p: np.minimum(smin(cap(p, v3(-0.44, y, 2.52), v3(-0.3, y - 0.26, 2.08), 0.12, 0.1), cap(p, v3(-0.3, y - 0.26, 2.08), v3(0, y - 0.34, 2.3), 0.09, 0.07), 0.03),
        smin(cap(p, v3(0.44, y, 2.52), v3(0.3, y - 0.26, 2.08), 0.12, 0.1), cap(p, v3(0.3, y - 0.26, 2.08), v3(0, y - 0.34, 2.3), 0.09, 0.07), 0.03))   # 모은 두 손
    folds = lambda p: (np.sin(p[:, 0] * 20.0 + np.sin(p[:, 2] * 3.0)) * 0.022) * np.clip(2.3 - p[:, 2], 0, 1)
    sc.add(rough(lambda p: smin(smin(robe(p) + folds(p), head(p), 0.07), arms(p), 0.05), 0.025, 0.2), "stone")
    piv_l, piv_r = v3(-0.2, y + 0.3, 2.3), v3(0.2, y + 0.3, 2.3)
    wing = lambda p, piv, a: smin(ell(rot_y(p, piv, a), piv + v3(0, 0, 1.0), (0.5, 0.09, 1.3)), ell(rot_y(p, piv, a * 1.9), piv + v3(0, 0.02, 0.45), (0.36, 0.08, 0.8)), 0.08)
    broken = lambda p: np.maximum(wing(p, piv_r, -0.55), p[:, 2] - 3.05 - sdf.noise(p, 0.15, 4) * 0.4)   # 오른 날개는 부러졌다
    feather = lambda p: np.sin(p[:, 2] * 15.0 - np.abs(p[:, 0]) * 7.0) * 0.014
    sc.add(rough(lambda p: np.minimum(wing(p, piv_l, 0.55), broken(p)) + feather(p), 0.03, 0.18, 2), "stone2")
    rubble(sc, [(1.15, -0.3), (1.4, -0.05)], 5)
    return sc, m, {"scale": 1.6}


def tower():
    sc, m = Scene(), base_mats()
    w, d, y0, hgt = 1.55, 1.15, 1.1, 6.2
    top = lambda p: 5.3 + sdf.noise(p * np.array([1, 1, 0], F), 0.55, 3) * 1.5 + np.abs(p[:, 0]) * 0.25     # 무너진 꼭대기 선
    shell = lambda p: sub(box(p, v3(0, y0, hgt / 2), (w, d, hgt / 2), 0.02), box(p, v3(0, y0, hgt / 2 + 1.4), (w - 0.28, d - 0.28, hgt / 2)))
    arch = lambda p, x: np.minimum(box(p, v3(x, y0 - d, 4.05), (0.3, 0.6, 0.45)), np.maximum(sdf.length((p - v3(x, 0, 4.5))[:, [0, 2]]) - 0.3, np.abs(p[:, 1] - (y0 - d)) - 0.6))
    slit = lambda p: box(p, v3(0, y0 - d, 2.2), (0.07, 0.5, 0.45))
    sc.add(rough(lambda p: sub(sub(sub(np.maximum(shell(p), p[:, 2] - top(p)), arch(p, -0.62)), arch(p, 0.62)), slit(p)), 0.035, 0.3), "masonry")
    sc.add(lambda p: box(p, v3(0, y0 - d + 0.42, 3.3), (w - 0.2, 0.04, 1.6)), "void")
    sc.add(rough(lambda p: box(p, v3(0, y0, 0.2), (w + 0.22, d + 0.22, 0.2), 0.03), 0.03), "stone2")
    sc.add(lambda p: smin(cone(p, v3(-0.62, y0 - d + 0.22, 3.72), 0.26, 0.62), cyl(p, v3(-0.62, y0 - d + 0.22, 3.7), 0.28, 0.08, 0.03), 0.04), "bronze")
    rubble(sc, [(1.95, -0.35), (2.25, -0.1), (1.7, -0.6), (2.5, -0.5), (-2.0, -0.4), (2.1, 0.3)], 7, "stone2")
    return sc, m, {}


def dead_tree(seed=11, h=4.4, r=0.46):
    """말라 죽은 큰 나무: 뒤틀린 줄기 + 갈라지는 굵은 가지 + 드러난 뿌리."""
    sc, m = Scene(), base_mats()
    m["bark"] = M.bark("#3a332c")
    rng = np.random.default_rng(seed)
    segs = []

    def grow(a, direction, length, rad, depth):
        b = a + direction * length
        segs.append((a, b, rad, rad * (0.62 if depth > 0 else 0.15)))
        if depth <= 0 or rad < 0.02:
            return
        for _ in range(2 if depth > 1 else int(rng.integers(2, 4))):
            nd = direction + rng.normal(0, 0.55, 3).astype(F) * np.array([1.0, 0.7, 0.55], F)
            nd[2] = abs(nd[2]) * 0.6 + 0.25
            grow(b, nd / np.sqrt((nd * nd).sum()), length * rng.uniform(0.62, 0.82), rad * 0.6, depth - 1)

    grow(v3(0, 0.3, 0), v3(0.06, 0, 1), h * 0.4, r, 5)
    for k in range(5):   # 뿌리
        a = k * 1.26 + 0.4
        segs.append((v3(0, 0.3, 0.35), v3(np.cos(a) * r * 2.3, 0.3 + np.sin(a) * r * 1.7, 0.02), r * 0.4, r * 0.12))
    thick = [s for s in segs if s[2] >= 0.09]
    thin = [s for s in segs if s[2] < 0.09]

    def trunk(p):
        d = None
        for a, b, ra, rb in thick:
            di = cap(p, a, b, ra, rb)
            d = di if d is None else smin(d, di, 0.09)
        return d + (sdf.fbm(p * np.array([1, 1, 0.3], F), 0.14, seed, 2) - 0.5) * 0.06

    def twigs(p):
        d = np.full(len(p), 1e9, F)
        for a, b, ra, rb in thin:
            d = np.minimum(d, cap(p, a, b, ra, rb))
        return d
    sc.add(trunk, "bark")
    if thin:
        sc.add(twigs, "bark")
    return sc, m, {"scale": 1.35}


def knight():
    sc, m = Scene(), base_mats()
    y = 0.45
    sc.add(rough(lambda p: np.minimum(box(p, v3(0, y, 0.15), (0.75, 0.62, 0.15), 0.03), box(p, v3(0, y, 0.62), (0.55, 0.45, 0.34), 0.03)), 0.03), "stone2")
    legs = lambda p: np.minimum(cap(p, v3(-0.17, y, 0.96), v3(-0.19, y, 1.75), 0.14, 0.17), cap(p, v3(0.17, y, 0.96), v3(0.19, y, 1.75), 0.14, 0.17))
    torso = lambda p: smin(ell(p, v3(0, y, 2.2), (0.36, 0.25, 0.5)), ell(p, v3(0, y, 2.55), (0.5, 0.26, 0.2)), 0.1)
    helm = lambda p: np.minimum(smin(sphere(p, v3(0, y, 3.02), 0.2), cyl(p, v3(0, y, 2.78), 0.17, 0.2), 0.05), ell(p, v3(0, y + 0.05, 3.25), (0.06, 0.2, 0.12)))
    arms = lambda p: np.minimum(smin(cap(p, v3(-0.48, y, 2.55), v3(-0.34, y - 0.22, 2.0), 0.13, 0.11), cap(p, v3(-0.34, y - 0.22, 2.0), v3(-0.04, y - 0.33, 1.9), 0.1, 0.09), 0.04),
        smin(cap(p, v3(0.48, y, 2.55), v3(0.34, y - 0.22, 2.0), 0.13, 0.11), cap(p, v3(0.34, y - 0.22, 2.0), v3(0.04, y - 0.33, 1.9), 0.1, 0.09), 0.04))
    cape = lambda p: box(p, v3(0, y + 0.26, 1.85), (0.5, 0.05, 0.85), 0.04) + np.sin(p[:, 0] * 14.0) * 0.02
    sc.add(rough(lambda p: np.minimum(smin(smin(legs(p), torso(p), 0.08), smin(helm(p), arms(p), 0.05), 0.05), cape(p)), 0.025, 0.2), "stone")
    sc.add(lambda p: np.minimum(box(p, v3(0, y - 0.34, 1.42), (0.045, 0.02, 0.5)), np.minimum(box(p, v3(0, y - 0.34, 1.9), (0.2, 0.035, 0.035)), cap(p, v3(0, y - 0.34, 1.9), v3(0, y - 0.34, 2.12), 0.035))), "stone2")
    return sc, m, {"scale": 1.6}


# ── 서 있는 소품(2 × 3칸) ──
def fence():
    sc, m = Scene(), base_mats()
    pickets(sc, -0.5, 0.5, 5, 1.25)
    return sc, m, {}


def lantern():
    sc, m = Scene(), base_mats()
    m["lamp"] = M.glow("#cfe0ff")
    sc.add(lambda p: np.minimum(cap(p, v3(0, 0, 0), v3(0, 0, 1.75), 0.045, 0.035), cyl(p, v3(0, 0, 0), 0.1, 0.07, 0.02)), "iron")
    sc.add(lambda p: smin(cap(p, v3(0, 0, 1.72), v3(0.3, 0, 1.82), 0.03), cap(p, v3(0.3, 0, 1.82), v3(0.3, 0, 1.66), 0.02), 0.03), "iron")
    sc.add(lambda p: np.minimum(box(p, v3(0.3, 0, 1.66), (0.1, 0.1, 0.02)), np.minimum(box(p, v3(0.3, 0, 1.36), (0.1, 0.1, 0.02)), cone(p, v3(0.3, 0, 1.67), 0.12, 0.1))), "iron")
    sc.add(lambda p: box(p, v3(0.3, 0, 1.51), (0.075, 0.075, 0.13), 0.02), "lamp")
    return sc, m, {"glow": [(0.3, 0, 1.51, 46, "#a8c4ff", 0.75)]}


def bush():
    sc, m = Scene(), base_mats()
    m["leaf"] = M.leaf("#4a4e40", 0.2, 3, 0.04)
    m["twig"] = M.plain("#2e2823", 0.3)
    rng = np.random.default_rng(4)
    blobs = [(v3(rng.uniform(-0.3, 0.3), rng.uniform(-0.15, 0.2), rng.uniform(0.18, 0.42)), rng.uniform(0.17, 0.28)) for _ in range(7)]

    def clump(p):
        d = None
        for c, r in blobs:
            di = sphere(p, c, r)
            d = di if d is None else smin(d, di, 0.08)
        return d + (sdf.fbm(p, 0.09, 5, 2) - 0.5) * 0.12
    sc.add(clump, "leaf")
    for k in range(6):
        a = rng.uniform(0, 6.28)
        tip = v3(np.cos(a) * 0.45, np.sin(a) * 0.25, rng.uniform(0.5, 0.85))
        sc.add(lambda p, tip=tip: cap(p, v3(0, 0, 0.1), tip, 0.03, 0.012), "twig")
    return sc, m, {}


def dig():
    sc, m = Scene(), base_mats()
    m["dirt"] = M.plain("#4c443a", 0.5, 0.1)
    sc.add(rough(lambda p: ell(p, v3(0, 0.25, 0.0), (0.62, 0.5, 0.3)), 0.07, 0.12, 2), "dirt")
    lean = 0.12
    sc.add(lambda p: np.minimum(box(rot_y(p, v3(0, 0.62, 0), lean), v3(0, 0.62, 0.55), (0.05, 0.04, 0.55)), box(rot_y(p, v3(0, 0.62, 0), lean), v3(0, 0.62, 0.78), (0.26, 0.04, 0.05))), "wood")
    rubble(sc, [(0.55, -0.2), (-0.6, -0.05)], 9, "stone2")
    return sc, m, {}


def epitaph():
    sc, m = Scene(), base_mats()
    m["slab"] = M.stone("#86837a", MOSS, 7, 0.15)
    sc.add(rough(lambda p: box(p, v3(0, 0.1, 0.1), (0.58, 0.3, 0.1), 0.02), 0.02), "stone2")
    slab = lambda p: np.minimum(box(p, v3(0, 0.12, 0.85), (0.42, 0.1, 0.66), 0.02), np.maximum(sdf.length((p - v3(0, 0, 1.5))[:, [0, 2]]) - 0.42, np.abs(p[:, 1] - 0.12) - 0.1))
    sc.add(rough(lambda p: sub(slab(p), sphere(p, v3(0.45, 0.02, 1.75), 0.2)), 0.02, 0.2), "slab")
    return sc, m, {}


def tomb_door():
    sc, m = Scene(), base_mats()
    frame = lambda p: sub(box(p, v3(0, 0.15, 0.95), (0.62, 0.22, 0.95), 0.02), box(p, v3(0, 0, 0.75), (0.4, 0.6, 0.75)))
    sc.add(rough(lambda p: np.minimum(frame(p), box(p, v3(0, 0.12, 1.95), (0.72, 0.27, 0.12), 0.02)), 0.025), "masonry")
    sc.add(lambda p: box(p, v3(0, 0.3, 0.75), (0.4, 0.03, 0.75)), "void")
    pickets(sc, -0.4, 0.4, 5, 1.48, 0.1, 0.03, 0.0, (0.2, 0.55, 0.9))
    sc.add(lambda p: box(p, v3(0.12, 0.04, 0.82), (0.09, 0.03, 0.11), 0.02), "bronze")
    return sc, m, {}


def wisp():
    sc, m = Scene(), base_mats()
    m["fire"] = M.glow("#e8f4ff")
    sc.add(lambda p: smin(sphere(p, v3(0, 0, 0.75), 0.11), cone(p, v3(0, 0, 0.78), 0.09, 0.3), 0.05), "fire")
    return sc, m, {"glow": [(0, 0, 0.8, 56, "#7ab8ff", 0.9)], "shadow": 0.0}


def sinew():
    sc, m = Scene(), base_mats()
    m["flesh"] = M.plain("#8a3a34", 0.5, 0.08)
    for k, x in enumerate((-0.22, 0.02, 0.26)):
        def rope(p, x=x, k=k):
            wave = np.sin(p[:, 2] * (5.0 + k) + k) * 0.05
            return np.maximum(np.hypot(p[:, 0] - x - wave, p[:, 1] - 0.05 * k) - (0.045 + 0.015 * np.sin(p[:, 2] * 9.0 + k)), p[:, 2] - 2.35)
        sc.add(rope, "flesh")
    return sc, m, {}


def bell():
    sc, m = Scene(), base_mats()
    m["lamp"] = M.glow("#ffd9a0")
    for x in (-0.55, 0.55):
        sc.add(rough(lambda p, x=x: np.minimum(cap(p, v3(x, 0.1, 0), v3(x * 0.92, 0.1, 1.75), 0.07), cap(p, v3(x, 0.1, 0.9), v3(x * 0.45, 0.1, 1.72), 0.045)), 0.02, 0.2), "wood")
    sc.add(rough(lambda p: np.minimum(box(p, v3(0, 0.1, 1.78), (0.72, 0.08, 0.07), 0.02), box(p, v3(0, 0.1, 0.06), (0.7, 0.2, 0.06), 0.02)), 0.02), "wood")
    bell_d = lambda p: sub(smin(cone(p, v3(0, 0.1, 0.92), 0.36, 0.95), cyl(p, v3(0, 0.1, 0.9), 0.36, 0.1, 0.04), 0.06), cone(p, v3(0, 0.1, 0.8), 0.3, 0.8))
    sc.add(lambda p: np.minimum(np.maximum(bell_d(p), p[:, 2] - 1.62), cap(p, v3(0, 0.1, 1.55), v3(0, 0.1, 1.74), 0.04)), "bronze")
    sc.add(lambda p: np.minimum(sphere(p, v3(0, 0.1, 0.86), 0.07), cap(p, v3(0, 0.1, 0.9), v3(0, 0.1, 1.3), 0.02)), "iron")
    sc.add(lambda p: np.minimum(cap(p, v3(-0.62, -0.02, 1.74), v3(-0.62, -0.02, 1.5), 0.012), box(p, v3(-0.62, -0.02, 1.52), (0.07, 0.07, 0.015))), "iron")
    sc.add(lambda p: box(p, v3(-0.62, -0.02, 1.42), (0.055, 0.055, 0.09), 0.02), "lamp")
    return sc, m, {"glow": [(-0.62, -0.02, 1.42, 40, "#ff9a4a", 0.7)]}


def gate():
    sc, m = Scene(), base_mats()
    pickets(sc, -0.5, 0.5, 6, 1.9, 0.0, 0.034, 0.18, (0.12, 0.5, 0.88))
    sc.add(lambda p: box(p, v3(0, -0.05, 1.0), (0.14, 0.03, 0.16), 0.02), "bronze")
    return sc, m, {}


BIG = {"mausoleum": mausoleum, "angel": angel, "tower": tower, "tree": dead_tree, "knight": knight}
STAND = {"f2d_fence": fence, "f2d_lantern": lantern, "f2d_bush": bush, "f2d_dig": dig, "f2d_epitaph": epitaph, "f2d_tomb_door": tomb_door,
    "f2d_wisp": wisp, "f2d_sinew": sinew, "f2d_bell": bell, "f2d_gate": gate}
