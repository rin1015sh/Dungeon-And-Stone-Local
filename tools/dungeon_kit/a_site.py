"""장소를 만드는 큰 조각(에셋 라이브러리 — docs/asset_library): 높낮이 단 · 비탈 · 암초 · 배 · 얼음 · 유리 계단 · 천장 레일 · 드론 잔해 · 도개교 ·
화약통 · 금 간 벽 · 보석 쥔 석상 · 천장까지 닿는 책장 · 불탄 벽돌집과 가구 · 계단식 사원 · 까마귀 · 떠다니는 부산물.
설정 문서에 생김새가 없는 부분(드론 · 사원의 세부 · 배의 꼴)은 지어낸 것이다(docs/asset_library/REGIONAL_ASSET_PLAN.md '남은 것')."""
import numpy as np

import fx
import mats as M
import sdf
from a_furniture import BOOKMAT, _book, _book_row, _case
from a_light import GLOWC, flame_post, shard
from a_nature import _rock
from kit import (F, box, cap, chip, cone, cut_above, cyl, ell, flat, gable, hcyl, pool, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep

PULSE = lambda f: 0.75 + 0.25 * np.sin((f or 0) * 1.5708)
_TOP = {"rock": ("#62625e", "#4c4e50", None), "grass": ("#5a5650", "#46443e", "#4a6a30"), "sand": ("#8a735a", "#6a5846", "#8a7a5c"), "ice": ("#7aa0c0", "#4a6c8c", "#b8c2cc"), "ash": ("#3c3836", "#262322", None)}


def _ledge_mats(k, kind, seed):
    a, b, top = _TOP[kind]
    k.mat("face", M.plain(a, 0.3, 0.3, seed) if kind == "ice" else M.stone(a, None, seed, 0.2 if kind == "sand" else 0.0))
    k.mat("face_d", M.plain(b, 0.3, 0.3, seed + 2) if kind == "ice" else M.stone(b, None, seed + 3))
    k.mat("top", (M.leaf(top, 0.12, seed, 0.1) if kind == "grass" else M.plain(top, 0.2, 0.3, seed + 4)) if top else M.stone(a, None, seed + 5))


# ── 높낮이 단 · 비탈 ─────────────────────────────────────────────────────────

_LV = {}
for _k in _TOP:
    _LV[_k] = {"kind": _k, "seed": 3}
    _LV[_k + "_b"] = {"kind": _k, "seed": 14}
_LV.update({"rock_end_l": {"kind": "rock", "end": -1, "seed": 5}, "rock_end_r": {"kind": "rock", "end": 1, "seed": 7}, "grass_end_l": {"kind": "grass", "end": -1, "seed": 5}, "grass_end_r": {"kind": "grass", "end": 1, "seed": 7}, "rock_high": {"kind": "rock", "h": 1.2, "seed": 9}})


@prop("ledge", "terrain", cell=(4, 4), collide=(2.0, 0.5), tags=["cliff", "height", "module"], name_ko="높낮이 단", variants=_LV,
    meta={"module": [2, 0.5], "note": "한 단 높은 땅의 앞면(남쪽을 본다) — 폭 2칸 조각을 옆으로 잇고 끝은 end_l · end_r. 위쪽 땅은 바닥 타일로 깐다. 오르내리는 길은 ramp"})
def ledge(k, kind="rock", end=0, h=0.7, seed=1):
    _ledge_mats(k, kind, seed)
    r = k.rng
    x0, x1 = (-1.0 if end >= 0 else -0.5), (1.0 if end <= 0 else 0.5)
    body = lambda p: box(p, v3((x0 + x1) / 2, 0.1, h / 2), ((x1 - x0) / 2, 0.3, h / 2), 0.04)
    if end:
        body = (lambda b: lambda p: np.maximum(b(p), (end * p[:, 0] - 0.1) * 0.6 + (p[:, 2] - h * 0.45) * 0.7))(body)   # 끝은 비스듬히 낮아진다
    k.add(chip(rough(body, 0.07, 0.3, seed), 0.44, 0.28, seed, 0.07), "face")
    for i in range(5):        # 앞면에 불거진 암괴
        x = r.uniform(x0 + 0.15, x1 - 0.15)
        k.add(_rock((x, -0.2, r.uniform(0.1, h * 0.7)), (r.uniform(0.15, 0.3), 0.14, r.uniform(0.12, 0.25)), seed + i, 5, 0.03), ("face_d", "face")[i % 2])
    k.add(lambda p: np.maximum(body(p - v3(0, 0, 0.035)), h - 0.06 - p[:, 2] + (sdf.fbm(p, 0.2, seed, 2) - 0.5) * 0.1), "top")     # 윗면 덮개(풀 · 눈 · 모래)
    k.rubble([(x0 + 0.3, -0.5), (x1 - 0.4, -0.45), (0.0, -0.55)], "face_d", 0.04, 0.08)
    return {}


@prop("ramp", "terrain", layer="decal", cell=(4, 4), collide=[(-0.95, -0.2, 0.25, 1.0), (0.7, -0.2, 0.25, 1.0)], tags=["cliff", "height", "passage"], name_ko="비탈길",
    variants={k_: {"kind": k_, "seed": 4} for k_ in _TOP}, meta={"walkable": True, "passage": True, "note": "단(ledge) 사이에 놓는 오르막 — 가운데로 오르내린다(양옆 턱만 막는다). 몸 아래에 그린다"})
def ramp(k, kind="rock", seed=1):
    _ledge_mats(k, kind, seed)
    slope = lambda p: np.maximum(box(p, v3(0, 0.25, 0.35), (0.7, 0.6, 0.35), 0.02), (p[:, 2] - (p[:, 1] + 0.4) * 0.62) * 0.85)
    k.add(rough(slope, 0.03, 0.25, seed), "top")
    for i in range(5):        # 밟아 다져진 디딤 턱
        y = -0.25 + i * 0.22
        k.add(rough(lambda p, y=y: box(p, v3(0, y, (y + 0.4) * 0.62 - 0.01), (0.62, 0.035, 0.03), 0.01), 0.015, 0.1, seed + i), "face_d")
    for sx in (-0.82, 0.82):  # 양옆 암괴
        k.add(chip(rough(lambda p, sx=sx: np.maximum(box(p, v3(sx, 0.25, 0.4), (0.14, 0.62, 0.4), 0.03), (p[:, 2] - 0.12 - (p[:, 1] + 0.4) * 0.7) * 0.8), 0.05, 0.25, seed), 0.45, 0.3, seed, 0.06), "face")
    return {"shadow": 0.3}


# ── 대해: 암초 · 배 ──────────────────────────────────────────────────────────

@prop("reef", "terrain", cell=(4, 3), collide=(1.2, 0.6), tags=["sea", "rock", "water"], name_ko="암초", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 12}, "large": {"seed": 7, "big": True}, "red": {"seed": 5, "red": True}, "red_large": {"seed": 9, "red": True, "big": True}},
    meta={"note": "물 위로 솟은 바위 — 물 칸에 놓는다(둘레에 흰 물결). red = 붉은 바위"})
