"""신전(도시 — 쓰이고 있는 깨끗한 신전): 제단 · 제단 단 · 봉헌상 · 작은 석상 · 기도대 · 신도석 · 성물함 · 향로 · 봉헌 촛대 · 성배 · 독경대 · 기도서 · 헌금함.
미궁의 제단 · 석상(a_structure)과 달리 밝은 석회석 · 흰 천 · 붉은 깔개 · 금빛 띠로 손질된 모습이다(동네 신전 = 흰 석회석 고딕 성당, 실내 제단 = 붉은 깔개 + 금빛 띠 — tools/interior_furn.py).
문양은 중립 도형만 쓴다(마름모 · 뾰족 아치 · 둥근 고리 · 촛불 · 물) — 세계관에 정해진 신의 상징이 없어 지어내지 않는다."""
import numpy as np

import fx
import sdf
from kit import (F, box, cap, cone, cyl, ell, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from a_furniture import _book, _frustum, _open_book
from a_light import flame_post

PI = np.pi
FIRE = "#f0a040"


def mats(k):
    """신전 재질: 밝은 석회석 · 금박 · 흰 제단보 · 물 · 꽃."""
    k.mat("lime", M.stone("#b4ae9e", None, 3))
    k.mat("lime_d", M.stone("#8e8878", None, 4))
    k.mat("lime_c", M.stone("#aaa494", None, 5, 0.09))
    k.mat("gilt", M.metal("#b89a4c", "#7a5c2c", 12, 0.08))
    k.mat("cloth_w", M.plain("#c6beaa", 0.18, 0.15, 5))
    k.mat("cloth_gd", M.plain("#a8863c", 0.22, 0.1, 6))
    k.mat("water", M.plain("#3e6270", 0.2, 0.2, 7))
    k.mat("fl_w", M.plain("#d4ccb8", 0.25, 0.03, 8))
    k.mat("fl_r", M.plain("#9a3a34", 0.3, 0.03, 9))
    k.mat("fl_y", M.plain("#c0a040", 0.3, 0.03, 10))
    k.mat("fruit", M.plain("#a0582c", 0.4, 0.05, 11))
    return k


def fold(p, amp=0.006, freq=38.0, axis=0):
    return np.sin(p[:, axis] * freq) * amp


def chalice(k, x, y, z, s=1.0, mat="gilt"):
    """잔: 발 · 대 · 마디 · 컵."""
    k.add(lambda p: np.minimum.reduce([_frustum(p, v3(x, y, z), 0.05 * s, 0.022 * s, 0.022 * s), cap(p, v3(x, y, z + 0.02 * s), v3(x, y, z + 0.09 * s), 0.012 * s),
        sphere(p, v3(x, y, z + 0.055 * s), 0.02 * s), sub(_frustum(p, v3(x, y, z + 0.085 * s), 0.028 * s, 0.055 * s, 0.075 * s), _frustum(p, v3(x, y, z + 0.1 * s), 0.02 * s, 0.047 * s, 0.08 * s))]), mat)


def candle(k, x, y, z, h=0.16, r=0.02, holder="gilt"):
    if holder:
        k.add(lambda p: np.minimum(_frustum(p, v3(x, y, z), r * 2.4, r * 1.2, 0.02), cyl(p, v3(x, y, z + 0.02), r * 1.9, 0.012, 0.004)), holder)
        z = z + 0.03
    k.add(lambda p: cyl(p, v3(x, y, z), r, h, 0.005), "wax")
    k.add(lambda p: cap(p, v3(x, y, z + h), v3(x, y, z + h + 0.016), 0.004), "coal")
    return (x, y, z + h + 0.02)


def flames(tips, seed, f, h=8, strength=0.26):
    return [flame_post(x, y, z, h, seed + i, f, "fire", 0.36, 2.4, strength) for i, (x, y, z) in enumerate(tips)]


def flowers(k, x, y, z, r=0.09, mat="fl_w", n=6, seed=1):
    rng = np.random.default_rng(seed)
    k.add(lambda p: ell(p, v3(x, y, z + r * 0.3), (r * 1.1, r * 0.9, r * 0.45)), "leaf")
    for _ in range(n):
        c = v3(x + rng.uniform(-r, r), y + rng.uniform(-r, r) * 0.8, z + r * 0.55 + rng.uniform(0, r * 0.3))
        k.add(lambda p, c=c: sphere(p, c, r * 0.3), mat)


def smoke(x, y, z, seed, f, r=9.0, rise=46.0, alpha=0.42):
    return lambda img, vw: fx.puff(img, *vw.px(x, y, z), r * vw.u / 64.0, "#b8b4a8", alpha, seed, f, rise * vw.u / 64.0, 7)


# ── 제단 · 단 ────────────────────────────────────────────────────────────────

@prop("shrine_altar", "shrine", cell=(4, 4), collide=(1.9, 0.8), tags=["temple", "stone", "cloth"], name_ko="신전 제단", interact="altar",
    variants={"plain": {}, "dressed": {"state": "dressed"}, "lit": {"state": "lit", "frames": 4}, "festival": {"state": "festival", "frames": 4}},
    light={"color": FIRE, "radius": 3.4, "at": (0, 0, 1.3), "flicker": 0.2, "variants": ["lit", "festival"]})
def shrine_altar(k, state="plain", seed=1, f=0):
    mats(k)
    w, d, h = 0.86, 0.36, 0.84
    k.add(rough(lambda p: box(p, v3(0, 0, 0.05), (w + 0.1, d + 0.1, 0.05), 0.015), 0.01, 0.2, seed), "lime_d")
    body = lambda p: sub(box(p, v3(0, 0, 0.42), (w - 0.04, d - 0.04, 0.32), 0.015),
        np.minimum.reduce([box(p, v3(sx * 0.52, -d + 0.02, 0.42), (0.2, 0.04, 0.22), 0.02) for sx in (-1, 0, 1)]))
    k.add(rough(body, 0.008, 0.2, seed), "lime")
    k.add(rough(lambda p: box(p, v3(0, 0, h - 0.05), (w + 0.05, d + 0.05, 0.05), 0.02), 0.008, 0.2, seed + 1), "lime")
    if state == "plain":
        k.add(lambda p: np.minimum.reduce([np.maximum(np.abs(np.abs(p[:, 0] - sx * 0.52) + np.abs(p[:, 2] - 0.42) * 0.8 - 0.1) - 0.012, np.abs(p[:, 1] + d - 0.045) - 0.012) for sx in (-1, 0, 1)]), "lime_c")
        return {}
    # 흰 제단보(앞으로 드리움) + 금빛 단 + 가운데 붉은 깔개와 금 마름모
    k.add(lambda p: np.minimum(box(p, v3(0, 0, h + 0.006), (w + 0.07, d + 0.07, 0.01), 0.008), box(p, v3(0, -d - 0.065, h - 0.11), (w + 0.07, 0.012, 0.125), 0.008) + fold(p, 0.005, 30)), "cloth_w")
    k.add(lambda p: box(p, v3(0, -d - 0.07, h - 0.215), (w + 0.07, 0.014, 0.022)) + fold(p, 0.005, 30), "cloth_gd")
    k.add(lambda p: np.minimum(box(p, v3(0, 0, h + 0.014), (0.26, d + 0.075, 0.008)), box(p, v3(0, -d - 0.082, h - 0.26), (0.26, 0.012, 0.28), 0.006) + fold(p, 0.004, 44)), "cloth_r")
    k.add(lambda p: np.maximum(np.abs(p[:, 0]) + np.abs(p[:, 2] - h + 0.3) * 0.75 - 0.1, np.abs(p[:, 1] + d + 0.09) - 0.012), "cloth_gd")
    k.add(lambda p: box(p, v3(0, -d - 0.088, h - 0.52), (0.26, 0.012, 0.02)), "cloth_gd")
    tips = [candle(k, sx * 0.62, 0.08, h + 0.02, 0.26, 0.024) for sx in (-1, 1)]
    chalice(k, 0.0, -0.02, h + 0.022, 1.25)
    _open_book(k, v3(-0.32, -0.06, h + 0.02), 0.8, 0.08, "cloth_r")
    k.add(lambda p: sub(_frustum(p, v3(0.34, -0.05, h + 0.02), 0.05, 0.085, 0.045), _frustum(p, v3(0.34, -0.05, h + 0.032), 0.04, 0.075, 0.05)), "gilt")
    if state == "festival":
        for i, x in enumerate(np.linspace(-0.8, 0.8, 9)):
            if abs(x) > 0.3:
                flowers(k, x, -d - 0.1, h - 0.05 - 0.05 * np.cos(x * 4), 0.075, ("fl_w", "fl_r", "fl_y")[i % 3], 5, seed + i)
        flowers(k, -0.95, -d - 0.2, 0.1, 0.12, "fl_w", 7, seed + 20)
        flowers(k, 0.95, -d - 0.2, 0.1, 0.12, "fl_y", 7, seed + 21)
        for dx, dy in ((0, 0), (0.04, 0.02), (-0.04, 0.02)):
            k.add(lambda p, dx=dx, dy=dy: sphere(p, v3(0.34 + dx, -0.05 + dy, h + 0.085), 0.034), "fruit")
    if state in ("lit", "festival"):
        return {"post": flames(tips, seed, f, 9, 0.32)}
    return {}


@prop("shrine_dais", "shrine", layer="decal", cell=(4, 3), tags=["temple", "stone", "module"], name_ko="제단 단(세 단 계단)",
    variants={"straight": {}, "runner": {"runner": True}, "corner": {"shape": "corner"}, "end": {"shape": "end"}}, meta={"module": True, "tile_w": 2})
def shrine_dais(k, shape="straight", runner=False, seed=1):
    mats(k)
    hw = 1.0 if shape != "corner" else 0.5
    for i, (grow, mat) in enumerate(((0.0, "lime"), (0.18, "lime"), (0.36, "lime_d"))):
        z = 0.2 - i * 0.1 + 0.1
        zc, hz = z / 2, z / 2
        if shape == "corner":   # 오른쪽 앞 모서리(왼쪽 · 뒤로 이어진다)
            fn = lambda p, g=grow, zc=zc, hz=hz: box(p, v3(-0.25 + g * 0.5, 0.25 - g * 0.5, zc), (0.75 + g * 0.5, 0.75 + g * 0.5, hz), 0.012)
        elif shape == "end":    # 오른쪽 끝(왼쪽으로 이어진다)
            fn = lambda p, g=grow, zc=zc, hz=hz: box(p, v3(g * 0.5, 0.25 - g * 0.5, zc), (hw + g * 0.5, 0.45 + g * 0.5, hz), 0.012)
        else:
            fn = lambda p, g=grow, zc=zc, hz=hz: box(p, v3(0, 0.25 - g * 0.5, zc), (hw, 0.45 + g * 0.5, hz), 0.012)
        k.add(rough(fn, 0.006, 0.25, seed + i), mat)
    if runner:
        for i in range(3):
            g = i * 0.18
            k.add(lambda p, g=g, i=i: box(p, v3(0, 0.25 - g * 0.5 - (0.0 if i == 0 else 0.45 + g * 0.5 - 0.1), 0.3 - i * 0.1 + 0.006), (0.34, 0.45 if i == 0 else 0.1, 0.008)), "cloth_r")
            k.add(lambda p, g=g, i=i: np.minimum(*[box(p, v3(sx * 0.3, 0.25 - g * 0.5 - (0.0 if i == 0 else 0.45 + g * 0.5 - 0.1), 0.3 - i * 0.1 + 0.01), (0.022, 0.45 if i == 0 else 0.1, 0.008)) for sx in (-1, 1)]), "cloth_gd")
    return {"shadow": 0.25, "foot": 0.9}


# ── 석상 ─────────────────────────────────────────────────────────────────────

def _figure(k, x, y, z0, s, seed, mat="lime", bowl="lime_d"):
    """베일을 쓰고 고개를 숙인 채 두 손으로 그릇을 받쳐 든 사람(얼굴은 새기지 않았다)."""
    c = lambda a, b, cc: v3(x + a * s, y + b * s, z0 + cc * s)
    folds = lambda p: np.sin(np.arctan2(p[:, 1] - y, p[:, 0] - x) * 11.0 + (p[:, 2] - z0) / s * 1.2) * 0.014 * s * np.clip(1.0 - (p[:, 2] - z0) / (1.0 * s), 0, 1)
    robe = lambda p: smin(cap(p, c(0, 0, 0), c(0, 0, 1.05), 0.3 * s, 0.17 * s), ell(p, c(0, 0, 1.14), (0.27 * s, 0.17 * s, 0.14 * s)), 0.09 * s) + folds(p)
    head = lambda p: smin(sphere(p, c(0, -0.03, 1.42), 0.115 * s), cap(p, c(0, 0, 1.2), c(0, -0.02, 1.34), 0.07 * s), 0.04 * s)
    veil = lambda p: sub(smin(ell(p, c(0, 0.03, 1.42), (0.16 * s, 0.16 * s, 0.17 * s)), ell(p, c(0, 0.07, 1.2), (0.25 * s, 0.16 * s, 0.22 * s)), 0.08 * s), sphere(p, c(0, -0.15, 1.38), 0.125 * s))
    arms = lambda p: smin(cap(p, c(-0.25, 0, 1.12), c(-0.07, -0.22, 0.9), 0.075 * s, 0.055 * s), cap(p, c(0.25, 0, 1.12), c(0.07, -0.22, 0.9), 0.075 * s, 0.055 * s), 0.04 * s)
    k.add(rough(lambda p: smin(smin(smin(robe(p), head(p), 0.03 * s), veil(p), 0.03 * s), arms(p), 0.04 * s), 0.008 * s, 0.2, seed), mat)
    k.add(lambda p: sub(_frustum(p, c(0, -0.27, 0.9), 0.05 * s, 0.11 * s, 0.07 * s), _frustum(p, c(0, -0.27, 0.925), 0.04 * s, 0.095 * s, 0.07 * s)), bowl)
    return c(0, -0.27, 0.975)


@prop("shrine_statue", "shrine", cell=(3, 5), collide=(0.95, 0.75), tags=["temple", "stone", "statue"], name_ko="봉헌상(그릇을 받쳐 든 석상)", interact="examine",
    variants={"plain": {}, "offerings": {"state": "offerings"}, "lamp": {"state": "lamp", "frames": 4}},
    light={"color": FIRE, "radius": 2.6, "at": (0, -0.3, 1.7), "flicker": 0.2, "variants": ["lamp"]})
def shrine_statue(k, state="plain", seed=1, f=0):
    mats(k)
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.08), (0.46, 0.38, 0.08), 0.015), box(p, v3(0, 0, 0.36), (0.38, 0.3, 0.2), 0.015)), 0.008, 0.2, seed), "lime_d")
    k.add(rough(lambda p: box(p, v3(0, 0, 0.59), (0.42, 0.34, 0.035), 0.015), 0.006, 0.2, seed), "lime")
    k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0], (p[:, 2] - 0.36) * 1.1) - 0.11) - 0.014, np.abs(p[:, 1] + 0.3) - 0.014), "lime_c")
    top = _figure(k, 0, 0.02, 0.62, 1.12, seed)
    if state == "offerings":
        flowers(k, top[0], top[1], top[2] - 0.05, 0.085, "fl_w", 6, seed)
        flowers(k, -0.3, -0.5, 0.0, 0.1, "fl_r", 6, seed + 1)
        flowers(k, 0.34, -0.52, 0.0, 0.09, "fl_y", 5, seed + 2)
        tips = [candle(k, x, -0.56, 0.0, hh, 0.02, None) for x, hh in ((-0.06, 0.1), (0.08, 0.07))]
        k.add(lambda p: pool(p, v3(0.0, -0.56, 0.006), 0.13, 0.07, 0.006), "wax")
    if state == "lamp":
        k.add(lambda p: sphere(p, top - v3(0, 0, 0.03), 0.06), "ember")
        return {"post": [flame_post(top[0], top[1], top[2] + 0.02, 12, seed, f, "fire", 0.4, 2.8, 0.42)]}
    return {}


