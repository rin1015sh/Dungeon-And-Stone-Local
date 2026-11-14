"""야외 · 자연 바닥(에셋 라이브러리 — docs/asset_library): 풀밭 · 숲 · 진흙 · 습지 · 갈라진 땅 · 암반 · 눈 · 얼음 · 재 · 붉은 흙 · 뼈밭 · 물 · 용암.
a_floor.py(실내 석재 바닥)와 같은 틀 — 4 × 4칸(256px)을 덮는, 사방으로 이어지는 넓은 그림. 칠하는 부품은 2층 바닥(tools/f2_art/ground.py · tex.py)을 그대로 쓴다.
물 · 용암은 4프레임이 돌아 이어진다(같은 잡음 둘을 cos · sin으로 섞어 한 바퀴) — TileSet에는 첫 프레임만 실린다(직접 그릴 때 kit.texture(id, v, frame))."""
import numpy as np
from PIL import Image

import ground
import surf
import tex
from kit import flat
from surf import W, F, fbm, hexc, pnoise

TILE = {"tile": [64, 64], "span": 4}
TAU = 2 * np.pi


def _rgba(rgb):
    return np.concatenate([rgb, np.full(rgb.shape[:2] + (1,), 255, np.uint8)], -1)


def _small(a):
    """W × W 마스크 → 256 × 256(0~1)."""
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((256, 256), Image.LANCZOS)).astype(F) / 255.0


def _lit(rgb, layers):
    """색 정리 뒤에 빛을 얹는다(layers = [(마스크 W × W, 색, 세기)])."""
    out = rgb.astype(F) / 255.0
    for m, col, k in layers:
        out = out + hexc(col)[None, None, :] * _small(m)[..., None] * k
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def _loop(cells, seed, f, n=4, octaves=3):
    """프레임 f에서의 이어지는 잡음 — n프레임에 한 바퀴 돈다."""
    a = TAU * f / n
    return np.clip(0.5 + (fbm(cells, seed, octaves) - 0.5) * np.cos(a) + (fbm(cells, seed + 77, octaves) - 0.5) * np.sin(a), 0, 1)


def _ground(id, name, variants=None, tags=(), **meta):
    return flat(id, "floor", layer="floor", cell=(256, 256), variants=variants or {"a": {"seed": 1}, "b": {"seed": 2}}, name_ko=name, meta=dict(TILE, **meta), tags=["floor", "ground"] + list(tags))


# ── 풀 · 숲 ──────────────────────────────────────────────────────────────────

def _grass(seed, base, dense=1.0, dry=0.0):
    rng = np.random.default_rng(seed)
    ly = tex.Layer()
    img, _ = ground.earth(base * 0.55, seed, 0.25, 0.6)
    patch = np.clip(fbm(5, seed + 20, 3) * 1.6 - 0.25, 0.15, 1.0)
    warm = np.array([1.25, 1.2, 0.8], F)
    g = [base * 0.7, base * 0.9, base * 1.1, base * warm]
    if dry:
        g = [c * (1 - dry) + hexc("#8a7a4a") * dry * (0.7 + 0.2 * i) for i, c in enumerate(g)]
    ground.strokes(ly, rng, int(9000 * dense), 8, 16, g[:2], 0.1, 0.7, 3.0, 0.95)
    ground.strokes(ly, rng, int(9000 * dense), 8, 18, g[1:3], 0.1, 0.6, 2.0, 0.95, patch)
    ground.strokes(ly, rng, int(3500 * dense), 10, 20, g[2:], 0.15, 0.5, 1.6, 0.9, patch ** 2)
    return img, ly, rng, patch


@_ground("ground_grass", "풀밭", {"a": {"seed": 1}, "b": {"seed": 2}, "dry": {"seed": 3, "dry": 0.6}}, tags=["grass"])
def ground_grass(c, seed=1, dry=0.0):
    img, ly, rng, _ = _grass(seed + 600, hexc("#4c6234"), 1.0, dry)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#5a5a3a" if dry else "#45552f", seed))


