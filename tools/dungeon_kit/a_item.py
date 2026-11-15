"""아이템 그림(에셋 전용 — data/에 등록하지 않는다): 가방 한 칸 80 × 80px, 투명 배경, 정면에서 조금 내려다본 물건 하나.
게임 아이템 그림(assets/items — tools/paint_items.gd)과 같은 생김새: 부드러운 찰흙 덩어리 칠 · 가는 먹 윤곽 · 낮은 채도 · 왼쪽 위 빛.
키트의 3/4 시점 손그림 마감(solid.py — 빗금 · 굵은 잉크)은 80px에서 지저분해서, 여기서는 정면 시점 전용 작은 렌더러(shot)를 쓴다.
좌표: 그림 = x(-1 … 1 오른쪽) · z(-1 … 1 위), y = 깊이(카메라는 -y에서 본다). 물건은 ±0.8 안에 빚는다.
shot()을 고쳤으면 캐시가 모르니 build.py --force로 다시 그린다."""
import numpy as np
from PIL import Image

import sdf
import solid
from kit import (F, box, cap, cyl, disc_x, ell, flat, hcyl, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)
from paint2d import hexc, vnoise

PX = 80
LIGHT = np.array([-0.5, -0.62, 0.6], F)
LIGHT /= np.sqrt((LIGHT * LIGHT).sum())
HALF = LIGHT + np.array([0, -1, 0], F)
HALF /= np.sqrt((HALF * HALF).sum())
INK = hexc("#17100e")
SHADE = hexc("#2a1a16")
LUM = np.array([0.3, 0.59, 0.11], F)
GLASS, CORK, PAPER, LINEN = "#b4bcb8", "#5c4030", "#c8ba94", "#bdb49c"
IRON, STEEL, BRASS, GOLD, RUST = "#55565a", "#8a9096", "#9a8048", "#c2a04a", "#6e4630"
WOOD, WOOD_D, LEATHER, LEATHER_D = "#6e5238", "#46342a", "#6a4a30", "#44302a"


def _col(c, p):
    return np.tile(hexc(c), (len(p), 1)) if isinstance(c, str) else np.asarray(c(p), F)


def shot(parts, seed=1, pitch=0.28, yaw=0.0, ss=3):
    """parts = [(거리 함수, 색 "#hex" 또는 함수(p) → (N, 3), 재질 matte · metal · glass · gem · glow)] → RGBA 80 × 80."""
    n_px = PX * ss
    jj, ii = np.mgrid[0:n_px, 0:n_px]
    x = ((ii + 0.5) / n_px * 2 - 1).astype(F).ravel()
    z = (1 - (jj + 0.5) / n_px * 2).astype(F).ravel()

    def T(q):
        p = rot_x(q, -pitch)
        return rot_z(p, yaw) if yaw else p

    def dist(q):
        p = T(q)
        d = parts[0][0](p)
        for fn, _, _ in parts[1:]:
            d = np.minimum(d, fn(p))
        return d

    p0 = np.stack([x, np.full_like(x, -3.0), z], 1)
    ray = np.array([0, 1, 0], F)
    t = np.zeros(len(x), F)
    hit = np.zeros(len(x), bool)
    live = np.arange(len(x))
    for _ in range(96):
        if len(live) == 0:
            break
        d = dist(p0[live] + t[live, None] * ray)
        done = d < 0.004
        hit[live[done]] = True
        t[live] += np.maximum(d, 0.004) * 0.85
        live = live[~done & (t[live] < 6.0)]
    q = (p0 + t[:, None] * ray)[hit]
    pm = T(q)
    ds = np.stack([fn(pm) for fn, _, _ in parts], 1)
    pid = ds.argmin(1)
    nrm = np.zeros_like(q)
    for k in range(3):
        o = np.zeros(3, F)
        o[k] = 0.006
        nrm[:, k] = dist(q + o) - dist(q - o)
    nrm /= np.maximum(np.sqrt((nrm * nrm).sum(-1, keepdims=True)), 1e-6)
    ao = np.clip(0.4 + 0.6 * dist(q + nrm * 0.07) / 0.07, 0, 1)
    col = np.zeros((len(q), 3), F)
    for i, (_, c, kind) in enumerate(parts):
        s = pid == i
        if not s.any():
            continue
        n = nrm[s]
        if kind == "gem":       # 깎은 면: 법선을 굵게 끊는다
            n = np.round(n * 2.0) / 2.0
            n = n / np.maximum(np.sqrt((n * n).sum(-1, keepdims=True)), 1e-6)
        base = _col(c, pm[s])
        lam = np.clip(n @ LIGHT, 0, 1)
        face = np.clip(-n[:, 1], 0, 1)
        spec = np.clip(n @ HALF, 0, 1)
        if kind == "glow":
            out = base * (0.82 + 0.18 * face)[:, None]
        else:
            if kind == "metal":
                tone = 0.26 + 0.8 * lam ** 1.4
                sp = spec ** 18 * 0.55
            elif kind == "glass":
                tone = 0.5 + 0.5 * lam
                sp = spec ** 40 * 0.8 + (1 - face) ** 3 * 0.12
            elif kind == "gem":
                tone = 0.36 + 0.75 * lam
                sp = spec ** 10 * 0.5
            else:
                tone = 0.3 + 0.72 * lam
                sp = spec ** 8 * 0.06
            tone = tone * (0.55 + 0.45 * ao[s]) * (1 - 0.3 * (1 - face) ** 2)
            out = base * tone[:, None]
            lum = (base @ LUM)[:, None]
            out = out + (SHADE * lum * 1.5 - out) * (np.clip(0.6 - tone, 0, 1) * 0.5)[:, None]
            out = out + sp[:, None] * np.array([1.0, 0.97, 0.9], F)
        col[s] = out
    rgb = np.zeros((n_px * n_px, 3), F)
    rgb[hit] = np.clip(col, 0, 1)
    rgb = rgb.reshape(n_px, n_px, 3)
    mask = hit.reshape(n_px, n_px)
    depth = np.full(n_px * n_px, 9.0, F)
    depth[hit] = q[:, 1]
    depth = depth.reshape(n_px, n_px)
    ids = np.full(n_px * n_px, -1, np.int32)
    ids[hit] = pid
    ids = ids.reshape(n_px, n_px)
    # 붓결 얼룩 + 알갱이
    rgb = rgb * (1.0 + (vnoise(n_px, n_px, 14, seed + 3)[..., None] - 0.5) * 0.14 + (vnoise(n_px, n_px, 2, seed + 4)[..., None] - 0.5) * 0.07)
    # 먹 윤곽: 바깥은 진하게, 안쪽(덩어리 경계 · 깊이 턱)은 옅게
    edge = np.zeros_like(mask)
    for sy, sx in ((1, 0), (0, 1)):
        d2, i2, m2 = (np.roll(a, (sy, sx), (0, 1)) for a in (depth, ids, mask))
        edge |= mask & m2 & ((np.abs(depth - d2) > 0.09) | (ids != i2))
    edge = solid._dilate(edge, 1) & mask
    sil = solid._dilate(mask, ss) & ~mask
    a_ink = np.where(edge, 0.62, 0.0).astype(F)
    rgb = rgb * (1 - a_ink[..., None]) + INK * a_ink[..., None]
    rgb = np.where(sil[..., None], INK, rgb)
    lum = (rgb @ LUM)[..., None]
    rgb = rgb * 0.9 + lum * 0.1
    alpha = np.where(mask, 1.0, np.where(sil, 0.92, 0.0)).astype(F)
    pmul = np.concatenate([np.clip(rgb, 0, 1) * alpha[..., None], alpha[..., None]], -1)
    small = np.asarray(Image.fromarray((pmul * 255 + 0.5).astype(np.uint8), "RGBA").resize((PX, PX), Image.LANCZOS)).astype(F) / 255.0
    a = small[..., 3:4]
    small[..., :3] = np.where(a > 1e-3, small[..., :3] / np.maximum(a, 1e-3), 0)
    return (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)


def item(id, name, variants, tags=()):
    return flat(id, "item", layer="decal", cell=(PX, PX), variants=variants, name_ko=name, tags=["item"] + list(tags), meta={"grid": True, "item_px": PX})


# ── 빚기 도우미 ───────────────────────────────────────────────────────────────

def fill(liquid, level, glass=GLASS):
    lq, gl = hexc(liquid), hexc(glass)
    return lambda p: np.where((p[:, 2] < level + np.sin(p[:, 0] * 9.0) * 0.012)[:, None], lq[None, :], gl[None, :])


def speck(base, other, scale=0.12, cut=0.6, seed=1, sharp=8.0):
    b, o = hexc(base), hexc(other)

    def fn(p):
        m = np.clip((sdf.fbm(p, scale, seed, 2) - cut) * sharp, 0, 1)[:, None]
        return b[None, :] * (1 - m) + o[None, :] * m
    return fn


def lines(base, ink="#4a4034", row=0.11, seed=1, x0=-9.0, x1=9.0, z0=-9.0, z1=9.0):
    """종이 위 읽히지 않는 글줄(z 줄마다 끊긴 가로 획)."""
    b, k = hexc(base), hexc(ink)

    def fn(p):
        r = np.floor(p[:, 2] / row)
        on = ((p[:, 2] / row - r) < 0.3) & (sdf._hash(np.floor(p[:, 0] / 0.09), r, r * 0, seed) > 0.28)
        on &= (p[:, 0] > x0) & (p[:, 0] < x1 - sdf._hash(r, r * 0, r * 0, seed + 1) * 0.3) & (p[:, 2] > z0) & (p[:, 2] < z1)
        return np.where(on[:, None], k[None, :], b[None, :] * (0.92 + sdf.noise(p, 0.3, seed)[:, None] * 0.14))
    return fn


