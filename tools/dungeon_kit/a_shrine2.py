"""신전 둘째 묶음: 향로(세운 · 매단) · 봉헌 촛대 · 색유리 창(뾰족창 · 둥근 장미창) · 벽감 · 장식 기둥 · 신전 벽 장식 · 봉헌물 · 성수반 · 종.
a_shrine.py와 같은 재질(밝은 석회석 · 금박 · 흰 천)과 같은 규칙 — 세계관에 정해진 신의 상징이 없어 문양은 중립 도형만(마름모 · 뾰족 아치 · 고리 · 꽃잎 · 물결).
색유리는 추상 색면(마름모 · 꽃잎 고리)만 — 사람 · 상징을 그리지 않는다."""
import numpy as np

import fx
from kit import (F, box, cap, cone, cyl, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from a_furniture import _frustum
from a_shrine import candle, chalice, flames, flowers, mats, smoke
from paint2d import sstep

PI = np.pi
FIRE = "#f0a040"
GLASS = ("#7a2a30", "#2e4a7a", "#a08030", "#3e6a4a", "#5a3a72")


def many(fns):
    return lambda p: np.minimum.reduce([f(p) for f in fns])


# ── 향로 ────────────────────────────────────────────────────────────────────

def _bowl_censer(k, z, r=0.13):
    """뚜껑에 구멍 뚫린 둥근 향로 몸통(가운데 z)."""
    k.add(lambda p: smin(sub(sphere(p, v3(0, 0, z), r), box(p, v3(0, 0, z + r * 0.15), (r * 2, r * 2, 0.008))), cap(p, v3(0, 0, z + r * 0.8), v3(0, 0, z + r * 1.3), 0.02, 0.008), 0.02), "gilt")
    k.add(lambda p: torus(p, v3(0, 0, z + r * 0.12), r * 0.99, 0.012), "brass")


@prop("censer", "shrine", cell=(2, 3), collide=(0.45, 0.45), tags=["temple", "metal", "smoke"], name_ko="세운 향로",
    variants={"smoking": {"frames": 4}, "cold": {"state": "cold"}})
def censer(k, state="smoking", seed=1, f=0):
    """세 발 받침 위 둥근 향로 — 피어오르는 향 연기."""
    mats(k)
    k.add(many([lambda p, a=a: cap(p, v3(np.cos(a) * 0.2, np.sin(a) * 0.2, 0.0), v3(np.cos(a) * 0.06, np.sin(a) * 0.06, 0.5), 0.02, 0.014) for a in (PI / 2, PI / 2 + 2.1, PI / 2 + 4.2)]), "gilt")
    k.add(lambda p: torus(p, v3(0, 0, 0.3), 0.12, 0.012), "gilt")
    _bowl_censer(k, 0.62)
    if state == "smoking":
        return {"shadow": 0.4, "post": [smoke(0, 0, 0.82, seed, f, 8, 52, 0.4)], "glow": [(0, 0, 0.66, 12, "#e08a3a", 0.25)]}
    return {}


@prop("censer_hanging", "shrine", layer="over", cell=(2, 4), tags=["temple", "metal", "smoke"], name_ko="매단 향로",
    variants={"smoking": {"frames": 4}, "cold": {"state": "cold"}})
def censer_hanging(k, state="smoking", seed=1, f=0):
    """천장에서 내려온 사슬 셋에 매단 향로 — 머리 위 전경(원점 = 바로 아래 바닥)."""
    mats(k)
    z = 1.75
    for a in (PI / 2, PI / 2 + 2.1, PI / 2 + 4.2):
        k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.1, np.sin(a) * 0.1, z + 0.06), v3(0, 0, 2.7), 0.007), "iron")
    _bowl_censer(k, z, 0.12)
    if state == "smoking":
        return {"shadow": 0.0, "post": [smoke(0, 0, z + 0.16, seed, f, 7, 40, 0.35)], "glow": [(0, 0, z + 0.03, 10, "#e08a3a", 0.25)]}
    return {"shadow": 0.0}


