"""가장자리 · 이음 에셋(에셋 라이브러리 — docs/asset_library): 지역을 잇는 기반.
바닥 번짐 띠(fringe_<바닥> — 높은 순위 바닥이 이웃 칸으로 스며드는 조각) · 물가 · 용암가 테(shore_rim) · 낭떠러지 벽(cliff_drop) · 낭떠러지 턱(cliff_lip) ·
다리(돌 · 나무 · 끊긴 끝) · 폭포 · 벽난로 · 깔개.
번짐 순위(RANK): 낮은 바닥 위로 높은 바닥이 덮인다 — 물 · 용암이 가장 낮아 물가는 저절로 뭍이 덮는다. 게임 쪽 = DungeonKit.put_fringe."""
import numpy as np

import a_floor  # noqa: F401 — 번짐 띠가 바닥 그림을 읽는다(먼저 등록)
import a_ground  # noqa: F401
import fx
import mats as M
import sdf
import surf
from a_light import FIRE, flame_post
from kit import (F, WALL_H, box, cap, chip, cut_above, cyl, ell, flat, hcyl, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, v3)  # noqa: F401
import kit as K
from paint2d import gblur, hexc, sstep

# 번짐 순위: 뒤에 올수록 위를 덮는다. 여기 없는 바닥(실내 석재 바닥)은 순위 1(물보다 위 · 자연 바닥보다 아래)이고 스며들지 않는다.
ORDER = ["ground_ice", "ground_rock", "ground_ash", "ground_hardpan", "ground_redsoil", "floor_dirt", "ground_mud", "ground_swamp", "floor_sand", "ground_bones",
    "ground_forest", "ground_thicket", "ground_grass", "ground_meadow", "ground_snow"]
RANK = dict({"ground_water": 0, "ground_lava": 0}, **{g: i + 2 for i, g in enumerate(ORDER)})
LIQUID = {"ground_water": "water", "ground_lava": "lava"}
D0 = 0.3      # 변 띠가 칸 양 끝에서 갖는 깊이(칸 비율) — 이웃 칸의 띠 · 모서리와 이어진다
DIRS = ("n", "e", "s", "w")
_FV = dict({"%s_%s" % (d, s): {"side": d, "seed": 3 + i * 7 + j * 31} for i, d in enumerate(DIRS) for j, s in enumerate("ab")}, **{c: {"side": c, "seed": 5 + i * 11} for i, c in enumerate(("ne", "se", "sw", "nw"))})


def _band(c, side, seed, depth0=D0, wob=0.26):
    """한 칸(64px) 안의 번짐 모양 마스크(c.H × c.W, 0~1). side = 높은 바닥이 있는 쪽(n · e · s · w 변, ne · se · sw · nw 대각)."""
    n = c.H
    yy, xx = np.mgrid[0:n, 0:n].astype(F) / n            # 0~1
    rng = np.random.default_rng(seed)
    if len(side) == 1:
        k = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, 6), rng.uniform(-1, 1, 6)).astype(F)
        depth = depth0 + (k * wob + 0.08) * np.sin(np.pi * np.linspace(0, 1, n)).astype(F) ** 0.8     # 양 끝은 depth0
        d = depth[None, :] - yy                                                                          # n: 위쪽 변에서 아래로
        d = d + (c.noise(5, seed + 1, 2) - 0.5) * 0.14 * np.sin(np.pi * xx) ** 0.5
        m = sstep(d / 0.05, 0, 1)
        m = np.rot90(m, -DIRS.index(side))               # n → e → s → w (시계 방향)
    else:
        r = np.hypot(1.0 - xx, yy)                       # ne: 오른쪽 위 모서리에서 부채꼴
        d = depth0 - r + (c.noise(5, seed + 1, 2) - 0.5) * 0.1 * np.clip(r / depth0, 0, 1) * (1 - np.clip(r / depth0, 0, 1)) * 4
        m = sstep(d / 0.05, 0, 1)
        m = np.rot90(m, -("ne", "se", "sw", "nw").index(side))
    return np.ascontiguousarray(m)


