"""지형물(에셋 라이브러리 — docs/asset_library): 공용 바위(a_nature.rock)의 틀을 지역 재질 · 형태로 넓힌 것과 큰 지형 흔적.
사암 바위(지층 · 버섯바위 · 돌문) · 얼음(파편 · 덩이 · 기둥 · 속에 갇힌 그림자) · 현무암(기둥 다발 · 달아오른 바위) · 수정 박힌 바위와 벽 · 천장 수정 ·
눈 더미 · 고드름 · 운석 구덩이와 운석 · 거대한 뼈 · 땅에 박힌 낡은 검 · 로프 건널목.
색만 바꾼 것이 아니다 — 지역마다 덩어리의 꼴이 다르다(지층은 켜, 얼음은 모난 결정, 현무암은 육각 기둥)."""
import numpy as np

import fx
import mats as M
import sdf
from a_light import GLOWC, shard
from a_nature import _rock, _spike
from kit import (F, box, cap, chip, cone, cut_above, cyl, ell, flat, hcyl, pool, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep

ICE_GLOW = "#a8d0f0"


def _mats(k, seed):
    k.mat("sand_rock", M.stone("#8a735a", None, seed, 0.2))
    k.mat("sand_rock_d", M.stone("#6a5846", None, seed + 3, 0.2))
    k.mat("ice", M.plain("#7aa0c0", 0.3, 0.3, seed))
    k.mat("ice_l", M.plain("#a8c4dc", 0.22, 0.25, seed + 1))
    k.mat("ice_d", M.plain("#4a6c8c", 0.3, 0.3, seed + 2))
    k.mat("snow", M.plain("#b8c2cc", 0.1, 0.4, seed + 3))
    k.mat("basalt", M.stone("#3c3836", None, seed, 0.0))
    k.mat("basalt_d", M.stone("#262322", None, seed + 3))
    k.mat("cave", M.stone("#6c6c68", None, seed))
    k.mat("cave_d", M.stone("#4c4e50", None, seed + 3))
    k.mat("bone_big", M.plain("#bcb49c", 0.3, 0.16, seed + 4))
    k.mat("bone_big_d", M.plain("#857d68", 0.35, 0.14, seed + 5))


def _strata(fn, step=0.11, depth=0.022, seed=1):
    """지층: 덩어리 겉에 가로 켜마다 턱을 판다(사암)."""
    return lambda p: fn(p) + (np.abs(((p[:, 2] + sdf.noise(p, 0.5, seed) * 0.08) / step) % 1.0 - 0.5) < 0.12) * depth


def _hexcol(c, r, h, seed):
    """육각 기둥(현무암): 밑면 가운데 c."""
    c = np.asarray(c, F)

    def fn(p):
        q = np.abs(p[:, :2] - c[:2])
        d = np.maximum(q[:, 0] * 0.866 + q[:, 1] * 0.5, q[:, 1]) - r
        return np.maximum(d, np.maximum(c[2] - p[:, 2], p[:, 2] - c[2] - h + (sdf.noise(p, 0.1, seed) - 0.5) * 0.05)) * 0.9
    return fn


# ── 사암 바위(바위사막) ──────────────────────────────────────────────────────

@prop("rock_sandstone", "terrain", cell=(4, 4), collide=(1.0, 0.55), tags=["stone", "desert", "rock"], name_ko="사암 바위", reuse="ext", base="rock",
    variants={"strata_a": {"form": "strata", "seed": 3}, "strata_b": {"form": "strata", "seed": 12}, "hoodoo": {"form": "hoodoo", "seed": 5}, "hoodoo_b": {"form": "hoodoo", "seed": 21},
        "arch": {"form": "arch", "seed": 7}, "stack": {"form": "stack", "seed": 9}, "buried": {"form": "buried", "seed": 14}})
def rock_sandstone(k, form="strata", seed=1):
    _mats(k, seed)
    r = k.rng
    if form == "strata":      # 켜켜이 쌓인 넓적한 암괴
        k.add(_strata(_rock((0, 0.05, 0.3), (0.7, 0.45, 0.42), seed, 7, 0.04), 0.12, 0.03, seed), "sand_rock")
        k.add(_strata(_rock((0.55, -0.15, 0.13), (0.3, 0.24, 0.2), seed + 1, 5, 0.03), 0.1, 0.02, seed + 1), "sand_rock_d")
    elif form == "hoodoo":    # 바람에 깎인 버섯바위: 가는 목 위에 넓은 갓
        prof = lambda z: 0.2 + 0.16 * np.abs(z / 0.85 - 1.0) ** 1.3 + (z > 1.3) * 0.22 * np.clip(1 - (z - 1.55) ** 2 / 0.09, 0, 1)
        body = lambda p: np.maximum(np.hypot(p[:, 0], p[:, 1] * 1.2) - prof(p[:, 2]), np.maximum(-p[:, 2], p[:, 2] - 1.85)) * 0.7
        k.add(_strata(rough(body, 0.05, 0.25, seed), 0.13, 0.03, seed), "sand_rock")
        k.add(_rock((0.42, -0.2, 0.1), (0.2, 0.17, 0.15), seed + 1, 5, 0.03), "sand_rock_d")
    elif form == "arch":      # 돌문: 두 다리 위에 걸친 암괴, 가운데가 뚫렸다
        mass = lambda p: box(p, v3(0, 0.05, 0.75), (0.95, 0.3, 0.75), 0.25)
        hole = lambda p: np.maximum(np.hypot(p[:, 0] + 0.05, (p[:, 2] - 0.45) * 0.85) - 0.48, np.abs(p[:, 1]) - 1.0)
        k.add(_strata(rough(lambda p: sub(mass(p), hole(p)), 0.07, 0.3, seed), 0.14, 0.03, seed), "sand_rock")
        k.add(_rock((1.0, -0.25, 0.12), (0.24, 0.2, 0.18), seed + 2, 5, 0.03), "sand_rock_d")
    elif form == "stack":     # 판바위 탑: 넓적한 돌이 비뚤게 포개졌다
        z = 0.0
        for i in range(4):
            w = 0.5 - i * 0.08 + r.uniform(-0.04, 0.04)
            hh = r.uniform(0.11, 0.17)
            k.add(_rock((r.uniform(-0.1, 0.1), r.uniform(-0.05, 0.05), z + hh), (w, w * 0.75, hh), seed + i, 5, 0.03), ("sand_rock", "sand_rock_d")[i % 2])
            z += hh * 1.7
    else:                     # buried: 모래에 반쯤 묻힌 암괴 + 쓸려 온 모래 턱
        k.add(_strata(lambda p: _rock((0, 0, 0.08), (0.75, 0.42, 0.34), seed, 6, 0.04)(rot_y(p, 0.25)), 0.1, 0.025, seed), "sand_rock")
        k.add(lambda p: np.maximum(ell(p, v3(-0.25, -0.2, 0), (0.85, 0.42, 0.14)), -p[:, 2]) + (sdf.fbm(p, 0.2, seed, 2) - 0.5) * 0.04, "sand")
    k.rubble([(0.75, -0.42), (-0.6, -0.38), (0.15, -0.5)], "sand_rock_d", 0.035, 0.07)
    return {}


# ── 얼음(빙하굴 · 아이스록 · 서리 지대) ───────────────────────────────────────

def _ice_post(tips, r=46, k=0.3):
    return lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 0.5), r, ICE_GLOW, k), [vw.px(x, y - 0.1, z) for x, y, z in tips[:3]], "#f0f8ff")