# ── 봉헌 촛대 ────────────────────────────────────────────────────────────────

@prop("votive_rack", "shrine", cell=(3, 3), collide=(1.0, 0.45), tags=["temple", "fire", "metal"], name_ko="봉헌 촛대",
    variants={"lit": {"frames": 4}, "half": {"state": "half", "frames": 4}, "out": {"state": "out"}},
    light={"color": FIRE, "radius": 3.0, "at": (0, 0, 0.8), "flicker": 0.25, "variants": ["lit", "half"]})
def votive_rack(k, state="lit", seed=1, f=0):
    """세 단 계단식 쇠 받침에 작은 초가 줄지어 — 앞에 모래 쟁반."""
    mats(k)
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: np.minimum(cap(p, v3(sx * 0.5, -0.2, 0), v3(sx * 0.5, -0.2, 0.42), 0.018), cap(p, v3(sx * 0.5, 0.2, 0), v3(sx * 0.5, 0.2, 0.82), 0.018)), "iron")
    rows = ((-0.16, 0.42), (0.0, 0.62), (0.16, 0.82))
    for y, z in rows:
        k.add(lambda p, y=y, z=z: box(p, v3(0, y, z), (0.52, 0.06, 0.012), 0.004), "iron")
    tips = []
    rng = np.random.default_rng(seed)
    for j, (y, z) in enumerate(rows):
        for i in range(7):
            x = -0.42 + i * 0.14
            lit = state == "lit" or (state == "half" and rng.random() < 0.45)
            h = rng.uniform(0.04, 0.09) if state != "out" else rng.uniform(0.02, 0.05)
            k.add(lambda p, x=x, y=y, z=z, h=h: cyl(p, v3(x, y, z + 0.012), 0.016, h, 0.004), "wax")
            if lit and state != "out":
                tips.append((x, y, z + 0.012 + h + 0.01))
    if state == "out":
        k.add(many([lambda p, x=x: sphere(p, v3(x, -0.16, 0.45), 0.012) for x in (-0.3, 0.1, 0.35)]), "wax")
        return {}
    return {"post": flames(tips, seed, f, 5, 0.12)}


# ── 색유리 창 (평면 — 벽면에 붙인다, 원점 = 벽 밑동) ─────────────────────────────

def _lancet_mask(c, cx, top, bot, half):
    """뾰족 아치 창 마스크: 위는 두 원호가 만나는 뾰족 끝."""
    r = half * 1.6
    spring = top + r * 0.9
    body = c.rect(cx - half, spring, cx + half, bot, 0.6)
    arch = np.minimum(1 - sstep(c.dist(cx - half + r, spring, r), 0.98, 1.02), 1 - sstep(c.dist(cx + half - r, spring, r), 0.98, 1.02)) * (c.yy <= spring + 0.5) * (c.yy >= top)
    return np.maximum(body, arch)


def _panes(c, m, glow, seed, ring=None):
    """납 줄로 나눈 추상 색면 — 마름모 격자(+ 둥근 고리 꽃잎)."""
    rng = np.random.default_rng(seed)
    u = (c.xx + c.yy) / 9.0
    v = (c.xx - c.yy) / 9.0
    cell = np.floor(u) * 31 + np.floor(v) * 7
    lead = np.maximum(sstep(0.12 - np.abs(u - np.round(u)), 0, 0.05), sstep(0.12 - np.abs(v - np.round(v)), 0, 0.05))
    idx = (np.abs(cell + seed * 3).astype(np.int64)) % len(GLASS)
    if ring is not None:   # 장미창: 고리 따라 꽃잎 색
        rr, aa = ring
        idx = np.where(rr < 1.0, ((aa * 8 / (2 * PI)).astype(np.int64) + (rr * 3).astype(np.int64)) % len(GLASS), idx)
        fa, fr = (aa * 8 / (2 * PI)) % 1, (rr * 3) % 1
        da = np.minimum(fa, 1 - fa) * (2 * PI / 8) * rr * 40      # 고리 둘레 px쯤
        dr = np.minimum(fr, 1 - fr) * 14
        lead = np.where(rr < 1.0, np.maximum(sstep(1.2 - da, 0, 0.6), sstep(1.2 - dr, 0, 0.6)), lead)
    col = np.zeros(c.xx.shape + (3,), F)
    from paint2d import hexc
    pal = np.stack([hexc(g) for g in GLASS])
    col = pal[idx] * (0.55 + c.noise(4, seed)[..., None] * 0.35)
    if glow:
        col = np.clip(col * 1.9 + 0.08, 0, 1)
    else:
        col = col * 0.55
    c.paint(m, col)
    c.paint(m * lead, "#14100e", 0.95)
    if glow:
        c.glow(m, "#e0c890", 6, 0.35)


