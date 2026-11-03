"""집 바리에이션 손그림 마감(사용자 2026-11-02 "3d 말고 손그림으로 뽑는 건 무리냐"):
tools/town_variants.gd가 남긴 날 그림(variants/raw/<id>_raw.png — 그림자·바닥 없음, 종이색 배경)과 면 번호 그림(<id>_id.png)으로
  ① 붓 자국 뭉개기(쿠와하라 — 유화처럼 색이 덩어리진다) ② 면마다 잉크 윤곽(면 번호가 바뀌는 곳 · 바깥은 굵게, 떨림·끊김)
  ③ 어두운 곳 펜 빗금 ④ 종이 결·얼룩 ⑤ 색 정리(채도 조금 빼고 따뜻하게) → variants/<id>_hand.png · sheet_hand.png
  python3 tools/town_handdrawn.py [--front] [v01 v05 …]   (--front = 정면 판 variants/front/)
  python3 tools/town_handdrawn.py --dir=concept   (도시 구상 그림 — raw/의 모든 <이름>_raw.png → <이름>_hand.png + 커밋용 <이름>_hand.jpg)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "docs", "plans", "town", "variants")
if "--front" in sys.argv:  # 정면 판(tools/town_variants.gd --view=front)
    DIR = os.path.join(DIR, "front")
    sys.argv.remove("--front")
SHEET = True
for a in list(sys.argv):
    if a.startswith("--dir="):  # 다른 그림 묶음(예: --dir=concept → docs/plans/town/concept — tools/town_concept.gd), 모아 보기 없음
        DIR = os.path.join(ROOT, "docs", "plans", "town", a[len("--dir="):])
        SHEET = False
        sys.argv.remove(a)
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
PAPER = np.array([216, 205, 180]) / 255.0
INK = np.array([26, 20, 16]) / 255.0
RNG = np.random.default_rng(7)


def box_mean(a, r):
    """(H, W[, C]) 배열의 (r+1)×(r+1) 상자 합 → 네 갈래(왼위·오위·왼아래·오아래) 평균."""
    s = r + 1
    pad = np.pad(a, ((r + 1, r + 1), (r + 1, r + 1)) + ((0, 0),) * (a.ndim - 2), mode="edge")
    c = pad.cumsum(0).cumsum(1)
    c = np.pad(c, ((1, 0), (1, 0)) + ((0, 0),) * (a.ndim - 2))
    H, W = a.shape[:2]
    out = []
    for dy, dx in [(-r, -r), (-r, 0), (0, -r), (0, 0)]:
        y0 = r + 1 + dy
        x0 = r + 1 + dx
        tot = c[y0 + s:y0 + s + H, x0 + s:x0 + s + W] - c[y0:y0 + H, x0 + s:x0 + s + W] - c[y0 + s:y0 + s + H, x0:x0 + W] + c[y0:y0 + H, x0:x0 + W]
        out.append(tot / (s * s))
    return out


def kuwahara(img, r=3):
    lum = img @ np.array([0.3, 0.59, 0.11])
    means = box_mean(img, r)
    lm = box_mean(lum, r)
    lm2 = box_mean(lum * lum, r)
    var = np.stack([lm2[k] - lm[k] ** 2 for k in range(4)], 0)
    best = var.argmin(0)
    out = np.zeros_like(img)
    for k in range(4):
        out[best == k] = means[k][best == k]
    return out


def noise(h, w, scale, seed):
    g = np.random.default_rng(seed).random((h // scale + 2, w // scale + 2))
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.asarray(im).astype(float) / 255.0


def dilate(m, n=1):
    for _ in range(n):
        m = m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)
    return m


def finish(raw, code, sprite=False):
    """날 그림(H, W, 3 · 0~1)과 면 번호(H, W)로 손그림 마감 → (그림, 불투명도). sprite면 배경을 투명하게(바깥 먹선까지만 남김 — 게임 집 그림, CT97)."""
    mask = code != 0
    H, W = mask.shape
    r1, r2 = (2, 1) if sprite else (3, 2)
    img = kuwahara(raw, r1)
    img = kuwahara(img, r2)
    img = np.clip(img, 0, 1) ** 0.88  # 조금 밝게(종이 위 물감)
    yy, xx = np.mgrid[0:H, 0:W]
    # 붓결: 비스듬히 늘인 잡음으로 밝기를 흔든다
    sx = Image.fromarray((RNG.random((H // 3 + 2, W // 18 + 2)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC).rotate(28, resample=Image.BICUBIC, expand=False)
    stroke = np.asarray(sx).astype(float) / 255.0
    soft = 0.5 if sprite else 1.0  # 게임 그림은 질감 · 빗금 · 먹선을 덜(형태가 먼저 읽히게 — CT98)
    img = img * (1.0 + (stroke[..., None] - 0.5) * 0.14 * soft)
    # 펜 빗금: 어두운 곳에 비스듬한 줄 · 더 어두우면 엇갈린 줄(끊기고 흔들린다)
    lum = img @ np.array([0.3, 0.59, 0.11])
    wob = noise(H, W, 24, 3) * 6.0
    breaks = noise(H, W, 9, 5) > 0.28
    dark = np.clip((0.5 - lum) / 0.3, 0, 1)
    h1 = ((xx * 0.55 + yy * 0.83 + wob) % 5.0) < 1.2
    h2 = ((xx * 0.83 - yy * 0.55 + wob) % 5.0) < 1.2
    hatch = (h1 * dark * 0.55 + h2 * np.clip(dark - 0.5, 0, 1) * 0.6) * breaks * mask
    hatch = hatch * soft
    img = img * (1 - hatch[..., None]) + INK[None, None, :] * hatch[..., None] * 0.3
    # 종이 결·얼룩
    grain = 1.0 + (noise(H, W, 2, 11) - 0.5) * 0.08 + (noise(H, W, 40, 13) - 0.5) * 0.10
    bg = PAPER[None, None, :] * grain[..., None]
    img = np.where(mask[..., None], img * (0.97 + (grain[..., None] - 1.0) * 0.6), bg)
    # 잉크 윤곽: 면 번호가 바뀌는 곳(굵기 1~3px로 흔들림) + 바깥 실루엣(굵게)
    edge = np.zeros_like(mask)
    for sh in [(1, 0), (0, 1), (-1, 0), (0, -1)]:
        edge |= (code != np.roll(np.roll(code, sh[0], 0), sh[1], 1))
    edge &= dilate(mask, 1)
    thick = noise(H, W, 18, 21)
    edge = edge | (dilate(edge, 1) & (thick > 0.35))
    sil = (dilate(mask, 3) & ~mask) & (dilate(mask, 2) | (thick > 0.5))
    if sprite:  # 게임 그림은 작아서 바깥 먹선을 얇게(2px)
        sil = (dilate(mask, 2) & ~mask) & (dilate(mask, 1) | (thick > 0.5))
    jitter = noise(H, W, 14, 17)
    a = np.where(edge, (0.75 + jitter * 0.25) * (0.7 if sprite else 1.0), 0.0)
    a = np.maximum(a, np.where(sil, 0.85 if sprite else 0.92, 0.0))
    a *= np.where(noise(H, W, 30, 19) > 0.1, 1.0, 0.4)  # 가끔 끊김
    img = img * (1 - a[..., None]) + INK[None, None, :] * a[..., None]
    # 색 정리: 채도 조금 빼고 따뜻하게
    lum = img @ np.array([0.3, 0.59, 0.11])
    img = img * 0.85 + lum[..., None] * 0.15
    img = img * np.array([1.03, 1.0, 0.94])
    alpha = np.where(mask, 1.0, np.where(sil, a, 0.0)) if sprite else np.ones(mask.shape)
    return np.clip(img, 0, 1), alpha


def hand(vid):
    raw = np.asarray(Image.open(os.path.join(DIR, "raw", vid + "_raw.png")).convert("RGB")).astype(float) / 255.0
    ids = np.asarray(Image.open(os.path.join(DIR, "raw", vid + "_id.png")).convert("RGB")).astype(np.int64)
    code = ids[..., 0] * 65536 + ids[..., 1] * 256 + ids[..., 2]
    img, _a = finish(raw, code)
    out = Image.fromarray((img * 255).astype(np.uint8))
    out.save(os.path.join(DIR, vid + "_hand.png"))
    if not SHEET:  # 묶음 그림(구상 그림)은 커밋용 jpg도(큰 png는 커밋하지 않는다)
        out.convert("RGB").save(os.path.join(DIR, vid + "_hand.jpg"), quality=86)
    return out


def sheet(names):
    cell = 400
    cols = 4
    rows = (len(names) + cols - 1) // cols
    s = Image.new("RGB", (cell * cols, (cell + 34) * rows), (216, 205, 180))
    d = ImageDraw.Draw(s)
    f = ImageFont.truetype(FONT, 17)
    for k, (vid, name) in enumerate(names):
        p = os.path.join(DIR, vid + "_hand.png")
        if not os.path.exists(p):
            continue
        x = (k % cols) * cell
        y = (k // cols) * (cell + 34)
        s.paste(Image.open(p).resize((cell, cell), Image.LANCZOS), (x, y + 34))
        d.text((x + 10, y + 8), "%s  %s" % (vid, name), font=f, fill=(40, 30, 22))
    s.save(os.path.join(DIR, "sheet_hand.png"))
    print("저장:", os.path.join(DIR, "sheet_hand.png"))


def main():
    import re
    if not SHEET:
        for f in sorted(os.listdir(os.path.join(DIR, "raw"))):
            if f.endswith("_raw.png"):
                hand(f[:-len("_raw.png")])
                print("손그림:", f)
        return
    src = open(os.path.join(ROOT, "tools", "town_kit", "Designs.gd"), encoding="utf-8").read()
    names = re.findall(r'\["(v\d+)", "([^"]+)", "_\w+"\]', src)
    want = set(sys.argv[1:])
    for vid, _ in names:
        if (not want or vid in want) and os.path.exists(os.path.join(DIR, "raw", vid + "_raw.png")):
            hand(vid)
            print("손그림:", vid)
    sheet(names)


if __name__ == "__main__":
    main()
