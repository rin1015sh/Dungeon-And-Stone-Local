"""도시 거리 살림 · 장식 2(도시 라이브러리 AM69 — 묶음 그림 city_life): 화분 · 창가 꽃상자 · 가로수(돌 테 · 나무 울) · 다듬은 관목 울타리 ·
낙엽 · 버려진 물건 더미 · 물지게 · 빨래 함지 · 건초 더미 · 말뚝(말 매는) · 빗물 통 · 닭장.
나무 · 덤불 · 풀 재질은 a_flora와 같다(같은 잎 · 껍질 색)."""
import numpy as np

import sdf
import trees as T
from a_city_life import _p, _wheel  # noqa: F401
from a_flora import _mats as _flora_mats
from a_furniture import _barrel, _frustum, _planks
from kit import (F, box, cap, cone, cyl, ell, flat, hcyl, pool, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401

PI = np.pi


def _clay(k):
    import mats as M
    k.mat("clay", M.plain("#7a4e36", 0.3, 0.12, 40))
    k.mat("clay_d", M.plain("#5a3828", 0.3, 0.12, 41))
    k.mat("soil", M.plain("#2e2620", 0.4, 0.06, 42))
    k.mat("hedge", M.leaf("#34522a", 0.16, 43, 0.06))
    k.mat("hedge_d", M.leaf("#2a4224", 0.16, 44, 0.04))
    k.mat("hay", M.plain("#9a8650", 0.4, 0.04, 45))
    k.mat("hay_d", M.plain("#6e5e38", 0.4, 0.04, 46))
    _flora_mats(k, k.seed)


def _pot(k, x, y, r, h, mat="clay", broken=False, seed=1):
    body = lambda p: _frustum(p, v3(x, y, 0), r * 0.72, r, h)
    rim = lambda p: torus(p, v3(x, y, h), r * 0.98, 0.02)
    if broken:
        cut = lambda p: p[:, 2] - h * 0.55 - (sdf.fbm(p, 0.06, seed, 2) - 0.5) * 0.2 - p[:, 0] * 0.5
        k.add(lambda p: np.maximum(sub(body(p), cyl(p, v3(x, y, 0.03), r * 0.6, h)), cut(p)), mat)
        for i, (dx, dy, a) in enumerate(((0.22, -0.12, 0.5), (-0.2, -0.16, -0.8), (0.05, -0.26, 1.6))):
            k.add(lambda p, dx=dx, dy=dy, a=a: box(rot_z(p, a, (x + dx, y + dy, 0)), v3(x + dx, y + dy, 0.015), (0.06, 0.035, 0.012), 0.006), mat)
        k.add(lambda p: ell(p, v3(x + 0.12, y - 0.06, 0.0), (0.18, 0.1, 0.05)), "soil")
        return
    k.add(lambda p: np.minimum(sub(body(p), cyl(p, v3(x, y, h - 0.05), r * 0.85, 0.2)), rim(p)), mat)
    k.add(lambda p: cyl(p, v3(x, y, 0), r * 0.86, h - 0.03), "soil")


def _tuft(cs, r, seed):
    """작은 잎 덩이(화분용 — 나무 머리 crown_fn은 덩이를 멀리 흩어 화분에는 너무 크다)."""
    def fn(p):
        d = None
        for c in cs:
            di = sdf.length((p - c) * np.array([1, 1, 1.25], F)) - r
            d = di if d is None else smin(d, di, 0.05)
        return d + (sdf.fbm(p, 0.05, seed, 2) - 0.5) * r * 0.6
    return fn


def _plant(k, x, y, z, kind, rng, s=1.0):
    if kind == "flowers":
        cs = [v3(x + rng.uniform(-0.12, 0.12) * s, y + rng.uniform(-0.06, 0.06), z + rng.uniform(0.06, 0.16) * s) for _ in range(5)]
        k.add(_tuft(cs, 0.07 * s, int(rng.integers(99))), "leaf_a")
        for c in cs:
            for _ in range(3):
                q = c + v3(rng.uniform(-0.08, 0.08), -0.09, rng.uniform(0.0, 0.08)) * s
                k.add(lambda p, q=q: sphere(p, q, 0.028 * s), ("petal_r", "petal_y", "petal_v", "petal_w")[int(rng.integers(4))])
    elif kind == "herb":
        for i in range(9):
            a = rng.uniform(0, 2 * PI)
            tip = v3(x + np.cos(a) * 0.12 * s, y + np.sin(a) * 0.06, z + rng.uniform(0.18, 0.3) * s)
            k.add(lambda p, tip=tip: cap(p, v3(x, y, z), tip, 0.022, 0.006), "grass")
    elif kind == "shrub":
        cs = [v3(x + rng.uniform(-0.1, 0.1) * s, y + rng.uniform(-0.05, 0.05), z + rng.uniform(0.12, 0.3) * s) for _ in range(5)]
        k.add(_tuft(cs, 0.11 * s, int(rng.integers(99))), "leaf_a")
    elif kind == "dead":
        for i in range(5):
            a = rng.uniform(0, 2 * PI)
            tip = v3(x + np.cos(a) * 0.14 * s, y + np.sin(a) * 0.06, z + rng.uniform(0.14, 0.26) * s)
            k.add(lambda p, tip=tip: cap(p, v3(x, y, z), tip, 0.012, 0.004), "bark_dry")


@_p("planter", "화분", (2, 2), tags=["city", "decor", "plant", "ornament"],
    variants={"flowers": {"kind": "flowers"}, "herb": {"kind": "herb"}, "shrub": {"kind": "shrub", "big": True}, "empty": {"kind": None}, "dead": {"kind": "dead"},
              "broken": {"kind": "flowers", "broken": True}, "group": {"kind": "group"}})
def planter(k, kind="flowers", big=False, broken=False, seed=1):
    """흙 화분(문간 · 창 아래 · 계단 옆). group = 크기가 다른 셋."""
    _clay(k)
    rng = k.rng
    if kind == "group":
        for x, y, r, h, kd in ((-0.24, 0.06, 0.15, 0.26, "shrub"), (0.12, 0.1, 0.12, 0.2, "flowers"), (0.3, -0.12, 0.09, 0.15, "herb")):
            _pot(k, x, y, r, h, "clay" if kd != "herb" else "clay_d")
            _plant(k, x, y, h, kd, rng, r / 0.15)
        return {"shadow": 0.4}
    r, h = (0.24, 0.4) if big else (0.18, 0.3)
    _pot(k, 0, 0, r, h, broken=broken, seed=seed)
    if kind and not broken:
        _plant(k, 0, 0, h, kind, rng, 1.5 if big else 1.6)  # 화분이 작아 잎 · 꽃을 키운다
    elif broken:
        _plant(k, 0.14, -0.08, 0.04, "flowers", rng, 0.8)
    return {"shadow": 0.4}


@_p("flower_box", "창가 꽃상자", (2, 2), layer="wall_decal", tags=["city", "decor", "plant", "ornament"],
    variants={"flowers": {"kind": "flowers"}, "herb": {"kind": "herb"}, "dead": {"kind": "dead"}, "empty": {"kind": None}})
def flower_box(k, kind="flowers", seed=1):
    """창턱 밑에 거는 나무 꽃상자(벽 밑동 원점 — 세트에서 up으로 창 높이까지 올린다)."""
    _clay(k)
    k.add(rough(lambda p: sub(box(p, v3(0, 0.02, 0.1), (0.38, 0.09, 0.08), 0.01), box(p, v3(0, 0.02, 0.2), (0.35, 0.065, 0.1))), 0.01, 0.2, seed), "plank_x")
    k.add(lambda p: box(p, v3(0, 0.02, 0.16), (0.35, 0.065, 0.02)), "soil")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: box(p, v3(sx * 0.3, 0.06, 0.02), (0.02, 0.05, 0.05)), "iron")
    if kind:
        rng = k.rng
        for x in (-0.24, -0.08, 0.08, 0.24):
            _plant(k, x, 0.02, 0.17, kind, rng, 0.75)
    return {"shadow": 0.2}