@flat("stained_glass", "shrine", layer="wall_decal", cell=(72, 160), tags=["temple", "glass", "window"], name_ko="색유리 창",
    variants={"dim": {}, "glowing": {"glow": True}, "pair": {"pair": True}, "pair_glowing": {"pair": True, "glow": True}},
    light={"color": "#e0c890", "radius": 3.5, "at": (0, -0.3, 1.4), "flicker": 0.0, "variants": ["glowing", "pair_glowing"]},
    meta={"note": "벽면에 붙인다 — 원점 = 벽 밑동, 창은 0.6~2.3칸 높이"})
def stained_glass(c, glow=False, pair=False, seed=1):
    c.origin = (36, 160)
    top, bot = 14, 118
    frame = _lancet_mask(c, 36, top - 5, bot + 5, 22 if not pair else 30)
    c.paint(frame, "#a8a292")
    c.shade(frame * (c.xx > 36), -0.18)
    c.paint(c.rect(8, bot + 4, 64, bot + 11), "#bab4a4")                          # 창턱
    c.shade(c.rect(8, bot + 9, 64, bot + 11), -0.35)
    if pair:
        for cx in (25, 47):
            _panes(c, _lancet_mask(c, cx, top + 8, bot, 9), glow, seed + cx)
        rose = 1 - sstep(c.dist(36, top + 9, 7.5), 0.95, 1.05)
        _panes(c, rose, glow, seed + 5, (c.dist(36, top + 9, 7.5), np.arctan2(c.yy - top - 9, c.xx - 36) + PI))
    else:
        _panes(c, _lancet_mask(c, 36, top, bot, 17), glow, seed)
    c.paint(c.rim(frame, 1.2), "#16100e", 0.8)


@flat("rose_window", "shrine", layer="wall_decal", cell=(112, 160), tags=["temple", "glass", "window"], name_ko="둥근 장미창",
    variants={"dim": {}, "glowing": {"glow": True}},
    light={"color": "#e0c890", "radius": 4.0, "at": (0, -0.3, 1.7), "flicker": 0.0, "variants": ["glowing"]},
    meta={"note": "벽면 높이 붙이는 둥근 창(가운데 1.7칸 높이) — 원점 = 벽 밑동"})
def rose_window(c, glow=False, seed=1):
    c.origin = (56, 160)
    cx, cy, R = 56, 52, 42
    frame = 1 - sstep(c.dist(cx, cy, R + 6), 0.97, 1.03)
    c.paint(frame, "#a8a292")
    c.shade(frame * sstep(c.xx + c.yy - cx - cy, 0, 30), -0.2)
    m = 1 - sstep(c.dist(cx, cy, R), 0.97, 1.03)
    rr = c.dist(cx, cy, R)
    _panes(c, m, glow, seed, (rr, np.arctan2(c.yy - cy, c.xx - cx) + PI))
    hub = 1 - sstep(c.dist(cx, cy, 7), 0.9, 1.1)
    c.paint(hub, "#a8a292")
    c.paint(c.rim(frame, 1.2), "#16100e", 0.8)


# ── 벽감 · 벽 장식 ─────────────────────────────────────────────────────────────

