"""3D 도시 구상 배치도 — 라비기온 7구역(차원광장 포함) 위에서 본 그림(기획 단계 스케치, 게임 데이터 아님).
  python3 tools/city3d_board.py [--out=docs/plans/city3d]
좌표는 미터(1칸 = 1m) — 동서 160m × 남북 220m, 위가 북쪽(카메라는 남쪽에서 북쪽을 본다).
기획 기록은 docs/plans/city_3d.md. 실제 지도는 구현 때 data/town/*.json으로 다시 만든다.
"""
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
PX = 4  # 1m = 4px
W, H = 160, 220
MARGIN = 24
LEGEND_W = 300

LEVELS = [  # (y0, y1, 이름, 높이, 바닥색)
    (0, 70, "상단 +6m", 6, (92, 90, 84)),
    (70, 152, "중단 0m", 0, (78, 74, 68)),
    (152, 220, "하단 −4m", -4, (60, 56, 52)),
]
HOUSES = [  # 주택 덩어리(둘레 필지 + 가운데 안마당) — 길은 골목 3~4m · 거리 5~6m · 대로 16m
    (4, 6, 70, 28), (102, 6, 156, 16), (144, 18, 156, 66), (102, 20, 111, 50), (102, 52, 142, 64),
    (4, 32, 58, 64), (62, 48, 70, 64),
    (4, 82, 30, 108), (4, 112, 30, 146), (64, 80, 70, 103), (118, 80, 156, 104),
    (34, 106, 58, 146), (126, 108, 156, 146), (102, 136, 122, 148), (74, 144, 98, 150), (30, 146, 58, 150),
    (4, 153, 58, 158), (74, 153, 134, 158),
    (4, 164, 38, 200), (42, 188, 62, 200), (66, 164, 100, 200), (146, 164, 156, 200), (104, 196, 144, 200),
]
FACILITIES = [  # (x0, y0, x1, y1, 이름, 메모)
    (72, 8, 100, 44, "신전", "첨탑 둘 · 대계단 위"),
    (34, 82, 60, 102, "탐험가 길드", "광장 북서 · 포탈 관리"),
    (90, 82, 114, 102, "은행", "대로변 석조"),
    (102, 106, 122, 132, "여관", "광장 동쪽 면"),
    (42, 164, 62, 186, "잡화점", "시장골목 아케이드"),
    (104, 164, 130, 194, "대장간", "수로 옆 · 굴뚝"),
]
ROTUNDA = (127, 35, 14, "도서관", "원형 열람당 · 유리 돔")
PLAZA = (80, 124, 18)
STAIRS = [(72, 64, 88, 80, "대계단"), (30, 64, 34, 80, "골목 계단"), (62, 146, 72, 164, "시장 계단"), (136, 146, 142, 164, "경사로")]
WALLS = [(0, 0, 160, 4), (0, 0, 3, 210), (156, 0, 160, 210), (0, 212, 160, 220)]
RETAIN = [(0, 68, 160, 71), (0, 150, 160, 153)]
CANAL = (0, 202, 160, 210)
BRIDGES = [(78, 200, 88, 212), (118, 200, 125, 212)]
GATES = [(74, 0, 88, 4, "구역문(→ 6구역·컴멜비)"), (0, 158, 3, 164, "서문(→ 8구역)")]
OPEN_YARDS = [(72, 46, 100, 64, "신전 앞뜰"), (130, 164, 144, 194, "뒷마당")]
ROAD = (72, 80, 88, 106)  # 대로(계단 아래 → 광장)
ROOF = [(110, 74, 58), (98, 66, 54), (120, 84, 64), (88, 70, 60), (104, 92, 84)]
WALL_C = (44, 42, 40)
STREET = (128, 120, 108)
BONE = (224, 214, 194)
GOLD = (190, 160, 96)


def P(x, y):
    return (MARGIN + x * PX, MARGIN + y * PX)


def rect(d, r, fill, outline=None, w=1):
    d.rectangle([P(r[0], r[1]), P(r[2], r[3])], fill=fill, outline=outline, width=w)


