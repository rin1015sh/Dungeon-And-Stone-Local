"""자연물: 바위 · 잔해 · 이끼 · 덩굴 · 뿌리 · 잡초 · 버섯 · 독버섯 · 종유석 · 석순 · 웅덩이."""
import numpy as np

import mats as M
import sdf
from kit import (F, box, cap, chip, cone, cut_above, cyl, ell, flat, hcyl, pool, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep

CAVE, CAVE_D = "#6c6c68", "#4c4e50"


# ── 덩어리 도우미 ─────────────────────────────────────────────────────────────

def _rock(c, r, seed, facets=6, bump=0.035):
    """모난 바위: 둥근 덩이를 여러 면으로 깎는다. c = 가운데, r = 반지름 (3)."""
    c, r = np.asarray(c, F), np.asarray(r, F)
    rng = np.random.default_rng(seed)
    cuts = []
    for _ in range(facets):
        n = rng.normal(size=3)
        n[2] = abs(n[2]) * 0.7 + 0.15
        cuts.append(((n / np.linalg.norm(n)).astype(F), rng.uniform(0.58, 0.88)))
    rmin = float(r.min())

    def fn(p):
        d = ell(p, c, r)
        q = (p - c) / r
        for n, k in cuts:
            d = np.maximum(d, (q @ n - k) * rmin)
        return d + (sdf.fbm(p, 0.13, seed, 2) - 0.5) * bump
    return fn


def _cave(k, seed, moss=False):
    k.mat("cave", M.stone(CAVE, "#4a5236" if moss else None, seed))
    k.mat("cave_d", M.stone(CAVE_D, "#4a5236" if moss else None, seed + 3))


def _spike(base, tip, r0, seed, rings=26.0):
    """석순 · 종유석 한 가닥: 굵은 밑에서 뾰족한 끝으로, 마디가 진다."""
    base, tip = np.asarray(base, F), np.asarray(tip, F)
    return lambda p: cap(p, base, tip, r0, r0 * 0.06) + np.sin(p[:, 2] * rings + sdf.noise(p, 0.2, seed) * 4.0) * r0 * 0.07 + (sdf.fbm(p, 0.1, seed, 2) - 0.5) * r0 * 0.25


def _stem(k, pts, r0, r1, mat, seed=1, wob=0.012):
    """굽이치는 줄기 · 뿌리: 점들을 굵기가 줄어드는 막대로 잇는다."""
    n = len(pts) - 1
    for i in range(n):
        a, b = v3(*pts[i]), v3(*pts[i + 1])
        ra, rb = r0 + (r1 - r0) * i / n, r0 + (r1 - r0) * (i + 1) / n
        k.add(rough(lambda p, a=a, b=b, ra=ra, rb=rb: cap(p, a, b, ra, rb), wob, 0.08, seed + i), mat)


# ── 바위 · 잔해 ──────────────────────────────────────────────────────────────

@prop("rock", "nature", cell=(3, 3), tags=["stone", "cave"], name_ko="바위",
    variants={"small_a": {"size": "s", "seed": 3}, "small_b": {"size": "s", "seed": 11}, "medium_a": {"size": "m", "seed": 5}, "medium_b": {"size": "m", "seed": 17},
        "large_a": {"size": "l", "seed": 7}, "large_b": {"size": "l", "seed": 23}, "slab_a": {"size": "slab", "seed": 9}, "slab_b": {"size": "slab", "seed": 29}, "mossy": {"size": "l", "seed": 13, "moss": True}})
def rock(k, size="m", moss=False, seed=1):
    _cave(k, seed, moss)
    r = k.rng
    if size == "s":
        k.add(_rock((0, 0, 0.07), (0.15, 0.12, 0.11), seed), "cave")
        k.add(_rock((0.2, -0.08, 0.035), (0.075, 0.06, 0.055), seed + 1, 4, 0.02), "cave_d")
    elif size == "m":
        k.add(_rock((0, 0, 0.14), (0.3, 0.23, 0.22), seed), "cave")
        k.add(_rock((0.32, -0.12, 0.06), (0.13, 0.11, 0.1), seed + 1, 5, 0.025), "cave_d")
        k.rubble([(-0.34, -0.14), (0.12, -0.26)], "cave_d", 0.035, 0.06)
    elif size == "l":
        k.add(_rock((0, 0.05, 0.3), (0.52, 0.36, 0.44), seed, 7, 0.05), "cave")
        k.add(_rock((0.46, -0.12, 0.14), (0.26, 0.22, 0.22), seed + 1, 6), "cave_d")
        k.add(_rock((-0.5, -0.14, 0.08), (0.16, 0.14, 0.13), seed + 2, 5, 0.025), "cave")
        k.rubble([(0.1, -0.4), (-0.25, -0.36), (0.7, -0.3)], "cave_d", 0.035, 0.07)
    else:   # slab: 넓적한 판바위
        k.add(_rock((0, 0, 0.07), (0.56, 0.36, 0.13), seed, 5, 0.03), "cave")
        k.add(_rock((0.12, 0.06, 0.2), (0.34, 0.24, 0.08), seed + 1, 4, 0.02), "cave_d")
        k.rubble([(-0.6, -0.2), (0.55, -0.3)], "cave_d", 0.035, 0.06)
    return {}


for _id, _col in (("rock", {"s": (0.34, 0.26), "m": (0.6, 0.44), "l": (1.0, 0.6), "slab": (1.0, 0.6)}),):
    pass   # 충돌은 변형마다 크기가 달라 kit.json에 넣지 않는다 — 큰 바위는 놓는 쪽에서 막는다(docs)


@prop("rubble", "nature", cell=(3, 3), tags=["stone", "ruin"], name_ko="돌무더기",
    variants={"small": {"seed": 4}, "small_b": {"seed": 14}, "large": {"size": "l", "seed": 6}, "large_b": {"size": "l", "seed": 21}, "scatter": {"size": "scatter", "seed": 8}, "brick": {"size": "brick", "seed": 10}, "brick_large": {"size": "brick_l", "seed": 15}})
def rubble(k, size="s", seed=1):
    r = k.rng
    if size in ("brick", "brick_l"):   # 무너진 벽돌 더미
        n, sp = (9, 0.3) if size == "brick" else (22, 0.5)
        k.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, 0), (sp * 1.1, sp * 0.8, sp * 0.45)), -p[:, 2]), 0.06, 0.1, seed), "dirt")
        for i in range(n):
            x, y = r.uniform(-sp, sp), r.uniform(-sp * 0.7, sp * 0.7)
            z = max(0.035, (sp - np.hypot(x, y * 1.3)) * 0.75) + 0.02
            a, t = r.uniform(0, 3.14), r.uniform(-0.5, 0.5)
            k.add(rough(lambda p, x=x, y=y, z=z, a=a, t=t: box(rot_y(rot_z(p, a, (x, y, z)), t, (x, y, z)), v3(x, y, z), (0.1, 0.055, 0.04), 0.008), 0.012, 0.05, seed + i), "brick" if i % 3 else "stone_d")
        return {}
    if size == "scatter":   # 흩어진 잔돌
        for i, (x, y) in enumerate(k.scatter(11, 0.8, 0.5)):
            s = r.uniform(0.04, 0.11)
            k.add(_rock((x, y, s * 0.5), (s * 1.2, s, s * 0.8), seed + i, 4, 0.02), ("stone", "stone_d")[i % 2])
        return {"shadow": 0.35}
    big = size == "l"
    sp = 0.55 if big else 0.3
    k.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, 0), (sp * 1.15, sp * 0.8, sp * 0.5)), -p[:, 2]), 0.05, 0.1, seed), "dirt")
    for i in range(16 if big else 8):
        x, y = r.uniform(-sp, sp), r.uniform(-sp * 0.65, sp * 0.65)
        s = r.uniform(0.09, 0.2 if big else 0.14)
        z = max(0.0, (sp - np.hypot(x, y * 1.3)) * 0.7) + s * 0.4
        k.add(_rock((x, y, z), (s * 1.2, s, s * 0.85), seed + i, 5, 0.03), ("stone", "stone_d", "stone_l")[i % 3])
    k.rubble(k.scatter(6, sp * 1.7, sp * 1.1, 0, 0, sp * 0.9), "stone_d", 0.03, 0.06)
    return {}


