"""특수 오브젝트: 마법진 · 봉인 장치 · 석판 · 룬석 · 고대 기계 · 레버 · 회전 장치 · 균열 · 포털 · 수정 · 마력 잔류물 · 압력판 · 잠금장치.
빛나는 것은 색 정리 뒤에 얹는다(post). 켜진 변형은 frames 4(f = 맥동)."""
import numpy as np

import fx
import sdf
from a_light import GLOWC, cglyph, chain, gear_x, gear_z, octa, rune_post, shard
from kit import (F, box, cap, chip, cone, cut_above, cyl, disc_x, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from paint2d import gblur, hexc, sstep, vnoise

PULSE = lambda f: 0.75 + 0.25 * np.sin(f * 1.5708)


# ── 마법진 ───────────────────────────────────────────────────────────────────

def _circle_mask(c, design):
    cx = cy = 96.0
    m = np.maximum(c.ring(cx, cy, 88, 2.6), c.ring(cx, cy, 72, 1.8))
    for i in range(16):   # 두 고리 사이 글자
        a = i * np.pi / 8 + 0.2
        m = np.maximum(m, cglyph(c, cx + np.cos(a) * 80, cy + np.sin(a) * 80, 10, design * 17 + i, 1.5, a + np.pi / 2))
    n = (5, 3, 4)[design]
    pts = [(cx + np.cos(-np.pi / 2 + i * 2 * np.pi / n) * 72, cy + np.sin(-np.pi / 2 + i * 2 * np.pi / n) * 72) for i in range(n)]
    if design == 0:      # 오각 별
        for i in range(5):
            m = np.maximum(m, c.seg([pts[i], pts[(i + 2) % 5]], 2.0, False))
        m = np.maximum(m, c.ring(cx, cy, 27, 1.6))
    elif design == 1:    # 맞물린 두 세모 + 눈
        for k in (0, 1):
            tri = [(cx + np.cos(-np.pi / 2 + k * np.pi + i * 2 * np.pi / 3) * 72, cy + np.sin(-np.pi / 2 + k * np.pi + i * 2 * np.pi / 3) * 72) for i in range(3)]
            for i in range(3):
                m = np.maximum(m, c.seg([tri[i], tri[(i + 1) % 3]], 2.0, False))
        m = np.maximum(m, np.maximum(c.ring(cx, cy, 34, 1.8), c.ring(cx, cy, 9, 3.0)))
    else:                # 네모 겹 + 십자
        for r, rot in ((72, 0.0), (72, np.pi / 4)):
            sq = [(cx + np.cos(rot + i * np.pi / 2) * r, cy + np.sin(rot + i * np.pi / 2) * r) for i in range(4)]
            for i in range(4):
                m = np.maximum(m, c.seg([sq[i], sq[(i + 1) % 4]], 2.0, False))
        m = np.maximum(m, np.maximum(c.ring(cx, cy, 44, 1.6), np.maximum(c.seg([(cx - 30, cy), (cx + 30, cy)], 2.0, False), c.seg([(cx, cy - 30), (cx, cy + 30)], 2.0, False))))
        for i in range(4):
            m = np.maximum(m, cglyph(c, cx + np.cos(i * np.pi / 2 + np.pi / 4) * 22, cy + np.sin(i * np.pi / 2 + np.pi / 4) * 22, 12, 60 + i, 1.5))
    return m


_MC = {}
for _d, _n in enumerate("abc"):
    _MC["%s_chalk" % _n] = {"design": _d, "state": "chalk"}
    _MC["%s_blood" % _n] = {"design": _d, "state": "blood"}
    _MC["%s_blue" % _n] = {"design": _d, "state": "blue", "frames": 4}
    _MC["%s_red" % _n] = {"design": _d, "state": "red", "frames": 4}


@flat("magic_circle", "special", cell=(192, 192), tags=["magic", "ritual"], name_ko="마법진", variants=_MC, interact="circle",
    light={"color": GLOWC["blue"], "radius": 3.5, "at": (0, 0, 0.1), "flicker": 0.1, "variants": [k for k in _MC if k.endswith(("blue", "red"))], "colors": {k: GLOWC["red"] for k in _MC if k.endswith("red")}},
    meta={"states": {"idle": "a_chalk", "active": "a_blue"}})
def magic_circle(c, design=0, state="chalk", f=0):
    m = _circle_mask(c, design)
    if state == "chalk":      # 분필: 군데군데 끊기고 번졌다
        c.paint(gblur(m, 2.0) * 0.5, "#a8a090", 0.35)
        c.paint(m * (0.35 + 0.65 * (c.noise(5, 11) > 0.33)) * (0.6 + 0.4 * c.noise(1.5, 12, 1)), "#c4bca8", 0.85)
    elif state == "blood":    # 피로 그렸다: 굵고 뚝뚝 흘렀다
        fat = np.clip(gblur(m, 1.6) * 2.4, 0, 1)
        c.paint(fat, "#3a0e0c", 0.9)
        c.paint(m * (c.noise(8, 21) > 0.4), "#6a1a16", 0.8)
        drops = sstep(c.noise(7, 22, 2), 0.74, 0.8) * sstep(gblur(m, 9.0), 0.02, 0.1)
        c.paint(drops, "#4a1210", 0.85)
    else:
        col = GLOWC[state]
        c.graded = False
        k = PULSE(f)
        c.paint(m, hexc(col) * 0.35, 0.8)
        sweep = 0.6 + 0.4 * np.cos(np.arctan2(c.yy - 96, c.xx - 96) * 2 - f * 1.5708)   # 빛이 고리를 따라 돈다
        c.glow(m, col, 7.0, 0.8 * k)
        c.add(m * (0.55 + 0.45 * sweep), hexc(col) * 0.9, 0.95)
        c.add(np.clip(m * 2.4 - 1.4, 0, 1) * sweep, hexc(col) * 0.35 + 0.65, 0.8 * k)
        c.add(sstep(1.0 - c.dist(96, 96, 70), 0, 1.0), col, 0.10 * k)


# ── 봉인 · 석판 · 룬석 ────────────────────────────────────────────────────────

@prop("seal_device", "special", cell=(3, 4), collide=(0.9, 0.7), tags=["magic", "seal", "stone"], name_ko="봉인 장치", interact="seal",
    variants={"sealed": {"frames": 4}, "weakened": {"state": "weakened", "frames": 4}, "broken": {"state": "broken"}},
    light={"color": GLOWC["violet"], "radius": 3.5, "at": (0, 0, 1.2), "flicker": 0.2, "variants": ["sealed", "weakened"]},
    meta={"states": {"idle": "sealed", "active": "weakened", "spent": "broken"}})
def seal_device(k, state="sealed", seed=1, f=0):
    k.add(rough(lambda p: np.minimum(cyl(p, v3(0, 0, 0), 0.6, 0.12, 0.03), cyl(p, v3(0, 0, 0.1), 0.46, 0.12, 0.03)), 0.02, 0.2, seed), "stone_d")
    mono = lambda p: np.maximum(box(p, v3(0, 0, 1.15), (0.32, 0.2, 0.95), 0.03), np.abs(p[:, 0]) - 0.33 + p[:, 2] * 0.055)
    if state == "broken":
        k.add(cut_above(rough(mono, 0.03, 0.2, seed), 0.95, 0.4, 0.25, seed, 0.7), "stone")
        k.add(rough(lambda p: np.maximum(mono(rot_y(p - v3(0.95, -0.25, -0.02), 1.45, (0, 0, 0.2))), 1.0 - rot_y(p - v3(0.95, -0.25, -0.02), 1.45, (0, 0, 0.2))[:, 2]), 0.03, 0.2, seed + 1), "stone")
        k.add(chain(v3(-0.3, -0.5, 0.03), v3(-0.9, -0.3, 0.03), 0.03), "rust")
        k.add(chain(v3(-0.9, -0.3, 0.03), v3(-1.0, 0.1, 0.03), 0.03), "rust")
        k.add(chain(v3(0.2, -0.55, 0.03), v3(0.6, -0.62, 0.03), 0.03), "rust")
        k.rubble([(-0.5, -0.4), (0.4, -0.45), (0.1, -0.6), (-0.75, 0.0)], "stone", 0.05, 0.1)
        return {"post": [rune_post(0, -0.2, 0.7, 20, 5)]}
    body = rough(mono, 0.025, 0.2, seed)
    k.add(chip(body, 0.5, 0.25, seed, 0.08) if state == "weakened" else body, "stone")
    for z, tilt in ((0.75, 0.22), (1.5, -0.22)):   # 감아 맨 사슬 띠
        band = lambda p, z=z, tilt=tilt: sub(box(rot_y(p, tilt, (0, 0, z)), v3(0, 0, z), (0.36, 0.26, 0.04), 0.03), box(rot_y(p, tilt, (0, 0, z)), v3(0, 0, z), (0.29, 0.19, 0.2)))
        k.add(lambda p, band=band: band(p) + np.sin(p[:, 0] * 70.0) * np.sin(p[:, 1] * 70.0) * 0.008, "iron")
    for s in (-1, 1):
        k.add(chain(v3(s * 0.33, -0.1, 0.8), v3(s * 0.56, -0.2, 0.1), 0.026), "iron")
    k.add(lambda p: np.minimum(box(p, v3(0, -0.24, 1.13), (0.1, 0.05, 0.12), 0.02), ring_x(p, v3(0, -0.25, 1.3), 0.07, 0.022)), "iron")   # 자물쇠
    k_ = PULSE(f) * (1.0 if state == "sealed" else (0.25 if f % 2 else 0.6))
    c = GLOWC["violet"]
    return {"post": [rune_post(0, -0.2, 1.75, 16, 5, "violet", f, 12), lambda img, vw: fx.halo(img, *vw.px(0, -0.2, 1.2), 62, c, 0.42 * k_)]}


@prop("stone_tablet", "special", cell=(2, 3), collide=(0.8, 0.4), tags=["stone", "ruin", "lore"], name_ko="석판", interact="read",
    variants={"intact": {}, "mossy": {"state": "mossy"}, "broken": {"state": "broken"}, "glowing": {"state": "glowing", "frames": 4}},
    light={"color": GLOWC["blue"], "radius": 2.5, "at": (0, -0.2, 0.9), "flicker": 0.1, "variants": ["glowing"]})
def stone_tablet(k, state="intact", seed=1, f=0):
    k.add(rough(lambda p: box(p, v3(0, 0, 0.09), (0.5, 0.24, 0.09), 0.02), 0.02, 0.2, seed), "stone_d")
    slab = lambda p: np.minimum(box(p, v3(0, 0, 0.72), (0.38, 0.1, 0.56), 0.02), disc_x(p, v3(0, 0, 1.28), 0.38, 0.1))
    rows = [(z, [(-0.24 + i * 0.12, seed * 5 + i + int(z * 40)) for i in range(5)]) for z in (1.3, 1.08, 0.86, 0.64, 0.42)]
    if state == "broken":
        k.add(rough(lambda p: np.maximum(slab(p), p[:, 2] - 0.85 - p[:, 0] * 0.6 - sdf.noise(p, 0.1, seed) * 0.12), 0.025, 0.2, seed), "stone")
        k.add(rough(lambda p: box(rot_z(p, 0.4, (0.62, -0.34, 0)), v3(0.62, -0.34, 0.07), (0.3, 0.22, 0.07), 0.03), 0.04, 0.15, seed + 2), "stone")
        k.rubble([(-0.5, -0.32), (0.2, -0.42), (0.95, -0.2)], "stone", 0.04, 0.08)
        rows = [r for r in rows if r[0] < 0.7]
    else:
        k.add(rough(slab, 0.02, 0.2, seed), "stone_m" if state == "mossy" else "stone")
    col = "blue" if state == "glowing" else None
    post = [rune_post(x, -0.105, z, 8, g, col, f, 6) for z, row in rows for x, g in row]
    if col:
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, -0.1, 0.9), 50, GLOWC["blue"], 0.3 * PULSE(f)))
    return {"post": post}