def reef(k, big=False, red=False, seed=1):
    rm = k.mat("reef", M.stone("#7a3a30" if red else "#4a4e50", None, seed))
    rd = k.mat("reef_d", M.stone("#562824" if red else "#34383a", None, seed + 3))
    r = k.rng
    s = 1.4 if big else 1.0
    pts = [(0.0, 0.0, 0.34 * s)] + [(r.uniform(-0.6, 0.6) * s, r.uniform(-0.2, 0.2), r.uniform(0.1, 0.22) * s) for _ in range(4)]
    for i, (x, y, rr) in enumerate(pts):
        k.add(_rock((x, y, rr * 0.5), (rr * 1.25, rr * 0.9, rr * (1.5 if i == 0 and big else 1.0)), seed + i, 6, 0.04), (rm, rd)[i % 2])

    def foam(img, vw):        # 물에 닿는 둘레의 흰 물결(그림 아래쪽에 얹는다)
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        m = np.zeros((hh, ww), F)
        for x, y, rr in pts:
            px, py = vw.px(x, y - rr * 0.6, 0)
            d = np.hypot((xx - px) / (rr * 1.5 * vw.u), (yy - py) / (rr * 0.55 * vw.u))
            m = np.maximum(m, sstep(1.0 - np.abs(d - 1.0) / 0.22, 0, 1) * (yy > py - 2))
        from paint2d import vnoise
        return fx._over(img, m * (vnoise(hh, ww, 4.0, seed) > 0.4) * 0.75, hexc("#d0e4e0"))
    return {"post": [foam], "shadow": 0.2}


@prop("boat", "structure", cell=(5, 4), collide=(1.9, 0.7), tags=["sea", "wood", "vehicle"], name_ko="작은 배", reuse="region", interact="boat",
    variants={"beached": {}, "oars": {"oars": True}, "mast": {"mast": True}, "wreck": {"wreck": True}}, meta={"note": "현지에서 만든 작은 배. wreck = 부서진 배"})
def boat(k, oars=False, mast=False, wreck=False, seed=1):
    hull = lambda p: np.maximum(ell(p, v3(0, 0, 0.3), (1.15, 0.42, 0.42)), p[:, 2] - 0.36)
    inner = lambda p: ell(p, v3(0, 0, 0.36), (1.05, 0.33, 0.33))
    shell = lambda p: sub(hull(p), inner(p)) + np.sin(p[:, 2] * 46.0) * 0.004     # 겹쳐 댄 널
    if wreck:
        T = lambda p: rot_x(p, 0.35, (0, 0, 0))
        k.add(rough(lambda p: np.maximum(shell(T(p)), (sdf.fbm(p, 0.3, seed, 2) - 0.42) * 0.5 + (p[:, 0] - 0.3) * 0.25), 0.02, 0.2, seed), "wood_d")
        for i in range(5):    # 드러난 늑골
            x = -0.2 + i * 0.25
            k.add(lambda p, x=x: np.maximum(np.abs(np.hypot((p[:, 1]) / 0.4, (p[:, 2] - 0.36) / 0.36) - 1.0) * 0.36 - 0.025, np.maximum(np.abs(p[:, 0] - x) - 0.03, p[:, 2] - 0.4)), "wood")
        k.rubble([(0.9, -0.5), (-0.6, -0.55)], "wood_d", 0.04, 0.07)
        return {}
    k.add(rough(shell, 0.012, 0.25, seed), "wood")
    k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0] / 1.15, p[:, 1] / 0.42) - 1.0) * 0.42 - 0.03, np.abs(p[:, 2] - 0.36) - 0.025), "wood_d")   # 뱃전
    for x in (-0.45, 0.3):    # 앉는 널
        k.add(lambda p, x=x: box(p, v3(x, 0, 0.27), (0.07, 0.36, 0.015)), "plank_y")
    if oars:
        for sy in (-1, 1):
            k.add(lambda p, sy=sy: np.minimum(cap(p, v3(-0.1, sy * 0.3, 0.38), v3(0.5, sy * 0.95, 0.12), 0.02), box(rot_z(p, sy * 0.8, (0.5, sy * 0.95, 0.1)), v3(0.6, sy * 1.02, 0.1), (0.14, 0.05, 0.012))), "wood_l")
    if mast:
        k.add(lambda p: cap(p, v3(0.05, 0, 0.25), v3(0.05, 0, 2.0), 0.035, 0.025), "wood_d")
        k.add(lambda p: box(p, v3(0.05, 0.02, 1.25), (0.5, 0.012, 0.55)) + (sdf.fbm(p, 0.3, seed, 2) - 0.5) * 0.04, "linen")
        return {"cell": (5, 5)}
    return {}


