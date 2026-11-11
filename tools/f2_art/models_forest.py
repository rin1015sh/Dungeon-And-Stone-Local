"""고블린 숲 소품 · 큰 구조물 · 나무 빚기(tools/f2_art/props.py가 부른다). 한 함수 = 한 그림 → (Scene, 재질 표, 덧붙임).
좌표는 칸 단위(sdf.py), 원점 = 발 칸 가운데. 나무 부품 = trees.py, 공통 부품 = models_dead(rough · rot · rubble)."""
import numpy as np

import mats as M
import sdf
import trees as T
from models_dead import rot_y, rot_z, rough, rubble
from sdf import Scene, box, cap, cone, cyl, ell, gable, smin, sphere, sub, v3

F = np.float32
MOSS = "#4c5e30"


def base_mats():
    return {"bark": M.bark("#4a3c2e", MOSS), "bark_d": M.bark("#3a3026", MOSS, 5), "pale": M.bark("#b4b0a0", MOSS, 7, True),
        "leaf": M.leaf("#3e6a2c"), "leaf_d": M.leaf("#2c4e2a", 0.3, 9, 0.06), "needle": M.leaf("#274a2c", 0.22, 11, 0.05), "leaf_y": M.leaf("#6a7a30", 0.28, 13, 0.14),
        "wood": M.wood("#5a442e"), "wood_d": M.wood("#40301f", 0.16, 2, 6), "plank": M.wood("#5e4a32", 0.22, 0, 7), "thatch": M.thatch("#7a6a3c"),
        "hide": M.hide("#6e5a40"), "stone": M.stone("#7a7a72", MOSS), "bone": M.plain("#d0c8b0", 0.2), "rope": M.plain("#8a744a", 0.3, 0.05),
        "void": M.void(), "rings": M.rings("#a08a5c", "#4a3c2e"), "wattle": M.wood("#5a4a34", 0.1, 0, 8), "cloth": M.plain("#6a3028", 0.3)}


def tree(seed, h, r, kind="oak", leaf="leaf", bark="bark", scale=1.0, crown=(1.9, 1.3), clump=(0.55, 0.85), n=16, y0=0.25, roots=5, cell_w=8.0):
    """활엽수: 곧게 선 줄기 · 갈라지는 가지 + 잎 무더기 여럿이 이룬 둥근 수관(crown = 반폭 · 반높이, clump = 덩이 반지름)."""
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(seed)
    base = v3(0, y0, 0)
    xmax = cell_w * 0.5 / scale - clump[1] * 1.25 - 0.25   # 수관이 그림 칸 밖으로 나가지 않게
    segs, tips = T.limbs(rng, base, h, r, 4, 0.42, 0.42 if kind != "birch" else 0.52, 0.5, xmax)
    segs += T.roots(rng, base, r, roots)
    sc.add(T.trunk_fn(segs, seed), bark)
    tw = T.twig_fn(segs)
    if tw is not None:
        sc.add(tw, bark)
    if kind != "dead":
        tp = np.array(tips)
        mid = tp.mean(0) + v3(0, 0, crown[1] * 0.15)
        size = np.maximum(np.array([crown[0], crown[0] * 0.7, crown[1]], F), np.abs(tp - mid).max(0) * 0.85)
        size[0] = min(size[0], xmax - abs(float(mid[0])))
        cs = [t + v3(0, 0, clump[0] * 0.2) for t in tips]   # 가지 끝마다 잎 덩이 + 수관 속을 채우는 덩이
        while len(cs) < n + len(tips) // 2:
            q = rng.normal(0, 0.5, 3).astype(F)
            cs.append(mid + q / max(1.0, float(np.sqrt((q * q).sum()))) * size)
        cs.sort(key=lambda c: c[2] - c[1] * 0.3)
        half = len(cs) * 2 // 5
        sc.add(T.crown_fn(rng, cs[:half], clump[0], clump[1], seed + 3), leaf + "_d" if leaf == "leaf" else leaf)   # 아래 · 뒤쪽은 어두운 잎
        sc.add(T.crown_fn(rng, cs[half:], clump[0], clump[1], seed), leaf)
    return sc, m, {"scale": scale, "far": 9.0}