@prop("boulder_mossy", "nature", cell=(4, 4), collide=(1.3, 0.8), tags=["stone", "cave", "moss"], name_ko="이끼 낀 큰 바위", variants={"a": {"seed": 5}, "b": {"seed": 19}})
def boulder_mossy(k, seed=1):
    _cave(k, seed, True)
    k.add(_rock((0, 0.1, 0.5), (0.72, 0.5, 0.75), seed, 8, 0.07), "cave")
    k.add(_rock((0.62, -0.1, 0.24), (0.36, 0.3, 0.36), seed + 1, 6, 0.05), "cave_d")
    k.add(_rock((-0.62, -0.08, 0.15), (0.28, 0.22, 0.24), seed + 2, 6, 0.04), "cave")
    cap_ = _rock((0, 0.1, 0.5), (0.74, 0.52, 0.77), seed, 8, 0.07)
    k.add(lambda p: np.maximum(cap_(p), 0.72 - p[:, 2] + (sdf.fbm(p, 0.25, seed, 3) - 0.5) * 0.7), "moss")   # 위를 덮은 이끼
    k.rubble([(0.2, -0.5), (-0.3, -0.45), (1.0, -0.35)], "cave_d", 0.04, 0.08)
    return {}


# ── 석순 · 종유석 ────────────────────────────────────────────────────────────

@prop("stalagmite", "nature", cell=(3, 4), tags=["cave", "stone"], name_ko="석순",
    variants={"small": {"seed": 3}, "tall": {"kind": "tall", "seed": 7}, "cluster": {"kind": "cluster", "seed": 11}, "cluster_b": {"kind": "cluster", "seed": 20}, "broken": {"kind": "broken", "seed": 15}})
def stalagmite(k, kind="small", seed=1):
    _cave(k, seed)
    foot = lambda r: (lambda p: np.maximum(ell(p, v3(0, 0, 0), (r, r * 0.8, r * 0.3)), -p[:, 2]) + (sdf.fbm(p, 0.1, seed, 2) - 0.5) * 0.04)
    if kind == "small":
        k.add(foot(0.2), "cave_d")
        k.add(_spike((0, 0, 0), (0.02, 0, 0.5), 0.12, seed), "cave")
        k.add(_spike((0.17, -0.06, 0), (0.19, -0.06, 0.24), 0.07, seed + 1), "cave_d")
    elif kind == "tall":
        k.add(foot(0.32), "cave_d")
        k.add(_spike((0, 0, 0), (0.04, 0, 1.5), 0.2, seed), "cave")
        k.add(_spike((-0.24, -0.08, 0), (-0.26, -0.08, 0.45), 0.09, seed + 1), "cave_d")
    elif kind == "cluster":
        r = k.rng
        k.add(foot(0.5), "cave_d")
        for i in range(6):
            x, y = r.uniform(-0.4, 0.4), r.uniform(-0.2, 0.2)
            h = r.uniform(0.3, 1.1) * (1.0 - abs(x) * 0.9)
            k.add(_spike((x, y, 0), (x + r.uniform(-0.05, 0.05), y, h), 0.07 + h * 0.09, seed + i), ("cave", "cave_d")[i % 2])
    else:   # broken: 부러진 밑동 + 쓰러진 끝
        k.add(foot(0.32), "cave_d")
        k.add(cut_above(_spike((0, 0, 0), (0.04, 0, 1.5), 0.2, seed), 0.45, 0.14, 0.12, seed, 0.3), "cave")
        tip = _spike((0, 0, 0), (0, 0, 0.9), 0.13, seed + 2)
        k.add(lambda p: tip(rot_y(p - v3(0.3, -0.26, 0.1), -1.45)), "cave")
        k.rubble([(0.3, -0.42), (-0.3, -0.25), (0.95, -0.36)], "cave_d", 0.035, 0.07)
    return {}


for _v, _c in (("tall", (0.45, 0.4)),):
    pass