# ── 얼음 · 유리 계단 ─────────────────────────────────────────────────────────

@prop("stairs_ice", "structure", cell=(4, 4), collide=[(-1.0, -0.1, 0.22, 1.7), (0.78, -0.1, 0.22, 1.7)], tags=["ice", "stairs"], name_ko="얼음 · 유리 계단", reuse="ext", base="stairs_up", interact="stairs",
    variants={"ice": {}, "ice_cracked": {"cracked": True}, "glass": {"kind": "glass"}}, meta={"note": "ice = 얼음 계단 · glass = 유리처럼 투명한 계단(옆 턱 없이 허공에 뜬 디딤판)"})
def stairs_ice(k, kind="ice", cracked=False, seed=1):
    a = k.mat("st_a", M.plain("#7aa0c0" if kind == "ice" else "#9ab4c4", 0.25, 0.3, seed))
    b = k.mat("st_b", M.plain("#a8c4dc" if kind == "ice" else "#c4d6e0", 0.2, 0.25, seed + 1))
    n, w = 6, 0.78
    for i in range(n):
        y0 = -0.1 + i * 0.3
        if kind == "glass":   # 얇은 판만 뜬다
            st = lambda p, i=i, y0=y0: box(p, v3(0, y0 + 0.15, (i + 1) * 0.22 - 0.02), (w, 0.15, 0.022), 0.008)
        else:
            st = lambda p, i=i, y0=y0: box(p, v3(0, y0 + (n - i) * 0.15, (i + 1) * 0.11), (w, (n - i) * 0.15, (i + 1) * 0.11), 0.02)
        k.add(chip(st, 0.5, 0.2, seed + i, 0.05) if cracked else st, (a, b)[i % 2])
    if kind == "ice":
        for s in (-1, 1):
            k.add(rough(lambda p, s=s: np.maximum(box(p, v3(s * (w + 0.11), 0.8, 0.6), (0.11, 0.92, 0.6), 0.03), p[:, 2] - 0.3 - (p[:, 1] + 0.1) * 0.37), 0.04, 0.25, seed + 9), k.mat("st_d", M.plain("#4a6c8c", 0.3, 0.3, seed + 2)))
    return {"far": 9.0, "post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0.6, 0.6), 60, "#a8d0f0", 0.25), [vw.px(-0.4, 0.2, 0.3), vw.px(0.3, 0.9, 0.7), vw.px(0.0, 1.4, 1.2)], "#f0f8ff")]}


# ── 공장(판텔리온): 천장 레일 · 드론 잔해 ─────────────────────────────────────

@prop("overhead_rail", "structure", layer="over", cell=(4, 5), tags=["machine", "factory", "module"], name_ko="천장 레일", reuse="region",
    variants={"straight": {}, "carriage": {"car": True}, "hook": {"hook": True}, "broken": {"broken": True}}, meta={"module": [2, 1], "note": "머리 위를 지나는 레일(2칸 조각 · 원점 = 그 아래 바닥). carriage = 매달린 운반대 · hook = 갈고리"})
def overhead_rail(k, car=False, hook=False, broken=False, seed=1):
    z = 2.7
    x1 = 0.3 if broken else 1.0
    k.add(lambda p: np.minimum(box(p, v3((x1 - 1.0) / 2, 0, z), ((x1 + 1.0) / 2, 0.06, 0.035)), box(p, v3((x1 - 1.0) / 2, 0, z + 0.07), ((x1 + 1.0) / 2, 0.025, 0.05))), "iron")
    for x in (-0.8, 0.0, 0.8):
        if x < x1:
            k.add(lambda p, x=x: cap(p, v3(x, 0, z + 0.1), v3(x, 0, 3.1), 0.022), "iron")
    if broken:
        k.add(lambda p: cap(p, v3(0.3, 0, z), v3(0.65, 0, z - 0.45), 0.04), "rust")
    if car or hook:
        k.add(lambda p: box(p, v3(-0.2, 0, z - 0.1), (0.16, 0.09, 0.07), 0.01), "steel")
        k.add(lambda p: cap(p, v3(-0.2, 0, z - 0.15), v3(-0.2, 0, z - (0.9 if hook else 0.45)), 0.015), "iron")
        if hook:
            k.add(lambda p: np.maximum(torus(rot_x(p, 1.5708, (-0.2, 0, z - 1.0)), v3(-0.2, 0, z - 1.0), 0.09, 0.022), -(p[:, 0] + 0.2) - (p[:, 2] - z + 1.0) - 0.04), "iron")
        else:
            k.add(rough(lambda p: sub(box(p, v3(-0.2, 0, z - 0.62), (0.3, 0.2, 0.17), 0.015), box(p, v3(-0.2, 0, z - 0.55), (0.26, 0.16, 0.17))), 0.01, 0.2, seed), "rust")
    return {"shadow": 0.0, "foot": 0.5}


@prop("drone_wreck", "structure", cell=(3, 3), collide=(0.7, 0.5), tags=["machine", "factory", "wreck"], name_ko="드론 잔해", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 11, "split": True}, "sparking": {"seed": 3, "frames": 4}}, light={"color": GLOWC["blue"], "radius": 1.5, "at": (0, 0, 0.3), "flicker": 0.9, "variants": ["sparking"]})
def drone_wreck(k, split=False, f=None, seed=1):
    """멈춰 떨어진 기계: 둥근 몸통 · 외눈 렌즈 · 꺾인 팔. (생김새는 지어낸 것 — 문서에는 '드론형 기계'뿐)"""
    body = lambda p: ell(rot_y(p, 0.4, (0, 0, 0.2)), v3(0, 0, 0.22), (0.34, 0.28, 0.2))
    if split:
        k.add(rough(lambda p: np.maximum(body(p), p[:, 0] * 0.8 + p[:, 2] * 0.3 - 0.1), 0.012, 0.2, seed), "steel")
        k.add(rough(lambda p: np.maximum(body(rot_z(p - v3(0.5, -0.2, -0.04), 0.9)), -p[:, 0] * 0.0 - (p[:, 0] - 0.5) * 0.8 - 0.1), 0.012, 0.2, seed + 1), "rust")
    else:
        k.add(rough(body, 0.012, 0.2, seed), "steel")
    k.add(lambda p: np.maximum(sphere(p, v3(-0.2, -0.2, 0.26), 0.09), -(sphere(p, v3(-0.24, -0.27, 0.27), 0.05))), "brass")
    k.add(lambda p: sphere(p, v3(-0.22, -0.24, 0.265), 0.05), "glass_b" if f is None else "glow_b")
    for i, (a, ln) in enumerate(((0.5, 0.5), (2.2, 0.42), (4.0, 0.36))):   # 꺾인 팔
        e = v3(np.cos(a) * ln, np.sin(a) * ln * 0.7, 0.03)
        m = v3(np.cos(a) * ln * 0.5, np.sin(a) * ln * 0.35, 0.3)
        k.add(lambda p, e=e, m=m: smin(cap(p, v3(0, 0, 0.25), m, 0.03), cap(p, m, e, 0.025, 0.012), 0.02), ("iron", "rust")[i % 2])
    k.rubble([(0.4, -0.3), (-0.45, -0.1)], "iron", 0.025, 0.05)
    if f is None:
        return {}
    pts = [(-0.22 + 0.1 * np.cos(f * 2.1 + i), -0.26, 0.3 + 0.12 * np.sin(f * 1.7 + i * 2)) for i in range(2 + f % 2)]
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(-0.22, -0.24, 0.27), 16, GLOWC["blue"], 0.4 + 0.3 * (f % 2)), [vw.px(*t) for t in pts], "#e0f0ff", 2.6)]}