@_ground("ground_meadow", "들꽃 핀 잔디밭", {"a": {"seed": 1}, "b": {"seed": 2}}, tags=["grass", "flower"])
def ground_meadow(c, seed=1):
    """짧고 고른 잔디에 들꽃(흰 · 노란 · 옅은 보라)이 무리 지어 피었다."""
    img, ly, rng, patch = _grass(seed + 610, hexc("#56703a"), 1.1)
    bloom = np.clip(fbm(4, seed + 611, 3) * 2.2 - 0.75, 0, 1)
    cols = [hexc("#d8d2bc"), hexc("#c8b458"), hexc("#a892c0"), hexc("#d8d2bc")]
    for _ in range(520):
        x, y = rng.random() * W, rng.random() * W
        if rng.random() > bloom[int(y), int(x)]:
            continue
        col = cols[rng.integers(len(cols))] * rng.uniform(0.85, 1.05)
        r = rng.uniform(1.6, 2.6)
        for k in range(5):   # 꽃잎 다섯 + 가운데
            a = k * TAU / 5 + rng.uniform(0, 1)
            ly.blob(x + np.cos(a) * r, y + np.sin(a) * r * 0.8, r * 0.75, r * 0.6, col, 0.95, a, 6, 0.1, rng)
        ly.blob(x, y, r * 0.5, r * 0.4, hexc("#8a6a2a"), 1.0, 0, 6, 0.1, rng)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#4c5e34", seed, 0.14))


@_ground("ground_forest", "숲 바닥", tags=["forest"])
def ground_forest(c, seed=1):
    """검은 흙 + 이끼 얼룩 + 낙엽 + 잔가지."""
    return _rgba(surf.finish(ground.paint("forestfloor", hexc("#40372a"), seed + 620), "#3a3528", seed))


@_ground("ground_thicket", "덤불 우거진 숲 바닥", {"a": {"seed": 1}}, tags=["forest", "jungle"])
def ground_thicket(c, seed=1):
    """밀림 · 대수림: 젖은 검은 흙을 넓은 잎과 덩굴 줄기가 덮었다."""
    rng = np.random.default_rng(seed + 630)
    img, _ = ground.earth(hexc("#2e2a20"), seed + 630, 0.3, 1.1)
    ly = tex.Layer()
    cover = np.clip(fbm(5, seed + 631, 3) * 2.0 - 0.45, 0.1, 1.0)
    ground.leaves(ly, rng, 900, [hexc("#2c4a26"), hexc("#3a5a2a"), hexc("#26402a"), hexc("#48662e")], 7.0, 15.0, cover)
    for _ in range(26):   # 바닥을 기는 덩굴 줄기
        x, y, a = rng.random() * W, rng.random() * W, rng.uniform(0, TAU)
        pts = [(x, y)]
        for _k in range(9):
            a += rng.uniform(-0.6, 0.6)
            pts.append((pts[-1][0] + np.cos(a) * 16, pts[-1][1] + np.sin(a) * 16))
        ly.line([(px + 1.5, py + 2) for px, py in pts], tex.SHADOW, 0.6, 4.0)
        ly.line(pts, hexc("#4a3c26") * rng.uniform(0.8, 1.2), 1.0, 3.0)
    ground.leaves(ly, rng, 260, [hexc("#4a6a30"), hexc("#587a36")], 6.0, 12.0, cover ** 2)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#30382a", seed))


# ── 진흙 · 습지 · 마른 땅 ────────────────────────────────────────────────────

@_ground("ground_mud", "검은 진흙", tags=["mud", "dead"])
def ground_mud(c, seed=1):
    """발이 빠지는 검은 진흙: 질척한 결 + 고인 물 + 번들거림."""
    return _rgba(surf.finish(ground.paint("mudroad", hexc("#2c2826"), seed + 640), "#282624", seed, 0.24))


