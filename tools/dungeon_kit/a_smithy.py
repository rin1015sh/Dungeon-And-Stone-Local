"""대장간 전용: 화덕 · 풀무 · 담금질 통 · 벽 연장걸이 · 망치와 집게 · 주괴 · 철광석 · 석탄 · 장작 · 방패 거치대 ·
검 · 도끼 · 창 진열대 · 도가니 · 주물 틀 · 기둥 바이스 · 편자와 못 · 벼리다 만 칼날 · 벽 그을음 · 불티 · 연기 · 가죽 앞치마 · 물 양동이.
이미 있는 것(모루 · 작업대 · 숫돌 · 연장통 · 무기 거치대 · 갑옷 거치대 · 바닥 그을음)은 다시 만들지 않는다.
벽 부착물(wall_decal)은 원점 = 벽 밑동 — 실제 걸리는 높이로 빚었다(up을 주지 않는다)."""
import numpy as np

import fx
import sdf
from kit import (F, box, cap, chip, cone, cut_above, cyl, disc_x, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from paint2d import hexc, sstep
from a_furniture import _X, _barrel, _crate, _frustum, _move, _planks
from a_light import FIRE, flame_post

PI = np.pi
HOT = "#e06a20"


def _mats(k):
    k.mat("copper", M.metal("#8a5a3c", "#4a6a58", 21, 0.3))
    k.mat("ore", M.stone("#5a4a44", None, 31))
    k.mat("ore_r", M.metal("#4a4444", "#7a4a30", 32, 0.9))
    k.mat("water", M.plain("#2a3a44", 0.5, 0.1, 4))
    k.mat("soot", M.stone("#3a3634", None, 12))
    k.mat("log_end", M.plain("#8a7250", 0.3, 0.03, 41))
    k.mat("bark", M.bark("#4a3a2c", None, 42))


def _heap(k, n, rx, ry, h, mat, r0=0.05, r1=0.09, cx=0.0, cy=0.0, mat2=None):
    """덩이 더미: 원뿔꼴 속 + 겉에 낱덩이 n개."""
    k.add(rough(lambda p: ell(p, v3(cx, cy, 0), (rx * 0.9, ry * 0.9, h * 0.9)), 0.05, 0.1, getattr(k, "seed", getattr(getattr(k, "k", None), "seed", 1))), mat)
    for i in range(n):
        a, rho = k.rng.uniform(0, 2 * PI), np.sqrt(k.rng.uniform(0.02, 1.0))
        r = k.rng.uniform(r0, r1)
        c = v3(cx + np.cos(a) * rho * rx, cy + np.sin(a) * rho * ry, max(r * 0.5, h * (1 - rho ** 1.5) * 0.95))
        s = int(k.rng.integers(999))
        k.add(chip(rough(lambda p, c=c, r=r: ell(p, c, (r * 1.2, r, r * 0.85)), 0.04, 0.08, s), 0.45, 0.12, s, 0.03), mat2 if (mat2 and i % 3 == 0) else mat)


def _ingot(t, c, ln=0.13, w=0.05, h=0.035, a=0.0, mat="iron"):
    c = np.asarray(c, F)
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: np.maximum(box(T(p), c + v3(0, 0, h), (ln, w, h), 0.006), (np.abs(T(p)[:, 1] - c[1]) + (T(p)[:, 2] - c[2]) * 0.35 - w) * 0.9), mat)


def _hsword(t, x, y, z, ln=0.7, mat="steel", grip="leather_d", flip=1):
    """벽에 가로로 건 칼(손잡이가 flip 쪽)."""
    s = flip
    t.add(lambda p: np.maximum(box(p, v3(x, y, z), (ln / 2, 0.007, 0.028)), (np.abs(p[:, 2] - z) + (-s * (p[:, 0] - x) - ln / 2 + 0.07) * 0.45 - 0.028)), mat)
    xg = x + s * ln / 2
    t.add(lambda p: box(p, v3(xg + s * 0.01, y, z), (0.013, 0.016, 0.085), 0.006), "brass")
    t.add(lambda p: np.minimum(hcyl(p, v3(xg + s * 0.02, y, z), v3(xg + s * 0.15, y, z), 0.017), sphere(p, v3(xg + s * 0.17, y, z), 0.026)), grip)


def _vaxe(t, x, y, z0, ln=0.7, big=False):
    """머리가 위인 도끼."""
    R = 0.2 if big else 0.14
    t.add(lambda p: cap(p, v3(x, y, z0), v3(x, y, z0 + ln), 0.02), "wood")
    zb = z0 + ln - 0.09
    blade = lambda p: np.maximum(np.maximum(disc_x(p, v3(x + 0.02, y, zb), R, 0.011), x + 0.02 - p[:, 0]), -disc_x(p, v3(x - R * 0.45, y, zb), R * 0.72, 0.1))
    fn = lambda p: np.minimum(blade(p), box(p, v3(x, y, zb), (0.03, 0.022, 0.05), 0.008))
    if big:
        blade2 = lambda p: np.maximum(np.maximum(disc_x(p, v3(x - 0.02, y, zb), R, 0.011), p[:, 0] - x + 0.02), -disc_x(p, v3(x + R * 0.45, y, zb), R * 0.72, 0.1))
        t.add(lambda p: np.minimum(fn(p), blade2(p)), "steel")
    else:
        t.add(fn, "steel")


def _hammer_v(t, x, y, z, ln=0.34, head=0.05):
    """머리가 위로 걸린 망치."""
    t.add(lambda p: cap(p, v3(x, y, z - ln), v3(x, y, z), 0.015), "wood_l")
    t.add(lambda p: box(p, v3(x, y, z), (head * 1.5, 0.03, head * 0.7), 0.008), "iron")


def _tongs(t, a, b, r=0.011, spread=0.05, mat="iron"):
    """집게: a(손잡이 끝) → b(물리는 끝). 가위꼴."""
    a, b = np.asarray(a, F), np.asarray(b, F)
    d = b - a
    n = np.array([-d[1], d[0], 0], F)
    if np.hypot(n[0], n[1]) < 1e-4:
        n = v3(1, 0, 0)
    n = n / np.sqrt((n * n).sum()) * spread
    piv = a + d * 0.72
    t.add(lambda p: np.minimum.reduce([cap(p, a + n, piv, r), cap(p, a - n, piv, r), cap(p, piv, b + n * 0.25, r), cap(p, piv, b - n * 0.25, r), sphere(p, piv, r * 1.7)]), mat)


def _shield_round(t, c, R=0.24, tilt=0.3, mat="plank_y"):
    c = np.asarray(c, F)
    T = lambda p: rot_x(p, tilt, c)
    t.add(lambda p: disc_x(T(p), c, R, 0.018), mat)
    t.add(lambda p: np.maximum(ring_x(T(p), c + v3(0, -0.012, 0), R - 0.012, 0.016), 0), "iron")
    t.add(lambda p: ell(T(p), c + v3(0, -0.025, 0), (0.065, 0.045, 0.065)), "steel")


def _shield_heater(t, c, tilt=0.3, mat="steel", band="brass"):
    c = np.asarray(c, F)
    T = lambda p: rot_x(p, tilt, c)
    shape = lambda q: np.maximum(np.maximum(box(q, c + v3(0, 0, 0.04), (0.19, 0.016, 0.3)), disc_x(q, c + v3(0.19, 0, 0.14), 0.42, 0.02)), disc_x(q, c + v3(-0.19, 0, 0.14), 0.42, 0.02))
    t.add(lambda p: shape(T(p)), mat)
    t.add(lambda p: np.maximum(shape(T(p)) - 0.004, np.minimum(np.abs(T(p)[:, 0] - c[0]) - 0.02, np.abs(T(p)[:, 2] - c[2] - 0.12) - 0.02)), band)


