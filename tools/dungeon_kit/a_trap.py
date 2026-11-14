"""함정: 바닥 가시 · 벽 창 · 천장 낙하물 · 회전 칼날 · 진자 도끼 · 독가스 · 화염 분사 · 무너지는 바닥 · 구덩이 · 화살 구멍 · 인계철선 · 룬 함정 · 함정의 흔적.
한 함정 = 작동 전(바닥에 붙는 decal) / 작동 중(서 있는 stand) / 작동 뒤(흔적)가 따로 놓이는 에셋 — meta.states = {"idle" · "active" · "spent": "에셋.변형"}으로 짝을 알린다."""
import numpy as np

import fx
import sdf
from a_light import GLOWC, cglyph, chain, flame_post, gear_x, gear_z, rune_post
from kit import (F, box, cap, chip, cone, cut_above, cyl, disc_x, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from paint2d import gblur, hexc, sstep

PULSE = lambda f: 0.75 + 0.25 * np.sin(f * 1.5708)


def _spike(x, y, h, r=0.045, z0=0.0, lean=0.0):
    return lambda p: cap(p, v3(x, y, z0), v3(x + lean, y, z0 + h), r, 0.004)


def _grid(n=3, span=0.3):
    return [((i - (n - 1) / 2) * span, (j - (n - 1) / 2) * span) for j in range(n) for i in range(n)]


# ── 바닥 가시 ────────────────────────────────────────────────────────────────

def _spike_base(k, seed):
    k.add(rough(lambda p: box(p, v3(0, 0, 0.02), (0.46, 0.46, 0.02), 0.01), 0.01, 0.2, seed), "stone_d")
    k.add(lambda p: np.minimum.reduce([cyl(p, v3(x, y, 0.036), 0.06, 0.012) for x, y in _grid()]), "void")
    k.add(lambda p: np.minimum.reduce([torus(p, v3(x, y, 0.042), 0.066, 0.012) for x, y in _grid()]), "iron")


@prop("spike_plate", "trap", layer="decal", cell=(2, 2), tags=["trap", "iron"], name_ko="가시 함정(숨음)", interact="trap",
    variants={"idle": {}, "bloody": {"blood": True}}, meta={"states": {"idle": "spike_plate.idle", "active": "spike_trap.extended", "spent": "spike_trap.bloody"}})
def spike_plate(k, blood=False, seed=1):
    _spike_base(k, seed)
    if blood:
        k.add(lambda p: pool(p, v3(0.1, -0.05, 0.045), 0.3, 0.22, 0.004) + (sdf.noise(p, 0.1, seed) - 0.45) * 0.14, "blood")
    return {"shadow": 0.2}


@prop("spike_trap", "trap", cell=(2, 2), tags=["trap", "iron"], name_ko="가시 함정(솟음)", interact="trap",
    variants={"half": {"h": 0.25}, "extended": {}, "bloody": {"state": "bloody"}, "rusted": {"state": "rusted"}},
    meta={"states": {"idle": "spike_plate.idle", "active": "spike_trap.extended", "spent": "spike_trap.bloody"}, "frames_rise": ["half", "extended"]})
def spike_trap(k, state="extended", h=0.62, seed=1):
    _spike_base(k, seed)
    rng = np.random.default_rng(seed)
    for i, (x, y) in enumerate(_grid()):
        hh, lean = h, 0.0
        if state == "rusted":
            if i in (2, 6):
                continue   # 부러져 없어진 가시
            hh, lean = h * rng.uniform(0.35, 1.0), rng.uniform(-0.1, 0.1)
        k.add(_spike(x, y, hh, 0.045, 0.03, lean), "rust" if state == "rusted" else "steel")
        if state == "bloody" and i % 2 == 0:
            k.add(_spike(x, y, hh * 1.005, 0.047, 0.03 + hh * 0.45), "blood")
    if state == "bloody":
        k.add(lambda p: pool(p, v3(0.05, -0.1, 0.045), 0.32, 0.2, 0.004) + (sdf.noise(p, 0.1, seed) - 0.45) * 0.14, "blood")
    if state == "rusted":
        k.add(lambda p: hcyl(p, v3(0.3, -0.5, 0.03), v3(0.62, -0.42, 0.03), 0.03), "rust")
    return {}


# ── 벽 창 ────────────────────────────────────────────────────────────────────

@prop("spear_wall", "trap", layer="wall_decal", cell=(3, 4), tags=["trap", "iron", "stone"], name_ko="벽 창 함정", interact="trap",
    variants={"idle": {}, "out": {"state": "out"}, "bloody": {"state": "bloody"}}, meta={"states": {"idle": "idle", "active": "out", "spent": "bloody"}})
def spear_wall(k, state="idle", seed=1):
    xs = (-0.36, 0.0, 0.36)
    slots = lambda p: np.minimum.reduce([box(p, v3(x, 0.0, 1.05), (0.06, 0.08, 0.06), 0.02) for x in xs])
    k.add(rough(lambda p: sub(box(p, v3(0, 0.07, 1.05), (0.6, 0.05, 0.2), 0.02), slots(p)), 0.015, 0.15, seed), "stone_d")
    k.add(lambda p: np.minimum.reduce([box(p, v3(x, 0.06, 1.05), (0.055, 0.02, 0.055)) for x in xs]), "void")
    for sx in (-0.52, 0.52):
        for z in (0.92, 1.18):
            k.add(lambda p, sx=sx, z=z: sphere(p, v3(sx, 0.02, z), 0.025), "iron")
    if state == "idle":
        return {"shadow": 0.0}
    for i, x in enumerate(xs):   # 벽에서 앞으로(−y) 살짝 아래로 찔러 나온 창
        tip = v3(x, -1.0, 0.86)
        mid = v3(x, -0.72, 0.91)
        k.add(lambda p, x=x, mid=mid: cap(p, v3(x, 0.05, 1.05), mid, 0.026), "wood_d")
        k.add(lambda p, mid=mid, tip=tip: cap(p, mid, tip, 0.055, 0.004), "blood" if (state == "bloody" and i != 1) else "steel")
        k.add(lambda p, mid=mid: sphere(p, mid, 0.04), "iron")
    return {"shadow": 0.35}


# ── 천장 낙하물 ──────────────────────────────────────────────────────────────

def _block(c, s, seed):
    return chip(rough(lambda p: box(p, c, (0.44 * s, 0.4 * s, 0.4 * s), 0.03), 0.03, 0.25, seed), 0.47, 0.3, seed, 0.07)


@flat("ceiling_warn", "trap", cell=(96, 96), tags=["trap"], name_ko="낙하 함정 자리", interact="trap",
    variants={"a": {}, "b": {"seed": 4}}, meta={"states": {"idle": "ceiling_warn.a", "active": "ceiling_chain.hang", "spent": "ceiling_block.fallen"}})
def ceiling_warn(c, seed=1):
    """떨어지기 전: 바닥에 드리운 네모 그늘 + 먼저 떨어진 돌 부스러기 · 잔금."""
    sh = gblur(c.rect(18, 18, 78, 78, 4.0), 8.0)
    c.paint(sh, "#0c0a0a", 0.42)
    cr = c.cracks([(48, 48, a, 20) for a in (0.4, 2.3, 4.1)], 1.6)
    c.paint(cr, "#120e0c", 0.7)
    for _ in range(9):
        x, y, r = c.rng.uniform(16, 80), c.rng.uniform(16, 80), c.rng.uniform(1.6, 3.6)
        b = c.blob(x, y, r, r * 0.8, 0.3, 3, 0.3)
        c.paint(np.roll(b, 2, 0), "#141010", 0.5)
        c.paint(b, hexc("#7d7a70") * c.rng.uniform(0.7, 1.1))
    c.paint(sstep(c.noise(3, seed + 5, 2), 0.62, 0.7) * sh, "#a09a8a", 0.35)   # 돌가루


@prop("ceiling_chain", "trap", layer="over", cell=(2, 5), tags=["trap", "stone"], name_ko="매달린 낙하석", interact="trap",
    variants={"hang": {}, "falling": {"z": 1.2}}, meta={"states": {"idle": "ceiling_warn.a", "active": "ceiling_chain.hang", "spent": "ceiling_block.fallen"}})
def ceiling_chain(k, z=2.0, seed=1):
    k.add(_block(v3(0, 0, z + 0.4), 1.0, seed), "masonry")
    for x, y in ((-0.3, -0.25), (0.3, -0.25), (-0.3, 0.25), (0.3, 0.25)):
        k.add(lambda p, x=x, y=y: torus(rot_x(p, 1.57, (x, y, z + 0.84)), v3(x, y, z + 0.84), 0.05, 0.018), "iron")
    if z > 1.5:
        for s in (-1, 1):
            k.add(chain(v3(s * 0.3, -0.25, z + 0.86), v3(0, -0.1, z + 1.45), 0.022), "iron")
        k.add(chain(v3(0, -0.1, z + 1.42), v3(0, -0.1, z + 1.9), 0.026), "iron")
    else:
        k.add(chain(v3(-0.3, -0.25, z + 0.86), v3(-0.36, -0.25, z + 1.3), 0.022), "iron")
    return {"shadow": 0.0, "far": 9.0}


@prop("ceiling_block", "trap", cell=(3, 3), collide=(1.0, 0.9), tags=["trap", "stone", "ruin"], name_ko="떨어진 낙하석",
    variants={"fallen": {}, "bloody": {"blood": True}, "dust": {"dust": True, "frames": 3}})
def ceiling_block(k, blood=False, dust=False, seed=1, f=0):
    k.add(_block(v3(0, 0, 0.3), 1.0, seed), "masonry")
    k.add(lambda p: torus(rot_x(p, 1.2, (-0.3, -0.2, 0.72)), v3(-0.3, -0.2, 0.72), 0.05, 0.018), "iron")
    k.add(chain(v3(-0.3, -0.2, 0.72), v3(-0.75, -0.5, 0.03), 0.022), "iron")
    k.rubble(k.scatter(9, 0.85, 0.6, 0, -0.1, 0.55), "stone", 0.04, 0.1)
    if blood:
        k.add(lambda p: pool(p, v3(0.1, -0.5, 0.006), 0.42, 0.2, 0.006) + (sdf.noise(p, 0.1, seed) - 0.45) * 0.12, "blood")
    if dust:
        mk = lambda s: (lambda img, vw: fx.puff(img, *vw.px(s * (0.5 + f * 0.12), -0.3, 0.1), 12 + f * 4, "#9a9486", 0.5 - f * 0.12, seed + int(s * 3) + 5, f, 8 + f * 5, 5))
        return {"post": [mk(-1), mk(1)]}
    return {}


# ── 회전 칼날 · 진자 ─────────────────────────────────────────────────────────

@prop("blade_slot", "trap", layer="decal", cell=(3, 2), tags=["trap", "iron"], name_ko="칼날 홈", interact="trap",
    variants={"idle": {}, "bloody": {"blood": True}}, meta={"states": {"idle": "blade_slot.idle", "active": "blade_trap.spin", "spent": "blade_trap.bloody"}})
def blade_slot(k, blood=False, seed=1):
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.02), (0.95, 0.16, 0.02), 0.01), box(p, v3(0, 0, 0.03), (0.86, 0.035, 0.05))), 0.008, 0.2, seed), "iron")
    k.add(lambda p: box(p, v3(0, 0, 0.012), (0.86, 0.035, 0.01)), "void")
    for x in (-0.9, -0.45, 0.45, 0.9):
        for y in (-0.11, 0.11):
            k.add(lambda p, x=x, y=y: sphere(p, v3(x, y, 0.04), 0.018), "steel")
    if blood:
        k.add(lambda p: pool(p, v3(0.2, -0.08, 0.043), 0.3, 0.12, 0.004) + (sdf.noise(p, 0.08, seed) - 0.45) * 0.1, "blood")
    return {"shadow": 0.2}


