"""도시 거리 살림 · 장식 1(도시 라이브러리 AM69 — 묶음 그림 city_life): 수레 · 손수레 · 좌판 · 차양 천막 · 벽 차양 · 청과 상자 ·
깃대 · 벽 깃발 · 세로 현수막 · 줄 깃발 · 돌출 간판 · 세움 간판 · 빨랫줄(말뚝 · 골목 위).
간판 그림은 글자 없이 물건 모양만(모루 = 대장간 · 잔 = 여관 · 주머니 = 상점 · 저울 = 은행 · 책 = 도서관 · 방패 = 길드). 깃발 무늬는 띠 · 갈매기 · 네 쪽 나눔 같은 중립 도안만.
나무통 · 상자 · 자루 · 바구니 · 긴 의자 · 덤불은 이미 있는 것을 쓴다(a_furniture · a_flora)."""
import numpy as np

import mats as M
import sdf
from a_furniture import _X, _barrel, _crate, _frustum, _move, _planks, _sack
from kit import (F, box, cap, chip, cone, cyl, ell, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401

PI = np.pi
SHEET = {"sheet": "city_life"}
RED, BLUE, GREEN, CREAM, OCHRE = "#6e302a", "#34425a", "#3e4a36", "#a69c82", "#8a7440"


def _p(id, name, cell, variants=None, layer="stand", **kw):
    kw["meta"] = dict(SHEET, **kw.get("meta", {}))
    return prop(id, "city", layer=layer, cell=cell, variants=variants, name_ko=name, **kw)


# ── 부품 ─────────────────────────────────────────────────────────────────────

def _wheel(t, c, R, th=0.035, spokes=4):
    """세운 바퀴(화면을 마주 본다): 테 · 살 · 바퀴통."""
    c = np.asarray(c, F)
    t.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0] - c[0], p[:, 2] - c[2]) - R + 0.035) - 0.035, np.abs(p[:, 1] - c[1]) - th), "wood_d")
    dirs = [v3(np.cos(i * PI / spokes), 0, np.sin(i * PI / spokes)) for i in range(spokes)]
    t.add(lambda p: np.minimum.reduce([hcyl(p, c - d * (R - 0.04), c + d * (R - 0.04), 0.02) for d in dirs]), "wood")
    t.add(lambda p: np.maximum(np.hypot(p[:, 0] - c[0], p[:, 2] - c[2]) - R * 0.2, np.abs(p[:, 1] - c[1]) - th * 1.5), "iron")


def _stripes(k, name, a, b, w=0.2, axis=0, seed=1):
    """줄무늬 천."""
    ca, cb = M.hexc(a), M.hexc(b)

    def fn(p, n):
        s = np.floor(p[:, axis] / w + 0.5) % 2
        c = np.where(s[:, None] > 0, ca[None, :], cb[None, :]) * (0.82 + sdf.fbm(p, 0.16, seed, 2)[:, None] * 0.36)
        return np.clip(c, 0, 1).astype(F), s.astype(F), np.zeros(len(p), F)
    return k.mat(name, fn)


def _heraldry(k, name, pat, a, b, uv, seed=1):
    """깃발 무늬(글자 · 상징 없음): uv(p) → (깃대 쪽 0 → 끝 1, 아래 0 → 위 1)."""
    ca, cb = M.hexc(a), M.hexc(b)

    def fn(p, n):
        u, v = uv(p)
        if pat == "stripes":
            s = np.floor(v * 3.0) % 2
        elif pat == "chevron":
            s = ((u * 1.4 + np.abs(v - 0.5) * 1.3) % 0.56 < 0.28)
        elif pat == "quartered":
            s = (u > 0.5) ^ (v > 0.5)
        elif pat == "border":
            s = np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v) * 1.4) < 0.13
        else:
            s = u < -1
        s = np.asarray(s, F)
        c = np.where(s[:, None] > 0, ca[None, :], cb[None, :]) * (0.8 + sdf.fbm(p, 0.14, seed, 2)[:, None] * 0.4)
        return np.clip(c, 0, 1).astype(F), s, np.zeros(len(p), F)
    return k.mat(name, fn)


def _hang(t, cx, y, ztop, w, h, mat, seed=1, wave=0.022):
    """줄에 널린 천 한 장(아래로 갈수록 물결친다)."""
    def fn(p):
        q = p.copy()
        q[:, 1] = q[:, 1] + np.sin(p[:, 0] * 15.0 + seed) * wave * np.clip((ztop - p[:, 2]) / h, 0, 1)
        return box(q, v3(cx, y, ztop - h / 2), (w / 2, 0.012, h / 2), 0.008)
    t.add(fn, mat)


def _rope(t, a, b, sag, r=0.012, n=8, mat="rope"):
    """늘어진 줄(a → b, 가운데가 sag만큼 처진다) → 줄 높이 함수 z(x)."""
    a, b = np.asarray(a, F), np.asarray(b, F)
    pts = [a + (b - a) * (i / n) - v3(0, 0, sag * (1 - (2 * i / n - 1) ** 2)) for i in range(n + 1)]
    t.add(lambda p: np.minimum.reduce([cap(p, pts[i], pts[i + 1], r) for i in range(n)]), mat)
    return lambda x: float(a[2] + (b[2] - a[2]) * (x - a[0]) / (b[0] - a[0]) - sag * (1 - (2 * (x - a[0]) / (b[0] - a[0]) - 1) ** 2))


def _b2(x, z, cx, cz, hw, hh):
    return np.maximum(np.abs(x - cx) - hw, np.abs(z - cz) - hh)


def _c2(x, z, cx, cz, r):
    return np.hypot(x - cx, z - cz) - r


