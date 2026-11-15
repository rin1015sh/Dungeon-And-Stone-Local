"""동네 집 리터칭 비교 그림(AM70): 같은 날 그림을 리터칭 없이 / 리터칭해서 손그림 마감한 두 장을 같은 크기 · 같은 바닥색 위에 나란히.
  python3 tools/town_retouch_compare.py [h70 h71 …] [--layers] [--out=<폴더>] [--crop]
  → <폴더>/<id>.jpg(왼쪽 원본 · 오른쪽 리터칭) + sheet.jpg(모두 모아 — 줄인 판). 기본 폴더 docs/screens/town_retouch/.
  --layers = 리터칭 자료(해 그림자 · 틈 그늘 · 모서리 · 재질 번호)도 한 줄 더. --crop = 아래쪽 반(벽 · 문 · 창) 확대 판도.
user://town_hand/의 자료 그림이 있어야 한다(tools/paint_town_hand.gd).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_handdrawn as th  # noqa: E402
import town_retouch as tr  # noqa: E402
from town_hand_bake import user_dir, ROOT  # noqa: E402

GROUND = np.array([62, 58, 52]) / 255.0  # 동네 돌길 언저리(어두운 바닥 — CT101)
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
NAMES = {"temple": "신전", "library": "도서관", "guild": "길드", "inn": "여관", "bank": "은행", "shop": "잡화점", "smithy": "대장간"}
MAX_W = 1800
PAL = np.array([[90, 90, 90], [220, 210, 170], [140, 140, 140], [150, 70, 50], [120, 80, 40], [60, 140, 170], [110, 60, 45], [70, 190, 180], [200, 60, 60]]) / 255.0


def load(hid):
    src = os.path.join(user_dir(), "town_hand")
    raw = np.asarray(Image.open(os.path.join(src, hid + "_raw.png")).convert("RGB")).astype(float) / 255.0
    ids = np.asarray(Image.open(os.path.join(src, hid + "_id.png")).convert("RGB")).astype(np.int64)
    code = ids[..., 0] * 65536 + ids[..., 1] * 256 + ids[..., 2]
    meta = json.load(open(os.path.join(src, hid + ".json"), encoding="utf-8"))
    mat = np.rint(np.asarray(Image.open(os.path.join(src, hid + "_mat.png")).convert("RGB"))[..., 0] / 30.0).astype(np.int64)
    geo = np.asarray(Image.open(os.path.join(src, hid + "_geo.png")).convert("RGB"))
    nrm = np.asarray(Image.open(os.path.join(src, hid + "_nrm.png")).convert("RGB"))
    return raw, code, mat, geo, nrm, meta


def on_ground(img, alpha):
    return img * alpha[..., None] + GROUND * (1 - alpha[..., None])


def compare(hid, out, layers=False, crop=False):
    raw, code, mat, geo, nrm, meta = load(hid)
    a, aa = th.finish(raw, code, sprite=True, fine=True)
    lay = {}
    rt = tr.retouch(raw, code, mat, geo, nrm, meta, hid, layers=lay)
    b, ba = th.finish(rt, code, sprite=True, fine=True)
    tiles = [on_ground(a, aa), on_ground(b, ba)]
    if layers:
        mask = (code != 0)[..., None]
        tiles.append(np.where(mask, 1 - np.dstack([lay["shadow"]] * 3) * 0.8, GROUND))
        tiles.append(np.where(mask, 1 - np.dstack([lay["ao"]] * 3), GROUND))
        tiles.append(np.where(mask, PAL[np.clip(lay["mat"], 0, 8)], GROUND))
    H, W = tiles[0].shape[:2]
    if crop:  # 아래쪽(벽 · 문 · 창)을 원래 크기로
        y0 = H // 2
        tiles = [t[y0:] for t in tiles[:2]]
        H = H - y0
    pad, top = 16, 46
    sheet = Image.new("RGB", (W * len(tiles) + pad * (len(tiles) + 1), H + top + pad), tuple((GROUND * 255).astype(int)))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(FONT, 26)
    label = NAMES.get(meta.get("fac", ""), meta.get("zone", "") or "집")
    heads = ["원본", "리터칭", "해 그림자", "틈 그늘", "재질 번호"]
    for k, t in enumerate(tiles):
        x = pad + k * (W + pad)
        sheet.paste(Image.fromarray((np.clip(t, 0, 1) * 255).astype(np.uint8)), (x, top))
        d.text((x + 4, 8), "%s %s — %s" % (hid, label, heads[k]), font=f, fill=(225, 215, 190))
    path = os.path.join(out, hid + ("_crop" if crop else "") + ".jpg")
    if sheet.width > MAX_W:  # 커밋용 크기(원래 크기 비교는 --crop)
        sheet = sheet.resize((MAX_W, int(sheet.height * MAX_W / sheet.width)), Image.LANCZOS)
    sheet.save(path, quality=86)
    return path


def main():
    out = os.path.join(ROOT, "docs", "screens", "town_retouch")
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = a[len("--out="):]
    os.makedirs(out, exist_ok=True)
    ids = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not ids:
        ids = sorted(f[:-len("_geo.png")] for f in os.listdir(os.path.join(user_dir(), "town_hand")) if f.endswith("_geo.png"))
    paths = []
    for hid in ids:
        paths.append(compare(hid, out, "--layers" in sys.argv))
        if "--crop" in sys.argv:
            compare(hid, out, crop=True)
        print("비교:", paths[-1])
    if len(paths) > 1:  # 모아 보기(줄인 판)
        ims = [Image.open(p) for p in paths]
        w = 1400
        rows = [im.resize((w, int(im.height * w / im.width))) for im in ims]
        sheet = Image.new("RGB", (w, sum(r.height for r in rows)), tuple((GROUND * 255).astype(int)))
        y = 0
        for r in rows:
            sheet.paste(r, (0, y))
            y += r.height
        sheet.save(os.path.join(out, "sheet.jpg"), quality=84)
        print("모아 보기:", os.path.join(out, "sheet.jpg"))


if __name__ == "__main__":
    main()
