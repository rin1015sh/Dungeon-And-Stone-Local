"""실내 다시 그린 것(CT112 — 2026-11-04 사용자 "건물 내부에서 그림체 안 맞는 것들 다시 그려. 탁자 · 벽난로 · 내부 문짝 · 입체감 안 느껴지는 것들 전부"):
3/4(앞면 + 윗면만 보인다)에서 깊이를 내는 법 — 뒤 다리 · 뒤 물건을 먼저(위로 보인다) · 윗판 두께와 앞 모서리 빛 · 들어간 면(문짝 · 화구)은 그만큼 위로 밀려
문지방 · 바닥이 보인다 · 벽에서 나온 것(벽난로 굴뚝 몸통 · 선반)은 윗면이 보인다 · 안쪽 면은 어둡게.
  round_table  = 둥근 탁자(가운데 기둥 · 십자 발 · 두꺼운 윗판 · 잔 · 접시 · 촛불) + 걸상 넷(뒤 둘이 먼저)
  door_shut    = 닫힌 문(벽보다 들어간 널문 · 돌 문틀이 앞으로 · 문지방 · 쇠 경첩 · 못 · 고리 · 작은 쇠살 창 · 문 앞 디딤돌)
  door_open    = 열린 아치 통로(두께 있는 문틀 · 안쪽 바닥이 이어진다 · 비스듬히 열린 문짝)
  fireplace    = 벽에서 나온 굴뚝 몸통(윗면) · 선반(물건) · 들어간 화구(검댕 · 안쪽 면) · 장작과 불 · 쇠 받침 · 앞 화덕돌
"""
import math

import interior_mats as M
from interior_canvas import hexc

WOOD_D, WOOD, WOOD_L = hexc("#3a2a1c"), hexc("#5a4030"), hexc("#7a5a3c")
IRON, BRASS = hexc("#38383a"), hexc("#9a7e48")
STONE, DARK = hexc("#8a8274"), hexc("#140f0c")


def _flame(cv, y, x, z, s=1.0):
    for k, col in enumerate(("#c25a1e", "#f0a040", "#ffe6a8")):
        h = (0.32 - k * 0.09) * s
        w = (0.1 - k * 0.025) * s
        cv.fill([cv.to_px(x - w, y, z), cv.to_px(x, y, z + h), cv.to_px(x + w, y, z), cv.to_px(x, y, z - w * 0.5)], hexc(col), glow=1.0)


def _arch_pts(cv, y, x0, x1, z0, z1):
    cx, r = (x0 + x1) / 2, (x1 - x0) / 2
    spring = z1 - r
    pts = [cv.to_px(x0, y, z0)]
    for i in range(25):
        d = -r + 2 * r * i / 24
        pts.append(cv.to_px(cx + d, y, spring + math.sqrt(max(0.0, r * r - d * d))))
    pts.append(cv.to_px(x1, y, z0))
    return pts


# ---------- 둥근 탁자 ----------

def round_table(cv, w, d, cx, seed):
    from interior_furn import stool, mug
    cy = d * 0.42
    for sx in (cx - 0.42, cx + 0.42):  # 뒤 걸상(탁자에 반쯤 가린다)
        stool(cv, sx, cy - 0.34)
    cv.shadow(cx + 0.1, cy + 0.12, 0.5, 0.3, 0.35)
    for a in (0.0, math.pi / 2, math.pi, 3 * math.pi / 2):  # 십자 발
        ex, ey = cx + math.cos(a) * 0.3, cy + 0.1 + math.sin(a) * 0.22
        cv.line(cv.to_px(cx, cy + 0.1, 0.04), cv.to_px(ex, ey, 0.02), 7, WOOD_D * (0.6 if math.sin(a) < 0 else 0.9))
    cv.cyl(cx, cy + 0.1, 0.075, 0.02, 0.7, WOOD, side=WOOD_D, tex_side=M.wood("#4a3424", seed + 2, False))  # 가운데 기둥
    cv.cyl(cx, cy + 0.1, 0.13, 0.55, 0.62, WOOD_D)  # 기둥 머리
    cv.cyl(cx, cy, 0.54, 0.66, 0.78, WOOD_L, side=WOOD_D * 1.1, tex_top=M.wood("#6a4c34", seed), tex_side=M.wood("#4a3424", seed + 1))
    cv.cyl(cx + 0.08, cy - 0.06, 0.15, 0.78, 0.785, hexc("#c8bca0"))  # 접시
    cv.cyl(cx + 0.08, cy - 0.06, 0.09, 0.785, 0.79, hexc("#a89a7c"))
    mug(cv, cx - 0.24, cy - 0.1, 0.78)
    mug(cv, cx + 0.3, cy + 0.15, 0.78)
    cv.cyl(cx - 0.12, cy + 0.18, 0.05, 0.78, 0.8, BRASS)  # 촛대 · 촛불
    cv.front(cx - 0.145, cx - 0.095, cy + 0.19, 0.8, 0.96, hexc("#e4d8bc"))
    _flame(cv, cy + 0.2, cx - 0.12, 0.96, 0.4)
    for sx in (cx - 0.46, cx + 0.46):  # 앞 걸상
        stool(cv, sx, cy + 0.42)


