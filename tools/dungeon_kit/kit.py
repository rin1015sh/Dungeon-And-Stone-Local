"""던전 에셋 키트 — 뼈대(등록 · 그리기 · 캐시). 그림 기법은 2층 소품과 같다(tools/f2_art — 덩어리 빚기 sdf.py → 3/4 시점 손그림 마감 solid.py).

에셋 하나 = 함수 하나. 두 갈래:
  @prop(...)   덩어리(SDF)로 빚는 서 있는 물건 — 함수(k: Kit, **변형 인자) → 덧붙임 dict(없어도 됨)
  @flat(...)   평면 그림(바닥 자국 · 벽 부착물 · 타일) — 함수(c: paint2d.Canvas, **변형 인자)
변형(variants) = {이름: 인자 dict}. 인자에 "frames": n 이 있으면 f = 0..n-1로 n장을 그려 애니메이션 한 묶음이 된다.
좌표: 칸 단위(1 = 바닥 한 칸 = U px). x 오른쪽 · y 깊이(멀수록 +) · z 높이. 원점 = 물건의 발(바닥에 닿는 가운데).

층(layer): floor 바닥 타일 · wall 벽 타일 · decal 바닥에 붙는 자국(몸 아래) · wall_decal 벽면 부착 · stand 서 있는 것(Y-정렬) · over 머리 위(전경)
충돌(collide): (폭, 깊이) 또는 (x, y, 폭, 깊이) — 칸 단위, 원점 기준 가운데 맞춤. None = 지나갈 수 있는 장식.
"""
import hashlib
import inspect
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools", "f2_art"))
import mats as M  # noqa: E402
import sdf  # noqa: E402
import solid  # noqa: E402
from sdf import box, cap, cone, cyl, ell, gable, smin, sphere, sub, v3  # noqa: E402,F401

F = np.float32
U = 64                 # 그림 px / 칸 (게임 세계 px 32 × art_scale 2)
K = solid.K            # 바닥 깊이가 화면에서 눌리는 비율
WALL_H = 2.5           # 벽 높이(칸) — 벽면 그림 160px
CACHE = os.path.join(HERE, ".cache")
OUT = os.path.join(ROOT, "assets", "dungeon_kit")
LAYERS = ("floor", "wall", "decal", "wall_decal", "stand", "over")
CATS = ("floor", "wall", "structure", "furniture", "light", "trace", "nature", "special", "trap")

REG = {}               # id → Asset


class Asset:
    def __init__(self, kind, fn, id, cat, layer, variants, **kw):
        assert cat in CATS, cat
        assert layer in LAYERS, layer
        assert id not in REG, "같은 id가 둘: " + id
        self.kind, self.fn, self.id, self.cat, self.layer = kind, fn, id, cat, layer
        self.variants = variants or {"base": {}}
        self.cell = kw.pop("cell", (2, 2))          # prop: 그릴 판 크기(칸) · flat: 그림 크기(px)
        self.collide = kw.pop("collide", None)
        self.tags = list(kw.pop("tags", ()))
        self.light = kw.pop("light", None)          # {"color": "#rrggbb", "radius": 칸, "at": (x, y, z), "flicker": 0~1}
        self.fps = kw.pop("fps", 8)
        self.name_ko = kw.pop("name_ko", id)
        self.interact = kw.pop("interact", None)    # 쓰임새 귀띔(예: "container", "door", "lever", "trap")
        self.seed = kw.pop("seed", None)
        self.meta = kw.pop("meta", None)            # 그대로 manifest에 실리는 덧붙임(타일 크기 등)
        assert not kw, "모르는 인자: %s" % list(kw)

    def jobs(self):
        """→ [(변형 이름, 프레임 번호 또는 None, 인자)]"""
        out = []
        for name, params in self.variants.items():
            p = dict(params)
            n = p.pop("frames", 0)
            if n:
                out += [(name, f, dict(p, f=f)) for f in range(n)]
            else:
                out.append((name, None, p))
        return out

    def digest(self, params):
        src = inspect.getsource(self.fn) + repr(sorted(params.items())) + repr(self.cell) + str(self.seed)
        return hashlib.sha1(src.encode()).hexdigest()[:12]