# ── 화덕 · 풀무 · 담금질 통 ──────────────────────────────────────────────────

@prop("forge", "smithy", cell=(4, 5), collide=(1.8, 1.1), tags=["fire", "workshop", "masonry"], name_ko="대장간 화덕", interact="fire",
    variants={"lit": {"frames": 4}, "embers": {"state": "embers", "frames": 4}, "cold": {"state": "cold"}},
    light={"color": FIRE, "radius": 5.5, "at": (0, -0.1, 0.9), "flicker": 0.4, "variants": ["lit", "embers"]},
    meta={"states": {"idle": "cold", "active": "lit", "spent": "embers"}, "note": "벽에 붙여 세운다 — 굴뚝이 벽 높이(2.5칸)를 조금 넘는다"})
def forge(k, state="lit", seed=1, f=0):
    _mats(k)
    k.add(rough(lambda p: sub(sub(box(p, v3(0, 0, 0.31), (0.86, 0.5, 0.31), 0.02), box(p, v3(0, -0.06, 0.66), (0.62, 0.32, 0.12))), box(p, v3(-0.38, -0.5, 0.2), (0.2, 0.16, 0.17), 0.05)), 0.02, 0.2, seed), "masonry")
    k.add(lambda p: box(p, v3(-0.38, -0.3, 0.2), (0.2, 0.05, 0.17)), "void")
    k.add(rough(lambda p: box(p, v3(0, 0.4, 1.02), (0.86, 0.1, 0.42), 0.02), 0.02, 0.2, seed + 1), "masonry")                      # 뒷벽
    hood = lambda p: np.maximum(box(p, v3(0, 0.06, 1.78), (0.84, 0.44, 0.36), 0.02), (np.abs(p[:, 0]) * 0.62 + (p[:, 1] < 0) * (-p[:, 1]) * 0.9 + p[:, 2] - 2.14) * 0.8)
    k.add(rough(lambda p: sub(hood(p), box(p, v3(0, -0.02, 1.4), (0.72, 0.36, 0.14))), 0.015, 0.2, seed + 2), "soot")             # 연기 갓
    k.add(lambda p: box(p, v3(0, 0.0, 1.5), (0.7, 0.3, 0.03)), "void")
    k.add(rough(lambda p: box(p, v3(0, 0.22, 2.42), (0.25, 0.22, 0.38), 0.02), 0.02, 0.2, seed + 3), "brick")                      # 굴뚝
    k.add(lambda p: box(p, v3(0, 0.22, 2.8), (0.29, 0.26, 0.04), 0.01), "stone_d")
    for s in (-1, 1):
        k.add(lambda p, s=s: cap(p, v3(s * 0.78, -0.42, 0.62), v3(s * 0.78, -0.3, 1.44), 0.022), "iron")
    k.add(rough(lambda p: ell(p, v3(0, -0.06, 0.56), (0.58, 0.29, 0.07)), 0.05, 0.07, seed), "ash" if state == "cold" else "coal")
    k.add(lambda p: np.minimum(hcyl(p, v3(0.84, -0.06, 0.5), v3(1.02, -0.06, 0.5), 0.05), torus(rot_y(p, PI / 2, (1.02, -0.06, 0.5)), v3(1.02, -0.06, 0.5), 0.05, 0.014)), "iron")   # 바람 구멍
    k.add(lambda p: hcyl(p, v3(0.2, -0.36, 0.63), v3(0.55, -0.1, 0.6), 0.012), "iron")                                             # 불쏘시개
    if state == "cold":
        return {"far": 9.0}
    post = [lambda img, vw: fx.embers(img, *vw.px(0, -0.06, 0.62), 32, 12, seed, f)]
    if state == "lit":
        post += [flame_post(-0.2, -0.06, 0.62, 18, seed + 1, f, "fire", 0.42, 0.5, 0.2), flame_post(0.05, -0.06, 0.62, 28, seed, f, "fire", 0.46, 2.6, 0.55), flame_post(0.28, -0.06, 0.62, 14, seed + 2, f, "fire", 0.4, 0.5, 0.2)]
    else:
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, -0.06, 0.7), 44, HOT, 0.32 + 0.05 * np.sin(f * 1.57)))
    return {"post": post, "far": 9.0}


@prop("bellows", "smithy", cell=(4, 3), collide=(1.3, 0.6), tags=["workshop", "leather", "wood"], name_ko="풀무", interact="lever",
    variants={"idle": {}, "compressed": {"state": "compressed"}, "torn": {"state": "torn"}}, meta={"states": {"idle": "idle", "active": "compressed"}, "note": "주둥이가 오른쪽(화덕 쪽) — 왼쪽 화덕에는 뒤집어 쓴다"})
def bellows(k, state="idle", seed=1):
    gap = 0.3 if state == "idle" else 0.1
    zb, nose = 0.5, v3(0.5, 0, 0.5)
    tear = lambda p, hz: np.maximum(np.maximum(ell(p, v3(-0.05, 0, p[0, 2] * 0 + 0), (0.62, 0.34, 9.0)), (np.abs(p[:, 1]) * 1.15 + (p[:, 0] - 0.1) * 0.62 - 0.3)), np.abs(p[:, 2]) - hz)
    board = lambda p, z, hz=0.022: tear(p - v3(0, 0, z), hz)
    up = lambda p: rot_y(p, -gap * 0.75, nose)
    for sx in (-0.5, 0.3):
        for sy in (-0.24, 0.24):
            k.add(lambda p, sx=sx, sy=sy: box(p, v3(sx, sy, zb / 2 - 0.02), (0.035, 0.035, zb / 2 - 0.02), 0.008), "wood_d")
    k.add(lambda p: np.minimum(box(p, v3(-0.1, -0.24, 0.12), (0.44, 0.025, 0.025)), box(p, v3(-0.1, 0.24, 0.12), (0.44, 0.025, 0.025))), "wood_d")
    k.add(rough(lambda p: board(p, zb), 0.008, 0.2, seed), "plank_x")
    k.add(rough(lambda p: board(up(p), zb + 0.05), 0.008, 0.2, seed + 1), "plank_x")
    lea = lambda p: np.maximum(np.maximum(tear(p - v3(0, 0, zb), 9.0) + 0.03 + np.sin((p[:, 2] - zb) * 70.0) * 0.008, zb - p[:, 2]), up(p)[:, 2] - zb - 0.04)
    if state == "torn":
        k.add(rough(lambda p: np.maximum(lea(p), 0.5 - sdf.fbm(p, 0.14, seed, 2) - (p[:, 0] + 0.3) * 0.4), 0.01, 0.1, seed), "leather_d")
    else:
        k.add(lea, "leather")
    k.add(lambda p: np.minimum(cap(p, nose + v3(-0.06, 0, 0.01), v3(0.95, 0, 0.47), 0.05, 0.028), torus(rot_y(p, PI / 2, (0.62, 0, 0.5)), v3(0.62, 0, 0.5), 0.05, 0.012)), "iron")
    tip = rot_y(v3(-0.55, 0, zb + 0.07)[None, :], gap * 0.75, nose)[0]
    k.add(lambda p: np.minimum.reduce([box(p, v3(-0.75, 0.3, 0.65), (0.04, 0.04, 0.65), 0.01), cap(p, v3(-0.75, 0.3, 1.26), v3(-0.5, 0.0, 1.3 - gap * 0.6), 0.022),
        cap(p, v3(-0.75, 0.3, 1.26), v3(-1.0, 0.45, 1.05 + gap * 0.8), 0.022), cap(p, v3(-0.5, 0.0, 1.3 - gap * 0.6), tip, 0.008)]), "wood_d")
    return {}