@prop("blade_trap", "trap", cell=(3, 3), collide=(0.9, 0.2), tags=["trap", "iron"], name_ko="회전 칼날", interact="trap",
    variants={"spin": {"frames": 4}, "still": {}, "bloody": {"blood": True, "frames": 4}, "jammed": {"jam": True}},
    meta={"states": {"idle": "blade_slot.idle", "active": "blade_trap.spin", "spent": "blade_trap.jammed"}})
def blade_trap(k, blood=False, jam=False, seed=1, f=0):
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.02), (0.95, 0.16, 0.02), 0.01), box(p, v3(0, 0, 0.03), (0.86, 0.035, 0.05))), 0.008, 0.2, seed), "iron")
    c = v3(-0.25 if jam else 0.0, 0, 0.12)
    ph = f * (2 * np.pi / 14 / 4) * 14
    saw = lambda p: gear_x(p, c, 0.5, 0.014, 14, ph, 0.0) if not jam else gear_x(rot_y(p, 0.2, c), c, 0.5, 0.014, 14, 0.4, 0.0)
    k.add(lambda p: np.maximum(saw(p), 0.02 - p[:, 2]), "rust" if jam else "steel")
    k.add(lambda p: np.maximum(disc_x(p, c, 0.13, 0.03), 0.02 - p[:, 2]), "iron")
    if blood:
        k.add(lambda p: np.maximum(np.maximum(disc_x(p, c, 0.53, 0.017), 0.3 - np.hypot(p[:, 0] - c[0], p[:, 2] - c[2])), np.sin(np.arctan2(p[:, 2] - c[2], p[:, 0] - c[0]) * 3 + ph * 0.3 + sdf.noise(p, 0.1, seed) * 3) * 0.2 + 0.05), "blood")
        k.add(lambda p: pool(p, v3(0.3, -0.25, 0.005), 0.3, 0.12, 0.005) + (sdf.noise(p, 0.08, seed) - 0.45) * 0.1, "blood")
    if jam:
        k.add(lambda p: hcyl(p, v3(0.1, -0.2, 0.05), v3(0.6, 0.1, 0.3), 0.03), "wood_d")   # 끼워 넣은 막대
    return {}


