"""도시 건물 겉(1) — 집 앞면을 조립하는 벽 조각: 석조 · 목골(나무 뼈대 + 회반죽) · 회벽 집 벽, 벽 모서리, 벽 끝, 층 사이 띠.
카메라는 북쪽을 본다 — 보이는 것은 벽의 남쪽 면과 그 위 지붕(a_city_build2.py)이다.

조립 규칙(한 칸 = 폭 1 · 벽 높이 2.5):
  - 벽 조각의 원점 = 벽 밑동 선의 칸 가운데. 조각을 한 칸 간격으로 나란히 놓으면 이어진다 — 그림을 칸보다 넓게 빚은 뒤 좌우를 칸 폭으로
    잘라(crop) 이음매에 잉크 윤곽이 생기지 않고, 재질 무늬(돌 줄눈 · 얼룩)는 폭 1칸 주기라 옆 칸과 맞물린다.
  - 줄의 끝에는 house_wall_end(끝 선에 원점 — 0.24칸 내밀어 윤곽을 닫는다)나 house_corner(끝 선 · 두 줄이 만나는 선에 얹는 모서리돌 · 모서리 기둥).
  - 2층은 같은 벽 조각을 2.5칸 올려(up) 쌓고 그 사이에 house_band(돌림띠 · 내민 들보)를 얹는다.
모든 조각은 묶음 그림 city_build에 들어간다. tags: straight 직선형 · corner 모서리형 · joint 연결형 · ornament 장식형."""
import numpy as np

import sdf
import mats as M
from kit import F, WALL_H, box, cap, cut_above, cyl, ell, hcyl, prop, rot_y, rot_z, rough, sphere, sub, torus, v3  # noqa: F401

SHEET = {"sheet": "city_build"}
HW = 0.8                      # 벽을 빚는 반폭(칸) — 그린 뒤 ±0.5로 자른다
WZ, WW, WH = 1.45, 0.2, 0.3   # 벽 속 창: 가운데 높이 · 반폭 · 반높이
WARM = "#e0a850"


def meta(**kw):
    return dict(SHEET, **kw)


def crop(x0=-0.5, x1=0.5):
    """그림을 x0~x1(칸)만 남기고 지운다(+1px 겹침) — 옆 칸과 이어지는 조각."""
    def fn(img, vw):
        img = img.copy()
        if x0 is not None:
            img[:, :max(0, int(round(vw.ox + x0 * vw.u)) - 1)] = 0
        if x1 is not None:
            img[:, int(round(vw.ox + x1 * vw.u)) + 1:] = 0
        return img
    return fn


def pfbm(p, scale, seed, octv=2, s=None):
    """x로 폭 1칸 주기인 잡음(-0.5와 +0.5에서 값이 같다)."""
    t = np.clip(p[:, 0] + 0.5, 0, 1)
    q = p - np.array([1, 0, 0], F)
    if s is not None:
        p, q = p * s, q * s
    return sdf.fbm(p, scale, seed, octv) * (1 - t) + sdf.fbm(q, scale, seed, octv) * t


def crack_mask(p, n, seed):
    """벽 앞면을 타고 내려오는 금 한 줄기 + 가지."""
    z, x = p[:, 2], p[:, 0]
    x0 = ((seed * 37) % 40) / 100.0 - 0.2
    line = lambda zz: x0 + 0.07 * np.sin(zz * 4.3 + seed) + 0.03 * np.sin(zz * 11.0 + seed * 2.1) + (zz - 1.2) * 0.1
    w = 0.007 + 0.012 * np.clip((z - 0.5) / 2.0, 0, 1)
    m = (np.abs(x - line(z)) < w) & (z > 0.5) & (z < 2.42)
    lx = line(1.5)
    m |= (np.abs(x - (lx - (z - 1.5) * 0.5)) < 0.007) & (z > 1.5) & (z < 2.0)
    return m & (n[:, 1] < -0.5)