# ---------- 문 ----------

def door_shut(cv, x0, x1, yf, seed):
    """닫힌 문: 돌 문틀(벽에서 0.06 나온다) · 널문은 벽에서 0.14 들어간다(위로 밀려 문지방이 보인다)."""
    a, b = x0 + 0.12, x1 - 0.12
    zt = 1.98
    cv.ground(a - 0.06, yf - 0.002, b + 0.06, yf + 0.22, None, tex=M.slabs("#6a6258", 1.0, 1.0, seed, 0.05), lit=0.9)  # 문 앞 디딤돌
    cv.front(a - 0.06, b + 0.06, yf + 0.22, 0.0, 0.06, hexc("#5a544a"), shade=(1.0, 0.7))
    cv.fill(_arch_pts(cv, yf + 0.06, a - 0.12, b + 0.12, 0.0, zt + 0.12), STONE * 0.82, shade=(1.0, 0.8))  # 문틀(앞)
    cv.fill(_arch_pts(cv, yf + 0.06, a, b, 0.0, zt), DARK * 2.2, shade=(1.0, 0.6), lit=0.5)  # 문틀 안쪽(두께 그늘)
    cv.ground(a, yf - 0.14, b, yf + 0.06, hexc("#4a443c"), z=0.0, lit=0.6)  # 문지방(들어간 만큼)
    door = _arch_pts(cv, yf - 0.14, a + 0.02, b - 0.02, 0.0, zt - 0.06)
    cv.fill(door, None, tex=M.plank_door(seed), shade=(0.95, 0.62))
    for z in (0.42, 1.3):  # 쇠 경첩 띠 · 못
        cv.front(a + 0.04, b - 0.18, yf - 0.139, z, z + 0.07, IRON, shade=(1.1, 0.8))
        for k in range(4):
            xx = a + 0.1 + k * (b - a - 0.3) / 3
            cv.front(xx - 0.02, xx + 0.02, yf - 0.138, z + 0.015, z + 0.055, hexc("#6a6660"))
    gx = (a + b) / 2
    cv.front(gx - 0.14, gx + 0.14, yf - 0.139, 1.45, 1.65, DARK * 1.5)  # 쇠살 창
    for k in range(3):
        cv.front(gx - 0.1 + k * 0.1 - 0.01, gx - 0.1 + k * 0.1 + 0.01, yf - 0.138, 1.45, 1.65, IRON * 1.3)
    cv.cyl(b - 0.2, yf - 0.13, 0.05, 0.9, 0.93, BRASS)  # 고리
    cv.fill(cv.ellipse_pts(b - 0.2, yf - 0.12, 0.06, 0.06, 0.86, 16), BRASS * 0.8)
    for zz in (0.15, zt - 0.5):  # 돌 문틀 쐐기돌 줄
        cv.front(a - 0.12, a, yf + 0.061, zz, zz + 0.02, DARK * 3.0)
        cv.front(b, b + 0.12, yf + 0.061, zz, zz + 0.02, DARK * 3.0)