def _pict(kind):
    """간판 그림(2D 거리 함수 — 판 가운데 기준, 반 크기 약 0.15)."""
    if kind == "smithy":      # 모루
        return lambda x, z: np.minimum.reduce([_b2(x, z, 0.01, 0.055, 0.12, 0.032), _b2(x, z, -0.13, 0.062, 0.045, 0.016), _b2(x, z, 0.01, 0.0, 0.045, 0.04), _b2(x, z, 0.01, -0.07, 0.1, 0.028)])
    if kind == "inn":         # 거품 인 잔
        return lambda x, z: np.minimum.reduce([_b2(x, z, -0.02, -0.02, 0.07, 0.09), np.maximum(np.abs(_c2(x, z, 0.06, -0.02, 0.055)) - 0.016, 0.05 - x),
            _c2(x, z, -0.07, 0.085, 0.036), _c2(x, z, -0.015, 0.1, 0.042), _c2(x, z, 0.035, 0.085, 0.032)])
    if kind == "shop":        # 묶은 주머니
        return lambda x, z: np.minimum.reduce([_c2(x, z, 0.0, -0.035, 0.1), _b2(x, z, 0.0, 0.07, 0.03, 0.03), _b2(x, z, 0.0, 0.11, 0.065, 0.016)])
    if kind == "bank":        # 저울
        return lambda x, z: np.minimum.reduce([_b2(x, z, 0, -0.01, 0.013, 0.11), _b2(x, z, 0, 0.1, 0.13, 0.013), _b2(x, z, 0, -0.12, 0.06, 0.014),
            np.maximum(_c2(x, z, -0.11, 0.03, 0.055), z - 0.02), np.maximum(_c2(x, z, 0.11, 0.03, 0.055), z - 0.02)])
    if kind == "library":     # 펼친 책
        return lambda x, z: np.maximum(np.maximum(np.abs(x) - 0.135, np.abs(z - np.abs(x) * 0.28 + 0.02) - 0.085), 0.01 - np.abs(x))
    if kind == "guild":       # 방패
        return lambda x, z: np.maximum.reduce([_c2(x, z, -0.07, 0.035, 0.18), _c2(x, z, 0.07, 0.035, 0.18), z - 0.115])
    return None


def _board(t, c, kind, hw=0.25, hh=0.2, paint="wax", seed=1, frame="wood_d"):
    """간판 판(화면을 마주 본다) + 앞면 그림."""
    c = np.asarray(c, F)
    t.add(rough(lambda p: box(p, c, (hw, 0.022, hh), 0.012), 0.008, 0.2, seed), "plank_x")
    t.add(lambda p: np.maximum(np.maximum(np.abs(p[:, 0] - c[0]) - hw - 0.012, np.abs(p[:, 2] - c[2]) - hh - 0.012),
        np.maximum(np.abs(p[:, 1] - c[1]) - 0.03, -np.maximum(np.abs(p[:, 0] - c[0]) - hw + 0.03, np.abs(p[:, 2] - c[2]) - hh + 0.03))), frame)
    f = _pict(kind)
    if f is not None:
        t.add(lambda p: np.maximum(f(p[:, 0] - c[0], p[:, 2] - c[2]), np.abs(p[:, 1] - c[1] + 0.024) - 0.01), paint)


def _goods_mats(k):
    for name, fn in {"apple": M.plain("#8a3a2c", 0.3, 0.05, 31), "green": M.leaf("#4a6a34", 0.1, 32, 0.08), "root": M.plain("#a89a80", 0.25, 0.05, 33), "carrot": M.plain("#a05a2a", 0.25, 0.05, 34),
            "clay": M.plain("#8a5a40", 0.3, 0.1, 35), "clay_d": M.plain("#5e4638", 0.3, 0.1, 36), "fish": M.metal("#7c8288", "#4a5a66", 37, 0.3), "bread": M.plain("#9a7240", 0.35, 0.05, 38),
            "hay": M.thatch("#8a7440", 0.07, 39)}.items():
        k.mat(name, fn)


def _heap(t, c, n, r, mats, rx=0.18, ry=0.12, seed=1, flat=1.0):
    """둥근 것 여러 알을 수북이(사과 · 순무 · 양배추)."""
    rng = np.random.default_rng(seed)
    for i in range(n):
        a, d = rng.uniform(0, 2 * PI), rng.uniform(0, 1) ** 0.6
        q = v3(c[0] + np.cos(a) * rx * d, c[1] + np.sin(a) * ry * d, c[2] + r * 0.8 + (1 - d) * r * 1.1)
        t.add(lambda p, q=q: ell(p, q, (r, r, r * flat)), mats[i % len(mats)])


# ── 수레 · 손수레 ────────────────────────────────────────────────────────────

@_p("cart", "짐수레", (5, 4), {"empty": {}, "sacks": {"load": "sacks"}, "barrels": {"load": "barrels"}, "hay": {"load": "hay"}, "broken": {"broken": True}},
    collide=(1.9, 0.9), tags=["wood", "vehicle", "street", "market"], interact="container")
def cart(k, load=None, broken=False, seed=1):
    """두 바퀴 짐수레(끌채는 왼쪽). broken = 앞바퀴가 빠져 기울었다."""
    _goods_mats(k)
    zb, R = 0.62, 0.4
    t = _X(k, (lambda p: rot_x(p, -0.36, (0, 0.47, 0.02))) if broken else (lambda p: p))
    t.add(rough(lambda p: box(p, v3(0, 0, zb), (0.9, 0.4, 0.03), 0.008), 0.01, 0.2, seed), "plank_x")
    t.add(lambda p: np.minimum.reduce([box(p, v3(0, sy * 0.4, zb + h), (0.9, 0.018, 0.045), 0.006) for sy in (-1, 1) for h in (0.1, 0.24)]), "plank_xd")
    t.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.86, sy * 0.4, zb + 0.15), (0.03, 0.03, 0.16), 0.006) for sx in (-1, 0, 1) for sy in (-1, 1)]
        + [box(p, v3(sx * 0.9, 0, zb + 0.13), (0.018, 0.4, 0.13), 0.006) for sx in (-1, 1)]), "wood_d")
    t.add(lambda p: hcyl(p, v3(0.05, -0.5, R), v3(0.05, 0.5, R), 0.035), "wood_d")
    t.add(lambda p: np.minimum.reduce([box(p, v3(0.05, sy * 0.3, (zb + R) / 2), (0.05, 0.03, (zb - R) / 2)) for sy in (-1, 1)]), "wood_d")
    t.add(lambda p: np.minimum.reduce([cap(p, v3(-0.88, sy * 0.3, zb - 0.02), v3(-1.72, sy * 0.3, 0.2 if not broken else 0.3), 0.032, 0.026) for sy in (-1, 1)]
        + [cap(p, v3(-1.6, -0.3, 0.27), v3(-1.6, 0.3, 0.27), 0.022)]), "wood")
    if not broken:
        t.add(lambda p: cap(p, v3(-0.82, 0, zb), v3(-0.9, 0, 0.0), 0.03), "wood_d")
        _wheel(t, v3(0.05, -0.47, R), R)
    else:
        w = _X(k, lambda p: rot_x(p - v3(0.55, -1.0, 0.045), PI / 2))
        _wheel(w, v3(0, 0, 0), R)
        _planks(k, [(-0.5, -0.95, 0.3), (1.15, -0.7, -0.6)], "plank_x", 0.16, seed)
    _wheel(t, v3(0.05, 0.47, R), R)
    z = zb + 0.03
    if load == "sacks":
        _sack(_move(k, -0.5, 0.05, z), v3(0, 0, 0), 1.0, seed)
        _sack(_move(k, -0.08, -0.05, z), v3(0, 0, 0), 0.95, seed + 1, "linen")
        _sack(_move(k, 0.36, 0.08, z), v3(0, 0, 0), 1.0, seed + 2)
        k.add(rough(lambda p: ell(p, v3(0.62, -0.08, z + 0.1), (0.24, 0.17, 0.12)) + np.sin(p[:, 0] * 22.0) * 0.005, 0.03, 0.1, seed), "cloth")
    elif load == "barrels":
        _barrel(_move(k, -0.52, 0.02, z), 0.2, 0.56, seed)
        _barrel(_move(k, -0.05, -0.02, z), 0.2, 0.56, seed + 1)
        _crate(_move(k, 0.52, 0.0, z, 0.1), 0.22, seed)
    elif load == "hay":
        k.add(rough(lambda p: np.maximum(smin(ell(p, v3(0, 0, z + 0.22), (0.92, 0.42, 0.42)), ell(p, v3(0.3, 0, z + 0.5), (0.5, 0.32, 0.26)), 0.15), z - 0.02 - p[:, 2]), 0.12, 0.08, seed), "hay")
        k.add(lambda p: cap(p, v3(-0.35, -0.1, z + 0.5), v3(-0.75, -0.25, z + 1.15), 0.016), "wood_l")
    if broken:
        _sack(k, v3(-0.7, -0.75, 0), 0.9, seed, "cloth", 0.0)
    return {"dx": 0.4, "foot": 0.95}