@prop("stalactite", "nature", layer="over", cell=(3, 5), tags=["cave", "stone"], name_ko="종유석",
    variants={"small": {"seed": 4}, "large": {"kind": "large", "seed": 9}, "cluster": {"kind": "cluster", "seed": 13}, "cluster_b": {"kind": "cluster", "seed": 22}, "dripping": {"kind": "drip", "seed": 17}})
def stalactite(k, kind="small", seed=1):
    """천장에서 드리운 종유석 — 원점은 그 아래 바닥, 뿌리는 z ≈ 3(화면 밖 천장)."""
    _cave(k, seed)
    top = 3.05
    extra = {"shadow": 0.0, "foot": 0.5}
    if kind == "small":
        k.add(_spike((0, 0, top), (0.01, 0, 2.2), 0.13, seed), "cave")
        k.add(_spike((0.16, 0, top), (0.17, 0, 2.6), 0.08, seed + 1), "cave_d")
    elif kind in ("large", "drip"):
        k.add(_spike((0, 0, top), (0.03, 0, 1.65), 0.24, seed), "cave")
        k.add(_spike((-0.27, 0, top), (-0.28, 0, 2.4), 0.11, seed + 1), "cave_d")
        k.add(_spike((0.25, 0.02, top), (0.25, 0.02, 2.55), 0.1, seed + 2), "cave_d")
        if kind == "drip":   # 끝에 맺힌 물방울 + 바닥에 고인 물
            k.add(lambda p: smin(sphere(p, v3(0.03, 0, 1.6), 0.028), cap(p, v3(0.03, 0, 1.6), v3(0.03, 0, 1.67), 0.012), 0.01), "glow_b")
            k.add(lambda p: pool(p, v3(0.03, 0, 0.004), 0.2, 0.15, 0.004) + (sdf.noise(p, 0.07, seed) - 0.5) * 0.06, k.mat("water", M.plain("#1a2630", 0.3, 0.1)))
            extra["glow"] = [(0.03, 0, 1.6, 9, "#a0c8e8", 0.5)]
    else:
        r = k.rng
        for i in range(7):
            x = -0.5 + i * 0.165 + r.uniform(-0.04, 0.04)
            ln = r.uniform(0.35, 1.25) * (1.0 - abs(x) * 0.7)
            k.add(_spike((x, r.uniform(-0.05, 0.05), top), (x + r.uniform(-0.03, 0.03), 0, top - ln), 0.07 + ln * 0.09, seed + i), ("cave", "cave_d")[i % 2])
    return extra


@prop("column_natural", "nature", cell=(3, 5), collide=(0.7, 0.55), tags=["cave", "stone"], name_ko="돌기둥(종유석과 석순이 이어진)", variants={"a": {"seed": 6}, "b": {"seed": 18}})
def column_natural(k, seed=1):
    _cave(k, seed)
    prof = lambda z: 0.13 + 0.2 * np.abs(z / 1.5 - 1.0) ** 1.6
    body = lambda p: np.maximum(np.hypot(p[:, 0], p[:, 1]) - prof(p[:, 2]), np.maximum(-p[:, 2], p[:, 2] - 3.05)) * 0.8
    k.add(lambda p: body(p) + np.sin(p[:, 2] * 22.0 + sdf.noise(p, 0.2, seed) * 5.0) * 0.012 + (sdf.fbm(p, 0.12, seed, 2) - 0.5) * 0.05 + np.cos(np.arctan2(p[:, 1], p[:, 0]) * 7.0) * 0.012, "cave")
    k.add(_spike((0.34, -0.08, 0), (0.36, -0.08, 0.5), 0.1, seed + 1), "cave_d")
    k.add(_spike((-0.32, 0.02, 0), (-0.34, 0.02, 0.32), 0.08, seed + 2), "cave_d")
    k.add(lambda p: np.maximum(ell(p, v3(0, 0, 0), (0.5, 0.36, 0.12)), -p[:, 2]) + (sdf.fbm(p, 0.1, seed, 2) - 0.5) * 0.04, "cave_d")
    return {"foot": 0.6}


# ── 풀 · 덤불 · 뿌리 ─────────────────────────────────────────────────────────

@prop("weeds", "nature", cell=(2, 2), tags=["plant"], name_ko="잡초",
    variants={"tuft_a": {"seed": 3}, "tuft_b": {"seed": 9}, "tuft_dry": {"seed": 14, "dry": True}, "fern": {"kind": "fern", "seed": 6}, "dead_bush": {"kind": "bush", "seed": 8}, "bramble": {"kind": "bramble", "seed": 12}, "sprouts": {"kind": "sprouts", "seed": 16}})