def door_open(cv, x0, x1, yf, seed, h=None):
    """열린 아치 통로: 두께 있는 문틀 · 안쪽으로 이어지는 바닥(멀수록 어둡다) · 비스듬히 열린 문짝(경첩 = 왼쪽)."""
    a, b = x0 + 0.06, x1 - 0.06
    zt = h or (2.3 + (x1 - x0 - 1) * 0.3)
    cv.fill(_arch_pts(cv, yf + 0.05, a - 0.1, b + 0.1, 0.0, zt + 0.1), STONE * 0.78, shade=(1.0, 0.8))
    cv.fill(_arch_pts(cv, yf + 0.05, a + 0.1, b - 0.1, 0.0, zt - 0.1), DARK, lit=0.0)
    for k in range(5):  # 안쪽 바닥(벽 두께 + 너머 — 들어갈수록 어둡게)
        y0 = yf + 0.05 - (k + 1) * 0.16
        cv.ground(a + 0.1, y0, b - 0.1, y0 + 0.16, None, tex=M.slabs("#6a6258", 1.0, 1.0, seed + k, 0.05), lit=max(0.08, 0.7 - k * 0.15))
    cv.fill(_arch_pts(cv, yf - 0.75, a + 0.18, b - 0.18, 0.0, zt - 0.3), hexc("#2a231c"), lit=0.35)  # 너머 방 벽(희미하게)
    cv.ground(a + 0.1, yf - 0.02, b - 0.1, yf + 0.05, hexc("#7a7266"), z=0.0, lit=0.9)  # 문지방 앞 모서리
    hx, hy = a + 0.1, yf - 0.05  # 열린 문짝(벽 안쪽으로 60° 돌아 붙었다)
    tip_x, tip_y = hx + 0.42, hy - 0.55
    leaf = [cv.to_px(hx, hy, zt - 0.45), cv.to_px(tip_x, tip_y, zt - 0.45), cv.to_px(tip_x, tip_y, 0.02), cv.to_px(hx, hy, 0.02)]
    cv.fill(leaf, None, tex=M.plank_door(seed + 7), shade=(0.7, 0.45), lit=0.6)
    cv.line(cv.to_px(hx, hy, 0.5), cv.to_px(tip_x, tip_y, 0.5), 3, IRON)
    cv.line(cv.to_px(hx, hy, 1.4), cv.to_px(tip_x, tip_y, 1.4), 3, IRON)


# ---------- 벽난로 ----------

