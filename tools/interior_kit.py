"""시설 · 집 실내에 에셋 라이브러리(던전 에셋 키트 — 도시 · 실내 · 대장간 · 여관 · 신전 · 상점 · 은행) 그림을 쓴다(AM71 — 사용자 2026-11-15
"범용 에셋을 게임에 적용 — 기존 에셋을 갈아엎고 대체, 대체할 것이 없거나 기존이 월등하면 유지").
tools/interior_bake.py가 부른다: 바닥 · 벽 재질(FLOORS · WALLS) = 키트 4 × 4칸 바닥 · 4 × 2.5칸 벽면을 칸 좌표로 이어 붙인 재질 함수,
가구(FURN) · 벽 장식(WALLART) = 키트 낱 그림을 캔버스에 찍는다(바닥 그림자 · 빛 무리는 뺀다 — 굽는 쪽이 가구 그림자를 따로 그린다).
찍은 뒤에도 방 빛(cv.light) · 손그림 마감(finish)이 그대로 걸린다 — 실내 분위기에 맞춰진다.
표에 없는 것 = 옛 그림(interior_furn · interior_walldeco · interior_mats — 키트에 같은 것이 없거나 옛 것이 낫다). 끄기 = 환경 변수 INTERIOR_KIT=0.
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
KPX = 64.0  # 키트 그림 px / 칸
FIT = 0.92  # 가구 · 벽 장식 그림 폭 = 차지한 칸 폭 × 이것(옛 가구처럼 칸을 채운다 — 키트 제 크기는 실내 칸에서 작았다)
UP_MAX = 1.6  # 키트 제 크기(P / 64)보다 이만큼까지만 키운다(더 키우면 흐려진다)
CONTRAST = (0.85, 1.2)
ON = os.environ.get("INTERIOR_KIT", "1") != "0"

# 바닥 재질 이름 → 키트 바닥(변형) — 옛 재질 색으로 다시 칠한다(match). 사암 · 석회암 판석 · 대리석 · 테라코타는 유지(무늬가 방의 정체 —
# 키트 무늬 타일 · 바둑판으로 바꾸면 방이 다른 곳이 된다).
FLOORS = {"oak": "room_wood.a", "honey": "room_wood.b", "dirt": "floor_dirt.a"}
# 벽 재질 이름 → 키트 벽면(옛 색으로 다시 칠한다). 회벽은 옛 것(반목조 들보가 그려진 벽 — 동네 집 그림과 이어진다)이 낫다 → 유지.
WALLS = {"plank": "wall_wood.clean", "ashlar": "wall_stone.clean", "stone_dark": "wall_stone.cracked", "brick_soot": "wall_brick.clean",
         "limestone": "wall_stone.clean", "sandstone": "wall_stone.clean"}
# 가구(legend art) → 키트 그림 — 옛 것과 하나씩 견줘(docs/screens/asset_swap/interior_furniture.jpg) 키트가 나은 것만.
# 유지: 침대 · 간이침대(키트가 칸의 1/4 크기) · 제단 · 단 · 신도석 · 긴 의자 · 술집 판 · 계산대 · 창구 · 쇠창살(옛 것이 칸을 채운 짜임) ·
# 식탁 · 둥근 탁자(옛 것은 의자까지) · 마네킹 · 걸상(옛 무리는 둘 — 키트는 하나라 수가 바뀐다) · 옷장 · 책장 · 독서대 · 책상 · 진열장 ·
# 대야 · 세면대 · 풀무 · 헌금함 · 봉헌 촛대(키트가 칸에서 너무 작다) · 통 선반(키트 술통 받침이 어색하다).
FURN = {
    "anvil": "anvil", "candelabra": "candelabra.lit", "chest": "chest.closed", "crates": "crate.stack", "font": "temple_font",
    "grindstone": "grindstone", "lumber": "firewood", "pillar": "temple_column", "quench_tub": "quench_tub", "sack": "sack.pile",
    "strongbox": "strongbox", "weapon_rack": "weapon_rack.full", "display_table": "gear_table", "peddler_stall": "goods_stand",
    "workbench": "workbench.tools",
}
# 벽 장식(legend art) → 키트 벽 부착물. 유지: 창(옛 아치 창 — 창 꼴을 바꾸지 않는다) · 색유리 창(옛 빨강 · 노랑 · 초록 세 장 — 키트는 어둡고 수가 바뀐다) ·
# 항아리 벽감(키트는 등불 벽감 — 물건이 바뀐다) · 책장(옛 것이 벽에 맞다) · 물약 선반 · 밧줄 걸이(키트 것은 병이 드물고 · 망토 걸이라 물건이 바뀐다) · 금고 문(키트 것이 검은 얼룩처럼 작다) · 시계 · 문서 벽 · 닫힌 문 ·
# 뚜껑 문 · 사다리 · 등급표 · 세금 고지 · 횃불 묶음 · 봉인 선반 · 화덕 · 사냥 트로피 · 방패 벽 · 무기 벽(키트 것이 실내 칸에서 빈 틀 · 검은 판처럼 보인다).
WALLART = {
    "banner": "banner_hanging.chevron", "fireplace": "fireplace", "herbs": "herb_bundles", "notice_board": "notice_board.notices",
    "plate_shelf": "plate_rack", "portrait": "painting", "tool_wall": "tool_rack_wall.full", "cook_hearth": "spit_hearth",
}
# 칸 무리가 넓으면 되풀이(옛 그림처럼 창 · 걸이를 여러 개 — 개수 유지): 하나가 차지하는 칸 폭.
REPEAT = {"stained_glass": 1.3, "herbs": 1.2, "plate_shelf": 2.0, "portrait": 2.5, "rope_hooks": 1.5, "banner": 1.8}

_kit = None
_sheets = {}


def kit():
    global _kit
    if _kit is None:
        _kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    return _kit


def _sheet(name):
    if name not in _sheets:
        _sheets[name] = np.asarray(Image.open(os.path.join(KIT, name + ".webp")).convert("RGBA")).astype(np.float32) / 255.0
    return _sheets[name]


def frame(ref):
    """'id.변형' → (RGBA 0~1 배열, 발 x, 발 y, 빛 나는가). 변형이 없으면 첫 변형."""
    aid, _, var = ref.partition(".")
    a = kit()["assets"][aid]
    if var not in a["variants"]:
        var = next(iter(a["variants"]))
    x, y, w, h, ox, oy = a["variants"][var]["frames"][0]
    img = _sheet(a["sheet"])[int(y):int(y + h), int(x):int(x + w)].copy()
    light = a.get("light")
    lit = bool(light) and var in light.get("variants", [var])
    return img, float(ox), float(oy), lit


def strip_shadow(img):
    body = img[..., 3] >= 0.78
    near = body.copy()
    near[1:] |= body[:-1]
    near[:-1] |= body[1:]
    near[:, 1:] |= body[:, :-1]
    near[:, :-1] |= body[:, 1:]
    out = img.copy()
    out[~near] = 0
    return out


def body_box(img):
    a = img[..., 3] > 0.3
    ys, xs = np.flatnonzero(a.any(1)), np.flatnonzero(a.any(0))
    if not len(ys):
        return 0, 0, 1, 1
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


def _resize(img, s):
    if abs(s - 1.0) < 1e-3:
        return img
    pm = img.copy()
    pm[..., :3] *= pm[..., 3:4]
    h, w = img.shape[:2]
    im = Image.fromarray((np.clip(pm, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    sm = np.asarray(im).astype(np.float32) / 255.0
    a = sm[..., 3:4]
    sm[..., :3] = np.where(a > 1e-3, sm[..., :3] / np.maximum(a, 1e-3), 0)
    return sm


def stamp(cv, ref, fx, fy, P, max_w=None, max_h=None, z=0.0, shadow=False):
    """키트 그림을 캔버스에 찍는다 — 발이 세계 칸 (fx, fy, z)에. 크기 = 칸 맞춤(P / 64), max_w · max_h(칸)를 넘으면 줄인다."""
    img, ox, oy, lit = frame(ref)
    if not shadow:
        img = strip_shadow(img)
    x0, y0, x1, y1 = body_box(img)
    s = P / KPX * UP_MAX
    if max_w:
        s = min(s, max_w * FIT * P / max(1.0, x1 - x0))
    if max_h:
        s = min(s, max_h * P / max(1.0, y1 - y0))
    img = _resize(img, s)
    px, py = cv.to_px(fx, fy, z)
    left, top = int(round(px - ox * s)), int(round(py - oy * s))
    H, W = cv.raw.shape[:2]
    h, w = img.shape[:2]
    sx0, sy0 = max(0, -left), max(0, -top)
    sx1, sy1 = min(w, W - left), min(h, H - top)
    if sx1 <= sx0 or sy1 <= sy0:
        return s
    sub = img[sy0:sy1, sx0:sx1]
    reg = (slice(top + sy0, top + sy1), slice(left + sx0, left + sx1))
    a = sub[..., 3:4]
    cv.raw[reg] = cv.raw[reg] * (1 - a) + sub[..., :3] * a
    cid = cv.new_id()
    m = sub[..., 3] >= 0.5
    cv.code[reg][m] = cid * 4096
    cv.lit[reg][m] = 1.0
    if lit:  # 불 · 촛불 · 창빛은 방 빛에 어두워지지 않게
        lum = sub[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
        g = np.clip((lum - 0.62) / 0.25, 0, 1) * m
        cv.glow[reg] = np.maximum(cv.glow[reg], g)
    return s


def need_height(ref, gw, P):
    """가구 캔버스 높이(칸) — 찍을 그림 높이에 맞춘다."""
    img, ox, oy, _ = frame(ref)
    img = strip_shadow(img)
    x0, y0, x1, y1 = body_box(img)
    s = min(P / KPX * UP_MAX, gw * FIT * P / max(1.0, x1 - x0))
    return (oy - y0) * s / P + 0.2


def furniture(cv, art, gw, gd, P):
    """가구 칸 무리(gw × gd 칸, 왼쪽 위 = 0, 0)에 키트 그림. 발 = 무리 가운데(남쪽으로 조금)."""
    stamp(cv, FURN[art], gw * 0.5, gd * 0.5 + 0.15, P, max_w=gw)


def wallart(cv, art, x0, x1, y, P):
    """북벽 장식(벽 밑동 줄 y — 키트 벽 부착물의 발도 벽 밑동). 넓은 무리는 REPEAT 폭마다 하나씩."""
    w = x1 - x0
    n = max(1, int(round(w / REPEAT[art]))) if art in REPEAT else 1
    for i in range(n):
        stamp(cv, WALLART[art], x0 + w * (i + 0.5) / n, y, P, max_w=w / n)


def _tile_tex(ref, tw, th):
    img, _ox, _oy, _ = frame(ref)
    rgb = img[..., :3]
    H, W = rgb.shape[:2]
    return rgb, W, H


def match(rgb, ref):
    """키트 재질 색을 옛 재질(ref — 같은 칸 넓이 표본)의 채널 평균 · 퍼짐에 맞춘다(방마다 정한 분위기 · 색 — 대비는 CONTRAST 안에서만)."""
    k = rgb.reshape(-1, 3)
    o = ref.reshape(-1, 3)
    out = np.empty_like(rgb)
    for c in range(3):
        mk, sk = k[:, c].mean(), k[:, c].std() + 1e-3
        r = float(np.clip(o[:, c].std() / sk, *CONTRAST))
        out[..., c] = (rgb[..., c] - mk) * r + o[:, c].mean()
    return np.clip(out, 0, 1)


def _sample(tex, w, h, base_y=None):
    v, u = np.mgrid[0:64, 0:96]
    u = u / 96.0 * w
    v = v / 64.0 * h if base_y is None else base_y - v / 64.0 * h
    rgb, _ = tex(u.astype(np.float32), v.astype(np.float32))
    return np.asarray(rgb, np.float32)


def floor_tex(name, old=None):
    """바닥 재질 → tex(u, v): 키트 바닥 4 × 4칸 그림을 칸 좌표로 되풀이(old = 옛 재질 tex — 색을 맞춘다)."""
    rgb, W, H = _tile_tex(FLOORS[name], 4, 4)
    if old is not None:
        rgb = match(rgb, _sample(old, 4.0, 4.0))

    def tex(u, v):
        px = (np.floor((u % 4.0) / 4.0 * W).astype(np.int64)) % W
        py = (np.floor((v % 4.0) / 4.0 * H).astype(np.int64)) % H
        return rgb[py, px], None
    return tex


def wall_tex(name, base_y, wall_h, old=None):
    """벽 재질 → tex(u, v): 키트 벽면(4칸 폭 · 2.5칸 높이)을 벽 높이(wall_h)에 맞춰 늘인다. z = base_y − v(old = 옛 재질 tex — 색을 맞춘다)."""
    rgb, W, H = _tile_tex(WALLS[name], 4, 2.5)
    if old is not None:
        rgb = match(rgb, _sample(old, 4.0, wall_h, base_y))

    def tex(u, v):
        z = base_y - v
        px = (np.floor((u % 4.0) / 4.0 * W).astype(np.int64)) % W
        py = np.clip(np.floor((1.0 - z / wall_h) * H).astype(np.int64), 0, H - 1)
        return rgb[py, px], None
    return tex