@prop("wall_niche", "shrine", layer="wall_decal", cell=(2, 4), tags=["temple", "stone", "fire"], name_ko="벽감",
    variants={"candle": {"frames": 4}, "vessel": {"state": "vessel"}, "empty": {"state": "empty"}},
    light={"color": FIRE, "radius": 2.2, "at": (0, -0.1, 1.2), "flicker": 0.2, "variants": ["candle"]})
def wall_niche(k, state="candle", seed=1, f=0):
    """벽에 파인 뾰족 아치 감실 — 둘레 돌테, 안 바닥에 촛대나 잔."""
    mats(k)
    z0, half, hh = 0.95, 0.22, 0.52
    frame = lambda p: sub(box(p, v3(0, -0.03, z0 + hh / 2), (half + 0.07, 0.04, hh / 2 + 0.08), 0.01), box(p, v3(0, -0.04, z0 + hh / 2), (half, 0.06, hh / 2)))
    k.add(rough(frame, 0.006, 0.2, seed), "lime")
    k.add(lambda p: np.maximum(box(p, v3(0, -0.03, z0 + hh + 0.13), (half + 0.07, 0.04, 0.15)), np.maximum(np.hypot(p[:, 0] + 0.15, p[:, 2] - z0 - hh + 0.04) - 0.38, np.hypot(p[:, 0] - 0.15, p[:, 2] - z0 - hh + 0.04) - 0.38)), "lime")
    k.add(lambda p: box(p, v3(0, 0.02, z0 + hh / 2), (half, 0.02, hh / 2 + 0.1)), "void")
    k.add(lambda p: box(p, v3(0, -0.06, z0 - 0.02), (half + 0.1, 0.07, 0.025), 0.008), "lime_d")
    if state == "candle":
        tip = candle(k, 0, -0.04, z0, 0.14, 0.022)
        return {"shadow": 0.0, "foot": 0.3, "post": flames([tip], seed, f, 7, 0.22)}
    if state == "vessel":
        chalice(k, 0, -0.04, z0, 1.3)
        flowers(k, 0.13, -0.05, z0, 0.05, "fl_w", 4, seed)
    return {"shadow": 0.0, "foot": 0.3}


@prop("shrine_wall_panel", "shrine", layer="wall_decal", cell=(3, 4), tags=["temple", "stone", "wall"], name_ko="신전 벽 장식",
    variants={"arcade": {}, "plaque": {"state": "plaque"}, "stoup": {"state": "stoup"}})
def shrine_wall_panel(k, state="arcade", seed=1):
    """arcade = 벽에 새긴 막힌 아치 셋 · plaque = 금빛 테 두른 추모판(새긴 글줄은 읽히지 않는 선) · stoup = 벽에 붙은 작은 물그릇."""
    mats(k)
    y = -0.02
    if state == "arcade":
        for x in (-0.36, 0.0, 0.36):
            k.add(lambda p, x=x: np.minimum(box(p, v3(x - 0.15, y, 1.0), (0.025, 0.03, 0.42)), box(p, v3(x + 0.15, y, 1.0), (0.025, 0.03, 0.42))), "lime")
            k.add(lambda p, x=x: np.maximum(np.abs(np.hypot(p[:, 0] - x, p[:, 2] - 1.42) - 0.15) - 0.025, np.maximum(np.abs(p[:, 1] - y) - 0.03, 1.42 - p[:, 2])), "lime")
            k.add(lambda p, x=x: box(p, v3(x, y + 0.03, 1.1), (0.12, 0.012, 0.5)), "lime_d")
        k.add(lambda p: box(p, v3(0, y - 0.01, 0.56), (0.58, 0.05, 0.03), 0.008), "lime")
        return {"shadow": 0.0, "foot": 0.3}
    if state == "plaque":
        k.add(rough(lambda p: box(p, v3(0, y, 1.25), (0.36, 0.025, 0.26), 0.01), 0.004, 0.2, seed), "lime_c")
        k.add(lambda p: sub(box(p, v3(0, y - 0.01, 1.25), (0.38, 0.03, 0.28), 0.01), box(p, v3(0, y - 0.03, 1.25), (0.35, 0.05, 0.25))), "gilt")
        k.add(many([lambda p, z=z, w=w: box(p, v3(0, y - 0.025, z), (w, 0.006, 0.008)) for z, w in ((1.38, 0.24), (1.3, 0.28), (1.22, 0.26), (1.14, 0.18))]), "lime_d")
        return {"shadow": 0.0, "foot": 0.3}
    k.add(rough(lambda p: np.minimum(box(p, v3(0, y, 0.95), (0.1, 0.03, 0.18), 0.02), sub(ell(p, v3(0, y - 0.1, 0.9), (0.17, 0.12, 0.08)), box(p, v3(0, y - 0.1, 1.0), (0.3, 0.3, 0.1)))), 0.004, 0.2, seed), "lime")
    k.add(lambda p: np.maximum(ell(p, v3(0, y - 0.1, 0.9), (0.15, 0.1, 0.06)), p[:, 2] - 0.885), "water")
    k.add(lambda p: cone(rot_x(p, PI, (0, y - 0.1, 0.84)), v3(0, y - 0.1, 0.84), 0.07, 0.14), "lime_d")
    return {"shadow": 0.0, "foot": 0.3}


