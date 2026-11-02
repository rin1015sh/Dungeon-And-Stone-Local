"""도시 구상판(사용자 2026-11-02 "둘 다 쓸 거고 틀어진 각도랑 정면 각도 생각해서 도시 맵 다시 구상해봐. 차원광장 옆에는 탐험가 길드"):
  ① view_labeled.jpg — 광장 구역 구상 그림(tools/town_concept.gd → town_handdrawn.py --dir=concept)에 이름표
  ② plan_labeled.jpg — 같은 구역을 위에서 본 배치 + 이름표
  ③ district.png — 7구역 전체 짜임(테라스 다섯 · 세 방향 거리 · 시설 자리) 도식
  python3 tools/town_concept_board.py     (기획 설명: docs/plans/city_town_v2.md)
"""
import json
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "docs", "plans", "town", "concept")
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
INK = (34, 26, 20)
PAPER = (226, 216, 192)
WINE = (110, 40, 34)


def font(n):
    return ImageFont.truetype(FONT, n)


def tag(d, x, y, text, kind, anchor=None, size=None):
    """이름표: place = 크게(종이 바탕 + 먹 테), dir = 검붉은 글씨(줄 방향), step = 작게."""
    f = font(size or {"place": 40, "dir": 34, "step": 28}.get(kind, 30))
    tw, th = d.textbbox((0, 0), text, font=f)[2:]
    ax, ay = anchor if anchor else (x, y)
    bx, by = x - tw / 2, y - th / 2 - 6
    pad = 10
    fill = PAPER if kind != "dir" else (236, 224, 206)
    d.rounded_rectangle((bx - pad, by - pad / 2, bx + tw + pad, by + th + pad), 8, fill=fill, outline=INK, width=3)
    d.text((bx, by), text, font=f, fill=WINE if kind == "dir" else INK)
    if anchor:
        d.line((x, by + th + pad, ax, ay), fill=INK, width=3)
        d.ellipse((ax - 6, ay - 6, ax + 6, ay + 6), fill=INK)


def view_labeled():
    im = Image.open(os.path.join(DIR, "district_hand.png")).convert("RGB")
    d = ImageDraw.Draw(im)
    for l in json.load(open(os.path.join(DIR, "labels.json"), encoding="utf-8")):
        tag(d, l["x"], l["y"], l["text"], l["kind"])
    im.save(os.path.join(DIR, "view_labeled.jpg"), quality=90)  # 3200×1800 — PNG는 9MB라 JPEG


def plan_labeled():
    im = Image.open(os.path.join(DIR, "plan.png")).convert("RGB")
    W, H = im.size
    # 카메라에 보이는 폭(±36칸)만 — 위에서 본 그림 64칸 높이 기준
    ppu = H / 64.0
    x0 = int(W / 2 - 37 * ppu)
    x1 = int(W / 2 + 37 * ppu)
    im = im.crop((x0, 0, x1, H))
    d = ImageDraw.Draw(im)
    for l in json.load(open(os.path.join(DIR, "plan_labels.json"), encoding="utf-8")):
        if l["kind"] == "dir":
            continue
        tag(d, l["x"] - x0, l["y"], l["text"], l["kind"], size=34)
    # 카메라 방향
    cx, cy = im.width - 150, H - 90
    d.line((cx, cy, cx, cy - 120), fill=WINE, width=8)
    d.polygon([(cx - 22, cy - 110), (cx + 22, cy - 110), (cx, cy - 150)], fill=WINE)
    d.text((cx - 230, cy + 10), "카메라는 남쪽에서 북쪽을 본다", font=font(26), fill=WINE, anchor="mt")
    im.save(os.path.join(DIR, "plan_labeled.jpg"), quality=90)


# ─── ③ 7구역 전체 도식 ─────────────────────────────────────────────────────
# 좌표 = 칸(x 동, z 남) — tools/town_kit/Concept.gd와 같은 자리(광장 (0, -1)).
S = 7.0          # px / 칸
OX, OZ = 100, 70  # 지도 왼쪽 위가 (-OX, -OZ)
MW, MH = 200, 130
TERR = [  # (이름, 북쪽 끝 z, 남쪽 끝 z, 색, 높이)
    ("꼭대기 단", -62, -29, (186, 174, 146), "+7.2"),
    ("위 단", -29, -17, (198, 187, 160), "+3.6"),
    ("광장 단", -17, 8, (210, 200, 175), "0"),
    ("아래 단", 8, 34, (219, 210, 187), "-3.6"),
    ("수로 단", 34, 56, (226, 218, 197), "-7.2"),
]
ROW = (104, 82, 66)
FAC = (52, 40, 32)
STREET = (236, 229, 210)