def pine(seed, h, r, scale=1.0, y0=0.25, bare=0.3, spread=0.0):
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(seed)
    base = v3(0, y0, 0)
    segs = [(base, base + v3(rng.uniform(-0.05, 0.05), 0, h), r, r * 0.12)] + T.roots(rng, base, r, 5, 2.0)
    sc.add(T.trunk_fn(segs, seed, 0.08, 0.04), "bark_d")
    n = int(h * 1.5)
    sc.add(T.tiers_fn(base, h * bare, h * 1.02, spread if spread > 0.0 else r * 5.5 + 0.6, n, seed), "needle")
    return sc, m, {"scale": scale, "far": 9.0}


def hut():
    """고블린 움막: 엮은 흙벽 + 덥수룩한 짚 지붕 + 뚫린 문 + 꼭대기 해골 · 삐져나온 장대."""
    sc, m = Scene(), base_mats()
    c = v3(0, 1.0, 0)
    wall = lambda p: sub(cyl(p, c, 1.45, 1.25, 0.05), np.minimum(box(p, v3(0, -0.4, 0.5), (0.36, 0.7, 0.5)), sdf.length((p - v3(0, 0, 1.0))[:, [0, 2]]) - 0.36 + (np.abs(p[:, 1] + 0.4) > 0.7) * 9.0))
    sc.add(rough(wall, 0.06, 0.2, 3), "wattle")
    sc.add(lambda p: cyl(p, c, 1.25, 1.2), "void")
    roof = lambda p: sub(cone(p, v3(0, 1.0, 1.18), 1.85, 2.2), cone(p, v3(0, 1.0, 0.9), 1.75, 2.2))
    shaggy = lambda p: (sdf.fbm(p * np.array([1, 1, 0.5], F), 0.12, 5, 2) - 0.5) * 0.14 + np.sin(np.arctan2(p[:, 1] - 1.0, p[:, 0]) * 17.0) * 0.03 * np.clip(2.6 - p[:, 2], 0, 1)
    sc.add(lambda p: roof(p) * 0.8 + shaggy(p), "thatch")
    for a in (0.4, 2.2, 4.0, 5.4):   # 삐져나온 장대
        tip = v3(np.cos(a) * 0.32, 1.0 + np.sin(a) * 0.3, 3.75)
        sc.add(lambda p, tip=tip: cap(p, v3(0, 1.0, 3.15), tip, 0.045, 0.03), "wood_d")
    sc.add(lambda p: np.minimum(ell(p, v3(0, 0.82, 3.42), (0.17, 0.15, 0.19)), box(p, v3(0, 0.76, 3.25), (0.09, 0.07, 0.07), 0.02)), "bone")
    for x in (-0.48, 0.48):   # 문설주
        sc.add(rough(lambda p, x=x: cap(p, v3(x, -0.47, 0), v3(x * 0.9, -0.47, 1.25), 0.07), 0.02, 0.2), "wood_d")
    sc.add(rough(lambda p: cap(p, v3(-0.55, -0.47, 1.22), v3(0.55, -0.47, 1.26), 0.065), 0.02, 0.2), "wood_d")
    return sc, m, {"scale": 1.45}


