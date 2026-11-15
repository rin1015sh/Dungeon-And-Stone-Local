"""도시 공공시설 — 우물 · 분수 · 가로등 · 게시판 · 표지판 · 안내판 · 광장 장식(돌말뚝 · 물구유 · 오벨리스크 · 해시계) ·
성문 · 성벽 · 망루 · 쇠 울타리 · 나무 울타리. (방책은 palisade, 벽 횃불 · 걸린 랜턴은 a_light — 다시 만들지 않는다.)
원점 = 발(바닥에 닿는 가운데). 줄로 잇는 조각(성벽 · 울타리)은 한 칸 간격으로 놓으면 이어진다 — a_city_build.crop과 같은 방식."""
import numpy as np

import fx
import sdf
import mats as M
from a_city_build import crop, house_mats, pfbm
from a_light import FIRE, flame_post
from kit import F, box, cap, cone, cyl, ell, hcyl, pool, prop, rot_x, rot_y, rot_z, rough, sphere, sub, torus, v3  # noqa: F401

SHEET = {"sheet": "city_public"}


def meta(**kw):
    return dict(SHEET, **kw)


def water(k, f=0, seed=1, name="water"):
    """고인 · 흐르는 물(f = 프레임 — 반짝이는 결이 흐른다)."""
    deep, hi = M.hexc("#1a262c"), M.hexc("#90a6aa")

    def fn(p, n):
        q = p + np.array([f * 0.07, f * 0.05, 0], F)
        s = sdf.noise(q * np.array([1.0, 2.0, 1.0], F), 0.06, seed)
        c = deep[None, :] * (0.75 + sdf.noise(p, 0.2, seed + 1)[:, None] * 0.6)
        g = np.clip((s - 0.66) * 7.0, 0, 1)[:, None]
        return (c * (1 - g) + hi[None, :] * g).astype(F), np.zeros(len(p), F), np.full(len(p), 0.5, F)
    return k.mat(name, fn)


def scribble(img, vw, x0, x1, z0, z1, rows, seed, color="#2a2220", y=0.0):
    """읽히지 않는 글줄(가로 낙서)."""
    rng = np.random.default_rng(seed)
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(F)
    m = np.zeros((h, w), F)
    for i in range(rows):
        z = z1 - (i + 0.5) * (z1 - z0) / rows
        px0, py = vw.px(x0, y, z)
        px1, _ = vw.px(x0 + (x1 - x0) * rng.uniform(0.55, 1.0), y, z)
        wob = np.sin(xx * 0.9 + i * 3) * 0.6
        m = np.maximum(m, np.clip(1.0 - np.abs(yy - py - wob) / 0.9, 0, 1) * (xx > px0) * (xx < px1) * (np.sin(xx * 1.7 + i) > -0.6))
    return fx._over(img, m * 0.75, M.hexc(color))


# ── 우물 · 분수 ───────────────────────────────────────────────────────────────

@prop("well", "city", cell=(3, 4), collide=(1.1, 1.0), tags=["plaza", "stone", "water"], name_ko="우물", interact="well",
    variants={"roofed": {"roof": True}, "plain": {}, "broken": {"broken": True}},
    meta=meta(note="돌 쌓은 둥근 우물. roofed = 작은 지붕 · 도르래 · 두레박 · broken = 테가 무너지고 말랐다"))
def well(k, roof=False, broken=False, seed=1):
    R = 0.48
    rim = lambda p: sub(cyl(p, v3(0, 0, 0), R, 0.6, 0.03), cyl(p, v3(0, 0, 0.1), R - 0.12, 1.0))
    if broken:
        k.add(rough(lambda p: np.maximum(rim(p), p[:, 2] - 0.6 + np.clip(p[:, 0] + 0.1, 0, 1) * 0.5 + sdf.noise(p, 0.1, seed) * 0.12), 0.03, 0.12, seed), "masonry_m")
        k.rubble([(0.62, -0.25), (0.75, 0.05), (0.5, -0.45), (0.85, -0.2)], "stone", 0.06, 0.11)
        k.add(lambda p: cyl(p, v3(0, 0, 0.25), R - 0.12, 0.02), "void")
        k.add(lambda p: hcyl(p, v3(-0.55, -0.2, 0.06), v3(-0.1, -0.5, 0.04), 0.035), "wood_d")
        return {"foot": 0.8}
    k.add(rough(rim, 0.015, 0.15, seed), "masonry")
    k.add(lambda p: sub(torus(p, v3(0, 0, 0.6), R - 0.06, 0.07), -p[:, 2] + 0.6), "stone_l")
    k.add(lambda p: cyl(p, v3(0, 0, 0.42), R - 0.12, 0.02), "void")
    water(k, 0, seed)
    k.add(lambda p: cyl(p, v3(0, 0, 0.38), R - 0.13, 0.01), "water")
    if roof:
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: box(p, v3(sx * (R + 0.02), 0, 0.95), (0.05, 0.05, 0.95), 0.008), "wood")
        k.add(lambda p: hcyl(p, v3(-R, 0, 1.25), v3(R, 0, 1.25), 0.05), "wood_d")       # 감는 축
        k.add(lambda p: torus(rot_y(p, np.pi / 2, (R - 0.12, 0, 1.25)), v3(R - 0.12, 0, 1.25), 0.1, 0.02), "wood_d")
        k.add(lambda p: hcyl(p, v3(0.05, 0, 1.25), v3(0.05, 0, 0.8), 0.008), "rope")
        k.add(lambda p: sub(cyl(p, v3(0.05, 0, 0.6), 0.09, 0.2, 0.01), cyl(p, v3(0.05, 0, 0.66), 0.07, 0.3)), "wood_l")
        k.add(lambda p: torus(p, v3(0.05, 0, 0.72), 0.09, 0.012), "iron")
        k.mat("shingle", M.wood("#4e3c2c", 0.07, 0, seed + 3))
        for s in (-1, 1):
            k.add(lambda p, s=s: np.maximum(box(rot_x(p, s * 0.75, (0, 0, 2.0)), v3(0, s * 0.32, 2.0), (0.72, 0.36, 0.03)), -(p[:, 2] - 1.6)), "shingle")
        k.add(lambda p: hcyl(p, v3(-0.75, 0, 2.03), v3(0.75, 0, 2.03), 0.04), "wood_d")
    return {"foot": 0.8}


@prop("fountain", "city", cell=(5, 5), collide=(2.4, 2.0), tags=["plaza", "stone", "water", "animated"], name_ko="분수", fps=6, interact="examine",
    variants={"running": {"frames": 4}, "dry": {"state": "dry"}, "broken": {"state": "broken"}},
    meta=meta(note="광장 가운데 두는 세 칸 남짓 둥근 분수 — 낮은 수반 + 가운데 기둥과 두 단 접시. running = 물줄기 4프레임 · broken = 위 접시가 떨어져 수반 안에 굴렀다"))
