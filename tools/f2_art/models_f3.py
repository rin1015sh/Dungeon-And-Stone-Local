"""3층 순례자의 길 소품 빚기(tools/f2_art/props.py가 부른다 — 사용자 2026-11-14 "3층 전용 소품 만들어줘").
한 함수 = 한 그림 → (Scene, 재질 표, 덧붙임). 좌표는 칸 단위(sdf.py), 원점 = 발 칸 가운데, z = 위.
가시갈대 둘 · 뒤틀린 덩굴 · 덩굴 감긴 가시나무 · 오크 천막 · 오크 토템 · 가죽 말림대 · 부서진 석상 머리 · 목 없는 석상 · 쓰러진 기둥. [창작]"""
import numpy as np

import mats as M
import sdf
import trees as T
from models_dead import rot_y, rough, rubble
from sdf import Scene, box, cap, cone, cyl, ell, smin, sphere, sub, v3

F = np.float32
MOSS = "#4c5236"


def base_mats():
    return {"straw": M.thatch("#a89058", 0.12, 3), "straw_d": M.plain("#7a6438", 0.3, 0.08), "seed": M.plain("#5e4a2c", 0.35, 0.05),
        "vine": M.bark("#3e3442", "#4a3a52", 11), "vine_d": M.bark("#2c2630", None, 12), "thorn": M.plain("#c8bca8", 0.2),
        "bark": M.bark("#3a3238", None, 13), "hide": M.hide("#7a5e44"), "hide_d": M.hide("#5a4230", 0.6, 14), "wood": M.wood("#5a442e"),
        "wood_d": M.wood("#3e2e20", 0.16, 2, 6), "bone": M.plain("#d4ccb4", 0.2), "red": M.plain("#7a2a22", 0.3), "rope": M.plain("#8a744a", 0.3, 0.05),
        "stone": M.stone("#8a8780", MOSS, 21), "stone_d": M.stone("#6a6862", MOSS, 22), "void": M.void(), "iron": M.metal("#3c3a3a", "#5e4434", 23, 0.4)}


def _stalks(sc, rng, n, h0, h1, spread, mat="straw", head=True, thorns=False):
    """갈대 줄기 n개: 밑동에서 살짝 벌어져 오르고 끝에 이삭, 가시가 돋는다."""
    for k in range(n):
        x, y = rng.normal(0, spread * 0.5), rng.normal(0, spread * 0.3)
        h = rng.uniform(h0, h1)
        lean = v3(rng.uniform(-0.15, 0.15), rng.uniform(-0.1, 0.1), 0)
        a, b = v3(x, y, 0), v3(x, y, h) + lean
        sc.add(lambda p, a=a, b=b: cap(p, a, b, 0.022, 0.01), mat)
        if head:
            c = b + v3(0, 0, 0.12)
            sc.add(lambda p, c=c: ell(p, c, (0.035, 0.035, 0.13)), "seed")
        if thorns:
            for t in (0.35, 0.55, 0.75):
                q = a + (b - a) * t
                d = v3(rng.choice([-1, 1]) * 0.09, 0, 0.05)
                sc.add(lambda p, q=q, d=d: cap(p, q, q + d, 0.012, 0.002), "thorn")
    for k in range(int(n * 0.6)):   # 밑동의 마른 잎
        a, z = rng.uniform(0, 6.28), rng.uniform(0.25, 0.5)
        tip = v3(np.cos(a) * 0.35, np.sin(a) * 0.18, z)
        sc.add(lambda p, tip=tip: cap(p, v3(0, 0, 0.05), tip, 0.03, 0.006), "straw_d")


def reeds():
    """어깨 높이 가시갈대 무더기."""
    sc, m = Scene(), base_mats()
    _stalks(sc, np.random.default_rng(31), 26, 1.35, 1.75, 0.55, thorns=True)
    return sc, m, {}


def reeds_low():
    sc, m = Scene(), base_mats()
    _stalks(sc, np.random.default_rng(32), 18, 0.7, 1.1, 0.5, thorns=True)
    return sc, m, {}


