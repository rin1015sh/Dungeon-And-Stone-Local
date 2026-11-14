"""상점(잡화점) 전용 물건: 상점 카운터 · 계단식 진열대 · 상품 선반 · 약재 서랍장 · 상품 상자 · 걸린 말린 고기 · 빵과 치즈 판 · 곡물 통 ·
물약 꽂이 · 약초 다발 · 약초 쟁반 · 걸린 가방 · 밧줄 타래 · 연장 묶음 · 연장 걸이판 · 탐험 장비 진열대 · 저울 · 가격표 · 장부 · 돈통 · 꾸러미 · 횃불 통.
진열된 물건은 게임이 실제로 파는 종류(식량 · 물약 · 약초 · 가방 · 랜턴 · 밧줄 · 도구 · 횃불)를 뭉뚱그려 그린 것이다 — 새 아이템을 뜻하지 않는다.
공용 가구(나무 상자 · 나무통 · 자루 · 바구니 · 병 · 배낭 · 랜턴 · 벽 선반)는 a_furniture · a_light의 것을 그대로 쓴다."""
import numpy as np

import sdf
from kit import (F, box, cap, cone, cyl, disc_x, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M
from a_furniture import _X, _barrel, _book, _bottle, _candle, _case, _crate, _flask, _frustum, _move, _open_book, _page_mat, _sack, _table

PI = np.pi


def many(fns):
    """같은 재질의 작은 덩어리 여럿을 한 덩어리로(그리는 값이 싸다)."""
    return lambda p: np.minimum.reduce([f(p) for f in fns])


def goods_mats(k):
    k.mat("bread", M.plain("#8a6238", 0.35, 0.05, 41))
    k.mat("cheese", M.plain("#b09a50", 0.2, 0.08, 42))
    k.mat("meat", M.plain("#6a3028", 0.4, 0.05, 43))
    k.mat("fat", M.plain("#a08a70", 0.3, 0.05, 44))
    k.mat("apple", M.plain("#7a3a2c", 0.45, 0.04, 45))
    k.mat("root", M.plain("#8a7a5a", 0.4, 0.04, 46))
    k.mat("jar", M.plain("#7a6a54", 0.25, 0.08, 47))
    k.mat("herb", M.leaf("#56603a", 0.06, 48, 0.05))
    k.mat("herb_dry", M.leaf("#7a6c40", 0.06, 49, 0.04))
    k.mat("herb_v", M.leaf("#5a4a62", 0.06, 50, 0.02))
    k.mat("straw", M.thatch("#8a7440", 0.05))
    k.mat("board_k", M.plain("#262826", 0.2, 0.1, 51))
    k.mat("velvet", M.plain("#4a1c2a", 0.25, 0.1, 52))
    k.mat("silver", M.metal("#9a9ea0", "#5a5a58", 53, 0.12))


def loaf(x, y, z, a=0.0, s=1.0):
    return lambda p: ell(rot_z(p, a, (x, y, z)), v3(x, y, z + 0.035 * s), (0.085 * s, 0.05 * s, 0.04 * s))


def wheel(x, y, z, r=0.07, h=0.045):
    """치즈 덩이(한 조각 잘라 낸)."""
    return lambda p: np.maximum(cyl(p, v3(x, y, z), r, h, 0.008), -np.maximum(p[:, 0] - x - 0.012 + (p[:, 1] - y) * 0.9, -(p[:, 1] - y) - 0.004) * 0 - np.minimum(p[:, 0] - x - 0.01, -(p[:, 1] - y) + 0.0))


def heap(x, y, z, rx, ry, n, r, seed):
    """알갱이 무더기(사과 · 뿌리): 낮은 둔덕 위에 구슬을 얹는다."""
    rng = np.random.default_rng(seed)
    pts = [(x + rng.uniform(-rx, rx) * 0.8, y + rng.uniform(-ry, ry) * 0.8, z + r * 0.7 + rng.uniform(0, r * 0.8)) for _ in range(n)]
    return lambda p: np.minimum(ell(p, v3(x, y, z), (rx, ry, r)), np.minimum.reduce([sphere(p, v3(*q), r) for q in pts]))


def coil(x, y, z, R=0.12, r=0.022, n=3):
    """누운 밧줄 타래(고리를 쌓았다)."""
    return lambda p: np.minimum.reduce([torus(p, v3(x, y, z + r + i * r * 1.7), R - i * 0.006, r) for i in range(n)])


def coil_x(x, y, z, R=0.1, r=0.02):
    """걸린 밧줄 타래(화면을 마주 본다)."""
    return lambda p: np.minimum(ring_x(p, v3(x, y, z), R, r), ring_x(p, v3(x, y - r * 1.2, z - 0.01), R - 0.012, r))


def jar(t, x, y, z, r=0.055, h=0.11, lid="cloth"):
    t.add(lambda p: cyl(p, v3(x, y, z), r, h, 0.015), "jar")
    t.add(lambda p: cyl(p, v3(x, y, z + h), r * 1.08, 0.018, 0.005), lid)


def coins(x, y, z, r=0.022, hs=(0.05,), dx=0.05):
    """동전 기둥 줄."""
    return lambda p: np.minimum.reduce([cyl(p, v3(x + i * dx, y + (i % 2) * 0.012, z), r, h, 0.003) + np.sin(p[:, 2] * 520.0) * 0.0012 for i, h in enumerate(hs)])


def scale_parts(t, c, s=1.0, tilt=0.0, mat="brass"):
    """양팔저울: 받침 · 기둥 · 들보 · 접시 둘. → 접시 가운데 (왼쪽, 오른쪽) 점."""
    x, y, z = c
    hb = 0.3 * s
    arm = 0.17 * s
    t.add(lambda p: smin(cyl(p, v3(x, y, z), 0.075 * s, 0.022 * s, 0.006), cap(p, v3(x, y, z + 0.02 * s), v3(x, y, z + hb), 0.016 * s, 0.01 * s), 0.02 * s), mat)
    T = lambda p: rot_y(p, tilt, (x, y, z + hb))
    t.add(lambda p: np.minimum(hcyl(T(p), v3(x - arm, y, z + hb), v3(x + arm, y, z + hb), 0.009 * s), sphere(p, v3(x, y, z + hb + 0.012 * s), 0.02 * s)), mat)
    out = []
    for sx in (-1, 1):
        dz = -sx * np.sin(tilt) * arm
        px, pz = x + sx * arm * np.cos(tilt), z + hb + dz
        zp = pz - 0.17 * s
        t.add(lambda p, px=px, pz=pz, zp=zp: np.minimum(cap(p, v3(px, y, pz), v3(px - 0.05 * s, y, zp + 0.02 * s), 0.005 * s), cap(p, v3(px, y, pz), v3(px + 0.05 * s, y, zp + 0.02 * s), 0.005 * s)), "iron")
        t.add(lambda p, px=px, zp=zp: sub(_frustum(p, v3(px, y, zp), 0.04 * s, 0.065 * s, 0.025 * s), _frustum(p, v3(px, y, zp + 0.008 * s), 0.035 * s, 0.06 * s, 0.03 * s)), mat)
        out.append(v3(px, y, zp + 0.01 * s))
    return out


def weights(x, y, z, n=3):
    return lambda p: np.minimum.reduce([smin(cyl(p, v3(x + i * 0.045, y, z), 0.02 - i * 0.004, 0.035 - i * 0.008, 0.004), sphere(p, v3(x + i * 0.045, y, z + 0.042 - i * 0.008), 0.008), 0.006) for i in range(n)])


def ledger_closed(t, c, a=0.0, mat="leather_d", s=1.0):
    _book(t, c, 0.13 * s, 0.095 * s, 0.035 * s, a, mat)
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: np.minimum(box(T(p), v3(c[0] + 0.11 * s, c[1] - 0.075 * s, c[2] + 0.035 * s), (0.022 * s, 0.022 * s, 0.037 * s), 0.004),
        box(T(p), v3(c[0] + 0.11 * s, c[1] + 0.075 * s, c[2] + 0.035 * s), (0.022 * s, 0.022 * s, 0.037 * s), 0.004)), "brass")


def inkpot(t, x, y, z):
    t.add(lambda p: cyl(p, v3(x, y, z), 0.03, 0.045, 0.01), "glass_b")
    t.add(lambda p: cap(p, v3(x, y, z + 0.04), v3(x + 0.08, y + 0.05, z + 0.22), 0.005, 0.018), "linen")


def tag(x, y, z, s=1.0):
    """끈에 달린 작은 꼬리표(앞을 본다)."""
    return lambda p: np.minimum(box(p, v3(x, y, z - 0.05 * s), (0.028 * s, 0.004, 0.035 * s), 0.003), cap(p, v3(x, y, z), v3(x, y, z - 0.02 * s), 0.004))


# ── 카운터 · 진열 ─────────────────────────────────────────────────────────────

def counter_body(k, w, d, h, seed=1, top="plank_x", body="wood", frame="wood_d"):
    k.add(rough(lambda p: box(p, v3(0, 0.01, (h - 0.04) / 2), (w - 0.04, d - 0.04, (h - 0.04) / 2), 0.008), 0.008, 0.2, seed), body)
    k.add(rough(lambda p: box(p, v3(0, -0.02, h - 0.02), (w, d + 0.02, 0.022), 0.01), 0.008, 0.2, seed + 1), top)
    k.add(many([lambda p, sx=sx: box(p, v3(sx * (w - 0.045), -d + 0.045, (h - 0.04) / 2), (0.04, 0.04, (h - 0.04) / 2), 0.006) for sx in (-1, 0, 1)]
        + [lambda p: box(p, v3(0, -d + 0.04, 0.035), (w - 0.03, 0.03, 0.035), 0.006), lambda p: box(p, v3(0, -d + 0.04, h - 0.085), (w - 0.03, 0.03, 0.03), 0.006)]), frame)


@prop("shop_counter", "shop", cell=(4, 3), collide=(1.7, 0.6), tags=["wood", "shop", "counter"], name_ko="상점 카운터", interact="counter",
    variants={"tidy": {}, "busy": {"state": "busy"}, "closed": {"state": "closed"}})
