"""균열 배치도 그림 — 지금 설계도(data/maps/rifts/)를 그대로 그린다.
  python3 tools/rift_boards.py [--out=docs/plans/rift_boards/current] [--cell=12]
챕터마다 <균열>_<챕터>.png + 균열마다 모아 본 <균열>.png.
칸 색: 걷는 바닥(타일 색을 밝게) · 벽(어둡게) · 소품(막는 것, 테두리) · 물·웅덩이(못 걷는 바닥) · 낭떠러지(검정) · 솟은 외곽(빗금).
점: 노란 점 = 빛 나는 소품, 흰 점 = 살필 수 있는 잡템(scavenge).
표시: 초록 = 시작·입구, 하늘 = 출구(마지막 챕터는 수호자 자리에 탈출 포탈), 빨강 = 조우(보라 = 수호자·중간 보스),
노랑 = 히든 피스, 주황 = 함정·위험. 대기 무리(posts)는 자리 없이 맨 위 줄에 수만 적는다.
"""
import glob
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")


def load(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return json.load(f)


def names(folder):
    out = {}
    for f in glob.glob(os.path.join(ROOT, "data", folder, "*.json")):
        if os.path.basename(f).startswith("_"):
            continue
        d = load(f)
        if "id" in d:
            out[d["id"]] = d.get("name_ko", d["id"])
    return out


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def cell_look(t):
    """타일 → (바탕색, 소품 테두리 색 또는 None, 종류)."""
    cols = t.get("colors", {})
    if t.get("rise"):
        return (54, 58, 70), None, "rise"
    if t.get("void"):
        return (6, 6, 8), None, "void"
    if t.get("kind") == "floor":
        c = hexc(cols.get("floor", "#555555"))
        if not t.get("walkable"):
            return mix(c, (255, 255, 255), 0.12), None, "liquid"
        return mix(c, (235, 228, 215), 0.38), None, "floor"
    face = hexc(cols.get("face", cols.get("top", "#444444")))
    if "stand" not in t.get("art", {}) and not t.get("scavenge"):  # 칸을 채우는 벽(세워 그린 소품이 아닌 것)
        return mix(hexc(cols.get("top", "#222222")), (92, 92, 104), 0.5), None, "wall"
    return (70, 66, 62), face, "prop"


def encounter_label(e, monsters, guardian):
    kind = e.get("kind")
    if kind == "guardian":
        return "수호자 " + monsters.get(guardian, guardian), True
    if kind == "chain":
        n = len(e.get("battles", []))
        last = e["battles"][-1]
        boss = monsters.get(last[0], last[0]) if isinstance(last, list) and len(last) == 1 else ""
        return "연전 %d판%s" % (n, " → " + boss if boss else ""), bool(e.get("midboss"))
    ids = e.get("monsters", [])
    label = " + ".join(monsters.get(m, m) for m in dict.fromkeys(ids))
    if len(ids) > 1 and len(set(ids)) == 1:
        label += " ×%d" % len(ids)
    if e.get("riddle"):
        label += "(수수께끼)"
    if e.get("guard"):
        label += "(성문 수비대 %d)" % len(ids)
    return label, bool(e.get("midboss"))


def draw_tag(d, font, x, y, text, fill, w, h, taken):
    tw = d.textlength(text, font=font)
    tx = min(max(x + 9, 2), w - tw - 4)
    ty = min(max(y - 9, 26), h - 20)
    for _ in range(6):  # 앞서 단 이름표와 겹치면 아래로 비킨다
        if not any(tx < r[2] and tx + tw > r[0] and ty < r[3] and ty + 18 > r[1] for r in taken):
            break
        ty = ty + 19 if ty + 38 < h else ty - 19
    taken.append((tx - 3, ty - 1, tx + tw + 3, ty + 17))
    d.rectangle([tx - 3, ty - 1, tx + tw + 3, ty + 17], fill=(14, 14, 16), outline=fill)
    d.text((tx, ty - 1), text, font=font, fill=fill)


def board(rift, ch_index, tiles, monsters, items, cell):
    ch = rift["chapters"][ch_index]
    bp = load(ch["map"]["blueprint"].replace("res://", ""))
    w, h = bp["width"] * cell, bp["height"] * cell + 30
    img = Image.new("RGB", (w, h), (14, 14, 16))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, 13)
    big = ImageFont.truetype(FONT, 16)
    for y, row in enumerate(bp["rows"]):
        for x, chr_ in enumerate(row):
            t = tiles.get(bp["legend"].get(chr_, ""), {})
            base, edge, kind = cell_look(t)
            x0, y0 = x * cell, y * cell + 30
            d.rectangle([x0, y0, x0 + cell - 1, y0 + cell - 1], fill=base)
            if kind == "rise":
                d.line([x0, y0 + cell - 1, x0 + cell - 1, y0], fill=(90, 96, 112))
            if edge:
                d.rectangle([x0 + 1, y0 + 1, x0 + cell - 2, y0 + cell - 2], fill=mix(edge, (30, 30, 30), 0.25),
                            outline=mix(edge, (255, 255, 255), 0.3))
            if t.get("light") and kind == "prop":
                d.ellipse([x0 + cell // 2 - 2, y0 + 2, x0 + cell // 2 + 2, y0 + 6], fill=(255, 220, 110))
            if t.get("scavenge"):
                d.ellipse([x0 + cell // 2 - 2, y0 + cell - 6, x0 + cell // 2 + 2, y0 + cell - 2], fill=(245, 245, 245))
    marks = bp.get("marks", {})
    last = ch_index == len(rift["chapters"]) - 1
    tags = []

    def at(p):
        return p[0] * cell + cell // 2, p[1] * cell + 30 + cell // 2

    def dot(p, fill, r=6):
        cx, cy = at(p)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=(0, 0, 0), width=2)

    if "entry" in marks:
        dot(marks["entry"], (110, 220, 110))
        tags.append((marks["entry"], "시작" if ch_index == 0 else "입구(앞 챕터에서)", (130, 235, 130)))
    encs = [e for e in ch.get("encounters", []) if e.get("kind") != "posts"]
    encs.sort(key=lambda e: e.get("kind") == "guardian")
    guardian_at = None
    for p, e in zip(marks.get("slots", []), encs):
        label, boss = encounter_label(e, monsters, rift.get("guardian", ""))
        col = (200, 90, 230) if boss or e.get("kind") == "guardian" else (230, 70, 60)
        dot(p, col, 7)
        tags.append((p, label, col))
        if e.get("kind") == "guardian":
            guardian_at = p
    hidden = ch.get("hidden", [])
    seen = set()
    for p, hd in zip(marks.get("hidden", []), hidden):
        dot(p, (250, 215, 70))
        name = "벽화" if hd.get("mural") else items.get(hd.get("item", ""), hd.get("id"))
        if hd.get("one_of"):
            name = "보물 더미" if hd["one_of"] in seen else "보물 더미(%d곳 중 진짜 하나)" % sum(
                1 for x in hidden if x.get("one_of") == hd["one_of"])
            seen.add(hd["one_of"])
        tags.append((p, name, (250, 215, 70)))
    hz = []
    for hd in ch.get("hazards", []):
        hz += [hd] * int(hd.get("count", 1))
    for p, hd in zip(marks.get("hazards", []), hz):
        dot(p, (250, 140, 40))
        tags.append((p, tiles.get(hd["tile"], {}).get("name_ko", hd["id"]), (250, 160, 70)))
    for f in ch.get("features", []):
        dot(f["at"], (250, 140, 40))
        tags.append((f["at"], "피의 우물(이벤트)", (250, 160, 70)))
    if last:
        if guardian_at:
            tags.append(([guardian_at[0], guardian_at[1] + 2], "→ 쓰러지면 탈출 포탈", (140, 210, 255)))
    elif "exit" in marks:
        dot(marks["exit"], (120, 200, 255))
        need = ch.get("exit_requires", {}).get("item")
        tags.append((marks["exit"], "출구" + ("(폭약 필요)" if need else ""), (140, 210, 255)))
    taken = []
    for p, text, col in tags:
        cx, cy = at(p)
        draw_tag(d, font, cx, cy, text, col, w, h, taken)
    posts = [e for e in ch.get("encounters", []) if e.get("kind") == "posts"]
    title = "%s %d · %s" % (rift["name_ko"], ch_index + 1, ch["name_ko"])
    extra = []
    if posts:
        extra.append("대기 무리 %d" % posts[0].get("count", 0))
    if ch.get("field_effects"):
        extra.append("필드: 저체온증")
    if ch.get("on_enter"):
        extra.append("들어설 때 피해(폭포·추락)")
    d.text((8, 4), title + ("   ·  " + " · ".join(extra) if extra else ""), font=big, fill=(240, 236, 228))
    return img


def main():
    args = {"out": "docs/plans/rift_boards/current", "cell": "12"}
    for a in sys.argv[1:]:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            args[k] = v
    out = os.path.join(ROOT, args["out"])
    os.makedirs(out, exist_ok=True)
    tiles = {t["id"]: t for t in load("data/tiles.json")}
    monsters, items = names("monsters"), names("items")
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "rifts", "rift_*.json"))):
        rift = load(f)
        boards = []
        for i, ch in enumerate(rift["chapters"]):
            img = board(rift, i, tiles, monsters, items, int(args["cell"]))
            img.save(os.path.join(out, "%s_%s.png" % (rift["id"], ch["id"])))
            boards.append(img)
        sw = max(b.width for b in boards)
        sheet = Image.new("RGB", (sw, sum(b.height + 8 for b in boards)), (40, 40, 44))
        y = 0
        for b in boards:
            sheet.paste(b, (0, y))
            y += b.height + 8
        sheet.save(os.path.join(out, "%s.png" % rift["id"]))
        print("%s: %d챕터" % (rift["id"], len(boards)))


if __name__ == "__main__":
    main()
