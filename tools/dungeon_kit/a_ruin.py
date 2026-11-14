"""건축 · 구조물(에셋 라이브러리 — docs/asset_library): 낱 조각을 이어 붙여 여러 꼴을 만드는 모듈식 구조물.
공용: 폐허 담(곧은 · 낮은 · 모퉁이 · 창 · 문 · 밑동) · 포탈 비석 · 문양 새긴 석문 · 말뚝 울타리 · 천막.
지역 확장 · 전용: 흰 대리석 기둥(공용 기둥의 틀) · 기념비 · 굳은 둔덕 · 거울 · 탄광(철로 · 수레 · 버팀목 · 광맥).
문양(용기 · 지혜 · 운명 · 인내)의 도안은 설정 문서에 생김새가 없어 지어낸 것이다(docs/asset_library/REGIONAL_ASSET_PLAN.md)."""
import numpy as np

import fx
import mats as M
import sdf
from a_light import GLOWC, iglyph, shard
from a_nature import _rock
from kit import (F, box, cap, chip, cone, cut_above, cyl, ell, flat, gable, hcyl, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep

PULSE = lambda f: 0.75 + 0.25 * np.sin((f or 0) * 1.5708)


def _seg_mask(img, segs, width=2.0):
    """그림 px 위 꺾은 선 마스크(segs = [((x0, y0), (x1, y1))])."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    m = np.zeros((hh, ww), F)
    for (ax, ay), (bx, by) in segs:
        dx, dy = bx - ax, by - ay
        t = np.clip(((xx - ax) * dx + (yy - ay) * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
        m = np.maximum(m, np.clip((width * 0.5 - np.hypot(xx - ax - t * dx, yy - ay - t * dy)) / 0.7 + 0.5, 0, 1))
    return m


def _ring_segs(cx, cy, r, n=14, a0=0.0, a1=2 * np.pi):
    pts = [(cx + np.cos(a) * r, cy + np.sin(a) * r) for a in np.linspace(a0, a1, n + 1)]
    return list(zip(pts[:-1], pts[1:]))


# ── 폐허 담(석조 건축물 잔해) ────────────────────────────────────────────────

@prop("ruin_wall", "structure", cell=(4, 4), collide=(1.7, 0.4), tags=["stone", "ruin", "module"], name_ko="폐허 담",
    variants={"straight_a": {"seed": 3}, "straight_b": {"seed": 12}, "low": {"form": "low", "seed": 5}, "window": {"form": "window", "seed": 7}, "doorway": {"form": "door", "seed": 9},
        "corner": {"form": "corner", "seed": 11}, "stub": {"form": "stub", "seed": 14}, "mossy": {"seed": 3, "moss": True}, "sunk": {"form": "low", "seed": 16, "sand": True}},
    meta={"module": [1.8, 0.4], "note": "폭 1.8칸 조각 — 옆으로 이어 놓으면 긴 담, corner로 꺾는다. doorway는 가운데로 지나간다(막는 곳은 놓는 쪽에서 양쪽 기둥만)"})
def ruin_wall(k, form="straight", moss=False, sand=False, seed=1):
    mat = "masonry_m" if moss else "masonry"
    W2, D2 = 0.9, 0.17
    top = {"straight": 1.75, "low": 0.7, "window": 1.9, "door": 2.0, "corner": 1.6, "stub": 0.45}[form]
    slab = lambda p: box(p, v3(0, 0, 1.2), (W2, D2, 1.2), 0.015)
    body = cut_above(slab, top, 0.55 if form != "stub" else 0.25, 0.35, seed, 0.25 if seed % 2 else -0.25)
    if form == "window":
        body = (lambda b: lambda p: sub(b(p), box(p, v3(0.05, 0, 1.2), (0.26, 0.5, 0.36), 0.02)))(body)
    if form == "door":
        body = (lambda b: lambda p: sub(b(p), np.minimum(box(p, v3(0, 0, 0.6), (0.36, 0.5, 0.75)), np.maximum(np.hypot(p[:, 0], p[:, 2] - 1.3) - 0.36, np.abs(p[:, 1]) - 0.5))))(body)
    k.add(chip(rough(body, 0.025, 0.25, seed), 0.42, 0.3, seed, 0.06), mat)
    if form == "corner":      # 뒤로 꺾이는 날개
        wing = cut_above(lambda p: box(p, v3(-W2 + D2, 0.7, 1.2), (D2, 0.7, 1.2), 0.015), 1.2, 0.6, 0.35, seed + 1, 0.0)
        k.add(chip(rough(wing, 0.025, 0.25, seed + 1), 0.42, 0.3, seed + 1, 0.06), mat)
    k.add(rough(lambda p: box(p, v3(0, 0, 0.07), (W2 + 0.05, D2 + 0.05, 0.07), 0.02), 0.02, 0.2, seed + 2), "stone_d")    # 밑단
    for i, (x, y) in enumerate(k.scatter(5, 0.9, 0.2, 0.1, -0.42)):                                                        # 굴러떨어진 마름돌
        a = k.rng.uniform(0, 3.14)
        k.add(rough(lambda p, x=x, y=y, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.07), (0.13, 0.08, 0.07), 0.015), 0.02, 0.1, seed + i), ("stone", "stone_d")[i % 2])
    if sand:                  # 모래에 묻혔다
        k.add(lambda p: np.maximum(ell(p, v3(-0.2, -0.25, 0), (1.1, 0.45, 0.3)), -p[:, 2]) + (sdf.fbm(p, 0.2, seed, 2) - 0.5) * 0.05, "sand")
    return {}


# ── 포탈 비석 ────────────────────────────────────────────────────────────────

@prop("portal_stele", "structure", cell=(3, 5), collide=(0.9, 0.6), tags=["stone", "portal", "landmark"], name_ko="포탈 비석", interact="portal",
    variants={"idle": {}, "active": {"col": "blue", "frames": 4}, "active_dark": {"col": "violet", "frames": 4}, "dead": {"dead": True}, "giant": {"big": True}, "leaning": {"lean": 0.16}},
    light={"color": GLOWC["blue"], "radius": 3.0, "at": (0, -0.2, 1.2), "flicker": 0.1, "variants": ["active", "active_dark"], "colors": {"active_dark": GLOWC["violet"]}},
    meta={"states": {"idle": "idle", "active": "active", "spent": "dead"}, "note": "dead = 다른 비석이 열려 돌덩이로 변한 모습 · giant = 랜드마크로 쓰는 거대한 비석"})
def portal_stele(k, col=None, dead=False, big=False, lean=0.0, f=0, seed=1):
    s = 1.45 if big else 1.0
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.07), (0.5 * s, 0.34 * s, 0.07), 0.02), box(p, v3(0, 0.02, 0.2), (0.38 * s, 0.26 * s, 0.07), 0.02)), 0.02, 0.2, seed), "stone_d")   # 두 단 받침
    if dead:                  # 글자가 사라진 돌덩이
        k.add(_rock((0, 0.02, 0.62), (0.34, 0.26, 0.42), seed, 7, 0.06), "stone")
        k.rubble([(0.42, -0.3), (-0.4, -0.26)], "stone_d", 0.04, 0.08)
        return {}
    h = 2.1 * s
    slab = lambda p: np.maximum(box(p, v3(0, 0.02, h / 2 + 0.25), (0.27 * s, 0.1 * s, h / 2), 0.02), (np.abs(p[:, 0]) * 0.8 + p[:, 2] - h - 0.2) * 0.75)   # 위가 뾰족한 판
    k.add(rough((lambda p: slab(rot_y(p, lean, (0, 0, 0.2)))) if lean else slab, 0.025, 0.25, seed), "carved")
    k.rubble([(0.45 * s, -0.32 * s)], "stone_d", 0.04, 0.07)
    post = []
    for i in range(5):        # 새긴 글줄(지어낸 글자) — 켜지면 빛난다
        z = 0.62 * s + i * 0.3 * s
        x = np.sin(lean) * (z - 0.2)

        def glyph(img, vw, z=z, x=x, i=i):
            px, py = vw.px(x, -0.12 * s, z)
            m = iglyph(img, px, py, 9 * s, 40 + i, 1.6) * (img[..., 3] > 128)
            if col is None:
                return fx._over(img, m * 0.75, hexc("#1c1614"))
            return fx.halo(fx._over(img, m, hexc(GLOWC[col]) * 0.6 + 0.4), px, py, 13, GLOWC[col], 0.5 * PULSE(f + i))
        post.append(glyph)
    return {"post": post}


@prop("monument", "structure", cell=(4, 4), collide=(1.6, 0.8), tags=["stone", "landmark", "altar"], name_ko="기념비", reuse="region", interact="altar",
    variants={"plain": {}, "offered": {"offered": True, "frames": 4}, "worn": {"worn": True}}, light={"color": "#8a5ad0", "radius": 2.5, "at": (0, -0.4, 0.6), "flicker": 0.2, "variants": ["offered"]},
    meta={"states": {"idle": "plain", "active": "offered"}, "note": "공동 한가운데 서는 기념석 — 앞 턱에 마석을 올리면(offered) 포탈이 열린다"})
def monument(k, offered=False, worn=False, f=0, seed=1):
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.08), (0.95, 0.5, 0.08), 0.02), box(p, v3(0, 0.05, 0.24), (0.75, 0.36, 0.08), 0.02)), 0.02, 0.2, seed), "stone_d")
    body = lambda p: np.maximum(box(p, v3(0, 0.1, 1.2), (0.55, 0.16, 0.95), 0.03), np.where(p[:, 2] > 1.6, np.hypot(p[:, 0], p[:, 2] - 1.6) - 0.55, -1.0))     # 위가 둥근 넓은 비
    k.add(chip(rough(body, 0.03, 0.25, seed), 0.45, 0.3, seed, 0.05) if worn else rough(body, 0.02, 0.25, seed), "marble")
    k.add(rough(lambda p: box(p, v3(0, -0.3, 0.42), (0.3, 0.14, 0.1), 0.02), 0.015, 0.15, seed + 1), "stone")                             # 공물 턱
    post = [lambda img, vw, i=i: fx._over(img, iglyph(img, *vw.px(-0.3 + (i % 4) * 0.2, -0.07, 1.6 - (i // 4) * 0.3), 7, 70 + i, 1.4) * (img[..., 3] > 128) * 0.7, hexc("#1c1614")) for i in range(12)]
    if offered:
        k.add(shard(v3(0, -0.3, 0.5), 0.07, 0.12), "crystal_v")
        post.append(lambda img, vw: fx.halo(img, *vw.px(0, -0.3, 0.62), 30, "#8a5ad0", 0.5 * PULSE(f)))
    return {"post": post}


# ── 문양 새긴 석문(벽에 세운다) ──────────────────────────────────────────────

def _emblem(kind, cx, cy, u):
    """문양 도안 → 선분 목록(지어낸 도안 — 용기 = 곧게 선 칼날 · 지혜 = 눈 · 운명 = 바퀴 · 인내 = 모래시계)."""
    r = 0.26 * u
    if kind == "courage":
        return [((cx, cy - r * 1.2), (cx, cy + r)), ((cx - r * 0.55, cy + r * 0.45), (cx + r * 0.55, cy + r * 0.45)), ((cx, cy - r * 1.2), (cx - r * 0.2, cy - r * 0.7)), ((cx, cy - r * 1.2), (cx + r * 0.2, cy - r * 0.7))]
    if kind == "wisdom":
        up = [(cx - r * 1.1 + i * r * 0.55, cy - np.sin(i * np.pi / 4) * r * 0.6) for i in range(5)]
        dn = [(x, 2 * cy - y) for x, y in up]
        return list(zip(up[:-1], up[1:])) + list(zip(dn[:-1], dn[1:])) + _ring_segs(cx, cy, r * 0.3, 10)
    if kind == "fate":
        return _ring_segs(cx, cy, r, 16) + _ring_segs(cx, cy, r * 0.3, 8) + [((cx + np.cos(a) * r * 0.3, cy + np.sin(a) * r * 0.3), (cx + np.cos(a) * r, cy + np.sin(a) * r)) for a in np.arange(8) * np.pi / 4]
    if kind == "patience":
        return [((cx - r * 0.7, cy - r), (cx + r * 0.7, cy - r)), ((cx - r * 0.7, cy + r), (cx + r * 0.7, cy + r)), ((cx - r * 0.7, cy - r), (cx + r * 0.7, cy + r)), ((cx + r * 0.7, cy - r), (cx - r * 0.7, cy + r))]
    return _ring_segs(cx, cy, r, 16) + _ring_segs(cx, cy, r * 0.62, 12) + [((cx - r * 0.62, cy), (cx + r * 0.62, cy)), ((cx, cy - r * 0.62), (cx, cy + r * 0.62))]   # plain: 기하학 문양


_SD = {"plain": {"kind": "plain"}, "courage": {"kind": "courage"}, "wisdom": {"kind": "wisdom"}, "fate": {"kind": "fate"}, "patience": {"kind": "patience"},
    "lit": {"kind": "plain", "lit": True, "frames": 4}, "open": {"kind": None}}


@prop("sealed_door", "wall", cell=(4, 4), collide=[(-0.95, -0.05, 0.3, 0.45), (0.65, -0.05, 0.3, 0.45)], tags=["wall", "passage", "door", "stone", "seal"], name_ko="문양 새긴 석문", interact="door", variants=_SD,
    light={"color": GLOWC["blue"], "radius": 3.0, "at": (0, -0.3, 1.1), "flicker": 0.1, "variants": ["lit"]},
    meta={"tile_w": 2, "passage": True, "blocks": [v for v in _SD if v != "open"], "states": {"closed": "plain", "active": "lit", "open": "open"},
        "note": "벽면 줄의 두 칸을 대신하는 큰 석문. open이 아니면 가운데도 막힌다(놓는 쪽에서 — blocks). 문양 넷은 시련의 문, lit = 빛나며 열리는 중"})
def sealed_door(k, kind="plain", lit=False, f=0, seed=1):
    H = 2.3
    for sx in (-0.8, 0.8):    # 문설주
        k.add(rough(lambda p, sx=sx: box(p, v3(sx, 0.1, H / 2), (0.16, 0.2, H / 2), 0.02), 0.02, 0.2, seed), "stone_d")
    k.add(rough(lambda p: box(p, v3(0, 0.1, H + 0.14), (1.0, 0.22, 0.16), 0.02), 0.02, 0.2, seed + 1), "stone_d")          # 상인방
    if kind is None:          # 열렸다: 안은 어둠, 문짝은 양옆으로 밀려 들어갔다
        k.add(lambda p: box(p, v3(0, 0.25, H / 2), (0.64, 0.03, H / 2)), "void")
        return {}
    for sx in (-0.32, 0.32):  # 문짝 둘
        k.add(rough(lambda p, sx=sx: box(p, v3(sx, 0.14, H / 2), (0.315, 0.08, H / 2 - 0.01), 0.015), 0.012, 0.3, seed + 2), "carved")

    def carve(img, vw):
        cx, cy = vw.px(0, 0.06, 1.3)
        segs = _emblem(kind, cx, cy, vw.u * 1.6)
        segs += [((vw.px(-0.6, 0.06, z)[0], vw.px(0, 0.06, z)[1]), (vw.px(0.6, 0.06, z)[0], vw.px(0, 0.06, z)[1])) for z in (0.35, 2.15)]     # 위아래 띠
        m = _seg_mask(img, segs, 1.8 if lit else 2.4) * (img[..., 3] > 128)
        if not lit:
            hi = np.clip(np.roll(m, (1, 1), (0, 1)) - m, 0, 1)
            return fx._over(fx._over(img, m * 0.8, hexc("#18130f")), hi * 0.35, hexc("#b0aa98"))
        k_ = PULSE(f)
        seam = _seg_mask(img, [(vw.px(0, 0.06, 0.05), vw.px(0, 0.06, H - 0.05))], 2.0 + f) * (img[..., 3] > 128)                           # 벌어지는 문틈
        img = fx._over(img, np.clip(gblur(m + seam, 2.0) * 1.2, 0, 1) * 0.35 * k_, hexc(GLOWC["blue"]))
        return fx.halo(fx._over(img, np.clip(m + seam, 0, 1) * 0.85, hexc("#b8d8f4")), cx, cy, 60, GLOWC["blue"], 0.28 * k_)
    return {"post": [carve]}


# ── 흰 대리석 기둥(공용 기둥의 틀을 넓힘) ────────────────────────────────────

@prop("pillar_white", "structure", cell=(3, 5), collide=(0.8, 0.65), tags=["stone", "temple", "marble"], name_ko="흰 대리석 기둥", reuse="ext", base="pillar",
    variants={"intact": {}, "cracked": {"state": "cracked"}, "broken": {"state": "broken"}, "glowing": {"state": "glowing", "frames": 4}, "sunken": {"state": "sunken"}},
    light={"color": "#a8d0f0", "radius": 3.0, "at": (0, 0, 1.6), "flicker": 0.05, "variants": ["glowing"]}, meta={"note": "glowing = 다가가면 빛을 내는 기둥 · sunken = 물에 잠겨 삭은 기둥"})
def pillar_white(k, state="intact", f=0, seed=1):
    h = 3.0
    white = k.mat("white", M.stone("#b4b0a6", "#4a6a5a" if state == "sunken" else None, seed, 0.0))
    flute = lambda p: np.abs(np.cos(np.arctan2(p[:, 1], p[:, 0]) * 8.0)) * 0.022
    shaft = lambda p: cyl(p, v3(0, 0, 0.34), 0.25 - 0.0, h - 0.74) + flute(p) - np.clip(1.6 - p[:, 2], -1, 1) * 0.012     # 아래가 조금 굵다(배흘림)
    base = lambda p: np.minimum(box(p, v3(0, 0, 0.08), (0.4, 0.36, 0.08), 0.015), np.minimum(torus(p, v3(0, 0, 0.21), 0.28, 0.06), torus(p, v3(0, 0, 0.3), 0.26, 0.045)))
    capital = lambda p: np.minimum(np.minimum(torus(p, v3(0, 0, h - 0.4), 0.27, 0.05), cyl(p, v3(0, 0, h - 0.36), 0.33, 0.14, 0.05)), box(p, v3(0, 0, h - 0.13), (0.36, 0.33, 0.055), 0.015))
    k.add(rough(base, 0.012, 0.2, seed), white)
    if state in ("broken",):
        k.add(cut_above(rough(shaft, 0.015, 0.3, seed), 1.3, 0.3, 0.2, seed, 0.4), white)
        k.add(rough(lambda p: hcyl(p, v3(0.5, -0.25, 0.24), v3(1.1, -0.15, 0.24), 0.24) + np.abs(np.cos(np.arctan2(p[:, 2] - 0.24, p[:, 1] + 0.2) * 8.0)) * 0.02, 0.02, 0.2, seed + 3), white)
        k.rubble([(0.4, -0.45), (-0.45, -0.25), (1.3, -0.4)], white, 0.05, 0.1)
        return {"cell": (4, 4), "dx": -0.4}
    body = rough(shaft, 0.012, 0.3, seed)
    if state in ("cracked", "sunken"):
        body = chip(body, 0.47, 0.28, seed, 0.06)
    k.add(body, white)
    k.add(rough(capital, 0.012, 0.2, seed + 1), white)
    if state != "glowing":
        return {}
    return {"post": [lambda img, vw: fx.halo(fx.tint(img, "#a8d0f0", 0.16 * PULSE(f)), *vw.px(0, 0, 1.6), 80, "#a8d0f0", 0.32 * PULSE(f))]}


# ── 굳은 둔덕(망자의 땅) ─────────────────────────────────────────────────────

@prop("mound", "terrain", cell=(5, 3), collide=(1.6, 0.6), tags=["earth", "dead", "ground"], name_ko="굳은 둔덕", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 11}, "long": {"seed": 6, "long": True}, "ruin": {"seed": 3, "ruin": True}}, meta={"note": "땅이 딱딱해지며 솟은 둔덕. ruin = 석조 잔해가 박힌 둔덕"})
def mound(k, long=False, ruin=False, seed=1):
    earth = k.mat("earth", M.plain("#3a3632", 0.4, 0.2, seed))
    w = 1.5 if long else 1.0
    k.add(lambda p: np.maximum(smin(ell(p, v3(-w * 0.3, 0, 0), (w * 0.8, 0.5, 0.42)), ell(p, v3(w * 0.4, 0.05, 0), (w * 0.6, 0.42, 0.3)), 0.25), -p[:, 2]) + (sdf.fbm(p, 0.25, seed, 3) - 0.5) * 0.09, earth)
    k.rubble(k.scatter(6, w, 0.4), "stone_d", 0.035, 0.08)
    if ruin:
        k.add(chip(rough(lambda p: box(rot_y(p, 0.3, (0.1, 0, 0.3)), v3(0.1, 0, 0.35), (0.3, 0.14, 0.4), 0.02), 0.02, 0.2, seed), 0.45, 0.3, seed, 0.06), "masonry")
        k.add(rough(lambda p: hcyl(p, v3(-0.75, -0.2, 0.16), v3(-0.3, -0.3, 0.2), 0.14), 0.03, 0.2, seed + 1), "stone")
    return {"shadow": 0.4}


# ── 거울(대마경의 거울) ──────────────────────────────────────────────────────

@prop("great_mirror", "special", cell=(3, 5), collide=(1.0, 0.5), tags=["mirror", "magic", "portal"], name_ko="거울", reuse="region", interact="portal",
    variants={"dormant": {}, "active": {"on": True, "frames": 4}, "broken": {"broken": True}}, light={"color": "#c8d8e8", "radius": 3.0, "at": (0, -0.2, 1.3), "flicker": 0.15, "variants": ["active"]},
    meta={"states": {"idle": "dormant", "active": "active", "spent": "broken"}})
def great_mirror(k, on=False, broken=False, f=0, seed=1):
    """돌 받침에 세운 커다란 거울: 테는 청동, 면은 어둠을 비춘다. active = 빛이 휘감는다."""
    k.add(rough(lambda p: box(p, v3(0, 0, 0.1), (0.55, 0.3, 0.1), 0.02), 0.02, 0.2, seed), "stone_d")
    frame = lambda p: np.maximum(np.abs(np.hypot(p[:, 0] / 0.46, (p[:, 2] - 1.35) / 1.0) - 1.0) * 0.46 - 0.07, np.abs(p[:, 1]) - 0.06)
    k.add(rough(frame, 0.012, 0.15, seed), "bronze")
    glass = lambda p: np.maximum(np.hypot(p[:, 0] / 0.44, (p[:, 2] - 1.35) / 0.98) * 0.44 - 0.44, np.abs(p[:, 1]) - 0.02)
    if broken:
        k.add(lambda p: np.maximum(glass(p), (sdf.fbm(p, 0.3, seed, 2) - 0.48) * 0.6), k.mat("mirror", M.plain("#26303a", 0.2, 0.3, seed)))
        k.add(lambda p: box(p, v3(0, 0.03, 1.35), (0.4, 0.01, 0.9)), "void")
        for i, (x, y) in enumerate(((0.3, -0.4), (-0.25, -0.45), (0.6, -0.3))):
            k.add(lambda p, x=x, y=y, i=i: box(rot_z(p, i * 1.1, (x, y, 0)), v3(x, y, 0.015), (0.09, 0.05, 0.012)), "glass")
        return {}
    k.add(glass, k.mat("mirror", M.plain("#26303a", 0.2, 0.3, seed)))

    def sheen(img, vw):
        cx, cy = vw.px(0, -0.05, 1.35)
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        inside = sstep(1.0 - np.hypot((xx - cx) / (0.4 * vw.u), (yy - cy) / (0.92 * vw.u)), 0, 0.08)
        band = np.clip(1.0 - np.abs((xx - cx) + (yy - cy) * 0.5 + 6.0) / 5.0, 0, 1) + np.clip(1.0 - np.abs((xx - cx) + (yy - cy) * 0.5 - 12.0) / 2.5, 0, 1) * 0.6
        img = fx._over(img, inside * band * 0.3, hexc("#c0d0dc"))
        if not on:
            return img
        swirl = 0.5 + 0.5 * np.cos(np.arctan2(yy - cy, xx - cx) * 2 + np.hypot(xx - cx, yy - cy) * 0.12 - (f or 0) * 1.5708)
        img = fx._over(img, inside * swirl * 0.55 * PULSE(f), hexc("#dce8f4"))
        return fx.halo(img, cx, cy, 70, "#c8d8e8", 0.35 * PULSE(f))
    return {"post": [sheen]}


# ── 말뚝 울타리 · 천막(야영지 · 군락) ────────────────────────────────────────

@prop("palisade", "structure", cell=(4, 4), collide=(1.8, 0.3), tags=["wood", "camp", "module", "fence"], name_ko="말뚝 울타리",
    variants={"straight_a": {"seed": 3}, "straight_b": {"seed": 10}, "broken": {"seed": 5, "broken": True}, "corner": {"seed": 7, "corner": True}, "gate": {"seed": 9, "gate": "closed"}, "gate_open": {"seed": 9, "gate": "open"}, "spiked": {"seed": 12, "spikes": True}},
    meta={"module": [1.8, 0.3], "states": {"closed": "gate", "open": "gate_open"}, "note": "폭 1.8칸 조각. gate_open은 가운데로 지나간다 · spiked = 바깥으로 내민 말뚝(방책)"})
def palisade(k, broken=False, corner=False, gate=None, spikes=False, seed=1):
    r = k.rng
    n = 8

    def stake(x, y, h, lean=0.0, mat="wood"):
        k.add(rough(lambda p: np.minimum(cap(rot_y(p, lean, (x, y, 0)), v3(x, y, -0.05), v3(x, y, h), 0.1, 0.09), cone(rot_y(p, lean, (x, y, 0)), v3(x, y, h), 0.09, 0.2)), 0.02, 0.12, seed + int(x * 10)), mat)
    xs = [-0.79 + i * 0.225 for i in range(n)]
    for i, x in enumerate(xs):
        if gate and 2 <= i <= 5:
            continue
        if broken and i in (3, 4):
            stake(x, 0, 0.45 + r.uniform(0, 0.2), 0.0, "wood_d")
            continue
        stake(x, r.uniform(-0.02, 0.02), 1.5 + r.uniform(-0.15, 0.15), r.uniform(-0.05, 0.05), ("wood", "wood_d", "wood_l")[i % 3])
    if not gate:
        for z in (0.5, 1.1):  # 가로대 + 묶은 밧줄
            k.add(lambda p, z=z: hcyl(p, v3(-0.88, -0.11, z), v3(0.88, -0.11, z), 0.035), "wood_d")
    if gate == "closed":
        k.add(rough(lambda p: box(p, v3(0, -0.02, 0.75), (0.44, 0.04, 0.7), 0.01), 0.015, 0.15, seed), "plank_y")
        for z in (0.35, 1.15):
            k.add(lambda p, z=z: box(p, v3(0, -0.07, z), (0.44, 0.02, 0.05)), "iron")
    if gate == "open":
        k.add(rough(lambda p: box(rot_z(p, 1.25, (-0.44, 0, 0)), v3(0, -0.02, 0.75), (0.44, 0.04, 0.7), 0.01), 0.015, 0.15, seed), "plank_y")
    if corner:
        for i in range(5):
            stake(-0.79, 0.25 + i * 0.225, 1.5 + r.uniform(-0.15, 0.15), 0.0, ("wood_d", "wood")[i % 2])
    if broken:
        k.add(rough(lambda p: hcyl(p, v3(-0.2, -0.45, 0.09), v3(0.7, -0.3, 0.09), 0.09), 0.02, 0.12, seed), "wood")
    if spikes:
        for i in range(4):
            x = -0.6 + i * 0.4
            k.add(rough(lambda p, x=x: cap(p, v3(x, 0.0, 0.25), v3(x + 0.05, -0.75, 0.8), 0.06, 0.008), 0.01, 0.1, seed + i), "wood_l")
    return {}


@prop("tent", "structure", cell=(5, 4), collide=(1.8, 1.0), tags=["camp", "cloth", "shelter"], name_ko="천막",
    variants={"canvas": {}, "canvas_b": {"col": "cloth_g", "seed": 8}, "hide": {"kind": "hide"}, "collapsed": {"kind": "down"}})
def tent(k, kind="canvas", col="linen", seed=1):
    hide = k.mat("hide", M.hide("#6e5a40"))
    if kind == "down":        # 무너진 천막: 꺾인 장대 위로 천이 널렸다
        k.add(lambda p: np.maximum(ell(p, v3(0, 0, 0), (1.0, 0.6, 0.22)), -p[:, 2]) + (sdf.fbm(p, 0.2, seed, 3) - 0.5) * 0.16, col)
        k.add(lambda p: cap(p, v3(-0.9, -0.2, 0.05), v3(0.5, 0.1, 0.45), 0.04), "wood_d")
        return {"shadow": 0.4}
    mat = hide if kind == "hide" else col
    body = lambda p: gable(p, v3(0, 0, 0), 0.85, 0.75, 1.25, 1)       # 용마루가 깊이 쪽 — 앞에 세모 입구
    k.add(lambda p: body(p) + (sdf.fbm(p, 0.35, seed, 2) - 0.5) * 0.05, mat)
    k.add(lambda p: np.maximum(np.abs(p[:, 0]) * 1.25 + p[:, 2] - 0.85, np.abs(p[:, 1] + 0.8) - 0.12), "void")   # 입구
    k.add(lambda p: cap(p, v3(0, -0.86, 0), v3(0, -0.86, 1.38), 0.035), "wood_d")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: cap(p, v3(sx * 0.75, -0.8, 0.05), v3(sx * 1.05, -1.0, 0.0), 0.012), "rope")
    return {}


# ── 탄광(녹색 탄광) ──────────────────────────────────────────────────────────

@flat("mine_track", "structure", cell=(128, 128), tags=["mine", "rail", "module"], name_ko="철로", reuse="region",
    variants={"straight_h": {}, "straight_v": {"dir": "v"}, "curve": {"dir": "curve"}, "broken": {"broken": True}, "end": {"end": True}},
    meta={"module": [2, 2], "note": "2칸 조각 — 이어 깔면 철로. curve는 서 → 남으로 꺾인다(뒤집어 다른 방향)"})
def mine_track(c, dir="h", broken=False, end=False, seed=1):
    rng = c.rng

    def path(t):   # t 0~1 → (x, y, 접선)
        if dir == "v":
            return 64.0, t * 128.0, (0.0, 1.0)
        if dir == "curve":
            a = t * np.pi / 2
            return 128.0 * (1 - np.cos(a)) * 0 + np.sin(a) * 64.0 * 0 + (64.0 * np.sin(a)), 128.0 - 64.0 * np.cos(a), (np.cos(a), np.sin(a))
        return t * 128.0, 64.0, (1.0, 0.0)
    t1 = 0.62 if (broken or end) else 1.0
    for i in range(7):    # 침목
        t = (i + 0.5) / 7
        if t > t1 + 0.05:
            continue
        x, y, (tx, ty) = path(t)
        nx, ny = -ty, tx
        m = c.seg([(x - nx * 26, y - ny * 26 * 0.8), (x + nx * 26, y + ny * 26 * 0.8)], 9.0, False)
        c.paint(m, hexc("#4a3a2a") * rng.uniform(0.8, 1.15))
        c.paint(c.rim(m, 1.2) * 0.7, "#16100e")
    for side in (-1, 1):  # 레일 둘
        pts = []
        for t in np.linspace(0, t1, 14):
            x, y, (tx, ty) = path(t)
            pts.append((x - ty * 15 * side, y + tx * 15 * side * 0.8))
        if broken:        # 끝이 휘어 들렸다
            pts[-1] = (pts[-1][0] + 5, pts[-1][1] - 9 * side)
        m = c.seg(pts, 4.5, False)
        c.paint(c.seg([(x + 1.5, y + 2) for x, y in pts], 5.0, False) * 0.5, "#141010")
        c.paint(m, "#5a544e")
        c.paint(c.seg([(x - 0.6, y - 0.9) for x, y in pts], 1.4, False) * 0.7, "#8a8680")
        c.paint(m * (c.noise(6, seed + side) > 0.6) * 0.6, "#6a4630")
    if end:               # 멈춤목
        x, y, _ = path(t1)
        m = c.rect(x + 2, y - 22, x + 12, y + 22)
        c.paint(m, "#4a3a2a")
        c.paint(c.rim(m, 1.2) * 0.8, "#16100e")
    c.origin = (64, 64)


@prop("mine_cart", "structure", cell=(3, 3), collide=(1.0, 0.6), tags=["mine", "container"], name_ko="광차", reuse="region", interact="container",
    variants={"empty": {}, "ore": {"load": "ore"}, "rubble": {"load": "rubble"}, "tipped": {"tipped": True}})
def mine_cart(k, load=None, tipped=False, seed=1):
    tub = lambda p: sub(box(p, v3(0, 0, 0.5), (0.5, 0.32, 0.26), 0.03), box(p, v3(0, 0, 0.58), (0.44, 0.26, 0.26)))
    wheels = lambda p: np.minimum.reduce([np.maximum(np.hypot(p[:, 0] - sx, p[:, 2] - 0.14) - 0.14, np.abs(p[:, 1] - sy) - 0.03) for sx in (-0.3, 0.3) for sy in (-0.3, 0.3)])
    T_ = (lambda p: rot_x(p, -1.2, (0, -0.3, 0))) if tipped else (lambda p: p)
    k.add(rough(lambda p: tub(T_(p)), 0.012, 0.2, seed), "rust")
    k.add(lambda p: wheels(T_(p)), "iron")
    k.add(lambda p: box(T_(p), v3(0, 0, 0.24), (0.42, 0.22, 0.03)), "wood_d")
    if load:
        gem = k.mat("gem_g", M.plain("#3e8a52", 0.4, 0.2, seed))
        for i, (x, y) in enumerate(k.scatter(7, 0.38, 0.2)):
            k.add(_rock((x, y, 0.72 + k.rng.uniform(0, 0.08)), (0.12, 0.1, 0.09), seed + i, 5, 0.02), gem if (load == "ore" and i % 2 == 0) else "stone_d")
    if tipped:
        k.rubble(k.scatter(5, 0.5, 0.2, 0.1, -0.7), "stone_d", 0.05, 0.1)
    return {}


@prop("mine_support", "structure", cell=(4, 4), collide=[(-0.95, -0.15, 0.3, 0.3), (0.65, -0.15, 0.3, 0.3)], tags=["mine", "wood", "module"], name_ko="갱도 버팀목", reuse="region",
    variants={"intact": {}, "sagging": {"sag": True}, "collapsed": {"down": True}}, meta={"passage": True, "note": "collapsed = 천장이 무너져 막힌 자리(지나갈 수 없다 — 놓는 쪽에서 막는다)"})
def mine_support(k, sag=False, down=False, seed=1):
    for sx in (-0.8, 0.8):
        k.add(rough(lambda p, sx=sx: cap(rot_y(p, 0.1 * (1 if sx > 0 else -1) * (2.5 if sag else 0.3), (sx, 0, 0)), v3(sx, 0, -0.05), v3(sx, 0, 2.2 if not down else 1.2), 0.1), 0.02, 0.12, seed), "wood_d")
    if down:
        k.add(rough(lambda p: hcyl(p, v3(-0.7, -0.2, 0.9), v3(0.75, -0.25, 0.25), 0.1), 0.02, 0.12, seed), "wood")
        for i, (x, y) in enumerate(k.scatter(9, 0.75, 0.3)):
            s = k.rng.uniform(0.15, 0.32)
            k.add(_rock((x, y, s * 0.6 + (0.7 - abs(x)) * 0.5), (s * 1.2, s, s * 0.85), seed + i, 5, 0.03), ("stone", "stone_d")[i % 2])
        k.rubble(k.scatter(6, 1.0, 0.3, 0, -0.45), "stone_d", 0.05, 0.1)
        return {}
    z = 2.2
    k.add(rough(lambda p: hcyl(p, v3(-0.95, 0, z + (0.0 if not sag else 0.05)), v3(0.95, 0, z - (0.0 if not sag else 0.3)), 0.11), 0.02, 0.12, seed + 1), "wood")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: cap(p, v3(sx * 0.78, 0, 1.75), v3(sx * 0.4, 0, z - 0.05), 0.05), "wood_l")
    return {}


@prop("ore_vein", "terrain", cell=(3, 3), collide=(0.8, 0.55), tags=["mine", "ore", "rock", "breakable"], name_ko="광맥 바위", reuse="ext", base="rock", interact="breakable",
    variants={"green": {"seed": 4}, "green_b": {"seed": 13}, "mined": {"seed": 4, "mined": True}, "iron": {"seed": 8, "ore": "iron"}},
    light={"color": GLOWC["green"], "radius": 1.6, "at": (0, 0, 0.4), "flicker": 0.05, "variants": ["green", "green_b"]}, meta={"states": {"idle": "green", "spent": "mined"}})
def ore_vein(k, mined=False, ore="green", seed=1):
    """부술 수 있는 광물 바위: green = 초록빛 보석이 박혔다 · mined = 캐낸 뒤."""
    r = np.random.default_rng(seed)
    body = _rock((0, 0.02, 0.3), (0.5, 0.38, 0.42), seed, 8, 0.06)
    if mined:
        k.add(lambda p: sub(body(p), sphere(p, v3(0.05, -0.3, 0.35), 0.3)), "stone_d")
        k.rubble(k.scatter(7, 0.6, 0.2, 0.1, -0.45), "stone_d", 0.04, 0.09)
        return {}
    k.add(body, "stone_d")
    gem = k.mat("gem", M.plain("#3e8a52", 0.45, 0.2, seed) if ore == "green" else M.metal("#6a5a50", "#8a5a3a", seed, 0.6))
    tips = []
    for i in range(6):
        a = r.uniform(-1.3, 1.3)
        x, z = np.sin(a) * 0.36, 0.3 + np.cos(a) * 0.26
        k.add(shard(v3(x, -0.2 + r.uniform(-0.08, 0.05), z - 0.05), r.uniform(0.06, 0.09), r.uniform(0.09, 0.16), r.uniform(0.2, 0.8), -a * 0.7), gem)
        tips.append((x, -0.3, z + 0.08))
    k.rubble([(0.5, -0.3), (-0.45, -0.28)], "stone_d", 0.035, 0.07)
    if ore != "green":
        return {}
    return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, -0.1, 0.4), 34, GLOWC["green"], 0.25), [vw.px(*t) for t in tips[:3]], "#d8ffd0", 1.8)]}
