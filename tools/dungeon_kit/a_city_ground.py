"""도시 길 · 땅(AM69): 큰길 포석 · 광장 판석 · 자갈길 · 보도 · 풀 난 돌바닥 · 바큇자국 흙길(바닥 타일 — a_floor와 같은 4 × 4칸 넓은 그림)과
길 조각(연석 · 배수로 · 배수구 · 맨홀 · 돌계단 · 경사로 · 꺼진 자리 · 바큇자국 · 짚 부스러기).
이미 있는 것은 다시 만들지 않는다: 판석 floor_flag · 낡은 floor_old · 깨진 floor_broken · 막돌 floor_cobble · 흙 floor_dirt · 진흙 ground_mud · 웅덩이 puddle · 금 ground_crack · 이끼 moss_patch."""
import numpy as np

import ground
import mats as M
import sdf
import surf
import tex
from a_floor import _floor, _rgba
from kit import (F, box, cap, chip, cyl, flat, hcyl, prop, rot_z, rough, sub, torus, v3)  # noqa: F401
from paint2d import gblur, sstep
from surf import W, fbm, hexc, pnoise

GAP = hexc("#1c1a19")


# ── 바닥 타일 ────────────────────────────────────────────────────────────────

def _setts(seed=1):
    cell, edge, _ = surf.courses(seed + 400, 14, 44, 60, 1.5, True, 0.07)
    img, gap, h = surf.stonework(cell, edge, hexc("#78756c"), GAP, seed, 2.6, 0.12, 1.0, 0.02, 0.5)
    return img, gap, h, cell, edge


@_floor("street_setts", "큰길 포석", {"a": {"seed": 1}, "b": {"seed": 2}})
def street_setts(c, seed=1):
    """반듯하게 다듬은 포석을 줄 맞춰 깐 큰길 — 밝고 고르다."""
    img, gap, h, _, _ = _setts(seed)
    return _rgba(surf.finish(img, "#66635c", seed))


@_floor("street_worn_setts", "낡고 꺼진 포석", base="street_setts")
def street_worn_setts(c, seed=1):
    """큰길 포석이 닳고 군데군데 꺼졌다: 빠진 돌 자리에 흙, 줄눈에 진흙, 수레가 다닌 자리는 어둡게 패였다."""
    img, gap, h, cell, edge = _setts(1)
    img0 = img
    rng = np.random.default_rng(seed + 61)
    sink = np.clip((fbm(5, seed + 3, 3) - 0.5) * 5.0, 0, 1)
    img = img * (1 - sink[..., None] * 0.26) * (1.0 + (surf.relief(-sink, 3.0) - 1.0) * 0.7)[..., None]
    gone = (rng.random(int(cell.max()) + 1) < 0.09)[cell].astype(F) * np.clip(sink * 3.0, 0, 1)
    soil, _ = ground.earth(hexc("#3c342b"), seed + 5, 0.3, 1.3)
    lip = np.clip(np.roll(gone, (4, 4), (0, 1)) - gone, -1, 0)
    img = surf.mix(img, gone, soil * 0.8) * (1.0 + lip[..., None] * 0.6)
    mud = np.clip(gap * 1.6 + np.clip(1 - edge / 9.0, 0, 1) * 0.5, 0, 1) * np.clip(fbm(7, seed + 8, 3) * 2.6 - 0.8, 0, 1)
    img = surf.mix(img, mud * 0.8, hexc("#3a3128"))
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 4, 70, width=1.8, branch=0.2)
    ground.stones(ly, rng, 30, 1.5, 3.5, hexc("#6e6b62"))
    return _rgba(surf.finish(ly.over(img), "#66635c", 1, ref=img0))


def _diag(n, seed, wob=1.4):
    """45° 돌린 정사각 판(사방으로 이어진다) → (돌 번호, 가장자리까지 거리)."""
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    wx = xx + (fbm(16, seed + 1, 2) - 0.5) * wob * 2
    wy = yy + (fbm(16, seed + 2, 2) - 0.5) * wob * 2
    s = W / n
    u, v = (wx + wy) / s, (wx - wy) / s
    iu, iv = np.floor(u), np.floor(v)
    fu, fv = u - iu, v - iv
    edge = np.minimum(np.minimum(fu, 1 - fu), np.minimum(fv, 1 - fv)) * s / np.sqrt(2.0)
    cell = (np.mod(iu - iv, 2 * n) * 2 * n + np.mod(iu + iv, 2 * n)).astype(np.int32)
    return cell, edge.astype(F)