@prop("pendulum", "trap", layer="over", cell=(5, 5), tags=["trap", "iron"], name_ko="진자 도끼", interact="trap",
    variants={"swing": {"frames": 3}, "still": {"a": 0.0}, "bloody": {"a": 0.0, "blood": True}}, fps=4, meta={"swing_cycle": [0, 1, 2, 1]})
def pendulum(k, a=None, blood=False, seed=1, f=0):
    a = (-0.55, 0.0, 0.55)[f] if a is None else a
    piv = v3(0, 0, 3.3)
    T = lambda p: rot_y(p, -a, piv)
    k.add(lambda p: np.minimum(box(p, piv + v3(0, 0, 0.1), (0.2, 0.08, 0.06), 0.02), hcyl(p, piv + v3(0, -0.1, 0), piv + v3(0, 0.1, 0), 0.05)), "iron")
    k.add(lambda p: cap(T(p), piv, v3(0, 0, 1.25), 0.035), "wood_d")
    cb = v3(0, 0, 1.2)
    blade = lambda p: np.maximum(np.maximum(disc_x(T(p), cb, 0.62, 0.016), -(disc_x(T(p), cb + v3(0, 0, 0.42), 0.6, 0.1))), T(p)[:, 2] - cb[2] - 0.12)   # 초승달 날
    k.add(blade, "steel")
    k.add(lambda p: box(T(p), cb + v3(0, 0, 0.05), (0.09, 0.045, 0.12), 0.02), "iron")
    if blood:
        k.add(lambda p: np.maximum(blade(p) - 0.004, T(p)[:, 2] - cb[2] + 0.42 + sdf.noise(p, 0.12, seed) * 0.12), "blood")
    return {"shadow": 0.0, "far": 9.0}


# ── 독가스 · 화염 ────────────────────────────────────────────────────────────

def _grate(k, seed, z=0.0):
    k.add(rough(lambda p: sub(cyl(p, v3(0, 0, z), 0.34, 0.045, 0.012), cyl(p, v3(0, 0, z + 0.02), 0.26, 0.06)), 0.01, 0.15, seed), "stone_d")
    k.add(lambda p: cyl(p, v3(0, 0, z), 0.26, 0.012), "void")
    k.add(lambda p: np.minimum.reduce([hcyl(p, v3(x, -np.sqrt(0.068 - x * x), z + 0.03), v3(x, np.sqrt(0.068 - x * x), z + 0.03), 0.018) for x in (-0.16, -0.055, 0.055, 0.16)] + [torus(p, v3(0, 0, z + 0.03), 0.26, 0.02)]), "rust")


