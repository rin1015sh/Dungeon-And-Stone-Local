"""여관 전용 물건: 여관 카운터 · 술통 · 술통 거치대 · 주방 작업대 · 식기 선반 · 조리 화덕(꼬치 굽기) · 음식이 놓인 테이블 · 침구 더미 · 담요 ·
열쇠 걸이 판 · 외투 걸이 · 걸어 둔 부엌살림 · 세면대 · 술병 선반.
공용 가구(탁자 · 의자 · 긴 의자 · 침대 · 벽난로 · 솥 · 식기 · 병 · 나무통 · 촛대)는 a_furniture · a_light의 것을 그대로 쓴다."""
import numpy as np

from kit import (F, box, cap, cone, cyl, ell, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from a_furniture import _X, _barrel, _bottle, _candle, _cup, _frustum, _move, _plate, _table
from a_light import flame_post
import fx

PI = np.pi
FIRE = "#f0a040"


def many(fns):
    return lambda p: np.minimum.reduce([f(p) for f in fns])


def inn_mats(k):
    k.mat("ale", M.plain("#8a6a2c", 0.2, 0.1, 61))
    k.mat("foam", M.plain("#c8bea4", 0.15, 0.1, 62))
    k.mat("bread", M.plain("#8a6238", 0.35, 0.05, 63))
    k.mat("roast", M.plain("#6a3a22", 0.45, 0.05, 64))
    k.mat("veg", M.plain("#5a6a34", 0.4, 0.05, 65))
    k.mat("carrot", M.plain("#9a5a28", 0.35, 0.05, 66))
    k.mat("onion", M.plain("#b09a70", 0.3, 0.05, 67))
    k.mat("sausage", M.plain("#6a3428", 0.4, 0.05, 68))
    k.mat("flour", M.plain("#c4bca6", 0.15, 0.1, 69))
    k.mat("blanket_r", M.plain("#6a3430", 0.3, 0.08, 70))
    k.mat("blanket_b", M.plain("#3e4a5a", 0.3, 0.08, 71))
    k.mat("wool", M.plain("#8a7c62", 0.35, 0.06, 72))
    k.mat("copper", M.metal("#8a5a3a", "#4a5a48", 73, 0.25))
    k.mat("water", M.plain("#3e5a64", 0.2, 0.2, 74))
    return k


def tankard(t, x, y, z, s=1.0, full=True):
    """나무 술잔: 쇠테 두른 통 + 손잡이(+ 거품)."""
    t.add(lambda p: sub(_frustum(p, v3(x, y, z), 0.04 * s, 0.035 * s, 0.1 * s), cyl(p, v3(x, y, z + 0.02 * s), 0.028 * s, 0.1 * s)), "wood_l")
    t.add(lambda p: np.maximum(ring_x(p, v3(x + 0.045 * s, y, z + 0.05 * s), 0.028 * s, 0.008), x + 0.03 * s - p[:, 0]), "wood_d")
    t.add(lambda p: np.maximum(np.hypot(p[:, 0] - x, p[:, 1] - y) - 0.041 * s, np.abs(p[:, 2] - z - 0.075 * s) - 0.006), "iron")
    if full:
        t.add(rough(lambda p: ell(p, v3(x, y, z + 0.095 * s), (0.034 * s, 0.034 * s, 0.018 * s)), 0.01, 0.02, 3), "foam")


def keg(t, x, y, z, r=0.17, ln=0.46, tap=True, seed=1):
    """누운 작은 술통: x축으로 눕힌 통 + 앞마구리 꼭지."""
    T = lambda p: rot_y(p - v3(x, y, z + r + 0.02), PI / 2)
    rad = lambda q: np.hypot(q[:, 0], q[:, 1]) - (r + 0.03 * np.sin(PI * np.clip(q[:, 2] / ln + 0.5, 0, 1)))
    body = lambda p: np.maximum(rad(T(p)), np.abs(T(p)[:, 2]) - ln / 2)
    t.add(rough(body, 0.008, 0.2, seed), "wood")
    t.add(lambda p: np.minimum.reduce([np.maximum(rad(T(p)) - 0.008, np.abs(T(p)[:, 2] - zz) - 0.016) for zz in (-ln * 0.38, -ln * 0.12, ln * 0.12, ln * 0.38)]), "iron")
    if tap:   # 꼭지는 앞(−y)으로
        t.add(lambda p: np.minimum(cap(p, v3(x - ln * 0.2, y - r * 0.9, z + r * 0.75), v3(x - ln * 0.2, y - r - 0.08, z + r * 0.75), 0.016),
            cap(p, v3(x - ln * 0.2, y - r - 0.07, z + r * 0.75), v3(x - ln * 0.2, y - r - 0.07, z + r * 0.55), 0.012)), "brass")


def cradle(t, x, y, w, h=0.12):
    """술통 받침(앞뒤 오목한 나무 받침 둘)."""
    for sx in (-1, 1):
        t.add(lambda p, sx=sx: sub(box(p, v3(x + sx * w, y, h / 2), (0.03, 0.2, h / 2), 0.005), cyl(rot_x(p, PI / 2, (x + sx * w, y, h + 0.12)), v3(x + sx * w, y - 0.3, h + 0.12), 0.15, 0.6)), "wood_d")


# ── 카운터 · 술통 ──────────────────────────────────────────────────────────────

@prop("inn_bar", "inn", cell=(5, 4), collide=(2.3, 0.6), tags=["wood", "inn", "counter"], name_ko="여관 카운터", interact="counter",
    variants={"straight": {}, "taps": {"state": "taps"}, "mugs": {"state": "mugs"}, "corner": {"state": "corner"}})
def inn_bar(k, state="straight", seed=1):
    """두꺼운 판자 앞판 + 손 닿아 반들한 상판 + 발걸이 막대. taps = 상판 뒤 꼭지 단 술통 둘, mugs = 늘어선 술잔."""
    inn_mats(k)
    w, d, h = 1.1, 0.28, 0.66
    if state == "corner":   # ㄱ자: 오른쪽 끝이 뒤로 꺾인다
        k.add(rough(lambda p: np.minimum(box(p, v3(-0.2, 0, h / 2), (0.86, d - 0.02, h / 2 - 0.03), 0.01), box(p, v3(0.66, 0.5, h / 2), (d - 0.02, 0.78, h / 2 - 0.03), 0.01)), 0.008, 0.2, seed), "plank_y")
        k.add(rough(lambda p: np.minimum(box(p, v3(-0.2, 0, h), (0.9, d + 0.04, 0.03), 0.01), box(p, v3(0.66, 0.48, h), (d + 0.04, 0.82, 0.03), 0.01)), 0.006, 0.2, seed + 1), "wood_l")
        k.add(lambda p: np.minimum(hcyl(p, v3(-1.05, -d - 0.06, 0.12), v3(0.36, -d - 0.06, 0.12), 0.016), hcyl(p, v3(0.36, -d - 0.06, 0.12), v3(0.36, 1.2, 0.12), 0.016)), "brass")
        tankard(k, -0.5, 0.0, h + 0.03)
        return {}
    k.add(rough(lambda p: box(p, v3(0, 0, h / 2), (w, d - 0.02, h / 2 - 0.03), 0.01), 0.008, 0.2, seed), "plank_y")
    k.add(lambda p: np.minimum.reduce([box(p, v3(x, -d + 0.02, h / 2), (0.045, 0.03, h / 2 - 0.02), 0.006) for x in (-w + 0.05, -0.36, 0.36, w - 0.05)]), "wood_d")
    k.add(rough(lambda p: box(p, v3(0, 0, h), (w + 0.05, d + 0.05, 0.03), 0.01), 0.006, 0.2, seed + 1), "wood_l")
    k.add(lambda p: np.minimum(hcyl(p, v3(-w, -d - 0.07, 0.12), v3(w, -d - 0.07, 0.12), 0.016), np.minimum.reduce([cap(p, v3(x, -d - 0.07, 0.12), v3(x, -d + 0.01, 0.12), 0.012) for x in (-w + 0.1, 0, w - 0.1)])), "brass")
    if state == "taps":
        for i, x in enumerate((-0.55, 0.35)):
            k.add(lambda p, x=x: np.minimum(box(p, v3(x - 0.2, 0.18, h + 0.05), (0.03, 0.12, 0.05)), box(p, v3(x + 0.2, 0.18, h + 0.05), (0.03, 0.12, 0.05))), "wood_d")
            keg(k, x, 0.18, h + 0.04, 0.15, 0.42, True, seed + i)
        tankard(k, -0.05, -0.08, h + 0.03)
    elif state == "mugs":
        for i, x in enumerate((-0.8, -0.55, -0.3, 0.15, 0.5)):
            tankard(k, x, -0.06 + (i % 2) * 0.08, h + 0.03, 1.0, i % 3 != 1)
        k.add(lambda p: box(p, v3(0.82, 0.02, h + 0.035), (0.12, 0.1, 0.006)), "linen")
    return {}


@prop("inn_keg", "inn", cell=(2, 2), collide=(0.6, 0.45), tags=["wood", "inn", "drink"], name_ko="꼭지 단 술통", interact="container",
    variants={"tapped": {}, "plain": {"state": "plain"}, "drip": {"state": "drip"}})
def inn_keg(k, state="tapped", seed=1):
    inn_mats(k)
    cradle(k, 0, 0, 0.17)
    keg(k, 0, 0, 0.06, 0.18, 0.5, state != "plain", seed)
    if state == "drip":
        k.add(lambda p: pool(p, (-0.1, -0.3, 0), 0.12, 0.07), "ale")
        k.add(lambda p: _frustum(p, v3(-0.1, -0.28, 0), 0.05, 0.06, 0.09), "wood_l")
    return {}


@prop("keg_rack", "inn", cell=(3, 4), collide=(1.2, 0.5), tags=["wood", "inn", "drink", "storage"], name_ko="술통 거치대", interact="container",
    variants={"full": {}, "tapped": {"state": "tapped"}, "empty": {"state": "empty"}})
def keg_rack(k, state="full", seed=1):
    """두 단 나무 거치대: 단마다 누운 술통 둘."""
    inn_mats(k)
    w, d = 0.56, 0.24
    k.add(many([lambda p, x=x, y=y: box(p, v3(x, y, 0.55), (0.035, 0.035, 0.55)) for x in (-w, 0, w) for y in (-d, d)]), "wood_d")
    k.add(many([lambda p, z=z, y=y: box(p, v3(0, y, z), (w + 0.03, 0.03, 0.025)) for z in (0.08, 0.56) for y in (-d, d)]), "wood")
    if state != "empty":
        for j, z in enumerate((0.1, 0.58)):
            for i, x in enumerate((-0.28, 0.28)):
                if state == "tapped" and j == 1 and i == 1:
                    continue
                keg(k, x, 0, z, 0.19, 0.44, state == "tapped" and j == 0, seed + i + j * 2)
    return {}


# ── 부엌 ────────────────────────────────────────────────────────────────────

@prop("kitchen_table", "inn", cell=(4, 3), collide=(1.5, 0.6), tags=["wood", "inn", "kitchen"], name_ko="주방 작업대",
    variants={"clean": {}, "messy": {"state": "messy"}})
def kitchen_table(k, state="clean", seed=1):
    inn_mats(k)
    h = 0.6
    _table(k, 0.72, 0.32, h, seed, top="plank_x")
    k.add(lambda p: box(p, v3(0, 0, 0.12), (0.64, 0.26, 0.015)), "plank_x")                       # 아래 선반
    k.add(lambda p: box(p, v3(-0.32, -0.02, h + 0.015), (0.2, 0.14, 0.014), 0.006), "wood_l")       # 도마
    k.add(lambda p: np.minimum(box(rot_z(p, 0.3, (-0.3, -0.05, 0)), v3(-0.25, -0.05, h + 0.034), (0.1, 0.012, 0.004)), cap(p, v3(-0.42, -0.1, h + 0.034), v3(-0.36, -0.08, h + 0.034), 0.01)), "steel")
    k.add(many([lambda p, x=x: cap(rot_z(p, 0.4 * x), v3(-0.25 + x * 0.05, 0.05, h + 0.045), v3(-0.13 + x * 0.05, 0.05, h + 0.045), 0.016, 0.006) for x in (0, 1)]), "carrot")
    k.add(many([lambda p, x=x: sphere(p, v3(0.25 + x, 0.1, h + 0.05), 0.04) for x in (0.0, 0.09)]), "onion")
    k.add(lambda p: cap(p, v3(0.42, -0.1, h + 0.06), v3(0.62, -0.1, h + 0.06), 0.045), "veg")
    k.add(many([lambda p, i=i: sphere(p, v3(-0.6 + i * 0.07, 0.18, 0.18), 0.05) for i in range(3)]), "onion")
    if state == "messy":
        k.add(rough(lambda p: pool(p, (0.1, -0.05, h + 0.03), 0.16, 0.1, 0.006), 0.01, 0.05, seed), "flour")
        k.add(rough(lambda p: ell(p, v3(0.08, 0.02, h + 0.055), (0.11, 0.08, 0.035)), 0.01, 0.05, seed), "bread")
        k.add(lambda p: cap(p, v3(0.35, -0.2, h + 0.05), v3(0.6, -0.12, h + 0.05), 0.02), "wood_l")   # 밀대
        k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, h + 0.035), 0.012) for x, y in ((-0.6, -0.2), (0.62, 0.15), (-0.05, -0.24))]), "veg")
        k.add(lambda p: pool(p, (-0.4, -0.5, 0), 0.14, 0.08), "flour")
    return {}