# ── 도개교(핏빛성채) ─────────────────────────────────────────────────────────

@prop("drawbridge", "structure", layer="decal", cell=(4, 5), tags=["bridge", "castle", "passage"], name_ko="도개교", reuse="region", interact="bridge",
    variants={"down": {}, "down_bloody": {"blood": True}}, meta={"walkable": True, "states": {"closed": "drawbridge_raised", "open": "down"}, "note": "내려온 도개교(남북으로 놓인다 · 폭 2칸 길이 3칸 · 몸 아래에 그린다). 올린 모습은 drawbridge_raised"})
def drawbridge(k, blood=False, seed=1):
    r = k.rng
    for i in range(8):
        x = -0.84 + i * 0.24
        k.add(rough(lambda p, x=x: box(p, v3(x, 0.4, 0.05), (0.115, 1.5, 0.03), 0.008), 0.012, 0.15, seed + i), ("plank_y", "wood_d", "wood")[i % 3])
    for y in (-0.9, 0.4, 1.7):
        k.add(lambda p, y=y: box(p, v3(0, y, 0.085), (0.97, 0.05, 0.012)), "iron")
    for sx in (-1, 1):        # 사슬 고리
        k.add(lambda p, sx=sx: torus(p, v3(sx * 0.85, -0.95, 0.1), 0.06, 0.018), "iron")
    if blood:
        k.add(lambda p: pool(p, v3(0.2, 0.3, 0.085), 0.5, 0.7, 0.004) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.2, "blood")
    return {"shadow": 0.3, "foot": 1.6}


@prop("drawbridge_raised", "structure", cell=(4, 5), collide=(2.0, 0.4), tags=["bridge", "castle", "door"], name_ko="올린 도개교", reuse="region", interact="bridge", variants={"up": {}})
def drawbridge_raised(k, ang=0.12, seed=1):
    T = lambda p: rot_x(p, ang, (0, 0, 0))
    for i in range(8):
        x = -0.84 + i * 0.24
        k.add(rough(lambda p, x=x: box(T(p), v3(x, 0.0, 1.5), (0.115, 0.04, 1.5), 0.008), 0.012, 0.15, seed + i), ("plank_y", "wood_d", "wood")[i % 3])
    for z in (0.3, 1.5, 2.7):
        k.add(lambda p, z=z: box(T(p), v3(0, -0.05, z), (0.97, 0.012, 0.05)), "iron")
    for sx in (-1, 1):        # 팽팽한 사슬
        top = v3(sx * 0.85, -np.sin(ang) * 2.9 - 0.05, np.cos(ang) * 2.9)
        k.add(lambda p, sx=sx, top=top: cap(p, top, v3(sx * 0.95, 0.4, 3.0), 0.02), "iron")
    return {"far": 9.0}


# ── 화약통 · 금 간 벽(녹색 탄광) ─────────────────────────────────────────────

@prop("powder_keg", "trap", cell=(3, 3), collide=(0.5, 0.45), tags=["mine", "explosive", "trap"], name_ko="화약통", interact="trap",
    variants={"intact": {}, "hidden": {"hidden": True}, "cluster": {"n": 3}, "lit": {"lit": True, "frames": 4}, "exploded": {"gone": True}},
    light={"color": "#f0b040", "radius": 1.5, "at": (0, 0, 0.6), "flicker": 0.8, "variants": ["lit"]}, meta={"states": {"idle": "intact", "active": "lit", "spent": "exploded"}, "note": "hidden = 돌무더기에 숨겨 둔 통"})