@prop("gas_grate", "trap", layer="decal", cell=(2, 2), tags=["trap", "iron", "sewer"], name_ko="독가스 분출구", interact="trap",
    variants={"idle": {}, "stained": {"stain": True}}, meta={"states": {"idle": "gas_grate.idle", "active": "gas_vent.venting", "spent": "gas_grate.stained"}})
def gas_grate(k, stain=False, seed=1):
    _grate(k, seed)
    if stain:
        return {"shadow": 0.2, "post": [lambda img, vw: fx.puff(img, *vw.px(0, 0, 0.05), 20, "#4a5a2a", 0.3, seed, 0, 0, 7)]}
    return {"shadow": 0.2}


@prop("gas_vent", "trap", cell=(3, 4), tags=["trap", "poison"], name_ko="독가스 분출", interact="trap",
    variants={"venting": {"frames": 4}, "thin": {"frames": 4, "amount": 0.5}}, meta={"states": {"idle": "gas_grate.idle", "active": "gas_vent.venting"}},
    light={"color": GLOWC["green"], "radius": 1.5, "at": (0, 0, 0.6), "flicker": 0.3, "variants": ["venting"]})
def gas_vent(k, amount=1.0, seed=1, f=0):
    _grate(k, seed)
    def post(img, vw):
        x, y = vw.px(0, 0, 0.06)
        img = fx.puff(img, x, y - 4, 26 * amount, "#5a7a30", 0.5 * amount, seed, f, 80 * amount, 8)
        img = fx.puff(img, x, y - 2, 15 * amount, "#9ac850", 0.5 * amount, seed + 3, f, 46 * amount, 6)
        return fx.puff(img, x, y, 7, "#d8f0a0", 0.5, seed + 5, f, 14, 3)
    return {"shadow": 0.2, "post": [post]}


@prop("gas_vent_wall", "trap", layer="wall_decal", cell=(3, 3), tags=["trap", "poison", "stone"], name_ko="벽 독가스 구멍", interact="trap",
    variants={"idle": {}, "venting": {"on": True, "frames": 4}}, meta={"states": {"idle": "idle", "active": "venting"}})
def gas_vent_wall(k, on=False, seed=1, f=0):
    k.add(rough(lambda p: sub(box(p, v3(0, 0.07, 0.6), (0.24, 0.05, 0.2), 0.03), box(p, v3(0, 0.0, 0.6), (0.15, 0.06, 0.11), 0.02)), 0.015, 0.15, seed), "stone_d")
    k.add(lambda p: box(p, v3(0, 0.07, 0.6), (0.15, 0.02, 0.11)), "void")
    k.add(lambda p: np.minimum.reduce([cap(p, v3(x, 0.03, 0.5), v3(x, 0.03, 0.7), 0.016) for x in (-0.08, 0.0, 0.08)]), "rust")
    if not on:
        return {"shadow": 0.0}
    def post(img, vw):
        x, y = vw.px(0, -0.1, 0.55)
        img = img[::-1].copy()   # 가스가 벽에서 앞(화면 아래)으로 퍼지게 뒤집어 칠한다
        yy = img.shape[0] - y
        img = fx.puff(img, x, yy, 22, "#5a7a30", 0.5, seed, f, 44, 7)
        img = fx.puff(img, x, yy, 11, "#9ac850", 0.5, seed + 3, f, 22, 5)
        return img[::-1].copy()
    return {"shadow": 0.0, "post": [post]}


def _nozzle(k, seed):
    k.add(rough(lambda p: box(p, v3(0, 0, 0.025), (0.36, 0.36, 0.025), 0.012), 0.01, 0.2, seed), "stone_d")
    k.add(lambda p: sub(smin(cyl(p, v3(0, 0, 0.04), 0.2, 0.04, 0.012), cap(p, v3(0, 0, 0.06), v3(0, 0, 0.17), 0.13, 0.085), 0.03), cyl(p, v3(0, 0, 0.1), 0.055, 0.2)), "bronze")
    k.add(lambda p: cyl(p, v3(0, 0, 0.1), 0.055, 0.02), "void")


@prop("flame_nozzle", "trap", layer="decal", cell=(2, 2), tags=["trap", "fire", "brass"], name_ko="화염 분사구", interact="trap",
    variants={"idle": {}, "scorched": {"scorch": True}, "pilot": {"pilot": True, "frames": 4}},
    meta={"states": {"idle": "flame_nozzle.idle", "active": "flame_jet.firing", "spent": "flame_nozzle.scorched"}})
def flame_nozzle(k, scorch=False, pilot=False, seed=1, f=0):
    if scorch:
        k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.62, 0.55, 0.004) + (sdf.fbm(p, 0.2, seed, 2) - 0.35) * 0.3, "coal")
    _nozzle(k, seed)
    if pilot:
        return {"shadow": 0.2, "post": [flame_post(0, 0, 0.17, 7, seed, f, "blue", 0.36, 2.0, 0.25)]}
    return {"shadow": 0.2}


@prop("flame_jet", "trap", cell=(3, 5), tags=["trap", "fire"], name_ko="화염 분사", interact="trap",
    variants={"firing": {"frames": 4}, "low": {"frames": 4, "h": 44}}, meta={"states": {"idle": "flame_nozzle.idle", "active": "flame_jet.firing", "spent": "flame_nozzle.scorched"}},
    light={"color": "#f0a040", "radius": 5.0, "at": (0, 0, 1.0), "flicker": 0.5, "variants": ["firing", "low"]})