def kite(p, c, w, hu, hd, dp):
    """마름모 결정(위 hu · 아래 hd로 뾰족, 폭 w, 두께 dp)."""
    q = p - c
    h = np.where(q[:, 2] > 0, hu, hd)
    return (np.abs(q[:, 0]) / w + np.abs(q[:, 2]) / h + np.abs(q[:, 1]) / dp - 1.0) * min(w, dp) * 0.6


def frustum(p, c, r0, r1, h):
    zz = p[:, 2] - c[2]
    r = r0 + (r1 - r0) * np.clip(zz / h, 0, 1)
    return np.maximum(np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) - r, np.abs(zz - h / 2) - h / 2)


def bowl(c, r, h, mat):
    return (lambda p: sub(frustum(p, c, r * 0.6, r, h), frustum(p, c + v3(0, 0, 0.05), r * 0.5, r * 0.9, h)), mat, "matte")


def bar(c, w, d, h, k=0.5):
    """주괴(위가 좁은 사다리꼴 막대)."""
    def fn(p):
        q = p - c
        s = q[:, 2] * k
        return np.maximum(np.maximum(np.abs(q[:, 0]) - (w - s), np.abs(q[:, 1]) - (d - s)), np.abs(q[:, 2] - h / 2) - h / 2) - 0.012
    return fn


def coin_x(c, r=0.3, tilt=0.0, mat=GOLD):
    """세운 동전(화면을 본다): 테 + 가운데 민무늬 돋을새김."""
    T = (lambda p: rot_y(p, tilt, c)) if tilt else (lambda p: p)
    return [(lambda p: disc_x(T(p), c, r, 0.035), mat, "metal"), (lambda p: ring_x(T(p), c + v3(0, -0.03, 0), r * 0.86, 0.022), mat, "metal"),
        (lambda p: ell(T(p), c + v3(0, -0.03, 0), (r * 0.42, 0.03, r * 0.42)), mat, "metal")]


def coin_z(c, r=0.2, mat=GOLD):
    return (lambda p: cyl(p, c, r, 0.045, 0.012), mat, "metal")


def sheet(c, w, h, colfn, th=0.02, a=0.0):
    return (lambda p: box(rot_y(p, a, c), c, (w, th, h), 0.01), colfn, "matte")


def neck_cork(z, r=0.15, h=0.22):
    return [(lambda p: cap(p, v3(0, 0, z - 0.12), v3(0, 0, z + h * 0.45), r, r * 0.92), GLASS, "glass"),
        (lambda p: cyl(p, v3(0, 0, z + h * 0.35), r * 1.08, h, 0.05), CORK, "matte")]


# ── 7-1 소모품 ───────────────────────────────────────────────────────────────

@item("item_potion", "물약병(아이템)", {"round_red": {"shape": "round", "col": "#8e2f3c"}, "tall_blue": {"shape": "tall", "col": "#38588e"},
    "square_green": {"shape": "square", "col": "#4e7a3a"}, "gourd_amber": {"shape": "gourd", "col": "#a8732c"}}, ["consumable", "potion"])
def item_potion(c, shape="round", col="#8e2f3c", seed=1):
    if shape == "round":
        body, top, lv = (lambda p: sphere(p, v3(0, 0, -0.24), 0.5)), 0.24, -0.28
    elif shape == "tall":
        body, top, lv = (lambda p: cap(p, v3(0, 0, -0.44), v3(0, 0, 0.0), 0.3, 0.27)), 0.26, -0.3
    elif shape == "square":
        body, top, lv = (lambda p: box(p, v3(0, 0, -0.28), (0.4, 0.3, 0.44), 0.1)), 0.2, -0.3
    else:
        body, top, lv = (lambda p: smin(sphere(p, v3(0, 0, -0.38), 0.37), sphere(p, v3(0, 0, 0.08), 0.24), 0.08)), 0.34, -0.2
    return shot([(body, fill(col, lv), "glass")] + neck_cork(top), seed, 0.12)


@item("item_vial", "작은 물약병", {"tube_red": {"shape": "tube", "col": "#96323c"}, "drop_blue": {"shape": "drop", "col": "#3c64a0"},
    "facet_green": {"shape": "facet", "col": "#5a8a3e"}}, ["consumable", "potion"])
def item_vial(c, shape="tube", col="#96323c", seed=1):
    if shape == "tube":
        parts = [(lambda p: cap(p, v3(0, 0, -0.5), v3(0, 0, 0.2), 0.17), fill(col, -0.1), "glass"), (lambda p: cyl(p, v3(0, 0, 0.3), 0.19, 0.2, 0.05), CORK, "matte"),
            (lambda p: torus(p, v3(0, 0, 0.28), 0.18, 0.03), GLASS, "glass")]
    elif shape == "drop":
        parts = [(lambda p: smin(sphere(p, v3(0, 0, -0.3), 0.3), cap(p, v3(0, 0, -0.05), v3(0, 0, 0.3), 0.14, 0.09), 0.12), fill(col, -0.25), "glass"),
            (lambda p: cyl(p, v3(0, 0, 0.3), 0.11, 0.18, 0.04), CORK, "matte")]
    else:
        parts = [(lambda p: kite(rot_z(p, 0.6), v3(0, 0, -0.18), 0.3, 0.36, 0.42, 0.3), fill(col, -0.2), "gem"), (lambda p: cyl(p, v3(0, 0, 0.1), 0.1, 0.16), GLASS, "glass"),
            (lambda p: cyl(p, v3(0, 0, 0.24), 0.12, 0.18, 0.04), CORK, "matte")]
    return shot(parts, seed, 0.12)


def _leaf(a, b, w, col, twist=0.0):
    a, b = np.asarray(a, F), np.asarray(b, F)
    mid = (a + b) / 2
    ln = float(np.sqrt(((b - a) ** 2).sum())) / 2
    ang = np.arctan2(b[0] - a[0], b[2] - a[2])
    return (lambda p: ell(rot_y(p, -ang, mid), mid, (w, 0.035, ln)), col, "matte")


@item("item_herb", "약초 다발", {"bundle": {"kind": "bundle"}, "sprig": {"kind": "sprig"}, "dried": {"kind": "dried"}}, ["consumable", "herb"])
def item_herb(c, kind="bundle", seed=1):
    rng = np.random.default_rng(seed + 4)
    parts = []
    if kind == "sprig":
        parts.append((lambda p: cap(p, v3(0.05, 0, -0.75), v3(-0.05, 0, 0.6), 0.03, 0.018), "#5a6a38", "matte"))
        for i, zz in enumerate(np.linspace(-0.4, 0.5, 5)):
            for s in (-1, 1):
                parts.append(_leaf((0, -0.02, zz), (s * (0.42 - i * 0.05), -0.04, zz + 0.2), 0.1 - i * 0.008, "#5c7c3c" if (i + s) % 2 else "#4c6c34"))
        parts.append(_leaf((-0.05, -0.02, 0.5), (-0.07, -0.04, 0.82), 0.08, "#688a42"))
        return shot(parts, seed, 0.1)
    green = ("#55743a", "#486a34", "#628244") if kind == "bundle" else ("#7a6a3c", "#6a5a34", "#8a7444")
    for i, a in enumerate(np.linspace(-0.55, 0.55, 6)):
        tip = v3(np.sin(a) * 0.75, rng.uniform(-0.08, 0.08), -0.45 + np.cos(a) * 1.15)
        parts.append((lambda p, tip=tip: cap(p, v3(0, 0, -0.45), tip, 0.03, 0.015), green[1], "matte"))
        parts.append(_leaf(v3(0, 0, -0.45) + (tip - v3(0, 0, -0.45)) * 0.55, tip + v3(0, -0.03, 0.05), 0.11, green[i % 3]))
        if kind == "dried" and i % 2 == 0:
            parts.append((lambda p, tip=tip: sphere(p, tip + v3(0, -0.05, 0), 0.07), "#8a6a8c", "matte"))
    parts.append((lambda p: cap(p, v3(0, 0, -0.8), v3(0, 0, -0.4), 0.09, 0.07), green[1], "matte"))
    parts.append((lambda p: cyl(p, v3(0, 0, -0.56), 0.11, 0.1, 0.03), "#8a7650", "matte"))
    return shot(parts, seed, 0.1)


@item("item_bandage_roll", "붕대 두루마리", {"roll": {"kind": "roll"}, "pair": {"kind": "pair"}, "pad": {"kind": "pad"}}, ["consumable", "healing"])
def item_bandage_roll(c, kind="roll", seed=1):
    def roll(cx, cz, r, w):
        return [(lambda p: hcyl(p, v3(cx - w, 0, cz), v3(cx + w, 0, cz), r) - 0.02, LINEN, "matte"),
            (lambda p: hcyl(p, v3(cx + w, 0, cz), v3(cx + w + 0.03, 0, cz), r * 0.45), "#8a8270", "matte"),
            (lambda p: box(rot_y(p, 0.25, (cx - w * 0.3, -r, cz - r)), v3(cx - w * 0.3, -r * 0.9, cz - r - 0.14), (w * 0.62, 0.02, 0.2), 0.01), "#cdc4aa", "matte")]
    if kind == "roll":
        return shot(roll(0, 0.08, 0.34, 0.36), seed, 0.3, 0.45)
    if kind == "pair":
        return shot(roll(-0.2, 0.25, 0.26, 0.3) + roll(0.2, -0.3, 0.26, 0.3), seed, 0.3, 0.45)
    parts = [(lambda p, i=i: box(rot_z(p, 0.1 * i - 0.1), v3(0, 0, -0.3 + i * 0.16), (0.55 - i * 0.03, 0.4, 0.07), 0.04), (LINEN, "#cdc4aa", "#aea58e")[i], "matte") for i in range(3)]
    parts.append((lambda p: np.minimum(box(p, v3(0, 0, -0.1), (0.06, 0.43, 0.3), 0.02), box(p, v3(0, 0, 0.19), (0.6, 0.06, 0.02), 0.01)), "#8a7650", "matte"))
    return shot(parts, seed, 0.55, 0.3)