@_floor("street_plaza", "광장 판석", {"a": {"seed": 1}, "b": {"seed": 2}})
def street_plaza(c, seed=1):
    """비스듬히 깐 네모 판석 — 광장. 오래 밟혀 가운데가 닳았다."""
    cell, edge = _diag(5, seed + 410)
    img, gap, h = surf.stonework(cell, edge, hexc("#7c786c"), GAP, seed, 2.8, 0.1, 1.0, 0.02, 0.6)
    worn = np.clip((fbm(6, seed + 3, 3) - 0.48) * 3.0, 0, 1)
    img = img * (1 - worn[..., None] * 0.14)
    rng = np.random.default_rng(seed + 62)
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 3, 60, width=1.6, branch=0.15)
    return _rgba(surf.finish(ly.over(img), "#69665d", seed))


@_floor("street_gravel", "자갈길", {"a": {"seed": 1}, "b": {"seed": 2}})
def street_gravel(c, seed=1):
    """다진 흙 위에 잔자갈을 촘촘히 깐 길."""
    img, h = ground.earth(hexc("#585046"), seed + 420, 0.2, 1.0)
    rng = np.random.default_rng(seed + 63)
    ly = tex.Layer()
    ground.stones(ly, rng, 520, 1.6, 3.4, hexc("#77726a"))
    ground.stones(ly, rng, 260, 2.2, 4.6, hexc("#8a857a"))
    ground.stones(ly, rng, 120, 1.5, 3.0, hexc("#5e5a54"))
    return _rgba(surf.finish(ly.over(img), "#5c574f", seed))


@_floor("street_sidewalk", "판석 보도", {"a": {"seed": 1}, "b": {"seed": 2}})
def street_sidewalk(c, seed=1):
    """집 둘레의 넓은 판석 보도: 한 칸 깊이의 큰 판이 줄지어 놓였다."""
    cell, edge, _ = surf.courses(seed + 430, 4, 170, 250, 1.2, True, 0.04)
    img, gap, h = surf.stonework(cell, edge, hexc("#847f74"), GAP, seed, 3.0, 0.09, 1.1, 0.018, 0.7)
    grime = np.clip((fbm(5, seed + 3, 3) - 0.5) * 2.6, 0, 1)
    img = img * (1 - grime[..., None] * 0.16)
    rng = np.random.default_rng(seed + 64)
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 3, 50, width=1.5, branch=0.15)
    ground.stones(ly, rng, 8, 1.5, 3.0, hexc("#7a766c"))
    return _rgba(surf.finish(ly.over(img), "#6d6a61", seed))