@prop("shrine_statuette", "shrine", cell=(2, 3), collide=(0.4, 0.35), tags=["temple", "stone", "statue"], name_ko="작은 석상(받침 위)",
    variants={"single": {}, "pair": {"state": "pair"}, "gilded": {"state": "gilded"}})
def shrine_statuette(k, state="single", seed=1):
    mats(k)
    xs = (-0.3, 0.3) if state == "pair" else (0.0,)
    for i, x in enumerate(xs):
        k.add(rough(lambda p, x=x: np.minimum.reduce([box(p, v3(x, 0, 0.04), (0.19, 0.17, 0.04), 0.01), cyl(p, v3(x, 0, 0.08), 0.12, 0.58, 0.01), box(p, v3(x, 0, 0.69), (0.17, 0.15, 0.03), 0.01)]), 0.006, 0.15, seed + i), "lime_d")
        _figure(k, x, 0, 0.72, 0.5, seed + i, "gilt" if state == "gilded" else "lime", "gilt")
    return {}


# ── 기도대 · 신도석 ──────────────────────────────────────────────────────────

@prop("prayer_kneeler", "shrine", cell=(2, 3), collide=(0.7, 0.6), tags=["temple", "wood"], name_ko="기도대", interact="pray",
    variants={"plain": {}, "cushion": {"state": "cushion"}, "book": {"state": "book"}})