def shop_counter(k, state="tidy", seed=1):
    """상인 카운터: 앞판에 물건 걸이(가죽 주머니 · 밧줄 타래 · 꼬리표), 위에는 저울 · 장부 · 동전 접시. closed = 천을 덮어 둔 빈 카운터."""
    goods_mats(k)
    w, d, h = 0.82, 0.27, 0.6
    counter_body(k, w, d, h, seed)
    yf = -d + 0.0
    k.add(many([lambda p, x=x: cap(p, v3(x, yf + 0.01, h - 0.16), v3(x, yf - 0.035, h - 0.15), 0.008) for x in (-0.6, -0.22, 0.2, 0.58)]), "brass")
    k.add(rough(lambda p: smin(ell(p, v3(-0.6, yf - 0.04, h - 0.3), (0.075, 0.04, 0.09)), cap(p, v3(-0.6, yf - 0.035, h - 0.15), v3(-0.6, yf - 0.035, h - 0.22), 0.012), 0.03), 0.015, 0.06, seed), "leather")
    k.add(coil_x(-0.22, yf - 0.035, h - 0.26, 0.085, 0.017), "rope")
    k.add(rough(lambda p: smin(ell(p, v3(0.2, yf - 0.04, h - 0.29), (0.06, 0.035, 0.075)), cap(p, v3(0.2, yf - 0.035, h - 0.15), v3(0.2, yf - 0.035, h - 0.2), 0.01), 0.03), 0.015, 0.06, seed + 2), "cloth")
    k.add(many([tag(0.58, yf - 0.035, h - 0.15), tag(0.5, yf - 0.03, h - 0.17, 0.9)]), "paper")
    if state == "closed":
        cover = lambda p: smin(box(p, v3(0.05, -0.03, h + 0.03), (w * 0.82, d + 0.02, 0.03), 0.03), smin(ell(p, v3(-0.3, 0.0, h + 0.07), (0.16, 0.12, 0.1)), ell(p, v3(0.35, 0.02, h + 0.05), (0.2, 0.12, 0.07)), 0.08), 0.06)
        k.add(rough(lambda p: np.minimum(cover(p), box(p, v3(0.05, -d - 0.045, h - 0.1), (w * 0.8, 0.012, 0.14), 0.01) + np.sin(p[:, 0] * 26.0) * 0.008) + np.sin(p[:, 0] * 17.0 + p[:, 1] * 9.0) * 0.004, 0.02, 0.15, seed + 3), "linen")
        return {}
    scale_parts(k, v3(-0.5, 0.03, h), 0.9, 0.0 if state == "tidy" else 0.22)
    ledger_closed(k, v3(0.05, -0.02, h), 0.08) if state == "tidy" else None
    k.add(lambda p: sub(box(p, v3(0.5, -0.04, h + 0.015), (0.12, 0.085, 0.015), 0.006), box(p, v3(0.5, -0.04, h + 0.03), (0.105, 0.07, 0.02))), "wood_d")
    k.add(coins(0.43, -0.05, h + 0.012, 0.02, (0.03, 0.045, 0.02, 0.035), 0.045), "gold")
    if state == "busy":
        _open_book(k, v3(0.02, -0.04, h), 0.95, 0.06)
        inkpot(k, 0.26, 0.1, h)
        k.add(weights(-0.33, -0.12, h), "iron")
        k.add(lambda p: sphere(p, v3(-0.345, 0.03, h + 0.15), 0.035), "apple")
        _flask(k, 0.72, 0.08, h, 0.05, "glass_r")
        _bottle(k, 0.62, 0.12, h, 0.03, 0.08, "glass", 0.06)
        k.add(rough(lambda p: box(rot_z(p, 0.3, (-0.72, -0.08, 0)), v3(-0.72, -0.08, h + 0.05), (0.08, 0.06, 0.05), 0.015), 0.01, 0.1, seed), "paper")
        k.add(lambda p: np.minimum(box(rot_z(p, 0.3, (-0.72, -0.08, 0)), v3(-0.72, -0.08, h + 0.05), (0.084, 0.008, 0.054)), box(rot_z(p, 0.3, (-0.72, -0.08, 0)), v3(-0.72, -0.08, h + 0.05), (0.008, 0.064, 0.054))), "rope")
    return {}


@prop("goods_stand", "shop", cell=(3, 3), collide=(1.3, 0.75), tags=["wood", "shop", "display"], name_ko="계단식 상품 진열대", interact="container",
    variants={"food": {}, "potions": {"state": "potions"}, "mixed": {"state": "mixed"}, "empty": {"state": "empty"}})
def goods_stand(k, state="food", seed=1):
    """뒤로 갈수록 높아지는 세 단 진열대 — 단마다 물건이 한눈에 보인다."""
    goods_mats(k)
    w = 0.6
    tiers = [(-0.22, 0.24), (0.0, 0.5), (0.22, 0.76)]   # (단 가운데 y, 윗면 z)
    for y, z in tiers:
        k.add(rough(lambda p, y=y, z=z: box(p, v3(0, y, z - 0.018), (w, 0.115, 0.018), 0.006), 0.008, 0.2, seed), "plank_x")
        k.add(lambda p, y=y, z=z: box(p, v3(0, y - 0.105, z + 0.012), (w, 0.01, 0.024), 0.004), "wood_d")
    side = lambda p, sx: np.maximum(box(p, v3(sx * (w - 0.02), 0.0, 0.38), (0.025, 0.34, 0.38), 0.006), p[:, 2] - 0.5 - p[:, 1] * 1.18 - 0.02)
    k.add(many([lambda p: side(p, -1), lambda p: side(p, 1), lambda p: box(p, v3(0, 0.33, 0.38), (w - 0.02, 0.012, 0.38))]), "wood_d")
    if state == "empty":
        return {}
    (y0, z0), (y1, z1), (y2, z2) = tiers
    if state in ("food", "mixed"):
        k.add(many([loaf(-0.42, y0, z0, 0.3), loaf(-0.22, y0 + 0.01, z0, -0.2), loaf(-0.33, y0, z0 + 0.06, 0.1, 0.9)]), "bread")
        k.add(sub_bowl(0.3, y0, z0, 0.13), "wood_l")
        k.add(heap(0.3, y0, z0 + 0.03, 0.09, 0.07, 9, 0.032, seed), "apple")
        k.add(many([wheel(-0.4, y1, z1, 0.075, 0.05), wheel(-0.22, y1 + 0.01, z1, 0.06, 0.04), lambda p: cyl(p, v3(-0.39, y1, z1 + 0.05), 0.06, 0.04, 0.008)]), "cheese")
    if state == "food":
        k.add(sub_bowl(0.0, y0, z0, 0.11), "wood_l")
        k.add(heap(0.0, y0, z0 + 0.03, 0.075, 0.06, 8, 0.028, seed + 3), "root")
        jar(k, 0.1, y1, z1, 0.06, 0.12)
        jar(k, 0.26, y1, z1, 0.05, 0.1, "leather")
        jar(k, 0.42, y1, z1, 0.06, 0.13)
        k.add(many([lambda p, x=x: ell(p, v3(x, y2, z2 + 0.06), (0.04, 0.035, 0.07)) for x in (-0.44, -0.33, -0.22)]), "meat")
        _sack(k, v3(0.3, y2 - 0.02, z2), 0.55, seed, "linen")
        _sack(k, v3(0.05, y2 - 0.02, z2), 0.5, seed + 1)
    if state in ("potions", "mixed"):
        xs = (-0.46, -0.3, -0.14, 0.02, 0.18, 0.34, 0.48) if state == "potions" else (0.06, 0.22, 0.4)
        for i, x in enumerate(xs):
            _flask(k, x, y2 - 0.02, z2, 0.052, ("glass_r", "glass_b", "glass")[i % 3])
        if state == "potions":
            for i, x in enumerate((-0.45, -0.3, -0.12, 0.1, 0.3, 0.46)):
                _bottle(k, x, y1, z1, 0.032, 0.09, ("glass", "glass_b", "glass_r")[i % 3], 0.06)
            for i, x in enumerate((-0.4, -0.18, 0.28)):
                _flask(k, x, y0, z0, 0.06, ("glass_b", "glass_r", "glass")[i])
            jar(k, 0.05, y0, z0, 0.05, 0.09)
            k.add(many([tag(-0.4, y0 - 0.12, z0 + 0.0, 0.8), tag(0.28, y0 - 0.12, z0, 0.8)]), "paper")
        else:
            k.add(coil(0.2, y1, z1, 0.1, 0.02, 3), "rope")
            _candle(k, 0.42, y1, z1, 0.09, 0.018)
            _candle(k, 0.47, y1 + 0.03, z1, 0.09, 0.018)
            k.add(rough(lambda p: ell(p, v3(-0.3, y2, z2 + 0.07), (0.1, 0.06, 0.08)), 0.015, 0.06, seed), "leather")
            k.add(lambda p: box(p, v3(-0.3, y2 - 0.055, z2 + 0.09), (0.06, 0.01, 0.04), 0.01), "leather_d")
    return {}


def sub_bowl(x, y, z, r):
    return lambda p: sub(_frustum(p, v3(x, y, z), r * 0.65, r, 0.05), _frustum(p, v3(x, y, z + 0.015), r * 0.55, r * 0.9, 0.06))


@prop("goods_shelf", "shop", cell=(3, 4), collide=(1.4, 0.45), tags=["wood", "shop", "display", "storage"], name_ko="상품 선반", interact="container",
    variants={"provisions": {}, "potions": {"state": "potions"}, "hardware": {"state": "hardware"}, "sparse": {"state": "sparse"}, "empty": {"state": "empty"}})
