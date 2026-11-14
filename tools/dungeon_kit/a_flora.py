"""식생(에셋 라이브러리 — docs/asset_library): 나무 · 덤불 · 풀 · 꽃 · 갈대 · 그루터기. 나무 부품은 2층 숲과 같다(tools/f2_art/trees.py).
공용: 활엽수 · 침엽수 · 덤불 · 키 큰 풀 · 꽃 무더기 · 그루터기 · 통나무 · 부들.
지역 확장: 매마른 가시나무(덩굴 · 잎 · 보랏빛 광채 · 살아 움직임) · 밀림의 거목(옹이구멍) · 검은 불에 타는 나무 · 가시갈대.
나무는 줄기 둘레만 막는다(collide) — 수관은 머리 위를 지나간다."""
import numpy as np

import fx
import mats as M
import sdf
import trees as T
from kit import (F, box, cap, cone, cyl, ell, hcyl, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import hexc, sstep

MOSS = "#4c5e30"
VIOLET = "#a070e0"


def _mats(k, seed=1):
    for name, fn in {"bark": M.bark("#4a3c2e", MOSS), "bark_d": M.bark("#3a3026", MOSS, 5), "bark_dry": M.bark("#5a5046", None, 6), "bark_burnt": M.bark("#1c1a1a", None, 7),
            "bark_j": M.bark("#54463a", "#3e5a2c", 8), "leaf_a": M.leaf("#3e6a2c"), "leaf_ad": M.leaf("#2c4e2a", 0.3, 9, 0.06), "needle": M.leaf("#274a2c", 0.22, 11, 0.05),
            "leaf_j": M.leaf("#2e5a30", 0.4, 12, 0.08), "leaf_jd": M.leaf("#1e4028", 0.4, 13, 0.04), "leaf_dry2": M.leaf("#6a6234", 0.3, 14, 0.1), "vine": M.leaf("#3a4a26", 0.2, 15, 0.04),
            "reed": M.plain("#8a7a4a", 0.3, 0.06, 16), "reed_d": M.plain("#5e5434", 0.3, 0.06, 17), "grass": M.leaf("#4a6a30", 0.12, 18, 0.1), "grass_d": M.leaf("#34502a", 0.12, 19, 0.05),
            "petal_w": M.plain("#d8d2bc", 0.1, 0.1, 20), "petal_y": M.plain("#c8b050", 0.12, 0.1, 21), "petal_v": M.plain("#9a80b8", 0.12, 0.1, 22), "petal_r": M.plain("#a8483c", 0.12, 0.1, 23),
            "fruit": M.plain("#a83a2c", 0.15, 0.1, 24), "rings": M.rings("#a08a5c", "#4a3c2e"), "snow": M.plain("#b8c2cc", 0.1, 0.4, 25), "cattail": M.plain("#4a3424", 0.2, 0.05, 26)}.items():
        k.mat(name, fn)


def _tree(k, seed, h, r, crown=(1.5, 1.0), clump=(0.45, 0.7), n=14, bark="bark", leaf=("leaf_a", "leaf_ad"), split=0.42, spread=0.42, xmax=2.2, depth=4, roots=5):
    """활엽수 한 그루(줄기 밑동 = 원점). leaf = None이면 벗은 가지만. → (가지 마디, 가지 끝)."""
    rng = np.random.default_rng(seed)
    base = v3(0, 0, 0)
    segs, tips = T.limbs(rng, base, h, r, depth, spread, split, 0.5, xmax)
    segs += T.roots(rng, base, r, roots)
    k.add(T.trunk_fn(segs, seed), bark)
    tw = T.twig_fn(segs)
    if tw is not None:
        k.add(tw, bark)
    if leaf:
        tp = np.array(tips)
        mid = tp.mean(0) + v3(0, 0, crown[1] * 0.15)
        size = np.array([crown[0], crown[0] * 0.7, crown[1]], F)
        cs = [t + v3(0, 0, clump[0] * 0.2) for t in tips]
        while len(cs) < n + len(tips) // 2:
            q = rng.normal(0, 0.5, 3).astype(F)
            cs.append(mid + q / max(1.0, float(np.sqrt((q * q).sum()))) * size)
        cs.sort(key=lambda c: c[2] - c[1] * 0.3)
        half = len(cs) * 2 // 5
        k.add(T.crown_fn(rng, cs[:half], clump[0], clump[1], seed + 3), leaf[1])
        k.add(T.crown_fn(rng, cs[half:], clump[0], clump[1], seed), leaf[0])
    return segs, tips


def _tufts(pts, h0, h1, rng, lean=0.25, r=0.012, n=1):
    """풀잎 · 줄기 다발: 점마다 위로 뻗는 가는 막대 n개 → 한 덩어리 거리 함수."""
    caps = []
    for x, y in pts:
        for _ in range(n):
            h = rng.uniform(h0, h1)
            caps.append((v3(x, y, 0), v3(x + rng.uniform(-lean, lean) * h, y + rng.uniform(-lean, lean) * h * 0.5, h), r))

    def fn(p):
        d = np.full(len(p), 9.0, F)
        for a, b, rr in caps:
            d = np.minimum(d, cap(p, a, b, rr, rr * 0.3))
        return d
    return fn, caps


TREE = {"far": 9.0, "foot": 0.9, "dx": -0.6}   # 그림자가 오른쪽으로 지므로 발을 왼쪽에 둔다(그림 칸 끝에서 그림자가 잘리지 않게)


# ── 공용 나무 ────────────────────────────────────────────────────────────────

@prop("tree_broadleaf", "flora", cell=(7, 7), collide=(0.6, 0.5), tags=["tree", "forest"], name_ko="활엽수",
    variants={"a": {"seed": 3}, "b": {"seed": 12}, "c": {"seed": 21, "h": 3.4}, "young": {"seed": 5, "h": 1.7}, "bare": {"seed": 8, "bare": True}, "fruit": {"seed": 14, "fruit": True}, "autumn": {"seed": 3, "dry": True}})
def tree_broadleaf(k, h=2.8, bare=False, fruit=False, dry=False, seed=1):
    _mats(k, seed)
    s = h / 2.8
    segs, tips = _tree(k, seed, h, 0.2 * s, (1.5 * s, 1.0 * s), (0.42 * s, 0.68 * s), 14, "bark_dry" if bare else "bark", None if bare else (("leaf_dry2", "leaf_ad") if dry else ("leaf_a", "leaf_ad")), xmax=2.0 * s)
    if fruit:   # 열매가 맺혔다
        rng = np.random.default_rng(seed + 9)
        for t in tips[:12]:
            c = t + v3(rng.uniform(-0.3, 0.3), -0.45 * s + rng.uniform(-0.1, 0.1), rng.uniform(-0.35, 0.1))
            k.add(lambda p, c=c: sphere(p, c, 0.075), "fruit")
    return dict(TREE)


@prop("tree_pine", "flora", cell=(7, 8), collide=(0.5, 0.45), tags=["tree", "forest", "cold"], name_ko="침엽수",
    variants={"a": {"seed": 4}, "b": {"seed": 15, "h": 3.2}, "young": {"seed": 7, "h": 2.0}, "snowy": {"seed": 4, "snow": True}, "dead": {"seed": 9, "dead": True}})
def tree_pine(k, h=4.0, snow=False, dead=False, seed=1):
    _mats(k, seed)
    rng = np.random.default_rng(seed)
    base = v3(0, 0, 0)
    r = 0.045 * h + 0.04
    segs = [(base, base + v3(rng.uniform(-0.06, 0.06), 0, h), r, r * 0.12)] + T.roots(rng, base, r, 5, 2.0)
    k.add(T.trunk_fn(segs, seed, 0.08, 0.04), "bark_dry" if dead else "bark_d")
    if dead:    # 가지만 남았다
        for i in range(9):
            z, a = h * (0.3 + 0.07 * i), i * 2.4
            ln = 0.75 * (1.0 - i / 11)
            k.add(lambda p, z=z, a=a, ln=ln: cap(p, v3(0, 0, z), v3(np.cos(a) * ln, np.sin(a) * ln * 0.6, z - 0.12), 0.035, 0.008), "bark_dry")
        return dict(TREE)
    tiers = T.tiers_fn(base, h * 0.3, h * 1.02, r * 5.0 + 0.5, int(h * 1.5), seed)
    k.add(tiers, "needle")
    if snow:    # 가지 단마다 얹힌 눈
        k.add(lambda p: np.maximum(tiers(p - v3(0, 0, 0.05)) - 0.0, 0.5 - sdf.fbm(p * np.array([1, 1, 2.5], F), 0.3, seed + 2, 2) + (h * 0.45 - p[:, 2]) * 0.1) * 0.8, "snow")
    return dict(TREE)


# ── 매마른 가시나무(마녀의 숲 — 지역 확장: 활엽수의 틀 + 가시 · 덩굴) ──────────

def _sway(fn, amp):
    """나무 전체가 한쪽으로 휜다(살아 움직이는 나무의 프레임)."""
    return lambda p: fn(p + np.stack([amp * np.clip(p[:, 2], 0, 9) ** 1.6, np.zeros(len(p), F), np.zeros(len(p), F)], 1).astype(F))


@prop("tree_thorn", "flora", cell=(7, 7), collide=(0.6, 0.5), tags=["tree", "witch", "thorn"], name_ko="매마른 가시나무", reuse="ext", base="tree_broadleaf",
    variants={"a": {"seed": 3}, "b": {"seed": 11}, "c": {"seed": 19, "h": 3.3}, "vined": {"seed": 3, "vine": True}, "vined_b": {"seed": 11, "vine": True}, "leafy": {"seed": 3, "leafy": True},
        "stir": {"seed": 11, "vine": True, "frames": 4}, "glow": {"seed": 19, "h": 3.3, "glow": True, "frames": 4}},
    light={"color": VIOLET, "radius": 3.5, "at": (0, 0, 1.0), "flicker": 0.15, "variants": ["glow"]}, fps=4,
    meta={"states": {"idle": "vined_b", "active": "stir"}, "note": "stir = 살아 움직이는 나무(4프레임 흔들림) · glow = 껍질에서 보랏빛 광채가 새는 나무(입구 표지) · leafy = 잎이 무성해진 모습"})
def tree_thorn(k, h=2.7, vine=False, leafy=False, glow=False, f=0, seed=1):
    _mats(k, seed)
    rng = np.random.default_rng(seed)
    base = v3(0, 0, 0)
    segs, tips = T.limbs(rng, base, h, 0.19, 4, 0.62, 0.36, 0.3, 2.2)      # 낮게 갈라져 옆으로 비틀린 가지
    segs += T.roots(rng, base, 0.19, 6, 2.6)
    amp = 0.035 * np.sin(f * 1.5708) if (vine and f is not None) else 0.0
    wrap = (lambda fn: _sway(fn, amp)) if amp else (lambda fn: fn)
    k.add(wrap(T.trunk_fn(segs, seed, 0.09, 0.09)), "bark_dry")
    tw = T.twig_fn(segs)
    if tw is not None:
        k.add(wrap(tw), "bark_dry")
    thorns = []
    for a, b, ra, rb in segs:                                               # 가지마다 돋은 가시
        ln = float(np.sqrt(((b - a) ** 2).sum()))
        for t in np.arange(0.2, 1.0, 0.16 / max(ln, 0.2)):
            c = a + (b - a) * t
            d = rng.normal(0, 1, 3).astype(F)
            d[2] = abs(d[2]) * 0.4
            d /= np.sqrt((d * d).sum())
            rr = ra + (rb - ra) * t
            thorns.append((c, c + d * (rr + 0.13), max(0.012, rr * 0.3)))
    thorns = thorns[:90]

    def thorn_fn(p):
        d = np.full(len(p), 9.0, F)
        for a, b, rr in thorns:
            d = np.minimum(d, cap(p, a, b, rr, 0.002))
        return d
    k.add(wrap(thorn_fn), "bark_d")
    if vine:                                                                # 줄기를 휘감은 덩굴 + 가지에서 늘어진 가닥
        coil = [(v3(np.cos(t * 5.5) * (0.24 - t * 0.07), np.sin(t * 5.5) * (0.24 - t * 0.07), t * h * 0.42), 0.035) for t in np.linspace(0, 1, 22)]
        k.add(wrap(lambda p: np.minimum.reduce([cap(p, coil[i][0], coil[i + 1][0], 0.035, 0.03) for i in range(len(coil) - 1)])), "vine")
        hang = [(t, t - v3(rng.uniform(-0.1, 0.1), 0.05, rng.uniform(0.4, 1.0))) for t in tips[::2][:9]]
        k.add(wrap(lambda p: np.minimum.reduce([cap(p, a, b, 0.022, 0.01) for a, b in hang])), "vine")
    if leafy:                                                               # 잎이 풍성하게 돋았다
        k.add(T.crown_fn(rng, [t + v3(0, 0, 0.1) for t in tips], 0.3, 0.5, seed), "leaf_a")
    if not glow:
        return dict(TREE)

    def aura(img, vw):                                                      # 껍질 틈에서 새는 보랏빛
        hh, ww = img.shape[:2]
        yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
        cx, cy = vw.px(0, 0, 0.9)
        from paint2d import vnoise
        n = vnoise(hh, ww, 5.0, seed * 3)
        body = (img[..., 3] > 128) * sstep(1.0 - np.hypot((xx - cx) / (0.45 * vw.u), (yy - cy) / (1.1 * vw.u)), 0, 0.6)
        seam = sstep(n, 0.58, 0.66) * body * (0.7 + 0.3 * np.sin(f * 1.5708 + yy * 0.05))
        img = fx._over(img, seam * 0.9, hexc("#c8a0ff"))
        return fx.halo(img, cx, cy, 70, VIOLET, 0.4 + 0.08 * np.sin(f * 1.5708))
    return dict(TREE, post=[aura])


# ── 밀림의 거목 · 불타는 나무 ────────────────────────────────────────────────

@prop("tree_giant", "flora", cell=(11, 11), collide=(1.5, 0.9), tags=["tree", "jungle", "giant"], name_ko="밀림의 거목", reuse="ext", base="tree_broadleaf", interact="entrance",
    variants={"a": {"seed": 4}, "b": {"seed": 13}, "hollow": {"seed": 4, "hollow": True}}, meta={"note": "hollow = 뿌리의 옹이구멍(들어가는 입구로 쓴다)"})
def tree_giant(k, hollow=False, seed=1):
    _mats(k, seed)
    rng = np.random.default_rng(seed)
    base = v3(0, 0, 0)
    segs, tips = T.limbs(rng, base, 5.2, 0.62, 3, 0.5, 0.5, 0.45, 2.6)
    k.add(T.trunk_fn(segs, seed, 0.14, 0.12), "bark_j")
    tw = T.twig_fn(segs)
    if tw is not None:
        k.add(tw, "bark_j")
    for i in range(7):   # 판처럼 벌어진 버팀뿌리
        a = i * 0.9 + rng.uniform(-0.2, 0.2)
        e = v3(np.cos(a) * 1.5, np.sin(a) * 1.0, 0.0)
        k.add(rough(lambda p, e=e: cap(p, v3(0, 0, 1.3), e, 0.2, 0.07), 0.05, 0.2, seed + i), "bark_j")
    if hollow:
        k.add(lambda p: ell(p, v3(0.05, -0.55, 0.45), (0.3, 0.5, 0.5)), "void")
    cs = [t + v3(0, 0, 0.2) for t in tips] + [np.array(tips).mean(0) + np.clip(rng.normal(0, 0.5, 3), -0.8, 0.8).astype(F) * np.array([1.3, 0.7, 0.45], F) for _ in range(12)]
    cs.sort(key=lambda c: c[2] - c[1] * 0.3)
    k.add(T.crown_fn(rng, cs[:len(cs) // 2], 0.6, 0.95, seed + 3, 0.4), "leaf_jd")
    k.add(T.crown_fn(rng, cs[len(cs) // 2:], 0.6, 0.95, seed, 0.4), "leaf_j")
    hang = [(t, t - v3(rng.uniform(-0.15, 0.15), 0.1, rng.uniform(0.8, 2.2))) for t in tips[:10]]   # 늘어진 덩굴
    k.add(lambda p: np.minimum.reduce([cap(p, a, b, 0.03, 0.012) for a, b in hang]), "vine")
    return {"far": 11.0, "foot": 1.4, "scale": 0.72, "dx": -0.8}


@prop("tree_burning", "flora", cell=(7, 7), collide=(0.6, 0.5), tags=["tree", "fire", "burnt"], name_ko="검은 불에 타는 나무", reuse="region",
    variants={"black_flame": {"seed": 6, "frames": 4}, "black_flame_b": {"seed": 17, "frames": 4}, "charred": {"seed": 6, "fire": False}},
    light={"color": "#8a5ad0", "radius": 2.5, "at": (0, 0, 1.6), "flicker": 0.4, "variants": ["black_flame", "black_flame_b"]}, fps=8)
def tree_burning(k, fire=True, f=0, seed=1):
    """숯이 된 나무가 흑색 불꽃에 싸여 탄다(불꽃 = 검은 속 + 보랏빛 가장자리)."""
    _mats(k, seed)
    segs, tips = _tree(k, seed, 2.6, 0.2, bark="bark_burnt", leaf=None, depth=3)
    k.rubble([(0.4, -0.25), (-0.35, -0.2)], "coal", 0.03, 0.06)
    if not fire:
        return dict(TREE)

    def flames(img, vw):
        for i, t in enumerate(tips[:7] + [v3(0, -0.1, 0.9)]):
            x, y = vw.px(float(t[0]), float(t[1]) - 0.1, float(t[2]) - 0.15)
            img = fx.flame(img, x, y, 26 + (i % 3) * 7, seed + i, f or 0, "black", 0.36, 1.3, 0.16)
        return img
    return dict(TREE, post=[flames])


fx.PAL.setdefault("black", ("#3a2866", "#140e1e", "#060408", "#6a4ab0"))   # 흑색 불꽃: 보랏빛 가장자리 → 검은 속


# ── 덤불 · 풀 · 꽃 · 갈대 ────────────────────────────────────────────────────

@prop("bush", "flora", cell=(3, 3), tags=["bush", "forest"], name_ko="덤불",
    variants={"a": {"seed": 3}, "b": {"seed": 10}, "wide": {"seed": 6, "wide": True}, "flowering": {"seed": 3, "flower": True}, "dry": {"seed": 10, "dry": True}, "snowy": {"seed": 6, "snow": True}})
def bush(k, wide=False, flower=False, dry=False, snow=False, seed=1):
    _mats(k, seed)
    rng = np.random.default_rng(seed)
    w = 0.7 if wide else 0.45
    cs = [v3(rng.uniform(-w, w), rng.uniform(-0.2, 0.2), rng.uniform(0.2, 0.5)) for _ in range(9 if wide else 6)]
    crown = T.crown_fn(rng, cs, 0.2, 0.34, seed, 0.25)
    k.add(lambda p: np.maximum(crown(p), -p[:, 2]), "leaf_dry2" if dry else "leaf_a")
    k.add(lambda p: np.minimum.reduce([cap(p, v3(c[0] * 0.3, 0, 0), c, 0.03, 0.01) for c in cs[:4]]), "bark_d")
    if flower:
        for c in cs:
            for _ in range(3):
                q = c + v3(rng.uniform(-0.2, 0.2), -0.22, rng.uniform(0.0, 0.25))
                k.add(lambda p, q=q: sphere(p, q, 0.035), ("petal_w", "petal_r")[int(rng.integers(2))])
    if snow:
        k.add(lambda p: np.maximum(crown(p - v3(0, 0, 0.05)), 0.42 - p[:, 2] + (sdf.fbm(p, 0.25, seed, 2) - 0.5) * 0.4), "snow")
    return {}


@prop("grass_tall", "flora", cell=(3, 3), tags=["grass"], name_ko="키 큰 풀", variants={"a": {"seed": 3}, "b": {"seed": 9}, "c": {"seed": 16}, "dry": {"seed": 3, "dry": True}, "wide": {"seed": 12, "wide": True}})
def grass_tall(k, dry=False, wide=False, seed=1):
    """무릎까지 오는 수풀 한 무더기(지나갈 수 있다)."""
    _mats(k, seed)
    rng = k.rng
    pts = k.scatter(26 if wide else 14, 0.8 if wide else 0.42, 0.3)
    fn, _ = _tufts(pts, 0.25, 0.55, rng, 0.35, 0.016, 2)
    k.add(fn, "reed" if dry else "grass")
    fn2, _ = _tufts(pts[::2], 0.15, 0.35, rng, 0.5, 0.02, 2)
    k.add(fn2, "reed_d" if dry else "grass_d")
    return {"shadow": 0.35}


@prop("reed_thorn", "flora", cell=(4, 4), tags=["reed", "thorn", "tall"], name_ko="가시갈대", reuse="region",
    variants={"a": {"seed": 3}, "b": {"seed": 10}, "c": {"seed": 18}, "dense": {"seed": 5, "n": 34, "w": 0.95}, "sparse": {"seed": 7, "n": 7}, "trampled": {"seed": 9, "down": True}},
    meta={"cover": True, "note": "어깨까지 올라오는 갈대 — 시야를 가리는 덮개로 쓴다(막지는 않는다). trampled = 밟혀 누운 자리"})
def reed_thorn(k, n=18, w=0.55, down=False, seed=1):
    _mats(k, seed)
    rng = k.rng
    pts = k.scatter(n, w, 0.3)
    if down:   # 밟혀 누운 줄기
        caps = [(v3(x, y, 0.03), v3(x + rng.uniform(0.4, 0.9), y + rng.uniform(-0.25, 0.25), 0.06), 0.02) for x, y in pts]
        k.add(lambda p: np.minimum.reduce([cap(p, a, b, r, r * 0.4) for a, b, r in caps]), "reed")
        return {"shadow": 0.3}
    fn, caps = _tufts(pts, 1.05, 1.45, rng, 0.12, 0.022, 1)
    k.add(fn, "reed")
    heads = [(b, b + (b - a) / np.sqrt(((b - a) ** 2).sum()) * 0.22) for a, b, _ in caps]          # 이삭
    k.add(lambda p: np.minimum.reduce([cap(p, a, b, 0.035, 0.012) for a, b in heads]), "reed_d")
    spikes = []
    for a, b, _ in caps:                                                                              # 줄기마다 돋은 가시
        for t in (0.3, 0.5, 0.7):
            c = a + (b - a) * t
            s = 1 if rng.random() < 0.5 else -1
            spikes.append((c, c + v3(s * 0.1, 0, 0.06)))
    k.add(lambda p: np.minimum.reduce([cap(p, a, b, 0.012, 0.002) for a, b in spikes]), "bark_d")
    return {"shadow": 0.4}


@prop("flowers", "flora", cell=(3, 2), tags=["flower", "grass"], name_ko="들꽃 무더기",
    variants={"white": {"col": "w", "seed": 3}, "yellow": {"col": "y", "seed": 8}, "violet": {"col": "v", "seed": 13}, "red": {"col": "r", "seed": 5}, "mixed_a": {"col": "wyv", "seed": 17, "n": 16}, "mixed_b": {"col": "ryw", "seed": 22, "n": 16}})
def flowers(k, col="w", n=10, seed=1):
    _mats(k, seed)
    rng = k.rng
    pts = k.scatter(n, 0.6, 0.28)
    fn, caps = _tufts(pts, 0.14, 0.3, rng, 0.2, 0.01, 1)
    k.add(fn, "grass")
    for i, (a, b, _) in enumerate(caps):
        m = "petal_" + col[i % len(col)]
        k.add(lambda p, b=b: ell(p, b, (0.075, 0.07, 0.04)), m)
        k.add(lambda p, b=b: sphere(p, b + v3(0, -0.03, 0.03), 0.026), "petal_y" if m != "petal_y" else "bark_d")
    leaf, _ = _tufts(pts[::2], 0.06, 0.14, rng, 0.9, 0.018, 2)
    k.add(leaf, "grass_d")
    return {"shadow": 0.25}


@prop("cattail", "flora", cell=(3, 3), tags=["swamp", "water", "reed"], name_ko="부들", variants={"a": {"seed": 4}, "b": {"seed": 11}, "c": {"seed": 19}})
def cattail(k, seed=1):
    """물가에 선 부들 무더기."""
    _mats(k, seed)
    rng = k.rng
    pts = k.scatter(8, 0.35, 0.2)
    fn, caps = _tufts(pts, 0.6, 1.0, rng, 0.1, 0.014, 1)
    k.add(fn, "grass_d")
    k.add(lambda p: np.minimum.reduce([hcyl(p, b - (b - a) * 0.22, b - (b - a) * 0.05, 0.035) for a, b, _ in caps[::2]]), "cattail")
    blades, _ = _tufts(pts, 0.4, 0.75, rng, 0.35, 0.02, 1)
    k.add(blades, "grass")
    return {"shadow": 0.3}


# ── 그루터기 · 통나무 ────────────────────────────────────────────────────────

@prop("stump", "flora", cell=(3, 3), collide=(0.6, 0.45), tags=["tree", "wood"], name_ko="그루터기", variants={"a": {"seed": 3}, "mossy": {"seed": 8, "moss": True}, "burnt": {"seed": 5, "burnt": True}, "axe": {"seed": 3, "axe": True}})
def stump(k, moss=False, burnt=False, axe=False, seed=1):
    _mats(k, seed)
    rng = np.random.default_rng(seed)
    bark = "bark_burnt" if burnt else "bark"
    body = lambda p: cyl(p, v3(0, 0, 0), 0.3, 0.36, 0.02) + np.cos(np.arctan2(p[:, 1], p[:, 0]) * 7 + 1.0) * 0.02
    k.add(rough(lambda p: np.maximum(body(p), p[:, 2] - 0.36 - (sdf.noise(p, 0.15, seed) - 0.5) * (0.25 if burnt else 0.04)), 0.03, 0.15, seed), bark)
    k.add(lambda p: cyl(p, v3(0, 0, 0.33), 0.26, 0.035), "coal" if burnt else "rings")
    roots = T.roots(rng, v3(0, 0, 0), 0.26, 5, 2.2)
    k.add(lambda p: np.minimum.reduce([cap(p, a, b, ra, rb) for a, b, ra, rb in roots]), bark)
    if moss:
        k.add(lambda p: np.maximum(cyl(p, v3(0, 0, 0.2), 0.33, 0.19, 0.03), sdf.fbm(p, 0.2, seed, 2) - 0.5), "moss")
    if axe:
        k.add(lambda p: cap(rot_y(p, 0.7, (0.05, 0, 0.4)), v3(0.05, 0, 0.4), v3(0.05, 0, 0.95), 0.022), "wood_l")
        k.add(lambda p: box(rot_y(p, 0.7, (0.05, 0, 0.4)), v3(0.1, 0, 0.44), (0.1, 0.014, 0.07)), "iron")
    return {}


@prop("log", "flora", cell=(4, 3), collide=(1.5, 0.4), tags=["tree", "wood"], name_ko="쓰러진 통나무", variants={"a": {"seed": 3}, "mossy": {"seed": 9, "moss": True}, "hollow": {"seed": 6, "hollow": True}, "burnt": {"seed": 12, "burnt": True}})
def log(k, moss=False, hollow=False, burnt=False, seed=1):
    _mats(k, seed)
    a, b = v3(-0.8, 0.05, 0.2), v3(0.8, -0.08, 0.19)
    bark = "bark_burnt" if burnt else "bark"
    k.add(rough(lambda p: hcyl(p, a, b, 0.2), 0.035, 0.15, seed), bark)
    for e, s in ((a, -1), (b, 1)):
        k.add(lambda p, e=e, s=s: hcyl(p, e + v3(s * 0.0, 0, 0), e + v3(s * 0.012, 0, 0), 0.17), "void" if (hollow and s == -1) else ("coal" if burnt else "rings"))
    k.add(rough(lambda p: cap(p, v3(0.25, 0, 0.3), v3(0.42, 0.15, 0.62), 0.05, 0.015), 0.01, 0.1, seed), bark)   # 부러진 가지
    if moss:
        k.add(lambda p: np.maximum(hcyl(p, a, b, 0.225), 0.26 - p[:, 2] + (sdf.fbm(p, 0.25, seed, 2) - 0.5) * 0.3), "moss")
    return {}
