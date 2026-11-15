"""도시 건물 겉(2) — a_city_build.py의 벽 조각 위 · 앞에 얹는 것: 지붕(나무 너와 · 돌 너와), 박공, 굴뚝, 창 · 창틀, 집 문 · 쇠 문,
아치 들머리, 처마 기둥 · 돌기둥, 발코니, 나무 난간, 바깥 계단 · 돌 디딤단.

조립 규칙(a_city_build.py와 같다 — 한 칸 = 폭 1 · 벽 높이 2.5, 원점 = 벽 밑동 선의 칸 가운데):
  - 지붕 조각(roof_*)은 벽 조각과 같은 원점에 놓는다 — 처마가 벽 머리(2.5칸) 앞으로 내밀고 뒤로 용마루까지 올라간다. 한 칸 간격으로 이어진다(crop).
    줄 끝에는 같은 지붕의 end_l · end_r(박공 끝 — 박공널이 윤곽을 닫는다). 2층 집이면 up = 2.5.
  - 굴뚝은 지붕 위에 서는 물건: 원점 = 굴뚝 밑동, up = 지붕 높이(처마 2.5 + 깊이 쪽 몇 칸 · 보통 3.2 안팎).
  - 창 · 문 · 아치 · 발코니(wall_decal)는 벽 밑동 선에 원점 — 벽 조각 위에 겹쳐 놓는다.
모든 조각은 묶음 그림 city_build에 들어간다. tags: straight 직선형 · corner 모서리형 · joint 연결형 · ornament 장식형."""
import numpy as np

import fx
import sdf
import mats as M
from a_city_build import (HW, WARM, WH, WW, WZ, crop, house_mats, leaf, meta, pfbm, ring_handle, sd_open, window)
from kit import F, WALL_H, box, cap, cyl, hcyl, prop, rot_z, rough, sphere, sub, torus, v3  # noqa: F401

# 지붕 경사: 처마 끝 (y0, z0) → 용마루 (y1, z1)
EY, EZ, RY, RZ = -0.34, 2.42, 1.35, 3.55
SL = (RZ - EZ) / (RY - EY)
NRM = float(np.sqrt(1 + SL * SL))


def _roof_plane(p):
    """지붕 겉면까지의 거리(위가 +)."""
    return (p[:, 2] - EZ - (p[:, 1] - EY) * SL) / NRM


def tiles(base, row, col, seed=1, moss=0.0, dark="#1e1a18"):
    """경사를 따라 줄지어 겹친 너와(폭 1칸 주기 — 칸마다 같은 무늬로 이어진다)."""
    base, dark, mossc = M.hexc(base), M.hexc(dark), M.hexc("#4a5236")
    ncol = int(round(1.0 / col))

    def fn(p, n):
        r = np.floor((p[:, 1] - EY) / row)
        fr = (p[:, 1] - EY) / row - r
        along = p[:, 0] + 0.5 + (r % 2) * col * 0.5
        c_ = np.floor(along / col)
        fa = along / col - c_
        h = sdf._hash(r, c_ % ncol, r * 0, seed)
        top = n[:, 2] > 0.35
        gap = top & ((fa < 0.06) | (fr < 0.12))
        c = base[None, :] * (0.72 + h * 0.4)[:, None] * (0.75 + fr * 0.35)[:, None]
        c = np.where(gap[:, None], dark[None, :], c)
        c = c * (0.86 + pfbm(p, 0.25, seed + 3, 2)[:, None] * 0.28)
        if moss > 0:
            m = np.clip((pfbm(p, 0.35, seed + 5, 3) - 0.55) * 5.0, 0, 1) * moss
            c = c * (1 - m[:, None]) + mossc[None, :] * m[:, None]
        return M._out(c, np.where(top, np.floor(h * 31) + r * 37 % 97, 300.0))
    return fn


ROOFS = {
    "wood": {"name": "나무 너와 지붕", "base": "#5c4632", "row": 0.13, "col": 0.125, "ridge": "wood_d"},
    "slate": {"name": "돌 너와 지붕", "base": "#4e5258", "row": 0.15, "col": 0.2, "ridge": "stone_d"},
}


