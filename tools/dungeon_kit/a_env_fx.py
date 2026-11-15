"""마법 · 환경 효과(도시 · 실내 라이브러리 AM69 — 키트에 없던 것만): 룬 고리 · 마법 에너지 · 마력 구체 · 봉인 장막 · 마법진 파편 · 빛기둥,
낱 불꽃(불 · 촛불 · 횃불) · 연기 · 먼지 구름 · 빛 알갱이 · 물방울 · 잔물결 · 물 반짝임 · 불빛 웅덩이 · 창으로 든 빛.
모두 평면 그림(@flat) 4프레임 — 입자 계산 없이 그림만 돈다. 작은 그림이라 화면에 보이는 곳에만 놓는다."""
import numpy as np

import fx
from a_fx import _cyc
from a_light import GLOWC, cglyph
from kit import F, flat
from paint2d import gblur, hexc, sstep

TAU = 2 * np.pi
COL = dict(GLOWC, gold="#e8c060", white="#e8e4d0")
PULSE = lambda f: 0.75 + 0.25 * np.sin((f or 0) * 1.5708)
KY = 0.72   # 바닥에 누운 원이 화면에서 눌리는 비율


def _lightvar(names, colors):
    return {"variants": names, "colors": {n: COL[c] for n, c in colors.items()}}


# ── 룬 고리 ──────────────────────────────────────────────────────────────────

_RR = {"off": {}, "off_b": {"seed": 5}, "blue": {"col": "blue", "frames": 4}, "violet": {"col": "violet", "frames": 4}, "gold": {"col": "gold", "frames": 4}}


@flat("rune_ring", "special", cell=(104, 80), tags=["magic", "rune", "animated"], name_ko="룬 고리", interact="circle", variants=_RR,
    light=dict({"color": COL["blue"], "radius": 1.4, "at": (0, 0, 0.05), "flicker": 0.15}, **_lightvar(["blue", "violet", "gold"], {"violet": "violet", "gold": "gold"})),
    meta={"states": {"idle": "off", "active": "blue"}, "note": "한 칸 반짜리 글자 고리 하나 — 마법진(magic_circle)보다 작고 단순하다. 물건 · 문 앞 바닥에 놓는다"})
def rune_ring(c, col=None, f=0, seed=1):
    cx, cy, R = 52.0, 40.0, 44.0
    m = np.maximum(c.ring(cx, cy, R, 1.6, ry=R * KY), c.ring(cx, cy, R - 13, 1.2, ry=(R - 13) * KY))
    for i in range(10):
        a = i * TAU / 10 + 0.3 + seed
        m = np.maximum(m, cglyph(c, cx + np.cos(a) * (R - 6.5), cy + np.sin(a) * (R - 6.5) * KY, 7.5, seed * 13 + i, 1.3, 0.0))
    if col is None:      # 새긴 자국: 어두운 홈 + 밝은 턱
        c.paint(np.clip(np.roll(m, (2, 2), (0, 1)) - m, 0, 1), "#8a8478", 0.4)
        c.paint(m * (0.55 + 0.45 * (c.noise(6, seed + 2) > 0.3)), "#14100e", 0.85)
        return
    c.graded = False
    k = PULSE(f)
    sweep = 0.55 + 0.45 * np.cos(np.arctan2((c.yy - cy) / KY, c.xx - cx) - (f or 0) * 1.5708)
    c.paint(m, hexc(COL[col]) * 0.35, 0.8)
    c.glow(m, COL[col], 5.0, 0.75 * k)
    c.add(m * sweep, hexc(COL[col]) * 0.5 + 0.5, 0.95)
    c.add(sstep(1.0 - c.dist(cx, cy, R, R * KY), 0, 1.0), COL[col], 0.10 * k)
    c.origin = (cx, cy)


# ── 마법 에너지(튀는 줄기 · 흐르는 가닥) ─────────────────────────────────────

@flat("magic_energy", "special", layer="over", cell=(72, 128), tags=["magic", "animated"], name_ko="마법 에너지", fps=10,
    variants={"arc_blue": {"col": "blue", "frames": 4}, "arc_violet": {"col": "violet", "frames": 4}, "arc_red": {"col": "red", "frames": 4},
        "wisp_blue": {"col": "blue", "kind": "wisp", "frames": 4}, "wisp_violet": {"col": "violet", "kind": "wisp", "frames": 4}, "wisp_gold": {"col": "gold", "kind": "wisp", "frames": 4}},
    light=dict({"color": COL["blue"], "radius": 1.8, "at": (0, 0, 0.9), "flicker": 0.6}, **_lightvar([], {"arc_violet": "violet", "wisp_violet": "violet", "arc_red": "red", "wisp_gold": "gold"})),
    meta={"note": "arc = 아래에서 위로 튀는 번개 같은 줄기(장치 · 수정 위) · wisp = 꼬이며 오르는 부드러운 가닥(마력이 새는 곳)"})