@prop("dish_hutch", "inn", cell=(3, 4), collide=(1.2, 0.4), tags=["wood", "inn", "kitchen", "storage"], name_ko="식기 선반", interact="container",
    variants={"full": {}, "sparse": {"state": "sparse"}, "broken": {"state": "broken"}})
def dish_hutch(k, state="full", seed=1):
    """아래는 문짝 달린 장, 위는 접시를 세워 둔 선반."""
    inn_mats(k)
    w, d = 0.56, 0.2
    tilt = 0.12 if state == "broken" else 0.0
    t = _X(k, lambda p: rot_y(p, tilt, (w, 0, 0)))
    t.add(rough(lambda p: box(p, v3(0, 0, 0.3), (w, d, 0.3), 0.01), 0.008, 0.2, seed), "wood_d")
    t.add(lambda p: np.minimum(box(p, v3(-0.27, -d, 0.3), (0.25, 0.012, 0.24), 0.006), box(p, v3(0.27, -d, 0.3), (0.25, 0.012, 0.24), 0.006)), "wood")
    t.add(lambda p: sub(box(p, v3(0, 0.08, 1.0), (w, 0.1, 0.42), 0.008), box(p, v3(0, 0.0, 1.0), (w - 0.04, 0.1, 0.38))), "wood_d")
    for z in (0.78, 1.08):
        t.add(lambda p, z=z: box(p, v3(0, 0.05, z - 0.02), (w - 0.04, 0.08, 0.012)), "wood")
        t.add(lambda p, z=z: hcyl(p, v3(-w, -0.02, z + 0.06), v3(w, -0.02, z + 0.06), 0.008), "wood_l")
    n = {"full": 7, "sparse": 3, "broken": 4}[state]
    for j, z in enumerate((0.78, 1.08)):
        for i in range(n):
            x = -0.44 + i * (0.88 / max(n - 1, 1))
            mat = ("steel", "bone", "copper")[(i + j) % 3]
            t.add(lambda p, x=x, z=z: np.maximum(np.hypot(p[:, 0] - x, p[:, 2] - z - 0.09) - 0.085, np.abs(p[:, 1] - 0.04 + (p[:, 2] - z) * 0.15) - 0.008), mat)
    t.add(many([lambda p, x=x: _frustum(p, v3(x, 0.0, 0.6), 0.04, 0.06, 0.07) for x in (-0.3, 0.0, 0.3)][: (3 if state == "full" else 1)]), "bone")
    if state == "broken":
        for i, (x, y, a) in enumerate(((-0.5, -0.45, 0.4), (0.2, -0.55, -0.3), (0.5, -0.4, 1.2))):
            k.add(lambda p, x=x, y=y, a=a: sub(cyl(rot_x(rot_z(p, a, (x, y, 0)), 0.3, (x, y, 0)), v3(x, y, 0), 0.07, 0.012), box(rot_z(p, a, (x, y, 0)), v3(x + 0.05, y, 0), (0.04, 0.1, 0.05))), "bone")
    return {}


