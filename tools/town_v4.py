"""도시 v4 — 블록형 7구역(사용자 2026-11-03 "그냥 도시 구조 바꾸자. 흩뿌려진 거 말고 맨 처음 기획한 것처럼 딱딱 맞아떨어지게.
다만 각도 비튼 버전이 들어가게. 실제 도시처럼 디자인해 줘", CT100).
  python3 tools/town_v4.py           → docs/plans/town/v4/district.png(배치도 + 3/4 상자) · district_plaza.png
  python3 tools/town_v3_export.py    → data/town/district7.json(이 파일의 plan_v4를 내보낸다)

짜임(맨 처음 구상 district7.png처럼): 길로 나뉜 블록마다 둘레에 줄집을 틈 없이 세운다 — 남쪽 줄은 길을 보고, 북쪽 줄은 등을 길 · 옹벽 · 성벽에
대고 안뜰을 본다, 동서 끝은 세로 줄(남쪽을 보는 집을 쌓는다). 집 폭은 블록 변을 꼭 나눠 떨어지게(n = 변 / 6칸 남짓, 합 = 변 길이).
안뜰은 골목이 뚫린 블록은 흙 뒷마당(빨래 · 우물 · 뒷골목 장소), 막힌 블록은 정원(TownMap이 닿지 않는 땅을 정원으로).
각도: 윗단 · 광장 · 시설 블록은 반듯하고(계획된 중심), 중단 동쪽 옛 골목(+12°)과 아랫단 서쪽 동네(−16°)는 옛길을 따라 비튼 블록이다 —
비튼 블록과 반듯한 블록 사이 쐐기 땅은 작은 광장(돌길)이 된다. 문은 늘 카메라 쪽(남 ±16°).
축: 북문 → 신전 앞뜰 → 큰 계단 → 큰길 → 차원광장 → 시장 계단 → 시장 → 아랫길 → 다리.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_v3 as tv  # noqa: E402
from town_v3 import Town, rect  # noqa: E402
from town_layouts import top_of, flat  # noqa: E402
import town_v3_small as small  # noqa: E402

EXTENT = small.EXTENT
CATALOG = small.CATALOG_S
HIGH, MIDH, LOWH, WATER = 2.0, 0.0, -1.6, -2.8  # 단 높이(칸) — 옹벽 · 계단 턱이 너무 높다(CT102: 3.0 · −2.4 · −4.2에서 낮춤)
GROW = 0.5  # 블록을 길 쪽으로 넓히는 칸(길이 너무 넓다 — CT102)
OUTLINE = [(-38, -73), (38, -73), (38, 33), (-38, 33)]
BAND1, BAND2 = -40.6, -6.6  # 윗단 / 중단 / 아랫단 경계(옹벽 — 위 단의 남쪽 길 바로 아래)


def _sub(a, b):
	return (a[0] - b[0], a[1] - b[1])


def _dot(a, b):
	return a[0] * b[0] + a[1] * b[1]


def _norm(a):
	L = math.hypot(*a)
	return (a[0] / L, a[1] / L)


def _cross(p, d, q, e):
	"""직선 p + t·d 와 q + s·e 의 만나는 점."""
	den = d[0] * e[1] - d[1] * e[0]
	if abs(den) < 1e-9:
		return None
	t = ((q[0] - p[0]) * e[1] - (q[1] - p[1]) * e[0]) / den
	return (p[0] + d[0] * t, p[1] + d[1] * t)


class Blk:
	"""길로 둘러싼 네 모서리 블록(사다리꼴 · 기운 네모 포함): NW · NE · SE · SW. 남쪽 변 = SW → SE(앞), 북쪽 변 = NW → NE."""

	def __init__(self, nw, ne, se, sw):
		self.nw, self.ne, self.se, self.sw = nw, ne, se, sw

	@staticmethod
	def rect(x0, z0, x1, z1):
		return Blk((x0, z0), (x1, z0), (x1, z1), (x0, z1))

	def frame(self, side):
		"""변의 (시작점, 방향 u, 안쪽(블록 쪽) 법선, 길이, yaw)."""
		a, b = (self.sw, self.se) if side == "s" else (self.nw, self.ne)
		u = _norm(_sub(b, a))
		inn = (u[1], -u[0]) if side == "s" else (-u[1], u[0])
		return a, u, inn, math.hypot(*_sub(b, a)), math.degrees(math.atan2(-u[1], u[0]))

	def edge_s(self, side, depth, end):
		"""변에서 depth만큼 안쪽 선이 서쪽(end='w') · 동쪽 변과 만나는 자리(변 시작점에서 u 방향 거리)."""
		a, u, inn, _L, _y = self.frame(side)
		p = (a[0] + inn[0] * depth, a[1] + inn[1] * depth)
		q, r = (self.nw, self.sw) if end == "w" else (self.ne, self.se)
		x = _cross(p, u, q, _sub(r, q))
		return _dot(_sub(x, a), u)

	def offset_line(self, side, depth):
		a, u, inn, _L, _y = self.frame(side)
		return (a[0] + inn[0] * depth, a[1] + inn[1] * depth), u


def split(L, target, r, lo=0.82, hi=1.18):
	"""길이 L을 target 남짓한 조각으로 꼭 나눈다(합 = L)."""
	n = max(1, int(round(L / target)))
	ws = [r.uniform(lo, hi) for _ in range(n)]
	k = L / sum(ws)
	return [w * k for w in ws]


class City(Town):
	def __init__(self):
		super().__init__("district", "7구역 v4 · 블록 도시", "80 × 110칸 · 둘레 줄집 블록 · 옛길을 따라 비튼 동네 둘", 4)
		self.blocks: list = []  # (Blk, 안뜰 다각형 또는 None, 골목이 뚫렸나)
		self.gates: list = []  # (id, (x0, z0, x1, z1))
		self.lanes: list = []  # (점들, 폭) — 블록을 꿰뚫는 굽은 골목(CT103)
		self.pockets: list = []  # 모퉁이 쉼터 다각형(CT103)
		self.piers: list = []  # 강변 나무 부두 다각형(CT103)
		self.start = (0.5, -12.5)

	def put(self, fx, fz, w, d, yaw, top, num=0, fid="", name="", force=False, zone="res") -> bool:
		"""앞면 가운데 (fx, fz) · 폭 w · 깊이 d(뒤 = 북쪽) 집. force가 아니면 다른 집 · 시설 · 옹벽과 겹치면 놓지 않는다(맞닿음은 괜찮다)."""
		if w < 2.6 or d < 2.6:
			return False
		poly = rect(fx, fz, w, d, yaw)
		if not force:
			t = math.radians(yaw)
			bx, bz = -math.sin(t), -math.cos(t)
			inner = rect(fx + bx * 0.8, fz + bz * 0.8, w - 1.6, d - 1.6, yaw)  # 자리 판이 칸당 2px라 맞닿은 변도 한 줄 겹친다
			pm = self.pmask(inner)
			if not pm.any() or (self.mask[pm] >= 2).any():
				return False
		self.try_house(poly, (poly[0], poly[1]), top, "fac" if (fid or num) else "house", name, force=True, strip=0.6)
		self.p.houses[-1].update({"yaw": yaw, "front_c": (fx, fz), "wd": (w, d), "num": num, "facility": fid,
			"zone": "townhall" if name == "관청" else zone})
		if num:
			mx, mz = sum(q[0] for q in poly) / 4, sum(q[1] for q in poly) / 4
			ax, az = poly[0]
			self.mark(num, ax + (mx - ax) * 0.35, az + (mz - az) * 0.35)
		return True

	def grow(self, b: Blk, g: float) -> Blk:
		"""블록 변을 바깥(길 쪽)으로 g칸 넓힌다 — 그 띠가 빈 땅(블록 사이 길)일 때만. 계단 · 큰길 · 광장 · 마당 · 시설 · 옹벽 · 성벽 쪽은 그대로."""
		cen = ((b.nw[0] + b.ne[0] + b.se[0] + b.sw[0]) / 4, (b.nw[1] + b.ne[1] + b.se[1] + b.sw[1]) / 4)
		lines = {}
		for k, (p, q) in {"n": (b.nw, b.ne), "s": (b.sw, b.se), "w": (b.nw, b.sw), "e": (b.ne, b.se)}.items():
			u = _norm(_sub(q, p))
			n = (-u[1], u[0])
			mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
			if _dot(n, _sub(mid, cen)) < 0:
				n = (-n[0], -n[1])
			strip = [p, q, (q[0] + n[0] * g, q[1] + n[1] * g), (p[0] + n[0] * g, p[1] + n[1] * g)]
			pm = self.pmask(strip)
			off = g if pm.any() and (self.mask[pm] != 0).mean() < 0.05 else 0.0
			lines[k] = ((p[0] + n[0] * off, p[1] + n[1] * off), u)
		c = lambda a, bb: _cross(lines[a][0], lines[a][1], lines[bb][0], lines[bb][1])  # noqa: E731
		return Blk(c("n", "w"), c("n", "e"), c("s", "e"), c("s", "w"))

	def block(self, b: Blk, seed: int, st=(2, 3), rows="nsew", dn=5.0, ds=5.4, cw=6.0, tw=6.0, fixed=(), alley=None, inner="yard",
			zone="res", zone_s=None, through=None, pocket=None, recess=0.3):
		"""둘레 줄집 블록. 남쪽 줄 = 남쪽 변(길)을 보고, 북쪽 줄 = 북쪽 변에 등을 대고 안뜰을 본다, 동서 세로 줄 = 남쪽을 보는 집을 쌓는다.
		변마다 집 폭이 변을 꼭 나눠 떨어진다(틈 없음). fixed = [(줄, x0, x1, 깊이, top, num, fid, 이름)] — x는 지도 가로 좌표.
		alley = 남쪽 줄 골목 자리(x, 폭 2.6 — 안뜰로). 깊이가 두 줄보다 얕으면 북쪽 줄을 줄여 등을 맞댄다.
		3차 개선(CT103): zone = 구역(집 꼴 · 지붕 색 — HouseFit.ZONE_FNS), zone_s = 남쪽 줄만 다른 구역(강변을 보는 줄),
		through = (남쪽 틈 x, 북쪽 틈 x) — 블록을 꿰뚫는 완만하게 굽은 골목, pocket = (줄, x0, x1) — 모퉁이 작은 쉼터(집을 비운다),
		recess = 남쪽 줄 집이 길에서 조금 물러서는 몫(앞선이 자로 그은 듯하지 않게)."""
		if through is not None:
			alley = through[0]
		r = random.Random(seed)
		b = self.grow(b, GROW)
		depth_w = math.hypot(*_sub(b.sw, b.nw))
		depth_e = math.hypot(*_sub(b.se, b.ne))
		dmin = min(depth_w, depth_e)
		if "n" in rows and "s" in rows and dmin - dn - ds < 2.5:  # 안뜰이 좁은 틈만 남으면 등을 맞댄 두 줄로
			dn = max(0.0, min(6.0, dmin - ds))
			if dn < 3.0:
				rows = rows.replace("n", "")

		def top_r():
			return top_of(r.randint(*st)) + r.uniform(-0.25, 0.45)

		for side in "sn":
			if side not in rows:
				continue
			d = ds if side == "s" else dn
			a, u, inn, L, yaw = b.frame(side)
			s0 = max(0.0, b.edge_s(side, d, "w"))
			s1 = min(L, b.edge_s(side, d, "e"))
			occ = []
			zn = (zone_s or zone) if side == "s" else zone
			for row, x0, x1, dd, top, num, fid, name in fixed:
				if row != side:
					continue
				sa, sb = (x0 - a[0]) / u[0], (x1 - a[0]) / u[0]
				qf = 0.0 if side == "s" else dd
				fx = a[0] + u[0] * (sa + sb) / 2 + inn[0] * qf
				fz = a[1] + u[1] * (sa + sb) / 2 + inn[1] * qf
				self.put(fx, fz, sb - sa, dd, yaw, top, num, fid, name, force=True, zone=zn)
				occ.append((sa, sb))
			if side == "s" and alley is not None:
				sa = (alley - a[0]) / u[0]
				occ.append((sa, sa + 2.6))
			if side == "n" and through is not None:
				sa = (through[1] - a[0]) / u[0]
				occ.append((sa, sa + 2.6))
			if pocket is not None and pocket[0] == side:
				sa, sb = (pocket[1] - a[0]) / u[0], (pocket[2] - a[0]) / u[0]
				occ.append((sa, sb))
				qf = d if side == "n" else 0.0
				pk = [(a[0] + u[0] * sa + inn[0] * qq, a[1] + u[1] * sa + inn[1] * qq) for qq in (qf, qf - d if side == "n" else d)]
				pk += [(a[0] + u[0] * sb + inn[0] * qq, a[1] + u[1] * sb + inn[1] * qq) for qq in ((qf - d if side == "n" else d), qf)]
				self.pockets.append(pk)
			s = s0
			gaps = []
			for x0, x1 in sorted(occ):
				if x0 - s > 0.4:
					gaps.append((s, x0))
				s = max(s, x1)
			if s1 - s > 0.4:
				gaps.append((s, s1))
			for g0, g1 in gaps:
				s = g0
				for w in split(g1 - g0, tw, r):
					qf = 0.0 if side == "s" else d
					rc = recess if (side == "s" and w > 3.4 and r.random() < 0.3) else 0.0  # 몇 집은 길에서 조금 물러선다
					fx = a[0] + u[0] * (s + w / 2) + inn[0] * (qf + rc)
					fz = a[1] + u[1] * (s + w / 2) + inn[1] * (qf + rc)
					self.put(fx, fz, w, d - rc, yaw, top_r(), zone=zn)
					s += w
		# 세로 줄(동서 끝): 남쪽 변의 틀로 — 북쪽 줄 앞선과 남쪽 줄 뒷선 사이
		a, u, inn, L, yaw = b.frame("s")
		pn, un = b.offset_line("n", dn if "n" in rows else 0.0)
		ps, us = b.offset_line("s", ds if "s" in rows else 0.0)
		back = (-inn[0], -inn[1])  # 남쪽(앞) 방향
		cs = [0.0, L]
		for side in "we":
			q0, q1 = (b.nw, b.sw) if side == "w" else (b.ne, b.se)
			e = _sub(q1, q0)
			P0, P1 = _cross(pn, un, q0, e), _cross(ps, us, q0, e)
			if P0 is None or P1 is None:
				continue
			sp0, sp1 = _dot(_sub(P0, a), u), _dot(_sub(P1, a), u)
			if side not in rows:
				cs[0 if side == "w" else 1] = min(sp0, sp1) if side == "w" else max(sp0, sp1)
				continue
			sx = max(sp0, sp1) if side == "w" else min(sp0, sp1) - cw
			qa, qb = _dot(_sub(P0, a), back), _dot(_sub(P1, a), back)  # 북 끝(음수) · 남 끝
			if qb - qa < 3.0:
				continue
			q = qa
			for d in split(qb - qa, 5.0, r, 0.9, 1.1):
				fx = a[0] + u[0] * (sx + cw / 2) + back[0] * (q + d)
				fz = a[1] + u[1] * (sx + cw / 2) + back[1] * (q + d)
				self.put(fx, fz, cw, d, yaw, top_r(), zone=zone)
				q += d
			cs[0 if side == "w" else 1] = sx + cw if side == "w" else sx
		court = None
		w_line = (a[0] + u[0] * cs[0], a[1] + u[1] * cs[0])
		e_line = (a[0] + u[0] * cs[1], a[1] + u[1] * cs[1])
		corners = [_cross(pn, un, w_line, back), _cross(pn, un, e_line, back), _cross(ps, us, e_line, back), _cross(ps, us, w_line, back)]
		if all(corners):
			area = abs(sum(corners[i][0] * corners[(i + 1) % 4][1] - corners[(i + 1) % 4][0] * corners[i][1] for i in range(4))) / 2
			if area > 4.0 and _dot(_sub(corners[3], corners[0]), back) > 0.8:
				court = corners
				if inner == "yard":
					self.p.yards.append(court)
				elif inner == "paving":
					self.p.pavings.append(court)
		if through is not None:  # 꿰뚫는 골목: 남쪽 틈 → 안뜰(완만한 굽이) → 북쪽 틈
			a, u, inn, L, _y = b.frame("s")
			an, un2, innn, _L2, _y2 = b.frame("n")
			ps_ = (a[0] + u[0] * ((through[0] - a[0]) / u[0] + 1.3) - inn[0] * 0.8, a[1] + u[1] * ((through[0] - a[0]) / u[0] + 1.3) - inn[1] * 0.8)
			pn_ = (an[0] + un2[0] * ((through[1] - an[0]) / un2[0] + 1.3) - innn[0] * 0.8, an[1] + un2[1] * ((through[1] - an[0]) / un2[0] + 1.3) - innn[1] * 0.8)
			mx, mz = (ps_[0] + pn_[0]) / 2, (ps_[1] + pn_[1]) / 2
			bend = 0.9 if (seed % 2) else -0.9
			pts = []
			for k in range(7):
				tt = k / 6.0
				cx, cz = mx + bend, mz
				x = (1 - tt) ** 2 * ps_[0] + 2 * (1 - tt) * tt * cx + tt ** 2 * pn_[0]
				z = (1 - tt) ** 2 * ps_[1] + 2 * (1 - tt) * tt * cz + tt ** 2 * pn_[1]
				pts.append((x, z))
			self.lane_n += 1
			self.lanes.append((pts, 2.2))
			self.street("through%d" % self.lane_n, pts, 2.2)  # 걷는 골목(소품이 막지 않게 길로 표시)
		self.blocks.append((b, court, alley is not None))
		return b


def zline2(p, q, x):
	return p[1] + (q[1] - p[1]) * (x - p[0]) / (q[0] - p[0])


def plan_v4():
	tv.set_extent(*EXTENT, 8)
	t = City()
	t.strip, t.strip_block, t.overlap, t.street_overlap = 0.6, 1.0, 0.12, 1.0
	t.ground([(flat(BAND1), HIGH), (flat(BAND2), MIDH), (flat(37), LOWH)], OUTLINE)
	t.channel([(-42, 25.0), (0, 24.6), (42, 25.0)], 6, WATER)
	t.bridge([(0, 19.5), (0, 30.5)], 4.0)
	t.opened([(-40, 28.6), (40, 28.6), (40, 35), (-40, 35)], "none")  # 수로 남쪽 둑길(성벽 밑)
	R = Blk.rect
	# ---- 축과 계단(나머지 블록 사이 땅도 모두 돌길) ----
	t.street("main", [(0, -55.5), (0, -31.5)], 5.0)  # 신전 앞뜰 → 큰 계단 → 광장
	t.street("main_s", [(0, -11), (0, 19.5)], 5.0)  # 시장 계단 → 시장 → 아랫길 → 다리
	t.street("st_w1", [(-15, -46), (-15, -35)], 3.6)
	t.street("st_e1", [(22, -46), (22, -35)], 3.6)
	t.street("st_w2", [(-33.5, -11), (-33.5, -2)], 3.6)
	t.street("st_e2", [(26, -10.5), (26, -2)], 3.6)
	t.gates += [("north", (14, -75, 18, -72)), ("west", (-40, -25, -38, -21))]

	# ================= 윗단(높이 3) — 반듯한 신전 지구 =================
	t.opened([(-37.5, -72.5), (-24.5, -72.5), (-24.5, -60.2), (-37.5, -60.2)])
	t.graves(-36.8, -72, -25.2, -62, 3)
	t.mark(17, -31, -66)
	t.block(R(-24, -73, -10.5, -59.5), 11, rows="ns", dn=5.0, ds=5.5, zone="civic", tw=6.8)
	t.fac(6, 17, 11, 12.0, at=(0, -59.5), yaw=0, name="신전", fid="temple")
	t.opened([(-8.5, -73), (8.5, -73), (8.5, -70.5), (-8.5, -70.5)], "none")  # 신전 뒤 좁은 뜰
	t.fac(22, 3.0, 4.0, 8.0, at=(12, -69))  # 북문 문루
	t.opened([(18.5, -73), (38, -73), (38, -59.5), (18.5, -59.5)], "paving")  # 도서관 뜰(판석)
	# 도서관 = 박물관 같은 돔 지붕 석조관(사용자 2026-11-03 "천문관 같다 — 일반 건물 위에 돔을 얹은 느낌", CT104) — 반듯한 네모 필지
	t.fac(7, 13.0, 9.6, 9.0, at=(28.0, -61.4), yaw=0, name="도서관", fid="library")
	# 신전 거리(z −59.5 ~ −55.5) 남쪽 줄 · 신전 앞뜰
	t.block(R(-38, -55.5, -17, -45), 13, rows="ns", dn=5.0, ds=5.4, zone="civic", tw=7.0,
			fixed=[("s", -34.5, -22.0, 6.0, 9.6, 0, "", "관청")])  # 관청(윗단 행정 — CT103)
	t.block(R(-13, -55.5, -6.5, -45), 14, rows="ns", tw=6.5, dn=5.0, ds=5.4, zone="civic")
	t.opened([(-6.5, -55.5), (6.5, -55.5), (6.5, -45), (-6.5, -45)], "paving")  # 신전 앞뜰
	t.block(R(6.5, -55.5, 19.5, -45), 15, rows="ns", dn=5.0, ds=5.4, zone="civic", tw=6.8)
	t.block(R(24.5, -55.5, 38, -45), 16, rows="ns", dn=5.0, ds=5.4, zone="civic", tw=7.0, pocket=("s", 24.0, 28.6))

	# ================= 중단(높이 0) — 차원광장 =================
	t.fac(2, 10.5, 8, 7.2, at=(-7.75, -31.5), yaw=0, name="탐험가 길드", fid="guild")
	t.fac(4, 10.5, 8, 6.6, at=(7.75, -31.5), yaw=0, name="여관", fid="inn")
	t.fac(10, 2.2, 0.5, 2.4, at=(-4.4, -31.2), yaw=0)
	t.plaza(0, -21.5, 8)
	t.opened([(-13, -31.5), (13, -31.5), (13, -11), (-13, -11)], "paving")  # 광장 네모 판석(원은 가운데)
	t.fac(3, 3.5, 2.6, 2.6, at=(-9.5, -14.0), yaw=0)
	# 서쪽: 은행 블록(옹벽에 등) · 서문 길(z −25.5 ~ −20.5) · 경비대 블록
	t.block(R(-38, -39.8, -17, -25.5), 21, rows="nswe", dn=4.8, ds=5.4, cw=5.5,
			fixed=[("s", -32.6, -22.1, 8.0, 6.8, 5, "bank", "은행")], alley=-35.2, zone="res")
	t.block(R(-38, -20.5, -13, -11), 23, st=(1, 3), rows="ns", dn=4.4, ds=5.1, zone="res", through=(-28.0, -27.2),
			fixed=[("s", -38.0, -31.0, 5.1, 6.0, 16, "", "경비 초소"), ("s", -25.4, -19.4, 5.1, 5.0, 13, "", "약초상")])
	t.mark(22, -36.5, -23)
	# 동쪽 옛 골목(+14.6°): 광장 동쪽에서 동북으로 오르는 선술집 골목 — 북쪽 블록은 남쪽 변이, 남쪽 블록은 북쪽 변이 기운다
	n0, n1 = (13, -23.5), (38, -30.0)  # 골목 북쪽 가
	s0, s1 = (13, -19.5), (38, -26.0)  # 골목 남쪽 가
	t.block(Blk((13, -39.8), (20.2, -39.8), (20.2, zline2(n0, n1, 20.2)), n0), 31, rows="nsw", dn=4.6, ds=5.0, cw=5.5, zone="market")
	t.block(Blk((23.8, -39.8), (38, -39.8), n1, (23.8, zline2(n0, n1, 23.8))), 32, rows="ns", dn=4.6, ds=5.0,
			fixed=[("s", 25.0, 32.0, 5.0, 5.6, 11, "", "선술집"), ("n", 32.0, 38.0, 4.6, 4.8, 20, "", "폐가")], zone="market")
	t.block(Blk(s0, s1, (38, -11), (13, -11)), 33, st=(1, 3), rows="nswe", dn=4.4, ds=5.2, cw=5.5, alley=21.0,
			fixed=[("s", 29.0, 35.0, 5.2, 4.8, 19, "", "전당포")], zone="market")

	# ================= 아랫단(높이 −2.4) — 시장 · 아랫동네 · 수로 =================
	t.opened([(-9, -6.6), (9, -6.6), (9, 4.5), (-9, 4.5)], "paving")  # 시장(계단 밑)
	t.mark(12, -5.0, 1.5)
	# 서쪽 아랫동네(−12.6°): 서문 밑에서 시장 쪽으로 내려오는 아랫길(가 = 북 · 남)
	a0, a1 = (-38, -2.0), (-9, 4.5)
	b0, b1 = (-38, 2.0), (-9, 8.5)
	t.block(Blk((-31.5, -5.8), (-20.0, -5.8), (-20.0, zline2(a0, a1, -20.0)), (-31.5, zline2(a0, a1, -31.5))), 41, st=(1, 2), rows="s", ds=4.8, zone="res",
			fixed=[("s", -31.5, -24.0, 4.8, 5.0, 18, "", "구빈원")])
	t.block(Blk((-17.4, -5.8), (-9.0, -5.8), a1, (-17.4, zline2(a0, a1, -17.4))), 42, st=(1, 2), rows="ns", dn=4.6, ds=4.8, zone="res")
	t.block(Blk(b0, (-20.4, zline2(b0, b1, -20.4)), (-20.4, 16.5), (-38, 16.5)), 43, st=(1, 2), rows="nsw", dn=4.6, ds=5.2, cw=5.0,
			zone="res", zone_s="river", through=(-30.0, -28.6))
	t.block(Blk((-17.8, zline2(b0, b1, -17.8)), (-2.5, zline2(b0, b1, -2.5)), (-2.5, 16.5), (-17.8, 16.5)), 44, st=(1, 2), rows="ns", dn=3.4, ds=5.2, zone="res", zone_s="river")
	# 동쪽: 가게 블록(시장 동쪽) · 대장간 · 창고(수로)
	t.block(R(9, -5.8, 24.2, 5.5), 45, st=(1, 3), rows="ns", dn=4.8, ds=5.6,
			fixed=[("s", 9.0, 18.0, 6.2, 4.6, 8, "shop", "잡화점")], zone="market", through=(19.6, 20.4))
	t.block(R(27.8, -5.8, 38, 5.5), 46, st=(1, 3), rows="ns", dn=4.8, ds=5.6, zone="res", pocket=("s", 33.6, 38.0))
	t.block(R(2.5, 10.5, 38, 16.5), 47, st=(1, 2), rows="s", ds=6.0,
			fixed=[("s", 7.0, 16.0, 6.0, 5.0, 9, "smithy", "대장간"), ("s", 23.0, 35.0, 6.0, 5.0, 21, "", "창고")], zone="river")
	# 강변 나무 부두 둘(걸어 나가는 판자 · 둘레 난간 · 배를 맨다 — CT103)
	for x0 in (-21.5, 17.0):
		pier = [(x0, 21.0), (x0 + 3.0, 21.0), (x0 + 3.0, 25.2), (x0, 25.2)]
		t.piers.append(pier)
		t.mask[t.pmask(pier)] = 1
	t.mark(15, -24, 21.0)
	t.mark(25, 3.8, 24.0)
	# 하수도: 큰 굴은 큰길 밑 → 다리 옆 배출구, 가지 굴 둘 · 갈림길 암시장
	t.sewer([(0, -50), (0, -21.5), (0, 4), (0, 24)])
	t.sewer([(0, -14), (28, -20)])
	t.sewer([(-30, 9), (0, 12), (24, 8)])
	for x, z in ((4.5, -13.5), (-19, 4.5), (-4.5, 19.5), (36, -43), (22, -36)):
		t.mark(23, x, z)
	t.mark(24, -1.0, 12)
	# 큰길(반듯한 돌 — 나머지 블록 사이 길 · 골목은 자갈, CT103): 신전 거리 · 윗단 남쪽 길 · 서문 길 · 선술집 골목 · 중단 남쪽 길 · 아랫길 · 둑길 · 북문 길
	t.mains = [([(-38, -57.5), (38, -57.5)], 3.2), ([(-38, -42.8), (38, -42.8)], 3.6), ([(-38, -23.0), (-13, -23.0)], 4.2),
			([(13, -21.5), (38, -28.0)], 3.4), ([(-38, -8.8), (38, -8.8)], 3.6), ([(-38, 0.0), (-9, 6.5)], 3.2), ([(9, 8.0), (38, 8.0)], 4.0),
			([(-38, 18.9), (38, 18.9)], 4.4), ([(16.2, -73), (16.2, -59)], 4.0)]
	dress(t)
	t.p.label(-26, -57.5, "신전 거리", "street").label(-28, -23, "서문 거리", "street").label(26, -27, "선술집 골목", "street")
	t.p.label(-26, 3.5, "아랫길", "street").label(20, 18.5, "둑길", "street")
	notes = [
		("짜임", "길로 나뉜 블록마다 둘레에 줄집을 틈 없이(집 폭 = 블록 변을 꼭 나눈 값). 남쪽 줄은 길을 보고, 북쪽 줄은 등을 길 · 옹벽 · 성벽에 대고 안뜰을 본다. 골목이 뚫린 안뜰은 흙 뒷마당, 막힌 안뜰은 정원."),
		("축", "북문 → 신전 앞뜰 → 큰 계단 → 큰길 → 차원광장(북쪽 길드 · 여관) → 시장 계단 → 시장 → 아랫길 → 다리."),
		("비튼 동네", "중단 동쪽 선술집 골목(+15°)과 아랫단 서쪽 아랫길(−13°)은 옛길을 따라 기운 블록 — 기운 길을 보는 줄은 길 각도대로, 등을 댄 줄은 반듯하게(사다리꼴 블록)."),
		("하수도", "큰길 밑 큰 굴 → 다리 옆 배출구. 들어가는 곳 다섯, 아랫동네 갈림길에 암시장."),
	]
	return t, notes


def dress(t: City):
	"""거리 소품: 블록 남쪽 줄 앞 9칸마다 가로등 · 광장 · 시장 · 시설 문 옆 · 뒷마당 빨래."""
	for b, _court, _open in t.blocks:
		a, u, inn, L, _yaw = b.frame("s")
		k = 3.0
		while k < L - 1.5:
			for dk in (0.0, 1.0, -1.0, 2.0, -2.0, 3.0):  # 문 앞을 비켜 옆 집 경계 쪽으로
				if t.spot("lamp", a[0] + u[0] * (k + dk) - inn[0] * 1.15, a[1] + u[1] * (k + dk) - inn[1] * 1.15, 0.8, 0.8):
					break
			k += 9.0
	if t.spot("well", -6.5, -18.0, 1.6, 1.6):
		t.mark(14, -6.5, -18.0)
	for x, z in ((-4.2, -12.8), (4.2, -12.8)):
		t.spot("bench", x, z, 2.0, 0.8)
	for x, z in ((10.0, -26.0), (10.0, -21.0)):
		t.spot("stall", x, z, 2.2, 1.2)
	for x, z in ((-6.5, -3.0), (6.0, -3.0), (-6.5, 1.5), (6.0, 1.5)):
		t.spot("stall", x, z, 2.2, 1.2)
	t.spot("fountain", 4.5, -0.6, 2.0, 2.0)
	t.spot("crate", -7.6, -0.6, 0.9, 0.9)
	for h in t.p.houses:
		fid = h.get("facility", "")
		num = h.get("num", 0)
		if not fid and num not in (11, 13, 19, 21):
			continue
		(fx, fz), (w, _d), yaw = h["front_c"], h["wd"], h["yaw"]
		ux, uz = math.cos(math.radians(yaw)), -math.sin(math.radians(yaw))
		nx, nz = math.sin(math.radians(yaw)), math.cos(math.radians(yaw))
		kinds = {"inn": ("planter", "planter"), "guild": ("planter", "planter"), "shop": ("crate", "barrel"), "smithy": ("barrel", "cart"),
				"bank": ("planter", "planter"), "temple": ("planter", "planter")}.get(fid, {11: ("barrel", "barrel"), 13: ("planter", "crate"), 19: ("crate", "crate"), 21: ("cart", "crate")}.get(num, ("crate", "barrel")))
		for sgn, kind in zip((-1, 1), kinds):
			for along in (w / 2 - 0.7, w / 2 - 1.6):
				x = fx + ux * along * sgn + nx * 1.1
				z = fz + uz * along * sgn + nz * 1.1
				if t.spot(kind, x, z, 1.8 if kind == "cart" else 0.9, 0.9):
					break
	t.spot("cart", -27.5, -21.2, 1.8, 0.9)
	t.spot("barrel", -3.4, 18.0, 0.9, 0.9)
	deco(t)


def clear(t: City, x, z, r) -> bool:
	"""(x, z) 둘레 r칸이 집 · 소품 · 문 앞이 아닌가(나무 · 석상처럼 그림이 넓은 소품)."""
	pm = t.pmask([(x - r, z - r), (x + r, z - r), (x + r, z + r), (x - r, z + r)])
	return pm.any() and not (t.mask[pm] >= 2).any() and not (pm & t.door).any()


def near(t: City, kind, x, z, w, d) -> bool:
	"""그 자리가 막혔으면 반 칸 · 한 칸 옆으로 비켜 놓는다."""
	for dx, dz in ((0, 0), (0.5, 0), (-0.5, 0), (0, 0.5), (0, -0.5), (1, 0), (-1, 0), (0, 1), (0, -1), (1.5, 0), (-1.5, 0)):
		if t.spot(kind, x + dx, z + dz, w, d):
			return True
	return False


def deco(t: City):
	"""도시 장식(사용자 2026-11-03 "도시에 있을 법한 장식 요소", CT101): 안뜰 나무 · 덤불 · 장작 · 빨래, 신전 앞뜰 석상 · 깃발,
	도서관 뜰 · 묘지 · 둑길 나무, 성문 이정표 · 물구유, 광장 깃발 · 돌말뚝, 둑길 돌말뚝 · 짐더미. 걷는 길 가운데는 비운다."""
	def tree(x, z, r=1.1):
		if clear(t, x, z, r):
			return t.spot("tree", x, z, 1.0, 1.0)
		return t.spot("bush", x, z, 1.0, 1.0) if clear(t, x, z, 0.6) else False

	# 블록 안뜰: 골목이 뚫린 마당 = 빨래 · 장작, 막힌 정원 = 나무 · 덤불
	for b, court, opened in t.blocks:
		if court is None:
			continue
		cx = sum(q[0] for q in court) / 4
		cz = sum(q[1] for q in court) / 4
		if opened:
			near(t, "laundry", cx, cz - 0.6, 2.4, 0.8)
			near(t, "woodpile", cx + 2.6, cz + 0.8, 1.8, 0.8)
		else:
			if not tree(cx, cz):
				t.spot("laundry", cx, cz, 2.4, 0.8)
			for q in court:  # 귀퉁이 덤불
				bx, bz = cx + (q[0] - cx) * 0.6, cz + (q[1] - cz) * 0.6
				if clear(t, bx, bz, 0.6):
					t.spot("bush", bx, bz, 1.0, 1.0)
	# 신전 앞뜰: 석상 둘 · 신전 문 양옆 깃발
	for x in (-4.6, 4.6):
		if clear(t, x, -50.0, 0.9):
			t.spot("statue", x, -50.0, 1.5, 1.5)
		near(t, "banner", x * 1.45, -58.6, 0.8, 0.8)
	# 도서관 뜰 · 묘지 나무
	for x, z in ((20.6, -61.6), (35.8, -61.6), (20.6, -71.2), (35.8, -71.2), (-36.0, -61.6), (-26.4, -71.4), (-26.4, -61.8)):
		tree(x, z, 0.9)
	for x, z in ((22.0, -64.0), (34.4, -64.0), (-36.2, -66.5)):
		t.spot("bush", x, z, 1.0, 1.0)
	# 성문: 이정표 · 물구유
	t.spot("signpost", -31.2, -24.6, 0.8, 0.8)
	t.spot("trough", -35.6, -21.0, 1.8, 0.8)
	t.spot("signpost", 19.3, -58.6, 0.8, 0.8)
	t.spot("trough", 17.6, -70.8, 0.8, 1.8)
	# 광장: 네 귀 깃발 · 시장 계단 위 돌말뚝
	for x, z in ((-11.7, -30.2), (11.7, -30.2), (-11.7, -12.2), (11.7, -12.2)):
		near(t, "banner", x, z, 0.8, 0.8)
	for x in (-3.6, 3.6):
		t.spot("bollard", x, -11.4, 0.7, 0.7)
	# 계단 머리 이정표
	for x, z in ((-17.6, -44.0), (24.6, -44.0), (28.4, -10.0), (-10.6, 6.4)):
		t.spot("signpost", x, z, 0.8, 0.8)
	# 시장 귀 짐더미 · 대장간 장작
	for x, z in ((-7.8, 3.6), (7.8, 3.6)):
		t.spot("goods", x, z, 1.6, 1.0)
	for x, z in ((5.0, 17.6), (-21.5, -66.4), (-30.0, 10.4), (-6.0, 10.6), (12.0, -0.6)):  # 장작더미(대장간 앞 · 안뜰)
		near(t, "woodpile", x, z, 1.8, 0.8)
	near(t, "laundry", -25.5, 19.6, 2.4, 0.8)  # 빨래터(수로 돌계단 옆)
	near(t, "laundry", -34.5, -29.0, 2.4, 0.8)  # 은행 블록 뒷마당(골목 안)
	# 둑길: 물가 돌말뚝 · 나무 · 창고 앞 짐더미
	for x in range(-36, 38, 6):
		if abs(x) > 3:
			t.spot("bollard", x + 0.5, 21.0, 0.7, 0.7)
	for x in (-31.0, -15.0, 13.0, 31.5):
		tree(x, 19.6, 0.9)
	for x, z in ((21.5, 17.6), (36.6, 17.6), (-20.0, 17.6)):
		t.spot("goods", x, z, 1.6, 1.0)
	life(t)


def life(t: City):
	"""3차 개선(CT103) 생활 소품 — 구역 용도대로: 가게 간판 · 주거 벽 등불 · 골목 살림 · 포장마차 · 모퉁이 쉼터 · 광장 진입 돌말뚝 · 부두 난간 · 거룻배."""
	shops = {"shop", "smithy", "inn", "bank"}
	k = 0
	for h in t.p.houses:
		if "front_c" not in h or h.get("kind") == "post":
			continue
		(fx, fz), (w, _d), yaw = h["front_c"], h["wd"], h["yaw"]
		ux, uz = math.cos(math.radians(yaw)), -math.sin(math.radians(yaw))
		nx, nz = math.sin(math.radians(yaw)), math.cos(math.radians(yaw))
		zone = h.get("zone", "")
		if h.get("facility") in shops or h.get("num") in (11, 13, 19) or (zone == "market" and w > 4.0):
			near(t, "sign", fx + ux * (w / 2 - 0.7) + nx * 1.0, fz + uz * (w / 2 - 0.7) + nz * 1.0, 0.8, 0.8)  # 문 옆 간판
		elif zone in ("res", "market", "river") and w > 3.6:
			k += 1
			if k % 3 == 0:
				near(t, "walllamp", fx - ux * (w / 2 - 0.6) + nx * 0.9, fz - uz * (w / 2 - 0.6) + nz * 0.9, 0.7, 0.7)  # 벽 등불
	for pts, _w in t.lanes:  # 꿰뚫는 골목: 들머리 벽 등불 · 가운데 살림
		near(t, "walllamp", pts[0][0] + 1.4, pts[0][1] - 0.6, 0.7, 0.7)
		near(t, "household", pts[3][0] + 1.3, pts[3][1], 1.2, 0.8)
	for pk in t.pockets:  # 모퉁이 쉼터: 뒤에 나무 · 앞에 벤치 · 화분
		cx = sum(q[0] for q in pk) / 4
		cz = sum(q[1] for q in pk) / 4
		if clear(t, cx, cz - 1.2, 1.0):
			t.spot("tree", cx, cz - 1.2, 1.0, 1.0)
		near(t, "bench", cx, cz + 1.4, 2.0, 0.8)
		near(t, "planter", cx + 1.5, cz + 0.2, 0.9, 0.9)
	# 포장마차: 서문 길 · 둑길 창고 앞 · 아랫길
	near(t, "wagon", -22.5, -23.0, 2.6, 1.0)
	near(t, "wagon", 29.5, 18.6, 2.6, 1.0)
	near(t, "wagon", -14.0, 6.2, 2.6, 1.0)
	# 광장 진입부: 길이 광장에 들어오는 곳 양옆 돌말뚝(서문 길 · 선술집 골목 · 큰길)
	for x, z in ((-12.3, -25.0), (-12.3, -21.0), (12.3, -23.1), (12.3, -19.8), (-3.4, -30.8), (3.4, -30.8)):
		near(t, "bollard", x, z, 0.7, 0.7)
	for x, z in ((-11.7, -16.0), (11.7, -16.0)):  # 광장 가장자리 화분
		near(t, "planter", x, z, 0.9, 0.9)
	# 부두: 끝 난간 · 뿌리에 짐 · 곁에 거룻배(물 위 — 걷지 않는 칸)
	for pier in t.piers:
		x0 = pier[0][0]
		t.props.append(("rail", x0 + 1.5, 24.7, 3.0, 0.9))
		t.props.append(("boat", x0 + 5.2, 24.2, 2.0, 1.0))
		t.props.append(("boat", x0 - 2.4, 23.4, 2.0, 1.0))
		near(t, "barrel", x0 - 0.8, 20.2, 0.9, 0.9)
		near(t, "crate", x0 + 3.8, 20.2, 0.9, 0.9)


def main():
	tv.set_extent(*EXTENT, 8)
	tv.OUT = os.path.join(os.path.dirname(tv.OUT), "v4")
	tv.render([plan_v4], CATALOG, overview=False)


if __name__ == "__main__":
	main()