def prayer_kneeler(k, state="plain", seed=1):
    # 뒤(북)에 비스듬한 책받침, 앞(남)에 무릎 받침
    k.add(rough(lambda p: np.minimum.reduce([box(p, v3(0, 0.16, 0.36), (0.3, 0.035, 0.36), 0.01), box(p, v3(-0.3, 0.02, 0.36), (0.03, 0.17, 0.36), 0.01), box(p, v3(0.3, 0.02, 0.36), (0.03, 0.17, 0.36), 0.01)]), 0.006, 0.2, seed), "wood_d")
    k.add(rough(lambda p: box(rot_x(p, -0.3, (0, 0.02, 0.74)), v3(0, 0.02, 0.74), (0.35, 0.17, 0.025), 0.008), 0.006, 0.2, seed), "plank_x")
    k.add(rough(lambda p: np.minimum(box(p, v3(0, -0.36, 0.1), (0.33, 0.14, 0.03), 0.01), np.minimum(box(p, v3(-0.3, -0.26, 0.05), (0.03, 0.24, 0.05)), box(p, v3(0.3, -0.26, 0.05), (0.03, 0.24, 0.05)))), 0.006, 0.2, seed), "wood")
    if state in ("cushion", "book"):
        k.add(rough(lambda p: box(p, v3(0, -0.36, 0.155), (0.29, 0.12, 0.03), 0.028), 0.008, 0.1, seed), "cloth_r")
    if state == "book":
        T = lambda p: rot_x(p, -0.3, (0, 0.02, 0.74))
        k.add(lambda p: box(T(p), v3(0, 0.01, 0.775), (0.17, 0.11, 0.008), 0.004), "leather_d")
        k.add(lambda p: np.minimum(box(T(p), v3(-0.082, 0.01, 0.79), (0.076, 0.1, 0.01), 0.006), box(T(p), v3(0.082, 0.01, 0.79), (0.076, 0.1, 0.01), 0.006)), "paper")
    return {}