def flame_jet(k, h=108, seed=1, f=0):
    _nozzle(k, seed)
    return {"shadow": 0.2, "post": [flame_post(0, 0, 0.15, h, seed, f, "fire", 0.2, 1.1, 0.5), flame_post(0, 0, 0.15, h * 0.5, seed + 2, f + 1, "fire", 0.3, 0.3, 0.1)]}


@prop("wall_flame", "trap", layer="wall_decal", cell=(3, 4), tags=["trap", "fire", "stone"], name_ko="벽 화염 분사구", interact="trap",
    variants={"idle": {}, "firing": {"on": True, "frames": 4}, "scorched": {"scorch": True}}, meta={"states": {"idle": "idle", "active": "firing", "spent": "scorched"}},
    light={"color": "#f0a040", "radius": 4.0, "at": (0, -0.6, 0.9), "flicker": 0.5, "variants": ["firing"]})
def wall_flame(k, on=False, scorch=False, seed=1, f=0):
    z = 1.2
    k.add(rough(lambda p: box(p, v3(0, 0.08, z), (0.3, 0.04, 0.3), 0.03), 0.015, 0.15, seed), "stone_d")
    # 용 머리: 이마 · 주둥이 · 뿔 · 벌린 입
    head = lambda p: smin(ell(p, v3(0, -0.02, z + 0.05), (0.2, 0.16, 0.17)), ell(p, v3(0, -0.2, z - 0.04), (0.13, 0.17, 0.1)), 0.06)
    mouth = lambda p: ell(p, v3(0, -0.34, z - 0.07), (0.08, 0.14, 0.05))
    horns = lambda p: np.minimum(cap(p, v3(-0.13, 0.0, z + 0.16), v3(-0.25, 0.04, z + 0.36), 0.04, 0.008), cap(p, v3(0.13, 0.0, z + 0.16), v3(0.25, 0.04, z + 0.36), 0.04, 0.008))
    k.add(rough(lambda p: np.minimum(sub(head(p), mouth(p)), horns(p)), 0.015, 0.1, seed), "bronze" if not scorch else "rust")
    k.add(lambda p: ell(p, v3(0, -0.27, z - 0.07), (0.06, 0.07, 0.035)), "ember" if on else "void")
    k.add(lambda p: np.minimum(sphere(p, v3(-0.09, -0.15, z + 0.08), 0.03), sphere(p, v3(0.09, -0.15, z + 0.08), 0.03)), "glow_r" if on else "void")
    if not on:
        return {"shadow": 0.0}
    def post(img, vw):
        x, y = vw.px(0, -0.36, z - 0.07)
        img = img[::-1].copy()   # 불길이 입에서 앞(화면 아래)으로
        img = fx.flame(img, x, img.shape[0] - y, 62, seed, f, "fire", 0.26, 1.3, 0.5)
        return img[::-1].copy()
    return {"shadow": 0.0, "post": [post]}


# ── 무너지는 바닥 · 구덩이 ────────────────────────────────────────────────────

def _slabs(c, body, seed, base="#77746a"):
    """돌판 바닥 조각(판 줄눈 + 얼룩)."""
    n = c.noise(18, seed)
    c.paint(body, hexc(base) * (0.82 + n[..., None] * 0.36))
    joints = np.maximum(sstep(np.abs((c.xx + 6) % 32 - 16), 15.0, 16.0), sstep(np.abs((c.yy + 3) % 32 - 16), 15.0, 16.0))
    c.shade(joints * body, -0.5)
    return joints


def _pit(c, hole, depth=26.0, wall="#4a4640"):
    """뚫린 구멍의 가짜 깊이: 북쪽 안벽이 보이고 아래는 어둠."""
    c.paint(hole, "#060505")
    up = np.roll(hole, int(depth * 2), 0)
    up[:int(depth * 2)] = 0
    face = hole * (1 - up)                                         # 구멍 위쪽 가장자리에서 depth만큼 = 안벽
    fall = np.clip(gblur(face, depth * 0.5) * 1.5, 0, 1)
    rows = sstep(np.abs((c.yy % 9) - 4.5), 3.6, 4.5)
    c.paint(face * fall, hexc(wall) * (0.55 + c.noise(7)[..., None] * 0.4) * (1 - rows[..., None] * 0.45), 0.92)
    c.paint(c.rim(hole, 2.0), "#120e0c", 0.9)


@flat("collapse_floor", "trap", cell=(128, 128), tags=["trap", "stone", "ruin"], name_ko="무너지는 바닥", interact="trap",
    variants={"cracked": {"stage": 0}, "sagging": {"stage": 1}, "half": {"stage": 2}, "pit": {"stage": 3}},
    meta={"states": {"idle": "cracked", "active": "half", "spent": "pit"}, "frames_collapse": ["cracked", "sagging", "half", "pit"], "solid_when": ["pit", "half"]})