@item("item_food", "음식(아이템)", {"stew": {"kind": "stew"}, "meat": {"kind": "meat"}, "cheese": {"kind": "cheese"}, "apple": {"kind": "apple"}}, ["consumable", "food"])
def item_food(c, kind="stew", seed=1):
    if kind == "stew":
        parts = [bowl(v3(0, 0, -0.4), 0.72, 0.5, WOOD), (lambda p: cyl(p, v3(0, 0, -0.1), 0.6, 0.12, 0.03), speck("#7a4e2a", "#b8742e", 0.14, 0.55, seed), "matte")]
        for x, y, col in ((-0.25, 0.1, "#a85a2c"), (0.2, -0.15, "#c8b070"), (0.1, 0.25, "#6a8a3c"), (-0.1, -0.25, "#8a4a30")):
            parts.append((lambda p, x=x, y=y: ell(p, v3(x, y, 0.03), (0.12, 0.1, 0.06)), col, "matte"))
        parts.append((lambda p: cap(p, v3(0.3, 0.2, 0.0), v3(0.75, 0.5, 0.5), 0.035), WOOD_D, "matte"))
        return shot(parts, seed, 0.75)
    if kind == "meat":
        T = lambda p: rot_y(p, 0.7)
        return shot([(rough(lambda p: ell(T(p), v3(0, 0, 0.18), (0.36, 0.3, 0.46)), 0.05, 0.25, seed), speck("#6e3a28", "#8a4e30", 0.2, 0.5, seed), "matte"),
            (lambda p: cap(T(p), v3(0, 0, -0.2), v3(0, 0, -0.78), 0.07), "#d8cfb8", "matte"),
            (lambda p: np.minimum(sphere(T(p), v3(-0.06, 0, -0.8), 0.09), sphere(T(p), v3(0.06, 0, -0.8), 0.09)), "#d8cfb8", "matte")], seed, 0.15)
    if kind == "cheese":
        holes = lambda p: np.minimum.reduce([sphere(p, v3(x, y, zz), r) for x, y, zz, r in ((-0.2, -0.36, -0.1, 0.1), (0.25, -0.36, 0.05, 0.07), (0.0, -0.36, -0.3, 0.06), (-0.1, 0.0, 0.2, 0.09))])
        wedge = lambda p: np.maximum(np.maximum(box(p, v3(0, 0, -0.12), (0.7, 0.36, 0.3), 0.03), (p[:, 1] * 0.5 + np.abs(p[:, 0]) * 0.0) - 0.3), p[:, 2] - 0.18 + (p[:, 0] + 0.7) * -0.0)
        tri = lambda p: np.maximum(wedge(p), (np.abs(p[:, 1] + 0.0) * 1.0 + (p[:, 0]) * 0.5) - 0.36)
        return shot([(lambda p: sub(tri(p), holes(p)), speck("#d0a848", "#b88a34", 0.3, 0.5, seed, 3.0), "matte")], seed, 0.5, 0.5)
    parts = [(lambda p: sub(ell(p, v3(0, 0, -0.08), (0.56, 0.54, 0.52)), sphere(p, v3(0, 0, 0.56), 0.2)), speck("#9a3430", "#b8843a", 0.5, 0.56, seed, 3.0), "glass"),
        (lambda p: cap(p, v3(0, 0, 0.36), v3(0.07, 0, 0.66), 0.03), WOOD_D, "matte"), _leaf((0.06, 0, 0.5), (0.4, -0.02, 0.7), 0.11, "#55743a")]
    return shot(parts, seed, 0.2)


@item("item_ration", "휴대 식량", {"pack": {"kind": "pack"}, "hardtack": {"kind": "hardtack"}, "jerky": {"kind": "jerky"}}, ["consumable", "food"])
def item_ration(c, kind="pack", seed=1):
    if kind == "pack":
        return shot([(rough(lambda p: box(p, v3(0, 0, 0), (0.62, 0.34, 0.46), 0.12), 0.04, 0.3, seed), "#a89a78", "matte"),
            (lambda p: np.minimum(box(p, v3(0, 0, 0), (0.035, 0.37, 0.49), 0.02), box(p, v3(0, 0, 0), (0.65, 0.37, 0.035), 0.02)), "#6e5a3c", "matte"),
            (lambda p: sphere(p, v3(0, -0.37, 0), 0.06), "#6e5a3c", "matte")], seed, 0.3, 0.25)
    if kind == "hardtack":
        def dots(p):
            on = (np.hypot((p[:, 0] + 9) % 0.3 - 0.15, (p[:, 1] + 9) % 0.3 - 0.15) < 0.035) & (p[:, 2] > 0.0)
            return np.where(on[:, None], hexc("#7a6240")[None, :], hexc("#c4aa76")[None, :] * (0.9 + sdf.noise(p, 0.2, seed)[:, None] * 0.2))
        return shot([(lambda p, i=i: box(rot_z(p, 0.25 * i), v3(0.05 * i, 0, -0.3 + i * 0.17), (0.5, 0.5, 0.07), 0.03), dots, "matte") for i in range(3)], seed, 0.8, 0.3)
    parts = []
    for i, (x, a) in enumerate(((-0.4, -0.12), (0.0, 0.06), (0.4, -0.05))):
        parts.append((rough(lambda p, x=x, a=a: box(rot_y(p, a), v3(x, i * 0.02, 0), (0.15, 0.04, 0.68), 0.04), 0.07, 0.16, seed + i), speck("#5a2c24", "#7a4430", 0.12, 0.5, seed + i), "matte"))
    parts.append((lambda p: box(p, v3(0, -0.02, 0.1), (0.62, 0.07, 0.03), 0.02), "#8a7650", "matte"))
    return shot(parts, seed, 0.1)


@item("item_drink", "음료(아이템)", {"waterskin": {"kind": "waterskin"}, "tankard": {"kind": "tankard"}, "wine": {"kind": "wine"}}, ["consumable", "drink"])
def item_drink(c, kind="waterskin", seed=1):
    if kind == "waterskin":
        return shot([(rough(lambda p: smin(ell(p, v3(-0.05, 0, -0.2), (0.5, 0.3, 0.52)), cap(p, v3(0.15, 0, 0.2), v3(0.36, 0, 0.56), 0.15, 0.09), 0.15), 0.04, 0.3, seed), LEATHER, "matte"),
            (lambda p: cap(p, v3(0.36, 0, 0.56), v3(0.43, 0, 0.7), 0.075), CORK, "matte"),
            (lambda p: np.maximum(ring_x(p, v3(-0.05, 0.05, 0.2), 0.6, 0.03), -p[:, 2] + 0.25), LEATHER_D, "matte"),
            (lambda p: ring_x(p, v3(0.3, -0.02, 0.46), 0.12, 0.025), LEATHER_D, "matte")], seed, 0.1)
    if kind == "tankard":
        return shot([(lambda p: sub(cyl(p, v3(-0.08, 0, -0.6), 0.42, 1.0, 0.03), cyl(p, v3(-0.08, 0, -0.3), 0.36, 1.0)), WOOD, "matte"),
            (lambda p: np.minimum(torus(p, v3(-0.08, 0, -0.42), 0.43, 0.04), torus(p, v3(-0.08, 0, 0.22), 0.43, 0.04)), IRON, "metal"),
            (lambda p: np.maximum(ring_x(p, v3(0.36, 0, -0.1), 0.3, 0.06), 0.3 - p[:, 0]), WOOD_D, "matte"),
            (rough(lambda p: ell(p, v3(-0.08, 0, 0.36), (0.38, 0.38, 0.1)), 0.05, 0.1, seed), "#d8ccac", "matte")], seed, 0.35)
    return shot([(lambda p: smin(cyl(p, v3(0, 0, -0.82), 0.27, 0.85, 0.08), cap(p, v3(0, 0, 0.0), v3(0, 0, 0.6), 0.2, 0.085), 0.1), "#34443a", "glass"),
        (lambda p: cyl(p, v3(0, 0, -0.55), 0.28, 0.34), lines("#b8ac8c", "#5a4a3a", 0.09, seed), "matte"),
        (lambda p: torus(p, v3(0, 0, 0.6), 0.09, 0.03), "#34443a", "glass"), (lambda p: cyl(p, v3(0, 0, 0.6), 0.075, 0.16, 0.03), CORK, "matte")], seed, 0.1)