def fountain(k, state="running", seed=1, f=0):
    k.mat("basin", M.masonry("#8a867a", 0.22, 0.6, "#4a5236" if state != "running" else None, seed))
    R = 1.25
    k.add(rough(lambda p: sub(np.maximum(np.hypot(p[:, 0], p[:, 1] / 0.86) - R, np.abs(p[:, 2] - 0.22) - 0.22), np.maximum(np.hypot(p[:, 0], p[:, 1] / 0.86) - R + 0.16, -p[:, 2] + 0.12)), 0.012, 0.15, seed), "basin")
    k.add(lambda p: sub(np.maximum(np.abs(np.hypot(p[:, 0], p[:, 1] / 0.86) - R + 0.08) - 0.11, np.abs(p[:, 2] - 0.46) - 0.04), -p[:, 2] + 0.0), "stone_l")
    if state == "running":
        water(k, f, seed)
        k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 1] / 0.86) - R + 0.15, np.abs(p[:, 2] - 0.34) - 0.015), "water")
    else:
        k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 1] / 0.86) - R + 0.15, np.abs(p[:, 2] - 0.14) - 0.015), "dirt")
        k.add(lambda p: pool(p, v3(0.35, -0.3, 0.16), 0.4, 0.25, 0.01), "moss")
    k.add(lambda p: cyl(p, v3(0, 0.05, 0.1), 0.17, 1.15, 0.02), "stone_l")
    tiers = ((1.25, 0.55), (1.85, 0.32)) if state != "broken" else ((1.25, 0.55),)
    for z, r in tiers:
        k.add(lambda p, z=z, r=r: sub(np.maximum(np.hypot(p[:, 0], p[:, 1] - 0.05) - r + (z - p[:, 2]) * 0.8, np.abs(p[:, 2] - z) - 0.09), np.maximum(np.hypot(p[:, 0], p[:, 1] - 0.05) - r + 0.06, -p[:, 2] + z + 0.03)), "stone_l")
    if state != "broken":
        k.add(lambda p: cyl(p, v3(0, 0.05, 1.85), 0.08, 0.35, 0.02), "stone_l")
        k.add(lambda p: sphere(p, v3(0, 0.05, 2.24), 0.09), "stone_l")
    else:
        k.add(rough(lambda p: sub(ell(rot_y(p, 1.1, (0.7, -0.35, 0.3)), v3(0.7, -0.35, 0.3), (0.32, 0.32, 0.09)), ell(rot_y(p, 1.1, (0.7, -0.35, 0.36)), v3(0.7, -0.35, 0.36), (0.26, 0.26, 0.07))), 0.02, 0.1, seed), "stone_l")
        k.add(rough(lambda p: np.maximum(cyl(p, v3(0, 0.05, 1.25), 0.1, 0.4, 0.01), p[:, 2] - 1.5 - sdf.noise(p, 0.05, seed) * 0.1), 0.02, 0.1, seed), "stone_l")
    out = {"foot": 0.6}
    if state == "running":
        def jets(img, vw):
            hh, ww = img.shape[:2]
            yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
            m = np.zeros((hh, ww), F)
            for z0, r, z1, rr in ((2.3, 0.0, 1.88, 0.3), (1.88, 0.3, 1.3, 0.55), (1.3, 0.55, 0.36, 1.0)):
                for a in np.linspace(0, 2 * np.pi, 9)[:-1]:
                    if np.sin(a) > 0.3:
                        continue
                    pts = []
                    for t in np.linspace(0, 1, 14):
                        rad = r + (rr - r) * t
                        z = z0 + (z1 - z0) * t * t
                        pts.append(vw.px(np.cos(a) * rad, 0.05 + np.sin(a) * rad * 0.86, z))
                    for (xa, ya), (xb, yb) in zip(pts[:-1], pts[1:]):
                        d = np.hypot(xx - (xa + xb) / 2, yy - (ya + yb) / 2)
                        m = np.maximum(m, np.clip(1.4 - d / 1.2, 0, 1) * 0.55)
            m = m * (0.6 + 0.4 * (np.sin(yy * 0.6 + f * 1.6) > 0))
            return fx._over(img, m, M.hexc("#b8cace"))
        out["post"] = [jets]
    return out


# ── 가로등 · 게시판 · 표지판 · 안내판 ─────────────────────────────────────────

@prop("street_lamp", "city", cell=(2, 5), collide=(0.3, 0.3), tags=["street", "iron", "fire"], name_ko="가로등",
    variants={"lit": {"frames": 4}, "unlit": {"state": "unlit"}, "bent": {"state": "bent"}},
    light={"color": FIRE, "radius": 5.0, "at": (0.32, 0, 2.55), "flicker": 0.25, "variants": ["lit"]},
    meta=meta(note="쇠 기둥 끝에 팔을 내어 등을 매단 가로등(높이 약 3칸). bent = 기둥이 휘고 등이 깨졌다"))
def street_lamp(k, state="lit", seed=1, f=0):
    T = (lambda p: rot_y(p, -0.32, (0, 0, 0.5))) if state == "bent" else (lambda p: p)
    k.add(rough(lambda p: cyl(p, v3(0, 0, 0), 0.16, 0.18, 0.03), 0.01, 0.15, seed), "stone_d")
    k.add(lambda p: (lambda q: np.minimum(cyl(q, v3(0, 0, 0.15), 0.07, 0.25, 0.01), cap(q, v3(0, 0, 0.35), v3(0, 0, 2.9), 0.04, 0.03)))(T(p)), "iron")
    k.add(lambda p: (lambda q: np.minimum.reduce([cap(q, v3(0, 0, 2.75), v3(0.36, 0, 2.86), 0.022), torus(rot_x(q, np.pi / 2, (0.18, 0, 2.7)), v3(0.18, 0, 2.7), 0.12, 0.012), sphere(q, v3(0, 0, 2.94), 0.05)]))(T(p)), "iron")
    if state == "bent":
        k.add(lambda p: (lambda q: cap(q, v3(0.36, 0, 2.86), v3(0.36, 0, 2.62), 0.01))(T(p)), "iron")
        k.add(lambda p: sub(box(rot_z(p, 0.6, (0.75, -0.3, 0.06)), v3(0.75, -0.3, 0.1), (0.11, 0.11, 0.1), 0.01), box(rot_z(p, 0.6, (0.75, -0.3, 0.06)), v3(0.75, -0.3, 0.1), (0.08, 0.08, 0.2))), "iron")
        k.rubble([(0.6, -0.1), (0.95, -0.4)], "glass", 0.015, 0.03)
        return {"foot": 0.6, "dx": 0.15}
    lz = 2.52
    k.add(lambda p: np.minimum(cone(p, v3(0.36, 0, lz + 0.18), 0.15, 0.12), box(p, v3(0.36, 0, lz - 0.17), (0.08, 0.08, 0.02), 0.005)), "iron")
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: cap(p, v3(0.36 + sx * 0.1, sy * 0.1, lz - 0.17), v3(0.36 + sx * 0.12, sy * 0.12, lz + 0.18), 0.012), "iron")
    k.add(lambda p: box(p, v3(0.36, 0, lz), (0.09, 0.09, 0.16)), "glass" if state == "unlit" else "glow_fire")
    out = {"foot": 0.6, "dx": 0.15}
    if state == "lit":
        out["post"] = [flame_post(0.36, -0.1, lz - 0.1, 12, seed, f, glow=3.5, strength=0.45)]
    return out


