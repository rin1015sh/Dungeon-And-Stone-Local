#!/usr/bin/env python3
"""도시 건물 실내 배치도 — data/interiors/<id>.json(게임 지도 — CT106) → docs/plans/interiors/<id>.png · all.png + 검사.

검사: 줄 길이가 같다 · 문(D)에서 모든 활동 자리 앞 칸에 걸어서 닿는다 · 방(벽과 방 사이 문으로 나뉜 곳)마다
한 화면(30×16칸)에 들어간다 — 게임에서는 플레이어가 있는 방만 보인다 · 문에서 활동 자리마다 걷는 시간(4.5칸/초).
게임 그림은 tools/interior_bake.py — 이것은 칸 배치를 한눈에 보는 그림.
"""
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data/interiors"
OUT = ROOT / "docs/plans/interiors"
FONT = str(ROOT / "assets/fonts/NotoSansKR-Regular.otf")
CELL = 30
SCREEN = (30, 16)      # 1280×720 ÷ (32px × zoom 1.3333)
WALK = 4.5             # city.json town.walk_tiles_per_sec
COLORS = {
    "#": (58, 52, 50), ".": (196, 182, 156), "D": (120, 168, 205),
    "wall": (150, 112, 84), "block": (122, 96, 70), "low": (214, 200, 168),
    "npc": (226, 214, 190), "act": (206, 150, 70), "back": (150, 140, 120), "door": (150, 200, 160), "wallact": (206, 150, 70),
}
WALKABLE = {".", "D"}


def kind(room: dict, ch: str) -> str:
    if ch in ("#", ".", "D"):
        return ch
    return room["legend"][ch][1]


def rooms_of(room: dict) -> list[list[tuple[int, int]]]:
    """벽 · 벽 장식 · 문으로 나뉜 칸 덩어리 = 방."""
    rows = room["rows"]
    w, h = len(rows[0]), len(rows)
    inside = lambda x, y: rows[y][x] not in ("#", "D") and kind(room, rows[y][x]) not in ("wall", "door", "wallact")
    seen, out = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or not inside(x, y):
                continue
            cells, q = [], deque([(x, y)])
            seen.add((x, y))
            while q:
                cx, cy = q.popleft()
                cells.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and inside(nx, ny):
                        seen.add((nx, ny))
                        q.append((nx, ny))
            out.append(cells)
    return out


def check(rid: str, room: dict) -> list[str]:
    rows = room["rows"]
    w, h = len(rows[0]), len(rows)
    msgs = []
    for i, r in enumerate(rows):
        if len(r) != w:
            msgs.append(f"{rid}: {i}줄 길이 {len(r)} ≠ {w}")
    for ch in {c for r in rows for c in r}:
        if ch not in ("#", ".", "D") and ch not in room["legend"]:
            msgs.append(f"{rid}: 범례에 없는 글자 {ch!r}")
    if msgs:
        return msgs
    walk = lambda x, y: rows[y][x] in WALKABLE or kind(room, rows[y][x]) in ("low", "door")
    start = [(x, h - 1) for x in range(w) if rows[h - 1][x] == "D"]
    dist = {p: 0 for p in start}
    q = deque(start)
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in dist and walk(nx, ny):
                dist[(nx, ny)] = dist[(x, y)] + 1
                q.append((nx, ny))
    times = []
    for ch, acts in room["acts"].items():
        best = None
        for y in range(h):
            for x in range(w):
                if rows[y][x] == ch and y + 1 < h and (x, y + 1) in dist:
                    d = dist[(x, y + 1)]
                    best = d if best is None else min(best, d)
        if best is None:
            msgs.append(f"{rid}: 활동 자리 {ch!r} 앞에 닿지 못한다")
        else:
            times.append(f"{room['legend'][ch][0]} {best / WALK:.1f}초")
    floor = sum(1 for r in rows for c in r if c != "#")
    unreached = sum(1 for y in range(h) for x in range(w) if walk(x, y) and (x, y) not in dist)
    if unreached:
        msgs.append(f"{rid}: 닿지 않는 바닥 {unreached}칸")
    names = {}
    for x, y, name in room.get("room_names", []):
        names[(x, y)] = name
    print(f"{rid:8s} 전체 {w}×{h}칸 · 바닥 {floor}")
    for cells in rooms_of(room):
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]
        rw, rh = max(xs) - min(xs) + 3, max(ys) - min(ys) + 3   # 둘레 벽 포함
        name = next((names[c] for c in cells if c in names), "?")
        if name == "?":
            msgs.append(f"{rid}: 이름 없는 방({min(xs)}, {min(ys)})")
        fits = rw <= SCREEN[0] and rh + 2 <= SCREEN[1]   # 북벽 앞면이 위로 약 2칸 솟는다
        if not fits:
            msgs.append(f"{rid}: 방 '{name}' {rw}×{rh}칸이 한 화면을 넘는다")
        print(f"    방 {name:8s} {rw:2d}×{rh:2d}칸 · 바닥 {len(cells):3d}")
    print("    문 → " + " · ".join(times))
    return msgs


