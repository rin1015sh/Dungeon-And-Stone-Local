"""UI · 시설 아이콘(도시 · 실내 라이브러리 AM69): 96 × 96, 상태이상 아이콘(tools/status_art — Shapes.plate · shape)과 같은 판 —
어두운 둥근 받침 + 가는 테(palette.select 뼈빛, 돈 · 보물만 palette.gold) + 위에서 아래로 어두워지는 평면 기호 + 굵은 잉크 윤곽 + 왼쪽 위 작은 반짝임.
변형: plate(받침 있음 — 카드 · 목록) · plain(기호만 — 지도 표식). 글자 · 종교 상징은 쓰지 않는다. 게임 데이터에는 아직 연결하지 않았다."""
import numpy as np

from kit import F, flat
from paint2d import INK, gblur, hexc

S = 96
C = 48.0
RIM = "#d6cbb0"     # render.json palette.select
GOLD = "#a88a4e"    # render.json palette.gold — 돈 · 보물에만(UI45)
VARS = {"plate": {}, "plain": {"plate": False}}


def _plate(c, rim):
    d = c.dist(C, C, 44.0)
    disc = np.clip((1.0 - d) * 44.0 + 0.5, 0, 1)
    tone = hexc("#1c1614")[None, None, :] * (1 - np.clip(d, 0, 1)[..., None]) + hexc("#0c0908")[None, None, :] * np.clip(d, 0, 1)[..., None]
    c.paint(disc, tone * (0.8 + 0.3 * c.noise(5)[..., None] + 0.15 * c.noise(1.5)[..., None]))   # 얼룩진 받침(상태 아이콘처럼)
    c.paint(c.ring(C, C, 43.0, 2.4) * (0.8 + 0.2 * c.noise(4)), rim, 0.78)
    c.paint(c.ring(C, C, 45.5, 1.5), INK, 0.9)


def shape(c, m, col, ink=3.0, shine=True):
    """칠한 도형: 밝은 위 → 어두운 아래(붓결) + 잉크 윤곽 + 반짝임(Shapes.shape와 같은 순서)."""
    col = hexc(col)
    ys, xs = np.nonzero(m > 0.5)
    if len(ys) == 0:
        return
    y0, y1, x0, x1 = ys.min() / 2, ys.max() / 2, xs.min() / 2, xs.max() / 2
    t = np.clip((c.yy - y0) / max(1.0, y1 - y0) * 0.8 + (c.xx - x0) / max(1.0, x1 - x0) * 0.2, 0, 1)
    top, low = col + (1 - col) * 0.28, col * 0.55
    grad = top[None, None, :] * (1 - t[..., None]) + low[None, None, :] * t[..., None]
    c.paint(m, grad * (0.92 + 0.16 * c.noise(3)[..., None]))
    if ink > 0:
        out = np.clip(gblur(m, ink * 0.9) * 2.2, 0, 1) * (1 - m)   # 바깥 테
        c.paint(np.maximum(out, c.rim(m, 1.0) * 0.8), INK, 0.95)
    if shine:
        hx, hy = x0 + (x1 - x0) * 0.3, y0 + (y1 - y0) * 0.25
        c.add(np.clip(1 - c.dist(hx, hy, max(2.0, min(x1 - x0, y1 - y0) * 0.22)), 0, 1) * m * 0.35, "#fff8e6", 1.0)


def bar(c, a, b, w, col):
    shape(c, c.seg([a, b], w, False), col, 2.5, False)


def U(*ms):
    return np.maximum.reduce(ms)


def _icon(id, name, rim=RIM, tags=()):
    def deco(fn):
        def run(c, plate=True, seed=1):
            c.graded = False
            if plate:
                _plate(c, rim)
            fn(c)
        run.__name__ = fn.__name__
        run.__wrapped__ = fn   # 캐시 열쇠(소스)가 기호 함수를 보게
        return flat(id, "icon", layer="over", cell=(S, S), variants=VARS, tags=["icon", "ui"] + list(tags), name_ko=name, meta={"grid": True, "icon_px": S})(run)
    return deco


# ── 시설 ─────────────────────────────────────────────────────────────────────