@prop("notice_board", "city", cell=(3, 4), collide=(1.2, 0.3), tags=["street", "wood", "paper"], name_ko="게시판", interact="examine",
    variants={"notices": {}, "empty": {"state": "empty"}, "torn": {"state": "torn"}},
    meta=meta(note="두 기둥 위 작은 지붕을 얹은 나무 게시판. notices = 쪽지 · 방(글은 읽히지 않는 줄) · torn = 찢겨 나부끼는 종이"))
def notice_board(k, state="notices", seed=1):
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: box(p, v3(sx * 0.58, 0, 1.0), (0.05, 0.05, 1.0), 0.008), "wood_d")
    k.add(lambda p: box(p, v3(0, 0.0, 1.2), (0.55, 0.035, 0.42), 0.01), "plank_x")
    k.add(lambda p: np.minimum(box(p, v3(0, -0.04, 1.63), (0.6, 0.04, 0.03)), box(p, v3(0, -0.04, 0.77), (0.6, 0.04, 0.03))), "wood_d")
    for s in (-1, 1):
        k.add(lambda p, s=s: np.maximum(box(rot_x(p, s * 0.9, (0, 0, 2.05)), v3(0, s * 0.18, 2.05), (0.72, 0.2, 0.025)), -(p[:, 2] - 1.82)), "plank_xd")
    rng = np.random.default_rng(seed)
    notes = []
    if state != "empty":
        for i in range(7 if state == "notices" else 4):
            x, z = rng.uniform(-0.42, 0.42), rng.uniform(0.95, 1.45)
            w, h, a = rng.uniform(0.08, 0.14), rng.uniform(0.09, 0.15), rng.uniform(-0.2, 0.2)
            T = (lambda p, x=x, z=z, a=a: rot_y(p, a, (x, 0, z)))
            k.add(lambda p, T=T, x=x, z=z, w=w, h=h: box(T(p), v3(x, -0.04 - i * 0.001, z), (w, 0.006, h)), "paper")
            k.add(lambda p, x=x, z=z, h=h: sphere(p, v3(x, -0.05, z + h - 0.02), 0.012), "iron")
            notes.append((x - w * 0.7, x + w * 0.7, z - h * 0.6, z + h * 0.7))
    if state == "torn":
        for x, z in ((-0.3, 1.5), (0.25, 1.05)):
            k.add(lambda p, x=x, z=z: box(rot_y(p, 0.8, (x, 0, z)), v3(x + 0.05, -0.05, z - 0.08), (0.06, 0.005, 0.1)), "paper")
        k.rubble([(0.4, -0.35), (-0.5, -0.5)], "paper", 0.03, 0.05)

    def lines(img, vw):
        for i, (x0, x1, z0, z1) in enumerate(notes):
            img = scribble(img, vw, x0, x1, z0, z1, 3, seed + i, y=-0.05)
        return img
    return {"foot": 0.6, "post": [lines]}


@prop("signpost", "city", cell=(3, 4), collide=(0.25, 0.25), tags=["street", "wood"], name_ko="갈림길 표지판",
    variants={"one": {"arms": 1}, "two": {"arms": 2}, "three": {"arms": 3}, "leaning": {"arms": 2, "lean": True}},
    meta=meta(note="길목에 세운 나무 표지판 — 화살 모양 팔(글은 새긴 줄). leaning = 기둥이 기울고 팔 하나가 처졌다"))
def signpost(k, arms=2, lean=False, seed=1):
    T = (lambda p: rot_y(p, 0.22, (0, 0, 0))) if lean else (lambda p: p)
    k.add(rough(lambda p: (lambda q: box(q, v3(0, 0, 1.0), (0.05, 0.05, 1.0), 0.01))(T(p)), 0.008, 0.2, seed), "wood_d")
    k.add(lambda p: (lambda q: cone(q, v3(0, 0, 2.0), 0.08, 0.1))(T(p)), "wood_d")
    k.rubble([(0.12, -0.08), (-0.1, 0.05)], "stone", 0.05, 0.07)
    specs = [(1.75, 1, 0.0), (1.48, -1, 0.5), (1.22, 1, -0.7)][:arms]
    k.mat("sign", M.wood("#6a5438", 0.06, 0, seed + 5))
    for i, (z, s, yaw) in enumerate(specs):
        droop = 0.45 if lean and i == 1 else 0.0
        def arm(p, z=z, s=s, yaw=yaw, droop=droop):
            q = rot_y(rot_z(T(p), yaw), s * droop, (0, 0, z))
            body = box(q, v3(s * 0.33, -0.06, z), (0.28, 0.02, 0.07), 0.006)
            tip = np.maximum(np.abs(q[:, 1] + 0.06) - 0.02, (np.abs(q[:, 2] - z) - (0.13 - (s * q[:, 0] - 0.6) * 0.0)) )
            tip = np.maximum(tip, np.maximum(-(s * q[:, 0] - 0.6), (s * q[:, 0] - 0.6) * 0.7 + np.abs(q[:, 2] - z) - 0.08))
            return np.minimum(body, tip)
        k.add(arm, "sign")
    return {"foot": 0.6}


@prop("info_board", "city", cell=(3, 4), collide=(1.0, 0.3), tags=["street", "plaza", "stone"], name_ko="안내판", interact="examine",
    variants={"stone": {"kind": "stone"}, "wood": {"kind": "wood"}, "wall": {"kind": "wall"}},
    meta=meta(note="광장 · 성문 앞의 안내판: stone = 돌 받침에 세운 청동판 · wood = 나무 틀에 끼운 지도판 · wall = 벽에 붙이는 판(wall_decal처럼 벽 밑동에 원점, 판 높이 1.4칸)"))