def weeds(k, kind="tuft", dry=False, seed=1):
    r = k.rng
    if kind == "tuft":
        k.mat("g1", M.plain("#6a6234" if dry else "#46562e", 0.4, 0.05, seed))
        k.mat("g2", M.plain("#8a7c44" if dry else "#5c6c38", 0.4, 0.05, seed + 1))
        for i in range(15):
            a = r.uniform(0, 6.28)
            lean, h = r.uniform(0.05, 0.3), r.uniform(0.18, 0.44)
            bx, by = np.cos(a) * 0.05, np.sin(a) * 0.04
            mid = v3(bx + np.cos(a) * lean * 0.4, by + np.sin(a) * lean * 0.3, h * 0.6)
            tip = v3(bx + np.cos(a) * lean, by + np.sin(a) * lean * 0.7, h)
            k.add(lambda p, bx=bx, by=by, mid=mid, tip=tip: smin(cap(p, v3(bx, by, 0), mid, 0.02, 0.016), cap(p, mid, tip, 0.016, 0.004), 0.01), ("g1", "g2")[i % 2])
    elif kind == "sprouts":   # 돌 틈에서 난 어린 싹 몇 포기
        k.mat("g1", M.plain("#4e6032", 0.4, 0.05, seed))
        for (x, y) in k.scatter(6, 0.45, 0.3):
            h = r.uniform(0.08, 0.18)
            for s in (-1, 1):
                k.add(lambda p, x=x, y=y, h=h, s=s: smin(cap(p, v3(x, y, 0), v3(x, y, h), 0.012), ell(p, v3(x + s * 0.04, y, h), (0.045, 0.025, 0.02)), 0.01), "g1")
    elif kind == "fern":
        k.mat("g1", M.plain("#3e5630", 0.4, 0.05, seed))
        k.mat("g2", M.plain("#546a38", 0.4, 0.05, seed + 1))
        for i in range(7):
            a = i * 0.9 + r.uniform(-0.2, 0.2)
            ln, h = r.uniform(0.3, 0.46), r.uniform(0.2, 0.36)
            ca, sa = np.cos(a), np.sin(a) * 0.7
            pts = [v3(ca * ln * t, sa * ln * t, np.sin(t * 2.2) * h) for t in (0.0, 0.35, 0.7, 1.0)]
            for j in range(3):
                k.add(lambda p, a_=pts[j], b_=pts[j + 1]: cap(p, a_, b_, 0.012), "g1")
                for t in (0.25, 0.75):   # 잔잎
                    c = pts[j] + (pts[j + 1] - pts[j]) * t
                    w = 0.075 * (1.0 - (j + t) / 3.4)
                    k.add(lambda p, c=c, w=w, ca=ca, sa=sa: cap(p, c + v3(-sa * w, ca * w, -0.01), c + v3(sa * w, -ca * w, -0.01), 0.017, 0.017), ("g2", "g1")[j % 2])
    elif kind == "bush":   # 말라 죽은 덤불
        def branch(a, b, r0, depth):
            k.add(lambda p, a=a, b=b, r0=r0: cap(p, a, b, r0, r0 * 0.6), "wood_d" if depth > 1 else "wood")
            if depth > 0:
                for _ in range(2 + (depth > 1)):
                    d = (b - a) * r.uniform(0.6, 0.8) + v3(r.uniform(-0.16, 0.16), r.uniform(-0.1, 0.1), r.uniform(0.0, 0.1))
                    branch(a + (b - a) * r.uniform(0.6, 1.0), b + d, r0 * 0.6, depth - 1)
        for a in (-0.5, 0.1, 0.6):
            branch(v3(0, 0, 0), v3(np.sin(a) * 0.16, r.uniform(-0.04, 0.04), 0.22), 0.03, 2)
    else:   # bramble: 가시덩굴
        k.mat("g1", M.plain("#3a3424", 0.4, 0.05, seed))
        for i in range(5):
            a = r.uniform(0, 3.14)
            x0, y0 = np.cos(a) * 0.4, np.sin(a) * 0.26 - 0.1
            x1, y1 = -x0 + r.uniform(-0.1, 0.1), -y0 * 0.6 + r.uniform(-0.1, 0.1)
            hh = r.uniform(0.18, 0.36)
            pts = [v3(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, np.sin(t * 3.14) * hh + 0.02) for t in np.linspace(0, 1, 6)]
            for j in range(5):
                k.add(lambda p, a_=pts[j], b_=pts[j + 1]: cap(p, a_, b_, 0.017), "g1")
                m = (pts[j] + pts[j + 1]) / 2
                k.add(lambda p, m=m, j=j: cap(p, m, m + v3(0.03 * (-1) ** j, 0.0, 0.055), 0.01, 0.002), "bone_d")
    return {"shadow": 0.35}


@prop("roots", "nature", cell=(4, 3), tags=["plant", "wood"], name_ko="바닥을 기는 뿌리", variants={"a": {"seed": 4}, "b": {"seed": 12}, "c": {"seed": 25}, "knot": {"kind": "knot", "seed": 9}})
def roots(k, kind="crawl", seed=1):
    r = k.rng
    k.mat("root", M.bark("#54422e", None, seed))
    k.mat("root_d", M.bark("#3e3024", None, seed + 2))
    if kind == "knot":   # 불거진 뿌리 옹이
        k.add(rough(lambda p: np.maximum(smin(ell(p, v3(0, 0, 0.05), (0.26, 0.2, 0.18)), ell(p, v3(0.2, -0.05, 0.02), (0.18, 0.14, 0.12)), 0.1), -p[:, 2]), 0.05, 0.08, seed), "root")
        n = 6
    else:
        n = 4
    for i in range(n):
        a = (i / n) * 6.28 + r.uniform(-0.3, 0.3) if kind == "knot" else r.uniform(-0.5, 0.5) + (3.14 if i % 2 else 0)
        x, y = (0.0, 0.0) if kind == "knot" else (r.uniform(-0.2, 0.2), r.uniform(-0.2, 0.2))
        pts, rad = [(x, y, 0.05)], r.uniform(0.05, 0.075)
        for j in range(5):
            a += r.uniform(-0.55, 0.55)
            x, y = x + np.cos(a) * 0.19, y + np.sin(a) * 0.13
            pts.append((x, y, 0.03 + 0.05 * abs(np.sin(j * 1.9 + i))))
        _stem(k, pts, rad, 0.012, ("root", "root_d")[i % 2], seed + i * 7)
        if i % 2 == 0:   # 곁뿌리
            bx, by, bz = pts[2]
            _stem(k, [pts[2], (bx + np.sin(a) * 0.14, by - np.cos(a) * 0.1, 0.02), (bx + np.sin(a) * 0.26, by - np.cos(a) * 0.2, 0.012)], rad * 0.45, 0.008, "root_d", seed + i)
    return {"shadow": 0.35}


# ── 버섯 ─────────────────────────────────────────────────────────────────────

def _shroom(k, x, y, h, R, stem_mat, cap_mat, lean=0.0, spots=0):
    top = v3(x + lean, y, h)
    k.add(lambda p: cap(p, v3(x, y, 0), top, R * 0.2 + 0.012, R * 0.16 + 0.008), stem_mat)
    k.add(lambda p: np.maximum(ell(p, top, (R, R, R * 0.7)), top[2] - 0.012 - p[:, 2]), cap_mat)
    for i in range(spots):
        a = i * 2.4 + x * 9
        d = R * (0.25 + 0.5 * ((i * 37) % 10) / 10.0)
        sx, sy = top[0] + np.cos(a) * d, top[1] + np.sin(a) * d
        sz = top[2] + R * 0.7 * np.sqrt(max(0.0, 1 - (d / R) ** 2))
        k.add(lambda p, sx=sx, sy=sy, sz=sz: sphere(p, v3(sx, sy, sz - R * 0.04), R * 0.14), "wax")


