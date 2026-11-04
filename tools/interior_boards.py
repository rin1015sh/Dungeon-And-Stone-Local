#!/usr/bin/env python3
"""도시 건물 실내 v2 기획 배치도 — docs/plans/interiors/boards.json → <id>.png · all.png + 검사.

검사: 줄 길이가 같다 · 문(D)에서 모든 활동 자리 앞 칸에 걸어서 닿는다 · 한 화면(30×16칸)에 들어간다 ·
문에서 가장 먼 활동 자리까지 걷는 시간(4.5칸/초). 기획용 도구 — 게임은 이 파일을 읽지 않는다.
"""
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/plans/interiors/boards.json"
OUT = SRC.parent
FONT = str(ROOT / "assets/fonts/NotoSansKR-Regular.otf")
CELL = 30
SCREEN = (30, 16)      # 1280×720 ÷ (32px × zoom 1.3333)
WALK = 4.5             # city.json town.walk_tiles_per_sec
COLORS = {
    "#": (58, 52, 50), ".": (196, 182, 156), "D": (120, 168, 205),
    "wall": (150, 112, 84), "block": (122, 96, 70), "low": (214, 200, 168),
    "npc": (226, 214, 190), "act": (206, 150, 70), "back": (150, 140, 120),
}
WALKABLE = {".", "D"}


def kind(room: dict, ch: str) -> str:
    if ch in ("#", ".", "D"):
        return ch
    return room["legend"][ch][1]


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
    walk = lambda x, y: rows[y][x] in WALKABLE or kind(room, rows[y][x]) == "low"
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
    far = 0
    for ch in room["acts"]:
        best = None
        for y in range(h):
            for x in range(w):
                if rows[y][x] == ch and y + 1 < h and (x, y + 1) in dist:
                    d = dist[(x, y + 1)]
                    best = d if best is None else min(best, d)
        if best is None:
            msgs.append(f"{rid}: 활동 자리 {ch!r} 앞에 닿지 못한다")
        else:
            far = max(far, best)
    floor = sum(1 for r in rows for c in r if c != "#")
    unreached = sum(1 for y in range(h) for x in range(w) if walk(x, y) and (x, y) not in dist)
    if unreached:
        msgs.append(f"{rid}: 닿지 않는 바닥 {unreached}칸")
    fits = w <= SCREEN[0] and h + 2 <= SCREEN[1]   # 북벽 앞면이 위로 약 2칸 솟는다
    print(f"{rid:8s} {w:2d}×{h:2d}칸 · 바닥 {floor:3d} · 한 화면 {'예' if fits else '아니오'} · "
          f"문 → 가장 먼 활동 {far}칸({far / WALK:.1f}초)")
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
                tc = (30, 24, 20) if k in ("npc", "act", "low", "D") else (240, 230, 210)
                d.text((x0 + CELL / 2, y0 + CELL / 2), ch, font=small, fill=tc, anchor="mm")
    lx = pad * 2 + w * CELL
    for i, (ch, name, k) in enumerate(leg):
        y0 = top + i * 20
        d.rectangle([lx, y0 + 2, lx + 14, y0 + 16], fill=COLORS[k])
        d.text((lx + 7, y0 + 9), ch, font=small, fill=(30, 24, 20), anchor="mm")
        mark = " ★" if ch in acts else ""
        d.text((lx + 22, y0 + 1), name + mark, font=small, fill=(225, 215, 195))
    return img


def main() -> None:
    data = json.loads(SRC.read_text(encoding="utf-8"))
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
