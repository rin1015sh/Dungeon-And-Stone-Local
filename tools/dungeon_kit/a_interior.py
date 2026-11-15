"""건물 실내 공통 — 바닥(목재 마루 · 낡은 마루 · 무늬 타일) · 구조(실내 창문 · 나무 계단 · 나무 기둥 · 나무 난간) ·
가구(긴 테이블 · 작은 원탁 · 협탁 · 카운터 · 장식장 · 안락의자 · 이층 침대). 도시 · 실내 라이브러리(AM69).
벽면(목재 · 회벽 · 장식 판벽)은 a_wall.py KINDS(wood · plaster · panel). 장식 · 살림은 a_interior2.py.
벽 부착물(wall_decal)은 벽 밑동 선(z = 0)에 맞춰 빚었다 — 세트에서 `up`(칸)으로 올려 단다(창문 · 그림 약 0.9~1.2)."""
import numpy as np

import sdf
import surf
import mats as M
from a_floor import _floor, _rgba
from a_furniture import _X, _bottle, _candle, _cup, _flask, _frustum, _planks, _plate, _table
from a_light import flame_post
from kit import box, cap, cyl, ell, hcyl, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3
from surf import F, W, fbm, hexc, pnoise
import tex

PI = np.pi
FIRE = "#f0b040"


# ── 바닥 ──────────────────────────────────────────────────────────────────────

def _boards(seed):
    """마루 판자 배치: 가로로 놓인 판자 16줄(판 폭 = 칸의 1/4), 이음매는 엇갈린다."""
    cell, edge, row = surf.courses(seed + 400, 16, 210, 430, 0.5, True, 0.0)
    return cell, edge, row


def _wood_paint(cell, edge, row, seed, base="#6a4e36"):
    img, gap, h = surf.stonework(cell, edge, hexc(base), hexc("#170f0a"), seed, 1.8, 0.17, 0.45, 0.035, 0.0)
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    warp = (fbm(6, seed + 11, 3) - 0.5) * 26.0 + cell.astype(F) * 7.3
    grain = np.sin((yy + warp) * (2 * PI * 64 / W))                       # 판마다 다르게 휘는 나뭇결(주기가 W에 맞아 이어진다)
    fine = pnoise(128, seed + 12)
    img = img * (1.0 + grain[..., None] * 0.06 + (fine[..., None] - 0.5) * 0.08)
    rng = np.random.default_rng(seed + 13)
    knot_c = rng.random((int(cell.max()) + 1, 2)).astype(F)
    for i in range(int(cell.max()) + 1):                                  # 판마다 옹이 하나쯤
        if knot_c[i, 0] < 0.35:
            m = cell == i
            ys, xs = np.nonzero(m)
            if len(xs) == 0:
                continue
            j = int(knot_c[i, 1] * (len(xs) - 1))
            d = np.hypot((xx - xs[j]) / 7.0, (yy - ys[j]) / 3.2)
            img = img * (1 - (np.clip(1.2 - d, 0, 1) * m * 0.45)[..., None])
    return img, gap


@_floor("room_wood", "목재 마루", {"a": {"seed": 1}, "b": {"seed": 2}})
def room_wood(c, seed=1):
    cell, edge, row = _boards(seed)
    img, gap = _wood_paint(cell, edge, row, seed)
    return _rgba(surf.finish(img, "#4e3a2a", seed))


@_floor("room_wood_old", "낡은 마루", {"a": {"seed": 1}}, base="room_wood")
def room_wood_old(c, seed=1):
    """같은 판자 배치(이음매가 room_wood와 이어진다)에 벌어진 틈 · 휜 판 · 빠진 판 · 덧댄 판 · 긁힘."""
    cell, edge, row = _boards(seed)
    ref, gap = _wood_paint(cell, edge, row, seed)
    img = ref.copy()
    rng = np.random.default_rng(seed + 70)
    n = int(cell.max()) + 1
    warp = rng.random(n) < 0.18
    wide = np.clip(1.0 - edge / 3.6, 0, 1) * 0.85                         # 벌어진 틈
    img = surf.mix(img, wide, hexc("#120c08"), 0.7)
    img = img * (1 - (warp[cell] * np.clip(1 - edge / 14.0, 0, 1) * 0.3)[..., None])  # 휜 판 가장자리 그늘
    gone = (rng.random(n) < 0.035)[cell].astype(F)                       # 빠진 판: 어두운 장선과 흙
    under = hexc("#1c1510") * (0.8 + fbm(30, seed + 5, 2)[..., None] * 0.4)
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    joist = (np.abs(((xx % 128) - 64)) < 7).astype(F)
    img = surf.mix(img, gone, under * (1 + joist[..., None] * 1.4))
    patch = (rng.random(n) < 0.05)[cell].astype(F) * (1 - gone)          # 덧댄 판: 색이 다른 새 판 + 못
    img = surf.mix(img, patch, img * hexc("#8a7660") / hexc("#6a4e36"), 0.7)
    dirt = np.clip((fbm(5, seed + 8, 3) - 0.52) * 3.0, 0, 1) * 0.5
    img = surf.mix(img, dirt, hexc("#2e261c"))
    ly = tex.Layer()
    for _ in range(14):                                                   # 끌린 긁힘
        x, y = rng.random() * W, rng.random() * W
        a = rng.uniform(-0.3, 0.3)
        ln = rng.uniform(30, 90)
        ly.line([(x, y), (x + np.cos(a) * ln, y + np.sin(a) * ln)], np.array([0.62, 0.52, 0.4], F), 0.25, 1.2)
    return _rgba(surf.finish(ly.over(img), "#46362a", seed, ref=ref))