@_p("street_tree", "가로수", (3, 4), collide=(0.5, 0.4), tags=["city", "tree", "plant", "ornament"],
    variants={"ring": {"guard": "ring"}, "guard": {"guard": "fence"}, "trimmed": {"guard": "ring", "trim": True}, "bare": {"guard": "ring", "bare": True}})
def street_tree(k, guard="ring", trim=False, bare=False, seed=1):
    """길가에 심은 어린 나무: 돌 테두리(ring) · 나무 울(fence). trimmed = 둥글게 다듬은 머리, bare = 잎 진 겨울."""
    _clay(k)
    rng = np.random.default_rng(seed + 5)
    h = 1.45
    k.add(rough(lambda p: cap(p, v3(0, 0, 0), v3(0.02, 0, h), 0.05, 0.035), 0.012, 0.1, seed), "bark")
    tips = []
    for i in range(6):
        a = i * PI / 3 + rng.uniform(-0.3, 0.3)
        z0 = h * rng.uniform(0.7, 0.92)
        tip = v3(np.cos(a) * 0.4, np.sin(a) * 0.25, z0 + rng.uniform(0.25, 0.45))
        tips.append(tip)
        k.add(lambda p, z0=z0, tip=tip: cap(p, v3(0.01, 0, z0), tip, 0.025, 0.01), "bark")
    if not bare:
        if trim:
            k.add(lambda p: ell(p, v3(0, 0, h + 0.25), (0.5, 0.4, 0.42)) + (sdf.fbm(p, 0.12, seed, 2) - 0.5) * 0.08, "hedge")
        else:
            k.add(T.crown_fn(rng, tips + [v3(0, 0, h + 0.35)], 0.22, 0.32, seed, 0.25), "leaf_a")
    if guard == "ring":
        k.add(lambda p: sub(cyl(p, v3(0, 0, 0), 0.42, 0.08, 0.02), cyl(p, v3(0, 0, 0.03), 0.33, 0.1)), "masonry")
        k.add(lambda p: cyl(p, v3(0, 0, 0), 0.33, 0.06), "soil")
    else:
        for i in range(8):
            a = i * PI / 4
            k.add(lambda p, a=a: box(p, v3(np.cos(a) * 0.3, np.sin(a) * 0.3, 0.32), (0.02, 0.02, 0.32), 0.005), "wood_d")
        for z in (0.2, 0.52):
            k.add(lambda p, z=z: torus(p, v3(0, 0, z), 0.3, 0.015), "iron")
    return {"cell": (3, 4), "foot": 0.9}


