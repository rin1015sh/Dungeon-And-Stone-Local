"""건물 실내 공통 2 — 장식(태피스트리 · 벽걸이 천 · 그림 액자 · 장식 문양판 · 벽걸이 장식 · 사냥 기념물 · 짐승 가죽 깔개 · 벽 깃발 줄 ·
장식 접시 걸이 · 실내 화분 · 걸이 화분)과 살림(항아리 · 잔 · 차린 음식 · 작은 장식품). 도시 · 실내 라이브러리(AM69).
문양은 모두 중립(띠 · 갈매기 · 덩굴 · 짐승 그림자) — 종교 · 문장(紋章) 상징을 새로 만들지 않는다. 글자 없음.
벽 부착물은 밑 = z 0 — 세트에서 `up`으로 올려 단다."""
import numpy as np

import sdf
import mats as M
from a_furniture import _X, _cup, _frustum, _plate
from kit import box, cap, cyl, ell, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3

F = np.float32
PI = np.pi
hexc = M.hexc


def _out(c):
    n = len(c)
    return np.clip(c, 0, 1).astype(F), np.zeros(n, F), np.zeros(n, F)


# ── 무늬 재질(물건 좌표 x · z로 그린다) ─────────────────────────────────────────

def _seg2(x, z, a, b, r):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    t = np.clip(((x - ax) * dx + (z - az) * dz) / max(dx * dx + dz * dz, 1e-9), 0, 1)
    return np.hypot(x - ax - t * dx, z - az - t * dz) - r


def _beast(x, z, cx, cz, s, flip=1.0, antler=True):
    """옆모습 사슴 그림자(2D 거리) — 몸 · 목 · 머리 · 다리 넷 · 뿔."""
    X = (x - cx) * flip
    Z = z - cz
    d = np.hypot(X / (0.12 * s), Z / (0.05 * s)) * 0.05 * s - 0.05 * s
    d = np.minimum(d, _seg2(X, Z, (0.09 * s, 0.02 * s), (0.15 * s, 0.1 * s), 0.022 * s))
    d = np.minimum(d, np.hypot((X - 0.17 * s) / 1.5, Z - 0.11 * s) - 0.022 * s)
    for lx, kick in ((-0.08, -0.02), (-0.05, 0.01), (0.06, 0.02), (0.09, -0.01)):
        d = np.minimum(d, _seg2(X, Z, (lx * s, -0.02 * s), ((lx + kick) * s, -0.12 * s), 0.011 * s))
    if antler:
        for a, b in (((0.16, 0.13), (0.13, 0.22)), ((0.14, 0.18), (0.1, 0.2)), ((0.17, 0.13), (0.22, 0.21)), ((0.2, 0.18), (0.24, 0.17))):
            d = np.minimum(d, _seg2(X, Z, (a[0] * s, a[1] * s), (b[0] * s, b[1] * s), 0.007 * s))
    return d


def _weave(base, pattern, hw, hz, z0, worn, seed):
    """짠 천: 바탕 + 무늬(x, z → 색 (N, 3) · 마스크) + 가장자리 띠 + 씨실 결. worn = 바래고 좀먹었다."""
    def fn(p, n):
        x, z = p[:, 0], p[:, 2] - z0
        c = np.tile(hexc(base), (len(p), 1))
        c = pattern(x, z, c)
        edge = (np.abs(x) > hw - 0.05) | (z < 0.05) | (z > hz - 0.05)
        c = np.where(edge[:, None], hexc("#3a2a20") * 1.2, c)
        thread = np.sin(z * 260) * 0.04 + (sdf.noise(p, 0.02, seed) - 0.5) * 0.08
        c = c * (1 + thread)[:, None]
        if worn:
            fade = np.clip(sdf.fbm(p, 0.25, seed + 3, 3) * 1.6 - 0.4, 0, 1)
            lum = (c @ np.array([0.3, 0.59, 0.11], F))[:, None]
            c = c * (1 - fade[:, None] * 0.55) + (lum * 0.8 + 0.12) * fade[:, None] * 0.55
        return _out(c)
    return fn


def _pat_bands(x, z, c):
    for i, col in enumerate(("#6a2e2a", "#8a7a52", "#34425a", "#8a7a52", "#6a2e2a")):
        zc = 0.25 + i * 0.22
        band = np.abs(z - zc) < 0.045
        zig = np.abs(((x * 8) % 1.0) - 0.5) * 0.08
        chev = (np.abs(z - zc - zig + 0.02) < 0.018)
        c = np.where(band[:, None], hexc(col), c)
        c = np.where((chev & ~band)[:, None], hexc("#b0a07a"), c)
    return c


def _pat_foliage(x, z, c):
    vine = np.abs(x * 0.9 - 0.12 * np.sin(z * 9)) < 0.018
    leaf = (np.abs(np.sin(z * 18)) > 0.82) & (np.abs(x * 0.9 - 0.12 * np.sin(z * 9) - np.sign(np.sin(z * 18)) * 0.07) < 0.05)
    vine2 = (np.abs(np.abs(x) - 0.3 - 0.04 * np.sin(z * 14)) < 0.012)
    c = np.where((leaf | vine2)[:, None], hexc("#5a6a3a"), c)
    c = np.where(vine[:, None], hexc("#8a7a4a"), c)
    flower = (np.hypot((np.abs(x) - 0.3) * 1.0, ((z * 7) % 1.0 - 0.5) / 7) < 0.03)
    return np.where(flower[:, None], hexc("#9a4a3a"), c)


def _pat_hunt(x, z, c):
    ground = z < 0.22 + 0.03 * np.sin(x * 11)
    c = np.where(ground[:, None], hexc("#4a4a30"), c)
    for tx in (-0.38, -0.3, 0.36):
        tree = (np.abs(x - tx) < (0.62 - z) * 0.22) & (z > 0.5) & (z < 0.95)
        c = np.where(tree[:, None], hexc("#2e3a26"), c)
    d = np.minimum(_beast(x, z, 0.02, 0.42, 1.6, 1.0), _beast(x, z, -0.24, 0.36, 1.0, -1.0, False))
    c = np.where((d < 0)[:, None], hexc("#2a1e18"), c)
    sun = np.hypot(x - 0.24, z - 0.9) < 0.06
    return np.where(sun[:, None], hexc("#b8984a"), c)


PATTERNS = {"bands": ("#4a3a2a", _pat_bands), "foliage": ("#2c3434", _pat_foliage), "hunt": ("#8a7650", _pat_hunt)}