@_ground("ground_swamp", "습지", tags=["mud", "swamp", "water"])
def ground_swamp(c, seed=1):
    """물 고인 진창: 탁한 녹빛 물웅덩이 + 물가 풀 + 개구리밥."""
    rng = np.random.default_rng(seed + 650)
    img, h = ground.earth(hexc("#3a3a2a"), seed + 650, 0.28, 1.3, 0.03)
    n = fbm(4, seed + 651, 3)
    pool = np.clip((n - 0.5) * 12.0, 0, 1)
    depth = np.clip((n - 0.5) * 5.0, 0, 1)
    water = hexc("#232c22")[None, None, :] * (1.0 - depth[..., None] * 0.4) * (0.9 + fbm(20, seed + 652, 2)[..., None] * 0.2)
    img = surf.mix(img, pool * 0.95, water)
    rim = np.clip(1.0 - np.abs(n - 0.505) / 0.012, 0, 1)
    img = surf.mix(img, rim * 0.5, hexc("#1a1c16"))
    img = img + (np.clip((fbm(30, seed + 653, 2) - 0.66) * 6, 0, 1) * pool * depth)[..., None] * hexc("#7a8c7a") * 0.3
    ly = tex.Layer()
    bank = np.clip(1.0 - np.abs(n - 0.46) / 0.07, 0, 1)
    ground.strokes(ly, rng, 5200, 8, 18, [hexc("#3e5226"), hexc("#50622e"), hexc("#66703a")], 0.05, 0.5, 2.0, 0.9, bank)
    ground.strokes(ly, rng, 1500, 6, 12, [hexc("#3a4a26"), hexc("#4a5a2c")], 0.1, 0.7, 1.8, 0.8, np.clip(1 - pool, 0, 1) * 0.5)
    for _ in range(420):   # 개구리밥
        x, y = rng.random() * W, rng.random() * W
        if pool[int(y), int(x)] > 0.8 and fbm(7, seed + 654, 2)[int(y), int(x)] > 0.5:
            ly.blob(x, y, rng.uniform(1.6, 3.2), rng.uniform(1.4, 2.6), hexc("#5a7434") * rng.uniform(0.8, 1.15), 0.95, 0, 7, 0.15, rng)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#30362a", seed))


@_ground("ground_hardpan", "갈라진 마른 땅", tags=["desert", "dry"])
def ground_hardpan(c, seed=1):
    return _rgba(surf.finish(ground.paint("hardpan", hexc("#84725a"), seed + 660), "#74644e", seed))


@_ground("ground_redsoil", "붉은 땅", tags=["red", "dry"])
def ground_redsoil(c, seed=1):
    """붉게 물든 메마른 땅: 거친 흙 + 검붉은 얼룩 + 잔돌."""
    rng = np.random.default_rng(seed + 670)
    base = hexc("#6a3a30")
    img, h = ground.earth(base, seed + 670, 0.26, 1.3, 0.05)
    dark = np.clip((fbm(5, seed + 671, 3) - 0.52) * 4.0, 0, 1)
    img = surf.mix(img, dark * 0.5, hexc("#3a1c1a"))
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 6, 110, width=1.8, branch=0.25)
    ground.stones(ly, rng, 70, 2.0, 5.5, hexc("#5a4640"))
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#5c342c", seed, 0.12))


# ── 암반 · 뼈 ────────────────────────────────────────────────────────────────

@_ground("ground_rock", "암반", {"a": {"seed": 1}, "b": {"seed": 2}, "dark": {"seed": 3, "dark": True}}, tags=["cave", "stone"])
def ground_rock(c, seed=1, dark=False):
    """다듬지 않은 바위 바닥(동굴 · 협곡): 넓은 암반이 갈라져 있고, 틈에 잔돌과 흙."""
    rng = np.random.default_rng(seed + 680)
    base = hexc("#3a3836" if dark else "#62625e")
    img, gap = ground.slabs(seed + 680, 22, 1.0, base, base * 0.3, 3.4, 0.1, 0.9)
    img = img * (1.0 + (fbm(5, seed + 681, 3) - 0.5) * 0.3)[..., None] * tex.relief(fbm(18, seed + 682, 3), 1.6)[..., None]
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 7, 90, width=1.6, branch=0.2)
    ground.stones(ly, rng, 60, 1.8, 5.0, base * 1.15)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#2e2d2c" if dark else "#52524e", seed))