@_p("handcart", "손수레", (4, 3), {"empty": {}, "loaded": {"load": True}, "tipped": {"tipped": True}}, collide=(1.1, 0.7), tags=["wood", "vehicle", "street", "market"], interact="container")
def handcart(k, load=False, tipped=False, seed=1):
    """한 사람이 미는 수레(손잡이는 오른쪽). tipped = 앞으로 고꾸라져 짐을 쏟았다."""
    R = 0.25
    t = _X(k, (lambda p: rot_y(p, 0.62, (-0.1, 0, R))) if tipped else (lambda p: p))
    tub = lambda p: sub(box(p, v3(0, 0, 0.5), (0.48, 0.3, 0.15), 0.01), box(p, v3(0, 0, 0.58), (0.44, 0.26, 0.19)))
    t.add(rough(tub, 0.01, 0.2, seed), "plank_x")
    t.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.3, -0.31, 0.5), (0.025, 0.012, 0.15)) for sx in (-1, 0, 1)]), "wood_d")
    t.add(lambda p: hcyl(p, v3(-0.1, -0.38, R), v3(-0.1, 0.38, R), 0.03), "wood_d")
    t.add(lambda p: np.minimum.reduce([cap(p, v3(0.4, sy * 0.27, 0.42), v3(1.08, sy * 0.27, 0.66), 0.026, 0.022) for sy in (-1, 1)]
        + [cap(p, v3(0.36, sy * 0.27, 0.38), v3(0.4, sy * 0.27, 0.0), 0.026) for sy in (-1, 1)]), "wood")
    _wheel(t, v3(-0.1, -0.36, R), R, 0.028)
    _wheel(t, v3(-0.1, 0.36, R), R, 0.028)
    if load:
        _sack(_move(k, -0.2, 0.02, 0.37), v3(0, 0, 0), 0.85, seed)
        _crate(_move(k, 0.2, 0.0, 0.38, 0.15), 0.17, seed)
        k.add(rough(lambda p: ell(p, v3(-0.02, -0.14, 0.68), (0.2, 0.1, 0.07)), 0.03, 0.1, seed), "linen")
    if tipped:
        _sack(k, v3(-0.95, -0.2, 0), 0.9, seed, "cloth", 0.0)
        k.add(rough(lambda p: ell(p, v3(-0.75, 0.2, 0.09), (0.26, 0.17, 0.11)) + np.sin(p[:, 0] * 22.0) * 0.005, 0.03, 0.1, seed), "linen")
        _crate(_move(k, -1.25, 0.15, 0, 0.5), 0.16, seed)
    return {"dx": 0.35 if tipped else -0.15}


# ── 좌판 · 차양 ──────────────────────────────────────────────────────────────

def _canopy(t, mat, w, y0, y1, z0, z1, seed=1, torn=False, valance=0.12):
    """기운 천 지붕: 앞(y0, z0) → 뒤(y1, z1). 앞 끝에 물결 드림."""
    sl = (z1 - z0) / (y1 - y0)

    def sheet(p):
        zc = z0 + (p[:, 1] - y0) * sl - 0.07 * np.sin(np.clip((p[:, 1] - y0) / (y1 - y0), 0, 1) * PI) * (0.6 + 0.4 * np.cos(p[:, 0] / w * PI * 1.5))
        d = np.maximum.reduce([np.abs(p[:, 0]) - w, y0 - p[:, 1], p[:, 1] - y1, np.abs(p[:, 2] - zc) - 0.014])
        return d * 0.8
    val = lambda p: np.maximum.reduce([np.abs(p[:, 0]) - w, np.abs(p[:, 1] - y0) - 0.014, p[:, 2] - z0, z0 - valance * (0.65 + 0.35 * np.abs(np.sin(p[:, 0] * PI / 0.22))) - p[:, 2]])
    fn = lambda p: np.minimum(sheet(p), val(p))
    t.add(chip(fn, 0.46, 0.34, seed, 0.1) if torn else fn, mat)