def _roof(k, kind="wood", end="", state="", seed=1):
    r = ROOFS[kind]
    k.mat("roof", tiles(r["base"], r["row"], r["col"], seed, 0.7 if state == "worn" else 0.0))
    k.mat("rafter", M.wood("#3e2e22", 0.2, 1, seed + 3))
    x0, x1 = -HW, HW
    if end == "r":
        x0, x1 = -HW, 0.32
    elif end == "l":
        x0, x1 = -0.32, HW
    hole = None
    if state == "damaged":   # 무너진 자리: 너와가 빠지고 서까래 · 어둠이 드러난다
        hole = lambda p: (np.hypot((p[:, 0] - 0.08) / 0.34, (p[:, 1] - 0.55) / 0.42) - 1.0 + (sdf.noise(p, 0.1, seed) - 0.5) * 0.5) * 0.3
    bound = lambda p: np.maximum.reduce([x0 - p[:, 0], p[:, 0] - x1, EY - p[:, 1], p[:, 1] - RY])
    slab = lambda p: np.maximum(np.abs(_roof_plane(p) + 0.04) - 0.045 - np.clip((p[:, 1] - EY) / r["row"] % 1.0, 0, 1) * 0.012, bound(p))
    if hole is not None:
        k.add(lambda p: sub(slab(p), np.maximum(hole(p), np.abs(_roof_plane(p)) - 0.2)), "roof")
        for x in (-0.25, 0.0, 0.25, 0.5):          # 서까래
            k.add(lambda p, x=x: np.maximum(box(p, v3(x, 0.5, 0), (0.035, 2, 9)), np.maximum(np.abs(_roof_plane(p) + 0.13) - 0.035, bound(p))), "rafter")
        k.add(lambda p: np.maximum(np.abs(_roof_plane(p) + 0.3) - 0.02, bound(p)), "void")
    else:
        k.add(slab, "roof")
        k.add(lambda p: np.maximum(np.abs(_roof_plane(p) + 0.25) - 0.02, bound(p)), "void")   # 밑 그늘(옆에서 비칠 때)
    # 처마널 · 용마루
    k.add(lambda p: np.maximum(box(p, v3(0, EY - 0.01, EZ - 0.03), (9, 0.035, 0.06), 0.008), np.maximum(x0 - p[:, 0], p[:, 0] - x1)), "rafter")
    k.add(lambda p: np.maximum(np.hypot(p[:, 1] - RY, p[:, 2] - RZ - 0.02) - 0.07, np.maximum(x0 - p[:, 0], p[:, 0] - x1)), r["ridge"])
    if end:                                         # 박공널: 끝 선을 따라 처마에서 용마루로
        ex = x1 if end == "r" else x0
        k.add(lambda p: np.maximum(np.abs(p[:, 0] - ex) - 0.04, np.maximum(np.abs(_roof_plane(p) + 0.01) - 0.07, np.maximum(EY - 0.05 - p[:, 1], p[:, 1] - RY - 0.05))), "rafter")
    post = [] if end else [crop()]
    if end == "r":
        post = [crop(-0.5, None)]
    elif end == "l":
        post = [crop(None, 0.5)]
    return {"foot": 1.0, "post": post, "shadow": 0.0}


def _roof_asset(kind):
    r = ROOFS[kind]
    id = "roof_" + kind

    @prop(id, "city", layer="over", cell=(2, 7), tags=["house", "roof", "straight", "module", kind], name_ko=r["name"],
        variants={"eave": {"seed": 1}, "eave_b": {"seed": 4}, "worn": {"state": "worn", "seed": 2}, "damaged": {"state": "damaged", "seed": 3},
            "end_l": {"end": "l", "seed": 1}, "end_r": {"end": "r", "seed": 1}},
        meta=meta(tile_w=1, note="벽 조각과 같은 원점에 얹는 지붕 한 칸 — 처마가 벽 머리 앞으로 내밀고 뒤로 용마루(높이 %.2f칸)까지. end_l · end_r = 줄 왼쪽 · 오른쪽 끝(박공널)" % RZ))
    def fn(k, end="", state="", seed=1):
        return _roof(k, kind, end, state, seed)
    fn.__name__ = id
    return fn


roof_wood = _roof_asset("wood")
roof_slate = _roof_asset("slate")


@prop("roof_gable_front", "city", layer="over", cell=(5, 7), collide=None, tags=["house", "roof", "ornament", "module"], name_ko="앞으로 향한 박공",
    variants={"plaster": {"kind": "plaster"}, "timber": {"kind": "timber"}, "stone": {"kind": "stone"}, "timber_window": {"kind": "timber", "win": True}},
    meta=meta(tile_w=3, note="세 칸 폭 벽 줄 위에 얹는 남쪽을 보는 삼각 박공과 양쪽 지붕(나무 너와) — 줄 가운데 칸에 원점. timber_window = 다락 창"))
