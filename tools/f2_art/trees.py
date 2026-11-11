"""2층 나무 빚기(tools/f2_art/models_forest.py가 쓴다): 뒤틀린 줄기 · 갈라지는 가지 · 드러난 뿌리 · 잎 무더기 · 층층 가지(침엽).
좌표는 칸 단위(sdf.py), 줄기 밑동 = (0, y0, 0)."""
import numpy as np

import sdf
from sdf import cap, cone, smin, sphere, v3

F = np.float32


def _union(segs, k):
    def fn(p):
        d = None
        for a, b, ra, rb in segs:
            di = cap(p, a, b, ra, rb)
            d = di if d is None else (smin(d, di, k) if k > 0 else np.minimum(d, di))
        return d
    return fn


def limbs(rng, base, h, r, depth, spread=0.55, split=0.4, lift=0.25, xmax=9.0):
    """줄기에서 갈라지는 가지 마디들 [(a, b, ra, rb)] + 가지 끝점들. xmax = 가지가 옆으로 뻗는 한계(그림 칸 밖으로 나가지 않게)."""
    segs, tips = [], []

    def grow(a, direction, length, rad, dep):
        b = a + direction * length
        b[0] = np.clip(b[0], -xmax, xmax)
        segs.append((a, b, rad, rad * (0.62 if dep > 0 else 0.2)))
        if dep <= 0 or rad < 0.02:
            tips.append(b)
            return
        for _ in range(2 if dep > 1 else int(rng.integers(2, 4))):
            nd = direction * 0.5 + rng.normal(0, spread, 3).astype(F) * np.array([1.0, 0.7, 0.5], F)
            nd[2] = abs(nd[2]) * 0.6 + lift
            grow(b, nd / np.sqrt((nd * nd).sum()), length * rng.uniform(0.62, 0.82), rad * 0.6, dep - 1)

    grow(base, v3(rng.uniform(-0.05, 0.05), 0, 1), h * split, r, depth)
    return segs, tips


def roots(rng, base, r, n=5, reach=2.2):
    out = []
    for k in range(n):
        a = k * 6.283 / n + rng.uniform(-0.3, 0.3)
        out.append((base + v3(0, 0, r * 0.7), base + v3(np.cos(a) * r * reach, np.sin(a) * r * reach * 0.75, 0.02), r * 0.42, r * 0.1))
    return out


def trunk_fn(segs, seed, k=0.09, bump=0.06):
    """굵은 마디들을 녹여 합친 줄기(껍질이 울퉁불퉁)."""
    thick = [s for s in segs if s[2] >= 0.08]
    f = _union(thick, k)
    return lambda p: f(p) + (sdf.fbm(p * np.array([1, 1, 0.3], F), 0.14, seed, 2) - 0.5) * bump


def twig_fn(segs):
    thin = [s for s in segs if s[2] < 0.08]
    return _union(thin, 0.0) if thin else None


def crown_fn(rng, centers, r0, r1, seed, lump=0.3, squash=0.8):
    """잎 무더기: 가지 끝 둘레에 둥근 덩이를 여럿 녹여 붙이고 잡음으로 들쭉날쭉하게."""
    blobs = [(c + rng.normal(0, 0.18, 3).astype(F), rng.uniform(r0, r1)) for c in centers]

    def fn(p):
        d = None
        for c, r in blobs:
            q = (p - c) * np.array([1, 1, 1.0 / squash], F)
            di = sdf.length(q) - r
            d = di if d is None else smin(d, di, 0.22)
        return d * 0.8 + (sdf.fbm(p, 0.22, seed, 3) - 0.5) * lump
    return fn


def tiers_fn(base, z0, z1, r_bottom, n, seed):
    """침엽수 층층 가지: 아래로 처진 원뿔 단을 쌓고 가장자리를 별 모양 · 잡음으로 흔든다."""
    def fn(p):
        d = None
        ang = np.arctan2(p[:, 1] - base[1], p[:, 0] - base[0])
        for k in range(n):
            t = k / max(1, n - 1)
            z = z0 + (z1 - z0) * t
            r = r_bottom * (1.0 - t * 0.78)
            hgt = (z1 - z0) / n * 2.1
            wave = 1.0 + 0.2 * np.sin(ang * (5 + k % 3) + k * 1.7)
            di = cone(p, v3(base[0], base[1], z), r * 1.0, hgt) / 1.0 - (wave - 1.0) * r * 0.35
            d = di if d is None else np.minimum(d, di)
        return d * 0.7 + (sdf.fbm(p, 0.16, seed, 3) - 0.5) * 0.22
    return fn