def _pew(k, w, face, seed, books=False):
    """face = +1 등받이가 뒤(북) — 앉는 쪽이 남쪽을 본다 · -1 등받이가 앞(남) — 제단(북)을 보고 앉는다."""
    yb = 0.2 * face
    k.add(rough(lambda p: box(p, v3(0, -0.02 * face, 0.3), (w, 0.2, 0.025), 0.008), 0.006, 0.2, seed), "plank_x")
    k.add(rough(lambda p: box(p, v3(0, yb, 0.5), (w, 0.025, 0.36), 0.008), 0.006, 0.2, seed + 1), "plank_x")
    k.add(lambda p: box(p, v3(0, yb, 0.87), (w + 0.01, 0.04, 0.025), 0.01), "wood_d")
    for sx in (-1, 1):   # 끝 판: 위가 둥글다
        k.add(rough(lambda p, sx=sx: np.minimum(box(p, v3(sx * w, 0, 0.3), (0.035, 0.24, 0.3), 0.01),
            np.maximum(np.hypot(p[:, 1] - yb * 0.7, (p[:, 2] - 0.6) * 0.75) - 0.22, np.abs(p[:, 0] - sx * w) - 0.035)), 0.006, 0.2, seed + 2), "wood_d")
    k.add(lambda p: box(p, v3(0, -0.02 * face, 0.12), (w - 0.05, 0.02, 0.12)), "wood_d")
    if books:
        _book(k, v3(-w * 0.5, -0.03 * face, 0.325), 0.07, 0.05, 0.016, 0.2, "cloth_r")
        _book(k, v3(w * 0.3, -0.05 * face, 0.325), 0.07, 0.05, 0.016, -0.3, "leather_d")