def info_board(k, kind="stone", seed=1):
    if kind == "stone":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.35), (0.42, 0.14, 0.35), 0.02), 0.01, 0.15, seed), "masonry")
        k.add(lambda p: box(rot_x(p, 0.35, (0, 0, 0.7)), v3(0, 0, 0.98), (0.4, 0.035, 0.3), 0.012), "bronze")
        k.add(lambda p: box(rot_x(p, 0.35, (0, 0, 0.7)), v3(0, -0.04, 0.98), (0.33, 0.006, 0.24)), "bronze")
        rect, y, tilt = (-0.3, 0.3, 0.8, 1.17), -0.05, True
    elif kind == "wood":
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: box(p, v3(sx * 0.45, 0, 0.75), (0.045, 0.045, 0.75), 0.008), "wood_d")
        k.add(lambda p: box(p, v3(0, 0, 1.05), (0.42, 0.025, 0.36), 0.008), "wood")
        k.add(lambda p: box(p, v3(0, -0.03, 1.05), (0.36, 0.005, 0.3)), "paper")
        rect, y, tilt = (-0.32, 0.32, 0.8, 1.3), -0.04, False
    else:
        k.add(lambda p: box(p, v3(0, -0.03, 1.4), (0.36, 0.03, 0.26), 0.01), "bronze")
        k.add(lambda p: np.minimum.reduce([sphere(p, v3(sx * 0.3, -0.06, 1.4 + sz * 0.2), 0.018) for sx in (-1, 1) for sz in (-1, 1)]), "iron")
        rect, y, tilt = (-0.26, 0.26, 1.22, 1.58), -0.065, False

    def marks(img, vw):
        x0, x1, z0, z1 = rect
        if kind == "wood":   # 지도 같은 선 + 줄
            img = scribble(img, vw, x0, x1, z0, z0 + 0.15, 2, seed, y=y)
            hh, ww = img.shape[:2]
            yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
            ax, ay = vw.px(x0 + 0.05, y, z1 - 0.05)
            bx, by = vw.px(x1 - 0.05, y, z0 + 0.25)
            m = np.clip(1.0 - np.abs((yy - ay) - (xx - ax) * (by - ay) / max(bx - ax, 1) - np.sin(xx * 0.25) * 3) / 1.0, 0, 1) * (xx > ax) * (xx < bx)
            return fx._over(img, m * 0.7, M.hexc("#6a3a2a"))
        return scribble(img, vw, x0, x1, z0 if not tilt else z0, z1, 5, seed, "#2c2418", y=y)
    return {"foot": 0.6 if kind != "wall" else 1.0, "post": [marks]}


# ── 광장 장식 ─────────────────────────────────────────────────────────────────

@prop("bollard", "city", cell=(1.5, 2), collide=(0.3, 0.3), tags=["street", "plaza", "stone"], name_ko="돌말뚝",
    variants={"stone": {}, "chained": {"chain": True}, "iron": {"kind": "iron"}, "broken": {"broken": True}},
    meta=meta(note="길 · 광장 가에 세운 낮은 돌말뚝. chained = 옆 말뚝(한 칸 오른쪽)으로 늘어진 쇠사슬 · iron = 쇠 말뚝"))
def bollard(k, chain=False, kind="stone", broken=False, seed=1):
    if kind == "iron":
        k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 0), 0.08, 0.6, 0.02), sphere(p, v3(0, 0, 0.64), 0.09)), "iron")
        k.add(lambda p: torus(p, v3(0, 0, 0.45), 0.08, 0.018), "iron")
        return {"foot": 0.5}
    body = lambda p: np.minimum(cyl(p, v3(0, 0, 0), 0.13, 0.5, 0.03), sphere(p, v3(0, 0, 0.5), 0.13))
    if broken:
        k.add(rough(lambda p: np.maximum(body(p), p[:, 2] - 0.3 - p[:, 0] * 0.5 - sdf.noise(p, 0.05, seed) * 0.1), 0.02, 0.1, seed), "stone")
        k.add(rough(lambda p: ell(p, v3(0.3, -0.2, 0.1), (0.16, 0.1, 0.1)), 0.02, 0.1, seed), "stone")
    else:
        k.add(rough(body, 0.012, 0.12, seed), "stone")
    if chain:
        k.add(lambda p: torus(rot_x(p, np.pi / 2, (0, 0, 0.45)), v3(0, 0, 0.45), 0.05, 0.012), "iron")
        for i in range(9):
            t = (i + 0.5) / 9
            x, z = 0.08 + t * 0.84, 0.45 - np.sin(t * np.pi) * 0.22
            k.add(lambda p, x=x, z=z, i=i: torus(rot_x(p, np.pi / 2 * (i % 2), (x, 0, z)) if i % 2 else rot_y(p, 0.0), v3(x, 0, z), 0.035, 0.009), "iron")
    return {"foot": 0.5, "dx": 0.25 if chain else 0.0}


@prop("horse_trough", "city", cell=(3, 2.5), collide=(1.4, 0.5), tags=["street", "plaza", "water", "stable"], name_ko="물구유",
    variants={"stone": {"kind": "stone"}, "wood": {"kind": "wood"}, "wood_dry": {"kind": "wood", "dry": True}},
    meta=meta(note="말 · 짐승이 물을 마시는 긴 구유(1.5칸). stone = 통돌을 판 구유 · wood = 쇠테 두른 나무 구유 · wood_dry = 말라 이끼 낀"))
def horse_trough(k, kind="stone", dry=False, seed=1):
    L, D, H = 0.7, 0.24, 0.42
    outer = lambda p: box(p, v3(0, 0, H / 2), (L, D, H / 2), 0.03)
    inner = lambda p: box(p, v3(0, 0, H / 2 + 0.08), (L - 0.07, D - 0.07, H / 2))
    if kind == "stone":
        k.add(rough(lambda p: sub(outer(p), inner(p)), 0.012, 0.15, seed), "stone_m")
    else:
        k.add(lambda p: sub(outer(p), inner(p)), "plank_x")
        for x in (-0.5, 0.5):
            k.add(lambda p, x=x: sub(box(p, v3(x, 0, H / 2), (0.03, D + 0.012, H / 2 + 0.01)), inner(p)), "iron")
        for x in (-0.55, 0.55):
            k.add(lambda p, x=x: box(p, v3(x, 0, 0.05), (0.06, D + 0.06, 0.05), 0.01), "wood_d")
    if dry:
        k.add(lambda p: box(p, v3(0, 0, 0.12), (L - 0.08, D - 0.08, 0.01)), "dirt")
        k.add(lambda p: pool(p, v3(-0.2, 0.0, 0.13), 0.3, 0.12, 0.01), "moss")
    else:
        water(k, 0, seed)
        k.add(lambda p: box(p, v3(0, 0, H - 0.07), (L - 0.07, D - 0.07, 0.01)), "water")
    return {"foot": 0.6}