# ── 장식 기둥 ────────────────────────────────────────────────────────────────

@prop("temple_column", "shrine", cell=(2, 5), collide=(0.6, 0.6), tags=["temple", "stone", "structure"], name_ko="신전 장식 기둥",
    variants={"fluted": {}, "clustered": {"state": "clustered"}, "banner": {"state": "banner"}})
def temple_column(k, state="fluted", seed=1):
    """흰 석회석 기둥: 단 · 홈 판 몸통 · 잎 모양을 줄인 덩어리 머리(fluted) / 가는 기둥 넷을 묶은 고딕 다발 기둥(clustered)."""
    mats(k)
    H = 2.6
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.06), (0.27, 0.27, 0.06), 0.01), cyl(p, v3(0, 0, 0.12), 0.22, 0.08, 0.02)), 0.005, 0.2, seed), "lime")
    if state == "clustered":
        k.add(lambda p: cyl(p, v3(0, 0, 0.2), 0.15, H - 0.4), "lime")
        k.add(many([lambda p, a=a: cyl(p, v3(np.cos(a) * 0.14, np.sin(a) * 0.14, 0.2), 0.065, H - 0.4) for a in (PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4)]), "lime_c")
        k.add(rough(lambda p: smin(cyl(p, v3(0, 0, H - 0.2), 0.25, 0.1, 0.02), _frustum(p, v3(0, 0, H - 0.32), 0.2, 0.26, 0.12), 0.03), 0.005, 0.2, seed), "lime")
    else:
        flute = lambda p: cyl(p, v3(0, 0, 0.2), 0.17, H - 0.42) + np.maximum(np.cos(np.arctan2(p[:, 1], p[:, 0]) * 12), 0) ** 4 * 0.012
        k.add(flute, "lime")
        k.add(rough(lambda p: smin(_frustum(p, v3(0, 0, H - 0.36), 0.17, 0.26, 0.16), box(p, v3(0, 0, H - 0.14), (0.28, 0.28, 0.06), 0.01), 0.03), 0.006, 0.2, seed), "lime")
        k.add(many([lambda p, a=a: sphere(p, v3(np.cos(a) * 0.22, np.sin(a) * 0.22, H - 0.26), 0.045) for a in np.linspace(0, 2 * PI, 9)[:-1]]), "lime_c")
    if state == "banner":   # 금빛 테 두른 흰 천을 기둥 앞에 늘어뜨린다
        k.add(lambda p: hcyl(p, v3(-0.24, -0.2, H - 0.45), v3(0.24, -0.2, H - 0.45), 0.014), "gilt")
        k.add(lambda p: box(p, v3(0, -0.2, H - 1.0), (0.2, 0.012, 0.55), 0.004), "cloth_w")
        k.add(lambda p: np.maximum(box(p, v3(0, -0.215, H - 1.0), (0.21, 0.008, 0.56)), -box(p, v3(0, -0.215, H - 1.0), (0.17, 0.02, 0.52))), "cloth_gd")
        k.add(lambda p: np.maximum(np.abs(p[:, 0]) + np.abs(p[:, 2] - H + 0.95) * 0.8 - 0.1, np.abs(p[:, 1] + 0.218) - 0.006), "cloth_gd")
    return {}


