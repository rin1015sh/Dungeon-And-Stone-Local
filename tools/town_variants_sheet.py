"""집 바리에이션 모아 보기 — tools/town_variants.gd가 그린 docs/plans/town/variants/v*.png를 4줄로(이름은 tools/town_kit/Designs.gd LIST).
  python3 tools/town_variants_sheet.py
"""
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "docs", "plans", "town", "variants")
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
CELL = 400
COLS = 4


def names():
    src = open(os.path.join(ROOT, "tools", "town_kit", "Designs.gd"), encoding="utf-8").read()
    return re.findall(r'\["(v\d+)", "([^"]+)", "_\w+"\]', src)


def main():
    items = [(i, n) for i, n in names() if os.path.exists(os.path.join(DIR, i + ".png"))]
    rows = (len(items) + COLS - 1) // COLS
    sheet = Image.new("RGB", (CELL * COLS, (CELL + 34) * rows), (24, 22, 20))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(FONT, 17)
    for k, (i, n) in enumerate(items):
        x = (k % COLS) * CELL
        y = (k // COLS) * (CELL + 34)
        im = Image.open(os.path.join(DIR, i + ".png")).convert("RGB").resize((CELL, CELL), Image.LANCZOS)
        sheet.paste(im, (x, y + 34))
        d.text((x + 10, y + 8), "%s  %s" % (i, n), font=f, fill=(226, 216, 196))
    sheet.save(os.path.join(DIR, "sheet.png"))
    print("저장:", os.path.join(DIR, "sheet.png"))


if __name__ == "__main__":
    main()