def prop(id, cat, layer="stand", variants=None, **kw):
    def deco(fn):
        REG[id] = Asset("prop", fn, id, cat, layer, variants, **kw)
        return fn
    return deco


def flat(id, cat, layer="decal", variants=None, **kw):
    def deco(fn):
        REG[id] = Asset("flat", fn, id, cat, layer, variants, **kw)
        return fn
    return deco


# ── 덩어리 빚기 도우미 ─────────────────────────────────────────────────────────

def rot_z(p, a, c=(0, 0, 0)):
    c = np.asarray(c, F)
    q = p - c
    ca, sa = np.cos(a), np.sin(a)
    return np.stack([q[:, 0] * ca + q[:, 1] * sa, -q[:, 0] * sa + q[:, 1] * ca, q[:, 2]], 1).astype(F) + c


def rot_y(p, a, c=(0, 0, 0)):
    c = np.asarray(c, F)
    q = p - c
    ca, sa = np.cos(a), np.sin(a)
    return np.stack([q[:, 0] * ca + q[:, 2] * sa, q[:, 1], -q[:, 0] * sa + q[:, 2] * ca], 1).astype(F) + c


def rot_x(p, a, c=(0, 0, 0)):
    c = np.asarray(c, F)
    q = p - c
    ca, sa = np.cos(a), np.sin(a)
    return np.stack([q[:, 0], q[:, 1] * ca + q[:, 2] * sa, -q[:, 1] * sa + q[:, 2] * ca], 1).astype(F) + c


def rough(fn, amp=0.03, scale=0.22, seed=1):
    """표면을 잡음으로 흔든다(닳고 깨진 돌 · 굽은 나무)."""
    return lambda p: fn(p) + (sdf.fbm(p, scale, seed, 2) - 0.5) * amp


def chip(fn, amount=0.5, scale=0.3, seed=1, depth=0.12):
    """모서리 · 겉을 잡음으로 뜯어낸다(깨진 돌)."""
    return lambda p: np.maximum(fn(p), (amount - sdf.fbm(p, scale, seed, 3)) * depth * 4.0 - depth)


def cut_above(fn, z, jag=0.25, scale=0.3, seed=1, tilt=0.0):
    """z 위를 들쭉날쭉하게 잘라 낸다(부러진 기둥 · 무너진 벽)."""
    return lambda p: np.maximum(fn(p), p[:, 2] - z - (sdf.fbm(p * np.array([1, 1, 0.2], F), scale, seed, 2) - 0.5) * jag * 2 - p[:, 0] * tilt)


def torus(p, c, R, r):
    """누운 고리(가운데 c, 큰 반지름 R, 굵기 r)."""
    q = np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) - R
    return np.hypot(q, p[:, 2] - c[2]) - r


def ring_x(p, c, R, r):
    """세운 고리 — 화면을 마주 본다(xz 평면)."""
    q = np.hypot(p[:, 0] - c[0], p[:, 2] - c[2]) - R
    return np.hypot(q, p[:, 1] - c[1]) - r


def disc_x(p, c, R, half):
    """세운 원판 — 화면을 마주 본다(xz 평면, 두께 half × 2)."""
    return np.maximum(np.hypot(p[:, 0] - c[0], p[:, 2] - c[2]) - R, np.abs(p[:, 1] - c[1]) - half)


def hcyl(p, a, b, r):
    """끝이 평평한 막대(두 점 사이 원통)."""
    a, b = np.asarray(a, F), np.asarray(b, F)
    ab = b - a
    ln = float(np.sqrt(ab @ ab))
    t = ((p - a) @ ab) / ln
    rad = sdf.length(p - a - (t / ln)[:, None] * ab) - r
    return np.maximum(rad, np.abs(t - ln * 0.5) - ln * 0.5)