def tent():
    """가죽 천막: 기운 가죽을 두른 원뿔 + 꼭대기로 삐져나온 장대 + 젖힌 입구."""
    sc, m = Scene(), base_mats()
    c = v3(0, 0.85, 0)
    body = lambda p: cone(p, c, 1.35, 2.7)
    door = lambda p: np.maximum(np.maximum(np.abs(p[:, 0]) * 2.2 + p[:, 2] * 0.55 - 0.75, -p[:, 1] - 0.9), p[:, 1] - 0.2)
    sag = lambda p: np.sin(np.arctan2(p[:, 1] - 0.85, p[:, 0]) * 7.0) * 0.045 * np.clip(p[:, 2] / 1.5, 0, 1) * np.clip(2.5 - p[:, 2], 0, 1)
    sc.add(lambda p: sub(sub(body(p), cone(p, v3(0, 0.85, -0.15), 1.3, 2.7)), door(p)) * 0.8 + sag(p), "hide")
    sc.add(lambda p: cone(p, v3(0, 0.85, 0), 1.2, 2.4), "void")
    for k, a in enumerate((0.3, 1.9, 3.3, 4.9)):
        tip = v3(np.cos(a) * 0.4, 0.85 + np.sin(a) * 0.35, 3.25 + 0.1 * k)
        sc.add(lambda p, tip=tip, a=a: cap(p, v3(-np.cos(a) * 0.12, 0.85 - np.sin(a) * 0.12, 2.3), tip, 0.04, 0.025), "wood_d")
    sc.add(lambda p: cap(p, v3(-0.08, 0.85, 2.52), v3(0.1, 0.85, 2.5), 0.07), "rope")
    return sc, m, {"scale": 1.5}


def watch():
    """망대: 벌어진 통나무 다리 넷 + 가새 + 판자 마루 · 난간 + 사다리 + 짚 차양."""
    sc, m = Scene(), base_mats()
    zc, yc = 3.3, 0.7
    for sx in (-1, 1):
        for sy in (-1, 1):
            a, b = v3(sx * 1.05, yc + sy * 0.7, 0), v3(sx * 0.78, yc + sy * 0.5, zc + 1.0)
            sc.add(rough(lambda p, a=a, b=b: cap(p, a, b, 0.09, 0.07), 0.025, 0.25), "wood_d")
    for sx in (-1, 1):   # 가새
        sc.add(lambda p, sx=sx: cap(p, v3(sx * 1.0, yc - 0.66, 0.5), v3(-sx * 0.86, yc - 0.56, 2.7), 0.045), "wood")
    sc.add(lambda p: cap(p, v3(-0.95, yc - 0.62, 1.6), v3(0.95, yc - 0.62, 1.6), 0.045), "wood")
    sc.add(rough(lambda p: box(p, v3(0, yc, zc), (1.15, 0.85, 0.07), 0.02), 0.02), "plank")
    for sx in (-1, 1):   # 난간
        sc.add(lambda p, sx=sx: cap(p, v3(sx * 1.1, yc - 0.8, zc + 0.5), v3(sx * 1.1, yc + 0.8, zc + 0.5), 0.04), "wood")
    sc.add(lambda p: np.minimum(cap(p, v3(-1.1, yc - 0.8, zc + 0.5), v3(1.1, yc - 0.8, zc + 0.5), 0.04), cap(p, v3(-1.1, yc + 0.8, zc + 0.5), v3(1.1, yc + 0.8, zc + 0.5), 0.04)), "wood")
    for x in (-0.55, 0.0, 0.55):
        sc.add(lambda p, x=x: cap(p, v3(x, yc - 0.8, zc), v3(x, yc - 0.8, zc + 0.5), 0.03), "wood")
    sc.add(lambda p: gable(p, v3(0, yc, zc + 1.0), 1.25, 1.0, 0.75, 0) * 0.85 + (sdf.fbm(p, 0.12, 4, 2) - 0.5) * 0.1, "thatch")
    for x in (0.25, 0.6):   # 사다리
        sc.add(lambda p, x=x: cap(p, v3(x, yc - 1.25, 0), v3(x, yc - 0.86, zc), 0.035), "wood")
    for k in range(7):
        t = (k + 0.7) / 7.6
        sc.add(lambda p, t=t: cap(p, v3(0.25, yc - 1.25 + 0.39 * t, zc * t), v3(0.6, yc - 1.25 + 0.39 * t, zc * t), 0.025), "wood")
    return sc, m, {"scale": 1.35}


# ── 서 있는 소품(2 × 3칸) ──
def small_tree():
    return tree(21, 1.4, 0.09, "oak", "leaf", "bark", 1.0, (0.6, 0.4), (0.2, 0.3), 9, 0.1, 4, 2.0)