def magic_energy(c, col="blue", kind="arc", f=0, seed=1):
    c.graded = False
    f = f or 0
    color = COL[col]
    if kind == "arc":
        m = np.zeros((c.H, c.W), F)
        for j in range(3):
            rng = np.random.default_rng(seed * 31 + f * 7 + j)
            x, pts = 36.0 + (j - 1) * 5, []
            top = rng.uniform(8, 40) if j else 6
            for y in np.linspace(122, top, 9):
                pts.append((x, y))
                x = np.clip(x + rng.uniform(-11, 11), 8, 64)
            m = np.maximum(m, c.seg(pts, 2.4 if j == 0 else 1.4, True))
        c.glow(m, color, 5.0, 0.7)
        c.add(m, hexc(color) * 0.3 + 0.7, 1.0)
        c.add(sstep(1.0 - c.dist(36, 120, 16, 7), 0, 0.8), color, 0.55)
    else:
        m = np.zeros((c.H, c.W), F)
        for j in range(3):
            ph = f * 1.5708 + j * 2.1 + seed
            pts = [(36 + np.sin(t * 5.0 + ph) * (5 + 13 * t) * (1 - 0.3 * j), 122 - t * 112) for t in np.linspace(0, 1, 14)]
            m = np.maximum(m, c.seg(pts, 4.5 - j, True, 1.4))
        fade = sstep(c.yy, 4, 60)
        c.add(gblur(m, 3.0) * fade, color, 0.5)
        c.add(m * fade * (0.6 + 0.4 * _cyc(c, 6, seed, f)), hexc(color) * 0.5 + 0.5, 0.8)
        rng = np.random.default_rng(seed + 9)
        for i in range(7):
            x, y = 36 + rng.uniform(-16, 16), (rng.uniform(10, 120) - f * 28 * (1 + i % 2)) % 116 + 6
            c.add(sstep(1.0 - c.dist(x, y, 1.6), 0, 0.7), "#ffffff", 0.8)
    c.origin = (36, 122)


# ── 작은 마력 구체 ───────────────────────────────────────────────────────────

@flat("mana_orb", "light", layer="over", cell=(56, 72), tags=["magic", "light", "animated"], name_ko="작은 마력 구체", fps=6,
    variants={k: {"col": k, "frames": 4} for k in ("blue", "violet", "red", "gold")},
    light=dict({"color": COL["blue"], "radius": 2.0, "at": (0, 0, 0.6), "flicker": 0.15}, **_lightvar([], {"violet": "violet", "red": "red", "gold": "gold"})),
    meta={"note": "제자리에 떠서 고리가 도는 빛 구슬(속심 + 빛 무리 + 도는 고리). 은빛 구체(light_orb)와 달리 떠오르지 않는다"})
def mana_orb(c, col="blue", f=0, seed=1):
    c.graded = False
    f = f or 0
    color = COL[col]
    cx, cy = 28.0, 30.0 + np.sin(f * 1.5708) * 1.5
    d = c.dist(cx, cy, 9.0)
    c.add(sstep(1.0 - d / 2.8, 0, 1) ** 2, color, 0.55 * PULSE(f))
    c.paint(sstep(1.0 - d, 0, 0.25), hexc(color) * 0.55, 0.95)
    swirl = _cyc(c, 5, seed, f) * sstep(1.0 - d, 0, 0.4)
    c.add(swirl, hexc(color) * 0.6 + 0.4, 0.7)
    c.add(sstep(1.0 - c.dist(cx - 2.5, cy - 2.5, 4.0), 0, 0.9), "#ffffff", 0.9)
    a0 = f * TAU / 8
    ring = c.ring(cx, cy, 13.5, 1.2, ry=4.5) * (0.35 + 0.65 * (np.cos(np.arctan2((c.yy - cy) * 3, c.xx - cx) - a0 * 2) > 0.2))
    c.add(ring * ((c.yy > cy) | (d > 1.0)), hexc(color) * 0.4 + 0.6, 0.9)
    c.add(sstep(1.0 - c.dist(28, 66, 9, 3.5), 0, 1), color, 0.3)       # 바닥에 비친 빛
    c.origin = (28, 66)


# ── 봉인 장막 ────────────────────────────────────────────────────────────────

def _glyph_band(c, cx, y, half, n, gid, size=8.0, scroll=0.0):
    m = np.zeros((c.H, c.W), F)
    for i in range(n):
        t = ((i + scroll) % n) / n * 2 - 1 + 1.0 / n
        x = cx + np.sin(t * 1.45) / np.sin(1.45) * half
        m = np.maximum(m, cglyph(c, x, y, size, gid + i, 1.3) * (0.4 + 0.6 * np.cos(t * 1.45)))
    return m