def powder_keg(k, n=1, hidden=False, lit=False, gone=False, f=0, seed=1):
    if gone:                  # 터진 자리: 그을음 + 통 조각
        k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.7, 0.5, 0.004) + (sdf.noise(p, 0.12, seed) - 0.5) * 0.3, "coal")
        for i, (x, y) in enumerate(k.scatter(6, 0.7, 0.4)):
            k.add(lambda p, x=x, y=y, i=i: box(rot_z(p, i * 1.3, (x, y, 0)), v3(x, y, 0.03), (0.12, 0.035, 0.02)), ("wood_d", "iron")[i % 3 == 0])
        return {"shadow": 0.2}
    spots = [(0.0, 0.0)] if n == 1 else [(-0.28, 0.05), (0.28, 0.0), (0.0, -0.22)]
    for i, (x, y) in enumerate(spots):
        k.add(rough(lambda p, x=x, y=y: cyl(p, v3(x, y, 0), 0.2, 0.46, 0.03) - np.clip(0.05 - np.abs(p[:, 2] - 0.23) * 0.2, 0, 1) * 0.4, 0.012, 0.15, seed + i), "wood_d")
        for z in (0.09, 0.37):
            k.add(lambda p, x=x, y=y, z=z: torus(p, v3(x, y, z), 0.205, 0.014), "iron")
        k.add(lambda p, x=x, y=y: cap(p, v3(x, y, 0.46), v3(x + 0.1, y - 0.06, 0.56), 0.012), "rope")           # 도화선
    if hidden:
        for i, (x, y) in enumerate(((-0.28, -0.12), (0.26, -0.16), (0.02, -0.26), (-0.1, 0.2))):
            k.add(_rock((x, y, 0.13), (0.2, 0.15, 0.17), seed + i, 5, 0.03), ("stone", "stone_d")[i % 2])
    if lit:
        x, y = spots[0]
        return {"post": [flame_post(x + 0.1, y - 0.06, 0.56, 7, seed, f, "fire", 0.5, 2.0, 0.35), lambda img, vw: fx.sparkle(img, [vw.px(x + 0.1 + 0.04 * np.cos(f * 2.0), y - 0.06, 0.62 + 0.03 * np.sin(f * 1.3))], "#fff0c0", 2.4)]}
    return {}


@flat("cracked_wall", "wall", layer="wall_decal", cell=(96, 150), tags=["wall", "breakable", "secret"], name_ko="금 간 벽", interact="breakable",
    variants={"cracked": {}, "cracked_b": {"seed": 9}, "loose": {"state": "loose"}, "broken": {"state": "broken"}},
    meta={"mount": "face", "states": {"idle": "cracked", "spent": "broken"}, "note": "부술 수 있는 벽(벽면 위에 얹는다 · 원점 = 벽 밑동). broken = 뚫린 구멍 — 뒤에 샛길"})
def cracked_wall(c, state="cracked", seed=1):
    cx = c.w / 2
    if state == "broken":
        hole = c.blob(cx, 92, 34, 54, 0.35, 16, 0.05, 0, seed)
        c.paint(hole, "#080707")
        c.paint(c.rim(hole, 2.2), "#16100e", 0.9)
        c.paint(np.clip(c.blob(cx, 92, 39, 59, 0.35, 16, 0.05, 0, seed) - hole, 0, 1) * 0.5, "#8a867a")        # 깨져 드러난 돌 단면
        for i in range(7):    # 밑에 떨어진 돌
            x, y, r = cx + c.rng.uniform(-36, 36), 140 + c.rng.uniform(-5, 6), c.rng.uniform(4, 8)
            b = c.blob(x, y, r, r * 0.7, 0.3, 4, 0.1, 0, seed + i)
            c.paint(b, hexc("#6a675f") * c.rng.uniform(0.7, 1.1))
            c.paint(c.rim(b, 1.0) * 0.8, "#16100e")
    else:
        starts = [(cx + c.rng.uniform(-10, 10), 40, 1.57 + c.rng.uniform(-0.3, 0.3), 80), (cx - 8, 70, 2.6, 34), (cx + 6, 84, 0.5, 30), (cx, 56, 1.0, 26)]
        m = c.cracks(starts, 2.6 if state == "cracked" else 3.4)
        c.paint(np.roll(m, (2, 3), (0, 1)) * 0.3, "#9a968a")
        c.paint(m, "#100c0a", 0.95)
        if state == "loose":   # 돌이 들떠 어긋났다 + 틈으로 새는 바람 먼지
            lo = c.blob(cx + 4, 78, 16, 12, 0.3, 8, 0.1, 0, seed)
            c.shade(lo * 0 + np.clip(gblur(m, 6) * 2, 0, 1), -0.25)
            c.paint(c.rim(lo, 1.6), "#100c0a", 0.85)
            c.paint(c.blob(cx, 142, 22, 5, 0.4, 6, 0.3, 0, seed + 1) * 0.6, "#6a665e")
    c.origin = (cx, c.h - 2)


# ── 보석 쥔 석상(백색신전 · 석문섬) ──────────────────────────────────────────

@prop("statue_gem", "structure", cell=(3, 4), collide=(0.9, 0.7), tags=["stone", "temple", "magic"], name_ko="보석을 쥔 석상", reuse="ext", base="statue_robed", interact="statue",
    variants={"lit": {"frames": 4}, "dark": {"on": False}, "white": {"white": True, "frames": 4}, "broken": {"broken": True}},
    light={"color": GLOWC["blue"], "radius": 3.0, "at": (0, -0.25, 1.5), "flicker": 0.1, "variants": ["lit", "white"]}, meta={"states": {"idle": "dark", "active": "lit", "spent": "broken"}})