def roof_gable_front(k, kind="plaster", win=False, seed=1):
    house_mats(k, seed)
    k.mat("roof", tiles("#5c4632", 0.13, 0.125, seed))
    k.mat("rafter", M.wood("#3e2e22", 0.2, 1, seed + 3))
    H, B = 1.45, 1.55                                      # 박공 높이 · 반폭
    tri = lambda p: np.maximum.reduce([(np.abs(p[:, 0]) * H + (p[:, 2] - WALL_H) * B - B * H) / np.hypot(H, B), WALL_H - p[:, 2], np.abs(p[:, 1] - 0.1) - 0.1])
    k.add(tri, {"plaster": "h_plaster", "timber": "h_infill", "stone": "h_stone"}[kind])
    if kind == "timber":
        for x in (-0.5, 0.5):
            k.add(lambda p, x=x: np.maximum(box(p, v3(x, -0.02, WALL_H + 0.8), (0.05, 0.04, 0.8)), tri(p) - 0.04), "h_post")
        k.add(lambda p: np.maximum(box(p, v3(0, -0.02, WALL_H + 0.55), (2, 0.04, 0.05)), tri(p) - 0.04), "h_beam")
    if win:
        window(k, 0, WALL_H + 0.62, 0.17, 0.2, "shut", "square", 0.0, "h_beam", "h_trim", seed)
    # 두 쪽 지붕 면: 용마루가 남북으로 — 박공 경사를 따라 x 방향으로 내려간다
    for s in (-1, 1):
        pl = lambda p, s=s: ((p[:, 2] - WALL_H + 0.08) * B - (B - s * p[:, 0]) * H) / np.hypot(H, B)
        k.add(lambda p, s=s, pl=pl: np.maximum.reduce([np.abs(pl(p)) - 0.05, -0.32 - p[:, 1], p[:, 1] - 1.9, s * (-p[:, 0]) - 0.02, s * p[:, 0] - B - 0.35]), "roof")
        k.add(lambda p, s=s: np.maximum(hcyl(p, v3(0, -0.3, WALL_H + H + 0.02), v3(s * (B + 0.3), -0.3, WALL_H - 0.18), 0.045), -p[:, 2] + 0.5), "rafter")
    k.add(lambda p: cap(p, v3(0, -0.3, WALL_H + H + 0.04), v3(0, 1.9, WALL_H + H + 0.04), 0.06), "rafter")
    return {"foot": 1.0, "shadow": 0.0}


# ── 굴뚝 ─────────────────────────────────────────────────────────────────────

@prop("chimney", "city", cell=(2, 4), tags=["house", "roof", "ornament", "smoke"], name_ko="굴뚝", fps=6,
    variants={"stone": {"kind": "stone"}, "brick": {"kind": "brick"}, "stone_smoke": {"kind": "stone", "frames": 4}, "brick_smoke": {"kind": "brick", "frames": 4},
        "broken": {"kind": "brick", "broken": True}},
    meta=meta(note="지붕 위에 서는 굴뚝 — 원점 = 굴뚝 밑동, up = 지붕 높이(보통 3.0~3.4칸). *_smoke = 연기 4프레임"))
def chimney(k, kind="stone", broken=False, seed=1, f=None):
    mat = "masonry" if kind == "stone" else "brick"
    top = 1.05 if not broken else 0.7
    if broken:
        k.add(rough(lambda p: np.maximum(box(p, v3(0, 0.1, top / 2), (0.24, 0.2, top / 2), 0.01), p[:, 2] - top + (p[:, 0] + 0.24) * 0.6 - sdf.noise(p, 0.06, seed) * 0.15), 0.02, 0.1, seed), mat)
        k.rubble([(0.35, -0.15), (-0.3, -0.2)], "brick", 0.04, 0.07)
    else:
        k.add(lambda p: box(p, v3(0, 0.1, top / 2), (0.24, 0.2, top / 2), 0.01), mat)
        k.add(lambda p: box(p, v3(0, 0.1, top + 0.04), (0.29, 0.25, 0.05), 0.012), "stone_d")
        k.add(lambda p: box(p, v3(0, 0.1, top + 0.1), (0.15, 0.12, 0.03)), "void")
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: cyl(p, v3(sx * 0.12, 0.1, top + 0.08), 0.05, 0.12, 0.01), "stone_d")
    out = {"foot": 0.6, "shadow": 0.0}
    if f is not None:
        out["post"] = [lambda img, vw: fx.puff(img, *vw.px(0, 0.1, top + 0.25), 0.22 * vw.u, "#7a7670", 0.55, seed, f, 0.9 * vw.u, 6)]
        out["cell"] = (2, 5)
    return out