@prop("plaza_monument", "city", cell=(3, 5), collide=(0.8, 0.8), tags=["plaza", "stone", "ornament"], name_ko="광장 기념 돌",
    variants={"obelisk": {"kind": "obelisk"}, "sundial": {"kind": "sundial"}, "obelisk_worn": {"kind": "obelisk", "worn": True}},
    meta=meta(note="obelisk = 세 단 받침 위 뾰족한 돌기둥(약 3칸) · sundial = 낮은 돌 받침 위 청동 해시계판(바늘 · 시각 금)"))
def plaza_monument(k, kind="obelisk", worn=False, seed=1):
    mat = "stone_m" if worn else "stone_l"
    for i, (w, h) in enumerate(((0.42, 0.14), (0.34, 0.14), (0.27, 0.12))):
        z = sum(hh * 2 for _, hh in ((0.42, 0.14), (0.34, 0.14), (0.27, 0.12))[:i])
        k.add(rough(lambda p, w=w, h=h, z=z: box(p, v3(0, 0, z + h), (w, w * 0.9, h), 0.015), 0.01, 0.15, seed + i), "masonry_m" if worn else "masonry")
    zb = 0.8
    if kind == "obelisk":
        top = 3.0
        sh = lambda p: np.maximum.reduce([np.abs(p[:, 0]) - (0.16 - (p[:, 2] - zb) * 0.03), np.abs(p[:, 1]) - (0.15 - (p[:, 2] - zb) * 0.03), zb - p[:, 2], p[:, 2] - top])
        k.add(rough(sh, 0.008 if not worn else 0.02, 0.15, seed), mat)
        k.add(lambda p: np.maximum.reduce([np.abs(p[:, 0]) + np.abs(p[:, 1]) + (p[:, 2] - top) * 0.6 - 0.1, top - p[:, 2] - 0.01]), mat)
        return {"foot": 0.6}
    k.add(lambda p: cyl(p, v3(0, 0, zb), 0.3, 0.04, 0.01), "bronze")
    k.add(lambda p: np.maximum.reduce([np.abs(p[:, 0]) - 0.012, p[:, 1] * 0.0 + np.abs(p[:, 1]) - 0.2 + 0.0, -(p[:, 2] - zb - 0.04), (p[:, 2] - zb - 0.04) - (0.2 - p[:, 1]) * 0.8]), "bronze")

    def ticks(img, vw):
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        m = np.zeros((hh, ww), F)
        for a in np.linspace(np.pi * 0.95, np.pi * 2.05, 11):
            x0, y0 = vw.px(np.cos(a) * 0.2, np.sin(a) * 0.2, zb + 0.045)
            x1, y1 = vw.px(np.cos(a) * 0.27, np.sin(a) * 0.27, zb + 0.045)
            d = np.abs((xx - x0) * (y1 - y0) - (yy - y0) * (x1 - x0)) / max(np.hypot(x1 - x0, y1 - y0), 1e-3)
            m = np.maximum(m, np.clip(1.0 - d, 0, 1) * (np.minimum(xx, 0) + 1) * ((xx - min(x0, x1) + 1) > 0) * ((max(x0, x1) + 1 - xx) > 0) * ((yy - min(y0, y1) + 1) > 0) * ((max(y0, y1) + 1 - yy) > 0))
        return fx._over(img, m * 0.8, M.hexc("#2a2218"))
    return {"foot": 0.6, "post": [ticks]}


# ── 성문 · 성벽 · 망루 ────────────────────────────────────────────────────────

def _crenel(k, x0, x1, z, y0=-0.3, y1=0.5, mat="cw", seed=1, broken=False):
    """총안 흉벽: z 위로 이빨(폭 1칸 주기 — 0.5칸마다 하나)."""
    k.add(lambda p: np.maximum.reduce([box(p, v3((x0 + x1) / 2, (y0 + y1) / 2, z + 0.06), ((x1 - x0) / 2, (y1 - y0) / 2, 0.06)), x0 - p[:, 0], p[:, 0] - x1]), "cw_trim")
    merlon = lambda p: np.maximum.reduce([np.abs(((p[:, 0] + 0.5) % 0.5) - 0.25) - 0.13, np.abs(p[:, 1] - y0 - 0.1) - 0.1, np.abs(p[:, 2] - z - 0.38) - 0.27, x0 - p[:, 0], p[:, 0] - x1])
    if broken:
        k.add(rough(lambda p: np.maximum(merlon(p), p[:, 2] - z - 0.65 + np.clip(p[:, 0], 0, 1) * 0.9 - sdf.noise(p, 0.1, seed) * 0.3), 0.02, 0.1, seed), mat)
    else:
        k.add(lambda p: merlon(p) - 0.006, mat)


def _wall_mats(k, seed=1, worn=False):
    k.mat("cw", M.masonry("#6e6a60", 0.28, 0.55, "#4a5236" if worn else None, seed))
    k.mat("cw_trim", M.masonry("#7e7a6e", 0.5, 1.0, None, seed + 3))


@prop("city_wall", "city", cell=(2, 7), collide=(-0.5, -0.3, 1.0, 0.8), tags=["wall", "fort", "stone", "straight", "module"], name_ko="성벽",
    variants={"straight": {}, "torch": {"torch": True, "frames": 4}, "damaged": {"damaged": True}, "drain": {"drain": True}},
    light={"color": FIRE, "radius": 4.0, "at": (0, -0.4, 2.1), "flicker": 0.35, "variants": ["torch"]},
    meta=meta(tile_w=1, note="높이 4칸 성벽 한 칸(두께 0.8칸) — 한 칸 간격으로 잇는다. 위에 총안 흉벽 · torch = 횃불 걸이(4프레임) · damaged = 흉벽이 무너지고 금 · drain = 아래 배수 구멍"))