@prop("tapestry", "interior", layer="wall_decal", cell=(3, 3.6), tags=["cloth", "decor", "wall"], name_ko="태피스트리",
    variants={"bands": {}, "foliage": {"pat": "foliage"}, "hunt": {"pat": "hunt"}, "worn": {"pat": "hunt", "worn": True}, "torn": {"pat": "bands", "torn": True}})
def tapestry(k, pat="bands", worn=False, torn=False, seed=1):
    """막대에 건 큰 벽걸이 직물(폭 1.6칸) — 띠 · 덩굴 · 사냥 그림자 무늬. 밑 = z 0."""
    hw, hz, z0 = 0.78, 1.3, 0.12
    base, fn = PATTERNS[pat]
    m = k.mat("weave", _weave(base, fn, hw, hz, z0, worn, seed))
    cloth = lambda p: box(p + np.stack([p[:, 0] * 0, 0.012 * np.sin(p[:, 0] * 14), p[:, 0] * 0], 1), v3(0, -0.03, z0 + hz / 2), (hw, 0.008, hz / 2), 0.004)
    if torn:   # 오른쪽 아래가 찢겨 나가고 한 귀퉁이가 처졌다
        cloth = (lambda b: lambda p: np.maximum(b(p), (p[:, 0] - 0.2) * 0.9 - (p[:, 2] - z0 - 0.5) + (sdf.fbm(p, 0.08, seed, 3) - 0.5) * 0.25))(cloth)
    k.add(rough(cloth, 0.006, 0.1, seed), m)
    k.add(lambda p: hcyl(p, (-hw - 0.1, -0.05, z0 + hz + 0.03), (hw + 0.1, -0.05, z0 + hz + 0.03), 0.022), "wood_d")
    k.add(lambda p: np.minimum(sphere(p, v3(-hw - 0.11, -0.05, z0 + hz + 0.03), 0.035), sphere(p, v3(hw + 0.11, -0.05, z0 + hz + 0.03), 0.035)), "brass")
    for i in range(14):                                             # 아래 술
        x = -hw + 0.06 + i * (2 * hw - 0.12) / 13
        if torn and x > 0.15:
            continue
        k.add(lambda p, x=x: cap(p, v3(x, -0.03, z0 + 0.02), v3(x, -0.03, z0 - 0.07), 0.01), "rope")
    return {"shadow": 0.0}


@prop("wall_cloth", "interior", layer="wall_decal", cell=(1.6, 3.4), tags=["cloth", "decor", "wall"], name_ko="벽걸이 천",
    variants={"red": {}, "blue": {"col": "#34425a", "chev": True}, "faded": {"col": "#6a5a4a", "worn": True}})
def wall_cloth(k, col="#6a2e2a", chev=False, worn=False, seed=1):
    """좁고 긴 천 드림(아래 끝이 제비꼬리) — 가운데 띠 둘(또는 갈매기)."""
    hw, z0, z1 = 0.22, 0.05, 1.45

    def pat(x, z, c):
        if chev:
            m = np.abs(z - 0.9 - np.abs(x) * 0.8) < 0.04
        else:
            m = (np.abs(z - 1.15) < 0.035) | (np.abs(z - 0.95) < 0.02)
        return np.where(m[:, None], hexc("#a89468"), c)
    m = k.mat("drop", _weave(col, pat, hw, z1 - z0, z0, worn, seed))
    k.add(rough(lambda p: np.maximum(box(p, v3(0, -0.03, (z0 + z1) / 2), (hw, 0.008, (z1 - z0) / 2), 0.004), -(p[:, 2] - z0 - 0.2 + np.abs(p[:, 0]) * 0.9)), 0.005, 0.1, seed), m)
    k.add(lambda p: hcyl(p, (-hw - 0.06, -0.05, z1 + 0.02), (hw + 0.06, -0.05, z1 + 0.02), 0.018), "brass")
    return {"shadow": 0.0}


def _canvas(kind, seed):
    def fn(p, n):
        x, z = p[:, 0], p[:, 2]
        if kind == "landscape":
            c = np.tile(hexc("#7a8288"), (len(p), 1)) * (0.8 + (z - 0.4)[:, None] * 0.6)
            hill = z < 0.5 + 0.08 * np.sin(x * 9 + 1) + 0.04 * np.sin(x * 23)
            c = np.where(hill[:, None], hexc("#4e5a3a") * (0.8 + 0.3 * sdf.noise(p, 0.05, seed)[:, None]), c)
            near = z < 0.36 + 0.03 * np.sin(x * 15)
            c = np.where(near[:, None], hexc("#3a3220"), c)
            tree = (np.hypot(x + 0.12, (z - 0.5) * 0.8) < 0.07)
            c = np.where(tree[:, None], hexc("#2c3424"), c)
        elif kind == "still":
            c = np.tile(hexc("#2e2420"), (len(p), 1))
            table = z < 0.38
            c = np.where(table[:, None], hexc("#4a3424"), c)
            bowl = (np.hypot(x / 1.6, z - 0.42) < 0.07) & (z < 0.44)
            c = np.where(bowl[:, None], hexc("#8a7a5a"), c)
            for fx_, fz, col in ((-0.05, 0.47, "#8a3a2a"), (0.04, 0.48, "#9a7a3a"), (0.0, 0.52, "#6a2a3a")):
                c = np.where((np.hypot(x - fx_, z - fz) < 0.04)[:, None], hexc(col), c)
            jug = (np.abs(x - 0.17) < 0.05 + 0.02 * np.sin((z - 0.38) * 14)) & (z > 0.38) & (z < 0.6)
            c = np.where(jug[:, None], hexc("#5a5a52"), c)
        else:   # 얼굴 없는 반신 그림자
            c = np.tile(hexc("#3a3028"), (len(p), 1)) * (0.8 + 0.4 * np.clip(1 - np.hypot(x, z - 0.6) * 3, 0, 1))[:, None]
            body = (np.hypot(x / 1.7, (z - 0.3) / 1.0) < 0.14) | (np.hypot(x, z - 0.58) < 0.075)
            c = np.where(body[:, None], hexc("#1e1816"), c)
            collar = (np.abs(z - 0.45) < 0.012) & (np.abs(x) < 0.08)
            c = np.where(collar[:, None], hexc("#8a7a5a"), c)
        c = c * (1 + (sdf.noise(p, 0.012, seed) - 0.5) * 0.12)[:, None]
        return _out(c)
    return fn


@prop("painting", "interior", layer="wall_decal", cell=(1.8, 2.2), tags=["decor", "wall", "frame"], name_ko="그림 액자",
    variants={"landscape": {}, "still_life": {"kind": "still"}, "portrait": {"kind": "portrait", "tall": True}, "empty_frame": {"kind": "none"},
              "crooked": {"tilt": 0.14}, "slashed": {"slash": True}})