def fireplace(cv, x0, x1, yf, H, seed):
    """벽난로: 굴뚝 몸통이 벽에서 0.38 나온다(윗면 · 앞면) · 화구는 그 안으로 0.3 들어간다 · 선반(1.38) · 앞 화덕돌."""
    p = 0.38
    a, b = x0 + 0.05, x1 - 0.05
    fy = yf + p
    stone = M.slabs("#7a7266", 0.42, 0.28, seed, 0.2)
    cv.box(a + 0.18, yf, b - 0.18, fy - 0.08, 1.5, H - 0.05, STONE * 0.9, tex_side=stone)  # 위 굴뚝(조금 좁게)
    cv.front(a, b, fy, 0.0, 1.32, None, tex=stone, shade=(1.0, 0.72))  # 아래 몸통 앞면
    cv.ground(a, yf, b, fy, STONE * 0.75, z=1.32)
    cv.edge_light(a, b, fy, 1.32)
    cv.box(a - 0.1, yf, b + 0.1, fy + 0.14, 1.32, 1.44, WOOD, side=WOOD_D, tex_top=M.wood("#6a4c34", seed), tex_side=M.wood("#4a3424", seed + 1))  # 선반
    cv.cyl(a + 0.3, fy - 0.05, 0.07, 1.44, 1.6, hexc("#7a5a3a"))  # 선반 물건(단지 · 촛불 · 접시)
    cv.front(b - 0.45, b - 0.15, fy - 0.12, 1.44, 1.72, hexc("#a89a7c"), shade=(1.0, 0.7))
    cv.front(b - 0.62, b - 0.58, fy - 0.02, 1.44, 1.6, hexc("#e4d8bc"))
    _flame(cv, fy - 0.01, b - 0.6, 1.6, 0.38)
    ia, ib = a + 0.34, b - 0.34
    top = 0.98
    cv.fill(_arch_pts(cv, fy, ia - 0.08, ib + 0.08, 0.0, top + 0.08), STONE * 0.55)  # 홍예 돌
    cv.fill(_arch_pts(cv, fy, ia, ib, 0.0, top), DARK * 1.4, lit=0.3)  # 화구 안(그을린 안쪽 면)
    back = fy - 0.3
    cv.fill(_arch_pts(cv, back, ia + 0.1, ib - 0.1, 0.0, top - 0.2), hexc("#1c1512"), lit=0.25)  # 뒷벽(검댕)
    cv.ground(ia + 0.04, back, ib - 0.04, fy, hexc("#3a2a20"), z=0.0, lit=0.9)  # 화구 바닥(재)
    cx = (ia + ib) / 2
    for s in (-1, 1):  # 쇠 받침
        cv.front(cx + s * 0.3 - 0.025, cx + s * 0.3 + 0.025, fy - 0.06, 0.0, 0.24, IRON, shade=(1.2, 0.7))
    for k, (dx, dz) in enumerate(((-0.12, 0.08), (0.12, 0.08), (0.0, 0.18))):  # 장작(누운 통나무 — 둥근 마구리)
        cv.front(cx - 0.32 + dx * 0.5, cx + 0.32 + dx * 0.5, fy - 0.12 - k * 0.04, dz - 0.06, dz + 0.06, hexc("#4a3020"), shade=(1.0, 0.6), lit=0.9)
        cv.fill(cv.ellipse_pts(cx + 0.32 + dx * 0.5, fy - 0.12 - k * 0.04, 0.05, 0.06, dz, 12), hexc("#8a6a44"), lit=0.9)
    cv.ground(cx - 0.3, fy - 0.2, cx + 0.3, fy - 0.08, hexc("#c25a1e"), z=0.04, glow=0.9)  # 잉걸
    for k in range(3):
        _flame(cv, fy - 0.1, cx - 0.2 + k * 0.2, 0.16, 1.4 - abs(k - 1) * 0.35)
    cv.box(a - 0.15, fy, b + 0.15, fy + 0.42, 0.0, 0.07, STONE * 0.85, tex_top=M.slabs("#857d6c", 0.5, 0.42, seed + 3, 0.12))  # 앞 화덕돌


# ---------- 상자꼴 가구(장 · 책장 · 진열장 · 궤 · 침대 · 계산대) ----------

def panel(cv, x0, x1, y, z0, z1, col, inset=0.06):
    """앞면에 도드라진 판(틀은 밝게 · 가운데는 어둡게 · 왼쪽 위 빛 · 오른쪽 아래 그늘)."""
    cv.front(x0, x1, y + 0.002, z0, z1, col * 1.12, shade=(1.0, 0.8))
    cv.front(x0 + inset, x1 - inset, y + 0.004, z0 + inset, z1 - inset, col * 0.78, shade=(0.9, 0.7))
    cv.front(x0 + inset, x1 - inset, y + 0.005, z1 - inset - 0.025, z1 - inset, col * 0.55)  # 위 안쪽 그늘(움푹)
    cv.front(x1 - inset - 0.02, x1 - inset, y + 0.005, z0 + inset, z1 - inset, col * 0.6)


def cabinet(cv, x0, y0, x1, y1, h, col, tex_side=None, cornice=True):
    """장 몸통: 굽(어둡게 · 조금 들어감) + 몸통 + 처마 돌림(앞 · 옆으로 내민다, 윗면 보인다)."""
    cv.box(x0 + 0.03, y0 + 0.03, x1 - 0.03, y1 - 0.03, 0.0, 0.1, col * 0.5)
    cv.box(x0, y0, x1, y1, 0.1, h - (0.1 if cornice else 0.0), col, side=col, tex_side=tex_side)
    if cornice:
        cv.box(x0 - 0.04, y0, x1 + 0.04, y1 + 0.05, h - 0.1, h, col * 1.15, side=col * 0.95)
        cv.front(x0 - 0.04, x1 + 0.04, y1 + 0.05, h - 0.1, h - 0.07, col * 0.5)