# ── 봉헌물 · 성수반 · 종 ──────────────────────────────────────────────────────

@prop("offerings", "shrine", cell=(2, 2), tags=["temple", "offering"], name_ko="봉헌물",
    variants={"flowers": {}, "fruit": {"state": "fruit"}, "coins": {"state": "coins"}, "candles": {"state": "candles", "frames": 4}, "cloth": {"state": "cloth"}},
    light={"color": FIRE, "radius": 1.6, "at": (0, 0, 0.2), "flicker": 0.3, "variants": ["candles"]})
def offerings(k, state="flowers", seed=1, f=0):
    """제단 앞 · 석상 발치에 놓는 작은 봉헌물."""
    mats(k)
    if state == "flowers":
        for i, (x, y, m) in enumerate(((-0.12, 0.02, "fl_w"), (0.1, -0.04, "fl_r"), (0.0, 0.1, "fl_y"))):
            k.add(lambda p, x=x, y=y: cap(p, v3(x - 0.12, y - 0.02, 0.02), v3(x + 0.05, y, 0.02), 0.012), "leaf")
            flowers(k, x + 0.08, y, 0.0, 0.06, m, 5, seed + i)
        k.add(lambda p: torus(p, v3(-0.02, 0.0, 0.025), 0.03, 0.008), "rope")
    elif state == "fruit":
        k.add(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.1, 0.2, 0.07), _frustum(p, v3(0, 0, 0.02), 0.09, 0.19, 0.08)), "gilt")
        k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, 0.09), 0.055) for x, y in ((-0.06, 0.0), (0.06, 0.03), (0.0, -0.06), (0.01, 0.04))]), "fruit")
        k.add(lambda p: sphere(p, v3(0.0, 0.0, 0.15), 0.05), "fl_y")
    elif state == "coins":
        k.add(lambda p: sub(cyl(p, v3(0, 0, 0), 0.15, 0.03, 0.01), cyl(p, v3(0, 0, 0.015), 0.13, 0.04)), "lime")
        k.add(many([lambda p, x=x, y=y, z=z: cyl(p, v3(x, y, 0.015 + z), 0.028, 0.008, 0.002) for x, y, z in ((-0.04, 0.02, 0), (0.03, -0.02, 0), (0.0, 0.05, 0), (0.05, 0.04, 0.008), (-0.02, -0.05, 0))]), "gilt")
    elif state == "candles":
        tips = [candle(k, x, y, 0, h, 0.018, None) for x, y, h in ((-0.12, 0.0, 0.08), (0.0, 0.06, 0.12), (0.11, -0.03, 0.06), (0.03, -0.1, 0.05))]
        return {"post": flames(tips, seed, f, 5, 0.18)}
    else:
        k.add(rough(lambda p: box(p, v3(0, 0, 0.05), (0.2, 0.14, 0.05), 0.03), 0.006, 0.08, seed), "cloth_w")
        k.add(lambda p: np.maximum(box(p, v3(0, 0, 0.05), (0.21, 0.025, 0.055), 0.01), -1.0), "cloth_gd")
    return {}


@prop("temple_font", "shrine", cell=(2, 3), collide=(0.6, 0.6), tags=["temple", "stone", "water"], name_ko="성수반", interact="examine",
    variants={"water": {"frames": 4}, "dry": {"state": "dry"}})
