"""도시 실내 복층 배치도 — 기획용 설계도(docs/plans/city_boards/<건물>.json)를 그림으로(균열 배치도 tools/rift_boards.py와 같은 꼴).
  python3 tools/city_boards.py [--cell=18] [--out=docs/plans/city_boards]
건물마다 <건물>.png(층을 옆으로 나란히 + 그 건물 범례) + 모아 본 all.png.
칸 색: 바닥(층 재질 — 판자·돌판·대리석·흙·어두운 돌) · 벽(어둡게) · 벽 장식(벽 위 색 띠) · 가구(테두리) · 빛 나는 가구(노란 점) · 바닥 장식(바닥 위 무늬) ·
깔개 · 계단(줄무늬) · 사다리(가로대) · 문(주황) · 문간 · 잠긴 문(빨간 X) · 입구(초록) · 트인 곳(아래층이 보임 — 빗금) · 난간.
표시: 흰 동그라미 = 사람(직원), 회색 = 분위기 사람 · 금색 이름표 = 주 활동 자리 · 흰 = 부 활동 · 보라 = 사건 때만 · 하늘색 = 층 사이(같은 글자끼리 이어진다).
게임은 이 파일을 읽지 않는다(기획안 — docs/plans/city_interiors.md).
"""
import glob
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")

FLOORS = {"wood": (112, 82, 56), "stone": (104, 102, 98), "marble": (168, 164, 154), "dirt": (138, 116, 82), "dark": (72, 70, 68)}
COMMON = {
    "#": ("벽", "wall", None), ".": ("바닥", "floor", None), ",": ("깔개", "rug", "#7a3a34"), "=": ("통로 깔개", "rug", "#8a2e2a"),
    "_": ("흙·모래", "dirt", None), ":": ("대리석", "floor", None), " ": ("밖", "void", None),
    "D": ("입구", "entry", None), "+": ("문(다가가면 열림)", "door", None), "/": ("문간", "doorway", None), "X": ("잠긴 문(사건 때 열림)", "locked", None),
    "^": ("올라가는 계단", "stairs_up", None), "v": ("내려가는 계단", "stairs_down", None), "H": ("사다리(오르기)", "ladder", None), "h": ("사다리(내려가기 — 바닥 구멍)", "ladder_down", None),
    "z": ("트인 곳(아래층이 보임)", "open", None), "r": ("난간", "rail", None), "@": ("사람", "npc_cell", None), "W": ("창", "walldeco", "#8a9aa4"),
}
SPOT = {"main": (236, 196, 84), "sub": (226, 226, 226), "event": (186, 136, 236)}


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def look(ch, legend, base):
    if ch in legend:
        name, kind, col = legend[ch][0], legend[ch][1], legend[ch][2]
    else:
        name, kind, col = COMMON.get(ch, ("?", "floor", None))
    return name, kind, hexc(col) if col else None, base