@prop("spit_hearth", "inn", cell=(4, 4), collide=(1.6, 0.6), tags=["fire", "inn", "kitchen", "masonry"], name_ko="꼬치 굽는 화덕", interact="fire",
    variants={"lit": {"frames": 4}, "cold": {"state": "cold"}},
    light={"color": FIRE, "radius": 4.5, "at": (0, -0.2, 0.4), "flicker": 0.3, "variants": ["lit"]})
def spit_hearth(k, state="lit", seed=1, f=0):
    """낮은 돌 화덕 위에 Y자 받침 둘 · 쇠꼬치 · 통고기 덩이 + 손잡이."""
    inn_mats(k)
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.11), (0.62, 0.32, 0.11), 0.03), box(p, v3(0, 0, 0.2), (0.52, 0.24, 0.12), 0.02)), 0.015, 0.15, seed), "masonry")
    k.add(rough(lambda p: ell(p, v3(0, 0, 0.12), (0.46, 0.2, 0.06)), 0.03, 0.06, seed + 1), "ash" if state == "cold" else "coal")
    k.add(many([lambda p, x=x: cap(p, v3(x * 0.3, 0.02, 0.12), v3(x * 0.3, -0.02, 0.2), 0.03) for x in (-1, 0, 1)]), "wood_d")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: np.minimum.reduce([cap(p, v3(sx * 0.6, 0, 0.0), v3(sx * 0.6, 0, 0.6), 0.02), cap(p, v3(sx * 0.6, 0, 0.6), v3(sx * 0.56, 0, 0.7), 0.014), cap(p, v3(sx * 0.6, 0, 0.6), v3(sx * 0.64, 0, 0.7), 0.014)]), "iron")
    k.add(lambda p: np.minimum(hcyl(p, v3(-0.72, 0, 0.64), v3(0.68, 0, 0.64), 0.012), np.minimum(cap(p, v3(-0.72, 0, 0.64), v3(-0.72, 0, 0.52), 0.01), cap(p, v3(-0.72, 0, 0.52), v3(-0.82, 0, 0.52), 0.014))), "iron")
    k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.64), (0.26, 0.11, 0.1)), ell(p, v3(0.2, 0, 0.6), (0.1, 0.08, 0.07)), 0.05), 0.02, 0.06, seed + 2), "roast")
    extra = {}
    if state == "lit":
        extra["post"] = [flame_post(x, -0.05, 0.16, h, seed + i, f, "fire", 0.4, 2.2, 0.35) for i, (x, h) in enumerate(((-0.25, 18), (0.05, 24), (0.3, 16)))]
        extra["post"].append(lambda img, vw: fx.puff(img, *vw.px(0, 0, 0.8), 10 * vw.u / 64, "#9a948a", 0.3, seed, f, 40 * vw.u / 64, 6))
    return extra