def bush():
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(5)
    cs = [v3(rng.uniform(-0.3, 0.3), rng.uniform(-0.1, 0.25), rng.uniform(0.2, 0.45)) for _ in range(7)]
    sc.add(T.crown_fn(rng, cs, 0.2, 0.3, 5, 0.16), "leaf")
    return sc, m, {}


def stump():
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(6)
    body = lambda p: np.maximum(cyl(p, v3(0, 0.05, 0), 0.3, 0.45, 0.02) + (sdf.fbm(p * np.array([1, 1, 0.2], F), 0.1, 6, 2) - 0.5) * 0.07, p[:, 2] - 0.4 - p[:, 0] * 0.08)
    sc.add(body, "rings")
    sc.add(T._union(T.roots(rng, v3(0, 0.05, 0), 0.26, 5, 2.0), 0.05), "bark")
    return sc, m, {}


def log():
    sc, m = Scene(), base_mats()
    a, b = v3(-0.62, 0.12, 0.17), v3(0.62, -0.02, 0.17)
    ax = (b - a) / np.sqrt(((b - a) ** 2).sum())
    sc.add(lambda p: np.maximum(cap(p, a, b, 0.18, 0.16) + (sdf.fbm(p * np.array([0.25, 1, 1], F), 0.09, 7, 2) - 0.5) * 0.05, np.abs((p - (a + b) * 0.5) @ ax) - 0.62), "bark")
    sc.add(lambda p: np.maximum(sdf.length(p - b) - 0.165, np.abs((p - b) @ ax) - 0.012), "bone")
    sc.add(lambda p: cap(p, v3(-0.2, 0.1, 0.3), v3(-0.3, 0.02, 0.52), 0.035, 0.02), "bark")
    return sc, m, {}


def mush():
    sc, m = Scene(), base_mats()
    m["cap"] = M.plain("#b8c4cc", 0.25, 0.05)
    m["stem"] = M.plain("#d8d8cc", 0.15)
    for x, y, h, r in ((-0.12, 0.05, 0.34, 0.15), (0.14, 0.0, 0.25, 0.11), (0.02, -0.14, 0.16, 0.08), (0.26, 0.14, 0.14, 0.07)):
        sc.add(lambda p, x=x, y=y, h=h: cap(p, v3(x, y, 0), v3(x, y, h), 0.028, 0.022), "stem")
        sc.add(lambda p, x=x, y=y, h=h, r=r: np.maximum(ell(p, v3(x, y, h), (r, r, r * 0.75)), h - 0.01 - p[:, 2]), "cap")
    return sc, m, {"glow": [(0.0, 0.0, 0.25, 30, "#b8d0e8", 0.22)]}


def totem():
    sc, m = Scene(), base_mats()
    sc.add(rough(lambda p: cap(p, v3(0, 0, 0), v3(0.03, 0, 1.75), 0.07, 0.05), 0.02, 0.2), "wood_d")
    sc.add(lambda p: cap(p, v3(-0.42, 0, 1.25), v3(0.42, 0, 1.3), 0.04), "wood_d")
    skull = lambda p: smin(ell(p, v3(0.02, -0.06, 1.72), (0.17, 0.15, 0.18)), ell(p, v3(0.02, -0.14, 1.56), (0.09, 0.1, 0.12)), 0.05)
    eyes = lambda p: np.minimum(sphere(p, v3(-0.06, -0.19, 1.73), 0.045), sphere(p, v3(0.1, -0.19, 1.73), 0.045))
    sc.add(lambda p: sub(skull(p), eyes(p)), "bone")
    for sx in (-1, 1):   # 뿔
        sc.add(lambda p, sx=sx: smin(cap(p, v3(0.02 + sx * 0.12, -0.04, 1.85), v3(0.02 + sx * 0.34, -0.02, 2.0), 0.045, 0.03), cap(p, v3(0.02 + sx * 0.34, -0.02, 2.0), v3(0.02 + sx * 0.4, -0.02, 2.22), 0.03, 0.008), 0.03), "bone")
    for x, ln in ((-0.36, 0.42), (-0.2, 0.3), (0.26, 0.36), (0.38, 0.5)):   # 늘어뜨린 천 조각
        sc.add(lambda p, x=x, ln=ln: box(p, v3(x, -0.02, 1.25 - ln / 2), (0.035, 0.012, ln / 2), 0.01) + np.sin(p[:, 2] * 20.0) * 0.006, "cloth")
    sc.add(lambda p: cyl(p, v3(0.01, 0, 1.2), 0.085, 0.12, 0.02), "rope")
    return sc, m, {}