def pool(p, c, rx, ry, h=0.012):
    """바닥 · 윗면에 고인 얇은 덩이(피 · 물 · 점액): 가운데 c, 반지름 rx · ry, 두께 h. 얇은 ell()은 거리가 틀려 그림자가 번진다 — 이것을 쓴다."""
    d = (np.hypot((p[:, 0] - c[0]) / rx, (p[:, 1] - c[1]) / ry) - 1.0) * min(rx, ry)
    return np.maximum(d, np.abs(p[:, 2] - c[2]) - h)


class Kit(sdf.Scene):
    """한 물건의 덩어리 묶음 + 재질 표. k.add(거리 함수, 재질 이름). yaw(라디안)를 주면 물건 전체가 z축으로 돈다."""

    def __init__(self, seed=1, yaw=0.0):
        super().__init__()
        self.seed, self.yaw = seed, yaw
        self.rng = np.random.default_rng(seed)
        self.mats = palette()

    def add(self, fn, mat):
        if self.yaw:
            a = self.yaw
            self.parts.append((lambda p, fn=fn: fn(rot_z(p, a)), mat))
        else:
            self.parts.append((fn, mat))
        return self

    def mat(self, name, fn):
        self.mats[name] = fn
        return name

    def rubble(self, pts, mat="stone", r0=0.07, r1=0.16):
        for x, y in pts:
            r = self.rng.uniform(r0, r1)
            c, s = v3(x, y, r * 0.55), int(self.rng.integers(99))
            self.add(rough(lambda p, c=c, r=r: ell(p, c, (r * 1.2, r, r * 0.75)), 0.05, 0.12, s), mat)

    def scatter(self, n, rx, ry, cx=0.0, cy=0.0, hole=0.0):
        """둘레에 흩을 점 n개(가운데 hole 반지름은 비운다)."""
        out = []
        while len(out) < n:
            x, y = self.rng.uniform(-rx, rx), self.rng.uniform(-ry, ry)
            if np.hypot(x / max(rx, 1e-6), y / max(ry, 1e-6)) <= 1.0 and np.hypot(x, y) >= hole:
                out.append((cx + x, cy + y))
        return out

    def final_mats(self):
        if not self.yaw:
            return self.mats
        a = self.yaw
        return {k: (lambda p, n, m=m: m(rot_z(p, a), rot_z(n, a))) for k, m in self.mats.items()}


STONE, STONE_D, MOSS = "#7d7a70", "#55534c", "#4a5236"