@_p("hedge", "다듬은 생울타리", (2, 2), collide=(1.0, 0.5), tags=["city", "plant", "straight", "joint"],
    variants={"straight": {"part": "straight"}, "end": {"part": "end"}, "corner": {"part": "corner"}, "overgrown": {"part": "straight", "wild": True}, "gap": {"part": "gap"}},
    meta={"tile_w": 1})
def hedge(k, part="straight", wild=False, seed=1):
    """정원 · 광장 둘레의 네모나게 다듬은 관목 울(한 칸 폭 — 이웃과 이어진다)."""
    _clay(k)
    h, d = 0.62, 0.24
    jag = 0.16 if wild else 0.05
    if part == "corner":
        body = lambda p: np.minimum(box(p, v3(0.25, 0, h / 2), (0.25, d, h / 2), 0.05), box(p, v3(0, 0.25, h / 2), (d, 0.25, h / 2), 0.05))
    elif part == "end":
        body = lambda p: box(p, v3(-0.08, 0, h / 2), (0.42, d, h / 2), 0.1)
    elif part == "gap":
        body = lambda p: np.minimum(box(p, v3(-0.38, 0, h / 2), (0.12, d, h / 2), 0.06), box(p, v3(0.38, 0, h / 2), (0.12, d, h / 2), 0.06))
    else:
        body = lambda p: box(p, v3(0, 0, h / 2), (0.5, d, h / 2), 0.04)
    k.add(lambda p: body(p) + (sdf.fbm(p, 0.08, seed, 3) - 0.5) * jag - (0.04 if wild else 0) * (p[:, 2] > h - 0.1), "hedge")
    if wild:
        rng = k.rng
        for _ in range(6):
            c = v3(rng.uniform(-0.45, 0.45), rng.uniform(-0.1, 0.1), h + rng.uniform(0.0, 0.08))
            k.add(lambda p, c=c: cap(p, c - v3(0, 0, 0.1), c + v3(rng.uniform(-0.1, 0.1), 0, 0.14), 0.012, 0.004), "bark_d")
    return {"shadow": 0.45}