@prop("quench_tub", "smithy", cell=(3, 3), collide=(0.8, 0.7), tags=["workshop", "water", "wood"], name_ko="담금질 통",
    variants={"still": {}, "steam": {"state": "steam", "frames": 4}, "dry": {"state": "dry"}})
def quench_tub(k, state="still", seed=1, f=0):
    _mats(k)
    r, h = 0.34, 0.46
    _barrel(k, r, h, seed, False, "wood_d")
    k.add(lambda p: cyl(p, v3(0, 0, h - 0.1 if state != "dry" else 0.05), r - 0.02, 0.012), "water" if state != "dry" else "void")
    if state == "steam":
        k.add(lambda p: box(rot_y(p, 0.9, (0.1, 0, h)), v3(0.1, 0, h + 0.1), (0.022, 0.007, 0.26)), "steel")
        return {"post": [lambda img, vw: fx.halo(fx.puff(img, *vw.px(0.05, 0, h + 0.05), 12, "#c8c4b8", 0.42, seed, f, 44, 6), *vw.px(0.05, 0, h - 0.06), 12, HOT, 0.35)]}
    if state == "still":
        _tongs(k, v3(0.5, -0.2, h + 0.3), v3(0.1, 0.05, h - 0.06))
    return {}


# ── 연장 ─────────────────────────────────────────────────────────────────────

@prop("tool_rack_wall", "smithy", layer="wall_decal", cell=(3, 3), tags=["workshop", "iron", "wall"], name_ko="벽 연장걸이",
    variants={"full": {}, "sparse": {"state": "sparse"}, "empty": {"state": "empty"}})
def tool_rack_wall(k, state="full", seed=1):
    z = 1.5
    k.add(rough(lambda p: box(p, v3(0, -0.02, z), (0.78, 0.022, 0.05), 0.006), 0.008, 0.2, seed), "plank_x")
    xs = (-0.66, -0.44, -0.22, 0.0, 0.22, 0.44, 0.66)
    k.add(lambda p: np.minimum.reduce([hcyl(p, v3(x + s, -0.04, z), v3(x + s, -0.12, z + 0.02), 0.01) for x in xs for s in (-0.035, 0.035)]), "iron")
    if state == "empty":
        return {"shadow": 0.0}
    full = state == "full"
    _hammer_v(k, xs[0], -0.09, z + 0.035, 0.42, 0.06)
    _tongs(k, v3(xs[2], -0.09, z - 0.62), v3(xs[2], -0.09, z + 0.06), 0.011, 0.045)
    if full:
        _hammer_v(k, xs[1], -0.09, z + 0.03, 0.3, 0.04)
        _tongs(k, v3(xs[3], -0.09, z - 0.48), v3(xs[3], -0.09, z + 0.06), 0.01, 0.06)
        k.add(lambda p: np.minimum(box(p, v3(xs[4], -0.09, z - 0.2), (0.016, 0.006, 0.2)), cap(p, v3(xs[4], -0.09, z - 0.4), v3(xs[4], -0.09, z - 0.52), 0.016)), "steel")      # 줄
        k.add(lambda p: np.minimum(cap(p, v3(xs[6], -0.09, z + 0.03), v3(xs[6], -0.09, z - 0.3), 0.012), cone(p * v3(1, 1, -1) + v3(0, 0, 2 * (z - 0.3)), v3(xs[6], -0.09, z - 0.3), 0.02, 0.12)), "iron")   # 정
    _hammer_v(k, xs[5], -0.09, z + 0.035, 0.5, 0.075)
    return {"shadow": 0.0}


@prop("smith_tools", "smithy", cell=(2, 2), tags=["workshop", "iron"], name_ko="망치와 집게",
    variants={"block": {}, "hot_iron": {"state": "hot_iron"}, "scattered": {"state": "scattered"}}, light={"color": HOT, "radius": 1.2, "at": (0.2, 0, 0.1), "flicker": 0.1, "variants": ["hot_iron"]})
def smith_tools(k, state="block", seed=1):
    if state == "block":       # 나무토막 위에 놓인 망치 둘과 집게
        k.add(rough(lambda p: box(p, v3(0, 0, 0.12), (0.3, 0.2, 0.12), 0.02), 0.02, 0.15, seed), "wood_d")
        k.add(lambda p: np.minimum(hcyl(p, v3(-0.22, -0.06, 0.262), v3(0.12, -0.1, 0.262), 0.016), box(rot_z(p, -0.12, (0.14, -0.1, 0)), v3(0.14, -0.1, 0.275), (0.04, 0.08, 0.035), 0.008)), "iron")
        k.add(lambda p: hcyl(p, v3(-0.2, -0.06, 0.262), v3(0.08, -0.095, 0.262), 0.017), "wood_l")
        _tongs(k, v3(-0.24, 0.1, 0.252), v3(0.26, 0.06, 0.252))
        k.add(lambda p: np.minimum(cap(p, v3(0.42, -0.1, 0.02), v3(0.36, 0.0, 0.5), 0.018), box(rot_x(p, 0.2, (0.36, 0, 0.5)), v3(0.36, 0, 0.5), (0.085, 0.045, 0.05), 0.01)), "iron")   # 기대 세운 큰 메
        k.add(lambda p: cap(p, v3(0.42, -0.1, 0.02), v3(0.365, -0.01, 0.44), 0.019), "wood")
    elif state == "hot_iron":  # 달군 쇠를 문 집게
        _tongs(k, v3(-0.42, -0.1, 0.02), v3(0.1, 0.02, 0.03), 0.013, 0.06)
        k.add(lambda p: box(rot_z(p, 0.25, (0.1, 0.02, 0)), v3(0.28, 0.02, 0.03), (0.2, 0.024, 0.018), 0.004), "ember")
        k.add(lambda p: pool(p, v3(0.3, 0.04, 0.004), 0.2, 0.08, 0.004), "coal")
        return {"glow": [(0.3, 0.04, 0.04, 26, HOT, 0.5)], "shadow": 0.3}
    else:
        _tongs(k, v3(-0.4, 0.12, 0.014), v3(0.05, -0.12, 0.014))
        k.add(lambda p: np.minimum(hcyl(p, v3(0.0, 0.2, 0.018), v3(0.34, 0.1, 0.018), 0.016), box(rot_z(p, -0.28, (0.36, 0.09, 0)), v3(0.36, 0.09, 0.035), (0.04, 0.075, 0.034), 0.008)), "iron")
        k.add(lambda p: hcyl(p, v3(0.0, 0.2, 0.018), v3(0.3, 0.11, 0.018), 0.017), "wood_l")
        k.add(lambda p: np.minimum(box(rot_z(p, 0.6, (0.25, -0.2, 0)), v3(0.25, -0.2, 0.008), (0.16, 0.014, 0.007)), cap(p, v3(0.1, -0.3, 0.014), v3(0.02, -0.36, 0.014), 0.016)), "steel")
        k.add(lambda p: torus(p, v3(-0.2, -0.22, 0.012), 0.05, 0.012), "iron")
    return {}


@prop("post_vise", "smithy", cell=(2, 3), collide=(0.4, 0.4), tags=["workshop", "iron"], name_ko="기둥 바이스", variants={"base": {}, "work": {"state": "work"}})
def post_vise(k, state="base", seed=1):
    k.add(rough(lambda p: box(p, v3(0, 0.05, 0.42), (0.1, 0.1, 0.42), 0.015), 0.015, 0.2, seed), "wood_d")
    k.add(lambda p: np.minimum.reduce([box(p, v3(0, -0.07, 0.72), (0.035, 0.022, 0.22), 0.008), box(p, v3(0, -0.16, 0.74), (0.035, 0.02, 0.2), 0.008), box(p, v3(0, -0.07, 0.94), (0.09, 0.03, 0.035), 0.008),
        box(p, v3(0, -0.16, 0.94), (0.09, 0.028, 0.035), 0.008), hcyl(p, v3(0, -0.3, 0.8), v3(0, 0.0, 0.8), 0.02), hcyl(p, v3(-0.16, -0.3, 0.8), v3(0.16, -0.3, 0.8), 0.011),
        cap(p, v3(0, -0.16, 0.55), v3(0, -0.07, 0.1), 0.02)]), "iron")
    if state == "work":
        k.add(lambda p: box(p, v3(0.02, -0.115, 1.12), (0.028, 0.008, 0.18)), "steel")
    return {}