def city_wall(k, torch=False, damaged=False, drain=False, seed=1, f=0):
    _wall_mats(k, seed, damaged)
    H = 4.0
    body = lambda p: np.maximum(box(p, v3(0, 0.1, H / 2), (0.8, 0.4, H / 2)), (p[:, 1] + 0.3) * 0.0 - 9)
    batter = lambda p: np.maximum(body(p), -(p[:, 1] + 0.3 + np.clip(0.8 - p[:, 2], 0, 1) * 0.15))
    base = lambda p: np.maximum(box(p, v3(0, 0.05, 0.4), (0.8, 0.45, 0.4)), (-(p[:, 1] + 0.42) + (p[:, 2]) * 0.18))
    if drain:
        hole = lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.3) - 0.17, np.abs(p[:, 1]) - 1)
        k.add(lambda p: sub(np.minimum(batter(p), base(p)), hole(p)), "cw")
        k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.3) - 0.17, np.abs(p[:, 1] - 0.2) - 0.01), "void")
        k.add(lambda p: np.maximum(np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.3) - 0.17, np.abs(p[:, 1] + 0.3) - 0.012), np.abs(((p[:, 0] + 0.5) % 0.08) - 0.04) - 0.012), "rust")
        k.add(lambda p: pool(p, v3(0, -0.75, 0.01), 0.3, 0.2, 0.01), "moss")
    else:
        k.add(lambda p: np.minimum(batter(p), base(p)), "cw")
    if damaged:
        k.add(lambda p: np.maximum(box(p, v3(0.1, -0.31, 2.6), (0.02, 0.01, 0.9)), np.abs(p[:, 0] - 0.1 - np.sin(p[:, 2] * 7) * 0.08) - 0.012), "void")
        k.rubble([(0.2, -0.6), (-0.25, -0.7), (0.4, -0.75), (-0.05, -0.85)], "stone", 0.07, 0.13)
    _crenel(k, -0.8, 0.8, H, -0.3, 0.5, "cw", seed, damaged)
    out = {"foot": 1.2, "post": [crop()], "shadow": 0.4}
    if torch:
        k.add(lambda p: np.minimum(cap(p, v3(0, -0.3, 1.95), v3(0, -0.45, 2.05), 0.025), torus(rot_x(p, -0.5, (0, -0.45, 2.1)), v3(0, -0.45, 2.1), 0.06, 0.02)), "iron")
        k.add(lambda p: cap(p, v3(0, -0.45, 2.0), v3(0, -0.5, 2.3), 0.03, 0.045), "wood_d")
        out["post"].append(flame_post(0, -0.52, 2.36, 26, seed, f))
    return out


@prop("city_wall_tower", "city", cell=(4, 9), collide=(1.8, 1.6), tags=["wall", "fort", "stone", "corner", "module"], name_ko="성벽 탑",
    variants={"intact": {}, "lit": {"lit": True}, "damaged": {"damaged": True}},
    meta=meta(note="성벽 줄의 모서리 · 마디에 서는 네모 탑(1.8칸 폭 · 높이 5.5칸) — 성벽 조각 사이에 두면 양쪽으로 이어진다. lit = 화살 구멍에 불빛"))
def city_wall_tower(k, lit=False, damaged=False, seed=1):
    _wall_mats(k, seed + 2, damaged)
    H = 5.5
    k.add(lambda p: np.maximum(box(p, v3(0, 0.1, H / 2), (0.9, 0.8, H / 2)), -(p[:, 1] + 0.7 + np.clip(1.0 - p[:, 2], 0, 1) * 0.2)), "cw")
    k.add(lambda p: box(p, v3(0, 0.1, H - 0.05), (1.0, 0.9, 0.12), 0.01), "cw_trim")
    if not damaged:
        for x in (-0.75, -0.25, 0.25, 0.75):
            k.add(lambda p, x=x: box(p, v3(x, -0.72, H + 0.33), (0.15, 0.1, 0.27), 0.006), "cw")
    else:
        _crenel(k, -1.0, 1.0, H - 0.07, -0.8, -0.6, "cw", seed, True)
        k.rubble([(0.6, -1.2), (0.95, -1.05), (0.3, -1.3)], "stone", 0.08, 0.14)
    for z in (2.2, 3.9):
        k.add(lambda p, z=z: box(p, v3(0, -0.7, z), (0.04, 0.03, 0.26)), "glow_fire" if lit else "void")
    out = {"foot": 1.6, "shadow": 0.4}
    if lit:
        out["glow"] = [(0, -0.75, 2.2, 22.0, FIRE, 0.4), (0, -0.75, 3.9, 22.0, FIRE, 0.4)]
    return out


@prop("city_gate", "city", cell=(6, 8), collide=[(-2.3, -0.4, 1.3, 1.0), (1.0, -0.4, 1.3, 1.0)], tags=["wall", "fort", "stone", "gate", "passage"], name_ko="성문", interact="gate",
    variants={"open": {}, "shut": {"state": "shut"}, "portcullis": {"state": "portcullis"}, "open_banner": {"banner": True}},
    meta=meta(states={"open": "open", "closed": "shut"}, note="네 칸 반 폭 성문 문루 — 두 칸 폭 아치 통로(가운데는 지나간다 · 양쪽 탑만 막는다). shut = 나무 문짝 닫힘 · portcullis = 쇠살문 내림 · 양옆에 성벽 조각을 잇는다"))
def city_gate(k, state="open", banner=False, seed=1):
    _wall_mats(k, seed + 4)
    W, H, Ha = 2.3, 4.6, 1.85              # 반폭 · 높이 · 아치 기둥 높이
    R = 0.85
    passage = lambda p: np.minimum(box(p, v3(0, 0, Ha / 2), (R, 2.0, Ha / 2 + 0.01)), np.maximum(np.hypot(p[:, 0], p[:, 2] - Ha) - R, np.abs(p[:, 1]) - 2.0))
    body = lambda p: np.maximum(box(p, v3(0, 0.1, H / 2), (W, 0.5, H / 2)), -(p[:, 1] + 0.4 + np.clip(0.8 - p[:, 2], 0, 1) * 0.15))
    k.add(lambda p: sub(body(p), passage(p)), "cw")
    for sx in (-1, 1):   # 양옆 탑 기둥(조금 내민다)
        k.add(lambda p, sx=sx: sub(np.maximum(box(p, v3(sx * (W - 0.45), -0.05, (H + 0.6) / 2), (0.45, 0.55, (H + 0.6) / 2)), -(p[:, 1] + 0.6)), passage(p)), "cw")
        for x in (-0.25, 0.2):
            k.add(lambda p, sx=sx, x=x: box(p, v3(sx * (W - 0.45) + x, -0.62, H + 0.85), (0.13, 0.06, 0.25), 0.006), "cw")
        k.add(lambda p, sx=sx: box(p, v3(sx * (W - 0.45), -0.62, 2.6), (0.035, 0.03, 0.24)), "void")
    k.add(lambda p: np.maximum.reduce([np.abs(np.hypot(p[:, 0], p[:, 2] - Ha) - R - 0.1) - 0.1, Ha - p[:, 2], np.abs(p[:, 1] + 0.42) - 0.04]), "cw_trim")
    _crenel(k, -W + 0.9, W - 0.9, H, -0.4, 0.6, "cw", seed)
    k.add(lambda p: np.maximum(passage(p), np.abs(p[:, 1] - 0.55) - 0.01), "void")
    if state == "shut":
        k.mat("gate_w", M.wood("#4a3826", 0.15, 2, seed + 6))
        k.add(lambda p: np.maximum(passage(p), np.abs(p[:, 1] - 0.0) - 0.05), "gate_w")
        k.add(lambda p: np.maximum(passage(p) + 0.0, np.minimum.reduce([np.abs(p[:, 2] - z) - 0.045 for z in (0.4, 1.0, 1.6)] + [np.abs(p[:, 0]) - 0.02]) ) + np.maximum(np.abs(p[:, 1] + 0.06) - 0.012, 0), "iron")
    elif state == "portcullis":
        bars = lambda p: np.maximum(passage(p) + 0.01, np.minimum(np.abs(((p[:, 0] + 2) % 0.2) - 0.1) - 0.018, np.abs(((p[:, 2]) % 0.32) - 0.16) - 0.018))
        k.add(lambda p: np.maximum(bars(p), np.abs(p[:, 1] + 0.2) - 0.02), "rust")
        k.add(lambda p: np.maximum.reduce([np.abs(((p[:, 0] + 2) % 0.2) - 0.1) - 0.03, np.abs(p[:, 1] + 0.2) - 0.03, np.abs(p[:, 2] - 0.02) - 0.03, np.abs(p[:, 0]) - R]), "rust")
    else:
        k.add(lambda p: np.maximum.reduce([passage(p) + 0.0, np.abs(p[:, 1] + 0.2) - 0.02, Ha + R * 0.55 - p[:, 2], np.abs(((p[:, 0] + 2) % 0.2) - 0.1) - 0.018]), "rust")   # 올린 쇠살문 끝
    k.add(rough(lambda p: box(p, v3(0, -0.2, 0.01), (R, 1.0, 0.012)), 0.006, 0.2, seed), "stone_d")
    if banner:
        k.mat("ban", M.plain("#6a2e2a", 0.3, 0.12, seed))
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: np.maximum(box(p, v3(sx * (W - 0.45), -0.63, 3.0), (0.22, 0.01, 0.6)), -(p[:, 2] - 2.4 - np.abs(p[:, 0] - sx * (W - 0.45)) * 0.8)), "ban")
            k.add(lambda p, sx=sx: np.maximum(box(p, v3(sx * (W - 0.45), -0.64, 3.0), (0.06, 0.01, 0.6)), -(p[:, 2] - 2.55)), "cloth_k")
    return {"foot": 1.3, "shadow": 0.45}