@flat("fallen_leaves", "city", cell=(96, 64), tags=["city", "decal", "leaves"], name_ko="낙엽",
    variants={"autumn": {"col": "autumn"}, "wet": {"col": "wet"}, "pile": {"col": "autumn", "pile": True}, "scatter": {"col": "autumn", "n": 14}}, meta={"sheet": "city_life"})
def fallen_leaves(c, col="autumn", pile=False, n=40, seed=1):
    """길 · 마당에 흩어지거나 쓸어 모은 낙엽(바닥 자국)."""
    rng = c.rng
    cols = {"autumn": ("#8a5a2a", "#a07a34", "#6e3a22", "#7a6a34"), "wet": ("#4a3424", "#5a4026", "#3a2a1e", "#4e4a2a")}[col]
    if pile:
        n = 80
    for _ in range(n):
        if pile:
            r, a = abs(rng.normal(0, 0.45)), rng.uniform(0, 2 * PI)
            x, y = 48 + np.cos(a) * r * 34, 34 + np.sin(a) * r * 18
        else:
            x, y = rng.uniform(8, 88), rng.uniform(8, 56)
        L, ang = rng.uniform(4, 7), rng.uniform(0, PI)
        m = c.blob(x, y, L, L * 0.5, 0.25, 3, 0.2, ang)
        c.paint(m, cols[int(rng.integers(4))])
        c.shade(m * c.rim(m, 0.8), -0.45)
        c.paint(c.seg([(x - np.cos(ang) * L * 0.8, y - np.sin(ang) * L * 0.8), (x + np.cos(ang) * L * 0.8, y + np.sin(ang) * L * 0.8)], 0.6, False), "#2e2016", 0.6)
    c.origin = (48, 34)


@_p("junk_pile", "버려진 물건 더미", (3, 3), tags=["city", "junk", "ruin"],
    variants={"small": {"size": "small"}, "large": {"size": "large"}, "alley": {"size": "alley"}})
def junk_pile(k, size="small", seed=1):
    """뒷골목에 내다 버린 살림: 부서진 판자 · 걸레 · 깨진 그릇 · 바퀴 · 의자 다리."""
    _clay(k)
    rng = k.rng
    s = {"small": 0.6, "large": 1.0, "alley": 0.85}[size]
    k.add(rough(lambda p: ell(p, v3(0, 0, 0), (0.55 * s, 0.32 * s, 0.22 * s)), 0.08, 0.12, seed), "dirt")
    k.add(rough(lambda p: ell(p, v3(-0.15 * s, 0.04, 0.12 * s), (0.28 * s, 0.2 * s, 0.14 * s)), 0.06, 0.08, seed + 1), "cloth")
    _planks(k, [(rng.uniform(-0.4, 0.4) * s, rng.uniform(-0.15, 0.15) * s, rng.uniform(-1.5, 1.5)) for _ in range(5 if size != "small" else 3)], "plank_x", 0.28 * s, seed)
    for i in range(4 if size != "small" else 2):
        a, b = v3(rng.uniform(-0.4, 0.3) * s, rng.uniform(-0.15, 0.1), 0.1 * s), None
        b = a + v3(rng.uniform(0.15, 0.35), rng.uniform(-0.1, 0.1), rng.uniform(0.05, 0.25)) * s
        k.add(lambda p, a=a, b=b: cap(p, a, b, 0.022), "wood_d")
    for i in range(3):
        x, y = rng.uniform(-0.45, 0.45) * s, -0.22 * s + rng.uniform(-0.05, 0.05)
        k.add(lambda p, x=x, y=y: sub(_frustum(p, v3(x, y, 0.0), 0.04, 0.06, 0.04), cyl(p, v3(x, y, 0.012), 0.045, 0.05)), "clay")
    if size != "small":
        k.add(rough(lambda p: ell(p, v3(0.25 * s, 0.08, 0.16 * s), (0.18, 0.14, 0.14)), 0.03, 0.1, seed + 2), "cloth_r")
        k.add(lambda p: np.maximum(np.abs(np.hypot(rot_x(p, 0.35, (0.38 * s, 0.1, 0.25))[:, 0] - 0.38 * s, rot_x(p, 0.35, (0.38 * s, 0.1, 0.25))[:, 2] - 0.25) - 0.2) - 0.025,
                                   np.abs(rot_x(p, 0.35, (0.38 * s, 0.1, 0.25))[:, 1] - 0.1) - 0.03), "wood_d")
    if size == "alley":
        _barrel(_Shift(k, -0.5, 0.25), 0.18, 0.5, seed, False, "wood_d")
    return {"shadow": 0.45}