# ── 창 ───────────────────────────────────────────────────────────────────────

_WIN_V = {"square_shut": {"shape": "square", "mode": "shut"}, "square_open": {"shape": "square", "mode": "open"}, "square_lit": {"shape": "square", "mode": "lit"},
    "square_broken": {"shape": "square", "mode": "broken"}, "square_boarded": {"shape": "square", "mode": "boarded"},
    "arch": {"shape": "arch", "mode": "bare"}, "arch_lit": {"shape": "arch", "mode": "lit"}, "round": {"shape": "round", "mode": "bare"}, "round_lit": {"shape": "round", "mode": "lit"},
    "frame_empty": {"shape": "square", "mode": "empty"}}


@prop("house_window", "city", layer="wall_decal", cell=(2, 4), tags=["house", "window", "ornament", "wood"], name_ko="집 창문", interact="window",
    variants=_WIN_V, light={"color": WARM, "radius": 2.5, "at": (0, -0.3, WZ), "flicker": 0.08, "variants": ["square_lit", "arch_lit", "round_lit"]},
    meta=meta(note="민벽 조각 위에 겹쳐 붙이는 창과 창틀(벽 밑동 선에 원점 · 창 가운데 높이 %.2f칸). frame_empty = 유리 없는 창틀만 · 2층은 up 2.5" % WZ))
def house_window(k, shape="square", mode="shut", seed=1):
    house_mats(k, seed)
    hw, hh = (WW, WH) if shape != "round" else (0.2, 0.2)
    if shape == "arch":
        hw, hh = 0.19, 0.34
    glow = window(k, 0, WZ, hw, hh, mode, shape, -0.01, "h_beam", "h_trim", seed)
    if shape != "square":      # 돌 테
        sd = sd_open(shape, 0, WZ, hw + 0.05, hh + 0.05)
        big = sd_open(shape, 0, WZ, hw + 0.12, hh + 0.12)
        k.add(lambda p: np.maximum.reduce([big(p), -sd(p), np.abs(p[:, 1] + 0.03) - 0.04]), "h_trim")
    return {"foot": 1.0, "glow": glow, "shadow": 0.0}


# ── 문 ───────────────────────────────────────────────────────────────────────

def _door_case(k, w, h, mat="h_beam"):
    k.add(lambda p: np.minimum.reduce([box(p, v3(sx * (w + 0.05), -0.02, h / 2), (0.05, 0.05, h / 2), 0.008) for sx in (-1, 1)] + [box(p, v3(0, -0.02, h + 0.05), (w + 0.1, 0.055, 0.06), 0.008)]), mat)
    k.add(lambda p: box(p, v3(0, 0.03, h / 2), (w, 0.01, h / 2)), "void")
    k.add(rough(lambda p: box(p, v3(0, -0.12, 0.025), (w + 0.12, 0.12, 0.025), 0.01), 0.01, 0.2, 3), "stone_d")


def _hinged(x_hinge, y, ang):
    return lambda p: rot_z(p, ang, (x_hinge, y, 0))


@prop("house_door", "city", layer="wall_decal", cell=(3, 4), collide=(-0.4, -0.05, 0.8, 0.1), tags=["house", "door", "ornament", "wood", "passage"], name_ko="집 나무 문", interact="door",
    variants={"plain": {}, "plain_ajar": {"ajar": True}, "reinforced": {"kind": "reinforced"}, "reinforced_ajar": {"kind": "reinforced", "ajar": True},
        "double": {"kind": "double"}, "double_ajar": {"kind": "double", "ajar": True}},
    meta=meta(states={"closed": "plain", "open": "plain_ajar"}, note="민벽 조각 위에 붙이는 문틀과 문짝 — 벽 밑동 선에 원점. double = 두 짝(1.2칸 폭) · *_ajar = 안으로 반쯤 열림"))