@_floor("room_tile", "무늬 타일 바닥", {"checker": {"seed": 1}, "inlay": {"seed": 2, "inlay": True}})
def room_tile(c, seed=1, inlay=False):
    """장식 바닥: 칸마다 2 × 2장의 네모 타일 — 바둑판(담색 · 적갈색) 또는 마름모 상감(테두리 띠 + 가운데 마름모)."""
    cell, edge, u, v = surf.squares(8, 0.8, seed + 5)
    ix, iy = cell % 8, cell // 8
    light, terra, inl = hexc("#8c8068"), hexc("#6a4a38"), hexc("#3e4c48")
    if inlay:
        img = np.broadcast_to(light, (W, W, 3)).copy()
        dia = (np.abs(u) + np.abs(v) < 0.55).astype(F)
        ring = ((np.abs(u) + np.abs(v) > 0.66) & (np.abs(u) + np.abs(v) < 0.78)).astype(F)
        corner = (np.maximum(np.abs(u), np.abs(v)) > 0.8).astype(F) * (np.abs(u) + np.abs(v) > 1.45)
        img = surf.mix(img, dia, terra)
        img = surf.mix(img, ring + corner, inl)
    else:
        dark = ((ix + iy) % 2).astype(F)
        img = surf.mix(np.broadcast_to(light, (W, W, 3)).copy(), dark, terra)
    img = img * (0.9 + fbm(12, seed + 3, 3)[..., None] * 0.2)
    rng = np.random.default_rng(seed + 9)
    tone = 1.0 + (rng.random(64).astype(F) - 0.5) * 0.12
    img = img * tone[cell][..., None]
    h = np.clip(edge / 8.0, 0, 1) ** 0.6
    img = img * tex.relief(h, 1.0)[..., None]
    g = np.clip(1.0 - edge / 2.4, 0, 1)
    img = surf.mix(img, g, hexc("#1e1a16"))
    worn = np.clip((fbm(4, seed + 4, 3) - 0.55) * 2.5, 0, 1) * 0.35
    img = surf.mix(img, worn, hexc("#4a4238"))
    return _rgba(surf.finish(img, "#64584a", seed))


# ── 실내 창문 · 계단 · 기둥 · 난간 ─────────────────────────────────────────────

@prop("room_window", "interior", layer="wall_decal", cell=(2, 3), tags=["wood", "glass", "window"], name_ko="실내 창문",
    variants={"day": {}, "night": {"state": "night"}, "curtained": {"state": "curtained"}, "shuttered": {"state": "shuttered"}, "broken": {"state": "broken"}},
    light={"color": "#d8d4b8", "radius": 3.0, "at": (0, -0.3, 1.5), "flicker": 0.0, "variants": ["day", "curtained"]})
def room_window(k, state="day", seed=1):
    """벽에 낸 창(밑 = 창턱 아래 · up ≈ 0.9). 낮엔 흐린 빛이 들고 밤엔 검푸르다."""
    hw, z0, z1 = 0.36, 0.06, 1.06
    zc = (z0 + z1) / 2
    k.add(lambda p: sub(box(p, v3(0, -0.04, zc), (hw + 0.07, 0.04, (z1 - z0) / 2 + 0.07), 0.01), box(p, v3(0, -0.04, zc), (hw, 0.08, (z1 - z0) / 2), 0.0)), "wood_d")
    k.add(lambda p: box(p, v3(0, -0.07, z0 - 0.05), (hw + 0.12, 0.07, 0.03), 0.01), "wood")                       # 창턱
    pane = {"day": k.mat("pane_day", M.glow("#a8ab98")), "curtained": "pane_day", "night": k.mat("pane_night", M.plain("#1a2030", 0.3, 0.2, 3)),
        "shuttered": "void", "broken": "void"}[state]
    if state == "curtained":
        k.mat("pane_day", M.glow("#a8ab98"))
    k.add(lambda p: box(p, v3(0, -0.012, zc), (hw, 0.008, (z1 - z0) / 2)), pane)
    if state != "shuttered":
        bars = lambda p: np.minimum(box(p, v3(0, -0.03, zc), (0.02, 0.025, (z1 - z0) / 2)), box(p, v3(0, -0.03, zc + 0.04), (hw, 0.025, 0.018)))
        if state == "broken":                                       # 살 반쪽이 떨어지고 유리 조각만 남았다
            k.add(lambda p: np.maximum(bars(p), -(p[:, 0] + p[:, 2] * 0.6 - 0.62)), "wood_d")
            for i, (x, z) in enumerate(((-0.28, 0.2), (-0.3, 0.9), (0.26, 0.14), (0.1, 0.96))):
                k.add(lambda p, x=x, z=z, i=i: box(rot_y(p, 0.6 + i, (x, -0.02, z)), v3(x, -0.02, z), (0.05, 0.004, 0.09)), "glass")
            k.rubble([(-0.2, -0.3), (0.15, -0.35), (0.3, -0.25)], "glass", 0.015, 0.03)
        else:
            k.add(bars, "wood_d")
    if state == "curtained":                                        # 반쯤 친 커튼 둘 + 막대
        k.add(lambda p: hcyl(p, (-hw - 0.14, -0.08, z1 + 0.04), (hw + 0.14, -0.08, z1 + 0.04), 0.016), "brass")
        for s in (-1, 1):
            k.add(rough(lambda p, s=s: box(p, v3(s * (hw - 0.06), -0.1, zc), (0.14, 0.03, (z1 - z0) / 2 + 0.03), 0.01) + 0.012 * np.sin(p[:, 0] * 45), 0.01, 0.1, seed), "cloth_r")
    if state == "shuttered":                                        # 닫힌 덧문 두 짝
        for s in (-1, 1):
            k.add(lambda p, s=s: box(p, v3(s * hw / 2, -0.05, zc), (hw / 2 - 0.006, 0.016, (z1 - z0) / 2), 0.004), "plank_y")
            k.add(lambda p, s=s: np.minimum(box(p, v3(s * hw / 2, -0.07, z0 + 0.18), (hw / 2 - 0.03, 0.01, 0.025)), box(p, v3(s * hw / 2, -0.07, z1 - 0.18), (hw / 2 - 0.03, 0.01, 0.025))), "iron")
    if state in ("day", "curtained"):
        return {"shadow": 0.0, "glow": [(0, -0.02, zc, 40, "#cfcab0", 0.18)]}
    return {"shadow": 0.0}


