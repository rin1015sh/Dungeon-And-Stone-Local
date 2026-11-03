"""도시 구상 v3 — 세로로 긴 7구역(첫 구상 160 × 220) · 집마다 살짝 뒤틀린 각도 · 하수도 · 도시에 있을 법한 곳 다(퀘스트 자리).
  python3 tools/town_v3.py   → docs/plans/town/v3/{a,b,c}.png(배치도 + 탐험 화면 3/4 상자 그림 + 장소 번호) · overview.png
사용자 2026-11-03 "각을 틀어서 쓴 게 반듯이 비행기 날개마냥 붙이라는 게 아니라 살짝 이리저리 뒤틀린(참고 그림처럼) 마을 ·
맨 처음에 뽑은 세로로 긴, 하수도 있는 그런 걸로 · 도시에 있을 법한 거 다 넣고 퀘스트용으로도 쓰게 · 여러 개 기획서".
기획서 docs/plans/city_town_v3.md. 안마다 배치는 tools/town_v3_plans.py.

집 놓기: 길(꺾은선)을 따라 길 북쪽 편에 한 채씩 — 각도 = 길 방향 + 조금씩 다른 뒤틀림(±10° 남짓), 앞으로 물러섬도 집마다 다르다.
남북으로 달리는 길은 양옆에 남쪽을 보는 집을 엇갈려 쌓는다(참고 그림의 계단 길). 문은 늘 카메라 쪽(남 ±45°)이고,
문 앞 1.6칸은 비워 둔다(그래서 남는 틈이 저절로 뒷골목·안뜰이 된다). 빈 땅은 마지막에 안쪽 집으로 듬성듬성 채운다.
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_layouts as tl  # noqa: E402
import town_plaza as tp  # noqa: E402  (불러오면 탐험 화면 3/4 투영)
from town_layouts import Plan, top_of, font  # noqa: E402

X0, X1, Z0, Z1 = -80, 80, -150, 70
STAIR_W = 3.6  ## 계단 폭(칸 — 모두 같게, CT98)
MS = 2  # 자리 판 해상도(칸당 px)
BOARD_S = 4  # 배치도 · 3/4 그림 배율(칸당 px)


def set_extent(x0: int, x1: int, z0: int, z1: int, board_s: int):
	"""작은 판(1/4 안 등)을 그릴 때 동네 넓이를 바꾼다 — Town · wig · board가 이 값을 읽는다."""
	global X0, X1, Z0, Z1, BOARD_S
	X0, X1, Z0, Z1, BOARD_S = x0, x1, z0, z1, board_s
OUT = os.path.join(tl.ROOT, "docs", "plans", "town", "v3")


def wig(z: float, seed: int, amp: float = 3.0, step: float = 14.0) -> list:
	"""구불구불한 동서 경계선."""
	r = random.Random(seed)
	pts, x = [], X0 - 2
	while x < X1 + 2:
		pts.append((x, z + r.uniform(-amp, amp)))
		x += step
	pts.append((X1 + 2, z + r.uniform(-amp, amp)))
	return pts


def rect(cx: float, cz: float, w: float, d: float, yaw: float) -> list:
	"""앞면 가운데(cx, cz)에서 너비 w · 뒤로 깊이 d. yaw > 0이면 동쪽 끝이 북쪽으로(앞이 남남동)."""
	t = math.radians(yaw)
	ux, uz = math.cos(t), -math.sin(t)
	nx, nz = math.sin(t), math.cos(t)
	p0 = (cx - ux * w / 2, cz - uz * w / 2)
	p1 = (cx + ux * w / 2, cz + uz * w / 2)
	return [p0, p1, (p1[0] - nx * d, p1[1] - nz * d), (p0[0] - nx * d, p0[1] - nz * d)]


class Town:
	def __init__(self, key: str, title: str, one: str, seed: int):
		self.p = Plan(key, title, one)
		self.p.arcades = []
		self.W, self.H = (X1 - X0) * MS, (Z1 - Z0) * MS
		self.mask = np.zeros((self.H, self.W), np.uint8)  # 0 빈 땅 · 1 길·마당(지을 수 없지만 문 앞으로는 된다) · 2 건물·옹벽 · 3 물·지도 밖
		self.road = np.zeros((self.H, self.W), bool)  # 길 · 골목 · 광장 · 다리 · 문 앞(이어진 길 — 문 앞이 여기에 닿아야 집을 놓는다, CT98)
		self.door = np.zeros((self.H, self.W), bool)  # 문 앞(소품을 놓지 않는 곳)
		self.need_road = False  # 켜면 문 앞이 길에 닿는 집만 놓는다
		self.road_reach = 2  # 문 앞에서 길까지 몇 칸(자리 판 px) 안이면 닿았다고 보나 — 안쪽 집은 뒷마당 너머 가까운 길
		self.props: list = []  # (종류, x, z, 폭, 깊이) — 거리 소품(CT98)
		self.lane_n = 0
		self.st: dict = {}
		self.rng = random.Random(seed)
		self.places: dict = {}
		# 집 놓기 기준(안마다 바꿀 수 있다): 문 앞 비울 깊이 · 문 앞이 막혀도 되는 몫 · 다른 것과 겹쳐도 되는 몫
		self.strip = 1.6
		self.strip_block = 0.25
		self.overlap = 0.03
		self.street_overlap = 0.03  # 길 · 마당 칸에 걸쳐도 되는 몫(건물과 겹침은 overlap)

	# ----- 자리 판 -----
	def m(self, x, z):
		return ((x - X0) * MS, (z - Z0) * MS)

	def pmask(self, poly):
		im = Image.new("L", (self.W, self.H), 0)
		ImageDraw.Draw(im).polygon([self.m(*q) for q in poly], fill=1)
		return np.array(im).astype(bool)

	def lmask(self, pts, w):
		im = Image.new("L", (self.W, self.H), 0)
		d = ImageDraw.Draw(im)
		q = [self.m(*a) for a in pts]
		d.line(q, fill=1, width=max(1, int(w * MS)))
		for x, y in q:
			r = w * MS / 2
			d.ellipse([x - r, y - r, x + r, y + r], fill=1)
		return np.array(im).astype(bool)

	# ----- 땅 -----
	def ground(self, bands: list, outline: list):
		"""bands = [(남쪽 경계 선, 높이)] 북→남. 경계(옹벽)는 집이 걸치지 않게 막아 둔다."""
		self.p.bands = bands
		self.bands = bands
		self.p.outline = outline
		inside = self.pmask(outline)
		self.mask[~inside] = 3
		for line, _h in bands[:-1]:
			self.mask[self.lmask(line, 1.4) & (self.mask < 2)] = 2

	def height_at(self, x: float, z: float) -> float:
		h = self.bands[-1][1]
		for line, hh in reversed(self.bands):
			if z < tl.zline(line, x):
				h = hh
		return h

	def street(self, name: str, pts: list, w: float):
		self.p.streets.append((pts, w))
		self.st[name] = (pts, w)
		lm = self.lmask(pts, w)
		self.mask[lm & (self.mask != 3)] = 1
		self.road |= lm & (self.mask != 3)
		# 옹벽을 건너는 곳은 계단(폭은 모두 같게 — CT98)
		for line, h_n in self.bands[:-1]:
			for (ax, az), (bx, bz) in zip(pts, pts[1:]):
				za, zb = az - tl.zline(line, ax), bz - tl.zline(line, bx)
				if za * zb < 0:
					t = za / (za - zb)
					x = ax + (bx - ax) * t
					zc = tl.zline(line, x)
					lo = self.height_at(x, zc + 3)
					hw = STAIR_W / 2
					self.p.stairs.append((x - hw, zc - 2.4, x + hw, zc + 2.4, h_n, lo))

	def opened(self, poly: list, kind: str = "yard"):
		"""마당·광장·묘지 — 집을 짓지 않는 땅."""
		if kind == "yard":
			self.p.yards.append(poly)
		elif kind == "paving":
			self.p.pavings.append(poly)
		pm = self.pmask(poly) & (self.mask != 3)
		self.mask[pm] = 1
		if kind == "paving":
			self.road |= pm

	def channel(self, pts: list, w: float, lv: float):
		self.p.channels.append((pts, w, lv))
		self.mask[self.lmask(pts, w)] = 3

	def bridge(self, pts: list, w: float):
		x, z = (pts[0][0] + pts[-1][0]) / 2, (pts[0][1] + pts[-1][1]) / 2
		self.p.bridges.append((pts, w, self.height_at(x, z)))
		lm = self.lmask(pts, w)
		self.mask[lm] = 1
		self.road |= lm

	# ----- 집 -----
	def try_house(self, poly, front, top, kind="house", name="", force=False, strip=None) -> bool:
		strip = self.strip if strip is None else strip
		pm = self.pmask(poly)
		if not pm.any():
			return False
		(ax, az), (bx, bz) = front
		L = math.hypot(bx - ax, bz - az)
		nx, nz = -(bz - az) / L, (bx - ax) / L
		sm = self.pmask([(ax, az), (bx, bz), (bx + nx * strip, bz + nz * strip), (ax + nx * strip, az + nz * strip)])
		if not force:
			if (self.mask[pm] >= 2).mean() > self.overlap or (self.mask[pm] == 1).mean() > self.street_overlap:
				return False
			if sm.any() and (self.mask[sm] >= 2).mean() > self.strip_block:
				return False
			if self.need_road and not (self._grow(sm, self.road_reach) & self.road).any():  # 문 앞이 길 · 골목에 닿지 않는 집은 놓지 않는다
				return False
		self.mask[pm] = 2
		self.mask[sm & (self.mask == 0)] = 1
		self.road |= sm & (self.mask == 1)
		cx, cz = (ax + bx) / 2, (az + bz) / 2
		dz = self.pmask([(cx - 0.9 * (bx - ax) / L, cz - 0.9 * (bz - az) / L), (cx + 0.9 * (bx - ax) / L, cz + 0.9 * (bz - az) / L),
						(cx + 0.9 * (bx - ax) / L + nx * 1.8, cz + 0.9 * (bz - az) / L + nz * 1.8), (cx - 0.9 * (bx - ax) / L + nx * 1.8, cz - 0.9 * (bz - az) / L + nz * 1.8)])
		self.door |= dz
		self.p.houses.append({"poly": poly, "front": front, "top": top, "kind": kind, "name": name})
		return True

	@staticmethod
	def _grow(m, n):
		for _ in range(n):
			m = m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)
		return m

	def spot(self, kind, x, z, w=1.0, d=1.0) -> bool:
		"""거리 소품 하나(x, z = 가운데): 길 · 마당 위이고 문 앞 · 집 · 다른 소품이 아닌 곳에만(CT98). 놓으면 그 자리를 막는다."""
		pm = self.pmask([(x - w / 2, z - d / 2), (x + w / 2, z - d / 2), (x + w / 2, z + d / 2), (x - w / 2, z + d / 2)])
		if not pm.any() or (self.mask[pm] >= 2).any() or (pm & self.door).any():
			return False
		self.mask[pm] = 2
		self.props.append((kind, x, z, w, d))
		return True

	def fit(self, cx, cz, w, d, yaw, top, front_fixed: bool = True) -> bool:
		"""맞는 가장 큰 크기로(깊이부터 줄이고, 그다음 폭) — 큰 집이 조금 겹친다고 작은 집으로 건너뛰지 않게(CT96)."""
		for kw in (1.0, 0.85, 0.7):
			for kd in (1.0, 0.85, 0.7, 0.55):
				ww, dd = w * kw, d * kd
				if ww < 3.2 or dd < 3.2:
					continue
				if self.house(cx, cz if front_fixed else cz - (d - dd) * 0.5, ww, dd, yaw, top * (0.85 + 0.15 * kd)):
					return True
		return False

	def house(self, cx, cz, w, d, yaw, top, kind="house", name="", force=False) -> bool:
		poly = rect(cx, cz, w, d, yaw)
		ok = self.try_house(poly, (poly[0], poly[1]), top, kind, name, force)
		if ok:
			self.p.houses[-1].update({"yaw": yaw, "front_c": (cx, cz), "wd": (w, d)})
		return ok

	def along(self, name: str, seed: int, st=(2, 4), w=(4.5, 7.5), d=(5.0, 8.0), yj=11.0, setback=(0.2, 1.2), gap=(0.0, 0.7), ns_side=(-1, 1),
			lane_every: int = 0, lane_w: float = 2.4):
		"""길을 따라 집 — 동서 길은 북쪽 편, 남북 길은 양옆에 남쪽을 보는 집을 엇갈려."""
		pts, sw = self.st[name]
		r = random.Random(seed)
		count = 0
		for a, b in zip(pts, pts[1:]):
			if b[0] < a[0]:
				a, b = b, a
			dx, dz = b[0] - a[0], b[1] - a[1]
			L = math.hypot(dx, dz)
			if L < 2:
				continue
			th = math.degrees(math.atan2(-dz, dx))
			ux, uz = dx / L, dz / L
			if abs(th) <= 52:
				nx, nz = -uz, ux
				s = 0.4
				while s < L - 2.5:
					ww, dd, sb = r.uniform(*w), r.uniform(*d), r.uniform(*setback)
					yaw = max(-45.0, min(45.0, th + r.uniform(-yj, yj)))
					cx = a[0] + ux * (s + ww / 2) - nx * (sw / 2 + sb)
					cz = a[1] + uz * (s + ww / 2) - nz * (sw / 2 + sb)
					top = top_of(r.randint(*st)) + r.uniform(-0.3, 0.6)
					placed = self.fit(cx, cz, ww, dd, yaw, top)
					s += ww + r.uniform(*gap)
					if placed:
						count += 1
					if lane_every and placed and count % lane_every == 0 and s < L - 4:
						self._lane(a, ux, uz, nx, nz, s + lane_w / 2, sw, d[1] + 1.5, lane_w)
						s += lane_w
			else:
				s = 1.0
				while s < L - 1:
					qx, qz = a[0] + ux * s, a[1] + uz * s
					for side in ns_side:
						ww, dd, sb = r.uniform(*w), r.uniform(*d) * 0.9, r.uniform(*setback)
						yaw = r.uniform(-yj, yj)
						cx = qx + side * (sw / 2 + sb + ww / 2)
						top = top_of(r.randint(*st)) + r.uniform(-0.3, 0.6)
						self.fit(cx, qz + r.uniform(-1, 1), ww, dd, yaw, top)
					s += (r.uniform(*d) + r.uniform(1.8, 3.2)) / max(abs(uz), 0.5)

	def _lane(self, a, ux, uz, nx, nz, s, sw, length, lw):
		"""길가 집 줄 사이 골목(길에서 뒤로 — 뒷마당 · 안쪽 집으로 들어간다, CT98). 집에 막히면 짧게."""
		x0 = a[0] + ux * s - nx * (sw / 2 - 0.3)
		z0 = a[1] + uz * s - nz * (sw / 2 - 0.3)
		for k in (1.0, 0.7, 0.45):
			x1, z1 = x0 - nx * length * k, z0 - nz * length * k
			lm = self.lmask([(x0, z0), (x1, z1)], lw)
			if (self.mask[lm] >= 2).mean() < 0.02:
				self.lane_n += 1
				self.street("lane%d" % self.lane_n, [(x0, z0), (x1, z1)], lw)
				return

	def fill(self, seed: int, tries: int = 4000, st=(1, 3), w=(4.0, 7.0), d=(4.5, 7.0), yj=18.0):
		"""남은 빈 땅에 안쪽 집(문 앞 틈이 있는 곳에만) — 안쪽 집 사이 틈이 뒷골목이 된다."""
		r = random.Random(seed)
		for _ in range(tries):
			x, z = r.uniform(X0 + 3, X1 - 3), r.uniform(Z0 + 3, Z1 - 3)
			i, j = int((z - Z0) * MS), int((x - X0) * MS)
			if self.mask[i, j] != 0:
				continue
			ww, dd = r.uniform(*w), r.uniform(*d)
			yaw, top = r.uniform(-yj, yj), top_of(r.randint(*st)) + r.uniform(-0.3, 0.5)
			self.fit(x, z + dd / 2, ww, dd, yaw, top, front_fixed=False)

	# ----- 장소 -----
	def street_point(self, name: str, x: float):
		pts, sw = self.st[name]
		for a, b in zip(pts, pts[1:]):
			lo, hi = min(a[0], b[0]), max(a[0], b[0])
			if lo <= x <= hi and hi - lo > 1e-6:
				if b[0] < a[0]:
					a, b = b, a
				t = (x - a[0]) / (b[0] - a[0])
				z = a[1] + (b[1] - a[1]) * t
				th = math.degrees(math.atan2(-(b[1] - a[1]), b[0] - a[0]))
				return z, th, sw
		raise ValueError(f"{name}: x={x} 밖")

	def fac(self, num, w, d, top, street=None, x=None, at=None, yaw=None, name="", setback=0.4, jit=0.0, kind="fac", fid=""):
		"""시설·장소 건물. street + x = 그 길 북쪽 편 · at = (앞면 가운데 x, z)."""
		if street is not None:
			z, th, sw = self.street_point(street, x)
			th = max(-45.0, min(45.0, th + jit))
			t = math.radians(th)
			nx, nz = math.sin(t), math.cos(t)
			cx, cz = x - nx * (sw / 2 + setback), z - nz * (sw / 2 + setback)
			yaw = th if yaw is None else yaw
		else:
			cx, cz = at
			yaw = 0.0 if yaw is None else yaw
		poly = rect(cx, cz, w, d, yaw)
		self.try_house(poly, (poly[0], poly[1]), top, kind, name, force=True)
		self.p.houses[-1].update({"num": num, "facility": fid, "yaw": yaw, "front_c": (cx, cz), "wd": (w, d)})
		mx, mz = sum(q[0] for q in poly) / 4, sum(q[1] for q in poly) / 4
		if num:  # 번호는 앞면 왼쪽 귀퉁이 안쪽(가운데에는 이름이 온다)
			ax, az = poly[0]
			self.mark(num, ax + (mx - ax) * 0.35, az + (mz - az) * 0.35)
		return mx, mz

	def round(self, num, cx, cz, r, top, name=""):
		self.p.rounds.append((cx, cz, r, top, name))
		self.mask[self.pmask([(cx + r * math.cos(a), cz + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 20)])] = 2
		if num:
			self.mark(num, cx, cz)

	def disc(self, num, x, z, r, h, color=(150, 144, 132)):
		self.p.discs.append((x, z, r, h, color))
		self.mask[self.pmask([(x + r * math.cos(a), z + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 12)])] = 2
		if num:
			self.mark(num, x, z)

	def mark(self, num, x, z):
		self.p.markers.append((x, z, num))
		self.places.setdefault(num, []).append((x, z))

	def plaza(self, cx, cz, r):
		"""차원광장: 판석 원 + 세 단 돌 단 + 돌 고리(3/4 그림이 tp.PC에 고리를 세운다)."""
		poly = [(cx + r * math.cos(a), cz + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 28)]
		self.opened(poly, "paving")
		self.p.plazas.append((cx, cz, 0))
		self.p.discs += [(cx, cz, 3.4, 0.3, (168, 160, 142)), (cx, cz, 2.75, 0.6, (176, 168, 150)), (cx, cz, 2.1, 0.9, (184, 176, 158))]
		self.plaza_at = (cx, cz)
		self.mark(1, cx, cz + 5.5)

	def stalls(self, x0, z0, x1, z1, seed, n=6):
		r = random.Random(seed)
		for _ in range(n * 3):
			if n <= 0:
				break
			x, z = r.uniform(x0, x1), r.uniform(z0, z1)
			if self.house(x, z, r.uniform(2.2, 3.0), r.uniform(1.6, 2.2), r.uniform(-15, 15), 2.2, kind="shed", force=False):
				n -= 1

	def graves(self, x0, z0, x1, z1, seed):
		r = random.Random(seed)
		z = z0 + 1.5
		while z < z1 - 1:
			x = x0 + 1.5
			while x < x1 - 1:
				if r.random() < 0.7:
					poly = rect(x + r.uniform(-0.3, 0.3), z, 0.7, 0.3, r.uniform(-12, 12))
					self.p.houses.append({"poly": poly, "front": (poly[0], poly[1]), "top": r.uniform(0.6, 1.1), "kind": "post", "name": ""})
				x += r.uniform(1.6, 2.2)
			z += 2.4

	def sewer(self, pts: list):
		self.p.sewers.append(pts)


# ---------- 그림판 ----------

def board(t: Town, catalog: list, notes: list) -> Image.Image:
	p = t.p
	tp.PC = t.plaza_at
	tp.region(X0, X1, Z0, Z1, BOARD_S)
	plan = tl.draw_plan(p)
	view, _ = tp.camera_view(p)
	M, LW = 18, 540
	H = M + 50 + max(plan.height, view.height) + M
	im = Image.new("RGB", (M + plan.width + M + view.width + M + LW + M, H), tl.BG)
	d = ImageDraw.Draw(im)
	d.text((M, M - 4), p.title, font=font(30), fill=tl.BONE)
	d.text((M + d.textlength(p.title, font=font(30)) + 24, M + 8), p.one, font=font(16), fill=tl.DIM)
	y0 = M + 50
	im.paste(plan, (M, y0))
	im.paste(view, (M + plan.width + M, y0))
	d.text((M + 6, y0 + 6), "위에서 본 배치(번호 = 장소 · 파란 점선 = 하수도 · 주황 = 뒷골목)", font=font(13), fill=tl.BONE)
	d.text((M + plan.width + M + 6, y0 + 6), "탐험 화면과 같은 3/4로 본 상자", font=font(13), fill=tl.BONE)
	x = M + plan.width + M + view.width + M
	y = y0
	f = font(13)
	col_w = LW // 2
	half = (len(catalog) + 1) // 2
	for k, (num, name, _grp, _what, _hook) in enumerate(catalog):
		cx = x + (k // half) * col_w
		cy = y + (k % half) * 19
		have = "" if num in t.places else " ·없음"
		d.text((cx, cy), f"{num:>2}  {name}{have}", font=f, fill=tl.GOLD if num <= 9 else tl.BONE)
	y += half * 19 + 16
	for head, body in notes:
		d.text((x, y), head, font=font(17), fill=tl.GOLD)
		y += 24
		for line in tl.wrap(d, body, font(14), LW):
			d.text((x, y), line, font=font(14), fill=tl.BONE)
			y += 20
		y += 8
	return im, view


def render(fns: list, catalog: list, overview: bool = True):
	os.makedirs(OUT, exist_ok=True)
	open(os.path.join(OUT, ".gdignore"), "w").close()
	views = []
	for fn in fns:
		t, notes = fn()
		im, view = board(t, catalog, notes)
		im.save(os.path.join(OUT, f"{t.p.key}.png"), optimize=True)
		views.append((t.p.title, view))
		# 광장 가까이(게임 화면 한 장쯤 — 가로 72칸)
		cx, cz = t.plaza_at
		tp.region(int(cx) - 36, int(cx) + 36, int(cz) - 40, int(cz) + 30, 9)
		close, _ = tp.camera_view(t.p)
		close = close.crop((0, 12 * 9, close.width, close.height - 4 * 9))
		M = 18
		ci = Image.new("RGB", (M + close.width + M, M + 44 + close.height + M), tl.BG)
		ImageDraw.Draw(ci).text((M, M - 4), t.p.title + " — 광장 가까이(탐험 화면 3/4 · 상자)", font=font(24), fill=tl.BONE)
		ci.paste(close, (M, M + 44))
		ci.save(os.path.join(OUT, f"{t.p.key}_plaza.png"), optimize=True)
		missing = [n for n, *_ in catalog if n not in t.places]
		print("wrote", t.p.key, im.size, "houses", len(t.p.houses), "missing", missing)
	if not overview:
		return
	M = 16
	sc = 0.62
	vs = [(ti, v.resize((int(v.width * sc), int(v.height * sc)), Image.LANCZOS)) for ti, v in views]
	ov = Image.new("RGB", (M + sum(v.width + M for _t, v in vs), M + 40 + vs[0][1].height + M), tl.BG)
	d = ImageDraw.Draw(ov)
	x = M
	for ti, v in vs:
		d.text((x, M), ti, font=font(20), fill=tl.BONE)
		ov.paste(v, (x, M + 36))
		x += v.width + M
	ov.save(os.path.join(OUT, "overview.png"), optimize=True)
	print("wrote overview", ov.size)


def main():
	"""python3 tools/town_v3.py [--small] — --small = 안 A를 넓이 1/4(80 × 110)로 줄인 판(CT94)."""
	import town_v3 as tv  # 배치 파일이 불러 쓰는 같은 모듈(직접 실행한 __main__과 전역이 다르다)
	import town_v3_plans as plans
	if "--small" in sys.argv:
		import town_v3_small as small
		tv.set_extent(*small.EXTENT, 8)
		tv.render([small.plan_a_small], small.CATALOG_S, overview=False)
	else:
		tv.render(plans.PLANS, plans.CATALOG)


if __name__ == "__main__":
	main()