def _stall_goods(k, goods, z, seed):
    _goods_mats(k)
    if goods == "produce":
        for x, ms, r in ((-0.52, ["apple"], 0.05), (0.0, ["green"], 0.075), (0.52, ["root", "carrot"], 0.045)):
            k.add(lambda p, x=x: sub(box(p, v3(x, -0.02, z + 0.05), (0.22, 0.2, 0.05), 0.006), box(p, v3(x, -0.02, z + 0.08), (0.2, 0.18, 0.06))), "plank_y")
            _heap(k, v3(x, -0.02, z + 0.02), 11 if r < 0.07 else 6, r, ms, 0.15, 0.13, seed + int(x * 10))
    elif goods == "bread":
        k.add(lambda p: box(p, v3(0, 0, z + 0.006), (0.74, 0.24, 0.006)), "linen")
        rng = np.random.default_rng(seed)
        for i in range(8):
            x, y, a = -0.6 + i * 0.17 + rng.uniform(-0.02, 0.02), rng.uniform(-0.12, 0.1), rng.uniform(-0.5, 0.5)
            if i % 3 == 2:
                k.add(lambda p, x=x, y=y: ell(p, v3(x, y, z + 0.05), (0.085, 0.085, 0.05)), "bread")
            else:
                k.add(lambda p, x=x, y=y, a=a: ell(rot_z(p, a, (x, y, 0)), v3(x, y, z + 0.045), (0.12, 0.055, 0.045)), "bread")
        k.add(lambda p: sub(_frustum(p, v3(0.6, 0.05, z), 0.1, 0.14, 0.1), _frustum(p, v3(0.6, 0.05, z + 0.03), 0.08, 0.12, 0.1)), "rope")
        _heap(k, v3(0.6, 0.05, z + 0.03), 4, 0.05, ["bread"], 0.06, 0.06, seed)
    elif goods == "cloth":
        for i, (x, m) in enumerate(((-0.55, "cloth_r"), (-0.38, "cloth_b"), (-0.21, "linen"), (-0.04, "cloth_g"))):
            k.add(rough(lambda p, x=x: hcyl(p, v3(x, -0.2, z + 0.07), v3(x, 0.2, z + 0.07), 0.07), 0.01, 0.1, seed + i), m)
        k.add(rough(lambda p: hcyl(p, v3(-0.46, -0.2, z + 0.19), v3(-0.46, 0.2, z + 0.19), 0.065), 0.01, 0.1, seed), "cloth")
        for i, m in enumerate(("linen", "cloth_b", "cloth_r", "cloth")):
            k.add(lambda p, i=i: box(p, v3(0.42, 0.0, z + 0.025 + i * 0.045), (0.2 - i * 0.012, 0.17, 0.02), 0.012), m)
        k.add(lambda p: box(rot_x(p, 0.15, (0, -0.3, z)), v3(0.05, -0.28, z - 0.12), (0.16, 0.012, 0.16), 0.008), "cloth_g")
    elif goods == "pottery":
        for i, (x, y, s, m) in enumerate(((-0.55, 0.0, 1.0, "clay"), (-0.25, -0.05, 0.75, "clay_d"), (0.02, 0.05, 1.15, "clay"), (0.32, -0.04, 0.7, "clay"), (0.56, 0.04, 0.9, "clay_d"))):
            k.add(lambda p, x=x, y=y, s=s: smin(ell(p, v3(x, y, z + 0.1 * s), (0.095 * s, 0.095 * s, 0.11 * s)), sub(cyl(p, v3(x, y, z + 0.17 * s), 0.055 * s, 0.07 * s, 0.01), cyl(p, v3(x, y, z + 0.2 * s), 0.04 * s, 0.1)), 0.02), m)
        for x in (-0.4, 0.18, 0.44):
            k.add(lambda p, x=x: sub(_frustum(p, v3(x, -0.2, z), 0.04, 0.075, 0.04), _frustum(p, v3(x, -0.2, z + 0.012), 0.03, 0.065, 0.04)), "clay")
    elif goods == "fish":
        k.add(lambda p: box(p, v3(0, 0, z + 0.02), (0.72, 0.24, 0.02), 0.01), "stone_l")
        rng = np.random.default_rng(seed)
        for i in range(7):
            x, y, a = -0.58 + i * 0.19, rng.uniform(-0.08, 0.08), rng.uniform(-0.25, 0.25) + PI / 2
            T = lambda p, x=x, y=y, a=a: rot_z(p, a, (x, y, 0))
            k.add(lambda p, x=x, y=y, T=T: np.minimum(ell(T(p), v3(x, y, z + 0.06), (0.15, 0.045, 0.028)), np.maximum(np.abs(T(p)[:, 1] - y) - (T(p)[:, 0] - x - 0.12) * 0.9, np.maximum(np.abs(T(p)[:, 0] - x - 0.17) - 0.05, np.abs(T(p)[:, 2] - z - 0.055) - 0.008))), "fish")
        k.add(lambda p: sub(cyl(p, v3(0.0, -0.75, 0.0), 0.16, 0.24, 0.01), cyl(p, v3(0.0, -0.75, 0.05), 0.14, 0.3)), "wood")


@_p("market_stall", "시장 좌판", (4, 5), {"produce": {"goods": "produce"}, "bread": {"goods": "bread", "col": "ochre"}, "cloth": {"goods": "cloth", "col": "blue"}, "pottery": {"goods": "pottery", "col": "green"},
    "fish": {"goods": "fish", "col": "blue"}, "empty": {"goods": None, "col": "plain"}, "wrecked": {"goods": None, "wrecked": True}}, collide=(1.7, 0.8), tags=["wood", "cloth", "market", "street"], interact="shop")
