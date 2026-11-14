"""환경 연출(에셋 라이브러리 — docs/asset_library): 그림 몇 장이 도는 가벼운 효과. 입자 계산 없이 4프레임 그림만 — 화면에 보이는 곳에만 놓는다.
안개(잿빛 · 검은 · 보랏빛 · 푸른) · 떠오르는 은빛 구체 · 흩날리는 입자(눈 · 불티 · 재 · 먼지) · 차원 균열 · 붉은 빛기둥 · 벼락 · 즉사 함정 타일.
모두 평면 그림(@flat). 색 정리를 끄고(c.graded = False) 빛을 더한다."""
import numpy as np

from a_light import GLOWC
from kit import F, flat
from paint2d import gblur, hexc, sstep

TAU = 2 * np.pi


def _cyc(c, scale, seed, f, n=4, octaves=2):
    """n프레임에 한 바퀴 도는 잡음(0~1)."""
    a = TAU * (f or 0) / n
    return np.clip(0.5 + (c.noise(scale, seed, octaves) - 0.5) * np.cos(a) + (c.noise(scale, seed + 53, octaves) - 0.5) * np.sin(a), 0, 1)


# ── 안개 ─────────────────────────────────────────────────────────────────────

_MIST = {"grey": ("#8a8c8a", 0.34), "black": ("#141216", 0.5), "violet": ("#7a5aa8", 0.36), "blue": ("#6a9ac8", 0.34)}


@flat("mist", "fx", layer="over", cell=(224, 112), tags=["fog", "animated"], name_ko="안개", fps=3,
    variants=dict({k: {"col": k, "frames": 4} for k in _MIST}, **{"grey_b": {"col": "grey", "frames": 4, "seed": 9}, "black_b": {"col": "black", "frames": 4, "seed": 9}}),
    meta={"note": "낮게 깔린 안개 한 자락 — 겹쳐 놓으면 짙어진다. black = 바람에도 흩어지지 않는 검은 안개 · violet = 보랏빛 안개 · blue = 보석에서 퍼지는 빛 안개"})
def mist(c, col="grey", f=0, seed=1):
    c.graded = False
    color, alpha = _MIST[col]
    edge = sstep(1.0 - c.dist(c.w / 2, c.h / 2, c.w * 0.5, c.h * 0.5), 0.0, 0.55)
    n = _cyc(c, 30, seed, f, 4, 3) * 0.65 + _cyc(c, 11, seed + 7, (f or 0) + 1, 4, 2) * 0.35
    m = np.clip((n - 0.34) * 2.2, 0, 1) * edge
    c.paint(gblur(m, 3.0), color, alpha)
    if col in ("violet", "blue"):
        c.add(gblur(m, 6.0) * np.clip(n - 0.5, 0, 1), GLOWC[col], 0.5)
    c.origin = (c.w / 2, c.h * 0.75)


# ── 떠오르는 은빛 구체 ───────────────────────────────────────────────────────

@flat("light_orb", "fx", layer="over", cell=(40, 72), tags=["light", "animated", "silver"], name_ko="은빛 구체", reuse="region", fps=4,
    variants={"rise": {"frames": 4}, "rise_b": {"frames": 4, "seed": 7}, "cluster": {"frames": 4, "n": 3, "seed": 4}},
    light={"color": "#d0d8e4", "radius": 1.6, "at": (0, 0, 0.6), "flicker": 0.1}, meta={"note": "땅에서 민들레씨처럼 떠올라 천장으로 사라지는 빛 — 놓는 쪽에서 위로 움직이며 프레임을 돌린다"})
def light_orb(c, n=1, f=0, seed=1):
    c.graded = False
    rng = np.random.default_rng(seed)
    for i in range(n):
        x = c.w / 2 + (rng.uniform(-10, 10) if n > 1 else 0) + np.sin((f or 0) * 1.5708 + i * 2.0) * 1.6
        y = c.h * 0.42 + (rng.uniform(-14, 18) if n > 1 else 0) - (f or 0) * 0.8
        r = rng.uniform(2.6, 3.6)
        d = c.dist(x, y, r)
        tail = sstep(1.0 - c.dist(x, y + r * 3.2, r * 0.7, r * 3.4), 0, 0.8)           # 아래로 끌리는 빛 꼬리
        c.add(tail, "#9aa6b8", 0.3)
        c.add(sstep(1.0 - d / 3.4, 0, 1), "#aab8cc", 0.55 + 0.1 * np.sin((f or 0) * 1.5708 + i))
        c.add(sstep(1.0 - d, 0, 0.5), "#f4f8ff", 1.0)
    c.origin = (c.w / 2, c.h - 4)


# ── 흩날리는 입자 ────────────────────────────────────────────────────────────

_DRIFT = {"snow": ("#e8f0f8", 1.6, (2.0, 6.0), 70, 0.9), "ember": ("#ffa040", 1.3, (-1.0, -7.0), 34, 1.0), "ash": ("#6a6664", 1.5, (1.5, 3.0), 50, 0.75), "dust": ("#b8a888", 0.9, (1.0, -0.6), 40, 0.5), "frost": ("#c8e4f8", 1.0, (0.5, 2.5), 60, 0.8)}