def P(x, z):
    return ((x + OX) * S + 40, (z + OZ) * S + 40)


def poly(d, pts, **kw):
    d.polygon([P(*p) for p in pts], **kw)


def house_row(d, rng, start, ang, length, depth=(3.8, 5.6), gap=0.25, skip=()):
    """줄: start에서 ang(도 — 0 동쪽, 화면 북쪽이 −z) 방향으로 집을 붙여 세운다. 집은 줄의 북쪽(카메라 반대쪽)."""
    a = math.radians(ang)
    dx, dz = math.cos(a), -math.sin(a)
    nx, nz = dz, -dx  # 북쪽(줄 왼쪽 위)
    if nz > 0:
        nx, nz = -nx, -nz
    t = 0.0
    while t < length:
        w = rng.uniform(3.4, 6.6)
        if t + w > length:
            break
        if not any(s0 <= t + w / 2 <= s1 for s0, s1 in skip):
            dp = rng.uniform(*depth)
            back = rng.uniform(0, 0.9)
            p0 = (start[0] + dx * t + nx * back, start[1] + dz * t + nz * back)
            pts = [p0, (p0[0] + dx * w, p0[1] + dz * w), (p0[0] + dx * w + nx * dp, p0[1] + dz * w + nz * dp), (p0[0] + nx * dp, p0[1] + nz * dp)]
            poly(d, pts, fill=ROW, outline=INK)
        t += w + gap


def label(d, x, z, text, size=24, fill=INK, bold=False):
    px, pz = P(x, z)
    f = font(size)
    if bold:
        tw, th = d.textbbox((0, 0), text, font=f)[2:]
        d.rounded_rectangle((px - tw / 2 - 8, pz - th / 2 - 8, px + tw / 2 + 8, pz + th / 2 + 6), 6, fill=PAPER, outline=INK, width=2)
    d.text((px, pz), text, font=f, fill=fill, anchor="mm")


def stairs(d, x, z0, z1, w):
    a, b = P(x - w / 2, min(z0, z1)), P(x + w / 2, max(z0, z1))
    d.rectangle((a, b), fill=STREET, outline=INK, width=2)
    for i in range(int(abs(z1 - z0) / 0.6)):
        y = a[1] + i * 0.6 * S
        d.line((a[0], y, b[0], y), fill=INK, width=1)


def facility(d, pts, name, at, circle=None):
    if circle:
        cx, cz, r = circle
        a, b = P(cx - r, cz - r), P(cx + r, cz + r)
        d.ellipse((a, b), fill=FAC, outline=INK, width=3)
    else:
        poly(d, pts, fill=FAC, outline=INK)
    label(d, at[0], at[1], name, 26, bold=True)