@prop("mushroom", "nature", cell=(2, 2), tags=["plant", "fungus"], name_ko="버섯",
    variants={"cluster_a": {"seed": 3}, "cluster_b": {"seed": 10}, "cluster_c": {"seed": 21}, "big": {"kind": "big", "seed": 5}, "pale": {"seed": 15, "cap": "pale"}})
def mushroom(k, kind="cluster", cap="brown", seed=1):
    r = k.rng
    k.mat("capm", M.plain({"brown": "#7a5a3c", "pale": "#b0a488"}[cap], 0.4, 0.06, seed))
    if kind == "big":
        _shroom(k, 0, 0, 0.36, 0.26, "shroom", "capm", 0.04)
        _shroom(k, 0.22, -0.08, 0.14, 0.1, "shroom", "capm")
        _shroom(k, -0.2, -0.05, 0.1, 0.075, "shroom", "capm")
    else:
        for (x, y) in k.scatter(int(r.integers(5, 8)), 0.3, 0.16):
            h = r.uniform(0.08, 0.26)
            _shroom(k, x, y, h, 0.05 + h * 0.3, "shroom", "capm", r.uniform(-0.04, 0.04))
    return {"shadow": 0.4}


@prop("mushroom_shelf", "nature", layer="wall_decal", cell=(2, 3), tags=["plant", "fungus"], name_ko="벽에 난 선반버섯", meta={"mount": "face"}, variants={"a": {"seed": 4}, "b": {"seed": 13}})
def mushroom_shelf(k, seed=1):
    r = k.rng
    k.mat("capm", M.plain("#8a6a44", 0.45, 0.05, seed))
    k.mat("under", M.plain("#c0b08c", 0.2, 0.05, seed))
    for i in range(int(r.integers(4, 7))):
        x, z, R = r.uniform(-0.3, 0.3), 0.75 + i * 0.16 + r.uniform(-0.04, 0.04), r.uniform(0.1, 0.19)
        k.add(lambda p, x=x, z=z, R=R: np.maximum(pool(p, v3(x, 0.02, z), R, R * 0.9, 0.022), p[:, 1] - 0.0) + (sdf.noise(p, 0.05, seed) - 0.5) * 0.02, "capm")
        k.add(lambda p, x=x, z=z, R=R: np.maximum(pool(p, v3(x, 0.02, z - 0.03), R * 0.9, R * 0.8, 0.012), p[:, 1] - 0.0), "under")
    return {"shadow": 0.0, "foot": 0.4}


@prop("toadstool", "nature", cell=(2, 2), tags=["plant", "fungus", "poison"], name_ko="독버섯",
    variants={"red_a": {"seed": 4}, "red_b": {"seed": 12}, "glow_a": {"kind": "glow", "seed": 7}, "glow_b": {"kind": "glow", "seed": 19}, "glow_violet": {"kind": "glow", "seed": 23, "col": "v"}},
    light={"color": "#70d0c0", "radius": 1.6, "at": (0, 0, 0.25), "flicker": 0.1, "variants": ["glow_a", "glow_b", "glow_violet"]})
def toadstool(k, kind="red", col="g", seed=1):
    import fx
    r = k.rng
    if kind == "red":
        k.mat("capm", M.plain("#8e2c26", 0.3, 0.06, seed))
        pts = [(0.0, 0.0, 0.3, 0.15), (0.2, -0.06, 0.16, 0.09), (-0.17, -0.04, 0.2, 0.1), (0.06, -0.16, 0.09, 0.06)]
        for i, (x, y, h, R) in enumerate(pts):
            _shroom(k, x + r.uniform(-0.03, 0.03), y, h, R, "wax", "capm", r.uniform(-0.03, 0.03), 6)
        return {"shadow": 0.4}
    base = {"g": ("#4fb8a0", "#70d0c0"), "v": ("#8a68d0", "#a888e8")}[col]
    c0 = M.hexc(base[0])

    def capm(p, n):
        t = 0.75 + sdf.noise(p, 0.05, seed) * 0.4
        return (c0[None, :] * t[:, None]).astype(F), np.zeros(len(p), F), np.full(len(p), 0.72, F)
    k.mat("capm", capm)
    k.mat("stemg", M.plain("#8aa89a" if col == "g" else "#9a90b8", 0.3, 0.05, seed))
    tops = []
    for (x, y) in k.scatter(int(r.integers(5, 8)), 0.32, 0.17):
        h = r.uniform(0.1, 0.34)
        R = 0.045 + h * 0.2
        _shroom(k, x, y, h, R, "stemg", "capm", r.uniform(-0.04, 0.04))
        tops.append((x, y, h))
    return {"shadow": 0.3, "post": [lambda img, vw: fx.sparkle(img, [vw.px(x, y, h + 0.12) for x, y, h in tops[:3]], "#e8fff4" if col == "g" else "#f0e4ff", 1.4)],
        "glow": [(x, y, h, 15, base[1], 0.35) for x, y, h in tops] + [(0, 0, 0.15, 46, base[1], 0.3)]}


# ── 평면: 이끼 · 웅덩이 · 금 · 자갈 ───────────────────────────────────────────

def _tone(c, col, lo=0.75, hi=1.2, scale=10.0):
    return hexc(col)[None, None, :] * (lo + c.noise(scale) * (hi - lo))[..., None]


def _dots(c, pts, soft=0.8):
    m = np.zeros((c.H, c.W), F)
    for x, y, r in pts:
        m = np.maximum(m, np.clip((r - np.hypot(c.xx - x, c.yy - y)) / soft + 0.5, 0, 1))
    return m