@flat("drift", "fx", layer="over", cell=(128, 128), tags=["particle", "weather", "animated"], name_ko="흩날리는 입자", fps=6, variants={k: {"kind": k, "frames": 4} for k in _DRIFT},
    meta={"tile": [128, 128], "loop": True, "note": "2 × 2칸을 덮는 한 장 — 사방으로 이어지고 4프레임이 돈다. snow 눈 · frost 얼음 가루 · ember 불티 · ash 재 · dust 먼지. 화면에 보이는 칸에만 깐다"})
def drift(c, kind="snow", f=0, seed=1):
    c.graded = False
    color, size, (vx, vy), n, alpha = _DRIFT[kind]
    rng = np.random.default_rng(seed + len(kind))
    for i in range(n):
        x0, y0, r = rng.uniform(0, 128), rng.uniform(0, 128), size * rng.uniform(0.6, 1.4)
        k = int(rng.integers(1, 3))                       # 프레임마다 정수 배 걸음 → 4프레임 뒤 제자리(이어진다)
        x = (x0 + (f or 0) * 32 * k * np.sign(vx if vx else 1) * (abs(vx) > 1.2) + np.sin((f or 0) * 1.5708 + i) * abs(vx) * 2) % 128
        y = (y0 + (f or 0) * 32 * k * np.sign(vy)) % 128
        tw = 0.6 + 0.4 * np.sin((f or 0) * 1.5708 + i * 1.3)
        for dx in (-128, 0, 128):
            for dy in (-128, 0, 128):
                if -4 < x + dx < 132 and -4 < y + dy < 132:
                    d = c.dist(x + dx, y + dy, r, r * (1.0 + 0.8 * (kind in ("snow", "ember", "frost"))))
                    if kind == "ember":
                        c.add(sstep(1.0 - d / 2.6, 0, 1), "#c03a10", 0.5 * tw)
                    c.add(sstep(1.0 - d, 0, 0.7), color, alpha * tw)
    c.origin = (64, 64)


# ── 차원 균열 ────────────────────────────────────────────────────────────────

@flat("collapse_crack", "fx", layer="over", cell=(160, 160), tags=["rift", "magic", "animated"], name_ko="퍼지는 공간 균열(차원 붕괴)", fps=4,
    variants={"seed": {"stage": 0, "frames": 4}, "spread": {"stage": 1, "frames": 4}, "web": {"stage": 2, "frames": 4}, "web_b": {"stage": 2, "frames": 4, "seed": 9}},
    light={"color": GLOWC["violet"], "radius": 2.5, "at": (0, 0, 0.8), "flicker": 0.3}, meta={"states": {"idle": "seed", "active": "spread", "spent": "web"}, "note": "허공에 작게 피어나(seed) 거미줄처럼 퍼지는(spread → web) 균열"})
def collapse_crack(c, stage=0, f=0, seed=1):
    c.graded = False
    rng = np.random.default_rng(seed + 3)
    cx, cy = 80.0, 80.0
    n, ln = ((4, 16), (7, 38), (11, 66))[stage]
    starts = [(cx + rng.uniform(-3, 3), cy + rng.uniform(-3, 3), a + rng.uniform(-0.3, 0.3), ln * rng.uniform(0.6, 1.0)) for a in np.linspace(0, TAU, n, endpoint=False)]
    m = c.cracks(starts, 1.6 + stage * 0.5)
    if stage == 2:        # 거미줄: 가지 사이를 잇는 고리
        for r in (22, 44):
            ring = c.ring(cx, cy, r, 1.2) * (c.noise(9, seed + r) > 0.42)
            m = np.maximum(m, ring * sstep(gblur(m, 6.0), 0.01, 0.06))
    k = 0.75 + 0.25 * np.sin((f or 0) * 1.5708)
    c.paint(np.clip(gblur(m, 1.2) * 2.0, 0, 1), "#0a0610", 0.9)                          # 갈라진 틈 속 어둠
    c.glow(m, GLOWC["violet"], 5.0, 0.55 * k)
    flick = 0.55 + 0.45 * (c.noise(14, seed + 20 + (f or 0)) > 0.45)
    c.add(m * flick, "#e0d0ff", 0.9)
    c.origin = (cx, cy)


# ── 붉은 빛기둥 · 벼락(운석 낙하의 앞뒤) ─────────────────────────────────────

@flat("red_beam", "fx", layer="decal", cell=(256, 176), tags=["meteor", "warning", "animated"], name_ko="붉은 빛(낙하 예고)", reuse="region", fps=4, variants={"pulse": {"frames": 4}},
    light={"color": "#e04848", "radius": 4.0, "at": (0, 0, 0.3), "flicker": 0.2}, meta={"note": "위에서 쏟아지는 붉은 빛이 덮은 자리 — 곧 무언가 떨어진다는 표시(바닥에 깐다). 뒤에 crater"})