@flat("seal_barrier", "special", layer="stand", cell=(176, 168), collide=(1.9, 1.2), tags=["magic", "seal", "animated"], name_ko="봉인 장막", interact="seal", fps=5,
    variants={"blue": {"col": "blue", "frames": 4}, "gold": {"col": "gold", "frames": 4}, "violet": {"col": "violet", "frames": 4}, "breaking": {"col": "blue", "state": "breaking", "frames": 4}},
    light=dict({"color": COL["blue"], "radius": 2.6, "at": (0, 0, 0.8), "flicker": 0.1}, **_lightvar([], {"gold": "gold", "violet": "violet"})),
    meta={"states": {"idle": "blue", "active": "breaking"}, "note": "안의 것을 가둔 반투명 반구(지름 두 칸 반) — 허리에 글자 띠가 돈다. breaking = 금이 가며 깜박인다"})
def seal_barrier(c, col="blue", state="idle", f=0, seed=1):
    c.graded = False
    f = f or 0
    color = COL[col]
    cx, base, R = 88.0, 132.0, 78.0
    dome = np.where(c.yy < base, c.dist(cx, base, R, R * 1.45), c.dist(cx, base, R, R * KY * 0.42))
    inside = sstep(1.0 - dome, 0, 0.03)
    shell = sstep(1.0 - np.abs(dome - 0.97) / 0.05, 0, 1)
    k = PULSE(f) * (1.0 if state == "idle" else (0.45, 1.0, 0.3, 0.8)[f])
    c.add(inside * (0.25 + 0.75 * dome ** 3) * (0.7 + 0.3 * _cyc(c, 22, seed, f, 4, 2)), color, 0.34 * k)
    c.add(shell, hexc(color) * 0.6 + 0.4, 0.75 * k)
    foot = c.ring(cx, base, R, 2.2, ry=R * KY * 0.42)
    c.add(foot, hexc(color) * 0.5 + 0.5, 0.9 * k)
    c.add(gblur(foot, 4.0), color, 0.5 * k)
    band = _glyph_band(c, cx, base - 52, R * 0.93, 9, seed * 7, 9.0, f * 0.25) * inside
    c.add(np.maximum(band, (np.abs(c.yy - (base - 63)) < 0.7) * inside * 0.6 + (np.abs(c.yy - (base - 41)) < 0.7) * inside * 0.6), hexc(color) * 0.4 + 0.6, 0.85 * k)
    c.add(sstep(1.0 - c.dist(cx - 30, base - 80, 16, 30, rot=0.5), 0, 1) * inside, "#ffffff", 0.16 * k)   # 겉면 번들거림
    if state == "breaking":
        cr = c.cracks([(cx + 10, base - 70, a, 46 + f * 8) for a in (0.4, 1.9, 3.3, 4.6, 5.6)], 1.8) * inside
        c.paint(cr, "#060810", 0.6)
        c.add(gblur(cr, 1.5) * 1.5, "#ffffff", 0.9)
    c.origin = (cx, base)


@flat("seal_wall", "special", layer="stand", cell=(80, 176), collide=(1.0, 0.3), tags=["magic", "seal", "door", "animated"], name_ko="봉인된 길목(빛의 벽)", interact="seal", fps=5,
    variants={"blue": {"col": "blue", "frames": 4}, "gold": {"col": "gold", "frames": 4}, "red": {"col": "red", "frames": 4}, "breaking": {"col": "blue", "state": "breaking", "frames": 4}},
    light=dict({"color": COL["blue"], "radius": 2.2, "at": (0, 0, 1.0), "flicker": 0.1}, **_lightvar([], {"gold": "gold", "red": "red"})),
    meta={"tile_w": 1, "states": {"idle": "blue", "active": "breaking"}, "note": "문구멍 · 통로 한 칸을 막는 빛의 벽(문틀 doorway.open 안에 세운다)"})
def seal_wall(c, col="blue", state="idle", f=0, seed=1):
    c.graded = False
    f = f or 0
    color = COL[col]
    x0, x1, y0, y1 = 10.0, 70.0, 14.0, 164.0
    pane = c.rect(x0, y0, x1, y1, 1.5)
    k = PULSE(f) * (1.0 if state == "idle" else (0.45, 1.0, 0.3, 0.8)[f])
    flow = np.clip(0.5 + (c.noise(16, seed, 2) - 0.5) * 1.6 + 0.25 * np.sin((c.yy + f * 20) / 80 * TAU / 1.0), 0, 1)
    c.add(pane * (0.35 + 0.65 * flow), color, 0.36 * k)
    c.add(np.clip(pane - c.rect(x0 + 2.5, y0 + 2.5, x1 - 2.5, y1 - 2.5, 1.0), 0, 1), hexc(color) * 0.5 + 0.5, 0.9 * k)
    m = np.zeros((c.H, c.W), F)
    for i in range(5):
        m = np.maximum(m, cglyph(c, 40, 34 + i * 27, 11, seed * 5 + (i + f) % 5 + 20, 1.6))
    m = np.maximum(m, np.maximum(c.seg([(27, y0), (27, y1)], 1.0, False), c.seg([(53, y0), (53, y1)], 1.0, False)))
    c.add(m * pane, hexc(color) * 0.35 + 0.65, 0.85 * k)
    c.add(sstep(1.0 - c.dist(40, y1 + 2, 38, 7), 0, 1), color, 0.35 * k)
    if state == "breaking":
        cr = c.cracks([(40, 80, a, 40 + f * 7) for a in (0.5, 2.0, 3.6, 5.0)], 1.8) * pane
        c.paint(cr, "#060810", 0.6)
        c.add(gblur(cr, 1.5) * 1.5, "#ffffff", 0.9)
    c.origin = (40, y1)