@_floor("street_overgrown", "풀이 자란 돌바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def street_overgrown(c, seed=1):
    """돌 틈마다 풀과 이끼가 올라온 막돌 길 — 인적 드문 뒷골목 · 안뜰."""
    cell, d1, edge = tex.voronoi(150, seed + 440, 1.0)
    img, gap, h = surf.stonework(cell, edge - 1.0, hexc("#69665e"), hexc("#1e1c1a"), seed, 4.5, 0.15, 0.95, 0.03, 0.4)
    img = img * surf.relief(np.clip(1.0 - d1 / 26.0, 0, 1) ** 0.5, 0.55)[..., None]
    patch = np.clip(fbm(5, seed + 3, 3) * 2.6 - 0.75, 0, 1)
    green = np.clip((gap * 1.5 + np.clip(1 - edge / 12.0, 0, 1) * 0.8) * (0.25 + patch) + np.clip(patch - 0.75, 0, 1) * 1.5, 0, 1)
    img = surf.mix(img, green * 0.85, hexc("#3c4a28")[None, None, :] * (0.7 + fbm(36, seed + 4, 2) * 0.6)[..., None])
    rng = np.random.default_rng(seed + 65)
    ly = tex.Layer()
    ground.strokes(ly, rng, 5200, 5, 12, [hexc("#3e5226"), hexc("#526632"), hexc("#6a7640")], 0.1, 0.8, 1.7, 0.9, np.clip(green * 1.3 - 0.2, 0, 1))
    return _rgba(surf.finish(ly.over(img), "#535446", seed))


@_floor("street_rutted", "바큇자국 난 흙길", {"h": {"seed": 1}, "v": {"seed": 1, "turn": True}, "h_b": {"seed": 2}})
def street_rutted(c, seed=1, turn=False):
    """수레가 다녀 두 줄로 패인 흙길(h = 동서 · v = 남북). 패인 골은 젖어 어둡고 둑은 말라 밝다."""
    base = hexc("#51463a")
    img, h0 = ground.earth(base, seed + 450, 0.24, 1.1)
    yy = np.mgrid[0:W, 0:W][0].astype(F)
    rut = np.zeros((W, W), F)
    for i, y0 in enumerate((150.0, 300.0)):
        wander = (pnoise(6, seed + 20 + i)[0][None, :] - 0.5) * 34.0
        d = np.abs(yy - y0 - wander)
        rut = np.maximum(rut, np.exp(-(d / 11.0) ** 2) * (0.75 + fbm(9, seed + 30 + i, 2) * 0.4))
        rut = np.maximum(rut, np.exp(-(np.abs(d - 30.0) / 6.0) ** 2) * 0.3 * np.clip(fbm(7, seed + 40 + i, 2) * 3 - 1.0, 0, 1))   # 겹친 옛 자국
    img = img * (1 - rut[..., None] * 0.42) * (1.0 + (surf.relief(-rut, 5.0) - 1.0) * 0.9)[..., None]
    wet = np.clip(rut - 0.72, 0, 1) * 3.0 * np.clip(fbm(6, seed + 50, 2) * 3 - 1.2, 0, 1)
    img = surf.mix(img, np.clip(wet, 0, 1) * 0.6, hexc("#1c1a18"))
    rng = np.random.default_rng(seed + 66)
    ly = tex.Layer()
    ground.stones(ly, rng, 46, 1.8, 4.6, hexc("#6a655c"))
    ground.strokes(ly, rng, 60, 6, 12, [hexc("#8a7648") * 0.8], 1.3, 1.5, 1.4, 0.7)
    out = surf.finish(ly.over(img), "#4a4036", seed)
    return _rgba(np.ascontiguousarray(out.transpose(1, 0, 2)) if turn else out)


# ── 길 조각(덩어리) ──────────────────────────────────────────────────────────

ARMS = {"n": (0, 1), "e": (1, 0), "s": (0, -1), "w": (-1, 0)}


def _water(k, f=0, seed=1, name="water"):
    """흐르는 물 재질(f = 프레임 — 반짝이는 줄이 흘러간다)."""
    deep, hi = M.hexc("#18242a"), M.hexc("#8ea4aa")

    def fn(p, n):
        q = p + np.array([f * 0.09, f * 0.06, 0], F)
        s = sdf.noise(q * np.array([1.0, 2.2, 1.0], F), 0.07, seed)
        c = deep[None, :] * (0.75 + sdf.noise(p, 0.22, seed + 1)[:, None] * 0.6)
        g = np.clip((s - 0.66) * 7.0, 0, 1)[:, None]
        return (c * (1 - g) + hi[None, :] * g).astype(F), np.zeros(len(p), F), np.full(len(p), 0.55, F)
    return k.mat(name, fn)


def _damp(k):
    base = M.hexc("#2a2826")

    def fn(p, n):
        return (base[None, :] * (0.7 + sdf.fbm(p, 0.12, 4, 2)[:, None] * 0.6)).astype(F), np.zeros(len(p), F), np.full(len(p), 0.3, F)
    return k.mat("damp", fn)


@prop("curb", "city", layer="decal", cell=(2, 2), tags=["street", "stone", "module", "edge"], name_ko="연석",
    variants={"h": {}, "v": {"arms": "ns"}, "corner_ne": {"arms": "ne"}, "corner_nw": {"arms": "nw"}, "corner_se": {"arms": "se"}, "corner_sw": {"arms": "sw"},
        "end": {"arms": "w", "end": True}, "broken": {"broken": True}, "drop": {"low": True}},
    meta={"module": [1.0, 0.22], "note": "칸 가운데를 지나는 낮은 돌 턱(한 칸 조각). h 동서 · v 남북 · corner_xy = 그 두 쪽으로 팔이 난 꺾임 · drop = 수레가 넘는 낮춘 턱"})
def curb(k, arms="ew", end=False, broken=False, low=False, seed=1):
    hgt = 0.035 if low else 0.07
    n = 0

    def stone(cx, cy, hx, hy, hz=hgt, bad=False):
        nonlocal n
        fn = rough(lambda p: box(p, v3(cx, cy, hz), (hx - 0.008, hy - 0.008, hz), 0.018), 0.014, 0.12, seed + n)
        k.add(chip(fn, 0.56, 0.16, seed + n, 0.07) if bad else fn, ("stone", "stone_l", "stone")[n % 3])
        n += 1
    if len(arms) == 2 and arms in ("ne", "nw", "se", "sw"):
        stone(0, 0, 0.12, 0.12)
    for a in arms:
        dx, dy = ARMS[a]
        full = len(arms) == 2 and set(arms) in ({"e", "w"}, {"n", "s"})
        c0, half = (0.25, 0.25) if full else (0.31, 0.19)
        if end:
            stone(dx * 0.3, dy * 0.3, 0.2 if dx else 0.11, 0.2 if dy else 0.11)
            stone(-dx * 0.02, -dy * 0.02, 0.12 if dx else 0.1, 0.12 if dy else 0.1, hgt * 0.55)
            continue
        stone(dx * c0, dy * c0, half if dx else 0.11, half if dy else 0.11, bad=broken and a == "e")
    if broken:
        k.rubble([(0.2, -0.26), (0.36, -0.2), (0.05, -0.2)], "stone", 0.025, 0.05)
    return {"shadow": 0.35}


def _chan2d(p, arms, grow):
    """배수로 물길(가운데 + 팔)의 평면 거리."""
    d = np.maximum(np.abs(p[:, 0]), np.abs(p[:, 1])) - (0.14 + grow)
    for a in arms:
        dx, dy = ARMS[a]
        cx, cy = dx * 0.45, dy * 0.45
        hx, hy = (0.45 if dx else 0.14) + grow, (0.45 if dy else 0.14) + grow
        d = np.minimum(d, np.maximum(np.abs(p[:, 0] - cx) - hx, np.abs(p[:, 1] - cy) - hy))
    return d


@prop("gutter", "city", layer="decal", cell=(2, 2), tags=["street", "stone", "water", "module"], name_ko="배수로", fps=6,
    variants={"h": {}, "v": {"arms": "ns"}, "corner_ne": {"arms": "ne"}, "corner_nw": {"arms": "nw"}, "corner_se": {"arms": "se"}, "corner_sw": {"arms": "sw"}, "end": {"arms": "w"},
        "h_flow": {"flow": True, "frames": 4}, "v_flow": {"arms": "ns", "flow": True, "frames": 4}},
    meta={"module": [1.0, 0.46], "note": "칸 가운데를 지나는 얕은 돌 도랑(한 칸 조각). end = 서쪽에서 와서 막힌 끝(배수구 drain_grate를 그 위에) · _flow = 물이 흐른다"})
def gutter(k, arms="ew", flow=False, seed=1, f=0):
    clip = lambda p: np.maximum(np.abs(p[:, 0]), np.abs(p[:, 1])) - 0.5
    mat = _water(k, f, seed) if flow else _damp(k)
    k.add(lambda p: np.maximum.reduce([_chan2d(p, arms, 0.0), clip(p), np.abs(p[:, 2] - 0.006) - 0.006]), mat)
    rim = lambda p: np.maximum.reduce([_chan2d(p, arms, 0.085), -_chan2d(p, arms, 0.0), clip(p), np.abs(p[:, 2] - 0.022) - 0.022])
    k.add(rough(rim, 0.012, 0.1, seed), "masonry")
    return {"shadow": 0.25}


@prop("drain_grate", "city", layer="decal", cell=(2, 2), tags=["street", "iron", "sewer"], name_ko="길바닥 배수구", interact="examine",
    variants={"grate": {}, "clogged": {"state": "clogged"}, "open": {"state": "open"}})
def drain_grate(k, state="grate", seed=1):
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.022), (0.33, 0.3, 0.022), 0.01), box(p, v3(0, 0, 0.02), (0.24, 0.21, 0.1))), 0.012, 0.1, seed), "stone_d")
    k.add(lambda p: box(p, v3(0, 0, 0.004), (0.24, 0.21, 0.004)), "void")
    bars = [-0.18, -0.09, 0.0, 0.09, 0.18]
    if state == "open":
        bars = [-0.18, 0.18]
        k.add(lambda p: np.minimum(hcyl(rot_z(p, 0.5, (0.5, -0.2, 0)), v3(0.5, -0.42, 0.02), v3(0.5, 0.02, 0.02), 0.02), hcyl(rot_z(p, -0.2, (0.62, -0.1, 0)), v3(0.62, -0.3, 0.02), v3(0.62, 0.1, 0.02), 0.02)), "rust")
    for x in bars:
        k.add(lambda p, x=x: hcyl(p, v3(x, -0.24, 0.028), v3(x, 0.24, 0.028), 0.02), "rust" if state != "grate" else "iron")
    if state == "clogged":
        for i, (x, y) in enumerate(k.scatter(7, 0.24, 0.2)):
            k.add(rough(lambda p, x=x, y=y: box(p, v3(x, y, 0.045), (0.07, 0.05, 0.012), 0.01), 0.03, 0.06, seed + i), ("leaf_dry", "dirt", "moss")[i % 3])
    return {"shadow": 0.2}