def ashlar(base, seed=1, course=0.25, ln=0.5, worn=0.0, crack=0, moss="#4a5236"):
    """다듬은 마름돌 쌓기(폭 1칸 주기)."""
    base, mossc = M.hexc(base), M.hexc(moss)
    ncol = int(round(1.0 / ln))

    def fn(p, n):
        z = p[:, 2]
        row = np.floor(z / course)
        along = p[:, 0] + 0.5 + (row % 2) * ln * 0.5
        col = np.floor(along / ln)
        fz, fa = z / course - row, along / ln - col
        ids = sdf._hash(row, col % ncol, row * 0, seed)
        top = n[:, 2] > 0.7
        joint = np.where(top, 0.0, ((fz < 0.1) | (fa < 0.025 / ln)).astype(F))
        c = base[None, :] * (0.82 + ids * 0.32)[:, None] * (1 - joint * 0.45)[:, None]
        c = c + (sdf._hash(col % ncol, row, row * 0, seed + 2)[:, None] - 0.5) * np.array([0.03, 0.0, -0.03], F)
        st = pfbm(p, 0.16, seed + 3, 2, np.array([1, 1, 0.22], F))
        c = c * (0.86 + st * 0.28)[:, None] * (0.78 + 0.22 * np.clip(z / 0.5, 0, 1))[:, None]
        if worn > 0:
            damp = np.clip((pfbm(p, 0.6, seed + 8, 2) - 0.4) * 3.0, 0, 1)
            c = c * (1 - worn * 0.3 * damp)[:, None]
            m = np.clip((pfbm(p, 0.4, seed + 5, 3) - 0.5) * 5.0 + np.clip(0.7 - z, 0, 0.7) * 0.9, 0, 1) * worn * 0.8
            c = c * (1 - m[:, None]) + mossc[None, :] * (m * (0.8 + sdf.noise(p, 0.05, seed + 6) * 0.4))[:, None]
        idv = np.floor(ids * 97)
        if crack:
            cm = crack_mask(p, n, crack)
            c = c * (1 - cm[:, None] * 0.85)
            idv = np.where(cm, 200.0, idv)
        return M._out(c, idv)
    return fn


def plaster(base, seed=1, worn=0.0, crack=0, under="#6e5648"):
    """회반죽 벽(폭 1칸 주기): worn = 떨어져 나간 자리에 속 벽돌이 드러난다."""
    base, brick = M.hexc(base), M.hexc(under)

    def fn(p, n):
        z = p[:, 2]
        c = base[None, :] * (0.9 + pfbm(p, 0.3, seed, 3) * 0.2)[:, None]
        st = pfbm(p, 0.14, seed + 3, 2, np.array([1, 1, 0.2], F))
        c = c * (0.9 + st * 0.2)[:, None] * (0.74 + 0.26 * np.clip(z / 0.6, 0, 1))[:, None]
        idv = np.zeros(len(p), F)
        if worn > 0:
            c = c * (1 - worn * 0.22 * np.clip((pfbm(p, 0.5, seed + 12, 2) - 0.42) * 3.0, 0, 1))[:, None]
            gone = (pfbm(p, 0.32, seed + 9, 3) + np.clip(0.9 - z, 0, 0.9) * 0.12) > (0.66 - worn * 0.1)
            row = np.floor(z / 0.11)
            along = p[:, 0] + 0.5 + (row % 2) * 0.125
            col = np.floor(along / 0.25)
            h = sdf._hash(row, col % 4, row * 0, seed + 4)
            joint = ((z / 0.11 - row) < 0.16) | ((along / 0.25 - col) < 0.07)
            bc = brick[None, :] * (0.8 + h * 0.35)[:, None] * (1 - joint * 0.5)[:, None]
            c = np.where(gone[:, None], bc, c)
            idv = np.where(gone, 20 + np.floor(h * 9), 0.0)
        if crack:
            cm = crack_mask(p, n, crack)
            c = c * (1 - cm[:, None] * 0.8)
            idv = np.where(cm, 200.0, idv)
        return M._out(c, idv)
    return fn