def _plane(p, nz, ny, c):
    """반공간 nz·z + ny·y ≤ c 의 거리(바깥 +)."""
    return (p[:, 2] * nz + p[:, 1] * ny - c) / np.hypot(nz, ny)


@prop("wood_stairs", "interior", cell=(2.4, 4.2), collide=(-0.5, 0.0, 1.0, 1.5), tags=["wood", "stairs"], name_ko="나무 계단",
    variants={"up": {}, "broken": {"state": "broken"}}, meta={"states": {"intact": "up", "broken": "broken"}})
def wood_stairs(k, state="up", seed=1):
    """북쪽(멀어지는 쪽)으로 오르는 나무 계단 6단 — 원점 = 첫 단 앞 가운데. 옆판 · 손잡이 난간."""
    n, d, r, hw = 6, 0.25, 0.25, 0.42
    for i in range(n):
        if state == "broken" and i == 2:
            continue
        k.add(rough(lambda p, i=i: box(p, v3(0, i * d + d / 2, (i + 1) * r - 0.025), (hw, d / 2 + 0.012, 0.025), 0.006), 0.006, 0.2, seed + i), "plank_x")
        k.add(lambda p, i=i: box(p, v3(0, i * d + 0.01, (i + 0.5) * r - 0.012), (hw - 0.01, 0.012, r / 2 - 0.012)), "wood_d")
    if state == "broken":                                           # 빠진 단 자리는 검고, 판은 앞에 떨어졌다
        k.add(lambda p: box(p, v3(0, 2 * d + d / 2, 2.0 * r), (hw - 0.02, d / 2 - 0.02, r - 0.02)), "void")
        k.add(lambda p: box(rot_z(p, 0.4, (0.5, -0.35, 0)), v3(0.5, -0.35, 0.025), (0.3, 0.07, 0.022), 0.006), "plank_x")
        _planks(k, [(-0.55, -0.3, 0.9), (0.1, -0.5, -0.3)], "plank_x", 0.12, seed)
    slope = r / d
    for s in (-1, 1):                                               # 옆판(톱니꼴 아래를 감싼다)
        k.add(lambda p, s=s: np.maximum(np.maximum(box(p, v3(s * (hw + 0.025), n * d / 2, n * r / 2), (0.025, n * d / 2, n * r / 2)), _plane(p, 1.0, -slope, r + 0.04)),
            -_plane(p, 1.0, -slope, -0.12)), "wood_d")
    x = hw + 0.06                                                   # 오른쪽 손잡이 난간: 기둥 둘 + 비스듬한 손잡이 + 살
    k.add(lambda p: np.minimum(box(p, v3(x, 0.05, 0.45), (0.035, 0.035, 0.45), 0.008), box(p, v3(x, n * d - 0.08, n * r + 0.45), (0.035, 0.035, 0.45), 0.008)), "wood")
    k.add(lambda p: hcyl(p, (x, 0.05, 0.86), (x, n * d - 0.08, n * r + 0.82), 0.026), "wood_l")
    for i in range(1, n):
        k.add(lambda p, i=i: cap(p, v3(x, i * d, (i + 0.5) * r), v3(x, i * d, (i + 0.5) * r + 0.62), 0.012), "wood_d")
    return {}


@prop("wood_post", "interior", cell=(3, 4), collide=(0.36, 0.36), tags=["wood", "pillar"], name_ko="나무 기둥",
    variants={"plain": {}, "braced": {"state": "braced"}, "cracked": {"state": "cracked"}})