# ── 식탁 ────────────────────────────────────────────────────────────────────

@prop("tavern_table", "inn", cell=(3, 3), collide=(1.0, 0.7), tags=["wood", "inn", "food"], name_ko="음식이 놓인 테이블",
    variants={"meal": {}, "after": {"state": "after"}, "candle": {"state": "candle", "frames": 4}},
    light={"color": FIRE, "radius": 2.5, "at": (0, 0, 0.8), "flicker": 0.2, "variants": ["candle"]})
def tavern_table(k, state="meal", seed=1, f=0):
    """둥근 선술집 탁자(굵은 가운데 다리 + 십자 발): 통닭 접시 · 빵 · 술잔."""
    inn_mats(k)
    h = 0.56
    k.add(rough(lambda p: cyl(p, v3(0, 0, h - 0.05), 0.46, 0.05, 0.015), 0.006, 0.2, seed), "plank_x")
    k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 0.04), 0.06, h - 0.08), np.minimum(box(p, v3(0, 0, 0.03), (0.3, 0.05, 0.03), 0.01), box(p, v3(0, 0, 0.03), (0.05, 0.3, 0.03), 0.01))), "wood_d")
    z = h
    if state in ("meal", "candle"):
        _plate(k, 0, 0.02, z, 0.15, "bone")
        k.add(rough(lambda p: smin(ell(p, v3(0, 0.02, z + 0.06), (0.1, 0.08, 0.06)), many([lambda p, s=s: cap(p, v3(s * 0.07, -0.02, z + 0.05), v3(s * 0.13, -0.07, z + 0.07), 0.025) for s in (-1, 1)])(p), 0.03), 0.01, 0.05, seed), "roast")
        k.add(many([lambda p, a=a: ell(rot_z(p, a, (0.27, 0.14, z)), v3(0.27, 0.14, z + 0.035), (0.08, 0.045, 0.035)) for a in (0.3,)]), "bread")
        tankard(k, -0.28, -0.12, z)
        tankard(k, 0.25, -0.2, z)
        _cup(k, -0.25, 0.22, z, 0.03, 0.06, "copper", False)
    if state == "candle":
        _candle(k, -0.08, 0.3, z, 0.1)
        return {"post": [flame_post(-0.08, 0.3, z + 0.13, 9, seed, f, "fire", 0.36, 2.4, 0.3)]}
    if state == "after":
        _plate(k, -0.1, 0.05, z, 0.14, "bone")
        k.add(many([lambda p, a=a: cap(rot_z(p, a, (-0.1, 0.05, z)), v3(-0.18, 0.05, z + 0.03), v3(-0.02, 0.05, z + 0.03), 0.012) for a in (0.2, 1.4)]), "bone")
        tankard(k, 0.25, -0.15, z, 1.0, False)
        k.add(lambda p: box(rot_y(p, PI / 2, (0.18, 0.2, z + 0.04)), v3(0.18, 0.2, z + 0.04), (0.04, 0.035, 0.05), 0.02), "wood_l")   # 쓰러진 잔
        k.add(lambda p: pool(p, (0.3, 0.22, z + 0.006), 0.1, 0.06, 0.004), "ale")
        k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, z + 0.012), 0.014) for x, y in ((0.05, -0.25), (-0.3, 0.2), (0.1, 0.3))]), "bread")
    return {}