def goods_shelf(k, state="provisions", seed=1):
    """벽에 붙여 세우는 키 큰 상품 선반(밝은 나무 · 칸막이 · 선반 턱) — 책장과 달리 물건이 칸마다 다르다."""
    goods_mats(k)
    w, d, h = 0.66, 0.19, 1.66
    zs = (0.1, 0.5, 0.88, 1.26)
    _case(k, w, d, h, zs, seed, "wood", "wood_l")
    k.add(many([lambda p, z=z: box(p, v3(0, -d + 0.012, z + 0.03), (w - 0.03, 0.01, 0.022), 0.004) for z in zs] + [lambda p: box(p, v3(0, -0.02, h + 0.02), (w + 0.03, d + 0.02, 0.025), 0.008)]), "wood_d")
    if state == "empty":
        return {}
    y = -0.03
    z0, z1, z2, z3 = [z + 0.016 for z in zs]
    if state == "provisions":
        _sack(k, v3(-0.4, y, z0), 0.72, seed)
        _sack(k, v3(0.0, y, z0), 0.68, seed + 1, "linen")
        _sack(k, v3(0.4, y, z0), 0.7, seed + 2)
        for i, x in enumerate((-0.5, -0.33, -0.16)):
            jar(k, x, y, z1, 0.065, 0.17, ("cloth", "leather", "cloth")[i])
        k.add(many([wheel(0.15, y, z1, 0.085, 0.06), lambda p: cyl(p, v3(0.16, y, z1 + 0.06), 0.075, 0.05, 0.01), wheel(0.42, y, z1, 0.08, 0.055)]), "cheese")
        k.add(many([loaf(-0.44, y, z2, 0.2, 1.1), loaf(-0.2, y, z2, -0.15, 1.1), loaf(-0.32, y, z2 + 0.07, 0.05), loaf(0.04, y, z2, 0.4, 1.0)]), "bread")
        k.add(sub_bowl(0.38, y, z2, 0.14), "wood_l")
        k.add(heap(0.38, y, z2 + 0.03, 0.1, 0.07, 9, 0.034, seed), "apple")
        k.add(many([lambda p, x=x: cap(p, v3(x, y, z3 + 0.3), v3(x + 0.01, y, z3 + 0.08), 0.03, 0.036) for x in (-0.46, -0.34, -0.22)]), "meat")
        k.add(many([lambda p, x=x: cap(p, v3(x, y, z3 + 0.34), v3(x, y, z3 + 0.3), 0.006) for x in (-0.46, -0.34, -0.22)]), "rope")
        for i, x in enumerate((0.1, 0.28, 0.46)):
            _bottle(k, x, y, z3, 0.04, 0.14, ("glass", "glass", "glass_b")[i], 0.09)
    elif state == "potions":
        for zi, z in enumerate((z1, z2, z3)):
            n = (6, 7, 5)[zi]
            for i in range(n):
                x = -0.5 + i * (1.0 / (n - 1))
                m = ("glass_r", "glass_b", "glass", "glass_r", "glass")[(i + zi * 2) % 5]
                if (i + zi) % 3 == 0:
                    _bottle(k, x, y, z, 0.036, 0.12, m, 0.08)
                else:
                    _flask(k, x, y, z, 0.058, m)
        for i, x in enumerate((-0.46, -0.26, -0.06)):
            jar(k, x, y, z0, 0.075, 0.2, ("cloth", "leather", "cloth")[i])
        k.add(lambda p: sub(box(p, v3(0.34, y, z0 + 0.09), (0.2, 0.12, 0.09), 0.008), box(p, v3(0.34, y, z0 + 0.14), (0.18, 0.1, 0.09))), "plank_x")
        k.add(rough(lambda p: ell(p, v3(0.34, y, z0 + 0.15), (0.17, 0.09, 0.05)), 0.04, 0.03, seed), "straw")
        k.add(many([lambda p, x=x: cap(p, v3(x, y, z0 + 0.13), v3(x, y, z0 + 0.27), 0.03, 0.014) for x in (0.24, 0.36, 0.46)]), "glass")
    elif state == "hardware":
        k.add(many([coil(-0.42, y, z0, 0.14, 0.026, 4), coil(-0.08, y, z0, 0.12, 0.024, 3)]), "rope")
        k.add(lambda p: sub(box(p, v3(0.36, y, z0 + 0.09), (0.2, 0.12, 0.09), 0.008), box(p, v3(0.36, y, z0 + 0.14), (0.18, 0.1, 0.09))), "plank_x")
        k.add(many([lambda p, x=x: cap(p, v3(x, y, z0 + 0.08), v3(x + 0.02, y - 0.02, z0 + 0.38), 0.016) for x in (0.24, 0.32, 0.4, 0.48)]), "wood_l")
        k.add(many([lambda p, x=x: cap(p, v3(x + 0.016, y - 0.016, z0 + 0.3), v3(x + 0.02, y - 0.02, z0 + 0.39), 0.026) for x in (0.24, 0.32, 0.4, 0.48)]), "cloth_k")
        for i, x in enumerate((-0.44, -0.2)):      # 불 꺼진 랜턴
            k.add(lambda p, x=x: np.minimum.reduce([cyl(p, v3(x, y, z1), 0.07, 0.02), cyl(p, v3(x, y, z1 + 0.17), 0.07, 0.02), cone(p, v3(x, y, z1 + 0.19), 0.06, 0.05),
                np.minimum.reduce([cap(p, v3(x + a, y + b, z1), v3(x + a, y + b, z1 + 0.18), 0.008) for a, b in ((-0.055, -0.03), (0.055, -0.03), (0.0, 0.05))])]), "iron")
            k.add(lambda p, x=x: cyl(p, v3(x, y, z1 + 0.02), 0.045, 0.15), "glass")
            k.add(lambda p, x=x: ring_x(p, v3(x, y, z1 + 0.27), 0.035, 0.007), "iron")
        k.add(many([lambda p, i=i: cyl(p, v3(0.14 + (i % 4) * 0.045, y - 0.03 + (i // 4) * 0.05, z1), 0.018, 0.13) for i in range(8)]), "wax")
        k.add(lambda p: box(p, v3(0.44, y, z1 + 0.05), (0.08, 0.08, 0.05), 0.008), "plank_x")
        k.add(many([lambda p: box(p, v3(-0.4, y, z2 + 0.035), (0.085, 0.04, 0.035), 0.006), lambda p: box(p, v3(0.1, y, z2 + 0.03), (0.07, 0.035, 0.03), 0.006), lambda p: cone(rot_y(p, PI / 2, (0.45, y, z2 + 0.04)), v3(0.45, y, z2 + 0.0), 0.04, 0.16)]), "iron")
        k.add(many([lambda p: hcyl(p, v3(-0.4, y, z2 + 0.035), v3(-0.14, y, z2 + 0.035), 0.016), lambda p: hcyl(p, v3(0.1, y, z2 + 0.03), v3(0.34, y, z2 + 0.03), 0.014)]), "wood_l")
        k.add(rough(lambda p: smin(ell(p, v3(-0.38, y, z3 + 0.1), (0.12, 0.07, 0.1)), cap(p, v3(-0.38, y, z3 + 0.2), v3(-0.34, y, z3 + 0.27), 0.03, 0.02), 0.04), 0.012, 0.08, seed), "leather")
        k.add(many([lambda p, x=x: box(p, v3(x, y, z3 + 0.045), (0.07, 0.07, 0.045), 0.006) for x in (0.0, 0.17)] + [lambda p: box(p, v3(0.08, y, z3 + 0.13), (0.07, 0.07, 0.04), 0.006)]), "plank_xd")
        k.add(coil(0.42, y, z3, 0.09, 0.02, 2), "rope")
    else:   # sparse — 거의 다 팔렸다
        _sack(k, v3(-0.38, y, z0), 0.7, seed)
        jar(k, 0.3, y, z1, 0.065, 0.17)
        k.add(loaf(-0.3, y, z2, 0.3, 1.1), "bread")
        _bottle(k, 0.42, y, z2, 0.04, 0.13, "glass", 0.09)
        _flask(k, -0.1, y, z3, 0.058, "glass_r")
        k.add(many([tag(-0.4, -d - 0.0, z1 + 0.03, 0.8), tag(0.1, -d, z3 + 0.03, 0.8)]), "paper")
    return {}


@prop("apothecary_drawers", "shop", cell=(3, 4), collide=(1.1, 0.45), tags=["wood", "shop", "herb"], name_ko="약재 서랍장", interact="container",
    variants={"closed": {}, "open": {"state": "open"}, "mortar": {"state": "mortar"}})
def apothecary_drawers(k, state="closed", seed=1):
    """작은 서랍이 빼곡한 약재장 — 서랍마다 놋쇠 손잡이와 종이 이름표."""
    goods_mats(k)
    w, d, h = 0.52, 0.2, 1.2
    cols, rows = 5, 6
    cw, rh = (2 * w - 0.06) / cols, (h - 0.2) / rows
    k.add(rough(lambda p: box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.01), 0.008, 0.25, seed), "wood_d")
    k.add(lambda p: box(p, v3(0, -0.01, h + 0.015), (w + 0.03, d + 0.02, 0.02), 0.008), "wood")
    pulled = {(1, 4): 0.1, (3, 2): 0.07, (0, 1): 0.05} if state == "open" else {}

    def front(p, out=0.0, only=None):
        gx = (p[:, 0] + w - 0.03) / cw
        gz = (p[:, 2] - 0.12) / rh
        ix, iz = np.floor(gx), np.floor(gz)
        fx_, fz = (gx - ix - 0.5) * cw, (gz - iz - 0.5) * rh
        inside = (ix >= 0) & (ix < cols) & (iz >= 0) & (iz < rows)
        return fx_, fz, ix, iz, inside

    def drawers(p):
        fx_, fz, ix, iz, inside = front(p)
        dd = np.maximum(np.maximum(np.abs(fx_) - cw / 2 + 0.012, np.abs(fz) - rh / 2 + 0.012), np.abs(p[:, 1] + d + 0.004) - 0.012)
        for (cx, cz) in pulled:
            dd = np.where((ix == cx) & (iz == cz), 1.0, dd)
        return np.where(inside, dd, 1.0)

    def knobs(p):
        fx_, fz, ix, iz, inside = front(p)
        dd = sdf.length(np.stack([fx_, p[:, 1] + d + 0.022, fz + 0.03], 1)) - 0.014
        for (cx, cz) in pulled:
            dd = np.where((ix == cx) & (iz == cz), 1.0, dd)
        return np.where(inside, dd, 1.0)

    def labels(p):
        fx_, fz, ix, iz, inside = front(p)
        dd = np.maximum(np.maximum(np.abs(fx_) - 0.045, np.abs(fz - 0.022) - 0.02), np.abs(p[:, 1] + d + 0.016) - 0.004)
        for (cx, cz) in pulled:
            dd = np.where((ix == cx) & (iz == cz), 1.0, dd)
        return np.where(inside, dd, 1.0)
    k.add(drawers, "wood")
    k.add(knobs, "brass")
    k.add(labels, "paper")
    for i, ((cx, cz), out) in enumerate(pulled.items()):
        x, z = -w + 0.03 + (cx + 0.5) * cw, 0.12 + (cz + 0.5) * rh
        k.add(lambda p, x=x, z=z, out=out: sub(box(p, v3(x, -d - out + 0.06, z), (cw / 2 - 0.012, out + 0.06, rh / 2 - 0.012), 0.004), box(p, v3(x, -d - out + 0.05, z + 0.03), (cw / 2 - 0.028, out + 0.04, rh / 2 - 0.012))), "wood")
        k.add(rough(lambda p, x=x, z=z, out=out: ell(p, v3(x, -d - out + 0.02, z + 0.02), (cw / 2 - 0.03, out, 0.04)), 0.03, 0.03, seed + i), ("herb", "herb_dry", "herb_v")[i % 3])
        k.add(lambda p, x=x, z=z, out=out: sphere(p, v3(x, -d - 2 * out - 0.015, z - 0.03), 0.014), "brass")
    if state in ("open", "mortar"):   # 위에 약절구 · 병
        zt = h + 0.035
        k.add(lambda p: sub(_frustum(p, v3(-0.25, 0, zt), 0.06, 0.09, 0.1), _frustum(p, v3(-0.25, 0, zt + 0.03), 0.045, 0.075, 0.1)), "stone_l")
        k.add(lambda p: cap(p, v3(-0.25, 0, zt + 0.06), v3(-0.14, 0.03, zt + 0.2), 0.02, 0.014), "stone")
        _bottle(k, 0.08, 0.02, zt, 0.035, 0.1, "glass", 0.07)
        _flask(k, 0.28, 0.0, zt, 0.055, "glass_b")
        if state == "mortar":
            k.add(rough(lambda p: ell(p, v3(-0.02, -0.08, zt + 0.02), (0.09, 0.05, 0.03)), 0.03, 0.03, seed), "herb")
            jar(k, 0.42, 0.03, zt, 0.05, 0.1)
    return {}


@prop("goods_crate", "shop", cell=(2, 2), collide=(0.6, 0.6), tags=["wood", "shop", "storage"], name_ko="상품 상자", interact="container",
    variants={"produce": {}, "bottles": {"state": "bottles"}, "herbs": {"state": "herbs"}, "candles": {"state": "candles"}})
def goods_crate(k, state="produce", seed=1):
    """뚜껑을 떼고 물건을 내보인 낮은 상자(앞쪽으로 살짝 기울여 놓았다)."""
    goods_mats(k)
    s, hh = 0.27, 0.15
    t = _X(k, lambda p: rot_x(p - v3(0, 0, 0.0), 0.16, (0, s, 0)))
    t.add(rough(lambda p: sub(box(p, v3(0, 0, hh), (s, s, hh), 0.008), box(p, v3(0, 0, hh + 0.05), (s - 0.03, s - 0.03, hh))), 0.01, 0.2, seed), "plank_x")
    t.add(many([lambda p, sx=sx: box(p, v3(sx * (s - 0.03), -s, hh), (0.03, 0.012, hh)) for sx in (-1, 1)]), "wood_d")
    k.add(lambda p: box(p, v3(0, s - 0.03, 0.04), (s, 0.03, 0.04)), "wood_d")
    z = hh * 1.3
    if state == "produce":
        t.add(heap(-0.1, 0, z, 0.12, 0.2, 12, 0.045, seed), "apple")
        t.add(heap(0.14, 0, z, 0.09, 0.2, 9, 0.042, seed + 5), "root")
    elif state == "bottles":
        t.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, z), (s - 0.04, s - 0.04, 0.07)), np.maximum(np.abs(p[:, 0]), np.abs(p[:, 1])) - s + 0.035), 0.05, 0.035, seed), "straw")
        for i, (x, y) in enumerate(((-0.15, -0.12), (0.0, -0.12), (0.15, -0.12), (-0.15, 0.08), (0.0, 0.08), (0.15, 0.08))):
            t.add(lambda p, x=x, y=y: smin(cyl(p, v3(x, y, z - 0.02), 0.04, 0.1, 0.012), cap(p, v3(x, y, z + 0.08), v3(x, y, z + 0.16), 0.018, 0.014), 0.012), ("glass", "glass_b", "glass_r")[i % 3])
            t.add(lambda p, x=x, y=y: cyl(p, v3(x, y, z + 0.16), 0.014, 0.02), "wood_l")
    elif state == "herbs":
        for i, (x, y, a) in enumerate(((-0.14, -0.08, 0.3), (0.1, -0.1, -0.2), (-0.05, 0.1, 0.8), (0.15, 0.1, 0.1))):
            t.add(rough(lambda p, x=x, y=y, a=a: ell(rot_z(p, a, (x, y, 0)), v3(x, y, z + 0.03), (0.12, 0.06, 0.05)), 0.04, 0.03, seed + i), ("herb", "herb_dry", "herb_v", "herb")[i])
            t.add(lambda p, x=x, y=y, a=a: torus(rot_y(rot_z(p, a, (x, y, 0)), PI / 2, (x - 0.07, y, z + 0.03)), v3(x - 0.07, y, z + 0.03), 0.035, 0.008), "rope")
    else:
        t.add(many([lambda p, i=i: hcyl(p, v3(-0.2 + (i % 6) * 0.08, -0.2, z + 0.0 + (i // 6) * 0.04), v3(-0.2 + (i % 6) * 0.08, 0.2, z + (i // 6) * 0.04), 0.022) for i in range(11)]), "wax")
        t.add(lambda p: box(p, v3(0, 0, z - 0.03), (s - 0.035, s - 0.035, 0.02)), "linen")
    return {}


# ── 식량 ──────────────────────────────────────────────────────────────────────

@prop("meat_rail", "shop", cell=(3, 4), collide=(1.3, 0.3), tags=["wood", "shop", "food"], name_ko="말린 고기 걸이",
    variants={"full": {}, "few": {"state": "few"}, "empty": {"state": "empty"}})
def meat_rail(k, state="full", seed=1):
    """세운 나무 틀의 가로대에 말린 고기 · 소시지 타래 · 넓적다리를 걸었다."""
    goods_mats(k)
    w, h = 0.6, 1.5
    k.add(many([lambda p, sx=sx: np.minimum(box(p, v3(sx * w, 0, h / 2), (0.035, 0.035, h / 2), 0.008), box(p, v3(sx * w, 0, 0.03), (0.04, 0.2, 0.03), 0.008)) for sx in (-1, 1)]
        + [lambda p: hcyl(p, v3(-w - 0.06, 0, h - 0.06), v3(w + 0.06, 0, h - 0.06), 0.025), lambda p: box(p, v3(0, 0, 0.3), (w, 0.02, 0.025))]), "wood_d")
    if state == "empty":
        k.add(many([lambda p, x=x: np.maximum(ring_x(p, v3(x, 0, h - 0.12), 0.03, 0.007), p[:, 2] - h + 0.1) for x in (-0.35, 0.0, 0.3)]), "iron")
        return {}
    zr = h - 0.085
    items = [(-0.45, "ham"), (-0.2, "saus"), (0.05, "strip"), (0.26, "ham"), (0.46, "saus")] if state == "full" else [(-0.3, "saus"), (0.3, "strip")]
    for i, (x, kind) in enumerate(items):
        k.add(lambda p, x=x: cap(p, v3(x, 0, zr), v3(x, 0, zr - 0.1), 0.007), "rope")
        if kind == "ham":
            k.add(rough(lambda p, x=x: smin(ell(p, v3(x, 0, zr - 0.38), (0.1, 0.075, 0.17)), cap(p, v3(x, 0, zr - 0.2), v3(x, 0, zr - 0.1), 0.035, 0.018), 0.05), 0.015, 0.06, seed + i), "meat")
            k.add(lambda p, x=x: cap(p, v3(x, 0, zr - 0.12), v3(x, 0, zr - 0.08), 0.016), "bone")
        elif kind == "saus":
            k.add(many([lambda p, x=x, j=j: cap(p, v3(x + (j - 1) * 0.055, 0, zr - 0.1), v3(x + (j - 1) * 0.06, 0.0, zr - 0.42 - (j % 2) * 0.06), 0.028) for j in range(3)]), "meat")
            k.add(many([lambda p, x=x, j=j: torus(p, v3(x + (j - 1) * 0.057, 0, zr - 0.26), 0.028, 0.006) for j in range(3)]), "rope")
        else:
            k.add(rough(lambda p, x=x: box(p, v3(x, 0, zr - 0.34), (0.075, 0.016, 0.24), 0.012) + np.sin(p[:, 2] * 30.0) * 0.006, 0.02, 0.07, seed + i), "meat")
            k.add(lambda p, x=x: box(p, v3(x + 0.05, -0.005, zr - 0.34), (0.018, 0.018, 0.23), 0.008), "fat")
    return {"foot": 0.6}


@prop("bread_board", "shop", cell=(3, 3), collide=(1.2, 0.55), tags=["wood", "shop", "food"], name_ko="빵과 치즈 판매대",
    variants={"full": {}, "picked": {"state": "picked"}})
def bread_board(k, state="full", seed=1):
    """낮은 가대 위 넓은 판자에 빵 · 치즈를 늘어놓았다(천을 깔았다)."""
    goods_mats(k)
    w, d, h = 0.56, 0.24, 0.44
    k.add(rough(lambda p: box(p, v3(0, 0, h - 0.02), (w, d, 0.02), 0.008), 0.01, 0.2, seed), "plank_x")
    k.add(many([lambda p, sx=sx, sy=sy: cap(p, v3(sx * (w - 0.1), sy * 0.04, h - 0.03), v3(sx * (w - 0.1) , sy * (d - 0.02), 0.0), 0.025) for sx in (-1, 1) for sy in (-1, 1)]
        + [lambda p, sx=sx: hcyl(p, v3(sx * (w - 0.1), -d + 0.07, 0.15), v3(sx * (w - 0.1), d - 0.07, 0.15), 0.015) for sx in (-1, 1)]), "wood_d")
    k.add(rough(lambda p: np.minimum(box(p, v3(-0.1, 0, h + 0.004), (0.36, d + 0.01, 0.006), 0.004), box(p, v3(-0.1, -d - 0.012, h - 0.05), (0.36, 0.008, 0.055), 0.004) + np.sin(p[:, 0] * 30.0) * 0.005), 0.008, 0.1, seed), "linen")
    z = h + 0.01
    full = state == "full"
    L = [loaf(-0.36, -0.08, z, 0.3, 1.15), loaf(-0.34, 0.1, z, -0.4, 1.0)] + ([loaf(-0.14, -0.1, z, 0.1, 1.05), loaf(-0.12, 0.08, z, 0.6, 1.1), loaf(-0.24, 0.0, z + 0.07, 0.2, 0.95)] if full else [])
    k.add(many(L + [lambda p: ell(p, v3(0.08, 0.1, z + 0.045), (0.07, 0.07, 0.05))]), "bread")
    C = [wheel(0.38, -0.04, z, 0.095, 0.06)] + ([wheel(0.14, -0.1, z, 0.07, 0.045), lambda p: cyl(p, v3(0.38, -0.03, z + 0.06), 0.08, 0.05, 0.01)] if full else [])
    k.add(many(C), "cheese")
    k.add(lambda p: np.minimum(box(p, v3(0.24, 0.14, z + 0.004), (0.07, 0.012, 0.003)), cap(p, v3(0.31, 0.14, z + 0.008), v3(0.37, 0.14, z + 0.008), 0.01)), "steel")
    if not full:
        k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, z + 0.004), 0.008) for x, y in ((-0.1, -0.08), (-0.02, 0.02), (-0.16, 0.06), (0.03, -0.12))]), "bread")
    return {}


@prop("grain_bin", "shop", cell=(3, 2), collide=(1.25, 0.5), tags=["wood", "shop", "food", "storage"], name_ko="곡물 통", interact="container",
    variants={"full": {}, "low": {"state": "low"}, "lidded": {"state": "lidded"}})
def grain_bin(k, state="full", seed=1):
    """칸 셋으로 나뉜 낮은 곡물 통 — 칸마다 곡식 · 콩 · 가루, 나무 국자가 꽂혀 있다."""
    goods_mats(k)
    w, d, h = 0.6, 0.22, 0.42
    shell = lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.008), np.minimum.reduce([box(p, v3(x, 0, h / 2 + 0.05), (0.175, d - 0.03, h / 2)) for x in (-0.39, 0.0, 0.39)]))
    k.add(rough(lambda p: np.maximum(shell(p), p[:, 2] - h + 0.1 - (p[:, 1] + d) * 0.22), 0.008, 0.2, seed), "wood")
    k.add(many([lambda p, z=z: box(p, v3(0, -d, z), (w + 0.006, 0.01, 0.022)) for z in (0.05, 0.26)]), "iron")
    if state == "lidded":
        k.add(rough(lambda p: box(rot_x(p, -0.22, (0, d, h)), v3(0, 0, h + 0.0), (w + 0.01, d + 0.02, 0.016), 0.006), 0.008, 0.2, seed + 1), "plank_x")
        k.add(many([lambda p, x=x: box(rot_x(p, -0.22, (0, d, h)), v3(x, -d - 0.02, h - 0.01), (0.04, 0.012, 0.03), 0.006) for x in (-0.39, 0.0, 0.39)]), "iron")
        return {}
    lv = h - (0.12 if state == "full" else 0.26)
    for i, x in enumerate((-0.39, 0.0, 0.39)):
        m = k.mat("grain%d" % i, M.plain(("#a08a50", "#6e5a40", "#b8ac94")[i], 0.5, 0.012, 60 + i))
        k.add(lambda p, x=x: np.maximum(ell(p, v3(x, 0.02, lv - 0.02), (0.19, d, 0.07 if state == "full" else 0.03)), np.maximum(np.abs(p[:, 0] - x) - 0.172, np.abs(p[:, 1]) - d + 0.032)), m)
    k.add(lambda p: np.minimum(sub(_frustum(p, v3(-0.36, -0.02, lv + 0.01), 0.04, 0.055, 0.07), cyl(p, v3(-0.36, -0.02, lv + 0.03), 0.04, 0.1)), cap(p, v3(-0.33, 0.0, lv + 0.05), v3(-0.2, 0.08, lv + 0.2), 0.012)), "wood_l")
    if state == "full":
        k.add(lambda p: pool(p, v3(0.1, -d - 0.12, 0.006), 0.1, 0.05, 0.006) + (sdf.noise(p, 0.02, seed) - 0.5) * 0.04, "grain1")
    return {}