def wood_post(k, state="plain", seed=1):
    """실내 버팀 기둥(모서리 깎은 각재) — braced = 머리에 가로 들보 토막과 까치발, cracked = 세로로 갈라지고 기울었다."""
    hh = 2.3
    tilt = 0.06 if state == "cracked" else 0.0
    t = _X(k, lambda p: rot_y(p, tilt))
    t.add(lambda p: box(p, v3(0, 0, 0.05), (0.17, 0.17, 0.05), 0.01), "stone_d")                         # 주춧돌
    body = lambda p: box(p, v3(0, 0, hh / 2 + 0.1), (0.11, 0.11, hh / 2), 0.025)
    if state == "cracked":
        body = (lambda b: lambda p: sub(b(p), box(rot_z(p, 0.05), v3(0.0, -0.11, 1.2), (0.012, 0.03, 0.7))))(body)
    t.add(rough(body, 0.008, 0.25, seed), "wood")
    t.add(lambda p: np.minimum(box(p, v3(0, 0, 0.28), (0.125, 0.125, 0.02)), box(p, v3(0, 0, hh + 0.02), (0.13, 0.13, 0.03), 0.006)), "wood_d")
    if state == "braced":
        t.add(lambda p: box(p, v3(0, 0, hh + 0.12), (0.62, 0.12, 0.08), 0.01), "wood_d")
        for s in (-1, 1):
            t.add(lambda p, s=s: hcyl(p, (s * 0.08, -0.02, hh - 0.32), (s * 0.48, -0.02, hh + 0.04), 0.035), "wood")
            t.add(lambda p, s=s: sphere(p, v3(s * 0.3, -0.07, hh - 0.12), 0.012), "iron")
    return {}


@prop("banister", "interior", cell=(2, 2.2), collide=(1.0, 0.2), tags=["wood", "railing"], name_ko="나무 난간",
    variants={"straight": {}, "post": {"state": "post"}, "broken": {"state": "broken"}}, meta={"tile_w": 1})
def banister(k, state="straight", seed=1):
    """실내 나무 난간 한 칸(가로로 이어 붙는다 — 칸 끝까지 그렸다). post = 끝 기둥(둥근 머리)."""
    if state == "post":
        k.add(lambda p: box(p, v3(0, 0, 0.42), (0.065, 0.065, 0.42), 0.01), "wood")
        k.add(lambda p: np.minimum(box(p, v3(0, 0, 0.86), (0.08, 0.08, 0.025), 0.008), sphere(p, v3(0, 0, 0.95), 0.07)), "wood_d")
        return {"cell": (1.2, 2.2)}
    broken = state == "broken"
    rail = lambda p: box(p, v3(0, 0, 0.82), (0.5, 0.04, 0.03), 0.012)
    if broken:                                                      # 손잡이가 가운데서 꺾여 처졌다
        k.add(lambda p: np.minimum(box(p, v3(-0.32, 0, 0.82), (0.18, 0.04, 0.03), 0.012), box(rot_y(p, -0.5, (0.12, 0, 0.82)), v3(0.31, 0, 0.82), (0.19, 0.04, 0.03), 0.012)), "wood_l")
    else:
        k.add(rail, "wood_l")
    k.add(lambda p: box(p, v3(0, 0, 0.07), (0.5, 0.035, 0.025), 0.008), "wood_d")
    for i, x in enumerate((-0.375, -0.125, 0.125, 0.375)):
        if broken and i in (1, 2):
            continue
        k.add(lambda p, x=x: smin(cap(p, v3(x, 0, 0.09), v3(x, 0, 0.8), 0.018), np.minimum(ell(p, v3(x, 0, 0.3), (0.035, 0.035, 0.08)), ell(p, v3(x, 0, 0.62), (0.03, 0.03, 0.05))), 0.02), "wood")
    if broken:
        k.add(lambda p: cap(p, v3(-0.1, -0.35, 0.03), v3(0.4, -0.25, 0.03), 0.026), "wood")
        k.add(lambda p: cap(p, v3(0.12, 0.02, 0.09), v3(0.15, 0.0, 0.32), 0.018), "wood")
    return {}


# ── 탁자 · 카운터 · 장식장 ─────────────────────────────────────────────────────

@prop("long_table", "interior", cell=(4, 2.6), collide=(2.7, 0.8), tags=["wood", "table", "dining"], name_ko="긴 테이블",
    variants={"empty": {}, "set": {"state": "set"}, "broken": {"state": "broken"}})