def house_door(k, kind="plain", ajar=False, seed=1):
    house_mats(k, seed)
    h = 1.55
    w = 0.3 if kind != "double" else 0.52
    _door_case(k, w, h)
    if kind == "double":
        for s in (-1, 1):
            T = _hinged(s * w, 0.0, -s * 0.9) if ajar else None
            xa, xb = (s * w, 0.0) if s < 0 else (0.0, s * w)
            leaf(k, min(xa, xb) + 0.005, max(xa, xb) - 0.005, h - 0.02, 0.0, "wood", T, seed + (s > 0))
            if not ajar:
                ring_handle(k, s * 0.08, -0.04, 0.8)
    else:
        T = _hinged(-w, 0.0, 1.0) if ajar else None
        leaf(k, -w + 0.005, w - 0.005, h - 0.02, 0.0, "wood", T, seed, straps=(kind == "reinforced"))
        if kind == "reinforced":
            k.add(lambda p: (lambda q: np.minimum.reduce([sphere(q, v3(x, -0.045, z), 0.016) for x in (-0.2, 0.0, 0.2) for z in (0.45, 0.85, 1.25)]))((T or (lambda p: p))(p)), "iron")
        if not ajar:
            ring_handle(k, 0.18, -0.04, 0.8)
    return {"foot": 1.0, "shadow": 0.0}


@prop("house_iron_door", "city", layer="wall_decal", cell=(3, 4), collide=(-0.4, -0.05, 0.8, 0.1), tags=["house", "door", "ornament", "iron", "passage"], name_ko="집 쇠 문", interact="door",
    variants={"closed": {}, "ajar": {"ajar": True}, "rusted": {"rust": True}},
    meta=meta(states={"closed": "closed", "open": "ajar"}, note="돌 문설주에 단 쇠띠 박은 문(창고 · 관청 · 부잣집) — 벽 밑동 선에 원점"))
def house_iron_door(k, ajar=False, rust=False, seed=1):
    house_mats(k, seed)
    h, w = 1.6, 0.32
    k.add(lambda p: np.minimum.reduce([box(p, v3(sx * (w + 0.06), -0.03, h / 2), (0.06, 0.06, h / 2), 0.01) for sx in (-1, 1)] + [box(p, v3(0, -0.03, h + 0.07), (w + 0.14, 0.07, 0.08), 0.012)]), "h_trim")
    k.add(lambda p: box(p, v3(0, 0.03, h / 2), (w, 0.01, h / 2)), "void")
    T = _hinged(-w, 0.0, 1.0) if ajar else None
    leaf(k, -w + 0.005, w - 0.005, h - 0.02, 0.0, "iron", T, seed + (7 if rust else 0))
    if rust:
        k.mat("door_i", M.metal("#45474c", "#7a4a30", seed + 13, 0.9))
    if not ajar:
        ring_handle(k, 0.2, -0.05, 0.82)
    k.add(rough(lambda p: box(p, v3(0, -0.12, 0.025), (w + 0.14, 0.12, 0.025), 0.01), 0.01, 0.2, 3), "stone_d")
    return {"foot": 1.0, "shadow": 0.0}


@prop("porch_arch", "city", cell=(3, 4), collide=[(-0.62, -0.18, 0.3, 0.36), (0.32, -0.18, 0.3, 0.36)], tags=["house", "door", "ornament", "stone", "passage"], name_ko="돌 아치 들머리",
    variants={"open": {}, "door": {"door": True}, "worn": {"worn": True}},
    meta=meta(note="벽 앞에 서는 돌 아치 현관(1.5칸 폭) — 벽 밑동 선에 원점. door = 아치 안 문짝 · 양쪽 기둥만 막는다"))