def beam(base, seed=4, axis=0):
    """집 뼈대 들보 · 기둥(결이 axis 방향, 폭 1칸 주기)."""
    base = M.hexc(base)

    def fn(p, n):
        s = np.ones(3, F)
        s[axis] = 0.1
        g = pfbm(p, 0.05, seed, 2, s)
        return M._out(base[None, :] * (0.66 + g * 0.55)[:, None], np.floor(g * 2.5))
    return fn


def house_mats(k, seed=1, worn=0.0, crack=0):
    k.mat("h_stone", ashlar("#77746b", seed, worn=worn, crack=crack))
    k.mat("h_plinth", ashlar("#5e5c56", seed + 20, 0.17, 0.5, worn * 0.7))
    k.mat("h_trim", ashlar("#8e8a7e", seed + 21, 0.5, 1.0))
    k.mat("h_plaster", plaster("#978f7e", seed, worn, crack))
    k.mat("h_infill", plaster("#a39a86", seed + 1, worn, crack, "#5a4a3a"))
    k.mat("h_beam", beam("#4a3828", seed + 4, 0))
    k.mat("h_post", beam("#463426", seed + 5, 2))
    k.mat("h_shut", M.wood("#5c4a34", 0.075, 2, seed + 6))
    k.mat("h_pane", M.plain("#20262c", 0.35, 0.12, seed + 7))
    k.mat("h_lit", M.glow("#d9a24c"))


# ── 창 · 문 부품(벽 속 · 낱개 공용 — a_city_build2도 쓴다) ────────────────────

def sd_open(shape, cx, cz, hw, hh):
    """창 · 문 구멍의 xz 단면 거리 함수: square · arch(둥근 머리) · round."""
    if shape == "round":
        return lambda p: np.hypot(p[:, 0] - cx, p[:, 2] - cz) - hw
    if shape == "arch":
        return lambda p: np.minimum(np.maximum(np.abs(p[:, 0] - cx) - hw, np.abs(p[:, 2] - (cz - hw / 2)) - (hh - hw / 2)), np.hypot(p[:, 0] - cx, p[:, 2] - (cz + hh - hw)) - hw)
    return lambda p: np.maximum(np.abs(p[:, 0] - cx) - hw, np.abs(p[:, 2] - cz) - hh)


def window(k, cx, cz, hw, hh, mode="shut", shape="square", yp=-0.005, frame="h_beam", sill="h_trim", seed=1):
    """창 한 짝. mode: shut 덧문 닫힘 · open 덧문 열림 · lit 불 켜짐 · bare 덧문 없음 · empty 유리 없음 · broken · boarded. yp = 유리 면의 y."""
    sd = sd_open(shape, cx, cz, hw, hh)
    big = sd_open(shape, cx, cz, hw + 0.05, hh + 0.05)
    k.add(lambda p: np.maximum.reduce([big(p), -sd(p), np.abs(p[:, 1] + 0.02) - 0.04]), frame)
    pane = "void" if mode in ("empty", "broken") else ("h_lit" if mode == "lit" else "h_pane")
    k.add(lambda p: np.maximum(sd(p), np.abs(p[:, 1] - yp) - 0.008), pane)
    if mode != "empty":
        k.add(lambda p: np.maximum(sd(p), np.minimum(np.maximum(np.abs(p[:, 0] - cx) - 0.012, np.abs(p[:, 1] - yp + 0.02) - 0.012), np.maximum(np.abs(p[:, 2] - cz - hh * 0.15) - 0.012, np.abs(p[:, 1] - yp + 0.02) - 0.012))), frame)
    if shape != "round":
        k.add(lambda p: box(p, v3(cx, -0.05, cz - hh - 0.075), (hw + 0.09, 0.07, 0.025), 0.008), sill)
    if mode == "broken":                              # 창틀 구석에 남은 유리 조각
        for i, (sx, sz, a) in enumerate(((-1, -1, 0.6), (1, -1, -0.5), (1, 1, 0.9), (-1, 0.3, -0.8))):
            c = v3(cx + sx * hw * 0.72, yp, cz + sz * hh * 0.72)
            k.add(lambda p, c=c, a=a: np.maximum(box(rot_y(p, a, c), c, (hw * 0.42, 0.006, hh * 0.3)), sd(p)), "glass")
    if mode == "boarded":
        for i, (dz, a) in enumerate(((-0.45, 0.12), (0.05, -0.1), (0.5, 0.07))):
            c = v3(cx, -0.07, cz + dz * hh)
            k.add(lambda p, c=c, a=a, i=i: box(rot_y(p, a, c), c, (hw + 0.1, 0.014, 0.055), 0.004) + sdf.noise(p, 0.05, seed + i) * 0.006, "plank_x")
            k.add(lambda p, c=c: np.minimum(sphere(p, c + v3(-hw - 0.04, -0.016, 0), 0.014), sphere(p, c + v3(hw + 0.04, -0.016, 0), 0.014)), "iron")
    if mode in ("shut", "open", "lit") and shape == "square":
        sw = hw / 2
        for sx in (-1, 1):
            x = cx + sx * (sw if mode == "shut" else hw + 0.06 + sw)
            k.add(lambda p, x=x: box(p, v3(x, -0.05, cz), (sw - 0.006, 0.018, hh), 0.004), "h_shut")
            k.add(lambda p, x=x: np.minimum(box(p, v3(x, -0.072, cz + hh * 0.6), (sw - 0.01, 0.006, 0.022)), box(p, v3(x, -0.072, cz - hh * 0.6), (sw - 0.01, 0.006, 0.022))), "iron")
    if mode == "lit":
        return [(cx, -0.1, cz, 46.0, WARM, 0.4)]
    return []