@item("item_healer_tools", "치료 도구", {"salve": {"kind": "salve"}, "needle": {"kind": "needle"}, "splint": {"kind": "splint"}, "mortar": {"kind": "mortar"}}, ["consumable", "healing", "tool"])
def item_healer_tools(c, kind="salve", seed=1):
    if kind == "salve":
        return shot([(lambda p: sub(cyl(p, v3(0, -0.1, -0.3), 0.55, 0.3, 0.04), cyl(p, v3(0, -0.1, -0.12), 0.48, 0.3)), "#8a8c86", "metal"),
            (rough(lambda p: cyl(p, v3(0, -0.1, -0.2), 0.48, 0.13, 0.03), 0.04, 0.15, seed), "#c8c8a0", "matte"),
            (lambda p: cyl(rot_x(p, -1.0, (0, 0.5, -0.1)), v3(0, 0.5, -0.1), 0.56, 0.07, 0.03), "#8a8c86", "metal")], seed, 0.7)
    if kind == "needle":
        return shot([(lambda p: np.minimum(cyl(p, v3(-0.15, 0, -0.6), 0.36, 0.1, 0.02), cyl(p, v3(-0.15, 0, 0.2), 0.36, 0.1, 0.02)), WOOD, "matte"),
            (lambda p: cyl(p, v3(-0.15, 0, -0.5), 0.26, 0.7), lines("#b8b09c", "#8a8272", 0.05, seed), "matte"),
            (lambda p: cap(p, v3(0.1, -0.4, -0.7), v3(0.62, -0.4, 0.62), 0.03, 0.012), STEEL, "metal"),
            (lambda p: ring_x(p, v3(0.63, -0.4, 0.64), 0.045, 0.015), STEEL, "metal")], seed, 0.3)
    if kind == "splint":
        T = lambda p: rot_y(p, 0.5)
        parts = [(lambda p, x=x: box(T(p), v3(x, 0, 0), (0.1, 0.035, 0.78), 0.02), (WOOD, "#7a5e40")[i], "matte") for i, x in enumerate((-0.14, 0.14))]
        parts.append((lambda p: np.minimum.reduce([box(T(p), v3(0, 0, zz), (0.29, 0.07, 0.09), 0.04) for zz in (-0.45, 0.0, 0.45)]), LINEN, "matte"))
        return shot(parts, seed, 0.15)
    return shot([bowl(v3(0, 0, -0.5), 0.62, 0.62, "#8a8880"), (lambda p: cyl(p, v3(0, 0, -0.5), 0.36, 0.08, 0.02), "#8a8880", "matte"),
        (lambda p: cyl(p, v3(0, 0, -0.15), 0.5, 0.08), speck("#5c7c3c", "#3e5a2c", 0.1, 0.5, seed), "matte"),
        (lambda p: cap(p, v3(-0.1, 0.1, 0.0), v3(0.5, -0.2, 0.7), 0.1, 0.07), "#a8a498", "matte")], seed, 0.6)


# ── 7-2 재료 ─────────────────────────────────────────────────────────────────

def _zigzag(pts, y, r=0.022):
    return lambda p: np.minimum.reduce([cap(p, v3(a[0], y, a[1]), v3(b[0], y, b[1]), r) for a, b in zip(pts[:-1], pts[1:])])


@item("item_magic_stone", "마법석(아이템)", {"raw_small": {"size": 0.72, "glow": "#f08a3a"}, "raw": {"size": 0.95, "glow": "#f06a8a", "body": "#5c4048"},
    "raw_large": {"size": 1.12, "glow": "#8ac8f0", "body": "#4a4a56", "twin": True}, "cut": {"cut": True, "glow": "#c8a8f0"}}, ["material", "magic"])
def item_magic_stone(c, size=0.8, glow="#f08a3a", body="#6a4a38", twin=False, cut=False, seed=1):
    if cut:   # 깎은 결정(게임의 magic_stone_N과 같은 꼴) + 가운데 빛줄
        return shot([(lambda p: kite(p, v3(0, 0, -0.05), 0.46, 0.5, 0.78, 0.36), "#8a7aa8", "gem"),
            (lambda p: np.minimum(cap(p, v3(0, -0.2, 0.3), v3(0, -0.2, -0.6), 0.02), cap(p, v3(-0.3, -0.12, -0.05), v3(0.3, -0.12, -0.05), 0.02)), glow, "glow")], seed, 0.05)
    s = size
    stone = rough(lambda p: box(p, v3(0, 0, 0), (0.5 * s, 0.4 * s, 0.6 * s), 0.2 * s), 0.1 * s, 0.4, seed)
    parts = [(stone, speck(body, "#3a2c28", 0.3, 0.55, seed, 4.0), "matte"),
        (_zigzag([(0.02 * s, 0.6 * s), (-0.12 * s, 0.25 * s), (0.12 * s, 0.0), (-0.08 * s, -0.3 * s), (0.04 * s, -0.6 * s)], -0.41 * s), glow, "glow")]
    if twin:
        parts.append((_zigzag([(0.3 * s, 0.5 * s), (0.22 * s, 0.2 * s), (0.36 * s, -0.1 * s)], -0.39 * s, 0.017), glow, "glow"))
    return shot(parts, seed, 0.05)


@item("item_ore", "광석 덩어리", {"iron": {"kind": "iron"}, "copper": {"kind": "copper"}, "silver": {"kind": "silver"}}, ["material", "ore"])
def item_ore(c, kind="iron", seed=1):
    if kind == "iron":      # 모난 덩어리 · 붉은 녹 얼룩
        return shot([(rough(lambda p: box(rot_z(p, 0.4), v3(0, 0, -0.05), (0.56, 0.44, 0.44), 0.1), 0.16, 0.35, seed), speck("#56565a", "#8a4a30", 0.16, 0.52, seed, 6.0), "matte")], seed, 0.3)
    if kind == "copper":    # 둥근 혹덩이 · 푸른 녹과 구릿빛 줄
        lump = lambda p: smin(smin(sphere(p, v3(-0.2, 0, -0.12), 0.44), sphere(p, v3(0.3, 0, -0.2), 0.36), 0.15), sphere(p, v3(0.05, 0, 0.28), 0.32), 0.15)
        vein = lambda p: np.where((np.sin(p[:, 0] * 7 + p[:, 2] * 9 + sdf.noise(p, 0.2, seed) * 6) > 0.75)[:, None], hexc("#c87a44")[None, :], speck("#6a5a4c", "#4e8a70", 0.14, 0.58, seed)(p))
        return shot([(rough(lump, 0.06, 0.2, seed), vein, "matte")], seed, 0.3)
    shards = lambda p: np.minimum.reduce([kite(rot_y(p, a, (x, 0, -0.5)), v3(x, y, zz), w, h, 0.3, w) for x, y, zz, a, w, h in
        ((-0.3, 0.1, -0.1, -0.35, 0.24, 0.6), (0.05, 0, 0.0, 0.05, 0.28, 0.8), (0.38, 0.05, -0.2, 0.4, 0.22, 0.5))])
    return shot([(lambda p: np.maximum(shards(p), -p[:, 2] - 0.62), speck("#70747a", "#d8dce0", 0.1, 0.5, seed, 9.0), "gem"),
        (rough(lambda p: ell(p, v3(0, 0, -0.56), (0.66, 0.4, 0.2)), 0.08, 0.2, seed), "#4c4a48", "matte")], seed, 0.25)


@item("item_ingot", "금속 주괴(아이템)", {"iron": {"col": IRON}, "copper_pair": {"col": "#a8683e", "n": 2}, "steel_stack": {"col": STEEL, "n": 3}, "gold": {"col": GOLD}}, ["material", "metal"])
def item_ingot(c, col=IRON, n=1, seed=1):
    if n == 1:
        parts = [(bar(v3(0, 0, -0.2), 0.68, 0.32, 0.36), col, "metal")]
    elif n == 2:
        parts = [(bar(v3(-0.1, 0.1, -0.4), 0.62, 0.28, 0.3), col, "metal"), (lambda p: bar(v3(0.1, -0.1, -0.1), 0.62, 0.28, 0.3)(rot_z(p, 0.9, (0.1, -0.1, 0))), col, "metal")]
    else:
        parts = [(bar(v3(-0.36, 0, -0.5), 0.32, 0.5, 0.3), col, "metal"), (bar(v3(0.36, 0, -0.5), 0.32, 0.5, 0.3), col, "metal"), (bar(v3(0, 0, -0.2), 0.32, 0.5, 0.3), col, "metal")]
    return shot(parts, seed, 0.6, 0.5 if n < 3 else 0.2)


@item("item_gem", "보석(아이템)", {"round_red": {"cut": "round", "col": "#b03a48"}, "emerald_green": {"cut": "emerald", "col": "#3e9a6a"},
    "teardrop_blue": {"cut": "teardrop", "col": "#4a78c0"}, "raw_violet": {"cut": "raw", "col": "#8a5ab8"}}, ["material", "gem"])
def item_gem(c, cut="round", col="#b03a48", seed=1):
    if cut == "round":
        fn = lambda p: np.maximum(ell(p, v3(0, 0, 0), (0.62, 0.34, 0.62)), -p[:, 1] - 0.2)
    elif cut == "emerald":
        fn = lambda p: np.minimum(np.maximum(box(p, v3(0, 0, 0), (0.5, 0.2, 0.66), 0.0), (np.abs(p[:, 0]) + np.abs(p[:, 2])) * 0.707 - 0.66), box(p, v3(0, -0.2, 0), (0.3, 0.08, 0.46)))
    elif cut == "teardrop":
        fn = lambda p: smin(ell(p, v3(0, 0, -0.22), (0.46, 0.3, 0.46)), kite(p, v3(0, 0, 0.1), 0.3, 0.66, 0.2, 0.26), 0.12)
    else:
        fn = lambda p: np.minimum.reduce([kite(rot_y(p, a), v3(x, 0, zz), w, h, h * 0.7, w) for x, zz, a, w, h in ((-0.2, 0.0, -0.3, 0.26, 0.62), (0.2, -0.1, 0.35, 0.3, 0.56), (0.02, -0.3, 0.0, 0.34, 0.4))])
    return shot([(fn, col, "gem")], seed, 0.1)