@prop("rock_ice", "terrain", cell=(4, 5), collide=(0.8, 0.5), tags=["ice", "rock"], name_ko="얼음 덩이", reuse="ext", base="rock",
    variants={"shards_a": {"form": "shards", "seed": 3}, "shards_b": {"form": "shards", "seed": 14}, "block": {"form": "block", "seed": 5}, "block_cracked": {"form": "block", "seed": 9, "cracked": True},
        "snowcap": {"form": "snowcap", "seed": 7}, "pillar": {"form": "pillar", "seed": 11}, "pillar_frozen": {"form": "pillar", "seed": 11, "frozen": True}, "pillar_broken": {"form": "pillar", "seed": 11, "broken": True}},
    meta={"states": {"idle": "pillar_frozen", "spent": "pillar_broken"}, "note": "pillar_frozen = 무언가 갇힌 얼음 기둥(부수면 pillar_broken)"})
def rock_ice(k, form="shards", cracked=False, frozen=False, broken=False, seed=1):
    _mats(k, seed)
    r = np.random.default_rng(seed)
    tips = []
    if form == "shards":      # 모난 얼음 결정이 비스듬히 솟았다
        for i in range(7):
            x, y = r.uniform(-0.5, 0.5), r.uniform(-0.2, 0.2)
            hz, rr = r.uniform(0.3, 0.75) * (1.1 - abs(x)), r.uniform(0.1, 0.17)
            tx, ty = r.uniform(-0.25, 0.25), -x * 0.9 + r.uniform(-0.2, 0.2)
            k.add(shard(v3(x, y, -0.03), rr, hz, tx, ty), ("ice", "ice_l", "ice_d")[i % 3])
            tips.append((x + np.sin(-ty) * hz * 1.3, y, hz * 1.3 * np.cos(ty)))
        k.rubble([(0.55, -0.3), (-0.5, -0.28)], "ice_l", 0.03, 0.06)
    elif form == "block":     # 떨어져 나온 얼음덩이: 반듯하게 쪼개진 면
        slab = lambda c, b, a, t: (lambda p: np.maximum(box(rot_y(rot_z(p, a, c), t, c), v3(*c), b, 0.01), -p[:, 2]))   # 반듯하게 쪼개진 덩이(비스듬히 박혔다)
        body = lambda p: np.maximum(slab((0, 0, 0.3), (0.5, 0.36, 0.42), 0.35, 0.2)(p), (p[:, 0] * 0.6 + p[:, 2] - 0.78) * 0.8)
        if cracked:
            body = chip(body, 0.52, 0.22, seed, 0.09)
        k.add(body, "ice")
        k.add(slab((0.62, -0.2, 0.1), (0.2, 0.16, 0.16), -0.5, 0.4), "ice_l")
        k.add(slab((-0.55, -0.24, 0.06), (0.14, 0.11, 0.11), 0.9, -0.3), "ice_d")
        tips = [(-0.2, 0, 0.75), (0.3, 0, 0.6)]
    elif form == "snowcap":   # 눈 덮인 바위
        k.add(_rock((0, 0.05, 0.3), (0.6, 0.42, 0.42), seed, 7, 0.05), "cave_d")
        k.add(_rock((0.5, -0.12, 0.13), (0.26, 0.22, 0.2), seed + 1, 6), "cave")
        cap_ = _rock((0, 0.05, 0.31), (0.63, 0.45, 0.45), seed, 7, 0.02)
        k.add(lambda p: np.maximum(cap_(p), 0.4 - p[:, 2] + (sdf.fbm(p, 0.3, seed, 2) - 0.5) * 0.5) - 0.02, "snow")
        k.add(lambda p: np.maximum(ell(p, v3(0.1, -0.3, 0), (0.8, 0.3, 0.1)), -p[:, 2]), "snow")
        return {}
    else:                     # pillar: 일정 간격으로 선 얼음 기둥(길잡이) · 속에 무언가 갇힌 기둥 · 부서진 밑동
        col = lambda p: (np.maximum(np.hypot(p[:, 0], p[:, 1]) - (0.3 + 0.07 * np.abs(p[:, 2] / 1.2 - 1.0) ** 2), np.maximum(-p[:, 2], p[:, 2] - 2.4)) + np.cos(np.arctan2(p[:, 1], p[:, 0]) * 6.0) * 0.02) * 0.8
        if broken:
            k.add(cut_above(col, 0.55, 0.35, 0.2, seed, 0.3), "ice")
            for i, (x, y) in enumerate(((0.6, -0.3), (-0.55, -0.25), (0.9, 0.05), (0.2, -0.45))):
                k.add(_rock((x, y, 0.1), (0.2, 0.15, 0.13), seed + i, 4, 0.0), ("ice_l", "ice")[i % 2])
            return {"post": [_ice_post([(0, 0, 0.5)], 30, 0.2)]}
        k.add(col, "ice")
        k.add(lambda p: np.maximum(ell(p, v3(0, 0, 0), (0.5, 0.4, 0.12)), -p[:, 2]), "ice_l")
        tips = [(-0.15, 0, 2.0), (0.12, 0, 1.2)]
        if frozen:            # 속에 갇힌 검은 그림자(무엇인지는 놓는 쪽이 정한다)
            def inside(img, vw):
                hh, ww = img.shape[:2]
                yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
                cx, cy = vw.px(0, 0, 1.1)
                m = sstep(1.0 - np.hypot((xx - cx) / (0.14 * vw.u), (yy - cy) / (0.62 * vw.u)), 0, 0.5)
                hx, hy = vw.px(0, 0, 1.75)
                m = np.maximum(m, sstep(1.0 - np.hypot((xx - hx) / (0.1 * vw.u), (yy - hy) / (0.11 * vw.u)), 0, 0.5))
                return fx._over(img, m * 0.82 * (img[..., 3] > 128), hexc("#101822"))
            return {"post": [inside, _ice_post(tips, 52, 0.25)]}
    return {"post": [_ice_post(tips)]}