def painting(k, kind="landscape", tall=False, tilt=0.0, slash=False, seed=1):
    """금박 · 나무 틀의 그림(풍경 · 정물 · 얼굴 없는 반신 그림자). 밑 = z 0."""
    hw, hh = (0.24, 0.33) if tall else (0.36, 0.25)
    zc = 0.15 + hh
    T = (lambda p: rot_y(p, tilt, (0, 0, zc + hh))) if tilt else (lambda p: p)
    t = _X(k, T)
    frame_m = "gold" if kind in ("landscape", "portrait") else "wood_d"
    t.add(lambda p: sub(box(p, v3(0, -0.03, zc), (hw + 0.05, 0.025, hh + 0.05), 0.01), box(p, v3(0, -0.06, zc), (hw, 0.05, hh), 0.0)), frame_m)
    t.add(lambda p: sub(box(p, v3(0, -0.055, zc), (hw + 0.035, 0.008, hh + 0.035), 0.006), box(p, v3(0, -0.07, zc), (hw + 0.01, 0.05, hh + 0.01))), "brass" if frame_m == "gold" else "wood")
    if kind != "none":
        cv = k.mat("canvas", _canvas(kind, seed))
        if tilt:
            k.mats["canvas"] = (lambda m: lambda p, n: m(T(p), n))(k.mats["canvas"])
        if slash:   # 칼로 X자로 그었다 — 찢긴 틈이 검다
            t.add(lambda p: np.maximum(box(p, v3(0, -0.012, zc), (hw, 0.006, hh)), -np.minimum(np.abs((p[:, 0]) - (p[:, 2] - zc) * 1.1), np.abs((p[:, 0]) + (p[:, 2] - zc) * 1.1)) + 0.012), cv)
        else:
            t.add(lambda p: box(p, v3(0, -0.012, zc), (hw, 0.006, hh)), cv)
    if tilt:   # 걸린 못과 끈
        k.add(lambda p: sphere(p, v3(0, -0.01, zc + hh + 0.18), 0.012), "iron")
    return {"shadow": 0.0}


@prop("motif_plaque", "interior", layer="wall_decal", cell=(2.4, 1.8), tags=["decor", "wall", "carved"], name_ko="장식 문양판",
    variants={"rosette": {}, "parted_shield": {"kind": "shield"}, "frieze": {"kind": "frieze"}})
def motif_plaque(k, kind="rosette", seed=1):
    """벽에 붙인 새김 장식 — 꽃잎 둥근판 · 두 빛깔로 가른 빈 방패(문장 없음) · 기하 띠(가로로 이어 붙인다)."""
    if kind == "rosette":
        zc = 0.32
        k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - zc) - 0.28, np.abs(p[:, 1] + 0.02) - 0.02), "carved")
        k.add(lambda p: torus(rot_x(p, PI / 2, (0, -0.04, zc)), v3(0, -0.04, zc), 0.25, 0.018), "carved")
        for i in range(8):
            a = i * PI / 4
            k.add(lambda p, a=a: ell(p, v3(np.cos(a) * 0.14, -0.045, zc + np.sin(a) * 0.14), (0.06, 0.025, 0.06)), "stone_l")
        k.add(lambda p: sphere(p, v3(0, -0.05, zc), 0.055), "brass")
    elif kind == "shield":
        zc = 0.36

        def shape(p):
            x, z = p[:, 0], p[:, 2] - zc
            top = np.maximum(np.abs(x) - 0.22, z - 0.24)
            bottom = np.hypot(np.abs(x) + 0.12, z + 0.0) - 0.34
            return np.maximum(np.maximum(np.minimum(top, np.maximum(bottom, z)), -z - 0.3), np.abs(p[:, 1] + 0.03) - 0.03 + (1 - np.clip(1 - np.abs(x) / 0.25, 0, 1)) * 0.01)
        k.add(lambda p: np.maximum(shape(p), -p[:, 0]), "cloth_b")
        k.add(lambda p: np.maximum(shape(p), p[:, 0]), "linen")
        k.add(lambda p: np.maximum(np.abs(shape(p) + 0.012) - 0.012, -p[:, 1] - 0.075), "wood_d")
    else:
        k.add(lambda p: box(p, v3(0, -0.03, 0.12), (0.5, 0.03, 0.1), 0.006), "carved")
        for i in range(5):
            x = -0.4 + i * 0.2
            k.add(lambda p, x=x: np.maximum(np.abs(np.abs(p[:, 0] - x) + np.abs(p[:, 2] - 0.12)) - 0.07, np.abs(p[:, 1] + 0.065) - 0.012), "stone_l")
            k.add(lambda p, x=x: sphere(p, v3(x + 0.1, -0.065, 0.12), 0.018), "stone_l")
        return {"shadow": 0.0, "cell": (2.2, 1.2)}
    return {"shadow": 0.0}


@prop("wall_ornament", "interior", layer="wall_decal", cell=(2.4, 2.2), tags=["decor", "wall", "rustic"], name_ko="벽걸이 장식",
    variants={"oars": {}, "farm_tools": {"kind": "tools"}, "horseshoe": {"kind": "horseshoe"}, "wreath": {"kind": "wreath"}})