# ── 마법진 파편 ──────────────────────────────────────────────────────────────

@flat("circle_fragments", "special", cell=(150, 112), tags=["magic", "ritual", "ruin"], name_ko="마법진 파편",
    variants={"dead_a": {"seed": 3}, "dead_b": {"seed": 11}, "faint_blue": {"seed": 3, "col": "blue", "frames": 4}, "faint_violet": {"seed": 11, "col": "violet", "frames": 4}},
    light=dict({"color": COL["blue"], "radius": 1.0, "at": (0, 0, 0.05), "flicker": 0.5}, **_lightvar(["faint_blue", "faint_violet"], {"faint_violet": "violet"})),
    meta={"note": "깨진 마법진의 남은 호 몇 토막과 흩어진 글자 — 지워지거나 부서진 의식 자리"})
def circle_fragments(c, col=None, f=0, seed=1):
    rng = np.random.default_rng(seed)
    cx, cy = 75.0, 56.0
    ang = np.arctan2((c.yy - cy) / KY, c.xx - cx)
    m = np.zeros((c.H, c.W), F)
    for R, w in ((64, 2.2), (50, 1.5)):
        keep = np.zeros((c.H, c.W), F)
        for _ in range(3):
            a0, span = rng.uniform(-np.pi, np.pi), rng.uniform(0.35, 0.9)
            keep = np.maximum(keep, sstep(span - np.abs(np.angle(np.exp(1j * (ang - a0)))), 0, 0.08))
        m = np.maximum(m, c.ring(cx, cy, R, w, ry=R * KY) * keep)
    for i in range(7):
        a = rng.uniform(0, TAU)
        r = rng.uniform(20, 60)
        m = np.maximum(m, cglyph(c, cx + np.cos(a) * r, cy + np.sin(a) * r * KY, 8, seed + i, 1.3, rng.uniform(-0.6, 0.6)) * rng.uniform(0.5, 1.0))
    m = m * (0.4 + 0.6 * (c.noise(7, seed + 4) > 0.3))
    smear = c.blob(cx + rng.uniform(-20, 20), cy + rng.uniform(-10, 10), 34, 16, 0.5, 14, 0.4, rng.uniform(0, 3))    # 발로 문질러 지운 자리
    m = m * (1 - smear * 0.85)
    if col is None:
        c.paint(smear * 0.6, "#8c8678", 0.16)
        c.paint(gblur(m, 1.5) * 0.6, "#9a9284", 0.3)
        c.paint(m, "#bcb4a0", 0.8)
        return
    c.graded = False
    flick = 0.35 + 0.65 * (_cyc(c, 18, seed, f) > 0.45)
    c.paint(m, hexc(COL[col]) * 0.3, 0.75)
    c.glow(m * flick, COL[col], 4.0, 0.45)
    c.add(m * flick, hexc(COL[col]) * 0.6 + 0.4, 0.7)


# ── 신비로운 빛(빛기둥) ──────────────────────────────────────────────────────

@flat("light_shaft", "light", layer="over", cell=(112, 232), tags=["light", "magic", "animated"], name_ko="신비로운 빛기둥", fps=4,
    variants={"warm": {"col": "#f0d8a0", "frames": 4}, "pale": {"col": "#d8e0ec", "frames": 4}, "blue": {"col": COL["blue"], "frames": 4}, "narrow": {"col": "#f0d8a0", "narrow": True, "frames": 4}},
    light={"color": "#f0d8a0", "radius": 2.4, "at": (0, 0, 0.2), "flicker": 0.05, "colors": {"pale": "#d8e0ec", "blue": COL["blue"]}},
    meta={"note": "위에서 비스듬히 내려와 바닥에 고이는 빛 한 줄기 — 천장 틈 · 높은 창 · 성물 위. 먼지 알갱이가 떠 있다"})