class _Shift:
    def __init__(self, k, dx, dy, dz=0.0):
        self.k, self.d, self.rng, self.mats = k, v3(dx, dy, dz), k.rng, k.mats

    def add(self, fn, mat):
        self.k.add(lambda p, fn=fn: fn(p - self.d), mat)
        return self

    def mat(self, name, fn):
        return self.k.mat(name, fn)


@_p("water_yoke", "물지게", (2, 2), tags=["city", "water", "tool"],
    variants={"full": {"full": True}, "empty": {"full": False}, "set_down": {"full": True, "down": True}})
def water_yoke(k, full=True, down=False, seed=1):
    """어깨에 지는 막대 + 양쪽 물동이. set_down = 막대를 동이에 걸쳐 내려놓은 것."""
    _clay(k)
    for sx in (-1, 1):
        x = sx * 0.34
        k.add(lambda p, x=x: sub(_frustum(p, v3(x, 0, 0), 0.11, 0.13, 0.26), cyl(p, v3(x, 0, 0.03), 0.11, 0.3)), "wood")
        for z in (0.05, 0.21):
            k.add(lambda p, x=x, z=z: torus(p, v3(x, 0, z), 0.12 + z * 0.08, 0.01), "iron")
        if full:
            k.add(lambda p, x=x: cyl(p, v3(x, 0, 0.0), 0.115, 0.23), "glass")
        k.add(lambda p, x=x: np.maximum(ring_x(p, v3(x, 0, 0.27), 0.12, 0.008), 0.27 - p[:, 2]), "iron")
    z = 0.42 if not down else 0.4
    k.add(lambda p: cap(p, v3(-0.42, 0, z), v3(0.42, 0, z + (0.0 if down else 0.03)), 0.025), "wood_l")
    return {"shadow": 0.4}


def ring_x(p, c, R, r):
    q = np.hypot(p[:, 0] - c[0], p[:, 2] - c[2]) - R
    return np.hypot(q, p[:, 1] - c[1]) - r


@_p("washtub", "빨래 함지", (2, 2), tags=["city", "water", "laundry"],
    variants={"laundry": {"state": "laundry"}, "water": {"state": "water"}, "board": {"state": "board"}, "empty": {"state": "empty"}})
def washtub(k, state="laundry", seed=1):
    """낮고 넓은 나무 함지(빨래터 · 뒷마당). board = 빨래판을 걸쳤다."""
    _clay(k)
    k.add(rough(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.32, 0.38, 0.22), cyl(p, v3(0, 0, 0.04), 0.34, 0.3)), 0.008, 0.2, seed), "plank_y")
    for z in (0.05, 0.17):
        k.add(lambda p, z=z: torus(p, v3(0, 0, z), 0.335 + z * 0.25, 0.012), "iron")
    if state != "empty":
        k.add(lambda p: cyl(p, v3(0, 0, 0.0), 0.34, 0.17), "glass")
    if state == "laundry":
        k.add(rough(lambda p: ell(p, v3(0.06, 0, 0.18), (0.24, 0.18, 0.06)), 0.05, 0.08, seed), "linen")
        k.add(rough(lambda p: ell(p, v3(-0.12, 0.05, 0.19), (0.12, 0.1, 0.05)), 0.04, 0.08, seed + 1), "cloth_b")
        k.add(rough(lambda p: ell(p, v3(0.42, -0.25, 0.06), (0.16, 0.12, 0.06)), 0.05, 0.08, seed + 2), "linen")
    if state == "board":
        k.add(lambda p: box(rot_x(p, 0.55, (0, 0.12, 0.3)), v3(0, 0.12, 0.3), (0.16, 0.025, 0.28), 0.01), "wood_l")
    return {"shadow": 0.4}