# ── 잠자리 · 방 살림 ─────────────────────────────────────────────────────────

@prop("bedding", "inn", cell=(2, 2), collide=(0.6, 0.5), tags=["cloth", "inn", "home"], name_ko="침구 더미",
    variants={"stack": {}, "pillows": {"state": "pillows"}})
def bedding(k, state="stack", seed=1):
    inn_mats(k)
    if state == "stack":
        for i, m in enumerate(("blanket_r", "linen", "blanket_b", "wool", "linen")):
            k.add(rough(lambda p, i=i: box(rot_z(p, (i % 2 - 0.5) * 0.12), v3(0, 0, 0.04 + i * 0.075), (0.27, 0.2, 0.034), 0.03), 0.006, 0.1, seed + i), m)
        return {}
    for i, (x, y, z, a) in enumerate(((-0.12, 0.05, 0.06, 0.2), (0.14, 0.0, 0.06, -0.3), (0.0, 0.02, 0.15, 0.1), (0.05, -0.18, 0.06, 0.9))):
        k.add(rough(lambda p, x=x, y=y, z=z, a=a: ell(rot_z(p, a, (x, y, z)), v3(x, y, z), (0.17, 0.11, 0.065)), 0.01, 0.1, seed + i), "linen" if i != 2 else "wool")
    return {}