def light_shaft(c, col="#f0d8a0", narrow=False, f=0, seed=1):
    c.graded = False
    f = f or 0
    cx, base = 56.0, 204.0
    t = np.clip((base - c.yy) / base, 0, 1)                     # 0 바닥 → 1 꼭대기
    half = (30 - 16 * t) * (0.55 if narrow else 1.0)
    axis = cx + t * 14                                           # 조금 기울었다
    beam = sstep(1.0 - np.abs(c.xx - axis) / half, 0, 0.9) * (c.yy < base) * sstep(c.yy, 0, 40)
    streak = 0.65 + 0.35 * np.sin((c.xx - axis) / half * 7 + seed) * (0.6 + 0.4 * _cyc(c, 40, seed, f, 4, 1))
    c.add(beam * streak, col, 0.3 * PULSE(f))
    pool = sstep(1.0 - c.dist(cx, base, (34 if not narrow else 20), 13), 0, 0.8)
    c.add(pool, col, 0.5)
    c.add(sstep(1.0 - c.dist(cx, base, 16, 6), 0, 1), "#ffffff", 0.25)
    rng = np.random.default_rng(seed + 5)
    for i in range(14):
        tt = rng.uniform(0.05, 0.9)
        x = cx + tt * 14 + rng.uniform(-1, 1) * (26 - 14 * tt) * (0.55 if narrow else 1.0) + np.sin(f * 1.5708 + i) * 1.5
        y = base - tt * base + np.cos(f * 1.5708 + i * 1.7) * 2.0
        c.add(sstep(1.0 - c.dist(x, y, 1.3), 0, 0.7) * (0.4 + 0.6 * ((i + f) % 3 != 0)), "#ffffff", 0.8)
    c.origin = (cx, base)


# ── 낱 불꽃 ──────────────────────────────────────────────────────────────────

def _flame_img(w, h, base_y, fh, seed, f, pal="fire", width=0.42, glow=2.2, strength=0.5, lean=0.0):
    img = fx.flame(np.zeros((h, w, 4), np.uint8), w / 2.0, base_y, fh, seed, f or 0, pal, width, glow, strength)
    if lean:      # 바람: 위로 갈수록 옆으로 민다
        out = np.zeros_like(img)
        for y in range(h):
            s = int(round(lean * max(0.0, base_y - y) * (1.0 + 0.25 * np.sin((f or 0) * 1.57 + y * 0.2))))
            out[y] = np.roll(img[y], s, 0)
        img = out
    return img


@flat("flame", "fx", layer="over", cell=(112, 150), tags=["fire", "animated"], name_ko="불꽃(낱 효과)",
    variants={"small": {"fh": 22, "frames": 4}, "medium": {"fh": 40, "frames": 4}, "large": {"fh": 68, "frames": 4}, "wide": {"fh": 40, "width": 0.7, "frames": 4}, "blue": {"fh": 40, "pal": "blue", "frames": 4}},
    light={"color": "#f0a040", "radius": 3.0, "at": (0, 0, 0.4), "flicker": 0.35, "colors": {"blue": COL["blue"]}},
    meta={"note": "물건 위에 얹는 불꽃만(받침 없음) — 불붙은 가구 · 잔해 · 화덕 속. small 반 칸 · medium 한 칸 · large 한 칸 반 · wide 바닥에 번진 불"})
def flame(c, fh=40, pal="fire", width=0.42, f=0, seed=1):
    c.origin = (56, 132)
    return _flame_img(112, 150, 132, fh, seed, f, pal, width, 1.6 if fh > 50 else 2.2)


@flat("candle_flame", "fx", layer="over", cell=(28, 36), tags=["fire", "animated"], name_ko="촛불 불꽃",
    variants={"steady": {"frames": 4}, "guttering": {"gutter": True, "frames": 4}}, light={"color": "#f0b860", "radius": 1.6, "at": (0, 0, 0.1), "flicker": 0.2},
    meta={"note": "양초 · 등잔 심지 위에 얹는 작은 불꽃(높이 9px). guttering = 꺼질 듯 흔들린다"})
def candle_flame(c, gutter=False, f=0, seed=1):
    c.origin = (14, 28)
    f = f or 0
    return _flame_img(28, 36, 28, (9, 6, 10, 4)[f] if gutter else 9 + (f % 2), seed, f, "fire", 0.34, 1.5, 0.45, (0.25, -0.2, 0.1, 0.35)[f] if gutter else 0.0)


@flat("torch_flame", "fx", layer="over", cell=(84, 96), tags=["fire", "animated"], name_ko="횃불 불꽃",
    variants={"steady": {"frames": 4}, "windblown": {"lean": 0.42, "frames": 4}, "dying": {"fh": 13, "frames": 4}}, light={"color": "#f0a040", "radius": 3.2, "at": (0, 0, 0.3), "flicker": 0.4},
    meta={"note": "횃불 머리에 얹는 불꽃 — 꺼진 횃불(torch_wall.unlit · torch_stand.unlit) 위에 놓아 켠다. windblown = 바람에 눕는다(바깥 · 통로)"})
def torch_flame(c, fh=30, lean=0.0, f=0, seed=1):
    c.origin = (42, 84)
    img = _flame_img(84, 96, 84, fh, seed + 2, f, "fire", 0.5, 2.0, 0.5, lean)
    if fh > 20:
        img = fx.puff(img, 42 + lean * 60, 84 - fh * 1.5, 7, "#4a4642", 0.3, seed, f or 0, 12, 4)
    return img


# ── 연기 ─────────────────────────────────────────────────────────────────────

_SMOKE = {"wisp": ("#9a968e", 0.4, 5, 5), "column": ("#6e6a66", 0.6, 12, 9), "black": ("#1e1c1c", 0.72, 13, 9), "chimney": ("#8a8680", 0.55, 10, 7)}