@flat("wall_tablet", "special", layer="wall_decal", cell=(96, 72), tags=["stone", "ruin", "lore"], name_ko="벽 석판", interact="read",
    variants={"a": {"seed": 1}, "b": {"seed": 2}, "c": {"seed": 3, "cracked": True}})
def wall_tablet(c, seed=1, cracked=False):
    body = c.rect(4, 4, 92, 68, 1.0)
    n = c.noise(14, seed)
    c.paint(body, hexc("#85827a") * (0.85 + n[..., None] * 0.3))
    inner = c.rect(9, 9, 87, 63, 1.0)
    c.shade(body - inner, -0.22)
    c.shade(c.rect(4, 4, 92, 7), 0.25)
    c.shade(c.rect(4, 64, 92, 68), -0.35)
    g = np.zeros((c.H, c.W), F)
    for r in range(4):
        for i in range(7):
            if (seed * 3 + r * 7 + i) % 9 == 0:
                continue
            g = np.maximum(g, cglyph(c, 17 + i * 10.4, 18 + r * 12.5, 8.5, seed * 31 + r * 7 + i, 1.4))
    c.paint(np.roll(g, 2, 0) * inner, "#b0aa9a", 0.3)
    c.paint(g * inner, "#1c1614", 0.8)
    if cracked:
        cr = c.cracks([(60, 4, 1.9, 70)], 2.2) * body
        c.paint(cr, "#120e0c", 0.9)
    c.paint(c.rim(body, 1.6), "#16100e", 0.9)