# ── 물약 · 약초 ───────────────────────────────────────────────────────────────

@prop("potion_rack", "shop", cell=(2, 2), collide=(0.8, 0.35), tags=["wood", "shop", "glass", "potion"], name_ko="물약 꽂이", interact="container",
    variants={"tidy": {}, "half_sold": {"state": "half"}, "empty": {"state": "empty"}})
def potion_rack(k, state="tidy", seed=1):
    """구멍 뚫린 나무 틀에 둥근 물약병을 두 줄로 꽂았다(뒷줄이 한 단 높다)."""
    w = 0.36
    rows = ((-0.07, 0.3), (0.09, 0.46))
    holes = lambda p, y, z: np.minimum.reduce([cyl(p, v3(x, y, z - 0.05), 0.05, 0.1) for x in (-0.24, -0.08, 0.08, 0.24)])
    for y, z in rows:
        k.add(rough(lambda p, y=y, z=z: sub(box(p, v3(0, y, z), (w, 0.075, 0.014), 0.005), holes(p, y, z)), 0.006, 0.2, seed), "plank_x")
    k.add(many([lambda p, sx=sx: np.maximum(box(p, v3(sx * w, 0.01, 0.25), (0.022, 0.17, 0.25), 0.006), p[:, 2] - 0.4 - p[:, 1] * 1.0) for sx in (-1, 1)] + [lambda p: box(p, v3(0, 0.0, 0.06), (w, 0.15, 0.014))]), "wood_d")
    if state == "empty":
        return {}
    keep = [(0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3)] if state == "tidy" else [(0, 1), (1, 0), (1, 3)]
    for i, (r, c) in enumerate(keep):
        y, z = rows[r]
        x = -0.24 + c * 0.16
        m = ("glass_r", "glass_b", "glass_r", "glass", "glass_b", "glass_r", "glass", "glass_b")[(r * 4 + c) % 8]
        k.add(lambda p, x=x, y=y, z=z: smin(sphere(p, v3(x, y, z - 0.03), 0.058), cap(p, v3(x, y, z + 0.02), v3(x, y, z + 0.1), 0.02, 0.016), 0.02), m)
        k.add(lambda p, x=x, y=y, z=z: cyl(p, v3(x, y, z + 0.1), 0.016, 0.025), "wood_l")
    return {}