@flat("smoke", "fx", layer="over", cell=(96, 176), tags=["smoke", "animated"], name_ko="연기", fps=5, variants={k: {"kind": k, "frames": 4} for k in _SMOKE},
    meta={"note": "wisp 가는 연기(꺼진 초 · 향 · 식는 재) · column 굵은 연기(모닥불 · 화덕) · black 검은 연기(불난 집 · 기름) · chimney 바람에 눕는 굴뚝 연기"})
def smoke(c, kind="column", f=0, seed=1):
    c.graded = False
    f = f or 0
    color, alpha, r0, n = _SMOKE[kind]
    m = np.zeros((c.H, c.W), F)
    lean = 30.0 if kind == "chimney" else 0.0
    for i in range(n):
        t = ((i + f * 0.25) % n) / n                              # 덩이가 프레임마다 한 칸씩 올라 4프레임 뒤 다음 덩이 자리
        x = 48 - lean * 0.5 + np.sin(t * 6.0 + i * 1.9 + seed) * (3 + 12 * t) + lean * t ** 1.3
        y = 166 - t * 150
        r = r0 * (0.6 + 1.5 * t)
        m = np.maximum(m, sstep(1.0 - c.dist(x, y, r * (1.25 if lean else 1.0), r), 0, 0.8) * (1.0 - t) ** 0.7 * sstep(t, 0, 0.08))
    m = m * (0.6 + 0.6 * _cyc(c, max(4, r0), seed, f, 4, 2))
    c.paint(gblur(m, 1.2), color, alpha)
    c.paint(gblur(m, 1.0) * sstep(c.noise(r0 * 1.2, seed + 3) - 0.5, 0, 0.2), hexc(color) * 1.35, alpha * 0.4)   # 빛 받은 쪽
    c.origin = (48 - lean * 0.5, 168)


# ── 먼지 구름 ────────────────────────────────────────────────────────────────

@flat("dust_puff", "fx", layer="over", cell=(112, 72), tags=["dust", "animated"], name_ko="먼지 구름", fps=10,
    variants={"impact": {"frames": 4}, "step": {"size": 0.45, "frames": 4}, "crumble": {"fall": True, "frames": 4}},
    meta={"loop": False, "note": "한 번 피어오르고 사라지는 먼지(되풀이하지 않는다). impact 무너짐 · 떨어진 물건 · step 발밑 · crumble 위에서 부스러기가 흘러내린다"})
def dust_puff(c, size=1.0, fall=False, f=0, seed=1):
    c.graded = False
    f = f or 0
    t = (f + 1) / 4.0
    cx, cy = 56.0, 58.0
    rng = np.random.default_rng(seed + 2)
    m = np.zeros((c.H, c.W), F)
    for i in range(9):
        a = rng.uniform(np.pi, TAU)
        d = rng.uniform(8, 40) * size * t ** 0.6
        r = rng.uniform(7, 13) * size * (0.6 + 0.6 * t)
        m = np.maximum(m, sstep(1.0 - c.dist(cx + np.cos(a) * d, cy + np.sin(a) * d * 0.5 - t * 6 * size, r, r * 0.8), 0, 0.8))
    m = m * (0.6 + 0.5 * c.noise(6 * size + 2, seed + f)) * (1.15 - t) / 0.9
    c.paint(gblur(m, 1.0), "#9a907c", 0.55)
    c.paint(m * sstep(c.noise(5, seed + 9) - 0.55, 0, 0.2), "#c2b8a0", 0.3)
    if fall:
        for i in range(12):
            x = cx + rng.uniform(-30, 30)
            y = (rng.uniform(0, 50) + f * 14) % 56
            c.paint(c.seg([(x, y), (x + 0.5, y + rng.uniform(3, 7))], rng.uniform(1.0, 2.0), False), "#7a7264", 0.8)
    c.origin = (cx, cy + 6)


# ── 빛 알갱이 ────────────────────────────────────────────────────────────────

_MOTE = {"warm": ("#ffd890", "#e0a040", 16, 1.5), "firefly": ("#d8f090", "#80c040", 10, 1.7), "spore": ("#e0e4d0", "#8aa08a", 26, 1.0)}


@flat("light_motes", "fx", layer="over", cell=(128, 128), tags=["particle", "light", "animated"], name_ko="빛 알갱이", fps=4, variants={k: {"kind": k, "frames": 4} for k in _MOTE},
    meta={"tile": [128, 128], "loop": True, "note": "2 × 2칸을 덮는 한 장. 제자리에서 느리게 맴돌며 깜박인다(흩날리는 입자 drift와 달리 흐르지 않고 스스로 빛난다). warm 등불 곁 먼지 빛 · firefly 반딧불 · spore 포자 · 꽃가루"})