@prop("rune_stone", "special", cell=(2, 2), collide=(0.5, 0.4), tags=["magic", "rune", "stone"], name_ko="룬석",
    variants={"dormant": {}, "blue": {"col": "blue", "frames": 4}, "red": {"col": "red", "frames": 4}, "dormant_b": {"shape": 1}, "blue_b": {"shape": 1, "col": "blue", "frames": 4}, "dormant_c": {"shape": 2}, "violet_c": {"shape": 2, "col": "violet", "frames": 4}},
    light={"color": GLOWC["blue"], "radius": 2.2, "at": (0, -0.15, 0.5), "flicker": 0.1, "variants": ["blue", "red", "blue_b", "violet_c"], "colors": {"red": GLOWC["red"], "violet_c": GLOWC["violet"]}})
def rune_stone(k, shape=0, col=None, seed=1, f=0):
    w, h, lean = ((0.3, 0.52, 0.08), (0.38, 0.38, -0.12), (0.24, 0.66, 0.03))[shape]
    k.add(rough(lambda p: ell(rot_y(p, lean), v3(0, 0, h * 0.8), (w, 0.19, h)), 0.07, 0.22, seed + shape * 9), "stone" if shape != 1 else "stone_d")
    k.rubble([(w + 0.1, -0.12), (-w - 0.08, 0.05)], "stone", 0.03, 0.06)
    return {"post": [rune_post(lean * h, -0.19, h * 0.85, h * 40, 20 + shape * 3, col, f, 18)]}


# ── 고대 기계 · 장치 ──────────────────────────────────────────────────────────

@prop("ancient_machine", "special", cell=(4, 4), collide=(1.9, 1.0), tags=["machine", "brass", "ruin"], name_ko="고대 기계 장치", interact="machine",
    variants={"dormant": {}, "active": {"state": "active", "frames": 4}, "wrecked": {"state": "wrecked"}},
    light={"color": GLOWC["blue"], "radius": 3.5, "at": (0.2, -0.2, 1.1), "flicker": 0.15, "variants": ["active"]},
    meta={"states": {"idle": "dormant", "active": "active", "spent": "wrecked"}})