def bundle(t, x, y, z, s=1.0, mat="herb", seed=1):
    """거꾸로 매단 약초 다발: 묶은 줄기(위) → 퍼진 잎(아래)."""
    t.add(rough(lambda p: smin(ell(p, v3(x, y, z - 0.19 * s), (0.065 * s, 0.045 * s, 0.11 * s)), cap(p, v3(x, y, z - 0.02 * s), v3(x, y, z - 0.12 * s), 0.014 * s, 0.03 * s), 0.04 * s), 0.035 * s, 0.035, seed), mat)
    t.add(lambda p: np.minimum(torus(p, v3(x, y, z - 0.05 * s), 0.018 * s, 0.007), cap(p, v3(x, y, z - 0.03 * s), v3(x, y, z + 0.03), 0.005)), "rope")


@prop("herb_bundles", "shop", layer="wall_decal", cell=(3, 3), tags=["shop", "herb", "plant"], name_ko="매단 약초 다발",
    variants={"full": {}, "mixed": {"state": "mixed"}, "sparse": {"state": "sparse"}})
def herb_bundles(k, state="full", seed=1):
    """벽에 박은 가로대에 말리는 약초 다발 — 원점 = 벽 밑동(가로대 높이 1.5칸)."""
    goods_mats(k)
    zr, y = 1.5, -0.07
    k.add(many([lambda p: hcyl(p, v3(-0.62, y, zr), v3(0.62, y, zr), 0.016)] + [lambda p, x=x: cap(p, v3(x, 0.0, zr + 0.02), v3(x, y, zr), 0.014) for x in (-0.55, 0.55)]), "wood_d")
    xs = {"full": (-0.48, -0.3, -0.12, 0.06, 0.24, 0.44), "mixed": (-0.46, -0.24, 0.0, 0.42), "sparse": (-0.4, 0.3)}[state]
    for i, x in enumerate(xs):
        m = ("herb", "herb_dry", "herb_v", "herb_dry", "herb", "herb_dry")[i % 6]
        bundle(k, x, y, zr - 0.03, 0.85 + ((i * 7 + seed) % 4) * 0.1, m, seed + i)
    if state == "mixed":   # 마늘 타래 · 말린 버섯 줄
        k.add(many([lambda p, j=j: sphere(p, v3(0.2 + (j % 2) * 0.04, y, zr - 0.08 - j * 0.045), 0.03) for j in range(6)]), "bone")
        k.add(lambda p: cap(p, v3(0.22, y, zr), v3(0.22, y, zr - 0.3), 0.006), "rope")
    return {"shadow": 0.0, "foot": 0.3}


@prop("herb_tray", "shop", cell=(2, 2), collide=(0.7, 0.4), tags=["shop", "herb", "plant"], name_ko="약초 쟁반", interact="container",
    variants={"fresh": {}, "dried": {"state": "dried"}, "sorted": {"state": "sorted"}})
def herb_tray(k, state="fresh", seed=1):
    """낮은 받침 위의 넓은 채반 — 약초를 펴 말리거나 종류별로 갈라 놓았다."""
    goods_mats(k)
    h = 0.3
    k.add(many([lambda p, sx=sx: np.minimum(cap(p, v3(sx * 0.28, -0.12, 0), v3(sx * 0.22, 0.12, h - 0.03), 0.02), cap(p, v3(sx * 0.28, 0.12, 0), v3(sx * 0.22, -0.12, h - 0.03), 0.02)) for sx in (-1, 1)]), "wood_d")
    k.add(lambda p: sub(cyl(p, v3(0, 0, h - 0.02), 0.34, 0.05, 0.012), cyl(p, v3(0, 0, h), 0.31, 0.06)) * 1.0, k.mat("wicker", M.thatch("#7a643c", 0.03, 5)))
    k.sq = None
    z = h + 0.0
    if state == "sorted":
        for i, (a, m) in enumerate(((0.3, "herb"), (2.4, "herb_dry"), (4.5, "herb_v"))):
            k.add(rough(lambda p, a=a: ell(p, v3(np.cos(a) * 0.15, np.sin(a) * 0.14, z + 0.015), (0.12, 0.1, 0.035)), 0.035, 0.03, seed + i), m)
        k.add(many([lambda p: box(rot_z(p, 0.5), v3(0, 0, z + 0.006), (0.29, 0.008, 0.012)), lambda p: box(rot_z(p, -1.6), v3(0.12, 0, z + 0.006), (0.17, 0.008, 0.012))]), "wood_l")
    else:
        m = "herb" if state == "fresh" else "herb_dry"
        k.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, z + 0.01), (0.28, 0.27, 0.04)), np.hypot(p[:, 0], p[:, 1]) - 0.3), 0.05, 0.035, seed), m)
        if state == "fresh":
            k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, z + 0.035), 0.014) for x, y in ((-0.1, -0.05), (0.08, 0.1), (0.15, -0.12), (-0.18, 0.12), (0.0, -0.18))]), "herb_v")
    return {}