@prop("watchtower", "city", cell=(4, 8), collide=(1.6, 1.4), tags=["fort", "wood", "tower"], name_ko="나무 망루",
    variants={"intact": {}, "lit": {"lit": True, "frames": 4}, "ruined": {"ruined": True}},
    light={"color": FIRE, "radius": 5.0, "at": (0.0, 0.0, 3.6), "flicker": 0.35, "variants": ["lit"]},
    meta=meta(note="네 기둥 위 지붕 덮은 나무 망루(약 2 × 2칸 · 높이 5칸) — 사다리가 앞에 걸린다. lit = 화로 불(4프레임) · ruined = 기둥 하나가 꺾여 기울었다"))
def watchtower(k, lit=False, ruined=False, seed=1, f=0):
    T = (lambda p: rot_y(p, 0.18, (0.7, 0, 0))) if ruined else (lambda p: p)
    add = lambda fn, m: k.add(lambda p, fn=fn: fn(T(p)), m)
    S, Z = 0.7, 3.2
    for sx in (-1, 1):
        for sy in (-1, 1):
            if ruined and sx < 0 and sy < 0:
                k.add(lambda p: hcyl(p, v3(-0.75, -0.7, 0.05), v3(-1.3, -0.95, 0.05), 0.07), "wood_d")
                continue
            add(lambda p, sx=sx, sy=sy: cap(p, v3(sx * S * 1.15, sy * S * 1.15, 0), v3(sx * S, sy * S, Z + 1.0), 0.075), "wood_d")
    for z in (1.0, 2.1):
        for s in (-1, 1):
            add(lambda p, z=z, s=s: hcyl(p, v3(-S * 1.1, s * S * 1.08, z - 0.3), v3(S * 1.1, s * S * 1.08, z + 0.3), 0.035), "wood")
    add(lambda p: box(p, v3(0, 0, Z), (S + 0.15, S + 0.15, 0.06), 0.01), "plank_x")
    for s in (-1, 1):
        add(lambda p, s=s: box(p, v3(0, s * (S + 0.1), Z + 0.35), (S + 0.12, 0.04, 0.3), 0.008), "plank_x")
        add(lambda p, s=s: box(p, v3(s * (S + 0.1), 0, Z + 0.35), (0.04, S + 0.1, 0.3), 0.008), "plank_y")
    k.mat("tw_roof", M.thatch("#6a5a3a", 0.18, seed))
    add(lambda p: cone(p, v3(0, 0, Z + 1.0), 1.15, 0.9), "tw_roof")
    for i in range(9):          # 사다리
        add(lambda p, i=i: hcyl(p, v3(-0.2, -S - 0.3 + i * 0.03, 0.25 + i * 0.32), v3(0.2, -S - 0.3 + i * 0.03, 0.25 + i * 0.32), 0.022), "wood")
    for sx in (-1, 1):
        add(lambda p, sx=sx: cap(p, v3(sx * 0.22, -S - 0.32, 0.0), v3(sx * 0.22, -S - 0.04, Z + 0.1), 0.03), "wood_d")
    out = {"foot": 1.5, "shadow": 0.4}
    if lit:
        add(lambda p: sub(cyl(p, v3(0.3, 0.2, Z + 0.06), 0.18, 0.18, 0.02), cyl(p, v3(0.3, 0.2, Z + 0.16), 0.14, 0.3)), "iron")
        add(lambda p: cyl(p, v3(0.3, 0.2, Z + 0.14), 0.14, 0.06), "ember")
        out["post"] = [flame_post(0.3, 0.2, Z + 0.24, 22, seed, f)]
    return out


# ── 울타리 ───────────────────────────────────────────────────────────────────

@prop("iron_fence", "city", cell=(2, 3), collide=(1.0, 0.16), tags=["fence", "iron", "module"], name_ko="쇠 울타리",
    variants={"straight": {}, "post": {"kind": "post"}, "gate_shut": {"kind": "gate"}, "gate_open": {"kind": "gate", "open": True}, "bent": {"kind": "bent"}},
    meta=meta(tile_w=1, states={"closed": "gate_shut", "open": "gate_open"}, note="낮은 돌 턱 위 창살 울타리 한 칸 — 칸 가운데 원점 · 옆으로 이어진다. post = 돌기둥(줄 끝 · 모서리) · gate = 두 짝 쇠문 · bent = 창살이 휘고 빠졌다"))