@prop("pew", "shrine", cell=(4, 3), collide=(1.8, 0.5), tags=["temple", "wood", "seat"], name_ko="신도석", interact="sit",
    variants={"facing_n": {"face": -1}, "facing_s": {"face": 1}, "books": {"face": 1, "books": True}, "short": {"face": -1, "w": 0.45}})
def pew(k, face=1, w=0.88, books=False, seed=1):
    _pew(k, w, face, seed, books)
    return {}


@prop("pew_side", "shrine", cell=(3, 4), collide=(0.5, 1.8), tags=["temple", "wood", "seat"], name_ko="신도석(옆으로 놓인)", interact="sit",
    variants={"facing_e": {"yaw": PI / 2}, "facing_w": {"yaw": -PI / 2}})
def pew_side(k, seed=1):
    _pew(k, 0.88, 1, seed)
    return {"foot": 1.4}


# ── 성물함 · 성배 · 헌금함 ───────────────────────────────────────────────────

@prop("reliquary", "shrine", cell=(2, 3), collide=(0.6, 0.5), tags=["temple", "gold", "treasure"], name_ko="성물함", interact="examine",
    variants={"closed": {}, "open": {"state": "open", "frames": 4}, "grille": {"state": "grille"}},
    light={"color": "#e8d8a0", "radius": 2.0, "at": (0, 0, 1.0), "flicker": 0.08, "variants": ["open"]})
