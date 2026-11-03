"""둘러싼 차원광장 구상 — 안 3(부채꼴 안마당) 바탕, 광장 남쪽을 막는 방법 셋(사각형 배치도 + 카메라에서 본 상자 그림).
  python3 tools/town_plaza.py   → docs/plans/town/layouts/plaza_{arcade,shops,raised}.png · plaza_views.png · c2.png
사용자 2026-11-02 "차원광장을 건물로 둘러싼 기획은 없나. 3번 기반으로 가고". 기획 설명은 docs/plans/city_town_layouts.md §5.

광장 = 육각형(북쪽 변 정면 · 비스듬한 변 넷은 ±28.8°). 북쪽 반은 집 앞면이 광장을 보고(정면·사선 판),
남쪽 반은 카메라 쪽에 있으므로 앞면이 바깥(남)을 본다 — 등이 광장 쪽. 그 등이 광장을 가리지 않게 하는 방법이 세 안이다.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_layouts as tl  # noqa: E402
from town_layouts import Plan, TOP, UP, MID, LOW, SL, C, Sn, flat, fan_block, top_of, font, lab  # noqa: E402

PC = (0.0, -4.5)  # 광장 가운데
NZ, SZ, HW = -16.0, 7.0, 11.0  # 북쪽 변 z · 남쪽 변 z · 북·남 변 반너비
DX = (SZ - NZ) / 2 / SL  # 비스듬한 변의 x 길이
WV, EV = (-HW - DX, PC[1]), (HW + DX, PC[1])  # 서·동 꼭짓점(거리가 나가는 곳)
HEX = [(-HW, NZ), (HW, NZ), EV, (HW, SZ), (-HW, SZ), WV]
# 화면 = 탐험 화면과 같은 3/4 사선 투영(사용자 2026-11-02 "화면각을 저렇게 눕히지 말고 탐험화면과 같은 각으로" — CT92):
# 바닥 깊이는 줄이지 않고(render.json view.floor_tile_px 32×32), 벽 앞면은 높이 그대로 선다(wall_tile_px 80 − 32 = 앞면 48px).
# 화면 y = 땅 깊이 z × KZ − 높이 × KY. 가림 기울기 = KY / KZ = 1(집은 제 높이만큼만 뒤를 가린다 — 18°에서는 약 3배).
SIN, COS = 1.0, 1.0
tl.TAN = 1.0
tl.CAM_LABEL = "카메라(탐험 화면과 같은 3/4)"
VARIANTS = {
	"arcade": "광장 A · 남쪽 회랑",
	"shops": "광장 B · 남쪽 가게 줄 + 문루",
	"raised": "광장 C · 돋운 광장",
}


def lerp(a, b, t):
	return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def south_edges(trim: float = 4.5, gate: float = 2.6) -> list:
	"""남쪽 반의 변(서→동): 남서(사선) · 남(정면, 가운데 문 자리 비움) · 남동(거울 사선). 꼭짓점 쪽은 거리 자리로 trim만큼 비운다."""
	L = math.hypot(EV[0] - HW, EV[1] - SZ)
	sw = (lerp(WV, (-HW, SZ), trim / L), (-HW, SZ))
	se = ((HW, SZ), lerp((HW, SZ), EV, 1 - trim / L))
	return [sw, ((-HW, SZ), (-gate, SZ)), ((gate, SZ), (HW, SZ)), se]


def outward(a, b, d):
	L = math.hypot(b[0] - a[0], b[1] - a[1])
	ux, uz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
	return [(a[0] - uz * d, a[1] + ux * d), (b[0] - uz * d, b[1] + ux * d)]


def ring_north(p: Plan, base: float, stair=(-35.0, -30.0, TOP)):
	"""북쪽 반: 앞면이 광장을 본다. 북 = 길드 + 집 줄(정면), 북동 = 여관 + 집(사선), 북서 = 집(뒤집은 사선)."""
	p.box(-HW, NZ, 10.2, 8, 6.4, "탐험가 길드")
	p.row([(0.6, NZ), (HW, NZ)], 70, st=(3, 4), depth=(5.5, 6.5), jitter=0.3)
	p.box(HW + 0.2, NZ + 0.2, 12, 6, 5.2, "여관", yaw=-28.8)
	p.row([(HW + 12 * C + 0.4, NZ + 0.2 + 12 * Sn), lerp((HW, NZ), EV, 0.86)], 71, st=(2, 3), depth=(4.5, 5.5), jitter=0.2)
	p.row([lerp(WV, (-HW, NZ), 0.14), (-HW - 0.2, NZ + 0.2)], 72, st=(2, 4), depth=(4.5, 5.5), jitter=0.2)
	p.box(-9.5, -12.2, 3.6, 2.6, 2.4, "정산 천막")
	p.stairs.append((0.5 - 1.2, stair[0], 0.5 + 1.2, stair[1], stair[2], base))


def ring_south(p: Plan, kind: str):
	edges = south_edges()
	if kind == "arcade":
		# 회랑: 기둥 줄 둘 + 떠 있는 지붕(밑 2.3 · 위 3.3). 밑으로 광장이 보이고 지붕 띠만 가린다.
		p.arcades = []
		for a, b in edges:
			oa, ob = outward(a, b, 3.2)
			poly = [a, b, ob, oa]
			p.slabs.append((poly, 2.3, 3.3))
			p.arcades.append(poly)
			L = math.hypot(b[0] - a[0], b[1] - a[1])
			for k in range(int(L / 2.6) + 1):
				for q in (lerp(a, b, k * 2.6 / L), lerp(oa, ob, k * 2.6 / L)):
					p.box(q[0] - 0.25, q[1] + 0.25, 0.5, 0.5, 2.3, kind="post")
		p.label(-20, 9.5, "회랑(노점)", "alley")
	elif kind == "shops":
		for i, (a, b) in enumerate(edges):
			fa, fb = outward(a, b, 5.0)
			p.row([fa, fb], 80 + i, st=(1, 2), depth=(5.0, 5.0), jitter=0.0, w=(3.6, 5.2))
		p.box(-2.5, SZ + 6.0, 5.0, 6.0, top_of(3) + 0.6, "문루")
	else:  # raised
		for i, (a, b) in enumerate(edges):
			fa, fb = outward(a, b, 4.6)
			p.row([fa, fb], 90 + i, st=(1, 1), depth=(4.6, 4.6), jitter=0.0, w=(3.6, 5.2))


def plan_ring(kind: str) -> Plan:
	p = Plan("c2_" + kind, "안 3 · 둘러싼 차원광장", VARIANTS[kind])
	p.arcades = []
	p.bands = [(flat(-30), TOP), (flat(18), MID), (flat(tl.Z1 + 2), LOW)]
	tl.common(p, -4)
	# 꼭대기 단(+7.2) — 안 3 그대로
	p.box(-10, -47, 20, 10, 12.0, "신전")
	p.yards.append([(-10, -46.6), (10, -46.6), (13, -36), (-13, -36)])
	fan_block(p, -42, -26, -48, 9, 40, -36)
	fan_block(p, 26, 42, -48, 9, 42, -36)
	fan_block(p, 62, 72, -50, 6, 44, -38, back_st=(2, 3))
	p.rounds.append((-66, -44, 6.0, 7.0, "도서관"))
	# 광장 단 — 둘러싼 광장
	base = 2.4 if kind == "raised" else MID
	if kind == "raised":
		p.raised.append(([WV, (-HW, SZ), (HW, SZ), EV, (EV[0] + 5, -9), (EV[0] + 5, -30), (WV[0] - 5, -30), (WV[0] - 5, -9)], base))
		p.stairs += [(-2.6, SZ, 2.6, SZ + 4.6, base, MID), (WV[0] - 1.5, -6.5, WV[0] + 2.5, -1.5, base, MID), (EV[0] - 2.5, -6.5, EV[0] + 1.5, -1.5, base, MID)]
	p.pavings.append(HEX)
	p.discs += [(PC[0], PC[1], 3.4, 0.3, (168, 160, 142)), (PC[0], PC[1], 2.75, 0.6, (176, 168, 150)), (PC[0], PC[1], 2.1, 0.9, (184, 176, 158))]
	p.plazas.append((PC[0], PC[1], 0))
	ring_north(p, base)
	ring_south(p, kind)
	fan_block(p, -64, -50, -20, 8, 52, -7)
	fan_block(p, 46, 58, -20, 7, 53, -7)
	p.box(66, -3, 12, 7, 6.0, "은행")
	p.stairs.append((-3, 18, 3, 22.8, MID, LOW))
	p.walls += [([(-80, 17.6), (-3, 17.6)], 0.6), ([(3, 17.6), (80, 17.6)], 0.6)]
	# 아래 단(−3.6) — 안 3에서 4칸 남쪽으로
	p.row([(-62, 21), (-52, 21)], 60, st=(2, 3), depth=(4.5, 5.5))
	p.box(-52, 21, 12, 6, 4.2, "잡화점")
	p.row([(-40, 21), (-30, 21)], 61, st=(2, 3), depth=(4.5, 5.5))
	fan_block(p, -62, -30, 21, 10, 62, 33, back=False, gate=False)
	fan_block(p, 14, 28, 21, 8, 63, 32, back_st=(1, 2))
	p.box(44, 26, 12, 7, 4.5, "대장간")
	p.yards.append([(44, 26.6), (56, 26.6), (56, 33), (44, 33)])
	p.paths += [[(-40, -26.5), (40, -26.5)], [(-38, -26.5), (-38, -6)], [(40, -26.5), (40, -6)], [(-70, 19), (-4, 19)], [(4, 19), (60, 19)]]
	p.label(PC[0], PC[1] + 6.5, "차원광장", "fac").label(-24, 15.5, "광장 둘레 길", "street").label(-60, -10.5, "안마당", "alley")
	p.label(52, -10.5, "안마당", "alley").label(0, 24.5, "큰 계단", "note").label(-10, 35, "수로 거리", "street").label(-46, 29, "시장 마당", "alley")
	p.label(-26, -27.5, "뒷골목", "alley")
	p.section_x = 4
	return p


# ---------- 카메라에서 본 상자 그림(높이 지도를 남쪽에서 북쪽으로 쓸어 그린다) ----------

WALLS = [(196, 184, 162), (182, 170, 150), (168, 158, 142), (188, 174, 152), (174, 166, 154)]
FAC_WALL = (178, 152, 120)
STONE = (110, 104, 94)
SKY = (52, 50, 48)
DOOR = (54, 38, 30)


def camera_view(p: Plan) -> tuple:
	g, b, _ = tl.raster(p)
	tex = np.array(tl.draw_plan(p, clean=True)).astype(np.int32)
	W, H, S, Z0 = tl.W, tl.H, tl.S, tl.Z0
	ID = Image.new("I", (W, H), 0)
	di = ImageDraw.Draw(ID)
	for k, hs in enumerate(p.houses):
		di.polygon([tl.px(*q) for q in hs["poly"]], fill=k + 1)
	for k, (x, z, r, _t, _n) in enumerate(p.rounds):
		di.ellipse([tl.px(x - r, z - r), tl.px(x + r, z + r)], fill=5000 + k)
	ids = np.array(ID)
	top = np.maximum(g, b)
	zc = Z0 + (np.arange(H) + 0.5) / S
	sy = zc[:, None] * SIN - top * COS
	y0 = Z0 * SIN - 21.0 * COS
	SH = int((tl.Z1 * SIN + 5.0 * COS - y0) * S)
	out = np.zeros((SH, W, 3), np.int32)
	out[:] = SKY
	sid = np.full((SH, W), -9, np.int64)
	sz = np.full((SH, W), 1e9)
	rng = np.random.default_rng(3)
	wall_c = [WALLS[int(v)] for v in rng.integers(0, len(WALLS), len(p.houses) + 1)]
	for c in range(W):
		ylim = SH
		prev = None
		for i in range(H - 1, -1, -1):
			y = int((sy[i, c] - y0) * S)
			h = top[i, c]
			if y < ylim:
				y = max(y, 0)
				hid = int(ids[i, c]) if b[i, c] > g[i, c] + 0.01 else 0
				if prev is not None and h - prev > 0.2 and ylim - y > 1:
					if hid:
						k = hid - 1
						col = FAC_WALL if hid >= 5000 or p.houses[k]["kind"] == "fac" else wall_c[k]
						if hid < 5000 and p.houses[k]["kind"] == "post":
							col = (120, 112, 100)
					else:
						col = STONE if prev > -20 else (12, 11, 10)
					out[y + 1:ylim, c] = col
					sid[y + 1:ylim, c] = hid * 2 + 1 if hid else -3
					sz[y + 1:ylim, c] = zc[i]
					ylim = y + 1
				out[y:ylim, c] = tex[i, c]
				sid[y:ylim, c] = hid * 2 if hid else -2
				sz[y:ylim, c] = zc[i]
				ylim = y
				if ylim <= 0:
					break
			prev = h
	img = Image.fromarray(out.clip(0, 255).astype(np.uint8))
	# 문(사람 크기 — 폭 0.9 · 높이 2): 그 집 앞벽이 보이는 자리에만
	arr = np.array(img)
	for k, hs in enumerate(p.houses):
		if hs["kind"] not in ("house", "fac"):
			continue
		(ax, az), (bx, bz) = hs["front"]
		mx, mz = (ax + bx) / 2, (az + bz) / 2
		dw = 1.6 if hs["kind"] == "fac" else 0.9
		dh = 2.6 if hs.get("name") == "문루" else 2.0
		if hs.get("name") == "문루":
			dw = 2.6
		for cx in range(int((mx - dw / 2 - tl.X0) * S), int((mx + dw / 2 - tl.X0) * S) + 1):
			if not 0 <= cx < W:
				continue
			ya = int((mz * SIN - (hs["base"] + dh) * COS - y0) * S)
			yb = int((mz * SIN - hs["base"] * COS - y0) * S)
			for yy in range(max(ya, 0), min(yb, SH)):
				if sid[yy, cx] == (k + 1) * 2 + 1:
					arr[yy, cx] = DOOR
	img = Image.fromarray(arr)
	d = ImageDraw.Draw(img)

	def P(x, z, h):
		return ((x - tl.X0) * S, (z * SIN - h * COS - y0) * S)

	def paint(poly, color, zmax):
		M = Image.new("L", (W, SH), 0)
		ImageDraw.Draw(M).polygon(poly, fill=1)
		m = np.array(M).astype(bool) & (sz <= zmax + 0.05)
		a = np.array(img)
		a[m] = color
		return Image.fromarray(a)

	# 회랑 지붕(떠 있는 판): 윗면 + 바깥(남쪽) 띠
	for poly in p.arcades:
		zmax = max(q[1] for q in poly)
		img = paint([P(x, z, 3.3) for x, z in poly], (104, 74, 60), zmax)
		img = paint([P(*poly[3], 3.3), P(*poly[2], 3.3), P(*poly[2], 2.3), P(*poly[3], 2.3)], (150, 138, 120), zmax)
	# 돌 고리(포탈): 세운 고리
	cx, cz = PC
	hb = (2.4 if p.raised else 0.0) + 0.9 + 1.95
	ring = [P(cx + 1.95 * math.cos(t), cz, hb + 1.95 * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 48)]
	inner = [P(cx + 1.5 * math.cos(t), cz, hb + 1.5 * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 48)]
	img = paint(ring, (150, 144, 132), cz)
	img = paint(inner, (70, 110, 120), cz)
	# 윤곽: 칸 주인이 바뀌는 곳
	a = np.array(img).astype(np.int32)
	e = np.zeros(sid.shape, bool)
	diff_x = sid[:, 1:] != sid[:, :-1]
	diff_y = sid[1:, :] != sid[:-1, :]
	ground = sid < 0
	e[:, 1:] |= diff_x & ~(ground[:, 1:] & ground[:, :-1])
	e[1:, :] |= diff_y & ~(ground[1:, :] & ground[:-1, :])
	a[e] = (a[e] * 0.45).astype(np.int32)
	img = Image.fromarray(a.clip(0, 255).astype(np.uint8))
	d = ImageDraw.Draw(img)
	for hs in p.houses:
		if hs.get("name") and hs["top"] > 3.0:
			mx = sum(q[0] for q in hs["poly"]) / 4
			mz = max(q[1] for q in hs["poly"])
			lab(d, P(mx, mz, hs["base"] + hs["top"] + 1.4), hs["name"], "fac")
	for x, z, r, t, n in p.rounds:
		if n:
			gi = min(max(int((z - Z0) * S), 0), H - 1)
			gj = min(max(int((x - tl.X0) * S), 0), W - 1)
			lab(d, P(x, z + r, float(g[gi, gj]) + t + 1.4), n, "fac")
	lab(d, P(cx + 7.5, cz, (2.4 if p.raised else 0) + 2.6), "차원광장", "fac")
	return img, sid


def region(x0, x1, z0, z1, s):
	tl.X0, tl.X1, tl.Z0, tl.Z1, tl.S = x0, x1, z0, z1, s
	tl.W, tl.H = (x1 - x0) * s, (z1 - z0) * s


NOTES = {
	"arcade": [
		("남쪽", "남쪽 반을 회랑(기둥 + 낮은 지붕, 노점이 선다)으로 막는다. 지붕 밑으로 광장 앞쪽이 보이고, 지붕 띠 너머로 돌 고리와 북쪽 집들이 보인다. 회랑 바깥은 광장 둘레 길."),
		("좋은 점", "광장이 닫혀 보이면서도 거의 다 보인다. 회랑 밑 노점·거리 사건 자리가 생긴다. 남쪽에 문이 없어도 어색하지 않다."),
		("아쉬움", "회랑 지붕 바로 뒤 좁은 띠만 가려진다 — 그 밑을 걸으면 회랑을 흐리게."),
	],
	"shops": [
		("남쪽", "남쪽 반도 집으로 막는다. 2층 가게 줄이 앞면을 바깥(광장 둘레 길)으로 두고 등을 광장에 댄다. 가운데 문루(아치 통로)로 들어온다."),
		("좋은 점", "진짜로 사방이 막힌 광장 — 아늑하다. 바깥 둘레 길에 가게 문이 줄지어 선다."),
		("아쉬움", "가게 줄 뒤 광장 남쪽 가장자리(약 4칸 띠)는 가려진다 — 그 띠를 걸을 때만 가게 줄을 흐리게. 3/4 화면이라 3층 문루도 돌 고리를 가리지 않는다."),
	],
	"raised": [
		("남쪽", "광장을 반 단(2.4칸) 돋운다. 남쪽 반은 둘레 길에 선 1층 가게 줄 — 지붕 꼭대기가 광장 바닥 높이쯤이라 광장을 둘러싸는 '지붕 담'이 된다. 남·서·동 계단으로 오른다."),
		("좋은 점", "광장 바닥이 끝까지 다 보인다. 둘러싸인 느낌 + 높은 단 위 무대라 포탈 연출이 가장 잘 보인다. 흐리게 할 일이 없다."),
		("아쉬움", "남쪽 가게가 1층뿐이라 낮다. 광장이 동네보다 높아 계단이 셋 더 든다."),
	],
}


def board(kind: str, p: Plan) -> Image.Image:
	region(-46, 46, -54, 30, 7)
	plan = tl.draw_plan(p)
	region(-36, 36, -52, 24, 8)
	view, _sid = camera_view(p)
	M = 18
	RW = view.width
	Hh = max(plan.height, view.height + 260)
	im = Image.new("RGB", (M + plan.width + M + RW + M, M + 44 + Hh + M), tl.BG)
	d = ImageDraw.Draw(im)
	d.text((M, M - 4), VARIANTS[kind], font=font(28), fill=tl.BONE)
	d.text((M + 430, M + 6), "안 3 바탕 · 왼쪽 = 위에서 본 배치(빗금 = 가려진 땅) · 오른쪽 = 탐험 화면과 같은 3/4로 본 상자", font=font(15), fill=tl.DIM)
	im.paste(plan, (M, M + 44))
	x = M + plan.width + M
	im.paste(view, (x, M + 44))
	y = M + 44 + view.height + 14
	for head, body in NOTES[kind]:
		d.text((x, y), head, font=font(17), fill=tl.GOLD)
		y += 24
		for line in tl.wrap(d, body, font(14), RW):
			d.text((x, y), line, font=font(14), fill=tl.BONE)
			y += 20
		y += 8
	return im, view


def main():
	out = tl.OUT
	os.makedirs(out, exist_ok=True)
	views = []
	full = None
	for kind in VARIANTS:
		region(-80, 80, -60, 42, 6)
		p = plan_ring(kind)
		if kind == "arcade":
			full = p
		im, view = board(kind, p)
		im.save(os.path.join(out, f"plaza_{kind}.png"), optimize=True)
		views.append((kind, view))
		print("wrote", kind, im.size)
	M = 14
	vw, vh = views[0][1].size
	ov = Image.new("RGB", (M + vw + M, M + len(views) * (vh + 34 + M)), tl.BG)
	d = ImageDraw.Draw(ov)
	for i, (kind, v) in enumerate(views):
		y = M + i * (vh + 34 + M)
		d.text((M, y), VARIANTS[kind], font=font(20), fill=tl.BONE)
		ov.paste(v, (M, y + 30))
	ov.save(os.path.join(out, "plaza_views.png"), optimize=True)
	# 고른 안(B 가게 줄 + 문루 — 사용자 2026-11-02 "그 2안으로")을 넣은 7구역 전체: 배치도 + 3/4 화면
	region(-80, 80, -60, 42, 6)
	full = plan_ring("shops")
	full.title = "안 3 · 둘러싼 광장"
	full.one = "부채꼴 안마당 동네 + 육각 광장(남쪽 반 = 가게 줄 + 문루) · 탐험 화면 3/4"
	full.notes = [
		("짜임", "안 3 그대로(덩어리 = 뒷줄 + 벌어진 날개 + 안마당). 광장 단 가운데에 육각 광장 — 북쪽 변 정면 줄(길드), 북동 변 사선(여관), 북서 변 뒤집은 사선, 남쪽 세 변은 2층 가게 줄(문은 바깥 둘레 길) + 가운데 문루. 서·동 꼭짓점과 문루로 드나든다."),
		("뒷골목", "광장 북쪽 줄 뒤 띠(옹벽 밑)와 덩어리 사이 틈, 안마당. 길드 옆 골목으로 꼭대기 단에 오른다."),
		("3/4 화면", "탐험 화면처럼 바닥 깊이를 줄이지 않으면 집은 제 높이만큼만 뒤를 가린다(18°에서는 약 3배). 그래서 빗금이 확 줄었다 — 안마당과 광장이 거의 다 보인다."),
	]
	tl.board(full).save(os.path.join(out, "c2.png"), optimize=True)
	view, _sid = camera_view(full)
	M = 18
	im = Image.new("RGB", (M + view.width + M, M + 44 + view.height + M), tl.BG)
	d = ImageDraw.Draw(im)
	d.text((M, M - 4), "안 3 · 둘러싼 광장 — 탐험 화면 3/4로 본 7구역(상자)", font=font(26), fill=tl.BONE)
	im.paste(view, (M, M + 44))
	im.save(os.path.join(out, "c2_view.png"), optimize=True)
	print("wrote c2")


if __name__ == "__main__":
	main()