def wall_ornament(k, kind="oars", seed=1):
    zc = 0.5
    if kind == "oars":
        for s in (-1, 1):
            k.add(lambda p, s=s: cap(p, v3(-s * 0.45, -0.04, zc - 0.35), v3(s * 0.3, -0.04, zc + 0.25), 0.022), "wood_l")
            k.add(lambda p, s=s: ell(rot_y(p, s * 0.67, v3(s * 0.4, -0.04, zc + 0.33)), v3(s * 0.4, -0.04, zc + 0.33), (0.05, 0.012, 0.14)), "wood")
        k.add(lambda p: torus(rot_x(p, PI / 2, (0, -0.05, zc - 0.05)), v3(0, -0.05, zc - 0.05), 0.04, 0.012), "rope")
    elif kind == "tools":
        k.add(lambda p: cap(p, v3(-0.4, -0.04, zc - 0.35), v3(0.3, -0.04, zc + 0.3), 0.02), "wood_l")
        for i in (-1, 0, 1):
            k.add(lambda p, i=i: cap(p, v3(0.28 + i * 0.04, -0.04, zc + 0.28 - i * 0.04), v3(0.37 + i * 0.07, -0.04, zc + 0.42 - i * 0.02), 0.009), "rust")
        k.add(lambda p: cap(p, v3(0.4, -0.04, zc - 0.35), v3(-0.3, -0.04, zc + 0.3), 0.02), "wood_l")
        k.add(lambda p: box(rot_y(p, 0.75, v3(-0.32, -0.04, zc + 0.32)), v3(-0.32, -0.04, zc + 0.32), (0.14, 0.012, 0.02)), "wood")
        for i in range(5):
            k.add(lambda p, i=i: cap(rot_y(p, 0.75, v3(-0.32, -0.04, zc + 0.32)), v3(-0.44 + i * 0.06, -0.04, zc + 0.3), v3(-0.44 + i * 0.06, -0.04, zc + 0.24), 0.007), "wood")
    elif kind == "horseshoe":
        k.add(lambda p: np.maximum(torus(rot_x(p, PI / 2, (0, -0.03, zc)), v3(0, -0.03, zc), 0.11, 0.025), -(p[:, 2] - zc + 0.08)), "iron")
        for a in (-0.6, 0.0, 0.6, 2.5, 3.14, 3.8):
            k.add(lambda p, a=a: sphere(p, v3(np.sin(a) * 0.11, -0.055, zc + np.cos(a) * 0.11), 0.01), "steel")
        k.add(lambda p: sphere(p, v3(0, -0.02, zc + 0.16), 0.012), "iron")
        return {"shadow": 0.0, "cell": (1.2, 1.6)}
    else:
        rng = np.random.default_rng(seed)
        for i in range(22):
            a = i * 2 * PI / 22
            r = 0.2 + rng.uniform(-0.02, 0.02)
            k.add(rough(lambda p, a=a, r=r: ell(p, v3(np.cos(a) * r, -0.04, zc + np.sin(a) * r), (0.06, 0.03, 0.035)), 0.02, 0.05, seed + i), "leaf_dry" if i % 3 else "leaf")
        for a in (0.4, 1.9, 3.6, 5.0):
            k.add(lambda p, a=a: sphere(p, v3(np.cos(a) * 0.21, -0.07, zc + np.sin(a) * 0.21), 0.025), "shroom_r")
        k.add(lambda p: np.minimum(cap(p, v3(0, -0.07, zc - 0.21), v3(-0.06, -0.07, zc - 0.36), 0.015), cap(p, v3(0, -0.07, zc - 0.21), v3(0.05, -0.07, zc - 0.37), 0.015)), "cloth_r")
    return {"shadow": 0.0}


@prop("hunting_trophy", "interior", layer="wall_decal", cell=(2.4, 2.0), tags=["decor", "wall", "hunt", "bone"], name_ko="사냥 기념물",
    variants={"antlers": {}, "boar_head": {"kind": "boar"}, "fish": {"kind": "fish"}})
def hunting_trophy(k, kind="antlers", seed=1):
    """나무 방패판에 단 사슴뿔 · 멧돼지 머리 · 큰 물고기."""
    zc = 0.4
    if kind == "fish":
        k.add(lambda p: box(p, v3(0, -0.015, zc), (0.42, 0.015, 0.14), 0.02), "wood_d")
        k.add(rough(lambda p: smin(ell(p, v3(-0.03, -0.06, zc), (0.28, 0.04, 0.09)), cap(p, v3(0.22, -0.06, zc), v3(0.32, -0.05, zc), 0.03, 0.01), 0.04), 0.008, 0.05, seed), k.mat("scales", M.plain("#6a7068", 0.35, 0.03, 47)))
        k.add(lambda p: np.maximum(np.abs(p[:, 1] + 0.06) - 0.008, np.maximum(np.abs(p[:, 2] - zc) - 0.11 + (p[:, 0] - 0.32) * 0.9, 0.31 - p[:, 0])), "scales")
        k.add(lambda p: sphere(p, v3(-0.24, -0.09, zc + 0.02), 0.012), "void")
        return {"shadow": 0.0}
    k.add(lambda p: np.maximum(np.hypot(p[:, 0] / 1.0, (p[:, 2] - zc) / 1.25) - 0.16, np.abs(p[:, 1] + 0.02) - 0.02), "wood_d")
    k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0], (p[:, 2] - zc) / 1.25) - 0.15) - 0.012, np.abs(p[:, 1] + 0.045) - 0.006), "brass")
    if kind == "antlers":
        k.add(rough(lambda p: ell(p, v3(0, -0.06, zc - 0.02), (0.07, 0.05, 0.06)), 0.01, 0.05, seed), "bone_d")
        for s in (-1, 1):
            pts = [(0.04, zc + 0.02), (0.18, zc + 0.16), (0.24, zc + 0.36), (0.2, zc + 0.5)]
            for (a, b) in zip(pts, pts[1:]):
                k.add(lambda p, a=a, b=b, s=s: cap(p, v3(s * a[0], -0.07, a[1]), v3(s * b[0], -0.07, b[1]), 0.02, 0.014), "bone")
            for (bx, bz, ex, ez) in ((0.18, 0.16, 0.08, 0.3), (0.24, 0.36, 0.34, 0.46), (0.22, 0.28, 0.12, 0.4)):
                k.add(lambda p, bx=bx, bz=bz, ex=ex, ez=ez, s=s: cap(p, v3(s * bx, -0.07, zc + bz), v3(s * ex, -0.07, zc + ez), 0.013, 0.006), "bone")
        return {"shadow": 0.0, "cell": (2.4, 2.4)}
    hide = k.mat("bristle", M.plain("#3e3026", 0.5, 0.03, 48))
    k.add(rough(lambda p: smin(ell(p, v3(0, -0.12, zc), (0.13, 0.12, 0.12)), cap(p, v3(0, -0.12, zc - 0.02), v3(0, -0.3, zc - 0.07), 0.08, 0.055), 0.06), 0.02, 0.04, seed), hide)
    k.add(lambda p: cyl(rot_x(p, PI / 2, v3(0, -0.32, zc - 0.07)), v3(0, -0.32, zc - 0.07), 0.05, 0.02, 0.01), k.mat("snout", M.plain("#5a4440", 0.3, 0.05, 49)))
    for s in (-1, 1):
        k.add(lambda p, s=s: cap(p, v3(s * 0.04, -0.3, zc - 0.1), v3(s * 0.08, -0.33, zc - 0.01), 0.012, 0.004), "bone")
        k.add(lambda p, s=s: ell(p, v3(s * 0.1, -0.09, zc + 0.12), (0.035, 0.02, 0.06)), hide)
        k.add(lambda p, s=s: sphere(p, v3(s * 0.06, -0.21, zc + 0.04), 0.013), "void")
    return {"shadow": 0.0}


@prop("pelt_rug", "interior", layer="decal", cell=(3.2, 2.4), tags=["decor", "floor", "hunt", "fur"], name_ko="짐승 가죽 깔개",
    variants={"bear": {}, "wolf": {"col": "#6a665e", "s": 0.8}})
