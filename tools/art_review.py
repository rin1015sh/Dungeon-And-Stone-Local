"""종족 그림 확인 시트(사용자가 게임 그림에 이상이 없는지 한눈에 보게 — 게임은 쓰지 않는다).

종족마다 한 장: 탐험 맵 걷기 시트 전체(줄 = 앞·왼쪽·오른쪽·뒤, 칸 = 걸음 A·반걸음·섬·반걸음·걸음 B, ×2) +
게임 크기(실제) + 전투 뒷모습 + 전투 동작 시트 전체(줄 = render.json ui.combat_party_motion.rows, 칸 3) + 쓰러짐.

  python3 tools/art_review.py --out <폴더> elf dwarf beastkin  → <폴더>/review_<종족>.png
  --motion=<동작>: 여러 종족의 그 동작 줄(칸 3)만 한 장에 → <폴더>/motion_<동작>.png
  --walk=<줄,…>(앞|왼쪽|오른쪽|뒤): 여러 종족의 걷기 시트 그 줄(칸 5, ×3)만 한 장에 → <폴더>/walk_<줄>.png
"""
import argparse
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
BG = (44, 38, 34, 255)
CELL_BG = (58, 51, 46, 255)
INK = (232, 220, 200, 255)
SUB = (170, 158, 140, 255)
WALK_ROWS = ["앞", "왼쪽", "오른쪽", "뒤"]
WALK_COLS = ["걸음 A", "반걸음", "섬", "반걸음", "걸음 B"]
MOTION_NAMES = {"idle": "대기", "stance": "전투 자세", "thrust": "주먹", "swing": "칼", "heavy": "대검", "shoot": "활",
                "spell": "주문", "damage": "피격", "wait": "회피"}
MOTION_K = 0.42  # 전투 동작 칸 줄임


def _races():
    data = json.load(open(os.path.join(ROOT, "data", "races.json"), encoding="utf-8"))
    return {r["id"]: r for r in data}


def _rows():
    render = json.load(open(os.path.join(ROOT, "data", "render.json"), encoding="utf-8"))
    return render["ui"]["combat_party_motion"]["rows"]


def _load(path):
    return Image.open(os.path.join(ROOT, path)).convert("RGBA")