def iron_fence(k, kind="straight", open=False, seed=1):
    if kind == "post":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.55), (0.13, 0.13, 0.55), 0.015), 0.01, 0.15, seed), "masonry")
        k.add(lambda p: np.minimum(box(p, v3(0, 0, 1.13), (0.16, 0.16, 0.04), 0.01), sphere(p, v3(0, 0, 1.24), 0.09)), "stone_l")
        return {"foot": 0.7}
    if kind != "gate":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.1), (0.8, 0.1, 0.1), 0.012), 0.008, 0.15, seed), "stone")
    T = lambda p: p
    bars = []
    for i in range(16):
        x = -0.75 + i * 0.1 + 0.05 - 0.05
        if kind == "bent" and i in (8, 9):
            continue
        bars.append(x)
    def fence(p, x0=-0.8, x1=0.8, bend=False):
        q = p
        if bend:
            q = p - np.stack([np.zeros(len(p)), np.clip(0.3 - np.abs(p[:, 0] - 0.1), 0, 1) * np.clip(p[:, 2] - 0.4, 0, 1) * 0.6, np.zeros(len(p))], 1).astype(F)
        rail = np.minimum(np.abs(q[:, 2] - 0.3) - 0.02, np.abs(q[:, 2] - 0.95) - 0.02)
        rail = np.maximum.reduce([rail, np.abs(q[:, 1]) - 0.02, x0 - q[:, 0], q[:, 0] - x1])
        bar = np.maximum.reduce([np.hypot(((q[:, 0] + 0.8) % 0.125) - 0.0625, q[:, 1]) - 0.014, q[:, 2] - 1.08 + 0.0, 0.2 - q[:, 2], x0 - q[:, 0], q[:, 0] - x1])
        tip = np.maximum.reduce([np.hypot(((q[:, 0] + 0.8) % 0.125) - 0.0625, q[:, 1]) - (1.15 - q[:, 2]) * 0.4, 1.06 - q[:, 2], q[:, 2] - 1.15, x0 - q[:, 0], q[:, 0] - x1])
        return np.minimum.reduce([rail, bar, tip])
    if kind == "gate":
        for s in (-1, 1):
            ang = (s * 1.1) if open else 0.0
            k.add(lambda p, s=s, ang=ang: fence(rot_z(p, ang, (s * 0.5, 0, 0)), *((-0.5, -0.005) if s < 0 else (0.005, 0.5))), "iron")
        k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0], p[:, 2] - 1.0) - 0.48) - 0.018, np.maximum(np.abs(p[:, 1]) - 0.02, 1.0 - p[:, 2])), "iron")
        for sx in (-1, 1):
            k.add(lambda p, sx=sx: box(p, v3(sx * 0.53, 0, 0.7), (0.035, 0.035, 0.7), 0.006), "iron")
        return {"foot": 0.7}
    k.add(lambda p: fence(p, bend=(kind == "bent")), "rust" if kind == "bent" else "iron")
    if kind == "bent":
        k.add(lambda p: hcyl(p, v3(-0.1, -0.45, 0.02), v3(0.35, -0.3, 0.02), 0.015), "rust")
    return {"foot": 0.7, "post": [crop()]}


@prop("wood_fence", "city", cell=(2, 2.5), collide=(1.0, 0.14), tags=["fence", "wood", "module"], name_ko="나무 울타리",
    variants={"rail": {}, "picket": {"kind": "picket"}, "corner": {"kind": "corner"}, "gate": {"kind": "gate"}, "gate_open": {"kind": "gate", "open": True}, "broken": {"kind": "broken"}},
    meta=meta(tile_w=1, states={"closed": "gate", "open": "gate_open"}, note="마당 · 밭 가의 낮은 나무 울타리 한 칸 — 칸 가운데 원점 · 옆으로 이어진다. rail = 가로대 둘 · picket = 뾰족한 널 · corner = 동 · 북으로 꺾임 · broken = 가로대가 빠지고 기둥이 기울었다"))
def wood_fence(k, kind="rail", open=False, seed=1):
    def run(ax, ay, rails=True, pick=False, skip=()):
        L = lambda p: p[:, 0] * ax + p[:, 1] * ay
        Wd = lambda p: p[:, 1] * ax - p[:, 0] * ay
        lo, hi = (-0.8, 0.8) if (ax, ay) == (1, 0) and kind != "corner" else (0.0, 0.8)
        if rails:
            for z in ((0.35, 0.68) if not pick else (0.25, 0.6)):
                if z in skip:
                    continue
                k.add(lambda p, z=z: np.maximum.reduce([np.abs(Wd(p)) - 0.025, np.abs(p[:, 2] - z) - 0.035, lo - L(p), L(p) - hi]) + sdf.noise(p, 0.1, seed) * 0.01, "plank_x")
        if pick:
            k.add(lambda p: np.maximum.reduce([np.abs(((L(p) + 0.8) % 0.16) - 0.08) - 0.045, np.abs(Wd(p) + 0.03) - 0.012, -p[:, 2], p[:, 2] - 0.78 + np.abs(((L(p) + 0.8) % 0.16) - 0.08) * 1.4, lo - L(p), L(p) - hi]), "wood_l")
    post = lambda x, y, lean=0.0: k.add(rough(lambda p: box(rot_y(p, lean, (x, y, 0)), v3(x, y, 0.42), (0.045, 0.045, 0.42), 0.01), 0.01, 0.2, seed), "wood_d")
    if kind == "corner":
        run(1, 0)
        run(0, 1)
        post(0, 0)
        return {"foot": 0.7}
    if kind == "gate":
        post(-0.5, 0)
        post(0.5, 0)
        ang = 1.2 if open else 0.0
        T = lambda p: rot_z(p, ang, (-0.45, 0, 0))
        k.add(lambda p: (lambda q: np.minimum.reduce([box(q, v3(0, 0, z), (0.43, 0.02, 0.035), 0.006) for z in (0.25, 0.65)] + [hcyl(q, v3(-0.4, 0, 0.25), v3(0.4, 0, 0.65), 0.025)]))(T(p)), "plank_x")
        for x in (-0.6, 0.6):
            k.add(lambda p, x=x: np.maximum.reduce([box(p, v3(x * 1.08, 0, z), (0.12, 0.02, 0.035)) for z in (0.35,)]), "plank_x")
        return {"foot": 0.7}
    if kind == "broken":
        run(1, 0, True, False, skip=(0.68,))
        k.add(lambda p: hcyl(p, v3(-0.1, -0.2, 0.03), v3(0.6, -0.35, 0.18), 0.03), "plank_x")
        post(0.5, 0, 0.35)
        post(-0.5, 0)
        return {"foot": 0.7, "post": [crop()]}
    run(1, 0, True, kind == "picket")
    post(-0.5, 0)
    post(0.5, 0)
    return {"foot": 0.7, "post": [crop()]}