@prop("manhole", "city", layer="decal", cell=(3, 2), tags=["street", "iron", "sewer", "passage"], name_ko="맨홀", interact="hatch",
    variants={"closed": {}, "ajar": {"state": "ajar"}, "open": {"state": "open"}}, meta={"states": {"closed": "closed", "open": "open"}})
def manhole(k, state="closed", seed=1):
    k.add(rough(lambda p: sub(cyl(p, v3(0, 0, 0), 0.42, 0.035, 0.01), cyl(p, v3(0, 0, -0.1), 0.32, 0.5)), 0.012, 0.1, seed), "stone_d")
    lx, ly = {"closed": (0, 0), "ajar": (0.2, 0.06), "open": (0.72, -0.05)}[state]
    if state != "closed":
        k.add(lambda p: cyl(p, v3(0, 0, 0), 0.32, 0.008), "void")
    z0 = 0.0 if state == "open" else 0.012
    lid = lambda p: cyl(p, v3(lx, ly, z0), 0.31, 0.04, 0.008)
    k.add(lid, "iron")
    k.add(lambda p: np.minimum.reduce([torus(p, v3(lx, ly, z0 + 0.042), 0.2, 0.014), box(p, v3(lx, ly, z0 + 0.042), (0.2, 0.014, 0.012)), box(p, v3(lx, ly, z0 + 0.042), (0.014, 0.2, 0.012)),
        torus(p, v3(lx, ly, z0 + 0.042), 0.08, 0.012)]), "rust")
    return {"shadow": 0.3}