def leaf(k, x0, x1, z1, y, kind="wood", T=None, seed=1, z0=0.04, straps=True):
    """문짝 한 장(x0~x1 · z0~z1 · 면 y). T = 점을 문짝 좌표로 옮기는 변환(열린 문)."""
    T = T or (lambda p: p)
    cx, hw, cz, hz = (x0 + x1) / 2, (x1 - x0) / 2, (z0 + z1) / 2, (z1 - z0) / 2
    if kind == "wood":
        k.add(lambda p: (lambda q: box(q, v3(cx, y, cz), (hw, 0.03, hz), 0.004) + np.abs(np.sin((q[:, 0] - x0) * np.pi / 0.14)) * 0.006)(T(p)), k.mat("door_w", M.wood("#4e3b2a", 0.14, 2, seed + 7)))
        if straps:
            k.add(lambda p: (lambda q: np.minimum(box(q, v3(cx, y - 0.036, z0 + 0.26), (hw - 0.012, 0.01, 0.04)), box(q, v3(cx, y - 0.036, z1 - 0.3), (hw - 0.012, 0.01, 0.04))))(T(p)), "iron")
    else:
        k.add(lambda p: box(T(p), v3(cx, y, cz), (hw, 0.03, hz), 0.004), k.mat("door_i", M.metal("#45474c", "#6a4630", seed + 13, 0.45)))
        k.add(lambda p: (lambda q: np.minimum.reduce([box(q, v3(cx, y - 0.036, z), (hw - 0.008, 0.01, 0.045)) for z in (z0 + 0.12, cz, z1 - 0.14)]))(T(p)), "iron")
        k.add(lambda p: (lambda q: np.minimum.reduce([sphere(q, v3(sx, y - 0.05, z), 0.018) for z in (z0 + 0.12, cz, z1 - 0.14) for sx in np.linspace(x0 + 0.07, x1 - 0.07, 3)]))(T(p)), "steel")


def ring_handle(k, x, y, z, T=None):
    T = T or (lambda p: p)
    k.add(lambda p: (lambda q: np.minimum(sphere(q, v3(x, y, z + 0.045), 0.02), np.maximum(np.abs(np.hypot(q[:, 0] - x, q[:, 2] - z) - 0.04) - 0.009, np.abs(q[:, 1] - y + 0.012) - 0.009)))(T(p)), "brass")


# ── 집 벽 ────────────────────────────────────────────────────────────────────