def draw(rid: str, room: dict) -> Image.Image:
    rows = room["rows"]
    w, h = len(rows[0]), len(rows)
    font = ImageFont.truetype(FONT, 15)
    small = ImageFont.truetype(FONT, 13)
    acts = room["acts"]
    leg = [(ch, v[0], v[1]) for ch, v in room["legend"].items()]
    pad, top = 12, 34
    lw = 300
    img = Image.new("RGB", (pad * 3 + w * CELL + lw, top + max(h * CELL, len(leg) * 20 + 10) + pad), (28, 26, 30))
    d = ImageDraw.Draw(img)
    d.text((pad, 8), room["name_ko"] + f"  ({w}×{h}칸)", font=font, fill=(235, 225, 205))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            k = kind(room, ch)
            x0, y0 = pad + x * CELL, top + y * CELL
            d.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=COLORS[k], outline=(40, 36, 34))
            if ch not in ("#", "."):
                tc = (30, 24, 20) if k in ("npc", "act", "wallact", "low", "door", "D") else (240, 230, 210)
                d.text((x0 + CELL / 2, y0 + CELL / 2), ch, font=small, fill=tc, anchor="mm")
    for x, y, name in room.get("room_names", []):
        if len(room.get("room_names", [])) > 1:
            d.text((pad + x * CELL + CELL / 2, top + y * CELL + CELL / 2), name, font=font,
                   fill=(250, 245, 235), anchor="mm", stroke_width=3, stroke_fill=(40, 30, 25))
    lx = pad * 2 + w * CELL
    for i, (ch, name, k) in enumerate(leg):
        y0 = top + i * 20
        d.rectangle([lx, y0 + 2, lx + 14, y0 + 16], fill=COLORS[k])
        d.text((lx + 7, y0 + 9), ch, font=small, fill=(30, 24, 20), anchor="mm")
        mark = " ★" if ch in acts else ""
        d.text((lx + 22, y0 + 1), name + mark, font=small, fill=(225, 215, 195))
    return img


KIND = {"furniture": "block", "wallart": "wall", "low": "low", "door": "door", "back": "back", "npc": "npc"}


def load_room(path: Path) -> dict:
    """게임 지도 → 배치도 꼴(legend [이름, 종류] · acts {글자: 활동} · room_names)."""
    d = json.loads(path.read_text(encoding="utf-8"))
    rows = d["rows"]
    acts = {}
    for sp in d.get("spots", []):
        ch = sp.get("char") or rows[sp["at"][1]][sp["at"][0]]
        acts.setdefault(ch, []).extend(sp["activities"])
    legend = {}
    for ch, e in d.get("legend", {}).items():
        k = KIND.get(e.get("kind"), "block")
        if ch in acts:
            k = "wallact" if k == "wall" else ("act" if k in ("block", "npc") else k)
        legend[ch] = [e.get("name_ko", ch), k]
    return {"name_ko": d.get("name_ko", d["id"]), "rows": rows, "legend": legend, "acts": acts,
            "room_names": [[r["at"][0], r["at"][1], r["name_ko"]] for r in d.get("rooms", [])]}


def main() -> None:
    rooms = {p.stem: load_room(p) for p in sorted(SRC.glob("*.json")) if not p.name.startswith("_")}
    data = {"rooms": rooms}
    errors, imgs = [], []
    for rid, room in data["rooms"].items():
        errors += check(rid, room)
        if not errors:
            img = draw(rid, room)
            img.save(OUT / f"{rid}.png")
            imgs.append(img)
    for e in errors:
        print("문제:", e)
    if imgs:
        cols = 2
        cw = max(i.width for i in imgs)
        rh = [max(i.height for i in imgs[r:r + cols]) for r in range(0, len(imgs), cols)]
        sheet = Image.new("RGB", (cw * cols, sum(rh)), (28, 26, 30))
        yy = 0
        for r in range(0, len(imgs), cols):
            for c, im in enumerate(imgs[r:r + cols]):
                sheet.paste(im, (c * cw, yy))
            yy += rh[r // cols]
        sheet.save(OUT / "all.png")
    print("모두 통과" if not errors else f"문제 {len(errors)}개")


if __name__ == "__main__":
    main()