def pelt_rug(k, col="#4a3626", s=1.0, seed=1):
    """바닥에 편 곰 · 늑대 가죽(머리 · 네 다리 · 꼬리)."""
    fur = k.mat("pelt", M.plain(col, 0.55, 0.035, 50))

    def shape(p):
        x, y = p[:, 0] / s, p[:, 1] / s
        d = np.hypot(x / 0.55, y / 0.36) - 1.0
        for lx, ly in ((0.48, 0.36), (-0.48, 0.36), (0.44, -0.36), (-0.44, -0.36)):
            d = np.minimum(d, (np.hypot((x - lx) / 0.14, (y - ly) / 0.1) - 1.0))
        d = np.minimum(d, np.hypot((x + 0.68) / 0.06, y / 0.05) - 1.0)
        return d * 0.12 * s + (sdf.noise(p, 0.05, seed) - 0.5) * 0.03
    k.add(lambda p: np.maximum(shape(p), np.abs(p[:, 2] - 0.012) - 0.012), fur)
    k.add(rough(lambda p: smin(ell(p, v3(0.62 * s, 0, 0.05 * s), (0.14 * s, 0.12 * s, 0.07 * s)), ell(p, v3(0.76 * s, 0, 0.04 * s), (0.08 * s, 0.06 * s, 0.045 * s)), 0.04), 0.012, 0.04, seed), fur)
    for sy in (-1, 1):
        k.add(lambda p, sy=sy: ell(p, v3(0.58 * s, sy * 0.09 * s, 0.11 * s), (0.03, 0.025, 0.035)), fur)
        k.add(lambda p, sy=sy: sphere(p, v3(0.71 * s, sy * 0.045 * s, 0.08 * s), 0.012), "void")
    return {"shadow": 0.25}


@prop("pennant_row", "interior", layer="wall_decal", cell=(3.4, 1.4), tags=["cloth", "decor", "wall", "festive"], name_ko="벽 깃발 줄",
    variants={"bright": {}, "faded": {"faded": True}, "torn": {"torn": True}})
def pennant_row(k, faded=False, torn=False, seed=1):
    """벽에 걸쳐 늘어진 세모 깃발 줄(폭 2.4칸)."""
    zt = 0.55
    sag = lambda x: zt - 0.12 * (1 - (x / 1.2) ** 2)
    k.add(lambda p: np.maximum(np.abs(p[:, 2] - sag(p[:, 0])) - 0.008, np.maximum(np.abs(p[:, 1] + 0.03) - 0.008, np.abs(p[:, 0]) - 1.2)), "rope")
    cols = ["cloth_r", "linen", "cloth_b", "cloth_g", "linen"] if not faded else ["linen", "cloth", "linen", "cloth"]
    for i in range(9):
        x = -1.05 + i * 0.26
        if torn and i in (3, 6):
            continue
        z0 = sag(x)
        ln = 0.2 if not (torn and i == 5) else 0.11
        k.add(lambda p, x=x, z0=z0, ln=ln: np.maximum(np.maximum(np.abs(p[:, 0] - x) - (p[:, 2] - z0 + ln) * 0.45, p[:, 2] - z0 + 0.005), np.maximum(np.abs(p[:, 1] + 0.03) - 0.006, z0 - ln - p[:, 2])), cols[i % len(cols)])
    return {"shadow": 0.0}


@prop("plate_rack", "interior", layer="wall_decal", cell=(2.6, 1.8), tags=["wood", "kitchen", "decor", "wall"], name_ko="장식 접시 걸이",
    variants={"full": {}, "sparse": {"n": 2}})
def plate_rack(k, n=5, seed=1):
    """벽 선반에 세워 둔 무늬 접시들(앞 막대가 받친다)."""
    zb = 0.12
    k.add(lambda p: box(p, v3(0, -0.07, zb), (0.62, 0.07, 0.018), 0.005), "plank_x")
    k.add(lambda p: box(p, v3(0, -0.13, zb + 0.07), (0.6, 0.008, 0.008)), "wood_d")
    for x in (-0.55, 0.55):
        k.add(lambda p, x=x: np.minimum(box(p, v3(x, -0.01, zb - 0.06), (0.02, 0.012, 0.08)), cap(p, v3(x, -0.02, zb - 0.12), v3(x, -0.12, zb - 0.02), 0.014)), "wood_d")
    glaze = k.mat("plate_glaze", _plate_glaze(seed))
    xs = [-0.44, -0.22, 0.0, 0.22, 0.44][:n] if n == 5 else [-0.3, 0.2]
    for i, x in enumerate(xs):
        r = 0.1 if i % 2 == 0 else 0.085
        k.add(lambda p, x=x, r=r: np.maximum(np.hypot(p[:, 0] - x, p[:, 2] - zb - 0.02 - r) - r, np.abs(rot_x(p, -0.2, v3(x, -0.06, zb + r))[:, 1] + 0.06) - 0.01), glaze)
    return {"shadow": 0.0}


def _plate_glaze(seed):
    def fn(p, n):
        r = np.hypot((p[:, 0] * 10) % 2.2 - 1.1, p[:, 2] * 0 + 0)  # 접시마다 다른 자리는 x로만 — 고리 무늬
        cx = np.round(p[:, 0] / 0.22) * 0.22
        rr = np.hypot(p[:, 0] - cx, p[:, 2] - 0.24)
        c = np.tile(hexc("#b4aa92"), (len(p), 1))
        ring = (np.abs(rr - 0.075) < 0.01) | (np.abs(rr - 0.03) < 0.008)
        c = np.where(ring[:, None], hexc("#34425a"), c)
        return _out(c * (0.9 + 0.2 * sdf.noise(p, 0.03, seed))[:, None])
    return fn


def _pot(k, r=0.13, h=0.22, mat="terra"):
    k.mat("terra", M.plain("#7a4a34", 0.3, 0.08, 51))
    k.add(lambda p: sub(_frustum(p, v3(0, 0, 0), r * 0.72, r, h), cyl(p, v3(0, 0, h - 0.03), r - 0.02, 0.1)), mat)
    k.add(lambda p: torus(p, v3(0, 0, h - 0.01), r + 0.005, 0.02), mat)
    k.add(lambda p: cyl(p, v3(0, 0, h - 0.06), r - 0.02, 0.04), "dirt")


@prop("potted_plant", "interior", cell=(2, 2.8), collide=(0.36, 0.3), tags=["plant", "decor", "clay"], name_ko="실내 화분",
    variants={"fern": {}, "tree": {"kind": "tree"}, "dead": {"kind": "dead"}})
