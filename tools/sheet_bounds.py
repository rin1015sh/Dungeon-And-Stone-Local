"""서 있는 소품 시트의 칸마다 "그림이 있는 네모"를 재서 시트 옆 <시트 이름>.json에 적는다(AM64 — 렉 줄이기).
큰 나무 · 구조물 시트는 칸(8 × 18칸)의 대부분이 투명한데 게임이 칸 전체를 네모로 그려 화면을 여러 겹 덮었다.
게임(WallRow._draw_stand)은 이 파일이 있으면 그림이 있는 네모만 그린다. 시트 목록 = tiles.json의 art.stand(sheet · cols · rows).
  python3 tools/sheet_bounds.py        (소품 시트를 다시 그렸으면 돌린다 — tools/f2_art/props.py는 끝에 스스로 부른다)
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sheets():
    out = {}
    for t in json.load(open(os.path.join(ROOT, "data", "tiles.json"), encoding="utf-8")):
        st = t.get("art", {}).get("stand")
        if st:
            out[st["sheet"].replace("res://", "")] = (int(st.get("cols", 1)), int(st.get("rows", 1)))
    return out


def measure(path, cols, rows):
    a = np.asarray(Image.open(os.path.join(ROOT, path)).convert("RGBA"))[..., 3]
    ch, cw = a.shape[0] // rows, a.shape[1] // cols
    bounds = []
    for k in range(cols * rows):
        cell = a[(k // cols) * ch:(k // cols + 1) * ch, (k % cols) * cw:(k % cols + 1) * cw] > 2
        ys, xs = np.flatnonzero(cell.any(1)), np.flatnonzero(cell.any(0))
        if len(ys) == 0:
            bounds.append([0, 0, 0, 0])
            continue
        # 칸 비율(0~1) — 왼 · 위 · 오른 · 아래, 한 픽셀 여유
        bounds.append([round(max(0, xs[0] - 1) / cw, 4), round(max(0, ys[0] - 1) / ch, 4), round(min(cw, xs[-1] + 2) / cw, 4), round(min(ch, ys[-1] + 2) / ch, 4)])
    out = os.path.splitext(os.path.join(ROOT, path))[0] + ".json"
    json.dump({"_comment": "tools/sheet_bounds.py가 만든다 — 칸마다 그림이 있는 네모(칸 비율: 왼 · 위 · 오른 · 아래)", "cols": cols, "rows": rows, "bounds": bounds},
        open(out, "w", encoding="utf-8"), ensure_ascii=False)
    return out


def main():
    for path, (cols, rows) in sorted(sheets().items()):
        if os.path.exists(os.path.join(ROOT, path)):
            print("네모:", os.path.relpath(measure(path, cols, rows), ROOT))


if __name__ == "__main__":
    main()
