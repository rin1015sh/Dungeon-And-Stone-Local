# 전투 아군 뒷모습 숨쉬기(idle) 미리보기 — 게임에는 아직 넣지 않았다(사용자 2026-10-28 "일단 그려봐").
# 쓰는 법: python3 tools/idle_breathe_preview.py assets/party/human_back.webp <out.gif> <배경 png>
#          python3 tools/idle_breathe_preview.py assets/party/human_back.webp <out.png> [칸 수=8]  → 투명 배경 가로 스프라이트 시트
# 피어 앤 헝거 2 전투의 아군처럼: 발·엉덩이는 그대로, 어깨·머리가 숨에 맞춰 살짝 오르내리고 가슴(등)이 조금 넓어진다.
import sys, math
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
SHEET = out.endswith(".png")
bg = None if SHEET else sys.argv[3]
CELLS = int(sys.argv[3]) if SHEET and len(sys.argv) > 3 else 8
RISE = 0.022      # 어깨·머리가 오르는 양(키 비율) — 555px 키에 약 12px
WIDEN = 0.035     # 가슴 폭이 넓어지는 양
ARM_DEG = 4.5     # 들이쉴 때 팔이 어깨를 축으로 바깥으로 벌어지는 각도
ARM_IN = 0.17     # 몸통 반폭(그림 폭 비율) — 이보다 바깥이 팔
ARM_OUT = 0.25
PERIOD = 2.8      # 한 숨(초)
FPS = 20
HIP = 0.50        # 이 아래(엉덩이·다리)는 움직이지 않는다(그림 높이 비율, 위 = 0)
SHOULDER = 0.20   # 여기부터 위는 통째로 RISE만큼

img = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
h, w, _ = img.shape
ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
v = ys / h
# 움직이는 정도: 엉덩이 0 → 어깨 1(부드럽게), 어깨 위 1
t = np.clip((HIP - v) / (HIP - SHOULDER), 0.0, 1.0)
wt = t * t * (3 - 2 * t)
# 가슴 폭: 어깨 아래 가슴께가 가장 크고 머리·엉덩이에선 0
chest = np.exp(-((v - 0.30) / 0.09) ** 2)
cols = np.where(img[..., 3].max(axis=0) > 8)[0]
cx = (cols.min() + cols.max()) / 2.0
# 팔: 몸통 바깥 열 · 어깨 아래 ~ 손끝(엉덩이 조금 아래)까지
side = np.clip((np.abs(xs - cx) / w - ARM_IN) / (ARM_OUT - ARM_IN), 0.0, 1.0)
side = side * side * (3 - 2 * side)
below = np.clip((v - (SHOULDER - 0.03)) / 0.06, 0.0, 1.0) * np.clip((0.62 - v) / 0.06, 0.0, 1.0)
arm = side * below
sgn = np.sign(xs - cx)
pivot_x = cx + sgn * ARM_IN * w
pivot_y = (SHOULDER + 0.02) * h

def sample(sx, sy):
    x0 = np.clip(np.floor(sx).astype(int), 0, w - 2); y0 = np.clip(np.floor(sy).astype(int), 0, h - 2)
    fx = np.clip(sx - x0, 0, 1)[..., None]; fy = np.clip(sy - y0, 0, 1)[..., None]
    a = img[y0, x0] * (1 - fx) + img[y0, x0 + 1] * fx
    b = img[y0 + 1, x0] * (1 - fx) + img[y0 + 1, x0 + 1] * fx
    o = a * (1 - fy) + b * fy
    inside = (sx >= 0) & (sx <= w - 1) & (sy >= 0) & (sy <= h - 1)
    o[~inside] = 0
    return o

frames = []
n = CELLS if SHEET else int(PERIOD * FPS)
for i in range(n):
    ph = i / n
    s = 0.5 - 0.5 * math.cos(2 * math.pi * ph)   # 0 → 1 → 0
    s = s ** 1.15                                 # 들이쉼은 조금 느리게 차오르고 내쉼은 툭
    sy = ys + RISE * h * s * wt                   # 뒤쪽 매핑: 위로 올라간 그림 = 아래 픽셀을 가져온다
    sx = cx + (xs - cx) / (1.0 + WIDEN * s * chest)
    # 팔을 어깨 축으로 바깥으로 돌린다(뒤쪽 매핑이라 반대로 돌려 가져온다)
    a = -math.radians(ARM_DEG) * s * arm * sgn
    dx = sx - pivot_x; dy = sy - pivot_y
    rx = pivot_x + dx * np.cos(a) + dy * np.sin(a)
    ry = pivot_y - dx * np.sin(a) + dy * np.cos(a)
    sx = sx + (rx - sx) * (arm > 0); sy = sy + (ry - sy) * (arm > 0)
    frames.append(sample(sx, sy))

if SHEET:
    sheet = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(Image.fromarray(np.clip(f, 0, 255).astype(np.uint8), "RGBA"), (i * w, 0))
    sheet.save(out)
    print("sheet", n, "cells", w, "x", h, "->", out, "(", round(PERIOD / n, 3), "s per cell )")
    sys.exit(0)

# 게임 크기쯤(키 270px)과 크게(키 540px) 나란히, 전투 화면 바닥 위에
back = Image.open(bg).convert("RGB")
scale_small = 270.0 / 540.0
out_frames = []
for f in frames:
    spr = Image.fromarray(np.clip(f, 0, 255).astype(np.uint8), "RGBA")
    canvas = back.copy()
    big = spr
    small = spr.resize((int(w * scale_small), int(h * scale_small)), Image.LANCZOS)
    canvas.paste(small, (90, canvas.height - small.height - 10), small)
    canvas.paste(big, (canvas.width - w - 60, canvas.height - h + 40), big)
    out_frames.append(canvas.convert("P", palette=Image.ADAPTIVE, colors=200))
out_frames[0].save(out, save_all=True, append_images=out_frames[1:], duration=int(1000 / FPS), loop=0, optimize=False)
print("frames", n, "->", out)
