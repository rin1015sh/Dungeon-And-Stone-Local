"""옷차림 후보 비교 그림(사용자에게 보여 줄 한 장 — 게임은 쓰지 않는다).

옷차림마다 한 칸: 위 = 시안(전투 그림 크기 앞·옆·뒤, paint_look_preview --look → --views 폴더)
또는 전투 동작(대기·전투 자세·주먹·칼·활·주문·피격 + 쓰러짐, paint_motions --look → --combat 폴더),
아래 = 탐험 맵 걷기(앞 섬·앞 걸음·옆 걸음·옆 섬·뒤 섬 ×2.5 + 실제 크기, paint_actors --look).
배율은 모든 칸이 같다(종족 키 차이가 그대로 보인다).

  python3 tools/looks_sheet.py --map <폴더> (--views <폴더> | --combat <폴더>) --out <png> [--title 제목] e0_bow e1_blade …
제목·부제는 tools/monster_art/MapLooks.gd의 name·note를 읽는다.
"""
import argparse
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
BG = (44, 38, 34, 255)
PANEL = (58, 51, 46, 255)
INK = (232, 220, 200, 255)
SUB = (170, 158, 140, 255)
MOTION_ROWS = ["idle", "stance", "thrust", "swing", "heavy", "shoot", "spell", "damage", "wait"]
SHOW = [("idle", 0), ("stance", 1), ("thrust", 2), ("swing", 2), ("shoot", 1), ("spell", 1), ("damage", 1)]
COMBAT_K = 0.4  # 전투 그림 줄임
VIEW_K = 0.85  # 시안 그림 줄임
MAP_K = 2.5  # 맵 그림 키움(실제 크기 칸은 따로)
MAP_CELLS = [(2, 0), (0, 0), (0, 1), (2, 1), (2, 3)]  # (칸, 줄): 앞 섬 · 앞 걸음 · 옆 걸음 · 옆 섬 · 뒤 섬


def look_names():
    src = open(os.path.join(ROOT, "tools", "monster_art", "MapLooks.gd"), encoding="utf-8").read()
    out = {}
    for lid, name, note in re.findall(r'"([a-z]\d+_[a-z_]+)": \{"race": "[a-z]+", "name": "([^"]+)"(?:, "note": "([^"]+)")?', src):
        out[lid] = (name, note)
    return out


def views_frames(folder, lid):
    im = Image.open(os.path.join(folder, lid + "_views.png")).convert("RGBA")
    return [im.resize((int(im.width * VIEW_K), int(im.height * VIEW_K)), Image.LANCZOS)]


def trim(im):
    box = im.getbbox()
    return im.crop(box) if box else im


def combat_frames(folder, lid):
    sheet = Image.open(os.path.join(folder, lid + "_back_motions.png")).convert("RGBA")
    cw, ch = sheet.width // 3, sheet.height // len(MOTION_ROWS)
    out = []
    for name, col in SHOW:
        r = MOTION_ROWS.index(name)
        cell = sheet.crop((col * cw, r * ch, (col + 1) * cw, (r + 1) * ch))
        out.append(cell.resize((int(cw * COMBAT_K), int(ch * COMBAT_K)), Image.LANCZOS))
    dead = Image.open(os.path.join(folder, lid + "_back_dead.png")).convert("RGBA")
    out.append(dead.resize((int(dead.width * COMBAT_K), int(dead.height * COMBAT_K)), Image.LANCZOS))
    return out


def map_frames(folder, lid):
    sheet = Image.open(os.path.join(folder, lid + ".webp")).convert("RGBA")
    cw, ch = sheet.width // 5, sheet.height // 4
    big = []
    for c, r in MAP_CELLS:
        cell = sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
        big.append(cell.resize((int(cw * MAP_K), int(ch * MAP_K)), Image.NEAREST))
    real = sheet.crop((2 * cw, 0, 3 * cw, ch)).resize((cw // 2, ch // 2), Image.LANCZOS)  # 게임 화면 크기(art_scale 2)
    return big, real


def _hcrop(im, pad=12):
    box = im.getbbox()
    if not box:
        return im
    return im.crop((max(0, box[0] - pad), 0, min(im.width, box[2] + pad), im.height))


def panel(lid, title, note, mdir, cdir, vdir, font, small):
    comb = views_frames(vdir, lid) if vdir else combat_frames(cdir, lid)
    big, real = map_frames(mdir, lid)
    big = [_hcrop(im) for im in big]
    pad = 16
    top = pad + 52
    ch = max(im.height for im in comb)
    mh = big[0].height
    cw = sum(im.width for im in comb)
    mw = sum(im.width for im in big) + 90
    side = bool(vdir)  # 시안: 맵 줄을 시안 오른쪽에(한 줄로)
    if side:
        w = cw + 40 + mw + pad * 2
        h = top + max(ch, mh + 20) + pad
    else:
        w = max(cw, mw + 60) + pad * 2
        h = top + ch + 24 + mh + pad
    p = Image.new("RGBA", (w, h), PANEL)
    d = ImageDraw.Draw(p)
    d.text((pad, pad - 4), lid.split("_")[0] + "  " + title, font=font, fill=INK)
    if note:
        d.text((pad + 2, pad + 26), note, font=small, fill=SUB)
    base = top + max(ch, mh + 20) if side else top + ch
    x = pad
    for im in comb:  # 발 = 칸 아래 가운데
        p.alpha_composite(im, (x, base - im.height))
        x += im.width
    if side:
        x += 40
        d.line((x - 20, top, x - 20, base), fill=(84, 74, 66, 255), width=1)
        d.text((x, top - 2), "맵 ×2.5", font=small, fill=SUB)
        y = base - mh
    else:
        y = top + ch + 8
        d.line((pad, y, w - pad, y), fill=(84, 74, 66, 255), width=1)
        d.text((pad, y + 4), "맵 ×2.5", font=small, fill=SUB)
        x = pad + 60
        y += 16
    for im in big:
        p.alpha_composite(im, (x, y))
        x += im.width
    d.text((x + 16, y + mh - real.height - 34), "실제", font=small, fill=SUB)
    p.alpha_composite(real, (x + 20, y + mh - real.height - 10))
    return p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--combat", default="")
    ap.add_argument("--views", default="")
    ap.add_argument("--cols", type=int, default=1)
    ap.add_argument("--out", required=True)
    ap.add_argument("--title", default="")
    ap.add_argument("looks", nargs="+")
    a = ap.parse_args()
    names = look_names()
    font = ImageFont.truetype(FONT, 26)
    small = ImageFont.truetype(FONT, 16)
    panels = [panel(lid, *names.get(lid, (lid, "")), a.map, a.combat, a.views, font, small) for lid in a.looks]
    gap = 10
    top = 56 if a.title else gap
    pw = max(p.width for p in panels)
    ph = max(p.height for p in panels)
    rows = (len(panels) + a.cols - 1) // a.cols
    W = a.cols * (pw + gap) + gap
    H = top + rows * (ph + gap)
    sheet = Image.new("RGBA", (W, H), BG)
    if a.title:
        ImageDraw.Draw(sheet).text((gap + 6, 12), a.title, font=ImageFont.truetype(FONT, 30), fill=INK)
    for i, p in enumerate(panels):
        sheet.alpha_composite(p, (gap + (i % a.cols) * (pw + gap), top + (i // a.cols) * (ph + gap)))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    sheet.convert("RGB").save(a.out, optimize=True)
    print(a.out, sheet.size)


if __name__ == "__main__":
    main()