def reliquary(k, state="closed", seed=1, f=0):
    mats(k)
    k.add(rough(lambda p: np.minimum.reduce([box(p, v3(0, 0, 0.04), (0.3, 0.24, 0.04), 0.012), box(p, v3(0, 0, 0.36), (0.2, 0.16, 0.3), 0.012), box(p, v3(0, 0, 0.69), (0.3, 0.24, 0.035), 0.012)]), 0.006, 0.2, seed), "lime")
    k.add(lambda p: box(p, v3(0, 0, 0.732), (0.27, 0.21, 0.008)), "cloth_r")
    z = 0.74
    k.add(lambda p: box(p, v3(0, 0, z + 0.1), (0.2, 0.12, 0.1), 0.012), "wood_d")
    bands = lambda p: np.minimum.reduce([box(p, v3(sx * 0.13, 0, z + 0.1), (0.018, 0.127, 0.106), 0.004) for sx in (-1, 1)] + [box(p, v3(0, 0, z + 0.012), (0.207, 0.127, 0.014)), box(p, v3(0, 0, z + 0.19), (0.207, 0.127, 0.014))])
    k.add(bands, "gilt")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: sphere(p, v3(sx * 0.2, -0.12, z - 0.0), 0.03), "gilt")
    lid = lambda p: sdf.gable(p, v3(0, 0, z + 0.2), 0.21, 0.13, 0.11, 0)
    extra = {}
    if state == "open":   # 뚜껑이 뒤로 젖혀지고 속이 은은히 빛난다
        k.add(lambda p: lid(rot_x(p, 1.15, (0, 0.12, z + 0.2))), "gilt")
        k.add(lambda p: box(p, v3(0, 0, z + 0.2), (0.17, 0.095, 0.006)), "cloth_r")
        k.add(lambda p: ell(p, v3(0, 0, z + 0.23), (0.07, 0.045, 0.035)), "glow_w")
        extra["glow"] = [(0, 0, z + 0.25, 30, "#e8d8a0", 0.3 + 0.06 * np.sin(f * 1.57))]
    else:
        k.add(lid, "gilt")
        k.add(lambda p: hcyl(p, v3(-0.2, 0, z + 0.315), v3(0.2, 0, z + 0.315), 0.014), "gilt")
        k.add(lambda p: np.maximum(np.abs(p[:, 0]) + np.abs(p[:, 2] - z - 0.1) - 0.05, np.abs(p[:, 1] + 0.125) - 0.01), "gilt")
    if state == "grille":   # 쇠살 우리 안
        bars = lambda p: np.minimum.reduce([cap(p, v3(x, y, 0.74), v3(x, y, 1.3), 0.011) for x in np.linspace(-0.27, 0.27, 6) for y in (-0.21, 0.21)]
            + [cap(p, v3(sx * 0.27, y, 0.74), v3(sx * 0.27, y, 1.3), 0.011) for sx in (-1, 1) for y in (-0.07, 0.07)])
        k.add(bars, "iron")
        k.add(lambda p: sub(box(p, v3(0, 0, 1.3), (0.29, 0.23, 0.016)), box(p, v3(0, 0, 1.3), (0.25, 0.19, 0.03))), "iron")
        k.add(lambda p: box(p, v3(0, -0.225, 1.02), (0.035, 0.014, 0.045), 0.006), "brass")
    return extra


@prop("chalice_stand", "shrine", cell=(2, 3), collide=(0.45, 0.4), tags=["temple", "gold", "vessel"], name_ko="성배 받침",
    variants={"single": {}, "set": {"state": "set"}, "empty": {"state": "empty"}})
def chalice_stand(k, state="single", seed=1):
    mats(k)
    k.add(rough(lambda p: np.minimum(cyl(p, v3(0, 0, 0), 0.2, 0.04, 0.01), cap(p, v3(0, 0, 0.04), v3(0, 0, 0.62), 0.07, 0.05)), 0.006, 0.2, seed), "wood_d")
    k.add(rough(lambda p: cyl(p, v3(0, 0, 0.62), 0.24, 0.035, 0.01), 0.006, 0.2, seed), "plank_x")
    k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 0.655), 0.255, 0.012, 0.005), sub(cyl(p, v3(0, 0, 0.5), 0.262, 0.16, 0.005), cyl(p, v3(0, 0, 0.45), 0.25, 0.3)) + np.sin(np.arctan2(p[:, 1], p[:, 0]) * 14) * 0.006), "cloth_w")
    k.add(lambda p: sub(cyl(p, v3(0, 0, 0.5), 0.27, 0.028), cyl(p, v3(0, 0, 0.45), 0.25, 0.3)) + np.sin(np.arctan2(p[:, 1], p[:, 0]) * 14) * 0.006, "cloth_gd")
    if state != "empty":
        chalice(k, 0.0 if state == "single" else -0.08, -0.02, 0.668, 1.5)
    if state == "set":   # 물병 + 작은 접시
        k.add(lambda p: smin(ell(p, v3(0.11, 0.05, 0.75), (0.055, 0.055, 0.08)), cap(p, v3(0.11, 0.05, 0.8), v3(0.11, 0.05, 0.9), 0.022, 0.028), 0.02), "gilt")
        k.add(lambda p: np.maximum(ring_x(p, v3(0.17, 0.05, 0.81), 0.045, 0.008), 0.15 - p[:, 0]), "gilt")
        k.add(lambda p: cyl(p, v3(0.08, -0.14, 0.668), 0.055, 0.01, 0.004), "gilt")
    return {}