@_ground("ground_bones", "뼈가 깔린 땅", tags=["bone", "dead"])
def ground_bones(c, seed=1):
    """뼈와 뼛조각이 깔린 잿빛 땅."""
    rng = np.random.default_rng(seed + 690)
    base = hexc("#56524a")
    img, _ = ground.earth(base, seed + 690, 0.22, 1.2, 0.03)
    ly = tex.Layer()
    ground.stones(ly, rng, 40, 2.0, 4.5, base * 1.2)
    bone = hexc("#c4bca4")
    for _ in range(150):   # 긴 뼈: 대 + 양 끝 마디
        x, y, a, ln = rng.random() * W, rng.random() * W, rng.uniform(0, TAU), rng.uniform(9, 26)
        col = bone * rng.uniform(0.7, 1.05)
        dx, dy = np.cos(a) * ln, np.sin(a) * ln
        ly.line([(x + 1.5, y + 2.5), (x + dx + 1.5, y + dy + 2.5)], tex.SHADOW, 0.6, 4.0)
        ly.line([(x, y), (x + dx, y + dy)], col, 1.0, 3.0)
        for ex, ey in ((x, y), (x + dx, y + dy)):
            ly.blob(ex, ey, 3.0, 2.4, col, 1.0, a, 7, 0.2, rng)
    for _ in range(60):    # 갈비 조각(굽은 줄)
        x, y, a, ln = rng.random() * W, rng.random() * W, rng.uniform(0, TAU), rng.uniform(12, 22)
        pts = [(x + np.cos(a + t * 0.5) * ln * t, y + np.sin(a + t * 0.5) * ln * t) for t in np.linspace(0, 1, 5)]
        ly.line([(px + 1, py + 2) for px, py in pts], tex.SHADOW, 0.55, 3.0)
        ly.line(pts, bone * rng.uniform(0.65, 0.95), 1.0, 2.0)
    ground.stones(ly, rng, 140, 1.4, 3.0, bone * 0.9, 0.6)
    return _rgba(surf.finish(ly.over(np.clip(img, 0, 1)), "#5a564c", seed))


# ── 눈 · 얼음 ────────────────────────────────────────────────────────────────

@_ground("ground_snow", "눈밭", {"a": {"seed": 1}, "b": {"seed": 2}, "thin": {"seed": 3, "thin": True}}, tags=["snow", "ice"])
def ground_snow(c, seed=1, thin=False):
    """바람에 쓸린 눈: 완만한 눈 더미 결 + 푸른 그늘. thin = 눈이 얇아 바위가 드러났다."""
    rng = np.random.default_rng(seed + 700)
    h = fbm(4, seed + 700, 3) * 0.7 + fbm(14, seed + 701, 2) * 0.3
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    drift = np.sin(TAU * (3 * xx + 7 * yy) / W + (fbm(3, seed + 702, 2) - 0.5) * 7.0) * 0.5 + 0.5
    h = h + drift * 0.12
    lit = tex.relief(h, 3.0)
    img = hexc("#aab4c0")[None, None, :] * lit[..., None]
    img = img + (hexc("#7a8aa6") - img) * np.clip((1.0 - lit) * 1.6, 0, 1)[..., None] * 0.55     # 그늘은 푸르게
    ly = tex.Layer()
    if thin:
        bare = np.clip((fbm(6, seed + 703, 3) - 0.52) * 7.0, 0, 1)
        rock, _ = ground.slabs(seed + 704, 40, 1.0, hexc("#56585c"), hexc("#1c1d20"), 3.0, 0.14, 0.9)
        img = surf.mix(img, bare, rock)
        img = img * (1.0 - np.clip(np.roll(bare, (-4, -4), (0, 1)) - bare, 0, 1)[..., None] * 0.35)
        ground.stones(ly, rng, 40, 2.0, 5.0, hexc("#5a5c60"))
    out = surf.finish(ly.over(np.clip(img, 0, 1)), "#8c96a2" if not thin else "#7c858f", seed, 0.1)
    spark = (pnoise(256, seed + 705) > 0.985).astype(F) * np.clip(lit - 0.9, 0, 1) * 3.0
    return _rgba(_lit(out, [(spark, "#ffffff", 0.5)]))