@_p("hay_bale", "건초 더미", (3, 3), collide=(0.9, 0.5), tags=["city", "farm", "stable"],
    variants={"bale": {"kind": "bale"}, "stack": {"kind": "stack"}, "loose": {"kind": "loose"}, "fork": {"kind": "loose", "fork": True}})
def hay_bale(k, kind="bale", fork=False, seed=1):
    """마구간 · 수레 터의 묶은 건초(짚 더미 straw_pile보다 단단한 네모 덩이). loose = 풀어 쌓은 무더기."""
    _clay(k)
    rng = k.rng

    def bale(x, y, z, a=0.0):
        k.add(lambda p: box(rot_z(p, a, (x, y, z)), v3(x, y, z + 0.16), (0.32, 0.18, 0.16), 0.04) + (sdf.fbm(p, 0.03, seed, 2) - 0.5) * 0.03, "hay")
        for sx in (-0.15, 0.15):
            k.add(lambda p, sx=sx: np.maximum(np.abs(rot_z(p, a, (x, y, z))[:, 0] - x - sx) - 0.012, box(rot_z(p, a, (x, y, z)), v3(x, y, z + 0.16), (0.34, 0.2, 0.18), 0.04)) , "rope")

    if kind == "bale":
        bale(0, 0, 0)
    elif kind == "stack":
        bale(-0.34, 0, 0, 0.0)
        bale(0.34, 0.02, 0, 0.05)
        bale(0.02, 0.03, 0.32, -0.08)
    else:
        k.add(lambda p: ell(p, v3(0, 0, 0), (0.55, 0.36, 0.45)) + (sdf.fbm(p * np.array([1, 1, 0.5], F), 0.05, seed, 3) - 0.5) * 0.14, "hay")
        for _ in range(16):
            a = v3(rng.uniform(-0.5, 0.5), rng.uniform(-0.4, -0.2), rng.uniform(0.0, 0.05))
            k.add(lambda p, a=a: cap(p, a, a + v3(rng.uniform(-0.12, 0.12), rng.uniform(-0.05, 0.0), 0.0), 0.008), "hay_d")
        if fork:
            k.add(lambda p: cap(p, v3(0.1, 0.05, 0.2), v3(0.42, -0.1, 1.05), 0.018), "wood_l")
            for dx in (-0.04, 0.0, 0.04):
                k.add(lambda p, dx=dx: cap(p, v3(0.1 + dx, 0.05, 0.2), v3(0.04 + dx, 0.1, 0.42), 0.008), "iron")
    return {"shadow": 0.45}


@_p("hitching_post", "말 매는 말뚝", (2, 2), collide=(0.8, 0.2), tags=["city", "stable", "post"],
    variants={"rail": {"kind": "rail"}, "post": {"kind": "post"}, "rail_rope": {"kind": "rail", "rope": True}, "broken": {"kind": "rail", "broken": True}})
def hitching_post(k, kind="rail", rope=False, broken=False, seed=1):
    """여관 · 시장 앞의 말 매는 가로대(rail) 또는 쇠고리 박힌 돌말뚝(post)."""
    _clay(k)
    if kind == "post":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.3), (0.08, 0.08, 0.3), 0.03), 0.015, 0.12, seed), "stone")
        k.add(lambda p: torus(rot_x(p, PI / 2, (0, -0.09, 0.48)), v3(0, -0.09, 0.48), 0.05, 0.012), "iron")
        return {"shadow": 0.4}
    for sx in (-1, 1):
        k.add(rough(lambda p, sx=sx: box(p, v3(sx * 0.38, 0, 0.3), (0.045, 0.045, 0.3), 0.01), 0.01, 0.1, seed + sx), "wood_d")
    if broken:
        k.add(lambda p: cap(p, v3(-0.38, 0, 0.56), v3(0.3, -0.12, 0.05), 0.035), "wood")
    else:
        k.add(rough(lambda p: hcyl(p, v3(-0.46, 0, 0.56), v3(0.46, 0, 0.56), 0.035), 0.008, 0.1, seed), "wood")
    if rope:
        k.add(lambda p: cap(p, v3(0.1, 0, 0.56), v3(0.14, -0.06, 0.32), 0.012), "rope")
        k.add(lambda p: torus(rot_x(p, PI / 2, (0.1, 0, 0.56)), v3(0.1, 0, 0.56), 0.045, 0.013), "rope")
    return {"shadow": 0.4}


