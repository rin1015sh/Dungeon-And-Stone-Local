"""동네 전체 그림 한 장(CT103): 구운 바닥 조각 + 집 그림판 + 소품 그림을 게임과 같은 자리 · 같은 앞뒤 순서(발 y)로 겹친다.
  godot --headless --path . --script res://tools/town_dump.gd   (집 앞 y · 땅 높이 · 소품 발 → user://town_dump.json)
  python3 tools/town_overview.py                                  (→ docs/plans/town/v4/town_full.jpg · town_full_north.jpg · town_full_south.jpg)
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from town_hand_bake import user_dir  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "plans", "town", "v4")


def main():
    dump = json.load(open(os.path.join(user_dir(), "town_dump.json")))
    g = json.load(open(os.path.join(ROOT, "assets/town/ground/index.json")))
    idx = json.load(open(os.path.join(ROOT, "assets/town/houses/index.json")))
    sc = idx.get("scale", 1.5)
    top = 400
    W = dump["w"] * 32
    H = max(c["rect"][1] + c["rect"][3] for c in g["chunks"]) + top
    im = Image.new("RGBA", (W, H), (14, 12, 10, 255))
    for c in g["chunks"]:
        x, y, _w, _h = c["rect"]
        im.alpha_composite(Image.open(os.path.join(ROOT, "assets/town/ground", c["file"] + ".webp")).convert("RGBA"), (x, y + top))
    items = [(h["front_y"] * 32, "h", h) for h in dump["houses"] if h["id"] in idx["houses"]] + [(p["y"], "p", p) for p in dump["props"]]
    items.sort(key=lambda t: t[0])
    pages, arts = {}, {}
    for _y, k, a in items:
        if k == "h":
            e = idx["houses"][a["id"]]
            if e["page"] not in pages:
                pages[e["page"]] = Image.open(os.path.join(ROOT, "assets/town/houses/p%d.webp" % e["page"])).convert("RGBA")
            rx, ry, rw, rh = e["rect"]
            spr = pages[e["page"]].crop((rx, ry, rx + rw, ry + rh)).resize((max(1, round(rw / sc)), max(1, round(rh / sc))), Image.LANCZOS)
            im.paste(spr, (round(e["off"][0]), round(a["front_y"] * 32 + e["off"][1] - a["elev"] * 32) + top), spr)
        else:
            if a["kind"] not in arts:
                f = os.path.join(ROOT, "assets/town/props", a["kind"] + ".webp")
                arts[a["kind"]] = Image.open(f).convert("RGBA") if os.path.exists(f) else None
            art = arts[a["kind"]]
            if art is None:
                continue
            spr = art.resize((max(1, round(art.width / 1.5)), max(1, round(art.height / 1.5))), Image.LANCZOS)
            im.paste(spr, (round(a["x"] - spr.width / 2), round(a["y"] - a["lift"] - spr.height) + top), spr)
    bbox = im.convert("L").point(lambda v: 255 if v > 20 else 0).getbbox()
    im = im.crop((0, max(0, bbox[1] - 10), W, H)).convert("RGB")
    os.makedirs(OUT, exist_ok=True)
    im.resize((im.width * 2 // 5, im.height * 2 // 5), Image.LANCZOS).save(os.path.join(OUT, "town_full.jpg"), quality=86)
    half = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
    half.crop((0, 0, half.width, half.height // 2)).save(os.path.join(OUT, "town_full_north.jpg"), quality=86)
    half.crop((0, half.height // 2, half.width, half.height)).save(os.path.join(OUT, "town_full_south.jpg"), quality=86)
    print("동네 전체 그림:", im.size)


if __name__ == "__main__":
    main()