@_ground("ground_ice", "얼음 바닥", {"a": {"seed": 1}, "b": {"seed": 2}, "clear": {"seed": 3, "clear": True}}, tags=["ice"])
def ground_ice(c, seed=1, clear=False):
    """얼어붙은 바닥: 푸른 얼음 속 흰 금과 공기 방울, 눈가루가 얹혔다. clear = 속이 비치는 투명한 얼음(어두운 깊이)."""
    rng = np.random.default_rng(seed + 710)
    deep = fbm(4, seed + 710, 3)
    base = hexc("#3a5068" if clear else "#5e7c94")
    img = base[None, None, :] * (0.72 + deep[..., None] * 0.6)
    if clear:
        img = img * (1.0 - np.clip((fbm(7, seed + 711, 3) - 0.5) * 3.0, 0, 1)[..., None] * 0.45)   # 얼음 밑 어두운 깊이
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 7 if clear else 11, 190, np.array([0.86, 0.93, 0.98], F), 1.6, 0.3)
    for _ in range(260):   # 공기 방울
        x, y, r = rng.random() * W, rng.random() * W, rng.uniform(0.8, 2.2)
        ly.blob(x, y, r, r, np.array([0.8, 0.9, 0.96], F), 0.55, 0, 6, 0.1, rng)
    img = ly.over(np.clip(img, 0, 1))
    frost = np.clip((fbm(6, seed + 712, 4) - (0.62 if clear else 0.5)) * 5.0, 0, 1)
    img = surf.mix(img, frost * 0.75, hexc("#a8b6c2")[None, None, :] * (0.9 + fbm(40, seed + 713, 2)[..., None] * 0.2))
    out = surf.finish(img, "#4a6076" if clear else "#6a8296", seed, 0.08)
    sheen = np.clip((fbm(3, seed + 714, 2) * 0.6 + fbm(22, seed + 715, 2) * 0.4 - 0.58) * 6.0, 0, 1) * (1 - frost)
    return _rgba(_lit(out, [(sheen, "#c8e0f0", 0.22)]))


# ── 재 · 용암 ────────────────────────────────────────────────────────────────

@_ground("ground_ash", "검게 탄 땅", {"a": {"seed": 1}, "b": {"seed": 2}, "ember": {"seed": 1, "ember": True}}, tags=["lava", "ash"])
def ground_ash(c, seed=1, ember=False):
    """식은 용암 바위 + 재: 검은 암반이 거북등처럼 갈라졌다. ember = 틈에서 불빛이 샌다."""
    rng = np.random.default_rng(seed + 720)
    base = hexc("#34302e")
    img, gap = ground.slabs(seed + 720, 70, 1.0, base, hexc("#0c0a0a"), 3.6, 0.16, 1.2)
    ash = np.clip((fbm(6, seed + 721, 3) - 0.5) * 3.5, 0, 1)
    img = surf.mix(img, ash * 0.7, hexc("#5a5654")[None, None, :] * (0.85 + fbm(30, seed + 722, 2)[..., None] * 0.3))
    ly = tex.Layer()
    ground.stones(ly, rng, 50, 1.8, 4.5, hexc("#2a2726"))
    out = surf.finish(ly.over(np.clip(img, 0, 1)), "#2e2b2a", seed)
    if not ember:
        return _rgba(out)
    hot = gap * np.clip((fbm(4, seed + 723, 3) - 0.42) * 5.0, 0, 1) * (1 - ash)
    return _rgba(_lit(out, [(np.clip(tex.blur(hot, 5) * 2.0, 0, 1), "#c03a10", 0.5), (hot, "#ffb040", 0.8)]))