@prop("blanket", "inn", cell=(2, 2), tags=["cloth", "inn", "home"], name_ko="담요",
    variants={"folded": {}, "draped": {"state": "draped"}, "crumpled": {"state": "crumpled"}})
def blanket(k, state="folded", seed=1):
    inn_mats(k)
    if state == "folded":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.05), (0.24, 0.17, 0.05), 0.035), 0.008, 0.08, seed), "blanket_r")
        k.add(lambda p: np.maximum(box(p, v3(0, -0.17, 0.05), (0.24, 0.012, 0.05), 0.01), -1.0), "wool")
        return {}
    if state == "draped":   # 나무 걸대에 걸친 담요
        k.add(many([lambda p, sx=sx: np.minimum(cap(p, v3(sx * 0.4, 0, 0), v3(sx * 0.4, 0, 0.62), 0.02), box(p, v3(sx * 0.4, 0, 0.015), (0.03, 0.14, 0.015))) for sx in (-1, 1)]), "wood_d")
        k.add(lambda p: hcyl(p, v3(-0.42, 0, 0.6), v3(0.42, 0, 0.6), 0.016), "wood_d")
        k.add(rough(lambda p: np.maximum(np.abs(np.hypot(p[:, 1], (p[:, 2] - 0.6) * 0.6) - 0.02) - 0.012 + np.sin(p[:, 0] * 30) * 0.004, np.maximum(np.abs(p[:, 0]) - 0.33, 0.25 - p[:, 2])), 0.006, 0.1, seed), "blanket_b")
        return {}
    k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.04), (0.32, 0.22, 0.04)), ell(p, v3(0.08, 0.04, 0.07), (0.14, 0.1, 0.06)), 0.06), 0.03, 0.06, seed), "blanket_r")
    return {}


@prop("key_rack", "inn", layer="wall_decal", cell=(2, 3), tags=["inn", "wood", "iron"], name_ko="열쇠 걸이 판",
    variants={"full": {}, "few": {"state": "few"}})
def key_rack(k, state="full", seed=1):
    """벽에 건 나무판에 못 두 줄 · 방 열쇠(고리 + 나무 꼬리표) — 원점 = 벽 밑동."""
    inn_mats(k)
    zr, y = 1.35, -0.02
    k.add(rough(lambda p: box(p, v3(0, y, zr), (0.34, 0.016, 0.2), 0.012), 0.006, 0.2, seed), "plank_x")
    for j, z in enumerate((zr + 0.09, zr - 0.07)):
        for i in range(5):
            x = -0.26 + i * 0.13
            k.add(lambda p, x=x, z=z: cap(p, v3(x, y, z), v3(x, y - 0.04, z + 0.01), 0.007), "brass")
            if state == "few" and (i + j) % 3:
                continue
            k.add(lambda p, x=x, z=z: np.minimum(ring_x(p, v3(x, y - 0.04, z - 0.025), 0.016, 0.004), cap(p, v3(x, y - 0.04, z - 0.04), v3(x, y - 0.04, z - 0.09), 0.005)), "iron")
            k.add(lambda p, x=x, z=z: box(p, v3(x + 0.02, y - 0.045, z - 0.06), (0.012, 0.006, 0.025), 0.003), "wood_l")
    return {"shadow": 0.0, "foot": 0.3}