def potted_plant(k, kind="fern", seed=1):
    _pot(k)
    rng = np.random.default_rng(seed)
    if kind == "fern":
        for i in range(11):
            a = i * 2 * PI / 11 + rng.uniform(-0.2, 0.2)
            ln = rng.uniform(0.32, 0.45)
            mid = v3(np.cos(a) * ln * 0.45, np.sin(a) * ln * 0.4, 0.38)
            tip = v3(np.cos(a) * ln, np.sin(a) * ln * 0.85, 0.2 + rng.uniform(0, 0.12))
            k.add(lambda p, mid=mid, tip=tip: np.minimum(cap(p, v3(0, 0, 0.18), mid, 0.03, 0.04), cap(p, mid, tip, 0.04, 0.01)), "leaf")
    elif kind == "tree":
        k.add(lambda p: cap(p, v3(0, 0, 0.18), v3(0.02, 0.0, 0.7), 0.025, 0.018), "wood_d")
        for c, r in ((v3(0, 0, 0.82), 0.2), (v3(-0.12, 0.02, 0.72), 0.13), (v3(0.13, -0.02, 0.74), 0.13), (v3(0.02, 0, 0.98), 0.12)):
            k.add(rough(lambda p, c=c, r=r: sphere(p, c, r), 0.06, 0.06, seed), "leaf")
    else:
        for i in range(6):
            a = i * 1.1
            tip = v3(np.cos(a) * 0.14, np.sin(a) * 0.1, 0.4 + (i % 3) * 0.1)
            k.add(lambda p, tip=tip: cap(p, v3(0, 0, 0.18), tip, 0.012, 0.004), "leaf_dry")
        k.rubble([(0.18, -0.12), (-0.2, -0.08)], "leaf_dry", 0.02, 0.035)
    return {}


@prop("hanging_pot", "interior", layer="over", cell=(1.6, 3.2), tags=["plant", "decor", "clay"], name_ko="걸이 화분",
    variants={"vines": {}, "dry": {"dry": True}})
def hanging_pot(k, dry=False, seed=1):
    """들보에 사슬로 단 화분 — 늘어진 덩굴. 원점 = 바닥 자리(화분은 높이 1.6에 뜬다)."""
    z = 1.6
    k.mat("terra", M.plain("#7a4a34", 0.3, 0.08, 51))
    k.add(lambda p: sub(ell(p, v3(0, 0, z), (0.12, 0.12, 0.09)), cyl(p, v3(0, 0, z + 0.02), 0.1, 0.2)), "terra")
    for a in (0.5, 2.6, 4.7):
        k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.11, np.sin(a) * 0.11, z + 0.04), v3(0, 0, z + 0.55), 0.006), "iron")
    rng = np.random.default_rng(seed)
    for i in range(7):
        a = i * 0.9
        x0, y0 = np.cos(a) * 0.1, np.sin(a) * 0.08
        ln = rng.uniform(0.15, 0.45)
        k.add(lambda p, x0=x0, y0=y0, ln=ln: cap(p, v3(x0, y0, z + 0.05), v3(x0 * 1.6, y0 * 1.4 - 0.03, z - ln), 0.022 if not dry else 0.008, 0.01 if not dry else 0.004), "leaf_dry" if dry else "leaf")
    return {"shadow": 0.0}


# ── 항아리 · 잔 · 음식 · 작은 장식품 ─────────────────────────────────────────────

def _jar_mat(k):
    k.mat("terra", M.plain("#7a4a34", 0.3, 0.08, 51))
    return k.mat("glaze_g", M.plain("#4a5a50", 0.3, 0.1, 52))


def _cracks_mat(base, seed):
    b = hexc(base)

    def fn(p, n):
        c = np.tile(b, (len(p), 1)) * (0.85 + 0.3 * sdf.fbm(p, 0.08, seed, 2))[:, None]
        line = np.abs(sdf.fbm(p * np.array([2.5, 2.5, 0.6], F), 0.12, seed + 4, 2) - 0.5) < 0.018
        c = np.where(line[:, None], hexc("#1a1210"), c)
        return _out(c)
    return fn


def _jar(k, x, y, s=1.0, mat="terra"):
    k.add(lambda p: smin(ell(p, v3(x, y, 0.2 * s), (0.15 * s, 0.15 * s, 0.19 * s)), cap(p, v3(x, y, 0.3 * s), v3(x, y, 0.42 * s), 0.07 * s, 0.06 * s), 0.05 * s), mat)
    k.add(lambda p: torus(p, v3(x, y, 0.42 * s), 0.065 * s, 0.018 * s), mat)


@prop("storage_jar", "interior", cell=(2, 2.4), collide=(0.4, 0.34), tags=["clay", "container", "kitchen"], name_ko="저장 항아리",
    variants={"jar": {}, "amphora": {"kind": "amphora"}, "crock": {"kind": "crock"}, "group": {"kind": "group"}, "cracked": {"kind": "cracked"}, "broken": {"kind": "broken"}},
    interact="container")
def storage_jar(k, kind="jar", seed=1):
    """곡식 · 기름 · 술을 담는 항아리 — 배 불룩한 항아리 · 손잡이 둘 긴 단지(받침 고리) · 뚜껑 덮은 독 · 무리 · 금 간 · 깨진."""
    glaze = _jar_mat(k)
    if kind == "jar":
        _jar(k, 0, 0)
    elif kind == "amphora":
        k.add(lambda p: torus(p, v3(0, 0, 0.04), 0.09, 0.022), "iron")
        k.add(lambda p: smin(smin(ell(p, v3(0, 0, 0.32), (0.13, 0.13, 0.22)), cap(p, v3(0, 0, 0.12), v3(0, 0, 0.03), 0.06, 0.02), 0.05), cap(p, v3(0, 0, 0.48), v3(0, 0, 0.66), 0.05, 0.045), 0.04), "terra")
        for s in (-1, 1):
            k.add(lambda p, s=s: np.maximum(ring_x(p, v3(s * 0.08, 0, 0.58), 0.06, 0.013), -s * (p[:, 0] - s * 0.06)), "terra")
    elif kind == "crock":
        k.add(lambda p: smin(cyl(p, v3(0, 0, 0), 0.14, 0.3, 0.04), torus(p, v3(0, 0, 0.29), 0.13, 0.018), 0.02), glaze)
        k.add(lambda p: smin(cyl(p, v3(0, 0, 0.3), 0.13, 0.03, 0.01), sphere(p, v3(0, 0, 0.35), 0.03), 0.02), "wood")
        k.add(lambda p: torus(p, v3(0, 0, 0.2), 0.143, 0.01), "iron")
    elif kind == "group":
        _jar(k, -0.2, 0.08, 1.0)
        _jar(k, 0.18, 0.12, 0.8, glaze)
        k.add(lambda p: smin(cyl(p, v3(0.04, -0.18, 0), 0.08, 0.16, 0.03), torus(p, v3(0.04, -0.18, 0.16), 0.075, 0.012), 0.02), "terra")
        return {"cell": (2.4, 2.4)}
    elif kind == "cracked":
        cm = k.mat("terra_cracked", _cracks_mat("#7a4a34", seed))
        _jar(k, 0, 0, 1.0, cm)
    else:   # 깨진: 아랫도리만 남고 조각 · 쏟아진 곡식
        k.add(lambda p: np.maximum(sub(ell(p, v3(0, 0, 0.2), (0.15, 0.15, 0.19)), ell(p, v3(0, 0, 0.2), (0.13, 0.13, 0.17))), p[:, 2] - 0.18 - (sdf.fbm(p, 0.05, seed, 2) - 0.5) * 0.18), "terra")
        rng = np.random.default_rng(seed)
        for i in range(6):
            x, y = rng.uniform(-0.4, 0.4), rng.uniform(-0.35, -0.1)
            a = rng.uniform(0, PI)
            k.add(lambda p, x=x, y=y, a=a: np.maximum(sub(sphere(rot_z(p, a, (x, y, 0)), v3(x, y + 0.1, 0.0), 0.14), sphere(rot_z(p, a, (x, y, 0)), v3(x, y + 0.12, 0.0), 0.125)), np.abs(rot_z(p, a, (x, y, 0))[:, 0] - x) - 0.06), "terra")
        k.add(lambda p: pool(p, v3(0.1, -0.3, 0.01), 0.26, 0.12, 0.012) + (sdf.noise(p, 0.04, seed) - 0.5) * 0.04, k.mat("grain", M.plain("#9a8256", 0.4, 0.02, 53)))
    return {}