@prop("street_steps", "city", cell=(4, 3), tags=["street", "stone", "passage"], name_ko="돌계단", interact="stairs",
    variants={"wide": {}, "narrow": {"w": 0.46}, "worn": {"worn": True}, "grand": {"w": 1.45, "steps": 5}},
    meta={"note": "북쪽 윗단으로 오르는 바깥 계단(단 높이 차 0.45~0.55칸). wide 2칸 · narrow 1칸 · grand 3칸 큰 계단. 양옆 낮은 볼기돌만 막힌다"})
def street_steps(k, w=0.95, steps=4, worn=False, seed=1):
    for i in range(steps):
        y0 = -0.45 + i * 0.24
        st = lambda p, i=i, y0=y0: box(p, v3(0, (y0 + 0.55) / 2, (i + 1) * 0.055), (w, (0.55 - y0) / 2, (i + 1) * 0.055), 0.014)
        fn = rough(st, 0.045 if worn else 0.016, 0.22, seed + i)
        k.add(chip(fn, 0.5, 0.2, seed + i, 0.05) if worn else fn, ("stone_m" if worn else "stone") if i % 2 == 0 else "stone_l")
    for s in (-1, 1):
        k.add(rough(lambda p, s=s: np.maximum(box(p, v3(s * (w + 0.1), 0.05, 0.3), (0.1, 0.5, 0.3), 0.02), p[:, 2] - 0.2 - (p[:, 1] + 0.45) * 0.42), 0.02, 0.2, seed + 9), "masonry_m" if worn else "masonry")
    if worn:
        k.rubble([(-w * 0.6, -0.6), (w * 0.5, -0.55), (0.1, -0.2)], "stone", 0.03, 0.06)
    return {"cell": (2 * w + 1.2, 2.4), "foot": 0.9}