def build_wall(k, kind, feat="plain", state="", brace=1, seed=1, x0=-HW, x1=HW, posts=(-0.5, 0.5)):
    worn = 1.0 if state == "worn" else 0.0
    house_mats(k, seed, worn, (seed + 3) if state == "cracked" else 0)
    cx, hx = (x0 + x1) / 2, (x1 - x0) / 2
    glow = []
    hole = None
    if feat.startswith("window"):
        sdw = sd_open("square", 0, WZ, WW, WH)
        hole = lambda p: np.maximum(sdw(p), np.abs(p[:, 1]) - 0.26)
    elif feat == "door":
        hole = lambda p: box(p, v3(0, 0, 0.8), (0.3, 0.5, 0.8))
    cut = (lambda fn: fn) if hole is None else (lambda fn: (lambda p: sub(fn(p), hole(p))))
    body = cut(lambda p: box(p, v3(cx, 0.2, WALL_H / 2), (hx, 0.2, WALL_H / 2), 0.008))
    ph = 0.3 if kind != "timber" else 0.25
    plinth = cut(lambda p: box(p, v3(cx, 0.185, ph / 2), (hx, 0.215, ph / 2), 0.012))
    bm = lambda xa, xb, za, zb, mat="h_beam": k.add(cut(lambda p: box(p, v3((xa + xb) / 2, 0.01, (za + zb) / 2), ((xb - xa) / 2, 0.04, (zb - za) / 2), 0.006)), mat)
    if kind == "stone":
        k.add(body, "h_stone")
        k.add(plinth, "h_plinth")
    elif kind == "plaster":
        k.add(body, "h_plaster")
        k.add(plinth, "h_plinth")
        bm(x0, x1, 2.38, 2.5)
    else:
        k.add(body, "h_infill")
        k.add(plinth, "h_plinth")
        bm(x0, x1, 0.25, 0.37)
        bm(x0, x1, 2.38, 2.5)
        for px in posts:
            bm(px - 0.065, px + 0.065, 0.25, 2.5, "h_post")
        if feat == "plain":
            bm(x0, x1, 1.25, 1.35)
            a, b = v3(-0.44 * brace, 0.01, 0.37), v3(0.44 * brace, 0.01, 1.25)
            k.add(lambda p: np.maximum(hcyl(p, a, b, 0.048), np.abs(p[:, 1] - 0.01) - 0.036), "h_post")
            bm(-0.045, 0.045, 1.35, 2.38, "h_post")
        elif feat == "end":
            bm(x0, x1, 1.25, 1.35)
        elif feat.startswith("window"):
            bm(x0, x1, WZ - WH - 0.17, WZ - WH - 0.07)
            bm(x0, x1, WZ + WH + 0.07, WZ + WH + 0.17)
        elif feat == "door":
            for sx in (-1, 1):
                bm(sx * 0.37 - 0.05, sx * 0.37 + 0.05, 0.0, 2.38, "h_post")
            bm(-0.42, 0.42, 1.62, 1.74)
            bm(-0.045, 0.045, 1.74, 2.38, "h_post")
    if feat.startswith("window"):
        mode = {"window": "shut", "window_open": "open", "window_lit": "lit"}[feat]
        glow = window(k, 0, WZ, WW, WH, mode, "square", 0.2, "h_trim" if kind == "stone" else "h_beam", "h_trim", seed)
    elif feat == "door":
        if kind == "stone":      # 돌 문설주 + 상인방
            k.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.35, 0.0, 0.82), (0.055, 0.05, 0.82), 0.01) for sx in (-1, 1)] + [box(p, v3(0, -0.01, 1.7), (0.46, 0.06, 0.09), 0.012)]), "h_trim")
        elif kind == "plaster":
            k.add(lambda p: np.minimum.reduce([box(p, v3(sx * 0.345, 0.0, 0.82), (0.05, 0.05, 0.82), 0.008) for sx in (-1, 1)] + [box(p, v3(0, 0.0, 1.67), (0.43, 0.05, 0.07), 0.008)]), "h_beam")
        k.add(lambda p: box(p, v3(0, 0.3, 0.8), (0.31, 0.02, 0.8)), "void")
        leaf(k, -0.29, 0.29, 1.58, 0.1, "wood", None, seed)
        ring_handle(k, 0.18, 0.06, 0.82)
        k.add(rough(lambda p: box(p, v3(0, -0.07, 0.03), (0.42, 0.11, 0.03), 0.012), 0.01, 0.2, seed), "stone_d")
    return glow


