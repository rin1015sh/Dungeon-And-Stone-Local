"""환경 흔적 · 파손(도시 · 실내 라이브러리 AM69 — 비어 있던 것만): 흙 얼룩 · 손자국 · 창 유리 조각 · 쏟은 술과 기름 · 촛농 · 방치된 물건 ·
무너진 선반 · 낡은 문 · 무너진 목재 구조물 · 바닥 파편 · 쓰레기 더미 · 무너진 천장 회반죽.
이미 있는 것(핏자국 · 긁힌 자국 · 발자국 · 먼지 · 물 얼룩 · 낙서 · 그을음 · 이끼 · 거미줄 · 나무 잔해 · 깨진 병 · 돌무더기)은 다시 만들지 않았다."""
import numpy as np

import sdf
from kit import (F, box, cap, cyl, ell, flat, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep
from a_trace import _dots, _stain, _tone
from a_furniture import _bottle, _book, _frustum, _planks


# ── 평면 자국 ─────────────────────────────────────────────────────────────────

@flat("mud_stain", "trace", cell=(150, 110), tags=["dirt", "street"], name_ko="흙 얼룩",
    variants={"a": {"seed": 3}, "b": {"seed": 9}, "smear": {"seed": 14, "kind": "smear"}, "wet": {"seed": 21, "wet": True}})
def mud_stain(c, kind="blob", wet=False, seed=1):
    if kind == "smear":   # 신발 · 바퀴로 끌린 흙 — 한쪽으로 길게
        m = np.zeros((c.H, c.W), F)
        for i in range(5):
            y = 30 + i * 11 + c.rng.uniform(-4, 4)
            m = np.maximum(m, c.seg([(18 + c.rng.uniform(0, 14), y), (75, y + c.rng.uniform(-6, 6)), (130 - c.rng.uniform(0, 30), y + c.rng.uniform(-8, 8))], c.rng.uniform(5, 10), True))
        m = m * sstep(c.noise(6) - 0.25, 0, 0.3)
    else:
        m = c.blob(75, 55, 52, 36, 0.45, 26, 0.12)
        m = np.maximum(m * sstep(c.noise(9) - 0.3, 0, 0.3), _dots(c, [(75 + c.rng.uniform(-62, 62), 55 + c.rng.uniform(-44, 44), c.rng.uniform(1, 3.4)) for _ in range(16)]))
    _stain(c, m, "#3e3426" if not wet else "#2e2820", "#241d16", 0.85, gloss=wet)
    c.paint(m * sstep(c.noise(4) - 0.6, 0, 0.15), "#54483a", 0.5)   # 마른 흙 알갱이


def _hand(c, x, y, ang, s=1.0, fingers=True):
    """손바닥 하나 마스크(손가락 넷 + 엄지)."""
    m = c.blob(x, y, 8.5 * s, 10 * s, 0.15, 5, 0.12, ang)
    ca, sa = np.cos(ang), np.sin(ang)
    if fingers:
        for i, (dx, ln) in enumerate(((-6, 11), (-2, 13), (2.4, 12.5), (6.4, 10))):
            bx, by = x + (dx * ca + 7 * sa) * s, y + (dx * sa - 7 * ca) * s
            tx, ty = bx + sa * ln * s, by - ca * ln * s
            m = np.maximum(m, c.seg([(bx, by), (tx, ty)], 3.6 * s, False))
        tx, ty = x + (-9 * ca - 2 * sa) * s, y + (-9 * sa + 2 * ca) * s
        m = np.maximum(m, c.seg([(tx, ty), (tx - 7 * ca * s, ty - 5 * s)], 3.4 * s, True))
    return m


@flat("handprints", "trace", cell=(110, 96), tags=["dirt", "soot"], name_ko="손자국",
    variants={"soot": {"col": "soot", "seed": 4}, "dust": {"col": "dust", "seed": 7}, "mud": {"col": "mud", "seed": 12, "n": 3}})
def handprints(c, col="soot", n=2, seed=1):
    """바닥 손자국(짚고 일어선 자리)."""
    m = np.zeros((c.H, c.W), F)
    for i in range(n):
        m = np.maximum(m, _hand(c, 30 + i * 32 + c.rng.uniform(-5, 5), 50 + c.rng.uniform(-14, 14), c.rng.uniform(-0.6, 0.6), c.rng.uniform(0.9, 1.1)))
    m = m * (0.55 + 0.45 * c.noise(3))
    color = {"soot": "#1a1614", "dust": "#9a907c", "mud": "#3a2e22"}[col]
    c.paint(m, _tone(c, color, 0.8, 1.1, 4), 0.8 if col != "dust" else 0.55)


@flat("wall_handprints", "trace", layer="wall_decal", cell=(110, 120), tags=["dirt", "soot", "wall"], name_ko="벽 손자국", meta={"mount": "face"},
    variants={"soot": {"col": "soot", "seed": 5}, "dust": {"col": "dust", "seed": 8}, "smear": {"col": "soot", "seed": 16, "smear": True}})
def wall_handprints(c, col="soot", smear=False, seed=1):
    c.origin = (55, 120)   # 벽 밑동
    m = np.zeros((c.H, c.W), F)
    for x, y, a in ((34, 42, -0.25), (70, 56, 0.2)):
        h = _hand(c, x, y, a)
        if smear:   # 미끄러져 내려간 자국
            for k in range(1, 7):
                h = np.maximum(h, np.roll(h, k * 4, 0) * (1 - k / 8))
        m = np.maximum(m, h)
    m = m * (0.6 + 0.4 * c.noise(3))
    c.paint(m, _tone(c, {"soot": "#1c1816", "dust": "#a09680"}[col], 0.8, 1.1, 4), 0.78 if col == "soot" else 0.55)


@flat("spill_stain", "trace", cell=(140, 104), tags=["drink", "inn"], name_ko="쏟은 자국",
    variants={"wine": {"col": "wine", "seed": 6}, "ale": {"col": "ale", "seed": 11}, "oil": {"col": "oil", "seed": 17}, "wine_dried": {"col": "wine", "dry": True, "seed": 23}})
def spill_stain(c, col="wine", dry=False, seed=1):
    m = c.blob(64, 54, 40, 26, 0.4, 20, 0.08, 0.3)
    m = np.maximum(m, c.seg([(90, 60), (112, 72), (128, 70)], 7, True) * sstep(c.noise(5) - 0.2, 0, 0.3))
    m = np.maximum(m, _dots(c, [(64 + c.rng.uniform(-55, 60), 54 + c.rng.uniform(-40, 40), c.rng.uniform(1, 2.6)) for _ in range(10)]))
    base = {"wine": "#4a1822", "ale": "#6a5230", "oil": "#1e1c18"}[col]
    rim = {"wine": "#2a0c12", "ale": "#3e2e18", "oil": "#0e0c0a"}[col]
    _stain(c, m, base if not dry else "#3a2024", rim, 0.7 if col != "oil" else 0.8, gloss=not dry and col != "ale")
    if col == "oil":   # 기름막 무지개 대신 탁한 번들거림
        c.paint(m * sstep(c.noise(9) - 0.55, 0, 0.1), "#4a463c", 0.35)


@flat("wax_drips", "trace", cell=(96, 72), tags=["candle"], name_ko="촛농",
    variants={"a": {"seed": 3}, "pool": {"seed": 8, "pool": True}, "trail": {"seed": 12, "trail": True}})
def wax_drips(c, pool=False, trail=False, seed=1):
    pts = []
    if pool:
        m = c.blob(48, 36, 22, 14, 0.35, 10, 0.1)
    else:
        m = np.zeros((c.H, c.W), F)
    n = 14 if trail else 9
    for i in range(n):
        x = (12 + i * 5.5) if trail else 48 + c.rng.uniform(-38, 38)
        y = (36 + np.sin(i * 0.7) * 8) if trail else 36 + c.rng.uniform(-26, 26)
        pts.append((x, y, c.rng.uniform(1.6, 4.2)))
    m = np.maximum(m, _dots(c, pts))
    c.paint(m, _tone(c, "#c8bc98", 0.85, 1.1, 5))
    c.paint(c.rim(m, 1.2) * 0.6, "#6a604c")
    c.paint(np.roll(m, (-1, -1), (0, 1)) * (1 - m) * 0 + gblur(m, 0.6) * sstep(c.noise(3) - 0.7, 0, 0.1), "#ece2c4", 0.6)


@flat("window_shards", "trace", cell=(150, 96), tags=["glass", "ruin"], name_ko="깨진 창유리 조각",
    variants={"a": {"seed": 5}, "frame": {"seed": 9, "frame": True}, "few": {"seed": 15, "n": 7}})
def window_shards(c, n=16, frame=False, seed=1):
    """창 아래 흩어진 판유리 조각(병 조각보다 넓적하고 각지다) — frame = 부서진 창살 토막도."""
    if frame:
        for a, b in (((20, 30), (82, 22)), ((70, 70), (128, 58)), ((40, 74), (56, 40))):
            mm = c.seg([a, b], 5, False)
            c.paint(mm, _tone(c, "#4a3a2a", 0.8, 1.1, 6))
            c.paint(c.rim(mm, 1.0), "#1a1210", 0.8)
    for _ in range(n):
        x, y, r = 75 + c.rng.normal(0, 30), 48 + c.rng.normal(0, 16), c.rng.uniform(3, 10)
        a = c.rng.uniform(0, 6.28)
        pts = [(x + np.cos(a + t) * r * c.rng.uniform(0.5, 1.2), y + np.sin(a + t) * r * 0.7 * c.rng.uniform(0.5, 1.2)) for t in (0, 2.1, 4.2)]
        m = c.poly(pts)
        c.paint(m, "#5a6a68", 0.55)
        c.paint(c.rim(m, 0.8), "#c8d4d0", 0.7)
        c.paint(m * sstep(c.noise(3) - 0.6, 0, 0.1), "#e0e8e4", 0.6)


@flat("floor_debris", "trace", cell=(170, 120), tags=["ruin", "stone"], name_ko="바닥 파편",
    variants={"tile": {"kind": "tile", "seed": 4}, "plaster": {"kind": "plaster", "seed": 9}, "slate": {"kind": "slate", "seed": 13}})
def floor_debris(c, kind="tile", seed=1):
    """깨진 바닥 타일 · 떨어진 회반죽 · 지붕 슬레이트 조각을 흩은 바닥 자국(밟고 지나간다)."""
    col, rim, n, sz = {"tile": ("#7a5a46", "#2a1e18", 22, (5, 12)), "plaster": ("#a49c88", "#4a443a", 30, (3, 9)), "slate": ("#3e4246", "#141618", 18, (6, 13))}[kind]
    dust = c.blob(85, 60, 70, 46, 0.5, 30, 0.2) * 0.35
    c.paint(dust, "#6a6254" if kind != "slate" else "#4a4844", 0.6)
    for _ in range(n):
        x, y = 85 + c.rng.normal(0, 34), 60 + c.rng.normal(0, 22)
        r = c.rng.uniform(*sz)
        a = c.rng.uniform(0, 6.28)
        k = 4 if kind != "plaster" else 5
        pts = [(x + np.cos(a + t * 6.28 / k) * r * c.rng.uniform(0.6, 1.1), y + np.sin(a + t * 6.28 / k) * r * 0.62 * c.rng.uniform(0.6, 1.1)) for t in range(k)]
        m = c.poly(pts)
        c.paint(m, _tone(c, col, 0.75, 1.2, 4))
        c.paint(c.rim(m, 1.0) * 0.8, rim)
        c.paint(np.roll(m, (-1, -1), (0, 1)) * (1 - np.roll(m, (1, 1), (0, 1))), "#d8ccb0", 0.25)


# ── 서 있는 · 쌓인 것 ─────────────────────────────────────────────────────────

@prop("abandoned_things", "trace", cell=(2, 2), tags=["lost", "street"], name_ko="방치된 물건", interact="search",
    variants={"satchel": {}, "boot": {"state": "boot"}, "bundle": {"state": "bundle"}, "coins": {"state": "coins"}, "bucket": {"state": "bucket"}})
def abandoned_things(k, state="satchel", seed=1):
    if state == "satchel":   # 엎어진 가죽 가방 + 쏟아진 것
        k.add(rough(lambda p: ell(rot_z(p, 0.4), v3(0, 0, 0.09), (0.24, 0.15, 0.1)), 0.02, 0.08, seed), "leather")
        k.add(lambda p: box(rot_z(p, 0.4), v3(0.05, -0.1, 0.12), (0.18, 0.06, 0.06), 0.03), "leather_d")
        k.add(lambda p: cap(p, v3(-0.2, 0.05, 0.04), v3(-0.5, -0.25, 0.02), 0.014), "leather_d")
        _book(k, v3(0.28, -0.2, 0), 0.07, 0.05, 0.016, 0.7, "cloth_r")
        k.add(lambda p: ell(p, v3(-0.05, -0.3, 0.03), (0.06, 0.05, 0.03)), "food")
    elif state == "boot":   # 한 짝만 남은 장화(옆으로 누움)
        k.add(rough(lambda p: smin(cap(rot_y(p, 1.4), v3(0, 0, 0.1), v3(0.0, 0, 0.36), 0.075), ell(p, v3(0.17, -0.02, 0.06), (0.15, 0.07, 0.06)), 0.05), 0.012, 0.08, seed), "leather_d")
        k.add(lambda p: cyl(rot_y(p, 1.4, (-0.03, 0, 0.1)), v3(-0.03, 0, 0.1), 0.07, 0.01), "void")
    elif state == "bundle":   # 끈으로 묶은 천 보따리
        k.add(rough(lambda p: ell(p, v3(0, 0, 0.13), (0.22, 0.17, 0.14)), 0.04, 0.07, seed), "cloth")
        k.add(lambda p: np.minimum(torus(rot_y(p, 1.57, (0, 0, 0.13)), v3(0, 0, 0.13), 0.15, 0.012), torus(rot_x(p, 1.57, (0, 0, 0.13)), v3(0, 0, 0.13), 0.16, 0.012)), "rope")
        k.add(rough(lambda p: ell(p, v3(0.0, 0.0, 0.28), (0.06, 0.05, 0.05)), 0.02, 0.05, seed), "cloth")
    elif state == "coins":   # 찢어진 주머니에서 쏟아진 동전
        k.add(rough(lambda p: ell(p, v3(-0.15, 0.05, 0.06), (0.11, 0.09, 0.07)), 0.03, 0.06, seed), "leather")
        for i in range(14):
            x, y, a = k.rng.uniform(-0.1, 0.4), k.rng.uniform(-0.25, 0.15), k.rng.uniform(-0.6, 0.6)
            k.add(lambda p, x=x, y=y, a=a, i=i: cyl(rot_x(p, a, (x, y, 0.01)), v3(x, y, 0.0 + (i % 3) * 0.008), 0.035, 0.008), "gold")
    else:   # 엎어진 나무 양동이 + 물 자국
        k.add(lambda p: pool(p, (0.14, -0.1, 0.0), 0.24, 0.14), "slime")
        T = lambda p: rot_y(p, 1.45, (0, 0, 0.13))
        k.add(lambda p: sub(_frustum(T(p) - v3(0, 0, 0.0), v3(0, 0, 0.0), 0.12, 0.15, 0.26), _frustum(T(p), v3(0, 0, 0.02), 0.1, 0.13, 0.3)), "plank_y")
        k.add(lambda p: np.minimum(torus(T(p), v3(0, 0, 0.05), 0.125, 0.012), torus(T(p), v3(0, 0, 0.21), 0.145, 0.012)), "iron")
    return {}


from kit import pool  # noqa: E402


@prop("collapsed_shelf", "trace", cell=(3, 3), collide=(1.2, 0.5), tags=["ruin", "wood"], name_ko="무너진 선반",
    variants={"goods": {}, "books": {"state": "books"}, "bare": {"state": "bare"}})
def collapsed_shelf(k, state="goods", seed=1):
    """앞으로 고꾸라진 선반장 + 바닥에 쏟아진 물건."""
    T = lambda p: rot_z(rot_y(p, 1.5, (0.0, 0.0, 0.14)), 0.25)   # 옆으로 쓰러져 누웠다 — 칸판이 세로 칸막이로 보인다
    k.add(lambda p: np.minimum(box(T(p), v3(0, 0.0, 0.0), (0.03, 0.14, 0.62)), box(T(p), v3(0, 0.0, 1.24), (0.03, 0.14, 0.62))), "wood_d")
    k.add(lambda p: np.minimum(box(T(p), v3(-0.5, 0.0, 0.62), (0.03, 0.14, 0.62)), box(T(p), v3(0.5, 0.0, 0.62), (0.03, 0.14, 0.62))) + 0.0, "wood_d")
    k.add(lambda p: box(T(p), v3(0, 0.13, 0.62), (0.5, 0.012, 0.62)), "plank_xd")
    for z in (0.32, 0.64, 0.96):
        k.add(lambda p, z=z: box(T(p), v3(0, 0.0, z), (0.48, 0.13, 0.016)), "plank_x")
    k.add(lambda p: box(rot_z(p, 0.5, (0.65, -0.5, 0)), v3(0.65, -0.5, 0.02), (0.22, 0.06, 0.016)), "plank_x")   # 떨어져 나간 칸판
    r = k.rng
    if state == "goods":
        for i in range(5):
            _bottle(k, r.uniform(-0.55, 0.5), r.uniform(-0.75, -0.45), 0.0, 0.035, 0.08, ("glass", "glass_b", "glass_r")[i % 3], 0.05) if i % 2 else \
                k.add(lambda p, x=r.uniform(-0.6, 0.6), y=r.uniform(-0.8, -0.45): ell(p, v3(x, y, 0.035), (0.07, 0.05, 0.035)), "food")
        k.add(lambda p: cap(p, v3(-0.7, -0.62, 0.03), v3(-0.35, -0.82, 0.03), 0.04), "linen")
    elif state == "books":
        for i in range(7):
            _book(k, v3(r.uniform(-0.6, 0.6), r.uniform(-0.85, -0.45), 0), 0.08, 0.055, 0.018, r.uniform(0, 3), ("cloth_r", "cloth_b", "leather", "cloth_g")[i % 4])
    return {}


@prop("old_door", "trace", cell=(3, 3), tags=["ruin", "wood", "door"], name_ko="낡은 문",
    variants={"leaning": {}, "fallen": {"state": "fallen"}, "boarded": {"state": "boarded"}})
def old_door(k, state="leaning", seed=1):
    """경첩에서 빠진 문짝 한 장(벽에 기댐 · 바닥에 쓰러져 썩음 · 판자를 덧대 못 박음 — 벽에 붙여 세운다)."""
    w, h = 0.36, 1.55
    k.mat("door_rot", __import__("mats").wood("#4a3a2a", 0.13, 2, 11))
    if state == "fallen":
        T = lambda p: rot_x(p, 1.57, (0, 0, 0.0))
        k.add(rough(lambda p: sub(box(T(p) - v3(0, 0, 0), v3(0, -0.03, h / 2), (w, 0.03, h / 2), 0.01), box(T(p), v3(0.15, -0.07, 1.25), (0.12, 0.06, 0.2))), 0.02, 0.06, seed), "door_rot")
        k.add(lambda p: np.minimum(box(T(p), v3(0, -0.075, 0.35), (w - 0.02, 0.015, 0.03)), box(T(p), v3(0, -0.075, 1.15), (w - 0.02, 0.015, 0.03))), "rust")
        k.add(rough(lambda p: ell(p, v3(-0.4, -0.6, 0.02), (0.18, 0.1, 0.03)), 0.03, 0.05, seed), "moss")
        return {"foot": 1.2}
    lean = 0.18 if state == "leaning" else 0.0
    T = lambda p: rot_x(p, -lean, (0, 0.3, 0))
    body = lambda p: box(T(p), v3(0, 0.3, h / 2), (w, 0.03, h / 2), 0.008)
    k.add(rough(lambda p: sub(body(p), box(T(p), v3(-0.18, 0.25, 1.45), (0.1, 0.08, 0.14)) if state == "leaning" else body(p) + 9), 0.012, 0.05, seed), "door_rot")
    k.add(lambda p: np.minimum(box(T(p), v3(0, 0.26, 0.3), (w + 0.01, 0.012, 0.03)), box(T(p), v3(0, 0.26, 1.25), (w + 0.01, 0.012, 0.03))), "rust")
    if state == "boarded":
        for i, (z, a) in enumerate(((0.45, 0.35), (0.95, -0.3), (1.3, 0.1))):
            k.add(lambda p, z=z, a=a: box(rot_y(p, a, (0, 0.24, z)), v3(0, 0.24, z), (w + 0.1, 0.02, 0.06), 0.005), "plank_x")
            for s in (-1, 1):
                k.add(lambda p, z=z, a=a, s=s: sphere(p, v3(s * (w + 0.03) * np.cos(a), 0.21, z - s * (w + 0.03) * np.sin(a)), 0.013), "iron")
    return {"foot": 1.2}


@prop("collapsed_timber", "trace", cell=(4, 3), collide=(2.0, 0.9), tags=["ruin", "wood"], name_ko="무너진 목재 구조물",
    variants={"rafters": {}, "scaffold": {"state": "scaffold"}})
def collapsed_timber(k, state="rafters", seed=1):
    r = k.rng
    beams = [((-1.0, -0.2, 0.06), (0.9, 0.25, 0.06)), ((-0.8, 0.35, 0.05), (0.2, -0.35, 0.5)), ((0.0, 0.4, 0.55), (1.0, -0.3, 0.05)),
             ((-0.4, -0.45, 0.06), (0.6, -0.15, 0.3)), ((-1.1, 0.1, 0.4), (-0.3, -0.4, 0.06))]
    for i, (a, b) in enumerate(beams):
        k.add(rough(lambda p, a=a, b=b: cap(p, v3(*a), v3(*b), 0.07 if state == "rafters" else 0.045), 0.02, 0.1, seed + i), ("wood_d", "wood", "wood_d", "wood_l", "wood")[i])
    if state == "scaffold":   # 가는 장대 + 밧줄 + 판자 발판
        for i in range(3):
            k.add(lambda p, i=i: box(rot_z(p, 0.2 + i * 0.4, (0.2 * i - 0.3, -0.2, 0)), v3(0.2 * i - 0.3, -0.2, 0.03 + i * 0.03), (0.42, 0.08, 0.016), 0.004), "plank_x")
        k.add(lambda p: torus(rot_y(p, 0.6, (-0.1, 0.0, 0.35)), v3(-0.1, 0.0, 0.35), 0.07, 0.014), "rope")
        k.add(lambda p: cap(p, v3(0.6, 0.2, 0.0), v3(0.7, 0.3, 1.1), 0.04), "wood_l")
    else:
        _planks(k, [(r.uniform(-1.0, 1.0), r.uniform(-0.55, -0.2), r.uniform(-1, 1)) for _ in range(5)], "plank_xd", 0.3, seed)
        k.rubble(k.scatter(5, 1.0, 0.25, 0.0, -0.55), "brick", 0.04, 0.08)
    return {}


@prop("trash_heap", "trace", cell=(3, 3), tags=["street", "ruin", "dirt"], name_ko="쓰레기 더미",
    variants={"small": {}, "large": {"big": True}, "rotten": {"rot": True, "seed": 7}})
def trash_heap(k, big=False, rot=False, seed=1):
    s = 1.5 if big else 1.0
    k.add(rough(lambda p: ell(p, v3(0, 0, 0.0), (0.45 * s, 0.32 * s, 0.13 * s)), 0.06, 0.12, seed), "rot" if rot else "dirt")
    r = k.rng
    for i in range(int(9 * s)):   # 넝마 · 깨진 그릇 · 판자 · 뼈다귀
        x, y = r.uniform(-0.4, 0.4) * s, r.uniform(-0.3, 0.2) * s
        z = max(0.0, 0.13 * s * (1 - (x / (0.45 * s)) ** 2 - (y / (0.32 * s)) ** 2)) ** 0.5 * (0.13 * s) ** 0.5 + 0.02
        kind = i % 4
        if kind == 0:
            k.add(rough(lambda p, x=x, y=y, z=z: ell(p, v3(x, y, z), (0.12, 0.08, 0.04)), 0.03, 0.05, seed + i), ("cloth", "cloth_k", "linen")[i % 3])
        elif kind == 1:
            k.add(lambda p, x=x, y=y, z=z: sub(sphere(p, v3(x, y, z + 0.04), 0.07), np.maximum(sphere(p, v3(x, y, z + 0.06), 0.06), p[:, 0] - x)), "bone_d")
        elif kind == 2:
            k.add(lambda p, x=x, y=y, z=z, a=r.uniform(0, 3): box(rot_z(p, a, (x, y, 0)), v3(x, y, z + 0.02), (0.18, 0.04, 0.012)), "plank_xd")
        else:
            k.add(_bone(v3(x - 0.07, y, z + 0.02), v3(x + 0.07, y + 0.03, z + 0.02), 0.014), "bone")
    if rot:   # 파리 떼 대신 검은 점 — 그림 위에 찍는다
        def flies(img, vw):
            pts = [vw.px(r.uniform(-0.3, 0.3), r.uniform(-0.1, 0.1), r.uniform(0.3, 0.55)) for _ in range(9)]
            hh, ww = img.shape[:2]
            yy, xx = np.mgrid[0:hh, 0:ww]
            m = np.zeros((hh, ww), F)
            for x, y in pts:
                m = np.maximum(m, np.clip(1.3 - np.hypot(xx - x, yy - y), 0, 1))
            import fx
            return fx._over(img, m, hexc("#100c0a"))
        return {"post": [flies]}
    return {}


from a_trace import _bone  # noqa: E402


@prop("fallen_plaster", "trace", cell=(3, 3), tags=["ruin", "plaster"], name_ko="무너진 천장 회반죽",
    variants={"heap": {}, "lath": {"lath": True, "seed": 4}})
def fallen_plaster(k, lath=False, seed=1):
    """천장에서 떨어진 회반죽 판 · 외 엮음(나무 살) 토막 + 흰 가루."""
    k.mat("plaster_dust", __import__("mats").plain("#8e877a", 0.3, 0.1, 42))
    k.add(lambda p: pool(p, (0, 0, 0), 0.7, 0.45, 0.008), "plaster_dust")
    k.mat("plaster_chunk", __import__("mats").plain("#b0a890", 0.25, 0.12, 41))
    r = k.rng
    for i in range(9):
        x, y, a, t = r.uniform(-0.6, 0.6), r.uniform(-0.4, 0.35), r.uniform(0, 3), r.uniform(-0.4, 0.4)
        sz = r.uniform(0.08, 0.2)
        k.add(rough(lambda p, x=x, y=y, a=a, t=t, sz=sz: box(rot_y(rot_z(p, a, (x, y, 0)), t, (x, y, 0.03)), v3(x, y, 0.03), (sz, sz * 0.7, 0.025), 0.005), 0.02, 0.06, seed + i), "plaster_chunk")
    if lath:
        for i in range(5):
            x, y, a = r.uniform(-0.5, 0.5), r.uniform(-0.3, 0.3), r.uniform(-0.5, 0.5)
            k.add(lambda p, x=x, y=y, a=a, i=i: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.06 + i * 0.01), (0.35, 0.02, 0.01)), "wood_l")
    return {}