@item("item_hide", "가죽(아이템)", {"roll": {"kind": "roll"}, "pelt": {"kind": "pelt"}, "strap": {"kind": "strap"}}, ["material", "leather"])
def item_hide(c, kind="roll", seed=1):
    if kind == "roll":
        return shot([(rough(lambda p: hcyl(p, v3(-0.6, 0, 0), v3(0.6, 0, 0), 0.34), 0.04, 0.3, seed), LEATHER, "matte"),
            (lambda p: hcyl(p, v3(0.6, 0, 0), v3(0.64, 0, 0), 0.25), speck("#8a7458", "#44302a", 0.06, 0.5, seed), "matte"),
            (lambda p: np.minimum(hcyl(p, v3(-0.32, 0, 0), v3(-0.25, 0, 0), 0.37), hcyl(p, v3(0.25, 0, 0), v3(0.32, 0, 0), 0.37)), "#8a7650", "matte")], seed, 0.3, 0.45)
    if kind == "pelt":
        body = lambda p: np.minimum.reduce([ell(p, v3(0, 0, 0), (0.44, 0.05, 0.6))] + [ell(rot_y(p, a, (x, 0, zz)), v3(x, 0, zz), (0.13, 0.05, 0.3)) for x, zz, a in
            ((-0.42, 0.45, -0.8), (0.42, 0.45, 0.8), (-0.42, -0.45, 0.8), (0.42, -0.45, -0.8))] + [ell(p, v3(0, 0, 0.66), (0.16, 0.05, 0.2))])
        return shot([(rough(body, 0.05, 0.14, seed), speck("#6a5a48", "#3e3228", 0.1, 0.5, seed, 4.0), "matte")], seed, 0.05)
    return shot([(lambda p: np.maximum(ring_x(p, v3(0, 0, 0.05), 0.5, 0.1), np.abs(p[:, 1]) - 0.2), LEATHER_D, "matte"),
        (lambda p: np.maximum(ring_x(p, v3(0, 0, 0.05), 0.3, 0.07), np.abs(p[:, 1]) - 0.2), LEATHER, "matte"),
        (lambda p: box(rot_y(p, 0.3), v3(0.45, 0, -0.55), (0.3, 0.2, 0.05), 0.02), LEATHER_D, "matte"),
        (lambda p: box(p, v3(0, -0.22, -0.42), (0.1, 0.03, 0.12), 0.02), BRASS, "metal")], seed, 0.15, 0.5)


@item("item_cloth", "옷감", {"bolt": {"kind": "bolt"}, "folded": {"kind": "folded"}, "rag": {"kind": "rag"}}, ["material", "cloth"])
def item_cloth(c, kind="bolt", seed=1):
    if kind == "bolt":
        return shot([(lambda p: hcyl(p, v3(-0.78, 0, 0.15), v3(0.78, 0, 0.15), 0.05), WOOD_D, "matte"),
            (rough(lambda p: hcyl(p, v3(-0.6, 0, 0.15), v3(0.6, 0, 0.15), 0.3), 0.02, 0.3, seed), "#3c5078", "matte"),
            (rough(lambda p: box(p, v3(0.05, -0.3, -0.3), (0.55, 0.025, 0.36), 0.02), 0.05, 0.3, seed + 1), "#46608a", "matte")], seed, 0.25, 0.3)
    if kind == "folded":
        return shot([(rough(lambda p, i=i: box(p, v3(0.03 * i, 0, -0.42 + i * 0.26), (0.62 - i * 0.03, 0.42, 0.12), 0.08), 0.03, 0.3, seed + i), ("#7a3430", "#b4aa90", "#46583c")[i], "matte") for i in range(3)], seed, 0.6, 0.3)
    return shot([(rough(lambda p: smin(ell(p, v3(-0.1, 0, -0.1), (0.6, 0.3, 0.4)), ell(p, v3(0.3, 0, 0.2), (0.3, 0.2, 0.34)), 0.2), 0.2, 0.3, seed), speck("#a09880", "#6a6250", 0.2, 0.5, seed, 3.0), "matte")], seed, 0.2)


@item("item_bone", "뼈 재료", {"bone": {"kind": "bone"}, "fang": {"kind": "fang"}, "horn": {"kind": "horn"}}, ["material", "bone"])
def item_bone(c, kind="bone", seed=1):
    if kind == "bone":
        T = lambda p: rot_y(p, 0.75)
        return shot([(lambda p: smin(cap(T(p), v3(0, 0, -0.6), v3(0, 0, 0.6), 0.09), np.minimum.reduce([sphere(T(p), v3(sx * 0.1, 0, sz * 0.66), 0.14) for sx in (-1, 1) for sz in (-1, 1)]), 0.08), "#d2c8ae", "matte")], seed, 0.1)
    n = 7

    def curve(p, r0, bend, ln):
        pts = [v3(-0.35 + np.sin(i / n * bend) * ln * 0.6, 0, -0.6 + (1 - np.cos(i / n * bend)) * 0 + i / n * ln) for i in range(n + 1)]
        return np.minimum.reduce([cap(p, pts[i], pts[i + 1], r0 * (1 - i / n) + 0.02, r0 * (1 - (i + 1) / n) + 0.02) for i in range(n)])
    if kind == "fang":
        return shot([(lambda p: curve(p, 0.2, 1.3, 1.25), "#d8d0b8", "matte"), (lambda p: sphere(p, v3(-0.35, 0, -0.62), 0.2), "#8a6a5a", "matte")], seed, 0.1)
    ridge = lambda p: hexc("#4e4238")[None, :] * (0.8 + 0.4 * (np.sin(p[:, 2] * 34) > 0.3))[:, None]
    return shot([(lambda p: curve(p, 0.3, 1.5, 1.3), ridge, "matte"), (lambda p: cyl(p, v3(-0.35, 0, -0.74), 0.33, 0.14, 0.04), "#8a8068", "matte")], seed, 0.1)


@item("item_wood", "목재(아이템)", {"log": {"kind": "log"}, "planks": {"kind": "planks"}, "branch": {"kind": "branch"}}, ["material", "wood"])
def item_wood(c, kind="log", seed=1):
    if kind == "log":
        ringc = lambda p: hexc("#b89a68")[None, :] * (0.78 + 0.22 * (np.sin(np.hypot(p[:, 1], p[:, 2]) * 46) > 0))[:, None]
        bark = lambda p: hexc("#54402e")[None, :] * (0.7 + sdf.fbm(p * np.array([0.15, 1, 1], F), 0.06, seed, 2)[:, None] * 0.6)
        return shot([(rough(lambda p: hcyl(p, v3(-0.6, 0, 0), v3(0.56, 0, 0), 0.36), 0.04, 0.2, seed), bark, "matte"),
            (lambda p: hcyl(p, v3(0.56, 0, 0), v3(0.6, 0, 0), 0.33), ringc, "matte"), (lambda p: cap(p, v3(-0.2, 0, 0.3), v3(-0.3, -0.1, 0.56), 0.06, 0.04), "#54402e", "matte")], seed, 0.3, 0.55)
    if kind == "planks":
        parts = [(lambda p, i=i: box(rot_z(p, 0.04 * (i - 1)), v3(0, 0, -0.3 + i * 0.2), (0.74, 0.3, 0.07), 0.015), ("#7a5e40", WOOD, "#86684a")[i], "matte") for i in range(3)]
        parts.append((lambda p: np.minimum(box(p, v3(-0.4, 0, -0.1), (0.035, 0.33, 0.34), 0.02), box(p, v3(0.4, 0, -0.1), (0.035, 0.33, 0.34), 0.02)), "#8a7650", "matte"))
        return shot(parts, seed, 0.5, 0.4)
    return shot([(rough(lambda p: np.minimum.reduce([cap(p, v3(-0.6, 0, -0.6), v3(0.3, 0, 0.3), 0.1, 0.06), cap(p, v3(0.3, 0, 0.3), v3(0.7, 0, 0.4), 0.06, 0.03), cap(p, v3(0.3, 0, 0.3), v3(0.3, 0, 0.78), 0.055, 0.03),
        cap(p, v3(-0.2, 0, -0.2), v3(-0.5, 0, 0.25), 0.05, 0.025)]), 0.04, 0.15, seed), "#5c4632", "matte"), _leaf((0.3, 0, 0.74), (0.5, -0.02, 0.88), 0.07, "#6a6a38")], seed, 0.1)


