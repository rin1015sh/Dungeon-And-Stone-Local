"""안 2(빗살 골목) 바탕 동네 + 둘러싼 차원광장 — 탐험 화면과 같은 3/4로 본 상자 그림.
  python3 tools/town_comb.py   → docs/plans/town/layouts/b2.png(배치도) · b2_view.png(7구역 3/4) · b2_plaza.png(광장 가까이 3/4)
사용자 2026-11-02 "원래 2안이었던 거 기반으로 뽑아 달라고"(처음 네 안의 안 2) · "화면각을 눕히지 말고 탐험화면과 같은 각으로" · "차원광장을 건물로 둘러싼".
기획 설명은 docs/plans/city_town_layouts.md §6.

3/4에서는 집이 제 높이만큼만 뒤를 가린다 — 안 2의 줄 간격(18°에서 20칸 남짓)을 그대로 두면 줄 뒤 뒷골목·뒤뜰이 다 보인다.
땅은 낮은 단 셋(위 +2.4 · 광장 0 · 아래 −1.2 — 3/4에서는 단 높이만큼 옹벽 앞면이 크게 보여 낮췄다).
"""
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_layouts as tl  # noqa: E402
import town_plaza as tp  # noqa: E402  (불러오면 3/4 투영으로 바뀐다)
from town_layouts import Plan, flat, top_of, font  # noqa: E402

UP2, MID0, LOW1 = 2.4, 0.0, -1.2


def back_zone(p: Plan, z: float, depth: float, seed: int, x0: float = -76, x1: float = 76):
	"""줄 뒤 뒷골목(z) + 그 북쪽 뒤뜰·헛간(depth칸)."""
	p.paths.append([(x0, z), (x1, z)])
	rng = random.Random(seed)
	x = x0 + 2
	while x < x1 - 8:
		r = rng.random()
		if r < 0.4 and depth > 3:
			p.yards.append([(x, z - 1.3), (x + rng.uniform(5, 8), z - 1.3), (x + rng.uniform(5, 8), z - depth), (x, z - depth)])
		elif r < 0.75:
			p.box(x, z - 1.4, rng.uniform(3, 4.5), min(3.0, depth - 1.4), top_of(1), kind="shed")
		x += rng.uniform(8, 13)