def ancient_machine(k, state="dormant", seed=1, f=0):
    ph = f * 0.16 if state == "active" else 0.0
    wreck = state == "wrecked"
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.16), (0.95, 0.5, 0.16), 0.03), box(p, v3(0.2, 0.05, 0.5), (0.62, 0.38, 0.2), 0.03)), 0.025, 0.25, seed), "masonry")
    dome = lambda p: np.maximum(sphere(p, v3(0.25, 0.0, 0.7), 0.42), 0.7 - p[:, 2])
    dm = k.mat("dome", M.metal("#7a6a40", "#4a6a5a", 4, 0.45))
    if wreck:
        k.add(chip(rough(dome, 0.03, 0.2, seed), 0.56, 0.3, seed, 0.25), dm)
        k.add(lambda p: sphere(p, v3(0.25, 0.0, 0.72), 0.3), "void")
    else:
        k.add(lambda p: np.maximum(dome(p), -(sphere(p, v3(0.25, -0.42, 0.93), 0.16))), dm)
        k.add(lambda p: sphere(p, v3(0.25, -0.24, 0.9), 0.17), "glow_b" if state == "active" else "glass")
        k.add(lambda p: ring_x(p, v3(0.25, -0.385, 0.93), 0.155, 0.028), "brass")
    for i in range(5):   # 돔 둘레 대갈못 띠
        a = -2.6 + i * 0.52
        k.add(lambda p, a=a: sphere(p, v3(0.25 + np.cos(a) * 0.43, np.sin(a) * 0.43, 0.72), 0.035), "brass")
    k.add(lambda p: torus(p, v3(0.25, 0, 0.71), 0.43, 0.03), "brass")
    # 톱니: 큰 것 · 작은 것이 맞물려 돈다
    if wreck:
        k.add(lambda p: gear_z(rot_y(p, 0.25, (-0.9, -0.62, 0.05)), v3(-0.9, -0.62, 0.05), 0.33, 0.035, 12, 0.3), "rust")
        k.add(lambda p: gear_x(p, v3(-0.26, -0.53, 0.52), 0.17, 0.035, 8, 0.0), "rust")
    else:
        k.add(lambda p: gear_x(p, v3(-0.62, -0.53, 0.62), 0.33, 0.035, 12, ph * 12), "brass")
        k.add(lambda p: gear_x(p, v3(-0.2, -0.53, 0.42), 0.17, 0.035, 8, -ph * 8 * 1.5 + 0.4), "bronze")
    k.add(lambda p: np.minimum(hcyl(p, v3(-0.62, -0.5, 0.62), v3(-0.62, -0.3, 0.62), 0.05), hcyl(p, v3(-0.2, -0.5, 0.42), v3(-0.2, -0.3, 0.42), 0.035)), "iron")
    k.add(rough(lambda p: box(p, v3(-0.55, 0.05, 0.62), (0.3, 0.3, 0.32), 0.03), 0.02, 0.2, seed + 1), "masonry")
    # 관: 돔에서 올라가 꺾여 내려온다
    pipe = lambda p: np.minimum.reduce([cap(p, v3(0.72, 0.0, 0.6), v3(0.72, 0.0, 1.35), 0.055), cap(p, v3(0.72, 0.0, 1.35), v3(-0.5, 0.05, 1.35), 0.055), cap(p, v3(-0.5, 0.05, 1.35), v3(-0.5, 0.05, 0.9), 0.055)])
    joints = lambda p: np.minimum.reduce([torus(p, v3(0.72, 0, 0.95), 0.06, 0.022), torus(p, v3(-0.5, 0.05, 1.08), 0.06, 0.022), sphere(p, v3(0.72, 0, 1.35), 0.075), sphere(p, v3(-0.5, 0.05, 1.35), 0.075)])
    if wreck:
        k.add(lambda p: np.maximum(pipe(p), -(box(p, v3(0.1, 0.02, 1.35), (0.3, 0.2, 0.2)))), "rust")
        k.add(lambda p: hcyl(p, v3(0.4, -0.75, 0.055), v3(0.95, -0.6, 0.055), 0.055), "rust")
        k.rubble([(0.1, -0.7), (-0.4, -0.75), (1.1, -0.4), (-1.2, -0.3)], "stone", 0.04, 0.09)
    else:
        k.add(pipe, "bronze")
        k.add(joints, "brass")
        k.add(lambda p: np.minimum(cyl(p, v3(0.9, -0.3, 0.32), 0.05, 0.36), disc_x(p, v3(0.9, -0.36, 0.78), 0.1, 0.03)), "brass")   # 계기
    if state == "active":
        c = GLOWC["blue"]
        return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0.25, -0.3, 0.9), 44, c, 0.5 * PULSE(f)), [vw.px(0.2, -0.4, 0.97)]),
            lambda img, vw: fx.puff(img, *vw.px(-0.5, 0.05, 0.95), 7, "#b8b8b0", 0.35, seed, f, 14, 4)]}
    return {}


@prop("gear_pile", "special", cell=(3, 2), tags=["machine", "brass"], name_ko="톱니바퀴 더미", variants={"a": {}, "b": {"seed": 5, "alt": True}})
def gear_pile(k, seed=1, alt=False):
    k.add(lambda p: gear_z(p, v3(-0.25, 0.05, 0.03), 0.34, 0.03, 12, 0.2), "rust" if alt else "brass")
    k.add(lambda p: gear_z(rot_y(p, 0.2, (0.3, -0.12, 0.08)), v3(0.3, -0.12, 0.08), 0.22, 0.03, 9, 0.9), "bronze")
    k.add(lambda p: gear_x(rot_z(p, 0.5, (0.55, 0.12, 0)), v3(0.55, 0.12, 0.2), 0.2, 0.03, 8, 0.3), "brass" if alt else "rust")
    k.add(lambda p: np.minimum(hcyl(p, v3(-0.7, -0.3, 0.03), v3(-0.3, -0.38, 0.03), 0.03), torus(p, v3(0.05, -0.36, 0.02), 0.07, 0.02)), "iron")
    return {}