# ── 가방 · 밧줄 · 연장 · 장비 ─────────────────────────────────────────────────

@prop("hanging_bags", "shop", layer="wall_decal", cell=(3, 3), tags=["shop", "leather", "explorer"], name_ko="걸어 둔 가방과 주머니",
    variants={"full": {}, "few": {"state": "few"}})
def hanging_bags(k, state="full", seed=1):
    """벽 못걸이 판에 건 어깨 가방 · 허리 주머니 · 물주머니 — 원점 = 벽 밑동(판 높이 1.45칸)."""
    zr, y = 1.45, -0.03
    k.add(rough(lambda p: box(p, v3(0, -0.012, zr), (0.66, 0.014, 0.04), 0.006), 0.006, 0.2, seed), "plank_x")
    xs = (-0.5, -0.25, 0.0, 0.25, 0.5)
    k.add(many([lambda p, x=x: cap(p, v3(x, -0.02, zr), v3(x, -0.08, zr + 0.02), 0.011) for x in xs]), "wood_d")
    yb = -0.085
    show = (0, 1, 2, 3, 4) if state == "full" else (0, 3)
    if 0 in show:   # 어깨 가방(덮개 · 버클)
        k.add(many([lambda p, sx=sx: cap(p, v3(-0.5, yb + 0.02, zr + 0.01), v3(-0.5 + sx * 0.1, yb, zr - 0.32), 0.009) for sx in (-1, 1)]), "leather_d")
        k.add(rough(lambda p: box(p, v3(-0.5, yb, zr - 0.44), (0.125, 0.05, 0.13), 0.04), 0.012, 0.08, seed), "leather")
        k.add(lambda p: box(p, v3(-0.5, yb - 0.045, zr - 0.38), (0.13, 0.012, 0.075), 0.02), "leather_d")
        k.add(lambda p: box(p, v3(-0.5, yb - 0.06, zr - 0.44), (0.02, 0.008, 0.025), 0.004), "brass")
    if 1 in show:   # 물주머니
        k.add(rough(lambda p: smin(ell(p, v3(-0.25, yb, zr - 0.3), (0.075, 0.045, 0.12)), cap(p, v3(-0.25, yb, zr - 0.19), v3(-0.25, yb, zr - 0.12), 0.022, 0.016), 0.03), 0.01, 0.06, seed + 1), "leather_d")
        k.add(lambda p: np.minimum(cap(p, v3(-0.25, yb, zr - 0.12), v3(-0.25, yb + 0.02, zr + 0.0), 0.006), cyl(p, v3(-0.25, yb, zr - 0.12), 0.014, 0.025)), "rope")
    if 2 in show:   # 졸라매는 주머니 둘
        for j, (dx, s) in enumerate(((-0.05, 1.0), (0.06, 0.8))):
            k.add(rough(lambda p, dx=dx, s=s: smin(ell(p, v3(dx, yb, zr - 0.22 * s - 0.05), (0.06 * s, 0.045 * s, 0.07 * s)), cone(rot_x(p, PI, (dx, yb, zr - 0.13 * s - 0.05)), v3(dx, yb, zr - 0.2 * s - 0.05), 0.045 * s, 0.07 * s), 0.02), 0.01, 0.05, seed + 2 + j), ("cloth", "cloth_r")[j])
            k.add(lambda p, dx=dx, s=s: cap(p, v3(dx, yb, zr - 0.14 * s - 0.05), v3(0.0, yb + 0.02, zr + 0.01), 0.005), "rope")
    if 3 in show:   # 큰 배낭
        k.add(many([lambda p, sx=sx: cap(p, v3(0.25, yb + 0.02, zr + 0.01), v3(0.25 + sx * 0.08, yb, zr - 0.2), 0.011) for sx in (-1, 1)]), "leather_d")
        k.add(rough(lambda p: box(p, v3(0.25, yb - 0.01, zr - 0.38), (0.115, 0.06, 0.17), 0.05), 0.014, 0.08, seed + 5), "cloth_g")
        k.add(lambda p: np.minimum(box(p, v3(0.25, yb - 0.065, zr - 0.44), (0.07, 0.014, 0.06), 0.015), box(p, v3(0.25, yb - 0.06, zr - 0.26), (0.12, 0.012, 0.05), 0.02)), "leather")
    if 4 in show:   # 허리띠 주머니 줄
        k.add(lambda p: np.maximum(ring_x(p, v3(0.5, yb, zr - 0.17), 0.17, 0.012) * 1.0, -1e9), "leather_d")
        k.add(many([lambda p, a=a: box(p, v3(0.5 + np.sin(a) * 0.17, yb - 0.02, zr - 0.17 - np.cos(a) * 0.17), (0.04, 0.025, 0.045), 0.012) for a in (-0.7, 0.0, 0.7)]), "leather")
    return {"shadow": 0.0, "foot": 0.3}


@prop("rope_coil", "shop", cell=(2, 2), tags=["shop", "rope", "explorer"], name_ko="밧줄 타래",
    variants={"single": {}, "stack": {"state": "stack"}, "spool": {"state": "spool"}})
def rope_coil(k, state="single", seed=1):
    if state == "single":
        k.add(coil(0, 0, 0, 0.17, 0.03, 3), "rope")
        k.add(lambda p: cap(p, v3(0.15, -0.05, 0.03), v3(0.3, -0.16, 0.025), 0.026), "rope")
    elif state == "stack":
        k.add(many([coil(-0.16, 0.05, 0, 0.18, 0.032, 4), coil(0.2, 0.0, 0, 0.15, 0.028, 3), coil(-0.12, 0.06, 0.22, 0.14, 0.028, 3)]), "rope")
        k.add(many([lambda p: torus(rot_y(p, PI / 2, (0.2, -0.15, 0.08)), v3(0.2, -0.15, 0.08), 0.04, 0.008)]), "leather_d")
    else:   # 굴대에 감은 긴 밧줄
        k.add(many([lambda p, sx=sx: disc_x(rot_z(p, PI / 2), v3(0, sx * 0.17, 0.2), 0.2, 0.014) for sx in (-1, 1)]), "wood_d")
        k.add(lambda p: hcyl(p, v3(-0.16, 0, 0.2), v3(0.16, 0, 0.2), 0.14) + np.sin(p[:, 0] * 110.0) * 0.006, "rope")
        k.add(lambda p: cap(p, v3(0.05, -0.13, 0.14), v3(0.12, -0.3, 0.02), 0.022), "rope")
        k.add(many([lambda p, sx=sx: box(p, v3(sx * 0.2, 0, 0.02), (0.02, 0.18, 0.02)) for sx in (-1, 1)]), "wood_d")
    return {}


def pick(t, T, ln=0.9):
    """곡괭이(자루 아래 원점에서 위로)."""
    t.add(lambda p: cap(T(p), v3(0, 0, 0), v3(0, 0, ln), 0.02, 0.022), "wood_l")
    t.add(lambda p: np.maximum(np.maximum(np.abs(np.hypot(T(p)[:, 0], T(p)[:, 2] - ln + 0.34) - 0.36) - 0.02 * (1.25 - np.abs(T(p)[:, 0]) / 0.3), np.abs(T(p)[:, 1]) - 0.018), np.abs(T(p)[:, 0]) - 0.28), "iron")


def shovel(t, T, ln=0.95):
    t.add(lambda p: cap(T(p), v3(0, 0, 0.22), v3(0, 0, ln), 0.018), "wood_l")
    t.add(lambda p: np.minimum(box(T(p), v3(0, 0, 0.12), (0.085, 0.01, 0.13), 0.035), cap(T(p), v3(0, 0, 0.2), v3(0, 0, 0.3), 0.024)), "iron")
    t.add(lambda p: ring_x(T(p), v3(0, 0, ln + 0.04), 0.045, 0.014), "wood_l")


def hammer_up(t, T, ln=0.7):
    t.add(lambda p: cap(T(p), v3(0, 0, 0), v3(0, 0, ln), 0.018), "wood_l")
    t.add(lambda p: box(T(p), v3(0, 0, ln), (0.09, 0.04, 0.04), 0.008), "iron")


@prop("tool_bundle", "shop", cell=(2, 3), collide=(0.55, 0.55), tags=["shop", "tools", "iron"], name_ko="연장 묶음", interact="container",
    variants={"barrel": {}, "leaning": {"state": "leaning"}})
def tool_bundle(k, state="barrel", seed=1):
    """파는 연장: 통에 꽂은 곡괭이 · 삽 · 망치, 또는 벽에 기대 묶어 둔 것."""
    if state == "barrel":
        _barrel(k, 0.22, 0.5, seed, False)
        k.add(lambda p: cyl(p, v3(0, 0, 0.36), 0.2, 0.01), "void")
        shovel(k, lambda p: rot_y(rot_x(p - v3(-0.08, 0.05, 1.3), PI + 0.08), 0.1), 0.95)                 # 날이 위로
        pick(k, lambda p: rot_y(p - v3(0.08, 0.0, 0.25), -0.12), 1.0)
        hammer_up(k, lambda p: rot_x(rot_y(p - v3(-0.02, -0.1, 0.3), 0.15), -0.12), 0.62)
        return {"foot": 0.6}
    T0 = lambda p, dx, a: rot_x(rot_y(p - v3(dx, 0.02, 0.0), a), 0.2)
    pick(k, lambda p: T0(p, -0.14, 0.12), 1.0)
    shovel(k, lambda p: rot_y(rot_x(p - v3(0.05, 0.25, 1.22), PI - 0.2), 0.0), 0.95)
    hammer_up(k, lambda p: T0(p, 0.2, -0.1), 0.7)
    k.add(lambda p: torus(rot_x(p, 0.2), v3(0.04, 0.1, 0.5), 0.14, 0.014), "rope")
    return {"foot": 0.6}


@prop("tool_board", "shop", layer="wall_decal", cell=(3, 3), tags=["shop", "tools", "iron"], name_ko="연장 걸이판",
    variants={"full": {}, "gaps": {"state": "gaps"}})