def review(race, out_dir, font, small, title_font):
    info = _races().get(race, {})
    walk = _load("assets/actors/%s.webp" % race)
    back = _load("assets/party/%s_back.webp" % race)
    motions = _load("assets/party/%s_back_motions.webp" % race)
    dead = _load("assets/party/%s_back_dead.webp" % race)
    rows = _rows()
    pad = 24
    # 걷기 시트(×2, 칸마다 바탕을 깔아 칸 경계가 보이게)
    cw, ch = walk.width // 5, walk.height // 4
    wk = 2
    walk_w = 70 + cw * wk * 5
    walk_h = 28 + ch * wk * 4
    # 전투 동작
    mw, mh = motions.width // 3, motions.height // len(rows)
    tw, th = int(mw * MOTION_K), int(mh * MOTION_K)
    mot_w = 90 + tw * 3
    mot_h = 28 + th * len(rows)
    back_s = back.resize((int(back.width * MOTION_K), int(back.height * MOTION_K)), Image.LANCZOS)
    dead_s = dead.resize((int(dead.width * MOTION_K), int(dead.height * MOTION_K)), Image.LANCZOS)
    W = pad * 3 + max(walk_w, back_s.width + dead_s.width + 200) + mot_w
    H = pad + 50 + max(walk_h + 40 + max(back_s.height, dead_s.height) + 60, mot_h) + pad
    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((pad, pad - 6), "%s(%s) — 게임 그림 확인" % (info.get("name_ko", race), race), font=title_font, fill=INK)
    top = pad + 50
    # 걷기
    d.text((pad, top), "탐험 맵 걷기 시트 ×2", font=font, fill=INK)
    for c, name in enumerate(WALK_COLS):
        d.text((pad + 70 + c * cw * wk + 6, top + 26), name, font=small, fill=SUB)
    y0 = top + 50
    for r, name in enumerate(WALK_ROWS):
        d.text((pad, y0 + r * ch * wk + ch * wk // 2 - 10), name, font=small, fill=SUB)
        for c in range(5):
            x = pad + 70 + c * cw * wk
            y = y0 + r * ch * wk
            d.rectangle((x + 2, y + 2, x + cw * wk - 2, y + ch * wk - 2), fill=CELL_BG)
            cell = walk.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).resize((cw * wk, ch * wk), Image.NEAREST)
            img.alpha_composite(cell, (x, y))
    # 게임 크기(실제 — art_scale 2라 시트의 반)
    gy = y0 + ch * wk * 4 + 20
    d.text((pad, gy), "게임 크기", font=small, fill=SUB)
    for c in range(4):
        real = walk.crop((2 * cw, c * ch, 3 * cw, (c + 1) * ch)).resize((cw // 2, ch // 2), Image.LANCZOS)
        img.alpha_composite(real, (pad + 90 + c * (cw // 2 + 8), gy))
    # 전투 뒷모습 · 쓰러짐
    by = gy + ch // 2 + 30
    d.text((pad, by), "전투 뒷모습", font=small, fill=SUB)
    img.alpha_composite(back_s, (pad, by + 24))
    d.text((pad + back_s.width + 40, by), "쓰러짐", font=small, fill=SUB)
    img.alpha_composite(dead_s, (pad + back_s.width + 40, by + 24 + back_s.height - dead_s.height))
    # 전투 동작
    mx = pad * 2 + max(walk_w, back_s.width + dead_s.width + 200)
    d.text((mx, top), "전투 동작 시트(칸 1·2·3)", font=font, fill=INK)
    for r, name in enumerate(rows):
        y = top + 34 + r * th
        d.text((mx, y + th // 2 - 10), MOTION_NAMES.get(name, name), font=small, fill=SUB)
        for c in range(3):
            x = mx + 90 + c * tw
            d.rectangle((x + 2, y + 2, x + tw - 2, y + th - 2), fill=CELL_BG)
            cell = motions.crop((c * mw, r * mh, (c + 1) * mw, (r + 1) * mh)).resize((tw, th), Image.LANCZOS)
            img.alpha_composite(cell, (x, y))
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, "review_%s.png" % race)
    img.convert("RGB").save(path, optimize=True)
    print(path, img.size)


def _sheet(title, lines, out_path, font, title_font):
    """lines = [(이름, [그림 …])] → 이름표 + 그림 줄들(칸마다 바탕)."""
    pad = 24
    label_w = 150
    cw = max(im.width for _, ims in lines for im in ims)
    lh = [max(im.height for im in ims) for _, ims in lines]
    W = pad * 2 + label_w + cw * max(len(ims) for _, ims in lines)
    H = pad + 56 + sum(h + 8 for h in lh) + pad
    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((pad, pad - 6), title, font=title_font, fill=INK)
    y = pad + 56
    for (name, ims), h in zip(lines, lh):
        d.text((pad, y + h // 2 - 12), name, font=font, fill=SUB)
        for i, im in enumerate(ims):
            x = pad + label_w + i * cw
            d.rectangle((x + 2, y, x + cw - 2, y + h), fill=CELL_BG)
            img.alpha_composite(im, (x + (cw - im.width) // 2, y + h - im.height))
        y += h + 8
    img.convert("RGB").save(out_path, optimize=True)
    print(out_path, img.size)


def motion_sheet(races, motion, out_dir, font, title_font):
    rows = _rows()
    lines = []
    for race in races:
        sheet = _load("assets/party/%s_back_motions.webp" % race)
        mw, mh = sheet.width // 3, sheet.height // len(rows)
        r = rows.index(motion)
        ims = [sheet.crop((c * mw, r * mh, (c + 1) * mw, (r + 1) * mh)) for c in range(3)]
        lines.append((_races().get(race, {}).get("name_ko", race), [im.resize((int(im.width * 0.5), int(im.height * 0.5)), Image.LANCZOS) for im in ims]))
    _sheet("전투 동작 — %s(칸 1·2·3, 같은 배율)" % MOTION_NAMES.get(motion, motion), lines, os.path.join(out_dir, "motion_%s.png" % motion), font, title_font)


def walk_sheet(races, walk_rows, out_dir, font, title_font):
    lines = []
    for race in races:
        sheet = _load("assets/actors/%s.webp" % race)
        cw, ch = sheet.width // 5, sheet.height // 4
        for name in walk_rows:
            r = WALK_ROWS.index(name)
            ims = [sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).resize((cw * 3, ch * 3), Image.NEAREST) for c in range(5)]
            lines.append(("%s %s" % (_races().get(race, {}).get("name_ko", race), name), ims))
    _sheet("탐험 맵 걷기 — %s(걸음 A·반걸음·섬·반걸음·걸음 B, ×3)" % "·".join(walk_rows), lines, os.path.join(out_dir, "walk_%s.png" % "_".join(walk_rows)), font, title_font)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--motion", default="")
    ap.add_argument("--walk", default="")
    ap.add_argument("races", nargs="+")
    a = ap.parse_args()
    font = ImageFont.truetype(FONT, 22)
    small = ImageFont.truetype(FONT, 16)
    title = ImageFont.truetype(FONT, 30)
    os.makedirs(a.out, exist_ok=True)
    if a.motion:
        motion_sheet(a.races, a.motion, a.out, font, title)
    if a.walk:
        walk_sheet(a.races, a.walk.split(","), a.out, font, title)
    if not a.motion and not a.walk:
        for r in a.races:
            review(r, a.out, font, small, title)


if __name__ == "__main__":
    main()