def market_stall(k, goods="produce", col="red", wrecked=False, seed=1):
    """지붕 천을 친 좌판(물건마다 다른 진열)."""
    cloth = {"red": _stripes(k, "awn", RED, CREAM, 0.2, 0, seed), "blue": _stripes(k, "awn", BLUE, CREAM, 0.2, 0, seed), "green": _stripes(k, "awn", GREEN, CREAM, 0.2, 0, seed),
        "ochre": _stripes(k, "awn", OCHRE, CREAM, 0.2, 0, seed), "plain": "linen"}[col]
    w, d, h = 0.82, 0.3, 0.62
    if wrecked:      # 기둥이 꺾이고 천이 내려앉았다
        t = _X(k, lambda p: rot_y(p, 0.2, (0.8, 0, 0)))
        t.add(rough(lambda p: np.maximum(box(p, v3(0, 0, h - 0.03), (w, d, 0.03), 0.01), -(p[:, 0] + 0.5 + sdf.noise(p, 0.08, seed) * 0.1)), 0.012, 0.2, seed), "plank_x")
        t.add(lambda p: np.minimum.reduce([box(p, v3(w - 0.06, sy * (d - 0.05), (h - 0.06) / 2), (0.04, 0.04, (h - 0.06) / 2)) for sy in (-1, 1)]), "wood_d")
        k.add(lambda p: np.minimum.reduce([cap(p, v3(0.8, 0.3, 0), v3(0.86, 0.3, 1.1), 0.035), cap(p, v3(-0.9, -0.55, 0.04), v3(0.3, -0.75, 0.04), 0.035), cap(p, v3(-0.8, 0.3, 0.0), v3(-0.75, 0.25, 0.5), 0.035)]), "wood_d")
        k.add(chip(rough(lambda p: np.maximum(smin(ell(p, v3(-0.35, -0.15, 0.0), (0.85, 0.6, 0.2)), cap(p, v3(0.1, 0.2, 0.3), v3(0.84, 0.3, 1.05), 0.12, 0.03), 0.25), -p[:, 2]), 0.1, 0.2, seed), 0.38, 0.3, seed, 0.08), cloth)
        _planks(k, [(0.35, -0.95, 0.4), (-1.1, 0.1, -0.5), (1.1, -0.6, 1.2)], "plank_x", 0.17, seed)
        return {"cell": (4, 4)}
    k.add(rough(lambda p: box(p, v3(0, 0, h - 0.03), (w, d, 0.03), 0.01), 0.012, 0.2, seed), "plank_x")
    k.add(lambda p: np.minimum.reduce([box(p, v3(sx * (w - 0.06), sy * (d - 0.05), (h - 0.06) / 2), (0.04, 0.04, (h - 0.06) / 2)) for sx in (-1, 1) for sy in (-1, 1)]), "wood_d")
    k.add(lambda p: box(p, v3(0, -d + 0.03, h - 0.2), (w - 0.1, 0.012, 0.14) , 0.006) + np.sin(p[:, 0] * 30.0) * 0.004, "cloth" if goods != "cloth" else "cloth_k")   # 앞 가림 천
    k.add(lambda p: np.minimum.reduce([cap(p, v3(sx * (w + 0.02), -d - 0.12, 0), v3(sx * (w + 0.02), -d - 0.12, 1.5), 0.03) for sx in (-1, 1)]
        + [cap(p, v3(sx * (w + 0.02), d + 0.1, 0), v3(sx * (w + 0.02), d + 0.1, 1.86), 0.03) for sx in (-1, 1)]
        + [cap(p, v3(-w - 0.02, y, z), v3(w + 0.02, y, z), 0.022) for y, z in ((-d - 0.12, 1.5), (d + 0.1, 1.86))]), "wood_d")
    _canopy(k, cloth, w + 0.12, -d - 0.24, d + 0.14, 1.5, 1.9, seed)
    if goods:
        _stall_goods(k, goods, h, seed)
    return {}


@_p("market_awning", "차양 천막", (5, 5), {"striped": {}, "plain": {"col": "plain"}, "torn": {"col": "plain", "torn": True}},
    collide=[(-1.25, -0.6, 0.2, 0.2), (1.05, -0.6, 0.2, 0.2), (-1.25, 0.4, 0.2, 0.2), (1.05, 0.4, 0.2, 0.2)], tags=["cloth", "market", "street", "shelter"],
    meta={"cover": True, "note": "기둥 넷만 막는다 — 아래에 탁자 · 상자를 놓아 가게 자리로 쓴다"})
def market_awning(k, col="striped", torn=False, seed=1):
    """기둥 넷에 친 넓은 천 지붕(밑은 비어 있다)."""
    cloth = _stripes(k, "awn", RED, CREAM, 0.26, 0, seed) if col == "striped" else "linen"
    posts = [(sx * 1.15, y, z) for sx in (-1, 1) for y, z in ((-0.5, 1.55), (0.5, 1.95))]
    k.add(lambda p: np.minimum.reduce([cap(p, v3(x, y, 0), v3(x, y, z), 0.035) for x, y, z in posts]
        + [cap(p, v3(-1.15, y, z), v3(1.15, y, z), 0.024) for y, z in ((-0.5, 1.55), (0.5, 1.95))]), "wood_d")
    k.add(lambda p: np.minimum.reduce([cap(p, v3(sx * 1.15, -0.5, 1.5), v3(sx * 1.5, -0.85, 0.0), 0.012) for sx in (-1, 1)]), "rope")
    _canopy(k, cloth, 1.3, -0.64, 0.56, 1.55, 2.0, seed, torn, 0.14)
    if torn:
        k.add(rough(lambda p: pool(p, v3(0.5, -0.3, 0.012), 0.3, 0.16, 0.012), 0.03, 0.1, seed), "linen")
    return {"foot": 1.1}


@_p("wall_awning", "벽 차양", (4, 4), {"striped": {}, "plain": {"col": "plain"}, "torn": {"col": "green", "torn": True}}, layer="wall_decal", tags=["cloth", "shop", "street", "wall"],
    meta={"note": "가게 문 · 창 위 벽에 붙인다(원점 = 벽 밑동)"})
def wall_awning(k, col="striped", torn=False, seed=1):
    cloth = {"striped": _stripes(k, "awn", RED, CREAM, 0.2, 0, seed), "green": _stripes(k, "awn", GREEN, CREAM, 0.2, 0, seed), "plain": "cloth"}[col]
    _canopy(k, cloth, 0.95, -0.75, 0.02, 1.62, 2.1, seed, torn, 0.13)
    k.add(lambda p: np.minimum.reduce([cap(p, v3(sx * 0.93, 0.02, 1.7), v3(sx * 0.93, -0.74, 1.63), 0.016) for sx in (-1, 1)]
        + [cap(p, v3(-0.95, -0.75, 1.62), v3(0.95, -0.75, 1.62), 0.016), box(p, v3(0, 0.03, 2.12), (0.97, 0.02, 0.03))]), "iron")
    return {"shadow": 0.0}