@prop("lever", "special", cell=(2, 2), collide=(0.5, 0.4), tags=["machine", "iron"], name_ko="레버", interact="lever",
    variants={"left": {}, "right": {"state": "right"}, "broken": {"state": "broken"}}, meta={"states": {"idle": "left", "active": "right", "spent": "broken"}})
def lever(k, state="left", seed=1):
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.11), (0.3, 0.2, 0.11), 0.03), box(p, v3(0, 0, 0.2), (0.2, 0.035, 0.1))), 0.02, 0.15, seed), "stone_d")
    k.add(lambda p: hcyl(p, v3(0, -0.08, 0.2), v3(0, 0.08, 0.2), 0.05), "iron")
    a = {"left": -0.6, "right": 0.6, "broken": 0.3}[state]
    ln = 0.2 if state == "broken" else 0.62
    tip = v3(np.sin(a) * ln, 0, 0.2 + np.cos(a) * ln)
    k.add(lambda p: cap(p, v3(0, 0, 0.2), tip, 0.028, 0.024), "iron")
    if state == "broken":
        k.add(lambda p: np.minimum(cap(p, v3(0.3, -0.3, 0.03), v3(0.62, -0.22, 0.03), 0.025), sphere(p, v3(0.66, -0.21, 0.05), 0.055)), "iron")
    else:
        k.add(lambda p: ell(p, tip + v3(np.sin(a) * 0.05, 0, np.cos(a) * 0.05), (0.06, 0.06, 0.075)), "wood_d")
    return {}


@prop("wall_lever", "special", layer="wall_decal", cell=(2, 3), tags=["machine", "iron"], name_ko="벽 레버", interact="lever",
    variants={"up": {}, "down": {"state": "down"}}, meta={"states": {"idle": "up", "active": "down"}})
def wall_lever(k, state="up", seed=1):
    k.add(rough(lambda p: sub(box(p, v3(0, 0.06, 1.3), (0.2, 0.05, 0.36), 0.025), box(p, v3(0, 0.0, 1.3), (0.045, 0.05, 0.27))), 0.012, 0.1, seed), "stone_d")
    for z in (1.02, 1.58):
        for s in (-1, 1):
            k.add(lambda p, z=z, s=s: sphere(p, v3(s * 0.14, 0.0, z), 0.03), "brass")
    dz = 0.3 if state == "up" else -0.3
    tip = v3(0, -0.32, 1.3 + dz)
    k.add(lambda p: cap(p, v3(0, 0.04, 1.3), tip, 0.034), "iron")
    k.add(lambda p: sphere(p, tip, 0.075), "wood")
    return {"shadow": 0.0}


@prop("winch", "special", cell=(3, 3), collide=(0.8, 0.7), tags=["machine", "wood"], name_ko="감는 틀", interact="winch",
    variants={"idle": {}, "turned": {"turn": 0.785}, "turned2": {"turn": 0.39}}, meta={"frames_turn": ["idle", "turned2", "turned"]})
def winch(k, turn=0.0, seed=1):
    k.add(rough(lambda p: cyl(p, v3(0, 0, 0), 0.42, 0.1, 0.02), 0.02, 0.2, seed), "stone_d")
    k.add(lambda p: cyl(p, v3(0, 0, 0.1), 0.17, 0.72, 0.02) + np.cos(np.arctan2(p[:, 1], p[:, 0]) * 8) * 0.008, "wood")
    k.add(lambda p: np.minimum(torus(p, v3(0, 0, 0.2), 0.175, 0.02), torus(p, v3(0, 0, 0.78), 0.175, 0.02)), "iron")
    for z in (0.34, 0.42, 0.5):   # 감긴 사슬
        k.add(lambda p, z=z: torus(p, v3(0, 0, z), 0.19, 0.03) + np.sin(np.arctan2(p[:, 1], p[:, 0]) * 14) * 0.01, "iron")
    k.add(chain(v3(0.19, -0.05, 0.36), v3(0.95, -0.45, 0.03), 0.026), "iron")
    for i in range(4):
        a = turn + i * np.pi / 2
        k.add(lambda p, a=a: cap(p, v3(0, 0, 0.68), v3(np.cos(a) * 0.62, np.sin(a) * 0.62, 0.68), 0.032, 0.026), "wood_l")
    k.add(lambda p: cyl(p, v3(0, 0, 0.8), 0.11, 0.06, 0.02), "iron")
    return {}


@prop("valve_wheel", "special", layer="wall_decal", cell=(3, 3), tags=["machine", "iron", "sewer"], name_ko="밸브 바퀴", interact="valve",
    variants={"idle": {}, "turned": {"turn": 0.5}, "rusted": {"rust": True}})
def valve_wheel(k, turn=0.0, rust=False, seed=1):
    m = "rust" if rust else "iron"
    k.add(lambda p: np.minimum(hcyl(p, v3(-1.0, 0.0, 1.25), v3(1.0, 0.0, 1.25), 0.085), np.minimum(hcyl(p, v3(-0.42, 0, 1.25), v3(-0.34, 0, 1.25), 0.115), hcyl(p, v3(0.34, 0, 1.25), v3(0.42, 0, 1.25), 0.115))), "rust" if rust else "bronze")
    k.add(lambda p: np.minimum(box(p, v3(0, -0.02, 1.25), (0.13, 0.11, 0.13), 0.03), hcyl(p, v3(0, -0.12, 1.25), v3(0, -0.26, 1.25), 0.035)), m)
    c = v3(0, -0.24, 1.25)
    k.add(lambda p: ring_x(p, c, 0.2, 0.026), m)
    for i in range(3):
        a = turn + i * np.pi / 3
        k.add(lambda p, a=a: cap(p, c - v3(np.cos(a) * 0.2, 0, np.sin(a) * 0.2), c + v3(np.cos(a) * 0.2, 0, np.sin(a) * 0.2), 0.018), m)
    return {"shadow": 0.0}