_WV = {"plain": {"seed": 1}, "plain_b": {"seed": 5, "brace": -1}, "worn": {"state": "worn", "seed": 2}, "cracked": {"state": "cracked", "seed": 3},
    "window": {"feat": "window", "seed": 4}, "window_open": {"feat": "window_open", "seed": 4}, "window_lit": {"feat": "window_lit", "seed": 4}, "door": {"feat": "door", "seed": 6}}
_WLIGHT = {"color": WARM, "radius": 2.5, "at": (0, -0.3, WZ), "flicker": 0.08, "variants": ["window_lit"]}
_WMETA = lambda note: meta(tile_w=1, module=[1, 0.4], states={"closed": "door"}, passage_variants=["door"], note=note)
_WCOL = (-0.5, 0.0, 1.0, 0.4)


def _wall_asset(id, kind, name, note, tags):
    @prop(id, "city", cell=(2, 4), collide=_WCOL, tags=["house", "wall", "straight", "module"] + tags, name_ko=name, variants=_WV, light=_WLIGHT, meta=_WMETA(note))
    def fn(k, feat="plain", state="", brace=1, seed=1):
        glow = build_wall(k, kind, feat, state, brace, seed)
        return {"foot": 1.0, "post": [crop()], "glow": glow, "shadow": 0.4}
    fn.__name__ = id
    return fn


house_wall_stone = _wall_asset("house_wall_stone", "stone", "석조 집 벽", "다듬은 마름돌 벽 한 칸 — 옆으로 이어 놓는다. window* = 덧문 창 · door = 나무 문(문 앞에서 상호작용)", ["stone"])
house_wall_timber = _wall_asset("house_wall_timber", "timber", "목골 집 벽", "나무 뼈대에 회반죽을 채운 벽 한 칸 — 기둥이 칸 경계에 선다. plain_b = 가새 방향이 반대", ["wood", "timber"])
house_wall_plaster = _wall_asset("house_wall_plaster", "plaster", "회벽 집 벽", "돌 밑단 위에 회반죽을 바른 벽 한 칸. worn = 회가 떨어져 속 벽돌이 드러났다", ["plaster"])


@prop("house_wall_end", "city", cell=(2, 4), collide=(0.24, 0.4), tags=["house", "wall", "joint", "module"], name_ko="집 벽 끝",
    variants={"%s_%s" % (kd, sd): {"kind": kd, "side": sd, "seed": 7 + i} for i, kd in enumerate(("stone", "timber", "plaster")) for sd in ("l", "r")},
    meta=meta(note="벽 줄이 끝나는 선에 원점을 둔다 — 0.24칸 내밀어 윤곽을 닫는다(r = 줄의 오른쪽 끝 · l = 왼쪽 끝)"))
def house_wall_end(k, kind="stone", side="r", seed=1):
    s = 1 if side == "r" else -1
    xa, xb = (-0.4, 0.24) if s > 0 else (-0.24, 0.4)
    build_wall(k, kind, "end", "", 1, seed, xa, xb, (s * 0.175,))
    return {"foot": 1.0, "post": [crop(0.0, None) if s > 0 else crop(None, 0.0)], "shadow": 0.4}


@prop("house_corner", "city", cell=(2, 4), collide=(0.4, 0.45), tags=["house", "wall", "corner", "module"], name_ko="집 벽 모서리",
    variants={"stone": {"kind": "stone"}, "timber": {"kind": "timber"}, "plaster": {"kind": "plaster"}, "stone_worn": {"kind": "stone", "worn": True}},
    meta=meta(note="벽 줄의 끝 선 · 두 줄이 만나는 선 위에 얹는다: stone = 길고 짧은 모서리돌 · timber = 굵은 모서리 기둥과 까치발 · plaster = 벽기둥"))