def draw_cell(d, x0, y0, c, kind, col, base):
    wall = (44, 40, 38)
    e = c - 1
    if kind in ("floor", "npc_cell"):
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=base)
    elif kind == "dirt":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=FLOORS["dirt"])
    elif kind == "wall":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=wall)
    elif kind == "void":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(14, 14, 16))
    elif kind == "walldeco":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=wall)
        d.rectangle([x0 + 2, y0 + 3, x0 + e - 2, y0 + e - 3], fill=col)
    elif kind == "rug":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=col)
    elif kind == "decor":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=mix(base, col, 0.55))
        d.ellipse([x0 + c // 2 - 2, y0 + c // 2 - 2, x0 + c // 2 + 2, y0 + c // 2 + 2], fill=mix(col, (255, 255, 255), 0.3))
    elif kind in ("furniture", "light"):
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=base)
        d.rectangle([x0 + 1, y0 + 1, x0 + e - 1, y0 + e - 1], fill=mix(col, (20, 20, 20), 0.15), outline=mix(col, (255, 255, 255), 0.4))
        if kind == "light":
            d.ellipse([x0 + c // 2 - 3, y0 + 2, x0 + c // 2 + 3, y0 + 8], fill=(255, 220, 110))
    elif kind in ("stairs_up", "stairs_down"):
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(150, 132, 106))
        for k in range(4):
            yy = y0 + 2 + k * (c - 4) // 4
            d.line([x0 + 2, yy, x0 + e - 2, yy], fill=(70, 56, 40), width=2)
        if kind == "stairs_down":
            d.rectangle([x0, y0 + c // 2, x0 + e, y0 + e], fill=(40, 32, 26))
    elif kind in ("ladder", "ladder_down"):
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=base if kind == "ladder" else (20, 18, 16))
        d.line([x0 + 4, y0, x0 + 4, y0 + e], fill=(176, 130, 70), width=2)
        d.line([x0 + e - 4, y0, x0 + e - 4, y0 + e], fill=(176, 130, 70), width=2)
        for k in range(3):
            yy = y0 + 3 + k * (c - 6) // 2
            d.line([x0 + 4, yy, x0 + e - 4, yy], fill=(176, 130, 70), width=2)
    elif kind == "door":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(206, 140, 62))
    elif kind == "doorway":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=base, outline=(206, 160, 90))
    elif kind == "locked":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(120, 40, 36))
        d.line([x0 + 3, y0 + 3, x0 + e - 3, y0 + e - 3], fill=(250, 200, 190), width=2)
        d.line([x0 + e - 3, y0 + 3, x0 + 3, y0 + e - 3], fill=(250, 200, 190), width=2)
    elif kind == "entry":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(96, 196, 104))
    elif kind == "open":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=(22, 22, 28))
        d.line([x0, y0 + e, x0 + e, y0], fill=(56, 56, 70))
    elif kind == "rail":
        d.rectangle([x0, y0, x0 + e, y0 + e], fill=base)
        d.rectangle([x0, y0 + c // 2 - 2, x0 + e, y0 + c // 2 + 2], fill=(150, 110, 60))


def tag(d, font, x, y, text, col, w, h, taken, top):
    tw = d.textlength(text, font=font)
    tx = min(max(x + 10, 2), w - tw - 4)
    ty = min(max(y - 9, top), h - 20)
    for _ in range(8):
        if not any(tx < r[2] and tx + tw > r[0] and ty < r[3] and ty + 18 > r[1] for r in taken):
            break
        ty = ty + 19 if ty + 38 < h else ty - 19
    taken.append((tx - 3, ty - 1, tx + tw + 3, ty + 17))
    d.rectangle([tx - 3, ty - 1, tx + tw + 3, ty + 17], fill=(14, 14, 16), outline=col)
    d.text((tx, ty - 1), text, font=font, fill=col)


def floor_img(b, fl, legend, cell, font, big, mid):
    rows = fl["rows"]
    w, h = max(len(r) for r in rows) * cell, len(rows) * cell
    pad_top = 34
    img = Image.new("RGB", (max(w, 260) + 16, h + pad_top + 12), (24, 24, 28))
    d = ImageDraw.Draw(img)
    base = FLOORS.get(fl.get("floor", "wood"), FLOORS["wood"])
    ox, oy = 8, pad_top
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            _, kind, col, _ = look(ch, legend, base)
            draw_cell(d, ox + x * cell, oy + y * cell, cell, kind, col, base)
    d.text((8, 4), fl["name_ko"], font=big, fill=(240, 236, 228))
    taken = []
    for x, y, t in fl.get("rooms", []):  # 방 이름(큰 글씨, 그림자)
        tw = d.textlength(t, font=mid)
        tx, ty = ox + x * cell + cell // 2 - tw / 2, oy + y * cell
        d.text((tx + 1, ty + 1), t, font=mid, fill=(0, 0, 0))
        d.text((tx, ty), t, font=mid, fill=(250, 246, 236))
        taken.append((tx - 2, ty, tx + tw + 2, ty + 20))
    for x, y, t, kind in fl.get("npcs", []):
        cx, cy = ox + x * cell + cell // 2, oy + y * cell + cell // 2
        fill = (236, 226, 200) if kind == "staff" else (150, 150, 150)
        d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=fill, outline=(0, 0, 0), width=2)
        tag(d, font, cx, cy, t, fill, img.width, img.height, taken, pad_top)
    for x, y, t, kind in fl.get("spots", []):
        cx, cy = ox + x * cell + cell // 2, oy + y * cell + cell // 2
        d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=SPOT[kind], outline=(0, 0, 0))
        tag(d, font, cx, cy + 14, t, SPOT[kind], img.width, img.height, taken, pad_top)
    for x, y, key, t in fl.get("links", []):
        cx, cy = ox + x * cell + cell // 2, oy + y * cell + cell // 2
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(120, 200, 250), outline=(0, 0, 0), width=2)
        d.text((cx - 4, cy - 10), key, font=font, fill=(0, 0, 0))
        tag(d, font, cx, cy, t, (140, 210, 255), img.width, img.height, taken, pad_top)
    for x, y, t in fl.get("labels", []):
        tag(d, font, ox + x * cell + cell // 2, oy + y * cell + cell // 2, t, (200, 190, 170), img.width, img.height, taken, pad_top)
    return img


def legend_img(b, width, cell, font):
    used = set("".join("".join(f["rows"]) for f in b["floors"]))
    items = [(ch, v[0], v[1], v[2]) for ch, v in b["legend"].items() if ch in used]
    items += [(ch, v[0], v[1], v[2]) for ch, v in COMMON.items() if ch in used and ch not in b["legend"] and ch not in "#. @_:"]
    col_w = 230
    per = max(1, (width - 16) // col_w)
    rows = (len(items) + per - 1) // per
    img = Image.new("RGB", (width, rows * (cell + 6) + 14), (24, 24, 28))
    d = ImageDraw.Draw(img)
    for i, (ch, name, kind, col) in enumerate(items):
        x0, y0 = 8 + (i % per) * col_w, 8 + (i // per) * (cell + 6)
        draw_cell(d, x0, y0, cell, kind, hexc(col) if col else None, FLOORS["wood"])
        d.text((x0 + cell + 6, y0 - 1), name, font=font, fill=(220, 214, 200))
    return img


def building(b, cell):
    font = ImageFont.truetype(FONT, 13)
    big = ImageFont.truetype(FONT, 17)
    mid = ImageFont.truetype(FONT, 15)
    title = ImageFont.truetype(FONT, 22)
    legend = b["legend"]
    floors = [floor_img(b, f, legend, cell, font, big, mid) for f in b["floors"]]
    gap = 14
    w = sum(f.width for f in floors) + gap * (len(floors) - 1) + 16
    w = max(w, 900)
    lg = legend_img(b, w, cell, font)
    head = 64
    h = head + max(f.height for f in floors) + lg.height + 10
    img = Image.new("RGB", (w, h), (16, 16, 18))
    d = ImageDraw.Draw(img)
    d.text((10, 6), b["name_ko"], font=title, fill=(244, 240, 230))
    d.text((10, 38), b.get("note", ""), font=font, fill=(190, 184, 170))
    x = 8
    for f in floors:
        img.paste(f, (x, head))
        x += f.width + gap
    img.paste(lg, (0, head + max(f.height for f in floors) + 4))
    return img


def main():
    args = {"cell": "18", "out": "docs/plans/city_boards"}
    for a in sys.argv[1:]:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            args[k] = v
    cell = int(args["cell"])
    out = os.path.join(ROOT, args["out"])
    imgs = []
    for path in sorted(glob.glob(os.path.join(ROOT, "docs", "plans", "city_boards", "*.json"))):
        with open(path, encoding="utf-8") as f:
            b = json.load(f)
        img = building(b, cell)
        img.save(os.path.join(out, b["id"] + ".png"))
        imgs.append(img)
        print(b["id"], img.size)
    w = max(i.width for i in imgs)
    allimg = Image.new("RGB", (w, sum(i.height for i in imgs)), (16, 16, 18))
    y = 0
    for i in imgs:
        allimg.paste(i, (0, y))
        y += i.height
    allimg.save(os.path.join(out, "all.png"))


if __name__ == "__main__":
    main()