# ── 재료 ─────────────────────────────────────────────────────────────────────

@prop("ingots", "smithy", cell=(2, 2), collide=(0.5, 0.4), tags=["workshop", "metal", "storage"], name_ko="금속 주괴", interact="container",
    variants={"iron_stack": {}, "copper_pallet": {"state": "copper_pallet"}, "steel_bars": {"state": "steel_bars"}, "loose": {"state": "loose"}})
def ingots(k, state="iron_stack", seed=1):
    _mats(k)
    if state == "iron_stack":       # 피라미드 쌓기
        for lv, n in enumerate((4, 3, 2)):
            for i in range(n):
                _ingot(k, v3((i - (n - 1) / 2) * 0.115, 0, lv * 0.068), 0.05, 0.16, 0.034, 0.0, "iron")
    elif state == "copper_pallet":  # 깔판 위에 엇갈려 쌓기
        k.add(lambda p: np.minimum(box(p, v3(0, 0, 0.05), (0.34, 0.26, 0.012)), np.minimum(box(p, v3(-0.26, 0, 0.02), (0.03, 0.26, 0.02)), box(p, v3(0.26, 0, 0.02), (0.03, 0.26, 0.02)))), "plank_x")
        for lv in range(3):
            for i in range(3):
                if lv % 2 == 0:
                    _ingot(k, v3((i - 1) * 0.2, 0, 0.062 + lv * 0.066), 0.085, 0.22, 0.033, 0.0, "copper")
                else:
                    _ingot(k, v3(0, (i - 1) * 0.15, 0.062 + lv * 0.066), 0.3, 0.06, 0.033, 0.0, "copper")
        return {"cell": (3, 2)}
    elif state == "steel_bars":     # 긴 봉강 묶음
        for i, (y, z) in enumerate(((-0.08, 0.025), (0.0, 0.025), (0.08, 0.025), (-0.04, 0.07), (0.04, 0.07))):
            dx = k.rng.uniform(-0.05, 0.05)
            k.add(lambda p, y=y, z=z, dx=dx: box(p, v3(dx, y, z), (0.55, 0.03, 0.022), 0.004), "steel")
        k.add(lambda p: np.minimum(box(p, v3(-0.3, 0, 0.05), (0.014, 0.13, 0.052)), box(p, v3(0.3, 0, 0.05), (0.014, 0.13, 0.052))), "leather_d")
        return {"cell": (3, 2)}
    else:
        for i, (x, y, a) in enumerate(((-0.2, -0.05, 0.3), (0.1, 0.08, -0.5), (0.22, -0.12, 1.2))):
            _ingot(k, v3(x, y, 0), 0.12, 0.05, 0.034, a, ("iron", "copper", "iron")[i])
    return {}


@prop("iron_ore", "smithy", cell=(3, 2), collide=(0.8, 0.5), tags=["workshop", "stone", "storage"], name_ko="철광석", interact="container",
    variants={"pile": {}, "crate": {"state": "crate"}, "sacks": {"state": "sacks"}})
def iron_ore(k, state="pile", seed=1):
    _mats(k)
    if state == "pile":
        _heap(k, 26, 0.5, 0.36, 0.34, "ore", 0.06, 0.11, mat2="ore_r")
    elif state == "crate":
        _crate(k, 0.28, seed, False)
        _heap(_move(k, 0, 0, 0.42), 12, 0.22, 0.22, 0.14, "ore", 0.05, 0.085, mat2="ore_r")
        k.rubble([(0.45, -0.2), (0.52, -0.05), (-0.42, -0.28)], "ore_r", 0.05, 0.08)
        return {"cell": (3, 3)}
    else:
        from a_furniture import _sack
        _sack(k, v3(-0.22, 0.05, 0), 0.95, seed, "cloth", -0.15)
        k.add(rough(lambda p: sub(smin(ell(p, v3(0.24, 0, 0.16), (0.22, 0.18, 0.18)), ell(p, v3(0.24, 0, 0.06), (0.24, 0.2, 0.08)), 0.05), cyl(p, v3(0.24, 0, 0.24), 0.15, 0.3)), 0.02, 0.1, seed), "cloth")
        _heap(_move(k, 0.24, 0, 0.2), 8, 0.14, 0.12, 0.1, "ore", 0.04, 0.065, mat2="ore_r")
        k.rubble([(0.5, -0.22), (0.02, -0.28)], "ore", 0.04, 0.07)
    return {}


@prop("coal_pile", "smithy", cell=(3, 2), collide=(0.8, 0.5), tags=["workshop", "fire", "storage"], name_ko="석탄 더미",
    variants={"pile": {}, "bin": {"state": "bin"}, "shovel": {"state": "shovel"}})
def coal_pile(k, state="pile", seed=1):
    if state == "bin":      # 앞이 낮은 나무 석탄 칸
        w, d = 0.5, 0.36
        k.add(rough(lambda p: np.minimum.reduce([box(p, v3(0, d, 0.3), (w, 0.025, 0.3)), box(p, v3(-w, 0, 0.3), (0.025, d, 0.3)), box(p, v3(w, 0, 0.3), (0.025, d, 0.3)), box(p, v3(0, -d, 0.13), (w, 0.025, 0.13))]), 0.01, 0.2, seed), "plank_xd")
        k.add(lambda p: np.minimum.reduce([box(p, v3(s * w, t * d, 0.31), (0.04, 0.04, 0.31), 0.008) for s in (-1, 1) for t in (-1, 1)]), "wood_d")
        _heap(k, 26, 0.44, 0.3, 0.42, "coal", 0.045, 0.08, 0, 0.04)
        k.rubble([(-0.2, -0.5), (0.3, -0.46), (0.05, -0.56)], "coal", 0.03, 0.05)
        return {"cell": (3, 3)}
    _heap(k, 30, 0.5, 0.36, 0.3, "coal", 0.045, 0.085)
    k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.62, 0.46, 0.004) + (sdf.noise(p, 0.07, seed) - 0.5) * 0.1, "ash")
    if state == "shovel":
        k.add(lambda p: cap(p, v3(0.2, -0.3, 0.1), v3(0.75, -0.5, 0.75), 0.02), "wood_l")
        k.add(lambda p: np.maximum(box(rot_y(p, -0.85, (0.2, -0.3, 0.1)), v3(0.12, -0.3, 0.1), (0.13, 0.1, 0.012), 0.008), -1), "iron")
        k.add(lambda p: hcyl(p, v3(0.7, -0.5, 0.75), v3(0.82, -0.5, 0.74), 0.022), "wood_l")
        return {"cell": (3, 3)}
    return {}


def _log(t, a, b, r=0.07):
    a, b = np.asarray(a, F), np.asarray(b, F)
    d = (b - a) / np.sqrt(((b - a) ** 2).sum())
    t.add(rough(lambda p: hcyl(p, a, b, r), 0.012, 0.08, int(abs(a[0] * 97 + a[2] * 31)) + 1), "bark")
    t.add(lambda p: np.minimum(hcyl(p, a - d * 0.006, a + d * 0.02, r * 0.82), hcyl(p, b - d * 0.02, b + d * 0.006, r * 0.82)), "log_end")