def _vine(sc, rng, base, h, r, curl, seed, mat="vine"):
    """땅에서 솟아 휘감아 오르는 덩굴 한 가닥(촉수처럼 꼬인다) + 가시."""
    pts = []
    a0 = rng.uniform(0, 6.28)
    for k in range(9):
        t = k / 8.0
        ang = a0 + t * curl
        rad = 0.12 + 0.25 * np.sin(t * 3.1)
        pts.append(base + v3(np.cos(ang) * rad, np.sin(ang) * rad * 0.6, t * h))
    for k in range(8):
        ra, rb = r * (1.0 - k / 9.0), r * (1.0 - (k + 1) / 9.0) + 0.006
        sc.add(rough(lambda p, a=pts[k], b=pts[k + 1], ra=ra, rb=rb: cap(p, a, b, ra, rb), 0.02, 0.12, seed + k), mat)
        if k in (2, 4, 6):
            q = pts[k]
            d = v3(rng.uniform(-0.12, 0.12), rng.uniform(-0.05, 0.05), 0.05)
            sc.add(lambda p, q=q, d=d: cap(p, q, q + d, 0.016, 0.002), "thorn")


def vines():
    """살아 움직이는 듯 꼬인 가시덩굴 무더기."""
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(41)
    for k in range(6):
        base = v3(rng.uniform(-0.35, 0.35), rng.uniform(-0.15, 0.2), 0)
        _vine(sc, rng, base, rng.uniform(0.8, 1.6), rng.uniform(0.06, 0.1), rng.uniform(3.0, 6.0), 400 + k * 9, "vine" if k % 2 else "vine_d")
    sc.add(rough(lambda p: ell(p, v3(0, 0.02, 0.05), (0.55, 0.32, 0.14)), 0.06, 0.1, 7), "vine_d")   # 뿌리 엉킴
    return sc, m, {}


def vine_tree():
    """덩굴이 휘감은 마른 가시나무."""
    sc, m = Scene(), base_mats()
    rng = np.random.default_rng(51)
    base = v3(0, 0.15, 0)
    segs, tips = T.limbs(rng, base, 1.8, 0.14, 4, 0.45, 0.5, 0.45, 0.75)
    segs += T.roots(rng, base, 0.15, 5, 1.6)
    sc.add(T.trunk_fn(segs, 51), "bark")
    tw = T.twig_fn(segs)
    if tw is not None:
        sc.add(tw, "bark")
    for k in range(3):
        _vine(sc, rng, base + v3(rng.uniform(-0.1, 0.1), 0, 0), rng.uniform(1.2, 1.7), 0.05, 7.0 + k, 500 + k * 7, "vine")
    return sc, m, {"far": 9.0}


def orc_tent():
    """오크 천막: 굵은 장대에 짐승 가죽을 덮고 엄니 · 뼈 · 붉은 천을 단다."""
    sc, m = Scene(), base_mats()
    c = v3(0, 0.25, 0)
    body = lambda p: sub(cone(p, c + v3(0, 0, 0.02), 0.95, 1.7), np.maximum(box(p, c + v3(0, -0.55, 0.3), (0.22, 0.5, 0.35)), -cone(p, c, 0.95, 1.7) - 0.05))
    sc.add(lambda p: body(p) + (sdf.fbm(p, 0.16, 3, 2) - 0.5) * 0.05 + np.sin(np.arctan2(p[:, 1] - 0.25, p[:, 0]) * 9.0) * 0.012, "hide")
    sc.add(lambda p: sub(cone(p, c + v3(0, 0, 0.02), 0.97, 1.7), cone(p, c + v3(0, 0, 0.12), 0.97, 1.7)) + np.maximum(0.0, 1.0 - p[:, 2]) * 9.0, "hide_d")   # 아랫단 다른 가죽
    sc.add(lambda p: box(p, c + v3(0, -0.52, 0.3), (0.2, 0.05, 0.3)), "void")   # 문
    for a in (0.6, 2.0, 3.6, 5.0):   # 꼭대기에 삐져나온 장대
        tip = c + v3(np.cos(a) * 0.25, np.sin(a) * 0.2, 2.15)
        sc.add(lambda p, tip=tip: cap(p, c + v3(0, 0, 1.4), tip, 0.04, 0.03), "wood_d")
    for sx in (-1, 1):   # 문 옆 엄니
        sc.add(lambda p, sx=sx: smin(cap(p, c + v3(sx * 0.3, -0.62, 0), c + v3(sx * 0.34, -0.7, 0.45), 0.05, 0.03), cap(p, c + v3(sx * 0.34, -0.7, 0.45), c + v3(sx * 0.24, -0.74, 0.62), 0.03, 0.006), 0.03), "bone")
    sc.add(lambda p: box(p, c + v3(0.42, -0.44, 0.75), (0.12, 0.012, 0.22), 0.01) + np.sin(p[:, 2] * 18.0) * 0.006, "red")
    return sc, m, {"scale": 0.8}