def long_table(k, state="empty", seed=1):
    w, d, h = 1.36, 0.4, 0.52
    if state == "broken":                                           # 가운데가 내려앉아 V자로 꺾였다
        for s in (-1, 1):
            t = _X(k, lambda p, s=s: rot_y(p, s * 0.28, (0, 0, 0.0)))
            t.add(rough(lambda p, s=s: box(p, v3(s * w / 2, 0, h - 0.04), (w / 2 - 0.02, d, 0.04), 0.012), 0.012, 0.2, seed), "plank_x")
            t.add(lambda p, s=s: np.minimum(box(p, v3(s * (w - 0.1), -d + 0.08, h / 2 - 0.04), (0.05, 0.05, h / 2 - 0.04)), box(p, v3(s * (w - 0.1), d - 0.08, h / 2 - 0.04), (0.05, 0.05, h / 2 - 0.04))), "wood_d")
        _planks(k, [(0.1, -0.62, 0.3), (-0.3, -0.55, -0.4), (0.5, -0.5, 1.2)], "plank_x", 0.14, seed)
        return {}
    _table(k, w, d, h, seed)
    k.add(lambda p: np.minimum(box(p, v3(-w + 0.1, 0, 0.12), (0.035, d - 0.08, 0.03)), np.minimum(box(p, v3(w - 0.1, 0, 0.12), (0.035, d - 0.08, 0.03)), box(p, v3(0, 0, 0.12), (w - 0.12, 0.03, 0.025)))), "wood_d")
    if state == "set":
        for x in (-0.95, -0.5, 0.0, 0.5, 0.95):
            for y, s in ((-0.24, 1), (0.24, -1)):
                _plate(k, x, y, h, 0.08, "steel")
                _cup(k, x + 0.13, y + s * 0.04, h, 0.03, 0.07, "steel" if (int(x * 10) % 2) else "wood_l")
        k.add(lambda p: ell(p, v3(-0.25, 0, h + 0.05), (0.2, 0.1, 0.06)), "food")
        k.add(lambda p: ell(p, v3(0.3, 0.02, h + 0.04), (0.12, 0.09, 0.05)), k.mat("bread", M.plain("#8a6236", 0.35, 0.05, 41)))
        _bottle(k, 0.72, 0.0, h, 0.04, 0.13, "glass")
        _candle(k, -0.7, 0.0, h, 0.09)
    return {}


@prop("round_table", "interior", cell=(2.2, 2.4), collide=(0.8, 0.6), tags=["wood", "table"], name_ko="작은 원탁",
    variants={"plain": {}, "cloth": {"state": "cloth"}, "candle": {"state": "candle", "frames": 4}},
    light={"color": FIRE, "radius": 2.2, "at": (0, 0, 0.75), "flicker": 0.25, "variants": ["candle"]})
def round_table(k, state="plain", seed=1, f=0):
    h = 0.5
    k.add(rough(lambda p: cyl(p, v3(0, 0, h - 0.04), 0.38, 0.04, 0.012), 0.01, 0.2, seed), "wood")
    k.add(lambda p: smin(cap(p, v3(0, 0, 0.05), v3(0, 0, h - 0.04), 0.04, 0.03), ell(p, v3(0, 0, 0.22), (0.06, 0.06, 0.08)), 0.03), "wood_d")
    for a in (0.3, 2.4, 4.5):
        k.add(lambda p, a=a: cap(p, v3(0, 0, 0.06), v3(np.cos(a) * 0.26, np.sin(a) * 0.22, 0.02), 0.03, 0.022), "wood_d")
    if state == "cloth":
        k.add(rough(lambda p: sub(_frustum(p, v3(0, 0, h - 0.2), 0.45, 0.39, 0.21), cyl(p, v3(0, 0, h - 0.24), 0.37, 0.22)), 0.012, 0.08, seed), "linen")
        k.add(lambda p: cyl(p, v3(0, 0, h - 0.002), 0.39, 0.01, 0.004), "linen")
        _flask(k, 0.1, 0.06, h, 0.05, "glass_b")
    if state == "candle":
        k.add(lambda p: cyl(p, v3(0, 0, h), 0.06, 0.012, 0.004), "brass")
        _candle(k, 0, 0, h + 0.01, 0.12)
        _cup(k, 0.2, -0.1, h, 0.03, 0.07, "steel")
        return {"post": [flame_post(0, 0, h + 0.15, 9, seed, f, "fire", 0.36, 2.6, 0.38)]}
    return {}


@prop("nightstand", "interior", cell=(1.6, 2.2), collide=(0.45, 0.4), tags=["wood", "bedroom"], name_ko="협탁",
    variants={"plain": {}, "candle": {"state": "candle", "frames": 4}, "open": {"state": "open"}},
    light={"color": FIRE, "radius": 2.0, "at": (0, 0, 0.75), "flicker": 0.25, "variants": ["candle"]})
def nightstand(k, state="plain", seed=1, f=0):
    w, d, h = 0.2, 0.17, 0.5
    k.add(rough(lambda p: box(p, v3(0, 0, h - 0.02), (w + 0.015, d + 0.015, 0.02), 0.006), 0.006, 0.2, seed), "plank_x")
    k.add(lambda p: box(p, v3(0, 0.01, 0.3), (w - 0.01, d - 0.02, 0.17), 0.006), "wood")
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: box(p, v3(sx * (w - 0.02), sy * (d - 0.02), h / 2), (0.025, 0.025, h / 2), 0.006), "wood_d")
    dy = -0.16 if state == "open" else 0.0
    k.add(lambda p: box(p, v3(0, -d + 0.02 + dy, 0.36), (w - 0.04, 0.015 + (0.08 if state == "open" else 0), 0.07), 0.005), "wood_l")
    k.add(lambda p: sphere(p, v3(0, -d - 0.005 + dy * 2, 0.36), 0.016), "brass")
    if state == "open":
        k.add(lambda p: box(p, v3(0.04, -0.27, 0.42), (0.05, 0.035, 0.012)), "leather")
        _bottle(k, -0.06, -0.26, 0.41, 0.02, 0.04, "glass_r", 0.03)
    if state == "candle":
        k.add(lambda p: cyl(p, v3(-0.04, 0, h), 0.05, 0.012, 0.004), "brass")
        _candle(k, -0.04, 0, h + 0.01, 0.1)
        k.add(lambda p: box(rot_z(p, 0.3, (0.1, 0.02, 0)), v3(0.1, 0.02, h + 0.02), (0.07, 0.05, 0.02)), "leather_d")
        return {"post": [flame_post(-0.04, 0, h + 0.13, 8, seed, f, "fire", 0.36, 2.6, 0.38)]}
    return {}