def tool_board(k, state="full", seed=1):
    """벽에 건 넓은 판자에 연장을 걸었다(망치 · 톱 · 집게 · 손도끼 · 끌) — gaps = 몇 개 팔려 못만 남았다. 원점 = 벽 밑동."""
    zc, y = 1.25, -0.03
    k.add(rough(lambda p: box(p, v3(0, -0.012, zc), (0.66, 0.014, 0.36), 0.008), 0.006, 0.25, seed), "plank_x")
    k.add(many([lambda p, sx=sx: box(p, v3(sx * 0.6, -0.03, zc), (0.03, 0.01, 0.36)) for sx in (-1, 1)]), "wood_d")
    yt = -0.055
    full = state == "full"
    pegs = [(-0.45, 0.28), (-0.2, 0.28), (0.05, 0.28), (0.3, 0.28), (0.5, 0.28)]
    k.add(many([lambda p, x=x, z=z: cap(p, v3(x, -0.03, zc + z), v3(x, yt - 0.02, zc + z + 0.01), 0.009) for x, z in pegs]), "iron")
    # 망치
    k.add(lambda p: cap(p, v3(-0.45, yt, zc + 0.22), v3(-0.45, yt, zc - 0.22), 0.016), "wood_l")
    k.add(lambda p: box(p, v3(-0.45, yt, zc + 0.24), (0.075, 0.03, 0.035), 0.008), "iron")
    if full:   # 톱
        k.add(lambda p: np.maximum(box(p, v3(-0.2, yt, zc - 0.02), (0.045, 0.006, 0.22)), (p[:, 0] + 0.2) - 0.045 + (zc + 0.2 - p[:, 2]) * 0.12 + np.abs(np.sin(p[:, 2] * 90.0)) * 0.008), "steel")
        k.add(lambda p: sub(box(p, v3(-0.2, yt, zc + 0.24), (0.06, 0.016, 0.05), 0.015), box(p, v3(-0.2, yt, zc + 0.24), (0.03, 0.03, 0.022), 0.01)), "wood_l")
    # 집게
    k.add(many([lambda p, s=s: np.minimum(cap(p, v3(0.05 + s * 0.012, yt, zc + 0.12), v3(0.05 + s * 0.045, yt, zc - 0.24), 0.01), cap(p, v3(0.05 + s * 0.012, yt, zc + 0.12), v3(0.05 - s * 0.03, yt, zc + 0.27), 0.012)) for s in (-1, 1)]), "iron")
    if full:   # 손도끼
        k.add(lambda p: cap(p, v3(0.3, yt, zc + 0.24), v3(0.3, yt, zc - 0.2), 0.016), "wood_l")
        k.add(lambda p: np.maximum(np.maximum(np.hypot(p[:, 0] - 0.3, p[:, 2] - zc - 0.2) - 0.13, np.abs(p[:, 1] - yt) - 0.014), np.maximum(0.3 - p[:, 0], np.abs(p[:, 2] - zc - 0.2) - 0.02 - (p[:, 0] - 0.3) * 0.75)), "steel")
    # 끌 둘
    k.add(many([lambda p, dx=dx: cap(p, v3(0.5 + dx, yt, zc + 0.25), v3(0.5 + dx, yt, zc + 0.1), 0.014) for dx in (-0.04, 0.04)]), "wood_l")
    k.add(many([lambda p, dx=dx: box(p, v3(0.5 + dx, yt, zc - 0.0), (0.012, 0.006, 0.11)) for dx in (-0.04, 0.04)]), "steel")
    k.add(many([coil_x(0.52, yt, zc - 0.22, 0.07, 0.014)]), "rope")
    return {"shadow": 0.0, "foot": 0.3}


@prop("gear_table", "shop", cell=(4, 3), collide=(1.5, 0.7), tags=["wood", "shop", "explorer", "display"], name_ko="탐험 장비 진열대", interact="container",
    variants={"full": {}, "picked": {"state": "picked"}})
def gear_table(k, state="full", seed=1):
    """탐험 준비물을 늘어놓은 탁자: 횃불 다발 · 물주머니 · 밧줄 · 부싯돌 통 · 꺼진 랜턴 · 붕대 뭉치(게임이 파는 종류를 뭉뚱그린 것)."""
    goods_mats(k)
    w, d, h = 0.7, 0.3, 0.5
    _table(k, w, d, h, seed, "plank_x", "wood_d")
    full = state == "full"
    # 횃불 다발
    n = 5 if full else 2
    k.add(many([lambda p, i=i: hcyl(p, v3(-0.62, -0.12 + i * 0.045, h + 0.022 + (i % 2) * 0.03), v3(-0.25, -0.1 + i * 0.045, h + 0.022 + (i % 2) * 0.03), 0.018) for i in range(n)]), "wood_l")
    k.add(many([lambda p, i=i: hcyl(p, v3(-0.36, -0.1 + i * 0.045, h + 0.022 + (i % 2) * 0.03), v3(-0.24, -0.1 + i * 0.045, h + 0.022 + (i % 2) * 0.03), 0.03) for i in range(n)]), "cloth_k")
    if full:
        k.add(lambda p: torus(rot_y(p, PI / 2, (-0.5, -0.02, h + 0.04)), v3(-0.5, -0.02, h + 0.04), 0.075, 0.008), "rope")
    k.add(coil(0.0, 0.08, h, 0.11, 0.022, 3), "rope")
    # 물주머니
    k.add(rough(lambda p: smin(ell(rot_z(p, 0.4, (0.05, -0.16, 0)), v3(0.05, -0.16, h + 0.04), (0.11, 0.065, 0.04)), cap(p, v3(0.14, -0.12, h + 0.04), v3(0.2, -0.1, h + 0.04), 0.022, 0.014), 0.03), 0.01, 0.06, seed), "leather_d")
    # 랜턴(꺼진)
    x, y = 0.38, 0.1
    k.add(lambda p: np.minimum.reduce([cyl(p, v3(x, y, h), 0.075, 0.02), cyl(p, v3(x, y, h + 0.18), 0.075, 0.02), cone(p, v3(x, y, h + 0.2), 0.065, 0.055),
        np.minimum.reduce([cap(p, v3(x + a, y + b, h), v3(x + a, y + b, h + 0.19), 0.008) for a, b in ((-0.06, -0.03), (0.06, -0.03), (0.0, 0.055))]), ring_x(p, v3(x, y, h + 0.29), 0.04, 0.007)]), "iron")
    k.add(lambda p: cyl(p, v3(x, y, h + 0.02), 0.05, 0.16), "glass")
    if full:
        k.add(lambda p: box(p, v3(0.58, -0.1, h + 0.035), (0.07, 0.05, 0.035), 0.008), "iron")                     # 부싯돌 통
        k.add(many([lambda p, i=i: hcyl(p, v3(0.3 + i * 0.075, -0.2, h + 0.03), v3(0.3 + i * 0.075, -0.1, h + 0.03), 0.03) for i in range(2)]), "linen")   # 붕대 뭉치
        _flask(k, 0.6, 0.12, h, 0.05, "glass_r")
    k.add(many([tag(-0.45, -d - 0.005, h - 0.02, 0.9), tag(0.3, -d - 0.005, h - 0.02, 0.9)]), "paper")
    return {}


@prop("torch_bin", "shop", cell=(2, 3), collide=(0.5, 0.5), tags=["wood", "shop", "explorer"], name_ko="횃불 통", interact="container",
    variants={"full": {}, "few": {"state": "few"}})
def torch_bin(k, state="full", seed=1):
    """불 붙이지 않은 횃불을 꽂아 둔 통(머리에 기름 먹인 헝겊)."""
    _barrel(k, 0.2, 0.46, seed, False)
    k.add(lambda p: cyl(p, v3(0, 0, 0.33), 0.18, 0.01), "void")
    rng = np.random.default_rng(seed)
    n = 9 if state == "full" else 3
    pts = [(rng.uniform(-0.1, 0.1), rng.uniform(-0.09, 0.09), rng.uniform(-0.16, 0.16), rng.uniform(-0.1, 0.1), rng.uniform(0.78, 0.92)) for _ in range(n)]
    k.add(many([lambda p, q=q: cap(p, v3(q[0], q[1], 0.1), v3(q[0] + q[2], q[1] + q[3], q[4]), 0.017) for q in pts]), "wood_l")
    k.add(many([lambda p, q=q: cap(p, v3(q[0] + q[2] * 0.86, q[1] + q[3] * 0.86, 0.1 + (q[4] - 0.1) * 0.86), v3(q[0] + q[2], q[1] + q[3], q[4]), 0.034) for q in pts]), "cloth_k")
    return {"foot": 0.6}


# ── 저울 · 장부 · 돈통 · 꾸러미 · 가격표 ──────────────────────────────────────

@prop("scale", "shop", cell=(2, 2), tags=["shop", "bank", "brass"], name_ko="양팔저울",
    variants={"level": {}, "weights": {"state": "weights"}, "coins": {"state": "coins"}})
def scale(k, state="level", seed=1):
    """놋쇠 양팔저울(탁자 · 카운터 위에 놓는다 — z 보정으로 올린다). weights = 추 쪽으로 기울었다 · coins = 동전을 단다."""
    s = 1.5
    tilt = {"level": 0.0, "weights": -0.2, "coins": 0.16}[state]
    L, R = scale_parts(k, v3(0, 0, 0), s, tilt)
    if state == "weights":
        k.add(weights(R[0] - 0.035, R[1], R[2] + 0.004, 2), "iron")
        k.add(weights(-0.1, -0.16, 0, 3), "iron")
    elif state == "coins":
        k.add(coins(L[0] - 0.03, L[1], L[2] + 0.004, 0.022, (0.04, 0.055), 0.05), "gold")
        k.add(weights(R[0] - 0.02, R[1], R[2] + 0.004, 1), "iron")
        k.add(coins(-0.08, -0.17, 0, 0.022, (0.02, 0.035, 0.012), 0.05), "gold")
    return {}


@prop("ledger", "shop", cell=(2, 2), tags=["shop", "bank", "paper"], name_ko="장부", interact="read",
    variants={"closed": {}, "open": {"state": "open"}, "stack": {"state": "stack"}})
def ledger(k, state="closed", seed=1):
    """두꺼운 거래 장부(모서리에 놋쇠) — 탁자 · 카운터 위에 놓는다. 글은 읽히지 않는 줄뿐."""
    if state == "closed":
        ledger_closed(k, v3(0, 0, 0), 0.12, "leather_d", 1.5)
        k.add(lambda p: box(rot_z(p, 0.12), v3(0.0, 0.0, 0.106), (0.2, 0.012, 0.004)), "cloth_r")
    elif state == "open":
        _open_book(k, v3(0, 0, 0), 1.5, 0.05, "leather_d")
        k.add(lambda p: box(p, v3(0.0, -0.1, 0.03), (0.012, 0.1, 0.004)), "cloth_r")
        inkpot(k, 0.34, 0.12, 0)
    else:
        ledger_closed(k, v3(0, 0, 0), 0.05, "leather_d", 1.45)
        ledger_closed(k, v3(0.01, 0.0, 0.103), -0.12, "leather", 1.35)
        ledger_closed(k, v3(-0.01, 0.01, 0.2), 0.2, "cloth_g", 1.25)
    return {}


