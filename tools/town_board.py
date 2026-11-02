"""도시 동네 지도 배치도 — data/town/<id>.json(라비기온 7구역, CT82)을 위에서 본 그림으로.
  python3 tools/town_board.py [--map=district7] [--out=docs/plans/town]
areas(길·광장·계단·옹벽·수로)·buildings(시설 — 뼈빛 테두리·금색 이름)·props(가로등 점)는 데이터 그대로,
blocks(주택 덩어리 — 게임은 그 각도로 기운 작은 집으로 채운다)는 집 줄 스케치(각도 없이 — 게임은 TownMap이 지도 seed로 세운다).
기획 기록은 docs/plans/city_town.md. 위 = 북, 1칸 = 4px.
"""
import json
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
PX = 4
MARGIN = 24
LEGEND_W = 300
NAMES = {"temple": "신전", "library": "도서관", "guild": "탐험가 길드", "bank": "은행", "inn": "여관", "shop": "잡화점", "smithy": "대장간"}
KIND = {
    "street": (128, 120, 108), "avenue": (150, 140, 124), "paving": (146, 138, 122), "plaza": (160, 150, 132),
    "stairs": (170, 160, 144), "bridge": (120, 108, 94), "yard": (120, 102, 80), "water": (52, 66, 72),
    "retain": (44, 42, 40), "wall": (34, 32, 30), "gate": (12, 10, 9), "dais": (186, 176, 156),
}
ROOF = [(110, 74, 58), (98, 66, 54), (120, 84, 64), (88, 70, 60), (84, 88, 96)]
BONE = (224, 214, 194)
GOLD = (190, 160, 96)


def P(x, y):
    return (MARGIN + x * PX, MARGIN + y * PX)


def rect(d, r, fill, outline=None, w=1):
    d.rectangle([P(r[0], r[1]), P(r[2], r[3])], fill=fill, outline=outline, width=w)


def lots(d, rng, b):
    x0, y0, x1, y1 = b[:4]
    if x1 - x0 <= 8 and y1 - y0 > x1 - x0:
        y = y0
        while y < y1:
            w = min(rng.randint(4, 8), y1 - y)
            rect(d, (x0, y, x1, y + w), rng.choice(ROOF), outline=(36, 30, 26))
            y += w
        return
    y = y0
    while y < y1:
        dep = rng.randint(4, 7)
        if y1 - y - dep < 4:
            dep = y1 - y if y1 - y <= 9 else y1 - y - 4
        x = x0
        while x < x1:
            w = rng.randint(4, 8)
            if x1 - x - w < 4:
                w = x1 - x if x1 - x <= 10 else x1 - x - 4
            rect(d, (x, y, x + w, y + dep), rng.choice(ROOF), outline=(36, 30, 26))
            d.line([P(x, y + dep), P(x + w, y + dep)], fill=(200, 186, 160), width=1)  # 앞면(남쪽)
            x += w
        y += dep
        if y1 - y >= 10 and rng.random() < 0.35:
            y += 2


def label(d, xy, text, font, fill=BONE, anchor="mm"):
    d.text(xy, text, font=font, fill=fill, anchor=anchor, stroke_width=3, stroke_fill=(16, 14, 12))