def orc_totem():
    """오크 토템: 굵은 통나무에 멧돼지 해골 · 큰 뿔 · 붉은 손자국 천 · 매단 뼈."""
    sc, m = Scene(), base_mats()
    sc.add(rough(lambda p: cap(p, v3(0, 0, 0), v3(0.02, 0, 2.0), 0.14, 0.11), 0.03, 0.2, 3), "wood_d")
    for z in (0.5, 0.9, 1.3):   # 새긴 홈
        sc.add(lambda p, z=z: cyl(p, v3(0.0, 0, z), 0.155, 0.03, 0.01), "red")
    skull = lambda p: smin(ell(p, v3(0.02, -0.12, 2.05), (0.24, 0.2, 0.2)), ell(p, v3(0.02, -0.3, 1.94), (0.12, 0.18, 0.11)), 0.06)
    eyes = lambda p: np.minimum(sphere(p, v3(-0.09, -0.27, 2.08), 0.05), sphere(p, v3(0.13, -0.27, 2.08), 0.05))
    sc.add(lambda p: sub(skull(p), eyes(p)), "bone")
    for sx in (-1, 1):   # 엄니 · 큰 뿔
        sc.add(lambda p, sx=sx: cap(p, v3(0.02 + sx * 0.1, -0.42, 1.9), v3(0.02 + sx * 0.17, -0.46, 2.08), 0.035, 0.008), "bone")
        sc.add(lambda p, sx=sx: smin(cap(p, v3(0.02 + sx * 0.18, -0.06, 2.18), v3(0.02 + sx * 0.5, -0.02, 2.32), 0.06, 0.04), cap(p, v3(0.02 + sx * 0.5, -0.02, 2.32), v3(0.02 + sx * 0.56, -0.05, 2.62), 0.04, 0.01), 0.04), "bone")
    sc.add(lambda p: box(p, v3(0.0, -0.16, 1.45), (0.22, 0.012, 0.28), 0.01) + np.sin(p[:, 0] * 16.0) * 0.006, "red")
    for x, ln in ((-0.18, 0.35), (0.2, 0.45)):   # 매단 뼈
        sc.add(lambda p, x=x, ln=ln: cap(p, v3(x, -0.15, 1.75), v3(x, -0.15, 1.75 - ln), 0.008), "rope")
        sc.add(lambda p, x=x, ln=ln: ell(p, v3(x, -0.15, 1.72 - ln), (0.04, 0.03, 0.08)), "bone")
    return sc, m, {}


def hide_rack():
    """가죽 말림대: 두 장대 + 가로대에 펼친 가죽."""
    sc, m = Scene(), base_mats()
    for x in (-0.55, 0.55):
        sc.add(rough(lambda p, x=x: cap(p, v3(x, 0, 0), v3(x * 0.95, 0, 1.55), 0.05, 0.04), 0.015, 0.2), "wood_d")
    sc.add(lambda p: cap(p, v3(-0.6, 0, 1.45), v3(0.6, 0, 1.48), 0.04), "wood_d")
    for x, w, ln, mat in ((-0.27, 0.22, 0.9, "hide"), (0.25, 0.24, 1.05, "hide_d")):
        sc.add(lambda p, x=x, w=w, ln=ln: box(p, v3(x, -0.02, 1.42 - ln / 2), (w, 0.015, ln / 2), 0.02) + np.sin(p[:, 2] * 7.0 + x * 9.0) * 0.012
               + (sdf.fbm(p, 0.1, 4, 2) - 0.5) * 0.02, mat)
        sc.add(lambda p, x=x: cap(p, v3(x - 0.15, -0.02, 1.45), v3(x + 0.15, -0.02, 1.45), 0.012), "rope")
    return sc, m, {}