def collapse_floor(c, stage=0, seed=1):
    rng = np.random.default_rng(7)
    cr = c.cracks([(64 + rng.uniform(-6, 6), 64 + rng.uniform(-6, 6), a, 44) for a in (0.3, 1.5, 2.6, 3.7, 5.0)], 2.2 + stage * 0.5)
    if stage <= 1:
        if stage == 1:   # 내려앉기 시작: 가운데가 꺼져 그늘지고 금이 벌어졌다
            sag = c.blob(64, 64, 40, 36, 0.3, 20, 0.5, 0, 31)
            c.paint(sag, "#0c0a0a", 0.38)
        c.paint(np.roll(cr, 2, 0), "#9a968a", 0.25)
        c.paint(cr, "#100c0b", 0.9)
        c.paint(sstep(c.noise(3, 5, 2), 0.66, 0.74) * gblur(cr, 6.0) * 3, "#8a867a", 0.5)   # 부스러기
        return
    r = 30 if stage == 2 else 50
    cxh, cyh = (74, 58) if stage == 2 else (64, 64)
    hole = c.blob(cxh, cyh, r, r * 0.92, 0.32, 16, 0.04, 0, 55)
    hole = np.clip(hole - cr * 0.0, 0, 1)
    lip = np.clip(gblur(hole, 5.0) * 1.8, 0, 1)
    c.paint(lip * (1 - hole), "#8f8b80", 0.55)                     # 깨진 가장자리의 밝은 단면
    _pit(c, hole, 30.0)
    out = cr * (1 - hole)
    c.paint(out, "#100c0b", 0.9)
    for _ in range(7 if stage == 2 else 5):                         # 가장자리에 걸린 판 조각
        a = rng.uniform(0, 6.28)
        x, y = cxh + np.cos(a) * r * 1.08, cyh + np.sin(a) * r * 1.0
        b = c.blob(x, y, rng.uniform(4, 8), rng.uniform(3, 6), 0.35, 4, 0.2, a)
        c.paint(np.roll(b, 3, 0), "#0c0a0a", 0.55)
        c.paint(b, hexc("#7d7a70") * rng.uniform(0.75, 1.1))
        c.paint(c.rim(b, 1.2), "#16100e", 0.7)


@flat("pit_trap", "trap", cell=(128, 128), tags=["trap", "stone"], name_ko="구덩이 함정", interact="trap",
    variants={"covered": {"state": "covered"}, "open": {}, "bloody": {"state": "bloody"}, "empty": {"state": "empty"}},
    meta={"states": {"idle": "covered", "active": "open", "spent": "bloody"}, "solid_when": ["open", "bloody", "empty"]})
def pit_trap(c, state="open", seed=1):
    if state == "covered":   # 덮개: 둘레와 조금 다른 판 + 가는 틈
        lid = c.rect(18, 18, 110, 110, 0.8)
        _slabs(c, lid, 3, "#736f66")
        c.a = c.a * 0.9
        seam = lid * (1 - c.rect(20.5, 20.5, 107.5, 107.5, 0.8))
        c.paint(seam, "#0e0b0a", 0.85)
        c.paint(c.seg([(64, 19), (64, 109)], 1.4, False), "#0e0b0a", 0.8)
        for x in (58, 70):
            c.paint(c.ring(x, 64, 3.2, 1.6), "#2a2422", 0.9)
        return
    frame = c.rect(10, 10, 118, 118, 0.8)
    hole = c.rect(20, 20, 108, 108, 0.8)
    c.paint(frame, hexc("#5e5b54") * (0.85 + c.noise(12, 3)[..., None] * 0.3))
    c.shade(c.rect(10, 10, 118, 13), 0.3)
    c.paint(c.rim(frame, 1.6), "#16100e", 0.9)
    _pit(c, hole, 34.0)
    if state != "empty":
        rng = np.random.default_rng(3)
        for j in range(3):
            for i in range(5):
                x, y = 30 + i * 17 + rng.uniform(-3, 3) + (j % 2) * 6, 70 + j * 14 + rng.uniform(-2, 2)
                h = 22 + rng.uniform(-3, 5)
                k = 0.5 + j * 0.22
                sp = c.poly([(x - 3.4, y), (x + 3.4, y), (x + rng.uniform(-1, 1), y - h)])
                c.paint(sp, hexc("#8a8e92") * k)
                c.paint(c.poly([(x - 3.4, y), (x - 0.6, y), (x, y - h)]), hexc("#c0c4c8") * k, 0.8)
                if state == "bloody" and (i + j) % 2 == 0:
                    c.paint(sp * sstep(y - h * 0.55 - c.yy, 0, 4), "#5a1412", 0.9)
        if state == "bloody":
            c.paint(c.blob(66, 96, 22, 8, 0.4, 8, 0.3) * hole, "#3a0e0c", 0.85)
            for (x0, y0, x1, y1) in ((50, 92, 78, 88), (60, 100, 72, 84)):   # 바닥의 뼈
                c.paint(c.seg([(x0, y0), (x1, y1)], 3.0, False) * hole, "#a8a08c", 0.9)
            sk = c.blob(84, 94, 6, 5, 0.15, 4, 0.2) * hole
            c.paint(sk, "#b4ac98")


# ── 화살 · 인계철선 · 룬 ──────────────────────────────────────────────────────

@flat("dart_holes", "trap", layer="wall_decal", cell=(112, 36), tags=["trap", "stone"], name_ko="화살 구멍", interact="trap",
    variants={"idle": {}, "fired": {"fired": True}}, meta={"states": {"idle": "dart_holes.idle", "active": "dart_holes.fired", "spent": "darts_spent.a"}})
def dart_holes(c, fired=False, seed=1):
    plate = c.rect(3, 6, 109, 30, 1.0)
    c.paint(plate, hexc("#6a6760") * (0.85 + c.noise(12, seed)[..., None] * 0.3))
    c.shade(c.rect(3, 6, 109, 9), 0.25)
    c.shade(c.rect(3, 27, 109, 30), -0.35)
    c.paint(c.rim(plate, 1.4), "#16100e", 0.9)
    for i in range(5):
        x = 16 + i * 20
        c.paint(sstep(1.0 - c.dist(x, 18, 5.2), 0, 0.2), "#3a3632")
        c.paint(sstep(1.0 - c.dist(x, 18.6, 3.6), 0, 0.25), "#070606")
        if fired and i % 2 == 0:   # 아직 물려 있는 화살 끝
            c.paint(sstep(1.0 - c.dist(x, 18.6, 1.8), 0, 0.4), "#a8acb0")