@prop("firewood", "smithy", cell=(3, 3), collide=(1.2, 0.5), tags=["wood", "fire", "storage", "home"], name_ko="장작",
    variants={"cord": {}, "pile": {"state": "pile"}, "block": {"state": "block"}})
def firewood(k, state="cord", seed=1):
    _mats(k)
    if state == "cord":       # 두 말뚝 사이에 쌓은 장작(마구리가 앞을 본다)
        for s in (-1, 1):
            k.add(lambda p, s=s: box(p, v3(s * 0.58, 0, 0.4), (0.03, 0.03, 0.4), 0.008), "wood_d")
        k.add(lambda p: box(p, v3(0, 0, 0.02), (0.6, 0.2, 0.02)), "wood_d")
        for row in range(5):
            n = 7 if row % 2 == 0 else 6
            for i in range(n):
                r = k.rng.uniform(0.062, 0.078)
                x = (i - (n - 1) / 2) * 0.155 + k.rng.uniform(-0.01, 0.01)
                _log(k, v3(x, -0.24 + k.rng.uniform(-0.03, 0.03), 0.11 + row * 0.128), v3(x, 0.24, 0.11 + row * 0.128), r)
    elif state == "pile":
        for i in range(9):
            a = k.rng.uniform(0, PI)
            x, y, z = k.rng.uniform(-0.3, 0.3), k.rng.uniform(-0.15, 0.15), 0.07 + (i // 4) * 0.11
            _log(k, v3(x - np.cos(a) * 0.24, y - np.sin(a) * 0.2, z), v3(x + np.cos(a) * 0.24, y + np.sin(a) * 0.2, z + k.rng.uniform(-0.03, 0.05)), k.rng.uniform(0.055, 0.075))
        return {"cell": (3, 2)}
    else:                     # 장작 패는 그루터기 + 도끼 + 쪼갠 장작
        k.add(rough(lambda p: cyl(p, v3(0, 0, 0), 0.26, 0.36, 0.02), 0.02, 0.15, seed), k.mat("stump", M.rings("#6a5238", "#3e2e22")))
        T = lambda p: rot_y(p, 0.75, (0.02, 0, 0.36))
        k.add(lambda p: cap(T(p), v3(0.02, 0, 0.4), v3(0.02, 0, 1.05), 0.02), "wood")
        k.add(lambda p: np.maximum(box(T(p), v3(0.02, 0, 0.42), (0.035, 0.07, 0.09), 0.006), (np.abs(T(p)[:, 0] - 0.02) * 2.4 - (T(p)[:, 2] - 0.33)) * 0.4), "steel")
        for i, (x, y, a) in enumerate(((-0.55, -0.2, 0.3), (0.5, -0.3, -0.4), (0.62, 0.1, 1.2), (-0.45, 0.15, 2.0))):
            k.add(rough(lambda p, x=x, y=y, a=a: np.maximum(hcyl(rot_z(p, a, (x, y, 0)), v3(x - 0.2, y, 0.02), v3(x + 0.2, y, 0.02), 0.075), -p[:, 2] + 0.0), 0.012, 0.08, seed + i), "log_end" if i % 2 else "bark")
        return {"cell": (3, 3), "collide": (0.55, 0.5)}
    return {}


# ── 진열 ─────────────────────────────────────────────────────────────────────

@prop("shield_rack", "smithy", cell=(3, 3), collide=(1.5, 0.45), tags=["wood", "armory", "shop"], name_ko="방패 거치대", interact="container",
    variants={"full": {}, "half": {"state": "half"}, "empty": {"state": "empty"}})
def shield_rack(k, state="full", seed=1):
    w = 0.7
    for s in (-1, 1):
        k.add(rough(lambda p, s=s: np.minimum.reduce([cap(p, v3(s * w, -0.2, 0), v3(s * w, 0.08, 0.78), 0.03), cap(p, v3(s * w, 0.26, 0), v3(s * w, 0.08, 0.78), 0.03), box(p, v3(s * w, 0.03, 0.03), (0.035, 0.26, 0.03), 0.008)]), 0.008, 0.2, seed), "wood_d")
    k.add(rough(lambda p: np.minimum(hcyl(p, v3(-w, 0.08, 0.76), v3(w, 0.08, 0.76), 0.03), box(p, v3(0, -0.16, 0.06), (w, 0.03, 0.03), 0.008)), 0.008, 0.2, seed), "wood")
    if state != "empty":
        _shield_round(k, v3(-0.42, -0.06, 0.4), 0.27, 0.32)
        if state == "full":
            _shield_heater(k, v3(0.08, -0.07, 0.38), 0.3)
            _shield_round(k, v3(0.5, -0.06, 0.34), 0.21, 0.32, "steel")
        else:
            _shield_heater(k, v3(0.4, -0.07, 0.38), 0.3, "plank_y", "iron")
    return {}


@prop("sword_display", "smithy", layer="wall_decal", cell=(3, 3), tags=["armory", "shop", "wall"], name_ko="검 진열대", interact="container",
    variants={"full": {}, "sparse": {"state": "sparse"}, "empty": {"state": "empty"}}, meta={"note": "벽에 거는 진열판 — 가로로 건 검"})
def sword_display(k, state="full", seed=1):
    k.add(rough(lambda p: box(p, v3(0, -0.015, 1.3), (0.72, 0.016, 0.42), 0.01), 0.008, 0.2, seed), "plank_xd")
    k.add(lambda p: sub(box(p, v3(0, -0.02, 1.3), (0.76, 0.024, 0.46), 0.01), box(p, v3(0, -0.02, 1.3), (0.7, 0.1, 0.4))), "wood")
    zs = (1.56, 1.3, 1.04)
    k.add(lambda p: np.minimum.reduce([hcyl(p, v3(x, -0.03, z - 0.035), v3(x, -0.1, z - 0.03), 0.012) for z in zs for x in (-0.4, 0.3)]), "brass")
    if state == "empty":
        return {"shadow": 0.0}
    _hsword(k, -0.06, -0.075, zs[0], 0.92, "steel", "leather_d", 1)
    if state == "full":
        _hsword(k, 0.02, -0.075, zs[1], 0.74, "steel", "cloth_r", -1)
        k.add(lambda p: np.maximum(box(p, v3(-0.12, -0.075, zs[2] - 0.0), (0.3, 0.007, 0.03)), (p[:, 2] - zs[2]) * 0.9 + (-(p[:, 0] + 0.12)) * 0.12 - 0.022) , "steel")     # 외날 검
        k.add(lambda p: np.minimum(hcyl(p, v3(0.2, -0.075, zs[2]), v3(0.36, -0.075, zs[2]), 0.018), box(p, v3(0.19, -0.075, zs[2]), (0.012, 0.016, 0.05), 0.005)), "leather")
    else:
        k.add(lambda p: np.maximum(box(p, v3(-0.16, -0.075, zs[2]), (0.2, 0.007, 0.026)), (np.abs(p[:, 2] - zs[2]) + (-(p[:, 0] + 0.16) - 0.13) * 0.4 - 0.026)), "steel")      # 단검
        k.add(lambda p: np.minimum(hcyl(p, v3(0.06, -0.075, zs[2]), v3(0.17, -0.075, zs[2]), 0.016), box(p, v3(0.05, -0.075, zs[2]), (0.012, 0.016, 0.055), 0.005)), "leather_d")
    return {"shadow": 0.0}


@prop("axe_display", "smithy", cell=(3, 3), collide=(1.1, 0.5), tags=["armory", "shop", "wood"], name_ko="도끼 진열대", interact="container",
    variants={"full": {}, "sparse": {"state": "sparse"}, "empty": {"state": "empty"}}, meta={"note": "뒤로 기운 진열판(이젤) — 머리를 위로 건 도끼"})
def axe_display(k, state="full", seed=1):
    T = lambda p: rot_x(p, 0.3, (0, 0, 0))
    t = _X(k, T)
    t.add(rough(lambda p: box(p, v3(0, 0, 0.62), (0.52, 0.02, 0.56), 0.01), 0.008, 0.2, seed), "plank_y")
    t.add(lambda p: np.minimum(box(p, v3(0, -0.03, 0.1), (0.54, 0.05, 0.02), 0.006), box(p, v3(0, -0.02, 1.16), (0.54, 0.03, 0.03), 0.006)), "wood_d")
    t.add(lambda p: np.minimum.reduce([hcyl(p, v3(x + s, -0.02, 0.92), v3(x + s, -0.09, 0.93), 0.01) for x in (-0.32, 0.0, 0.32) for s in (-0.035, 0.035)]), "iron")
    for s in (-1, 1):
        k.add(lambda p, s=s: cap(p, v3(s * 0.46, 0.34, 1.02), v3(s * 0.46, 0.5, 0), 0.026), "wood_d")
    if state != "empty":
        _vaxe(t, -0.32, -0.06, 0.2, 0.84)
        if state == "full":
            _vaxe(t, 0.0, -0.06, 0.14, 0.92, True)
            _vaxe(t, 0.32, -0.06, 0.34, 0.68)
    return {}


@prop("spear_display", "smithy", cell=(2, 4), collide=(0.6, 0.6), tags=["armory", "shop", "wood"], name_ko="창 진열대", interact="container",
    variants={"full": {}, "sparse": {"state": "sparse"}, "empty": {"state": "empty"}}, meta={"note": "둥근 꽂이 — 긴 자루 무기를 세워 꽂는다"})
def spear_display(k, state="full", seed=1):
    k.add(rough(lambda p: cyl(p, v3(0, 0, 0), 0.28, 0.1, 0.02), 0.01, 0.2, seed), "wood_d")
    for a in (0.6, 2.7, 4.8):
        k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.24, np.sin(a) * 0.22, 0.08), v3(np.cos(a) * 0.24, np.sin(a) * 0.22, 0.9), 0.022), "wood_d")
    k.add(lambda p: torus(p, v3(0, 0, 0.9), 0.24, 0.028), "wood")
    k.add(lambda p: torus(p, v3(0, 0, 0.9), 0.24, 0.012) - 0.022 + np.abs(np.sin(np.arctan2(p[:, 1], p[:, 0]) * 3.0)) * 0.03, "iron")
    if state == "empty":
        return {"cell": (2, 3)}
    def pole(x, y, lx, top, kind):
        a, b = v3(x, y, 0.1), v3(x + lx, y, top)
        k.add(lambda p: cap(p, a, b, 0.017), "wood_l")
        T = lambda p: rot_y(p, -np.arctan2(lx, top - 0.1), b)
        if kind == 0:      # 창
            k.add(lambda p: np.maximum(ell(T(p), b + v3(0, 0, 0.1), (0.045, 0.012, 0.14)), b[2] - 0.02 - T(p)[:, 2]), "steel")
        elif kind == 1:    # 미늘창
            k.add(lambda p: np.minimum.reduce([np.maximum(ell(T(p), b + v3(0, 0, 0.12), (0.03, 0.012, 0.16)), b[2] - 0.02 - T(p)[:, 2]),
                np.maximum(np.maximum(disc_x(T(p), b + v3(0.03, 0, -0.06), 0.15, 0.011), b[0] + 0.02 - T(p)[:, 0]), -disc_x(T(p), b + v3(-0.05, 0, -0.06), 0.1, 0.1)),
                cap(T(p), b + v3(0, 0, -0.06), b + v3(-0.11, 0, -0.1), 0.014, 0.004)]), "steel")
        else:              # 언월도 꼴 날
            k.add(lambda p: np.maximum(np.maximum(disc_x(T(p), b + v3(-0.1, 0, 0.1), 0.2, 0.01), -disc_x(T(p), b + v3(-0.2, 0, 0.12), 0.2, 0.1)), b[2] - 0.03 - T(p)[:, 2]), "steel")
    pole(-0.08, -0.05, -0.12, 1.75, 0)
    if state == "full":
        pole(0.06, -0.08, 0.14, 1.62, 1)
        pole(0.0, 0.08, 0.02, 1.86, 2)
        pole(0.1, 0.02, 0.3, 1.5, 0)
    else:
        pole(0.06, 0.04, 0.16, 1.6, 1)
    return {}