def lots(d, rng, b):
    """덩어리 둘레를 폭 5~9m 필지로 나누고 깊이 10m 안쪽은 안마당으로 남긴다."""
    x0, y0, x1, y1 = b
    depth = 10
    court = (x1 - x0) > 2 * depth + 4 and (y1 - y0) > 2 * depth + 4
    rect(d, b, ROOF[0])
    for side in range(4):
        pos = 0.0
        length = (x1 - x0) if side < 2 else (y1 - y0)
        while pos < length - 1:
            w = min(rng.uniform(5, 9), length - pos)
            dep = depth if court else ((y1 - y0) if side < 2 else (x1 - x0)) / 2
            if side == 0:
                r = (x0 + pos, y0, x0 + pos + w, y0 + dep)
            elif side == 1:
                r = (x0 + pos, y1 - dep, x0 + pos + w, y1)
            elif side == 2:
                r = (x0, y0 + pos, x0 + dep, y0 + pos + w)
            else:
                r = (x1 - dep, y0 + pos, x1, y0 + pos + w)
            rect(d, r, rng.choice(ROOF), outline=(40, 32, 28))
            pos += w
    if court:
        rect(d, (x0 + depth, y0 + depth, x1 - depth, y1 - depth), (70, 74, 60), outline=(40, 32, 28))


def label(d, xy, text, font, fill=BONE, anchor="mm"):
    d.text(xy, text, font=font, fill=fill, anchor=anchor, stroke_width=3, stroke_fill=(16, 14, 12))