@item("item_reagent_herb", "약초 재료", {"root": {"kind": "root"}, "mushroom": {"kind": "mushroom"}, "flower": {"kind": "flower"}, "berries": {"kind": "berries"}}, ["material", "herb"])
def item_reagent_herb(c, kind="root", seed=1):
    if kind == "root":
        segs = [((-0.1, 0.7), (0.05, 0.2), 0.16, 0.2), ((0.05, 0.2), (-0.05, -0.3), 0.2, 0.12), ((-0.05, -0.3), (-0.4, -0.75), 0.12, 0.03), ((-0.05, -0.3), (0.35, -0.7), 0.1, 0.03), ((0.05, 0.1), (0.5, -0.1), 0.08, 0.02), ((0, 0), (-0.5, 0.05), 0.07, 0.02)]
        return shot([(rough(lambda p: np.minimum.reduce([cap(p, v3(a[0], 0, a[1]), v3(b[0], 0, b[1]), r0, r1) for a, b, r0, r1 in segs]), 0.05, 0.12, seed), speck("#a88a5c", "#6a5238", 0.1, 0.55, seed), "matte"),
            _leaf((-0.1, 0, 0.7), (-0.3, -0.02, 0.9), 0.07, "#55743a"), _leaf((-0.1, 0, 0.7), (0.12, -0.02, 0.92), 0.07, "#628244")], seed, 0.05)
    if kind == "mushroom":
        spots = lambda p: np.where((sdf.noise(p, 0.13, seed) > 0.68)[:, None], hexc("#d8ccb0")[None, :], hexc("#8a4a34")[None, :])
        return shot([(lambda p: cap(p, v3(0, 0, -0.75), v3(0.04, 0, 0.1), 0.15, 0.1), "#d2c6a8", "matte"),
            (lambda p: np.maximum(ell(p, v3(0.04, 0, 0.1), (0.62, 0.55, 0.5)), 0.08 - p[:, 2]), spots, "matte"),
            (lambda p: cyl(p, v3(0.04, 0, 0.05), 0.5, 0.05), "#b8a888", "matte")], seed, -0.12)
    if kind == "flower":
        parts = [(lambda p: cap(p, v3(0.1, 0, -0.8), v3(-0.02, 0, 0.3), 0.03, 0.02), "#6a6a3c", "matte"), _leaf((0.06, 0, -0.4), (0.4, -0.02, -0.15), 0.09, "#6a6e3c"), _leaf((0.04, 0, -0.2), (-0.3, -0.02, 0.0), 0.08, "#5e6636")]
        for i in range(6):
            a = i / 6 * 2 * np.pi
            parts.append(_leaf((-0.02, -0.05, 0.36), (-0.02 + np.sin(a) * 0.36, -0.07, 0.36 + np.cos(a) * 0.36), 0.12, "#9a7aa8" if i % 2 else "#86689a"))
        parts.append((lambda p: sphere(p, v3(-0.02, -0.1, 0.36), 0.1), "#b89a48", "matte"))
        return shot(parts, seed, 0.05)
    parts = [(lambda p: np.minimum(cap(p, v3(0.1, 0, 0.75), v3(0, 0, 0.2), 0.025), cap(p, v3(0, 0, 0.2), v3(-0.25, 0, -0.1), 0.02)), "#5a4a30", "matte"), _leaf((0.1, 0, 0.6), (0.52, -0.02, 0.72), 0.13, "#55743a")]
    for x, zz, y in ((-0.28, -0.25, 0), (0.05, -0.1, -0.08), (0.3, -0.3, 0), (-0.05, -0.48, -0.1), (-0.3, 0.1, 0.05), (0.26, 0.1, 0.05)):
        parts.append((lambda p, x=x, zz=zz, y=y: sphere(p, v3(x, y, zz), 0.2), "#7a2a3a", "glass"))
    return shot(parts, seed, 0.05)


@item("item_reagent_magic", "마법 재료", {"dust_vial": {"kind": "dust"}, "feather": {"kind": "feather"}, "shard": {"kind": "shard"}, "bead": {"kind": "bead"}, "rune_chip": {"kind": "chip"}}, ["material", "magic"])
def item_reagent_magic(c, kind="dust", seed=1):
    if kind == "dust":
        dust = lambda p: np.where((p[:, 2] < -0.2 + sdf.noise(p, 0.15, seed) * 0.12)[:, None], hexc("#b88af0")[None, :] * (0.75 + 0.5 * (sdf.noise(p, 0.04, seed + 1)[:, None] > 0.6)), hexc(GLASS)[None, :])
        return shot([(lambda p: sphere(p, v3(0, 0, -0.26), 0.46), dust, "glass")] + neck_cork(0.18, 0.13, 0.2) + [(lambda p: torus(p, v3(0, 0, 0.14), 0.15, 0.03), "#8a7650", "matte")], seed, 0.1)
    if kind == "feather":
        T = lambda p: rot_y(p, 0.5)
        barbs = lambda p: hexc("#3e4a66")[None, :] * (0.7 + 0.5 * (np.sin((T(p)[:, 2] + np.abs(T(p)[:, 0]) * 1.5) * 40) > 0))[:, None]
        return shot([(lambda p: np.maximum(ell(T(p), v3(0, 0, 0.12), (0.26, 0.03, 0.66)), -ell(T(p), v3(0.28, 0, -0.2), (0.12, 0.2, 0.1))), barbs, "matte"),
            (lambda p: cap(T(p), v3(0, -0.03, -0.85), v3(0, -0.03, 0.7), 0.03, 0.01), "#d8d0b8", "matte")], seed, 0.05)
    if kind == "shard":
        return shot([(lambda p: np.minimum(kite(rot_y(p, 0.25), v3(-0.05, 0, 0.0), 0.3, 0.8, 0.6, 0.24), kite(rot_y(p, -0.5), v3(0.3, 0, -0.3), 0.16, 0.4, 0.3, 0.14)), "#6aa8e0", "gem"),
            (lambda p: cap(rot_y(p, 0.25), v3(-0.05, -0.15, 0.5), v3(-0.05, -0.15, -0.35), 0.022), "#d0f0ff", "glow")], seed, 0.05)
    if kind == "bead":      # 눈처럼 보이지 않게: 소용돌이 얼룩만
        swirl = lambda p: hexc("#5a3a8a")[None, :] + (np.clip(np.sin(np.arctan2(p[:, 2], p[:, 0]) * 3 + np.hypot(p[:, 0], p[:, 2]) * 14) * 0.5 + 0.2, 0, 1)[:, None] * hexc("#7a70d0")[None, :] * 0.7)
        return shot([(lambda p: sphere(p, v3(0, 0, 0), 0.6), swirl, "glass")], seed, 0.0)
    chip = rough(lambda p: np.maximum(box(rot_z(p, 0.0), v3(0, 0, 0), (0.5, 0.14, 0.62), 0.06), (np.abs(p[:, 0]) + p[:, 2] * 0.6) - 0.74), 0.06, 0.3, seed)
    mark = lambda p: np.minimum.reduce([cap(p, v3(a, -0.15, b), v3(c2, -0.15, d), 0.028) for a, b, c2, d in ((0, 0.3, 0, -0.4), (0, 0.3, -0.22, 0.0), (0, -0.05, 0.22, -0.3), (-0.2, -0.4, 0.2, -0.4))])
    return shot([(chip, "#68665e", "matte"), (mark, "#80d0c0", "glow")], seed, 0.05)


# ── 7-3 기타 ─────────────────────────────────────────────────────────────────

def _key(mat, bow="ring", bend=0.0, cut=None):
    T = lambda p: rot_y(p, -0.6)

    def shaft(p):
        q = T(p)
        if bend:
            q = q + np.stack([np.clip(-q[:, 2] - 0.1, 0, 1) ** 2 * bend, q[:, 0] * 0, q[:, 0] * 0], 1)
        d = np.minimum(cap(q, v3(0, 0, 0.2), v3(0, 0, -0.8), 0.055), np.minimum(box(q, v3(0.13, 0, -0.68), (0.13, 0.04, 0.1)), box(q, v3(0.1, 0, -0.44), (0.1, 0.04, 0.06))))
        d = np.minimum(d, torus(rot_x(q, 0), v3(0, 0, 0.14), 0.07, 0.03))
        return d if cut is None else np.maximum(d, cut(q))
    if bow == "ring":
        head = lambda p: ring_x(T(p), v3(0, 0, 0.5), 0.24, 0.065)
    elif bow == "trefoil":
        head = lambda p: np.minimum.reduce([ring_x(T(p), v3(x, 0, zz), 0.15, 0.05) for x, zz in ((0, 0.66), (-0.2, 0.38), (0.2, 0.38))])
    else:
        head = lambda p: sub(box(T(p), v3(0, 0, 0.46), (0.22, 0.05, 0.22), 0.04), box(T(p), v3(0, 0, 0.46), (0.11, 0.2, 0.11), 0.02))
    return [(shaft, mat, "metal"), (head, mat, "metal")]


@item("item_key", "열쇠(아이템)", {"ornate": {"mat": BRASS, "bow": "trefoil"}, "iron": {"mat": IRON, "bow": "ring"}, "small": {"mat": STEEL, "bow": "square"}}, ["key"])
def item_key(c, mat=BRASS, bow="ring", seed=1):
    return shot(_key(mat, bow), seed, 0.05)


@item("item_key_old", "낡은 열쇠", {"rusty": {}, "bent": {"bend": 0.5}, "broken": {"broken": True}}, ["key", "old"])
def item_key_old(c, bend=0.0, broken=False, seed=1):
    rust = speck("#5a4438", "#8a4e30", 0.12, 0.45, seed, 5.0)
    if broken:
        parts = _key(rust, "ring", 0.0, lambda q: -q[:, 2] - 0.25 + q[:, 0] * 0.6)
        T = lambda p: rot_y(p, 1.2, (0.3, 0, -0.5))
        parts.append((lambda p: np.minimum(cap(T(p), v3(0.3, 0, -0.3), v3(0.3, 0, -0.75), 0.055), box(T(p), v3(0.43, 0, -0.62), (0.13, 0.04, 0.1))), rust, "metal"))
        return shot(parts, seed, 0.05)
    return shot(_key(rust, "ring", bend), seed, 0.05)


@item("item_treasure_box", "보물 상자(아이템)", {"closed": {}, "open": {"open": True}, "jeweled": {"jewel": True}}, ["container", "treasure"])
def item_treasure_box(c, open=False, jewel=False, seed=1):
    wood = "#3a2e34" if jewel else WOOD
    trim = GOLD if jewel else BRASS
    a = -1.1 if open else 0.0
    L = lambda p: rot_x(p, a, (0, 0.34, 0.0))
    parts = [(lambda p: sub(box(p, v3(0, 0, -0.3), (0.62, 0.36, 0.3), 0.03), box(p, v3(0, 0, -0.1), (0.54, 0.28, 0.3))) if open else box(p, v3(0, 0, -0.3), (0.62, 0.36, 0.3), 0.03), wood, "matte"),
        (lambda p: np.maximum(hcyl(L(p), v3(-0.62, 0, 0.0), v3(0.62, 0, 0.0), 0.36), -L(p)[:, 2]), wood, "matte"),
        (lambda p: np.minimum.reduce([np.maximum(hcyl(L(p), v3(x - 0.05, 0, 0.0), v3(x + 0.05, 0, 0.0), 0.385), -L(p)[:, 2]) for x in (-0.42, 0.42)] + [box(p, v3(x, 0, -0.3), (0.05, 0.385, 0.31)) for x in (-0.42, 0.42)]), trim, "metal"),
        (lambda p: box(p, v3(0, -0.38, -0.12), (0.09, 0.03, 0.11), 0.02), trim, "metal")]
    if open:
        parts.append((rough(lambda p: ell(p, v3(0, 0, -0.1), (0.5, 0.26, 0.12)), 0.08, 0.08, seed), GOLD, "metal"))
    if jewel:
        parts.append((lambda p: kite(L(p), v3(0, -0.36, 0.14), 0.1, 0.12, 0.12, 0.08), "#b03a48", "gem"))
    return shot(parts, seed, 0.4, 0.35)