@_p("rain_barrel", "빗물 통", (2, 3), collide=(0.55, 0.45), tags=["city", "water"],
    variants={"full": {"full": True}, "dry": {"full": False}, "overflow": {"full": True, "over": True}})
def rain_barrel(k, full=True, over=False, seed=1):
    """처마 홈통이 내려와 꽂힌 빗물 통(받침돌 위). 홈통은 벽 쪽(뒤)으로 올라간다."""
    _clay(k)
    k.add(lambda p: box(p, v3(0, 0, 0.06), (0.26, 0.24, 0.06), 0.02), "stone")
    _barrel(_Shift(k, 0, 0, 0.12), 0.22, 0.62, seed, False, "wood")
    if full:
        k.add(lambda p: cyl(p, v3(0, 0, 0.12), 0.2, 0.56), "glass")
    k.add(lambda p: np.minimum(hcyl(p, v3(0.04, 0.12, 0.7), v3(0.04, 0.12, 1.45), 0.04), hcyl(p, v3(0.04, 0.12, 0.7), v3(0.04, 0.02, 0.62), 0.04)), "iron")
    if over:
        k.add(lambda p: pool(p, v3(0.12, -0.32, 0.0), 0.3, 0.14, 0.008), "glass")
    return {"cell": (2, 3), "shadow": 0.4}


@_p("chicken_coop", "닭장", (3, 3), collide=(1.0, 0.6), tags=["city", "farm", "yard"],
    variants={"closed": {"open": False}, "open": {"open": True}, "broken": {"open": True, "broken": True}})
def chicken_coop(k, open=False, broken=False, seed=1):
    """뒷마당의 작은 닭장: 다리 달린 판자 집 + 비탈 판자 + 그물 마당."""
    _clay(k)
    k.add(rough(lambda p: box(p, v3(-0.12, 0.08, 0.42), (0.34, 0.26, 0.2), 0.01), 0.01, 0.2, seed), "plank_x")
    k.add(lambda p: box(rot_y(p, -0.18, (-0.12, 0.08, 0.68)), v3(-0.12, 0.08, 0.68), (0.4, 0.32, 0.03), 0.01), "wood_d")
    for sx in (-0.4, 0.16):
        for sy in (-0.12, 0.28):
            k.add(lambda p, sx=sx, sy=sy: box(p, v3(sx, sy, 0.11), (0.03, 0.03, 0.11)), "wood_d")
    k.add(lambda p: box(p, v3(-0.12, -0.19, 0.4), (0.09, 0.012, 0.09)), "void" if open else "wood")
    k.add(lambda p: box(rot_x(p, -0.6, (0.1, -0.2, 0.22)), v3(0.18, -0.32, 0.12), (0.06, 0.02, 0.2), 0.005), "wood_l")
    run = lambda p: box(p, v3(0.5, 0.05, 0.22), (0.24, 0.26, 0.22))
    mesh = lambda p: np.maximum(run(p), -np.maximum(box(p, v3(0.5, 0.05, 0.22), (0.23, 0.25, 0.21)), (np.abs(np.sin(p[:, 0] * 70) * np.sin(p[:, 2] * 70)) - 0.15) * 0.02))
    if broken:
        k.add(lambda p: np.maximum(mesh(p), p[:, 0] - 0.42 - p[:, 2] * 0.6), "iron")
        _planks(k, [(0.6, -0.4, 0.4), (0.9, -0.1, -0.8)], "plank_x", 0.18, seed)
    else:
        k.add(lambda p: np.maximum(sub(run(p), box(p, v3(0.5, 0.05, 0.22), (0.228, 0.248, 0.212))), (np.minimum(np.abs(np.sin(p[:, 0] * 40)), np.abs(np.sin(p[:, 2] * 40))) - 0.2) * 0.02), "iron")
    for sx in (0.27, 0.73):
        k.add(lambda p, sx=sx: box(p, v3(sx, 0.05, 0.22), (0.015, 0.27, 0.22)), "wood_d")
    k.add(rough(lambda p: pool(p, v3(0.5, 0.0, 0.0), 0.24, 0.22, 0.01), 0.01, 0.1, seed), "hay")
    return {"shadow": 0.45}