@prop("offering_box", "shrine", cell=(2, 3), collide=(0.5, 0.4), tags=["temple", "wood", "coin"], name_ko="헌금함", interact="offer",
    variants={"post": {}, "chest": {"state": "chest"}, "open": {"state": "open"}})
def offering_box(k, state="post", seed=1):
    mats(k)
    if state == "post":   # 기둥 위 상자: 위에 동전 구멍, 앞에 자물쇠
        k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.03), (0.2, 0.17, 0.03), 0.01), box(p, v3(0, 0, 0.36), (0.06, 0.06, 0.34), 0.008)), 0.006, 0.2, seed), "wood_d")
        z = 0.7
        k.add(rough(lambda p: box(p, v3(0, 0, z + 0.13), (0.2, 0.15, 0.13), 0.012), 0.006, 0.2, seed), "plank_x")
        k.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.14, 0, z + 0.13), (0.016, 0.156, 0.136)) for sx in (-1, 1)] + [box(p, v3(0, 0, z + 0.262), (0.205, 0.155, 0.01))]), "iron")
        k.add(lambda p: box(p, v3(0, 0, z + 0.27), (0.075, 0.014, 0.008)), "void")
        k.add(lambda p: np.minimum(box(p, v3(0, -0.16, z + 0.12), (0.035, 0.014, 0.04), 0.006), np.maximum(ring_x(p, v3(0, -0.16, z + 0.17), 0.025, 0.007), z + 0.16 - p[:, 2])), "brass")
        return {}
    z, w, d, h = 0.0, 0.3, 0.2, 0.15
    k.add(rough(lambda p: sub(box(p, v3(0, 0, z + h), (w, d, h), 0.012), box(p, v3(0, 0, z + h + 0.06), (w - 0.03, d - 0.03, h)) if state == "open" else p[:, 0] * 0 + 1), 0.006, 0.2, seed), "plank_x")
    k.add(lambda p: np.maximum(np.minimum.reduce([box(p, v3(sx * 0.2, 0, z + h), (0.022, d + 0.008, h + 0.006)) for sx in (-1, 1)] + [box(p, v3(0, 0, z + 0.02), (w + 0.008, d + 0.008, 0.02))]),
        -(box(p, v3(0, 0, z + h + 0.06), (w - 0.03, d - 0.03, h)) if state == "open" else p[:, 0] * 0 + 1)), "iron")
    if state == "chest":
        k.add(rough(lambda p: box(p, v3(0, 0, z + 2 * h + 0.025), (w + 0.01, d + 0.01, 0.025), 0.01), 0.006, 0.2, seed), "plank_x")
        k.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.2, 0, z + 2 * h + 0.03), (0.022, d + 0.016, 0.03)) for sx in (-1, 1)]), "iron")
        k.add(lambda p: box(p, v3(0, 0, z + 2 * h + 0.05), (0.07, 0.014, 0.006)), "void")
        k.add(lambda p: np.minimum(box(p, v3(0, -d - 0.012, z + h + 0.06), (0.04, 0.014, 0.05), 0.006), np.maximum(ring_x(p, v3(0, -d - 0.012, z + h + 0.12), 0.028, 0.008), z + h + 0.11 - p[:, 2])), "brass")
    else:   # 뚜껑이 뒤로 열려 동전이 보인다
        k.add(rough(lambda p: box(rot_x(p, 1.25, (0, d, z + 2 * h)), v3(0, 0, z + 2 * h + 0.025), (w + 0.01, d + 0.01, 0.025), 0.01), 0.006, 0.2, seed), "plank_x")
        k.add(rough(lambda p: box(p, v3(0, 0, z + 2 * h - 0.06), (w - 0.035, d - 0.035, 0.02)) + (sdf.noise(p, 0.03, seed) - 0.5) * 0.03, 0.0), "gold")
        for x, y in ((-0.45, -0.3), (-0.38, -0.36), (0.42, -0.32)):
            k.add(lambda p, x=x, y=y: cyl(p, v3(x, y, 0), 0.035, 0.008), "gold")
    return {}