@_icon("icon_smithy", "대장간 아이콘", tags=["facility"])
def icon_smithy(c):
    anvil = c.poly([(22, 46), (70, 46), (74, 50), (62, 54), (58, 62), (64, 70), (34, 70), (40, 62), (36, 54), (26, 52), (18, 50)])
    shape(c, anvil, "#6a6e74")
    bar(c, (40, 40), (66, 18), 6, "#7a5a38")                 # 자루
    shape(c, c.poly([(58, 14), (72, 26), (78, 20), (64, 8)]), "#8a8e94")


@_icon("icon_inn", "여관 아이콘", tags=["facility"])
def icon_inn(c):
    shape(c, c.ring(66, 52, 10, 6), "#7a5a38", 2.5, False)   # 손잡이
    body = c.poly([(30, 34), (66, 34), (64, 74), (32, 74)])
    shape(c, body, "#8a6a42")
    for y in (42, 66):
        shape(c, c.rect(30, y - 2, 66, y + 2), "#5a5a5c", 2.0, False)
    shape(c, U(c.blob(36, 32, 9, 7, 0.1), c.blob(48, 29, 10, 8, 0.1), c.blob(60, 32, 9, 7, 0.1)), "#e0d6bc")


@_icon("icon_shrine", "신전 아이콘", tags=["facility"])
def icon_shrine(c):
    """뾰족 아치 창 + 그 앞의 촛불(특정 신의 상징 없이)."""
    win = U(c.rect(32, 40, 64, 76), c.poly([(32, 41), (48, 14), (64, 41)]) * 0 + np.clip((1 - np.maximum(c.dist(32, 41, 32, 30), c.dist(64, 41, 32, 30))) * 30, 0, 1) * (c.yy < 42) * (c.xx > 31) * (c.xx < 65))
    shape(c, win, "#8a94a0")
    pane = np.clip((1 - np.maximum(c.dist(38, 43, 22, 23), c.dist(58, 43, 22, 23))) * 30, 0, 1) * (c.yy < 44) * (c.xx > 37) * (c.xx < 59)
    shape(c, U(c.rect(38, 42, 58, 72), pane), "#3e5a78", 1.2, False)
    c.paint(c.rect(47, 22, 49, 72), INK, 0.7)
    c.paint(c.rect(38, 50, 58, 52), INK, 0.7)
    shape(c, c.rect(44, 62, 52, 80), "#e0d4b0")             # 초
    shape(c, c.blob(48, 55, 4, 7, 0.1), "#f0a040", 1.5, False)


@_icon("icon_shop", "상점 아이콘", tags=["facility"])
def icon_shop(c):
    sack = U(c.blob(42, 56, 20, 20, 0.08), c.poly([(34, 30), (50, 30), (46, 40), (38, 40)]))
    shape(c, sack, "#9a8058")
    bar(c, (34, 38), (52, 36), 3, "#5a4428")
    shape(c, U(c.blob(68, 60, 10, 12, 0.02), c.rect(65, 38, 71, 50)), "#7a2a2a")   # 물약 병
    shape(c, c.rect(64, 34, 72, 40), "#8a6a42", 2.0, False)


@_icon("icon_bank", "은행 아이콘", rim=GOLD, tags=["facility", "money"])
def icon_bank(c):
    bar(c, (48, 22), (48, 72), 5, "#8a7440")
    bar(c, (22, 30), (74, 30), 4, "#8a7440")
    for x in (26, 70):
        c.paint(c.seg([(x, 30), (x - 8, 52)], 1.5, False), INK, 0.9)
        c.paint(c.seg([(x, 30), (x + 8, 52)], 1.5, False), INK, 0.9)
        shape(c, c.blob(x, 54, 12, 5, 0.0), "#b09448")
    shape(c, c.rect(34, 72, 62, 78), "#6a5a34")
    for i, y in enumerate((50, 44)):
        shape(c, c.blob(70, y - 4, 7, 3, 0.0), "#c8a850", 1.8, i == 1)


@_icon("icon_guild", "탐험가 길드 아이콘", tags=["facility"])
def icon_guild(c):
    """탐험가 신원패(구멍 뚫린 금속 패 + 끈)."""
    c.paint(c.seg([(36, 18), (48, 30), (60, 18)], 3, False), "#6a5a40")
    tag = c.poly([(30, 30), (66, 30), (70, 36), (70, 74), (26, 74), (26, 36)])
    shape(c, tag, "#8a8e90")
    c.paint(c.blob(48, 37, 3.5, 3.5, 0), INK, 0.9)
    for y in (50, 58, 66):
        c.paint(c.rect(34, y, 62 - (y % 3) * 4, y + 2), INK, 0.55)