@prop("coat_pegs", "inn", layer="wall_decal", cell=(3, 3), tags=["inn", "cloth", "wood"], name_ko="외투 걸이",
    variants={"cloaks": {}, "hats": {"state": "hats"}, "empty": {"state": "empty"}})
def coat_pegs(k, state="cloaks", seed=1):
    inn_mats(k)
    zr, y = 1.45, -0.02
    k.add(rough(lambda p: box(p, v3(0, y, zr), (0.5, 0.016, 0.04), 0.006), 0.006, 0.2, seed), "plank_x")
    xs = (-0.36, -0.12, 0.12, 0.36)
    k.add(many([lambda p, x=x: cap(p, v3(x, y, zr), v3(x, y - 0.08, zr + 0.03), 0.013) for x in xs]), "wood_d")
    if state == "empty":
        return {"shadow": 0.0, "foot": 0.3}
    mats_ = ("cloth_k", "cloth_g", "leather_d", "cloth_b")
    for i, x in enumerate(xs):
        if state == "hats" and i % 2:
            k.add(lambda p, x=x: np.minimum(cyl(p, v3(x, y - 0.08, zr - 0.02), 0.09, 0.012), cone(p, v3(x, y - 0.08, zr - 0.01), 0.055, 0.1)), "leather_d")
            continue
        if i == 2 and state == "cloaks":
            continue
        k.add(rough(lambda p, x=x: np.maximum(np.abs(np.hypot((p[:, 0] - x) * 1.0, p[:, 1] - y + 0.07) - 0.07 - (zr - p[:, 2]) * 0.12) - 0.018 + np.sin((p[:, 0] - x) * 40) * 0.005,
            np.maximum(p[:, 2] - zr + 0.01, zr - 0.72 - p[:, 2])), 0.006, 0.08, seed + i), mats_[i])
    return {"shadow": 0.0, "foot": 0.3}


@prop("kitchen_hangings", "inn", layer="wall_decal", cell=(3, 3), tags=["inn", "kitchen", "food"], name_ko="걸어 둔 부엌살림",
    variants={"pots": {}, "sausages": {"state": "sausages"}, "onions": {"state": "onions"}})
def kitchen_hangings(k, state="pots", seed=1):
    """벽에 박은 쇠막대에 건 냄비 · 국자 / 소시지 줄 / 양파 · 마늘 타래 — 원점 = 벽 밑동."""
    inn_mats(k)
    zr, y = 1.5, -0.08
    k.add(lambda p: np.minimum(hcyl(p, v3(-0.55, y, zr), v3(0.55, y, zr), 0.012), many([lambda p, x=x: cap(p, v3(x, 0, zr), v3(x, y, zr), 0.012) for x in (-0.5, 0.5)])(p)), "iron")
    if state == "pots":
        for i, (x, r) in enumerate(((-0.36, 0.11), (0.0, 0.09), (0.3, 0.07))):
            k.add(lambda p, x=x, r=r: np.minimum(cap(p, v3(x, y, zr), v3(x, y, zr - 0.08), 0.006), sub(_frustum(p, v3(x, y, zr - 0.08 - r * 1.3), r * 0.85, r, r * 1.0), _frustum(p, v3(x, y - 0.01, zr - 0.06 - r * 1.3), r * 0.8, r * 0.95, r))), "copper")
        k.add(lambda p: np.minimum(cap(p, v3(0.47, y, zr), v3(0.47, y, zr - 0.3), 0.008), sphere(p, v3(0.47, y, zr - 0.34), 0.04)), "iron")
        k.add(lambda p: np.minimum(cap(p, v3(-0.53, y, zr), v3(-0.53, y, zr - 0.28), 0.008), box(p, v3(-0.53, y, zr - 0.33), (0.03, 0.006, 0.05), 0.01)), "steel")
    elif state == "sausages":
        for i, x in enumerate((-0.42, -0.2, 0.05, 0.3)):
            n = 3 + i % 2
            k.add(many([lambda p, x=x, j=j: cap(p, v3(x + np.sin(j * 1.3) * 0.02, y, zr - 0.02 - j * 0.1), v3(x - np.sin(j * 1.3) * 0.02, y, zr - 0.1 - j * 0.1), 0.024) for j in range(n)]), "sausage")
    else:
        for i, x in enumerate((-0.38, -0.08, 0.24)):
            k.add(lambda p, x=x: cap(p, v3(x, y, zr), v3(x, y, zr - 0.5), 0.01), "straw" if "straw" in k.mats else "rope")
            k.add(many([lambda p, x=x, j=j: sphere(p, v3(x + (j % 2 - 0.5) * 0.06, y - 0.01, zr - 0.08 - j * 0.07), 0.04 - (j > 4) * 0.008) for j in range(7)]), "onion" if i != 1 else "bone")
    return {"shadow": 0.0, "foot": 0.3}