def porch_arch(k, door=False, worn=False, seed=1):
    house_mats(k, seed, 1.0 if worn else 0.0)
    W, Hs, R = 0.5, 1.25, 0.5
    for sx in (-1, 1):
        k.add(rough(lambda p, sx=sx: box(p, v3(sx * (W + 0.12), -0.0, Hs / 2), (0.12, 0.17, Hs / 2), 0.012), 0.008, 0.2, seed), "h_stone")
        k.add(lambda p, sx=sx: box(p, v3(sx * (W + 0.12), -0.0, Hs + 0.04), (0.16, 0.2, 0.05), 0.01), "h_trim")
    ring = lambda p: np.maximum.reduce([np.abs(np.hypot(p[:, 0], p[:, 2] - Hs) - (R + 0.12)) - 0.12, Hs - p[:, 2], np.abs(p[:, 1]) - 0.17])
    k.add(rough(ring, 0.008, 0.2, seed), "h_stone")
    k.add(lambda p: box(p, v3(0, -0.02, Hs + R + 0.3), (W + 0.32, 0.19, 0.06), 0.012), "h_trim")
    k.add(lambda p: sphere(p, v3(0, -0.17, Hs + R + 0.12), 0.07), "h_trim")      # 쐐기돌
    xz = lambda p: np.minimum(np.maximum(np.abs(p[:, 0]) - W, np.abs(p[:, 2] - Hs / 2) - Hs / 2), np.maximum(np.hypot(p[:, 0], p[:, 2] - Hs) - R, Hs - p[:, 2]))
    k.add(lambda p: np.maximum(xz(p), np.abs(p[:, 1] - 0.18) - 0.01), "void")
    if door:
        k.add(lambda p: np.maximum(xz(p) + 0.01, np.abs(p[:, 1] - 0.12) - 0.03), k.mat("door_w", M.wood("#4e3b2a", 0.13, 2, seed + 7)))
        k.add(lambda p: np.maximum(xz(p) + 0.01, np.minimum.reduce([np.abs(p[:, 2] - z) - 0.035 for z in (0.3, 0.95)] + [np.abs(p[:, 1] - 0.085) - 0.01 + 9 * 0])) + np.maximum(np.abs(p[:, 1] - 0.085) - 0.01, 0), "iron")
        ring_handle(k, 0.15, 0.07, 0.78)
    k.add(rough(lambda p: box(p, v3(0, -0.28, 0.03), (W + 0.3, 0.14, 0.03), 0.01), 0.01, 0.2, seed), "stone_d")
    return {"foot": 1.0, "shadow": 0.4}


# ── 기둥 · 발코니 · 난간 · 계단 ───────────────────────────────────────────────

@prop("porch_post", "city", cell=(2, 4), collide=(0.26, 0.26), tags=["house", "post", "ornament"], name_ko="처마 기둥",
    variants={"wood": {"kind": "wood"}, "wood_brace": {"kind": "wood", "brace": True}, "stone": {"kind": "stone"}, "stone_worn": {"kind": "stone", "worn": True}},
    meta=meta(note="처마 · 차양 · 발코니를 받치는 기둥(높이 2.5칸). wood_brace = 까치발 · stone = 받침과 머리를 깎은 돌기둥"))
def porch_post(k, kind="wood", brace=False, worn=False, seed=1):
    house_mats(k, seed, 1.0 if worn else 0.0)
    if kind == "wood":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.06), (0.12, 0.12, 0.06), 0.02), 0.01, 0.15, seed), "stone_d")
        k.add(lambda p: box(p, v3(0, 0, 1.25), (0.075, 0.075, 1.14), 0.01), "h_post")
        k.add(lambda p: box(p, v3(0, 0, 2.43), (0.1, 0.1, 0.07), 0.008), "h_beam")
        if brace:
            for sx in (-1, 1):
                k.add(lambda p, sx=sx: hcyl(p, v3(sx * 0.05, 0, 1.95), v3(sx * 0.42, 0, 2.38), 0.04), "h_post")
            k.add(lambda p: box(p, v3(0, 0, 2.45), (0.5, 0.08, 0.05), 0.008), "h_beam")
    else:
        k.add(rough(lambda p: box(p, v3(0, 0, 0.09), (0.17, 0.17, 0.09), 0.015), 0.01, 0.15, seed), "h_plinth")
        k.add(lambda p: torus(p, v3(0, 0, 0.21), 0.12, 0.035), "h_trim")
        k.add(rough(lambda p: cyl(p, v3(0, 0, 0.2), 0.11 - 0.0, 2.05, 0.01) + (sdf.noise(p, 0.05, seed) - 0.5) * (0.02 if worn else 0.0), 0.006, 0.2, seed), "marble" if not worn else "stone")
        k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 2.2), 0.15, 0.1, 0.015), box(p, v3(0, 0, 2.38), (0.18, 0.18, 0.08), 0.012)), "h_trim")
    return {"foot": 0.6}


@prop("balcony", "city", layer="wall_decal", cell=(3, 6), tags=["house", "balcony", "ornament"], name_ko="발코니",
    variants={"wood": {"kind": "wood"}, "wood_plants": {"kind": "wood", "plants": True}, "stone": {"kind": "stone"}, "wood_broken": {"kind": "wood", "broken": True}},
    meta=meta(tile_w=2, note="2층 벽(문 · 창 칸) 앞에 붙는 두 칸 폭 발코니 — 벽 밑동 선에 원점, 바닥 높이 = 벽 머리 %.1f칸(1층 벽 위). 아래를 지나다닐 수 있다" % WALL_H))