def statue_head():
    """목이 부러진 석상의 머리: 옆으로 누운 돌 얼굴(이마 · 코 · 감은 눈) + 부서진 목 단면 + 돌 부스러기."""
    sc, m = Scene(), base_mats()
    c = v3(0, 0.05, 0.32)
    q = lambda p: rot_y(p, c, 1.35)   # 옆으로 눕힌다
    head = lambda p: smin(ell(q(p), c, (0.3, 0.34, 0.4)), ell(q(p), c + v3(0, -0.33, -0.04), (0.08, 0.13, 0.15)), 0.05)   # 머리 + 코
    brow = lambda p: smin(ell(q(p), c + v3(0, -0.29, 0.12), (0.26, 0.08, 0.06)), ell(q(p), c + v3(0, -0.27, -0.2), (0.13, 0.08, 0.06)), 0.04)   # 이마 · 턱
    neck = lambda p: np.maximum(cyl(q(p), c + v3(0, 0.02, -0.55), 0.17, 0.25, 0.02), q(p)[:, 2] - c[2] + 0.28)
    sc.add(rough(lambda p: smin(smin(head(p), brow(p), 0.03), neck(p), 0.06), 0.035, 0.15, 5), "stone")
    sc.add(lambda p: np.maximum(cyl(q(p), c + v3(0, 0.02, -0.56), 0.165, 0.02), -1.0), "stone_d")   # 부러진 단면
    for sx in (-1, 1):
        sc.add(lambda p, sx=sx: ell(q(p), c + v3(sx * 0.12, -0.31, 0.04), (0.07, 0.03, 0.03)), "stone_d")   # 감은 눈
    rubble(sc, [(-0.45, 0.25), (0.42, -0.1), (0.25, 0.32)], 61, "stone_d")
    return sc, m, {}


def headless():
    """목 없는 석상: 받침돌 위 두 손을 모은 옷자락 상, 목에서 부러졌다."""
    sc, m = Scene(), base_mats()
    y = 0.3
    sc.add(rough(lambda p: np.minimum(box(p, v3(0, y, 0.12), (0.5, 0.42, 0.12), 0.03), box(p, v3(0, y, 0.4), (0.38, 0.32, 0.18), 0.03)), 0.03, 0.2, 2), "stone_d")
    robe = lambda p: smin(cone(p, v3(0, y, 0.55), 0.36, 1.35), ell(p, v3(0, y, 1.55), (0.3, 0.2, 0.32)), 0.12)
    folds = lambda p: np.sin(np.arctan2(p[:, 1] - y, p[:, 0]) * 11.0) * 0.012 * np.clip(1.4 - p[:, 2], 0, 1)
    hands = lambda p: smin(ell(p, v3(0, y - 0.2, 1.35), (0.13, 0.09, 0.1)), cap(p, v3(-0.26, y - 0.05, 1.65), v3(-0.05, y - 0.18, 1.38), 0.07), 0.05)
    hands2 = lambda p: cap(p, v3(0.26, y - 0.05, 1.65), v3(0.05, y - 0.18, 1.38), 0.07)
    neck = lambda p: np.maximum(cyl(p, v3(0, y, 1.8), 0.11, 0.1, 0.01), p[:, 2] - 1.93 + p[:, 0] * 0.25)   # 비스듬히 부러진 목
    sc.add(rough(lambda p: smin(smin(robe(p) + folds(p), np.minimum(hands(p), hands2(p)), 0.04), neck(p), 0.04), 0.03, 0.18, 4), "stone")
    rubble(sc, [(-0.55, -0.05), (0.5, 0.0)], 71, "stone_d")
    return sc, m, {"scale": 1.0}


def column():
    """쓰러진 사원 기둥 토막(홈 파인 둥근 기둥) + 받침 + 부스러기."""
    sc, m = Scene(), base_mats()
    a, b = v3(-0.7, 0.18, 0.2), v3(0.6, -0.05, 0.2)
    ax = (b - a) / np.sqrt(((b - a) ** 2).sum())
    flutes = lambda p: np.sin(np.arctan2(p[:, 2] - 0.2, p[:, 1]) * 14.0) * 0.012
    sc.add(rough(lambda p: np.maximum(cap(p, a, b, 0.2, 0.19) + flutes(p), np.abs((p - (a + b) * 0.5) @ ax) - 0.66), 0.03, 0.15, 8), "stone")
    sc.add(rough(lambda p: box(p, v3(0.62, -0.2, 0.12), (0.26, 0.26, 0.12), 0.02), 0.04, 0.2, 9), "stone_d")
    rubble(sc, [(-0.2, -0.3), (0.1, 0.38), (-0.6, -0.15)], 81, "stone_d")
    return sc, m, {}


BIG = {}
STAND = {"f3a_reeds": reeds, "f3a_reeds_low": reeds_low, "f3a_vines": vines, "f3a_vine_tree": vine_tree, "f3a_orc_tent": orc_tent,
    "f3a_orc_totem": orc_totem, "f3a_hide_rack": hide_rack, "f3a_head": statue_head, "f3a_headless": headless, "f3a_column": column}