def _stele(lit):
    sc, m = Scene(), base_mats()
    m["rune"] = M.glow("#d8e8ff") if lit else M.plain("#2e2e2c", 0.1)
    slab = lambda p: np.maximum(box(p, v3(0, 0.08, 0.85), (0.34, 0.15, 0.85), 0.06), p[:, 2] - 1.62 + p[:, 0] * 0.35)
    crack = (lambda p: np.abs(p[:, 0] - 0.1 - np.sin(p[:, 2] * 9.0) * 0.04) - 0.012) if not lit else None
    body = rough(slab, 0.07, 0.3, 8)
    sc.add(body if lit else (lambda p: sub(body(p), np.maximum(crack(p), 0.9 - p[:, 2]))), "stone")
    ring = lambda p: np.maximum(np.abs(sdf.length((p - v3(0, 0, 1.0))[:, [0, 2]]) - 0.17) - 0.022, np.abs(p[:, 1] + 0.07) - 0.035)
    bar = lambda p: box(p, v3(0, -0.07, 1.0), (0.018, 0.035, 0.27))
    sc.add(lambda p: np.minimum(ring(p), bar(p)), "rune")
    return sc, m, ({"glow": [(0, -0.07, 1.0, 44, "#9ec0ff", 0.7)]} if lit else {})


def stele():
    return _stele(True)


def stele_dead():
    return _stele(False)


def stakes():
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(9)
    for k in range(5):
        x = -0.4 + k * 0.2
        h = rng.uniform(1.05, 1.45)
        lean = rng.uniform(-0.06, 0.06)
        sc.add(rough(lambda p, x=x, h=h, lean=lean: np.minimum(cap(p, v3(x, 0, 0), v3(x + lean, 0, h), 0.075, 0.065), cone(p, v3(x + lean, 0, h - 0.02), 0.07, 0.24)), 0.02, 0.15, k), "wood_d")
    for z in (0.45, 0.95):
        sc.add(lambda p, z=z: cap(p, v3(-0.5, -0.07, z), v3(0.5, -0.07, z + 0.03), 0.028), "rope")
    return sc, m, {}


BIG = {"bigtree": lambda: tree(31, 6.6, 0.8, "oak", "leaf", "bark", 1.2, (2.2, 1.7), (0.7, 1.0), 22, 0.5, 6), "hut": hut, "tent": tent, "watch": watch,
    "oak": lambda: tree(41, 5.0, 0.36, "oak", "leaf", "bark", 1.2, (2.0, 1.35), (0.55, 0.85), 16),
    "pine": lambda: pine(42, 7.2, 0.27, 1.2),
    "birch": lambda: tree(43, 5.6, 0.2, "birch", "leaf_y", "pale", 1.02, (1.3, 1.5), (0.4, 0.6), 14),
    "dead": lambda: tree(44, 4.4, 0.26, "dead", "leaf", "bark_d", 1.2),
    "giant_oak": lambda: tree(45, 10.6, 0.85, "oak", "leaf", "bark", 1.15, (2.2, 1.6), (0.7, 1.0), 24, 0.4, 6),
    "giant_pine": lambda: pine(46, 14.0, 0.62, 1.1, 0.4, 0.55, 2.2),
    "giant_pale": lambda: tree(47, 10.6, 0.8, "oak", "leaf_y", "pale", 1.15, (2.2, 1.6), (0.7, 1.0), 22, 0.4, 7)}
STAND = {"f2g_tree": small_tree, "f2g_bush": bush, "f2g_stump": stump, "f2g_log": log, "f2g_mush": mush, "f2g_totem": totem,
    "f2g_stele": stele, "f2g_stele_dead": stele_dead, "f2g_stakes": stakes}