@prop("street_ramp", "city", cell=(3, 3), tags=["street", "passage"], name_ko="작은 경사로", interact="stairs",
    variants={"stone": {}, "plank": {"kind": "plank"}, "plank_broken": {"kind": "plank", "broken": True}},
    meta={"note": "북쪽으로 0.45칸 오르는 비탈(수레 · 손수레용). plank = 단에 걸친 널다리"})
def street_ramp(k, kind="stone", broken=False, seed=1):
    slope = lambda p: p[:, 2] - (p[:, 1] + 0.5) * 0.45 - 0.02
    if kind == "stone":
        k.add(rough(lambda p: np.maximum(box(p, v3(0, 0, 0.25), (0.48, 0.5, 0.25), 0.01), slope(p)), 0.02, 0.2, seed), "masonry")
        for s in (-1, 1):
            k.add(rough(lambda p, s=s: np.maximum(box(p, v3(s * 0.55, 0, 0.3), (0.08, 0.5, 0.3), 0.015), slope(p) - 0.09), 0.02, 0.2, seed + 3), "stone_d")
        return {"foot": 0.9}
    for i, x in enumerate((-0.33, -0.11, 0.11, 0.33)):
        if broken and i == 2:
            k.add(rough(lambda p: box(rot_z(p, 0.5, (0.6, -0.5, 0)), v3(0.6, -0.5, 0.02), (0.1, 0.3, 0.02), 0.006), 0.012, 0.1, seed), "plank_y")
            continue
        k.add(rough(lambda p, x=x: np.maximum(np.maximum(np.abs(p[:, 0] - x) - 0.1, np.abs(p[:, 1]) - 0.52), np.abs(slope(p) + 0.0) - 0.022), 0.01, 0.15, seed + i), "plank_y" if i % 2 else "wood_l")
    for y in (-0.3, 0.0, 0.3):
        k.add(lambda p, y=y: box(p, v3(0, y, (y + 0.5) * 0.45 + 0.055), (0.44, 0.025, 0.014)), "wood_d")
    k.add(rough(lambda p: box(p, v3(0, 0.46, 0.2), (0.46, 0.05, 0.2), 0.01), 0.02, 0.15, seed), "wood_d")
    return {"foot": 0.9}


# ── 길 자국(평면) ────────────────────────────────────────────────────────────

@flat("road_patch", "city", cell=(160, 120), tags=["street", "wear"], name_ko="길 꺼진 자리",
    variants={"sunken": {"seed": 3}, "sunken_b": {"seed": 8}, "dirt": {"kind": "dirt", "seed": 5}, "dirt_b": {"kind": "dirt", "seed": 12}})