def _moss_paint(c, m, dry=False):
    """이끼 덩이: 어두운 밑 + 얼룩덜룩한 초록 + 밝은 솜털 점."""
    c.paint(gblur(m, 2.0) * 1.2, "#161a10", 0.5)
    c.paint(m, _tone(c, "#3e4a2a" if not dry else "#55502e", 0.7, 1.25, 7.0), 0.95)
    c.paint(m * sstep(c.noise(4.0) - 0.5, 0, 0.14), _tone(c, "#56663a" if not dry else "#6e6638", 0.85, 1.15, 3.0), 0.85)
    c.paint(m * sstep(c.noise(1.6, None, 2) - 0.62, 0, 0.06) * gblur(m, 2.0), "#7c8c50" if not dry else "#8e8450", 0.7)
    c.paint(c.rim(m, 1.2) * 0.8, "#1a2012", 0.6)


@flat("moss_patch", "nature", cell=(140, 120), tags=["moss", "plant"], name_ko="이끼", variants={"a": {"seed": 3}, "b": {"seed": 11}, "c": {"seed": 19}, "d": {"seed": 27, "sparse": True}, "dry": {"seed": 33, "dry": True}})
def moss_patch(c, sparse=False, dry=False, seed=1):
    r = c.rng
    base = c.blob(70, 60, 54, 42, 0.5, 34, 0.5, r.uniform(-0.5, 0.5))
    m = sstep(base * 0.9 + (c.noise(13.0) - 0.5) * (1.2 if sparse else 0.7) + (c.noise(4.0, None, 2) - 0.5) * 0.3, 0.42, 0.52)
    m = np.maximum(m, _dots(c, [(70 + r.uniform(-58, 58), 60 + r.uniform(-48, 48), s) for s in r.uniform(1.0, 3.4, 12)]))
    _moss_paint(c, m, dry)


@flat("wall_moss", "nature", layer="wall_decal", cell=(96, 160), tags=["moss", "plant"], name_ko="벽 이끼", variants={"base_a": {"seed": 5}, "base_b": {"seed": 14}, "top_a": {"seed": 22, "top": True}, "top_b": {"seed": 31, "top": True}, "patch": {"seed": 40, "patch": True}})
def wall_moss(c, top=False, patch=False, seed=1):
    c.origin = (48, 160)
    t = c.yy / 160.0
    side = sstep(1.0 - np.abs(c.xx - 48) / 48.0 + (c.noise(22.0) - 0.5) * 0.5, 0.0, 0.35)
    if patch:
        g = c.blob(48, 80, 34, 40, 0.5, 26, 0.5)
    elif top:
        g = np.clip(1.0 - t * 2.4, 0, 1) + (c.noise(8.0, None, 2) - 0.5) * 0.2 * (t < 0.6)
        g = g + sstep(c.noise(9.0, None, 2) * np.clip(1.2 - t * 1.6, 0, 1) - 0.42, 0, 0.1) * 0.5 * (np.abs(((c.xx + c.noise(30.0) * 30) % 17) - 8) < 3.5)   # 흘러내린 줄
    else:
        g = np.clip((t - 0.52) * 2.3, 0, 1)
    m = sstep(g * side + (c.noise(11.0) - 0.5) * 0.55, 0.3, 0.42)
    _moss_paint(c, m)


def _leaf(c, x, y, s, ang, col):
    m = c.blob(x, y, s, s * 0.52, 0.12, s, 0.25, ang)
    c.paint(gblur(m, 0.8) * 1.3, "#10140c", 0.7)
    c.paint(m, col, 1.0)
    ca, sa = np.cos(ang), np.sin(ang)
    c.paint(c.seg([(x - ca * s * 0.8, y - sa * s * 0.8), (x + ca * s * 0.8, y + sa * s * 0.8)], 0.9, False, 0.4), np.asarray(col) * 0.6, 0.8)


@flat("vines", "nature", layer="wall_decal", cell=(96, 160), tags=["plant"], name_ko="덩굴",
    variants={"hang_short": {"seed": 4, "ln": 0.4}, "hang_mid": {"seed": 11, "ln": 0.68}, "hang_long": {"seed": 18, "ln": 0.97}, "ivy_a": {"seed": 6, "kind": "ivy"}, "ivy_b": {"seed": 24, "kind": "ivy"}, "dead": {"seed": 30, "ln": 0.8, "dead": True}})
def vines(c, kind="hang", ln=0.7, dead=False, seed=1):
    r = c.rng
    c.origin = (48, 160)
    greens = [hexc(h) for h in (("#3a4c28", "#4a5e30", "#5c6e38") if not dead else ("#4a4030", "#5a4c34"))]
    stem_col = "#2e2a1c" if not dead else "#3a3024"
    stems = []
    for i in range(int(r.integers(4, 7))):
        if kind == "hang":
            x = 12 + r.uniform(0, 72)
            L = 160 * ln * r.uniform(0.45, 1.0)
            ph, amp = r.uniform(0, 6), r.uniform(2, 6)
            stems.append([(x + np.sin(t * 0.045 + ph) * amp, t) for t in np.linspace(0, L, 12)])
        else:   # ivy: 밑에서 타고 오르며 갈라진다
            x = 14 + r.uniform(0, 68)
            L = r.uniform(70, 150)
            ph, amp = r.uniform(0, 6), r.uniform(4, 12)
            stems.append([(x + np.sin(t * 0.04 + ph) * amp + (t / L) ** 2 * r.uniform(-18, 18), 160 - t) for t in np.linspace(0, L, 12)])
    for pts in stems:
        c.paint(c.seg(pts, 3.6, True, 0.7), "#10100c", 0.85)
        c.paint(c.seg(pts, 2.0, True, 0.6), stem_col, 1.0)
    for pts in stems:
        for j, (x, y) in enumerate(pts[1:]):
            if dead and r.random() < 0.6:
                continue
            for _ in range(2 if kind == "ivy" else 1):
                s = r.uniform(3.5, 6.0) * (1.0 - j / 18.0)
                side = r.choice([-1, 1])
                a = (1.57 + side * r.uniform(0.5, 1.2)) if kind == "hang" else (-1.57 + side * r.uniform(0.6, 1.5))
                _leaf(c, x + np.cos(a) * s * 0.9, y + np.sin(a) * s * 0.9, s, a, greens[int(r.integers(len(greens)))] * r.uniform(0.85, 1.15))