def statue_gem(k, on=True, white=False, broken=False, f=0, seed=1):
    st = k.mat("st", M.stone("#b4b0a6" if white else "#7d7a70", None, seed))
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.1), (0.44, 0.36, 0.1), 0.02), cyl(p, v3(0, 0, 0.18), 0.33, 0.3, 0.03)), 0.025, 0.2, seed), "stone_d" if not white else st)
    z0 = 0.48
    folds = lambda p: np.sin(np.arctan2(p[:, 1], p[:, 0]) * 9.0 + p[:, 2] * 2.0) * 0.018 * np.clip(1.7 - p[:, 2], 0, 1)
    robe = lambda p: smin(cap(p, v3(0, 0, z0), v3(0, 0, z0 + 1.2), 0.34, 0.2), ell(p, v3(0, 0, z0 + 1.32), (0.3, 0.2, 0.17)), 0.1) + folds(p)
    head = lambda p: smin(sphere(p, v3(0, -0.01, z0 + 1.62), 0.14), ell(p, v3(0, 0.03, z0 + 1.68), (0.17, 0.16, 0.13)), 0.05)
    arm = lambda p: smin(cap(p, v3(0.28, 0, z0 + 1.3), v3(0.3, -0.25, z0 + 1.1), 0.085, 0.07), cap(p, v3(0.3, -0.25, z0 + 1.1), v3(0.2, -0.38, z0 + 1.3), 0.07, 0.06), 0.03)   # 앞으로 내민 손
    fig = lambda p: smin(smin(robe(p), head(p), 0.05), arm(p), 0.04)
    if broken:                # 팔이 부러져 보석이 사라졌다
        k.add(cut_above(rough(lambda p: smin(robe(p), head(p), 0.05), 0.02, 0.2, seed), z0 + 1.2, 0.3, 0.2, seed, 0.3), st)
        k.rubble([(0.4, -0.4), (-0.3, -0.45), (0.1, -0.5)], st, 0.05, 0.1)
        return {}
    k.add(rough(fig, 0.02, 0.2, seed), st)
    g = v3(0.2, -0.4, z0 + 1.4)
    k.add(shard(g - v3(0, 0, 0.1), 0.06, 0.1), "crystal_b" if on else "stone_d")
    if not on:
        return {}
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(fx.halo(img, *vw.px(*g), 9, GLOWC["blue"], 0.8), *vw.px(*g), 46, GLOWC["blue"], 0.45 * PULSE(f)), [vw.px(g[0], g[1], g[2] + 0.05 - 0.02 * (f or 0))])]}


# ── 천장까지 닿는 책장(도서관) ────────────────────────────────────────────────

@prop("bookshelf_tall", "furniture", cell=(3, 6), collide=(1.2, 0.5), tags=["wood", "library"], name_ko="천장까지 닿는 책장", reuse="ext", base="bookshelf", interact="container",
    variants={"full": {}, "full_b": {"seed": 12}, "half": {"fill": 0.5}, "ladder": {"ladder": True}, "empty": {"fill": 0.0}}, meta={"note": "벽 높이를 넘는 큰 책장(책도 크다) — 옆으로 이어 놓는다. ladder = 기대 놓은 사다리"})
def bookshelf_tall(k, fill=0.95, ladder=False, seed=1):
    w, d, h = 0.58, 0.2, 3.5
    zs = tuple(0.1 + i * 0.56 for i in range(6))
    _case(k, w, d, h, zs, seed)
    if fill > 0:
        for i, z in enumerate(zs):
            _book_row(k, -w + 0.05, (w - 0.05) if fill > 0.6 or i % 2 == 0 else 0.05, -d + 0.02, d - 0.03, z + 0.015, 0.46, fill, seed + i * 7)
    k.add(rough(lambda p: box(p, v3(0, 0, h + 0.05), (w + 0.05, d + 0.04, 0.05), 0.012), 0.01, 0.2, seed), "wood_d")       # 처마
    if ladder:
        for sx in (-0.2, 0.2):
            k.add(lambda p, sx=sx: cap(p, v3(0.1 + sx, -0.75, 0), v3(0.1 + sx, -d - 0.02, 2.9), 0.028), "wood_l")
        for i in range(8):
            t = (i + 0.7) / 9
            k.add(lambda p, t=t: hcyl(p, v3(-0.1, -0.75 + (0.75 - d) * t, 2.9 * t), v3(0.3, -0.75 + (0.75 - d) * t, 2.9 * t), 0.02), "wood")
    return {"far": 9.0}


# ── 불탄 벽돌집과 가구(불의 거울) ────────────────────────────────────────────

@prop("burnt_house", "structure", cell=(8, 8), collide=(3.0, 1.5), tags=["house", "brick", "burnt", "landmark"], name_ko="불탄 2층 벽돌집", reuse="region", interact="door",
    variants={"ruin": {}, "door_open": {"door": False}}, meta={"note": "검게 그을린 나무 문이 달린 2층 벽돌집(겉모습 한 덩이 — 안은 따로 방으로). door_open = 문이 열렸다"})
