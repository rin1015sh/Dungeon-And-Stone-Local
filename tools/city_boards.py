"""도시 실내 배치도 — 게임 지도(data/rooms/<건물>.json — 한 지도에 층이 다 있다, CT66)를 그림으로(균열 배치도 tools/rift_boards.py와 같은 꼴).
  python3 tools/city_boards.py [--cell=14] [--out=docs/plans/city_boards]
건물마다 <건물>.png(지도 + 그 건물 범례) + 모아 본 all.png. 공통 칸 글자는 data/city.json room.legend.
칸 색: 바닥(층 재질 — 판자·돌판·대리석·흙·어두운 돌) · 벽(어둡게) · 벽 장식(벽 위 색 띠) · 가구(테두리) · 빛 나는 가구(노란 점) · 바닥 장식(바닥 위 무늬) ·
깔개 · 계단(줄무늬) · 사다리(가로대) · 문(주황) · 문간 · 잠긴 문(빨간 X) · 입구(초록) · 트인 곳(아래층이 보임 — 빗금) · 난간.
표시: 흰 동그라미 = 사람(직원), 회색 = 분위기 사람 · 금색 이름표 = 주 활동 자리 · 흰 = 부 활동 · 보라 = 사건 때만 · 하늘색 = 층 사이(같은 글자끼리 이어진다).
기획 기록은 docs/plans/city_interiors.md.
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


KIND = {"floor": "floor", "rug": "rug", "decor": "decor", "wall": "wall", "walldeco": "walldeco", "door": "door", "doorway": "doorway",
        "locked": "locked", "entry": "entry", "stairs": "stairs_up", "ladder": "ladder", "open": "open", "rail": "rail", "void": "void", "npc": "npc_cell"}


def look(ch, legend):
    d = legend.get(ch, {})
    kind = d.get("kind", "void")
    if kind == "furniture":
        kind = "light" if d.get("light") else "furniture"
    else:
        kind = KIND.get(kind, "floor")
    col = d.get("color")
    return d.get("name_ko", ch), kind, hexc(col) if col else None


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


def legend_img(b, width, cell, font):
    used = set("".join("".join(f["rows"]) for f in b["floors"]))
    items = [(ch,) + look(ch, b["legend"]) for ch in b["legend"] if ch in used and ch not in "#. @"]
    col_w = 210
    per = max(1, (width - 16) // col_w)
    rows = (len(items) + per - 1) // per
    img = Image.new("RGB", (width, rows * (cell + 6) + 14), (24, 24, 28))
    d = ImageDraw.Draw(img)
    for i, (ch, name, kind, col) in enumerate(items):
        x0, y0 = 8 + (i % per) * col_w, 8 + (i // per) * (cell + 6)
        draw_cell(d, x0, y0, cell, kind, col, FLOORS["wood"])
        d.text((x0 + cell + 6, y0 - 2), name, font=font, fill=(220, 214, 200))
    return img


def material(room, legend, x, y):
    d = legend.get(room["rows"][y][x], {})
    if d.get("kind") == "floor" and d.get("material"):
        return d["material"]
    m = room.get("floor", "wood")
    for rg in room.get("regions", []):
        r = rg["rect"]
        if r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3]:
            m = rg.get("floor", m)
    return m


def acts_text(sp, acts):
    ids = ([sp["activity"]] if sp.get("activity") else []) + sp.get("activities", [])
    names = " · ".join(acts.get(a, {}).get("name_ko", a) for a in ids)
    if sp.get("rest"):
        names += (" · " if names else "") + "(사건)"
    head = sp.get("name_ko", "")
    kind = "event" if not ids or all(acts.get(a, {}).get("extra") for a in ids) else "main"
    return (head + " — " + names if head else names), kind


def building(room, legend, acts, cell):
    font = ImageFont.truetype(FONT, 12)
    mid = ImageFont.truetype(FONT, 15)
    title = ImageFont.truetype(FONT, 22)
    rows = room["rows"]
    mw, mh = max(len(r) for r in rows) * cell, len(rows) * cell
    lg = legend_img({"legend": legend, "floors": [{"rows": rows}]}, max(mw + 16, 900), cell, font)
    head = 40
    img = Image.new("RGB", (max(mw + 16, 900), head + mh + 12 + lg.height), (16, 16, 18))
    d = ImageDraw.Draw(img)
    d.text((10, 6), room["name_ko"] + "  ·  한 지도(위층 북쪽 · 지하 남쪽, 계단·사다리 줄로 이어짐)", font=title, fill=(244, 240, 230))
    ox, oy = 8, head
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            _, kind, col = look(ch, legend)
            draw_cell(d, ox + x * cell, oy + y * cell, cell, kind, col, FLOORS.get(material(room, legend, x, y), FLOORS["wood"]))
    taken = []
    for x, y, t, k in room.get("names", []):
        if k == "room":
            tw = d.textlength(t, font=mid)
            tx, ty = ox + x * cell + cell // 2 - tw / 2, oy + y * cell
            d.text((tx + 1, ty + 1), t, font=mid, fill=(0, 0, 0))
            d.text((tx, ty), t, font=mid, fill=(250, 246, 236))
            taken.append((tx - 2, ty, tx + tw + 2, ty + 20))
    for n in room.get("npcs", []):
        x, y = n["at"]
        cx, cy = ox + x * cell + cell // 2, oy + y * cell + cell // 2
        fill = (236, 226, 200) if n.get("staff", True) else (150, 150, 150)
        d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=fill, outline=(0, 0, 0), width=2)
        tag(d, font, cx, cy, n["name_ko"], fill, img.width, img.height, taken, head)
    for sp in room.get("spots", []):
        r = sp["rect"]
        cx, cy = ox + (r[0] + r[2] / 2) * cell, oy + (r[1] + r[3]) * cell
        t, kind = acts_text(sp, acts)
        d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=SPOT[kind], outline=(0, 0, 0))
        tag(d, font, cx, cy + 12, t, SPOT[kind], img.width, img.height, taken, head)
    for x, y, t, k in room.get("names", []):
        if k != "room":
            tag(d, font, ox + x * cell + cell // 2, oy + y * cell + cell // 2, t, (200, 190, 170), img.width, img.height, taken, head)
    img.paste(lg, (0, head + mh + 8))
    return img


def main():
    args = {"cell": "14", "out": "docs/plans/city_boards"}
    for a in sys.argv[1:]:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            args[k] = v
    cell = int(args["cell"])
    out = os.path.join(ROOT, args["out"])
    with open(os.path.join(ROOT, "data", "city.json"), encoding="utf-8") as f:
        common = json.load(f)["room"]["legend"]
    acts = {}
    for path in glob.glob(os.path.join(ROOT, "data", "activities", "*.json")):
        if not os.path.basename(path).startswith("_"):
            with open(path, encoding="utf-8") as f:
                a = json.load(f)
            acts[a["id"]] = a
    imgs = []
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "rooms", "*.json"))):
        if os.path.basename(path).startswith("_"):
            continue
        with open(path, encoding="utf-8") as f:
            room = json.load(f)
        legend = dict(common)
        legend.update(room.get("legend", {}))
        img = building(room, legend, acts, cell)
        img.save(os.path.join(out, room["id"] + ".png"))
        imgs.append(img)
        print(room["id"], img.size)
    w = sum(i.width for i in imgs[:4])
    rows = [imgs[k:k + 4] for k in range(0, len(imgs), 4)]
    allimg = Image.new("RGB", (max(sum(i.width for i in r) for r in rows), sum(max(i.height for i in r) for r in rows)), (16, 16, 18))
    y = 0
    for r in rows:
        x = 0
        for i in r:
            allimg.paste(i, (x, y))
            x += i.width
        y += max(i.height for i in r)
    allimg.save(os.path.join(out, "all.png"))


if __name__ == "__main__":
    main()