@item("item_scroll", "두루마리(아이템)", {"rolled": {"kind": "rolled"}, "sealed": {"kind": "sealed"}, "open": {"kind": "open"}}, ["document"])
def item_scroll(c, kind="rolled", seed=1):
    if kind == "open":
        return shot([sheet(v3(0, 0, 0), 0.5, 0.56, lines(PAPER, "#4a4034", 0.12, seed, -0.38, 0.4, -0.45, 0.45)),
            (lambda p: np.minimum(hcyl(p, v3(-0.6, -0.03, 0.62), v3(0.6, -0.03, 0.62), 0.11), hcyl(p, v3(-0.6, -0.03, -0.62), v3(0.6, -0.03, -0.62), 0.11)), PAPER, "matte"),
            (lambda p: np.minimum(hcyl(p, v3(-0.7, -0.03, 0.62), v3(0.7, -0.03, 0.62), 0.045), hcyl(p, v3(-0.7, -0.03, -0.62), v3(0.7, -0.03, -0.62), 0.045)), WOOD_D, "matte")], seed, 0.05)
    T = lambda p: rot_y(p, -0.5)
    parts = [(lambda p: hcyl(T(p), v3(-0.66, 0, 0), v3(0.66, 0, 0), 0.24), PAPER, "matte"),
        (lambda p: np.minimum(hcyl(T(p), v3(-0.7, 0, 0), v3(-0.66, 0, 0), 0.17), hcyl(T(p), v3(0.66, 0, 0), v3(0.7, 0, 0), 0.17)), "#8a7a58", "matte"),
        (lambda p: hcyl(T(p), v3(-0.06, 0, 0), v3(0.06, 0, 0), 0.265), "#7a3430", "matte")]
    if kind == "sealed":
        parts.append((rough(lambda p: ell(T(p), v3(0, -0.27, 0), (0.15, 0.05, 0.15)), 0.03, 0.08, seed), "#8e2a26", "matte"))
    else:
        parts.append((lambda p: cap(T(p), v3(0, -0.2, -0.2), v3(0.1, -0.2, -0.5), 0.035), "#7a3430", "matte"))
    return shot(parts, seed, 0.2, 0.25)


@item("item_book", "책(아이템)", {"closed": {"kind": "closed"}, "clasp": {"kind": "clasp"}, "tome": {"kind": "tome"}}, ["document", "book"])
def item_book(c, kind="closed", seed=1):
    d = 0.2 if kind == "tome" else 0.12
    cover = {"closed": "#5a3e30", "clasp": "#34425a", "tome": "#3a2a34"}[kind]
    parts = [(lambda p: box(p, v3(0, 0, 0), (0.5, d, 0.66), 0.03), cover, "matte"), (lambda p: box(p, v3(0.03, 0, 0), (0.5, d - 0.035, 0.62)), lines(PAPER, "#8a7e62", 0.035, seed), "matte"),
        (lambda p: hcyl(p, v3(-0.5, 0, -0.66), v3(-0.5, 0, 0.66), d) if False else cap(p, v3(-0.5, 0, -0.62), v3(-0.5, 0, 0.62), d), cover, "matte")]
    if kind != "closed":
        parts.append((lambda p: np.minimum.reduce([box(p, v3(sx * 0.42, -d, sz * 0.58), (0.09, 0.02, 0.09), 0.01) for sx in (-0.7, 1) for sz in (-1, 1)]), BRASS, "metal"))
        parts.append((lambda p: box(p, v3(0.44, -d * 0.4, 0), (0.09, d * 0.9, 0.09), 0.02), BRASS, "metal"))
    if kind == "tome":
        parts.append((lambda p: ell(p, v3(0, -d, 0.05), (0.16, 0.04, 0.22)), "#6a4a9a", "gem"))
        parts.append((lambda p: ring_x(p, v3(0, -d, 0.05), 0.26, 0.025), BRASS, "metal"))
    else:
        parts.append((lambda p: np.minimum(box(p, v3(0, -d, 0.4), (0.3, 0.012, 0.02)), box(p, v3(0, -d, -0.4), (0.3, 0.012, 0.02))), "#8a7650", "matte"))
    return shot(parts, seed, 0.12, 0.3)


def _route(base, seed):
    """지도 그림: 끊긴 길 점선 + 물결 + 표시(글자 없음)."""
    b, k, r = hexc(base), hexc("#4a4034"), hexc("#8e2a26")

    def fn(p):
        x, zz = p[:, 0], p[:, 2]
        path = np.abs(zz - np.sin(x * 4.0 + seed) * 0.22 - x * 0.3) < 0.022
        dash = np.floor(x / 0.07) % 2 == 0
        hill = (np.abs(np.hypot(x + 0.25, zz - 0.3) - 0.13) < 0.015) & (zz > 0.3)
        wave = (np.abs(zz + 0.4 - np.sin(x * 22) * 0.02) < 0.012) & (x > 0.0)
        mark = (np.minimum(np.abs((x - 0.34) - (zz - 0.3)), np.abs((x - 0.34) + (zz - 0.3))) < 0.022) & (np.hypot(x - 0.34, zz - 0.3) < 0.1)
        out = b[None, :] * (0.9 + sdf.noise(p, 0.3, seed)[:, None] * 0.18)
        out = np.where(((path & dash) | hill | wave)[:, None], k[None, :], out)
        return np.where(mark[:, None], r[None, :], out)
    return fn


@item("item_map", "지도(아이템)", {"folded": {"kind": "folded"}, "unrolled": {"kind": "unrolled"}, "fragment": {"kind": "fragment"}}, ["document", "map"])
def item_map(c, kind="unrolled", seed=1):
    if kind == "folded":
        return shot([(lambda p: box(rot_y(p, 0.12), v3(0.04, 0.04, 0), (0.4, 0.05, 0.6), 0.02), "#b4a680", "matte"),
            (lambda p: box(rot_y(p, -0.08), v3(-0.04, -0.05, -0.02), (0.4, 0.04, 0.6), 0.02), _route(PAPER, seed), "matte"),
            (lambda p: box(p, v3(0, -0.1, 0), (0.46, 0.02, 0.05), 0.01), "#7a3430", "matte")], seed, 0.1, 0.3)
    if kind == "fragment":
        torn = lambda p: np.maximum(box(rot_y(p, 0.15), v3(0, 0, 0), (0.56, 0.02, 0.56), 0.01), (p[:, 0] * 0.8 + p[:, 2] * 0.6) - 0.35 - sdf.noise(p, 0.1, seed) * 0.16)
        return shot([(torn, _route("#b8a880", seed + 2), "matte")], seed, 0.05)
    return shot([sheet(v3(0, 0, 0), 0.66, 0.5, _route(PAPER, seed)),
        (lambda p: np.minimum(hcyl(p, v3(-0.7, -0.04, -0.52), v3(-0.7, -0.04, 0.52), 0.08), hcyl(p, v3(0.7, -0.04, -0.52), v3(0.7, -0.04, 0.52), 0.08)), "#b4a680", "matte")], seed, 0.05)


@item("item_document", "문서(아이템)", {"letter": {"kind": "letter"}, "contract": {"kind": "contract"}, "note": {"kind": "note"}}, ["document"])
def item_document(c, kind="letter", seed=1):
    if kind == "letter":
        fold = lambda p: np.where((np.abs(np.abs(p[:, 0]) * 0.75 + p[:, 2] - 0.1) < 0.018)[:, None] & (p[:, 2] > -0.3)[:, None], hexc("#7a6e54")[None, :], hexc(PAPER)[None, :] * (0.92 + sdf.noise(p, 0.3, seed)[:, None] * 0.14))
        return shot([(lambda p: box(rot_y(p, 0.1), v3(0, 0, 0), (0.66, 0.03, 0.46), 0.02), fold, "matte"),
            (rough(lambda p: ell(p, v3(0, -0.06, -0.06), (0.16, 0.05, 0.16)), 0.04, 0.08, seed), "#8e2a26", "matte")], seed, 0.1)
    if kind == "contract":
        return shot([sheet(v3(0.05, 0.04, 0.02), 0.5, 0.66, "#b4a680", 0.02, -0.08), sheet(v3(0, 0, 0), 0.5, 0.66, lines(PAPER, "#4a4034", 0.12, seed, -0.38, 0.4, -0.2, 0.55), 0.02, 0.05),
            (lambda p: np.minimum(cap(p, v3(0.2, -0.04, -0.4), v3(0.12, -0.04, -0.72), 0.04), cap(p, v3(0.26, -0.04, -0.4), v3(0.36, -0.04, -0.7), 0.04)), "#34425a", "matte"),
            (rough(lambda p: ell(p, v3(0.23, -0.06, -0.4), (0.13, 0.04, 0.13)), 0.03, 0.08, seed), "#8e2a26", "matte")], seed, 0.05)
    torn = lambda p: np.maximum(box(rot_y(p, -0.2), v3(0, 0, 0), (0.46, 0.02, 0.5), 0.01), -p[:, 2] - 0.34 - sdf.noise(p, 0.08, seed) * 0.14)
    return shot([(torn, lines("#beb08a", "#4a4034", 0.14, seed, -0.32, 0.34, -0.2, 0.4), "matte"), (lambda p: sphere(p, v3(0, -0.04, 0.4), 0.05), IRON, "metal")], seed, 0.05)