def district():
    rng = random.Random(7)
    img = Image.new("RGB", (int(MW * S) + 80 + 190, int(MH * S) + 80 + 330), PAPER)
    d = ImageDraw.Draw(img)
    # 테라스(높을수록 짙게) + 옹벽
    for name, z0, z1, col, h in TERR:
        poly(d, [(-OX, z0), (OX, z0), (OX, z1), (-OX, z1)], fill=col)
        px, pz = P(OX, (z0 + z1) / 2)
        d.text((px + 18, pz - 30), name, font=font(24), fill=INK)
        d.text((px + 18, pz + 2), "높이 %s" % h, font=font(20), fill=(80, 64, 50))
    for z in [-29, -17, 8, 34]:
        d.line((P(-OX, z), P(OX, z)), fill=INK, width=5)
        for x in range(-OX, OX, 3):
            d.line((P(x, z), P(x + 0.6, z + 1.0)), fill=INK, width=1)
    # 성벽 · 구역문
    for a, b in [((-OX, -62), (OX, -62)), ((-OX, 56), (OX, 56)), ((-OX, -62), (-OX, 56)), ((OX, -62), (OX, 56))]:
        d.line((P(*a), P(*b)), fill=INK, width=12)
    for gx, gz, txt, vert in [(36, -62, "북문(6구역 · 컴멜비)", False), (-OX, -6, "서문(8구역)", True)]:
        if vert:
            d.line((P(gx, gz - 3), P(gx, gz + 3)), fill=STREET, width=14)
            label(d, gx + 12, gz - 6, txt, 22, WINE)
        else:
            d.line((P(gx - 3, gz), P(gx + 3, gz)), fill=STREET, width=14)
            label(d, gx, gz + 4, txt, 22, WINE)
    # 수로 + 다리
    poly(d, [(-OX, 44), (OX, 44), (OX, 48.5), (-OX, 48.5)], fill=(128, 140, 140), outline=INK)
    for x in range(-OX + 2, OX, 6):
        d.arc((P(x, 45.4), P(x + 3, 47.4)), 200, 340, fill=(214, 220, 214), width=2)
    for bx in [-40, 6, 52]:
        poly(d, [(bx - 2, 43), (bx + 2, 43), (bx + 2, 49.5), (bx - 2, 49.5)], fill=STREET, outline=INK)
    # 거리(밝은 띠) — 정면 거리 넷 + 사선 시장골목 둘
    for z0, z1 in [(-33, -29.5), (-20.6, -17), (14.6, 18.2), (36, 43)]:
        poly(d, [(-OX, z0), (OX, z0), (OX, z1), (-OX, z1)], fill=STREET)
    poly(d, [(-OX, -9), (-14, -9), (-14, -5), (-OX, -5)], fill=STREET)
    poly(d, [(14, -5), (OX, -5), (OX, -1.5), (14, -1.5)], fill=STREET)
    for sx, sz, ex, ez in [(-1, 18, -34, 34), (1, 18, 34, 34)]:
        L = math.hypot(ex - sx, ez - sz)
        nx, nz = -(ez - sz) / L * 2.2, (ex - sx) / L * 2.2
        poly(d, [(sx - nx, sz - nz), (ex - nx, ez - nz), (ex + nx, ez + nz), (sx + nx, sz + nz)], fill=STREET)
    # 차원광장
    a, b = P(-9, -10), P(9, 8)
    d.ellipse((a, b), fill=(236, 228, 206), outline=INK, width=3)
    a, b = P(-2, -3), P(2, 1)
    d.ellipse((a, b), outline=INK, width=6)
    # 집 줄 — 광장 단(광장 구역은 Concept.gd와 같은 줄)
    house_row(d, rng, (0.9, -10.6), 0, 13)
    house_row(d, rng, (14.4, -9.6), -28.8, 22)
    house_row(d, rng, (-31, 5.4), 28.8, 19)
    house_row(d, rng, (-OX + 4, -9.2), 0, 64, skip=[(30, 34)])
    house_row(d, rng, (36, -5.2), 0, 60, skip=[(4, 16)])
    house_row(d, rng, (-OX + 4, 3.6), 0, 58, depth=(3.4, 4.4))  # 난간 길(광장 단 남쪽 끝)을 보는 줄
    house_row(d, rng, (34, 3.6), 0, 62, depth=(3.4, 4.4))
    poly(d, [(-OX, 3.6), (-35, 3.6), (-35, 7.5), (-OX, 7.5)], fill=STREET)
    poly(d, [(14, 3.6), (OX, 3.6), (OX, 7.5), (14, 7.5)], fill=STREET)
    # 위 단 · 꼭대기
    house_row(d, rng, (-OX + 4, -20.6), 0, 92, skip=[(36, 50), (55, 59)])
    house_row(d, rng, (14.2, -20.6), 0, 82)
    house_row(d, rng, (-OX + 4, -33.2), 0, 82, depth=(4.5, 7.5))
    house_row(d, rng, (20, -33.2), 0, 76, depth=(4.5, 7.5), skip=[(13, 19)])
    house_row(d, rng, (-OX + 4, -46), 0, 190, depth=(5, 9), skip=[(80, 120)])
    # 아래 단 · 시장골목(사선 · 거울 사선) · 수로 단
    house_row(d, rng, (-OX + 4, 14.6), 0, 94, depth=(3.2, 5.0), skip=[(90, 99)])
    house_row(d, rng, (3.4, 14.6), 0, 92, depth=(3.2, 5.0))
    house_row(d, rng, (-32.2, 30.4), 28.8, 26, depth=(3.4, 4.6))
    house_row(d, rng, (9.2, 19.3), -28.8, 26, depth=(3.4, 4.6))
    house_row(d, rng, (-OX + 4, 36), 0, 120, depth=(3, 4.2), skip=[(35, 50)])
    house_row(d, rng, (40, 36), 0, 56, depth=(3, 4.2), skip=[(4, 20)])
    # 계단
    stairs(d, 0, 8, 12.8, 5.6)
    stairs(d, -0.95, -17, -12.2, 2.6)
    stairs(d, 12.6, -29, -24.2, 2.6)
    stairs(d, -50, -17, -12.2, 3.4)
    stairs(d, 60, -17, -12.2, 3.4)
    stairs(d, -36, 34, 38.8, 3.0)
    stairs(d, 36, 34, 38.8, 3.0)
    stairs(d, 40, -62 + 4.8, -62 + 9.6, 3.0)
    # 시설
    facility(d, [(-14.3, -10.6), (-2.7, -10.6), (-2.7, -17), (-14.3, -17)], "탐험가 길드", (-8.5, -13.8))
    poly(d, [(-14.8, -8.4), (-11.8, -8.4), (-11.8, -6.4), (-14.8, -6.4)], fill=(150, 60, 50), outline=INK)
    label(d, -21, -7.0, "정산 천막", 20)
    label(d, 0, 4.4, "차원광장", 30, WINE, bold=True)
    facility(d, [(23, -3.5), (30, -0.8), (28, 4.5), (20.5, 1.5)], "여관", (25.4, 0.6))
    facility(d, [(40, -5.6), (52, -5.6), (52, -12.6), (40, -12.6)], "은행", (46, -9.1))
    facility(d, None, "도서관", (-43, -25), circle=(-43, -25, 5.2))
    facility(d, [(-14, -33), (8, -33), (8, -52), (-14, -52)], "신전", (-3, -42.5))
    facility(d, [(16.2, 23.1), (21.5, 26.0), (23.7, 22.0), (18.4, 19.1)], "잡화점", (20.0, 18.0))
    facility(d, [(42, 36.5), (54, 36.5), (54, 42.5), (42, 42.5)], "대장간", (48, 39.5))
    label(d, -21, 28.4, "시장골목(거울 사선)", 20, WINE, bold=True)
    label(d, 27, 30.8, "시장골목(사선)", 20, WINE, bold=True)
    label(d, -60, -7, "서문 거리", 20, WINE)
    label(d, 68, -3.2, "은행 거리", 20, WINE)
    label(d, -70, -18.8, "위 단 거리", 20, WINE)
    label(d, -70, 16.4, "아래 거리", 20, WINE)
    label(d, -70, 5.6, "난간 길", 20, WINE)
    label(d, -70, 39.5, "수로 거리", 20, WINE)
    label(d, -20, 46.3, "수로", 20, (230, 236, 230))
    # 광장 구역 그림 범위(구상 그림 view_labeled.jpg)
    a, b = P(-35, -45), P(35, 18)
    d.rectangle((a, b), outline=WINE, width=3)
    label(d, 22, -43, "구상 그림 범위", 20, WINE)
    # 범례
    ly = int(MH * S) + 120
    d.text((40, ly - 14), "거리는 세 방향뿐 — 집 그림 한 장이 그대로 맞는다", font=font(30), fill=INK)
    for i, (ang, name, sub) in enumerate([(0, "정면 줄", "정면 판 (variants/front)"), (-28.8, "사선 줄", "사선 판 (variants)"), (28.8, "거울 사선 줄", "사선 판 좌우 뒤집기")]):
        bx = 70 + i * 470
        a = math.radians(ang)
        cx, cy = bx + 70, ly + 120
        dx, dy = math.cos(a) * 60, math.sin(a) * 60
        d.line((cx - dx, cy + dy, cx + dx, cy - dy), fill=INK, width=4)
        for k in range(-1, 2):
            hx, hy = cx + dx * k * 0.6, cy - dy * k * 0.6
            nx, ny = -math.sin(a) * 34, -math.cos(a) * 34
            box = [(hx - dx * 0.25, hy + dy * 0.25), (hx + dx * 0.25, hy - dy * 0.25), (hx + dx * 0.25 + nx, hy - dy * 0.25 + ny), (hx - dx * 0.25 + nx, hy + dy * 0.25 + ny)]
            d.polygon(box, fill=ROW, outline=INK)
        d.line((cx, cy + 6, cx + math.sin(a) * 40, cy + 6 + math.cos(a) * 40), fill=WINE, width=4)
        d.text((bx + 160, ly + 80), name, font=font(28), fill=INK)
        d.text((bx + 160, ly + 120), sub, font=font(22), fill=(80, 64, 50))
        d.text((bx + 160, ly + 152), "앞면(문)이 붉은 쪽", font=font(20), fill=WINE)
    d.text((40, ly + 220), "북쪽이 높다(테라스 다섯 · 옹벽과 계단) — 카메라는 남쪽에서 약 18°로 내려다본다. 문은 모두 카메라 쪽(남 · 남남서 · 남남동)으로만.", font=font(22), fill=INK)
    img.save(os.path.join(DIR, "district.png"))


if __name__ == "__main__":
    os.makedirs(DIR, exist_ok=True)
    district()
    if os.path.exists(os.path.join(DIR, "district_hand.png")):
        view_labeled()
        plan_labeled()
    print("저장:", DIR)