def light_motes(c, kind="warm", f=0, seed=1):
    c.graded = False
    f = f or 0
    core, halo, n, size = _MOTE[kind]
    rng = np.random.default_rng(seed + len(kind) * 3)
    for i in range(n):
        x0, y0, r, ph = rng.uniform(6, 122), rng.uniform(6, 122), size * rng.uniform(0.7, 1.3), rng.uniform(0, TAU)
        x, y = x0 + np.cos(f * 1.5708 + ph) * 3.0, y0 + np.sin(f * 1.5708 + ph) * 2.0
        tw = 0.25 + 0.75 * (0.5 + 0.5 * np.sin(f * 1.5708 + ph * 3)) if kind != "spore" else 0.7
        d = c.dist(x, y, r)
        c.add(sstep(1.0 - d / 3.4, 0, 1) ** 2, halo, 0.6 * tw)
        c.add(sstep(1.0 - d, 0, 0.7), core, tw)
    c.origin = (64, 64)


# ── 물방울 · 물 표면 ─────────────────────────────────────────────────────────

@flat("water_drip", "fx", layer="over", cell=(40, 150), tags=["water", "animated"], name_ko="떨어지는 물방울", fps=8,
    variants={"fall": {"frames": 4}, "splash": {"kind": "splash", "frames": 4}, "trickle": {"kind": "trickle", "frames": 4}},
    meta={"note": "fall = 위에서 떨어지는 방울(두 칸 높이) → 이어서 splash(바닥에 튀는 고리 — 원점이 떨어진 자리) · trickle = 가늘게 이어 떨어지는 줄기(새는 지붕 · 종유석)"})
def water_drip(c, kind="fall", f=0, seed=1):
    c.graded = False
    f = f or 0
    cx, base = 20.0, 138.0
    if kind == "fall":
        y = 8 + (f / 3.0) ** 1.7 * (base - 16)
        ln = 3 + f * 3.5
        c.paint(c.seg([(cx, y - ln), (cx, y)], 2.0, False), "#6a8088", 0.55)
        c.paint(sstep(1.0 - c.dist(cx, y, 2.2, 2.8), 0, 0.6), "#9ab0b8", 0.9)
        c.add(sstep(1.0 - c.dist(cx - 0.6, y - 0.8, 0.9), 0, 0.8), "#ffffff", 0.9)
    elif kind == "splash":
        r = 3 + f * 4.0
        c.paint(c.ring(cx, base, r, 1.4, ry=r * 0.45), "#a8bcc4", 0.8 * (1 - f * 0.22))
        if f < 3:
            for a in (-2.3, -1.57, -0.85):
                h = (10, 15, 8)[f]
                x, y = cx + np.cos(a) * (3 + f * 3), base + np.sin(a) * h
                c.paint(sstep(1.0 - c.dist(x, y, 1.4 - f * 0.2), 0, 0.7), "#b8ccd4", 0.9)
        if f == 0:
            c.paint(c.seg([(cx, base - 12), (cx, base - 2)], 2.4, True), "#b8ccd4", 0.85)
    else:
        for i in range(6):
            y = (i * 24 + f * 6) % 132 + 4
            c.paint(c.seg([(cx, y), (cx, y + 13)], 1.6, False), "#8aa0a8", 0.6)
            c.add(c.seg([(cx - 0.4, y + 2), (cx - 0.4, y + 7)], 0.7, False), "#ffffff", 0.6)
        r = 4 + (f % 2) * 3
        c.paint(c.ring(cx, base, r, 1.2, ry=r * 0.45), "#a8bcc4", 0.7)
    c.origin = (cx, base)


@flat("water_ripple", "fx", layer="decal", cell=(112, 80), tags=["water", "animated"], name_ko="잔물결 고리", fps=5,
    variants={"single": {"frames": 4}, "double": {"n": 2, "frames": 4}, "rain": {"n": 6, "frames": 4}},
    meta={"note": "물 타일 · 웅덩이 위에 덧얹는 고리만(물 그림 없음). single 한 점에서 퍼진다 · double 두 겹 · rain 빗방울 여럿"})
def water_ripple(c, n=1, f=0, seed=1):
    c.graded = False
    f = f or 0
    rng = np.random.default_rng(seed)
    cx, cy = 56.0, 40.0
    spots = [(cx, cy, 0)] if n == 1 else [(cx - 12, cy - 4, 0), (cx + 16, cy + 6, 2)] if n == 2 else [(rng.uniform(14, 98), rng.uniform(12, 68), int(rng.integers(4))) for _ in range(n)]
    big = 1.0 if n < 3 else 0.42
    for x, y, ph in spots:
        for j in range(2 if n < 3 else 1):
            t = ((f + ph + j * 2) % 4 + 1) / 4.0
            r = 44 * big * t
            ring = c.ring(x, y, r, 1.5, ry=r * 0.55)
            lit = 0.5 + 0.5 * np.clip((c.xx - x + c.yy - y) / max(r, 1), -1, 1)
            c.paint(ring * (1 - lit), "#05080a", 0.5 * (1.1 - t))
            c.add(ring * lit, "#b4c4cc", 0.6 * (1.1 - t))
    c.origin = (cx, cy)