# ── 균열 · 포털 ──────────────────────────────────────────────────────────────

@flat("rift", "special", cell=(176, 120), tags=["magic", "rift"], name_ko="차원 균열", interact="rift",
    variants={"active": {"frames": 4}, "dormant": {"on": False}, "active_b": {"frames": 4, "seed": 9}},
    light={"color": GLOWC["violet"], "radius": 3.0, "at": (0, 0, 0.1), "flicker": 0.3, "variants": ["active", "active_b"]}, meta={"states": {"idle": "dormant", "active": "active"}})
def rift(c, on=True, f=0, seed=1):
    rng = np.random.default_rng(seed)
    # 벌어진 틈: 가운데가 넓고 양 끝이 가는 들쭉날쭉한 띠
    n = 13
    xs = np.linspace(14, 162, n)
    mid = 60 + np.cumsum(rng.uniform(-9, 9, n)) * 0.6
    wid = np.sin(np.linspace(0, np.pi, n)) ** 0.8 * rng.uniform(7, 15, n)
    gap = c.poly([(xs[i], mid[i] - wid[i]) for i in range(n)] + [(xs[i], mid[i] + wid[i] * 0.8) for i in range(n - 1, -1, -1)])
    cr = c.cracks([(xs[i], mid[i], a, 26) for i, a in ((2, 4.2), (5, 1.3), (8, 4.6), (10, 1.8), (0, 3.2), (12, 0.1))], 2.4)
    edge = np.clip(gblur(gap, 3.0) * 1.6 - gap, 0, 1)
    c.paint(np.clip(edge * 1.2, 0, 1), "#8a867a", 0.35)
    c.paint(np.maximum(gap, cr), "#0a0810", 0.95)
    if on:
        c.graded = False
        col, k = GLOWC["violet"], PULSE(f)
        swirl = c.noise(9, seed * 5 + f, 2)
        c.glow(np.maximum(gap, cr), col, 9.0, 0.85 * k)
        c.add(gap * sstep(swirl, 0.35, 0.75), hexc(col) * 0.8, 0.8)
        c.add(c.rim(gap, 1.6), hexc(col) * 0.5 + 0.5, 0.9 * k)
        c.add(cr, col, 0.7)
        c.add(gap * sstep(swirl, 0.68, 0.8), "#f0e4ff", 0.8)


def _swirl(x, y, z, r, col, f, seed):
    """post: 세운 고리 안의 소용돌이치는 막."""
    def fn(img, vw):
        cx, cy = vw.px(x, y, z)
        R = r * vw.u
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        d = np.hypot(xx - cx, yy - cy) / R
        ang = np.arctan2(yy - cy, xx - cx)
        arms = 0.5 + 0.5 * np.sin(ang * 3.0 + d * 7.0 - f * 1.5708)
        n = vnoise(hh, ww, 5.0, seed * 3 + f)
        inside = sstep(1.0 - d, 0.0, 0.08)
        c = hexc(GLOWC[col])
        img = fx._over(img, inside, c * 0.22)
        img = fx._over(img, inside * arms * (0.5 + n * 0.5) * (0.35 + d * 0.65), c * 0.9)
        img = fx._over(img, inside * sstep(arms * n, 0.5, 0.75) * 0.9, c * 0.4 + 0.6)
        img = fx._over(img, sstep(0.22 - d, 0, 0.2) * 0.85, np.array([0.04, 0.02, 0.07], F))
        return fx.halo(img, cx, cy, R * 1.9, GLOWC[col], 0.4 * PULSE(f))
    return fn


@prop("portal", "special", cell=(4, 4), collide=[(-1.05, -0.3, 0.5, 0.6), (0.55, -0.3, 0.5, 0.6)], tags=["magic", "rift", "stone"], name_ko="포털", interact="portal",
    variants={"dormant": {}, "violet": {"col": "violet", "frames": 4}, "blue": {"col": "blue", "frames": 4}, "shattered": {"state": "shattered"}},
    light={"color": GLOWC["violet"], "radius": 5.0, "at": (0, 0, 1.1), "flicker": 0.2, "variants": ["violet", "blue"], "colors": {"blue": GLOWC["blue"]}},
    meta={"states": {"idle": "dormant", "active": "violet", "spent": "shattered"}})
def portal(k, state="intact", col=None, seed=1, f=0):
    R, zc = 0.86, 1.16
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.08), (1.15, 0.42, 0.08), 0.03), box(p, v3(0, 0.02, 0.22), (0.9, 0.3, 0.08), 0.03)), 0.025, 0.2, seed), "stone_d")
    ring = lambda p: np.maximum(np.abs(np.hypot(p[:, 0], p[:, 2] - zc) - R) - 0.17, np.abs(p[:, 1]) - 0.16) - 0.02
    vm = k.mat("vous", M.masonry("#807c74", 0.3, 0.3, None, 5))
    if state == "shattered":
        gone = lambda p: (p[:, 2] - 1.25) * 0.8 + (p[:, 0] + 0.2) * 0.55 + (sdf.fbm(p, 0.3, seed, 2) - 0.5) * 0.6
        k.add(rough(lambda p: np.maximum(ring(p), gone(p)), 0.03, 0.2, seed), vm)
        for i, (x, y, a) in enumerate(((0.75, -0.6, 0.4), (1.3, -0.35, 1.2), (0.2, -0.7, -0.3), (-0.5, -0.62, 0.8))):
            k.add(rough(lambda p, x=x, y=y, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.12), (0.22, 0.15, 0.12), 0.03), 0.04, 0.15, seed + i), "stone")
        k.rubble(k.scatter(7, 1.0, 0.25, 0.4, -0.6), "stone", 0.04, 0.09)
        return {}
    k.add(rough(ring, 0.02, 0.2, seed), vm)
    post = [rune_post(np.cos(a) * R, -0.19, zc + np.sin(a) * R, 11, 30 + i, col, f, 7) for i, a in enumerate(np.linspace(-0.3, np.pi + 0.3, 7))]
    if col:
        post.insert(0, _swirl(0, 0.0, zc, R - 0.15, col, f, seed))
    return {"post": post}