@flat("darts_spent", "trap", cell=(96, 64), tags=["trap", "battle"], name_ko="쏘고 남은 화살", variants={"a": {}, "b": {"seed": 6}, "bloody": {"seed": 9, "blood": True}})
def darts_spent(c, blood=False, seed=1):
    rng = np.random.default_rng(seed)
    if blood:
        c.paint(c.blob(50, 36, 18, 11, 0.45, 9, 0.3), "#3a0e0c", 0.85)
    for _ in range(6):
        x, y, a = rng.uniform(16, 80), rng.uniform(14, 50), rng.uniform(-0.6, 0.6) + rng.choice([0, np.pi])
        dx, dy = np.cos(a) * 11, np.sin(a) * 11
        c.paint(c.seg([(x - dx + 1.5, y - dy + 2), (x + dx + 1.5, y + dy + 2)], 2.4, False), "#0e0b0a", 0.5)
        c.paint(c.seg([(x - dx, y - dy), (x + dx, y + dy)], 1.8, False), "#4a3a2a")
        c.paint(c.seg([(x + dx * 0.55, y + dy * 0.55), (x + dx * 1.25, y + dy * 1.25)], 3.0), "#a0a4a8")
        c.paint(c.seg([(x - dx * 1.1, y - dy * 1.1), (x - dx * 0.6, y - dy * 0.6)], 4.0, False), "#6a2a26", 0.9)


@prop("tripwire", "trap", cell=(3, 2), tags=["trap"], name_ko="인계철선", interact="trap",
    variants={"set": {}, "tripped": {"state": "tripped"}, "side": {"yaw": 1.5708}}, meta={"states": {"idle": "set", "spent": "tripped"}})
def tripwire(k, state="set", seed=1):
    for s in (-1, 1):
        k.add(rough(lambda p, s=s: cap(p, v3(s * 0.95, 0, 0.0), v3(s * 0.97, 0, 0.26), 0.035, 0.028), 0.01, 0.1, seed), "wood_d")
        k.add(lambda p, s=s: torus(p, v3(s * 0.96, 0, 0.19), 0.036, 0.012), "rope")
    if state == "set":
        k.add(lambda p: cap(p, v3(-0.95, 0, 0.19), v3(0.95, 0, 0.19), 0.011), "steel")
    else:
        k.add(lambda p: np.minimum(cap(p, v3(-0.95, 0, 0.19), v3(-0.5, -0.12, 0.012), 0.011), cap(p, v3(-0.5, -0.12, 0.012), v3(-0.1, 0.05, 0.012), 0.011)), "steel")
        k.add(lambda p: cap(p, v3(0.95, 0, 0.19), v3(0.7, 0.1, 0.012), 0.011), "steel")
    return {"shadow": 0.4}


@flat("rune_trap", "trap", cell=(96, 96), tags=["trap", "magic", "rune"], name_ko="룬 함정", interact="trap",
    variants={"faint": {"state": "faint"}, "armed": {"frames": 4}, "spent": {"state": "spent"}},
    light={"color": GLOWC["red"], "radius": 2.0, "at": (0, 0, 0.05), "flicker": 0.2, "variants": ["armed"]}, meta={"states": {"idle": "faint", "active": "armed", "spent": "spent"}})
def rune_trap(c, state="armed", f=0):
    m = np.maximum(c.ring(48, 48, 36, 2.2), c.ring(48, 48, 30, 1.2) * (c.noise(5, 3) > 0.35))
    m = np.maximum(m, cglyph(c, 48, 48, 34, 77, 3.0))
    for i in range(6):
        a = i * np.pi / 3 + 0.5
        m = np.maximum(m, c.seg([(48 + np.cos(a) * 36, 48 + np.sin(a) * 36), (48 + np.cos(a) * 43, 48 + np.sin(a) * 43)], 2.0, False))
    if state == "spent":   # 터진 뒤: 그을음 + 타 버린 룬
        c.paint(c.blob(48, 48, 44, 40, 0.35, 16, 0.5), "#0e0c0c", 0.6)
        c.paint(sstep(c.noise(4, 9, 2), 0.55, 0.7) * sstep(1.0 - c.dist(48, 48, 44), 0, 0.5), "#060505", 0.5)
        c.paint(m, "#2a2624", 0.8)
        return
    c.paint(np.roll(m, 2, 0), "#8a867a", 0.28)
    c.paint(m, "#1a0c0c", 0.85)
    if state == "faint":
        c.graded = False
        c.add(m, GLOWC["red"], 0.22)
        return
    c.graded = False
    k = PULSE(f)
    c.glow(m, GLOWC["red"], 7.0, 0.85 * k)
    c.add(m, hexc(GLOWC["red"]) * 0.9, 0.95)
    c.add(np.clip(m * 2.4 - 1.4, 0, 1), hexc(GLOWC["red"]) * 0.4 + 0.6, 0.5 + 0.4 * k)


# ── 함정의 흔적 ──────────────────────────────────────────────────────────────