def plan_comb() -> Plan:
	p = Plan("b2", "안 2 · 빗살 골목 + 둘러싼 광장", "긴 줄 · 줄마다 뒷골목 · 3~4채마다 틈 · 육각 광장(3/4)")
	p.arcades = []
	p.bands = [(flat(-24), UP2), (flat(18), MID0), (flat(tl.Z1 + 2), LOW1)]
	tl.common(p, -5)
	# 위 단(+2.4): 신전 거리 줄 · 위 거리 줄(도서관) — 줄마다 뒤에 뒷골목
	p.row(flat(-46), 21, st=(2, 4), lanes=3, skip=[(-12, 12)])
	p.box(-11, -45, 22, 11, 11.0, "신전")
	back_zone(p, -53.5, 4.5, 31)
	p.row(flat(-30), 22, st=(2, 3), lanes=4, skip=[(-66, -52), (-2, 3)])
	p.rounds.append((-59, -36, 6.0, 7.0, "도서관"))
	back_zone(p, -37.5, 2.4, 32)
	# 광장 단(0): 둘러싼 육각 광장(북쪽 반 = 길드·여관이 광장을 봄 · 남쪽 반 = 가게 줄 + 문루) + 양옆 빗살 줄
	p.pavings.append(tp.HEX)
	p.discs += [(tp.PC[0], tp.PC[1], 3.4, 0.3, (168, 160, 142)), (tp.PC[0], tp.PC[1], 2.75, 0.6, (176, 168, 150)), (tp.PC[0], tp.PC[1], 2.1, 0.9, (184, 176, 158))]
	p.plazas.append((tp.PC[0], tp.PC[1], 0))
	tp.ring_north(p, MID0, stair=(-29.0, -24.0, UP2))
	tp.ring_south(p, "shops")
	for side, (a, b) in (("w", (-79, -38)), ("e", (38, 79))):
		p.row([(a, -8), (b, -8)], 41 if side == "w" else 42, st=(2, 4), lanes=3, skip=[(56, 70)] if side == "e" else [])
		back_zone(p, -15.5, 8.0, 43 if side == "w" else 44, a + 2, b - 2)
		p.row([(a, 12), (b, 12)], 45 if side == "w" else 46, st=(2, 3), lanes=4)
		back_zone(p, 4.5, 5.0, 47 if side == "w" else 48, a + 2, b - 2)
	p.box(56, -8, 13, 7, 6.0, "은행")
	p.stairs.append((-3, 18, 3, 21.6, MID0, LOW1))
	p.walls += [([(-80, 17.6), (-3, 17.6)], 0.6), ([(3, 17.6), (80, 17.6)], 0.6)]
	# 아래 단(−1.2): 시장 거리 줄(잡화점 · 대장간) — 뒤는 옹벽 밑 뒷골목
	p.row(flat(26), 24, st=(1, 3), lanes=3, skip=[(-5, 5), (12, 24), (40, 53)])
	p.box(12, 26, 12, 6, 4.2, "잡화점")
	p.box(40, 26, 13, 7, 4.5, "대장간")
	back_zone(p, 19.5, 1.5, 49)
	p.label(tp.PC[0], tp.PC[1] + 7.0, "차원광장", "fac").label(-60, -5, "서문 거리", "street").label(60, -5, "은행 거리", "street")
	p.label(-40, -43, "신전 거리", "street").label(-44, -27, "위 거리", "street").label(-58, 15, "광장 둘레 길", "street")
	p.label(-58, 31, "시장 거리", "street").label(0, 23.5, "큰 계단", "note")
	p.label(-60, -19.5, "뒷골목 · 뒤뜰", "alley").label(60, 1.5, "뒷골목", "alley").label(30, -56.5, "뒷골목", "alley").label(-26, 20.6, "옹벽 밑 뒷골목", "alley")
	p.section_x = -56
	p.notes = [
		("짜임", "안 2 그대로 — 긴 줄을 띄워 놓고 줄마다 뒤에 나란한 뒷골목, 3~4채마다 좁은 틈(빗살)으로 앞 거리와 잇는다. 뒷골목 북쪽은 뒤뜰·헛간. 광장 단 가운데만 육각 광장으로 둘러싼다."),
		("광장", "북쪽 반은 앞면이 광장을 본다 — 길드(정면) · 여관(사선) · 뒤집은 사선 줄. 남쪽 반은 2층 가게 줄(문은 바깥 둘레 길) + 가운데 3층 문루. 서·동 꼭짓점이 서문 거리 · 은행 거리로 이어진다."),
		("3/4 화면", "탐험 화면처럼 바닥 깊이를 줄이지 않으면 집은 제 높이만큼만 가린다. 그래서 줄 뒤 뒷골목·뒤뜰이 대부분 보인다(빗금이 적다). 단은 낮게(+2.4 · 0 · −1.2)."),
	]
	return p


def framed(view: Image.Image, title: str) -> Image.Image:
	M = 18
	im = Image.new("RGB", (M + view.width + M, M + 44 + view.height + M), tl.BG)
	ImageDraw.Draw(im).text((M, M - 4), title, font=font(26), fill=tl.BONE)
	im.paste(view, (M, M + 44))
	return im


def main():
	out = tl.OUT
	tp.region(-80, 80, -60, 42, 6)
	p = plan_comb()
	tl.board(p).save(os.path.join(out, "b2.png"), optimize=True)
	view, _ = tp.camera_view(p)
	framed(view, "안 2 · 빗살 골목 + 둘러싼 광장 — 탐험 화면 3/4로 본 7구역(상자)").save(os.path.join(out, "b2_view.png"), optimize=True)
	tp.region(-40, 40, -36, 34, 10)
	view, _ = tp.camera_view(p)
	view = view.crop((0, int(10 * 10), view.width, view.height - int(9 * 10)))
	framed(view, "광장 가까이 — 탐험 화면 3/4(상자 · 문 = 사람 크기)").save(os.path.join(out, "b2_plaza.png"), optimize=True)
	print("wrote b2 · b2_view · b2_plaza")


if __name__ == "__main__":
	main()