def _panels(p, x0, x1, y, z0, z1, n):
    """앞판에 오목하게 파인 네모 칸 n개(거리 — 파낼 모양)."""
    w = (x1 - x0) / n
    out = None
    for i in range(n):
        c = x0 + w * (i + 0.5)
        d = box(p, v3(c, y, (z0 + z1) / 2), (w / 2 - 0.05, 0.012, (z1 - z0) / 2 - 0.06))
        out = d if out is None else np.minimum(out, d)
    return out


@prop("counter", "interior", cell=(1.6, 2.2), collide=(1.0, 0.44), tags=["wood", "counter", "straight"], name_ko="카운터",
    variants={"straight": {}, "side": {"state": "side"}, "corner": {"state": "corner"}, "end_closed": {"state": "end_closed"}, "end_open": {"state": "end_open"}},
    interact="counter", meta={"tile_w": 1, "states": {"closed": "end_closed", "open": "end_open"}, "note": "straight = 가로로 이어지는 한 칸 · side = 세로(북쪽)로 이어지는 한 칸 · corner = 가로 줄이 북쪽으로 꺾이는 자리"})
def counter(k, state="straight", seed=1):
    """가게 · 여관 · 은행 어디서나 쓰는 판매대 한 칸. 앞판에 오목한 칸, 윗판은 앞으로 조금 나온다."""
    h, d = 0.62, 0.2
    def run(x0, x1, y0, y1, front=True):
        cx, cy, hx, hy = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
        k.add(rough(lambda p: box(p, v3(cx, cy - 0.015, h - 0.025), (hx, hy + 0.03, 0.025), 0.008), 0.006, 0.2, seed), "plank_x")
        body = lambda p: box(p, v3(cx, cy, (h - 0.05) / 2), (hx, hy, (h - 0.05) / 2))
        if front and hy < hx + 0.01:
            k.add(lambda p: sub(body(p), _panels(p, x0, x1, y0, 0.08, h - 0.08, max(1, int(round((x1 - x0) / 0.5))))), "wood")
        else:
            k.add(body, "wood")
        k.add(lambda p: box(p, v3(cx, cy, 0.03), (hx + 0.012, hy + 0.012, 0.03)), "wood_d")
    if state == "straight":
        run(-0.5, 0.5, -d, d)
    elif state == "side":
        run(-d, d, -0.5, 0.5, False)
    elif state == "corner":
        run(-0.5, d, -d, d)
        run(-d, d, d, 0.5, False)
        return {"cell": (1.6, 2.2)}
    else:                                                           # 끝: 오른쪽이 막혔거나, 들어 올린 뚜껑판으로 열린 드나드는 자리
        run(-0.5, 0.15, -d, d)
        k.add(lambda p: box(p, v3(0.17, 0, (h - 0.04) / 2), (0.025, d + 0.01, (h - 0.04) / 2), 0.006), "wood_d")
        if state == "end_closed":
            k.add(lambda p: box(p, v3(0.35, 0, h - 0.025), (0.16, d + 0.015, 0.022), 0.008), "plank_x")
            k.add(lambda p: box(p, v3(0.35, -d + 0.01, 0.3), (0.15, 0.015, 0.22), 0.005), "plank_y")
        else:
            k.add(lambda p: box(p, v3(0.2, 0, h + 0.17), (0.022, d + 0.015, 0.16), 0.008), "plank_x")
            k.add(lambda p: np.minimum(sphere(p, v3(0.19, -0.1, h), 0.014), sphere(p, v3(0.19, 0.1, h), 0.014)), "iron")
    return {}


def _curio(k, kind, x, y, z, seed):
    if kind == 0:
        k.add(lambda p: smin(ell(p, v3(x, y, z + 0.06), (0.045, 0.045, 0.06)), cap(p, v3(x, y, z + 0.1), v3(x, y, z + 0.16), 0.02, 0.028), 0.02), k.mat("glaze", M.plain("#4a5a62", 0.3, 0.08, 43)))
    elif kind == 1:
        k.add(lambda p: smin(cyl(p, v3(x, y, z), 0.03, 0.02), np.minimum(cap(p, v3(x, y, z + 0.02), v3(x, y, z + 0.1), 0.022, 0.016), sphere(p, v3(x, y, z + 0.13), 0.024)), 0.01), "marble")
    elif kind == 2:
        k.add(lambda p: box(p, v3(x, y, z + 0.035), (0.06, 0.04, 0.035), 0.008), "wood_l")
        k.add(lambda p: box(p, v3(x, y - 0.042, z + 0.04), (0.012, 0.004, 0.012)), "brass")
    else:
        k.add(lambda p: np.maximum(disc_like(p, x, y + 0.02, z + 0.1, 0.09), np.abs(p[:, 1] - y - 0.02) - 0.008), "steel")