@_p("produce_crate", "청과 상자", (2, 2), {"apples": {}, "greens": {"kind": "greens"}, "roots": {"kind": "roots"}, "stack": {"kind": "stack"}}, collide=(0.6, 0.45), tags=["wood", "market", "food", "storage"])
def produce_crate(k, kind="apples", seed=1):
    """과일 · 채소가 담긴 얕은 상자."""
    _goods_mats(k)

    def tray(t, fill, r, n):
        t.add(rough(lambda p: sub(box(p, v3(0, 0, 0.09), (0.28, 0.2, 0.09), 0.006), box(p, v3(0, 0, 0.13), (0.255, 0.175, 0.1))), 0.008, 0.2, seed), "plank_x")
        t.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.27, -0.2, 0.09), (0.02, 0.008, 0.09)) for sx in (-1, 1)]), "wood_d")
        if fill:
            _heap(t, v3(0, 0, 0.06), n, r, fill, 0.2, 0.13, seed + n)
    if kind == "stack":
        tray(_move(k, 0.0, 0.05, 0.0), ["root", "carrot"], 0.045, 10)
        tray(_move(k, 0.03, 0.05, 0.19, 0.08), ["apple"], 0.05, 12)
        k.add(rough(lambda p: box(rot_x(p, -1.05, (0, -0.32, 0)), v3(-0.2, -0.32, 0.2), (0.26, 0.19, 0.014), 0.006), 0.008, 0.2, seed), "plank_x")
        return {"cell": (2, 3)}
    fill, r, n = {"apples": (["apple"], 0.05, 13), "greens": (["green"], 0.085, 6), "roots": (["root", "carrot", "root"], 0.045, 13)}[kind]
    tray(k, fill, r, n)
    return {}


# ── 깃발 · 현수막 · 줄 깃발 ──────────────────────────────────────────────────

_FLAGS = {"stripes": ("stripes", RED, CREAM), "chevron": ("chevron", BLUE, CREAM), "quartered": ("quartered", GREEN, OCHRE)}


def _wave_sheet(x0, L, z0, H, amp=0.05, seed=1):
    def fn(p):
        q = p.copy()
        q[:, 1] = q[:, 1] + np.sin((p[:, 0] - x0) * 9.0 + seed) * amp * np.clip((p[:, 0] - x0) / L, 0, 1)
        q[:, 2] = q[:, 2] + np.clip((p[:, 0] - x0) / L, 0, 1) ** 2 * 0.12       # 끝이 조금 처진다
        return box(q, v3(x0 + L / 2, 0, z0 + H / 2), (L / 2, 0.012, H / 2), 0.006) * 0.8
    return fn


@_p("flag_pole", "깃대", (4, 6), {"stripes": {}, "chevron": {"pat": "chevron"}, "quartered": {"pat": "quartered"}, "tattered": {"pat": "stripes", "torn": True}, "bare": {"pat": None}},
    collide=(0.4, 0.35), tags=["cloth", "plaza", "street", "landmark"])
def flag_pole(k, pat="stripes", torn=False, seed=1):
    """돌 받침에 세운 깃대와 깃발."""
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.1), (0.22, 0.2, 0.1), 0.02), box(p, v3(0, 0, 0.26), (0.14, 0.13, 0.07), 0.02)), 0.015, 0.2, seed), "stone")
    k.add(lambda p: cap(p, v3(0, 0, 0.2), v3(0, 0, 3.6), 0.04, 0.028), "wood_d")
    k.add(lambda p: sphere(p, v3(0, 0, 3.64), 0.055), "brass")
    if pat:
        x0, L, z0, H = 0.04, 1.2, 2.72, 0.8
        m = _heraldry(k, "flag", *_FLAGS[pat], lambda p: ((p[:, 0] - x0) / L, (p[:, 2] + np.clip((p[:, 0] - x0) / L, 0, 1) ** 2 * 0.12 - z0) / H), seed)
        fn = _wave_sheet(x0, L, z0, H, 0.05, seed)
        if torn:
            fn0 = fn
            fn = lambda p: np.maximum(fn0(p), (0.42 + np.clip((p[:, 0] - x0) / L, 0, 1) * 0.3 - sdf.fbm(p, 0.22, seed, 3)) * 0.4 - 0.1)
        k.add(fn, m)
    else:
        k.add(lambda p: cap(p, v3(0.04, 0, 3.5), v3(0.06, -0.02, 2.5), 0.008), "rope")
    return {"dx": -0.55, "shadow": 0.4}


@_p("wall_flag", "벽 깃발", (3, 4), {"stripes": {}, "chevron": {"pat": "chevron"}, "tattered": {"pat": "quartered", "torn": True}}, layer="wall_decal", tags=["cloth", "wall", "street"],
    meta={"note": "벽에서 비스듬히 내민 깃대(원점 = 벽 밑동)"})
def wall_flag(k, pat="stripes", torn=False, seed=1):
    a, b = v3(-0.5, 0.04, 1.75), v3(0.55, -0.3, 2.35)
    k.add(lambda p: np.minimum(box(p, v3(-0.5, 0.05, 1.75), (0.07, 0.03, 0.09), 0.01), cap(p, v3(-0.5, 0.04, 1.6), v3(-0.25, -0.05, 1.86), 0.014)), "iron")
    k.add(lambda p: cap(p, a, b, 0.026, 0.02), "wood_d")
    k.add(lambda p: sphere(p, b, 0.035), "brass")
    x0, x1, H = -0.38, 0.5, 0.82
    top = lambda p: a[2] + (p[:, 0] - a[0]) / (b[0] - a[0]) * (b[2] - a[2]) - 0.02
    yl = lambda p: a[1] + (p[:, 0] - a[0]) / (b[0] - a[0]) * (b[1] - a[1])
    m = _heraldry(k, "flag", *_FLAGS[pat], lambda p: (np.clip((top(p) - p[:, 2]) / H, 0, 1), (p[:, 0] - x0) / (x1 - x0)), seed)
    fn = lambda p: np.maximum.reduce([np.abs(p[:, 0] - (x0 + x1) / 2) - (x1 - x0) / 2, np.abs(p[:, 2] - top(p) + H / 2) - H / 2,
        np.abs(p[:, 1] - yl(p) + np.sin(p[:, 0] * 14.0 + seed) * 0.03 * np.clip((top(p) - p[:, 2]) / H, 0, 1)) - 0.012]) * 0.7
    if torn:
        fn0 = fn
        fn = lambda p: np.maximum(fn0(p), (0.36 + np.clip((top(p) - p[:, 2]) / H, 0, 1) * 0.34 - sdf.fbm(p, 0.2, seed, 3)) * 0.4 - 0.1)
    k.add(fn, m)
    return {"shadow": 0.0}


