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
HIGH, MIDH, LOWH, WATER = 3.0, 0.0, -2.4, -4.2
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
		self.blocks: list = []  # (Blk, 안뜰 다각형 또는 None)
		self.gates: list = []  # (id, (x0, z0, x1, z1))
		self.start = (0.5, -12.5)

	def put(self, fx, fz, w, d, yaw, top, num=0, fid="", name="", force=False) -> bool:
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
		self.p.houses[-1].update({"yaw": yaw, "front_c": (fx, fz), "wd": (w, d), "num": num, "facility": fid})
		if num:
			mx, mz = sum(q[0] for q in poly) / 4, sum(q[1] for q in poly) / 4
			ax, az = poly[0]
			self.mark(num, ax + (mx - ax) * 0.35, az + (mz - az) * 0.35)
		return True

	def block(self, b: Blk, seed: int, st=(2, 3), rows="nsew", dn=5.0, ds=5.4, cw=6.0, tw=6.0, fixed=(), alley=None, inner="yard"):
		"""둘레 줄집 블록. 남쪽 줄 = 남쪽 변(길)을 보고, 북쪽 줄 = 북쪽 변에 등을 대고 안뜰을 본다, 동서 세로 줄 = 남쪽을 보는 집을 쌓는다.
		변마다 집 폭이 변을 꼭 나눠 떨어진다(틈 없음). fixed = [(줄, x0, x1, 깊이, top, num, fid, 이름)] — x는 지도 가로 좌표.
		alley = 남쪽 줄 골목 자리(x, 폭 2.6 — 안뜰로). 깊이가 두 줄보다 얕으면 북쪽 줄을 줄여 등을 맞댄다."""
		r = random.Random(seed)
		depth_w = math.hypot(*_sub(b.sw, b.nw))
		depth_e = math.hypot(*_sub(b.se, b.ne))
		dmin = min(depth_w, depth_e)
		if "n" in rows and "s" in rows and dmin < dn + ds + 0.3:
			dn = max(0.0, dmin - ds)
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
			for row, x0, x1, dd, top, num, fid, name in fixed:
				if row != side:
					continue
				sa, sb = (x0 - a[0]) / u[0], (x1 - a[0]) / u[0]
				qf = 0.0 if side == "s" else dd
				fx = a[0] + u[0] * (sa + sb) / 2 + inn[0] * qf
				fz = a[1] + u[1] * (sa + sb) / 2 + inn[1] * qf
				self.put(fx, fz, sb - sa, dd, yaw, top, num, fid, name, force=True)
				occ.append((sa, sb))
			if side == "s" and alley is not None:
				sa = (alley - a[0]) / u[0]
				occ.append((sa, sa + 2.6))
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
					fx = a[0] + u[0] * (s + w / 2) + inn[0] * qf
					fz = a[1] + u[1] * (s + w / 2) + inn[1] * qf
					self.put(fx, fz, w, d, yaw, top_r())
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
				self.put(fx, fz, cw, d, yaw, top_r())
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
		self.blocks.append((b, court))
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
	t.block(R(-24, -73, -10.5, -59.5), 11, rows="ns", dn=5.0, ds=5.5)
	t.fac(6, 17, 11, 12.0, at=(0, -59.5), yaw=0, name="신전", fid="temple")
	t.opened([(-8.5, -73), (8.5, -73), (8.5, -70.5), (-8.5, -70.5)], "none")  # 신전 뒤 좁은 뜰
	t.fac(22, 3.0, 4.0, 8.0, at=(12, -69))  # 북문 문루
	t.opened([(18.5, -73), (38, -73), (38, -59.5), (18.5, -59.5)], "paving")  # 도서관 뜰(판석)
	t.round(7, 28, -66.2, 6.0, 8.0, "도서관")
	# 신전 거리(z −59.5 ~ −55.5) 남쪽 줄 · 신전 앞뜰
	t.block(R(-38, -55.5, -17, -45), 13, rows="ns", dn=5.0, ds=5.4)
	t.block(R(-13, -55.5, -6.5, -45), 14, rows="ns", tw=6.5, dn=5.0, ds=5.4)
	t.opened([(-6.5, -55.5), (6.5, -55.5), (6.5, -45), (-6.5, -45)], "paving")  # 신전 앞뜰
	t.block(R(6.5, -55.5, 19.5, -45), 15, rows="ns", dn=5.0, ds=5.4)
	t.block(R(24.5, -55.5, 38, -45), 16, rows="ns", dn=5.0, ds=5.4)

	# ================= 중단(높이 0) — 차원광장 =================
	t.fac(2, 10.5, 8, 7.2, at=(-7.75, -31.5), yaw=0, name="탐험가 길드", fid="guild")
	t.fac(4, 10.5, 8, 6.6, at=(7.75, -31.5), yaw=0, name="여관", fid="inn")
	t.fac(10, 2.2, 0.5, 2.4, at=(-4.4, -31.2), yaw=0)
	t.plaza(0, -21.5, 8)
	t.opened([(-13, -31.5), (13, -31.5), (13, -11), (-13, -11)], "paving")  # 광장 네모 판석(원은 가운데)
	t.fac(3, 3.5, 2.6, 2.6, at=(-9.5, -14.0), yaw=0)
	# 서쪽: 은행 블록(옹벽에 등) · 서문 길(z −25.5 ~ −20.5) · 경비대 블록
	t.block(R(-38, -39.8, -17, -25.5), 21, rows="nswe", dn=4.8, ds=5.4, cw=5.5,
			fixed=[("s", -32.6, -22.1, 8.0, 6.8, 5, "bank", "은행")], alley=-35.2)
	t.block(R(-38, -20.5, -13, -11), 23, st=(1, 3), rows="ns", dn=4.4, ds=5.1,
			fixed=[("s", -38.0, -31.0, 5.1, 6.0, 16, "", "경비 초소"), ("s", -24.0, -18.0, 5.1, 5.0, 13, "", "약초상")])
	t.mark(22, -36.5, -23)
	# 동쪽 옛 골목(+14.6°): 광장 동쪽에서 동북으로 오르는 선술집 골목 — 북쪽 블록은 남쪽 변이, 남쪽 블록은 북쪽 변이 기운다
	n0, n1 = (13, -23.5), (38, -30.0)  # 골목 북쪽 가
	s0, s1 = (13, -19.5), (38, -26.0)  # 골목 남쪽 가
	t.block(Blk((13, -39.8), (20.2, -39.8), (20.2, zline2(n0, n1, 20.2)), n0), 31, rows="nsw", dn=4.6, ds=5.0, cw=5.5)
	t.block(Blk((23.8, -39.8), (38, -39.8), n1, (23.8, zline2(n0, n1, 23.8))), 32, rows="ns", dn=4.6, ds=5.0,
			fixed=[("s", 25.0, 32.0, 5.0, 5.6, 11, "", "선술집"), ("n", 32.0, 38.0, 4.6, 4.8, 20, "", "폐가")])
	t.block(Blk(s0, s1, (38, -11), (13, -11)), 33, st=(1, 3), rows="nswe", dn=4.4, ds=5.2, cw=5.5, alley=21.0,
			fixed=[("s", 29.0, 35.0, 5.2, 4.8, 19, "", "전당포")])

	# ================= 아랫단(높이 −2.4) — 시장 · 아랫동네 · 수로 =================
	t.opened([(-9, -6.6), (9, -6.6), (9, 4.5), (-9, 4.5)], "paving")  # 시장(계단 밑)
	t.mark(12, -5.0, 1.5)
	# 서쪽 아랫동네(−12.6°): 서문 밑에서 시장 쪽으로 내려오는 아랫길(가 = 북 · 남)
	a0, a1 = (-38, -2.0), (-9, 4.5)
	b0, b1 = (-38, 2.0), (-9, 8.5)
	t.block(Blk((-31.5, -5.8), (-20.0, -5.8), (-20.0, zline2(a0, a1, -20.0)), (-31.5, zline2(a0, a1, -31.5))), 41, st=(1, 2), rows="s", ds=4.8,
			fixed=[("s", -31.5, -24.0, 4.8, 5.0, 18, "", "구빈원")])
	t.block(Blk((-17.4, -5.8), (-9.0, -5.8), a1, (-17.4, zline2(a0, a1, -17.4))), 42, st=(1, 2), rows="ns", dn=4.6, ds=4.8)
	t.block(Blk(b0, (-20.4, zline2(b0, b1, -20.4)), (-20.4, 16.5), (-38, 16.5)), 43, st=(1, 2), rows="nsw", dn=4.6, ds=5.2, cw=5.0)
	t.block(Blk((-17.8, zline2(b0, b1, -17.8)), (-2.5, zline2(b0, b1, -2.5)), (-2.5, 16.5), (-17.8, 16.5)), 44, st=(1, 2), rows="ns", dn=3.4, ds=5.2)
	# 동쪽: 가게 블록(시장 동쪽) · 대장간 · 창고(수로)
	t.block(R(9, -5.8, 24.2, 5.5), 45, st=(1, 3), rows="ns", dn=4.8, ds=5.6,
			fixed=[("s", 9.0, 18.0, 6.2, 4.6, 8, "shop", "잡화점")])
	t.block(R(27.8, -5.8, 38, 5.5), 46, st=(1, 3), rows="ns", dn=4.8, ds=5.6)
	t.block(R(2.5, 10.5, 38, 16.5), 47, st=(1, 2), rows="s", ds=6.0,
			fixed=[("s", 7.0, 16.0, 6.0, 5.0, 9, "smithy", "대장간"), ("s", 23.0, 35.0, 6.0, 5.0, 21, "", "창고")])
	t.mark(15, -24, 21.0)
	t.mark(25, 3.8, 24.0)
	# 하수도: 큰 굴은 큰길 밑 → 다리 옆 배출구, 가지 굴 둘 · 갈림길 암시장
	t.sewer([(0, -50), (0, -21.5), (0, 4), (0, 24)])
	t.sewer([(0, -14), (28, -20)])
	t.sewer([(-30, 9), (0, 12), (24, 8)])
	for x, z in ((4.5, -13.5), (-19, 4.5), (-4.5, 19.5), (36, -43), (22, -36)):
		t.mark(23, x, z)
	t.mark(24, -1.0, 12)
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
	for b, _court in t.blocks:
		a, u, inn, L, _yaw = b.frame("s")
		k = 3.0
		while k < L - 1.5:
			t.spot("lamp", a[0] + u[0] * k - inn[0] * 0.75, a[1] + u[1] * k - inn[1] * 0.75, 0.8, 0.8)
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
				x = fx + ux * along * sgn + nx * 0.75
				z = fz + uz * along * sgn + nz * 0.75
				if t.spot(kind, x, z, 1.8 if kind == "cart" else 0.9, 0.9):
					break
	t.spot("cart", -33.5, -21.2, 1.8, 0.9)
	t.spot("barrel", -3.4, 18.0, 0.9, 0.9)
	n = 0
	for b, court in t.blocks:
		if court is None or n >= 7:
			continue
		cx = sum(q[0] for q in court) / 4
		cz = sum(q[1] for q in court) / 4
		if t.spot("laundry", cx, cz, 2.4, 0.8):
			n += 1


def main():
	tv.set_extent(*EXTENT, 8)
	tv.OUT = os.path.join(os.path.dirname(tv.OUT), "v4")
	tv.render([plan_v4], CATALOG, overview=False)


if __name__ == "__main__":
	main()