def road_patch(c, kind="sunken", seed=1):
    """포석이 꺼지거나(sunken — 어두운 그늘과 금) 빠져 흙이 드러난 자리(dirt)."""
    r = c.rng
    m = c.blob(80, 60, 58, 38, 0.4, 22, 0.1, r.uniform(-0.4, 0.4))
    c.graded = kind == "dirt"
    if kind == "dirt":
        tone = 0.75 + c.noise(10.0)[..., None] * 0.5
        c.paint(m, hexc("#463c30")[None, None, :] * tone, 0.95)
        c.shade(np.clip(m - np.roll(m, (5, 5), (0, 1)), 0, 1), -0.55)
        for _ in range(16):
            x, y = 80 + r.uniform(-48, 48), 60 + r.uniform(-30, 30)
            s = c.blob(x, y, r.uniform(2.5, 5.5), r.uniform(2.0, 4.0), 0.3, 4, 0.2, r.uniform(0, 3)) * (m > 0.5)
            c.paint(np.roll(s, (2, 2), (0, 1)) * (m > 0.5), "#1a1614", 0.6)
            c.paint(s, hexc("#6e6a60") * r.uniform(0.8, 1.15))
        c.paint(c.rim(m, 1.4), "#191513", 0.75)
    else:
        deep = np.clip(gblur(m, 9) * 1.3 - 0.2, 0, 1)
        c.paint(m * deep, "#12100f", 0.42)
        c.paint(gblur(np.clip(m - np.roll(m, (5, 5), (0, 1)), 0, 1), 1.5), "#0a0908", 0.5)
        c.paint(gblur(np.clip(m - np.roll(m, (-4, -4), (0, 1)), 0, 1), 1.2), "#b0a890", 0.14)
        ck = c.cracks([(80 + r.uniform(-20, 20), 60 + r.uniform(-12, 12), r.uniform(0, 6.28), r.uniform(40, 70)) for _ in range(3)], 1.8) * (gblur(m, 6) > 0.2)
        c.paint(ck, "#0c0a0a", 0.85)


@flat("cart_ruts", "city", cell=(200, 200), tags=["street", "wear", "track"], name_ko="수레바퀴 자국",
    variants={"h": {"seed": 4}, "v": {"seed": 6, "turn": True}, "curve": {"seed": 9, "curve": True}})
def cart_ruts(c, turn=False, curve=False, seed=1):
    r = c.rng
    c.graded = False
    for off in (-22.0, 22.0):
        pts = []
        for i in range(13):
            t = i / 12.0
            a, b = 12 + t * 176, 100 + off + np.sin(t * 5.0 + seed) * 3.0 + r.uniform(-1.2, 1.2)
            if curve:
                ang = t * 1.2
                rad = 150 + off
                a, b = 14 + np.sin(ang) * rad, 190 - np.cos(ang) * rad + 0 * b
            pts.append((b, a) if turn else (a, b))
        g = c.seg(pts, 9.0, False, 2.0) * sstep(c.noise(14.0), 0.25, 0.55)
        ends = sstep(np.minimum((c.yy if turn else c.xx) - 8, 192 - (c.yy if turn else c.xx)), 0, 34) if not curve else 1.0
        c.paint(g * ends, "#14110f", 0.5)
        c.paint(np.clip(np.roll(g, (3, 3), (0, 1)) - g, 0, 1) * ends, "#a89c84", 0.16)


@flat("straw_scatter", "city", cell=(140, 100), tags=["street", "stable", "litter"], name_ko="흩어진 짚",
    variants={"a": {"seed": 3}, "b": {"seed": 7, "n": 40}, "dung": {"seed": 11, "dung": True}})
def straw_scatter(c, n=75, dung=False, seed=1):
    r = c.rng
    cols = ("#9a8450", "#7a6a40", "#b09a5e", "#5e5232")
    for i in range(n):
        x, y = 70 + r.normal(0, 26), 50 + r.normal(0, 17)
        a, ln = r.uniform(0, 3.14), r.uniform(7, 17)
        pts = [(x - np.cos(a) * ln / 2, y - np.sin(a) * ln / 2), (x + r.uniform(-1.5, 1.5), y + r.uniform(-1.5, 1.5)), (x + np.cos(a) * ln / 2, y + np.sin(a) * ln / 2)]
        s = c.seg(pts, 1.7, False, 0.6)
        c.paint(np.roll(s, (2, 2), (0, 1)), "#15110e", 0.35)
        c.paint(s, cols[i % 4])
    if dung:
        for x, y in ((62, 48), (74, 54), (68, 60), (82, 47)):
            b = c.blob(x, y, 7, 5, 0.25, 5, 0.2)
            c.paint(np.roll(b, (3, 3), (0, 1)), "#120e0c", 0.5)
            c.paint(b, hexc("#3e3022")[None, None, :] * (0.8 + c.noise(4.0)[..., None] * 0.5))
            c.paint(c.rim(b, 1.0), "#17120f", 0.7)