@prop("snow_drift", "terrain", cell=(4, 2), tags=["snow"], name_ko="눈 더미", variants={"a": {"seed": 3}, "b": {"seed": 8}, "c": {"seed": 15}, "long": {"seed": 5, "long": True}})
def snow_drift(k, long=False, seed=1):
    _mats(k, seed)
    r = k.rng
    n = 5 if long else 3
    lumps = [((i - (n - 1) / 2) * (0.42 if long else 0.34) + r.uniform(-0.06, 0.06), r.uniform(-0.08, 0.08), r.uniform(0.3, 0.5), r.uniform(0.12, 0.24)) for i in range(n)]

    def heap(p):   # 여러 봉우리가 한 덩이로 녹아 붙은 눈 더미
        d = None
        for x, y, a, h in lumps:
            di = ell(p, v3(x, y, 0), (a, a * 0.6, h))
            d = di if d is None else smin(d, di, 0.2)
        return np.maximum(d, -p[:, 2])
    k.add(heap, "snow")
    return {"shadow": 0.25}


@prop("icicles", "terrain", layer="over", cell=(3, 5), tags=["ice", "cave"], name_ko="고드름", reuse="ext", base="stalactite", variants={"a": {"seed": 4}, "b": {"seed": 13}, "sparse": {"seed": 9, "n": 4}})
def icicles(k, n=9, seed=1):
    _mats(k, seed)
    r = k.rng
    top = 3.05
    for i in range(n):
        x = -0.55 + i * 1.1 / max(1, n - 1) + r.uniform(-0.04, 0.04)
        ln = r.uniform(0.25, 1.0) * (1.0 - abs(x) * 0.6)
        k.add(lambda p, x=x, ln=ln, y=r.uniform(-0.04, 0.04): cap(p, v3(x, y, top), v3(x, y, top - ln), 0.05 + ln * 0.03, 0.004), ("ice_l", "ice")[i % 2])
    return {"shadow": 0.0, "foot": 0.5}