# ── 금속 가공 ────────────────────────────────────────────────────────────────

@prop("crucible", "smithy", cell=(2, 2), collide=(0.4, 0.4), tags=["workshop", "fire", "metal"], name_ko="도가니",
    variants={"molten": {"frames": 4}, "cold": {"state": "cold"}, "spilled": {"state": "spilled"}}, light={"color": HOT, "radius": 2.0, "at": (0, 0, 0.4), "flicker": 0.15, "variants": ["molten"]})
def crucible(k, state="molten", seed=1, f=0):
    clay = k.mat("clay", M.plain("#6a5a50", 0.35, 0.08, 51))
    if state == "spilled":
        t = _X(k, lambda p: rot_y(p - v3(-0.1, 0, 0.14), PI / 2 - 0.2))
        t.add(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.1, 0.15, 0.26), _frustum(p, v3(0, 0, 0.03), 0.08, 0.13, 0.3)), clay)
        k.add(rough(lambda p: pool(p, v3(0.32, -0.05, 0.012), 0.26, 0.14, 0.012), 0.03, 0.08, seed), "iron")
        return {"cell": (3, 2)}
    for a in (0.5, 2.6, 4.7):
        k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.2, np.sin(a) * 0.17, 0), v3(np.cos(a) * 0.14, np.sin(a) * 0.12, 0.2), 0.02), "iron")
    k.add(lambda p: torus(p, v3(0, 0, 0.2), 0.14, 0.018), "iron")
    k.add(lambda p: sub(_frustum(p, v3(0, 0, 0.14), 0.1, 0.16, 0.28), _frustum(p, v3(0, 0, 0.18), 0.08, 0.14, 0.3)), clay)
    k.add(lambda p: cyl(p, v3(0, 0, 0.36), 0.13, 0.012), "ember" if state == "molten" else "iron")
    if state == "molten":
        return {"post": [lambda img, vw: fx.halo(fx.embers(img, *vw.px(0, 0, 0.375), 8, 5, seed, f, "fire"), *vw.px(0, 0, 0.4), 30 + 2 * np.sin(f * 1.57), HOT, 0.5)]}
    return {}


@prop("casting_mold", "smithy", cell=(2, 2), collide=(0.5, 0.4), tags=["workshop", "metal"], name_ko="주물 틀",
    variants={"empty": {}, "poured": {"state": "poured"}, "stack": {"state": "stack"}}, light={"color": HOT, "radius": 1.2, "at": (0, 0, 0.15), "flicker": 0.1, "variants": ["poured"]})
def casting_mold(k, state="empty", seed=1):
    sandm = k.mat("moldsand", M.plain("#4a4038", 0.4, 0.04, 52))

    def mold(t, hot=False):
        t.add(rough(lambda p: sub(box(p, v3(0, 0, 0.06), (0.26, 0.17, 0.06), 0.008), box(p, v3(0, 0, 0.1), (0.235, 0.145, 0.06))), 0.008, 0.2, seed), "plank_xd")
        t.add(lambda p: sub(box(p, v3(0, 0, 0.05), (0.235, 0.145, 0.04)), np.minimum.reduce([box(p, v3(x, 0, 0.09), (0.05, 0.1, 0.025), 0.01) for x in (-0.14, 0.0, 0.14)])), sandm)
        t.add(lambda p: np.minimum.reduce([box(p, v3(x, 0, 0.068), (0.045, 0.095, 0.006)) for x in (-0.14, 0.0, 0.14)]), "ember" if hot else "void")
    if state == "stack":
        mold(k)
        t = _move(k, 0.03, 0.02, 0.125, 0.12)
        t.add(rough(lambda p: box(p, v3(0, 0, 0.06), (0.26, 0.17, 0.06), 0.008), 0.008, 0.2, seed + 1), "plank_xd")
        t.add(lambda p: box(p, v3(0, 0, 0.122), (0.235, 0.145, 0.004)), sandm)
        return {}
    mold(k, state == "poured")
    if state == "poured":
        return {"glow": [(0, 0, 0.1, 30, HOT, 0.45)]}
    return {}