# ── 독경대 · 기도서 ──────────────────────────────────────────────────────────

@prop("lectern", "shrine", cell=(2, 3), collide=(0.5, 0.45), tags=["temple", "wood", "book"], name_ko="독경대", interact="read",
    variants={"open": {}, "closed": {"state": "closed"}, "empty": {"state": "empty"}})
def lectern(k, state="open", seed=1):
    k.add(rough(lambda p: np.minimum.reduce([box(p, v3(0, 0, 0.035), (0.22, 0.2, 0.035), 0.012), box(p, v3(0, 0, 0.1), (0.13, 0.12, 0.035), 0.012), cap(p, v3(0, 0, 0.1), v3(0, 0, 0.92), 0.06, 0.045), ell(p, v3(0, 0, 0.55), (0.085, 0.085, 0.06))]), 0.006, 0.2, seed), "wood_d")
    T = lambda p: rot_x(p, -0.42, (0, 0, 0.98))
    k.add(rough(lambda p: np.minimum(box(T(p), v3(0, 0, 0.98), (0.3, 0.2, 0.022), 0.008), box(T(p), v3(0, -0.2, 1.01), (0.3, 0.014, 0.03), 0.006)), 0.006, 0.2, seed), "plank_x")
    if state == "open":
        k.add(lambda p: box(T(p), v3(0, 0, 1.01), (0.22, 0.15, 0.008), 0.004), "cloth_r")
        k.add(lambda p: np.minimum(box(T(p), v3(-0.105, 0, 1.03), (0.1, 0.14, 0.014), 0.008), box(T(p), v3(0.105, 0, 1.03), (0.1, 0.14, 0.014), 0.008)), "paper")
        k.add(lambda p: box(T(p), v3(0.03, -0.1, 1.048), (0.012, 0.12, 0.003)), "cloth_r")   # 가름끈
    elif state == "closed":
        k.add(lambda p: box(T(p), v3(0, -0.02, 1.035), (0.13, 0.16, 0.035), 0.008), "cloth_r")
        k.add(lambda p: box(T(p), v3(0.006, -0.02, 1.035), (0.13, 0.15, 0.024)), "paper")
        k.add(lambda p: np.maximum(np.abs(p[:, 0]) + np.abs(T(p)[:, 1] + 0.02) - 0.05, np.abs(T(p)[:, 2] - 1.07) - 0.006), "brass")
    return {}


@prop("prayer_books", "shrine", cell=(2, 2), tags=["temple", "book"], name_ko="기도서", interact="read",
    variants={"stack": {}, "row": {"state": "row"}, "open": {"state": "open"}})
def prayer_books(k, state="stack", seed=1):
    if state == "open":
        _open_book(k, v3(0, 0, 0), 1.0, 0.15, "cloth_r")
        k.add(lambda p: box(rot_z(p, 0.15), v3(0.02, -0.08, 0.05), (0.01, 0.1, 0.003)), "cloth_r")
    elif state == "row":   # 세워 꽂은 책 줄(책 받침 사이)
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: np.minimum(box(p, v3(sx * 0.27, 0, 0.012), (0.05, 0.08, 0.012)), box(p, v3(sx * 0.31, 0, 0.1), (0.012, 0.08, 0.1))), "brass")
        x = -0.27
        for i, (wd, mat) in enumerate(((0.04, "cloth_r"), (0.035, "leather_d"), (0.045, "cloth_r"), (0.03, "cloth_k"), (0.04, "leather"), (0.045, "cloth_r"), (0.035, "leather_d"))):
            hh = 0.1 + 0.015 * ((i * 5 + seed) % 3)
            k.add(lambda p, x=x, wd=wd, hh=hh: box(p, v3(x + wd, 0, hh), (wd - 0.004, 0.075, hh), 0.006), mat)
            k.add(lambda p, x=x, wd=wd, hh=hh: box(p, v3(x + wd, 0.004, hh + 0.004), (wd - 0.012, 0.07, hh - 0.004)), "paper")
            x += wd * 2
    else:
        for i, (a, mat) in enumerate(((0.1, "cloth_r"), (-0.15, "leather_d"), (0.3, "cloth_r"), (0.0, "cloth_k"))):
            _book(k, v3(0, 0, i * 0.05), 0.1 - i * 0.004, 0.075, 0.024, a, mat)
    return {}