@prop("drinkware", "interior", cell=(1.6, 1.4), tags=["kitchen", "dining", "small"], name_ko="잔",
    variants={"tankards": {}, "goblets": {"kind": "goblets"}, "cups": {"kind": "cups"}, "toppled": {"kind": "toppled"}})
def drinkware(k, kind="tankards", seed=1):
    """탁자 위 크기의 잔(실제 크기 — 탁자에 얹을 때 z 보정) — 나무 맥주잔 · 쇠 굽잔 · 질그릇 잔 · 쓰러져 쏟아진 잔."""
    if kind == "tankards":
        for x, y in ((-0.07, 0.0), (0.08, 0.04)):
            k.add(lambda p, x=x, y=y: sub(cyl(p, v3(x, y, 0), 0.045, 0.12, 0.01), cyl(p, v3(x, y, 0.02), 0.035, 0.2)), "wood")
            k.add(lambda p, x=x, y=y: np.minimum(torus(p, v3(x, y, 0.03), 0.046, 0.007), torus(p, v3(x, y, 0.1), 0.046, 0.007)), "iron")
            k.add(lambda p, x=x, y=y: np.maximum(ring_x(p, v3(x + 0.05, y, 0.065), 0.035, 0.01), x + 0.04 - p[:, 0]), "wood_d")
            k.add(lambda p, x=x, y=y: cyl(p, v3(x, y, 0.1), 0.036, 0.02), k.mat("ale", M.plain("#c8b48a", 0.3, 0.03, 54)))
    elif kind == "goblets":
        for x, y in ((-0.06, 0.0), (0.07, 0.03)):
            k.add(lambda p, x=x, y=y: smin(smin(cyl(p, v3(x, y, 0), 0.04, 0.01, 0.004), cap(p, v3(x, y, 0.01), v3(x, y, 0.08), 0.008), 0.01),
                sub(_frustum(p, v3(x, y, 0.08), 0.015, 0.045, 0.07), cyl(p, v3(x, y, 0.1), 0.038, 0.1)), 0.01), "brass")
    elif kind == "cups":
        for x, y in ((-0.08, 0.0), (0.0, 0.06), (0.08, -0.01)):
            _cup(k, x, y, 0.0, 0.032, 0.06, "glaze_c" if k.mat("glaze_c", M.plain("#8a6a50", 0.3, 0.06, 55)) else "terra", False)
    else:
        k.add(lambda p: sub(cyl(rot_y(p, PI / 2, (0, 0, 0.045)), v3(0, 0, -0.015), 0.045, 0.12, 0.01), cyl(rot_y(p, PI / 2, (0, 0, 0.045)), v3(0, 0, 0.005), 0.035, 0.2)), "wood")
        k.add(lambda p: np.minimum(torus(rot_y(p, PI / 2, (0, 0, 0.045)), v3(0, 0, 0.015), 0.046, 0.007), torus(rot_y(p, PI / 2, (0, 0, 0.045)), v3(0, 0, 0.085), 0.046, 0.007)), "iron")
        k.add(lambda p: pool(p, v3(-0.17, -0.03, 0.004), 0.12, 0.07, 0.004) + (sdf.noise(p, 0.03, seed) - 0.5) * 0.02, k.mat("spill", M.plain("#4a3020", 0.3, 0.05, 56)))
    return {}


@prop("served_food", "interior", cell=(1.8, 1.4), tags=["food", "kitchen", "dining", "small"], name_ko="차린 음식",
    variants={"loaves": {}, "cheese": {"kind": "cheese"}, "roast": {"kind": "roast"}, "fruit": {"kind": "fruit"}, "pie": {"kind": "pie"}})