def temple_font(k, state="water", seed=1, f=0):
    """팔각 받침 위 넓은 돌 대야 — 잔잔한 물이 반짝인다."""
    mats(k)
    oct_ = lambda p, z, r, h: np.maximum(np.maximum.reduce([np.abs(p[:, 0] * np.cos(a) + p[:, 1] * np.sin(a)) for a in (0, PI / 4, PI / 2, 3 * PI / 4)]) - r, np.abs(p[:, 2] - z - h / 2) - h / 2)
    k.add(rough(lambda p: np.minimum.reduce([oct_(p, 0, 0.26, 0.08), oct_(p, 0.08, 0.1, 0.42)]), 0.005, 0.2, seed), "lime")
    k.add(rough(lambda p: sub(_frustum(p, v3(0, 0, 0.5), 0.14, 0.34, 0.18), _frustum(p, v3(0, 0, 0.56), 0.1, 0.3, 0.2)), 0.005, 0.2, seed + 1), "lime_c")
    k.add(lambda p: torus(p, v3(0, 0, 0.68), 0.32, 0.025), "lime")
    if state == "water":
        k.add(lambda p: cyl(p, v3(0, 0, 0.6), 0.29, 0.05), "water")
        rng = np.random.default_rng(seed + f)
        pts = [(rng.uniform(-0.2, 0.2), rng.uniform(-0.15, 0.15)) for _ in range(4)]
        return {"post": [lambda img, vw, pts=pts: fx.sparkle(img, [vw.px(x, y, 0.655) for x, y in pts], "#dceaf0", 1.6)]}
    k.add(lambda p: pool(p, (0.04, 0.02, 0.56), 0.12, 0.08, 0.004), "lime_d")
    return {}


@prop("temple_bell", "shrine", cell=(3, 4), collide=(1.1, 0.5), tags=["temple", "metal", "wood"], name_ko="신전 종", interact="examine",
    variants={"frame": {}, "rope": {"state": "rope"}})
def temple_bell(k, state="frame", seed=1):
    """frame = 나무 문틀에 매단 청동 종(바닥에 서는 것) · rope = 벽 앞 높이 매단 종 + 늘어뜨린 줄."""
    mats(k)
    bell = lambda p, z, s: sub(smin(_frustum(p, v3(0, 0, z), 0.2 * s, 0.11 * s, 0.24 * s), sphere(p, v3(0, 0, z + 0.24 * s), 0.11 * s), 0.05), _frustum(p, v3(0, 0, z - 0.01), 0.18 * s, 0.09 * s, 0.22 * s))
    if state == "frame":
        k.add(many([lambda p, sx=sx: np.minimum(box(p, v3(sx * 0.42, 0, 0.6), (0.04, 0.04, 0.6), 0.008), box(p, v3(sx * 0.42, 0, 0.03), (0.06, 0.22, 0.03), 0.008)) for sx in (-1, 1)]), "wood_d")
        k.add(lambda p: box(p, v3(0, 0, 1.22), (0.52, 0.05, 0.05), 0.01), "wood_d")
        k.add(lambda p: cap(p, v3(0, 0, 1.17), v3(0, 0, 1.08), 0.015), "iron")
        k.add(lambda p: bell(p, 0.8, 1.15), "bronze")
        k.add(lambda p: sphere(p, v3(0, 0, 0.78), 0.035), "iron")
        k.add(lambda p: cap(p, v3(0.42, -0.06, 0.9), v3(0.3, -0.12, 0.3), 0.01), "rope")
        return {}
    k.add(lambda p: box(p, v3(0, 0.04, 2.1), (0.26, 0.04, 0.04), 0.01), "wood_d")
    k.add(lambda p: bell(p, 1.62, 1.1), "bronze")
    k.add(lambda p: cap(p, v3(0.05, -0.05, 1.6), v3(0.12, -0.15, 0.55), 0.012), "rope")
    k.add(lambda p: cap(p, v3(0.12, -0.15, 0.58), v3(0.12, -0.15, 0.48), 0.022), "rope")
    return {"shadow": 0.2}
