"""동네 집 그림 방식 비교판 — tools/town_styles.gd가 그린 docs/plans/town/styles/<방식>_<집>.png를 한 장에.
  python3 tools/town_styles_sheet.py
E(픽셀아트)는 여기서 C(등각)를 1/3로 줄이고 색 40개로 줄인 뒤 다시 키워 만든다.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "docs", "plans", "town", "styles")
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
ROWS = [("A", "A 정면 쿼터뷰 (게임 시점, 기울이지 않음)"), ("B", "B 비스듬히 (앞면 + 오른쪽 옆면)"), ("C", "C 등각 (아이소메트릭)"),
        ("D", "D 3D로 지어 빛·그림자 렌더"), ("E", "E 픽셀아트 (C를 1/3로)")]
COLS = [("b1", "반목조 3층"), ("b2", "돌집 모임지붕"), ("b3", "좁은 회벽 박공"), ("b4", "여관"), ("b5", "고딕 신전")]
CELL = 300
BG = (34, 31, 28)


def pixelate(im):
    im = im.convert("RGBA")
    small = im.resize((max(1, im.width // 3), max(1, im.height // 3)), Image.BOX)
    alpha = small.getchannel("A").point(lambda a: 255 if a > 110 else 0)
    rgb = Image.new("RGB", small.size, BG)
    rgb.paste(small, mask=small.getchannel("A"))
    q = rgb.quantize(colors=40, method=Image.Quantize.MEDIANCUT).convert("RGB")
    out = Image.new("RGBA", small.size)
    out.paste(q, mask=alpha)
    return out.resize((small.width * 3, small.height * 3), Image.NEAREST)


def main():
    for b, _ in COLS:
        src = os.path.join(DIR, "C_%s.png" % b)
        if os.path.exists(src):
            pixelate(Image.open(src)).save(os.path.join(DIR, "E_%s.png" % b))
    f_big = ImageFont.truetype(FONT, 18)
    f = ImageFont.truetype(FONT, 14)
    left = 200
    sheet = Image.new("RGB", (left + CELL * len(COLS), 40 + CELL * len(ROWS)), BG)
    d = ImageDraw.Draw(sheet)
    for j, (b, name) in enumerate(COLS):
        d.text((left + j * CELL + CELL // 2, 20), name, font=f_big, fill=(224, 214, 194), anchor="mm")
    for i, (m, name) in enumerate(ROWS):
        y0 = 40 + i * CELL
        words = name.split(" (")
        d.text((12, y0 + CELL // 2 - 12), words[0], font=f_big, fill=(224, 214, 194))
        if len(words) > 1:
            d.text((12, y0 + CELL // 2 + 14), "(" + words[1], font=f, fill=(170, 160, 145))
        for j, (b, _) in enumerate(COLS):
            p = os.path.join(DIR, "%s_%s.png" % (m, b))
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGBA")
            k = min((CELL - 16) / im.width, (CELL - 16) / im.height)
            im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.NEAREST if m == "E" else Image.LANCZOS)
            x = left + j * CELL + (CELL - im.width) // 2
            y = y0 + (CELL - im.height) // 2
            sheet.paste(im, (x, y), im)
    sheet.save(os.path.join(DIR, "sheet.png"))
    print("저장:", os.path.join(DIR, "sheet.png"))


if __name__ == "__main__":
    main()