# ── 현무암 · 불탄 바위(지옥불 협곡 · 화산 지대) ───────────────────────────────

@prop("rock_basalt", "terrain", cell=(4, 5), collide=(0.9, 0.5), tags=["stone", "lava", "rock"], name_ko="현무암 바위", reuse="ext", base="rock",
    variants={"columns_a": {"form": "columns", "seed": 3}, "columns_b": {"form": "columns", "seed": 13}, "columns_low": {"form": "columns", "seed": 7, "low": True},
        "scorched": {"form": "scorched", "seed": 5}, "molten": {"form": "scorched", "seed": 5, "hot": True}, "spire": {"form": "spire", "seed": 9}},
    light={"color": "#e06a20", "radius": 2.0, "at": (0, 0, 0.3), "flicker": 0.2, "variants": ["molten"]})
def rock_basalt(k, form="columns", low=False, hot=False, seed=1):
    _mats(k, seed)
    r = k.rng
    if form == "columns":     # 육각 기둥 다발: 높이가 제각각
        for i in range(11):
            x, y = r.uniform(-0.55, 0.55), r.uniform(-0.3, 0.3)
            h = r.uniform(0.25, 0.7 if low else 1.9) * (1.15 - abs(x) * 1.1)
            k.add(_hexcol((x, y, 0), r.uniform(0.13, 0.2), max(h, 0.15), seed + i), ("basalt", "basalt_d")[i % 2])
        k.rubble([(0.7, -0.35), (-0.65, -0.3)], "basalt_d", 0.04, 0.08)
        return {}
    if form == "spire":       # 뾰족하게 솟은 검은 바위
        k.add(_spike((0, 0, 0), (0.1, 0, 2.3), 0.42, seed, 9.0), "basalt")
        k.add(_spike((-0.4, -0.1, 0), (-0.5, -0.1, 0.9), 0.24, seed + 1, 9.0), "basalt_d")
        k.add(_spike((0.42, -0.05, 0), (0.5, -0.05, 0.55), 0.2, seed + 2, 9.0), "basalt_d")
        return {}
    body = _rock((0, 0.05, 0.3), (0.6, 0.42, 0.42), seed, 8, 0.07)   # 그을린 바위 · 속이 달아오른 바위
    k.add(body, "basalt")
    k.add(_rock((0.52, -0.14, 0.13), (0.26, 0.22, 0.2), seed + 1, 6), "basalt_d")
    k.rubble([(-0.55, -0.32), (0.2, -0.45)], "basalt_d", 0.04, 0.08)
    if not hot:
        return {}

    return {"post": [_veins(seed, 0.35)]}


def _veins(seed, z):
    def veins(img, vw):       # 금을 따라 새는 불빛
        hh, ww = img.shape[:2]
        rng = np.random.default_rng(seed)
        from paint2d import Canvas
        c = Canvas(ww, hh, seed)
        cx, cy = vw.px(0, 0, z)
        m = c.cracks([(cx + rng.uniform(-20, 20), cy + rng.uniform(-12, 12), a, 30) for a in (0.4, 2.2, 3.9, 5.3)], 1.8)
        m = np.asarray(__import__("PIL.Image", fromlist=["x"]).fromarray((m * 255).astype(np.uint8)).resize((ww, hh), 1)).astype(F) / 255.0 * (img[..., 3] > 128)
        img = fx._over(img, np.clip(gblur(m, 2.5) * 1.6, 0, 1) * 0.55, hexc("#c03a10"))
        return fx.halo(fx._over(img, m, hexc("#ffb040")), cx, cy, 40, "#e06a20", 0.3)
    return veins


# ── 수정동굴: 벽과 천장에 붙은 수정이 광원 ────────────────────────────────────