def house_corner(k, kind="stone", worn=False, seed=1):
    house_mats(k, seed, 1.0 if worn else 0.0)
    if kind == "stone":
        n = 8
        h = WALL_H / n
        for i in range(n):
            w = 0.2 if i % 2 == 0 else 0.13
            k.add(rough(lambda p, i=i, w=w: box(p, v3(0, 0.17, (i + 0.5) * h), (w, 0.23, h / 2 - 0.006), 0.02), 0.012, 0.15, seed + i), k.mat("q%d" % (i % 2), M.stone(("#8a867a", "#7c786e")[i % 2], MOSS if worn else None, seed + i)))
    elif kind == "timber":
        k.add(rough(lambda p: box(p, v3(0, 0.16, 0.12), (0.17, 0.24, 0.12), 0.02), 0.012, 0.15, seed), "h_plinth")
        k.add(lambda p: box(p, v3(0, 0.14, 1.37), (0.105, 0.2, 1.13), 0.012), "h_post")
        for sx in (-1, 1):
            a, b = v3(sx * 0.1, -0.02, 1.95), v3(sx * 0.36, -0.02, 2.42)
            k.add(lambda p, a=a, b=b: np.maximum(hcyl(p, a, b, 0.05), np.abs(p[:, 1] + 0.02) - 0.04), "h_post")
        k.add(lambda p: box(p, v3(0, 0.12, 2.46), (0.4, 0.2, 0.05), 0.008), "h_beam")
    else:
        k.add(lambda p: box(p, v3(0, 0.16, 0.17), (0.17, 0.24, 0.17), 0.015), "h_plinth")
        k.add(lambda p: box(p, v3(0, 0.16, 1.3), (0.125, 0.22, 1.0), 0.01), "h_plaster")
        k.add(lambda p: np.minimum(box(p, v3(0, 0.15, 2.36), (0.16, 0.24, 0.05), 0.012), box(p, v3(0, 0.14, 2.455), (0.19, 0.26, 0.045), 0.012)), "h_trim")
    return {"foot": 1.0, "shadow": 0.4}


MOSS = "#4a5236"


@prop("house_band", "city", layer="wall_decal", cell=(2, 4), tags=["house", "wall", "joint", "module"], name_ko="층 사이 띠(돌림띠 · 내민 들보)",
    variants={"stone": {"kind": "stone"}, "stone_dentil": {"kind": "dentil"}, "timber": {"kind": "timber"}},
    meta=meta(tile_w=1, note="벽 머리(2.5칸 높이)에 얹는 한 칸 띠 — 1층과 2층 사이 · 처마 밑. stone = 돌림띠 · stone_dentil = 이빨 장식 돌림띠 · timber = 내민 장선과 들보"))
def house_band(k, kind="stone", seed=1):
    house_mats(k, seed)
    if kind == "timber":
        k.add(lambda p: np.minimum.reduce([box(p, v3(x, -0.06, 2.35), (0.045, 0.1, 0.05), 0.008) for x in (-0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875)]), "h_post")
        k.add(lambda p: box(p, v3(0, -0.04, 2.46), (HW, 0.13, 0.06), 0.01), "h_beam")
    else:
        k.add(lambda p: np.minimum(box(p, v3(0, 0.1, 2.39), (HW, 0.16, 0.04), 0.01), box(p, v3(0, 0.08, 2.475), (HW, 0.2, 0.045), 0.014)), "h_trim")
        if kind == "dentil":
            k.add(lambda p: np.minimum.reduce([box(p, v3(x, 0.06, 2.3), (0.04, 0.13, 0.05), 0.006) for x in np.arange(-0.75, 0.8, 0.166667)]), "h_trim")
    return {"foot": 1.0, "post": [crop()], "shadow": 0.0}
