"""집 그림 가림 판(CT111): 구운 그림판(assets/town/houses/p<k>.webp + index.json)에서 집마다 불투명한 곳을 8 게임 px 칸으로 → mask.json.
게임(TownWorld.update_fade)은 몸이 필지 뒤에 있고 이 판이 몸을 덮을 때만 집을 흐리게 한다 — 그림 감싼 사각형만 보면 박공 지붕 옆 빈 곳에서도 흐려졌다.
  python3 tools/town_house_masks.py   (paint_town_houses.gd --pack 다음에)
"""
import base64
import json
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "assets", "town", "houses")
CELL = 8  # 게임 px


def main():
    idx = json.load(open(os.path.join(DIR, "index.json")))
    sc = idx.get("scale", 1.5)
    pages = {}
    out = {}
    for hid, e in idx["houses"].items():
        if e["page"] not in pages:
            pages[e["page"]] = Image.open(os.path.join(DIR, "p%d.webp" % e["page"])).convert("RGBA").getchannel("A")
        rx, ry, rw, rh = e["rect"]
        a = pages[e["page"]].crop((rx, ry, rx + rw, ry + rh))
        w = max(1, -(-round(rw / sc) // CELL))
        h = max(1, -(-round(rh / sc) // CELL))
        small = a.resize((w, h), Image.BOX)  # 칸 평균 불투명도
        bits = bytearray((w * h + 7) // 8)
        for i, v in enumerate(small.tobytes()):
            if v >= 128:
                bits[i >> 3] |= 1 << (i & 7)
        out[hid] = {"w": w, "h": h, "bits": base64.b64encode(bytes(bits)).decode()}
    json.dump({"_comment": "tools/town_house_masks.py가 만든다(손으로 고치지 않는다). 집 그림 불투명 판 — cell 게임 px 칸, 행 우선 비트(base64). 원점 = index.json off.",
               "cell": CELL, "houses": out}, open(os.path.join(DIR, "mask.json"), "w"), ensure_ascii=False, separators=(",", ":"))
    print("집 가림 판:", len(out), "채")


if __name__ == "__main__":
    main()