def chest(cv, x0, y0, x1, y1, h, col, seed, iron=None):
    """궤: 몸통 + 둥근 뚜껑(앞에서 본 반원 단면을 앞면 위로 올린 띠 — 위가 밝다) + 쇠띠 · 모서리 쇠 · 자물쇠."""
    iron = IRON if iron is None else iron
    cv.box(x0, y0, x1, y1, 0.0, h, col, tex_side=M.wood("#5a4030", seed), tex_top=M.wood("#6a4c34", seed + 1))
    lid = (y1 - y0) * 0.5
    for k in range(6):  # 뚜껑: 앞에서 뒤로 둥글게(층층이 — 앞쪽이 낮다)
        t0, t1 = k / 6.0, (k + 1) / 6.0
        za, zb = h + math.sin(t0 * math.pi) * lid * 0.55, h + math.sin(t1 * math.pi) * lid * 0.55
        ya, yb = y1 - t0 * (y1 - y0), y1 - t1 * (y1 - y0)
        cv.fill([cv.to_px(x0, ya, za), cv.to_px(x1, ya, za), cv.to_px(x1, yb, zb), cv.to_px(x0, yb, zb)], col * (0.78 + 0.08 * k), tex=None)
    for xx in (x0 + 0.12, x1 - 0.16):  # 쇠띠(앞면 → 뚜껑)
        cv.front(xx, xx + 0.04, y1 + 0.003, 0.0, h, iron)
        cv.fill([cv.to_px(xx, y1, h), cv.to_px(xx + 0.04, y1, h), cv.to_px(xx + 0.04, y0, h), cv.to_px(xx, y0, h)], iron * 1.2)
    cx = (x0 + x1) / 2
    cv.front(cx - 0.06, cx + 0.06, y1 + 0.005, h - 0.2, h - 0.04, BRASS)
    cv.front(cx - 0.015, cx + 0.015, y1 + 0.006, h - 0.15, h - 0.09, DARK)


def bed(cv, w, d, seed, blanket):
    """침대: 머리판(뒤 · 높게 · 판 둘) · 매트(두께) · 베개(볼록) · 이불(앞으로 늘어진다 · 주름) · 발판(앞 · 낮게) · 기둥 넷."""
    for x in (0.05, w - 0.13):  # 뒤 기둥
        cv.front(x, x + 0.08, 0.12, 0.0, 1.15, WOOD_D * 0.8)
        cv.cyl(x + 0.04, 0.1, 0.05, 1.15, 1.2, WOOD_L)
    cv.front(0.13, w - 0.13, 0.12, 0.45, 1.05, WOOD_D)
    panel(cv, 0.2, w / 2 - 0.04, 0.12, 0.55, 0.98, WOOD_D * 1.3, 0.05)
    panel(cv, w / 2 + 0.04, w - 0.2, 0.12, 0.55, 0.98, WOOD_D * 1.3, 0.05)
    cv.box(0.08, 0.14, w - 0.08, d - 0.08, 0.2, 0.42, WOOD, tex_side=M.wood("#5a4030", seed))  # 틀
    cv.box(0.13, 0.16, w - 0.13, d - 0.12, 0.42, 0.56, hexc("#c4b898"))  # 매트
    for k in range(2 if w > 1.4 else 1):  # 베개
        px0 = 0.22 + k * (w - 0.44) / 2
        px1 = px0 + (w - 0.44) / (2 if w > 1.4 else 1) - 0.06
        cv.cyl((px0 + px1) / 2, 0.36, (px1 - px0) / 2, 0.56, 0.66, hexc("#d8ceb4"), ry=0.13)
    cv.ground(0.11, 0.62, w - 0.11, d - 0.1, None, z=0.6, tex=M.grainy("#%02x%02x%02x" % tuple(int(c * 255) for c in blanket), seed + 1, 0.12, 6))  # 이불
    cv.front(0.11, w - 0.11, d - 0.1, 0.3, 0.6, blanket * 0.72, shade=(1.0, 0.7))
    for k in range(int(w * 3)):  # 주름
        xx = 0.2 + k * (w - 0.4) / max(1, int(w * 3) - 1)
        cv.line(cv.to_px(xx, d - 0.1, 0.58), cv.to_px(xx + 0.02, d - 0.1, 0.32), 2, blanket * 0.5)
    cv.edge_light(0.11, w - 0.11, d - 0.1, 0.6, 0.04, 1.25)
    for x in (0.05, w - 0.13):  # 앞 기둥 · 발판
        cv.front(x, x + 0.08, d - 0.05, 0.0, 0.7, WOOD_D)
        cv.cyl(x + 0.04, d - 0.07, 0.05, 0.7, 0.75, WOOD_L)
    cv.front(0.13, w - 0.13, d - 0.05, 0.42, 0.62, WOOD)