_CRL = {"color": GLOWC["blue"], "radius": 3.2, "at": (0, 0, 0.6), "flicker": 0.04}


@prop("rock_crystal", "terrain", cell=(4, 4), collide=(1.0, 0.6), tags=["cave", "crystal", "rock"], name_ko="수정 박힌 바위", reuse="ext", base="rock",
    variants={"a": {"seed": 3}, "b": {"seed": 12}, "large": {"seed": 7, "big": True}, "dim": {"seed": 3, "lit": False}}, light=dict(_CRL, variants=["a", "b", "large"]))
def rock_crystal(k, big=False, lit=True, seed=1):
    _mats(k, seed)
    r = np.random.default_rng(seed)
    s = 1.3 if big else 1.0
    k.add(_rock((0, 0.05, 0.28 * s), (0.55 * s, 0.4 * s, 0.4 * s), seed, 7, 0.06), "cave")
    k.add(_rock((0.5 * s, -0.12, 0.12), (0.24, 0.2, 0.18), seed + 1, 6), "cave_d")
    tips = []
    for i in range(6 if big else 4):   # 바위 틈에서 돋은 수정
        a = r.uniform(-1.2, 1.2)
        x, z0 = np.sin(a) * 0.38 * s, 0.3 * s + np.cos(a) * 0.22 * s
        hz, rr = r.uniform(0.2, 0.36) * s, r.uniform(0.06, 0.1) * s
        k.add(shard(v3(x, -0.12 + r.uniform(-0.1, 0.1), z0), rr, hz, r.uniform(-0.3, 0.3), -a * 0.8), "crystal_b" if lit else "stone_d")
        tips.append((x + np.sin(a * 0.8) * hz, -0.12, z0 + hz * 1.2))
    k.rubble([(-0.5 * s, -0.3), (0.15, -0.42)], "cave_d", 0.035, 0.07)
    if not lit:
        return {}
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 0.5 * s), 62 * s, GLOWC["blue"], 0.42), [vw.px(x, y - 0.1, z) for x, y, z in tips[:3]])]}


@prop("crystal_wall", "terrain", layer="wall_decal", cell=(3, 4), tags=["cave", "crystal", "wall"], name_ko="벽에 붙은 수정", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 11}, "c": {"seed": 19}, "cluster": {"seed": 7, "n": 9}, "dim": {"seed": 3, "lit": False}},
    light=dict(_CRL, at=(0, -0.2, 1.2), variants=["a", "b", "c", "cluster"]), meta={"mount": "face", "note": "원점 = 벽 밑동. 벽면에서 앞으로 돋는다"})