def burnt_house(k, door=True, seed=1):
    brick = k.mat("bk", M.masonry("#5a463c", 0.14, 0.34, None, seed))
    W2, D2, H = 1.6, 0.75, 2.9
    shell = lambda p: box(p, v3(0, 0.3, H / 2), (W2, D2, H / 2), 0.02)
    holes = lambda p: np.minimum.reduce([box(p, v3(sx, -0.45, z), (0.24, 0.3, 0.3)) for sx in (-0.95, 0.95) for z in (0.9, 2.15)] + [box(p, v3(0, -0.45, 2.15), (0.24, 0.3, 0.3)), box(p, v3(0, -0.45, 0.62), (0.32, 0.3, 0.62))])
    body = lambda p: sub(shell(p), holes(p))
    k.add(chip(rough(cut_above(body, H - 0.15, 0.5, 0.4, seed, 0.12), 0.02, 0.25, seed), 0.4, 0.3, seed, 0.05), brick)
    k.add(lambda p: box(p, v3(0, 0.2, 1.4), (W2 - 0.1, D2 - 0.25, 1.35)), "void")                                          # 속은 어둠
    for i in range(5):        # 내려앉은 지붕 들보(숯)
        x = -1.3 + i * 0.65
        k.add(rough(lambda p, x=x, i=i: cap(p, v3(x, -0.4, H - 0.1 - (i % 2) * 0.5), v3(x + 0.25, 1.0, H + 0.35 - (i % 3) * 0.3), 0.06), 0.02, 0.1, seed + i), "coal")
    k.add(rough(lambda p: box(p, v3(0, -0.5, 0.05), (0.5, 0.2, 0.05), 0.015), 0.01, 0.2, seed), "stone_d")                 # 문턱
    if door:
        k.add(rough(lambda p: box(p, v3(0, -0.44, 0.66), (0.3, 0.035, 0.58), 0.01), 0.015, 0.12, seed + 7), "coal")
        k.add(lambda p: sphere(p, v3(0.2, -0.49, 0.62), 0.03), "iron")
    k.rubble(k.scatter(8, 1.7, 0.3, 0, -0.75), "brick", 0.05, 0.1)

    def soot(img, vw):        # 창 위로 번진 그을음
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        m = np.zeros((hh, ww), F)
        for sx, z in ((-0.95, 1.25), (0.95, 1.25), (-0.95, 2.5), (0, 2.5), (0.95, 2.5), (0, 1.3)):
            px, py = vw.px(sx, -0.45, z)
            m = np.maximum(m, sstep(1.0 - np.hypot((xx - px) / (0.34 * vw.u), (yy - py + 0.2 * vw.u) / (0.5 * vw.u)), 0, 0.8))
        return fx._over(img, m * 0.6 * (img[..., 3] > 128), hexc("#0c0a0a"))
    return {"far": 10.0, "post": [soot], "foot": 1.2}


@prop("burnt_furniture", "furniture", cell=(3, 3), tags=["burnt", "home", "wreck"], name_ko="불타 뼈대만 남은 가구", variants={"table": {"kind": "table"}, "bed": {"kind": "bed"}, "shelf": {"kind": "shelf"}, "chair": {"kind": "chair"}})
def burnt_furniture(k, kind="table", seed=1):
    bar = lambda a, b, r=0.035: (lambda p: cap(p, v3(*a), v3(*b), r, r * 0.8) + (sdf.fbm(p, 0.08, seed, 2) - 0.5) * 0.025)
    if kind == "table":
        segs = [((sx * 0.5, sy * 0.3, 0), (sx * 0.5, sy * 0.3, 0.55)) for sx in (-1, 1) for sy in (-1, 1)][:3] + [((-0.5, -0.3, 0.55), (0.5, -0.3, 0.55)), ((-0.5, 0.3, 0.55), (0.5, 0.3, 0.5)), ((-0.5, -0.3, 0.55), (-0.5, 0.3, 0.55)), ((0.5, 0.3, 0.5), (0.6, -0.4, 0.05))]
    elif kind == "bed":
        segs = [((sx * 0.75, sy * 0.38, 0), (sx * 0.75, sy * 0.38, 0.5 if sx < 0 else 0.3)) for sx in (-1, 1) for sy in (-1, 1)] + [((-0.75, sy * 0.38, 0.22), (0.75, sy * 0.38, 0.22)) for sy in (-1, 1)] + [((x, -0.38, 0.22), (x, 0.38, 0.22)) for x in (-0.4, 0.0, 0.4)]
    elif kind == "shelf":
        segs = [((sx * 0.45, 0, 0), (sx * 0.45 + sx * 0.03, 0, 1.5 - (sx > 0) * 0.5)) for sx in (-1, 1)] + [((-0.45, 0, z), (0.45, 0, z - 0.03)) for z in (0.1, 0.55, 1.0)] + [((-0.2, -0.3, 0.03), (0.5, -0.45, 0.05))]
    else:
        segs = [((sx * 0.2, sy * 0.2, 0), (sx * 0.2, sy * 0.2, 0.42)) for sx in (-1, 1) for sy in (-1, 1)] + [((-0.2, 0.2, 0.42), (-0.22, 0.2, 0.95)), ((0.2, 0.2, 0.42), (0.22, 0.2, 0.8)), ((-0.2, -0.2, 0.42), (0.2, -0.2, 0.42)), ((-0.2, 0.2, 0.42), (0.2, 0.2, 0.42))]
    for i, (a, b) in enumerate(segs):
        k.add(bar(a, b), "coal" if i % 3 else "ash")
    k.add(lambda p: pool(p, v3(0, -0.1, 0.004), 0.6, 0.4, 0.004) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.25, "ash")
    return {"shadow": 0.35}


# ── 계단식 사원(아틀란테) ────────────────────────────────────────────────────

@prop("pyramid_temple", "structure", cell=(11, 9), collide=(5.0, 2.6), tags=["temple", "landmark", "stone"], name_ko="계단식 사원", reuse="region", interact="entrance",
    variants={"intact": {}, "sunken": {"sunken": True}, "lit": {"lit": True, "frames": 4}}, light={"color": "#a8d0f0", "radius": 4.0, "at": (0, -0.6, 2.6), "flicker": 0.1, "variants": ["lit"]},
    meta={"note": "피라미드 구조의 큰 사원(한 덩이 랜드마크 · 폭 5칸) — 가운데 계단, 꼭대기 좁은 방의 문이 입구. sunken = 물에 잠겨 삭았다"})