@item("item_relic", "유물(아이템)", {"disc": {"kind": "disc"}, "crown_piece": {"kind": "crown"}, "device": {"kind": "device"}}, ["relic", "old"])
def item_relic(c, kind="disc", seed=1):
    if kind == "disc":
        bronze = speck("#6a5c40", "#4e7a68", 0.14, 0.55, seed, 5.0)
        crack = lambda p: p[:, 0] * 0.9 - p[:, 2] * 0.3 - 0.3 + sdf.noise(p, 0.12, seed) * 0.12
        return shot([(lambda p: np.maximum(disc_x(p, v3(0, 0, 0), 0.7, 0.05), -np.abs(crack(p)) + 0.02), bronze, "metal"),
            (lambda p: np.minimum(ring_x(p, v3(0, -0.05, 0), 0.52, 0.03), ring_x(p, v3(0, -0.05, 0), 0.3, 0.03)), bronze, "metal"),
            (lambda p: sub(ell(p, v3(0, -0.05, 0), (0.14, 0.05, 0.14)), sphere(p, v3(0, -0.12, 0), 0.07)), bronze, "metal")], seed, 0.05, 0.25)
    if kind == "crown":
        gold = speck("#a88a44", "#5e5238", 0.16, 0.5, seed, 4.0)
        band = lambda p: np.maximum(np.maximum(sub(cyl(p, v3(0, 0.3, -0.5), 0.72, 0.36), cyl(p, v3(0, 0.3, -0.6), 0.66, 0.6)), p[:, 1] - 0.1), np.abs(p[:, 0]) - 0.66 + sdf.noise(p, 0.1, seed) * 0.08)
        pts = lambda p: np.minimum(kite(p, v3(-0.3, -0.33, -0.05), 0.13, 0.42, 0.14, 0.05), np.maximum(kite(p, v3(0.25, -0.36, -0.05), 0.13, 0.42, 0.14, 0.05), p[:, 2] - 0.08 - p[:, 0] * 0.3))
        return shot([(band, gold, "metal"), (pts, gold, "metal"), (lambda p: sub(sphere(p, v3(0, -0.4, -0.32), 0.1), sphere(p, v3(0, -0.47, -0.32), 0.07)), "#3a3028", "matte")], seed, 0.2)
    return shot([(lambda p: sub(cyl(p, v3(0, 0, -0.15), 0.64, 0.24, 0.04), cyl(p, v3(0, 0, 0.0), 0.54, 0.3)), BRASS, "metal"), (lambda p: cyl(p, v3(0, 0, -0.1), 0.54, 0.12), speck("#c0b490", "#8a7e62", 0.2, 0.55, seed, 3.0), "matte"),
        (lambda p: np.minimum(kite(rot_z(rot_x(p, np.pi / 2, (0, 0, 0.04)), 0.7), v3(0, 0, 0.04), 0.07, 0.42, 0.42, 0.03), cyl(p, v3(0, 0, 0.0), 0.06, 0.08)), IRON, "metal"),
        (lambda p: np.minimum(ring_x(p, v3(0, 0.62, 0.3), 0.14, 0.035), torus(p, v3(0, 0, 0.09), 0.64, 0.035)), BRASS, "metal")], seed, 0.95)


@item("item_trinket", "장신구(아이템)", {"ring": {"kind": "ring"}, "necklace": {"kind": "necklace"}, "brooch": {"kind": "brooch"}, "bracelet": {"kind": "bracelet"}}, ["jewelry"])
def item_trinket(c, kind="ring", seed=1):
    if kind == "ring":
        return shot([(lambda p: ring_x(p, v3(0, 0, -0.15), 0.46, 0.085), GOLD, "metal"), (lambda p: cyl(p, v3(0, 0, 0.3), 0.17, 0.1, 0.02), GOLD, "metal"),
            (lambda p: kite(p, v3(0, 0, 0.5), 0.2, 0.2, 0.14, 0.18), "#3e9a6a", "gem")], seed, 0.1, 0.3)
    if kind == "necklace":
        beads = [v3(np.sin(a) * 0.6, 0, 0.5 - np.cos(a) * 0.0 - (1 - np.abs(np.sin(a))) * 0.0 - np.cos(a) * 0.75) for a in np.linspace(-1.35, 1.35, 15)]
        return shot([(lambda p: np.minimum.reduce([sphere(p, b, 0.055) for b in beads]), GOLD, "metal"), (lambda p: ring_x(p, v3(0, 0, -0.32), 0.07, 0.022), GOLD, "metal"),
            (lambda p: smin(sphere(p, v3(0, 0, -0.56), 0.17), cap(p, v3(0, 0, -0.5), v3(0, 0, -0.36), 0.08, 0.03), 0.06), "#4a78c0", "gem")], seed, 0.05)
    if kind == "brooch":
        return shot([(lambda p: ell(p, v3(0, 0, 0), (0.6, 0.08, 0.46)), BRASS, "metal"), (lambda p: np.minimum.reduce([sphere(p, v3(np.cos(a) * 0.5, -0.06, np.sin(a) * 0.37), 0.055) for a in np.linspace(0, 2 * np.pi, 12, endpoint=False)]), GOLD, "metal"),
            (lambda p: ell(p, v3(0, -0.08, 0), (0.34, 0.1, 0.24)), "#b03a48", "gem"), (lambda p: cap(p, v3(-0.75, 0.05, -0.2), v3(0.78, 0.05, 0.2), 0.022, 0.01), STEEL, "metal")], seed, 0.05)
    return shot([(lambda p: torus(p, v3(0, 0, 0), 0.56, 0.1), speck("#8a8e94", "#5a5e66", 0.2, 0.5, seed, 3.0), "metal"),
        (lambda p: np.minimum.reduce([sphere(p, v3(np.cos(a) * 0.56, np.sin(a) * 0.56, 0.08), 0.07) for a in np.linspace(0, 2 * np.pi, 8, endpoint=False)]), "#4e7a8a", "gem")], seed, 0.85)


@item("item_gold_coin", "금화(아이템)", {"single": {"kind": "single"}, "stack": {"kind": "stack"}, "pile": {"kind": "pile"}}, ["money", "treasure"])
def item_gold_coin(c, kind="single", seed=1):
    if kind == "single":
        return shot(coin_x(v3(0, 0, 0), 0.62, 0.35), seed, 0.05)
    if kind == "stack":
        return shot([coin_z(v3(np.sin(i * 2.1) * 0.035, np.cos(i * 1.7) * 0.03, -0.6 + i * 0.12), 0.42) for i in range(8)] + [(lambda p: torus(p, v3(0, 0, 0.4), 0.3, 0.02), GOLD, "metal")], seed, 0.5)
    rng = np.random.default_rng(seed + 9)
    parts = [(rough(lambda p: ell(p, v3(0, 0.1, -0.5), (0.7, 0.45, 0.3)), 0.05, 0.1, seed), "#a88a40", "metal")]
    for i in range(16):
        x, y = rng.uniform(-0.6, 0.6), rng.uniform(-0.4, 0.3)
        h = -0.42 + 0.3 * (1 - np.hypot(x / 0.7, y / 0.5)) + rng.uniform(0, 0.05)
        ax, ay = rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5)
        parts.append((lambda p, c0=v3(x, y, h), ax=ax, ay=ay: cyl(rot_x(rot_y(p, ay, c0), ax, c0), c0, 0.17, 0.04, 0.01), GOLD, "metal"))
    return shot(parts + coin_x(v3(0.5, -0.5, -0.5), 0.17, 0.5), seed, 0.6)


@item("item_gem_pouch", "보석 주머니", {"closed": {}, "open": {"open": True}}, ["treasure", "container"])
def item_gem_pouch(c, open=False, seed=1):
    if not open:
        return shot([(rough(lambda p: smin(ell(p, v3(0, 0, -0.22), (0.56, 0.44, 0.5)), cap(p, v3(0, 0, 0.2), v3(0, 0, 0.55), 0.14, 0.26), 0.2), 0.06, 0.25, seed), LEATHER, "matte"),
            (lambda p: torus(p, v3(0, 0, 0.3), 0.17, 0.045), "#8a7650", "matte"), (lambda p: cap(p, v3(0.15, -0.1, 0.3), v3(0.4, -0.15, -0.05), 0.03), "#8a7650", "matte")], seed, 0.15)
    T = lambda p: rot_y(p, 1.0, (0, 0, -0.3))
    parts = [(rough(lambda p: sub(smin(ell(T(p), v3(0, 0, -0.3), (0.42, 0.4, 0.5)), cap(T(p), v3(0, 0, 0.1), v3(0, 0, 0.42), 0.16, 0.26), 0.2), cap(T(p), v3(0, 0, 0.2), v3(0, 0, 0.6), 0.13, 0.22)), 0.05, 0.25, seed), LEATHER, "matte"),
        (lambda p: torus(T(p), v3(0, 0, 0.16), 0.19, 0.04), "#8a7650", "matte")]
    for x, y, zz, col, s in ((0.42, -0.2, -0.56, "#b03a48", 0.15), (0.66, 0.0, -0.6, "#3e9a6a", 0.13), (0.3, -0.36, -0.66, "#4a78c0", 0.12), (0.56, -0.36, -0.68, "#c2a04a", 0.1), (0.76, -0.26, -0.68, "#8a5ab8", 0.11)):
        parts.append((lambda p, x=x, y=y, zz=zz, s=s: kite(rot_z(p, x * 3, (x, y, zz)), v3(x, y, zz), s, s, s, s), col, "gem"))
    return shot(parts, seed, 0.3)
