#!/usr/bin/env python3
"""망자의 땅 줄이기(사용자 2026-11-08 "망자의 땅만 너무 크다 — 줄여"): 길 그래프의 구간(node) 자리 · 반지름과 지도 크기를 줄인다.
구간에 붙은 것(건물 · 도장 · 랜드마크 · 매복 · 요소 — node 기준 상대 좌표)은 그대로 따라온다. 한 번 돌리는 스크립트(원본 = git 기록).
  python3 tools/f2d_shrink.py [--ky=0.68 --kx=0.82 --kr=0.8]   (kx 0.8 아래 · kr 0.75 아래는 예배당 도장이 길을 막아 끊긴다)
[창작] 임시값."""
import json, math, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "data/floors/f2_land_of_dead.json")
args = {"ky": 0.68, "kx": 0.82, "kr": 0.8, "kp": 0.6}
for a in sys.argv[1:]:
    k, v = a.lstrip("-").split("=")
    args[k] = float(v)

d = json.load(open(PATH))
g = d["gen"]
W, H = g["size"]
cx = W / 2.0
top = min(n["at"][1] for n in g["nodes"])
for n in g["nodes"]:
    x, y = n["at"]
    n["at"] = [round(cx + (x - cx) * args["kx"]), round(top + (y - top) * args["ky"])]
    n["r"] = max(5, round(n["r"] * args["kr"]))
for e in g["edges"]:
    if "wiggle" in e:
        e["wiggle"] = round(e["wiggle"] * 0.75)
for key in ("props", "ruins"):  # 넓이가 줄어든 만큼 흩뿌리는 수도
    for p in g.get(key, []):
        if "count" in p:
            p["count"] = max(1, round(p["count"] * args["kp"]))
bottom = max(n["at"][1] + n["r"] for n in g["nodes"])
left = min(n["at"][0] - n["r"] for n in g["nodes"]) - 30  # 곁 건물 · 랜드마크가 구간 밖으로 나가는 만큼 둔다
right = max(n["at"][0] + n["r"] for n in g["nodes"]) + 30
shift = max(0, left)
for n in g["nodes"]:
    n["at"][0] -= shift
crypt_w = max((len(c["rows"][0]) for c in g.get("crypts", [])), default=0)
new_w = max(right - shift, crypt_w + 10)
new_h = int(math.ceil(bottom + 14))
for c in g.get("crypts", []):  # 지하 묘실(따로 떨어진 어둠 — 계단으로만): 오른쪽 아래 구석으로
    rows = len(c["rows"])
    c["at"] = [new_w - len(c["rows"][0]) - 4, new_h - rows - 3]
g["size"] = [new_w, new_h]
json.dump(d, open(PATH, "w"), ensure_ascii=False, indent=2)
open(PATH, "a").write("\n")
print("지도 %d×%d → %d×%d" % (W, H, new_w, new_h))