def disc_like(p, x, y, z, r):
    return np.hypot(p[:, 0] - x, p[:, 2] - z) - r


@prop("display_cabinet", "interior", cell=(2, 3.4), collide=(0.9, 0.42), tags=["wood", "glass", "display"], name_ko="장식장",
    variants={"curios": {}, "empty": {"state": "empty"}, "broken": {"state": "broken"}}, interact="container")
def display_cabinet(k, state="curios", seed=1):
    """유리 문을 단 진열장(문틀 살 · 유리 반짝임) — 선반 셋에 자잘한 물건."""
    w, d, h = 0.42, 0.18, 1.45
    k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.01), box(p, v3(0, -0.05, h / 2 + 0.02), (w - 0.04, d, h / 2 - 0.09))), 0.006, 0.2, seed), "wood_d")
    k.add(lambda p: box(p, v3(0, 0, h + 0.03), (w + 0.03, d + 0.03, 0.03), 0.008), "wood")
    k.add(lambda p: box(p, v3(0, 0.12, h / 2), (w - 0.04, 0.01, h / 2 - 0.1)), k.mat("velvet", M.plain("#3a2228", 0.3, 0.1, 44)))
    shelves = (0.12, 0.5, 0.88)
    for z in shelves:
        k.add(lambda p, z=z: box(p, v3(0, 0.0, z), (w - 0.04, d - 0.03, 0.012)), "wood")
    if state == "curios":
        rng = np.random.default_rng(seed)
        for si, z in enumerate(shelves):
            for j, x in enumerate((-0.25, 0.0, 0.25)):
                _curio(k, (si * 3 + j + int(rng.integers(3))) % 4, x, 0.04, z + 0.012, seed)
    doorf = lambda p: np.minimum(np.minimum(box(p, v3(0, -d + 0.01, h / 2 + 0.02), (0.02, 0.012, h / 2 - 0.08)), box(p, v3(0, -d + 0.01, 1.28), (w - 0.04, 0.012, 0.018))),
        np.minimum(box(p, v3(-w + 0.06, -d + 0.01, h / 2 + 0.02), (0.02, 0.012, h / 2 - 0.08)), box(p, v3(w - 0.06, -d + 0.01, h / 2 + 0.02), (0.02, 0.012, h / 2 - 0.08))))
    if state == "broken":                                           # 오른쪽 문이 떨어져 기울었다 · 유리 조각
        k.add(lambda p: np.maximum(doorf(p), p[:, 0] - 0.03), "wood")
        k.add(lambda p: box(rot_y(p, 0.35, (0.6, -0.35, 0)), v3(0.6, -0.35, 0.45), (0.2, 0.014, 0.42), 0.006), "wood")
        k.rubble([(0.2, -0.4), (-0.1, -0.45), (0.35, -0.55), (0.0, -0.32)], "glass", 0.012, 0.028)
        k.add(lambda p: box(rot_z(p, 0.6, (-0.15, -0.5, 0)), v3(-0.15, -0.5, 0.03), (0.06, 0.04, 0.03), 0.008), "wood_l")
        return {"post": [_glints([(-0.2, -d, 1.1), (-0.3, -d, 0.6)])]}
    k.add(doorf, "wood")
    return {"post": [_glints([(-0.2, -d, 1.1), (-0.32, -d, 0.65), (0.22, -d, 1.0), (0.3, -d, 0.35)])]}


def _glints(pts):
    """유리 위 비스듬한 빛 줄(유리가 있다는 표시)."""
    def fn(img, vw):
        h, w = img.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w].astype(F)
        m = np.zeros((h, w), F)
        for x, y, z in pts:
            px, py = vw.px(x, y, z)
            d = np.abs((xx - px) + (yy - py) * 0.8)
            m = np.maximum(m, np.clip(1.6 - d, 0, 1) * (np.hypot(xx - px, yy - py) < 9) * (img[..., 3] > 128))
        import fx
        return fx._over(img, m * 0.5, hexc("#d8dccc"))
    return fn


# ── 의자 · 침대 ──────────────────────────────────────────────────────────────