@flat("water_glint", "fx", layer="decal", cell=(128, 40), tags=["water", "animated"], name_ko="물 반짝임", fps=5,
    variants={"day": {"frames": 4}, "day_b": {"seed": 6, "frames": 4}, "moon": {"col": "#c4d4f0", "frames": 4}, "torch": {"col": "#f0b060", "frames": 4}},
    meta={"note": "물 위에 가로로 놓는 반짝임 띠(두 칸) — 수로 · 분수 · 강. moon 달빛 · torch 불빛이 비친 물"})
def water_glint(c, col="#e8f0f0", f=0, seed=1):
    c.graded = False
    f = f or 0
    rng = np.random.default_rng(seed + 4)
    env = sstep(1.0 - c.dist(64, 20, 62, 17), 0, 0.6)
    for i in range(22):
        x, y, ln = rng.uniform(6, 122), rng.uniform(5, 35), rng.uniform(3, 11)
        on = ((i + f * (1 + i % 2)) % 4) < 2
        if on:
            m = c.seg([(x - ln / 2, y), (x + ln / 2, y)], 1.3, False) * env
            c.add(gblur(m, 1.0), col, 0.35)
            c.add(m, hexc(col) * 0.5 + 0.5, 0.85)
    c.origin = (64, 20)


# ── 빛의 흔들림 ──────────────────────────────────────────────────────────────

@flat("light_flicker", "fx", layer="decal", cell=(208, 150), tags=["light", "fire", "animated"], name_ko="일렁이는 불빛(바닥)", fps=7,
    variants={"fire": {"frames": 4}, "candle": {"size": 0.45, "col": "#f0c070", "frames": 4}, "cold": {"col": "#90b8e8", "frames": 4}, "forge": {"col": "#f07030", "size": 0.8, "frames": 4}},
    meta={"note": "광원 아래 바닥에 까는 빛 웅덩이 — 밝기와 가장자리가 4프레임으로 흔들린다(빛 계산 없이 불빛 느낌만 낼 때). fire 모닥불 · 횃불 · candle 촛불 · cold 마법등 · forge 화덕"})
def light_flicker(c, col="#f0a850", size=1.0, f=0, seed=1):
    c.graded = False
    f = f or 0
    cx, cy = 104.0, 75.0
    k = (1.0, 0.86, 0.95, 0.8)[f]
    d = c.dist(cx, cy, 98 * size * (0.94 + 0.06 * k), 70 * size * (0.94 + 0.06 * k)) + (_cyc(c, 30, seed, f, 4, 2) - 0.5) * 0.16
    c.add(sstep(1.0 - d, 0, 1.0) ** 1.5, col, 0.42 * k)
    c.add(sstep(1.0 - d * 2.2, 0, 1.0), hexc(col) * 0.5 + 0.5, 0.2 * k)
    c.origin = (cx, cy)


@flat("window_light", "fx", layer="decal", cell=(128, 168), tags=["light", "window"], name_ko="창으로 든 빛(바닥)",
    variants={"day": {}, "moon": {"col": "#a8bce0", "k": 0.3}, "arched": {"arched": True}, "dusty": {"frames": 4}},
    meta={"note": "창 아래 바닥에 비스듬히 떨어진 빛 — 창살 그림자로 칸이 나뉜다. arched = 둥근 머리 창 · dusty = 빛 속 먼지가 깜박인다(4프레임)"})
def window_light(c, col="#f0e0b0", k=0.36, arched=False, f=0, seed=1):
    c.graded = False
    f = f or 0
    u, v = (c.xx - 26 - (c.yy - 10) * 0.3) / 62.0, (c.yy - 10) / 146.0      # 비스듬한 네모 안 좌표 0~1
    inside = sstep(np.minimum(np.minimum(u, 1 - u) * 62, np.minimum(v, 1 - v) * 146), 0, 5)
    if arched:
        inside = inside * sstep(1.0 - np.hypot((u - 0.5) * 2, np.clip(0.22 - v, 0, 1) / 0.22), 0, 0.1)
    bars = np.minimum(np.abs((u * 2) % 1.0 - 0.5) * 31, np.abs((v * 3) % 1.0 - 0.5) * 49)
    bars = sstep(bars, 13.5, 11.0) if False else 1.0 - sstep(np.minimum(np.abs(u - 0.5) * 62, np.minimum(np.abs(v - 1 / 3.0), np.abs(v - 2 / 3.0)) * 146), 1.5, 4.5)
    m = gblur(inside * (1 - bars), 1.6 + 0.0) * (0.75 + 0.25 * v)
    c.add(m * (0.85 + 0.15 * c.noise(20, seed)), col, k)
    if f or "dusty":
        rng = np.random.default_rng(seed + 3)
        for i in range(10):
            x, y = rng.uniform(34, 110), rng.uniform(20, 150)
            c.add(sstep(1.0 - c.dist(x + np.sin(f * 1.57 + i) * 1.5, y, 1.1), 0, 0.7) * m * 3 * ((i + f) % 3 != 0), "#ffffff", 0.6)
    c.origin = (64, 84)