@_p("banner_hanging", "세로 현수막", (2, 4), {"border": {}, "chevron": {"pat": "chevron", "col": "blue"}, "plain": {"pat": "none", "col": "green"}, "torn": {"pat": "border", "torn": True}}, layer="wall_decal",
    tags=["cloth", "wall", "street", "hall"], meta={"note": "벽에 가로대로 건 긴 천(원점 = 벽 밑동) — 실내 벽에도 쓴다"})
def banner_hanging(k, pat="border", col="red", torn=False, seed=1):
    zt, H, w = 2.25, 1.35, 0.3
    ca = {"red": RED, "blue": BLUE, "green": GREEN}[col]
    m = _heraldry(k, "flag", pat, OCHRE if pat == "border" else CREAM, ca, lambda p: ((p[:, 0] + w) / (2 * w), np.clip((zt - p[:, 2]) / H, 0, 1) * 1.0), seed)
    k.add(lambda p: np.minimum.reduce([hcyl(p, v3(-w - 0.08, -0.07, zt), v3(w + 0.08, -0.07, zt), 0.02), sphere(p, v3(-w - 0.09, -0.07, zt), 0.032), sphere(p, v3(w + 0.09, -0.07, zt), 0.032),
        cap(p, v3(-w + 0.04, 0.04, zt + 0.02), v3(-w + 0.04, -0.07, zt), 0.014), cap(p, v3(w - 0.04, 0.04, zt + 0.02), v3(w - 0.04, -0.07, zt), 0.014)]), "brass")
    fn = lambda p: np.maximum.reduce([np.abs(p[:, 0]) - w, p[:, 2] - zt, (zt - H) + (w - np.abs(p[:, 0])) * 0.55 - p[:, 2],      # 제비꼬리 끝
        np.abs(p[:, 1] + 0.07 + np.sin(p[:, 0] * 11.0 + seed) * 0.02 * np.clip((zt - p[:, 2]) / H, 0, 1)) - 0.012]) * 0.75
    if torn:
        fn0 = fn
        fn = lambda p: np.maximum(fn0(p), (0.3 + np.clip((zt - p[:, 2]) / H, 0, 1) * 0.42 - sdf.fbm(p, 0.2, seed, 3)) * 0.4 - 0.1)
    k.add(fn, m)
    return {"shadow": 0.0}


@_p("bunting", "줄 깃발", (6, 4), {"festive": {}, "sparse": {"skip": 0.4, "seed": 5}, "tattered": {"skip": 0.2, "torn": True, "seed": 9}}, layer="over", tags=["cloth", "street", "festival", "overhead"],
    meta={"note": "길 위를 가로지르는 줄(양 끝을 집 벽 · 기둥 높이에 맞춘다) — 원점 = 줄 가운데 아래 바닥"})
def bunting(k, skip=0.0, torn=False, seed=1):
    zf = _rope(k, v3(-2.7, 0, 2.55), v3(2.7, 0, 2.55), 0.4, 0.012, 12)
    rng = np.random.default_rng(seed)
    cols = ["cloth_r", "linen", "cloth_b", k.mat("pen_o", M.plain(OCHRE, 0.3, 0.12, 3)), "cloth_g"]
    for i in range(17):
        x = -2.5 + i * 0.3125
        if rng.random() < skip:
            continue
        zt, h, w = zf(x) - 0.01, 0.3 * (rng.uniform(0.5, 0.8) if torn else 1.0), 0.115
        k.add(lambda p, x=x, zt=zt, h=h, w=w: np.maximum.reduce([np.abs(p[:, 0] - x) / w + (zt - p[:, 2]) / h - 1.0, p[:, 2] - zt, np.abs(p[:, 1]) - 0.01]) * 0.07, cols[i % 5])
    return {"shadow": 0.0, "foot": 0.4}


# ── 간판 ─────────────────────────────────────────────────────────────────────

_SIGNS = {"smithy": {"kind": "smithy"}, "inn": {"kind": "inn"}, "shop": {"kind": "shop"}, "bank": {"kind": "bank"}, "library": {"kind": "library"}, "guild": {"kind": "guild"},
    "blank": {"kind": None}, "broken": {"kind": "inn", "broken": True}}


@_p("shop_sign", "돌출 간판", (2, 4), _SIGNS, layer="wall_decal", tags=["wood", "iron", "shop", "street", "wall", "sign"],
    meta={"note": "벽에 박은 쇠 까치발에 매단 그림 간판(글자 없음). 원점 = 벽 밑동, 판 아래 끝이 머리 위"})
def shop_sign(k, kind="smithy", broken=False, seed=1):
    za = 2.2
    k.add(lambda p: np.minimum.reduce([box(p, v3(-0.34, 0.05, za - 0.08), (0.04, 0.03, 0.2), 0.01), hcyl(p, v3(-0.34, -0.1, za), v3(0.36, -0.1, za), 0.02), cap(p, v3(-0.34, 0.04, za - 0.24), v3(0.1, -0.1, za - 0.02), 0.015),
        cap(p, v3(-0.34, 0.04, za), v3(-0.34, -0.1, za), 0.02), sphere(p, v3(0.38, -0.1, za), 0.032)]), "iron")
    c = v3(0.02, -0.1, za - 0.36)
    if broken:       # 한쪽 사슬이 끊겨 비스듬히 매달렸다
        t = _X(k, lambda p: rot_y(p, 0.95, (-0.2, -0.1, za - 0.12)))
        k.add(lambda p: cap(p, v3(-0.2, -0.1, za), v3(-0.2, -0.1, za - 0.12), 0.012), "iron")
        k.add(lambda p: cap(p, v3(0.24, -0.1, za), v3(0.24, -0.1, za - 0.07), 0.012), "iron")
        _board(t, c, kind, 0.25, 0.2, "wax", seed)
        return {"shadow": 0.0}
    k.add(lambda p: np.minimum(cap(p, v3(-0.2, -0.1, za), v3(-0.2, -0.1, za - 0.15), 0.012), cap(p, v3(0.24, -0.1, za), v3(0.24, -0.1, za - 0.15), 0.012)), "iron")
    _board(k, c, kind, 0.25, 0.2, "wax", seed)
    return {"shadow": 0.0}