@prop("washstand", "inn", cell=(2, 3), collide=(0.5, 0.4), tags=["wood", "inn", "home", "water"], name_ko="세면대",
    variants={"jug": {}, "used": {"state": "used"}})
def washstand(k, state="jug", seed=1):
    """세 다리 받침에 놓인 놋 대야 + 물주전자, 아래 칸에 수건."""
    inn_mats(k)
    h = 0.62
    k.add(many([lambda p, a=a: cap(p, v3(np.cos(a) * 0.2, np.sin(a) * 0.2, 0), v3(np.cos(a) * 0.15, np.sin(a) * 0.15, h), 0.02) for a in (PI / 2, PI / 2 + 2.1, PI / 2 + 4.2)]), "wood_d")
    k.add(lambda p: torus(p, v3(0, 0, h), 0.17, 0.02), "wood_d")
    k.add(lambda p: cyl(p, v3(0, 0, 0.2), 0.16, 0.015), "wood")
    k.add(lambda p: box(p, v3(0, 0, 0.23), (0.1, 0.08, 0.02), 0.015), "linen")
    k.add(lambda p: sub(_frustum(p, v3(0, 0, h - 0.04), 0.09, 0.2, 0.08), _frustum(p, v3(0, 0, h - 0.025), 0.08, 0.19, 0.09)), "copper")
    k.add(lambda p: cyl(p, v3(0, 0, h - 0.02), 0.16, 0.05 if state == "jug" else 0.035), "water")
    if state == "jug":
        k.add(lambda p: smin(ell(p, v3(0.08, 0.04, h + 0.12), (0.06, 0.06, 0.08)), cap(p, v3(0.08, 0.04, h + 0.18), v3(0.08, 0.04, h + 0.24), 0.035, 0.045), 0.03), "bone")
    else:
        k.add(rough(lambda p: ell(p, v3(0.3, -0.25, 0.03), (0.16, 0.1, 0.03)), 0.01, 0.05, seed), "linen")
        k.add(lambda p: pool(p, (-0.2, -0.28, 0), 0.12, 0.07), "water")
    return {}


@prop("wine_rack", "inn", cell=(3, 4), collide=(1.1, 0.4), tags=["wood", "inn", "drink", "storage"], name_ko="술병 선반", interact="container",
    variants={"full": {}, "half": {"state": "half"}})
def wine_rack(k, state="full", seed=1):
    """마름모 칸 대신 가로 칸마다 병을 눕혀 꽂은 술병 선반(병 바닥이 앞을 본다)."""
    inn_mats(k)
    w, d, h = 0.52, 0.2, 1.2
    k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.01), box(p, v3(0, -0.05, h / 2), (w - 0.04, d, h / 2 - 0.04))), 0.008, 0.2, seed), "wood_d")
    rows = (0.12, 0.34, 0.56, 0.78, 1.0)
    for z in rows:
        k.add(lambda p, z=z: box(p, v3(0, 0, z - 0.06), (w - 0.04, d - 0.02, 0.01)), "wood")
    for j, z in enumerate(rows):
        for i in range(6):
            if state == "half" and (i * 3 + j) % 5 < 2:
                continue
            x = -0.4 + i * 0.16
            m = ("glass", "glass_r", "glass", "glass_b")[(i + j) % 4]
            k.add(lambda p, x=x, z=z: smin(hcyl(p, v3(x, -0.1, z), v3(x, 0.12, z), 0.045), hcyl(p, v3(x, 0.1, z), v3(x, 0.2, z), 0.016), 0.03), m)
    return {}