# ── 수정 · 마력 ──────────────────────────────────────────────────────────────

_CR = {}
for _c in ("blue", "red", "violet"):
    _CR["%s_small" % _c] = {"col": _c, "big": False}
    _CR["%s_large" % _c] = {"col": _c, "big": True}
_CR["dead"] = {"col": None, "big": True}
_CR["blue_small_b"] = {"col": "blue", "big": False, "seed": 31}


@prop("crystal", "special", cell=(3, 3), collide=(0.7, 0.5), tags=["magic", "crystal", "cave"], name_ko="수정", variants=_CR,
    light={"color": GLOWC["blue"], "radius": 2.6, "at": (0, 0, 0.5), "flicker": 0.05, "variants": [k for k in _CR if k != "dead"], "colors": dict([(k, GLOWC["red"]) for k in _CR if k.startswith("red")] + [(k, GLOWC["violet"]) for k in _CR if k.startswith("violet")])})
def crystal(k, col="blue", big=False, seed=1):
    rng = np.random.default_rng(seed + (7 if big else 0))
    mat = {"blue": "crystal_b", "red": "crystal_r", "violet": "crystal_v", None: "stone_d"}[col]
    s = 1.0 if big else 0.55
    tips = []
    spec = [(0.0, 0.0, 0.2, 0.62, 0.0, 0.05)] + [(rng.uniform(-0.42, 0.42), rng.uniform(-0.2, 0.2), rng.uniform(0.09, 0.15), rng.uniform(0.25, 0.45), rng.uniform(-0.3, 0.3), 0.0) for _ in range(6 if big else 4)]
    for x, y, r, hz, tx, _ in spec:
        ty = -x * 1.1 + rng.uniform(-0.15, 0.15)
        c0 = v3(x * s, y * s, -0.02)
        k.add(shard(c0, r * s, hz * s, tx, ty), mat)
        tips.append((x * s + np.sin(-ty) * hz * s * 1.3, y * s, hz * s * 1.35 * np.cos(ty)))
    k.rubble([(0.5 * s, -0.25 * s), (-0.5 * s, -0.2 * s), (0.1 * s, -0.32 * s)], "stone_d", 0.04 * s + 0.02, 0.08 * s + 0.02)
    if not col:
        return {}
    c = GLOWC[col]
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 0.45 * s), 60 * s + 12, c, 0.4), [vw.px(x, y - 0.1, z * 0.85) for x, y, z in tips[:3]])]}


@flat("mana_residue", "special", cell=(96, 96), tags=["magic"], name_ko="마력 잔류물",
    variants={"blue": {"col": "blue", "frames": 4}, "violet": {"col": "violet", "frames": 4}, "green": {"col": "green", "frames": 4}, "blue_b": {"col": "blue", "frames": 4, "seed": 9}},
    light={"color": GLOWC["blue"], "radius": 1.5, "at": (0, 0, 0.05), "flicker": 0.3, "variants": ["blue", "violet", "green", "blue_b"], "colors": {"violet": GLOWC["violet"], "green": GLOWC["green"]}})
def mana_residue(c, col="blue", f=0, seed=1):
    c.graded = False
    rng = np.random.default_rng(seed)
    color = GLOWC[col]
    smear = c.blob(48, 50, 34, 22, 0.5, 14, 0.5, rng.uniform(0, 3), seed) * (0.4 + 0.6 * c.noise(6, seed + 3))
    c.add(smear, hexc(color) * 0.7, 0.34 * PULSE(f))
    c.add(sstep(smear * c.noise(3, seed + 5, 2), 0.3, 0.5), color, 0.4)
    for i in range(16):   # 떠도는 빛 알갱이(프레임마다 몇 개가 깜박인다)
        x, y, r = rng.uniform(14, 82), rng.uniform(18, 80), rng.uniform(1.0, 2.4)
        on = 0.35 + 0.65 * ((i + f) % 4 != 0)
        d = c.dist(x, y, r)
        c.add(sstep(1.0 - d / 3.0, 0, 1) * 0.5 * on, color, 1.0)
        c.add(sstep(1.0 - d, 0, 0.6) * on, hexc(color) * 0.3 + 0.7, 1.0)


# ── 압력판 · 잠금장치 ─────────────────────────────────────────────────────────

@prop("pressure_plate", "special", layer="decal", cell=(2, 2), tags=["machine", "stone", "trap"], name_ko="압력판", interact="plate",
    variants={"up": {}, "pressed": {"state": "pressed"}, "rune": {"rune": True}, "rune_pressed": {"rune": True, "state": "pressed", "frames": 4}},
    meta={"states": {"idle": "up", "active": "pressed"}})
