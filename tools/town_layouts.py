"""도시 짜임 구상안 여럿 — 사각형으로만 그린 위에서 본 배치도(집을 실제로 세우지 않는다).
  python3 tools/town_layouts.py            → docs/plans/town/layouts/<안>.png · overview.png
사용자 2026-11-02 "기획구상을 여러개 해봐 · 사각형으로 간략하게 · 맨처음 기획한 느낌이 마음에 들긴 했는데 건물을 두 줄씩
겹쳐 버리면 힘들 것 같다 · 뒷골목 같은 거 넣기 좋게". 기획 설명은 docs/plans/city_town_layouts.md.

좌표 = 칸(동 x · 남 z, 위가 북). 카메라는 남쪽에서 약 18° 내려다본다(CT88) — 어디가 가려지는지 높이로 계산해 칠한다.
집 = 한 줄로만 선다(앞면 = 굵은 뼈빛 선 = 문 쪽, 늘 남·남남서·남남동). 줄 방향은 0° · ±28.8°만(정면 판 · 사선 판 · 뒤집기).
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "plans", "town", "layouts")
FONT = os.path.join(ROOT, "assets", "fonts", "NotoSansKR-Regular.otf")
S = 6  # 1칸 = 6px
X0, X1, Z0, Z1 = -80, 80, -60, 42
W, H = (X1 - X0) * S, (Z1 - Z0) * S
TAN = math.tan(math.radians(18.0))  # 가림 기울기(땅 깊이 1칸당 가리는 높이) — 탐험 화면 3/4(사선 투영)이면 1.0
CAM_LABEL = "카메라(남쪽 18°)"
SL = math.tan(math.radians(28.8))  # 사선 줄 기울기(칸 z / 칸 x)
STOREY, ROOF = 1.15, 1.5
TOP, UP, MID, LOW, CANAL = 7.2, 3.6, 0.0, -3.6, -7.2

BG = (24, 22, 20)
BONE = (226, 216, 196)
GOLD = (206, 172, 104)
ALLEY = (214, 138, 82)
DIM = (150, 142, 128)
GROUND = {TOP: (150, 142, 124), UP: (136, 128, 111), MID: (122, 114, 98), LOW: (106, 99, 85), CANAL: (92, 86, 74)}
WATER = (66, 84, 90)
YARD = (104, 112, 92)
PLAZA_C = (176, 168, 148)
ROOFS = [(112, 76, 60), (98, 66, 54), (122, 86, 66), (88, 64, 56), (106, 82, 70), (94, 72, 62)]
FAC = (138, 92, 66)
WALL = (40, 37, 34)


def font(n: int) -> ImageFont.FreeTypeFont:
	return ImageFont.truetype(FONT, n)


def px(x: float, z: float) -> tuple:
	return ((x - X0) * S, (z - Z0) * S)


def top_of(st: int) -> float:
	return st * STOREY + ROOF


# ---------- 땅 ----------

def bent(z: float, a: float = 20.0, run: float = 15.0) -> list:
	"""가운데는 곧고(|x| < a) 양옆이 28.8°로 남쪽으로 내려오는 등고선(광장이 언덕에 파고든 만 꼴)."""
	d = run * SL
	return [(X0 - 2, z + d), (-a - run, z + d), (-a, z), (a, z), (a + run, z + d), (X1 + 2, z + d)]


def flat(z: float) -> list:
	return [(X0 - 2, z), (X1 + 2, z)]


def zline(line: list, x: float) -> float:
	for (ax, az), (bx, bz) in zip(line, line[1:]):
		if ax <= x <= bx:
			return az + (bz - az) * (x - ax) / max(bx - ax, 1e-6)
	return line[-1][1]


def shift(line: list, dz: float) -> list:
	return [(x, z + dz) for x, z in line]


class Plan:
	def __init__(self, key: str, title: str, one: str):
		self.key, self.title, self.one = key, title, one
		self.bands: list = []  # (남쪽 경계 선, 높이) — 북쪽에서 남쪽 순, 첫 칸은 지도 북쪽 끝까지
		self.houses: list = []  # {poly, front, top, kind, name}
		self.rounds: list = []  # (x, z, r, top, name)
		self.water: list = []
		self.yards: list = []
		self.plazas: list = []  # (x, z, r)
		self.stairs: list = []  # (x0, z0, x1, z1, 높은 쪽 높이, 낮은 쪽 높이) — 북이 높다
		self.walls: list = []  # (점들, 높이) — 낮은 담·성벽
		self.paths: list = []  # 뒷골목 동선(점들)
		self.labels: list = []  # (x, z, 글, 종류)
		self.notes: list = []  # (머리, 글)
		self.section_x = 0.0
		self.raised: list = []  # (점들, 높이) — 단 위에 돋운 땅(돋운 광장 등)
		self.pavings: list = []  # 점들 — 광장 판석(다각형)
		self.discs: list = []  # (x, z, r, 높이, 색) — 둥근 단(광장 돌 단 등)
		self.slabs: list = []  # (점들, 밑 높이, 위 높이 — 땅 기준) — 떠 있는 지붕(회랑): 밑으로는 보이고 지붕은 가린다

	# 줄: 앞선(서→동 꺾은선)을 따라 집을 한 채씩 붙인다. 앞면 = 선, 집은 북쪽(뒤)으로 depth만큼.
	def row(self, line: list, seed: int, st=(2, 4), depth=(4.5, 6.0), w=(4.0, 6.5), gap=(0.0, 0.35),
			jitter=0.8, skip=(), lanes: int = 0, lane_w: float = 1.8, x_from: float = -1e9, x_to: float = 1e9):
		rng = random.Random(seed)
		count = 0
		for (ax, az), (bx, bz) in zip(line, line[1:]):
			lo, hi = max(ax, x_from), min(bx, x_to)
			if hi - lo < 3:
				continue
			L = math.hypot(bx - ax, bz - az)
			ux, uz = (bx - ax) / L, (bz - az) / L
			nx, nz = -uz, ux  # 앞(남쪽)
			s = (lo - ax) / ux + 0.6
			end = (hi - ax) / ux - 0.6
			while s < end - 3.0:
				ww = min(rng.uniform(*w), end - s)
				if ww < 3.0:
					break
				cx = ax + ux * (s + ww / 2)
				if any(a <= cx <= b for a, b in skip):
					s += ww + rng.uniform(*gap)
					continue
				d = rng.uniform(*depth)
				j = rng.uniform(0, jitter)
				p0 = (ax + ux * s - nx * j, az + uz * s - nz * j)
				p1 = (p0[0] + ux * ww, p0[1] + uz * ww)
				p2 = (p1[0] - nx * d, p1[1] - nz * d)
				p3 = (p0[0] - nx * d, p0[1] - nz * d)
				self.houses.append({"poly": [p0, p1, p2, p3], "front": (p0, p1), "top": top_of(rng.randint(*st)), "kind": "house"})
				count += 1
				s += ww + rng.uniform(*gap)
				if lanes and count % lanes == 0:
					s += lane_w
		return self

	def box(self, x: float, z: float, width: float, depth: float, top: float, name: str = "", yaw: float = 0.0, kind: str = "fac"):
		"""(x, z) = 앞면 왼쪽 끝. yaw = 0 · −28.8(사선 — 동쪽으로 갈수록 남쪽) · +28.8(거울)."""
		t = math.radians(yaw)
		ux, uz = math.cos(t), -math.sin(t)
		nx, nz = -uz, ux
		p0 = (x, z)
		p1 = (x + ux * width, z + uz * width)
		p2 = (p1[0] - nx * depth, p1[1] - nz * depth)
		p3 = (x - nx * depth, z - nz * depth)
		self.houses.append({"poly": [p0, p1, p2, p3], "front": (p0, p1), "top": top, "kind": kind, "name": name})
		return self

	def label(self, x: float, z: float, text: str, kind: str = "street"):
		self.labels.append((x, z, text, kind))
		return self


# ---------- 계산: 땅 높이 · 지붕 높이 · 카메라에서 보이는가 ----------

def raster(p: Plan):
	G = Image.new("F", (W, H), p.bands[0][1])
	dg = ImageDraw.Draw(G)
	# 북쪽 단부터: 그 단의 남쪽 경계 위(북쪽)를 그 높이로 칠한다 → 낮은 단이 남쪽에서 덮어 쓰지 않게 거꾸로 칠한다.
	for line, h in reversed(p.bands):
		poly = [px(X0 - 2, Z0 - 2)] + [px(x, z) for x, z in line] + [px(X1 + 2, Z0 - 2)]
		dg.polygon(poly, fill=h)
	for poly, h in p.raised:
		dg.polygon([px(*q) for q in poly], fill=h)
	# 남쪽 끝 단(마지막 경계 남쪽)은 맨 아래 높이 — bands 마지막 항목이 그 높이를 갖는다.
	for x0, z0, x1, z1, hi, lo in p.stairs:
		for k in range(int((z1 - z0) * S) + 1):
			zz = z0 + k / S
			dg.line([px(x0, zz), px(x1, zz)], fill=hi + (lo - hi) * (zz - z0) / max(z1 - z0, 1e-6))
	g = np.array(G)
	B = Image.new("F", (W, H), -99.0)
	db = ImageDraw.Draw(B)
	for hs in p.houses:
		cx = sum(q[0] for q in hs["poly"]) / 4
		cz = sum(q[1] for q in hs["poly"]) / 4
		gx, gz = px(cx, cz)
		base = float(g[min(max(int(gz), 0), H - 1), min(max(int(gx), 0), W - 1)])
		hs["base"] = base
		db.polygon([px(*q) for q in hs["poly"]], fill=base + hs["top"])
	for x, z, r, top, _n in p.rounds:
		gx, gz = px(x, z)
		base = float(g[int(gz), int(gx)])
		db.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=base + top)
	for x, z, r, h, _c in p.discs:
		gx, gz = px(x, z)
		db.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=float(g[int(gz), int(gx)]) + h)
	for pts, h in p.walls:
		for a, b in zip(pts, pts[1:]):
			gx, gz = px(*a)
			base = float(g[min(int(gz), H - 1), min(int(gx), W - 1)])
			db.line([px(*a), px(*b)], fill=base + h, width=max(2, int(0.6 * S)))
	b = np.array(B)
	top = np.maximum(g, b)
	zz = (np.arange(H)[:, None] / S + Z0).astype(np.float32)
	k = top - TAN * zz
	# 남쪽(아래 줄)부터 큰 값을 누적 — 그 점보다 남쪽에 있는 것 중 시선을 가장 높이 막는 것
	suf = np.maximum.accumulate(k[::-1], axis=0)[::-1]
	suf = np.vstack([suf[1:], np.full((1, W), -1e9, np.float32)])
	vis = (g - TAN * zz) >= suf - 0.05
	for poly, y0, y1 in p.slabs:  # 떠 있는 지붕: 시선이 지붕 높이 사이를 지나면 가려진다
		M = Image.new("L", (W, H), 0)
		ImageDraw.Draw(M).polygon([px(*q) for q in poly], fill=1)
		m = np.array(M).astype(bool)
		gx, gz = px(sum(q[0] for q in poly) / len(poly), sum(q[1] for q in poly) / len(poly))
		base = float(g[min(int(gz), H - 1), min(int(gx), W - 1)])
		zc = zz[:, 0]
		for c in np.nonzero(m.any(axis=0))[0]:
			rs = np.nonzero(m[:, c])[0]
			r = g[:, c][:, None] + TAN * (zc[rs][None, :] - zc[:, None])
			hit = (rs[None, :] > np.arange(H)[:, None]) & (r >= base + y0) & (r <= base + y1)
			vis[:, c] &= ~hit.any(axis=1)
	return g, b, vis


# ---------- 그리기 ----------

def draw_plan(p: Plan, clean: bool = False) -> Image.Image:
	"""clean = 카메라 그림의 바닥·지붕 색으로 쓸 판(빗금·글·선 없음)."""
	g, b, vis = raster(p)
	img = np.zeros((H, W, 3), np.uint8)
	for h, c in GROUND.items():
		img[np.abs(g - h) < 0.01] = c
	ramp = np.ones((H, W), bool)
	for h in GROUND:
		ramp &= np.abs(g - h) >= 0.01
	img[ramp] = (132, 124, 108)  # 계단
	im = Image.fromarray(img)
	d = ImageDraw.Draw(im)
	for x0, z0, x1, z1 in p.water:
		d.rectangle([px(x0, z0), px(x1, z1)], fill=WATER)
	for poly in p.yards:
		d.polygon([px(*q) for q in poly], fill=YARD)
	for x, z, r in p.plazas:
		d.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=PLAZA_C, outline=(96, 90, 80), width=2)
		d.ellipse([px(x - 2, z - 2), px(x + 2, z + 2)], outline=(70, 66, 60), width=3)
	for poly in p.pavings:
		d.polygon([px(*q) for q in poly], fill=PLAZA_C)
	for x, z, r in p.plazas:
		if p.pavings:
			d.ellipse([px(x - 3.4, z - 3.4), px(x + 3.4, z + 3.4)], fill=(160, 152, 134), outline=(96, 90, 80), width=2)
			d.ellipse([px(x - 2, z - 2), px(x + 2, z + 2)], outline=(70, 66, 60), width=3)
	for x, z, r, _h, c in p.discs:
		d.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=c, outline=(96, 90, 80), width=1)
	# 가려진 땅 = 어둡게 + 빗금(카메라에서 안 보이는 곳)
	arr = np.array(im).astype(np.float32)
	hid = (~vis) & (b < -50) & (not clean)
	yy, xx = np.mgrid[0:H, 0:W]
	hatch = ((xx + yy) % 9) < 2
	arr[hid] *= 0.52
	arr[hid & hatch] = arr[hid & hatch] * 0.5 + np.array([40, 30, 26]) * 0.5
	im = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
	d = ImageDraw.Draw(im)
	# 옹벽(단 경계) — 굵은 검은 띠
	edge = np.zeros((H, W), bool)
	gs = np.round(g, 2)
	edge[1:, :] |= (gs[1:, :] - gs[:-1, :]) < -1.0
	edge[:, 1:] |= np.abs(gs[:, 1:] - gs[:, :-1]) > 1.0
	ea = np.array(im)
	for dy in range(3):
		ea[np.roll(edge, dy, axis=0)] = WALL
	im = Image.fromarray(ea)
	d = ImageDraw.Draw(im)
	for x0, z0, x1, z1, _hi, _lo in p.stairs:
		for k in range(int((z1 - z0) / 0.6) + 1):
			zz = z0 + k * 0.6
			d.line([px(x0, zz), px(x1, zz)], fill=(84, 78, 70), width=1)
		d.rectangle([px(x0, z0), px(x1, z1)], outline=(60, 56, 50), width=1)
	for pts, h in p.walls:
		d.line([px(*q) for q in pts], fill=WALL if h > 3 else (70, 64, 58), width=max(3, int(0.6 * S)) if h > 3 else 3)
	for path in ([] if clean else p.paths):
		dashed(d, [px(*q) for q in path], ALLEY, 3, 10, 7)
	rng = random.Random(p.key)
	for hs in p.houses:
		poly = [px(*q) for q in hs["poly"]]
		if hs["kind"] == "post":
			d.polygon(poly, fill=(70, 64, 58))
			continue
		if hs["kind"] == "fac":
			d.polygon(poly, fill=FAC, outline=(60, 44, 36) if clean else BONE, width=1 if clean else 3)
		elif hs["kind"] == "shed":
			d.polygon(poly, fill=(128, 104, 84), outline=(52, 46, 40), width=1)
		else:
			t = hs["top"]
			c = rng.choice(ROOFS)
			k = 1.0 - (t - 3.8) * 0.06
			d.polygon(poly, fill=tuple(int(v * k) for v in c), outline=(46, 38, 34), width=1)
		hs["roof"] = im.getpixel((int(sum(q[0] for q in poly) / 4), int(sum(q[1] for q in poly) / 4))) if 0 <= sum(q[0] for q in poly) / 4 < W and 0 <= sum(q[1] for q in poly) / 4 < H else FAC
		if not clean:
			a, bq = hs["front"]
			d.line([px(*a), px(*bq)], fill=BONE, width=3)
	for x, z, r, _t, _n in p.rounds:
		d.ellipse([px(x - r, z - r), px(x + r, z + r)], fill=FAC, outline=BONE, width=3)
		d.ellipse([px(x - r * 0.5, z - r * 0.5), px(x + r * 0.5, z + r * 0.5)], outline=(170, 140, 110), width=2)
	if clean:
		return im
	dp = ImageDraw.Draw(im, "RGBA")
	for poly in getattr(p, "arcades", []):  # 회랑 지붕(떠 있는 판)
		dp.polygon([px(*q) for q in poly], fill=(104, 74, 60, 150), outline=(226, 216, 196, 255))
	for hs in p.houses:
		if hs.get("name"):
			cx = sum(q[0] for q in hs["poly"]) / 4
			cz = sum(q[1] for q in hs["poly"]) / 4
			lab(d, px(cx, cz), hs["name"], "fac")
	for x, z, _r, _t, name in p.rounds:
		lab(d, px(x, z), name, "fac")
	for x, z, text, kind in p.labels:
		lab(d, px(x, z), text, kind)
	# 카메라
	cx, cy = W - 70, H - 14
	d.polygon([(cx, cy - 34), (cx - 9, cy - 16), (cx + 9, cy - 16)], fill=BONE)
	d.text((cx - 12 - d.textlength(CAM_LABEL, font=font(15)), cy - 30), CAM_LABEL, font=font(15), fill=BONE)
	return im


def dashed(d, pts, color, width, on, off):
	for a, b in zip(pts, pts[1:]):
		L = math.hypot(b[0] - a[0], b[1] - a[1])
		t = 0.0
		while t < L:
			t1 = min(t + on, L)
			d.line([(a[0] + (b[0] - a[0]) * t / L, a[1] + (b[1] - a[1]) * t / L),
					(a[0] + (b[0] - a[0]) * t1 / L, a[1] + (b[1] - a[1]) * t1 / L)], fill=color, width=width)
			t += on + off


def lab(d, at, text, kind):
	style = {"fac": (font(19), GOLD), "street": (font(14), BONE), "alley": (font(14), ALLEY), "band": (font(14), DIM), "note": (font(13), DIM)}
	f, c = style[kind]
	bb = d.textbbox((0, 0), text, font=f)
	x, y = at[0] - (bb[2] - bb[0]) / 2, at[1] - (bb[3] - bb[1]) / 2 - bb[1]
	for ox, oy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
		d.text((x + ox * 2, y + oy * 2), text, font=f, fill=BG)
	d.text((x, y), text, font=f, fill=c)


def draw_section(p: Plan, g, b, vis, sw: int) -> Image.Image:
	"""남북 자른 면(왼쪽 = 북, 오른쪽 = 남 · 카메라는 오른쪽 위). 빨강 = 카메라에서 가려진 땅."""
	col = int((p.section_x - X0) * S)
	sc = sw / H  # 가로 축 = z
	hmin, hmax = -9.0, 18.0
	sh = int((hmax - hmin) * S * sc) + 8
	im = Image.new("RGB", (sw, sh), (36, 34, 31))
	d = ImageDraw.Draw(im)

	def Y(h):
		return sh - 4 - (h - hmin) * S * sc

	for i in range(H):
		x = i * sc
		gh, bh = g[i, col], b[i, col]
		d.line([(x, Y(hmin)), (x, Y(gh))], fill=(90, 84, 74))
		if bh > gh:
			d.line([(x, Y(gh)), (x, Y(bh))], fill=(118, 82, 64))
		d.line([(x, Y(gh) - 1), (x, Y(gh) + 1)], fill=(120, 214, 140) if vis[i, col] or bh > gh else (226, 80, 64))
	# 시선 몇 줄(18°)
	for zs in range(0, H, 60):
		x0, h0 = zs * sc, g[zs, col] if b[zs, col] < g[zs, col] else b[zs, col]
		d.line([(x0, Y(h0)), (x0 + 400, Y(h0) - 400 * TAN)], fill=(70, 70, 64), width=1)
	d.text((6, 4), f"자른 면 x={p.section_x:g} · 왼쪽 북 · 오른쪽 남(카메라)", font=font(13), fill=DIM)
	return im


def board(p: Plan) -> Image.Image:
	plan = draw_plan(p)
	g, b, vis = raster(p)
	RW = 470
	M = 18
	im = Image.new("RGB", (M + W + M + RW + M, M + 44 + H + M), BG)
	d = ImageDraw.Draw(im)
	d.text((M, M - 4), p.title, font=font(28), fill=BONE)
	d.text((M + max(330, d.textlength(p.title, font=font(28)) + 24), M + 6), p.one, font=font(16), fill=DIM)
	im.paste(plan, (M, M + 44))
	d.rectangle([M - 1, M + 43, M + W, M + 44 + H], outline=(70, 66, 60))
	x = M + W + M
	y = M + 44
	sec = draw_section(p, g, b, vis, RW)
	im.paste(sec, (x, y))
	y += sec.height + 14
	for head, body in p.notes:
		d.text((x, y), head, font=font(17), fill=GOLD)
		y += 24
		for line in wrap(d, body, font(14), RW):
			d.text((x, y), line, font=font(14), fill=BONE)
			y += 20
		y += 8
	y = max(y, M + 44 + H - 150)
	legend(d, x, y)
	return im


def wrap(d, text, f, width):
	out = []
	for para in text.split("\n"):
		line = ""
		for word in para.split(" "):
			t = (line + " " + word).strip()
			if d.textlength(t, font=f) > width and line:
				out.append(line)
				line = word
			else:
				line = t
		out.append(line)
	return out


def legend(d, x, y):
	f = font(13)
	items = [
		((112, 76, 60), "집(한 줄) — 진할수록 높다", "box"),
		(BONE, "굵은 선 = 앞면·문(카메라 쪽)", "line"),
		(FAC, "시설", "fac"),
		(ALLEY, "뒷골목 동선", "dash"),
		((60, 46, 40), "빗금 = 카메라에서 가려진 땅", "hatch"),
		(WALL, "검은 띠 = 옹벽(단 경계)·성벽", "box"),
		(YARD, "안뜰·뒷마당", "box"),
	]
	for c, t, kind in items:
		if kind == "line":
			d.line([(x, y + 9), (x + 22, y + 9)], fill=c, width=3)
		elif kind == "dash":
			d.line([(x, y + 9), (x + 8, y + 9)], fill=c, width=3)
			d.line([(x + 13, y + 9), (x + 22, y + 9)], fill=c, width=3)
		elif kind == "fac":
			d.rectangle([x, y + 2, x + 22, y + 16], fill=c, outline=BONE, width=2)
		elif kind == "hatch":
			d.rectangle([x, y + 2, x + 22, y + 16], fill=(66, 60, 52))
			for k in range(0, 30, 6):
				d.line([(x + k, y + 2), (x + k - 14, y + 16)], fill=(40, 30, 26), width=2)
		else:
			d.rectangle([x, y + 2, x + 22, y + 16], fill=c)
		d.text((x + 30, y), t, font=f, fill=BONE)
		y += 21


# ---------- 구상안 ----------

def common(p: Plan, west_gate_z: float, canal: bool = True):
	p.walls.append(([(X0 + 1, Z0 + 1), (X1 - 1, Z0 + 1)], 7.0))
	p.walls.append(([(X0 + 1, Z0 + 1), (X0 + 1, west_gate_z - 3)], 7.0))
	p.walls.append(([(X0 + 1, west_gate_z + 3), (X0 + 1, Z1 - 1)], 7.0))
	p.walls.append(([(X1 - 1, Z0 + 1), (X1 - 1, Z1 - 1)], 7.0))
	p.walls.append(([(X0 + 1, Z1 - 1), (X1 - 1, Z1 - 1)], 7.0))
	p.label(X0 + 6, west_gate_z, "서문", "note")
	if canal:
		p.water.append((X0 + 2, 35.5, X1 - 2, 39.5))
		p.label(-50, 37.5, "수로", "note")


def plan_a() -> Plan:
	p = Plan("a", "안 1 · 계단 띠", "언덕을 등고선대로 깎은 단마다 거리 하나 + 집 한 줄 + 옹벽 밑 뒷골목")
	b_top, b_up = bent(-40), bent(-22)
	p.bands = [(b_top, TOP), (b_up, UP), (flat(10), MID), (flat(26), LOW), (flat(Z1 + 2), CANAL)]
	common(p, -4)
	# 꼭대기 단: 집 줄(앞 = 꼭대기 거리) · 신전 · 원형 도서관
	p.row(shift(b_top, -6), 11, st=(2, 4), skip=[(-11, 11), (-66, -50)])
	p.box(-9, -45, 18, 10, 12.0, "신전")
	p.rounds.append((-60, -43.5, 6.0, 7.0, "도서관"))
	p.yards += [[(-78, -57), (-36, -57), (-36, -48), (-78, -48)], [(36, -57), (78, -57), (78, -48), (36, -48)]]
	p.label(57, -52.5, "뒤뜰·작은 정원", "alley")
	# 위 단: 거리 · 집 줄(계단 골목 하나)
	p.row(shift(b_up, -9.5), 12, st=(2, 3), skip=[(8, 11)])
	# 광장 단: 길드(광장 북서) · 정면 줄 · 사선(여관) · 거울 사선 · 은행 거리
	p.box(-16, -12.5, 11, 7, 6.0, "탐험가 길드")
	p.row(shift(b_up, 9.5), 13, st=(2, 4), skip=[(-17, -4), (-3.5, -0.5), (22, 33), (40, 55)], x_from=-80)
	p.box(23, -12.5 + 3 * SL, 11, 6, 5.2, "여관", yaw=-28.8)
	p.box(42, -12.5 + 15 * SL, 12, 7, 6.0, "은행")
	p.plazas.append((0, -2, 9))
	p.stairs += [(-3.5, -23.5, -0.5, -18.0, UP, MID), (8.0, -42.0, 11.0, -36.0, TOP, UP), (-3, 10, 3, 15, MID, LOW)]
	p.walls.append(([(-80, 9.6), (-3, 9.6)], 0.6))
	p.walls.append(([(3, 9.6), (80, 9.6)], 0.6))
	# 아래 단: 낮은 집 줄(옹벽 밑 뒷골목) · 잡화점
	p.row(shift(flat(10), 8.5), 14, st=(1, 2), depth=(4, 5.5), skip=[(-5, 5), (14, 25)])
	p.box(14, 18.5, 10, 6, 4.0, "잡화점")
	# 수로 단: 작업장 줄 · 대장간
	p.row(shift(flat(26), 7.5), 15, st=(1, 2), depth=(4, 5.5), skip=[(36, 50)])
	p.box(37, 33.5, 12, 7, 4.5, "대장간")
	# 뒷골목(옹벽 밑 띠)
	for line in (shift(b_top, -18.5), shift(b_up, -16.5), shift(b_up, -1.6), shift(flat(10), 1.4), shift(flat(26), 1.4)):
		p.paths.append([(x, z) for x, z in line if X0 + 3 <= x <= X1 - 3] if len(line) > 2 else [(X0 + 4, line[0][1]), (X1 - 4, line[0][1])])
	p.label(0, 3.5, "차원광장", "fac").label(-55, -5, "광장 단 거리", "street").label(-30, 22, "아래 거리", "street")
	p.label(-58, -24, "위 단 거리", "street").label(-30, -42, "꼭대기 거리", "street").label(60, 32.5, "수로 거리", "street")
	p.label(-34, -19.5, "뒷골목(옹벽 밑)", "alley").label(55, 12, "뒷골목", "alley").label(0, 16.5, "큰 계단", "note")
	p.label(-2, -26, "골목 계단", "note")
	p.section_x = -10
	p.notes = [
		("짜임", "단 하나 = 거리 → 집 한 줄(문이 거리 쪽) → 옹벽 밑 뒷골목. 단이 언덕 꼴로 광장 둘레에서 휘어서 휘는 곳의 집이 사선 판·뒤집은 사선 판이 된다(여관 = 사선)."),
		("뒷골목", "옹벽 밑 좁은 띠. 앞줄 집에 가려 숨어 있다 — 들어가면 앞줄이 흐려진다. 양 끝이 계단·틈으로 거리와 이어진다. 뒷문·쓰레기·빨래·하수 구멍 자리."),
		("좋은 점", "가장 단순하다. 단마다 거리가 늘 보여서 길을 잃지 않는다. v2 구상 그림과 같은 짜임이라 바로 만들 수 있다."),
		("아쉬움", "띠가 길게 반복돼 단조롭다. 뒷골목이 모두 '옹벽 밑 한 줄'이라 갈림길이 적다."),
	]
	return p


def plan_b() -> Plan:
	p = Plan("b", "안 2 · 빗살 골목", "평지에 긴 줄을 넓게 띄워 놓고, 줄 사이 숨은 땅을 뒷골목·뒤뜰로 채운다")
	p.bands = [(flat(-20), UP), (flat(12), MID), (flat(Z1 + 2), LOW)]
	common(p, -2)
	rows = [(-48.0, UP, 21), (-26.0, UP, 22), (-11.0, MID, 23), (24.0, LOW, 24)]
	# 위 단(평지) — 앞줄 둘. 줄 사이 15칸 남짓 = 앞줄에 가려진 뒷골목 지대
	p.row(flat(-48), 21, st=(2, 4), lanes=3, skip=[(-12, 12)])
	p.box(-11, -47, 22, 9, 12.0, "신전")
	p.row(flat(-27), 22, st=(2, 3), lanes=4, skip=[(-66, -48), (46, 50)])
	p.rounds.append((-57, -33, 6.0, 7.0, "도서관"))
	# 광장 단
	p.box(-17, -11.5, 11, 7, 6.0, "탐험가 길드")
	p.row(flat(-11), 23, st=(2, 4), lanes=3, skip=[(-18, -5), (-3.5, -0.5), (44, 58)])
	p.row([(10, -11), (32, -11 + 22 * SL)], 25, st=(2, 3), depth=(4.5, 5.5))
	p.box(45, -11, 12, 8, 6.0, "은행")
	p.plazas.append((0, 0, 9))
	p.stairs += [(-3.5, -22.5, -0.5, -17.5, UP, MID), (-3, 12, 3, 17, MID, LOW)]
	p.walls.append(([(-80, 11.6), (-3, 11.6)], 0.6))
	p.walls.append(([(3, 11.6), (80, 11.6)], 0.6))
	# 아래 단 — 시장 줄 + 수로 옆
	p.row(flat(25), 24, st=(1, 3), lanes=3, skip=[(-4, 4), (12, 23), (38, 50)])
	p.box(12, 25, 11, 6, 4.2, "잡화점")
	p.box(38, 25, 12, 7, 4.5, "대장간")
	# 뒷골목 지대: 줄 뒤 평행 골목 + 빗살 틈 + 뒤뜰·헛간
	for z, seed in ((-54.5, 31), (-33.0, 32), (-17.5, 33), (18.5, 34)):
		p.paths.append([(X0 + 4, z), (X1 - 4, z)])
		rng = random.Random(seed)
		x = X0 + 6
		while x < X1 - 12:
			if rng.random() < 0.45:
				p.yards.append([(x, z - 1.2), (x + 6, z - 1.2), (x + 6, z - 5.5), (x, z - 5.5)])
			elif rng.random() < 0.5:
				p.box(x, z - 1.4, rng.uniform(3, 4.5), 3.0, top_of(1), kind="shed")
			x += rng.uniform(9, 14)
	p.label(0, 4.5, "차원광장", "fac").label(-55, -5, "광장 거리", "street").label(-60, -23, "위 거리", "street")
	p.label(-40, -44, "신전 거리", "street").label(-58, 30, "시장 거리", "street")
	p.label(30, -36, "뒷골목 · 뒤뜰", "alley").label(-35, 15.5, "뒷골목", "alley").label(25, -57.5, "뒷골목", "alley")
	p.label(0, 19, "큰 계단", "note").label(21, -2, "사선 줄", "note")
	p.section_x = -30
	p.notes = [
		("짜임", "땅을 거의 평평하게 두고 앞줄을 20칸 남짓 간격으로 띄운다. 앞줄 뒤 15칸쯤은 카메라에서 가려진다 — 이 숨은 띠를 통째로 뒷골목·뒤뜰·헛간으로 쓴다."),
		("뒷골목", "줄 뒤에 나란히 달리는 골목 하나 + 집 3~4채마다 뚫린 좁은 틈(빗살)로 앞 거리와 이어진다. 틈 몇 개는 집 밑 아치 통로. 막다른 뒤뜰이 여기저기 붙는다. 뒷골목이 가장 많은 안."),
		("좋은 점", "옹벽이 적어 계단·높낮이 일이 적다. 뒷골목이 촘촘해 숨은 곳·지름길·뒤질 곳을 넣기 좋다. 화면에는 집 앞면이 층층이 쌓여 빽빽해 보인다."),
		("아쉬움", "평지라 단이 주는 '올라가는 동네' 맛이 약하다. 뒷골목은 거의 다 가려져서 걸어 들어갈 때마다 앞줄이 흐려진다."),
	]
	return p


C, Sn = math.cos(math.radians(28.8)), math.sin(math.radians(28.8))


def fan_block(p: Plan, x0: float, x1: float, zf: float, L: float, seed: int, zs: float, back: bool = True, back_st=(3, 4), gate: bool = True):
	"""안 3 덩어리: 뒷줄(x0~x1, 앞 = zf, 안마당을 봄) + 서쪽 날개(뒤집은 사선 — 남남동) + 동쪽 날개(사선 — 남남서) + 남쪽 낮은 담(zs)."""
	if back:
		p.row([(x0, zf), (x1, zf)], seed, st=back_st, depth=(5, 6), jitter=0.5)
	wa, wb = (x0 - L * C, zf + 1.0 + L * Sn), (x0 - 0.2, zf + 1.0)
	ea, eb = (x1 + 0.2, zf + 1.0), (x1 + L * C, zf + 1.0 + L * Sn)
	p.row([wa, wb], seed + 1, st=(2, 3), depth=(4, 5), jitter=0.3, w=(3.6, 5.0))
	p.row([ea, eb], seed + 2, st=(2, 3), depth=(4, 5), jitter=0.3, w=(3.6, 5.0))
	p.yards.append([(x0, zf + 0.4), (x1, zf + 0.4), (eb[0] - 0.6, eb[1] + 0.4), (eb[0] - 0.6, zs), (wa[0] + 0.6, zs), (wa[0] + 0.6, wa[1] + 0.4)])
	if zs - wa[1] > 1.0:
		p.walls.append(([(wa[0], wa[1] + 0.5), (wa[0], zs)], 1.1))
		p.walls.append(([(eb[0], eb[1] + 0.5), (eb[0], zs)], 1.1))
	mid = (x0 + x1) / 2
	if gate:
		p.walls.append(([(wa[0], zs), (mid - 1.8, zs)], 1.1))
		p.walls.append(([(mid + 1.8, zs), (eb[0], zs)], 1.1))
	return wa[0], eb[0]


def plan_c() -> Plan:
	p = Plan("c", "안 3 · 부채꼴 안마당", "첫 구상의 덩어리 동네를 남쪽으로 열어서 — 덩어리마다 뒷줄 + 비스듬히 벌어진 날개 + 안마당")
	p.bands = [(flat(-30), TOP), (flat(10), MID), (flat(Z1 + 2), LOW)]
	common(p, -4)
	# 꼭대기 단(+7.2): 신전(앞뜰이 안마당) · 덩어리 · 원형 도서관
	p.box(-10, -47, 20, 10, 12.0, "신전")
	p.yards.append([(-10, -46.6), (10, -46.6), (13, -36), (-13, -36)])
	fan_block(p, -42, -26, -48, 9, 40, -36)
	fan_block(p, 26, 42, -48, 9, 42, -36)
	fan_block(p, 62, 72, -50, 6, 44, -38, back_st=(2, 3))
	p.rounds.append((-66, -44, 6.0, 7.0, "도서관"))
	# 광장 단(0): 광장 = 가장 큰 부채꼴 마당 — 뒷줄 = 길드 + 집 줄, 서쪽 날개 = 거울 사선 줄, 동쪽 날개 = 여관(사선)
	p.box(-15, -14, 11, 8, 6.0, "탐험가 길드")
	p.row([(-3.2, -14), (14, -14)], 50, st=(3, 4), skip=[(-3.2, 0.2)])
	p.row([(-15 - 13 * C, -13 + 13 * Sn), (-15.2, -13)], 51, st=(2, 3), depth=(4.5, 5.5))
	p.box(14.2, -13, 13, 6, 5.2, "여관", yaw=-28.8)
	p.plazas.append((0, -2, 9))
	fan_block(p, -62, -46, -20, 9, 52, -7)
	fan_block(p, 36, 50, -20, 8, 53, -7)
	p.box(64, -2, 12, 7, 6.0, "은행")
	p.row([(-80, -2), (-73, -2)], 55, st=(2, 3))
	p.stairs += [(-3, -35, 0.2, -30, TOP, MID), (-3, 10, 3, 15, MID, LOW)]
	p.walls.append(([(-80, 9.6), (-3, 9.6)], 0.6))
	p.walls.append(([(3, 9.6), (80, 9.6)], 0.6))
	# 아래 단(−3.6): 시장 마당(잡화점이 뒷줄 가운데 — 담 없이 열림) · 집 덩어리 · 대장간 마당(수로 옆)
	p.row([(-62, 17), (-52, 17)], 60, st=(2, 3), depth=(4.5, 5.5))
	p.box(-52, 17, 12, 6, 4.2, "잡화점")
	p.row([(-40, 17), (-30, 17)], 61, st=(2, 3), depth=(4.5, 5.5))
	fan_block(p, -62, -30, 17, 10, 62, 29, back=False, gate=False)
	fan_block(p, 14, 28, 17, 8, 63, 28, back_st=(1, 2))
	p.box(44, 22, 12, 7, 4.5, "대장간")
	p.yards.append([(44, 22.6), (56, 22.6), (56, 30), (44, 30)])
	# 뒷골목 = 덩어리 사이 틈 · 뒷줄 뒤 띠 · 옹벽 밑
	p.paths += [[(-50, -57), (-20, -57)], [(18, -57), (48, -57)], [(-20, -38), (-20, -28.5), (-56, -28.5), (-56, -26)],
				[(-38, -6), (-38, -26), (30, -26)], [(60, -26), (60, -8)], [(-70, 11.5), (-20, 11.5)], [(6, 11.5), (40, 11.5)],
				[(40, 11.5), (40, 30)]]
	p.label(0, 3.5, "차원광장", "fac").label(-54, -10.5, "안마당", "alley").label(-34, -39.5, "안마당", "alley").label(43, -10.5, "안마당", "alley")
	p.label(-46, 25, "시장 마당", "alley").label(21, 23.5, "안마당", "alley").label(0, -39, "신전 앞뜰", "note").label(-48, -32.5, "꼭대기 거리", "street")
	p.label(-25, 1, "광장 거리", "street").label(-10, 32, "수로 거리", "street").label(0, 16.5, "큰 계단", "note")
	p.label(-28, -24, "뒷골목", "alley").label(62, 13.5, "옹벽 밑 뒷골목", "alley")
	p.section_x = -54
	p.notes = [
		("짜임", "첫 구상처럼 덩어리로 짓되 덩어리의 남쪽 줄을 빼고 낮은 담·문간으로 바꾼다. 뒷줄은 안마당을 보고, 양옆 날개는 28.8°로 벌어져 사선 판(동)·뒤집은 사선 판(서)으로 마당을 본다. 광장도 같은 꼴 — 길드가 뒷줄, 여관이 동쪽 날개."),
		("뒷골목", "두 겹이다. ① 안마당 — 담 너머로 카메라에서 다 보인다(우물·빨래·통·막다른 문). ② 덩어리 사이 틈과 뒷줄 뒤 띠 — 가려진 진짜 뒷골목. '대문 → 마당 → 뒷문 → 골목 → 다른 마당'으로 이어진다."),
		("좋은 점", "첫 구상의 오밀조밀한 덩어리 느낌이 가장 많이 남는다. 집이 두 줄로 겹치지 않으면서 마당이 보여서 사람 사는 동네 같다. 세 방향 판을 고르게 쓴다."),
		("아쉬움", "문 대부분이 큰길이 아니라 마당 안에 있다 — 가게·시설은 덩어리 밖(거리 쪽)으로 따로 뺀다. 덩어리가 똑같이 반복되지 않게 날개 길이·마당 꼴을 섞어야 한다."),
	]
	return p


def plan_d() -> Plan:
	p = Plan("d", "안 4 · 부채 골목", "광장에서 거리가 사선으로 부채처럼 퍼지고, 거리 사이 세모 덩어리 속이 뒷골목")
	p.bands = [(flat(-34), UP), (flat(12), MID), (flat(Z1 + 2), LOW)]
	common(p, 4)
	p.plazas.append((0, 0, 9))
	# 광장 북쪽 세모 덩어리들: 서쪽 변 = 사선 줄(남남서), 동쪽 변 = 거울 사선 줄(남남동) — 등을 맞대지 않고 속이 빈다
	fans = [(-9.5, -9.5, 50), (12.0, -21.5, 51)]
	# 북동 사선 거리(광장 → 북동): 거리 북서쪽에 거울 사선 줄
	p.row([(10, -10), (38, -10 - 28 * SL)], 52, st=(2, 4), depth=(4.5, 5.5))
	p.row([(10, 1.5), (52, 1.5 - 42 * SL)], 53, st=(2, 3), depth=(4.5, 5.5), skip=[(28, 41)])
	p.box(28, 1.5 - 18 * SL, 13, 6, 5.2, "여관", yaw=28.8)
	# 북서 사선 거리(광장 → 북서): 거리 북동쪽에 사선 줄
	p.row([(-38, -10 - 28 * SL), (-10, -10)], 54, st=(2, 4), depth=(4.5, 5.5))
	p.row([(-56, 4 - 46 * SL), (-14, 4.0)], 55, st=(2, 3), depth=(4.5, 5.5), skip=[(-36, -23)])
	# 길드: 광장 서쪽 — 정면, 서쪽 거리 머리
	p.box(-24, 4 - 10 * SL, 12, 7, 6.0, "탐험가 길드", yaw=-28.8)
	# 광장 북쪽 머리: 정면 줄
	p.row([(-9, -12), (9, -12)], 56, st=(3, 4))
	# 위 단: 정면 줄 둘(부채가 닿는 곳) · 신전 · 도서관
	p.row(flat(-40), 57, st=(2, 4), skip=[(-11, 11), (-68, -52)])
	p.box(-10, -40, 20, 12, 12.0, "신전")
	p.rounds.append((-60, -46, 6.0, 7.0, "도서관"))
	p.row([(-80, -18), (-58, -18)], 58, st=(2, 3))
	p.row([(58, -18), (80, -18)], 59, st=(2, 3))
	p.box(60, 6, 13, 8, 6.0, "은행")
	p.row([(-80, 8), (-62, 8)], 60, st=(2, 3))
	p.stairs += [(-2, -37, 2, -32, UP, MID), (-3, 12, 3, 17, MID, LOW)]
	p.walls.append(([(-80, 11.6), (-3, 11.6)], 0.6))
	p.walls.append(([(3, 11.6), (80, 11.6)], 0.6))
	# 아래 단: 수로까지 Λ 시장
	p.row([(-34, 20 + 28 * SL), (-6, 20)], 61, st=(1, 2), depth=(4, 5))
	p.row([(6, 20), (34, 20 + 28 * SL)], 62, st=(1, 2), depth=(4, 5), skip=[(21, 34)])
	p.box(21.5, 20 + 15.5 * SL, 12, 5.5, 4.0, "잡화점", yaw=-28.8)
	p.box(52, 26, 12, 6, 4.5, "대장간")
	p.row([(-80, 26), (-50, 26)], 63, st=(1, 2))
	# 뒷골목 = 세모 덩어리 속(사선 줄 둘의 등 사이)
	p.paths += [[(-24, -21), (-12, -26), (0, -20), (12, -26), (24, -21)], [(-40, -12), (-30, -4)], [(40, -12), (30, -4)],
				[(-30, 22), (-14, 14), (0, 19), (14, 14), (30, 22)]]
	p.yards.append([(-6, -18), (6, -18), (0, -27)])
	p.label(0, 5, "차원광장", "fac").label(0, -31, "세모 속 뒷골목", "alley").label(38, -26, "북동 사선 거리", "street")
	p.label(-38, -26, "북서 사선 거리", "street").label(0, 23, "Λ 시장", "street").label(-22, 22, "시장 뒷골목", "alley")
	p.label(-50, -43, "위 거리", "street").label(0, 18.5, "큰 계단", "note")
	p.section_x = 4
	p.notes = [
		("짜임", "광장에서 거리가 셋(북서 사선 · 북 정면 · 북동 사선)으로 퍼진다. 사선 거리마다 북쪽 편에만 집이 서서(사선 판·뒤집은 사선 판), 거리와 거리 사이가 세모 덩어리가 된다. 남쪽은 Λ 시장이 수로까지."),
		("뒷골목", "세모 덩어리 속 — 두 줄이 등을 맞대지 않고 속을 비워서 꺾이고 좁아지는 뒷골목이 된다. 거의 다 가려져 있고 세모 꼭짓점의 틈으로 들어간다."),
		("좋은 점", "가장 중세 도시 같다(길이 비스듬히 갈라지고 모이는 곳마다 작은 광장). 사선 판을 가장 많이 쓴다. 광장이 진짜 '모든 길이 모이는 곳'이 된다."),
		("아쉬움", "사선 거리는 W/S로 걸을 때 벽을 따라 미끄러져야 한다. 줄이 짧게 끊겨 집 그림 이음매가 많다. 길드가 사선 판이 된다(정면을 원하면 광장 서쪽 머리를 정면 줄로)."),
	]
	return p


def overview(boards: list) -> Image.Image:
	tw = 780
	ims = []
	for p, im in boards:
		plan = draw_plan(p)
		th = int(plan.height * tw / plan.width)
		ims.append((p, plan.resize((tw, th), Image.LANCZOS)))
	th = ims[0][1].height
	M = 16
	out = Image.new("RGB", (M + 2 * (tw + M), M + 2 * (th + 40 + M)), BG)
	d = ImageDraw.Draw(out)
	for i, (p, im) in enumerate(ims):
		x = M + (i % 2) * (tw + M)
		y = M + (i // 2) * (th + 40 + M)
		d.text((x, y), p.title, font=font(22), fill=BONE)
		out.paste(im, (x, y + 36))
	return out


def main():
	os.makedirs(OUT, exist_ok=True)
	open(os.path.join(OUT, ".gdignore"), "w").close()
	boards = []
	for fn in (plan_a, plan_b, plan_c, plan_d):
		p = fn()
		im = board(p)
		path = os.path.join(OUT, f"{p.key}.png")
		im.save(path, optimize=True)
		boards.append((p, im))
		print("wrote", path, im.size)
	ov = overview(boards)
	ov.save(os.path.join(OUT, "overview.png"), optimize=True)
	print("wrote overview", ov.size)


if __name__ == "__main__":
	main()