def balcony(k, kind="wood", plants=False, broken=False, seed=1):
    house_mats(k, seed)
    z0, D = WALL_H + 0.02, 0.55
    if kind == "wood":
        k.add(lambda p: box(p, v3(0, -D / 2 + 0.02, z0), (0.98, D / 2, 0.05), 0.01), "plank_y")
        for x in (-0.8, 0.8):
            k.add(lambda p, x=x: hcyl(p, v3(x, 0.02, z0 - 0.5), v3(x, -D + 0.05, z0 - 0.03), 0.04), "h_post")
        rail_z = z0 + 0.55
        xs = np.linspace(-0.92, 0.92, 13)
        for i, x in enumerate(xs):
            if broken and i in (7, 8, 9):
                continue
            k.add(lambda p, x=x: box(p, v3(x, -D + 0.04, z0 + 0.3), (0.022, 0.022, 0.25)), "h_post")
        if broken:
            k.add(lambda p: np.minimum(box(p, v3(-0.5, -D + 0.04, rail_z), (0.48, 0.035, 0.035)), hcyl(p, v3(0.3, -D + 0.04, rail_z), v3(0.7, -D - 0.25, z0 - 0.4), 0.03)), "h_beam")
        else:
            k.add(lambda p: box(p, v3(0, -D + 0.04, rail_z), (0.98, 0.04, 0.035), 0.008), "h_beam")
        for x in ((-0.95,) if broken else (-0.95, 0.95)):
            k.add(lambda p, x=x: box(p, v3(x, -D / 2 + 0.02, z0 + 0.3), (0.03, D / 2, 0.025)), "h_beam")
    else:
        k.add(lambda p: box(p, v3(0, -D / 2 + 0.02, z0), (1.0, D / 2, 0.07), 0.015), "h_trim")
        for x in (-0.75, 0.0, 0.75):
            k.add(lambda p, x=x: np.maximum(box(p, v3(x, -0.15, z0 - 0.2), (0.07, 0.17, 0.18)), (p[:, 1] + 0.32) * 0.7 - (p[:, 2] - z0 + 0.38)), "h_trim")    # 까치발 돌
        for x in np.linspace(-0.85, 0.85, 9):
            k.add(lambda p, x=x: np.minimum(cyl(p, v3(x, -D + 0.06, z0 + 0.07), 0.04, 0.4, 0.01), sphere(p, v3(x, -D + 0.06, z0 + 0.25), 0.055)), "h_trim")
        k.add(lambda p: box(p, v3(0, -D + 0.06, z0 + 0.5), (1.0, 0.07, 0.04), 0.012), "h_trim")
    if plants:
        for x in (-0.6, 0.55):
            k.add(lambda p, x=x: box(p, v3(x, -D + 0.12, z0 + 0.62), (0.2, 0.06, 0.06), 0.01), "wood_l")
            k.add(rough(lambda p, x=x: np.maximum(sphere(p, v3(x, -D + 0.12, z0 + 0.72), 0.17), -(p[:, 2] - z0 - 0.66)), 0.04, 0.06, seed), "leaf")
    return {"foot": 1.0, "shadow": 0.0}


@prop("wood_railing", "city", cell=(2, 3), collide=(1.0, 0.16), tags=["house", "railing", "wood"], name_ko="나무 난간",
    variants={"straight": {}, "post": {"kind": "post"}, "corner": {"kind": "corner"}, "broken": {"kind": "broken"}},
    meta=meta(tile_w=1, note="현관 · 다리 · 마당 가의 나무 난간 한 칸 — 칸 가운데 원점, 옆으로 이어진다. post = 끝 기둥 · corner = 꺾이는 칸(동 · 북으로 팔)"))