def served_food(k, kind="loaves", seed=1):
    """탁자 위 크기의 음식(실제 크기) — 도마의 빵 · 치즈 덩이 · 구운 고기 접시 · 과일 그릇 · 파이."""
    crust = k.mat("crust", M.plain("#8a5e32", 0.35, 0.04, 57))
    if kind == "loaves":
        k.add(lambda p: box(p, v3(0, 0, 0.012), (0.17, 0.1, 0.012), 0.006), "wood_l")
        k.add(rough(lambda p: ell(p, v3(-0.05, 0.0, 0.05), (0.09, 0.055, 0.04)), 0.006, 0.03, seed), crust)
        k.add(rough(lambda p: ell(p, v3(0.09, 0.03, 0.045), (0.05, 0.05, 0.035)), 0.006, 0.03, seed + 1), crust)
        for i in range(3):
            k.add(lambda p, i=i: box(rot_z(p, 0.5, (0.0, 0, 0)), v3(-0.07 + i * 0.03, -0.0, 0.088), (0.006, 0.03, 0.004)), "coal")
    elif kind == "cheese":
        ch = k.mat("cheese", M.plain("#c8a85a", 0.25, 0.04, 58))
        wedge = lambda q: np.maximum(-q[:, 0], q[:, 1])                       # x > 0 · y < 0 쪽 부채꼴
        k.add(lambda p: sub(cyl(p, v3(0, 0, 0), 0.12, 0.07, 0.015), wedge(p)), ch)
        k.add(lambda p: np.maximum(cyl(p - v3(0.07, -0.08, 0), v3(0, 0, 0), 0.12, 0.06, 0.01), wedge(p - v3(0.07, -0.08, 0)) + 0.0), ch)
    elif kind == "roast":
        _plate(k, 0, 0, 0, 0.16, "steel")
        k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.06), (0.1, 0.07, 0.055)), np.minimum(cap(p, v3(0.06, 0.03, 0.06), v3(0.14, 0.06, 0.04), 0.02), cap(p, v3(0.06, -0.03, 0.06), v3(0.14, -0.06, 0.04), 0.02)), 0.02), 0.008, 0.03, seed), k.mat("roast", M.plain("#6a3a1e", 0.4, 0.03, 59)))
        k.add(lambda p: np.minimum(sphere(p, v3(0.15, 0.065, 0.04), 0.012), sphere(p, v3(0.15, -0.065, 0.04), 0.012)), "bone")
        for x, y in ((-0.11, 0.06), (-0.12, -0.05)):
            k.add(lambda p, x=x, y=y: sphere(p, v3(x, y, 0.035), 0.022), "leaf")
    elif kind == "fruit":
        k.add(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.06, 0.13, 0.06), _frustum(p, v3(0, 0, 0.015), 0.05, 0.12, 0.08)), "wood_l")
        rng = np.random.default_rng(seed)
        cols = [k.mat("apple", M.plain("#8a3028", 0.3, 0.04, 60)), k.mat("pear", M.plain("#8a8a3e", 0.3, 0.04, 61)), k.mat("plum", M.plain("#4a2a40", 0.3, 0.04, 62))]
        for i, (x, y, z) in enumerate(((-0.05, 0.0, 0.07), (0.04, 0.03, 0.07), (0.0, -0.05, 0.07), (0.01, 0.0, 0.11), (0.07, -0.04, 0.065))):
            k.add(lambda p, x=x, y=y, z=z: sphere(p, v3(x, y, z), 0.037), cols[i % 3])
    else:
        _plate(k, 0, 0, 0, 0.14, "steel")
        k.add(lambda p: smin(_frustum(p, v3(0, 0, 0.02), 0.1, 0.115, 0.04), ell(p, v3(0, 0, 0.06), (0.11, 0.11, 0.02)), 0.02), crust)
        for i in range(-2, 3):
            k.add(lambda p, i=i: np.minimum(cap(p, v3(i * 0.04, -0.09, 0.075), v3(i * 0.04, 0.09, 0.075), 0.008), cap(p, v3(-0.09, i * 0.04, 0.078), v3(0.09, i * 0.04, 0.078), 0.008)) + np.maximum(np.hypot(p[:, 0], p[:, 1]) - 0.1, 0), crust)
        k.add(lambda p: np.maximum(box(p, v3(0.07, -0.02, 0.05), (0.04, 0.05, 0.03)), -np.maximum(p[:, 0] - 0.04, 0)), k.mat("filling", M.plain("#5a2030", 0.3, 0.03, 63)))
    return {}


@prop("trinket", "interior", cell=(1.2, 1.4), tags=["decor", "small"], name_ko="작은 장식품",
    variants={"vase": {}, "figurine": {"kind": "figurine"}, "hourglass": {"kind": "hourglass"}, "box": {"kind": "box"}})
def trinket(k, kind="vase", seed=1):
    """선반 · 탁자에 얹는 장식품(실제 크기) — 꽃 꽂은 병 · 말 조각 · 모래시계 · 작은 함."""
    if kind == "vase":
        k.add(lambda p: smin(ell(p, v3(0, 0, 0.07), (0.05, 0.05, 0.07)), cap(p, v3(0, 0, 0.12), v3(0, 0, 0.18), 0.022, 0.03), 0.02), k.mat("glaze_b", M.plain("#3e4e66", 0.3, 0.06, 64)))
        for a, c in ((0.3, "shroom_r"), (2.0, "wax"), (4.0, "shroom_r")):
            tip = v3(np.cos(a) * 0.05, np.sin(a) * 0.03, 0.27)
            k.add(lambda p, tip=tip: cap(p, v3(0, 0, 0.16), tip, 0.005), "leaf")
            k.add(lambda p, tip=tip: sphere(p, tip, 0.018), c)
    elif kind == "figurine":   # 받침 위 서 있는 작은 말(짐승) 조각
        k.add(lambda p: box(p, v3(0, 0, 0.015), (0.07, 0.04, 0.015), 0.004), "wood_d")
        k.add(lambda p: smin(smin(ell(p, v3(0, 0, 0.09), (0.05, 0.025, 0.025)), cap(p, v3(0.04, 0, 0.1), v3(0.06, 0, 0.14), 0.015, 0.012), 0.015),
            ell(p, v3(0.07, 0, 0.145), (0.022, 0.013, 0.012)), 0.01), "bronze")
        for x in (-0.035, 0.03):
            for y in (-0.012, 0.012):
                k.add(lambda p, x=x, y=y: cap(p, v3(x, y, 0.08), v3(x, y, 0.03), 0.007), "bronze")
    elif kind == "hourglass":
        for z in (0.0, 0.17):
            k.add(lambda p, z=z: cyl(p, v3(0, 0, z), 0.05, 0.015, 0.004), "wood_d")
        for a in (0.8, 2.9, 5.0):
            k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.042, np.sin(a) * 0.042, 0.01), v3(np.cos(a) * 0.042, np.sin(a) * 0.042, 0.18), 0.006), "wood_d")
        k.add(lambda p: smin(ell(p, v3(0, 0, 0.055), (0.03, 0.03, 0.04)), ell(p, v3(0, 0, 0.13), (0.03, 0.03, 0.04)), 0.01), "glass")
        k.add(lambda p: ell(p, v3(0, 0, 0.03), (0.024, 0.024, 0.016)), "sand")
    else:
        k.add(lambda p: box(p, v3(0, 0, 0.035), (0.07, 0.045, 0.035), 0.006), "wood_l")
        k.add(lambda p: box(p, v3(0, 0, 0.074), (0.072, 0.047, 0.008), 0.004), "wood_d")
        k.add(lambda p: np.minimum(box(p, v3(0, -0.047, 0.05), (0.012, 0.004, 0.014)), np.minimum(box(p, v3(-0.07, 0, 0.035), (0.004, 0.047, 0.006)), box(p, v3(0.07, 0, 0.035), (0.004, 0.047, 0.006)))), "brass")
    return {}