def crystal_wall(k, n=5, lit=True, seed=1):
    r = np.random.default_rng(seed)
    tips = []
    for i in range(n):   # 벽(y = 0 뒤)에서 앞 · 아래위로 뻗는 수정
        x, z = r.uniform(-0.45, 0.45), r.uniform(0.75, 1.75)
        hz, rr = r.uniform(0.24, 0.42), r.uniform(0.07, 0.11)
        tx, ty = r.uniform(0.25, 0.7), r.uniform(-0.7, 0.7)
        c0 = v3(x, 0.05, z)
        k.add(shard(c0, rr, hz, tx, ty), "crystal_b" if lit else "stone_d")
        tips.append((x, -0.2, z + hz))
    cd = k.mat("cave_d", M.stone("#4c4e50", None, seed + 3))
    for i, (x, y, z) in enumerate(tips):   # 수정이 돋은 자리의 작은 암괴(벽에서 살짝 불거졌다)
        k.add(_rock((x, 0.1, z - 0.02), (0.1, 0.05, 0.07), seed + i, 4, 0.02), cd)
    if not lit:
        return {"shadow": 0.0}
    return {"shadow": 0.0, "post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, -0.2, 1.25), 58, GLOWC["blue"], 0.45), [vw.px(*t) for t in tips[:3]])]}


@prop("crystal_ceiling", "terrain", layer="over", cell=(3, 5), tags=["cave", "crystal"], name_ko="천장 수정", reuse="region", variants={"a": {"seed": 5}, "b": {"seed": 14}},
    light=dict(_CRL, at=(0, 0, 2.4), radius=4.0))
def crystal_ceiling(k, seed=1):
    r = np.random.default_rng(seed)
    top = 3.05
    for i in range(6):
        x = r.uniform(-0.4, 0.4)
        hz = r.uniform(0.25, 0.55)
        k.add(lambda p, x=x, hz=hz, rr=r.uniform(0.07, 0.11), a=r.uniform(-0.3, 0.3): shard(v3(x, 0, top - hz * 1.3), rr, hz, 0.0, a)(p), "crystal_b")
    return {"shadow": 0.0, "foot": 0.5, "post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 2.5), 60, GLOWC["blue"], 0.45), [vw.px(-0.1, 0, 2.3), vw.px(0.2, 0, 2.5)])]}


# ── 운석 구덩이(별무덤) ──────────────────────────────────────────────────────

@flat("crater", "terrain", cell=(288, 208), tags=["meteor", "ground"], name_ko="운석 구덩이", reuse="region",
    variants={"cold": {}, "fresh": {"hot": True, "frames": 4}, "small": {"small": True}}, light={"color": "#e04848", "radius": 4.0, "at": (0, 0, 0.2), "flicker": 0.3, "variants": ["fresh"]})
def crater(c, hot=False, small=False, f=0, seed=1):
    cx, cy = c.w / 2, c.h / 2
    s = 0.6 if small else 1.0
    rx, ry = 118 * s, 78 * s
    d = c.dist(cx, cy, rx, ry) + (c.noise(26, seed + 1) - 0.5) * 0.16
    bowl = sstep(1.0 - d, 0, 0.12)
    rim = sstep(1.0 - np.abs(d - 1.0) / 0.2, 0, 1)
    c.paint(np.clip(bowl + rim, 0, 1), hexc("#3a3430")[None, None, :] * (0.8 + c.noise(8, seed + 2)[..., None] * 0.4))
    c.shade(bowl * np.clip(1.2 - d, 0, 1), -0.5)                                   # 안으로 갈수록 깊다
    lit = np.clip((c.yy - cy) / ry, -1, 1) * bowl                                    # 아래(남쪽) 안벽이 빛을 받는다
    c.shade(np.clip(lit, 0, 1), 0.35)
    c.shade(rim * np.clip(-(c.yy - cy) / ry * 0.5 + 0.5, 0, 1), 0.3)                 # 밀려 올라간 턱
    ray = np.clip(np.cos(np.arctan2(c.yy - cy, (c.xx - cx) * ry / rx) * 11 + c.noise(30, seed + 3) * 5) - 0.55, 0, 1) * sstep(1.75 - d, 0, 0.6) * (d > 1.05)
    c.paint(ray * 0.55, "#2a2624")                                                    # 사방으로 튄 흙
    c.paint(c.cracks([(cx + np.cos(a) * rx * 0.2, cy + np.sin(a) * ry * 0.2, a, 60 * s) for a in (0.3, 1.9, 3.4, 4.8)], 2.0) * bowl, "#141110", 0.9)
    c.paint(c.rim(sstep(1.0 - d, 0, 0.04), 1.5) * 0.7, "#16100e")
    if hot:
        c.graded = False
        k = 0.75 + 0.25 * np.sin(f * 1.5708)
        core = sstep(0.45 - d, 0, 0.4) * (0.6 + 0.4 * c.noise(10, seed + 5 + f))
        c.add(core, "#b02820", 0.6 * k)
        c.add(sstep(0.2 - d, 0, 0.2), "#ff9060", 0.6 * k)
    c.origin = (cx, cy)


@prop("meteorite", "terrain", cell=(3, 3), collide=(0.7, 0.5), tags=["meteor", "rock"], name_ko="운석", reuse="region",
    variants={"cold": {"seed": 4}, "glowing": {"seed": 4, "hot": True}, "shards": {"seed": 9, "split": True}}, light={"color": "#e04848", "radius": 2.5, "at": (0, 0, 0.3), "flicker": 0.25, "variants": ["glowing"]})
def meteorite(k, hot=False, split=False, seed=1):
    _mats(k, seed)
    pit = k.mat("pitted", M.stone("#2e2a2c", None, seed, 0.0))
    body = lambda p: _rock((0, 0, 0.26), (0.4, 0.34, 0.32), seed, 9, 0.02)(p) + np.clip(0.6 - sdf.fbm(p, 0.09, seed + 2, 2), 0, 1) * 0.07   # 얽은 겉
    if split:
        k.add(lambda p: np.maximum(body(p), p[:, 0] * 0.9 + p[:, 2] * 0.3 - 0.05), pit)
        k.add(lambda p: np.maximum(body(rot_z(p - v3(0.35, -0.15, -0.05), 0.5)), -(p[:, 0] - 0.35) * 0.9 - 0.05), pit)
    else:
        k.add(body, pit)
    k.rubble([(0.5, -0.3), (-0.45, -0.25), (0.1, -0.4)], "basalt_d", 0.03, 0.06)
    if hot:
        return {"post": [lambda img, vw: fx.tint(img, "#a03028", 0.14), _veins(seed, 0.26)]}
    return {}


# ── 거대한 뼈(용의 심처) ─────────────────────────────────────────────────────

@prop("giant_bone", "terrain", cell=(6, 5), tags=["bone", "dead", "giant"], name_ko="거대한 뼈", reuse="region",
    variants={"rib_arch": {"form": "ribs", "seed": 3}, "rib_single": {"form": "rib", "seed": 5}, "vertebra": {"form": "vertebra", "seed": 7}, "spine": {"form": "spine", "seed": 9},
        "skull": {"form": "skull", "seed": 11}, "femur": {"form": "femur", "seed": 13}, "shards": {"form": "shards", "seed": 15}})
def giant_bone(k, form="ribs", seed=1):
    _mats(k, seed)
    r = k.rng
    B, D = "bone_big", "bone_big_d"

    def rib(x, lean, h=1.9, y=0.0, side=1):
        pts = [v3(x + side * lean * 1.3 * (1 - np.cos(t * 2.0)), y, -0.05 + h * np.sin(t * 1.75)) for t in np.linspace(0, 1, 8)]
        for i in range(len(pts) - 1):
            ra, rb = 0.12 - i * 0.012, 0.108 - i * 0.012
            k.add(rough(lambda p, a=pts[i], b=pts[i + 1], ra=ra, rb=rb: cap(p, a, b, ra, rb), 0.02, 0.1, seed + i), B if i % 2 == 0 else D)

    def vert(x, y, s=1.0, tilt=0.0):
        c = v3(x, y, 0.3 * s)
        k.add(rough(lambda p: sub(ell(rot_z(p, tilt, c), c, (0.22 * s, 0.3 * s, 0.28 * s)), sphere(p, c + v3(0, -0.3 * s, 0.02), 0.1 * s)), 0.04, 0.12, seed), B)
        k.add(rough(lambda p: cap(p, c + v3(0, 0, 0.2 * s), c + v3(0, 0.05, 0.72 * s), 0.09 * s, 0.03 * s), 0.02, 0.1, seed + 1), D)       # 가시 돌기
        for sgn in (-1, 1):
            k.add(rough(lambda p, sgn=sgn: cap(p, c, c + v3(0, sgn * 0.5 * s, 0.1 * s), 0.08 * s, 0.03 * s), 0.02, 0.1, seed + 2), D)        # 가로 돌기

    if form == "ribs":        # 땅에서 솟아 머리 위로 휘는 갈비뼈 줄(지나갈 수 있는 문)
        for i, x in enumerate((-1.5, -0.5, 0.5, 1.5)):
            rib(x, 0.55 + 0.1 * r.random(), 1.9 - 0.25 * abs(i - 1.5), r.uniform(-0.1, 0.1), 1 if i % 2 else -1)
        k.rubble(k.scatter(5, 1.6, 0.4), D, 0.04, 0.08)
        return {"foot": 0.6}
    if form == "rib":
        rib(-0.2, 0.9, 2.2)
        return {"cell": (4, 5)}
    if form == "vertebra":
        vert(0, 0, 1.2, 0.2)
        return {"cell": (3, 3)}
    if form == "spine":       # 줄지어 누운 척추뼈
        for i in range(5):
            vert(-1.6 + i * 0.8, np.sin(i * 0.9) * 0.15, 1.0 - abs(i - 2) * 0.08, i * 0.08)
        return {"cell": (6, 3)}
    if form == "skull":       # 반쯤 묻힌 거대한 머리뼈
        dome = lambda p: ell(p, v3(-0.2, 0.1, 0.45), (0.9, 0.65, 0.7))
        snout = lambda p: cap(p, v3(0.3, 0.05, 0.3), v3(1.5, 0.0, 0.14), 0.42, 0.2)
        eye = lambda p: min_(sphere(p, v3(0.15, -0.5, 0.55), 0.24), sphere(p, v3(0.15, 0.6, 0.55), 0.24))
        min_ = np.minimum
        k.add(rough(lambda p: np.maximum(sub(smin(dome(p), snout(p), 0.15), eye(p)), -p[:, 2] - 0.05), 0.05, 0.25, seed), B)
        for i in range(5):    # 이빨
            k.add(lambda p, i=i: cone(p, v3(0.55 + i * 0.2, -0.3, 0.0), 0.06, 0.2), D)
        for sgn, a in ((-1, 0.5), (1, 0.35)):   # 뿔
            k.add(rough(lambda p, sgn=sgn, a=a: cap(p, v3(-0.7, sgn * 0.3, 0.9), v3(-1.4, sgn * 0.55, 1.5 + a), 0.14, 0.02), 0.02, 0.1, seed + 3), D)
        return {"cell": (5, 4)}
    if form == "femur":
        a, b = v3(-1.0, 0.05, 0.16), v3(1.0, -0.1, 0.2)
        k.add(rough(lambda p: smin(smin(cap(p, a, b, 0.13, 0.12), sphere(p, a, 0.24), 0.08), np.minimum(sphere(p, b + v3(0, 0.12, 0), 0.2), sphere(p, b - v3(0, 0.14, 0), 0.19)), 0.08), 0.03, 0.12, seed), B)
        return {"cell": (4, 2)}
    for i, (x, y) in enumerate(k.scatter(9, 1.0, 0.45)):   # shards: 부서진 뼛조각 무더기
        a = r.uniform(0, 3.14)
        ln = r.uniform(0.15, 0.4)
        k.add(rough(lambda p, x=x, y=y, a=a, ln=ln: cap(p, v3(x - np.cos(a) * ln, y - np.sin(a) * ln * 0.6, 0.06), v3(x + np.cos(a) * ln, y + np.sin(a) * ln * 0.6, 0.08), 0.06, 0.03), 0.02, 0.1, seed + i), (B, D)[i % 2])
    return {"cell": (4, 2), "shadow": 0.4}


# ── 낡은 검이 박힌 벌판(패자의 안식처) ────────────────────────────────────────

@prop("planted_sword", "terrain", cell=(3, 3), tags=["weapon", "dead", "battle"], name_ko="땅에 박힌 낡은 검", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 8}, "c": {"seed": 14}, "broken": {"seed": 5, "broken": True}, "cluster": {"seed": 9, "n": 5}, "cluster_b": {"seed": 17, "n": 7}})
def planted_sword(k, n=1, broken=False, seed=1):
    r = k.rng
    spots = [(0.0, 0.0)] if n == 1 else k.scatter(n, 0.75, 0.4)
    for i, (x, y) in enumerate(spots):
        lean, ln = r.uniform(-0.35, 0.35), r.uniform(0.55, 0.95) * (0.55 if broken else 1.0)
        wide = r.uniform(0.035, 0.055)
        o = (x, y, 0.0)
        blade = lambda p, x=x, y=y, ln=ln, wide=wide: box(p, v3(x, y, ln * 0.5 - 0.05), (wide, 0.012, ln * 0.5))
        if broken:
            k.add(lambda p, blade=blade, lean=lean, o=o, ln=ln: cut_above(blade, ln * 0.8, 0.08, 0.06, seed, 0.6)(rot_y(p, lean, o)), "rust")
            continue
        guard = lambda p, x=x, y=y, ln=ln: box(p, v3(x, y, ln), (0.13, 0.022, 0.02), 0.008)
        grip = lambda p, x=x, y=y, ln=ln: np.minimum(cap(p, v3(x, y, ln), v3(x, y, ln + 0.2), 0.022), sphere(p, v3(x, y, ln + 0.23), 0.035))
        k.add(lambda p, blade=blade, lean=lean, o=o: blade(rot_y(p, lean, o)), ("rust", "iron")[i % 2])
        k.add(lambda p, guard=guard, lean=lean, o=o: guard(rot_y(p, lean, o)), "bronze")
        k.add(lambda p, grip=grip, lean=lean, o=o: grip(rot_y(p, lean, o)), "leather_d")
    k.rubble([(0.2, -0.15)], "dirt", 0.03, 0.05)
    return {"shadow": 0.4}