@_icon("icon_library", "도서관 아이콘", tags=["facility"])
def icon_library(c):
    left = c.poly([(16, 34), (46, 40), (46, 74), (16, 68)])
    right = c.poly([(50, 40), (80, 34), (80, 68), (50, 74)])
    shape(c, U(c.poly([(14, 36), (48, 43), (82, 36), (82, 72), (48, 78), (14, 72)])), "#5a3a28", 2.5, False)
    shape(c, left, "#d8ccaa")
    shape(c, right, "#ccbf9c")
    for i in range(4):
        y = 46 + i * 6
        c.paint(c.seg([(21, y - 4), (41, y)], 1.2, False), INK, 0.5)
        c.paint(c.seg([(55, y), (75, y - 4)], 1.2, False), INK, 0.5)


@_icon("icon_plaza", "차원광장 아이콘", tags=["facility", "magic"])
def icon_plaza(c):
    """돌 고리(차원광장 포탈) — 둘러선 돌 여섯 + 가운데 푸른 빛."""
    c.add(np.clip(1 - c.dist(48, 50, 22, 16), 0, 1) ** 1.5, "#70b0f0", 0.9)
    for i in range(6):
        a = i / 6 * 6.283 - 1.57
        x, y = 48 + np.cos(a) * 26, 52 + np.sin(a) * 18
        shape(c, c.poly([(x - 5, y + 8), (x + 5, y + 8), (x + 4, y - 10), (x - 3, y - 12)]), "#8a867a", 2.2, False)
    c.add(np.clip(1 - c.dist(48, 50, 8, 10), 0, 1), "#dcf2ff", 0.9)


@_icon("icon_city_gate", "도시 입구 아이콘", tags=["facility"])
def icon_city_gate(c):
    wall = U(c.rect(18, 34, 78, 78), *[c.rect(x, 26, x + 8, 36) for x in (18, 32, 56, 70)])
    shape(c, wall, "#8a8274")
    arch = U(c.rect(36, 52, 60, 80), np.clip((1 - c.dist(48, 52, 12, 13)) * 20, 0, 1))
    c.paint(arch, "#0e0c0b")
    for x in (40, 46, 52, 58):
        c.paint(c.rect(x - 1, 46, x + 1, 80), "#4a4440")
    c.paint(c.rect(36, 62, 60, 64), "#4a4440")


# ── 표식 ─────────────────────────────────────────────────────────────────────

@_icon("icon_interact", "상호작용 아이콘", tags=["marker"])
def icon_interact(c):
    """편 손바닥(살피기 · 줍기)."""
    palm = c.blob(48, 58, 16, 16, 0.05)
    fingers = [c.seg([(x, 54), (x + dx, 54 - ln)], 8.5, False) for x, dx, ln in ((37, -3, 26), (45, -1, 32), (53, 1, 31), (60, 3, 24))]
    thumb = c.seg([(34, 62), (22, 48)], 9, False)
    shape(c, U(palm, thumb, *fingers), "#c8a890")


@_icon("icon_locked_door", "잠긴 문 아이콘", tags=["marker", "lock"])
def icon_locked_door(c):
    door = U(c.rect(28, 36, 68, 80), np.clip((1 - c.dist(48, 36, 20, 20)) * 20, 0, 1) * (c.yy < 37))
    shape(c, door, "#6a4a30")
    for x in (38, 48, 58):
        c.paint(c.rect(x - 0.6, 20, x + 0.6, 80), INK, 0.5)
    shape(c, c.ring(56, 52, 7, 3.5), "#9a9a9a", 2.0, False)
    shape(c, c.rect(46, 54, 66, 72), "#b09448")
    c.paint(c.blob(56, 61, 2.5, 2.5, 0), INK, 1.0)
    c.paint(c.rect(55.2, 61, 56.8, 67), INK, 1.0)


@_icon("icon_key", "열쇠 아이콘", tags=["marker", "lock"])
def icon_key(c):
    shape(c, U(c.ring(30, 36, 11, 7), c.seg([(38, 44), (70, 72)], 7, False), c.seg([(60, 63), (66, 57)], 6, False), c.seg([(66, 69), (72, 63)], 6, False)), "#a09070")