@flat("scorch_mark", "trap", cell=(128, 112), tags=["trap", "fire", "battle"], name_ko="그을린 자국", variants={"a": {}, "b": {"seed": 5}, "streak": {"seed": 8, "streak": True}})
def scorch_mark(c, streak=False, seed=1):
    rx, ry = (56, 20) if streak else (46, 38)
    b = c.blob(64, 56, rx, ry, 0.4, 18, 0.7, 0, seed)
    c.paint(b, "#161212", 0.55)
    c.paint(c.blob(64, 56, rx * 0.6, ry * 0.6, 0.45, 10, 0.6, 0, seed + 1), "#080707", 0.75)
    c.paint(sstep(c.noise(3, seed + 2, 2), 0.6, 0.72) * b, "#3a3632", 0.5)     # 재
    rays = sstep(np.sin(np.arctan2(c.yy - 56, c.xx - 64) * 9 + c.noise(20, seed + 3) * 6), 0.55, 0.9) * sstep(1.25 - c.dist(64, 56, rx, ry), 0, 0.5) * (1 - b)
    c.paint(rays, "#121010", 0.35)


@prop("trap_remains", "trap", cell=(3, 3), tags=["trap", "ruin", "battle"], name_ko="함정의 흔적",
    variants={"rusty_spikes": {"kind": "spikes"}, "snapped_blade": {"kind": "blade"}, "skeleton_spikes": {"kind": "skeleton"}, "sprung_spears": {"kind": "spears"}})
def trap_remains(k, kind="spikes", seed=1):
    rng = np.random.default_rng(seed)
    if kind in ("spikes", "skeleton"):
        _spike_base(k, seed)
        for i, (x, y) in enumerate(_grid()):
            if kind == "spikes" and i in (1, 5, 6):
                k.add(lambda p, x=x, y=y: cap(p, v3(x, y, 0.03), v3(x + 0.02, y, 0.12), 0.045, 0.035), "rust")   # 밑동만
                continue
            k.add(_spike(x, y, 0.6 * rng.uniform(0.8, 1.0), 0.045, 0.03, rng.uniform(-0.05, 0.05)), "rust")
        if kind == "spikes":
            k.add(lambda p: np.minimum(cap(p, v3(0.5, -0.45, 0.03), v3(0.85, -0.35, 0.03), 0.04, 0.005), cap(p, v3(-0.75, -0.3, 0.03), v3(-0.5, -0.5, 0.03), 0.04, 0.005)), "rust")
        else:   # 가시에 꿰인 채 삭은 유골
            k.add(lambda p: smin(sphere(p, v3(-0.34, -0.05, 0.42), 0.11), box(p, v3(-0.34, -0.12, 0.35), (0.06, 0.05, 0.04), 0.02), 0.03), "bone")
            k.add(lambda p: np.minimum(sphere(p, v3(-0.38, -0.15, 0.44), 0.028), sphere(p, v3(-0.3, -0.15, 0.44), 0.028)), "void")
            k.add(lambda p: np.minimum.reduce([torus(rot_y(p, 1.4, (x, 0, 0.36)), v3(x, 0, 0.36), 0.12, 0.018) for x in (-0.12, -0.02, 0.08)]), "bone")
            k.add(lambda p: np.minimum.reduce([cap(p, v3(-0.2, 0, 0.38), v3(0.3, 0.02, 0.3), 0.022), cap(p, v3(0.2, -0.1, 0.3), v3(0.5, -0.3, 0.06), 0.026), cap(p, v3(0.2, 0.1, 0.3), v3(0.55, 0.2, 0.08), 0.026), cap(p, v3(-0.1, -0.2, 0.34), v3(-0.3, -0.42, 0.05), 0.022)]), "bone_d")
            k.add(lambda p: box(p, v3(0.05, 0.0, 0.33), (0.2, 0.12, 0.012)) + (sdf.noise(p, 0.07, seed) - 0.4) * 0.08, "cloth_k")
    elif kind == "blade":
        k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.02), (0.95, 0.16, 0.02), 0.01), box(p, v3(0, 0, 0.03), (0.86, 0.035, 0.05))), 0.008, 0.2, seed), "rust")
        c = v3(0.1, 0, 0.1)
        k.add(lambda p: np.maximum(np.maximum(gear_x(p, c, 0.5, 0.014, 14, 0.3, 0.0), 0.02 - p[:, 2]), -(p[:, 0] - 0.05 + (p[:, 2] - 0.3) * 0.6 + sdf.noise(p, 0.1, seed) * 0.1)), "rust")
        k.add(lambda p: np.maximum(gear_z(rot_y(p, 0.12, (-0.6, -0.45, 0.03)), v3(-0.6, -0.45, 0.03), 0.5, 0.014, 14, 0.1, 0.0), p[:, 0] + 0.5 + p[:, 1] * 0.5), "rust")
    else:   # spears: 부러진 창대가 바닥에
        for i in range(3):
            x, y, a = -0.5 + i * 0.5, -0.1 + rng.uniform(-0.2, 0.2), rng.uniform(-0.5, 0.5)
            d = v3(np.cos(a), np.sin(a), 0) * 0.4
            c = v3(x, y, 0.03)
            k.add(lambda p, c=c, d=d: cap(p, c - d, c + d * 0.5, 0.026), "wood_d")
            if i != 1:
                k.add(lambda p, c=c, d=d: cap(p, c + d * 0.5, c + d * 1.15, 0.05, 0.004), "rust")
        k.add(lambda p: pool(p, v3(0.1, -0.2, 0.004), 0.4, 0.2, 0.004) + (sdf.noise(p, 0.1, seed) - 0.42) * 0.14, "blood")
    return {}