# ── 끊긴 길의 로프(대마경 · 빙하굴) ───────────────────────────────────────────

@prop("rope_crossing", "terrain", cell=(4, 3), tags=["rope", "cliff", "climb"], name_ko="로프 건널목", interact="rope",
    variants={"anchor": {}, "taut_e": {"line": 1}, "taut_w": {"line": -1}, "coiled": {"coil": True}, "cut": {"cut": True}}, meta={"states": {"idle": "anchor", "active": "taut_e", "spent": "cut"}})
def rope_crossing(k, line=0, coil=False, cut=False, seed=1):
    """낭떠러지 끝에 박은 말뚝과 로프: anchor 말뚝만 · taut 건너편으로 팽팽히 맨 줄 · coiled 사려 둔 줄 · cut 끊긴 줄."""
    k.add(rough(lambda p: cap(rot_y(p, 0.12), v3(0, 0, -0.05), v3(0, 0, 0.62), 0.07, 0.055), 0.02, 0.1, seed), "wood_d")
    k.add(lambda p: torus(p, v3(0, 0, 0.42), 0.085, 0.022), "rope")
    k.rubble([(0.16, -0.1), (-0.15, -0.08)], "stone_d", 0.04, 0.07)
    if line:
        k.add(lambda p: cap(p, v3(0, 0, 0.42), v3(line * 1.9, 0.5, 0.75), 0.02), "rope")
    if coil:
        for i in range(3):
            k.add(lambda p, i=i: torus(p, v3(0.42, -0.12, 0.03 + i * 0.035), 0.2 - i * 0.02, 0.024), "rope")
    if cut:
        k.add(lambda p: smin(cap(p, v3(0, 0, 0.42), v3(0.3, -0.1, 0.03), 0.02), cap(p, v3(0.3, -0.1, 0.03), v3(0.75, -0.25, 0.02), 0.02, 0.012), 0.03), "rope")
    return {"dx": -0.6 * line if line else 0.0}