def _armchair(t, seed, worn=False, broken=False):
    cushion = "cloth_r" if not worn else k_worn(t)
    for sx in (-1, 1):
        for sy in (-1, 1):
            if broken and sx == 1 and sy == -1:
                continue
            t.add(lambda p, sx=sx, sy=sy: cap(p, v3(sx * 0.24, sy * 0.2, 0.0), v3(sx * 0.23, sy * 0.19, 0.24), 0.028, 0.032), "wood_d")
    t.add(lambda p: box(p, v3(0, 0, 0.27), (0.27, 0.23, 0.04), 0.01), "wood")
    t.add(rough(lambda p: box(p, v3(0, -0.02, 0.33), (0.23, 0.2, 0.045), 0.04), 0.01, 0.15, seed), cushion)
    back = lambda p: box(p, v3(0, 0.2, 0.68), (0.26, 0.05, 0.38), 0.03)
    if broken:
        back = (lambda b: lambda p: np.maximum(b(p), p[:, 2] - 0.62 - (sdf.noise(p, 0.06, seed) - 0.5) * 0.1))(back)
    t.add(rough(back, 0.008, 0.2, seed), "wood")
    t.add(rough(lambda p: np.maximum(box(p, v3(0, 0.15, 0.68 if not broken else 0.5), (0.2, 0.02, 0.3 if not broken else 0.12), 0.03), p[:, 2] - (0.62 if broken else 9)), 0.008, 0.15, seed + 1), cushion)
    for sx in (-1, 1):
        t.add(lambda p, sx=sx: np.minimum(box(p, v3(sx * 0.27, 0.0, 0.47), (0.035, 0.22, 0.025), 0.012), cap(p, v3(sx * 0.27, -0.18, 0.3), v3(sx * 0.27, -0.19, 0.46), 0.022)), "wood")
    if not broken:
        t.add(lambda p: np.minimum(sphere(p, v3(-0.2, 0.22, 1.06), 0.035), sphere(p, v3(0.2, 0.22, 1.06), 0.035)), "wood_d")


def k_worn(t):
    return t.mat("cloth_worn", M.plain("#5e3a30", 0.55, 0.06, 45))


@prop("armchair", "interior", cell=(2, 3), collide=(0.6, 0.5), tags=["wood", "cloth", "chair"], name_ko="안락의자",
    variants={"s": {}, "e": {"yaw": PI / 2}, "w": {"yaw": -PI / 2}, "worn": {"state": "worn"}, "broken": {"state": "broken"}})
def armchair(k, state="s", seed=1):
    """등받이 높은 천 의자 — 의자(chair)의 걸터앉는 나무 의자와 달리 쿠션 · 팔걸이."""
    if state == "worn":
        _armchair(k, seed, worn=True)
        k.add(lambda p: np.minimum(ell(p, v3(0.08, -0.12, 0.38), (0.06, 0.04, 0.025)), ell(p, v3(-0.1, 0.16, 0.8), (0.04, 0.02, 0.06))), "linen")   # 찢어진 틈으로 삐져나온 속
    elif state == "broken":
        t = _X(k, lambda p: rot_x(rot_y(p, -0.18), 0.12, (0, -0.2, 0)))
        _armchair(t, seed, broken=True)
        k.add(lambda p: cap(p, v3(0.4, -0.45, 0.025), v3(0.62, -0.3, 0.025), 0.026), "wood_d")
        k.add(lambda p: box(rot_z(p, 0.4, (-0.45, -0.5, 0)), v3(-0.45, -0.5, 0.03), (0.16, 0.08, 0.03), 0.01), "wood")
    else:
        _armchair(k, seed)
    return {}


@prop("bunk_bed", "interior", cell=(3.2, 3.6), collide=(1.5, 0.75), tags=["wood", "bedroom", "inn"], name_ko="이층 침대",
    variants={"made": {}, "messy": {"state": "messy"}})
def bunk_bed(k, state="made", seed=1):
    """두 칸짜리 이층 침대(숙소 · 막사) — 기둥 넷 · 짚 매트 둘 · 오른쪽 사다리."""
    w, d = 0.72, 0.36
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: box(p, v3(sx * w, sy * d, 0.72), (0.04, 0.04, 0.72), 0.008), "wood_d")
    for z in (0.28, 0.98):
        k.add(lambda p, z=z: sub(box(p, v3(0, 0, z), (w, d, 0.05), 0.008), box(p, v3(0, 0, z + 0.03), (w - 0.04, d - 0.04, 0.06))), "wood")
        k.add(rough(lambda p, z=z: box(p, v3(0, 0, z + 0.04), (w - 0.05, d - 0.05, 0.05), 0.04), 0.012, 0.12, seed), "linen")
        k.add(rough(lambda p, z=z: ell(p, v3(-w + 0.18, 0, z + 0.11), (0.12, 0.2, 0.05)), 0.008, 0.1, seed), "linen")
        if state == "messy":
            k.add(rough(lambda p, z=z: box(rot_z(p, 0.2, (0.2, 0, z)), v3(0.2, -0.04, z + 0.11), (0.38, d - 0.02, 0.03), 0.03), 0.03, 0.12, seed + int(z * 10)), "cloth_b")
        else:
            k.add(rough(lambda p, z=z: box(p, v3(0.22, 0, z + 0.1), (0.42, d - 0.03, 0.025), 0.025), 0.006, 0.12, seed), "cloth_b")
    k.add(lambda p: box(p, v3(0, d, 1.25), (w, 0.02, 0.07), 0.006), "wood")
    for z in (0.2, 0.45, 0.7):                                     # 사다리(오른쪽 끝)
        k.add(lambda p, z=z: hcyl(p, (w + 0.05, -d + 0.05, z + 0.3), (w + 0.05, -d + 0.3, z + 0.3), 0.016), "wood")
    if state == "messy":
        k.add(rough(lambda p: box(rot_z(p, -0.4, (0.1, -0.6, 0)), v3(0.1, -0.6, 0.03), (0.25, 0.18, 0.03), 0.03), 0.03, 0.1, seed), "cloth_b")
    return {}