def _ground_px(gid, c):
    """그 바닥 그림의 한 칸(왼쪽 위 64px)을 판 크기로."""
    a = K.REG[gid]
    vname = next(iter(a.variants))
    params = dict(a.variants[vname])
    nfr = params.pop("frames", 0)
    if nfr:
        params["f"] = 0
    img, _ = K.render(gid, vname, 0 if nfr else None, params)
    tile = img[:64, :64, :3].astype(F) / 255.0
    return np.repeat(np.repeat(tile, c.H // 64, 0), c.W // 64, 1)


def _fringe(gid, rank):
    name = K.REG[gid].name_ko
    src = K.REG[gid].digest({})        # 바닥 그림이 바뀌면 띠도 다시 그린다

    @flat("fringe_" + gid.split("_", 1)[1], "floor", layer="decal", cell=(64, 64), variants={v: dict(p, src=src) for v, p in _FV.items()}, name_ko=name + " 번짐 띠", tags=["fringe", "edge"],
        meta={"grid": True, "tile": [64, 64], "sheet": "fringes", "of": gid, "rank": rank, "note": "이웃 칸으로 스며드는 조각 — 변 넷 × 2 + 대각 모서리 넷. DungeonKit.put_fringe가 깐다"})
    def fringe(c, side="n", seed=1, src=None):
        c.graded = False
        m = _band(c, side, seed)
        c.paint(np.clip(gblur(_band(c, side, seed, D0 + 0.05), 2.5) * 1.3, 0, 1) * 0.42, "#100c0a")     # 띠 밖으로 드리운 그늘(두께)
        c.paint(m, _ground_px(gid, c))
        c.paint(c.rim(m, 1.2) * 0.35, "#16100e")
        c.origin = (32, 32)
    return fringe


for _g in ORDER:
    _fringe(_g, RANK[_g])


_RV = {"%s_%s" % (k, d): {"kind": k, "side": d, "seed": 3 + i * 5} for k in ("water", "lava", "poison") for i, d in enumerate(DIRS + ("ne", "se", "sw", "nw"))}
_RIMC = {"water": ("#0c1418", "#a8c4d0", 0.3), "lava": ("#3a1408", "#ffb040", 0.75), "poison": ("#14200c", "#b0d860", 0.6)}


@flat("shore_rim", "floor", layer="decal", cell=(64, 64), variants=_RV, name_ko="물가 · 용암가 테", tags=["edge", "water", "lava"],
    meta={"grid": True, "tile": [64, 64], "sheet": "fringes", "note": "물 · 용암 칸에서 뭍 쪽 변에 깐다(번짐 띠 아래): 물 = 젖은 그늘과 잔물결 테 · 용암 = 달아오른 테"})
def shore_rim(c, kind="water", side="n", seed=1):
    c.graded = False
    dark, lit, k = _RIMC[kind]
    wide = _band(c, side, seed, D0 + 0.2, 0.2)
    c.paint(gblur(wide, 3.0) * 0.5, dark)                                              # 뭍 그늘 · 얕은 가장자리
    line = np.clip(c.rim(_band(c, side, seed, D0 + 0.12, 0.24), 1.6), 0, 1)
    if kind == "water":
        c.add(line * (c.noise(6, seed + 4) > 0.4), lit, k)                             # 끊어진 잔물결 테
    else:
        c.add(gblur(line, 3.0) * 1.4, hexc(lit) * np.array([0.8, 0.35, 0.2], F) if kind == "lava" else hexc(lit) * 0.5, 0.6)
        c.add(line, lit, k)
    c.origin = (32, 32)


# ── 낭떠러지 ─────────────────────────────────────────────────────────────────

_DROP = {"cave": ("#56565a", "chunk"), "sandstone": ("#6e5c48", "strata"), "ice": ("#5c7a90", "ice"), "basalt": ("#2e2b2a", "column"), "stone": ("#56544f", None)}


@flat("cliff_drop", "wall", layer="decal", cell=(256, 160), variants={k: {"kind": k} for k in _DROP}, name_ko="낭떠러지 벽", tags=["cliff", "edge", "void"],
    meta={"tile": [64, 160], "span": 4, "sheet": "cliff_drops", "note": "바닥이 끝나는 줄 바로 아래(남쪽) 빈 칸의 윗변에 그림 윗변을 맞춘다 — 아래로 2.5칸, 어둠에 잠긴다. 4칸 폭 한 장(칸 x를 4로 나눈 나머지 조각을 잘라도 이어진다). 원점 = 왼쪽 위"})
def cliff_drop(c, kind="cave", seed=1):
    """바닥 끝에서 아래로 떨어지는 암벽: 윗변은 밝은 턱, 아래로 갈수록 어둠."""
    import a_wall
    kd = "stone" if kind == "stone" else kind
    img, gap, h, cell, edge, t = a_wall._face_base(kd, 900 + list(_DROP).index(kind) * 13)
    img = img[:320]
    yy = np.mgrid[0:320, 0:512][0].astype(F) / 320.0
    lip = np.clip(1.0 - yy * 320 / 10.0, 0, 1)
    full = np.zeros((512, 512, 3), F)
    full[:320] = img
    full[320:] = img[:192]
    out = surf.finish(full, _DROP[kind][0], seed)[:160].astype(F) / 255.0          # 색 정리는 어둡히기 전에(평균 밝기 맞춤이 턱을 하얗게 날리지 않게)
    ty = np.mgrid[0:160, 0:256][0].astype(F) / 160.0
    out = out * (1.0 + np.clip(1.0 - ty * 160 / 5.0, 0, 1) * 0.2)[..., None] * (0.8 - np.clip(ty * 3.0, 0, 1) * 0.25)[..., None]   # 밝은 턱 → 바로 그늘
    fade = np.clip(1.0 - ty ** 1.1 * 1.25, 0, 1)
    out = out * fade[..., None] + hexc("#0c0b0b")[None, None, :] * (1 - fade[..., None])
    c.origin = (0, 0)
    return np.concatenate([(np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), np.full((160, 256, 1), 255, np.uint8)], -1)


_LV = dict({"%s_%s" % (d, s): {"side": d, "seed": 4 + i * 9 + j * 23} for i, d in enumerate(("n", "e", "w")) for j, s in enumerate("ab")}, **{"ne": {"side": "ne", "seed": 6}, "nw": {"side": "nw", "seed": 17}})


@flat("cliff_lip", "wall", layer="decal", cell=(64, 64), variants=_LV, name_ko="낭떠러지 턱", tags=["cliff", "edge", "void"],
    meta={"grid": True, "tile": [64, 64], "sheet": "fringes", "note": "빈 칸(어둠)에 깐다 — 바닥이 있는 쪽 변에서 부서져 들어온 바닥 가장자리와 그늘. n = 북쪽이 바닥(아래로 꺼진다) · e/w = 옆이 바닥. 남쪽이 바닥인 빈 칸에는 cliff_drop"})
def cliff_lip(c, side="n", seed=1):
    c.graded = False
    wide = _band(c, side, seed, 0.5, 0.2)
    c.paint(gblur(wide, 5.0) * 0.55, "#2a2826")                                        # 어둠 속으로 흐려지는 벼랑 면
    m = _band(c, side, seed, 0.12, 0.12)
    c.paint(m, hexc("#4a4844")[None, None, :] * (0.8 + c.noise(6, seed)[..., None] * 0.4))   # 부서진 바닥 턱
    c.paint(c.rim(m, 1.4) * 0.8, "#100c0a")
    c.origin = (32, 32)


# ── 다리 ─────────────────────────────────────────────────────────────────────

@prop("bridge", "structure", layer="decal", cell=(4, 3), tags=["bridge", "module", "passage"], name_ko="다리",
    variants={"wood_h": {}, "wood_v": {"axis": "v"}, "wood_broken": {"broken": True}, "wood_end": {"end": True}, "stone_h": {"mat": "stone"}, "stone_v": {"mat": "stone", "axis": "v"},
        "stone_broken": {"mat": "stone", "broken": True}, "rope_h": {"mat": "rope"}},
    meta={"module": [2, 1], "walkable": True, "note": "2칸 조각 — 이어 놓으면 긴 다리(몸보다 아래에 그린다 · 막지 않는다). broken = 가운데가 끊겼다(지나갈 수 없다 — 놓는 쪽에서 막는다) · end = 끊긴 끝 · rope = 흔들다리"})
def bridge(k, mat="wood", axis="h", broken=False, end=False, seed=1):
    r = k.rng
    L, Wd = 1.0, 0.42
    T = (lambda p: rot_z(p, np.pi / 2)) if axis == "v" else (lambda p: p)
    x1 = 0.15 if (broken or end) else L
    if mat == "stone":
        deck = lambda p: box(p, v3(0, 0, 0.05), (L, Wd, 0.06), 0.015)
        body = (lambda p: np.maximum(deck(p), np.minimum(p[:, 0] - x1 - (sdf.fbm(p, 0.2, seed, 2) - 0.5) * 0.3, 9.0) if end else -np.abs(p[:, 0] - 0.1) + 0.28 + (sdf.fbm(p, 0.2, seed, 2) - 0.5) * 0.3)) if (broken or end) else deck
        k.add(rough(lambda p: body(T(p)), 0.015, 0.2, seed), "masonry")
        for sy in (-Wd, Wd):   # 낮은 난간돌
            k.add(rough(lambda p, sy=sy: np.maximum(box(T(p), v3(0, sy, 0.14), (L, 0.05, 0.08), 0.01), (-np.abs(T(p)[:, 0] - 0.1) + 0.3) if broken else (T(p)[:, 0] - x1 if end else -9.0)), 0.015, 0.15, seed + 1), "stone_d")
        if broken or end:
            k.rubble([(0.2, -0.6), (-0.1, 0.55)], "stone", 0.04, 0.08)
        return {"shadow": 0.25}
    n = 11
    for i in range(n):         # 디딤 널
        x = -L + (i + 0.5) * 2 * L / n
        if (broken and abs(x - 0.1) < 0.3) or (end and x > x1):
            continue
        sag = 0.05 * (1 - (x / L) ** 2) if mat == "rope" else 0.0
        k.add(rough(lambda p, x=x, sag=sag, a=r.uniform(-0.06, 0.06): box(rot_z(T(p), a, (x, 0, 0)), v3(x, 0, 0.05 - sag), (0.075, Wd, 0.022), 0.006), 0.01, 0.1, seed + i), ("plank_y", "wood_d", "wood")[i % 3])
    for sy in (-Wd + 0.05, Wd - 0.05):
        if mat == "rope":      # 밧줄 둘 + 손잡이 줄
            k.add(lambda p, sy=sy: cap(T(p), v3(-L, sy, 0.04), v3(L, sy, 0.04), 0.022), "rope")
            k.add(lambda p, sy=sy: np.minimum(cap(T(p), v3(-L, sy, 0.5), v3(0, sy, 0.36), 0.016), cap(T(p), v3(0, sy, 0.36), v3(L, sy, 0.5), 0.016)), "rope")
        else:                  # 굵은 멍에목
            k.add(rough(lambda p, sy=sy: np.maximum(hcyl(T(p), v3(-L, sy, 0.0), v3(L, sy, 0.0), 0.05), (-np.abs(T(p)[:, 0] - 0.1) + 0.26) if broken else (T(p)[:, 0] - x1 - 0.1 if end else -9.0)), 0.012, 0.1, seed), "wood_d")
    for sx in (-L + 0.06, L - 0.06):   # 끝 말뚝
        if end and sx > 0:
            continue
        for sy in (-Wd, Wd):
            k.add(rough(lambda p, sx=sx, sy=sy: cap(T(p), v3(sx, sy, -0.03), v3(sx, sy, 0.55 if mat == "rope" else 0.3), 0.045), 0.012, 0.1, seed + 3), "wood_d")
    if broken:
        k.add(rough(lambda p: box(rot_z(T(p), 0.5, (0.15, -0.6, 0)), v3(0.15, -0.6, 0.03), (0.075, 0.3, 0.02)), 0.01, 0.1, seed), "plank_y")
    return {"shadow": 0.25}


# ── 폭포 ─────────────────────────────────────────────────────────────────────

_WF = {"clear": ("#5a8088", "#d8ecf0"), "red": ("#7a2a28", "#f0b0a0"), "black": ("#141a20", "#8a98a8")}


@flat("waterfall", "fx", layer="wall_decal", cell=(96, 200), tags=["water", "animated", "wall"], name_ko="폭포", fps=8,
    variants=dict({k: {"col": k, "frames": 4} for k in _WF}, **{"clear_wide": {"col": "clear", "frames": 4, "wide": True}}), meta={"mount": "face", "note": "벽면을 타고 쏟아지는 물줄기(원점 = 벽 밑동) + 떨어지는 자리 물보라. 옆으로 이어 놓으면 넓은 폭포"})
def waterfall(c, col="clear", wide=False, f=0, seed=1):
    c.graded = False
    body, foam = _WF[col]
    cx, half = c.w / 2, (40 if wide else 22)
    top, foot = 6.0, 168.0
    inside = sstep((half - np.abs(c.xx - cx) - (c.noise(8, seed + 1) - 0.5) * 8) / 3.0, 0, 1) * (c.yy > top) * (c.yy < foot)
    c.paint(inside, body, 0.88)
    v = (c.yy / 24.0 - (f or 0) * 0.25) % 1.0                                           # 아래로 흐르는 결(4프레임에 한 칸)
    col = c.noise(1.3, seed + 2, 2)[0:1, :] * np.ones_like(c.yy)                       # 세로 물줄기마다 다른 결
    streak = sstep(col, 0.5, 0.75) * sstep(np.sin((v + col * 3.0) * 2 * np.pi + c.noise(12, seed + 3) * 3.0), 0.1, 0.9)
    c.shade(inside * sstep(0.45 - col, 0.0, 0.2), -0.25)
    c.add(inside * np.clip(streak, 0, 1), foam, 0.4)
    c.add(inside * sstep(1.0 - np.abs(c.xx - cx) / half, 0.0, 0.25) * 0 + inside * sstep(np.abs(c.xx - cx) / half, 0.8, 1.0), foam, 0.35)   # 가장자리 흰 물
    for i in range(7):         # 물보라
        a = i * 0.9 + (f or 0) * 0.6
        px, py = cx + np.cos(a) * half * 1.1 * (0.5 + 0.5 * ((i + (f or 0)) % 3) / 2), foot + 6 + np.sin(a) * 5
        c.paint(sstep(1.0 - c.dist(px, py, 13, 8), 0, 0.8) * 0.5, foam)
    c.paint(sstep(1.0 - c.dist(cx, foot + 12, half * 1.5, 12), 0, 0.6) * 0.45, body)    # 고인 자리
    c.origin = (cx, foot + 8)


# ── 벽난로 · 깔개 ────────────────────────────────────────────────────────────

@prop("fireplace", "light", cell=(4, 4), collide=(1.5, 0.5), tags=["fire", "home", "wall"], name_ko="벽난로", interact="fire",
    variants={"lit": {"frames": 4}, "dying": {"state": "dying", "frames": 4}, "cold": {"state": "cold"}},
    light={"color": FIRE, "radius": 5.0, "at": (0, -0.3, 0.5), "flicker": 0.4, "variants": ["lit", "dying"]},
    meta={"states": {"idle": "cold", "active": "lit", "spent": "dying"}, "note": "벽에 붙여 세운다(원점 = 벽 밑동 앞). dying = 장작불이 꺼져 간다"})
def fireplace(k, state="lit", f=0, seed=1):
    for sx in (-0.62, 0.62):
        k.add(rough(lambda p, sx=sx: box(p, v3(sx, 0.2, 0.6), (0.16, 0.25, 0.6), 0.02), 0.02, 0.2, seed), "masonry")
    k.add(rough(lambda p: box(p, v3(0, 0.2, 1.3), (0.9, 0.3, 0.12), 0.02), 0.02, 0.2, seed + 1), "stone_d")              # 선반 돌
    k.add(rough(lambda p: np.maximum(box(p, v3(0, 0.28, 1.95), (0.5, 0.18, 0.55), 0.02), (np.abs(p[:, 0]) * 0.5 + p[:, 2] - 2.55) * 0.8), 0.02, 0.2, seed + 2), "masonry")   # 굴뚝 가슴
    k.add(lambda p: box(p, v3(0, 0.34, 0.6), (0.46, 0.1, 0.6)), "void")                                                   # 아궁이 속
    k.add(rough(lambda p: box(p, v3(0, -0.02, 0.04), (0.8, 0.32, 0.04), 0.012), 0.012, 0.15, seed + 3), "stone")          # 화덕 바닥돌
    for a, x in ((0.25, -0.12), (-0.3, 0.1), (0.05, 0.0)):
        k.add(lambda p, a=a, x=x: hcyl(p, v3(x - 0.24, 0.12 + a * 0.2, 0.13), v3(x + 0.24, 0.12 - a * 0.2, 0.15), 0.05), "coal" if state != "lit" else "wood_d")
    if state == "cold":
        k.add(lambda p: ell(p, v3(0, 0.1, 0.09), (0.32, 0.14, 0.03)), "ash")
        return {}
    post = [lambda img, vw: fx.embers(img, *vw.px(0, 0.1, 0.13), 20, 6, seed, f)]
    if state == "lit":
        post += [flame_post(-0.14, 0.1, 0.16, 22, seed + 1, f, "fire", 0.42, 0.5, 0.2), flame_post(0.06, 0.1, 0.16, 34, seed, f, "fire", 0.46, 2.2, 0.5), flame_post(0.2, 0.1, 0.16, 16, seed + 2, f, "fire", 0.4, 0.5, 0.2)]
    else:
        post += [flame_post(0.04, 0.1, 0.16, 11, seed, f, "fire", 0.4, 1.6, 0.25), lambda img, vw: fx.halo(img, *vw.px(0, 0.1, 0.2), 30, "#e06a20", 0.25 + 0.05 * np.sin((f or 0) * 1.57))]
    return {"post": post}


_CARPET = {"red": ("#5e2a26", "#a08a58"), "blue": ("#2e3c52", "#a09a80"), "green": ("#34442e", "#a08a58")}


@flat("carpet", "furniture", layer="decal", cell=(200, 144), tags=["home", "cloth"], name_ko="깔개",
    variants={"red": {"col": "red"}, "blue": {"col": "blue"}, "green": {"col": "green"}, "round": {"col": "red", "round": True}, "worn": {"col": "red", "worn": True}, "torn": {"col": "blue", "worn": True, "torn": True}})
def carpet(c, col="red", round=False, worn=False, torn=False, seed=1):
    base, trim = _CARPET[col]
    cx, cy = c.w / 2, c.h / 2
    if round:
        d = c.dist(cx, cy, 84, 60)
        body, inner, mid = sstep(1.0 - d, 0, 0.03), sstep(0.86 - d, 0, 0.03), sstep(0.45 - d, 0, 0.03)
    else:
        rect = lambda m: c.rect(10 + m, 12 + m * 0.72, c.w - 10 - m, c.h - 12 - m * 0.72)
        body, inner, mid = rect(0), rect(12), rect(40)
        fr = (np.abs(((c.yy - 12) / 5.0) % 1.0 - 0.5) < 0.3) * ((c.rect(2, 12, 10, c.h - 12) + c.rect(c.w - 10, 12, c.w - 2, c.h - 12)) > 0.5)
        c.paint(fr.astype(F), trim, 0.9)                                                 # 양 끝 술
    if torn:
        body = body * sstep(c.noise(26, seed + 3) + (c.xx / c.w - 0.5) * 0.9, 0.2, 0.26)
    weave = 0.9 + 0.1 * np.sin(c.yy * 2.2) * np.sin(c.xx * 2.2) + (c.noise(18, seed) - 0.5) * 0.2
    c.paint(body, hexc(base)[None, None, :] * weave[..., None])
    c.paint(np.clip(body - inner, 0, 1) * 0.0 + np.clip(inner - sstep(inner, 0.99, 1.0) * 0, 0, 1) * 0, trim)
    band = np.clip(inner - (c.rect(26, 26, c.w - 26, c.h - 26) if not round else sstep(0.74 - c.dist(cx, cy, 84, 60), 0, 0.03)), 0, 1) * body
    c.paint(band, hexc(trim)[None, None, :] * weave[..., None], 0.85)                    # 테 무늬 띠
    diamond = sstep(1.0 - (np.abs(c.xx - cx) / 46 + np.abs(c.yy - cy) / 30), 0, 0.05) * mid
    c.paint(np.clip(diamond - sstep(0.62 - (np.abs(c.xx - cx) / 46 + np.abs(c.yy - cy) / 30), 0, 0.05), 0, 1) * body, trim, 0.8)   # 가운데 마름모 테
    if worn:
        c.shade(body * sstep(c.noise(30, seed + 5), 0.5, 0.75), -0.4)
        c.paint(body * sstep(c.noise(12, seed + 6), 0.66, 0.74) * 0.6, "#3a342c")
    c.paint(c.rim(body, 1.4) * 0.7, "#16100e")
    c.origin = (cx, cy)