@flat("wall_roots", "nature", layer="wall_decal", cell=(128, 160), tags=["plant", "ruin"], name_ko="벽을 뚫고 나온 뿌리", variants={"a": {"seed": 5}, "b": {"seed": 16}, "c": {"seed": 28}})
def wall_roots(c, seed=1):
    r = c.rng
    c.origin = (64, 160)
    bx, by = 64 + r.uniform(-10, 10), r.uniform(48, 70)
    # 뚫린 자리: 검은 구멍 + 뻗어 나간 금 + 밀려난 돌
    hole = c.blob(bx, by, r.uniform(15, 20), r.uniform(11, 15), 0.5, 10, 0.1)
    cr = c.cracks([(bx, by, a, r.uniform(26, 54)) for a in (r.uniform(-0.5, 0.3), r.uniform(2.6, 3.6), r.uniform(-2.2, -1.0), r.uniform(0.9, 1.6), r.uniform(1.9, 2.5))], 2.6)
    c.paint(np.roll(cr, (1, 1), (0, 1)) * (1 - cr), "#9a9486", 0.35)
    c.paint(cr, "#0e0b0a", 0.9)
    c.paint(gblur(hole, 3.0) * 1.3, "#1a1512", 0.55)
    c.paint(hole, _tone(c, "#0a0808", 0.8, 1.3, 5.0), 1.0)
    for _ in range(3):   # 구멍 가장자리에 걸린 깨진 돌
        a = r.uniform(0, 6.28)
        x, y, s = bx + np.cos(a) * 18, by + np.sin(a) * 13, r.uniform(5, 8)
        pts = [(x + np.cos(a + da) * s * rr, y + np.sin(a + da) * s * rr) for da, rr in ((0.3, 1.0), (1.7, 0.8), (3.2, 1.0), (4.6, 0.75))]
        m = c.poly(pts)
        c.paint(gblur(m, 1.2) * 1.4, "#100c0a", 0.8)
        c.paint(m, _tone(c, "#7a766c", 0.8, 1.15, 4.0), 1.0)
        c.paint(m * sstep(-(c.xx - x) - (c.yy - y), 0, s), "#a09a8c", 0.35)
    # 뿌리: 구멍에서 나와 벽을 타고 바닥으로
    for i in range(int(r.integers(4, 6))):
        a = r.uniform(0.5, 2.6)
        x, y, w = bx + r.uniform(-8, 8), by + r.uniform(-3, 5), r.uniform(5.5, 9.5)
        pts = [(x, y)]
        while y < 158 and len(pts) < 16:
            a += r.uniform(-0.5, 0.5)
            a = np.clip(a, 0.35, 2.8)
            x, y = np.clip(x + np.cos(a) * 12, 6, 122), y + np.sin(a) * 12 + 1.5
            pts.append((x, y))
        c.paint(c.seg(pts, w + 2.6, True, 0.8), "#120e0a", 0.92)
        c.paint(c.seg(pts, w, True, 0.7), _tone(c, "#55432e", 0.75, 1.2, 3.0), 1.0)
        c.paint(c.seg([(px - w * 0.2, py - 0.5) for px, py in pts], w * 0.3, True, 0.6), "#86704c", 0.6)
        c.paint(c.seg([(px + w * 0.25, py) for px, py in pts], w * 0.3, True, 0.6), "#2a2016", 0.5)
        if r.random() < 0.7:   # 잔뿌리
            k = int(r.integers(2, max(3, len(pts) - 2)))
            sx, sy = pts[k]
            sub_pts = [(sx, sy), (sx + r.uniform(-16, 16), sy + r.uniform(8, 16)), (sx + r.uniform(-26, 26), sy + r.uniform(20, 34))]
            c.paint(c.seg(sub_pts, 3.6, True, 0.6), "#120e0a", 0.9)
            c.paint(c.seg(sub_pts, 2.0, True, 0.5), "#55432e", 1.0)
    # 바닥에 떨어진 돌 부스러기
    for _ in range(4):
        x, y, s = 64 + r.uniform(-50, 50), 160 - r.uniform(3, 8), r.uniform(3, 6)
        m = c.blob(x, y, s, s * 0.7, 0.25, s, 0.2)
        c.paint(gblur(m, 1.0) * 1.3, "#100c0a", 0.8)
        c.paint(m, _tone(c, "#726e64", 0.8, 1.15, 3.0), 1.0)


@flat("puddle", "nature", cell=(170, 140), tags=["water"], name_ko="웅덩이", fps=5,
    variants={"small": {"seed": 4, "size": 0.45}, "medium": {"seed": 10, "size": 0.72}, "large": {"seed": 17, "size": 1.0}, "murky": {"seed": 23, "size": 0.85, "tint": "murky"},
        "bloody": {"seed": 29, "size": 0.8, "tint": "blood"}, "ripple": {"seed": 10, "size": 0.72, "ripple": True, "frames": 4}})