@_p("sign_aframe", "세움 간판", (2, 2), {"inn": {"kind": "inn"}, "shop": {"kind": "shop"}, "blank": {"kind": None}, "fallen": {"kind": "shop", "fallen": True}}, collide=(0.5, 0.35), tags=["wood", "shop", "street", "sign"])
def sign_aframe(k, kind="inn", fallen=False, seed=1):
    """가게 앞 길에 세우는 맞배 간판."""
    if fallen:
        t = _X(k, lambda p: rot_z(rot_x(p - v3(0, 0, 0.05), -PI / 2 + 0.06), 0.3))
        _board(t, v3(0, 0, 0.0), kind, 0.24, 0.3, "wax", seed)
        k.add(rough(lambda p: box(rot_z(p, -0.5, (0.5, -0.3, 0)), v3(0.5, -0.3, 0.02), (0.24, 0.04, 0.018)), 0.01, 0.1, seed), "wood_d")
        return {"shadow": 0.35}
    for sy, a in ((-1, 0.28), (1, -0.28)):
        t = _X(k, lambda p, sy=sy, a=a: rot_x(p - v3(0, sy * 0.17, 0), a))
        if sy < 0:
            _board(t, v3(0, 0, 0.36), kind, 0.24, 0.3, "wax", seed)
        else:
            t.add(lambda p: box(p, v3(0, 0, 0.36), (0.24, 0.02, 0.3), 0.01), "plank_xd")
        t.add(lambda p: np.minimum(box(p, v3(-0.22, 0, 0.03), (0.025, 0.022, 0.05)), box(p, v3(0.22, 0, 0.03), (0.025, 0.022, 0.05))), "wood_d")
    return {}


# ── 빨랫줄 ───────────────────────────────────────────────────────────────────

def _laundry(k, zf, items, y=0.0, seed=1):
    """줄에 넌 빨래: items = [(x, 종류, 재질)]."""
    for i, (x, kind, mat) in enumerate(items):
        zt = zf(x) + 0.01
        if kind == "sheet":
            _hang(k, x, y, zt, 0.62, 0.72, mat, seed + i)
        elif kind == "shirt":
            _hang(k, x, y, zt, 0.3, 0.5, mat, seed + i)
            k.add(lambda p, x=x, zt=zt: np.minimum(box(rot_y(p, 0.5, (x - 0.15, y, zt)), v3(x - 0.25, y, zt - 0.06), (0.12, 0.012, 0.06), 0.02), box(rot_y(p, -0.5, (x + 0.15, y, zt)), v3(x + 0.25, y, zt - 0.06), (0.12, 0.012, 0.06), 0.02)), mat)
        elif kind == "trousers":
            k.add(lambda p, x=x, zt=zt: np.minimum.reduce([box(p, v3(x, y, zt - 0.09), (0.15, 0.012, 0.09), 0.01), box(p, v3(x - 0.085, y, zt - 0.36), (0.065, 0.012, 0.2), 0.01), box(p, v3(x + 0.085, y, zt - 0.36), (0.065, 0.012, 0.2), 0.01)]), mat)
        else:   # rag · 작은 천
            _hang(k, x, y, zt, 0.2, 0.26, mat, seed + i)
        k.add(lambda p, x=x, zt=zt: box(p, v3(x, y, zt), (0.012, 0.02, 0.03)), "wood_l")       # 집게


@_p("clothesline", "빨랫줄", (5, 4), {"laundry": {}, "sheets": {"kind": "sheets"}, "empty": {"kind": "empty"}}, collide=[(-1.45, -0.12, 0.25, 0.25), (1.2, -0.12, 0.25, 0.25)],
    tags=["cloth", "wood", "street", "yard", "home"])
def clothesline(k, kind="laundry", seed=1):
    """말뚝 둘 사이에 맨 빨랫줄(말뚝만 막는다)."""
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: np.minimum.reduce([cap(p, v3(sx * 1.32, 0, 0), v3(sx * 1.32, 0, 1.72), 0.04, 0.032), hcyl(p, v3(sx * 1.32, -0.14, 1.62), v3(sx * 1.32, 0.14, 1.62), 0.022),
            cap(p, v3(sx * 1.32, 0, 0.9), v3(sx * 1.62, 0, 0.0), 0.022)]), "wood_d")
    zf = _rope(k, v3(-1.32, 0, 1.62), v3(1.32, 0, 1.62), 0.14)
    if kind == "laundry":
        _laundry(k, zf, [(-0.9, "shirt", "linen"), (-0.38, "trousers", "cloth_b"), (0.02, "rag", "cloth_r"), (0.36, "rag", "linen"), (0.85, "shirt", "cloth")], 0.0, seed)
    elif kind == "sheets":
        _laundry(k, zf, [(-0.72, "sheet", "linen"), (0.05, "sheet", k.mat("sheet2", M.plain("#8a8674", 0.25, 0.12, 4))), (0.82, "rag", "cloth_b")], 0.0, seed)
    else:
        k.add(lambda p: np.minimum.reduce([box(p, v3(x, 0, zf(x)), (0.012, 0.02, 0.03)) for x in (-0.6, -0.5, 0.3)]), "wood_l")
        k.add(lambda p: sub(_frustum(p, v3(0.9, -0.3, 0), 0.16, 0.22, 0.18), _frustum(p, v3(0.9, -0.3, 0.03), 0.14, 0.2, 0.2)), "rope")       # 빈 빨래 바구니
    return {"shadow": 0.4}


@_p("clothesline_hanging", "골목 위 빨랫줄", (6, 4), {"laundry": {}, "sparse": {"kind": "sparse"}}, layer="over", tags=["cloth", "street", "alley", "overhead", "home"],
    meta={"note": "집과 집 사이 골목 위에 걸린 줄 — 원점 = 줄 가운데 아래 바닥"})
def clothesline_hanging(k, kind="laundry", seed=1):
    zf = _rope(k, v3(-2.8, 0, 2.7), v3(2.8, 0, 2.7), 0.3, 0.012, 12)
    if kind == "laundry":
        items = [(-2.1, "shirt", "linen"), (-1.5, "rag", "cloth_r"), (-0.95, "sheet", "linen"), (-0.2, "trousers", "cloth"), (0.35, "shirt", "cloth_b"), (1.0, "rag", "linen"), (1.5, "sheet", k.mat("sheet2", M.plain("#8a8674", 0.25, 0.12, 4))), (2.2, "rag", "cloth_g")]
    else:
        items = [(-1.6, "trousers", "cloth_b"), (-0.2, "rag", "linen"), (0.3, "rag", "cloth"), (1.7, "shirt", "linen")]
    _laundry(k, zf, items, 0.0, seed)
    return {"shadow": 0.0, "foot": 0.4}