def main():
    out = os.path.join(ROOT, "docs", "plans", "city3d")
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = os.path.join(ROOT, a[6:])
    os.makedirs(out, exist_ok=True)
    rng = random.Random(7)
    img = Image.new("RGB", (MARGIN * 2 + W * PX + LEGEND_W, MARGIN * 2 + H * PX), (14, 12, 10))
    d = ImageDraw.Draw(img)
    f_big = ImageFont.truetype(FONT, 15)
    f = ImageFont.truetype(FONT, 12)
    f_s = ImageFont.truetype(FONT, 10)
    for y0, y1, _n, _h, c in LEVELS:  # 바닥(길)
        rect(d, (0, y0, W, y1), tuple(min(255, v + 44) for v in c))
    for y0, y1, _n, _h, c in LEVELS:  # 테라스 그늘 띠
        rect(d, (0, y0, W, y0 + 1), c)
    rect(d, CANAL, (52, 62, 66))
    for b in BRIDGES:
        rect(d, b, (112, 104, 94), outline=(40, 36, 32))
    rect(d, ROAD, (150, 140, 124))
    for b in OPEN_YARDS:
        rect(d, b[:4], (138, 128, 112), outline=(60, 54, 48))
        label(d, ((P(b[0], b[1])[0] + P(b[2], b[3])[0]) // 2, (P(b[0], b[1])[1] + P(b[2], b[3])[1]) // 2), b[4], f_s, fill=(200, 190, 170))
    for b in HOUSES:
        lots(d, rng, b)
    cx, cy, r = PLAZA  # 차원광장
    d.ellipse([P(cx - r, cy - r), P(cx + r, cy + r)], fill=(156, 146, 128), outline=(60, 54, 48), width=2)
    for k in range(3):  # 단 세 겹 + 돌 고리
        rr = 7 - k * 2
        d.ellipse([P(cx - rr, cy - rr - 2), P(cx + rr, cy + rr - 2)], outline=(70, 64, 56), width=2)
    d.ellipse([P(cx - 2.5, cy - 4.5), P(cx + 2.5, cy + 0.5)], outline=(120, 150, 170), width=3)
    label(d, (P(cx, cy + 9)[0], P(cx, cy + 9)[1]), "차원광장", f_big, fill=GOLD)
    label(d, (P(cx, cy - 2)[0], P(cx, cy - 2)[1] - 26), "포탈 돌 고리", f_s)
    tent = (64, 132, 71, 137)
    rect(d, tent, (120, 70, 56), outline=(30, 24, 20))
    label(d, P(68, 140), "정산 천막", f_s)
    rect(d, (91, 110, 96, 113), (96, 84, 70), outline=(30, 24, 20))
    label(d, P(93, 108), "공시판", f_s)
    for x0, y0, x1, y1, name in STAIRS:
        rect(d, (x0, y0, x1, y1), (150, 140, 126), outline=(50, 44, 38))
        for yy in range(int(y0) + 1, int(y1), 1):
            d.line([P(x0, yy), P(x1, yy)], fill=(96, 88, 78), width=1)
        label(d, (P(x1, y0)[0] + 4, (P(x0, y0)[1] + P(x0, y1)[1]) // 2), name, f_s, anchor="lm")
    for b in RETAIN:
        rect(d, b, WALL_C)
    for x0, y0, x1, y1, _n in STAIRS:  # 옹벽을 계단 자리만 뚫는다
        rect(d, (x0, y0 + 1, x1, y1 - 1), (150, 140, 126))
        for yy in range(int(y0) + 1, int(y1), 1):
            d.line([P(x0, yy), P(x1, yy)], fill=(96, 88, 78), width=1)
    for b in WALLS:
        rect(d, b, (36, 34, 32), outline=(20, 18, 16))
    for tx, ty in [(0, 212), (40, 212), (80, 212), (120, 212), (156, 212), (156, 100)]:  # 성벽 탑
        d.ellipse([P(tx - 3, ty - 1), P(tx + 5, ty + 7)], fill=(46, 44, 42), outline=(20, 18, 16), width=2)
    label(d, P(30, 216), "바깥 성벽", f_s)
    for x0, y0, x1, y1, name in GATES:
        rect(d, (x0, y0, x1, y1), (150, 140, 126))
        label(d, (P((x0 + x1) / 2, y1)[0] + (0 if y1 < 10 else 30), P((x0 + x1) / 2, y1)[1] + 10), name, f_s, anchor="mm" if y1 < 10 else "lm")
    for x0, y0, x1, y1, name, memo in FACILITIES:
        rect(d, (x0, y0, x1, y1), (132, 96, 70), outline=BONE, w=3)
        mx, my = (P(x0, y0)[0] + P(x1, y1)[0]) // 2, (P(x0, y0)[1] + P(x1, y1)[1]) // 2
        label(d, (mx, my - 7), name, f_big, fill=GOLD)
        label(d, (mx, my + 10), memo, f_s)
    rx, ry, rr, name, memo = ROTUNDA
    d.ellipse([P(rx - rr, ry - rr), P(rx + rr, ry + rr)], fill=(150, 146, 136), outline=BONE, width=3)
    d.ellipse([P(rx - rr + 4, ry - rr + 4), P(rx + rr - 4, ry + rr - 4)], outline=(110, 124, 130), width=2)
    label(d, (P(rx, ry)[0], P(rx, ry)[1] - 7), name, f_big, fill=GOLD)
    label(d, (P(rx, ry)[0], P(rx, ry)[1] + 10), memo, f_s)
    label(d, P(80, 206), "수로", f_s, fill=(160, 180, 186))
    label(d, P(22, 161), "시장골목", f_s)
    label(d, P(80, 90), "대로", f_s)
    # 범례
    lx = MARGIN * 2 + W * PX
    ly = MARGIN
    d.text((lx, ly), "라비기온 7구역 — 3D 구상 배치도", font=f_big, fill=BONE)
    ly += 26
    lines = [
        "1칸 = 1m · 동서 160m × 남북 220m",
        "위 = 북. 카메라는 남쪽에서 내려다본다",
        "",
        "높낮이(테라스 셋)",
    ]
    for y0, y1, n, _h, c in LEVELS:
        lines.append(f"  {n}  (남북 {y0}~{y1}m)")
    lines += [
        "",
        "시설 = 뼈빛 테두리 · 금색 이름",
        "갈색 칸 = 주택 필지(폭 5~9m, 3~5층)",
        "녹회색 = 덩어리 안 안마당(빨래·우물)",
        "검은 띠 = 옹벽(테라스 경계) · 성벽",
        "줄무늬 = 계단",
        "",
        "걸음 거리(광장 고리 → 문)",
        "  여관 20m · 은행 30m · 길드 40m",
        "  잡화점 60m · 신전 80m",
        "  대장간·도서관 약 100m",
        "  (초속 4m면 가장 먼 곳도 25초 안팎)",
        "",
        "거리 성격",
        "  대로·광장: 넓고 밝다(가로등)",
        "  상단: 조용한 석조 · 신전 첨탑이",
        "        어디서나 보이는 랜드마크",
        "  하단: 좁고 어둡다 · 연기·수로",
        "        (대로변과 뒷골목 격차)",
    ]
    for t in lines:
        d.text((lx, ly), t, font=f, fill=(200, 192, 178))
        ly += 18
    # 축척
    sx, sy = lx, ly + 16
    d.line([(sx, sy), (sx + 20 * PX, sy)], fill=BONE, width=3)
    d.text((sx + 20 * PX + 8, sy - 8), "20m", font=f, fill=BONE)
    img.save(os.path.join(out, "district7.png"))
    print("저장:", os.path.join(out, "district7.png"))


if __name__ == "__main__":
    main()