def puddle(c, size=1.0, tint="water", ripple=False, f=0, seed=1):
    r = c.rng
    cx, cy = 85, 70
    rx, ry = 64 * size, 46 * size
    # 물 모양: 크고 작은 덩이 넷이 이어진 얕은 물(돌바닥의 낮은 곳을 따라 번졌다)
    m = c.blob(cx, cy, rx * 0.8, ry * 0.8, 0.38, 26 * size + 6, 0.06, r.uniform(-0.5, 0.5))
    for _ in range(3):
        a = r.uniform(0, 6.28)
        m = np.maximum(m, c.blob(cx + np.cos(a) * rx * 0.55, cy + np.sin(a) * ry * 0.5, rx * r.uniform(0.3, 0.5), ry * r.uniform(0.3, 0.5), 0.42, 14 * size + 4, 0.08, r.uniform(0, 3)))
    deep, shallow, hi = {"water": ("#070c10", "#172026", "#aebcc4"), "murky": ("#0b0f08", "#20281a", "#a8ae8c"), "blood": ("#160606", "#3a1210", "#c4a09a")}[tint]
    c.graded = False
    wet = sstep(gblur(m, 4.5) * 1.5 + (c.noise(8.0) - 0.5) * 0.35, 0.22, 0.75)
    c.paint(wet * (1 - m), "#0c0d0e", 0.3)                                # 젖어 어두워진 둘레(바닥이 비친다)
    inner = np.clip(gblur(m, 5.0 * size + 2.5) * 1.25 - 0.25, 0, 1) ** 1.4  # 가운데로 갈수록 깊다
    c.paint(m, shallow, 0.42)                                             # 얕은 가장자리 — 비쳐서 바닥 돌 · 줄눈이 보인다
    c.paint(m * inner, deep, 0.62)
    shade = np.clip(m - np.roll(m, (4, 4), (0, 1)), 0, 1)                 # 왼쪽 위 물가: 돌 턱이 드리운 그늘
    c.paint(gblur(shade, 1.0) * m, "#030506", 0.55)
    lit = sstep((c.xx - cx) / rx + (c.yy - cy) / ry, -0.25, 0.7)          # 빛을 마주 보는 오른쪽 아래 물가가 가늘게 반짝인다
    edge = c.rim(m, 1.1)
    c.paint(edge * lit * sstep(c.noise(9.0), 0.3, 0.5), hi, 0.62)
    glare = c.blob(cx + rx * 0.18, cy + ry * 0.2, rx * 0.42, ry * 0.2, 0.3, 12 * size + 4, 0.5, -0.25)   # 물낯에 길게 누운 희미한 빛
    c.paint(gblur(glare, 2.5 * size + 1) * m * inner, hi, 0.16)
    glare2 = c.blob(cx - rx * 0.25, cy - ry * 0.22, rx * 0.2, ry * 0.08, 0.3, 8 * size + 3, 0.5, -0.25)
    c.paint(gblur(glare2, 1.5) * m * inner, hi, 0.2)
    if ripple:                                                             # 떨어진 물방울의 번지는 고리
        for k, r0 in enumerate((3.0, 12.0)):
            rad = r0 + f * 6.5
            fade = max(0.0, 1.0 - rad / (40.0 * size + 8)) * (1.0 if k == 0 else 0.6)
            ring = c.ring(cx - 4, cy - 2, rad, 1.6, 0.7, rad * 0.78)
            c.paint(ring * m * lit.clip(0.35, 1), hi, 0.5 * fade)
            c.paint(np.roll(ring, (2, 0), (0, 1)) * m, "#04070a", 0.35 * fade)
        if f == 0:
            c.paint(_dots(c, [(cx - 4, cy - 2, 1.8)]), hi, 0.9)
    c.graded = False


@flat("ground_crack", "nature", cell=(180, 150), tags=["stone", "cave"], name_ko="바닥 균열", variants={"a": {"seed": 5}, "b": {"seed": 13}, "c": {"seed": 26}, "wide": {"seed": 34, "wide": True}})
def ground_crack(c, wide=False, seed=1):
    r = c.rng
    a = r.uniform(-0.5, 0.5)
    x, y = 90 - np.cos(a) * 70, 75 - np.sin(a) * 60
    pts = [(x, y)]
    for _ in range(13):
        a2 = a + r.uniform(-0.7, 0.7)
        x, y = x + np.cos(a2) * 11, y + np.sin(a2) * 11
        pts.append((x, y))
    w = 9.0 if wide else 4.5
    mid = len(pts) // 2
    m = np.maximum(c.seg(pts[mid:], w, True, 0.7), c.seg(pts[mid::-1], w, True, 0.7))
    m = np.maximum(m, c.cracks([(pts[k][0], pts[k][1], r.uniform(0, 6.28), r.uniform(14, 34)) for k in (2, 5, 8, 11)], 2.0))
    m = sstep(m + (c.noise(3.0, None, 2) - 0.5) * 0.5, 0.3, 0.55)
    c.paint(gblur(m, 2.5) * 1.2 * (1 - m), "#1a1512", 0.4)
    c.paint(np.roll(m, (2, 2), (0, 1)) * (1 - m), "#9a9486", 0.4)   # 빛 받는 아래쪽 턱
    c.paint(m, _tone(c, "#0b0908", 0.8, 1.3, 4.0), 0.96)
    c.paint(_dots(c, [(pts[k][0] + r.uniform(-10, 10), pts[k][1] + r.uniform(-10, 10), s) for k, s in zip(r.integers(0, len(pts), 10), r.uniform(0.8, 2.0, 10))]) * (1 - m), "#6e6a60", 0.75)


@flat("gravel", "nature", cell=(150, 120), tags=["stone", "cave"], name_ko="자갈", variants={"a": {"seed": 4}, "b": {"seed": 12}, "c": {"seed": 20}, "sparse": {"seed": 28, "n": 14}})
def gravel(c, n=38, seed=1):
    r = c.rng
    stones = []
    for _ in range(n):
        a, d = r.uniform(0, 6.28), r.uniform(0, 1) ** 0.7
        stones.append((75 + np.cos(a) * d * 60, 60 + np.sin(a) * d * 44, r.uniform(1.6, 4.8) * (1.15 - d * 0.5)))
    body = np.zeros((c.H, c.W), F)
    tone = np.zeros((c.H, c.W), F)
    for x, y, s in stones:
        m = c.blob(x, y, s, s * r.uniform(0.65, 0.9), 0.25, max(2.0, s), 0.25, r.uniform(0, 3.1))
        tone = np.where(m > body, r.uniform(0.75, 1.25), tone)
        body = np.maximum(body, m)
    c.paint(np.roll(gblur(body, 1.2), (3, 3), (0, 1)) * 1.3, "#0e0b0a", 0.6)       # 그림자
    c.paint(gblur(body, 0.9) * 1.5, "#141010", 0.85)                               # 잉크 테
    c.paint(body, hexc("#76726a")[None, None, :] * tone[..., None], 1.0)
    c.paint(np.roll(body, (-2, -2), (0, 1)) * body * gblur(body, 1.5) ** 2, "#b0aa9c", 0.4)   # 왼쪽 위 밝은 면
