"""조명: 벽 횃불 · 바닥 횃불 · 촛대 · 양초 · 샹들리에 · 랜턴 · 화로 · 모닥불 · 마법 등 · 빛나는 룬 · 빛나는 균열.
불꽃 · 빛 무리는 색 정리 뒤에 얹는다(post — fx.py). 불 켜진 변형은 frames 4(f = 일렁임). light = 게임이 놓을 광원 귀띔.
아래 도우미(octa · gear · glyph …)는 a_special · a_trap도 같이 쓴다."""
import numpy as np

import fx
import sdf
from kit import (F, box, cap, chip, cone, cut_above, cyl, disc_x, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from paint2d import hexc

FIRE = "#f0a040"
GLOWC = {"blue": "#70b0f0", "red": "#e04848", "violet": "#a070e0", "green": "#80d060", "fire": FIRE}
GLOWM = {"blue": "glow_b", "red": "glow_r", "violet": "glow_v", "green": "glow_g"}


# ── 같이 쓰는 도우미 ──────────────────────────────────────────────────────────

def octa(p, c, r, hz):
    """뾰족한 여덟면체(수정 조각): 가운데 c, 허리 반지름 r, 위아래 반높이 hz."""
    q = np.abs(p - c)
    return ((q[:, 0] + q[:, 1]) / r + q[:, 2] / hz - 1.0) * min(r, hz) * 0.55


def shard(c, r, hz, tilt_x=0.0, tilt_y=0.0):
    """기울어 솟은 수정 한 조각(밑이 c)."""
    cc = v3(c[0], c[1], c[2] + hz * 0.55)
    return lambda p: octa(rot_x(rot_y(p, tilt_y, c), tilt_x, c), cc, r, hz)


def gear_x(p, c, R, half, teeth=10, phase=0.0, hole=0.3):
    """세운 톱니바퀴(화면을 마주 본다)."""
    dx, dz = p[:, 0] - c[0], p[:, 2] - c[2]
    r = np.hypot(dx, dz)
    rim = r - R - 0.14 * R * np.clip(np.cos(np.arctan2(dz, dx) * teeth + phase) * 2.5, -1, 1)
    return np.maximum(np.maximum(rim * 0.7, np.abs(p[:, 1] - c[1]) - half), R * hole - r)


def gear_z(p, c, R, half, teeth=10, phase=0.0, hole=0.3):
    """누운 톱니바퀴."""
    dx, dy = p[:, 0] - c[0], p[:, 1] - c[1]
    r = np.hypot(dx, dy)
    rim = r - R - 0.14 * R * np.clip(np.cos(np.arctan2(dy, dx) * teeth + phase) * 2.5, -1, 1)
    return np.maximum(np.maximum(rim * 0.7, np.abs(p[:, 2] - c[2]) - half), R * hole - r)


def chain(a, b, r=0.022):
    """쇠사슬(고리 마디가 보이게 굵기가 출렁이는 막대)."""
    a, b = np.asarray(a, F), np.asarray(b, F)
    ln = float(np.sqrt(((b - a) ** 2).sum()))

    def fn(p):
        ab = b - a
        t = np.clip(((p - a) @ ab) / (ln * ln), 0, 1)
        return sdf.length(p - a - t[:, None] * ab) - r * (1.0 + 0.45 * np.sin(t * ln * 60.0))
    return fn


def glyph_strokes(gid):
    """룬 글자 한 자의 획(−0.5~0.5 상자 안 선분들). 같은 gid = 같은 글자."""
    rng = np.random.default_rng(1000 + gid * 7)
    pts = [(x, y) for x in (-0.36, 0.0, 0.36) for y in (-0.5, -0.17, 0.17, 0.5)]
    out, cur = [((0.0, -0.5), (0.0, 0.5))] if gid % 2 == 0 else [], pts[int(rng.integers(12))]
    while len(out) < 4:
        nxt = pts[int(rng.integers(12))]
        if nxt != cur and (nxt[0] != cur[0] or abs(nxt[1] - cur[1]) < 0.4):
            out.append((cur, nxt))
            cur = nxt if rng.random() < 0.6 else pts[int(rng.integers(12))]
    return out


def cglyph(c, cx, cy, size, gid, width=2.0, rot=0.0):
    """평면 판(Canvas)에 룬 글자 마스크."""
    m = np.zeros((c.H, c.W), F)
    cr, sr = np.cos(rot), np.sin(rot)
    for (x0, y0), (x1, y1) in glyph_strokes(gid):
        a = (cx + (x0 * cr - y0 * sr) * size * 0.7, cy + (x0 * sr + y0 * cr) * size)
        b = (cx + (x1 * cr - y1 * sr) * size * 0.7, cy + (x1 * sr + y1 * cr) * size)
        m = np.maximum(m, c.seg([a, b], width, False))
    return m


def iglyph(img, cx, cy, size, gid, width=1.6):
    """덩어리 그림(px) 위 룬 글자 마스크."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    m = np.zeros((hh, ww), F)
    for (x0, y0), (x1, y1) in glyph_strokes(gid):
        ax, ay, bx, by = cx + x0 * size * 0.7, cy + y0 * size, cx + x1 * size * 0.7, cy + y1 * size
        dx, dy = bx - ax, by - ay
        t = np.clip(((xx - ax) * dx + (yy - ay) * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
        m = np.maximum(m, np.clip((width * 0.5 - np.hypot(xx - ax - t * dx, yy - ay - t * dy)) / 0.7 + 0.5, 0, 1))
    return m


def rune_post(x, y, z, size, gid, col=None, f=0, glow=14.0):
    """post: (x, y, z) 자리에 룬 글자 — col이 없으면 새긴 자국(어둡게), 있으면 빛난다(f로 맥동)."""
    def fn(img, vw):
        px, py = vw.px(x, y, z)
        m = iglyph(img, px, py, size, gid) * (img[..., 3] > 128)
        if col is None:
            return fx._over(img, m * 0.75, hexc("#1c1614"))
        k = 0.75 + 0.25 * np.sin(f * 1.57)
        img = fx._over(img, m, hexc(GLOWC[col]) * 0.6 + 0.4)
        return fx.halo(img, px, py, glow, GLOWC[col], 0.55 * k)
    return fn


def flame_post(x, y, z, h, seed, f, pal="fire", width=0.42, glow=2.6, strength=0.5):
    return lambda img, vw: fx.flame(img, *vw.px(x, y, z), h * vw.u / 64.0, seed, f, pal, width, glow, strength)


def lit(name="lit", extra=()):
    return [name] + list(extra)


# ── 횃불 ─────────────────────────────────────────────────────────────────────

@prop("torch_wall", "light", layer="wall_decal", cell=(2, 4), tags=["fire", "iron"], name_ko="벽 횃불",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}, "stub": {"state": "stub"}},
    light={"color": FIRE, "radius": 4.0, "at": (0, -0.2, 1.8), "flicker": 0.35, "variants": ["lit"]})
def torch_wall(k, state="lit", seed=1, f=0):
    k.add(rough(lambda p: box(p, v3(0, 0.07, 1.42), (0.1, 0.035, 0.2), 0.02), 0.01, 0.1, seed), "iron")
    k.add(lambda p: np.minimum(cap(p, v3(0, 0.06, 1.34), v3(0, -0.16, 1.44), 0.03), torus(rot_x(p, -0.5, (0, -0.16, 1.52)), v3(0, -0.16, 1.52), 0.075, 0.024)), "iron")
    top = 1.6 if state == "stub" else 1.86
    tip = v3(0, -0.04 - (top - 1.24) * 0.42, top)
    k.add(lambda p: cap(p, v3(0, -0.04, 1.24), tip, 0.036, 0.05), "wood_d")
    if state != "stub":
        k.add(rough(lambda p: ell(p, tip + v3(0, -0.01, 0.04), (0.085, 0.085, 0.11)), 0.03, 0.05, seed), "coal" if state == "unlit" else "ember")
        k.add(lambda p: torus(rot_x(p, -0.4, tip), tip + v3(0, 0, -0.04), 0.06, 0.016), "rope")
    else:
        k.add(rough(lambda p: sphere(p, tip, 0.055), 0.03, 0.04, seed), "coal")
    if state == "lit":
        return {"shadow": 0.0, "post": [flame_post(0, tip[1] - 0.01, top + 0.1, 30, seed, f)]}
    return {"shadow": 0.0}


@prop("torch_stand", "light", cell=(2, 4), collide=(0.4, 0.4), tags=["fire", "iron"], name_ko="바닥 횃불",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}, "fallen": {"state": "fallen"}},
    light={"color": FIRE, "radius": 4.5, "at": (0, 0, 1.6), "flicker": 0.35, "variants": ["lit"]})
def torch_stand(k, state="lit", seed=1, f=0):
    if state == "fallen":
        k.add(lambda p: cap(p, v3(-0.7, -0.05, 0.04), v3(0.5, 0.1, 0.04), 0.03), "iron")
        k.add(lambda p: sub(ell(p, v3(0.62, 0.11, 0.1), (0.14, 0.12, 0.11)), sphere(p, v3(0.74, 0.12, 0.12), 0.09)), "iron")
        for a in (0.4, 2.2, 4.4):
            k.add(lambda p, a=a: cap(p, v3(-0.7, -0.05, 0.04), v3(-0.82 + np.cos(a) * 0.1, -0.05 + np.sin(a) * 0.22, 0.03 + (a < 1) * 0.16), 0.02), "iron")
        k.add(lambda p: pool(p, v3(0.85, 0.05, 0.008), 0.24, 0.16, 0.008) + (sdf.noise(p, 0.08, seed) - 0.5) * 0.06, "coal")
        k.rubble([(0.86, 0.0), (0.98, 0.12), (0.76, -0.1)], "coal", 0.025, 0.045)
        return {"cell": (4, 2)}
    for a in (0.5, 2.6, 4.7):
        k.add(lambda p, a=a: cap(p, v3(0, 0, 0.34), v3(np.cos(a) * 0.24, np.sin(a) * 0.2, 0.0), 0.022), "iron")
    k.add(lambda p: cap(p, v3(0, 0, 0.3), v3(0, 0, 1.3), 0.026), "iron")
    k.add(lambda p: np.minimum(torus(p, v3(0, 0, 0.75), 0.035, 0.014), sub(cap(p, v3(0, 0, 1.28), v3(0, 0, 1.46), 0.05, 0.13), cyl(p, v3(0, 0, 1.4), 0.1, 0.2))), "iron")
    k.add(rough(lambda p: ell(p, v3(0, 0, 1.44), (0.095, 0.095, 0.06)), 0.03, 0.05, seed), "ember" if state == "lit" else "coal")
    if state == "lit":
        return {"post": [flame_post(0, 0, 1.47, 30, seed, f)]}
    return {}


# ── 초 ───────────────────────────────────────────────────────────────────────

def _candle(k, x, y, z, h, r=0.032):
    k.add(lambda p: smin(cyl(p, v3(x, y, z), r, h, 0.008), cyl(p, v3(x, y, z), r * 1.5, 0.015), 0.02), "wax")
    k.add(lambda p: cap(p, v3(x, y, z + h), v3(x, y, z + h + 0.025), 0.006), "coal")


@prop("candlestick", "light", cell=(2, 3), collide=(0.3, 0.3), tags=["fire", "brass"], name_ko="촛대",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}},
    light={"color": FIRE, "radius": 2.5, "at": (0, 0, 1.3), "flicker": 0.25, "variants": ["lit"]})
def candlestick(k, state="lit", seed=1, f=0):
    k.add(lambda p: smin(smin(cyl(p, v3(0, 0, 0), 0.15, 0.04, 0.012), cap(p, v3(0, 0, 0.04), v3(0, 0, 0.98), 0.03, 0.022), 0.05),
        np.minimum(ell(p, v3(0, 0, 0.5), (0.055, 0.055, 0.07)), cyl(p, v3(0, 0, 0.97), 0.09, 0.025, 0.008)), 0.02), "brass")
    _candle(k, 0, 0, 0.99, 0.2)
    return {"post": [flame_post(0, 0, 1.22, 11, seed, f, "fire", 0.36, 2.6, 0.38)]} if state == "lit" else {}


@prop("candelabra", "light", cell=(2, 4), collide=(0.4, 0.3), tags=["fire", "brass"], name_ko="세 갈래 촛대",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}},
    light={"color": FIRE, "radius": 3.2, "at": (0, 0, 1.6), "flicker": 0.25, "variants": ["lit"]})
def candelabra(k, state="lit", seed=1, f=0):
    k.add(lambda p: smin(smin(cyl(p, v3(0, 0, 0), 0.17, 0.045, 0.012), cap(p, v3(0, 0, 0.04), v3(0, 0, 1.3), 0.034, 0.024), 0.05), ell(p, v3(0, 0, 0.6), (0.06, 0.06, 0.08)), 0.02), "brass")
    tops = [(-0.3, 1.22), (0.0, 1.34), (0.3, 1.22)]
    for s in (-1, 1):   # 휘어 올라가는 팔
        k.add(lambda p, s=s: smin(cap(p, v3(0, 0, 1.0), v3(s * 0.22, 0, 1.02), 0.02), cap(p, v3(s * 0.22, 0, 1.02), v3(s * 0.3, 0, 1.2), 0.02), 0.04), "brass")
    post = []
    for i, (x, z) in enumerate(tops):
        k.add(lambda p, x=x, z=z: cyl(p, v3(x, 0, z - 0.02), 0.07, 0.022, 0.006), "brass")
        hh = 0.16 + 0.05 * ((i * 7 + seed) % 3)
        _candle(k, x, 0, z, hh, 0.028)
        post.append(flame_post(x, 0, z + hh + 0.03, 10, seed + i, f, "fire", 0.36, 2.6, 0.3))
    return {"post": post} if state == "lit" else {}


@prop("candles", "light", cell=(2, 2), tags=["fire", "ritual"], name_ko="양초 무더기",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}, "stubs": {"state": "stubs"}},
    light={"color": FIRE, "radius": 2.4, "at": (0, 0, 0.35), "flicker": 0.3, "variants": ["lit"]})
def candles(k, state="lit", seed=1, f=0):
    spots = [(-0.2, 0.05, 0.3), (0.0, -0.08, 0.18), (0.2, 0.06, 0.24), (0.08, 0.16, 0.38), (-0.08, -0.16, 0.1)]
    k.add(lambda p: pool(p, v3(0, 0, 0.008), 0.34, 0.26, 0.008) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.1, "wax")
    post = []
    for i, (x, y, hh) in enumerate(spots):
        hh = hh * 0.3 if state == "stubs" else hh
        _candle(k, x, y, 0.0, hh, 0.036)
        k.add(lambda p, x=x, y=y, hh=hh: cap(p, v3(x + 0.03, y - 0.02, hh), v3(x + 0.035, y - 0.025, hh * 0.4), 0.012, 0.016), "wax")   # 흘러내린 촛농
        post.append(flame_post(x, y, hh + 0.03, 9, seed + i, f, "fire", 0.36, 2.4, 0.26))
    return {"post": post} if state == "lit" else {}


def _chandelier(k, z, tilt=0.0):
    c0 = v3(0, 0, z)
    T = (lambda p: rot_y(p, tilt, c0)) if tilt else (lambda p: p)
    k.add(lambda p: np.minimum(torus(T(p), c0, 0.5, 0.03), torus(T(p), c0 + v3(0, 0, 0.0), 0.16, 0.022)), "iron")
    spots = []
    for i in range(6):
        a = i * np.pi / 3 + 0.3
        x, y = np.cos(a) * 0.5, np.sin(a) * 0.5
        k.add(lambda p, x=x, y=y: np.minimum(cyl(T(p), v3(x, y, z + 0.02), 0.06, 0.02, 0.005), cap(T(p), v3(x, y, z), v3(x * 0.32, y * 0.32, z), 0.014)), "iron")
        spots.append((x, y))
    return spots


@prop("chandelier", "light", layer="over", cell=(3, 5), tags=["fire", "iron"], name_ko="샹들리에",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}},
    light={"color": FIRE, "radius": 5.5, "at": (0, 0, 2.4), "flicker": 0.2, "variants": ["lit"]})
def chandelier(k, state="lit", seed=1, f=0):
    z = 2.25
    spots = _chandelier(k, z)
    for i in range(3):
        a = i * 2.094 + 0.3
        k.add(chain(v3(np.cos(a) * 0.5, np.sin(a) * 0.5, z), v3(0, 0, z + 0.62), 0.016), "iron")
    k.add(chain(v3(0, 0, z + 0.6), v3(0, 0, z + 1.3), 0.02), "iron")
    post = []
    for i, (x, y) in enumerate(spots):
        hh = 0.12 + 0.04 * (i % 3)
        _candle(k, x, y, z + 0.04, hh, 0.026)
        post.append(flame_post(x, y, z + 0.07 + hh, 9, seed + i, f, "fire", 0.36, 2.6, 0.24))
    return {"shadow": 0.0, "far": 9.0, "post": post if state == "lit" else []}


@prop("chandelier_fallen", "light", cell=(3, 2), collide=(1.0, 0.7), tags=["iron", "ruin", "battle"], name_ko="떨어진 샹들리에", variants={"base": {}})
def chandelier_fallen(k, seed=1):
    spots = _chandelier(k, 0.14, 0.22)
    for i, (x, y) in enumerate(spots[::2]):
        k.add(lambda p, x=x, y=y: hcyl(p, v3(x * 1.3, y * 1.3 - 0.1, 0.03), v3(x * 1.3 + 0.14, y * 1.3 - 0.04, 0.03), 0.026), "wax")
    k.add(chain(v3(0.1, 0.1, 0.2), v3(0.75, 0.3, 0.02), 0.02), "iron")
    k.add(chain(v3(0.75, 0.3, 0.02), v3(1.1, 0.05, 0.02), 0.02), "iron")
    return {}


# ── 랜턴 ─────────────────────────────────────────────────────────────────────

def _lantern(k, c, state, s=1.0):
    """쇠 테 랜턴(밑 가운데 c): 유리 속은 켜지면 빛난다."""
    x, y, z = c
    glass = {"lit": "glow_fire", "unlit": "glass", "broken": "void"}[state]
    k.add(lambda p: box(p, v3(x, y, z + 0.17 * s), (0.085 * s, 0.085 * s, 0.11 * s), 0.01), glass)
    frame = lambda p: np.minimum.reduce([box(p, v3(x, y, z + 0.03 * s), (0.11 * s, 0.11 * s, 0.03 * s), 0.01), smin(box(p, v3(x, y, z + 0.3 * s), (0.11 * s, 0.11 * s, 0.025 * s), 0.01), cone(p, v3(x, y, z + 0.32 * s), 0.1 * s, 0.1 * s), 0.02),
        torus(rot_x(p, 1.57, (x, y, z + 0.46 * s)), v3(x, y, z + 0.46 * s), 0.05 * s, 0.012 * s)] + [cap(p, v3(x + sx * 0.095 * s, y + sy * 0.095 * s, z + 0.03 * s), v3(x + sx * 0.095 * s, y + sy * 0.095 * s, z + 0.3 * s), 0.014 * s) for sx in (-1, 1) for sy in (-1, 1)])
    k.add(frame, "iron")


@prop("lantern", "light", cell=(2, 2), tags=["fire", "iron", "camp"], name_ko="랜턴",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}, "broken": {"state": "broken"}},
    light={"color": FIRE, "radius": 3.5, "at": (0, 0, 0.3), "flicker": 0.15, "variants": ["lit"]})
def lantern(k, state="lit", seed=1, f=0):
    if state == "broken":
        k.yaw = 0.3
        _lantern(k, (0, 0, 0), "broken", 1.3)
        k.yaw = 0.0
        for i, (x, y) in enumerate(k.scatter(5, 0.3, 0.2, 0.25, -0.2)):
            k.add(lambda p, x=x, y=y, i=i: box(rot_z(p, i * 1.1, (x, y, 0)), v3(x, y, 0.008), (0.04, 0.025, 0.008)), "glass")
        return {}
    _lantern(k, (0, 0, 0), state, 1.3)
    if state == "lit":
        return {"post": [lambda img, vw: fx.halo(img, *vw.px(0, -0.1, 0.22), 46 + 3 * np.sin(f * 1.57), FIRE, 0.5 + 0.05 * np.cos(f * 1.57)), flame_post(0, -0.12, 0.14, 7, seed, f, "fire", 0.4, 0.1, 0.0)]}
    return {}


@prop("lantern_hanging", "light", layer="wall_decal", cell=(2, 4), tags=["fire", "iron"], name_ko="걸린 랜턴",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}},
    light={"color": FIRE, "radius": 4.0, "at": (0, -0.3, 1.5), "flicker": 0.15, "variants": ["lit"]})
def lantern_hanging(k, state="lit", seed=1, f=0):
    k.add(lambda p: np.minimum.reduce([box(p, v3(0, 0.07, 1.9), (0.05, 0.03, 0.2), 0.012), cap(p, v3(0, 0.06, 2.02), v3(0, -0.32, 2.02), 0.022), cap(p, v3(0, 0.06, 1.76), v3(0, -0.2, 2.0), 0.016)]), "iron")
    k.add(chain(v3(0, -0.3, 2.0), v3(0, -0.3, 1.82), 0.014), "iron")
    _lantern(k, (0, -0.3, 1.36), state, 1.0)
    if state == "lit":
        return {"shadow": 0.0, "post": [lambda img, vw: fx.halo(img, *vw.px(0, -0.38, 1.53), 44 + 3 * np.sin(f * 1.57), FIRE, 0.5 + 0.05 * np.cos(f * 1.57)), flame_post(0, -0.4, 1.47, 6, seed, f, "fire", 0.4, 0.1, 0.0)]}
    return {"shadow": 0.0}


# ── 화로 · 모닥불 ─────────────────────────────────────────────────────────────

@prop("brazier", "light", cell=(2, 3), collide=(0.6, 0.5), tags=["fire", "iron", "temple"], name_ko="화로",
    variants={"lit": {"frames": 4}, "embers": {"state": "embers", "frames": 4}, "cold": {"state": "cold"}, "toppled": {"state": "toppled"}},
    light={"color": FIRE, "radius": 5.0, "at": (0, 0, 1.0), "flicker": 0.4, "variants": ["lit", "embers"]})
def brazier(k, state="lit", seed=1, f=0):
    bowl = lambda p, c: np.maximum(sub(ell(p, c, (0.34, 0.3, 0.2)), ell(p, c + v3(0, 0, 0.05), (0.29, 0.25, 0.19))), p[:, 2] - c[2] - 0.03)
    if state == "toppled":
        c = v3(0.1, 0, 0.26)
        k.add(lambda p: bowl(rot_y(p, 1.25, c), c), "iron")
        for a, ln in ((0.3, 0.7), (2.5, 0.75)):
            k.add(lambda p, a=a, ln=ln: cap(p, v3(-0.1, 0, 0.2), v3(-0.1 - ln, np.sin(a) * 0.3, 0.03 + (a < 1) * 0.3), 0.024), "iron")
        k.add(lambda p: pool(p, v3(0.65, -0.1, 0.008), 0.34, 0.2, 0.008) + (sdf.noise(p, 0.08, seed) - 0.5) * 0.08, "ash")
        k.rubble(k.scatter(7, 0.3, 0.16, 0.65, -0.1), "coal", 0.03, 0.055)
        return {"cell": (3, 2)}
    c = v3(0, 0, 0.72)
    for a in (0.5, 2.6, 4.7):
        k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.12, np.sin(a) * 0.1, 0.56), v3(np.cos(a) * 0.3, np.sin(a) * 0.24, 0.0), 0.026), "iron")
    k.add(lambda p: torus(p, v3(0, 0, 0.26), 0.2, 0.016), "iron")
    k.add(lambda p: np.minimum(bowl(p, c), torus(p, c + v3(0, 0, 0.02), 0.33, 0.025)), "iron")
    k.add(rough(lambda p: ell(p, c + v3(0, 0, -0.02), (0.27, 0.23, 0.06)), 0.05, 0.06, seed), "ash" if state == "cold" else "coal")
    if state == "cold":
        return {}
    post = [lambda img, vw: fx.embers(img, *vw.px(0, 0, 0.74), 16, 9, seed, f)]
    if state == "lit":
        post += [flame_post(-0.08, 0, 0.74, 20, seed + 1, f, "fire", 0.4, 0.5, 0.2), flame_post(0.04, 0, 0.74, 30, seed, f, "fire", 0.44, 2.4, 0.55)]
    else:
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, 0, 0.8), 36, "#e06a20", 0.3 + 0.05 * np.sin(f * 1.57)))
    return {"post": post}


@prop("firepit", "light", cell=(2, 3), collide=(0.6, 0.5), tags=["fire", "camp"], name_ko="모닥불",
    variants={"lit": {"frames": 4}, "embers": {"state": "embers", "frames": 4}, "cold": {"state": "cold"}},
    light={"color": FIRE, "radius": 5.0, "at": (0, 0, 0.4), "flicker": 0.45, "variants": ["lit", "embers"]})
def firepit(k, state="lit", seed=1, f=0):
    rng = np.random.default_rng(seed)
    for i in range(9):
        a = i * 0.698 + rng.uniform(-0.1, 0.1)
        r = rng.uniform(0.075, 0.11)
        c = v3(np.cos(a) * 0.36, np.sin(a) * 0.3, r * 0.5)
        k.add(rough(lambda p, c=c, r=r: ell(p, c, (r * 1.15, r, r * 0.8)), 0.04, 0.1, seed + i), "stone" if i % 3 else "stone_d")
    k.add(lambda p: pool(p, v3(0, 0, 0.01), 0.3, 0.24, 0.01), "ash" if state == "cold" else "coal")
    for a in (0.3, 1.5, 2.6):
        k.add(lambda p, a=a: hcyl(p, v3(-np.cos(a) * 0.24, -np.sin(a) * 0.2, 0.05), v3(np.cos(a) * 0.24, np.sin(a) * 0.2, 0.09), 0.04), "coal" if state != "lit" else "wood_d")
    if state == "cold":
        return {}
    post = [lambda img, vw: fx.embers(img, *vw.px(0, 0, 0.06), 15, 10, seed, f)]
    if state == "lit":
        post += [flame_post(-0.1, 0, 0.08, 20, seed + 1, f, "fire", 0.42, 0.5, 0.2), flame_post(0.05, 0, 0.08, 32, seed, f, "fire", 0.46, 2.4, 0.55)]
    else:
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, 0, 0.1), 36, "#e06a20", 0.3 + 0.05 * np.sin(f * 1.57)))
    return {"post": post}


# ── 마법 조명 ────────────────────────────────────────────────────────────────

@prop("magic_lamp", "light", cell=(2, 3), collide=(0.4, 0.4), tags=["magic", "crystal"], name_ko="마법 등",
    variants={"blue": {"col": "blue", "frames": 4}, "red": {"col": "red", "frames": 4}, "violet": {"col": "violet", "frames": 4}, "dead": {"col": None}},
    light={"color": GLOWC["blue"], "radius": 4.0, "at": (0, 0, 1.3), "flicker": 0.1, "variants": ["blue", "red", "violet"], "colors": {"red": GLOWC["red"], "violet": GLOWC["violet"]}})
def magic_lamp(k, col="blue", seed=1, f=0):
    k.add(lambda p: smin(smin(cyl(p, v3(0, 0, 0), 0.17, 0.05, 0.012), cap(p, v3(0, 0, 0.04), v3(0, 0, 1.0), 0.036, 0.026), 0.05), ell(p, v3(0, 0, 0.55), (0.06, 0.06, 0.07)), 0.02), "iron")
    for a in (0.4, 2.5, 4.6):   # 수정을 움켜쥔 발톱
        k.add(lambda p, a=a: smin(cap(p, v3(0, 0, 1.0), v3(np.cos(a) * 0.13, np.sin(a) * 0.11, 1.1), 0.018), cap(p, v3(np.cos(a) * 0.13, np.sin(a) * 0.11, 1.1), v3(np.cos(a) * 0.08, np.sin(a) * 0.07, 1.3), 0.016, 0.008), 0.02), "iron")
    z = 1.3 + (0.015 * np.sin(f * 1.57) if col else -0.02)
    mat = {"blue": "crystal_b", "red": "crystal_r", "violet": "crystal_v", None: "stone_d"}[col]
    k.add(lambda p: octa(p, v3(0, 0, z), 0.115, 0.24), mat)
    if not col:
        return {}
    c = GLOWC[col]
    pulse = 0.5 + 0.08 * np.sin(f * 1.57)
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(fx.halo(img, *vw.px(0, 0, z), 10, c, 0.8), *vw.px(0, 0, z), 52, c, pulse), [vw.px(-0.03, -0.1, z + 0.08 - 0.03 * f), vw.px(0.05, -0.1, z - 0.06 + 0.02 * f)])]}


def _groove(c, m, on=None, pulse=1.0, glow=5.0):
    """새긴 홈: 어두운 골 + 아래쪽 밝은 턱. on(색)이면 골이 빛난다."""
    c.paint(np.roll(np.roll(m, 2, 0), 1, 1), "#8a867a", 0.35)
    c.paint(m, "#14100e", 0.85)
    if on:
        c.graded = False
        c.glow(m, on, glow, 0.85 * pulse)
        c.add(m, hexc(on) * 0.9, 0.95)
        c.add(np.clip(m * 2.4 - 1.4, 0, 1), hexc(on) * 0.4 + 0.6, 0.55 + 0.4 * pulse)


@flat("glow_rune", "light", cell=(64, 64), tags=["magic", "rune"], name_ko="빛나는 룬",
    variants=dict([("%s_off" % g, {"gid": i}) for i, g in enumerate("abcd")] + [("%s_blue" % g, {"gid": i, "col": "blue", "frames": 4}) for i, g in enumerate("abcd")] + [("a_red", {"gid": 0, "col": "red", "frames": 4}), ("c_red", {"gid": 2, "col": "red", "frames": 4})]),
    light={"color": GLOWC["blue"], "radius": 1.6, "at": (0, 0, 0.05), "flicker": 0.1, "variants": ["a_blue", "b_blue", "c_blue", "d_blue", "a_red", "c_red"], "colors": {"a_red": GLOWC["red"], "c_red": GLOWC["red"]}})
def glow_rune(c, gid=0, col=None, f=0):
    m = np.maximum(cglyph(c, 32, 32, 30, gid * 3 + 1, 3.0), c.ring(32, 32, 24, 1.6) * (c.noise(6, 40 + gid) > 0.3))
    _groove(c, m, GLOWC[col] if col else None, 0.75 + 0.25 * np.sin(f * 1.57))


@flat("glow_crack", "light", cell=(144, 96), tags=["magic", "rift"], name_ko="빛나는 균열",
    variants={"blue": {"col": "blue", "frames": 4}, "red": {"col": "red", "frames": 4}, "dead": {"col": None}, "blue_b": {"col": "blue", "frames": 4, "seed": 77}, "dead_b": {"col": None, "seed": 77}},
    light={"color": GLOWC["blue"], "radius": 2.2, "at": (0, 0, 0.05), "flicker": 0.2, "variants": ["blue", "red", "blue_b"], "colors": {"red": GLOWC["red"]}})
def glow_crack(c, col="blue", f=0, seed=1):
    c.rng = np.random.default_rng(seed)
    m = c.cracks([(72, 48, a + c.rng.uniform(-0.3, 0.3), ln) for a, ln in ((0.1, 56), (3.2, 58), (1.9, 26), (4.6, 24))], 4.6)
    wide = np.clip(m * 1.0, 0, 1)
    c.paint(np.roll(wide, 2, 0), "#8a867a", 0.3)
    c.paint(wide, "#0e0b0a", 0.9)
    if col:
        c.graded = False
        pulse = 0.72 + 0.28 * np.sin(f * 1.57)
        c.glow(m, GLOWC[col], 8.0, 0.9 * pulse)
        c.add(m, hexc(GLOWC[col]) * 0.9, 0.95)
        c.add(np.clip(m * 2.4 - 1.4, 0, 1), hexc(GLOWC[col]) * 0.4 + 0.6, 0.5 + 0.45 * pulse)


@flat("wall_rune", "light", layer="wall_decal", cell=(128, 40), tags=["magic", "rune", "ruin"], name_ko="벽 룬 글줄",
    variants={"off": {}, "blue": {"col": "blue", "frames": 4}, "red": {"col": "red", "frames": 4}, "off_b": {"seed": 5}, "blue_b": {"col": "blue", "frames": 4, "seed": 5}},
    light={"color": GLOWC["blue"], "radius": 2.0, "at": (0, 0, 1.4), "flicker": 0.1, "variants": ["blue", "red", "blue_b"], "colors": {"red": GLOWC["red"]}})
def wall_rune(c, col=None, f=0, seed=1):
    m = np.zeros((c.H, c.W), F)
    for i in range(6):
        m = np.maximum(m, cglyph(c, 16 + i * 19.2, 20, 20, seed * 11 + i, 2.2))
    _groove(c, m, GLOWC[col] if col else None, 0.75 + 0.25 * np.sin(f * 1.57 + 0.5), 4.0)