def pyramid_temple(k, sunken=False, lit=False, f=0, seed=1):
    st = k.mat("tp", M.masonry("#787060" if not sunken else "#5e665e", 0.2, 0.5, "#4a6a5a" if sunken else None, seed))
    tiers = 5
    for i in range(tiers):
        w, d, z = 2.5 - i * 0.42, 1.3 - i * 0.2, i * 0.5
        body = lambda p, w=w, d=d, z=z: box(p, v3(0, 0.2, z + 0.25), (w, d, 0.25), 0.02)
        k.add(chip(rough(body, 0.02, 0.3, seed + i), 0.43 if sunken else 0.36, 0.3, seed + i, 0.05), st)
    k.add(rough(lambda p: np.maximum(box(p, v3(0, -0.5, 1.25), (0.38, 0.9, 1.25), 0.01), (p[:, 2] - (p[:, 1] + 1.4) * 1.5) * 0.55) + np.abs(((p[:, 2] / 0.125) % 1.0) - 0.5) * 0.02, 0.01, 0.2, seed), "stone_l")   # 가운데 계단
    k.add(rough(lambda p: sub(box(p, v3(0, 0.25, 2.85), (0.5, 0.42, 0.36), 0.02), box(p, v3(0, -0.2, 2.78), (0.17, 0.3, 0.27))), 0.015, 0.2, seed + 9), st)       # 꼭대기 방
    k.add(lambda p: box(p, v3(0, 0.0, 2.78), (0.16, 0.05, 0.26)), "glow_b" if lit else "void")
    k.rubble(k.scatter(8, 2.6, 0.3, 0, -1.3), "stone", 0.05, 0.11)
    post = []
    if lit:
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, -0.3, 2.78), 50, "#a8d0f0", 0.4 * PULSE(f)))
    return {"far": 12.0, "scale": 0.9, "foot": 1.6, "post": post}


# ── 까마귀 · 떠다니는 부산물 ─────────────────────────────────────────────────

@flat("crows", "fx", layer="over", cell=(128, 80), tags=["bird", "animated", "sky"], name_ko="까마귀 떼", reuse="region", fps=6, variants={"flock": {"frames": 4}, "flock_b": {"frames": 4, "seed": 9}, "few": {"frames": 4, "n": 3}},
    meta={"note": "머리 위를 나는 검은 새 그림자(4프레임 날갯짓) — 놓는 쪽에서 옆으로 움직인다"})
def crows(c, n=7, f=0, seed=1):
    rng = np.random.default_rng(seed)
    for i in range(n):
        x, y, s = rng.uniform(14, 114), rng.uniform(12, 68), rng.uniform(0.7, 1.15)
        flap = np.sin((f or 0) * 1.5708 + i * 1.3)                   # −1 날개 내림 … 1 올림
        m = c.blob(x, y, 3.2 * s, 1.8 * s, 0.1, 2, 0.3)
        for sgn in (-1, 1):
            tip = (x + sgn * 8.5 * s, y - flap * 5.0 * s)
            mid = (x + sgn * 4.5 * s, y - flap * 3.4 * s - 1.2 * s)
            m = np.maximum(m, c.seg([(x, y), mid, tip], 3.0 * s))
        m = np.maximum(m, c.seg([(x, y), (x + 4.6 * s, y + 0.6 * s)], 1.8 * s))   # 부리 쪽
        c.paint(m, "#100e10", 0.92)
    c.origin = (64, 40)


@flat("flotsam", "fx", layer="decal", cell=(112, 80), tags=["water", "debris"], name_ko="떠다니는 부산물", variants={"planks": {"kind": "planks", "frames": 2}, "barrel": {"kind": "barrel", "frames": 2}, "mixed": {"kind": "mixed", "frames": 2}}, fps=2,
    meta={"note": "물 위에 뜬 잔해(2프레임 — 살짝 까딱인다). 물 칸에 놓는다"})
def flotsam(c, kind="planks", f=0, seed=1):
    rng = np.random.default_rng(seed + len(kind))
    bob = (f or 0) * 1.2
    items = {"planks": ["p", "p", "p"], "barrel": ["b", "p"], "mixed": ["b", "p", "c", "p"]}[kind]
    for i, it in enumerate(items):
        x, y, a = rng.uniform(26, 86), rng.uniform(24, 56) + bob * (1 if i % 2 else -1), rng.uniform(-0.6, 0.6)
        if it == "p":
            m = c.seg([(x - np.cos(a) * 17, y - np.sin(a) * 17), (x + np.cos(a) * 17, y + np.sin(a) * 17)], 6.5, False)
            col = "#5a4430"
        elif it == "b":
            m = c.blob(x, y, 12, 9, 0.08, 6, 0.05)
            col = "#4a3828"
        else:
            m = c.rect(x - 10, y - 8, x + 10, y + 7)
            col = "#62503a"
        ring = np.clip(gblur(m, 5.0) * 1.6 - m, 0, 1)
        c.add(ring * (c.noise(5, seed + i + (f or 0)) > 0.45), "#c0d4d8", 0.3)       # 둘레 잔물결
        c.paint(m, hexc(col)[None, None, :] * (0.85 + c.noise(5, seed + i * 3)[..., None] * 0.3))
        if it == "b":
            c.paint(c.ring(x, y, 9, 1.6, ry=6.5) * m, "#2e2e30", 0.9)
        c.shade(m * sstep(c.yy - y, 0.0, 6.0), -0.35)                               # 물에 잠긴 아래쪽
        c.paint(c.rim(m, 1.2) * 0.8, "#16100e")
    c.origin = (56, 40)