@prop("ironware_heap", "smithy", cell=(2, 2), tags=["workshop", "iron", "shop"], name_ko="편자와 못",
    variants={"horseshoes": {}, "nail_keg": {"state": "nail_keg"}, "chains": {"state": "chains"}})
def ironware_heap(k, state="horseshoes", seed=1):
    shoe = lambda p, c, a, tilt: np.maximum(torus(rot_x(rot_z(p, a, c), tilt, c), c, 0.075, 0.016), -(rot_z(p, a, c)[:, 1] - c[1]) - 0.035)
    if state == "horseshoes":
        for i in range(9):
            c = v3(k.rng.uniform(-0.2, 0.2), k.rng.uniform(-0.14, 0.14), 0.02 + (i // 3) * 0.035)
            k.add(lambda p, c=c, a=k.rng.uniform(0, 6.28), tl=k.rng.uniform(-0.3, 0.3): shoe(p, c, a, tl), "iron" if i % 4 else "rust")
    elif state == "nail_keg":
        _barrel(k, 0.15, 0.36, seed, False)
        k.add(rough(lambda p: cyl(p, v3(0, 0, 0.26), 0.13, 0.03), 0.03, 0.02, seed), "iron")
        for i in range(8):
            x, y, a = k.rng.uniform(0.2, 0.42), k.rng.uniform(-0.28, 0.1), k.rng.uniform(0, PI)
            k.add(lambda p, x=x, y=y, a=a: np.minimum(hcyl(p, v3(x - np.cos(a) * 0.045, y - np.sin(a) * 0.045, 0.008), v3(x + np.cos(a) * 0.045, y + np.sin(a) * 0.045, 0.008), 0.006), sphere(p, v3(x - np.cos(a) * 0.045, y - np.sin(a) * 0.045, 0.01), 0.012)), "iron")
    else:
        from a_light import chain
        k.add(rough(lambda p: ell(p, v3(0, 0, 0.03), (0.22, 0.17, 0.07)), 0.05, 0.05, seed) + 0.0 if False else rough(lambda p: ell(p, v3(0, 0, 0.03), (0.2, 0.15, 0.06)), 0.06, 0.045, seed), "iron")
        for i in range(5):
            a = i * 1.3
            k.add(chain(v3(np.cos(a) * 0.16, np.sin(a) * 0.12, 0.07), v3(np.cos(a + 1.5) * 0.2, np.sin(a + 1.5) * 0.15, 0.05 + (i % 2) * 0.04), 0.02), "iron" if i % 2 else "rust")
        k.add(chain(v3(0.15, -0.08, 0.05), v3(0.45, -0.22, 0.015), 0.02), "iron")
    return {}


@prop("blade_blanks", "smithy", cell=(2, 3), collide=(0.45, 0.4), tags=["workshop", "armory", "metal"], name_ko="벼리다 만 칼날", variants={"bucket": {}, "bundle": {"state": "bundle"}})
def blade_blanks(k, state="bucket", seed=1):
    if state == "bucket":      # 통에 세워 꽂은 날
        _barrel(k, 0.17, 0.4, seed, False, "wood_d")
        k.add(lambda p: cyl(p, v3(0, 0, 0.3), 0.15, 0.01), "void")
        for i, (x, y, top, lean) in enumerate(((-0.06, 0.0, 1.0, -0.12), (0.05, -0.04, 0.86, 0.14), (0.02, 0.06, 1.1, 0.03), (-0.02, -0.07, 0.74, -0.05))):
            T = lambda p, x=x, y=y, lean=lean: rot_y(p, lean, (x, y, 0.2))
            k.add(lambda p, T=T, x=x, y=y, top=top: np.minimum(np.maximum(box(T(p), v3(x, y, (top + 0.3) / 2), (0.03, 0.007, (top - 0.3) / 2)), (np.abs(T(p)[:, 0] - x) * 1.0 + (T(p)[:, 2] - top) * 0.5 + 0.0 - 0.03)),
                box(T(p), v3(x, y, 0.3), (0.012, 0.007, 0.1))), "steel" if i % 2 == 0 else "iron")
    else:
        for i, (y, z, dx) in enumerate(((-0.05, 0.012, 0.0), (0.03, 0.012, 0.06), (-0.01, 0.03, -0.04))):
            k.add(lambda p, y=y, z=z, dx=dx: np.minimum(np.maximum(box(p, v3(dx, y, z), (0.36, 0.03, 0.007)), (np.abs(p[:, 1] - y) + (p[:, 0] - dx - 0.36) * 0.4 + 0.03 - 0.03)), box(p, v3(dx - 0.42, y, z), (0.08, 0.011, 0.007))), "iron" if i else "steel")
        k.add(lambda p: np.minimum(box(p, v3(-0.15, -0.01, 0.022), (0.014, 0.08, 0.026)), box(p, v3(0.15, -0.01, 0.022), (0.014, 0.08, 0.026))), "rope")
        return {"cell": (2, 2), "collide": None}
    return {}


# ── 걸이 · 양동이 ────────────────────────────────────────────────────────────

@prop("smithy_wall_hang", "smithy", layer="wall_decal", cell=(2, 3), tags=["workshop", "iron", "wall"], name_ko="벽에 건 편자와 사슬",
    variants={"horseshoes": {}, "chains": {"state": "chains"}, "apron": {"state": "apron"}})
def smithy_wall_hang(k, state="horseshoes", seed=1):
    from a_light import chain
    if state == "horseshoes":
        k.add(rough(lambda p: box(p, v3(0, -0.015, 1.5), (0.42, 0.015, 0.035), 0.005), 0.006, 0.2, seed), "plank_x")
        for i, x in enumerate((-0.3, -0.1, 0.1, 0.3)):
            c = v3(x, -0.05, 1.4 - (i % 2) * 0.02)
            k.add(lambda p, c=c: np.minimum(np.maximum(ring_x(p, c, 0.07, 0.015), p[:, 2] - c[2] - 0.045 + 0.0 * p[:, 0]) if False else np.maximum(ring_x(p, c, 0.07, 0.015), c[2] - 0.035 - p[:, 2]) , hcyl(p, v3(c[0], -0.02, c[2] + 0.085), v3(c[0], -0.09, c[2] + 0.09), 0.009)), "iron" if i != 2 else "rust")
    elif state == "chains":
        k.add(lambda p: np.minimum(hcyl(p, v3(-0.2, -0.01, 1.7), v3(-0.2, -0.1, 1.72), 0.014), hcyl(p, v3(0.2, -0.01, 1.7), v3(0.2, -0.1, 1.72), 0.014)), "iron")
        k.add(chain(v3(-0.2, -0.08, 1.7), v3(-0.22, -0.08, 1.0), 0.024), "iron")
        k.add(chain(v3(-0.16, -0.08, 1.7), v3(-0.02, -0.08, 1.3), 0.024), "iron")
        k.add(chain(v3(-0.02, -0.08, 1.3), v3(0.18, -0.08, 1.7), 0.024), "rust")
        k.add(chain(v3(0.22, -0.08, 1.7), v3(0.24, -0.08, 1.2), 0.024), "iron")
        k.add(lambda p: np.maximum(ring_x(p, v3(0.24, -0.08, 1.14), 0.05, 0.014), 0), "iron")
    else:                      # 못에 건 가죽 앞치마 + 장갑
        k.add(lambda p: hcyl(p, v3(0, -0.01, 1.62), v3(0, -0.1, 1.64), 0.014), "iron")
        k.add(rough(lambda p: np.maximum(box(p, v3(0, -0.06, 1.12), (0.24 - (p[:, 2] > 1.38) * 0.1, 0.02, 0.44), 0.02) + np.sin(p[:, 0] * 26.0) * 0.006, -1), 0.02, 0.12, seed), "leather")
        k.add(lambda p: np.maximum(ring_x(p, v3(0, -0.06, 1.6), 0.07, 0.01), 1.56 - p[:, 2]), "leather_d")
        k.add(rough(lambda p: smin(ell(p, v3(0.3, -0.05, 1.42), (0.06, 0.03, 0.1)), cap(p, v3(0.3, -0.05, 1.5), v3(0.3, -0.05, 1.58), 0.05, 0.06), 0.02), 0.01, 0.06, seed), "leather_d")
        k.add(lambda p: hcyl(p, v3(0.3, -0.01, 1.6), v3(0.3, -0.08, 1.61), 0.01), "iron")
    return {"shadow": 0.0}


@prop("water_bucket", "smithy", cell=(2, 2), collide=(0.36, 0.36), tags=["wood", "water", "home"], name_ko="물 양동이",
    variants={"full": {}, "empty": {"state": "empty"}, "toppled": {"state": "toppled"}})
def water_bucket(k, state="full", seed=1):
    _mats(k)
    t = k if state != "toppled" else _X(k, lambda p: rot_y(p - v3(0.05, 0, 0.17), PI / 2 - 0.1))
    t.add(rough(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.13, 0.17, 0.3), _frustum(p, v3(0, 0, 0.03), 0.11, 0.15, 0.4)), 0.008, 0.15, seed), "wood")
    t.add(lambda p: np.minimum(np.maximum(np.hypot(p[:, 0], p[:, 1]) - 0.148, np.abs(p[:, 2] - 0.08) - 0.016), np.maximum(np.hypot(p[:, 0], p[:, 1]) - 0.168, np.abs(p[:, 2] - 0.24) - 0.016)) , "iron")
    if state == "toppled":
        k.add(lambda p: pool(p, v3(-0.36, -0.05, 0.004), 0.28, 0.18, 0.004) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.08, "water")
        return {"cell": (3, 2), "collide": None}
    t.add(lambda p: np.maximum(ring_x(p, v3(0, 0, 0.29), 0.165, 0.009), 0.29 - p[:, 2]), "iron")
    t.add(lambda p: cyl(p, v3(0, 0, 0.24 if state == "full" else 0.04), 0.14, 0.01), "water" if state == "full" else "void")
    return {}