def pew(cv, w, d, seed):
    """긴 의자: 등받이(뒤 — 갓 · 판) · 뒤 다리 · 앉을 판(두께 · 앞 모서리 빛) · 팔걸이 옆판 · 앞 다리."""
    cv.box(0.05, 0.1, w - 0.05, 0.22, 0.42, 1.0, WOOD_D, tex_side=M.wood("#4a3424", seed + 1))
    cv.box(0.02, 0.08, w - 0.02, 0.24, 1.0, 1.06, WOOD_L * 0.9)
    for k in range(max(1, int(w * 1.5))):
        a = 0.15 + k * (w - 0.3) / max(1, int(w * 1.5))
        IF_panel = panel
        IF_panel(cv, a, a + (w - 0.3) / max(1, int(w * 1.5)) - 0.06, 0.22, 0.55, 0.92, WOOD_D * 1.25, 0.04)
    for x in (0.1, w - 0.2):
        cv.front(x, x + 0.1, 0.3, 0.0, 0.42, WOOD_D * 0.6, shade=(0.8, 0.55))
    cv.box(0.05, 0.24, w - 0.05, d - 0.18, 0.38, 0.46, WOOD, side=WOOD_D, tex_top=M.wood("#5e4430", seed))
    for x in (0.0, w - 0.08):  # 옆판(앞으로 둥근 팔걸이)
        cv.front(x, x + 0.08, d - 0.16, 0.0, 0.62, WOOD_D * 0.9)
        cv.cyl(x + 0.04, d - 0.2, 0.06, 0.62, 0.66, WOOD_L)
    cv.front(0.1, w - 0.1, d - 0.18, 0.1, 0.15, WOOD_D * 0.7)


def crate(cv, x0, y0, x1, y1, z0, z1, seed):
    """궤짝: 앞면 판자 + 테두리 각목(밝게 · 도드라진다) + X 버팀 · 윗면 판자 틈 · 쇠 모서리."""
    col = hexc("#6a5038")
    cv.box(x0, y0, x1, y1, z0, z1, col, tex_side=M.planks("#6a5038", 0.16, seed), tex_top=M.planks("#7a5a3c", 0.16, seed + 1))
    t = 0.06
    for (a, b, c, e) in ((x0, x1, z0, z0 + t), (x0, x1, z1 - t, z1), (x0, x0 + t, z0, z1), (x1 - t, x1, z0, z1)):
        cv.front(a, b, y1 + 0.004, c, e, col * 1.25, shade=(1.05, 0.85))
    cv.line(cv.to_px(x0 + t, y1 + 0.005, z0 + t), cv.to_px(x1 - t, y1 + 0.005, z1 - t), 5, col * 1.15)
    cv.line(cv.to_px(x0 + t, y1 + 0.005, z1 - t), cv.to_px(x1 - t, y1 + 0.005, z0 + t), 5, col * 1.05)
    for (a, e) in ((x0, z0), (x1 - 0.08, z0), (x0, z1 - 0.08), (x1 - 0.08, z1 - 0.08)):
        cv.front(a, a + 0.08, y1 + 0.006, e, e + 0.08, IRON)
