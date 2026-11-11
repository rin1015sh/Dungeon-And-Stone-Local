"""2층 바닥 번짐 띠 모양 · 덧그림(tools/f2_art/ground.py와 한 묶음 — AM64).
① 번짐 띠 모양 assets/floor/fringe_mask.webp: 가로 변형 COLS칸 × (생김새 STYLES × 8줄). 줄 0~3 = 북·동·남·서 변에서 스며드는 띠,
   4~7 = 북서·북동·남동·남서 모서리 부채꼴. R = 덮는 정도, G = 가장자리 그늘. 변 띠의 깊이는 칸 양 끝에서 D0로 같아
   이웃 칸의 띠 · 모서리와 이어진다(그리는 쪽 src/explore/view/FloorFringe.gd — COLS · ROWS · STYLES를 같이 고친다).
② 덧그림(타일 art.overlay — 둘레 바닥 위에 얹는 투명 그림, 한 줄 변형 6칸): 올가미 · 덮은 구덩이 · 말뚝 · 금 · 꺼진 구멍.
  python3 tools/f2_art/ground_extra.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
C = 64
COLS = 4
D0 = 0.30
EDGE = 0.68    # 변 띠가 칸 안으로 들어오는 가장 큰 깊이(칸 비율) — 게임은 이만큼만 그린다(FloorFringe.EDGE)
CORNER = 0.5   # 모서리 부채꼴이 차지하는 가장 큰 폭(FloorFringe.CORNER)
# 생김새(TileDef.fringe_style): 0 흙 · 1 풀 · 2 깨진 돌 · 3 모래
STYLES = [
    {"amp": 0.20, "jag": 0.03, "specks": 4, "soft": 0.03},
    {"amp": 0.22, "jag": 0.10, "specks": 6, "soft": 0.02},
    {"amp": 0.13, "jag": 0.02, "specks": 2, "soft": 0.02, "blocky": True},
    {"amp": 0.24, "jag": 0.0, "specks": 0, "soft": 0.14},
]
INK = (26, 20, 18)


def smooth1(rng, n, knots):
    k = rng.uniform(-1.0, 1.0, knots + 3)
    x = np.linspace(0, knots, n)
    i = np.floor(x).astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    return k[i] * (1 - f) + k[i + 1] * f


def edge_mask(rng, st):
    """북쪽 변에서 스며드는 띠(위 = 재질 쪽) → (덮는 정도, 가장자리 그늘)."""
    t = (np.arange(C) + 0.5) / C
    win = np.sin(np.pi * t) ** 0.6
    depth = D0 + win * (smooth1(rng, C, 3) * st["amp"] + smooth1(rng, C, 9) * st["amp"] * 0.4)
    if st.get("blocky"):  # 깨진 돌: 깊이를 몇 단으로 끊는다
        depth = np.where(win > 0.35, D0 + np.round((depth - D0) / 0.11) * 0.11, depth)
    depth = np.clip(depth + win * rng.uniform(-1, 1, C) * st["jag"], 0.06, 0.62)
    s = ((np.arange(C) + 0.5) / C)[:, None]
    a = np.clip((depth[None, :] - s) / st["soft"] * 0.5 + 0.5, 0.0, 1.0)
    yy, xx = np.mgrid[0:C, 0:C]
    for _ in range(st["specks"]):  # 가장자리 밖 떨어진 조각(풀 포기 · 잔돌)
        cx = rng.uniform(0.15, 0.85) * C
        cy = min(depth[int(cx)] + rng.uniform(0.04, 0.14), EDGE - 0.07) * C
        a = np.maximum(a, np.clip((rng.uniform(1.4, 3.2) - np.hypot((xx - cx) / 1.25, yy - cy)) / 1.2, 0, 1))
    a = a * (s < EDGE - 0.01)
    rim = np.clip(1.0 - (depth[None, :] - s) / 0.07, 0.0, 1.0) * (a > 0.05)
    return a, rim


def corner_mask(rng, st):
    """북서 모서리에서 스며드는 부채꼴(양 변에서 반지름 = D0 — 이웃 칸의 변 띠 끝과 만난다)."""
    yy, xx = np.mgrid[0:C, 0:C]
    x, y = (xx + 0.5) / C, (yy + 0.5) / C
    th = np.clip(np.arctan2(y, x) / (np.pi / 2), 0, 1)
    win = np.sin(np.pi * th) ** 0.6
    wob = smooth1(rng, 64, 3)[(th * 63).astype(int)]
    rad = D0 * (1.0 + win * (wob * 0.28 + 0.06)) + win * rng.uniform(-1, 1, (C, C)) * st["jag"] * 0.3
    d = np.hypot(x, y)
    a = np.clip((rad - d) / st["soft"] * 0.5 + 0.5, 0.0, 1.0) * ((x < CORNER - 0.01) & (y < CORNER - 0.01))
    return a, np.clip(1.0 - (rad - d) / 0.07, 0.0, 1.0) * (a > 0.05)


def fringe_mask():
    out = np.zeros((len(STYLES) * 8 * C, COLS * C, 3), np.float32)
    for si, st in enumerate(STYLES):
        rng = np.random.default_rng(900 + si)
        for row in range(8):
            for v in range(COLS):
                a, rim = edge_mask(rng, st) if row < 4 else corner_mask(rng, st)
                y0 = (si * 8 + row) * C
                out[y0:y0 + C, v * C:(v + 1) * C, 0] = np.rot90(a, -(row % 4))  # 시계 방향: 북 → 동 → 남 → 서
                out[y0:y0 + C, v * C:(v + 1) * C, 1] = np.rot90(rim, -(row % 4))
    path = os.path.join(ROOT, "assets", "floor", "fringe_mask.webp")
    Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB").save(path, lossless=True, quality=100)
    print("번짐 띠:", os.path.relpath(path, ROOT))


def jag(rng, a, b, n, wob):
    """a → b 사이를 n 마디로 꺾은 선."""
    pts = [a]
    for k in range(1, n + 1):
        t = k / n
        pts.append((a[0] + (b[0] - a[0]) * t + rng.uniform(-wob, wob) * (k < n), a[1] + (b[1] - a[1]) * t + rng.uniform(-wob, wob) * (k < n)))
    return pts


def overlay(name, v):
    """덧그림 한 칸(4배로 칠해 줄인다) → RGBA."""
    k = 4
    n = C * k
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = np.random.default_rng(sum(map(ord, name)) * 31 + v)
    cx, cy = n / 2 + rng.uniform(-14, 14), n / 2 + rng.uniform(-10, 10)
    if name == "snare":  # 올가미: 흙에 반쯤 묻힌 밧줄 고리 + 말뚝
        rx, ry = rng.uniform(52, 62), rng.uniform(26, 32)
        ring = [(cx + np.cos(a) * rx * (1 + rng.uniform(-0.05, 0.05)), cy + np.sin(a) * ry * (1 + rng.uniform(-0.05, 0.05))) for a in np.linspace(0, 6.3, 30)]
        d.line([(x + 3, y + 4) for x, y in ring], fill=INK + (120,), width=9)
        d.line(ring, fill=(84, 66, 40, 255), width=8)
        d.line(ring, fill=(150, 126, 82, 255), width=4)
        peg = (cx + rx + rng.uniform(26, 36), cy - rng.uniform(20, 34))
        d.line([ring[2], peg], fill=(120, 100, 64, 255), width=4)
        d.line([peg, (peg[0] + 5, peg[1] - 34)], fill=INK + (255,), width=13)
        d.line([peg, (peg[0] + 5, peg[1] - 32)], fill=(70, 52, 36, 255), width=8)
    elif name == "pitcover":  # 덮은 구덩이: 얼기설기 걸친 가지 사이로 검은 틈
        for _ in range(9):
            x, y = cx + rng.uniform(-36, 36), cy + rng.uniform(-28, 28)
            d.ellipse([x - rng.uniform(16, 30), y - rng.uniform(12, 20), x + rng.uniform(16, 30), y + rng.uniform(12, 20)], fill=(12, 9, 8, 215))
        im = im.filter(ImageFilter.GaussianBlur(5))
        d = ImageDraw.Draw(im)
        for _ in range(9):
            a = rng.uniform(0, 3.14)
            ln = rng.uniform(60, 100)
            p0 = (cx + rng.uniform(-30, 30) - np.cos(a) * ln / 2, cy + rng.uniform(-24, 24) - np.sin(a) * ln / 2)
            p1 = (p0[0] + np.cos(a) * ln, p0[1] + np.sin(a) * ln)
            d.line([p0, p1], fill=INK + (230,), width=8)
            d.line([p0, p1], fill=(92, 70, 44, 255), width=5)
        for _ in range(7):
            x, y = cx + rng.uniform(-44, 44), cy + rng.uniform(-34, 34)
            d.ellipse([x - 9, y - 5, x + 9, y + 5], fill=(98, 84, 40, 255), outline=INK + (200,))
    elif name == "spikes":  # 박아 둔 말뚝 끝: 그림자 + 깎은 끝
        for _ in range(int(rng.integers(6, 9))):
            x, y = cx + rng.uniform(-70, 70), cy + rng.uniform(-50, 60)
            h = rng.uniform(34, 56)
            lean = rng.uniform(-8, 8)
            d.line([(x, y), (x + 22, y + 9)], fill=INK + (110,), width=7)
            d.polygon([(x - 6, y), (x + 6, y), (x + lean, y - h)], fill=INK + (255,))
            d.polygon([(x - 4, y - 1), (x + 4, y - 1), (x + lean, y - h + 6)], fill=(96, 74, 48, 255))
            d.polygon([(x - 4, y - 1), (x, y - 1), (x + lean, y - h + 6)], fill=(142, 116, 78, 255))
    elif name == "crack":  # 금 간 자리: 가운데에서 뻗는 금
        for _ in range(int(rng.integers(5, 8))):
            a = rng.uniform(0, 6.28)
            ln = rng.uniform(50, 105)
            pts = jag(rng, (cx, cy), (cx + np.cos(a) * ln, cy + np.sin(a) * ln * 0.8), 5, 9)
            for i in range(len(pts) - 1):
                d.line([pts[i], pts[i + 1]], fill=(10, 8, 8, 235), width=max(2, int(10 * (1 - i / 5))))
            mid = pts[2]
            b = a + rng.uniform(0.5, 1.0) * (1 if rng.random() < 0.5 else -1)
            d.line(jag(rng, mid, (mid[0] + np.cos(b) * 34, mid[1] + np.sin(b) * 28), 3, 5), fill=(10, 8, 8, 220), width=3)
        d.ellipse([cx - 14, cy - 10, cx + 14, cy + 10], fill=(8, 6, 6, 240))
    elif name == "pit":  # 꺼진 구멍: 들쭉날쭉한 검은 구멍 + 왼쪽 위 안벽
        ang = np.linspace(0, 6.28, 26, endpoint=False)
        rim = [(n / 2 + np.cos(a) * 104 * (1 + rng.uniform(-0.12, 0.12)), n / 2 + np.sin(a) * 92 * (1 + rng.uniform(-0.12, 0.12))) for a in ang]
        d.polygon(rim, fill=(54, 50, 48, 255), outline=INK + (255,))
        d.polygon([(x * 0.86 + n * 0.07 + 12, y * 0.84 + n * 0.08 + 16) for x, y in rim], fill=(8, 7, 8, 255))
        d.line(rim + rim[:1], fill=INK + (255,), width=5)
    im = im.resize((C, C), Image.LANCZOS)
    return im


def overlays():
    for place, name in (("f2g", "snare"), ("f2g", "pitcover"), ("f2g", "spikes"), ("f2d", "crack"), ("f2d", "pit")):
        sheet = Image.new("RGBA", (6 * C, C), (0, 0, 0, 0))
        for v in range(6):
            sheet.paste(overlay(name, v), (v * C, 0))
        path = os.path.join(ROOT, "assets", "floor", place, name + ".webp")
        sheet.save(path, lossless=True, quality=100, exact=True)
        print("덧그림:", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    fringe_mask()
    overlays()