def pressure_plate(k, state="up", rune=False, seed=1, f=0):
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.035), (0.46, 0.46, 0.035), 0.012), box(p, v3(0, 0, 0.05), (0.36, 0.36, 0.06))), 0.012, 0.15, seed), "stone_d")
    z = 0.012 if state == "pressed" else 0.05
    k.add(rough(lambda p: box(p, v3(0, 0, z), (0.34, 0.34, z), 0.012), 0.01, 0.2, seed + 1), "stone")
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: sphere(p, v3(sx * 0.27, sy * 0.27, z * 2), 0.022), "iron")
    if rune:
        on = state == "pressed"
        return {"shadow": 0.25, "post": [rune_post(0, 0, z * 2, 20, 41, "red" if on else None, f, 14)]}
    return {"shadow": 0.25}


@prop("lock_pedestal", "special", cell=(2, 3), collide=(0.6, 0.5), tags=["machine", "stone", "lock"], name_ko="잠금 받침대", interact="lock",
    variants={"locked": {"frames": 4}, "unlocked": {"state": "unlocked", "frames": 4}, "empty": {"state": "empty"}, "keyhole": {"state": "keyhole"}},
    light={"color": GLOWC["red"], "radius": 1.8, "at": (0, -0.1, 0.95), "flicker": 0.1, "variants": ["locked", "unlocked"], "colors": {"unlocked": GLOWC["blue"]}},
    meta={"states": {"idle": "locked", "active": "unlocked", "spent": "empty"}})
def lock_pedestal(k, state="locked", seed=1, f=0):
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.07), (0.32, 0.28, 0.07), 0.02), box(p, v3(0, 0, 0.45), (0.21, 0.18, 0.36), 0.03)), 0.02, 0.2, seed), "stone")
    top = v3(0, 0, 0.86)
    T = lambda p: rot_x(p, -0.5, top)
    k.add(rough(lambda p: sub(box(T(p), top, (0.28, 0.22, 0.07), 0.02), cyl(T(p), top + v3(0, 0, 0.03), 0.1, 0.1)), 0.012, 0.2, seed + 1), "stone_d")
    k.add(lambda p: torus(T(p), top + v3(0, 0, 0.07), 0.11, 0.022), "brass")
    gx, gy, gz = 0.0, -0.04, 0.96
    if state in ("locked", "unlocked"):
        col = "red" if state == "locked" else "blue"
        k.add(lambda p: octa(T(p), top + v3(0, 0, 0.09), 0.085, 0.09), "crystal_r" if col == "red" else "crystal_b")
        c = GLOWC[col]
        return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(gx, gy, gz), 26, c, 0.5 * PULSE(f)), [vw.px(gx - 0.02, gy - 0.05, gz + 0.03)])]}
    k.add(lambda p: cyl(T(p), top + v3(0, 0, 0.035), 0.09, 0.02), "void")
    if state == "keyhole":
        k.add(lambda p: box(T(p), top + v3(0, 0, 0.06), (0.1, 0.1, 0.012), 0.005), "brass")
        k.add(lambda p: np.minimum(cyl(T(p), top + v3(0, 0.02, 0.07), 0.025, 0.012), box(T(p), top + v3(0, -0.025, 0.075), (0.012, 0.04, 0.008))), "void")
    return {}


@prop("chained_lock", "special", layer="wall_decal", cell=(3, 4), tags=["iron", "lock", "prison"], name_ko="사슬 자물쇠", interact="lock",
    variants={"locked": {}, "broken": {"state": "broken"}}, meta={"states": {"idle": "locked", "spent": "broken"}})
def chained_lock(k, state="locked", seed=1):
    y = -0.08
    if state == "broken":
        k.add(chain(v3(-0.5, y, 1.9), v3(-0.46, y, 0.9), 0.034), "iron")
        k.add(chain(v3(0.5, y, 1.9), v3(0.47, y, 1.2), 0.034), "iron")
        k.add(chain(v3(-0.5, y, 0.5), v3(-0.3, y - 0.25, 0.03), 0.034), "iron")
        k.add(lambda p: np.minimum(box(rot_y(p, 0.5, (0.25, -0.4, 0.06)), v3(0.25, -0.4, 0.06), (0.13, 0.11, 0.05), 0.02), torus(p, v3(0.5, -0.36, 0.025), 0.08, 0.024)), "rust")
        return {"shadow": 0.3}
    k.add(chain(v3(-0.5, y, 1.9), v3(0.5, y, 0.5), 0.034), "iron")
    k.add(chain(v3(0.5, y, 1.9), v3(-0.5, y, 0.5), 0.034), "iron")
    for sx, z in ((-0.5, 1.9), (0.5, 1.9), (-0.5, 0.5), (0.5, 0.5)):
        k.add(lambda p, sx=sx, z=z: ring_x(p, v3(sx, y + 0.03, z), 0.06, 0.022), "iron")
    k.add(lambda p: ring_x(p, v3(0, y - 0.05, 1.33), 0.085, 0.03), "iron")
    k.add(rough(lambda p: box(p, v3(0, y - 0.07, 1.13), (0.15, 0.06, 0.14), 0.03), 0.012, 0.1, seed), "rust")
    k.add(lambda p: np.minimum(disc_x(p, v3(0, y - 0.13, 1.16), 0.03, 0.01), box(p, v3(0, y - 0.13, 1.1), (0.012, 0.01, 0.05))), "void")
    return {"shadow": 0.0}
