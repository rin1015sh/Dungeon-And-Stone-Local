"""동네 바닥을 한 장으로 굽는다(사용자 2026-11-03 "바닥 타일 전체적으로 교체 · 지금처럼 단순 격자 말고", CT99).
  godot --headless --path . --script res://tools/town_cells.gd   (칸 정보 → user://town_cells.json)
  python3 tools/town_ground_bake.py                               (→ assets/town/ground/g<cx>_<cy>.webp + index.json)
칸마다 같은 무늬를 찍지 않는다 — data/town 지도의 곡선 · 다각형(굽은 길 · 원 광장 · 다각형 마당)을 칸당 32px로 그려 재질을 입힌다:
  자갈길 = 크기가 제각각인 둥근 돌(보로노이) · 큰길 · 시설 앞 · 다리 = 불규칙한 판석 · 광장 = 동심원으로 깐 판석 · 흙마당 = 얼룩 흙 + 잔돌 ·
  정원 = 풀 · 덤불 · 물 = 잔물결 · 계단 = 판석 + 단마다 앞면. 그다음 단 높이만큼 3/4로 올려(화면 y = 남쪽 깊이 − 높이) 옹벽 · 둑 앞면에
  마름돌을 쌓고, 손그림 마감(tools/town_handdrawn.finish — 재질이 바뀌는 곳에 먹선)을 한 뒤 512px 조각으로 자른다.
색은 예전 바닥 색(render.json city.town.colors — 사용자 "전체적 색감이 예전이 나은 것 같은데").
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_handdrawn as th  # noqa: E402
from town_hand_bake import user_dir  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "town", "ground")
PX = 32
CHUNK = 512
KINDS = ["void", "street", "avenue", "paving", "plaza", "stairs", "bridge", "yard", "court", "water", "retain", "wall", "gate", "dais", "house", "prop"]
K = {k: i for i, k in enumerate(KINDS)}


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def hash2(i, j, seed):
    """정수 격자 → 0~1(같은 자리는 늘 같은 값)."""
    h = (i.astype(np.int64) * 374761393 + j.astype(np.int64) * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF).astype(np.float32) / 65535.0


def voronoi(xs, ys, cell, seed, jitter=0.85):
    """세계 px 좌표(xs, ys)에서 흔들린 격자점 보로노이: (가까운 점과의 거리, 둘째와의 차 = 줄눈까지, 돌 번호)."""
    gx, gy = xs / cell, ys / cell
    ix, iy = np.floor(gx).astype(np.int64), np.floor(gy).astype(np.int64)
    f1 = np.full(xs.shape, 1e9, np.float32)
    f2 = np.full(xs.shape, 1e9, np.float32)
    cid = np.zeros(xs.shape, np.int64)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx, cy = ix + dx, iy + dy
            px = cx + 0.5 + (hash2(cx, cy, seed) - 0.5) * jitter
            py = cy + 0.5 + (hash2(cx, cy, seed + 7) - 0.5) * jitter
            d = np.hypot(gx - px, gy - py).astype(np.float32)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            cid = np.where(closer, cx * 100003 + cy, cid)
            f1 = np.where(closer, d, f1)
    return f1 * cell, (f2 - f1) * cell, cid


def noise(xs, ys, scale, seed):
    """값 잡음(쌍선형) 0~1."""
    gx, gy = xs / scale, ys / scale
    ix, iy = np.floor(gx).astype(np.int64), np.floor(gy).astype(np.int64)
    fx, fy = gx - ix, gy - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, seed), hash2(ix + 1, iy, seed)
    c, d = hash2(ix, iy + 1, seed), hash2(ix + 1, iy + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(xs, ys, scale, seed, oct=3):
    v, a, t = 0.0, 1.0, 0.0
    for o in range(oct):
        v = v + noise(xs, ys, scale / (2 ** o), seed + o * 31) * a
        t += a
        a *= 0.5
    return v / t


def stones(xs, ys, base, cell, seed, mortar, gap=1.6, dome=0.22, var=0.16):
    """돌 깐 바닥: 돌마다 밝기 · 색 조금씩 · 돌 가운데가 볼록(왼쪽 위가 밝다) · 줄눈."""
    f1, edge, cid = voronoi(xs, ys, cell, seed)
    tone = 1.0 + (hash2(cid, cid * 7, seed + 3) - 0.5) * 2 * var
    warm = (hash2(cid, cid * 3, seed + 5) - 0.5) * 0.06
    col = base[None, None, :] * tone[..., None]
    col[..., 0] += warm
    col[..., 2] -= warm
    shade = 1.0 + dome * (1.0 - np.clip(f1 / (cell * 0.55), 0, 1)) - 0.06
    col = col * shade[..., None]
    grain = (fbm(xs, ys, 6, seed + 11, 2) - 0.5) * 0.12
    col = col * (1.0 + grain[..., None])
    m = np.clip((gap - edge) / gap, 0, 1)
    col = col * (1 - m[..., None]) + mortar[None, None, :] * m[..., None]
    return col


def plaza_stones(xs, ys, cx, cy, base, mortar):
    """광장: 가운데를 둘러 동심원으로 깐 판석."""
    r = np.hypot(xs - cx, ys - cy)
    ring = np.floor(r / 22.0)
    a = np.arctan2(ys - cy, xs - cx)
    n = np.maximum(6, np.floor(2 * np.pi * (ring + 0.5) * 22.0 / 30.0))
    seg = np.floor((a + np.pi + ring * 0.37) / (2 * np.pi) * n)
    cid = (ring * 1000 + seg).astype(np.int64)
    tone = 1.0 + (hash2(cid, cid * 5, 41) - 0.5) * 0.24
    col = base[None, None, :] * tone[..., None]
    er = np.minimum(r - ring * 22.0, (ring + 1) * 22.0 - r)
    ea = np.abs(((a + np.pi + ring * 0.37) / (2 * np.pi) * n) - seg - 0.5)
    ea = (0.5 - ea) * 2 * np.pi * np.maximum(r, 1) / n
    e = np.minimum(er, ea)
    m = np.clip((1.6 - e) / 1.6, 0, 1)
    col = col * (1.0 + (fbm(xs, ys, 7, 43, 2)[..., None] - 0.5) * 0.12)
    return col * (1 - m[..., None]) + mortar[None, None, :] * m[..., None]


def dirt(xs, ys, base, seed):
    """흙마당: 얼룩 흙 + 잔돌 + 마른 풀 자국."""
    v = fbm(xs, ys, 40, seed, 4)
    col = base[None, None, :] * (0.82 + 0.36 * v[..., None])
    f1, _e, cid = voronoi(xs, ys, 9, seed + 3, 0.9)
    peb = (f1 < 1.6) & (hash2(cid, cid, seed + 5) < 0.35)
    col[peb] = col[peb] * 0.72 + 0.06
    grass = fbm(xs, ys, 18, seed + 9, 3) > 0.66
    col[grass] = col[grass] * np.array([0.88, 0.98, 0.78], np.float32)
    return col


def garden(xs, ys, base, seed):
    """정원(닿지 않는 틈): 풀 + 덤불 덩이."""
    v = fbm(xs, ys, 22, seed, 4)
    col = base[None, None, :] * (0.8 + 0.4 * v[..., None])
    f1, _e, cid = voronoi(xs, ys, 26, seed + 3, 0.8)
    bush = (f1 < 9.0) & (hash2(cid, cid, seed + 5) < 0.55)
    shade = np.clip(1.15 - f1 / 9.0 * 0.4, 0.7, 1.2)
    col[bush] = (np.array([0.27, 0.32, 0.2], np.float32)[None, :] * shade[bush][:, None])
    return col


def water(xs, ys, base):
    v = fbm(xs * 0.4, ys * 1.6, 14, 51, 3)
    col = base[None, None, :] * (0.85 + 0.3 * v[..., None])
    rip = np.abs(np.sin(xs * 0.11 + fbm(xs, ys, 30, 53, 2) * 6)) > 0.97
    col[rip] = col[rip] * 1.35
    return col


def main():
    town = json.load(open(os.path.join(ROOT, "data", "town", "district7.json"), encoding="utf-8"))
    cells = json.load(open(os.path.join(user_dir(), "town_cells.json")))
    render = json.load(open(os.path.join(ROOT, "data", "render.json"), encoding="utf-8"))
    colors = render["city"]["town"]["colors"]
    cw, ch = cells["width"], cells["height"]
    W, H = cw * PX, ch * PX
    # 1) 종류(지도 영역을 순서대로 — 곡선 그대로)
    kim = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(kim)

    def P(q):
        return (q[0] * PX, q[1] * PX)

    for a in town["areas"]:
        k = K.get(a["kind"], K["street"])
        if "poly" in a:
            d.polygon([P(q) for q in a["poly"]], fill=k)
        elif "line" in a:
            pts = [P(q) for q in a["line"]]
            w = a["width"] * PX
            d.line(pts, fill=k, width=int(w))
            for x, y in pts:
                d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=k)
        elif "circle" in a:
            cx, cy, r = a["circle"]
            d.ellipse([(cx - r) * PX, (cy - r) * PX, (cx + r) * PX, (cy + r) * PX], fill=k)
        elif "rect" in a:
            x0, y0, x1, y1 = a["rect"]
            d.rectangle([x0 * PX, y0 * PX, x1 * PX - 1, y1 * PX - 1], fill=k)
    kind = np.array(kim)
    ck = np.array([K.get(s, 0) for s in cells["kinds"]], np.uint8).reshape(ch, cw)
    cell_kind = np.repeat(np.repeat(ck, PX, 0), PX, 1)
    # 정원 · 계단은 칸 정보대로(정원은 가장자리를 흐리게 섞는다), 집 밑은 둘레 땅 그대로
    court = Image.fromarray(((cell_kind == K["court"]) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    court = np.array(court) > 140
    kind[court & (kind != K["void"])] = K["court"]
    kind[cell_kind == K["stairs"]] = K["stairs"]
    # 2) 높이: 단 경계선(곡선) · 계단 · 물(칸 정보)
    xs1 = (np.arange(W) + 0.5) / PX
    hmap = np.full((H, W), float(town["bands"][-1]["h"]), np.float32)
    ys1 = (np.arange(H)[:, None] + 0.5) / PX
    for b in reversed(town["bands"][:-1]):
        line = np.array(b["line"], np.float32)
        zb = np.interp(xs1, line[:, 0], line[:, 1])
        hmap[ys1 < zb[None, :]] = b["h"]
    chs = np.array(cells["heights"], np.float32).reshape(ch, cw)
    cell_h = np.repeat(np.repeat(chs, PX, 0), PX, 1)
    st = kind == K["stairs"]
    hmap[st] = cell_h[st]
    for a in town["areas"]:
        if "h" in a:
            hmap[kind == K[a["kind"]]] = a["h"]
    # 3) 재질(위에서 본 그림)
    col = np.zeros((H, W, 3), np.float32)
    mortar = hexc("#2c2824")
    plaza_c = None
    for a in town["areas"]:
        if a["kind"] == "plaza":
            plaza_c = (a["circle"][0] * PX, a["circle"][1] * PX)
    for y0 in range(0, H, CHUNK):
        for x0 in range(0, W, CHUNK):
            y1, x1 = min(H, y0 + CHUNK), min(W, x0 + CHUNK)
            ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            kk = kind[y0:y1, x0:x1]
            out = np.zeros((y1 - y0, x1 - x0, 3), np.float32)
            todo = {
                "street": lambda: stones(xs, ys, hexc(colors["street"]) * 1.12, 11.0, 3, mortar),
                "avenue": lambda: stones(xs, ys, hexc(colors["avenue"]) * 1.08, 24.0, 5, mortar, gap=2.4, dome=0.1, var=0.14),
                "paving": lambda: stones(xs, ys, hexc(colors["paving"]) * 1.08, 20.0, 7, mortar, gap=2.2, dome=0.1, var=0.14),
                "bridge": lambda: stones(xs, ys, hexc(colors["bridge"]) * 1.1, 18.0, 9, mortar, gap=2.0, dome=0.08),
                "stairs": lambda: stones(xs, ys, hexc(colors["stairs"]) * 1.1, 22.0, 13, mortar, gap=2.2, dome=0.08),
                "retain": lambda: stones(xs, ys, hexc(colors["retain"]) * 1.15, 26.0, 15, mortar, gap=1.4, dome=0.04),
                "plaza": lambda: plaza_stones(xs, ys, plaza_c[0], plaza_c[1], hexc(colors["plaza"]) * 1.08, mortar) if plaza_c else None,
                "dais": lambda: plaza_stones(xs, ys, plaza_c[0], plaza_c[1], hexc(colors["plaza"]) * 1.08, mortar) if plaza_c else None,
                "yard": lambda: dirt(xs, ys, hexc(colors["yard"]) * 1.08, 17),
                "court": lambda: garden(xs, ys, hexc(colors["court"]) * 1.15, 19),
                "water": lambda: water(xs, ys, hexc(colors["water"]) * 1.15),
            }
            for name, fn in todo.items():
                m = kk == K[name]
                if m.any():
                    c = fn()
                    if c is not None:
                        out[m] = c[m]
            rest = (kk != K["void"]) & (out.sum(-1) == 0)  # 집 밑 · 소품 칸 등 남은 곳 = 흙
            if rest.any():
                out[rest] = dirt(xs, ys, hexc(colors["yard"]) * 1.08, 17)[rest]
            col[y0:y1, x0:x1] = out
    # 길 가장자리 연석(돌길과 흙 · 정원이 만나는 곳을 어둡게 한 줄)
    hard = np.isin(kind, [K["street"], K["avenue"], K["paving"], K["plaza"], K["bridge"]])
    soft = np.isin(kind, [K["yard"], K["court"]])
    near = np.zeros_like(hard)
    for sh in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (0, 2), (-2, 0), (0, -2)):
        near |= np.roll(np.roll(soft, sh[0], 0), sh[1], 1)
    curb = hard & near
    col[curb] = col[curb] * 0.62
    # 4) 3/4로 올린다(남쪽부터 북쪽으로 — 높은 땅이 앞의 낮은 땅 위로, 높이 차는 앞면)
    top = int(math.ceil(float(cells["max_h"]) * PX)) + 4
    SH = H + top
    scr = np.zeros((SH, W, 3), np.float32)
    code = np.zeros((SH, W), np.int64)
    ylim = np.full(W, SH, np.int64)
    prev_h = hmap[H - 1].copy()
    cols_i = np.arange(W)
    face_stone = hexc(colors["retain"]) * 1.05
    for i in range(H - 1, -1, -1):
        h = hmap[i]
        k = kind[i]
        sy = (i + top - np.round(h * PX)).astype(np.int64)
        vis = (sy < ylim) & (k != K["void"])
        if vis.any():
            span = np.where(vis, ylim - sy, 0)
            wall = vis & (h - prev_h > 0.05) & (span > 1)
            # 윗면 한 줄
            ys_ = sy[vis]
            scr[ys_, cols_i[vis]] = col[i, vis]
            code[ys_, cols_i[vis]] = k[vis] + 1
            # 앞면(옹벽 · 계단 단 · 둑): 마름돌 — 화면 좌표로 줄눈
            mx = int(span[wall].max()) if wall.any() else 0
            for dd in range(1, mx):
                m = wall & (span > dd)
                yy = sy[m] + dd
                xx = cols_i[m]
                row = yy // 11
                brick = ((xx + (row % 2) * 13) % 26 < 2) | (yy % 11 == 0)
                tone = 1.0 + (hash2(row, (xx + (row % 2) * 13) // 26, 61) - 0.5) * 0.22
                c = face_stone[None, :] * (tone * (0.92 - 0.25 * (dd / max(mx, 1))))[:, None]
                c[brick] = c[brick] * 0.55
                stair = k[m] == K["stairs"]
                c[stair] = c[stair] * 0.8
                scr[yy, xx] = c
                code[yy, xx] = 50 + (k[m] == K["stairs"])
            # 빈 칸(뒤쪽 높은 땅이 더 위로 그려져 생긴 틈)은 앞면 위 칸에서 메운다
            fill = vis & ~wall & (span > 1)
            for dd in range(1, int(span[fill].max()) if fill.any() else 0):
                m = fill & (span > dd)
                scr[sy[m] + dd, cols_i[m]] = col[i, m]
                code[sy[m] + dd, cols_i[m]] = k[m] + 1
            ylim = np.where(vis, sy, ylim)
        prev_h = np.where(k != K["void"], h, prev_h)
    # 5) 손그림 마감 · 조각
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.startswith("g") and (f.endswith(".webp") or f.endswith(".import")):
            os.remove(os.path.join(OUT, f))
    pad = 16
    chunks = []
    for y0 in range(0, SH, CHUNK):
        for x0 in range(0, W, CHUNK):
            y1, x1 = min(SH, y0 + CHUNK), min(W, x0 + CHUNK)
            ya, xa, yb, xb = max(0, y0 - pad), max(0, x0 - pad), min(SH, y1 + pad), min(W, x1 + pad)
            cc = code[ya:yb, xa:xb]
            if not (cc != 0).any():
                continue
            img, alpha = th.finish(np.clip(scr[ya:yb, xa:xb], 0, 1).astype(np.float64), cc, sprite=True)
            alpha = np.where(cc != 0, 1.0, 0.0)  # 바닥은 바깥 먹선 없이(빈곳 = 검은 바깥)
            rgba = np.dstack([img, alpha])[y0 - ya:y0 - ya + (y1 - y0), x0 - xa:x0 - xa + (x1 - x0)]
            name = "g%d_%d" % (x0 // CHUNK, y0 // CHUNK)
            Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".webp"), quality=88)
            chunks.append({"file": name, "rect": [x0, y0 - top, x1 - x0, y1 - y0]})
    json.dump({"_comment": "tools/town_ground_bake.py가 만든다(손으로 고치지 않는다). 바닥 조각 그림: rect = [x, y, w, h] 게임 px(칸당 32 — 화면 y = 남쪽 깊이 − 높이, 높은 단은 0보다 위).",
               "tile": PX, "chunks": chunks}, open(os.path.join(OUT, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("바닥: %d×%d px → 조각 %d장" % (W, SH, len(chunks)))


if __name__ == "__main__":
    main()