def main():
    map_id = "district7"
    out = os.path.join(ROOT, "docs", "plans", "town")
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = os.path.join(ROOT, a[6:])
        elif a.startswith("--map="):
            map_id = a[6:]
    data = json.load(open(os.path.join(ROOT, "data", "town", map_id + ".json"), encoding="utf-8"))
    W, H = data["size"]
    os.makedirs(out, exist_ok=True)
    img = Image.new("RGB", (MARGIN * 2 + W * PX + LEGEND_W, MARGIN * 2 + H * PX), (10, 9, 8))
    d = ImageDraw.Draw(img)
    f_big = ImageFont.truetype(FONT, 15)
    f = ImageFont.truetype(FONT, 12)
    f_s = ImageFont.truetype(FONT, 10)
    for a in data["areas"]:
        c = KIND.get(a["kind"], (90, 90, 90))
        if "circle" in a:
            cx, cy, r = a["circle"]
            d.ellipse([P(cx - r, cy - r), P(cx + r, cy + r)], fill=c)
        else:
            rect(d, a["rect"], c)
        if a["kind"] == "stairs":
            x0, y0, x1, y1 = a["rect"]
            for yy in range(y0 + 1, y1):
                d.line([P(x0, yy), P(x1, yy)], fill=(100, 92, 82))
    rng = random.Random(data.get("seed", 7))
    for b in data["blocks"]:
        lots(d, rng, b)
        if len(b) >= 5 and b[4]:
            label(d, P((b[0] + b[2]) / 2, (b[1] + b[3]) / 2), "%+d°" % b[4], f_s)
    for p in data.get("props", []):
        pts = []
        if "at" in p:
            pts = p["at"]
        elif "line" in p:
            x0, y0, x1, y1 = p["line"]
            n = max(abs(x1 - x0), abs(y1 - y0))
            step = p.get("step", 6)
            pts = [(x0 + (x1 - x0) * i * step // max(1, n), y0 + (y1 - y0) * i * step // max(1, n)) for i in range(n // step + 1)]
        elif "rect" in p:
            pts = [p["rect"][:2]]
        if p["kind"] == "lamp":
            for (x, y) in pts:
                d.ellipse([P(x + 0.1, y + 0.1), P(x + 0.9, y + 0.9)], fill=(232, 200, 140))
        elif p["kind"] == "tent" and "rect" in p:
            rect(d, p["rect"], (122, 58, 50))
    for b in data["buildings"]:
        name = NAMES.get(b["facility"], b["facility"])
        if "circle" in b:
            cx, cy, r = b["circle"]
            d.ellipse([P(cx - r, cy - r), P(cx + r, cy + r)], fill=(150, 146, 136), outline=BONE, width=3)
            mx, my = P(cx, cy)
        else:
            rect(d, b["rect"], (132, 96, 70), outline=BONE, w=3)
            mx, my = P((b["rect"][0] + b["rect"][2]) / 2, (b["rect"][1] + b["rect"][3]) / 2)
        dx, dy = b["door"]
        rect(d, (dx - 1, dy, dx + 2, dy + 1), GOLD)
        label(d, (mx, my), name, f_big, fill=GOLD)
    cx, cy = data["start"]
    d.ellipse([P(cx - 1, cy - 1), P(cx + 1, cy + 1)], outline=(140, 200, 140), width=2)
    lx = MARGIN * 2 + W * PX
    ly = MARGIN
    d.text((lx, ly), data.get("name_ko", map_id) + " — 동네 지도", font=f_big, fill=BONE)
    ly += 26
    lines = [
        f"{W}×{H}칸 · 위 = 북 · 3/4 탑뷰",
        "(건물 남쪽 앞면이 보인다)",
        "",
        "시설 = 뼈빛 테두리 · 금색 이름",
        "  금색 칸 = 문(앞에서 위를 보고 Enter)",
        "갈색 칸 = 주택 덩어리(스케치 — 게임은 기운 작은 집)",
        "  숫자 = 덩어리 각도(도)",
        "검은 띠 = 옹벽(테라스) · 성벽 · 구역문",
        "줄무늬 = 계단 · 노란 점 = 가로등",
        "초록 고리 = 들어온 자리(차원광장)",
        "",
        "테라스: 위(신전·도서관) / 가운데(광장·",
        "  길드·은행·여관) / 아래(시장·대장간·수로)",
    ]
    for t in lines:
        d.text((lx, ly), t, font=f, fill=(200, 192, 178))
        ly += 18
    d.line([(lx, ly + 16), (lx + 20 * PX, ly + 16)], fill=BONE, width=3)
    d.text((lx + 20 * PX + 8, ly + 8), "20칸", font=f, fill=BONE)
    path = os.path.join(out, map_id + ".png")
    img.save(path)
    print("저장:", path)


if __name__ == "__main__":
    main()