@_icon("icon_treasure", "보물 아이콘", rim=GOLD, tags=["marker", "money"])
def icon_treasure(c):
    shape(c, c.poly([(22, 30), (74, 30), (70, 44), (26, 44)]), "#6a3a28")   # 열린 뚜껑
    shape(c, U(c.blob(48, 48, 22, 9, 0.2), c.blob(36, 46, 8, 6, 0.1), c.blob(60, 45, 8, 6, 0.1)), "#c8a850")
    shape(c, c.rect(22, 50, 74, 78), "#7a4430")
    shape(c, c.rect(22, 54, 74, 58), "#a08848", 1.5, False)
    shape(c, c.rect(44, 56, 52, 66), "#a08848", 1.5, False)
    for x, y in ((30, 22), (66, 20), (50, 16)):
        c.add(U(c.seg([(x - 5, y), (x + 5, y)], 1.4, False), c.seg([(x, y - 5), (x, y + 5)], 1.4, False)), "#fff0c0", 1.0)


@_icon("icon_chest", "상자 아이콘", tags=["marker", "container"])
def icon_chest(c):
    lid = U(c.rect(22, 36, 74, 48), np.clip((1 - c.dist(48, 38, 26, 10)) * 20, 0, 1) * (c.yy < 39))
    shape(c, lid, "#7a5838")
    shape(c, c.rect(22, 48, 74, 76), "#6a4a30")
    for x in (28, 68):
        shape(c, c.rect(x - 3, 30, x + 3, 76), "#5a5a5c", 1.5, False)
    shape(c, c.rect(44, 46, 52, 56), "#8a8e94", 1.5, False)


@_icon("icon_magic_stone", "마석 아이콘", tags=["marker", "material", "magic"])
def icon_magic_stone(c):
    """깎인 마석 덩이(1층 마석과 같은 붉은 돌빛 + 금 간 속빛)."""
    stone = c.poly([(30, 30), (54, 18), (72, 34), (68, 66), (44, 78), (24, 60)])
    shape(c, stone, "#8a4a40")
    c.paint(U(c.seg([(54, 18), (50, 46), (44, 78)], 1.4, False), c.seg([(50, 46), (72, 34)], 1.4, False), c.seg([(50, 46), (24, 60)], 1.4, False)), INK, 0.6)
    c.add(c.seg([(46, 30), (52, 46), (48, 60)], 2.2, True), "#f07050", 0.9)


@_icon("icon_potion", "물약 아이콘", tags=["marker", "consumable"])
def icon_potion(c):
    shape(c, U(c.blob(48, 60, 18, 18, 0.0), c.rect(42, 28, 54, 46)), "#8a9a98")
    shape(c, c.blob(48, 64, 15, 13, 0.0) * (c.yy > 54), "#a02a2a", 1.0, False)
    shape(c, c.rect(41, 20, 55, 30), "#8a6a42", 2.0, False)


@_icon("icon_material", "재료 아이콘", tags=["marker", "material"])
def icon_material(c):
    shape(c, c.poly([(18, 70), (40, 52), (78, 52), (80, 60), (60, 78), (20, 78)]), "#8a8e94")    # 주괴
    shape(c, c.poly([(24, 42), (36, 22), (56, 20), (64, 36), (52, 50), (30, 52)]), "#5a5650")    # 광석 덩이
    for x, y in ((40, 34), (50, 30), (46, 42)):
        shape(c, c.blob(x, y, 3.5, 2.5, 0.0), "#6a9a58", 1.2, False)


@_icon("icon_equipment", "장비 아이콘", tags=["marker", "equipment"])
def icon_equipment(c):
    shield = c.poly([(26, 26), (70, 26), (70, 52), (48, 80), (26, 52)])
    shape(c, shield, "#5a4a3a")
    shape(c, c.rect(26, 26, 70, 31), "#8a8e94", 1.5, False)
    bar(c, (22, 76), (74, 20), 6, "#a8aeb4")      # 검날
    bar(c, (24, 62), (38, 76), 5, "#8a7440")      # 날밑
    shape(c, c.blob(22, 78, 4, 4, 0), "#8a7440", 1.5, False)