# ── 벽 그을음 · 불티 · 연기 ──────────────────────────────────────────────────

@flat("wall_soot", "smithy", layer="wall_decal", cell=(128, 160), tags=["fire", "wall", "trace"], name_ko="벽 그을음",
    variants={"plume": {"seed": 3}, "heavy": {"seed": 8, "heavy": True}, "streak": {"seed": 14, "streak": True}}, meta={"note": "화덕 · 벽난로 · 횃불 위 벽에 — 원점 = 벽 밑동, 위로 번진다"})
def wall_soot(c, heavy=False, streak=False, seed=1):
    c.origin = (64, 160)
    t = (160 - c.yy) / 160.0                                   # 0 밑동 → 1 벽 머리
    half = (16 if streak else 26) + t * (20 if streak else (60 if heavy else 44))
    m = sstep(1.0 - np.abs(c.xx - 64 - np.sin(t * 5 + seed) * 5) / half, 0, 0.75) * sstep(t, 0.02, 0.3)
    m = m * (0.45 + c.noise(14, seed + 1) * 0.75) * (1.0 if heavy else 0.8)
    m = np.clip(m * (0.6 + 0.4 * sstep(c.noise(3.0, seed + 2), 0.2, 0.7)), 0, 1)
    c.paint(m, "#0e0c0b", 0.85 if heavy else 0.7)
    c.paint(m * sstep(c.noise(5.0, seed + 3) - 0.6, 0, 0.1) * sstep(t, 0.5, 0.9), "#5a5650", 0.3)       # 떠 붙은 재


@flat("forge_sparks", "smithy", layer="over", cell=(96, 96), tags=["fire", "particle", "animated"], name_ko="대장간 불티", fps=8,
    variants={"hammer": {"kind": "hammer", "frames": 4}, "rising": {"kind": "rising", "frames": 4}}, meta={"note": "hammer = 모루에서 튀는 불티(원점 = 맞는 자리) · rising = 화덕에서 오르는 불티(원점 = 불 위)"})
def forge_sparks(c, kind="hammer", f=0, seed=1):
    c.graded = False
    f = f or 0
    rng = np.random.default_rng(seed + 7)
    if kind == "hammer":
        ox, oy = 48, 70
        for i in range(26):
            a, sp = rng.uniform(-PI * 0.95, -PI * 0.05), rng.uniform(9, 26)
            t0 = (f + 1) * 0.5 + rng.uniform(-0.15, 0.15)
            x, y = ox + np.cos(a) * sp * t0, oy + np.sin(a) * sp * t0 + 5.0 * t0 * t0
            x1, y1 = ox + np.cos(a) * sp * (t0 - 0.28), oy + np.sin(a) * sp * (t0 - 0.28) + 5.0 * (t0 - 0.28) ** 2
            fade = max(0.0, 1.0 - f * 0.22)
            c.add(c.seg([(x1, y1), (x, y)], 1.6, False), "#ff9a30", 0.9 * fade)
            c.add(sstep(1.0 - c.dist(x, y, 1.6), 0, 0.8), "#fff0b0", fade)
        c.add(sstep(1.0 - c.dist(ox, oy, 11 - f * 2.5), 0, 1), "#ffb040", max(0, 0.8 - f * 0.28))
        c.origin = (ox, oy)
    else:
        for i in range(18):
            x0, ph, sp = rng.uniform(26, 70), rng.uniform(0, 1), rng.uniform(0.7, 1.3)
            t0 = (ph + f / 4.0) % 1.0
            x, y = x0 + np.sin(t0 * 6 + i) * 5, 90 - t0 * 82 * sp
            fade = (1 - t0) ** 0.7
            c.add(sstep(1.0 - c.dist(x, y, 3.2), 0, 1), "#c03a10", 0.5 * fade)
            c.add(sstep(1.0 - c.dist(x, y, 1.3, 1.9), 0, 0.7), "#ffb850", fade)
        c.origin = (48, 92)


@flat("forge_smoke", "smithy", layer="over", cell=(96, 160), tags=["fire", "smoke", "animated"], name_ko="대장간 연기", fps=6,
    variants={"thin": {"frames": 4}, "thick": {"thick": True, "frames": 4}}, meta={"note": "원점 = 연기가 나는 자리(굴뚝 · 화덕 위). 위로 퍼지며 옅어진다"})
def forge_smoke(c, thick=False, f=0, seed=1):
    c.graded = False
    f = f or 0
    img = np.zeros((c.h, c.w, 4), np.uint8)
    for j, (col, al, r) in enumerate((("#2e2c2c", 0.5, 15), ("#5a5856", 0.36, 11), ("#8a8680", 0.2, 7)) if thick else (("#4a4846", 0.34, 11), ("#84807a", 0.2, 7))):
        img = fx.puff(img, 48 + np.sin(f * 1.57 + j) * 3, 150, r, col, al, seed + j * 3, f, 128 - j * 16, 9)
    c.origin = (48, 152)
    return img