def palette():
    """키트 공통 재질(채도 낮게 — ART.md §2). 물건마다 k.mat()으로 더할 수 있다."""
    return {
        "stone": M.stone(STONE), "stone_d": M.stone(STONE_D, None, 5), "stone_m": M.stone(STONE, MOSS, 6), "stone_l": M.stone("#9a968a", None, 7),
        "masonry": M.masonry(STONE), "masonry_m": M.masonry(STONE, moss=MOSS), "brick": M.masonry("#6e5648", 0.14, 0.34, None, 3),
        "carved": M.stone("#807c72", None, 4, 0.11), "marble": M.stone("#a8a49a", None, 8),
        "iron": M.metal("#3c3c40", "#5a4234", 8, 0.3), "rust": M.metal("#4a3c36", "#7a4a30", 9, 0.85), "steel": M.metal("#7c8288", "#5a4638", 10, 0.18),
        "brass": M.metal("#8a7440", "#5a4a2c", 11, 0.25), "gold": M.metal("#b09448", "#6a5428", 12, 0.12), "bronze": M.metal("#5e5240", "#7a4e32", 3, 0.6),
        "wood": M.wood("#5a4430"), "wood_d": M.wood("#3e2e22", 0.2, 2, 5), "wood_l": M.wood("#7a6244", 0.2, 2, 6),
        "plank_x": M.wood("#5a4430", 0.16, 0, 7), "plank_y": M.wood("#54402e", 0.16, 1, 8), "plank_xd": M.wood("#3e2e22", 0.16, 0, 9),
        "cloth": M.plain("#5a5244", 0.3, 0.12), "cloth_r": M.plain("#6a2e2a", 0.3, 0.12, 2), "cloth_b": M.plain("#34425a", 0.3, 0.12, 3),
        "cloth_g": M.plain("#3e4a36", 0.3, 0.12, 4), "linen": M.plain("#9a927c", 0.25, 0.12, 5), "cloth_k": M.plain("#2a2628", 0.3, 0.12, 6),
        "leather": M.plain("#5a3e28", 0.35, 0.1, 7), "leather_d": M.plain("#3a2a20", 0.35, 0.1, 8), "rope": M.plain("#7a6a4a", 0.4, 0.04, 9),
        "bone": M.plain("#c8c0aa", 0.22, 0.1, 10), "bone_d": M.plain("#8e8672", 0.3, 0.1, 11), "paper": M.plain("#b8ac8c", 0.2, 0.15, 12),
        "dirt": M.plain("#4a443c", 0.4, 0.15, 13), "sand": M.plain("#8a7a5c", 0.3, 0.15, 14), "ash": M.plain("#3a3836", 0.4, 0.1, 15), "coal": M.plain("#1e1c1c", 0.5, 0.06, 16),
        "moss": M.leaf("#465232", 0.2, 17, 0.05), "leaf": M.leaf("#3e5a2c", 0.2, 18), "leaf_dry": M.leaf("#6a5a30", 0.2, 19, 0.06),
        "flesh": M.plain("#7a4a44", 0.35, 0.1, 20), "rot": M.plain("#4e4a34", 0.45, 0.08, 21), "blood": M.plain("#4a1614", 0.3, 0.1, 22),
        "slime": M.plain("#16141a", 0.5, 0.1, 23), "glass": M.plain("#4a5e58", 0.3, 0.2, 24), "glass_r": M.plain("#6a2a2e", 0.3, 0.2, 25), "glass_b": M.plain("#2e4466", 0.3, 0.2, 26),
        "wax": M.plain("#c8bc98", 0.12, 0.2, 27), "food": M.plain("#8a6a3e", 0.4, 0.06, 28), "shroom": M.plain("#9a8468", 0.3, 0.1, 29),
        "shroom_r": M.plain("#8a3a30", 0.3, 0.1, 30), "shroom_t": M.plain("#5a7a4a", 0.35, 0.08, 31),
        "crystal_b": M.plain("#4a78b0", 0.5, 0.25, 32), "crystal_r": M.plain("#a03a44", 0.5, 0.25, 33), "crystal_v": M.plain("#6a4a9a", 0.5, 0.25, 34),
        "void": M.void(), "ember": M.glow("#e06a20"), "glow_fire": M.glow("#f0b040"), "glow_b": M.glow("#70b0f0"), "glow_r": M.glow("#e04848"),
        "glow_v": M.glow("#a070e0"), "glow_g": M.glow("#80d060"), "glow_w": M.glow("#e8e0c0"),
    }


class View:
    """그릴 판의 좌표 변환: 세계(칸) → 그림 px."""

    def __init__(self, w, h, u, ox, oy):
        self.w, self.h, self.u, self.ox, self.oy = w, h, u, ox, oy

    def px(self, x, y, z):
        return self.ox + x * self.u, self.oy - (z + K * y) * self.u


def hex_rgb(s):
    return M.hexc(s)