def wood_railing(k, kind="straight", seed=1):
    house_mats(k, seed)
    if kind in ("post", "corner"):
        k.add(lambda p: np.minimum(box(p, v3(0, 0, 0.42), (0.06, 0.06, 0.42), 0.008), sphere(p, v3(0, 0, 0.88), 0.07)), "h_post")
    arms = {"straight": [(-1, 0), (1, 0)], "broken": [(-1, 0), (1, 0)], "post": [], "corner": [(1, 0), (0, 1)]}[kind]
    for ax, ay in arms:
        span = lambda p, ax=ax, ay=ay: np.maximum(p[:, 0] * -ax if ax else np.abs(p[:, 0]) - 0.04, p[:, 1] * -ay if ay else np.abs(p[:, 1]) - 0.04)
        k.add(lambda p, ax=ax, ay=ay: np.maximum(box(p, v3(ax * 0.4, ay * 0.4, 0.78), (0.45 if ax else 0.035, 0.45 if ay else 0.035, 0.035), 0.008),
            -(p[:, 0] * ax + p[:, 1] * ay) + (0.02 if kind != "broken" else -0.0) - (0.0 if kind != "broken" or ax < 0 else 9.0)), "h_beam")
        k.add(lambda p, ax=ax, ay=ay: box(p, v3(ax * 0.4, ay * 0.4, 0.3), (0.45 if ax else 0.025, 0.45 if ay else 0.025, 0.025), 0.006), "h_beam")
        for t in (0.17, 0.42, 0.67):
            if kind == "broken" and ax > 0 and t > 0.3:
                continue
            k.add(lambda p, ax=ax, ay=ay, t=t: box(p, v3(ax * t, ay * t, 0.52), (0.025, 0.025, 0.24)), "h_post")
    if kind == "broken":
        k.add(lambda p: hcyl(p, v3(0.1, 0.0, 0.78), v3(0.6, -0.15, 0.05), 0.033), "h_beam")
        k.add(lambda p: hcyl(p, v3(0.42, -0.25, 0.03), v3(0.62, 0.05, 0.03), 0.022), "h_post")
    post = [crop()] if kind in ("straight", "broken") else []
    return {"foot": 0.8, "post": post}


@prop("outside_stairs", "city", cell=(4, 5), collide=(-0.55, -0.1, 1.6, 0.45), tags=["house", "stairs", "passage"], name_ko="바깥 계단", interact="stairs",
    variants={"wood": {"kind": "wood"}, "wood_l": {"kind": "wood", "flip": True}, "stoop": {"kind": "stoop"}, "stoop_worn": {"kind": "stoop", "worn": True}},
    meta=meta(note="wood = 벽을 따라 오른쪽으로 2층 문(높이 %.1f칸)까지 오르는 나무 계단(원점 = 계단 밑 끝) · wood_l = 왼쪽으로 · stoop = 문 앞 세 단 돌 디딤단(원점 = 벽 밑동 선)" % WALL_H))
def outside_stairs(k, kind="wood", flip=False, worn=False, seed=1):
    house_mats(k, seed, 1.0 if worn else 0.0)
    if kind == "stoop":
        for i in range(3):
            d = 0.5 - i * 0.14
            k.add(rough(lambda p, i=i, d=d: box(p, v3(0, -d / 2 + 0.02, 0.06 + i * 0.12), (0.5 - i * 0.04, d / 2, 0.06), 0.012), 0.012 if worn else 0.005, 0.15, seed + i), "h_trim" if i == 2 else "h_plinth")
        return {"foot": 0.8, "cell": (3, 3)}
    s = -1 if flip else 1
    n, run, rise = 10, 1.9, WALL_H
    for i in range(n):
        x, z = s * (-0.3 + i * run / n), (i + 1) * rise / n
        k.add(lambda p, x=x, z=z: box(p, v3(x, -0.22, z), (run / n / 2 + 0.01, 0.2, 0.025), 0.006), "plank_x")
    k.add(lambda p: np.maximum(hcyl(p, v3(s * -0.4, -0.42, 0.0), v3(s * 1.65, -0.42, rise), 0.05), -p[:, 2]), "h_beam")
    k.add(lambda p: box(p, v3(s * 1.8, -0.22, rise), (0.25, 0.22, 0.04), 0.008), "plank_x")          # 층참
    k.add(lambda p: box(p, v3(s * 0.75, -0.4, 0.6), (0.05, 0.05, 0.6)), "h_post")
    k.add(lambda p: box(p, v3(s * 1.95, -0.4, rise / 2), (0.05, 0.05, rise / 2)), "h_post")
    k.add(lambda p: np.maximum(hcyl(p, v3(s * -0.35, -0.42, 0.85), v3(s * 1.6, -0.42, rise + 0.85), 0.03), -p[:, 2]), "h_beam")    # 손잡이
    for i in range(0, n, 2):
        x, z = s * (-0.3 + i * run / n), (i + 1) * rise / n
        k.add(lambda p, x=x, z=z: box(p, v3(x, -0.42, z + 0.42), (0.02, 0.02, 0.42)), "h_post")
    return {"foot": 0.8, "dx": s * 0.6}