def red_beam(c, f=0, seed=1):
    c.graded = False
    cx, cy = c.w / 2, c.h / 2
    d = c.dist(cx, cy, 120, 80)
    k = 0.7 + 0.3 * np.sin((f or 0) * 1.5708)
    c.add(sstep(1.0 - d, 0, 0.5) * (0.75 + 0.25 * c.noise(18, seed + (f or 0))), "#b02820", 0.42 * k)
    c.add(sstep(1.0 - np.abs(d - 0.93) / 0.05, 0, 1), "#ff7060", 0.5 * k)                  # 빛의 테
    c.add(sstep(1.0 - np.abs(d - (0.25 + 0.2 * (f or 0))) / 0.03, 0, 1) * (d < 0.9), "#e04848", 0.35)   # 안에서 퍼져 나가는 고리
    c.origin = (cx, cy)


@flat("lightning", "fx", layer="over", cell=(96, 256), tags=["meteor", "storm", "animated"], name_ko="벼락 줄기", reuse="region", fps=10, variants={"strike": {"frames": 3}, "strike_b": {"frames": 3, "seed": 8}},
    light={"color": "#c8d8ff", "radius": 5.0, "at": (0, 0, 1.0), "flicker": 0.8})
def lightning(c, f=0, seed=1):
    c.graded = False
    rng = np.random.default_rng(seed)
    x, pts = 48.0, []
    for y in np.linspace(0, 250, 16):
        pts.append((x, y))
        x = np.clip(x + rng.uniform(-13, 13), 14, 82)
    pts[-1] = (48.0, 250.0)
    m = c.seg(pts, (3.2, 2.2, 1.0)[f or 0], False)
    for i in (4, 8, 11):      # 곁가지
        bx, by = pts[i]
        m = np.maximum(m, c.seg([(bx, by), (bx + rng.uniform(-22, 22), by + 18), (bx + rng.uniform(-30, 30), by + 34)], 1.6))
    k = (1.0, 0.7, 0.3)[f or 0]
    c.glow(m, "#8aa8ff", 7.0, 0.7 * k)
    c.add(m, "#f0f6ff", k)
    c.add(sstep(1.0 - c.dist(48, 250, 30, 12), 0, 0.8), "#c8d8ff", 0.6 * k)                # 떨어진 자리의 섬광
    c.origin = (48, 250)


# ── 즉사 함정 타일(심연의 문 앞) ─────────────────────────────────────────────

@flat("death_tile", "trap", layer="decal", cell=(64, 64), tags=["trap", "floor", "instant"], name_ko="즉사 함정 타일", reuse="region", interact="trap",
    variants={"hidden": {}, "hidden_b": {"seed": 7}, "revealed": {"state": "revealed"}, "armed": {"state": "armed", "frames": 4}, "sprung": {"state": "sprung"}},
    light={"color": "#e04848", "radius": 1.2, "at": (0, 0, 0.05), "flicker": 0.3, "variants": ["armed"]},
    meta={"tile": [64, 64], "states": {"idle": "hidden", "active": "armed", "spent": "sprung"}, "note": "한 칸 바닥 판. hidden = 둘레 바닥과 거의 같다(줄눈이 조금 깊을 뿐) · revealed = 찾아낸 표시 · armed = 밟는 순간 · sprung = 터진 뒤"})
def death_tile(c, state="hidden", f=0, seed=1):
    plate = c.rect(3, 3, 61, 61, 0.8)
    seam = np.clip(plate - c.rect(5.5, 5.5, 58.5, 58.5, 0.8), 0, 1)
    c.paint(seam, "#0c0a0a", 0.55 if state == "hidden" else 0.9)                            # 판 둘레 줄눈
    if state == "hidden":
        c.paint(c.rect(5.5, 5.5, 58.5, 58.5) * (c.noise(10, seed) - 0.45).clip(0, 1), "#141012", 0.25)
        return
    inner = c.rect(5.5, 5.5, 58.5, 58.5)
    mark = np.maximum(c.ring(32, 32, 15, 2.0), np.maximum(c.seg([(21, 21), (43, 43)], 2.0, False), c.seg([(43, 21), (21, 43)], 2.0, False)))   # 새겨진 표식(고리 + 엇갈린 금)
    if state == "revealed":
        c.paint(inner * 0.3, "#2a2224")
        c.paint(mark, "#161012", 0.9)
        c.paint(np.clip(np.roll(mark, (2, 2), (0, 1)) - mark, 0, 1) * inner, "#8a8478", 0.35)
    elif state == "armed":
        c.graded = False
        k = 0.7 + 0.3 * np.sin((f or 0) * 1.5708)
        c.paint(inner * 0.5, "#1c1012")
        c.glow(mark, "#e04848", 4.0, 0.6 * k)
        c.add(mark, "#ffb0a0", 0.95 * k)
    else:                     # sprung: 판이 꺼지고 그을렸다
        c.paint(inner, "#0c0a0c", 0.92)
        c.paint(c.blob(32, 32, 34, 30, 0.4, 9, 0.3, 0, seed) * (1 - inner), "#141010", 0.6)
        c.paint(c.cracks([(32, 32, a, 26) for a in (0.5, 2.4, 4.1, 5.5)], 1.8), "#060506", 0.9)