def render_prop(a, params):
    """prop 한 장 → (RGBA uint8, 원점 px (ox, oy))."""
    p = dict(params)
    seed = p.pop("seed", a.seed if a.seed is not None else (int(hashlib.sha1(a.id.encode()).hexdigest()[:6], 16) % 9000 + 1))
    yaw = p.pop("yaw", 0.0)
    k = Kit(seed, yaw)
    sig = inspect.signature(a.fn).parameters
    if "seed" in sig:
        p["seed"] = seed
    extra = a.fn(k, **p) or {}
    cw, ch = extra.get("cell", a.cell)
    w, h = int(cw * U), int(ch * U)
    scale = extra.get("scale", 1.0)
    u = U * scale
    ox, oy = w * 0.5 + extra.get("dx", 0.0) * U, h - U * extra.get("foot", 0.75)
    view = View(w, h, u, ox, oy)
    if k.parts:
        img = solid.render(k, k.final_mats(), w, h, u, ox, oy, seed, extra.get("shadow", 0.5), -3.0, extra.get("far", 8.0))
    else:
        img = np.zeros((h, w, 4), np.uint8)
    for fn in extra.get("post", []):
        img = fn(img, view)
    for gx, gy, gz, r, color, strength in extra.get("glow", []):
        x, y = view.px(gx, gy, gz)
        img = solid.add_glow(img, x, y, r * scale, hex_rgb(color), strength)
    return img, (ox, oy)


def render_flat(a, params):
    import paint2d
    p = dict(params)
    seed = p.pop("seed", a.seed if a.seed is not None else (int(hashlib.sha1(a.id.encode()).hexdigest()[:6], 16) % 9000 + 1))
    w, h = a.cell
    c = paint2d.Canvas(int(w), int(h), seed)
    if "seed" in inspect.signature(a.fn).parameters:
        p["seed"] = seed
    out = a.fn(c, **p)
    img = out if isinstance(out, np.ndarray) else c.result()
    return img, c.origin


def trim(img, origin, pad=1):
    """투명 둘레를 잘라 낸다 → (그림, 원점)."""
    img = img.copy()
    img[img[..., 3] < 10] = 0     # 보이지 않는 옅은 그림자 찌꺼기는 버린다
    al = img[..., 3] > 0
    ys, xs = np.flatnonzero(al.any(1)), np.flatnonzero(al.any(0))
    if len(ys) == 0:
        return img[:2, :2], (origin[0], origin[1])
    y0, y1, x0, x1 = max(0, ys[0] - pad), min(img.shape[0], ys[-1] + 1 + pad), max(0, xs[0] - pad), min(img.shape[1], xs[-1] + 1 + pad)
    return img[y0:y1, x0:x1], (origin[0] - x0, origin[1] - y0)


def render(id, vname, frame, params, force=False):
    """한 장 그리기(캐시) → (RGBA, 원점). 타일(floor · wall)은 자르지 않는다."""
    a = REG[id]
    os.makedirs(CACHE, exist_ok=True)
    key = "%s.%s.%s.%s" % (id, vname, "x" if frame is None else frame, a.digest(params))
    path = os.path.join(CACHE, key + ".png")
    if os.path.exists(path) and not force:
        im = Image.open(path)
        return np.asarray(im.convert("RGBA")), tuple(float(v) for v in im.info.get("origin", "0,0").split(","))
    img, origin = (render_prop if a.kind == "prop" else render_flat)(a, params)
    if a.layer not in ("floor", "wall"):
        img, origin = trim(img, origin)
    from PIL import PngImagePlugin
    meta = PngImagePlugin.PngInfo()
    meta.add_text("origin", "%.2f,%.2f" % origin)
    for old in os.listdir(CACHE):
        if old.startswith("%s.%s.%s." % (id, vname, "x" if frame is None else frame)):
            os.remove(os.path.join(CACHE, old))
    Image.fromarray(img, "RGBA").save(path, pnginfo=meta)
    return img, origin


def load_all():
    """에셋 모듈을 모두 읽어 REG를 채운다."""
    import importlib
    for name in sorted(os.listdir(HERE)):
        if name.startswith("a_") and name.endswith(".py"):
            importlib.import_module(name[:-3])
    return REG