def _lava(seed, f, crust_col, glow_d, glow_l, mean):
    plates, gap = ground.slabs(seed, 46, 1.0, hexc(crust_col), hexc("#0a0808"), 6.0, 0.2, 1.3)
    flow = _loop(5, seed + 3, f)
    molten = np.clip(gap * 1.25 + (flow - 0.56) * 2.4, 0, 1)                     # 틈 + 굳지 않은 못
    molten = np.clip((tex.blur(molten, 2) - 0.3) * 3.2, 0, 1)
    out = surf.finish(plates * (1 - molten[..., None] * 0.85), mean, seed, 0.1)
    pulse = 0.82 + 0.18 * _loop(9, seed + 5, f, 4, 2)
    core = np.clip((molten - 0.55) * 2.6, 0, 1) * (0.55 + 0.45 * _loop(16, seed + 7, f, 4, 2))
    halo = np.clip(tex.blur(molten, 7) * 1.5, 0, 1) * (1 - molten * 0.5)
    return _rgba(_lit(out, [(halo, glow_d, 0.2), (molten * pulse, glow_d, 0.8), (core, glow_l, 0.55)]))


@_ground("ground_lava", "용암", {"flow": {"frames": 4}, "poison": {"frames": 4, "poison": True}}, tags=["lava", "hazard", "animated"], hazard="lava", glow="#e06a20")
def ground_lava(c, f=0, poison=False, seed=1):
    """굳은 껍질 사이로 흐르는 용암(4프레임 · 지나갈 수 없는 위험 바닥으로 쓴다). poison = 맹독 용암(녹빛)."""
    if poison:
        return _lava(731, f, "#22261e", "#3a6a20", "#a8c858", "#2a3020")
    return _lava(730, f, "#2a2422", "#b8380e", "#f0b050", "#342826")


# ── 물 ───────────────────────────────────────────────────────────────────────

_WATER = {"clear": ("#33505a", "#a8c8d0", "#3a5560"), "black": ("#101418", "#7c8c9c", "#14181c"), "red": ("#5a1c1c", "#d89080", "#56201e"), "silver": ("#7c848e", "#eef2f6", "#727a84")}


@_ground("ground_water", "얕은 물", {k: {"kind": k, "frames": 4} for k in _WATER}, tags=["water", "animated"], hazard="water")
def ground_water(c, kind="clear", f=0, seed=1):
    """얕은 물(4프레임 잔물결). clear 맑은 물(강 · 얕은 도랑) · black 검은 물 · red 붉은 물 · silver 수은 같은 은빛 물."""
    body, shine, mean = _WATER[kind]
    seed = 740
    bed, _ = ground.slabs(seed, 150, 1.0, hexc(body) * 1.5, hexc(body) * 0.8, 3.0, 0.2, 0.15)      # 물 밑 자갈이 흐릿하게 비친다
    bed = np.stack([tex.blur(bed[..., i], 3) for i in range(3)], -1)
    depth = fbm(3, seed + 1, 3)
    img = bed * (0.3 * (1 - depth[..., None]) ** 2) + hexc(body)[None, None, :] * (0.75 + depth[..., None] * 0.3)
    if kind in ("black", "silver"):
        img = hexc(body)[None, None, :] * (0.8 + depth[..., None] * 0.5)
    out = surf.finish(np.clip(img, 0, 1), mean, seed, 0.1)
    n = _loop(7, seed + 2, f) * 0.6 + _loop(15, seed + 4, (f + 1) % 4, 4, 2) * 0.4
    crest = np.clip(1.0 - np.abs(n - 0.5) / 0.022, 0, 1) * np.clip(fbm(4, seed + 6, 2) * 2.2 - 0.5, 0, 1)    # 잔물결 마루
    crest2 = np.clip(1.0 - np.abs(n - 0.62) / 0.014, 0, 1) * 0.5
    return _rgba(_lit(out, [(np.clip(crest + crest2, 0, 1), shine, 0.34)]))