@prop("coin_box", "shop", cell=(2, 2), tags=["shop", "wood", "coin"], name_ko="돈통", interact="container",
    variants={"closed": {}, "open": {"state": "open"}})
def coin_box(k, state="closed", seed=1):
    """칸이 나뉜 작은 나무 돈통(가게 계산용) — 카운터 위에 놓는다."""
    w, d, h = 0.2, 0.13, 0.1
    if state == "closed":
        k.add(rough(lambda p: box(p, v3(0, 0, (h + 0.03) / 2), (w, d, (h + 0.03) / 2), 0.012), 0.006, 0.15, seed), "wood")
        k.add(many([lambda p: box(p, v3(0, 0, h), (w + 0.004, d + 0.004, 0.008)), lambda p: box(p, v3(0, -d - 0.006, h - 0.015), (0.03, 0.008, 0.035), 0.006)]), "brass")
        k.add(lambda p: sphere(p, v3(0, -d - 0.016, h - 0.03), 0.008), "void")
        return {}
    k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.008), np.minimum.reduce([box(p, v3(x, 0, h / 2 + 0.03), (0.055, d - 0.02, h / 2)) for x in (-0.125, 0.0, 0.125)])), 0.006, 0.15, seed), "wood")
    k.add(rough(lambda p: box(rot_x(p - v3(0, d, h), 1.9), v3(0, -d, 0.012), (w, d, 0.012), 0.006), 0.006, 0.15, seed + 1), "wood")
    k.add(coins(-0.14, -0.04, 0.03, 0.02, (0.05, 0.065), 0.04), "gold")
    k.add(coins(-0.02, -0.02, 0.03, 0.02, (0.04, 0.07), 0.04), k.mat("silver", M.metal("#9a9ea0", "#5a5a58", 53, 0.12)))
    k.add(coins(0.105, -0.04, 0.03, 0.018, (0.03, 0.05), 0.04), "bronze")
    k.add(coins(0.3, -0.12, 0.0, 0.02, (0.012, 0.008), 0.06), "gold")
    return {}


@prop("parcels", "shop", cell=(2, 2), tags=["shop", "paper", "storage"], name_ko="포장한 꾸러미",
    variants={"single": {}, "stack": {"state": "stack"}, "cloth": {"state": "cloth"}})
def parcels(k, state="single", seed=1):
    """종이 · 천으로 싸서 끈으로 묶은 꾸러미(손님에게 내줄 물건)."""
    def one(c, w, d, h, a, mat="paper"):
        T = lambda p: rot_z(p, a, c)
        k.add(rough(lambda p: box(T(p), v3(c[0], c[1], c[2] + h), (w, d, h), 0.02), 0.012, 0.1, seed), mat)
        k.add(lambda p: np.minimum(box(T(p), v3(c[0], c[1], c[2] + h), (w + 0.004, 0.008, h + 0.004), 0.004), box(T(p), v3(c[0], c[1], c[2] + h), (0.008, d + 0.004, h + 0.004), 0.004)), "rope")
        k.add(lambda p: np.minimum(torus(T(p), v3(c[0] + 0.02, c[1], c[2] + 2 * h + 0.008), 0.018, 0.005), torus(T(p), v3(c[0] - 0.02, c[1], c[2] + 2 * h + 0.008), 0.018, 0.005)), "rope")
    if state == "single":
        one(v3(0, 0, 0), 0.15, 0.11, 0.07, 0.2)
    elif state == "stack":
        one(v3(-0.06, 0.04, 0), 0.19, 0.14, 0.08, 0.1)
        one(v3(0.2, -0.12, 0), 0.1, 0.08, 0.055, -0.4, "linen")
        one(v3(-0.08, 0.03, 0.16), 0.12, 0.1, 0.055, 0.5)
    else:   # 보자기 꾸러미
        k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.11), (0.17, 0.15, 0.12)), cone(p, v3(0, 0, 0.19), 0.07, 0.1), 0.04) + np.sin(np.arctan2(p[:, 1], p[:, 0]) * 6.0) * 0.006, 0.02, 0.1, seed), "cloth_b")
        k.add(many([lambda p, a=a: ell(rot_z(p, a), v3(0.06, 0, 0.27), (0.07, 0.02, 0.03)) for a in (0.3, 2.6)]), "cloth_b")
        k.add(tag(0.1, -0.15, 0.2, 1.0), "paper")
    return {}


def _scribble(c, x0, y0, x1, rows, gap, seed, color="#2a2018", alpha=0.75, width=1.3):
    """읽히지 않는 글줄(짧은 획 묶음)."""
    rng = np.random.default_rng(seed)
    m = np.zeros((c.H, c.W), F)
    for r in range(rows):
        x, y = x0, y0 + r * gap
        end = x1 - rng.uniform(0, (x1 - x0) * 0.35)
        while x < end:
            ln = rng.uniform(2.5, 6.0)
            pts = [(x, y + rng.uniform(-1, 1)), (x + ln * 0.5, y + rng.uniform(-1.6, 1.6)), (x + ln, y + rng.uniform(-1, 1))]
            m = np.maximum(m, c.seg(pts, width, False))
            x += ln + rng.uniform(1.5, 3.0)
    c.paint(m, color, alpha)


@flat("price_tags", "shop", layer="wall_decal", cell=(96, 80), tags=["shop", "paper", "sign"], name_ko="가격표와 상품 라벨",
    variants={"tag": {"kind": "tag", "seed": 1}, "tags_row": {"kind": "row", "seed": 2}, "label_strip": {"kind": "strip", "seed": 3}, "chalk_board": {"kind": "board", "seed": 4}, "chalk_board_worn": {"kind": "board", "seed": 5, "worn": True}})
def price_tags(c, kind="tag", seed=1, worn=False):
    """벽 · 선반 · 상자에 붙이는 종이 꼬리표, 선반 턱 라벨 띠, 분필로 적은 값 판(눈금 · 낙서 — 읽히는 글자는 없다)."""
    paper = np.array([0.72, 0.67, 0.53], F)

    def one(cx, cy, s, rot, sd):
        pts = [(-11, -7), (5, -7), (11, 0), (5, 7), (-11, 7)]
        ca, sa = np.cos(rot), np.sin(rot)
        P = [(cx + (x * ca - y * sa) * s, cy + (x * sa + y * ca) * s) for x, y in pts]
        m = c.poly(P)
        c.paint(m, paper * (0.88 + c.noise(6, sd)[..., None] * 0.2))
        hx, hy = cx + (7 * ca) * s, cy + (7 * sa) * s
        c.paint(c.ring(hx, hy, 1.6 * s, 1.2), "#2a2018", 0.9)
        c.paint(c.seg([(hx, hy), (hx + 5 * s, hy - 9 * s), (hx + 3 * s, hy - 15 * s)], 1.2, False), "#6a5a3a", 0.9)
        rng = np.random.default_rng(sd)
        for r in range(2):
            x = cx - 8 * s
            while x < cx + 2 * s:
                ln = rng.uniform(2, 4) * s
                dx0, dy0 = (x - cx), (-3 + r * 5) * s
                c.paint(c.seg([(cx + dx0 * ca - dy0 * sa, cy + dx0 * sa + dy0 * ca), (cx + (dx0 + ln) * ca - dy0 * sa, cy + (dx0 + ln) * sa + dy0 * ca)], 1.2, False), "#2a2018", 0.75)
                x += ln + 2 * s
        c.paint(c.rim(m, 1.2), "#16100e", 0.85)
    if kind == "tag":
        one(46, 44, 1.5, -0.25, seed)
    elif kind == "row":
        for i, (x, y, r) in enumerate(((18, 42, -0.5), (40, 46, -0.2), (62, 42, -0.6), (82, 46, -0.35))):
            one(x, y, 0.95, r, seed * 7 + i)
        c.paint(c.seg([(4, 22), (30, 26), (60, 24), (92, 27)], 1.6, False), "#6a5a3a", 0.95)
    elif kind == "strip":
        body = c.rect(3, 30, 93, 48, 0.8)
        c.paint(body, hexc_("#4a3a2a") * (0.85 + c.noise(10, seed)[..., None] * 0.3))
        c.shade(c.rect(3, 30, 93, 33), 0.25)
        for i in range(4):
            x0 = 7 + i * 22
            lab = c.rect(x0, 33, x0 + 17, 45, 0.7)
            c.paint(lab, paper * (0.9 + c.noise(5, seed + i)[..., None] * 0.15))
            _scribble(c, x0 + 2, 37, x0 + 15, 2, 4.5, seed * 5 + i, width=1.1)
            c.paint(c.rim(lab, 1.0), "#16100e", 0.7)
        c.paint(c.rim(body, 1.4), "#16100e", 0.9)
    else:
        frame = c.rect(6, 6, 90, 74, 1.0)
        c.paint(frame, hexc_("#5a4430") * (0.8 + c.noise(9, seed)[..., None] * 0.35))
        slate = c.rect(11, 11, 85, 69, 0.8)
        c.paint(slate, hexc_("#262826") * (0.85 + c.noise(12, seed + 1)[..., None] * 0.35))
        c.paint(slate * c.noise(18, seed + 2), "#8a8a84", 0.22 if not worn else 0.45)   # 지운 분필 자국
        rng = np.random.default_rng(seed)
        chalk = "#c8c4b4"
        for r in range(4):
            y = 20 + r * 12
            if worn and r in (1, 3):
                continue
            _scribble(c, 16, y, 46, 1, 1, seed * 11 + r, chalk, 0.8, 1.5)
            n = int(rng.integers(2, 6))                                   # 값 = 세로 눈금 묶음
            m = np.zeros((c.H, c.W), F)
            for i in range(n):
                x = 56 + i * 4.2
                m = np.maximum(m, c.seg([(x, y - 3.5), (x + rng.uniform(-0.6, 0.6), y + 3.5)], 1.5, False))
            if n == 5:
                m = np.maximum(m, c.seg([(54, y + 2.5), (76, y - 2.5)], 1.5, False))
            c.paint(m, chalk, 0.85)
        c.paint(c.rim(slate, 1.2), "#0e0c0c", 0.8)
        c.paint(c.rim(frame, 1.6), "#16100e", 0.9)
        c.paint(c.ring(48, 6, 2.2, 1.6), "#3a3030", 0.9)


def hexc_(s):
    return M.hexc(s)
